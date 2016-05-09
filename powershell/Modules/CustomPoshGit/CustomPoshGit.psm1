# dynamic export
function export
{
    param (
        [parameter(mandatory=$true)] [validateset("function","variable")] $type,
        [parameter(mandatory=$true)] $name,
        [parameter(mandatory=$true)] $avalue
    )

    #Write-Host "$type , $name"
    if ($type -eq "function")
    {
        Set-item "function:script:$name" $avalue
        Export-ModuleMember $name
    }
    if ($type -eq "workflow")
    {
        Set-item "workflow:script:$name" $avalue
        Export-ModuleMember $name
    }
    else
    {
        Set-Variable -scope Script $name $avalue
        Export-ModuleMember -variable $name
    }
}

# Create git shortcuts
# ======================================================================================================
export function stat { git status $args }
export function stash { git stash $args }
export function co { git checkout $args }
export function commit { git commit $args }
export function undo { git checkout -- $args }
export function reset { git reset --soft HEAD~1 }
export function prune { git fetch --all --prune $args }
export function prune_local { co master; (git branch -vv).Trim() -match ': gone' | %{ $_.Split(' ')[0] } | %{ git branch -d $_ } }
export function local { 
    if ($args.Length -eq 0) {
        # git log --stat '@{u}..HEAD' #HEAD is optional/implied, @{u} is upstream
        git log --stat '@{push}..' # @{push} is the last commit pushed regardless of where it was pushed
    }
    else {
        git log --stat $args
    }
}

export function Show { GitRepoAction "Show" { } }
export function ShowStash { GitRepoActionDetails "ShowStash" { git stash list; } }
export function SetStashCount { param ([parameter(mandatory=$true)] [bool] $enabled) $Global:GitPromptSettings.EnableStashStatus = $enabled; }

export function CheckOutAll { param ([parameter(mandatory=$true)] [string] $branch) GitRepoAction "CheckOut" { if ($branch -ne (GetBranch)) {git checkout $branch -q;} } }
set-alias coa CheckOutAll;

export function Fetch { GitRepoAction "Fetching" { git fetch -apq; } }
export function Push { GitRepoActionDetails "Push" { git push; } }
export function Pull { GitRepoActionDetails "Pull" { git pull; } }
export function PullBranch { 
    param ([parameter(mandatory=$true)] [string] $Branch) 
    GitRepoActionDetails "CheckOutPull" { 
        git checkout $Branch -q; 
        $currentBranch = GetBranch;
        if ($currentBranch -eq $Branch) {
            git pull; 
        }
    } 
}
export function Merge { 
    param ([parameter(mandatory=$true)] [string] $Source) 
    GitRepoActionDetails "Merge" { 
        $currentBranch = GetBranch;
        if ($Source -ne $currentBranch) { 
            git merge $Branch;
        } 
    } 
}
export function UpdateBranch { 
    param ([parameter(mandatory=$true)] [string] $Branch, [string] $Source = 'master') 
    PullBranch $Source; 
    PullBranch $Branch; 
    Merge $Source; 
    show; 
}

# ======================================================================================================
# Git Helpers 
# ======================================================================================================
function GetBranch([string]$refhead) {
    if ($refhead -eq $null -or $refhead.Trim() -eq '') {
        $refhead = git symbolic-ref HEAD
    }
    $refhead.Replace('refs/heads/', '')
}

function NeedsUpdate {
    $localCommit = git rev-list --all -n1;
    $remoteCommit = (git ls-remote origin GetBranch) -replace '\s.*$'
    $localCommit -ne $remoteCommit
}

function GetRefHeads {
    git for-each-ref --format='%(refname:short):%(upstream:short)' refs/heads
}

function GetRefHeadsFilterUpstream {
    param (
        [parameter(mandatory=$true)] [bool] $hasUpstream
    )

    if ($hasUpstream) {
        GetRefHeads | % { ,$_.Split(':') } | ? { $_[1] -ne '' } | % { $_[0] }
    }
    else {
        GetRefHeads | % { ,$_.Split(':') } | ? { $_[1] -eq '' } | % { $_[0] }
    }
}

function GetRemoteMerged {
    $refs = GetRefHeadsFilterUpstread($true)
    $merges = (git branch --merged).Trim()
    $refs | ? { $merges -contains $_ }
}

function ConvertToDir($path) {
    try {
        if ($path -eq '' -or $path -eq $null -or -not(Test-Path $path)) { return ''; }
        $path = Resolve-Path $path;
        if ((Get-Item $path) -is [System.IO.DirectoryInfo])
        {
        	return $path
        }
        else
        {
        	return (Resolve-Path ((Get-Item $path).Directory))
        }
    }
    catch { return ''; }
}

function HasGitDir($dir) {
    $dir = ConvertToDir($dir)
    $gitDir = Join-Path $dir .git 
    $hasGit = (Test-Path $gitDir);
    return $hasGit;
}

function FindGitDirDown($dir) {
    $gitDirs = @();
    if ($dir -eq '' -or $dir -eq $null) { return $getDirs; }

    $dir = ConvertToDir($dir)
    if (HasGitDir($dir)){
        $gitDirs += (Resolve-Path $dir);
        return $gitDirs;
    }
    else
    {
        Get-ChildItem $dir -Directory | % { $gitDirs += FindGitDirDown($_.FullName); }
        return $gitDirs;
    }
}

function FindGitDirUp($dir) {
    $gitDirs = @();
    if ($dir -eq '' -or $dir -eq $null) { return $getDirs; }

    $dir = ConvertToDir($dir)
    if (HasGitDir($dir)){
        $gitDirs += (Resolve-Path $dir);
        return $gitDirs;
    }
    else
    {
        $dir | Get-Item | % { $gitDirs += FindGitDirUp($_.Parent.FullName); }
        return $gitDirs;
    }
}

function FindGitDirs($dir) {
    if ($dir -eq $null -or $dir -eq '') { $dir = Resolve-Path . }
    $gitDirs = FindGitDirUp($dir);
    if ($gitDirs -ne $null -and $gitDirs.Count -gt 0) { return $gitDirs; }
    if ($Global:GitRepos) {return $Global:GitRepos;}
    $Global:GitRepos = FindGitDirDown($dir);
    return $Global:GitRepos;
}

function GitRepoAction {
    Param(
        [parameter(Mandatory)][string]$DispayName,
        [parameter(Mandatory)][scriptblock]$Action
    )

    $origin = Get-Location
    Write-Host ''
    $gitDirs = FindGitDirs('.');    
    Write-Host "=============== $DispayName Git Directories ==============="
    $gitDirs | % { 
        Set-Location $_
        $Action.InvokeReturnAsIs();
        $gitStatus = Get-GitStatus;
        PrintDetails "$DispayName $_ " $gitStatus;
    }
    Write-Host ''   
    Set-Location $origin
}

function GitRepoActionDetails {
    Param(
        [parameter(Mandatory)][string]$DispayName,
        [parameter(Mandatory)][scriptblock]$Action
    )

    $origin = Get-Location
    Write-Host ''
    Write-Host "=============== $DispayName Git Directories ==============="
    $gitDirs = FindGitDirs('.');    
    $gitDirs | % { 
        Set-Location $_
        Write-Host ''
        Write-Host "$DispayName $_ ";
        Write-Host "--------------------------------------------------------";
        $Action.InvokeReturnAsIs();
        $gitStatus = Get-GitStatus;
        PrintDetails "$DispayName $_ " $gitStatus;
    }
    Write-Host ''
    Set-Location $origin
}

function PrintDetails([string]$details, $gitStatus)
{
    Write-Host -NoNewline $details; Write-GitStatus($gitStatus); Write-Host '';
}

Export-ModuleMember -alias *