loader.ps1

Push-CDSData "Data\documenttemplates.txt" 
Push-CDSData "Data\deployedentity.txt" 
Push-CDSData "Data\\deployedentitywithstatus.txt" 
#Push-CDSData "Data\businessunit.txt" 
Push-CDSData "Data\\themes.txt"
Push-CDSTheme "Test Theme"

write-host "Import finished - press a key..."

#Wait for key down
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



