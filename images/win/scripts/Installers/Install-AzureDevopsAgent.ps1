################################################################################
##  File:  Install-AzureDevopsAgent.ps1
##  Team:  National Careers Service
##  Desc:  Install Azure Devops Agent.
################################################################################

Write-Host "Install and configure Azure Devops build agent"

$PatToken = $env:PatToken
$VstsBaseUrl = $env:AzureDevopsBaseUrl
$AgentName = $env:AgentName
$AgentPool = $env:AgentPool

function GetRandomPassword {
    $sourceChars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$^&(){}[],.'
    $max = $sourceChars.Length
    $result = ''
    for ($i = 0; $i -lt 20; $i += 1) {
        $index = Get-Random -Minimum 0 -Maximum $max
        $c = $sourceChars[$index]
        $result += $c
    }

    return $result
}

function Get-BasicHeader {
    param(
        [string] $Token
    )

    # Construct authorization header for Azure DevOps REST API
    $PATenc = [System.Text.Encoding]::ASCII.GetBytes(':' + $Token)
    $PATenc = [System.Convert]::ToBase64String($PATenc)
    return @{ Authorization = "Basic $PATenc" }
}

Write-Host "Creating new user for agent to run as"

$serviceUserName = 'svcBuild'
$servicePassword = GetRandomPassword
$serviceSecurePassword = ConvertTo-SecureString $servicePassword -AsPlainText -Force
$args = @{
    Name = $serviceUserName
    Password = $serviceSecurePassword
    FullName = 'BuildService'
    AccountNeverExpires = $true
    PasswordNeverExpires = $true
}
$serviceUser = New-LocalUser @args
$administratorsGroup = Get-LocalGroup -Name 'Administrators'
Add-LocalGroupMember -Group $administratorsGroup -Member $serviceUser
Write-Output 'Created user svcBuild'

Write-Host "Creating build directory"

New-Location -Path "C:\BuildHome" -ItemType Directory
Push-Location
Set-Location -Path "C:\BuildHome"

Write-Host "Searching for agent to download"

$headers = Get-BasicHeader -Token $PatToken

# Automatically detect Azure DevOps agent download URL
Write-Output "Searching for Azure DevOps download URL."
$url = $VstsUrl + '_apis/distributedtask/packages/agent?platform=win-x64'
$response = Invoke-WebRequest -Uri $url -UseBasicParsing -Headers $headers
$packages = ConvertFrom-Json -InputObject $response.Content
$packages = $packages.value | Sort-Object -Property @({ $_.version.major }, { $_.version.minor }, { $_.version.patch }) -Descending
$package = $packages | Select-Object -First 1
$VSTSAgentUrl = $package.downloadUrl

Write-Output "Azure DevOps agent URL: $VSTSAgentUrl"

$vstsAgentZipPath = "vsts-agent.zip"
Invoke-WebRequest -Uri $VSTSAgentUrl -UseBasicParsing -OutFile $vstsAgentZipPath
Write-Output 'Downloaded vsts-agent.zip'

# Unzip VSTS Agent
$buildFolder = New-Item -Path 'Build' -ItemType Directory
Expand-Archive -Path $vstsAgentZipPath -DestinationPath $buildFolder.FullName
Set-Location $buildFolder.FullName
Write-Output 'Extracted vsts-agent.zip'

$serviceUserQualifiedName = ".\$serviceUserName"
& .\config.cmd --unattended  --url "`"$VstsBaseUrl`"" --auth pat --token "`"$PatToken`"" --pool "`"$AgentPool`"" --agent "`"$AgentName`"" --runAsService --windowsLogonAccount "`"$serviceUserQualifiedName`"" --windowsLogonPassword "`"$servicePassword`""
Write-Output 'VSTS Build Agent configured.'

Pop-Location