
$script:cds = $null
$script:TagLookups = @{}
$script:DestTagValues = @{}
$script:SourceTagValues = @{}


$HelperSource = @"

public class Helper
{
  public static void SetAttribute(Microsoft.Xrm.Sdk.Entity entity, string name, object value)
  {
     entity[name] = value;
  }
  
  public static void SetNullAttribute(Microsoft.Xrm.Sdk.Entity entity, string name, object value)
  {
     entity[name] = null;
  }
  
  public static string GetBaseTypes(System.Type type)
  {
    if(type.BaseType != null) return GetBaseTypes(type.BaseType) + ":" + type.ToString();
    else return type.ToString();
  }
  
  public static string GetObjectTypes(System.Object obj)
  {
    return GetBaseTypes(obj.GetType());
  }
}
"@


function Add-CDSTagLookup{
  param(
      [Parameter(Mandatory = $true)]
      [string]
	  $tagName = $null,
	  [Parameter(Mandatory = $true)]
      [string]
	  $fetch = $null
   )
  if ($script:TagLookups.Contains($tagName)  -eq $false){
    $TagLookups.add($tagName, $fetch)
  }
}

function Get-CDSSchema($entityNames, $fileName){
   $script:cds.ExportSchema($entityNames, $fileName)
}

function Push-CDSData($fileName){
   $script:cds.ImportData($fileName)
}

function Get-CDSData{
   param(
      [Parameter(Mandatory = $true)]
      [string]
	  $fetch = $null,
	  [Parameter(Mandatory = $true)]
      [string]
	  $filePath = $null
   )
   $script:cds.ExportData($fetch, $filePath)
}

function Initialize-CDSConnections{
   param(
      [string]$EnvironmentFolder = $null,
      [switch]$ForceUpdate = $true, 
	  [string]$SourceConnectionString = $null, 
	  [string]$DestinationConnectionString = $null
   )
   $script:cds = [CDSDeployment]::new()
   $script:cds.InitializeDeployment($EnvironmentFolder, $ForceUpdate, $SourceConnectionString, $DestinationConnectionString) 
}

function Get-Types($param)
{
  return [Helper]::GetObjectTypes($param)
}

function Get-CDSSolution([string] $solutionName, [switch] $Managed = $false)
{
  $script:cds.ExportSolution($solutionName, $Managed)
}

function Push-CDSSolution()
{
  param(
	[string]$solutionName, #Solution name
	[switch] $Managed = $false,
	[bool]$override, #If set to 1 will override the solution even if a solution with same version exists
	[bool]$publishWorkflows, #Will publish workflows during import
	[bool]$overwriteUnmanagedCustomizations, #Will overwrite unmanaged customizations
	[bool]$skipProductUpdateDependencies, #Will skip product update dependencies
	[switch]$holdingSolution = $false #Imports by creating a holding/upgrade solution
	#[bool]$ImportAsync = $false, #Import solution in Async Mode, recommended
	#[int]$AsyncWaitTimeout #Optional - Async wait timeout in seconds
  )
  
    write-host "Importing solution: $solutionName"
		
	if(!$Managed)
	{
	  $fileBytes = [System.IO.File]::ReadAllBytes("$($script:cds.SolutionsFolder)\$solutionName.zip")
	}
	else{
	  $fileBytes = [System.IO.File]::ReadAllBytes("$($script:cds.SolutionsFolder)\${solutionName}_managed.zip")
	}
		
	

	$impSolReq = [Microsoft.Crm.Sdk.Messages.ImportSolutionRequest]::New()
	$impSolReq.CustomizationFile = $fileBytes
    $impSolReq.PublishWorkflows = $publishWorkflows
	$impSolReq.OverwriteUnmanagedCustomizations = $overwriteUnmanagedCustomizations
	$impSolReq.SkipProductUpdateDependencies = $skipProductUpdateDependencies
	$impSolReq.HoldingSolution = $holdingSolution
	
	$script:cds.DestConn.Execute($impSolReq)
	
	if(!$Managed)
	{
		write-host "Publishing customizations"
		$script:cds.PublishAll()
	}
		
}

function Push-ApplySolutionUpgrades()
{
    param(
	  [string]$solutionName #Solution name
    )
  
    write-host "Applying solution upgrades: $solutionName"
	$promoteReq = [Microsoft.Crm.Sdk.Messages.DeleteAndPromoteRequest]::New()
	$promoteReq.UniqueName = $solutionName
	$result = $script:cds.DestConn.Execute($promoteReq)
	write-host "Publishing customizations"
}

#A workaround for PSObject wrapping/unwrapping
#Seems to work, so all good
function Set-Attribute($entity, $name, $value)
{
   if($value -eq $null){ [Helper]::SetNullAttribute($entity, $name, $value) }
   else{  [Helper]::SetAttribute($entity, $name, $value) }
}

function Get-CustomConnection($conString)
{
  return [Microsoft.Xrm.Tooling.Connector.CrmServiceClient]::New($conString);
}

function Get-EntityFilters()
{
	return [Microsoft.Xrm.Sdk.Metadata.EntityFilters]::Attributes + [Microsoft.Xrm.Sdk.Metadata.EntityFilters]::Relationships
}

function Get-AttributeTypeName($typeCode)
{
   switch ($typeCode.Value)
     {
         ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::LookupType).Value { return "entityReference" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::MoneyType).Value { return "money" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::DecimalType).Value { return "decimal" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::StringType).Value { return "string" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::PicklistType).Value { return "optionSet" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::BooleanType).Value { return "bool" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::VirtualType).Value { return "virtual" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::DoubleType).Value { return "double" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::IntegerType).Value { return "integer" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::DateTimeType).Value { return "dateTime" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::UniqueidentifierType).Value { return "guid" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::StatusType).Value { return "status" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::StateType).Value { return "state" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::CustomerType).Value { return "customer" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::BigIntType).Value { return "bigint" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::MemoType).Value { return "string" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::EntityNameType).Value { return "entityName" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::ImageType).Value { return "image" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::OwnerType).Value { return "owner" }
		 ([Microsoft.Xrm.Sdk.Metadata.AttributeTypeDisplayName]::MultiSelectPicklistType).Value { return "multiSelectOptionSet" }
		 
         default { return $typeCode }
     }
}


class CDSDeployment {
	
	[string]   $environmentFolder = $null
	[PSObject] $SourceConn = $null
	[PSObject] $DestConn = $null
	[string]   $SolutionsFolder = "" 
    [PSObject] $schema = $null

	[bool] CheckRecordExists([PSObject] $conn, [PSObject] $entity, $isIntersect)
	{
	    
			Try
			{
				$ColumnSet = New-Object Microsoft.Xrm.Sdk.Query.ColumnSet $true
				$conn.Retrieve($entity.LogicalName, $entity.id, $ColumnSet)
				return $true
			}
			Catch
			{
				return $false
			}
		
	}
	
	[void] UpsertRecord([PSObject] $conn, [PSObject] $entity, [PSObject] $schema)
	{
		#assuming there is always an id - this is for configuration data after all
		if($schema.isIntersect){
		    $firstRef = New-Object Microsoft.Xrm.Sdk.EntityReference -ArgumentList @($schema."Entity1LogicalName", $entity.attributes[$schema."Entity1IntersectAttribute"])   
			$secondRef = New-Object Microsoft.Xrm.Sdk.EntityReference -ArgumentList @($schema."Entity2LogicalName", $entity.attributes[$schema."Entity2IntersectAttribute"])   
			$request = New-Object Microsoft.Xrm.Sdk.Messages.AssociateRequest
			$request.Target = $firstRef
			$request.RelatedEntities = New-Object Microsoft.Xrm.Sdk.EntityReferenceCollection
			$request.RelatedEntities.Add($secondRef)
			$relEntityName = $entity.LogicalName
			$request.Relationship = New-Object Microsoft.Xrm.Sdk.Relationship -ArgumentList @($schema."RelationshipName")
			try
			{
			  $conn.Execute($request)
			}
			catch
			{
			  if($_.Exception.Message.contains("Cannot insert duplicate key") -eq $false) {
				throw
			  }
			}
		}
		else{
			$recordExists = $this.CheckRecordExists($conn, $entity, $schema.isIntersect)
			if($recordExists) { $conn.Update($entity) }
			else { $conn.Create($entity) }
		}
	}

	[void] PublishAll()
	{
	   $request = New-Object Microsoft.Crm.Sdk.Messages.PublishAllXmlRequest
	   $this.DestConn.Execute($request)
	}

	[void] ImportSolution([string] $solutionName)
	{
		#$impId = New-Object Guid
		
	}

	[void] ExportSolution([string] $solutionName, [switch] $Managed = $false)
	{
	    write-host "Exporting solution: $solutionName"
		$request = New-Object Microsoft.Crm.Sdk.Messages.ExportSolutionRequest
		$request.Managed = $Managed
		$request.SolutionName = $solutionName
		$response = $this.SourceConn.Execute($request)
		if(!$Managed)
		{
		  [io.file]::WriteAllBytes("$($this.SolutionsFolder)\$solutionName.zip",$response.ExportSolutionFile)
		}
		else{
		  [io.file]::WriteAllBytes("$($this.SolutionsFolder)\${solutionName}_managed.zip",$response.ExportSolutionFile)
		}
	}
	
	

	[void] SetField([string] $entityName, [PSObject] $schema, [PSObject] $entity, [string] $fieldName, [PSObject] $value)
	{
		
		try{
			$assigned = $false
			if($value -eq $null){
			   Set-Attribute $entity $fieldName $null
			   return
			}
			
			if($schema.attributes.$fieldName -eq $null)
			{
			   throw "$entityName.$fieldName attribute is not defined in the schema"
			}
			
			$ignore = $false
			$value = $value.Trim()
			$convValue = $value

            
            switch($fieldName){
			   "createdon" { $fieldName = "overriddencreatedon" }
			}
			
			switch($schema.attributes.$fieldName){
			   "optionSet" { $convValue = New-Object Microsoft.Xrm.Sdk.OptionSetValue $value }
			   "multiSelectOptionSet" { 
				   $stringValues = $value.Split(" ")
					[object] $valueList = foreach($number in $stringValues) {
						try {
							New-Object Microsoft.Xrm.Sdk.OptionSetValue $number
						}
						catch {
							write-host "Cannot create an option set value for $entityName.$fieldName - $value"
						}
					}
					$convValue = New-Object Microsoft.Xrm.Sdk.OptionSetValueCollection 
					$convValue.AddRange($valueList)
				}
				
				"money" {
				   $convValue = New-Object Microsoft.Xrm.Sdk.Money $value
				}
				
				"bool" {
				   $convValue = [System.Boolean]::Parse($value)
				}
				"entityReference" {
					$pair = $value.Split(":")
					$convValue = New-Object -TypeName Microsoft.Xrm.Sdk.EntityReference
					$convValue.LogicalName = $pair[0]
					$convValue.Id = $pair[1]
					$convValue.Name = $null
				}
				"guid"{
				   $convValue = [System.Guid]::Parse($value)
				}
				
				"entityName"{
				   $convValue = $value
				}
				"dateTime"{
				    $convValue = [DateTime]::Parse($value)
				}
				
				"owner"  { $ignore = $true }
				"status" { $ignore = $true }
			    "state"  { $ignore = $true }
				
				
				default {
				   $convValue = $value
				}
			}
			if($ignore -ne $true)
			{
			    Set-Attribute $entity $fieldName $convValue
		    }
		}
		catch{
		    write-host "Error setting $fieldName to $value"
			write-host $_.Exception.Message
			throw
		}
	}

	[string] GetFieldValueInternal($value)
	{
	    $typeName =  $value.GetType().ToString().Trim()
		if($typeName -eq "Microsoft.Xrm.Sdk.OptionSetValue"){
		  return $value.Value
		}
		if($typeName -eq "Microsoft.Xrm.Sdk.EntityReference"){
		  return "$($value.LogicalName):$($value.Id)"
		}
		if($typeName -eq "Microsoft.Xrm.Sdk.OptionSetValueCollection"){
		  $list = @()
		  $value | ForEach-Object -Process {
		      $list += $_.Value
		  }
		  return $list
		}
		if($typeName -eq "Microsoft.Xrm.Sdk.Money"){
		  return $value.Value
		}
		if($typeName -eq "System.Guid"){
		  return $value
		}
		return $value
	}
	
	[string] GetFieldValue($val, $tagValues)
	{
		$result = $this.GetFieldValueInternal($val)
		#replace known values with tags
	    foreach($key in $tagValues.keys){
		  $result = $result.Replace($tagValues[$key], $key)
	    }
		return $result
	}

    [string] ReplaceTags($val, $tagValues)
	{
	   foreach($key in $tagValues.keys){
	      $val = $val.Replace($key, $tagValues[$key])
	   }
	   return $val;
	}
	
	[void] ImportData([string] $DataFile)
	{
		write-host "Importing data from $dataFile..."
		
		#$cdsSchema = Get-Content "$SchemaFile" | Out-String | ConvertFrom-Json 
		$json = Get-Content "$DataFile" | Out-String | ConvertFrom-Json 
	  
	    $json | ForEach-Object -Process {
			$entityName = $_.entityName
			$this.LoadSchema($entityName, $this.DestConn)
			
			$entitySchema = $this.schema.$entityName
			if($entitySchema -eq $null){
				write-host "There is no schema for $entityName"
			}
		    else {
			     $entity = New-Object Microsoft.Xrm.Sdk.Entity -ArgumentList $entityName
				 $_.value.PSObject.Properties | ForEach-Object -Process {
				    $fieldName = $_.Name.Trim()
					$value = $this.ReplaceTags($_.Value, $script:DestTagValues)
					if($fieldName -ne "id") {
						$this.SetField($entityName, $entitySchema, $entity, $fieldName, $value)
					}
					else{
						$entity.id = $value
					}
				 }
				 $this.UpsertRecord($this.DestConn, $entity, $entitySchema)
			}
		}
		
	}
	
	[void] ExportData([string] $FetchXml, [string] $DataFile)
	{
		write-host "Exporting data to $DataFile..."
		
		$fetch = $this.ReplaceTags($FetchXml, $script:SourceTagValues)
		$query  = New-Object Microsoft.Xrm.Sdk.Query.FetchExpression $fetch
		$results = $this.SourceConn.RetrieveMultiple($query)

		$records = @()
		$results.Entities | ForEach-Object -Process{
		    $r = New-Object Object
			$records += $r
			$r | Add-Member -NotePropertyName entityName -NotePropertyValue $_.LogicalName

			$value = New-Object Object
			$r | Add-Member -NotePropertyName value -NotePropertyValue $value

			$value | Add-Member -NotePropertyName id -NotePropertyValue $_.Id

		   
			$_.Attributes | ForEach-Object -Process {
			  $value | Add-Member -NotePropertyName $_.Key -NotePropertyValue $this.GetFieldValue($_.Value, $script:SourceTagValues)
			}
			
		}

		$records | ConvertTo-Json | Out-File -FilePath $DataFile
	}
	
	[void] AddAttribute($object, $name, $value)
	{
	    if($object.$name -eq $null)
		{
			$object | Add-Member -NotePropertyName $name -NotePropertyValue $value
		}
	}
	
	[void] LoadSchema([string] $entityName, [PSObject] $conn)
	{
	    if($this.schema -eq $null)
		{
		    $this.schema = New-Object Object
		}
	    $request = New-Object Microsoft.Xrm.Sdk.Messages.RetrieveEntityRequest
		$request.EntityFilters = Get-EntityFilters
		$request.LogicalName = $entityName
		$response = $conn.Execute($request)
		$attributes = New-Object Object
		if($this.schema.$($request.LogicalName) -eq $null)
		{
			$entityObject = New-Object Object
			$this.schema | Add-Member -NotePropertyName $request.LogicalName -NotePropertyValue $entityObject
		}
		
		if($this.schema.$($request.LogicalName).attributes -eq $null)
		{
			$this.schema.$($request.LogicalName) | Add-Member -NotePropertyName "attributes" -NotePropertyValue $attributes
		}
		
		if($this.schema.$($request.LogicalName).isIntersect -eq $null)
		{
			$this.schema.$($request.LogicalName) | Add-Member -NotePropertyName "isIntersect" -NotePropertyValue $false
		}
		
		if($this.schema.$($request.LogicalName).primaryIdAttribute -eq $null)
		{
			$this.schema.$($request.LogicalName) | Add-Member -NotePropertyName "primaryIdAttribute" -NotePropertyValue ""
		}
		
		$this.schema.$($request.LogicalName).isIntersect = $response.EntityMetadata.IsIntersect 
		if($response.EntityMetadata.IsIntersect -eq $true)
		{
			$this.AddAttribute($this.schema.$($request.LogicalName), "Entity1IntersectAttribute", $response.EntityMetadata.ManyToManyRelationships[0].Entity1IntersectAttribute)
			$this.AddAttribute($this.schema.$($request.LogicalName), "Entity1LogicalName", $response.EntityMetadata.ManyToManyRelationships[0].Entity1LogicalName)
			$this.AddAttribute($this.schema.$($request.LogicalName), "Entity2IntersectAttribute", $response.EntityMetadata.ManyToManyRelationships[0].Entity2IntersectAttribute)
			$this.AddAttribute($this.schema.$($request.LogicalName), "Entity2LogicalName", $response.EntityMetadata.ManyToManyRelationships[0].Entity2LogicalName)
			$this.AddAttribute($this.schema.$($request.LogicalName), "RelationshipName", $response.EntityMetadata.ManyToManyRelationships[0].SchemaName)
		}
		$this.schema.$($request.LogicalName).attributes = $attributes
		$this.schema.$($request.LogicalName).primaryIdAttribute = $response.EntityMetadata.PrimaryIdAttribute

		$response.EntityMetadata.Attributes | ForEach-Object -Process {
			$typeName = Get-AttributeTypeName $_.AttributeTypeName
			$attributes | Add-Member -NotePropertyName $_.LogicalName -NotePropertyValue $typeName
		}
	}
	
	[void] ExportSchema([string[]] $entityNames, [string] $schemaFile)
	{
		write-host "Exporting schema"
		$this.schema = New-Object Object
		if(Test-Path -Path $schemaFile){
		   $this.schema = Get-Content "$schemaFile" | Out-String | ConvertFrom-Json 
		}

		$entityNames | ForEach-Object -Process {
			$this.LoadSchema($_, $this.sourceConn)
		}
		$this.schema | ConvertTo-Json | Out-File -FilePath $schemaFile
	}

	[void] InitializeDeployment([string]$environmentFolder, [Switch] $forceUpdate, [string] $sourceConnectionString, [string] $destinationConnectionString)
	{
	    write-host "Initializing connections..."
		$this.environmentFolder = $environmentFolder
		$currentDir = Get-Location
		$this.SolutionsFolder = $environmentFolder
		$this.SolutionsFolder = "$($this.SolutionsFolder)\Solutions"
		
		if (!(Test-Path -Path ".\PSModules")) {
		  New-Item -ItemType "directory" -Path ".\PSModules"
		}

		cd .\PSModules
		
		#Get nuget
		$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
		$targetNugetExe = ".\nuget.exe"

		if (!(Test-Path -Path $targetNugetExe)) {
		  Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
		}
		Set-Alias nuget $targetNugetExe -Scope Global 

		
		#Download and install modules

		if($forceUpdate) { Remove-Item .\Microsoft.CrmSdk.XrmTooling.CrmConnector.PowerShell -Force -Recurse -ErrorAction Ignore }
		if ($forceUpdate -OR !(Test-Path -Path .\Microsoft.CrmSdk.XrmTooling.CrmConnector.PowerShell\tools))
		{
		  ./nuget install Microsoft.CrmSdk.XrmTooling.CrmConnector.PowerShell -ExcludeVersion -O .\
		}

		#Register XRM cmdlets
		cd .\Microsoft.CrmSdk.XrmTooling.CrmConnector.PowerShell\tools
		.\RegisterXrmTooling.ps1 *> $null
		
		cd "Microsoft.Xrm.Tooling.CrmConnector.PowerShell"
		
		#No need to add connector dll manuall now that entity references are working correctly
		#Add-Type -Path Microsoft.Xrm.Tooling.Connector.dll
		
		#Register Helper class		
		$assemblyDir = Get-Location
		$refs = @("$assemblyDir\Microsoft.Xrm.Sdk.dll","System.Runtime.Serialization.dll","System.ServiceModel.dll")
		Add-Type -TypeDefinition $script:HelperSource -ReferencedAssemblies $refs | Out-Null

		cd $currentDir
		
		
		if (!(Test-Path -Path $this.SolutionsFolder)) {
		  New-Item -ItemType "directory" -Path $this.SolutionsFolder
		}
		
		#$this.SourceConn = Get-CustomConnection $sourceConnectionString
		#$this.DestConn = Get-CustomConnection $destinationConnectionString
		$this.SourceConn = Get-CrmConnection -ConnectionString $sourceConnectionString
		$this.DestConn = Get-CrmConnection -ConnectionString $destinationConnectionString
		
		#start reading "tag" values
	
	    #Destination lookups
		foreach($key in $script:TagLookups.keys){
		  $fetch = $script:TagLookups[$key]
		  $fetch = $this.ReplaceTags($fetch, $script:TagLookups)
		  $query  = New-Object Microsoft.Xrm.Sdk.Query.FetchExpression $fetch
		  $results = $this.DestConn.RetrieveMultiple($query)
		  $results.Entities | ForEach-Object -Process{
			$DestTagValues[$key] = $_.Id
		  }  
  	    }
		
		#Source lookups
		foreach($key in $script:TagLookups.keys){
		  $fetch = $script:TagLookups[$key]
		  $fetch = $this.ReplaceTags($fetch, $script:TagLookups)
		  $query  = New-Object Microsoft.Xrm.Sdk.Query.FetchExpression $fetch
		  $results = $this.SourceConn.RetrieveMultiple($query)
		  $results.Entities | ForEach-Object -Process{
			$SourceTagValues[$key] = $_.Id
		  }  
  	    }
		
		#end reading "tag" values	
		
		write-host "Connections ready"
	}

	[void] LoadModule ($m) {

		# If module is imported say that and do nothing
		if (Get-Module | Where-Object {$_.Name -eq $m}) {
			write-host "Module $m is already imported."
		}
		else {

			# If module is not imported, but available on disk then import
			if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
				Import-Module $m -Verbose
			}
			else {

				# If module is not imported, not available on disk, but is in online gallery then install and import
				if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
					Install-Module -Name $m -Force -Verbose -Scope CurrentUser
					Import-Module $m -Verbose
				}
				else {

					# If module is not imported, not available and not in online gallery then abort
					write-host "Module $m not imported, not available and not in online gallery, exiting."
					EXIT 1
				}
			}
		}
	}
}