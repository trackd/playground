function Set-ChannelAutoCompleter {
    Register-ArgumentCompleter -CommandName Get-Tv -ParameterName Channel -ScriptBlock {
        (Invoke-RestMethod -Uri https://web-api.tv.nu/packages/allChannels).Data.Name | ForEach-Object { "'$_'" }
    }
}