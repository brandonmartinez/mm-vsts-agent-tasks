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
$dnxVersion = if($globalJson -and $globalJson.sdk -and $globalJson.sdk.version) { $globalJson.sdk.version } else { throw("Global.json doesn't specify DNX runtime version.") }
$dnxArchitecture = if($globalJson -and $globalJson.sdk -and $globalJson.sdk.architecture) { $globalJson.sdk.architecture } else { "x86" }
$dnxRuntime = if($globalJson -and $globalJson.sdk -and $globalJson.sdk.runtime) { $globalJson.sdk.runtime } else { "clr" }
$dnxRuntimePath = "$($env:USERPROFILE)\.dnx\runtimes\dnx-$dnxRuntime-win-$dnxArchitecture.$dnxVersion"

Write-Verbose "DNX Runtime Path = $dnxRuntimePath"

# Import the Task.Common and Task.Internal dll that has all the cmdlets we need for Build
$agentDistributedTaskInternalModulePath = "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
$agentDistributedTaskCommonModulePath = "Microsoft.TeamFoundation.DistributedTask.Task.Common"
  
Write-Verbose "Importing VSTS Module $agentDistributedTaskInternalModulePath" 
Import-Module $agentDistributedTaskInternalModulePath
Write-Verbose "Importing VSTS Module $agentDistributedTaskCommonModulePath"
Import-Module $agentDistributedTaskCommonModulePath

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