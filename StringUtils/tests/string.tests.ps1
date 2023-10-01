BeforeAll {
    Import-Module $PSScriptRoot/../StringUtils.psm1 -Force
}


$sampledata = [Ordered]@{
    Test01 = @{
        Input    = "String: '\t\t' `t`tTabs🤷‍♂️"
        Expected = "String: '\t\t' Tabs🤷‍♂️"
    }
    Test02 = @{
        Input    = "String: '\n\n' `n`nNewlines"
        Expected = "String: '\n\n' Newlines"
    }
    Test03 = @{
        Input    = "String: '\r\r' `r`rCarriage Returns"
        Expected = "String: '\r\r' Carriage Returns"
    }
    Test04 = @{
        Input    = "String: '\v\v' `v`vVertical Tabs"
        Expected = "String: '\v\v' Vertical Tabs"
    }
    Test05 = @{
        Input    = "String: '\f\f' `f`fForm Feeds"
        Expected = "String: '\f\f' Form Feeds"
    }
    Test06 = @{
        Input    = "String: '\b\b' `b`bBackspaces"
        Expected = "String: '\b\b' Backspaces"
    }
    Test07 = @{
        Input    = "String: '\0\0' `0`0Null Characters"
        Expected = "String: '\0\0' Null Characters"
    }
    Test08 = @{
        Input    = "String: '\a\a' `a`aAlerts"
        Expected = "String: '\a\a' Alerts"
    }
    Test09 = @{
        Input    = "String: '\e\e' `e`eEscapes"
        Expected = "String: '\e\e' Escapes"
    }
    Test10 = @{
        Input    = "String: '\r\n' `r`nNewline Carriage Return"
        Expected = "String: '\r\n' Newline Carriage Return"
    }
    Test11 = @{
        Input    = "Some '\r\n'`r`n😍🙌 with an '\e'`e escape "
        Expected = "Some '\r\n'😍🙌 with an '\e' escape"
    }
    Test12 = @{
        Input    = '😁 just a happy emoji'
        Expected = '😁 just a happy emoji'
    }
    Test13 = @{
        Input    = "double quote "" and single quote '"
        Expected = "double quote "" and single quote '"
    }
    Test14 = @{
        Input    = "`n`n newlines for the win`t and tabs"
        Expected = "newlines for the win and tabs"
    }
    Test15 = @{
        Input    = '123'
        Expected = '123'
    }
    Test16 = @{
        Input    = "string has a null character$null"
        Expected = 'string has a null character'
    }
    Test17 = @{
        Input    = '`n`n literal string'
        Expected = '`n`n literal string'
    }
    Test18 = @{
        Input    = [string]@(1, 2, 3)
        Expected = '1 2 3'
    }
    Test19 = @{
        Input    = '1       5'
        Expected = '1       5'
    }
    Test20 = @{
        Input    = "😁🤷‍♂️🙌❤️🤣🤞✌️🤷‍♀️🤦‍♂️🤦‍♀️"
        Expected = '😁🤷‍♂️🙌❤️🤣🤞✌️🤷‍♀️🤦‍♂️🤦‍♀️'
    }
    Test21 = @{
        Input    = "😎🎶😢😜🧍‍♂️🏃‍♂️🏃‍♀️🧎‍♂️👨‍🦼👩‍🦼🤚🤜"
        Expected = '😎🎶😢😜🧍‍♂️🏃‍♂️🏃‍♀️🧎‍♂️👨‍🦼👩‍🦼🤚🤜'
    }
}


Describe "Invoke-TrimRunes" {
    Context "Invoke-TrimRunes" {
        foreach ($testName in $sampledata.Keys) {
            $testData = $sampledata[$testName]
            It "pipeline test $testName" {
                $pipe = $testData.Input | Invoke-TrimRunes
                $pipe | Should -Be $testData.Expected
            }
            It "Input test $testName" {
                $result = Invoke-TrimRunes $testData.Input
                $result | Should -Be $testData.Expected
            }
        }
    }
}

Describe "Invoke-TrimRunesRange" {
    Context "Invoke-TrimRunesRange" {
        foreach ($testName in $sampledata.Keys) {
            $testData = $sampledata[$testName]
            It "pipeline test $testName" {
                $pipe = $testData.Input | Invoke-TrimRunesRange
                $pipe | Should -Be $testData.Expected
            }
            It "Input test $testName" {
                $result = Invoke-TrimRunesRange $testData.Input
                $result | Should -Be $testData.Expected
            }
        }
    }
}

Describe "Invoke-TrimCharClass" {
    Context "Invoke-TrimCharClass" {
        foreach ($testName in $sampledata.Keys) {
            $testData = $sampledata[$testName]
            It "pipeline test $testName" {
                $pipe = $testData.Input | Invoke-TrimCharClass
                $pipe | Should -Be $testData.Expected
            }
            It "Input test $testName" {
                $result = Invoke-TrimCharClass $testData.Input
                $result | Should -Be $testData.Expected
            }
        }
    }
}

Describe "Invoke-TrimRunesWithCategories" {
    Context "Invoke-TrimRunesWithCategories" {
        foreach ($testName in $sampledata.Keys) {
            $testData = $sampledata[$testName]
            It "pipeline test $testName" {
                $pipe = $testData.Input | Invoke-TrimRunesWithCategories
                $pipe | Should -Be $testData.Expected
            }
            It "Input test $testName" {
                $result = Invoke-TrimRunesWithCategories $testData.Input
                $result | Should -Be $testData.Expected
            }
        }
    }
}

Describe "Remove-Whitespace" {
    Context "Remove-Whitespace" {
        foreach ($testName in $sampledata.Keys) {
            $testData = $sampledata[$testName]
            It "pipeline test $testName" {
                $pipe = $testData.Input | Remove-Whitespace
                $pipe | Should -Be $testData.Expected
            }
            It "Input test $testName" {
                $result = Remove-Whitespace $testData.Input
                $result | Should -Be $testData.Expected
            }
        }
    }
}

Describe "Invoke-TrimRuneClass" {
    Context "Invoke-TrimRuneClass" {
        foreach ($testName in $sampledata.Keys) {
            $testData = $sampledata[$testName]
            It "pipeline test $testName" {
                $pipe = $testData.Input | Invoke-TrimRuneClass
                $pipe | Should -Be $testData.Expected
            }
            It "Input test $testName" {
                $result = Invoke-TrimRuneClass $testData.Input
                $result | Should -Be $testData.Expected
            }
        }
    }
}

$properties = @(
    'Character',
    'Rune',
    'Hex',
    'UnicodeCategory',
    'Control',
    'Digit',
    'Letter',
    'LetterOrDigit',
    'lower',
    'Number',
    'Punctuation',
    'Separator',
    'Symbol',
    'Upper',
    'WhiteSpace',
    'UTF8',
    'BigEndian',
    'Unicode',
    'CharCode'
)

Describe 'Get-Rune' {
    $characters = @(128512, 128516, 128525, 128536, 128563)
    $randomCharacters = $characters | Get-Random -Count 3

    foreach ($character in $randomCharacters) {
        Context "when given character $character" {
            It 'returns the correct character information' {
                $result = Get-Rune $character -Detailed
                $randomProperties = $properties | Get-Random -Count 5
                foreach ($property in $randomProperties) {
                    $result.$property | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
Describe 'Get-Rune Invalid Input' {
    Context 'when given an invalid input' {
        It 'returns an error message' {
            { $result = Get-Rune 9999999 -ErrorAction SilentlyContinue } | Should -Throw
            $result | Should -Be $null
        }
    }
}

Describe 'Get-Rune reversal with emojis' {
    Context 'enumate back and forth' {
        It 'works' {
            $runenumbers = @(128512, 128516, 128525, 128536, 128563)
            $smileyChar = @('😀','😄','😍','😘','😳')
            $RuneToChar = ($runenumbers | Get-Rune).Character
            $RuneToChar | Should -Be $smileyChar
            $CharToRune = ($smileyChar | Get-Rune).Rune
            $CharToRune | Should -Be $runenumbers
        }
    }
}
Describe 'Get-Rune test' {
    Context 'simple text' {
        It 'works' {
            $runes = 'hello' | Get-Rune
            $runes.Rune | Should -Be @('104','101','108','108','111')
            $runes.Character | Should -Be @('h','e','l','l','o') }
    }
}
