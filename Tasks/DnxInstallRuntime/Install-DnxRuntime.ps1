[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String]
    $SolutionRoot
)

Write-Host "Entering script Install-DnxRuntime.ps1"

$GlobalJsonPath = Join-Path $SolutionRoot "global.json"

Write-Verbose "SolutionRoot = $SolutionRoot"
Write-Verbose "GlobalJsonPath = $GlobalJsonPath"

&{$Branch='dev';iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/brandonmartinez/Aspnet-Home/dev/dnvminstall.ps1'))}
$globalJson = Get-Content -Path $GlobalJsonPath -Raw -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore
$dnxVersion = if($globalJson -and $globalJson.sdk -and $globalJson.sdk.version) { $globalJson.sdk.version } else { throw("Global.json doesn't specify DNX runtime version.") }
$dnxArchitecture = if($globalJson -and $globalJson.sdk -and $globalJson.sdk.architecture) { $globalJson.sdk.architecture } else { "x86" }
$dnxRuntime = if($globalJson -and $globalJson.sdk -and $globalJson.sdk.runtime) { $globalJson.sdk.runtime } else { "clr" }
$dnxRuntimePath = "$($env:USERPROFILE)\.dnx\runtimes\dnx-$dnxRuntime-win-$dnxArchitecture.$dnxVersion"
& $env:USERPROFILE\.dnx\bin\dnvm install $dnxVersion -a $dnxArchitecture -r $dnxRuntime -OS win -Persistent

Write-Verbose "DnxVersion = $dnxVersion"

Write-Host "Exiting script Install-DnxRuntime.ps1"