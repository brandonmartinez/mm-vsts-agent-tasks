[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String]
    $WordPressRoot,

    [String] [Parameter(Mandatory = $true)]
    $ArtifactName
)

Write-Host "Entering script Publish-WordPressArtifacts.ps1"

Write-Verbose "WordPressRoot = $WordPressRoot"
Write-Verbose "ArtifactName = $ArtifactName"

# Import the Task.Common and Task.Internal dll that has all the cmdlets we need for Build
$agentWorkerModulesPath = "$($env:AGENT_HOMEDIRECTORY)\agent\worker\Modules"
$agentDistributedTaskInternalModulePath = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.Internal\Microsoft.TeamFoundation.DistributedTask.Task.Internal.dll"
$agentDistributedTaskCommonModulePath = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.Common\Microsoft.TeamFoundation.DistributedTask.Task.Common.dll"
  
Write-Verbose "Importing VSTS Module $agentDistributedTaskInternalModulePath" 
Import-Module $agentDistributedTaskInternalModulePath
Write-Verbose "Importing VSTS Module $agentDistributedTaskCommonModulePath"
Import-Module $agentDistributedTaskCommonModulePath

$stagingFolder = Get-TaskVariable $distributedTaskContext "build.artifactstagingdirectory"
$artifactStagingFolder = "$stagingFolder\$ArtifactName"
$WordPressCopyDestination = "$artifactStagingFolder"

Write-Verbose "Copying $WordPressRoot to $WordPressCopyDestination"
Copy-Item "$WordPressRoot" $WordPressCopyDestination -Exclude @(".git", ".git*", ".flow", ".hg", ".hg*") -Recurse

Write-Verbose "Cleaning up $WordPressCopyDestination before publish."

Write-Host "Publishing WordPress artifact from staging folder to Build Artifact destination $artifactStagingFolder"
Publish-BuildArtifact $ArtifactName $artifactStagingFolder

Write-Host "Leaving script Publish-WordPressArtifacts.ps1"