using namespace System.Text

function Get-Rune {
    <#
    tries to convert a string to a rune, and returns information about the rune.
    also accepts a rune, and returns information about the rune.
    .PARAMETER InputObject
    input can be a rune, a hexcode, or a string.
    .PARAMETER Character
    String to convert to rune
    .PARAMETER Rune
    Rune Codepoint number
    .PARAMETER Hex
    Hexcode either in U+... or `u{....} format
    .PARAMETER Detailed
    returns more information.
    .EXAMPLE
    accepts hexformat both in:
    rune "U+1f600"
    .EXAMPLE
    and hexformat in:
    rune "`u{1f600}"
    .EXAMPLE
    rune 😀
    .EXAMPLE
    rune 128512
    .EXAMPLE
    $PSStyle.Foreground.Red, $PSStyle.Reset | rune

    #>
    [CmdletBinding()]
    [Alias('Get-Char','Char','Rune')]
    param (
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [Parameter(Mandatory, ValueFromPipeline,ValueFromPipelineByPropertyName)]
        $InputObject,
        [Parameter(ValueFromPipelineByPropertyName)]
        [String[]]
        $Character,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Int[]]
        $Rune,
        [Parameter(ValueFromPipelineByPropertyName)]
        [String[]]
        $Hex,
        [Alias('Full')]
        [Switch]
        $Detailed
    )
    begin {
        Write-Debug "Module: $($ExecutionContext.SessionState.Module.Name) Command: $($MyInvocation.MyCommand.Name) ParameterSetName: $($PSCmdlet.ParameterSetName) Param: $($PSBoundParameters.GetEnumerator())"
        $list = [System.Collections.Generic.List[int]]::new()
        $regexU = [regex]::escape('^`u{([0-9A-Fa-f]{4,6})}$')
    }
    process {
        $InputObject = switch ($true) {
            { $Rune } { $Rune; break }
            { $Hex } { $Hex; break }
            { $Character } { $Character; break }
            default { $InputObject }
        }
        foreach ($item in $InputObject) {
            if ([String]::IsNullOrEmpty($item)) {
                # skip empty entries.
                continue
            }
            if ($InputObject -match '^U\+([0-9A-Fa-f]{4,6})$|\^`u\{\(\[0-9A-Fa-f]\{4,6}\)}\$') {
                # U+.... or `u{....} unicode format
                Write-Debug "hex: $item"
                $list.add([Convert]::ToInt32($matches[1], 16))
            }
            elseif ($item -is [int]) {
                # rune
                Write-Debug "int: $item, assuming rune"
                $list.add($item)
            }
            elseif ($item -is [Char]) {
                # char
                Write-Debug "char: $item"
                $item | ForEach-Object {
                    # all 3 methods work, not sure which is best..
                    # $list.add([Char]::ConvertToUtf32($_.ToString(),0))
                    # $list.add([Rune]::GetRuneAt($_,0).Value)
                    $list.add([int]$_)
                }
            }
            else {
                $item.EnumerateRunes() | ForEach-Object {
                    Write-Debug "String $item, Enumerating to rune [$($_.Value)]:  $_"
                    $list.add([int]$_.Value)
                }
            }
        }
    }
    end {
        foreach ($rnum in $list) {
            try {
                $runeobj = [Rune]$rnum
            }
            catch {
                throw $_
            }
            $hex = [Convert]::ToString($rnum, 16)
            $Category = [Rune]::GetUnicodeCategory($rnum)
            if ($Category -eq 'Control') {
                $StringChar = 'Control'
            }
            else {
                [string]$StringChar = $runeobj
            }
            $Info = [ordered]@{
                Character       = $StringChar
                Rune            = $runeobj.value
                Hex             = [String]::Concat('`','u','{',$hex,'}')
                UnicodeCategory = $Category
            }
            if ($Detailed) {
                $Info.Control = [Rune]::IsControl($runeobj)
                $Info.Digit = [Rune]::IsDigit($runeobj)
                $Info.Letter = [Rune]::IsLetter($runeobj)
                $Info.LetterOrDigit = [Rune]::IsLetterOrDigit($runeobj)
                $Info.lower = [Rune]::Islower($runeobj)
                $Info.Number = [Rune]::IsNumber($runeobj)
                $Info.Punctuation = [Rune]::IsPunctuation($runeobj)
                $Info.Separator = [Rune]::IsSeparator($runeobj)
                $Info.Symbol = [Rune]::IsSymbol($runeobj)
                $Info.Upper = [Rune]::IsUpper($runeobj)
                $Info.WhiteSpace = [Rune]::IsWhiteSpace($ruruneobjne)
                $Info.UTF8Bytes = [Encoding]::UTF8.GetBytes($runeobj) | Join-String -FormatString '{0:x2}' -Separator ' '
                $Info.BigEndianBytes = [Encoding]::BigEndianUnicode.GetBytes($runeobj) | Join-String -FormatString '{0:x2}' -Separator ' '
                $Info.UnicodeBytes = [Encoding]::Unicode.GetBytes($runeobj) | Join-String -FormatString '{0:x2}' -Separator ' '
                # $info.Unicode = 'U+' + $hex
                $info.Unicode = 'U+' + [Convert]::ToString($rnum, 16)
                # CharUnicodeInfo = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($rune)
                switch ($StringChar.Length) {
                    '1' { $Info.CharCode = '[char]0x{0:X4}' -f [Char]::ConvertToUtf32($runeobj.ToString(),0) }
                    '2' { $info.CharCode = 'Surrogate Pair' }
                    default { }
                }
            }
            [PSCustomObject]$Info
        }
    }
}
