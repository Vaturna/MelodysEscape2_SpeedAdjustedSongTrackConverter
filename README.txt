===============================================================================================
  Melody's Escape 2 (ME2) - SpeedAdjustedSongTrackConverter
-----------------------------------------------------------------------------------------------
  Version: 1.0.2 (2024-08-09)
  Targeted game version: 1.13 (Early Access)

  (Might not be compatible with later versions of the game if the way tracks are stored gets changed)
===============================================================================================

This is a utility script for the rythm game "Melody's Escape 2" by Icetesy.

The goal of this script is to create tracks for Melody's Escape 2 with higher BPM (beats per minute) than what is natively supported by the game by generating a track for a slowed-down version of a song and converting it back to the original speed.

-------

GENERAL INFORMATION:

If "Cache track data" is enabled in the settings the game will store files with information about the tracks inside the user's "AppData\LocalLow\Icetesy\Melodys Escape 2" directory. If a file for the song already exists, the game will try to load the track from that file instead of generating a new track.
The goal is to replace the file for a given song to make the game load a different track for that song.


All generated tracks can be found under:
"C:\Users\<username>\AppData\LocalLow\Icetesy\Melody's Escape 2\Tracks Cache"

There can be multiple tracks for the same song for the different levels of Obstacle Density.
Depending on what difficulty mode you play, the game will try to open a different file. You can identify the correct one by looking at the number at the end of the filename:
  0 = Low/Relaxing    - up to 180 bpm (halftime 90 bpm)
  1 = Medium          - up to 200 bpm (halftime 100 bpm)
  2 = Extreme/Intense - up to 220 bpm (halftime 110 bpm)


As long as the file is correctly formatted, the game will let you play whatever is written in it. If the file is not correctly formatted, the game will generate a new track and overwrite your file. If you want to protect your file from accidentally getting deleted, make a copy of it and store it in a different directory.

You can force the game to generate a new track by deleting the track file.
It's also possible to temporarily deactivate "Cache track data" in the settings to play the default version of a song. This will not delete any of the cached tracks and they will be available again after you reactivate the setting.


It can be problematic if you use different songs that have the exact same filename, because the game will treat them as the same song and will try to load the cached track of whatever song got opened in the game first. 

-------

USAGE:

To use the script, you need a song you want to play in ME2 as well as a slowed-down version of the song. Open both songs inside the game using the desired object density level with "Cache track data" enabled to generate the tracks. The script will use both tracks to map the obstacles from the speed-adjusted version into the track of the original song.

By default the script will ask about the names of the songs that will be used for the conversion and will automatically overwrite the track data of the original song.
The script keeps the intensity levels and transitions from the original track and converts all slides that are considered too short into regular notes. This behavior can be adjusted by using -OVERWRITE_TRANSITIONS and -MINIMUM_HOLD_DURATION <number> (if hold duration is 0 the script will not change any slides. The default is 17 hundreds of a second).

To get good results, the alternative version of the song should be slowed down at least enough so that its tempo falls below the next-lowest BPM threshold (for "Extreme" object density it should fall below 220 or 110). Being only slightly below the BPM threshold can lead to fewer obstacles being generated. Slowing down a song by more than 50% may give unpredictable results.


You can either execute the script "ME2_SpeedAdjustedSongTrackConverter.ps1" directly or use the "ME2_SpeedAdjustedSongTrackConverter.bat" file.
It's necessary to use the .bat file if unsigned script execution is disabled on your system (Windows disables this by default for security reasons). You can't use any additional arguments when executing the script using the .bat file.

-------
