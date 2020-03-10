# ItAintBoring.Deployment

A powershell module for solution export/import, and more

## Nuget

https://www.nuget.org/packages/ItAintBoring.CDS.PowerShell

## Overview

https://www.itaintboring.com/dynamics-crm/a-powershell-script-to-importexport-solutions-and-data/

## Solutions, data, and word templates export/import

https://www.itaintboring.com/dynamics-crm/using-powershell-to-exportimport-solutions-data-and-word-templates/

## Bulk-loading inactive records

https://www.itaintboring.com/dynamics-crm/bulk-loading-inactive-records-to-cds/


## Concepts

There are always two connections (source and destination)
Get commands (with the exception of Get-CDSSolutionExists) are working with the source connections 
Push commands(and Get-CDSSolutionExists) are working with the destination connection 

## List of commands

### Get-CDSData

Parameters: [string]$fetch, [string]$filePath

Export data from CDS to a local file

### Get-CDSSolution

Parameters: [string] $solutionName, [switch] $Managed = $false

Export a CDS solution by name (also, managed/unmanaged)

### Push-CDSTheme

Parameters: [string]$themeName
    
Publish a cds theme by name

### Push-CDSData

Parameters: [string]$fileName

Push previously exported data from a local file to CDS

### Push-CDSSolution 

Parameters: 
    [string]$solutionName, #Solution name
	[switch] $Managed = $false,
	[bool]$override, #If set to 1 will override the solution even if a solution with same version exists
	[bool]$publishWorkflows, #Will publish workflows during import
	[bool]$overwriteUnmanagedCustomizations, #Will overwrite unmanaged customizations
	[bool]$skipProductUpdateDependencies, #Will skip product update dependencies
	[switch]$holdingSolution = $false, #Imports by creating a holding/upgrade solution
	[switch]$ImportAsync = $false, #Import solution in Async Mode, recommended
	[int]$AsyncWaitTimeout = 120, #Optional - Async wait timeout in seconds
	[switch]$WaitForCompletion = $true #For async only
	
Push solution to CDS

### Push-ApplySolutionUpdates

Parameters: [string]$solutionName

Apply updates to a solution 

### Get-CDSSolutionExists

Parameters: [string]$solutionName

Check if solution exists in the environment
