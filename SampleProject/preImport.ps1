Import-Module .\loader.psm1 -force -verbose

			
#$global:cds.ImportSolution($SolutionName)


#$global:cds.PushData("Data\businessunits.txt", "Data\schema.txt")

write-host "Pre-import finished!"
#Wait for key down
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



