# ===============================================================================================
#   Melody's Escape 2 (ME2) - SpeedAdjustedSongTrackConverter
# -----------------------------------------------------------------------------------------------
#   Version: 1.2.0 (2024-08-27)
#   Targeted game version: 1.13 (Early Access)
#
#   (Might not be compatible with later versions of the game if the way tracks are stored gets changed)
# ===============================================================================================

[CmdletBinding(DefaultParameterSetName = 'SameName')]
param
(
	[string]
	[Parameter(ParameterSetName = 'SameName', Position = 0)]
	$SongName,
	[string]
	[Parameter(Mandatory, ParameterSetName = 'SeparateNames', Position = 0)]
	$OriginalSongName,
	[string]
	[Parameter(Mandatory, ParameterSetName = 'SeparateNames', Position = 1)]
	$AdjustedSongName,
	[string]
	[Parameter(Mandatory, ParameterSetName = 'LiteralPath', Position = 0)]
	$OriginalTrackFilePath,
	[string]
	[Parameter(Mandatory, ParameterSetName = 'LiteralPath', Position = 1)]
	$AdjustedTrackFilePath,
	[string]
	[Parameter(Mandatory, ParameterSetName = 'LiteralPath', Position = 2)]
	$OutputPath,
	[Nullable[System.Int32]]
	[Parameter(ParameterSetName = 'SameName')]
	[Parameter(ParameterSetName = 'SeparateNames')]
	[ValidateRange(0,2)]
	$ObstacleDensity,
	[string]
	[Parameter(ParameterSetName = 'SameName')]
	[Parameter(ParameterSetName = 'SeparateNames')]
	$ME2_TRACK_CACHE_DIRECTORY = "$($env:AppData)\..\LocalLow\Icetesy\Melody's Escape 2\Tracks Cache",
	[int]
	$MINIMUM_HOLD_DURATION = 16,
	[int]
	$MINIMUM_HOLD_GAP = 9,
	[switch]
	$OVERWRITE_TRANSITIONS
)

# ===============================================================================================

function SelectME2TrackFile
{
	param
	(
		$SearchPattern,
		$Name,
		$Prompt,
		$Exclude
	)
	
	$search = [String]::Format($SearchPattern, $Name)
	
	$results = Get-ChildItem $search -File
	if ($results.Count -eq 0)
	{
		Write-Error "No file could be found that matches the song name '$search'" -Category ObjectNotFound -ErrorAction Stop
	}
	
	$filteredResults = $results | Where-Object Name -ne $Exclude
	if ($filteredResults.Count -eq 1)
	{
		return $filteredResults
	}
	elseif ($filteredResults.Count -eq 0)
	{
		Write-Error "No other file could be found that matches the song name '$search'" -Category ObjectNotFound -ErrorAction Stop
	}
	
	"($($filteredResults.Count)) Matches found:" | Out-Host
	"Each Obstacle Density level has its own cached track file. Low = 0, Medium = 1, Extreme = 2" | Out-Host
	"----------------------------------" | Out-Host
	foreach ($i in 0..($filteredResults.Count - 1))
	{
		"* " + "$i".PadLeft(($filteredResults.Count - 1).ToString().Length) + " : " + $filteredResults[$i].Name | Out-Host
	}
	
	$input = Read-Host $prompt
	do
	{
		if ($input -match "^\d+$" -and [int]$input -le $filteredResults.Count)
		{
			return $filteredResults[[int]$input]
		}
		elseif ($input -like "")
		{
			Write-Error "No file selected" -Category NotSpecified -ErrorAction Stop
		}
		else
		{
			$input = Read-Host "Please input a valid number"
		}
	}
	while ($true)
}

# ===============================================================================================

$ErrorActionPreference = "Stop"

if ($PSCmdlet.ParameterSetName -eq "LiteralPath")
{
	$fileA = Get-Item -LiteralPath "$OriginalTrackFilePath"
	$fileB = Get-Item -LiteralPath "$AdjustedTrackFilePath"
	$fileOut = $OutputPath
}
else
{
	if ($PSCmdlet.ParameterSetName -eq "SameName")
	{
		$songA = $SongName
		$songB = $SongName
	}
	elseif ($PSCmdlet.ParameterSetName -eq "SeparateNames")
	{
		$songA = $OriginalSongName
		$songB = $AdjustedSongName
	}

	if (-not (Test-Path $ME2_TRACK_CACHE_DIRECTORY))
	{
		Write-Error "The Tracks Cache directory for Melody's Escape 2 '$ME2_TRACK_CACHE_DIRECTORY' does not exist. Please specify the directory using '-ME2_TRACK_CACHE_DIRECTORY' or use '-OriginalTrackFilePath', '-AdjustedTrackFilePath' and '-OutputPath'" -Category ObjectNotFound -ErrorAction Stop
	}
	
	if ($ObstacleDensity -ne $null)
	{
		$obstacleDensitySuffix = "_$ObstacleDensity"
	}
	else
	{
		$obstacleDensitySuffix = "_?"
	}

	$searchPattern = "$ME2_TRACK_CACHE_DIRECTORY\*{0}*$obstacleDensitySuffix.txt"
	if ($songA -like "")
	{
		$songA = Read-Host "Search file name of the original song (can be left empty to list all files)"
	}
	$fileA = SelectME2TrackFile -SearchPattern $searchPattern -Name $songA -Prompt "Select the number of the file for the original song"
	"Original track = $fileA" | Out-Host
	"" | Out-Host

	if ($songB -like "")
	{
		$songB = Read-Host "Search file name of the speed-adjusted song (can be left empty to list all files)"
	}
	$fileB = SelectME2TrackFile -SearchPattern $searchPattern -Name $songB -Prompt "Select the number of the file for the speed-adjusted song" -Exclude $fileA.Name
	"Alternative track = $fileB" | Out-Host
	"" | Out-Host
	
	"===========================================" | Out-Host
	"" | Out-Host
	
	$fileOut = $fileA.FullName
}



$rawContentA = Get-Content -LiteralPath $fileA
$rawContentB = Get-Content -LiteralPath $fileB

$versionA = $rawContentA[0]
$versionB = $rawContentB[0]
$metadataA = $rawContentA[1] -split ";"
$metadataB = $rawContentB[1] -split ";"

$speedChange = $metadataA[0] / $metadataB[0]

$sectionsA = $rawContentA[2] -split ";"
$sectionsB = $rawContentB[2] -split ";"
$obstaclesA = $rawContentA[3] -split ";"
$obstaclesB = $rawContentB[3] -split ";"


if ([float]$versionA -ge [float]$versionB)
{
	$trackVersion = $versionA
}
else
{
	$trackVersion = $versionB
}

$trackMetadata = $metadataA[0], $metadataA[1], [int]([int]$metadataB[2] / $speedChange), $metadataA[3]

if (-not $OVERWRITE_TRANSITIONS)
{
	$trackSections = $sectionsA
}
else
{
	$trackSections = New-Object Collections.ArrayList
	foreach ($sec in $sectionsB)
	{
		if ($sec -match "^(\w):(\d+)-(\d+)(.*)")
		{
			$trackSections.Add( $Matches[1] + ":" + ([int]([int]$Matches[2] * $speedChange)).toString() + "-" + ([int]([int]$Matches[3] * $speedChange)).toString() + $Matches[4] ) | Out-Null
		}
		else
		{
			$trackSections.Add($sec) | Out-Null
		}
	}
}

$trackObstacles = New-Object Collections.ArrayList
foreach ($i in 0..($obstaclesB.Count - 1))
{
	$obst = $obstaclesB[$i]
	
	if ($obst -match "^(\d+)\:([SZ])-?(\d*)$")
	{
		$time = [int]$Matches[1] * $speedChange
		$type = $Matches[2]
		
		$hold = ""
		if ($Matches[3] -ne "")
		{
			$holdTime = [int]$Matches[3] * $speedChange
			
			if ($obstaclesB[$i + 1] -match "^(\d+)\:")
			{
				$nextTime = [int]$Matches[1] * $speedChange
				if ($time + $holdTime + $MINIMUM_HOLD_GAP -gt $nextTime)
				{
					$holdTime = $nextTime - $time - $MINIMUM_HOLD_GAP
				}
			}
			
			if ($holdTime -gt $MINIMUM_HOLD_DURATION)
			{
				$hold = "-" + [int]$holdTime
			}
		}
		$trackObstacles.Add( ([int]$time).toString() + ":" + $type + $hold ) | Out-Null
	}
	else
	{
		$trackObstacles.Add($obst) | Out-Null
	}
}

$output = $trackVersion, ($trackMetadata -join ";"), ($trackSections -join ";"), ($trackObstacles -join ";")



"* Original track '$($fileA.Name)'" | Out-Host
"Version: $versionA" | Out-Host
"Duration: $($metadataA[0])" | Out-Host
"???: $($metadataA[1])" | Out-Host
"BPM: $($metadataA[2])" | Out-Host
"Time Signature (4/4 or 3/4): $($metadataA[3])" | Out-Host
"Track Section Count: $($sectionsA.Count - 1)" | Out-Host
"Raw Obstacle Count: $($obstaclesA.Count - 1)" | Out-Host
"" | Out-Host
"* Alternative track '$($fileB.Name)'" | Out-Host
"Version: $versionB" | Out-Host
"Duration: $($metadataB[0])" | Out-Host
"???: $($metadataB[1])" | Out-Host
"BPM: $($metadataB[2])" | Out-Host
"Time Signature (4/4 or 3/4): $($metadataB[3])" | Out-Host
"Track Section Count: $($sectionsB.Count - 1)" | Out-Host
"Raw Obstacle Count: $($obstaclesB.Count - 1)" | Out-Host
"" | Out-Host
"(Time Adjustment: $($speedChange.ToString("p")))" | Out-Host
"" | Out-Host
"- New data -" | Out-Host
"Version: $trackVersion" | Out-Host
"Duration: $($trackMetadata[0])" | Out-Host
"???: $($trackMetadata[1])" | Out-Host
"BPM: $($trackMetadata[2])" | Out-Host
"Time Signature (4/4 or 3/4): $($trackMetadata[3])" | Out-Host
"Track Section Count: $($trackSections.Count - 1)" | Out-Host
"Raw Obstacle Count: $($trackObstacles.Count - 1)" | Out-Host
"" | Out-Host

if ($versionA -ne $versionB)
{
	"Warning - Versions don't match." | Out-Host
	"" | Out-Host
}

if ($PSCmdlet.ParameterSetName -ne "LiteralPath")
{
	$confirmation = Read-Host "The original song's cached track data will be overwritten. Continue? (yes/no)"
	if ($confirmation -like "" -or "yes" -notlike "$confirmation*")
	{
		return
	}
	"" | Out-Host
}


$output | Out-Host

Set-Content -LiteralPath $fileOut $output

"" | Out-Host
"Conversion Successful!" | Out-Host
