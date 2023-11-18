function Edit-VSCode {
    <#
    .SYNOPSIS
        Edit a command in vscode.
    .PARAMETER Command
    CommandName, or alias.
    .PARAMETER InputObject
    CommandInfo object.
    .PARAMETER Stable
    Use stable version of vscode.
    .EXAMPLE
    Edit-VSCode myfunction
    .EXAMPLE
    Get-Command myfunction | Edit-VSCode
    .EXAMPLE
    Edit-VSCode -Command myfunction -Stable
    #>
    [Alias('ev','edit')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = 'String', Position = 0)]
        [String]$Command,
        [Parameter(Mandatory,ValueFromPipeline, ParameterSetName = 'Object')]
        [System.Management.Automation.CommandInfo]$InputObject,
        [Switch]$Stable
    )
    # vs code version, defaults to insiders.
    if ($Stable) {
        $code = Get-Command code -ErrorAction Stop
    }
    else {
        $code = Get-Command code-insiders -ErrorAction Stop
    }

    # command lookup
    if ($Command) {
        $lookup = $ExecutionContext.InvokeCommand.GetCommand($Command,'All')
    }
    else { $lookup = $InputObject }
    if ($null -eq $lookup -or $lookup.CommandType -eq 'Cmdlet') { return 'Action not supported' }
    if ($lookup.ResolvedCommand) {
        $lookup = $lookup.ResolvedCommand
    }

    # builder
    $pointer = "{0}:{1}:{2}" -f $lookup.scriptblock.file,
    $lookup.ScriptBlock.StartPosition.StartLine,
    $lookup.ScriptBlock.StartPosition.StartLine.StartColumn
    $vsargs = @(
        '--goto'
        $pointer
    )
    & $code $vsargs
}
