<#
never really got the dotnet class working properly, so i just left it here for now.
#>

Function Invoke-TrimRuneClass {
    [cmdletbinding()]
    # [Alias('TrimPipeline')]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [parameter(Mandatory, ValueFromPipeline)]
        [String[]]
        $String,
        [Switch]
        $NoTrim,
        [ValidateLength(1, 2)]
        [string]
        $ExcludeCharacter = ' ' #'0x20' # space
    )
    begin {
        throw 'broken rune class'
        if (-Not ('StringCleanerR' -as [type])) {
            Add-StringCleanerRune
        }
        $keep = $ExcludeCharacter.EnumerateRunes().value -as [int]
    }
    process {
        foreach ($item in $String) {
            if ([String]::IsNullOrEmpty($item)) {
                continue
            }
            if ($NoTrim) {
                [StringCleanerR]::Trim($item, $keep)
            }
            else {
                # using .Trim() to cleanup the input string after whitespace removal, should be safe to use for leading/trailing whitespace without touching spaces.
                [StringCleanerR]::Trim($item, $keep)
            }
        }
    }
}
Function Add-StringCleanerRune {
    <#
    broken rune class
    dotnet code from
    https://stackoverflow.com/questions/6219454/efficient-way-to-remove-all-whitespace-from-string/37368176#37368176
    https://en.wikipedia.org/wiki/Whitespace_character
    https://www.compart.com/en/unicode/block/U+2400
    #>

    if (-Not ('StringCleanerR' -as [type])) {
        $StringCleanerR = @'
using System;
using System.Text;

public static class StringCleanerR {
    public static string Trim(string input, int keep) {
        StringBuilder sb = new StringBuilder();
        foreach (Rune rune in input.EnumerateRunes()) {
            Console.WriteLine(rune.Tostring());
            console.WriteLine(rune.Value);
            if (rune.Value == keep) {
                sb.Append(rune.ToString());
                break;
            } else {
                switch (rune.Value) {
                    case 0x20: // normal space
                    case 0x09: // horizontal tab
                    case 0x0A: // line feed
                    case 0x0B: // vertical tab
                    case 0x0C: // form feed
                    case 0x0D: // carriage return
                    case 0x85: // next line
                    case 0xA0: // non-breaking space
                    case 0x1680: // ogham space mark
                    case 0x2000: // en quad
                    case 0x2001: // em quad
                    case 0x2002: // en space
                    case 0x2003: // em space
                    case 0x2004: // three-per-em space
                    case 0x2005: // four-per-em space
                    case 0x2006: // six-per-em space
                    case 0x2007: // figure space
                    case 0x2008: // punctuation space
                    case 0x2009: // thin space
                    case 0x200A: // hair space
                    case 0x2028: // line separator
                    case 0x2029: // paragraph separator
                    case 0x202F: // narrow no-break space
                    case 0x205F: // medium mathematical space
                    case 0x3000: // ideographic space
                        break; // skip this character
                    default:
                        sb.Append(rune.ToString());
                        break;
                }
            }
        }
        string result = sb.ToString();
        sb.Clear();
        return result.Trim();
    }
}
'@
        Add-Type -TypeDefinition $StringCleanerR -Language CSharp
    }
}
Function Old-StringCleanerRune {
    <#
    broken rune class
    dotnet code from
    https://stackoverflow.com/questions/6219454/efficient-way-to-remove-all-whitespace-from-string/37368176#37368176
    https://en.wikipedia.org/wiki/Whitespace_character
    https://www.compart.com/en/unicode/block/U+2400
    #>

    if (-Not ('StringCleanerR' -as [type])) {
        $StringCleaner = @'
using System;
using System.Text;

public static class StringCleanerR {
    public static string Trim(string str, int keep) {
        var sb = new StringBuilder();
        foreach (Rune rune in str.EnumerateRunes()) {
            if (rune.Value != keep) {
                // string character = char.ConvertFromUtf32(rune.Value);
                string character = rune.ToString();
                sb.Append(character);
                break;
            }
            switch (rune.Value) {
                case 5760:
                case 8192:
                case 1680:
                case 8194:
                case 8195:
                case 8196:
                case 8197:
                case 8198:
                case 8199:
                case 8200:
                case 8201:
                case 8202:
                case 8239:
                case 8287:
                case 12288:
                case 8232:
                case 8233:
                case 9:
                case 10:
                case 11:
                case 12:
                case 13:
                case 8203:
                case 65279:
                case 8205:
                case 8204:
                case 8288:
                case 6158:
                case 6144:
                case 6156:
                case 6157:
                    break;
                default:
                    //string character = char.ConvertFromUtf32(rune.Value);
                    string character = rune.ToString();
                    sb.Append(character);
                    break;
            }
        }
        string result = sb.ToString();
        return result.Trim();
    }
}
'@
        Add-Type -TypeDefinition $StringCleaner -Language CSharp
    }
}

<#
\u0085 -> 5760  # Next Line (NEL)
\u00A0 -> 8192  # No-Break Space (NBSP)
\u1680 -> 5760  # Ogham Space Mark
\u2000 -> 8194  # En Quad
\u2001 -> 8195  # Em Quad
\u2002 -> 8196  # En Space
\u2003 -> 8197  # Em Space
\u2004 -> 8198  # Three-Per-Em Space
\u2005 -> 8199  # Four-Per-Em Space
\u2006 -> 8200  # Six-Per-Em Space
\u2007 -> 8201  # Figure Space
\u2008 -> 8202  # Punctuation Space
\u2009 -> 8201  # Thin Space
\u200A -> 8202  # Hair Space
\u202F -> 8239  # Narrow No-Break Space
\u205F -> 8287  # Medium Mathematical Space
\u3000 -> 12288  # Ideographic Space
\u2028 -> 8232  # Line Separator
\u2029 -> 8233  # Paragraph Separator
\u0009 -> 9  # Tab
\u000A -> 10  # Line Feed (LF)
\u000B -> 11  # Vertical Tab (VT)
\u000C -> 12  # Form Feed (FF)
\u000D -> 13  # Carriage Return (CR)
\u200B -> 8203  # Zero Width Space
\uFEFF -> 65279  # Zero Width No-Break Space (BOM)
\u200D -> 8205  # Zero Width Joiner
\u200C -> 8204  # Zero Width Non-Joiner
\u2060 -> 8288  # Word Joiner
\u180E -> 6158  # Mongolian Vowel Separator
\u2400 -> 6144  # Symbol for Null
\u240c -> 6156  # Symbol for Form Feed
\u240d -> 6157  # Symbol for Carriage Return
#>
