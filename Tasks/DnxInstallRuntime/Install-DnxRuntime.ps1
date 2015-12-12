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

&{$Branch='dev';iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/aspnet/Home/dev/dnvminstall.ps1'))}
$globalJson = Get-Content -Path $GlobalJsonPath -Raw -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore
$dnxVersion = if($globalJson) { $globalJson.sdk.version } else { throw("Global.json doesn't specify DNX runtime version.") }
& $env:USERPROFILE\.dnx\bin\dnvm install $dnxVersion -Persistent

Write-Verbose "DnxVersion = $dnxVersion"

Write-Host "Exiting script Install-DnxRuntime.ps1"