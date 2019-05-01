#Uncomment to read password from console
#$password = Read-Host -assecurestring "Please enter your password"
#$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$global:SourceConnectionString = "RequireNewInstance=True;AuthType=Office365;Url=;UserName=;Password="
$global:DestinationConnectionString = "RequireNewInstance=True;AuthType=Office365;Url=;UserName=;Password="