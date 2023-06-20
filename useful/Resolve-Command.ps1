function Resolve-Command {
    <#
    .DESCRIPTION
    trackd
    .EXAMPLE
    Resolve-Command <CommandName>
    Get-Command <Commmand | Resolve-Command
    shows you the code from the function.
    shows a proxycmd for cmdlets.
    follows aliases to source.
    checks if command matches data from Function:\command (duplicates from modules etc) (testing this out..)
    .PARAMETER Name
    Name of the command you want to see
    Resolve-Command -Name Get-User
    .PARAMETER Object
    pipeline, if you pipe Get-Command <command> to Resolve-Command
    e.g. Get-Command Get-Childitem | Resolve-Command
    will just show more info and attempt to display code
    .PARAMETER Beta
    beta is just testing out the module 'PwshSyntaxHighlight' by Shaun Lawrie for some nicer formatting.
    .NOTES
    maybe shouldn't play around with so many different output streams..
    .LINK
    https://github.com/trackd/Powershell
    #>
    [CmdletBinding()]
    [Alias('which')]
    param(
        [Parameter(Position = 0)]
        [String]
        $Name,
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.CommandInfo]
        $Object,
        [Switch]
        $Beta
    )
    if ($object) {
        $results = $object | Select-Object -First 1
    } elseif ($Name) {
        #get CommandInfo object if it's a name
        $results = Get-Command $name -ErrorAction 'SilentlyContinue'
    }
    if ($results) {
        #if we find results
        while ($results.CommandType -eq 'Alias') {
            Write-Warning "Alias found: $($results.Name) = $($results.definition)"
            #if it's an alias, continue down the rabbit hole til we get something else.
            $results = Get-Command $results.definition
        }
        if ($results.CommandType -eq 'Function') {
            if ($beta) {
                Write-Verbose 'beta'
                $pref = $InformationPreference
                $InformationPreference = 'Continue'
                Write-Information "File: $($results.ScriptBlock.file)"
                Write-Information "Parameters: $($results.ParameterSets)"
                Write-Codeblock $results.ScriptBlock.ast.extent.text -SyntaxHighlight
                $InformationPreference = $pref
            } elseif (-Not $beta) {
                $pref = $InformationPreference
                $InformationPreference = 'Continue'
                Write-Information "File: $($results.ScriptBlock.file)"
                Write-Information "Parameters: $($results.ParameterSets)"
                # Write-Output $($results.ScriptBlock.ast.extent.text)
                Write-Output $results.ScriptBlock.ast.extent.text
                #pansies
                # (New-Text -Object $results.ScriptBlock.ast.extent.text -BackgroundColor Gray34 -ForegroundColor Orange).tostring()
                $InformationPreference = $pref
            }
        } elseif ($results.CommandType -eq 'Cmdlet') {
            #if it's a cmdlet try something but recommend ilspy for dll.
            $pref = $InformationPreference
            $InformationPreference = 'Continue'
            Write-Warning 'This command is a cmdlet, you need ilspy or something similar to decompile the code, output is a proxyfunction'
            Write-Information "File: $($results.DLL)`n"
            Write-Information "Parameters: $($results.ParameterSets)`n"
            Write-Output "function $($results.Name) {"
            $MetaData = [System.Management.Automation.CommandMetaData]::new($results)
            $ProxyCmd = [System.Management.Automation.ProxyCommand]::Create($MetaData)
            $ProxyCmd
            Write-Output '}'
            $InformationPreference = $pref
        } else {
            #else just output all, like for applications.
            $results | Format-List *
        }
    } else { Write-Error "command not found: $($name)" }
    Remove-Variable results -Force -ErrorAction SilentlyContinue
}
