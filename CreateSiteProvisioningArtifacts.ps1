
<#
.SYNOPSIS
    This following script is to create site columns for the site provisioning solution.
    The script relies on the input file XML file with the fields information.
.DESCRIPTION
    A detailed description of the function or script. 
    The script used the PnP PowerShell module. To run the script you need to modify the tenant name.
.NOTES
    File Name      : CreateSiteProvisioningArtifacts.ps1
    Author         : Pankaj Surti
    Prerequisite   : https://github.com/SharePoint/PnP-PowerShell

.LINK


.EXAMPLE
    Example 1
.EXAMPLE
    Example 2
#>
# define variables
$tenant = "M365x391807"; # TODO add your tenant
$userName = "admin@M365x391807.onmicrosoft.com" ; # TODO add your user name
$provisiningSite = "/sites/siteprovisioning";

$webUrl = "https://{0}.sharepoint.com{1}/" -f $tenant, $provisiningSite;
Write-Output $("Connecting to {0}" -f $webUrl);
$userCrendential = Get-Credential -Message "Enter SPO credentials" -UserName $userName
$connSitePvr = Connect-PnPOnline -Credentials $userCrendential -Url $webUrl  -ReturnConnection 

$localScriptRoot = $PSScriptRoot

# create content type
$ctFilePath = ($localScriptRoot) + "\ProvisiningDataFiles\SiteProvisioningArtifacts.xml";
Apply-PnPProvisioningTemplate -Path $ctFilePath -Connection $connSitePvr
write-host "Created all artifacts... " 
