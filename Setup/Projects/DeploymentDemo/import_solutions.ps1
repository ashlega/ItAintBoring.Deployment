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

write-host "Import finished - press a key..."

#Wait for key down
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



