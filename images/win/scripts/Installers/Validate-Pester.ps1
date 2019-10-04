# Validate the installation
$env:PSModulePath = Get-SystemVariable "PSModulePath"
$modules = Get-Module -Name Pester -ListAvailable
Write-Host "The Pester Modules present are:"
$modules | Select-Object Name,Version,Path | Format-Table

if ($modules) {
    $pesterVersion = $modules.Version
}


# Adding description of the software to Markdown
$SoftwareName = "Pester"

$Description = @"
_Version:_ $pesterVersion
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description