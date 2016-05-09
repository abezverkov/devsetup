if ((gcm choco.exe -ErrorAction SilentlyContinue) -eq $null)
{
	iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

cinst poshgit -y
cinst 7zip -y
cinst rdcman -y
cinst pscx -y
cinst sublimetext3 -y
cinst SublimeText3.PackageControl -y
cinst sublimetext3.powershellalias -y
cinst linqpad4 -y
cinst foxitreader -y

cinst firefox -y
cinst chrome -y
cinst fiddler4 -y
cinst wireshark -y
cinst putty -y

cinst treesizefree -y
cinst sysinternals -y
cinst ccleaner -y
cinst jing -y

cinst slack -y
cinst skype -y
cinst ncrunch-vs2013 -y

cinst vcredist2010 -y
cinst soapui -y

#choco install sqlserver2012express
#choco install sqlsentryplanexplorer
#choco install planexplorerssmsaddin
#choco install queueexplorer-professional

