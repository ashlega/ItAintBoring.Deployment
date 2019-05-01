using module .\PSModules\deployment.psm1

if($env:ConnectionString -eq $null){
  Import-Module .\PSModules\deploymentSettings.psm1 -force -verbose
}
else{
  $SourceConnectionString = $env:ConnectionString
  $DestinationConnectionString = $env:ConnectionString
}

if($env:SolutionName -eq $null){
  $SolutionName = "DeploymentDemo"
}
else{
  $SolutionName = $env:SolutionName
}

$cds = [CDSDeployment]::new()
$cds.InitializeDeployment($true, $SourceConnectionString, $DestinationConnectionString)

$cds.ExportSolution($SolutionName, $false)

$fetch = @'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="ita_deployedentity">
    <attribute name="ita_deployedentityid" />
    <attribute name="ita_name" />
    <attribute name="createdon" />
    <attribute name="ita_parententity" />
    <attribute name="ita_optionset" />
    <attribute name="ita_multiselect" />
    <attribute name="ita_money" />
    <order attribute="ita_name" descending="false" />
  </entity>
</fetch>
'@

$cds.ExportData($fetch, "Data\exportedData.txt")

#Wait for key down
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
