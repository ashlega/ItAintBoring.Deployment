loader.ps1

Push-CDSData "Data\documenttemplates.txt" 
Push-CDSData "Data\deployedentity.txt" 
Push-CDSData "Data\businessunit.txt" 

write-host "Import finished - press a key..."

#Wait for key down
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



