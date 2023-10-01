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
    .PARAMETER Name
    Name of the command you want to see
    Resolve-Command -Name Get-User
    .PARAMETER Object
    pipeline, if you pipe Get-Command <command> to Resolve-Command
    e.g. Get-Command Get-Childitem | Resolve-Command
    will just show more info and attempt to display code
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
        $Object
    )
    if ($object) {
        $results = $object | Select-Object -First 1
    }
    elseif ($Name) {
        #get CommandInfo object if it's a name
        $results = Get-Command $name -ErrorAction 'Stop'
    }
    if ($results) {
        #if we find results
        while ($results.CommandType -eq 'Alias') {
            Write-Warning "Alias found: $($results.Name) = $($results.definition)"
            #if it's an alias, continue down the rabbit hole til we get something else.
            $results = Get-Command $results.definition -ErrorAction 'Stop'
        }
        if ($results.CommandType -eq 'Function') {
            if (Get-Command -Name Format-Powershell) {
                # Format-Powershell is from https://github.com/SeeminglyScience/dotfiles/blob/main/Documents/PowerShell/Utility.psm1
                # relies on bat.
                @(
                    '<#'
                    "File: $($results.ScriptBlock.file)"
                    "Parameters: $($results.ParameterSets)"
                    '#>'
                    $results.ScriptBlock.ast.extent.text
                ) | Format-Powershell
            }
            else {
                $pref = $InformationPreference
                $InformationPreference = 'Continue'
                Write-Information "File: $($results.ScriptBlock.file)"
                Write-Information "Parameters: $($results.ParameterSets)"
                $results.ScriptBlock.ast.extent.text
                $InformationPreference = $pref
            }
        }
        elseif ($results.CommandType -eq 'Cmdlet') {
            if (Get-Command -Name Expand-MemberInfo) {
                # Expand-MemberInfo and Format-CSharp are from https://github.com/SeeminglyScience/dotfiles/blob/main/Documents/PowerShell/Utility.psm1
                # they also rely on dnspy.console & bat.
                $results.ImplementingType | Expand-MemberInfo | Format-CSharp
            }
            else {
                #if it's a cmdlet try something but recommend ilspy for dll.
                $pref = $InformationPreference
                $InformationPreference = 'Continue'
                Write-Warning 'This command is a cmdlet, you need ilspy/dnspy or something similar to decompile the code, output is a proxyfunction'
                Write-Information "File: $($results.DLL)`n"
                Write-Information "Parameters: $($results.ParameterSets)`n"
                Write-Output "function $($results.Name) {"
                $MetaData = [System.Management.Automation.CommandMetaData]::new($results)
                [System.Management.Automation.ProxyCommand]::Create($MetaData)
                Write-Output '}'
                $InformationPreference = $pref
            }
        }
        else {
            #else just output all, like for applications.
            $results | Select-Object Name, Source, Path, CommandType, Extension, FileVersionInfo
        }
    }
    else { Write-Error "command not found: $($name)" }
    Remove-Variable results -Force -ErrorAction SilentlyContinue
}
