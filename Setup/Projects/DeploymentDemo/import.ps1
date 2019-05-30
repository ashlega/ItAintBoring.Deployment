..\..\loader.ps1

			
Push-CDSSolution $global:SolutionName -Managed -HoldingSolution
Push-ApplySolutionUpdates $global:SolutionName

Push-CDSData "Data\deployedentity.txt" 
Push-CDSData "Data\businessunit.txt" 

write-host "Import finished!"

#Wait for key down
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



