if ((gcm choco.exe -ErrorAction SilentlyContinue) -eq $null)
{
	iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

cinst poshgit -y
cinst 7zip -y

#cinst rdcman -y #not supported anymore

cinst sublimetext3 -y
#cinst SublimeText3.PackageControl -y #broken?
cinst sublimetext3.powershellalias -y
cinst linqpad -y --ignorechecksum
cinst foxitreader -y
cinst markdownmonster -y

cinst firefox -y
cinst chrome -y
cinst fiddler -y
cinst wireshark -y
cinst putty -y

cinst treesizefree -y
cinst sysinternals -y
cinst ccleaner -y
#cinst jing -y

cinst slack -y
#cinst skype -y
cinst ncrunch-vs2019 -y

cinst ssms -y

cinst vscode -y
cinst azure-data-studio -y
cinst microsoftazurestorageexplorer -y

cinst docker-desktop -y #needs restart

#choco install sqlsentryplanexplorer
#choco install planexplorerssmsaddin
#choco install queueexplorer-professional

Install-Module -Name Pscx -AllowClobber
