# . $psScriptRoot\Private\Update-ChannelList.ps1
# . $psScriptRoot\Private\Get-ChannelID.ps1
# . $psScriptRoot\Public\Get-Tvnu.ps1
# . $psScriptRoot\Public\Get-TvnuSport.ps1

$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue -Recurse)

Write-Host "Private $($Private.count) / Public $($public.Count)"
Foreach ($file in @($Public + $Private)) {
    Write-Host "iterating $($file)"
    Try {
        . $file.fullname
    } Catch {
        Write-Error "ERROR $($error[0].exception.message)"
    }
}

Export-ModuleMember -Function * -Alias *