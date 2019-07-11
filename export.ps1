.\Scripts\loader.ps1

#Export solution
Get-CDSSolution $global:SolutionName -Managed
Get-CDSSolution $global:SolutionName 

#Export schema
#$entityNames = @("ita_deployedentity", "businessunit")
#Get-CDSSchema $entityNames "Data\schema.txt"

#Export data


$fetch = @'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="ita_deployedentity">
    <all-attributes />
  </entity>
</fetch>
'@
Get-CDSData $fetch "Data\deployedentity.txt"

$fetch = @'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="businessunit">
    <all-attributes />
	<filter type="and">
      <condition attribute="name" operator="eq" value="Test" />
    </filter>
  </entity>
</fetch>
'@
Get-CDSData $fetch "Data\businessunit.txt"

write-host "Done!"

#Wait for key down
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

