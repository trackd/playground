function Resolve-Command {
    <#
    .DESCRIPTION
    for test/debug and learning how things work/built.
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
    .PARAMETER object
    pipeline, if you pipe Get-Command <command> to Resolve-Command
    e.g. Get-Command Get-Childitem | Resolve-Command
    will just show more info and attempt to display code
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
        $object
    )
    #check if we are getting an commandinfo object from pipeline.
    if ($object) {
        $results = $object | Select-Object -First 1
    } else {
        #get command info data on name
        $results = Get-Command $name -ErrorAction SilentlyContinue
    }
    if ($results) {
        #if we find results
        while ($results.CommandType -eq 'Alias') {
            Write-Output "Alias found: $($results.Name) = $($results.definition)"
            #if it's an alias, continue down the rabbit hole til we get something else.
            $results = Get-Command $results.definition
        }
        if ($results.CommandType -eq 'Function') {
            $test = Get-ChildItem Function:\$($results.Name)
            if ($test.definition -eq $results.definition) {
                Write-Debug "Function loaded in (Get-Childitem Function:\$($results.Name) matches Get-Command definition)"
            }
            if ($test.definition -ne $results.definition) {
                Write-Warning "MISMATCH: Function does not match (Get-Childitem Function:\$($results.Name)) possibly duplicates/clobber from module?"
            }
            #if its a function, output some info and fake out the function so it should be copy-pasteable.
            Write-Output "File: $($results.ScriptBlock.file)"
            Write-Output "Parameters: $($results.ParameterSets)"
            Write-Output "Function $($results.Name) {"
            #just cleaning up empty space/rows and adding a } on newline.
            ($results.Definition.Trim() -replace "(?m)^\s*`r`n",'') + "`n}"
        } elseif ($results.CommandType -eq 'Cmdlet') {
            #if it's a cmdlet try something but recommend ilspy for dll.
            Write-Warning 'This is a cmdlet, you need a .NET Decompiler, like ilspy to peek inside it. https://github.com/icsharpcode/ILSpy'
            Write-Output "File: $($results.DLL)`n"
            Write-Output "Parameters: $($results.ParameterSets)`n"
            Write-Output "[cmdlet proxycommand] $($results.Name)"
            $proxycommand = New-Object system.management.automation.commandmetadata $results
            [System.management.automation.proxycommand]::Create($proxycommand)
        } else {
            #else just output all, like for applications.
            $results | Format-List *
        }
    } else { Write-Error "command not found: $($name)" }
}