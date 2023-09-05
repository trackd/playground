Function Invoke-TrimCharClass {
    <#
    space is is not part of switch statement in the C# code.
    hardcoded class of whitespace characters.
    there is an alternative to use unicode characters like the rune function but it doesn't work as well.
    #>
    [cmdletbinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [parameter(Mandatory, ValueFromPipeline)]
        [String[]]
        $String
    )
    begin {
        if (-Not ('StringCleaner' -as [type])) {
            Add-StringCleanerClass
        }
    }
    process {
        foreach ($item in $String) {
            if ([String]::IsNullOrEmpty($item)) {
                continue
            }
            [StringCleaner]::Trim($item).Trim()
        }
    }
}
Function Add-StringCleanerClass {
    <#
    dotnet code from
    https://stackoverflow.com/questions/6219454/efficient-way-to-remove-all-whitespace-from-string/37368176#37368176
    supposed to be the most efficient way to remove whitespace from a string.
    But i think the .ToCharArray() breaks a bit on some stuff as it does not remove all whitespace in PS5..

    https://en.wikipedia.org/wiki/Whitespace_character
    https://www.compart.com/en/unicode/block/U+2400
    #>

    if (-Not ('StringCleaner' -as [type])) {
        $StringCleaner = @'
using System;

public static class StringCleaner {
    public static string Trim(string str) {
        var len = str.Length;
        var src = str.ToCharArray();
        int dstIdx = 0;
        for (int i = 0; i < len; i++) {
            var ch = src[i];
            switch (ch) {
                // removed case '\u0020': this is normal 'space'
                case '\u0085': case '\u00A0': case '\u1680': case '\u2000': case '\u2001':
                case '\u2002': case '\u2003': case '\u2004': case '\u2005': case '\u2006':
                case '\u2007': case '\u2008': case '\u2009': case '\u200A': case '\u202F':
                case '\u205F': case '\u3000': case '\u2028': case '\u2029': case '\u0009':
                case '\u000A': case '\u000B': case '\u000C': case '\u000D': case '\u200B':
                // added below from wikipedia page
                // case '\uFEFF': case '\u200D': case '\u200C': case '\u2060': case '\u180E':
                // from compart.com
                // case '\u2400': case '\u240c': case '\u240d':
                    continue;
                default:
                    src[dstIdx++] = ch;
                    break;
            }
        }
        return new string(src, 0, dstIdx);
    }
}
'@
        Add-Type -TypeDefinition $StringCleaner -Language CSharp
    }
}
Function Add-StringCleanerCategories {
    <#
    this method is just worse than the above, but it is here for reference.
    it doesn't work and fails the tests.
    #>
    if (-Not ('StringCleanerCat' -as [type])) {
        $StringCleanerCat = @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

public class StringCleaner {
    public static string Trim(string str, string[] exclude)
    {
        List<char> excludeChars = new List<char>();
        foreach (string excludeChar in exclude)
        {
            char excludeCharFirst = excludeChar[0];
            excludeChars.Add(excludeCharFirst);
        }

        StringBuilder bufferSB = new StringBuilder();
        foreach (char c in str)
        {
            if (excludeChars.Contains(c))
            {
                bufferSB.Append(c);
                continue;
            }
            UnicodeCategory category = char.GetUnicodeCategory(c);
            switch (category) {
                case UnicodeCategory.Control:
                case UnicodeCategory.SpaceSeparator:
                case UnicodeCategory.LineSeparator:
                case UnicodeCategory.ParagraphSeparator:
                case UnicodeCategory.Surrogate:
                case UnicodeCategory.OtherNotAssigned:
                // Uncomment the following cases if needed for future tests
                // case UnicodeCategory.Format:
                // case UnicodeCategory.PrivateUse:
                // case UnicodeCategory.OtherSymbol:
                // case UnicodeCategory.OtherPunctuation:
                // case UnicodeCategory.OtherNumber:
                // case UnicodeCategory.MathSymbol:
                    continue;
                default:
                    bufferSB.Append(c);
                    break;
            }
        }
        string trimmedString = bufferSB.ToString().Trim();
        return trimmedString;
    }
}
'@
        Add-Type -TypeDefinition $StringCleanerCat -Language CSharp
    }
}
