function Invoke-TrimRunesWithCategories {
    <#
    simple test
    "`t".EnumerateRunes()
    [System.Text.Rune]::IsControl("`t".EnumerateRunes().value)
    [System.Text.Rune]::GetUnicodeCategory("`t".EnumerateRunes().Value)
    [System.Text.Rune] | fime
    Todo: should load the categories in begin block so we know all the ranges and dont have to lookup each value.
    https://en.wikipedia.org/wiki/Unicode_character_property
    #>
    [cmdletbinding()]
    # [Alias('TrimPipeline','Trim')]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]
        $String,
        [ValidateLength(1, 1)]
        [string]
        $KeepCharacter = ' ' #'0x20' # space
    )
    begin {
        $bufferSB = [Text.StringBuilder]::new()
        $keep = $KeepCharacter.EnumerateRunes().value
        # Todo: add support for preloading values for all the categories, so we dont have to do a lookup for each rune.
        # ie bypassing each call to GetUnicodeCategory... might be faster.
        # $lookup = [System.Enum]::GetValues([System.Globalization.UnicodeCategory]) | ForEach-Object {
        #     [PSCustomObject]@{
        #         Category = $_
        #         Range    = [System.Globalization.UnicodeCategory]::$_.value__ # this doesn't work.
        #     }
        # }
    }
    process {
        foreach ($str in $String) {
            if ([String]::IsNullOrEmpty($str)) {
                continue
            }
            foreach ($Rune in $str.EnumerateRunes()) {
                if ($KeepCharacter) {
                    if ($Rune.Value -eq $keep) {
                        [void]$bufferSB.Append($Rune.ToString())
                        continue
                    }
                }
                $Category = [System.Text.Rune]::GetUnicodeCategory($Rune.Value)
                switch ($Category) {
                    'Control' { continue }
                    'SpaceSeparator' { continue }
                    'LineSeparator' { continue }
                    'ParagraphSeparator' { continue }
                    # 'Format' { continue }
                    'Surrogate' { continue }
                    # 'PrivateUse' { continue }
                    # 'OtherNotAssigned' { continue }
                    # 'OtherFormat' { continue }
                    # 'OtherSurrogate' { continue }
                    # 'OtherPrivateUse' { continue }
                    # 'Other' { continue }
                    # etc ..
                    default {
                        [void]$bufferSB.Append($Rune.ToString())
                    }
                }
            }
            $bufferSB.ToString().Trim()
            [void]$bufferSB.Clear()
        }
    }
}
