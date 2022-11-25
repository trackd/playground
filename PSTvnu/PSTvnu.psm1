$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue -Recurse)

Foreach ($file in @($Public + $Private)) {
    Try {
        . $file.fullname
    } Catch {
        Write-Error "ERROR $($error[0].exception.message)"
    }
}

Export-ModuleMember -Function * -Alias *

#Register autocomplete
Set-ChannelAutoCompleter

#update channellist
Get-ChannelID
