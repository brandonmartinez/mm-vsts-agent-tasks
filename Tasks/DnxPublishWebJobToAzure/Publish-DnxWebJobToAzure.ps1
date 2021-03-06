[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String] [Parameter(Mandatory = $true)]
    $ConnectedServiceName,
    
    [String] [Parameter(Mandatory = $true)]
    $AzureWebJobPath,

    [String] [Parameter(Mandatory = $true)]
    $AzureWebJobName,

    [String] [Parameter(Mandatory = $true)]
    $AzureWebJobType,

    [String] [Parameter(Mandatory = $true)]
    $AzureTargetWebApps,

    [String]
    $AzureTargetWebAppSlotName,
    
    [String]
    $AzureWebAppForceStop = "0",
    
    [String]
    $SkipExtraFilesOnServer = "0"
)

Write-Host "Entering script Publish-DnxWebJobToAzure.ps1"

Write-Verbose "AzureWebJobPath = $AzureWebJobPath"
Write-Verbose "AzureWebJobName = $AzureWebJobName"
Write-Verbose "AzureWebJobType = $AzureWebJobType"
Write-Verbose "AzureTargetWebApps = $AzureTargetWebApps"
Write-Verbose "AzureTargetWebAppSlotName = $AzureTargetWebAppSlotName"
Write-Verbose "AzureWebAppForceStop = $AzureWebAppForceStop"

$AzureWebAppForceStopChecked = [System.Convert]::ToBoolean($AzureWebAppForceStop)
Write-Verbose "AzureWebAppForceStopChecked = $AzureWebAppForceStopChecked"

$SkipExtraFilesOnServerChecked = $SkipExtraFilesOnServer -eq "1" -or $SkipExtraFilesOnServer -eq "true"
Write-Verbose "SkipExtraFilesOnServerChecked = $SkipExtraFilesOnServerChecked"

$msdeployRegKey = "hklm:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy"
if (-not (Test-Path -Path $msdeployRegKey)) {
    throw "Cannot find msdeploy.exe location!" 
}

$msdeployPath = (Get-ChildItem -Path $msdeployRegKey | Select -Last 1).GetValue("InstallPath")
if (-not (Test-Path -Path $msdeployPath)) {
    throw "Cannot find msdeploy.exe at $msdeployPath!"
}

$msdeployPath = Join-Path $msdeployPath msDeploy.exe

Write-Verbose "msdeployPath = $msdeployPath"

$AzureTargetWebAppList = $AzureTargetWebApps.split("`r`n").split(",").split(";") | Where {-not [string]::IsNullOrWhiteSpace($_)}

$AzureTargetWebAppList | % {
    $webappName = $_
    
    Write-Verbose "Azure Web App Targeted: $webappName"
    
    if ($AzureWebAppForceStopChecked) {
        Write-Verbose "Force Stop Requested. Stopping Azure Website $webappName to ensure no locks"
        if ([string]::IsNullOrWhiteSpace($AzureTargetWebAppSlotName)) {
            Stop-AzureWebsite -Name $webappName
        }
        else {
            Stop-AzureWebsite -Name $webappName -Slot $AzureTargetWebAppSlotName
        }
    }
    else {
        Write-Verbose "Restarting Azure Website $webappName to ensure no locks"
        if ([string]::IsNullOrWhiteSpace($AzureTargetWebAppSlotName)) {
            Restart-AzureWebsite -Name $webappName
        }
        else {
            Restart-AzureWebsite -Name $webappName -Slot $AzureTargetWebAppSlotName
        }
    }
    
    try {
        Write-Verbose "Starting publish of $AzureWebJobType web job $AzureWebJobName to $webappName"
        $webapp = if ([string]::IsNullOrWhiteSpace($AzureTargetWebAppSlotName)) {  Get-AzureWebsite -Name $webappName } else {  Get-AzureWebsite -Name $webappName -Slot $AzureTargetWebAppSlotName }
        
        # If we have an array, we most likely have additional slots on this website. Throw an exception and leave.
        if ($webapp -is [System.Object[]]) {
            throw [System.Exception] "Multiple websites returned for $webappName; please specify a slot"
        }
        
        # Grab SCM url to use with MSDeploy; there should only be one
        $msdeployurl = $webapp.EnabledHostNames | Where-Object {$_ -like "*.scm.*"}
        
        if ($msdeployurl -is [System.Object[]]) {
            throw [System.Exception] "Multiple SCM urls returned for $webappName; consult Kudu/Azure portal to clarify."
        }
        
        Write-Verbose "$webappName - msdeployurl = $msdeployurl"
        
        # MSDeploy variables to use in arguments below
        $msdeployIisAppPath = $webapp.Name
        $msdeployIisSubAppPath = "$msdeployIisAppPath\app_data\jobs\$AzureWebJobType\$AzureWebJobName"
        # The following is Azure specific; your mileage may vary
        $msdeployComputerName = "https://$msdeployurl/msdeploy.axd"
        $msdeployUserName = $webapp.PublishingUsername
        $msdeployPassword = $webapp.PublishingPassword
        
        # Build the msdeploy command, more info on this command here https://technet.microsoft.com/sv-se/library/dd569034(v=ws.10).aspx
        $webrootOutputFolder = (Get-Item $AzureWebJobPath).FullName
        Write-Verbose "$webappName - webrootOutputFolder = $webrootOutputFolder"
        $publishArgs = @()
        $publishArgs += "-source:contentPath='$webrootOutputFolder'"
        $publishArgs += "-dest:contentPath='$msdeployIisSubAppPath',ComputerName='$msdeployComputerName',UserName='$msdeployUserName',Password='$msdeployPassword',IncludeAcls='False',AuthType='Basic'"
        $publishArgs += '-verb:sync'
        $publishArgs += '-usechecksum'
        $publishArgs += '-enablerule:AppOffline'
        $publishArgs += '-retryAttempts:2'
        $publishArgs += '-disablerule:BackupRule'
        if ($SkipExtraFilesOnServerChecked) {
            $publishArgs += '-enableRule:DoNotDeleteRule'
        }
        
        $msdeployArguments = $publishArgs -join " "
        $msdeployArgumentsLog = $msdeployArguments.replace($msdeployPassword, "*********")
        
        Write-Verbose "$webappName - Executing MSDeploy command $msdeployPath"

        $command = "`"$msdeployPath`" $msdeployArguments"
        $command = $command.Replace("'", "`"")
        $PowershellVersion5 = "5"
        $ErrorActionPreference = 'Continue'
        if ($PSVersionTable.PSVersion.Major -ge $PowershellVersion5) {
            cmd.exe /c "$command"
        }
        else {
            cmd.exe /c "`"$command`""
        }
        $ErrorActionPreference = 'Stop'
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error "An exception occurred during deployment of $webappName - $errorMessage"
        throw
    }
    finally {
        Write-Verbose "Force Stop Previously Requested. Starting Azure Website $webappName"
        if ([string]::IsNullOrWhiteSpace($AzureTargetWebAppSlotName)) {
            Start-AzureWebsite -Name $webappName
        }
        else {
            Start-AzureWebsite -Name $webappName -Slot $AzureTargetWebAppSlotName
        }
    }

    Write-Verbose "Finished publish of $AzureWebJobType web job $AzureWebJobName to $webappName"
}


Write-Host "Leaving script Publish-DnxWebJobToAzure.ps1"