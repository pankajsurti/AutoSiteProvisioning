
<#
.SYNOPSIS
    This following script is to create site columns for the site provisioning solution.
    The script relies on the input file XML file with the fields information.
.DESCRIPTION
    A detailed description of the function or script. 
    The script used the PnP PowerShell module. To run the script you need to modify the tenant name.
.NOTES
    File Name      : CleanUp.ps1
    Author         : Pankaj Surti 
    Prerequisite   : https://github.com/SharePoint/PnP-PowerShell

.LINK


.EXAMPLE
    Example 1
.EXAMPLE
    Example 2
#>

$tenant = "M365x391807";
$provisiningSite = "/sites/siteprovisioning";
$webUrl = "https://{0}.sharepoint.com{1}/" -f $tenant, $provisiningSite;
Write-Output $("Connecting to {0}" -f $webUrl);
$userCrendential = Get-Credential -Message "Enter SPO credentials" -UserName "admin@M365x391807.onmicrosoft.com"
$connSitePvr = Connect-PnPOnline -Credentials $userCrendential -Url $webUrl  -ReturnConnection 

$listNames = @("MasterSiteInventory", "EmailConfigurationStore", "SiteProvisioningConfiguration")
foreach ($element in $listNames) {
	
    Remove-PnPList -Identity $element -Force -Connection $connSitePvr
    write-host "Removed list " $element
}


$localScriptRoot = $PSScriptRoot

Remove-PnPContentType -Identity "MasterSiteInventoryCT" -Force -Connection $connSitePvr
write-host "Removed content type " "MasterSiteInventoryCT"


$fieldsXML = [xml] (Get-Content ($localScriptRoot + "\ProvisiningDataFiles\SiteColumns.xml"));

$fieldsXML.Fields.Field | ForEach-Object {

#Configure core properties belonging to all column types
    Remove-PnPField -Identity $_.ID -Force -Connection $connSitePvr
    write-host "Removed site column" $_.DisplayName " ID " $_.ID
}
