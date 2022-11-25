function Get-TvSport {
	<#
	.SYNOPSIS
	Get Sporting events from tv.nu
	unofficial use of api... could break
	All parameters are optional for filtering

	.NOTES
	trackd 2022-10-29
	just created this to learn a bit more


	.PARAMETER Sport
	Choose which sport you want to see
	acceptable inputs Hockey, Fotboll, Bandy, Handboll, Tennis, Vintersport, Motorsport, Other, all
	if none is selected, all is chosen per default.

	.PARAMETER Viewall
	if selected will show previous and future sport events for the day
	if not selected it will only current and future sport events the day

	.PARAMETER Reruns
	parameter to show rerun events
	by default reruns are not shown.

	.PARAMETER Day
	acceptable input is today or tomorrow
	default today

	.PARAMETER Full
	show all attributes (same as | fl * )
	will use this to test new properties in the future.
	Title = Event Title
	Live = Live event? Not reliable info
	Channel = Which TV Channel is the game on
	Stream = Which Stream is the game on
	Time = Event start
	StreamStart = Stream start (can be array if reruns etc)
	StreamEnd = Stream end (can be array if reruns etc)
	Date = date of event
	Tournament = which league, cup etc.
	Sport = which sport
	HomeTeam = "team1", should be home team for most sports, possible NHL is reverse. not realiable
	AwayTeam = "team2", should be away team for most sports, possible NHL is reverse. not realiable
	Rerun = is this a rerun game
	Description = description of event

	.EXAMPLE
	will return all current and future sport events for today
	no reruns, no previous events, "limited default output"

	Get-TvSport
	.EXAMPLE
	all hockey games for today

	Get-TvSport -Sport Hockey
	.Example
	All fotball games for tomorrow including reruns, all available properties

	Get-TvSport -Sport fotboll -Day Tomorrow -Reruns -Full

	.LINK
	credit www.tv.nu

#>
	[CmdletBinding()]
	param(
		[ValidateSet('Ishockey', 'Fotboll', 'Bandy', 'Handboll', 'Tennis', 'Vintersport', 'Motorsport', 'Other', 'all')]
		[string] $Sport,
		[Switch] $Viewall,
		[Switch] $Reruns,
		[ValidateSet('Today', 'Tomorrow')]
		[string] $Day,
		[Switch] $Full
	)
	begin {
		switch ($Sport) {
			All { $sportfilter = 'sportGroups[]=1&sportGroups[]=2&sportGroups[]=6&sportGroups[]=7&sportGroups[]=8&sportGroups[]=9&sportGroups[]=10&sportGroups[]=11' }
			Fotboll { $sportfilter = 'sportGroups[]=1' }
			Ishockey { $sportfilter = 'sportGroups[]=2' }
			Bandy { $sportfilter = 'sportGroups[]=6' }
			Handboll { $sportfilter = 'sportGroups[]=7' }
			Tennis { $sportfilter = 'sportGroups[]=8' }
			Vintersport { $sportfilter = 'sportGroups[]=9' }
			Motorsport { $sportfilter = 'sportGroups[]=10' }
			Other { $sportfilter = 'sportGroups[]=11' }
			Default { $sportfilter = 'sportGroups[]=1&sportGroups[]=2&sportGroups[]=6&sportGroups[]=7&sportGroups[]=8&sportGroups[]=9&sportGroups[]=10&sportGroups[]=11' }
		}
		if ($Viewall) { $Viewall2 = 'true' } else { $Viewall2 = 'false' }
		if ($Reruns) { $Reruns2 = 'true' } else { $Reruns2 = 'false' }
		switch ($Day) {
			Today { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
			Tomorrow { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).ToString('yyyy-MM-dd') } else { $date = (Get-Date).AddDays(1).ToString('yyyy-MM-dd') } }
			Default { if ((Get-Date) -lt (Get-Date 05:00)) { $date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') } else { $date = (Get-Date).ToString('yyyy-MM-dd') } }
		}
		$games = [System.Collections.Generic.List[psobject]]::new()
	}
	process {
		try {
			$useragent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36'
			$headers = @{
				'authority'       = 'web-api.tv.nu'
				'method'          = 'GET'
				'scheme'          = 'https'
				'accept'          = 'application/json, text/plain, */*'
				'accept-encoding' = 'gzip, deflate, br'
				'accept-language' = 'en-US,en;q=0.9,sv-SE;q=0.8,sv;q=0.7'
				'origin'          = 'https://www.tv.nu'
			}
			$url = "https://web-api.tv.nu/sport/schedule?modules[]=pp-13&modules[]=pp-12&modules[]=ch-51&modules[]=ch-52&modules[]=pp-14&modules[]=ed-6&modules[]=pp-18&modules[]=ch-60&modules[]=ed-19&modules[]=ch-27&modules[]=pl-3&modules[]=pp-31&modules[]=ch-63&modules[]=ch-65&modules[]=pp-9&modules[]=ch-64&modules[]=ed-15&modules[]=ch-66&modules[]=pp-34&modules[]=ch-67&modules[]=pp-30&modules[]=tl-13&modules[]=ch-68&modules[]=pp-4&modules[]=ch-70&modules[]=pp-16&modules[]=ch-88&modules[]=pc-8&modules[]=ch-132&modules[]=pl-2&modules[]=ch-49&modules[]=ch-53&modules[]=pp-33&modules[]=ch-54&modules[]=pp-36&modules[]=ch-30233&preset=sport&scheduleDate=$date&$($sportfilter)&viewAll=$($viewall2)&withReruns=$($reruns2)"
			$raw = Invoke-RestMethod -UserAgent $useragent -Headers $headers -Uri $url
			foreach ($game in $raw.data) {
				$object = [pscustomobject]@{
					Title       = $game.title
					Live        = $game.isLive
					Channel     = $game.broadcasts.channel.name -join ','
					Stream      = $game.playEpisodes.playprovider.name -join ','
					Time        = [System.DateTimeOffset]::FromUnixTimeMilliseconds($game.eventTime).LocalDateTime.ToString('ddd HH:mm')
					StreamStart = [System.DateTimeOffset]::FromUnixTimeMilliseconds($game.playEpisodes.streamstart).LocalDateTime.ToString('ddd HH:mm') -join ','
					StreamEnd   = [System.DateTimeOffset]::FromUnixTimeMilliseconds($game.playEpisodes.streamend).LocalDateTime.ToString('ddd HH:mm') -join ','
					Date        = $game.scheduleDate
					Tournament  = $game.tournament
					Sport       = $game.Sport
					HomeTeam    = $game.team1.name
					AwayTeam    = $game.team2.name
					Rerun       = $game.broadcasts.isRerun -join ','
					Description = $game.description
					TimeFull    = [System.DateTimeOffset]::FromUnixTimeMilliseconds($game.eventTime).LocalDateTime.ToString('yyyy-MM-dd HH:mm')
				}
				$games.add($object)
			}
		} catch {
			Write-Error "ERROR $($error[0].exception.message)"
			break
		}
	}
	end {
		if (!$Full) {
			$fields = 'Time', 'Title', 'Channel', 'Stream', 'Tournament', 'Sport'
			$default = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$fields)
			$members = [System.Management.Automation.PSMemberInfo[]]@($default)
			$games | Add-Member MemberSet PSStandardMembers $members
		}
		$games | Sort-Object -Property Timefull
	}
}