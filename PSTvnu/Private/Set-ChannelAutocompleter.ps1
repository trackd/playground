function Set-ChannelAutoCompleter {
    Register-ArgumentCompleter -CommandName Get-Tv -ParameterName Channel -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        (Get-ChannelID).keys | Where-Object { $_ -like "*$wordToComplete*" } | ForEach-Object {
            if ($_.contains(' ')) {
                #handle stuff with spaces in them.
                return [System.Management.Automation.CompletionResult]::new(
                    """$_""",
                    $_,
                    'ParameterValue',
                    $_
                )
            } else {
                return [System.Management.Automation.CompletionResult]::new(
                    $_,
                    $_,
                    'ParameterValue',
                    $_
                )
            }
        }
    }
}
