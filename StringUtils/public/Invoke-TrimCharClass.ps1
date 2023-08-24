Function Invoke-TrimCharClass {
    [cmdletbinding()]
    # [Alias('TrimPipeline')]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [parameter(Mandatory, ValueFromPipeline)]
        [String[]]
        $String,
        [Switch]
        $NoTrim
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
            if ($NoTrim) {
                [StringCleaner]::Trim($item)
            }
            else {
                # using .Trim() to cleanup the input string after whitespace removal, should be safe to use for leading/trailing whitespace without touching spaces.
                # todo: do this in the .net code.
                [StringCleaner]::Trim($item).Trim()
            }
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
                case '\uFEFF': case '\u200D': case '\u200C': case '\u2060': case '\u180E':
                // from compart.com
                case '\u2400': case '\u240c': case '\u240d':
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
