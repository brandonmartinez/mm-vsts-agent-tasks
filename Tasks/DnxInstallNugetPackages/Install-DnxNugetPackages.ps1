[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String]
    $SolutionRoot
)

Write-Host "Entering script Install-DnxNugetPackages.ps1"

$SrcRoot = Join-Path $SolutionRoot "src"

Write-Verbose "SolutionRoot = $SolutionRoot"
Write-Verbose "SrcRoot = $SrcRoot"

Write-Host "Scanning Source Directory $SrcRoot for project.json files to restore"
Get-ChildItem -Path $SrcRoot -Filter project.json -Recurse | ForEach-Object {
    $ProjectPath = $_.FullName
    Write-Host "Attempting to restore packages for project $ProjectPath"
    & "dnu" "restore" $ProjectPath "--fallbacksource" "https://www.myget.org/F/aspnetmaster/api/v2" "2>1"
}

Write-Host "Exiting script Install-DnxNugetPackages.ps1"