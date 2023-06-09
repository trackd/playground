#Requires -Version 5.1
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue -Recurse)

Foreach ($file in @($Public + $Private)) {
    Try {
        . $file.fullname
    } Catch {
        throw $PSItem
    }
}

Export-ModuleMember -Function * -Alias *

#update channellist
Get-ChannelID

#Register autocomplete for Get-Tv -Channel <autocomplete>
Set-ChannelAutoCompleter
