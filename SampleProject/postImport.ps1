Import-Module .\loader.psm1 -force -verbose

$global:cds.PushData("Data\deployedentity.txt", "Data\schema.txt")

write-host "Post-import finished!"
#Wait for key down
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

