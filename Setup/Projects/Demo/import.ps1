..\..\loader.ps1

			
#Push-CDSSolution "DeploymentDemo"

Push-CDSData "Data\deployedentity.txt" "Data\schema.txt"

write-host "Import finished!"

#Wait for key down
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



