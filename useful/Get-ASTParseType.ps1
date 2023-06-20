function Get-ASTParseType {
    <#
    .SYNOPSIS
    small little helper function to explore AST stuff, check powershell file or a loaded function,
    uses the tokenizer to parse the content
    .EXAMPLE
    Get-ASTParseType -Type Comment -Path .\github\Powershell\PSTvnu\Public\Get-Tv.ps1
    .EXAMPLE
    Get-ASTParseType -Type Command,CommandArgument,CommandParameter -Path .\github\Powershell\PSTvnu\Public\Get-Tv.ps1
    .EXAMPLE
    Get-ASTParseType -Type Comment -Function Resolve-Command|ft
    #>
    [cmdletbinding()]
    [Alias('Get-AstType')]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Command','CommandParameter','CommandArgument','Number','String','Variable','Member','Attribute','Type','Operator','GroupStart','GroupEnd','Keyword','Comment','NewLine','All')]
        [String[]]
        $Type,
        [ValidateScript({ Test-Path -LiteralPath $_ })]
        [String]
        $Path,
        [ValidateScript({ Test-Path -LiteralPath Function:\$_ })]
        [String]
        $Function,
        [Switch]
        $FullOutput,
        [Switch]
        $OnlyContent
    )
    begin {
        if ($path) {
            $Content = Get-Content -Raw $Path
        } elseif ($Function) {
            $Content = Get-Content -Path Function:\$Function
        }
    }
    process {
        if ($Type -eq 'All') {
            $ASTToken = [System.Management.Automation.PSParser]::Tokenize($content,[ref]$null)
        } else {
            $ASTToken = [System.Management.Automation.PSParser]::Tokenize($content,[ref]$null) | Where-Object { $_.Type -in $Type }
        }
    }
    end {
        if ($FullOutput) {
            $ASTToken | Select-Object Type, Start, Length, StartLine, StartColumn, Endline, Endcolumn, Content
        } elseif ($OnlyContent) {
            $ASTToken | Select-Object -ExpandProperty Content
        } else {
            $ASTToken | Select-Object Type, Length, StartLine, Endline, Content
        }
    }
}
