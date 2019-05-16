if ($global:TagLookups.Contains("#ROOTBU#")  -eq $false){
    $TagLookups.add("#ROOTBU#", @"
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
				)
}

