function Get-Weather {
    <#
    .SYNOPSIS
    Shows weather in terminal, as ANSI art, or as objects.
    defaults to ansi output if nothing is specified.
    uses wttr.in
    .PARAMETER Forecast
    Show forecast instead of current weather, as a list of objects.
    .PARAMETER Current
    Show current weather, as an object.
    .PARAMETER ANSI
    Show current weather, as ANSI art with pretty colors.
    .Parameter Location
    Specify a location, otherwise it will guess based on your IP.
    .PARAMETER Culture
    Specify a culture, otherwise it will use your current culture settings.
    needs to be a two letter ISO language code, e.g. en, sv, de, fr, etc.
    .Notes
    credit to chubin for a cool service, https://wttr.in/
    for more details see https://github.com/chubin/wttr.in
    #>
    [Cmdletbinding(DefaultParameterSetName = 'ANSI')]
    Param(
        [Parameter()]
        [String]
        $Location,
        [Parameter(ParameterSetName = 'ANSI')]
        [Switch]
        $ANSI,
        [Parameter(ParameterSetName = 'Object.Current')]
        [Alias('AsObject')]
        [Switch]
        $Current,
        [Parameter(ParameterSetName = 'Object.Forecast')]
        [Switch]
        $Forecast,
        [Parameter()]
        [String]
        $Culture = (Get-Culture).TwoLetterISOLanguageName
    )
    begin {
        if (-Not $ANSI -And $PSCmdlet.ParameterSetName -eq 'ANSI') {
            # default to ANSI if nothing is specified.
            $ANSI = $true
        }
        # supported languages from https://github.com/chubin/wttr.in/blob/master/lib/translations.py
        $FULL_TRANSLATION = (
            "am", "ar", "af", "be", "bn",  "ca", "da", "de", "el", "et",
            "fr", "fa", "gl", "hi", "hu", "ia", "id", "it", "lt", "mg",
            "nb", "nl", "oc", "pl", "pt-br", "ro",
            "ru", "ta", "tr", "th", "uk", "vi", "zh-cn", "zh-tw"
        )
        $PARTIAL_TRANSLATION = (
            "az", "bg", "bs", "cy", "cs",
            "eo", "es", "eu", "fi", "ga", "hi", "hr",
            "hy", "is", "ja", "jv", "ka", "kk",
            "ko", "ky", "lv", "mk", "ml", "mr", "nl", "fy",
            "nn", "pt", "pt-br", "sk", "sl", "sr",
            "sr-lat", "sv", "sw", "te", "uz", "zh",
            "zu", "he"
        )
        $SUPPORTED_LANGS = $FULL_TRANSLATION + $PARTIAL_TRANSLATION
        if ($culture -in $SUPPORTED_LANGS) {
            # culture supported, using it.
            Write-Verbose "Culture $Culture is supported."
            $header = @{
                'Accept-Language' = "$Culture"
            }
        }
        else {
            # culture not supported, defaulting to english.
            Write-Verbose "Culture $Culture is not supported, defaulting to en."
            $header = @{
                'Accept-Language' = 'en'
            }
        }
    }
    process {
        try {
            if ($ANSI) {
                Invoke-RestMethod "https://wttr.in/$($location)?Fq1" -Headers $header
            }
            else {
                $Results = Invoke-RestMethod "https://wttr.in/$($location)?format=j1" -Headers $header
                if ($Current) {
                    [PSCustomObject]@{
                        PSTypeName    = 'PS.Weather.Current'
                        Temperature   = $Results.current_condition.temp_C
                        FeelsLike     = $Results.current_condition.FeelsLikeC
                        Precipitation = $Results.current_condition.precipMM
                        Humidity      = $Results.current_condition.humidity
                        Pressure      = $Results.current_condition.pressure
                        WindSpeed     = $Results.current_condition.windspeedKmph
                        WindDir       = $Results.current_condition.winddir16Point
                        UV            = $Results.current_condition.uvIndex
                        Visibility    = $Results.current_condition.visibility
                        Clouds        = $Results.current_condition.cloudcover
                        Description   = $Results.current_condition.weatherDesc.value
                        Area          = $Results.nearest_area.areaName.value
                        Region        = $Results.nearest_area.region.value
                    }
                }
                elseif ($Forecast) {
                    foreach ($day in $Results.weather) {
                        [PSCustomObject]@{
                            PSTypeName           = 'PS.Weather.Forecast'
                            date                 = $day.date
                            avgtempC             = $day.avgtempC
                            avgTempF             = $day.avgtempF
                            maxtempC             = $day.maxtempC
                            mintempC             = $day.mintempC
                            sunHour              = $day.sunHour
                            totalSnow_cm         = $day.totalSnow_cm
                            uvIndex              = $day.uvIndex
                            moon_illumination    = $day.astronomy.moon_illumination
                            moon_phase           = $day.astronomy.moon_phase
                            moonrise             = $day.astronomy.moonrise
                            moonset              = $day.astronomy.moonset
                            sunrise              = $day.astronomy.sunrise
                            sunset               = $day.astronomy.sunset
                            hourlyTime           = $day.hourly.time -join ', '
                            hourlyTemperature    = $day.hourly.tempC -join ', '
                            hourlyfeelslike      = $day.hourly.FeelsLikeC -join ', '
                            hourlychancesunshine = $day.hourly.chanceofsunshine -join ', '
                            hourlychancethunder  = $day.hourly.chanceofthunder -join ', '
                            hourlychancerain     = $day.hourly.chanceofrain -join ', '
                            hourlyDesc           = $day.hourly.weatherDesc.value -join ', '
                        }
                    }
                }
            }
        }
        catch {
            throw $_
        }
    }
    end {
    }
}
