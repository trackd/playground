function Remove-Whitespace {
    <#
    just simple regex to remove whitespace.

    manual charlist for whitespace, does not include normal space to be able to cleanup strings
    #>
    [cmdletbinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [parameter(Mandatory, ValueFromPipeline)]
        [String[]]
        $InputObject
    )
    begin {
        # regex for cleaning strings
        $Cleanup = @{
            # dotnet whitespace
            simple          = '\s+'
            # multiline whitespace
            multi           = '(?m)^\s*$'
            # dotnet whitespace, tabs, newlines, carriage returns
            stuff           = '\s+|\t+|\r?\n'
            # dotnet whitespace, tabs, newlines, carriage returns, start and end of string
            # this in combination with [String]::IsNullOrEmpty($InputObject) would work for most scenarios.
            testing         = '^\s+|\s+$|\t+|\r?\n'
            Whitespace      = @(
                #'\u0020' # space, dont want to break sentences.
                '\u00A0' # non-breaking space
                '\u1680' # ogham space mark
                '\u2000' # en quad
                '\u2001' # em quad
                '\u2002' # en space
                '\u2003' # em space
                '\u2004' # three-per-em space
                '\u2005' # four-per-em space
                '\u2006' # six-per-em space
                '\u2007' # figure space
                '\u2008' # punctuation space
                '\u2009' # thin space
                '\u200A' # hair space
                '\u202F' # narrow no-break space
                '\u205F' # medium mathematical space
                '\u3000' # ideographic space
                '\u2028' # line separator
                '\u2029' # paragraph separator
                '\u0009' # tab
                '\u000A' # line feed
                '\u000B' # vertical tab
                '\u000C' # form feed
                '\u000D' # carriage return
                '\u0085' # next line
                '\u00A0' # non-breaking space
                '\u200B' # zero width space
                '\uFEFF' # zero width no-break space
            ) -join '|'
            WhitespaceChars = @(
                # non-breaking space
                [char]0x00A0,
                # zero width space
                [char]0x2000,
                # en quad
                [char]0x2001,
                # em quad
                [char]0x2002,
                # en space
                [char]0x2003,
                # em space
                [char]0x2004,
                # three-per-em space
                [char]0x2005,
                # four-per-em space
                [char]0x2006,
                # six-per-em space
                [char]0x2007,
                # figure space
                [char]0x2008,
                # punctuation space
                [char]0x2009,
                # thin space
                [char]0x200A,
                # zero width space
                [char]0x200B,
                # line separator
                [char]0x2028,
                # paragraph separator
                [char]0x2029,
                # ideographic space
                [char]0x3000
            ) -join ','
        }
    }
    process {
        if ([String]::IsNullOrEmpty($InputObject)) {
            return
        }
        ($InputObject -replace $Cleanup.Whitespace).Trim()
    }
}
