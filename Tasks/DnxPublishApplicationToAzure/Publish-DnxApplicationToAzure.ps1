[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String] [Parameter(Mandatory = $true)]
    $ConnectedServiceName,
    
    [String] [Parameter(Mandatory = $true)]
    $AzureApplicationPath,

    [String] [Parameter(Mandatory = $true)]
    $AzureTargetWebApps,

    [String]
    $AzureTargetWebAppSlotName,
    
    [String]
    $AzureWebAppForceStop
)

Write-Host "Entering script Publish-DnxApplicationToAzure.ps1"
Write-Verbose "AzureWebJobPath = $AzureWebJobPath"
Write-Verbose "AzureTargetWebApps = $AzureTargetWebApps"
Write-Verbose "AzureTargetWebAppSlotName = $AzureTargetWebAppSlotName"
Write-Verbose "AzureWebAppForceStop = $AzureWebAppForceStop"

Convert-String $AzureWebAppForceStop Boolean

$AzureTargetWebAppList = $AzureTargetWebApps.split("`r`n") | Where {-not [string]::IsNullOrWhiteSpace($_)}

$AzureTargetWebAppList | % {
    $webappName = $_
    
    Write-Verbose "Azure Web App Targeted: $webappName"
  
    if($AzureWebAppForceStop) {
        Write-Verbose "Force Stop Requested. Stopping Azure Website $webappName to ensure no locks"
        Stop-AzureWebsite -Name $webappName
    } else {
        Write-Verbose "Restarting Azure Website $webappName to ensure no locks"
        Restart-AzureWebsite -Name $webappName
    }
    
    try {
        Write-Verbose "Starting publish of $webappName"
        $webapp = if ([string]::IsNullOrWhiteSpace($AzureTargetWebAppSlotName)) {  Get-AzureWebsite -Name $webappName } else {  Get-AzureWebsite -Name $webappName -Slot $AzureTargetWebAppSlotName }
        
        # If we have an array, we most likely have additional slots on this website. Throw an exception and leave.
        if($webapp -is [System.Object[]]) {
            throw [System.Exception] "Multiple websites returned for $webappName; please specify a slot"
        }
        
        # Grab SCM url to use with MSDeploy; there should only be one
        $msdeployurl = $webapp.EnabledHostNames | Where-Object {$_ -like "*.scm.*"}
        
        if($msdeployurl -is [System.Object[]]) {
            throw [System.Exception] "Multiple SCM urls returned for $webappName; consult Kudu/Azure portal to clarify."
        }
        
        $msdeployIisAppPath = $webapp.Name
        
        # For additional options, check here: https://github.com/sayedihashimi/publish-module/blob/master/publish-module.psm1
        $publishProperties = @{
            'WebPublishMethod'='MSDeploy'; `
            'MSDeployServiceUrl'=$msdeployurl; `
            'DeployIisAppPath'=$msdeployIisAppPath; `
            'EnableMSDeployAppOffline'=$true; `
            'MSDeployUseChecksum'=$true; `
        }
        
        <#
        TODO: add ability to clear deployment
        if($clearDeployment -eq $true) {
            $publishProperties.Add('SkipExtraFilesOnServer', $false)
        }
        #>
    
        Write-Verbose "Using the following publish properties (excluding username and password):"            
        Write-Verbose ($publishProperties | Format-List | Out-String)
        
        $publishProperties.Add('Username', $webapp.PublishingUsername)
        $publishProperties.Add('Password', $webapp.PublishingPassword)
        
        $publishScript = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\Publish\Scripts\default-publish.ps1"
            
        Write-Verbose "Running publish script $publishScript"
        
        . $publishScript -publishProperties $publishProperties -packOutput $AzureApplicationPath
        
        Write-Verbose "Finished publish of $webappName"
    }
    catch
    {
        $errorMessage = $_.Exception.Message
        Write-Error "An exception occurred during deployment of $webappName - $errorMessage"
        throw
    }
    finally {
        if($AzureWebAppForceStop) {
            Write-Verbose "Force Stop Previously Requested. Starting Azure Website $webappName"
            Start-AzureWebsite -Name $webappName
        }
    }
}


Write-Host "Leaving script Publish-DnxApplicationToAzure.ps1"