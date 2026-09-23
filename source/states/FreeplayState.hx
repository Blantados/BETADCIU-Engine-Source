package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;
import objects.FunkinSprite;
import objects.freeplay.*;
import objects.freeplay.DifficultyDot;
import objects.ui.AtlasText;

import options.GameplayChangersSubstate;
import shaders.AngleMask;
import shaders.StrokeShader;
import substates.ResetScoreSubState;

import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;
import haxe.Json;

class FreeplayState extends MusicBeatState
{
	// tried to organize and make the code a bit more readable and understandable

	/* constants */
	public static final DEFAULT_DOTS_GROUP_POS:Array<Int> = [260, 170];
	public static final DEFAULT_SONG_COLOR:Array<Int> = [146, 113, 253];
	public static final DRAW_DISTANCE:Int = 6;
	public static final DOT_DISTANCE:Int = 30;
	public static final DOT_GROUP_OFFSET:Float = 14.7;
	public static final MAX_DOTS_PER_ROW:Int = 8;

	/* statics */
	private static var curSelected:Int = 0;
	private static var lastDifficultyName:String = Difficulty.getDefault();
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;

	/* songs */
	public var songs:Array<SongMetadata> = [];

	/* sprites & groups */
	private var grpSongs:FlxTypedGroup<SongCapsule>;
	var difficultyDots:FlxTypedSpriteGroup<DifficultyDot>; // would be better if the dots and the sprites were the same thing? maybe, but idc.
	var diffSprite:DifficultySprite; // difficulties as sprites!
	var albumRoll:AlbumRoll;
	var fpScoreDisplay:FreeplayScore;
	var txtCompletion:AtlasText;
	var bg:FlxSprite;
	var dj:DJBoyfriend;
	var topLeftCornerText:FlxText;
	var ostName:FlxText;
	var tabSelectHint:FlxText;
	public var bottomText:FlxText;
	public var bottomString:String; // not a sprite but its used in the music player to change the 'bottomText'
	var bottomBG:FlxSprite;
	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	var player:MusicPlayer; // not a sprite too but idc
	var stickerSubState:StickerSubState; // technically a sprite

	// scrolling texts
	var moreWays:BGScrollingText;
	var funnyScroll:BGScrollingText;
	var txtNuts:BGScrollingText;
	var funnyScroll2:BGScrollingText;
	var moreWays2:BGScrollingText;
	var funnyScroll3:BGScrollingText;

	/* tabs */
	private var _weeksByTab:Map<Int, Array<{week:WeekData, index:Int}>> = new Map();
	private var _weeks:Array<{week:WeekData, index:Int}> = [];
	private var _betadciuWeeks:Array<{week:WeekData, index:Int}> = [];
	private var _bonusWeeks:Array<{week:WeekData, index:Int}> = [];

	/* other vars */
	var currentTab:Null<Int> = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	var lerpScore:Float = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var intendedColor:Int;
	var instPlaying:Int = -1;
	var holdTime:Float = 0;
	var hintTimer:Float = 0;
	var stopMusicPlay:Bool = false;
	var canMove:Bool = true;
	var _lastVisibles:Array<Int> = [];
	var saturatedColor:FlxColor;
	var desaturatedColor:FlxColor;
	var angleMaskShader:AngleMask = new AngleMask();

	public function new(?stickers:StickerSubState = null) {
		super();

		if (stickers != null) stickerSubState = stickers;
	}



	// used for the tabs

	override function create()
	{
		Paths.clearStoredMemory();

		if (FlxG.sound.music == null || !FlxG.sound.music.playing || FlxG.sound.music.volume == 0 || MainMenuState.mainMusic) {
			FunkinSound.playMusic('songSelect', {overrideExisting: true, persist: true});
			FlxG.sound.music.volume = 1;
			MainMenuState.mainMusic = false;
		}
		
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		if (stickerSubState != null){
			this.persistentUpdate = true;
			this.persistentDraw = true;
		
			openSubState(stickerSubState);
			stickerSubState.degenStickers();
		} else {
			// Paths.clearUnusedMemory(); // this fucks up the stuff made on new() so.. yeah
		}

		persistentUpdate = true;

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if(WeekData.weeksList.length < 1) {
			noWeeksPopUp();
			return;
		}
		loadWeeks();
		
		// testing a saved tab system - update: it worked!
		// TODO: find a way to precache the tabs
		if (FlxG.save.data.freeplayTab == null) FlxG.save.data.freeplayTab = 0;
		currentTab = FlxG.save.data.freeplayTab;
		currentTab = Std.int(FlxMath.wrap(currentTab, 0, 2));

		loadSongs((_weeksByTab.get(currentTab) != null ? _weeksByTab.get(currentTab) : []));

		buildBackground(); // making this to debloat 'create()' a bit

		grpSongs = new FlxTypedGroup<SongCapsule>();
		add(grpSongs);

		createCapsules();

		buildUI();
		
		player = new MusicPlayer(this);
		add(player);
		
		changeSelection();
		updateTexts();
		super.create();
	}

	private function noWeeksPopUp():Void
	{
		FlxTransitionableState.skipNextTransIn = true;
		persistentUpdate = false;

		var errorMsg:String = "NO WEEKS ADDED FOR FREEPLAY\n\n"
			+ "Press ACCEPT to go to the Week Editor Menu.\n"
			+ "Press BACK to return to Main Menu.";

		MusicBeatState.switchState(new states.ErrorState(errorMsg,
			function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
			function() MusicBeatState.switchState(new states.MainMenuState())
		));
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int, ?album:String, ?difficulty:Array<Int> , ?bpm:Int, ?weekname:String, ?ostName:String)
	{
		if (album == null) album = "template"; 
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color, album, difficulty, bpm, weekname, ostName));
	}

	function loadWeeks() {
		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i])) continue;
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);

			if ((WeekData.weeksList[i].endsWith("-betadciu") && leWeek.betadciu == null) || leWeek.betadciu)
				_betadciuWeeks.push({week: leWeek, index: i});
			else if ((WeekData.weeksList[i].endsWith("-bonus") && leWeek.bonus == null) || leWeek.bonus)
				_bonusWeeks.push({week: leWeek, index: i});
			else
				_weeks.push({week: leWeek, index: i});
		}
		Mods.loadTopMod();

		_weeksByTab.set(0, _weeks);
		_weeksByTab.set(1, _betadciuWeeks);
		_weeksByTab.set(2, _bonusWeeks);
	}

	private inline function getColors(colors:Array<Int>):Array<Int> return (colors != null && colors.length >= 3) ? colors : DEFAULT_SONG_COLOR.copy();

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}


	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
			return;

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		lerpScore = FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;

		if (tabSelectHint != null) {
			hintTimer += elapsed * 2;
			var targetAmt:Float = (Math.sin(hintTimer) + 1) / 2;
			tabSelectHint.alpha = FlxMath.lerp(0.3, 0.9, targetAmt);
		}

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) //No decimals, add an empty space
			ratingSplit.push('');
		
		while(ratingSplit[1].length < 2) //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!player.playingMusic)
		{
			if (fpScoreDisplay.scoreShit !=  Std.int(lerpScore)) fpScoreDisplay.updateScore( Std.int(lerpScore));
			if (txtCompletion.text != Std.string(Std.int(lerpRating * 100))) txtCompletion.text = Std.string(Std.int(lerpRating * 100));

			// Right align the completion percentage
			switch (txtCompletion.text.length) {
				case 3: txtCompletion.offset.x = 10;
				case 2: txtCompletion.offset.x = 0;
				case 1: txtCompletion.offset.x = -24;
				default: txtCompletion.offset.x = 0;
			}
			
			if(songs.length > 1)
			{
				if(canMove) { // whoops
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if (FlxG.keys.justPressed.TAB) {
					changeTabs(FlxG.keys.pressed.SHIFT ? true : false);
				}

				if(FlxG.mouse.wheel != 0)
				{
					FunkinSound.playOnce('scrollMenu', 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
				}
			}

			if(canMove) { // whoops
			if (controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}
			}
		}

		if (controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FunkinSound.playMusic('songSelect', {overrideExisting: true, startingVolume: 0, persist: true});
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else 
			{
				persistentUpdate = false;
				FunkinSound.playOnce('cancelMenu');
				fadeDots(false);
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE)
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if(loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
							vocals.pause();
						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch(e:Dynamic)
					{
						vocals = FlxDestroyUtil.destroy(vocals);
					}
					
					opponentVocals = new FlxSound();
					try
					{
						//trace('please work...');
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
							opponentVocals.pause();
							//trace('yaaay!!');
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch(e:Dynamic)
					{
						//trace('FUUUCK');
						opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
				}

				FunkinSound.playMusic(PlayState.SONG.song, {startingVolume: 0.8, overrideExisting: true, pathsFunction: INST});
				FlxG.sound.music.pause();
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
				player.pauseOrResume(true);
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(!player.playing);
			}
		}
		else if (persistentUpdate && controls.ACCEPT && !FlxG.keys.pressed.ALT && !player.playingMusic)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			updateTexts(elapsed, true, poop, songLowercase);
		}
		else if(controls.RESET && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FunkinSound.playOnce('scrollMenu');
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	function changeTabs(reverse:Bool) {
		for (capsule in grpSongs.members) {
			capsule.kill();
			capsule.destroy();
		}
		grpSongs.clear();
		songs.resize(0);
		_lastVisibles = [];

		var tabToGo:String = "";

		currentTab += reverse ? -1 : 1;
		currentTab = Std.int(FlxMath.wrap(currentTab, 0, 2));

		PlayState.isBETADCIU = false;
		PlayState.isBonus = false;
		var arrToRead = _weeks;
		switch (currentTab) {
			case 0: tabToGo = "FREEPLAY";
			case 1: tabToGo = "BETADCIU"; PlayState.isBETADCIU = true; arrToRead = _betadciuWeeks;
			case 2: tabToGo = "BONUS"; PlayState.isBonus = true; arrToRead = _bonusWeeks;
		}

		topLeftCornerText.text = tabToGo;
		FlxG.save.data.freeplayTab = currentTab;

		loadSongs(arrToRead);
		if (songs.length == 0) return;
		createCapsules();
		
		curSelected = 0;
		changeSelection();
		changeDiff();
		updateTexts();
	}

	function loadSongs(arrToRead:Array<{week:WeekData, index:Int}>) {
		for (entry in arrToRead) {
			WeekData.setDirectoryFromWeek(entry.week);

			for (song in entry.week.songs) {
				var daAlbum = song[3];
				if (song[3] != null && Paths.image('freeplay/AlbumRoll/${song[3]}') == null) daAlbum = "template";
				var colors:Array<Int> = getColors(song[2]);
				final daWeekName = entry.week.weekName ?? WeekData.weeksList[entry.index];

				// i probably should find a better way to do this instead of pushing everything to the metadata
				addSong(
					song[0], // name
					entry.index, // week number
					song[1], // icon
					FlxColor.fromRGB(colors[0], colors[1], colors[2]), // colors
					daAlbum, // album image/text image
					song[4], // difficulty/stars
					song[5], // bpm
					daWeekName, // week name
					entry.week.albumOSTName // text used in the top right corner
				);
			}
		}
	}

	function createCapsules() {
		for (i in 0...songs.length) {
			Mods.currentModDirectory = songs[i].folder;

			final startRating:Int = (songs[i].difficultyStars != null && songs[i].difficultyStars.length > 0) ? songs[i].difficultyStars[0] : 0;
			var capsule:SongCapsule = new SongCapsule(320, 230, songs[i].songName, songs[i].songCharacter, songs[i].bpm, startRating, songs[i].weekName);
			capsule.targetY = i;
			capsule.distancePerItem.y = (110 * 0.8);
			capsule.visible = capsule.active = false;
			capsule.doLerp = true;
			grpSongs.add(capsule);
		}
		WeekData.setDirectoryFromWeek();
	}

	private function showChartError(e:haxe.Exception, item:SongCapsule, song:String):Void {
		var errorStr:String = e.message;
		if (errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(song), errorStr.length - 1);
		else errorStr += '\n\n' + e.stack;

		missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
		missingText.screenCenter(Y);
		missingText.visible = true;
		missingTextBG.visible = true;

		var errorSound:FlxSound = FunkinSound.playOnce('confirmMenu', FlxG.sound.volume - 0.4);
		var musicLength:Float = errorSound.length;

		if (item.songText.text != songs[curSelected].songName)
			FlxTween.tween(item, {alpha: 1}, musicLength / 1000, {ease: FlxEase.sineOut});
	}

	private function loadPlayState()
	{
		@:privateAccess
		if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
		{
			trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
			Paths.freeGraphicsFromMemory();
		}
		LoadingState.prepareToSong();
		LoadingState.loadAndSwitchState(new PlayState());
		#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
		stopMusicPlay = true;

		destroyFreeplayVocals();
		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}
	
	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic) return;

		var _prevIndex:Int = curDifficulty;
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		
		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		if (lastDifficultyName != diffSprite.difficultyId) 
			diffSprite.updateSprite(lastDifficultyName, change == -1 ? "left" : "right");

		missingText.visible = false;
		missingTextBG.visible = false;

		updateDifficultyStars();
		refreshDots(5, curDifficulty, _prevIndex);
	}

	function updateDifficultyStars():Void {
		var starsArray = (songs[curSelected].difficultyStars != null && songs[curSelected].difficultyStars.length > 0) ? songs[curSelected].difficultyStars : [0];
		var _diff = FlxMath.wrap(curDifficulty, 0, starsArray.length - 1);
		albumRoll.difficultyStars.difficulty = starsArray[_diff];

		for (item in grpSongs.members) {
			var songStars = (songs[item.targetY].difficultyStars != null && songs[item.targetY].difficultyStars.length > 0) ? songs[item.targetY].difficultyStars : [0];
			var d:Int = FlxMath.wrap(curDifficulty, 0, songStars.length - 1);
			item.updateDifficultyRating(songStars[d]);
		}
	}


	function rebuildDifficultyDots():Void {
		for (dot in difficultyDots) dot.destroy();
		difficultyDots.clear();

		for (i in 0...Difficulty.list.length)
			difficultyDots.add(new DifficultyDot(Difficulty.list[i], i));

		fadeDots(true);
	}

	function fadeDots(fadeIn:Bool):Void {
		for (dot in difficultyDots.group.members)
			fadeIn ? dot.fadeIn() : dot.fadeOut();
	}

	var prevDotAmount:Int = 0;
	function refreshDots(amount:Int, index:Int, prevIndex:Int):Void {
		var shiftAmt:Float = (DOT_DISTANCE * amount) / 2;
		
		difficultyDots.x = (difficultyDots.group.members.length > MAX_DOTS_PER_ROW) ? DEFAULT_DOTS_GROUP_POS[0] - DOT_GROUP_OFFSET * (MAX_DOTS_PER_ROW - 1) : DEFAULT_DOTS_GROUP_POS[0] - DOT_GROUP_OFFSET * (difficultyDots.group.members.length - 1);
				
		var curRow:Int = 0;
		var curDot:Int = 0;
		var daSong:SongMetadata = (curSelected >= 0 && curSelected < songs.length) ? songs[curSelected] : null;

		for (i in 0...difficultyDots.group.members.length) {
			var dot = difficultyDots.group.members[i];
			var diffId:String = dot.difficultyId;

			dot.important = false;

			var targetState:DotState = (i == index) ? SELECTED : (i == prevIndex) ? DESELECTING : DESELECTED;
			var targetType:DotType = (diffId == 'erect' || diffId == 'nightmare') ? ERECT : NORMAL;
			if (targetType == ERECT) dot.important = true;

			dot.visible = true;
			dot.x = ((difficultyDots.x + (DOT_DISTANCE * curDot)) - shiftAmt);
			dot.y = DEFAULT_DOTS_GROUP_POS[1] + DOT_DISTANCE * curRow;

			curDot++;

			if (curDot >= MAX_DOTS_PER_ROW) {
				curDot = 0;
				curRow++;
			}

			if (daSong != null && !Difficulty.list.contains(diffId)) {
				targetType = INACTIVE;
			}

			if (i > amount - 1 && amount != 5) dot.visible = false;

			dot.updateState(targetType, targetState);
		}

		prevDotAmount = amount;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic) return;

		dj.resetAFKTimer();
		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);
		_updateSongLastDifficulty();

		if(playSound) 
			FunkinSound.playOnce('scrollMenu', 0.4);

		for (item in grpSongs.members)
			if (item != null) item.selected = (item.targetY == curSelected);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			intendedColor = newColor;
			updateColors(newColor);
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		rebuildDifficultyDots();
		albumRoll.updateImage(songs[curSelected].album);
		updateOSTName();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);

		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	function updateOSTName(forceAnimation:Bool = false):Void
	{
		var newName:String = songs[curSelected].ostName ?? 'UNOFFICIAL OST';
		if (forceAnimation || ostName.text != newName) {
			ostName.text = newName;

			var sillyStroke:StrokeShader = cast ostName.shader;
			sillyStroke.width = sillyStroke.height = 2;
			FlxTimer.wait(1.5 / 24, () -> { sillyStroke.width = sillyStroke.height = 0; });
		}
	}

	function updateColors(newColor:Int, ?tween:Bool=true) {
		saturatedColor = newColor;
		saturatedColor.saturation = 0.8;
		saturatedColor.brightness += 0.5;

		desaturatedColor = newColor;
		desaturatedColor.saturation = 0.6;
		desaturatedColor.brightness += 0.1;

		if (!tween) return;
		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 1, bg.color, intendedColor);

		for (_saturatedTexts in [funnyScroll, funnyScroll2, funnyScroll3]) {
			FlxTween.cancelTweensOf(_saturatedTexts);
			if (_saturatedTexts == funnyScroll3) saturatedColor.saturation += 0.3; // the last text is a bit more saturated
			FlxTween.color(_saturatedTexts, 1, _saturatedTexts.color, saturatedColor);
		}
			
		for (_desaturatedTexts in [moreWays, moreWays2]) {
			FlxTween.cancelTweensOf(_desaturatedTexts);
			FlxTween.color(_desaturatedTexts, 1, _desaturatedTexts.color, desaturatedColor);
		}
	}

	inline private function _updateSongLastDifficulty()
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);

	public function updateTexts(elapsed:Float = 0.0, ?accepted:Bool = false, ?highscore:String = "", ?song:String = "")
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.pow(1 / 100, elapsed / 0.256));
		for (i in _lastVisibles)
			if (grpSongs.members[i] != null) grpSongs.members[i].visible = grpSongs.members[i].active = false;
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - DRAW_DISTANCE)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + DRAW_DISTANCE)));

		var confirmSound:FlxSound = null;
		if (accepted) {
			confirmSound = FunkinSound.playOnce('confirmMenu');
			dj.confirm();
		}

		for (i in min...max)
		{
			var item:SongCapsule = grpSongs.members[i];
			item.visible = item.active = true;

			if (accepted) { // i could do this in a better way, except that i'm dumb. - Ryiuu
				try
				{
					canMove = false;
					var musicLength:Float = confirmSound.length;
					if (item.songText.text != songs[curSelected].songName){
						FlxTween.tween(item, {alpha: 0}, musicLength / 10000, {ease: FlxEase.sineIn});
					} else {
						var daFuckingtween:FlxTween = FlxTween.num(1, 0, 0.05, {type: FlxTweenType.PINGPONG}, function(v) { // flicker was not working so i just made a tween for it bcuz why not?
							if (v == 1 || v == 0) item.alpha = v;
						});

						new FlxTimer().start(musicLength / 1000 - 0.5, function(tmr:FlxTimer) {
							daFuckingtween.cancel();	
							daFuckingtween = null;	
							
							item.alpha = 1;
						});

						new FlxTimer().start(musicLength / 1000 - 0.2, function(tmr:FlxTimer) {

							Song.loadFromJson(highscore, song);
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = curDifficulty;

							trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
							loadPlayState();
						});
					}
				}
				catch(e:haxe.Exception)
				{
					canMove = true;
					trace('ERROR! ${e.message}');
					showChartError(e, item, song);
				}
			}

			// item.targetPos.y = item.intendedY(item.targetY - lerpSelected); // doesn't look good.
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;
			item.targetPos.x = item.intendedX((item.targetY + 1) - lerpSelected);

			_lastVisibles.push(i);
		}
	}

	function buildBackground() {
		bg = new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayDesat'));
		bg.scale.set(1.1,1.1);
		bg.updateHitbox();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var bgOverlay:FlxSprite = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK); // just to make the bg a bit darker
		bgOverlay.alpha = 0.3;
		bgOverlay.antialiasing = false;
		add(bgOverlay);

		// placed in order here
		funnyScroll = new BGScrollingText(0, 220, "GO GO GO GO", FlxG.width / 2, false, 60);
		moreWays = new BGScrollingText(0, 160, "GET FREAKY ON A FRIDAY NIGHT YEAH!", FlxG.width, true, 43);
		txtNuts = new BGScrollingText(0, 285, "FRIDAY NIGHT FUNKIN'", FlxG.width / 2, true, 43);
		funnyScroll2 = new BGScrollingText(0, 335, "GO GO GO GO", FlxG.width / 2, false, 60);
		moreWays2 = new BGScrollingText(0, 397, "GET FREAKY ON A FRIDAY NIGHT YEAH!", FlxG.width, true, 43);
		funnyScroll3 = new BGScrollingText(0, 450, "GO GO GO GO", FlxG.width / 2, false, 60);

		updateColors(songs[curSelected].color, false);

		moreWays.funnyColor = desaturatedColor;
		moreWays.speed = 6.8;
		add(moreWays);

		funnyScroll.funnyColor = saturatedColor;
		funnyScroll.speed = -3.8;
		add(funnyScroll);

		txtNuts.speed = 3.5;
		add(txtNuts);

		funnyScroll2.funnyColor = saturatedColor;
		funnyScroll2.speed = -3.8;
		add(funnyScroll2);

		moreWays2.funnyColor = desaturatedColor;
		moreWays2.speed = 6.8;
		add(moreWays2);

		saturatedColor.saturation = 1;
		funnyScroll3.funnyColor = saturatedColor;
		funnyScroll3.speed = -3.8;
		add(funnyScroll3);

		var dad:FlxSprite = new FlxSprite(524 * 0.74,0).loadGraphic(Paths.image("freeplay/background-dad"));
		dad.setGraphicSize(0, FlxG.height + 1); // this makes the texture sizes consistent, for the angle shader
		dad.updateHitbox();
		dad.antialiasing = ClientPrefs.data.antialiasing;
		dad.shader = angleMaskShader;
		add(dad);

		dj = new DJBoyfriend(20, 306);
		add(dj);
	}

	function buildUI() {
		albumRoll = new AlbumRoll();
		add(albumRoll);

		var fnfHighscoreSpr:FlxSprite = new FlxSprite(FlxG.width - 420, 70);
		fnfHighscoreSpr.frames = Paths.getSparrowAtlas('freeplay/highscore');
		fnfHighscoreSpr.animation.addByPrefix('highscore', 'highscore small instance 1', 24, false);
		fnfHighscoreSpr.setGraphicSize(0, Std.int(fnfHighscoreSpr.height * 1));
		fnfHighscoreSpr.updateHitbox();
		add(fnfHighscoreSpr);

		fpScoreDisplay = new FreeplayScore(FlxG.width - 353, 60, 7, 100);
		add(fpScoreDisplay);

		new FlxTimer().start(FlxG.random.float(12, 50), function(tmr) {
			fnfHighscoreSpr.animation.play('highscore');
			tmr.time = FlxG.random.float(20, 60);
		}, 0);

		var clearBoxSprite:FlxSprite = new FlxSprite(FlxG.width - (FullScreenScaleMode.gameNotchSize.x + 115), 65).loadGraphic(Paths.image('freeplay/clearBox'));
		add(clearBoxSprite);

		txtCompletion = new AtlasText(FlxG.width - 95, 87, '69', AtlasFont.FREEPLAY_CLEAR);
		add(txtCompletion);

		diffSprite = new DifficultySprite("normal", 73, 80);
		add(diffSprite);

		difficultyDots = new FlxTypedSpriteGroup<DifficultyDot>(DEFAULT_DOTS_GROUP_POS[0], DEFAULT_DOTS_GROUP_POS[1]);
		add(difficultyDots);

		var topBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 64, FlxColor.BLACK);
		add(topBG);

		final tabNames:Array<String> = ["FREEPLAY", "BETADCIU", "BONUS"];
		topLeftCornerText= new FlxText(8, 8, 0, tabNames[currentTab], 48);
		topLeftCornerText.font = Paths.font('vcr.ttf');
		add(topLeftCornerText);

		tabSelectHint = new FlxText(-40, 18, FlxG.width - 8 - 8, 'Press [ TAB ] to change tabs', 32);
		tabSelectHint.alignment = CENTER;
		tabSelectHint.font = '5by7';
		tabSelectHint.color = 0xFF5F5F5F;
		add(tabSelectHint);

		ostName = new FlxText(8, 8, FlxG.width - 8 - 8, "OFFICIAL OST", 48);
		ostName.font = Paths.font('vcr.ttf');
		ostName.alignment = RIGHT;
		ostName.shader = new StrokeShader(0xFFFFFFFF, 2, 2);
		add(ostName);
		updateOSTName(true);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
	}

	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxG.save.flush();
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var album:String = "template";
	public var folder:String = "";
	public var lastDifficulty:String = null;
	public var difficultyStars:Array<Int> = [0];
	public var bpm:Int = 100;
	public var weekName:String = "";
	public var ostName:String;

	public function new(song:String, week:Int, songCharacter:String, color:Int, album:String, difficultyStars:Array<Int>, bpm:Int, weekname:String, ostName:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.album = album;
		this.folder = Mods.currentModDirectory;
		this.difficultyStars = difficultyStars;
		this.bpm = bpm;
		this.weekName = weekname;
		this.ostName = ostName;
		if(this.folder == null) this.folder = '';
	}
}