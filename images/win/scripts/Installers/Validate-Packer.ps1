################################################################################
##  File:  Validate-Docker.ps1
##  Team:  National Careers Service
##  Desc:  Validate Docker.
################################################################################


if((Get-Command -Name 'packer'))
{
    Write-Host "packer $(packer version) on path"
}
else
{
     Write-Host "packer is not on path"
    exit 1
}

# Adding description of the software to Markdown
$SoftwareName = "Packer"

$version = $(packer --version)

$Description = @"
_Version:_ $version<br/>
_Environment:_
* PATH: contains location of docker.exe
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

