using namespace System.Text
function Get-RuneFromChar {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]]
        $Character
    )
    process {
        $Character.EnumerateRunes() | ForEach-Object {
            [PSCustomObject]@{
                Character          = $_.ToString()
                Rune               = $_.Value
                # Converted          = [char]::ConvertFromUtf32( $_.Value )
                GetUnicodeCategory = [Rune]::GetUnicodeCategory($_.Value)
                IsControl          = [Rune]::IsControl($_.Value)
                IsDigit            = [Rune]::IsDigit($_.Value)
                IsLetter           = [Rune]::IsLetter($_.Value)
                IsLetterOrDigit    = [Rune]::IsLetterOrDigit($_.Value)
                Islower            = [Rune]::Islower($_.Value)
                IsNumber           = [Rune]::IsNumber($_.Value)
                IsPunctuation      = [Rune]::IsPunctuation($_.Value)
                IsSeparator        = [Rune]::IsSeparator($_.Value)
                IsSymbol           = [Rune]::IsSymbol($_.Value)
                IsUpper            = [Rune]::IsUpper($_.Value)
                IsWhiteSpace       = [Rune]::IsWhiteSpace($_.Value)
            }
        }
    }
}

function Get-CharFromRune {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [int]
        $Number
    )
    process {
        $Character = ([Rune]$Number).ToString()
        [PSCustomObject]@{
            Character          = $Character
            Rune               = $Number
            GetUnicodeCategory = [Rune]::GetUnicodeCategory($Number)
            IsControl          = [Rune]::IsControl($Number)
            IsDigit            = [Rune]::IsDigit($Number)
            IsLetter           = [Rune]::IsLetter($Number)
            IsLetterOrDigit    = [Rune]::IsLetterOrDigit($Number)
            Islower            = [Rune]::Islower($Number)
            IsNumber           = [Rune]::IsNumber($Number)
            IsPunctuation      = [Rune]::IsPunctuation($Number)
            IsSeparator        = [Rune]::IsSeparator($Number)
            IsSymbol           = [Rune]::IsSymbol($Number)
            IsUpper            = [Rune]::IsUpper($Number)
            IsWhiteSpace       = [Rune]::IsWhiteSpace($Number)
        }
    }
}
