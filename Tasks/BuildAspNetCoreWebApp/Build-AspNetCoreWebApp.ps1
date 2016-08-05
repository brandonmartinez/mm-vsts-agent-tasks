[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String] [Parameter(Mandatory = $true)]
    $ProjectName,

    [String] [Parameter(Mandatory = $true)]
    $BuildConfiguration
)

Write-Host "Entering script Build-AspNetCoreWebApp.ps1"

Write-Verbose "ProjectName = $ProjectName"

# Import the Task.Common and Task.Internal dll that has all the cmdlets we need for Build
$agentWorkerModulesPath = "$($env:AGENT_HOMEDIRECTORY)\agent\worker\Modules"
$agentDistributedTaskInternalModulePath = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.Internal\Microsoft.TeamFoundation.DistributedTask.Task.Internal.dll"
$agentDistributedTaskCommonModulePath = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.Common\Microsoft.TeamFoundation.DistributedTask.Task.Common.dll"

Write-Verbose "Importing VSTS Module $agentDistributedTaskInternalModulePath" 
Import-Module $agentDistributedTaskInternalModulePath
Write-Verbose "Importing VSTS Module $agentDistributedTaskCommonModulePath"
Import-Module $agentDistributedTaskCommonModulePath

# Starting building
$stagingFolder = Get-TaskVariable $distributedTaskContext "build.artifactstagingdirectory"
$SolutionRoot = $env:BUILD_SOURCESDIRECTORY
$ProjectPath = "$SolutionRoot\src\$ProjectName"
$OutputPath = "$stagingFolder\$ProjectName"

Write-Host "Restore Packages: dotnet restore $ProjectPath"
& "dotnet" "restore" $SolutionRoot

Write-Host "Publishing Project: dotnet publish $ProjectPath --configuration $BuildConfiguration --output $OutputPath"
& "dotnet" "publish" "$ProjectPath" "--configuration" $BuildConfiguration "--output" $OutputPath

# Collect Artifacts
Publish-BuildArtifact $ProjectName $OutputPath

Write-Host "Exiting script Build-AspNetCoreWebApp.ps1"