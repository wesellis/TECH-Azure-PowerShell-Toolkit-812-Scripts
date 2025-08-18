# 💰 Azure Enterprise Toolkit - Money Process Checklist

## PowerShell Gallery Publishing
- [ ] Create account: https://www.powershellgallery.com/
- [ ] Get API key: ________________
- [ ] Prepare modules for publishing:
  - [ ] Az.Accounts.Enterprise
  - [ ] Az.Resources.Enterprise  
  - [ ] Az.Storage.Enterprise
  - [ ] Az.KeyVault.Enterprise
- [ ] Update module manifests with:
  - [ ] Author info
  - [ ] Company: "WesEllis"
  - [ ] Project URI (GitHub)
  - [ ] License URI
- [ ] Publish command: `Publish-Module -Name ModuleName -NuGetApiKey "key"`

## GitHub Sponsors
- [ ] Already in FUNDING.yml
- [ ] Enable at: https://github.com/sponsors
- [ ] Create tiers:
  - [ ] $5/mo - Priority issues
  - [ ] $25/mo - Feature requests
  - [ ] $100/mo - Custom modules

## Donation Options
- [ ] Buy Me a Coffee: https://buymeacoffee.com
- [ ] Ko-fi: https://ko-fi.com
- [ ] Add donation links to:
  - [ ] README.md
  - [ ] Module help files
  - [ ] GitHub releases

## Consulting/Support Model
- [ ] Create "Enterprise Support" offering
- [ ] Price: $500/month
- [ ] Includes:
  - [ ] Priority support
  - [ ] Custom scripts
  - [ ] Architecture reviews
  - [ ] Implementation help

## Marketing
- [ ] Post modules on r/PowerShell
- [ ] LinkedIn articles
- [ ] PowerShell.org forums
- [ ] Twitter #PowerShell community
- [ ] Dev.to articles

## Documentation
- [ ] Create landing page
- [ ] Record demo videos
- [ ] Write blog posts
- [ ] Case studies

## Revenue Tracking
- [ ] PowerShell Gallery downloads: ________________
- [ ] GitHub sponsors: ________________
- [ ] Donations received: ________________
- [ ] Consulting leads: ________________

## Automation
PowerShell Gallery has CLI:
```powershell
# Publish all modules
Get-ChildItem -Path .\modules -Directory | ForEach-Object {
    Publish-Module -Path $_.FullName -NuGetApiKey $apiKey
}
```

## Notes/Issues:
_Edit this section with progress_