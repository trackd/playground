#version 0.5
#for fun, learning about json parsing.

function Get-TvSport {
	[CmdletBinding()]
	param(
		[ValidateSet("Hockey", "Fotboll", "Bandy", "Handboll", "Tennis", "Vintersport", "Motorsport", "Other", "all")]
		[string] $Sport,
		[Switch] $Viewall,
		[Switch] $Reruns,
		[ValidateSet("Today", "Tomorrow")]
		[string] $Day,
		[Switch] $Showall
	)
	begin {
		switch ($Sport) {
			All { $sportfilter = "sportGroups[]=1&sportGroups[]=2&sportGroups[]=6&sportGroups[]=7&sportGroups[]=8&sportGroups[]=9&sportGroups[]=10&sportGroups[]=11" }
			Fotboll { $sportfilter = "sportGroups[]=1" }
			Hockey { $sportfilter = "sportGroups[]=2" }
			Bandy { $sportfilter = "sportGroups[]=6" }
			Handboll { $sportfilter = "sportGroups[]=7" }
			Tennis { $sportfilter = "sportGroups[]=8" }
			Vintersport { $sportfilter = "sportGroups[]=9" }
			Motorsport { $sportfilter = "sportGroups[]=10" }
			Other { $sportfilter = "sportGroups[]=11" }
			Default { $sportfilter = "sportGroups[]=1&sportGroups[]=2&sportGroups[]=6&sportGroups[]=7&sportGroups[]=8&sportGroups[]=9&sportGroups[]=10&sportGroups[]=11" }
		}
		# cant have a switch as a string, and string cannot be without parameter
		if ($Viewall) { $Viewall2 = 'true' } else { $Viewall2 = 'false' }
		if ($Reruns) { $Reruns2 = 'true' } else { $Reruns2 = 'false' }
		switch ($Day) {
			Today { $date = (Get-Date -Format yyyy-MM-dd) }
			Tomorrow { $date = (Get-Date).AddDays(1).ToString('yyyy-MM-dd') }
			Default { $date = (Get-Date -Format yyyy-MM-dd) }
		}
		if (!$Showall) {
			$DisplaySet = 'Time', 'Title', 'Channel', 'Stream', 'Tournament', 'Sport'
			$DisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’, [string[]]$DisplaySet)
			$PSMembers = [System.Management.Automation.PSMemberInfo[]]@($DisplayPropertySet)
		}
	}
	process {
		$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
		$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
		$raw = Invoke-WebRequest -UseBasicParsing -Uri "https://web-api.tv.nu/sport/schedule?modules[]=pp-13&modules[]=pp-12&modules[]=ch-51&modules[]=ch-52&modules[]=pp-14&modules[]=ed-6&modules[]=pp-18&modules[]=ch-60&modules[]=ed-19&modules[]=ch-27&modules[]=pl-3&modules[]=pp-31&modules[]=ch-63&modules[]=ch-65&modules[]=pp-9&modules[]=ch-64&modules[]=ed-15&modules[]=ch-66&modules[]=pp-34&modules[]=ch-67&modules[]=pp-30&modules[]=tl-13&modules[]=ch-68&modules[]=pp-4&modules[]=ch-70&modules[]=pp-16&modules[]=ch-88&modules[]=pc-8&modules[]=ch-132&modules[]=pl-2&modules[]=ch-49&modules[]=ch-53&modules[]=pp-33&modules[]=ch-54&modules[]=pp-36&modules[]=ch-30233&preset=sport&scheduleDate=$date&$($sportfilter)&viewAll=$($viewall2)&withReruns=$($reruns2)" `
			-WebSession $session `
			-Headers @{
			"authority"       = "web-api.tv.nu"
			"method"          = "GET"
			"scheme"          = "https"
			"accept"          = "application/json, text/plain, */*"
			"accept-encoding" = "gzip, deflate, br"
			"accept-language" = "en-US,en;q=0.9,sv-SE;q=0.8,sv;q=0.7"
			"origin"          = "https://www.tv.nu"
		}
		$tvobj = ConvertFrom-Json $raw.Content
	}
	end {
		$games = foreach ($game in $tvobj.data) {
			[pscustomobject]@{
				Title       = $game.title
				#Location   = $game.plats
				Live        = $game.isLive
				Channel     = $game.broadcasts.channel.name -join ","
				Stream      = $game.playEpisodes.playprovider.name -join ","
				Time        = [System.DateTimeOffset]::FromUnixTimeMilliseconds($game.eventTime).LocalDateTime.ToString("yyyy-MM-dd HH:mm")
				StreamStart = [System.DateTimeOffset]::FromUnixTimeMilliseconds($game.playEpisodes.streamstart).LocalDateTime.ToString("yyyy-MM-dd HH:mm") -join ","
				StreamEnd   = [System.DateTimeOffset]::FromUnixTimeMilliseconds($game.playEpisodes.streamend).LocalDateTime.ToString("yyyy-MM-dd HH:mm") -join ","
				Date        = $game.scheduleDate
				Tournament  = $game.tournament
				Sport       = $game.Sport
				HomeTeam    = $game.team1.name
				AwayTeam    = $game.team2.name
				Rerun       = $game.broadcasts.isRerun -join ","
				Description = $game.description
			}
		}
		if (!$Showall) {
			$games.PSObject.TypeNames.Insert(0, 'Game.View')
			$games | Add-Member MemberSet PSStandardMembers $PSMembers
		}
		$games
	}
}
