param(
    [string] $envFolder
)
if( -not $envFolder) {
    $envFolder = Get-Location
}

cd $PSScriptRoot
.\loadmodules.ps1
cd $envFolder
.\settings.ps1
cd $PSScriptRoot
Initialize-CDSConnections -EnvironmentFolder $envFolder -ForceUpdate -SourceConnectionString $global:SourceConnectionString -DestinationConnectionString $global:DestinationConnectionString
cd $envFolder