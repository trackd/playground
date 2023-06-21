
function Set-HelpspotEndpointhelper {
    Register-ArgumentCompleter -CommandName Invoke-HelpspotApi,Get-HelpspotAPIHelp -ParameterName ApiEndpoint -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        $script:apidefinition.keys | Where-Object { $_ -like "*$wordToComplete*" } | ForEach-Object {
            return [System.Management.Automation.CompletionResult]::new(
                $_,
                $_,
                'ParameterValue',
                $_
            )
        }
    }
}
