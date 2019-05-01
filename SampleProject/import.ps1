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
$cds.ImportSolution($SolutionName)
$cds.PushData("Data\data.txt", "Data\schema.txt")

write-host "Done!"
#Wait for key down
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



