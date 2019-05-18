$currentFolder = Get-Location 

cd $PSScriptRoot
.\loadmodules.ps1
cd $currentFolder
.\settings.ps1
cd $PSScriptRoot
write-host $PSScriptRoot
Initialize-CDSConnections -EnvironmentFolder $currentFolder -ForceUpdate -SourceConnectionString $global:SourceConnectionString -DestinationConnectionString $global:DestinationConnectionString
cd $currentFolder