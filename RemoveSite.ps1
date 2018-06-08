$tenant = "M365x391807";
$userName = "admin@M365x391807.onmicrosoft.com" ; # TODO add your user name
$tenantSiteurl = "https://{0}-admin.sharepoint.com/" -f $tenant # Tenant Admin URL  

$userCrendential = Get-Credential -Message "Enter SPO credentials" -UserName $userName
$adminConn = Connect-PnPOnline -Url $tenantSiteurl -Credentials $userCrendential -ReturnConnection


$site = read-host $("Please enter your site url {0} :" -f $tenantSiteurl)
$webUrl = "https://{0}.sharepoint.com/sites/{1}" -f $tenant, $site;
Write-Host $("Checking to {0}" -f $webUrl);

Write-Host $("Connecting to {0}" -f $tenantSiteurl);

$IsSiteCollExists = ([bool] (Get-PnPTenantSite -Url $webUrl -Connection $adminConn -ErrorAction SilentlyContinue) -eq $true)

if ( $IsSiteCollExists -eq $true )
{

    $message = $("Are you sure you want to delete {0} [y/n]" -f $webUrl)
    $confirmation = Read-Host $message
    while ($confirmation -ne "y")
    {
        if ( $confirmation -eq 'n' ) {exit}
        $confirmation = Read-Host $message
    }
    Write-Output $("Deleting {0}..." -f $webUrl)
    Remove-PnPTenantSite -Url $webUrl -Connection $adminConn -Force -SkipRecycleBin -Verbose -Wait
    Write-Output $("Site {0} is deleted..." -f $webUrl)
}
else
{
    Write-Host $("{0} site does not exist." -f $webUrl);
}
