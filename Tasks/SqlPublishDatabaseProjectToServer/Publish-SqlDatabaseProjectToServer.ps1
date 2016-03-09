[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String] [Parameter(Mandatory = $true)]
    $DatabasePublishProfilePath,

    [String] [Parameter(Mandatory = $true)]
    $DatabaseDacpacPath,

    [String] [Parameter(Mandatory = $true)]
    $DatabaseServerName,

    [String] [Parameter(Mandatory = $true)]
    $DatabaseName,

    [String] [Parameter(Mandatory = $true)]
    $DatabaseUserName,

    [String] [Parameter(Mandatory = $true)]
    $DatabasePassword,
    
    [String] [Parameter(Mandatory = $true)]
    $SqlCommandTimeout,

    [String]
    $AdditionalArguments
)

Write-Host "Entering script Publish-SqlDatabaseProjectToAzure.ps1"

Write-Verbose "DatabasePublishProfilePath = $DatabasePublishProfilePath"
Write-Verbose "DatabaseDacpacPath = $DatabaseDacpacPath"
Write-Verbose "DatabaseServerName = $DatabaseServerName"
Write-Verbose "DatabaseName = $DatabaseName"
Write-Verbose "DatabaseUserName = $DatabaseUserName"
Write-Verbose "DatabasePassword = $DatabasePassword"
Write-Verbose "SqlCommandTimeout = $SqlCommandTimeout"
Write-Verbose "AdditionalArguments = $AdditionalArguments"

# Santiize an empty AdditionalArguments value
if([string]::IsNullOrWhiteSpace($AdditionalArguments)) {
    $AdditionalArguments = ""
}

# Adding known arguments. For more information visit https://msdn.microsoft.com/en-us/hh550080(v=vs.103).aspx
$AdditionalArguments += " /p:CommandTimeout=$SqlCommandTimeout"

# Import the Task.Common and Task.Internal dll that has all the cmdlets we need for Build
$agentWorkerModulesPath = "$($env:AGENT_HOMEDIRECTORY)\agent\worker\Modules"
$agentDistributedTaskInternalModulePath = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.Internal\Microsoft.TeamFoundation.DistributedTask.Task.Internal.dll"
$agentDistributedTaskCommonModulePath = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.Common\Microsoft.TeamFoundation.DistributedTask.Task.Common.dll"
$agentDistributedTaskDevTestLabs = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.DevTestLabs\Microsoft.TeamFoundation.DistributedTask.Task.DevTestLabs.dll"
$agentDistributedTaskDeploymentInternal = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.Deployment.Internal\Microsoft.TeamFoundation.DistributedTask.Task.Deployment.Internal.psm1"
  
Write-Verbose "Importing VSTS Module $agentDistributedTaskInternalModulePath" 
Import-Module $agentDistributedTaskInternalModulePath
Write-Verbose "Importing VSTS Module $agentDistributedTaskCommonModulePath"
Import-Module $agentDistributedTaskCommonModulePath
Write-Verbose "Importing VSTS Module $agentDistributedTaskDevTestLabs"
Import-Module $agentDistributedTaskDevTestLabs
Write-Verbose "Importing VSTS Module $agentDistributedTaskDeploymentInternal"
Import-Module $agentDistributedTaskDeploymentInternal

$scriptArgument = Get-SqlPackageCommandArguments -dacpacFile $DatabaseDacpacPath -targetMethod "server" -serverName $DatabaseServerName -databaseName $DatabaseName -sqlUsername $DatabaseUserName -sqlPassword $DatabasePassword -publishProfile $DatabasePublishProfilePath -additionalArguments $AdditionalArguments

Write-Verbose "Created SQLPackage.exe agruments"  -Verbose

<#
// Returns an older version of sqlpackage; working around this for now
$sqlDeploymentScriptPath = Join-Path "$env:AGENT_HOMEDIRECTORY" "Agent\Worker\Modules\Microsoft.TeamFoundation.DistributedTask.Task.DevTestLabs\Scripts\Microsoft.TeamFoundation.DistributedTask.Task.Deployment.Sql.ps1"
$SqlPackageCommand = "& `"$sqlDeploymentScriptPath`" $scriptArgument"

Write-Verbose "Executing SQLPackage.exe"  -Verbose

$ErrorActionPreference = 'Continue'

Invoke-Expression -Command $SqlPackageCommand

$ErrorActionPreference = 'Stop'
#>

$sqlPackage = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\120\SqlPackage.exe"
$sqlPackageArguments = $scriptArgument.Trim('"', ' ')
$command = "`"$sqlPackage`" $sqlPackageArguments"
$command = $command.Replace("'", "`"")

Write-Verbose "Executing SQLPackage.exe with command $command"

$PowershellVersion5 = "5"
$ErrorActionPreference = 'Continue'
if ($PSVersionTable.PSVersion.Major -ge $PowershellVersion5) {
    cmd.exe /c "$command"
} else {
    cmd.exe /c "`"$command`""
}
$ErrorActionPreference = 'Stop'




Write-Host "Leaving script Publish-SqlDatabaseProjectToAzure.ps1"