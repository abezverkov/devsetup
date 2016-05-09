# Load posh-git example profile
. 'C:\tools\poshgit\dahlbyk-posh-git-fadc4dd\profile.example.ps1'

# Set prompt
# ======================================================================================================
Rename-Item Function:\Prompt PoshGitPrompt -Force
function Prompt() {if(Test-Path Function:\PrePoshGitPrompt){++$global:poshScope; New-Item function:\script:Write-host -value "param([object] `$object, `$backgroundColor, `$foregroundColor, [switch] `$nonewline) " -Force | Out-Null;$private:p = PrePoshGitPrompt; if(--$global:poshScope -eq 0) {Remove-Item function:\Write-Host -Force}}PoshGitPrompt}

# Above this line was added by PoshGit

# Set my config preferences
# ======================================================================================================
git config --global push.default current
git config --global pull.rebase true

#perf test ... https://github.com/msysgit/msysgit/wiki/Diagnosing-why-Git-is-so-slow
git config --global core.preloadindex true
git config --global core.fscache true
git config --global gc.auto 256

# Interesting things in Posh-Git
# $Global:GitPromptSettings
$Global:GitPromptSettings.EnableStashStatus = $false

# Program shortcuts
# ======================================================================================================
$env:USERDOWNLOADS = "${env:USERPROFILE}\Downloads"
$env:USERDOCUMENTS = "${env:USERPROFILE}\Documents"
$env:VSPATH120 = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE"

function downloads { Set-Location "${env:USERPROFILE}\Downloads" }
function manage { .'compmgmt.msc'}
function sublime { ."${env:ProgramFiles}\Sublime Text 3\sublime_text.exe" $args }
function bash { ."${env:ProgramFiles}\Git\bin\sh.exe" $args }
function reload { start powershell; exit; }
function qx { ."${env:ProgramFiles(x86)}\QueueExplorer Professional\QueueExplorer.exe" }
function vs { 
    # clear cache before starting vs
	del "${env:LOCALAPPDATA}\Microsoft\WebSiteCache\*" -Recurse -Force
	del "${env:LOCALAPPDATA}\Temp\Temporary ASP.NET Files\*" -Recurse -Force
	start "${env:VSPATH120}\devenv.exe"
}

$updateServices = "bits","wuauserv"
function Stop-Updates { $updateServices | Stop-Service -PassThru }
function Start-Updates { $updateServices | Start-Service -PassThru }

# Import local network shortcts
# ======================================================================================================
."${env:USERDOCUMENTS}\WindowsPowershell\LocalNetwork_profile.ps1"

# Module Imports
# ======================================================================================================
Import-Module CustomPoshGit

