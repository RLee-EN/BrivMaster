Briv Master is a consolidated Idle Champions addon for Script Hub. It aims to provide comprehensive Briv-based gem farming without needing multiple additional addons.

Requires ScriptHub by MikeBaldi and Antilectual (the latter being the current author), which can be found at https://github.com/antilectual/Idle-Champions, which also hosts the BrivGemFarm addon on which BrivMaster is based.  This was formerly hosted at https://github.com/mikebaldi/Idle-Champions. This addon replaces the functionality of 3 of ImpEGamer's addons from https://github.com/imp444/IC_Addons: HybridTurboStacking and LevelUp, which are full replacements, and RNGWaitingRoom on which the 'Casino' in BrivMaster is heavily based.

This addon would not have been possible without the work of those who came before.

Briv Master is available at https://github.com/RLee-EN/BrivMaster. It requires specific imports, the generator for which can be found at https://github.com/RLee-EN/BrivMaster-Imports. The latter responsitry contains the imports themselves, however I cannot commit to always updating them promptly.

This ReadMe has been written 11Nov25 for BrivMaster v0.2.1. Changes are actively being made so things may have changed by the time you read this! When reviewing settings note that many options which might not be intuitive have tooltips to aid you.

# Environment

BrivMaster requires the IC Core addon to be enabled. This is enforced by ScriptHub. The About addon is recommended.
Do not load BrivGemFarm or addons that modify it, and in general it is advisable to only enable addons you are actively using.

You require a modron core with automation to farm. Four formations are used, Q,W,E which are named after their formation hotkey, and M, which is short for Modron and is the formation selected in the modron core
The difference between Q and E will depend on whether feat swapping is being used or not. Feat swapping is the use of feats to give Briv 2 different jump values, one for the Q formation and one for the E formation, to give more route options. This allows use to use jumps that are not paractical on their own as they'd either hit bosses, or require so many walks as to be inferior to a lower jump value. Emmote's route calculator (https://emmotes.github.io/ic_scripting_routes/#stacksTab_pure4TT_500_100_490_2_q_1_1_1_0, this has a Tall Tales 4J route selected) is an invaluable tool in setting this up. In this document feat swap setups are written in the style of 12/11J, 6/4J. Those using the round-down feat sometimes written in the style of 12-1J (one item level from 12J) in other resources.

In general feats should not be saved in these formations. If you are concerned about forgetting to set feats, e.g. on Elly after using her for gold farming, saving into M is acceptable. Emmote's site can again help with example formations: https://emmotes.github.io/ic_scripting_routes/#formsTab.

Without feat swapping:

	Q: The farming team with Briv
	W: The stacking team, with Briv at the front, possibly only Briv. When online stacking the relevant supporting champions must be included as well.
	E: The farming team with Briv removed
	M: The team to start the run with. Only champions in this formation can have specialisation choices taken. Regardless of using feat swap, a different jump value can be used in the Modron formation to control the start of the route, allowing bosses to be avoided. For example, a 9J route could have 4J in M to allow it to land on z1 instead of z6 without walks. Whether that is a benefit or not for an individual setup would need testing

With feat swapping:
	
	With feat swapping Briv must have feats saved in each formation, to ensure that changes are applied consistently. When using Thunder Step this feat will be sufficent
	
	Q: The farming team with Briv in the higher jump configuration (e.g. 12 for 12/11J)
	W: The stacking team, with Briv at the front, possibly only Briv. When online stacking the relevant supporting champions must be included as well. When using Ultra stacking (below) Briv must be configured to match the jump value associated with the stack zones selected
	E: The farming team with Briv in the lower jump configuration  (e.g. 11 for 12/11J)
	M: The team to start the run with. Only champions in this formation can have specialisation choices taken. Regardless of using feat swap, a different jump value can be used in the Modron formation to control the start of the route, allowing bosses to be avoided. For example, a 12/11J route could have 9J in M.

# Settings

BrivMaster presents itself in 3 ScriptHub tabs. The following details the contents of these tabs. 

## Briv Master

This is the 'home' tab of the addon, and is intended to be the one shown during general use - the other two contain settings that will not need to be reviewed regularly

Buttons:
	Start the gem farm script
	Stop the gem farm script
	Reconnect the hub with the script (e.g. when restarting the hub without restarting the script)
	Save settings - this saves settings from all 3 tabs
	Reset Stats

Cycle display:
	Mostly relevant when running hybrid stacking (which is the mid to end game method of stacking), this displays progression towards the next offline restart / stack, e.g. with an 'Offline every: x runs' setting of 40, this will initially display '1/40', and a restart will normally occur on Run '40/40'. When forcing an offline (see below) this will show 'FO' after the cycle numbers.

Run Control:
	Offline stacking: Controls whether game restarts are allowed (stacking or otherwise). Normally on, shown by a green indicator. These can be disabled whilst the script is running by pressing 'Pause', which will be shown by a red indicator. The button will change to 'Resume' which can be used to allow restarts again
	Queue: Queue an offline restart for the next run, regardless of the above general setting. A red indicator is normal operation, with a green one showing that a restart is queued. Once the restart run starts, this will clear (since it specifically reflects the next run). The forced offline will show in the Cycle display above.
	
	> Author's Note: These options are intended for use when playing other games that you do not wish to be interupted by loss of focus as IC restarts whilst using Hybrid stacking (again, the mid-end game method). Whilst playing such a game you can disable offline restarts, preventing those interuptions, and manually queue a restart when taking a break to clear memory bloat which will otherwise degrade performance very significantly.
	
	Restore Window: Toggles whether focus is return to the IC window when the game is restarted or not. The default at script start is set by an option presented later.
	
	Strategy: This displays the RouteMaster's 'strategy' based on the read game state and your settings, including Thellora's jump target, the stacks required, and the jump number (or numbers when feat swapping), along with the target zone.
	
	> Author's Note 1: Thellora's jump will not display correctly for the first run if she is not in the field when the script is started. It will be update during the first full Run
	> Author's Note 2: The jumps are displayed in zones jumped, not Briv 'J' number, i.e. 9J is listed as 10z/J, as that is the number relevant to routing - from z1, a '9J' Briv jumps to z11, having proceeded 10 zones
	
	Stacking: The expected stacking to be performed this run, or after stacking the result. This will showing the stacking intent even if no stacks are actually required, i.e. it shows where stacking will occur if needed
	
	Stage: Shows the current progression of the script through the run
	
	Last Close: The reason for the last closure, e.g. a restart, recovering from getting stuck
	
	Current Area / Run (s): The time taken in the current area and current run. Note that due to the limited refresh rate of the display, the area time will generally show 0.0s outside of the Casino or stacking
	
	Current SB / Haste Stacks: Briv's current Steelbones and Haste stacks
	
Run Stats:
	This group shows statistics based on the runs completed, with timings and rewards received
	
Chests & Daily Platinum:
	Briv Master can buy and open chests, and claim daily login rewards. The log displays the last action, and can be expanded using the button beside it.
	Click the cog icon for the settings for this tool:
	Gold to buy per call: Number of gold chests to buy per server call. Should generally be left at 250 as buying chests is a fast operation
	
	> Author's Note: Buying Silver chests is not supported because there is no reason to do so. Consider other tools if you really want to buy Silver chests
	
	Goild/Silver to open per call: Number of chests to buy per call. Whilst IC allows 1000 to be opened at a time this can result in a very long servercall which has the potential to impact the game, e.g. when resetting, so using a smaller amount is advised to keep the buy time (which is displayed in the log) lower. Aim for less than 4s. Gold chests are much slower to open than Silvers (e.g. I am using 150 Gold / 500 Silver)
	
	Reserve Gems: Stay above this number of gems when purchasing chests. Use this to ensure you can always buy a needed Feat or such
	
	> Author's Note: Gems are not useful directly - you use them to buy chests, which lead to iLevels. Do not hoard them! A pile of gems does nothing for you - invested iLevels will. Only set this to what you might actually need - if saving for a Modron Core, 500000, otherwise much less.
	
	Reserve Gold / Silver: Stay above this number of each chest when opening. Reserving a small number of gold chests allows you to get the feats for new champions as soon as you unlock them.
	
	> Author's Note: Reserving Silver is not useful. I am unsure why it's an option...
	
	Claim Daily Rewards: Enables claiming of daily rewards. The log will report the standard and premimum reward claim status, along with the premimum duration remaining if applicable
	
	> Author's Note: The first check of daily rewards will not be made for a minute after starting, to avoid spamming the server when testing and restarting the hub a lot. After that the check will be made every 8h, or at the reported reset time. This feature is based on Emmote's ClaimDailyPlatinum addon available at https://github.com/Emmotes/IC_Addons.
	
Game Settings:
	Game settings are important to farming; settings like the framerate cap can slow down a farm, and the Modifer key based levelling requires that the appropriate key binds are set. Briv Master allows 2 profiles to be defined, and they can be swapped between using the radio buttons. The selected profile saves with the rest of the settings. Briv Master will never automatically modify game settings, but checks periodically that they match the selected profile so that corrective action can be taken if needed. This is generally the case after modifying settings in-game.
	
	> Author's Note 1: I use one profile for farming (which is the one I save as the default) which is set to the resolution I use for farming, and another for other activities which is set to a higher resolution.
	> Author's Note 2: This feature is based on Emmote's GameSettingsFix addon available at https://github.com/Emmotes/IC_Addons.
	
	Set Now: Applies the current settings profile; the game must be closed. The result of the check will be reported.
	
	Click the cog icon for the settings for this tool. Two columns of entries are available for each setting; one for each of the 2 profiles.
	
	Name: You can give the profile a name, e.g. 'Farm'
	
	Framerate: The game's framerate cap; the default 600 is a good starting point for most. Mobile devices with low power / thermal limits might benefit from lowering it.
	
	% Particles: % of Particles rendered. Should be 0 for farming.
	
	H/V. Resolution: Game resolution
	
	Fullscreen: Self-explanatory
	
	Cap FPS in BG: Cap the game's framerate when in the background. This needs to be off for farming.
	
	Save Feats: Whether feats should be included in new formation saves by default. Highly recommended to turn this off.
	
	> Author's Note: Overwriting a save does not use this option - instead it will by default save feats if the existing formation has any saved.
	
	Level Amount: I am not even going to let you screw this up.
	
	Console Portaits: Enable for face-on portraits, Disable for three-quarter view. This is personal preference.
	
	Narrow Hero Boxes: Enable for narrow hero boxes to allow all 12 to be displayed at once. Personal preference, but disabling it might make issues with champions in the hidden seats harder to identify.
	
	Show All Heroes: Personal preference.
	
	Swap x25 and x100: By default IC uses CTRL as the shortcut for x100 levelling, and CTRL+SHIFT for x25. As we're using x100 as standard we do not need a shortcut for it, and swapping them allows x25 which we do want to use to have a single modifer key instead of two - this means less key presses are required , and thus less chances for things to go wrong. Should be Enabled.
	
Ellywick Non-Gemfarm Re-roll Tool:
	As the name suggests, this tool is not for use whilst farming, but leverages the logic for Ellywick to allow re-rolling in other situations; most likely when gold farming which is reflected in the default card selection. DM will be used automatically if present.
	
	Min:Max: The target number of each card can be entered. The default of 4:5 Moon and 0:1 Fates means that any combination of 4 Moon and 1 Fate, or 5 Moon are accepted outcomes.
	
	> Author's Note: I use these settings as I find 5 Moon takes to long to get, you are free to just set 5:5 Moon and the others to 0:0 if you have more patience than I do, but note that they are not saved.
	
	Start: Start re-rolling. The current status is displayed below the buttons, including the number of re-rolls used once completed

	Stop: Stop the tool early.
	
## BM Route

This tab focuses mostly on routing of the run

Starting Strategy:
	Combine Thellora and Briv: There are two primary ways for a run to start.
		1) Non-combining. Thellora jumps without Briv, landing on Favour+1, e.g. at 300 favour she jumps to zone 301. In this scenario Thellora is NOT saved into the Modron formation and the Casino (Ellywick card draw) is performed in zone 1
		2) Combining. Thellora and Briv jump together, landing on Favour+Briv Jump+1, e.g. at 300 favour and 9J Briv they land on 310. Note this is not the same as if they jumped seperately, where it would be Thellora to 301 (favour+1) then Briv to 311 (9+1) as the 'normal' next zone is only factored in once. In this scenario Thellora is NOT saved into the Modron formation and the Casino (Ellywick card draw) is performed after Thellora's jump
	Generally combining is better, as it removes a transition, but some routes and favours may not work well with it, e.g. if they land on a boss as a result.
	
	> Author's Note: The level settings (below) are saved independently for combining / non-combining.

	Avoid Bosses: When configuring a route landing on a boss is to be avoided, during recovery however Thellora may not have enough charges to make the usual jump, and will land elsewhere. If she would land on a boss zone this option when enabled will break the combine if doing so would cause her to no longer land on a boss zone. This should be enabled on any adventure with armoured / hit based bosses, and is likely a good idea for any adventure.
	
Route: This grid serves two purposes,
	1) Defining the route, which is the zones that the script will proceed on the Q formation and therefore also which will use the E formation. This should be taken from Emmote's routes site at https://emmotes.github.io/ic_scripting_routes/#gemTab. Highlighting the triangle for the zone green means that the Q formation (which is with Briv, or the higher jump for Feat Swap) will be used for that zone, and corresponds to the zone being ticked in the web tool.
	2) Defining the zones that online stacking will be performed on. Different zones have different enemy compositions that can be more or less favourable for stacking. For Tall Tales, the ranged enemies attack much faster than the melee ones (3s vs 5s between attacks), so a ranged only zone gives the highest stacking rate, then mixed zones, and then melee only. The projectiles from ranged enemies can have signficant impact on framerate however, which might result in a lower total stack rate and therefore the appropriate zone for your PC can only be determined by testing. Highlighting the 'stack' icon red means that stacking is allowed on that zone.
	
	> Author's Note 1: Do not just select zones on-route, as you might go off route recovering from problems; include all the zones of the type you are interested in. Also consider enabling every zone after the last one of interest to act as a fall-back.
	> Author's Note 2: The UI allows boss zones to be selected for stacking, but these will be ignored.
	
	Import/Export: As these settings are time consuming to enter (90 selections!) they can be exported to a short string to share, or imported from a string. The strings contain two parts ordered as above; leaving one part blank will result in only the other being changed, e.g. {3zXoa17wA,} will set a 9J route for Tall Tales without changing the stacking settings. Some samples are provided below for Tall Tales; please review these, particularly the stacking selections, if you wish to use them.
	
		4J Offline				{973oe9D3g,________w}
		6/4J Offline			{2xZxxK3rQ,________w}
		9J Melee stacking		{3zXoa17wA,x4DjGAbxA}
		11J						{-p-hvk_gw,MB0MY8gGg}
		12/11J					{BeR7QfAfg,MB0MY8gGg}
		14J						{hSFIV5CEA,AAAMY9gGg}
		14/9J					{t_Hvn___w,AAAIYxgGg}
		14/9J Ultra stacking	{t_Hvn___w,FrCtChrWg}

Briv Jumps: The Briv jump value for each formation. The formations are described in more detail earlier in this document.
	1) Q will be Briv's standard jump (e.g. 9 for, well, 9J, 12 for 12/11J)
	2) E will be 0 for non-feat swap, or the lower jump for feat swap (e.g. 11 for 12/11J)
	3) M will reflect the jump Briv will have in the Modron formation
	
Stacking Zones:
	Offline: Offline stacking or blank restarts will be performed on or after this zone during normal operation. When flames-based stacking is enabled this will be used for 0 flames cards. If offline stacking, set this based on the stacks needed.
	
	Minimum stack zone: The minimum zone Briv can farm stacks on; that is the lowest zone that the W formation does not kill enemies. Used for recovery
	
	Flames-based: When online stacking it is generally worth having Ellywick in the formation as her flames cards speed up the arrival of enemies, however when running hybrid with offline stacking the increased damage taken from flames cards will impact the number of stacks Brivs generates on a given zone. These options allow for a different offline stack zone to be configured based on the number of flames cards Elly holds to compensate for this.
	
	> Author's Note: Remember that when using the Gem feat 5 flames is impossible so that value is not worth setting
	
	Online Stack with Melf: When enabled online stacking will be performed when Melf's increased spawn count effect is active, within the range specified. Melf has 3 different buffs that are 'randomly' active, but being a computer program it is only psuedo-random and is possible to predict.
	
	> Author's Note: For the curious Melf effective active in each block of 50 zones are based on the number of resets your account has performed in total

	Min/Max: The range that online stacking can be performed in. This should be as wide as possible to allow as many 50-zone segments as possible to be covered and so to maximise the chances of Melf's spawn speed buff being available. Due to the buffs being in those 50-zone blocks there is no need to encompass the whole range. For example if your route hits z49, setting the minimum to z349 would allow the z301 to z350 segment to be used, even if your stacking team's damage is too high to stack at say z330.
	
	Ultra Stack: Normally with online stacking the party arrives, swaps to whichever of Q or E is appropriate, completes the zone, and then swaps to W. Any champions not already levelled are then levelled as stacking begins. This has some drawbacks - the first kill in the zone is wasted, and if levelling of important champions scuh as Melf is required it can delay their effects. It's also possible for an unfortunately timed attack to block the placement of a champion that was not yet levelled at all. 'Ultra' stacking is a different approach whereby the formation swap happens when exiting the previous zone, any levelling needed starts during the transition and the zone is completed once done via Briv's ultimate attack. This does therefore require sufficent BUD to clear the zone; when this option is selected BrivMaster will automatically select between Ultra and normal online stacking based on BUD and the stack zone for that run. Important: All allowed stack zones, configured in the Route grid described above, must use the same Briv configuration (i.e. all be Q 'Jump' zones, or all be E zones, and for feat swap the relevant feat must be saved on Briv in the W formation. Due to switching whilst in the previous zone, Diana should be included in the W formation.
	
	> Author's Note: In my testing Ultra stacking is superior to normal stacking, but your mileage may vary. Particularly at lower general levels of items accross the farm team, blessings, etc, your BUD may not be high enough for it to activate very often
	
Offline Settings:
	Platform Login: When a stacking restart is needed BrivMaster will restart the game early and hold it after platform login, in order to be as consistent as possible. IC requires 15s to elapse between the save when closing and the game login when restarting to trigger offline progress, therefore the upper bound for this value is 15000ms. As some time elapses between platform login and game login it should be possible to reduce this somewhat; slower PCs will be able to reduce it further to compensate.
	
	> Author's Note: My relatively fast PC (13900KS) got consistent results with 13750ms.
	
	Restart sleep: The amount of time to wait between the game closing and be restarted when going offline, whether stacking or not. This should generally be left at 0, but some platforms can have issues detecting the game's state if it is instantly restarted, and a small delay can help; suggest increasing in 50ms steps.

	Timeout factor: Controls the time allowed for the game to start and close. The start time is 10s times this value, and the close value a number of seconds equal to it. For starting the game if it fails to open in time is is closed and then restarted (which, if not allowed enough time on a slow PC, can result in it being stuck in an infinte loop), and for closing once the time expires more aggressive commands are used to force the game close, which will interrupt a save if done too early.
	
	> Author's Note: A fast PC should use the default of 5. A very slow mobile device might benefit from values at high as 10.
	
	Offline every x runs: Often referred to as FORT (Force Offline Run Threshold), taken from the BrivGemFarm setting name. This is the frequency off offline runs. A value of 1 disables hybrid stacking and will restart every run if stacks are required, a higher value means to restart every x runs.
	
	> Author's Note: The optimal value will depend upon the user's system and platform, as memory bloat can be impacted by things like platform and drivers, and also by the type of offline being done, as it is based on the opportunity cost of doing an offline stack; therefore a relay blank restart has less impact than offline stacking for doubles, which in term has less imapct than offline stacking for singles. The ideal value is likely between 40 and 80.
	
	Restore window: Whether focus is returned to the IC window when the game is restarted or not. Can be toggled at run time on the Briv Master tab.
	
	Blank restarts: The purpose of restarting during hybrid stacking is to clear memory bloat that slows the game. Blank restarts provide an alternative: always online stack, and simple close and immediately re-open the game to clear that bloat out.
	
	> Author's Note: Whether this is beneficial or not will depend on how long online stacking takes verses offline stacking, which therefore also depends on the number of stacks required for each run, and therefore is very user-dependent. With an end-farm on a decent PC Blank restarts should be superior.
	
	Relay restarts: Instead of closing the game and immediately restarting it during a blank restart, this option starts a new instance of the game before the old one is closed, and holds it at platform login ready to go. This can significantly reduce the time required to preform a blank restart. This is not compatible with the EGS launcher which will not allow a second copy of the game to be started.
	
	Relay start offset: The number of zones prior to the Offline zone that the relay will start. If stacking with Melf and the online stacking zone is within the Relay window, this will be be offset from that stacking zone instead. In any case the relay will not start until after Thellora's landing zone
	
Ellywick's Casino:
	Ellywick's Gem cards provide an immense boost to our gem income. Briv Master allows for re-rolling using her ultimate, including a second use via Dungeon Master(DM)'s ultimate to increase the average number of gem cards. Options in this section control this.
	
	> Author's Note: For early farms doing short runs (perhaps to z500 or less) the use of DM to get a second re-roll is not likely worth the large relative increase in run time.
	
	Target/Redraws/Min Gen: These are presented in two sets, one for Melf's spawn-more buff being inactive active in the Casino zone, and one for it being active. This is due to the increased spawns signficantly speeding up Ellywick's card draw, and therefore reducing the opportunity cost of re-rolls. These are generally the same when using the Gem feat.
	
		Target: The number of Gem cards to aim for; if this cannot be achived and a redraw is available, the re-roll will be used. This should be 3.
		Redraws: The number of redraws allowed (via Ellywick's ultimate). This should be 1 without DM, or 2 with DM. DM should be used if available so this is normally 2.
		Min: This is the minimum total cards to hold before leaving the Casino. If your route does not hit bosses, this should always be 0. If your route hits bosses, it should be set to allow Ellywick to reach a full hand before hitting your first boss. 5 is the 'safe' option, but it might be possible to use 4 and get the same result.
	
	> Author's Note: This option pre-dates the Gem feat, and might be beneficial for this without it (although that should be addressed with a high priority). In that case using target/redraws of 3/1 base and 3/2 with Melf may be beneficial
	
	Target post-Casino: If re-rolls are available after the Casino is exited, this is the number of Gem cards to re-roll for. This is not generally relevant and should be left at 2.
	
	> Author's Note: This is a legacy setting, which was more relevant before the Gem feat. With DM's ultimate being used for a 2nd re-roll where necessary in the Casino for a standard setup, it doesn't serve much purpose. When using the mixed 3/1 base 3/2 Melf setup described in the previous note, this allows for Elly's second ultimate to be used in-flight. Note that in-flight re-rolls have a significant risk of a game save occuring whilst holding few  / no gem cards, which would be rather determinental.
	
Window Options:
	These options control the appearance of the farm script window.
	
	Screen Position (x,y), the x (horizonal) and y (vertical) location of the gem farm window when the script starts, measured from the top left of the screen in pixels.
	
	Hide: If selected the farm window will not be displayed.
	
	Dark Icon: Select to use a window icon with a black background instead of the default transparent one. It looks pretty bad at the moment.
	
## BM Levels
	This tab focuses mostly on champion levelling. After a little side quest, anyway.
	
Game Location:
	This section specifies where the game is and how it is launched. It can be populated automatically whilst pressing the 'Copy from IC' button. If using the EGS launcher, select the EGS tickbox first.
	
	Executable: The name of the game executable, normally IdleDragons.exe. This shoulld not need to be changed.
	
	> Author's Note: Some methods of running two farms on the same PC require one of the executables to be renamed, which is why this is editable at all.
	
	Location: The game install location.
	
	Launch Command: The command used to launch the game. For non-EGS setups this will just be the Executable and Location fields combined, however for EGS it will either be the EGS URI for the game, or if using an alternative to the EGS Launcher the appropriate command will need to be added here.
	
	Hide launcher: Selecting this option will hide the window created by invoking the Launch Command. Use this only for 3rd party EGS launchers that might otherwise pop up a command window. Using it with the game directly will cause it to fail to start.
	
	EGS & Copy from IC: Described in the introduction to this group.
	
Levelling Options:
	Max sequential F-keys: The maximum number of levelling commands that will be send in a batch. A higher number increases the likelyhood of drifting whilst levelling, a lower number means more overhead in the script and may delay levelling of important champions at the start of the run.
	
	Default level: If a champion is saved a formation but no level is specified in the Level Manager section below, this option determines if it is considered to be set to level 0 (i.e. not levelled) or level 1, and will thus be placed.
	
	> Author's Note: This option may be deleted soon; if a champion is meant to be used it should be set up in the options, if it is not it should not be saved in the formations.
	
	Modifier key for x10/25: Modifier key levelling allows for champions to be levelled to amounts that are not multiples of 100, but applying either CTRL or SHIFT. These options set the modifer to use and the level up amount that it is bound to. This must match the the in-game key bindings; the Game Settings options can help maintain that. It is recommended to use the default of CTRL for x25.
	
	> Author's Note: Only one value can be used at once (i.e. you can have x100 and x25, or x100 and x10, not x100, x25 and x10. This is as currently there is no particular need for it the capability to do so.
	
	Briv Level Boost: When online stacking this option will dynamically level Briv based on the stacking zone; the intent of this feature is to allow Briv to be set to level 200 (the first multiple of 100 after he gets his farming-relevant Metalborn upgrade) to minimise the amount of levelling performed, but to also allow him to survive when stacking on higher zones.
	
	Safety Factor: When using Briv Level Boost, this is how many more times expected incoming damage from a full zone of 100 enemies he should have in health. This value depends on how long stacking takes, as mobs will gain more enrage stacks the longer it takes. For a faster stack (up to 5s) the default of 8 is appropriate. Slower stacks may require more to be reliable.
	
	Dynamic Diana: Diana can give excess chests after the daily reset. This option will raise her level to 200 for Electrum Chest Scavenger from 3 minutes before the daily reset to 30 minutes after. Her level in the main options should be left at 100.
	
	> Author's Note: This is attempting to profit from a bug, but perhaps if enough people do so it might get fixed...
	
	Smart Tatyana in Casino: When using a setup that has Melf in the M formation, this option will only level Tatyana (if also present) at the start of the run if Melf's spawn-more buff is not active. This may be beneficial because a decent level Melf (~30 spawn) is able to allow Ellywick to draw rapidly alone, and the extra champion plus load from having a full Tatyana wave active at once might not be worth it. If using this option, Tatyana's 'Start' level should be 0.
	
	Surpress From Row: If selected champions other than Briv will not be levelled if in the front row of the M formation at the start of the run. This is useful to ensure any attacks made against the formation whilst the Casino runs are directed at Briv, and thus grant Steelbones stacks. Do not use if the other champion in the front row is needed for some reason.
	
	Ghost Level: During the Casino, level champions that are not part of the formation so long as they will not be placed, either due to all slots being full or only slots at the front being available and the formation being under attack. This option makes it more likely all speed effects will be ready for the first normal zone. Only applied when combining, and should normally be enabled.
	
Level Manager:
	This section allows the levelling of champions to be configured. The formations should already be set up in game before reviewing it.
	
	Refresh Formations: Updates the list of champions from the saved formations in-game.
	
	Champion List: Each champion is displayed with their seat and name, along with their level selections
		Start: The level this champion is to be raised to at the start of a run; prior to the end of the Casino. This should only be set for farming-relevant champions, e.g. if bringing a champion along for their Scavenger effect, or for achievement progress, they should have a Start level of 0. 
		Priority: The priority to be applied to levelling this champion at the start of a run (only, it does not apply to the Normal selection). A higher number is a higher priority. Options with a prioirty number followed by a second number apply that priority only until the champion has been raised to the level specified by the second number, after which it becomes 0. This is useful for champions that need to be placed and gain early abilities, but do not need to be fully levelled urgently. 4↓100 means 'Priority 4 until level 100, after which 0'. Priority 1 is used automatically by the script for some functions, so it's generally best to use the values above 1 to meet specific requriements.
		
		> Author's Note: A prime use for this is Ellywick; we want her Deck of Many Things ability, gained at level 80, as soon as possible so that she starts counting kills, but her Start level will be higher as she needs to get Call Of The Feywild at level 150 in order to make redraws in the Casino. There is no reason to have her ultimate available in z1 at all, so x↓100 would therefore be appropriate for her, allowing champions that may provide a benefit to be levelled instead.
		
		Normal: The post-Casino level for this champion. This is frequenty the same as the Start level, but in the case of an extra champion as described in the Start text they might have a level here. A champion that Diana that gains a potentially desirable ability (Scavenger) could be set to Start 100 and Normal 200 so she picks up that Scavenger ability without interfering with the start of the run (although in that case, consider Dynamic Diana above).
		
		Formations: This grid displays the formations that each champion is in, as an aid to configuration and also to aid in sharing your setup. Champion levels should always be rounded up to the next 100 unless the use of modifier levelling is specifically desired; remember that an x10/x25 level-up requires double the key actions as an x100, and is less reliable.
		
		The following provide the Author's current setup, which is an end-game farm using Dynahier (rather than a BBEG) and Baldric. The #scripting channel in the IC discord is a good place to ask for help for other setups.
		
		- Thellora: 1/0/1 - she is normally placed automatically by the game without the script's intervention, but this will place her otherwise, normally if she is not present when the farm is started.
		- Widdle: 300/0/300
		- Dynaheir: 100/0/100
		- Briv: 200/3/200 - this example is based on a fast PC that can combine reliably with Briv being the third and fourth level-ups performed. When starting out it's best to have him as the highest priority if combining.
		- Dungeon Master: 200/2/200
		- Minsc: 100/0/100
		- Hew Maan: 220/0/220 - this example has Tatyana in M, so Hew Maan cannot have a spec saved. This avoids his spec pop-up which would appear if 300 was used.
		- Tatyana: 100/4/100 - see comment on Briv.
		- Diana: 100/2/100
		- Ellywick: 200/4↓100/200 - see priority description above for the reason this is benefical, and also the comment on Briv.
		- Imoen: 50/0/50 - Imoen gains the ability we need at level 40, and an ability of non-trivial complexity at level 60 (Perseverance, counting Favoured Foe kills). As Imoen is not important at the start of the run, she can use modifier levelling with much impact to avoid that ability.
		- Melf: 70/2/70 - this example has Baldric in M, so MElf cannot have a spec saved. This avoids his spec pop-up which would appear if 100 was used.
		- Baldric: 200/2/200
		
	> Author's Note: When saving Briv Master's settings, level settings will be ignored if no champions are displayed at all. Take care if tweaking options whilst doing something else in-game, as it is a little bit too easy to overwrite your settings. Once you have things configured to your satisfaction making a backup of IC_BrivMaster_Settings.json might be sensible.
	
I hope that this project is useful to you, either directly or through ideas that have shared with BrivGemFarm and its addons (largely by Emmote).

Irisiri / R. Lee. It turns out I'm not actually a Night Elf rogue...