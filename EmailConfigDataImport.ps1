
$tenant = "M365x391807";
$userName = "admin@M365x391807.onmicrosoft.com" ; # TODO add your user name
$provisiningSite = "/sites/siteprovisioning";

$webUrl = "https://{0}.sharepoint.com{1}/" -f $tenant, $provisiningSite;
Write-Output $("Connecting to {0}" -f $webUrl);
$userCrendential = Get-Credential -Message "Enter SPO credentials" -UserName $userName
$connSitePvr = Connect-PnPOnline -Credentials $userCrendential -Url $webUrl  -ReturnConnection 

$localScriptRoot = $PSScriptRoot

# create content type
$csvFile = ($localScriptRoot) + "\ProvisiningDataFiles\EmailConfigData.CSV";

# CSV path/File name
$contents = Import-Csv $csvFile
# SPList name
$list = Get-PnPList -Identity EmailConfigurationStore -Connection $connSitePvr 
#$grp = New-PnPGroup -Title "SiteRequestApprovers" -Description "This is a Site Approvers group" -Connection $connSitePvr
foreach ($row in $contents) {
    $item = Add-PnPListItem -List EmailConfigurationStore
    $item["Title"] = $row.Title;
    $item["Subject"] = $row.Subject;
    $item["Body"] = $row.Body;
    $item.Update();
}

# create content type
$csvFile = ($localScriptRoot) + "\ProvisiningDataFiles\SiteProvisioningConfigData.CSV";

# CSV path/File name
$contents = Import-Csv $csvFile
# SPList name
$list = Get-PnPList -Identity SiteProvisioningConfiguration -Connection $connSitePvr 

foreach ($row in $contents) {
    $item = Add-PnPListItem -List SiteProvisioningConfiguration
    $item["Title"] = $row.Title;
    Write-Output $row.Title
    $item["Approvers"] = $row.Approvers;
    $item["StorageQuotasInGB"] = $row.StorageQuotasInGB;
    $item["SCAGlobalAdmins"] = $row.SCAGlobalAdmins;
    $item["SCAAdminSID"] = $row.SCAAdminSID;
    $item.Update();
}