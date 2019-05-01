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


function Get-Types($param)
{
  return [Helper]::GetObjectTypes($param)
}

#A workaround for PSObject wrapping/unwrapping
#Seems to work, so all good
function Set-Attribute($entity, $name, $value)
{
   if($value -eq $null){ [Helper]::SetNullAttribute($entity, $name, $value) }
   else{  [Helper]::SetAttribute($entity, $name, $value) }
}

function Custom-GetConnection($conString)
{
  return [Microsoft.Xrm.Tooling.Connector.CrmServiceClient]::New($conString);
}

function Get-EntityFilters()
{
	return [Microsoft.Xrm.Sdk.Metadata.EntityFilters]::Attributes
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
	
	[PSObject] $SourceConn = $null
	[PSObject] $DestConn = $null
	[string]   $SolutionsFolder = ""    

	[bool] CheckRecordExists([PSObject] $conn, [string] $entityName, [string] $id)
	{
		$query = New-Object Microsoft.Xrm.Sdk.Query.QueryByAttribute $entityName
		$query.AddAttributeValue("${entityName}id", $id)
		$query.ColumnSet = New-Object Microsoft.Xrm.Sdk.Query.ColumnSet "${entityName}id"
		$results = $conn.RetrieveMultiple($query)
		if($results.Entities.Count -gt 0) { return $true }
		return $false
	}

	[void] UpsertRecord([PSObject] $conn, [PSObject] $entity)
	{
		#assuming there is always an id - this is for configuration data after all
		$recordExists = $this.CheckRecordExists($conn, $entity.LogicalName, $entity.id)
		if($recordExists) { $conn.Update($entity) }
		else { $conn.Create($entity) }
	}

	[void] PublishAll()
	{
	   $request = New-Object Microsoft.Crm.Sdk.Messages.PublishAllXmlRequest
	   $this.DestConn.Execute($request)
	}

	[void] ImportSolution([string] $solutionName)
	{
		$impId = New-Object Guid
		write-host "Importing solution"
		$this.DestConn.ImportSolutionToCrm("$($this.SolutionsFolder)\$solutionName.zip",[ref] $impId)
		write-host "Publishing customizations"
		$this.PublishAll()
	}

	[void] ExportSolution([string] $solutionName, [switch] $Managed = $false)
	{
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
		
		
	    $assigned = $false
		if($value -eq $null){
		   Set-Attribute $entity $fieldName $null
		   return
		}
		
		if($schema.$fieldName -eq $null)
		{
		   write-host "$entityName.$fieldName attribute is not defined in the schema"
		   return
		}
		
		$value = $value.Trim()
		$convValue = $value

		switch($schema.$fieldName){
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
			default {
			   $convValue = $value
			}
		}
		Set-Attribute $entity $fieldName $convValue
	}

	[string] GetFieldValue($value)
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

	[void] PushData([string] $DataFile, [string] $SchemaFile)
	{
		write-host "Importing data files..."
		$cdsSchema = Get-Content "$SchemaFile" | Out-String | ConvertFrom-Json 
		$json = Get-Content "$DataFile" | Out-String | ConvertFrom-Json 
	  
	    $json | ForEach-Object -Process {
			$entityName = $_.entityName
			$schema = $cdsSchema.$entityName
			if($schema -eq $null){
				write-host "There is no schema for $entityName"
			}
		    else {
			     $entity = New-Object Microsoft.Xrm.Sdk.Entity -ArgumentList $entityName
				 $_.value.PSObject.Properties | ForEach-Object -Process {
				    $fieldName = $_.Name.Trim()
					if($fieldName -ne "id") {
						$this.SetField($entityName, $schema, $entity, $fieldName, $_.Value)
					}
					else{
						$entity.id = $_.Value
					}
				 }
				 $this.UpsertRecord($this.DestConn, $entity)
			}
		}
		
	}
	
	[void] ExportData([string] $FetchXml, [string] $DataFile)
	{
		write-host "Loading data..."
		$query  = New-Object Microsoft.Xrm.Sdk.Query.FetchExpression $FetchXml
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
			  $value | Add-Member -NotePropertyName $_.Key -NotePropertyValue $this.GetFieldValue($_.Value)
			}
			
		}

		$records | ConvertTo-Json | Out-File -FilePath $DataFile
		write-host "Done!"
	}
	
	[void] ExportSchema([string[]] $entityNames, [string] $schemaFile)
	{

	   
		write-host "Exporting schema"
		$schema = New-Object Object
		if(Test-Path -Path $schemaFile){
		   $schema = Get-Content "$schemaFile" | Out-String | ConvertFrom-Json 
		}

		$entityNames | ForEach-Object -Process {
			$request = New-Object Microsoft.Xrm.Sdk.Messages.RetrieveEntityRequest
			$request.EntityFilters = Get-EntityFilters
			$request.LogicalName = $_
			$response = $this.sourceConn.Execute($request)
			$attributes = New-Object Object
			if($schema.$($request.LogicalName) -eq $null)
			{
			    $schema | Add-Member -NotePropertyName $request.LogicalName -NotePropertyValue $null
			}
			$schema.$($request.LogicalName) = $attributes

			$response.EntityMetadata.Attributes | ForEach-Object -Process {
			    $typeName = Get-AttributeTypeName $_.AttributeTypeName
			    $attributes | Add-Member -NotePropertyName $_.LogicalName -NotePropertyValue $typeName
			}
		}
		$schema | ConvertTo-Json | Out-File -FilePath $schemaFile
	}

	[void] InitializeDeployment([Switch] $forceUpdate, [string] $sourceConnectionString, [string] $destinationConnectionString)
	{
		$currentDir = Get-Location
		$this.SolutionsFolder = Get-Location
		$this.SolutionsFolder = "$($this.SolutionsFolder)\Solutions"
		
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
		  write-host "installing nuget"
		  ./nuget install Microsoft.CrmSdk.XrmTooling.CrmConnector.PowerShell -ExcludeVersion -O .\
		}

		#Register XRM cmdlets
		cd .\Microsoft.CrmSdk.XrmTooling.CrmConnector.PowerShell\tools
		.\RegisterXrmTooling.ps1
		
		cd "Microsoft.Xrm.Tooling.CrmConnector.PowerShell"
		
		#No need to add connector dll manuall now that entity references are working correctly
		#Add-Type -Path Microsoft.Xrm.Tooling.Connector.dll
		
		#Register Helper class		
		$assemblyDir = Get-Location
		$refs = @("$assemblyDir\Microsoft.Xrm.Sdk.dll","System.Runtime.Serialization.dll","System.ServiceModel.dll")
		Add-Type -TypeDefinition $script:HelperSource -ReferencedAssemblies $refs

		cd $currentDir
		
		
		if (!(Test-Path -Path $this.SolutionsFolder)) {
		  New-Item -ItemType "directory" -Path $this.SolutionsFolder
		}
		
		#$this.SourceConn = Custom-GetConnection $sourceConnectionString
		#$this.DestConn = Custom-GetConnection $destinationConnectionString
		$this.SourceConn = Get-CrmConnection -ConnectionString $sourceConnectionString
		$this.DestConn = Get-CrmConnection -ConnectionString $destinationConnectionString
		
		
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