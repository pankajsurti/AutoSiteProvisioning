function Write-Log
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path='C:\Logs\PowerShellLog.log',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level="Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        
        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
                }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
                }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
                }
            }
        
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
        ## also dump to console
        #$savedColor = $host.UI.RawUI.ForegroundColor 
        #$host.UI.RawUI.ForegroundColor = "DarkGreen"
        Write-Output  $message 
        #$host.UI.RawUI.ForegroundColor = $savedColor
    }
    End
    {
    }
}

function Check-MasterSiteRecoveryRequestStatus
{
    begin
    {
        $LogFileName = $("{0}\Log-{1}.txt" -f $env:LOG_FILE_PATH , (Get-Date -Format "yyyy-MM-dd"))
        $tenant = "$env:TENANT_NAME";
        $localTemplatesFolder = "${env:HOME}\site\wwwroot\SiteProvisioning\"
        $provisiningSite = "/sites/siteprovisioning";
        $webUrl = "https://{0}.sharepoint.com{1}/" -f $tenant, $provisiningSite;
        $requestStatu2Check = "Approved"
        $strQuery = "<View><Query><Where><Eq><FieldRef Name='RequestStatus' /><Value Type='Text'>" + $requestStatu2Check + "</Value></Eq></Where></Query></View><ViewFields><FieldRef Name='SiteDescription' /><FieldRef Name='SiteRelativeUrl' /><FieldRef Name='PrimarySiteOwner' /><FieldRef Name='SecondarySiteOwner' /><FieldRef Name='SiteRegion' /><FieldRef Name='RequestStatus' /><FieldRef Name='hiddenRequestStatus' /><FieldRef Name='Title' /></ViewFields>"
        $blue = "DarkBlue-Blue.xml"
        $lightgrey = "DarkBlue-LightGrey.xml"
        $medgrey = "DarkBlue-MedGrey.xml"
    }
    process
    {
        Write-Log -Path $LogFileName " *************************************** Start  *************************************** "
        Write-Log -Path $LogFileName $("Connecting to {0}" -f $webUrl);
        $conn = Connect-PnPOnline -AppId $env:SP_APP_ID -AppSecret $env:SP_APP_SECRET -Url $webUrl  -ReturnConnection 
        [array]$items = Get-PnPListItem -Connection $conn -List "MasterSiteInventory” -Query $strQuery | %{New-Object psobject -Property @{Id = $_.Id; RequestStatus = $_["RequestStatus"];PrimarySiteOwner = $_["PrimarySiteOwner"]; SecondarySiteOwner = $_["SecondarySiteOwner"]; SiteRelativeUrl = $_["SiteRelativeUrl"]; Title = $_["Title"]; SiteDescription = $_["SiteDescription"]; hiddenRequestStatus = $_["hiddenRequestStatus"]; SiteTemplate = $_["SiteTemplate"]; StorageQuotaInGB = $_["StorageQuotaInGB"]; }} | select ID, RequestStatus,PrimarySiteOwner,SiteRelativeUrl,Title,SecondarySiteOwner,hiddenRequestStatus,SiteDescription,SiteTemplate,StorageQuotaInGB
        if ( ($items -ne $null) -and ($items.Count -gt 0) )
        {
            Write-Log -Path $LogFileName $("There are {0} {1} RequestStatus on MasterSiteInventory list." -f $items.Count, $requestStatu2Check);
            foreach ($item in $items)
            {
                if ( $item.RequestStatus -eq "Approved" )
                {
                    $TemplatePath = "TeamTemplate"
                    $BaseSiteTemplate = "PROJECTSITE#0"
                    if ( $item.SiteTemplate -eq "Team Site" )
                    {
                        $TemplatePath = "TeamTemplate"
                        $BaseSiteTemplate = "STS#0"
                    } 
                    elseif ( $item.SiteTemplate -eq "Project Site" )
                    {
                        $TemplatePath = "ProjectTemplate"
                        $BaseSiteTemplate = "PROJECTSITE#0"
                    } 
                    else
                    {
                        # Since the site is not set 
                        Set-PnPListItem -Connection $conn -List "MasterSiteInventory" -Identity $item.Id -Values @{ "SiteTemplate"= "Tea Site"} 
                    }
                    # prefix the path with abosolute path
                    $TemplatePath = $localTemplatesFolder + $TemplatePath

                    Write-Log -Path $LogFileName $("Setting RequestStatus to CreatingSite for Item Id = {0}." -f $item.Id);
                    Set-PnPListItem -Connection $conn -List "MasterSiteInventory" -Identity $item.Id -Values @{ "RequestStatus"= "CreatingSite"; }
                    $newSiteUrl = "https://{0}.sharepoint.com/sites/{1}" -f $tenant, $item.SiteRelativeUrl;
                    try
                    {

                        $adminWebUrl = "https://{0}-admin.sharepoint.com/" -f $tenant
                        Write-Log -Path $LogFileName $("Connecting to {0}" -f $adminWebUrl);
                        $adminConn = Connect-PnPOnline -Url $adminWebUrl  -AppId $env:SP_APP_ID -AppSecret $env:SP_APP_SECRET -ReturnConnection 
                        Write-Log -Path $LogFileName $("Connected to {0}" -f $adminWebUrl);

                        # check the storage quota for null, if it is default to 500 GB
                        if ( $item.StorageQuotaInGB -eq $null ) {
                            $item.StorageQuotaInGB = 500;
                        }

                        Write-Log -Path $LogFileName $("Please wait creating the site {0} for {1}" -f $newSiteUrl, $item.PrimarySiteOwner.Email);
                        $aNewSite = New-PnPTenantSite -Connection $adminConn -Description $item.SiteDescription -url $newSiteUrl  -Owner $item.PrimarySiteOwner.Email -Title $item.Title -Lcid 1033 -TimeZone 11 -Template $BaseSiteTemplate -StorageQuota ($item.StorageQuotaInGB * 1024) -RemoveDeletedSite -Verbose -Wait -Force -ErrorAction Stop
                        Write-Log -Path $LogFileName $("Created the site  {0}" -f $newSiteUrl);

                        Write-Log -Path $LogFileName  $("Connecting to newly created site : {0}" -f $newSiteUrl);
                        $newSiteConn = Connect-PnPOnline -Url $newSiteUrl  -AppId $env:SP_APP_ID -AppSecret $env:SP_APP_SECRET -ReturnConnection 

                        Write-Log -Path $LogFileName $("Setting owners to {0}" -f $newSiteUrl);
                        Set-PnPTenantSite -Url $newSiteUrl -Owners $item.PrimarySiteOwner.Email, $item.SecondarySiteOwner.Email -Connection $adminConn -Wait

                        # apply the template

                        $TemplateFile = $TemplatePath + "\" + $lightgrey;
                        Write-Log -Path $LogFileName  $("Apply {0} template to {1}" -f $TemplateFile, $newSiteUrl);
                        Apply-PnPProvisioningTemplate -path $TemplateFile -Connection $newSiteConn 
                        $TemplateFile = $TemplatePath + "\" + $medgrey;
                        Write-Log -Path $LogFileName  $("Apply {0} template to {1}" -f $TemplateFile, $newSiteUrl);
                        Apply-PnPProvisioningTemplate -path $TemplateFile -Connection $newSiteConn 
                        $TemplateFile = $TemplatePath + "\" + $blue;
                        Write-Log -Path $LogFileName  $("Apply {0} template to {1}" -f $TemplateFile, $newSiteUrl);
                        Apply-PnPProvisioningTemplate -path $TemplateFile -Connection $newSiteConn 


                        Write-Log -Path $LogFileName $("Setting RequestStatus to SiteCreated AND hiddenRequestStatus to Trigger for Item Id = {0}." -f $item.Id);
                        Set-PnPListItem -Connection $conn -List "MasterSiteInventory" -Identity $item.Id -Values @{ "RequestStatus"= "SiteCreated"; "hiddenRequestStatus" = "Trigger"; } 

                        Write-Log -Path $LogFileName  $("Success creating the site {0}" -f $newSiteUrl);
                    }
                    catch
                    {
                        Write-Log -Path $LogFileName -Level Error $("Failed creating the site {0}" -f $newSiteUrl);
                        Write-Log -Path $LogFileName -Level Error $(“Message: {0} ErrorRecord: {1} StackTrace : {2}” -f $_.Exception.Message, $_.Exception.ErrorRecord, $_.Exception.StackTrace)
                        Write-Log -Path $LogFileName $("Setting RequestStatus to Error AND hiddenRequestStatus to Trigger for Item Id = {0}." -f $item.Id);
                        Set-PnPListItem -Connection $conn -List "MasterSiteInventory" -Identity $item.Id -Values @{ "RequestStatus"= "Error"; "hiddenRequestStatus" = "Trigger"; }

                    }
                    finally
                    {
                        Write-Log -Path $LogFileName $("Disconnecting to {0}" -f $adminWebUrl);
                        Disconnect-PnPOnline -Connection $adminConn
                        Write-Log -Path $LogFileName $("Disconnected to {0}" -f $adminWebUrl);
                    }

                }
            }
        }
        else
        {
            Write-Log -Path $LogFileName $("There are no {0} RequestStatus on MasterSiteInventory list." -f $requestStatu2Check);
        }
        Write-Log -Path $LogFileName $("Disconnecting to {0}" -f $webUrl);
        Disconnect-PnPOnline -Connection $conn
        Write-Log -Path $LogFileName $("Disconnected to {0}" -f $webUrl);

        Write-Log -Path $LogFileName " ***************************************  End   *************************************** "
    }
    end
    {
        return;
    }
}
Check-MasterSiteRecoveryRequestStatus
