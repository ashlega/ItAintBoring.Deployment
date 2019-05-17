..\..\loader.ps1

#Export solution
Get-CDSSolution "DeploymentDemo" #-Managed

#Export schema
$entityNames = @("ita_deployedentity")
Get-CDSSchema $entityNames "Data\schema.txt"

#Export data


$fetch = @'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="ita_deployedentity">
    <all-attributes />
  </entity>
</fetch>
'@
Get-CDSData $fetch "Data\deployedentity.txt"

write-host "Done!"

#Wait for key down
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

