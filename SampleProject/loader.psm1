using module .\PSModules\deployment.psm1

Import-Module .\TagLookups.psm1 -force -verbose

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

				
$global:cds = [CDSDeployment]::new()
$global:cds.InitializeDeployment($true, $SourceConnectionString, $DestinationConnectionString)
