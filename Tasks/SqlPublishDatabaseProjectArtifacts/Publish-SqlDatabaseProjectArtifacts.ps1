[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String] [Parameter(Mandatory = $true)]
    $SqlDatabaseProjectPath,

    [String] [Parameter(Mandatory = $true)]
    $BuildConfiguration,

    [String] [Parameter(Mandatory = $true)]
    $ArtifactName
)

Write-Host "Entering script Publish-SqlDatabaseProjectArtifacts.ps1"

Write-Verbose "SqlDatabaseProjectPath = $SqlDatabaseProjectPath"
$SqlDatabaseProjectDirectoryPath = Split-Path $SqlDatabaseProjectPath
Write-Verbose "SqlDatabaseProjectDirectoryPath = $SqlDatabaseProjectDirectoryPath"
Write-Verbose "BuildConfiguration = $BuildConfiguration"
Write-Verbose "ArtifactName = $ArtifactName"

# Import the Task.Common and Task.Internal dll that has all the cmdlets we need for Build
$agentDistributedTaskInternalModulePath = "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
$agentDistributedTaskCommonModulePath = "Microsoft.TeamFoundation.DistributedTask.Task.Common"
  
Write-Verbose "Importing VSTS Module $agentDistributedTaskInternalModulePath" 
Import-Module $agentDistributedTaskInternalModulePath
Write-Verbose "Importing VSTS Module $agentDistributedTaskCommonModulePath"
Import-Module $agentDistributedTaskCommonModulePath

$stagingFolder = Get-TaskVariable $distributedTaskContext "build.artifactstagingdirectory"
$artifactStagingFolder = "$stagingFolder\$ArtifactName"

Write-Host "Configuring MSBuild for Database Project $SqlDatabaseProjectPath"
$MSBuildLocation = Get-MSBuildLocation -Version '' -Architecture 'x86'
$MSBuildArguments = @()
$MSBuildArguments += "/p:Configuration=$BuildConfiguration"
$MSBuildArguments += "/p:OutDir=$artifactStagingFolder"
$MSBuildArgumentList = ($MSBuildArguments -join ' ')

Write-Verbose "MSBuildLocation = $MSBuildLocation"
Write-Verbose "MSBuildArgumentList = $MSBuildArgumentList"

Invoke-MSBuild $SqlDatabaseProjectPath -LogFile "$SqlDatabaseProjectPath.log" -ToolLocation $MSBuildLocation -CommandLineArgs $MSBuildArgumentList

$PublishProfileCopyPattern = "$SqlDatabaseProjectDirectoryPath\*.publish.xml"
Write-Host "Copying publish profiles from $PublishProfileCopyPattern to $artifactStagingFolder"
Copy-Item $PublishProfileCopyPattern $artifactStagingFolder -Recurse -Verbose

Write-Host "Publishing SQL database project artifacts from staging folder to Build Artifact destination $artifactStagingFolder"
Publish-BuildArtifact $ArtifactName $artifactStagingFolder

Write-Host "Leaving script Publish-SqlDatabaseProjectArtifacts.ps1"