################################################################################
##  File:  Validate-Rust.ps1
##  Team:  CI-X
##  Desc:  Verify that Rust is on the path and output version information.
################################################################################

$RustPath = "$env:userprofile\.cargo\bin"
$env:Path = $RustPath + ";" + $env:Path
$RustcVersion = $(rustc --version)

if (Get-Command -Name 'rustc')
{
    Write-Host "$RustcVersion is on the path"
}
else
{
    Write-Host "rustc is not on the path"
    
    exit 1
}

$RustcVersion -Match "\d+\.\d+\.\d+" | out-null
$Version = $Matches[0]

# Adding description of the software to Markdown
$SoftwareName = "Rust (64-bit)"

$Description = @"
#### $Version
_Location:_ $RustPath
_Environment:_
* PATH: contains the location of rustc.exe
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
