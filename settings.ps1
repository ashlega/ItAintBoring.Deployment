#Processing connections
if($env:ConnectionString -eq $null){
  $password = Read-Host -assecurestring "Please enter your password"
  $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

  $global:SourceConnectionString = "RequireNewInstance=True;AuthType=Office365;Url=https://treecatsoftware.crm3.dynamics.com;UserName=info@treecatsoftware.com;Password=$password"
  $global:DestinationConnectionString = "RequireNewInstance=True;AuthType=Office365;Url=https://treecatsoftware.crm3.dynamics.com/;UserName=info@treecatsoftware.com;Password=$password"
}
else{
  $global:SourceConnectionString = $env:ConnectionString
  $global:DestinationConnectionString = $env:ConnectionString
}

if($env:SolutionName -eq $null){
  $global:SolutionName = "Demo"
}
else{
  $global:SolutionName = $env:SolutionName
}




#Adding tag lookups

Add-CDSTagLookup "#ROOTBU#" @"
		<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
									  <entity name="businessunit">
										<attribute name="businessunitid" />
										<order attribute="parentbusinessunitid" descending="false" />
										<filter type="and">
										  <condition attribute="parentbusinessunitid" operator="null" />
										</filter>
									  </entity>
									</fetch>
"@ 
				

