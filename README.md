## Welcome to Auto Site Provisioning Solution for SharePoint Online (SPO)

A Site Provisioning solution is a number one asks from the customer. Multiple variations of such solution can be implemented based on the customer needs. With no surprise, the first request for our customer was to track the sites requested, approval workflow of the request, automation of the creation of the site, applying unique template, automating governance, controlling the quotas based on the requestor need, etc. We have looked in to [PnP Partner Pack solution](https://github.com/SharePoint/PnP-Partner-Pack) but that was not meeting the needs of the customer. We have looked at other approach to deliver the customer requirement using very simple OOTB components with no code solution. Our customer did not have Flow and PowerApps in their tenant. Such limitation made us create this solution with SPD workflow which we think can be useful to your customer now or in the future.  

### Prerequesits

- [PnP PowerShell Module](https://github.com/SharePoint/PnP-PowerShell)

### Components for the solution
- Three Lists
- Two SharePoint Workflows 
- One PnP PowerShell Script

### Deployement steps

```markdown

1. Clone this repo to your local drive.

2. Create a site in your tenant as following.
https://{your_tenant_name}.sharepoint.com/sites/siteprovisioning/

3. Run CreateSiteProvisioningArtifacts.ps1 PowerShell 

4. Run EmailConfigDataImport.ps1

5. In the list update the values as needed.
```

>Refer to O356SiteProvisioningDeploymentGuide.docx document for inside details.
