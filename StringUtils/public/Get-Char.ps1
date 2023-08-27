using namespace System.Text

function Get-CharInfo {
    [CmdletBinding()]
    [Alias('Get-RuneInfo','Get-Char','Get-Rune')]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        $String,
        [Alias('Full')]
        [Switch]
        $Detailed
    )
    begin {
        $list = [System.Collections.Generic.List[int]]::new()
    }
    process {
        if ($String -is [int]) {
            Write-Debug "int: $Any received, assuming rune"
            $list.add($Any)
        }
        else {
            $String.EnumerateRunes() | ForEach-Object {
                Write-Debug "String $String received, Enumerating to rune: $_"
                $list.add([int]$_.Value)
            }
        }
    }
    end {
        foreach ($r in $list) {
            try {
                $rune = [Rune]$r
            }
            catch {
                Write-Warning "Out of range, $r is not valid input"
                continue
            }
            $Character = $rune.ToString()
            $Info = [ordered]@{
                Character       = $character.ToString()
                Rune            = $rune.Value
                Char            = '[char]0x{0:X4}' -f [Char]::ConvertToUtf32($character,0)
                UnicodeCategory = [Rune]::GetUnicodeCategory($rune.Value)
            }
            if ($Character.Length -gt 1) {
                if ([Char]::IsSurrogatePair($Character[0],$Character[1])) {
                    $info.Char = 'Surrogate Pair'
                }
            }
            if ($Detailed) {
                $Info.Control = [Rune]::IsControl($rune.Value)
                $Info.Digit = [Rune]::IsDigit($rune.Value)
                $Info.Letter = [Rune]::IsLetter($rune.Value)
                $Info.LetterOrDigit = [Rune]::IsLetterOrDigit($rune.Value)
                $Info.lower = [Rune]::Islower($rune.Value)
                $Info.Number = [Rune]::IsNumber($rune.Value)
                $Info.Punctuation = [Rune]::IsPunctuation($rune.Value)
                $Info.Separator = [Rune]::IsSeparator($rune.Value)
                $Info.Symbol = [Rune]::IsSymbol($rune.Value)
                $Info.Upper = [Rune]::IsUpper($rune.Value)
                $Info.WhiteSpace = [Rune]::IsWhiteSpace($rune.Value)
                $Info.UTF8 = [Encoding]::UTF8.GetBytes($character) | Join-String -FormatString '{0:x2}' -Separator ' '
                $Info.BigEndian = [Encoding]::BigEndianUnicode.GetBytes($character) | Join-String -FormatString '{0:x2}' -Separator ' '
                $Info.Unicode = [Encoding]::Unicode.GetBytes($character) | Join-String -FormatString '{0:x2}' -Separator ' '
            }
            [PSCustomObject]$Info
        }
    }
}
