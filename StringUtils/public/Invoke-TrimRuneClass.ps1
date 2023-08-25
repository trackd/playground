Function Invoke-TrimRuneClass {
    <#
    This is probably the fastest way to trim a string in Powershell reliably.
    and fairly easy to work with as well.
    can pass a Excludecharacter
    You can also just modify the dotnet class and add more categories.
    [System.Enum]::GetValues([System.Globalization.UnicodeCategory])
    #>
    [cmdletbinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [parameter(Mandatory, ValueFromPipeline)]
        [String[]]
        $String,
        [String]
        $ExcludeCharacter = ' ' #'0x20' # space
    )
    begin {
        if (-Not ('StringCleanerR' -as [type])) {
            Add-StringCleanerRuneclass
        }
    }
    process {
        foreach ($item in $String) {
            if ([String]::IsNullOrEmpty($item)) {
                continue
            }
            [StringCleanerR]::Trim($item, $ExcludeCharacter)
        }
    }
}

function Add-StringCleanerRuneclass {

    if (-Not ('StringCleanerR' -as [type])) {
        $StringCleanerR = @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

public class StringCleanerR {
    public static string Trim(string str, string[] exclude) {
        List<Rune> excludeRunes = new List<Rune>();
        foreach (string excludeChar in exclude) {

            // some characters are represented by multiple runes.

            StringRuneEnumerator enumerator = excludeChar.EnumerateRunes();
            enumerator.MoveNext();
            Rune excludeRune = enumerator.Current;
            excludeRunes.Add(excludeRune);
            }

        StringBuilder bufferSB = new StringBuilder();
        foreach (Rune rune in str.EnumerateRunes()) {
            if (excludeRunes.Contains(rune)) {
                bufferSB.Append(rune.ToString());
                continue;
            }
            UnicodeCategory category = Rune.GetUnicodeCategory(rune);
            switch (category) {
                case UnicodeCategory.Control:
                case UnicodeCategory.SpaceSeparator:
                case UnicodeCategory.LineSeparator:
                case UnicodeCategory.ParagraphSeparator:
                case UnicodeCategory.Surrogate:
                case UnicodeCategory.OtherNotAssigned:
                // Uncomment the following cases if needed for future tests/use
                // full list of UnicodeCategories: https://docs.microsoft.com/en-us/dotnet/api/system.globalization.unicodecategory?view=net-5.0
                // case UnicodeCategory.Format:
                // case UnicodeCategory.PrivateUse:
                // case UnicodeCategory.OtherSymbol:
                // case UnicodeCategory.OtherPunctuation:
                // case UnicodeCategory.OtherNumber:
                // case UnicodeCategory.MathSymbol:
                    continue;
                default:
                    bufferSB.Append(rune.ToString());
                    break;
            }
        }
        string trimmedString = bufferSB.ToString().Trim();
        return trimmedString;
    }
}
'@
        Add-Type -TypeDefinition $StringCleanerR -Language CSharp
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
