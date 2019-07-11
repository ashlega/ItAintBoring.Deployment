$FileName = "NuGet\ItAintBoring.CDS.PowerShell"
if (Test-Path "$FileName.nupkg") 
{
  Remove-Item "$FileName.nupkg"
}

if (Test-Path "$FileName.zip") 
{
  Remove-Item "$FileName.zip"
}

Compress-Archive -LiteralPath 'deployment.psm1', 'loader.ps1', 'loadmodules.ps1', 'Package.nuspec'  -CompressionLevel Optimal -DestinationPath "$FileName.zip"

Rename-Item -Path "$FileName.zip" -NewName "ItAintBoring.CDS.PowerShell.nupkg"