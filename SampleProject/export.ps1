Import-Module .\loader.psm1 -force -verbose



#Export schema
$entityNames = @("ita_deployedentity", "team", "businessunit", "queue", "teamroles", "documenttemplate")
$global:cds.ExportSchema($entityNames, "Data\schema.txt")

#Export solution
#$cds.ExportSolution($SolutionName, $false)

#Export data
$fetch = @'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="ita_deployedentity">
    <all-attributes/>
  </entity>
</fetch>
'@

$global:cds.ExportData($fetch, "Data\deployedentity.txt")




write-host "Done!"

#Wait for key down
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

