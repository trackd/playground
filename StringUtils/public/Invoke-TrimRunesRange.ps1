function Invoke-TrimRunesRange {
    <#
        reworked Ninmonkeys Format-ControlChar to trim
        hardcoded ranges of control characters.
    #>
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]
        $Text,
        # Preserves whitespace: tab, cr, space.
        # useful when piping from something like ansi-highlighted Markdown files
        [Alias('AllowWhitespace')]
        [Parameter()]
        [switch]
        $PreserveWhitespace,
        # Preserve \r\n, otherwise replace all other whitespace
        [Alias('AllowNewline')]
        [Parameter()]
        [switch]
        $PreserveNewline,
        [Parameter()]
        [switch]
        $RemoveSpace
    )
    begin {
        $Filters = @{
            'ControlChars_C0' = @{
                type = 'range'
                min  = 0x0
                max  = 0x1f
            }
            # useful if  you dont want to break sentences.
            'Space'           = @{
                type   = 'list'
                values = @(
                    0x20 # space
                )
            }
            'Whitespace'      = @{
                type   = 'list'
                values = @(
                    0x20 # space
                    0xd  # cr
                    0x9  # tab
                    0xa  # newline
                )
            }
            'Newlines'        = @{
                type   = 'list'
                values = @(
                    0xd  # cr
                    0xa  # newline
                )
            }
        }
        $controlMin = $Filters.'ControlChars_C0'.min
        $controlMax = $Filters.'ControlChars_C0'.max + 1
        # $range = 0x0..0x1f + 0x20
        $bufferSB = [System.Text.StringBuilder]::new()
    }
    process {
        foreach ($item in $Text) {
            if ([String]::IsNullOrEmpty($item)) {
                continue
            }
            foreach ($Rune in $item.EnumerateRunes()) {
                if ($Rune.Value -ge $controlMin -and $Rune.Value -le $controlMax ) {
                    if ($PreserveNewline) {
                        if ($Rune.Value -in $Filters.Newlines.values) {
                            [void]$bufferSB.Append($Rune.ToString())
                            continue
                        }
                    }
                    if ($PreserveWhitespace) {
                        if ($Rune.Value -in $Filters.Whitespace.values) {
                            [void]$bufferSB.Append($Rune.ToString())
                            continue
                        }
                    }
                    if (-Not $RemoveSpace) {
                        if ($Rune.Value -in $Filters.Space.values) {
                            [void]$bufferSB.Append($Rune.ToString())
                            continue
                        }
                    }
                    continue
                }
                [void]$bufferSB.Append($Rune.ToString())
            }
            $bufferSB.ToString().Trim()
            [void]$bufferSB.Clear()
        }
    }
}
