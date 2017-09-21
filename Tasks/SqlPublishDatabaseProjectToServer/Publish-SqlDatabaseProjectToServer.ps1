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
    $SqlPackage,

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

# If location not specified, use default version
if([string]::IsNullOrWhiteSpace($SqlPackage)) {
    $SqlPackage = "c:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\SqlPackage.exe"
}

# Adding known arguments. For more information visit https://msdn.microsoft.com/en-us/hh550080(v=vs.103).aspx
$AdditionalArguments += " /p:CommandTimeout=$SqlCommandTimeout"

# Import the Task.Common and Task.Internal dll that has all the cmdlets we need for Build
$agentDistributedTaskInternalModulePath = "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
$agentDistributedTaskCommonModulePath = "Microsoft.TeamFoundation.DistributedTask.Task.Common"
$agentDistributedTaskDevTestLabs = "Microsoft.TeamFoundation.DistributedTask.Task.DevTestLabs"
$agentDistributedTaskDeploymentInternal = "Microsoft.TeamFoundation.DistributedTask.Task.Deployment.Internal"
  
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

$sqlPackageArguments = $scriptArgument.Trim('"', ' ')
$command = "`"$SqlPackage`" $sqlPackageArguments"
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