[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String]
    $ProjectPath,

    [String] [Parameter(Mandatory = $true)]
    $BuildConfiguration,

    [String] [Parameter(Mandatory = $true)]
    $ArtifactName,
    
    [String]
    $CollectOnlyApproot
)

Write-Host "Entering script Publish-DnxApplicationArtifacts.ps1"

$SolutionRoot = $env:BUILD_SOURCESDIRECTORY
$GlobalJsonPath = Join-Path $SolutionRoot "global.json"

Write-Host "SolutionRoot = $SolutionRoot"
Write-Host "GlobalJsonPath = $GlobalJsonPath"
Write-Host "ProjectPath = $ProjectPath"
Write-Host "BuildConfiguration = $BuildConfiguration"
Write-Host "ArtifactName = $ArtifactName"
Write-Host "CollectOnlyApproot = $CollectOnlyApproot"

$CollectOnlyApprootChecked = Convert-String $CollectOnlyApproot Boolean
Write-Host "CollectOnlyApprootChecked = $CollectOnlyApprootChecked"

$globalJson = Get-Content -Path $GlobalJsonPath -Raw -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore
$dnxVersion = if($globalJson) { $globalJson.sdk.version } else { throw("Global.json doesn't specify DNX runtime version.") }
$dnxRuntimePath = "$($env:USERPROFILE)\.dnx\runtimes\dnx-clr-win-x86.$dnxVersion"

Write-Verbose "DNX Runtime Path = $dnxRuntimePath"

# Import the Task.Common and Task.Internal dll that has all the cmdlets we need for Build
$agentWorkerModulesPath = "$($env:AGENT_HOMEDIRECTORY)\agent\worker\Modules"
$agentDistributedTaskInternalModulePath = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.Internal\Microsoft.TeamFoundation.DistributedTask.Task.Internal.dll"
$agentDistributedTaskCommonModulePath = "$agentWorkerModulesPath\Microsoft.TeamFoundation.DistributedTask.Task.Common\Microsoft.TeamFoundation.DistributedTask.Task.Common.dll"
  
Write-Verbose "Importing VSTS Module $agentDistributedTaskInternalModulePath" 
Import-Module $agentDistributedTaskInternalModulePath
Write-Verbose "Importing VSTS Module $agentDistributedTaskCommonModulePath"
Import-Module $agentDistributedTaskCommonModulePath

Write-Host "Restoring DNX project $ProjectPath references"
& "dnu" "restore" "$ProjectPath\project.json" "--fallbacksource" "https://www.myget.org/F/aspnetmaster/api/v2" "2>1"
    
Write-Host "Building DNX project $ProjectPath"
& "dnu" "build" "$ProjectPath"  "--configuration" "$BuildConfiguration" "2>1"

$stagingFolder = Get-TaskVariable $distributedTaskContext "build.artifactstagingdirectory"
$artifactStagingFolder = "$stagingFolder\$ArtifactName"

Write-Host "Publishing DNX project to $artifactStagingFolder"

# TODO: give option of --no-source or not
& "dnu" "publish" $ProjectPath "--configuration" $BuildConfiguration "--out" $artifactStagingFolder "--runtime" $dnxRuntimePath "--no-source"

if($CollectOnlyApprootChecked) {
    $appRootFolder = Join-Path $artifactStagingFolder "approot"
    
    Write-Host "Publishing DNX project artifact from staging folder to Build Artifact destination $appRootFolder"
    Publish-BuildArtifact $ArtifactName $appRootFolder
} else {
    Write-Host "Publishing DNX project artifact from staging folder to Build Artifact destination $artifactStagingFolder"
    Publish-BuildArtifact $ArtifactName $artifactStagingFolder
}

Write-Host "Leaving script Publish-DnxApplicationArtifacts.ps1"