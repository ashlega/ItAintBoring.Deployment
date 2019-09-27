loader.ps1

$targetSolutionExists = Get-CDSSolutionExists($global:SolutionName)
			
if($targetSolutionExists)
{	
  Push-CDSSolution $global:SolutionName -Managed -HoldingSolution
  Push-ApplySolutionUpdates $global:SolutionName
}
else{
  Push-CDSSolution $global:SolutionName -Managed
}

Push-CDSData "Data\deployedentity.txt" 
Push-CDSData "Data\businessunit.txt" 

write-host "Import finished!"

#Wait for key down
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



