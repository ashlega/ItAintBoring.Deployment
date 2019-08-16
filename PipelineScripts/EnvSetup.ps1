$CDSlocation = "canada"


$firstUser = "info@treecatsoftware.com"
$firstPassword = ""
$secondUser = "testuser1@treecatsoftware.com"
$secondPassword = ""
$thirdUser = "testuser2@treecatsoftware.com"
$thirdPassword = ""
$forthUser = "trialuser1@treecatsoftware.com"
$forthPassword = ""
$fithUser = "trialuser2@treecatsoftware.com"
$fithPassword = ""

$environments = @()



$environments += @{
                     name = 'TestMaster'
                     user = $firstUser
                     pass = $firstPassword
                     sku = 'Trial'
                  }
$environments += @{
                     name = 'DevFeature1'
                     user = $secondUser
                     pass = $secondPassword
                     sku = 'Trial'
                  }
$environments += @{
                     name = 'TestFeature1'
                     user = $thirdUser
                     pass = $thirdPassword
                     sku = 'Trial'
                  }
$environments += @{
                     name = 'DevFeature2'
                     user = $forthUser
                     pass = $forthPassword
                     sku = 'Trial'
                  }
$environments += @{
                     name = 'TestFeature2'
                     user = $fithUser
                     pass = $fithPassword
                     sku = 'Trial'
                  }

Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -force
Install-Module -Name Microsoft.PowerApps.PowerShell -AllowClobber -force

foreach ($env in $environments) {
  $securepassword = ConvertTo-SecureString -String $env.pass -AsPlainText -Force
  Add-PowerAppsAccount -Username $env.user -Password $securepassword -Verbose
  $envDev = New-AdminPowerAppEnvironment -DisplayName  $env.name -LocationName $CDSlocation -EnvironmentSku $env.sku -Verbose -WaitUntilFinished $true
  New-AdminPowerAppCdsDatabase -EnvironmentName  $envDev.EnvironmentName -CurrencyName CAD -LanguageName 1033 -Verbose -ErrorAction Continue -WaitUntilFinished $true
}
 