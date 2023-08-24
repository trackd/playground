function Invoke-TrimRunes {
    [cmdletbinding()]
    # [Alias('TrimPipeline')]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [String[]]
        $String,
        [ValidateLength(1, 2)]
        [String]
        $ExcludeCharacter = ' ' #'0x20' # space
    )
    begin {
        $bufferSB = [System.Text.StringBuilder]::new()
        $keep = $ExcludeCharacter.EnumerateRunes().value
    }
    process {
        foreach ($str in $String) {
            if ([String]::IsNullOrEmpty($str)) {
                # skip empty entries.
                continue
            }
            foreach ($Rune in $str.EnumerateRunes()) {
                if ($ExcludeCharacter) {
                    if ($Rune.Value -eq $keep) {
                        [void]$bufferSB.Append($Rune.ToString())
                    }
                }
                # maybe use categories.
                # $Category = [System.Globalization.UnicodeCategory]::Control -bor [System.Globalization.UnicodeCategory]::WhiteSpace
                if ([System.Text.Rune]::IsControl($Rune.Value) -or [System.Text.Rune]::IsWhitespace($Rune.Value)) {
                    continue
                }
                else {
                    [void]$bufferSB.Append($Rune.ToString())
                }
            }
            $bufferSB.ToString().Trim()
            [void]$bufferSB.Clear()
        }
    }
}
