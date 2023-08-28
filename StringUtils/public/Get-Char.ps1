using namespace System.Text

function Get-CharInfo {
    <#
    tries to convert a string to a rune, and returns information about the rune.
    also accepts a rune, and returns information about the rune.
    .PARAMETER String
    input string, can be a rune, a hexcode, or a string.

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

    #>
    [CmdletBinding()]
    [Alias('Get-RuneInfo','Get-Char','Get-Rune')]
    param (
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [Parameter(Mandatory, ValueFromPipeline)]
        $String,
        [Alias('Full')]
        [Switch]
        $Detailed
    )
    begin {
        $list = [System.Collections.Generic.List[int]]::new()
        $regexU = [regex]::escape('^`u{([0-9A-Fa-f]{4,6})}$')
    }
    process {
        if ([String]::IsNullOrEmpty($String)) {
            # skip empty entries.
            continue
        }
        if ($String -match "^U\+([0-9A-Fa-f]{4,6})$|$regexU") {
            Write-Debug "hex: $String"
            $list.add([Convert]::ToInt32($matches[1], 16))
        }
        elseif ($String -is [int]) {
            Write-Debug "int: $String, assuming rune"
            $list.add($String)
        }
        else {
            $String.EnumerateRunes() | ForEach-Object {
                Write-Debug "String $String, Enumerating to rune [$($_.Value)]:  $_"
                $list.add([int]$_.Value)
            }
        }
    }
    end {
        foreach ($rnum in $list) {
            try {
                $rune = [Rune]$rnum
            }
            catch {
                throw $_
            }
            $Character = $rune.ToString()
            $hex = [Convert]::ToString($rnum, 16)
            $Info = [ordered]@{
                Character       = $Character
                Rune            = $rnum
                Hex             = "$([System.String]::Concat('`','u','{',$hex,'}'))"
                UnicodeCategory = [Rune]::GetUnicodeCategory($rnum)
            }

            if ($Detailed) {
                $Info.Control = [Rune]::IsControl($rnum)
                $Info.Digit = [Rune]::IsDigit($rnum)
                $Info.Letter = [Rune]::IsLetter($rnum)
                $Info.LetterOrDigit = [Rune]::IsLetterOrDigit($rnum)
                $Info.lower = [Rune]::Islower($rnum)
                $Info.Number = [Rune]::IsNumber($rnum)
                $Info.Punctuation = [Rune]::IsPunctuation($rnum)
                $Info.Separator = [Rune]::IsSeparator($rnum)
                $Info.Symbol = [Rune]::IsSymbol($rnum)
                $Info.Upper = [Rune]::IsUpper($rnum)
                $Info.WhiteSpace = [Rune]::IsWhiteSpace($rnum)
                $Info.UTF8 = [Encoding]::UTF8.GetBytes($character) | Join-String -FormatString '{0:x2}' -Separator ' '
                $Info.BigEndian = [Encoding]::BigEndianUnicode.GetBytes($character) | Join-String -FormatString '{0:x2}' -Separator ' '
                $Info.Unicode = [Encoding]::Unicode.GetBytes($character) | Join-String -FormatString '{0:x2}' -Separator ' '
                switch ($Character.Length) {
                    '1' { $Info.CharCode = '[char]0x{0:X4}' -f [Char]::ConvertToUtf32($character,0) }
                    '2' { $info.CharCode = 'Surrogate Pair' }
                    default { }
                }
            }
            [PSCustomObject]$Info
        }
    }
}
