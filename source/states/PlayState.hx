package states;

import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Rating;

import extensions.flixel.FlxCameraEx;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import haxe.Json;

import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
// import substates.PauseSubStateNew as PauseSubState;
import substates.GameOverSubstate;

#if !flash
import openfl.filters.ShaderFilter;
#end

import shaders.ErrorHandledShader;

import objects.Note.EventNote;
import objects.HoldCover.CoverSprite;
import objects.*;
import states.stages.*;
import states.stages.objects.*;

import states.betadciu.*;

#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end
import extensions.hscript.Sharables;

#if HSCRIPT_ALLOWED
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

#if VIDEOS_ALLOWED
import objects.PsychVideoSprite;
#end

import sys.thread.Thread;

#if sys
import sys.FileSystem;
#end

import flixel.addons.plugin.screengrab.FlxScreenGrab;

import objects.FunkinSprite;
import backend.EaseUtil;
import backend.tools.PreloadUtil;

import objects.notes.NoteSkinConfig;

typedef PreloadResult = {
	var thread:Thread;
	var asset:String;
	@:optional var terminated:Bool;
}

typedef AssetPreload = {
	var path:String;
	@:optional var type:String;
	@:optional var library:String;
	@:optional var terminate:Bool;
}

/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/
class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	//event variables
	public var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	#if LUA_ALLOWED // yeah, i'll use dedicated maps because i like
	public var modchartCharacters:Map<String, Character> = new Map<String, Character>(); // tryna get this working on psych -- future me here: its working!
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var curStage:String = '';

	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function set_stageUI(value:String):String
	{
		uiPrefix = uiPostfix = "";
		if (value != "normal")
		{
			uiPrefix = value.split("-pixel")[0].trim();
			if (value == "pixel" || value.endsWith("-pixel")) uiPostfix = "-pixel";
		}
		return stageUI = value;
	}

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var isBETADCIU:Bool = false;
	public static var isBonus:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;
	public static var holdSubdivisions:Int = 1;

	public var inst:FunkinSound;
	public var vocals:FunkinSound;
	public var opponentVocals:FunkinSound;

	// public var dad:Character = null;
	// public var gf:Character = null;
	// public var boyfriend:Character = null;

	public var boyfriend(default, set):Character = null;
	public var dad(default, set):Character = null;
	public var gf(default, set):Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();
	public var opponentHoldCovers:HoldCover;
	public var playerHoldCovers:HoldCover;

  	public var enabledHolds:Bool = ClientPrefs.data.holdCovers;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var camZoomingSpeed:Float = 2;
	public var psychCamZooming(default, set):Bool = false; // Just for backwards compatibility

	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var speedBaseMod:Int = 1;
	public var health(default, set):Float = 1;
	public var combo:Int = 0;

	public var healthBar:Bar;
	public var timeBar:Bar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var healthSet:Bool = false;
	public var practiceMode:Bool = false;
	public var pressMissDamage:Float = 0.05;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var playDad:Bool = true;
	public var playBF:Bool = true;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var defaultBar:Bool = true;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end
	public var introSoundsPrefix:String = '';
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;

	public var stageData:StageFile;
	public var pauseCameraEffects:Bool = false;

	public var canRestart:Bool = true;
	public var canControlPauseMenu:Bool = true; // becasue set/getPropertyFromClass don't work?!
	public static var restarted:Bool = false;

	override public function create()
	{
		if (FlxG.sound.music != null) {
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.stop();
		}
		
		//trace('Playback Rate: ' + playbackRate);
		_lastLoadedModDirectory = Mods.currentModDirectory;
		if (!restarted) {
			Paths.clearStoredMemory();
			if(nextReloadAll)
			{
				Paths.clearUnusedMemory();
				Language.reloadPhrases();
			}
		}
		nextReloadAll = false;

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
		];

		// if(FlxG.sound.music != null)
		// 	FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		// var gameCam:FlxCameraEx = FlxG.camera;
		camGame = initPsychCamera();
		camHUD = new FlxCameraEx();
		camOther = new FlxCameraEx();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else if (isBETADCIU)
			detailsText =  SONG.song + " But Every Turn A Different Cover is Used";
		else if (isBonus) // adding one for bonus songs too because i want
			detailsText =  "Bonus Song";
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));

		curStage = SONG.stage;
		stageData = StageData.getStageFile(curStage);
		setStageDetails(stageData);

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		if(isPixelStage) introSoundsSuffix = '-pixel';

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// if (!stageData.hide_girlfriend)
		// {
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			if (stageData.hide_girlfriend) SONG.gfVersion = 'emptygf'; // quick change to prevent the null gf bug
			gf = new Character(0, 0, SONG.gfVersion);
			gfOldChar = SONG.gfVersion;
			gf.charName = "gf";
			startCharacterPos(gf);
			//gf.scrollFactor.set(0.95, 0.95);
		// }

		dad = new Character(0, 0, SONG.player2);
		dad.charName = "dad";
		startCharacterPos(dad, true);

		boyfriend = new Character(0, 0, SONG.player1, true);
		boyfriend.charName = "boyfriend";
		startCharacterPos(boyfriend);
		
		addStage(false, true);
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// "SCRIPTS FOLDER" SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end
			
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf') || dad.curCharacter.endsWith('speaker') || dad.isSpeakerChar) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// CHARACTER SCRIPTS
		if(gf != null) startCharacterScripts(gf.curCharacter);
		startCharacterScripts(dad.curCharacter);
		startCharacterScripts(boyfriend.curCharacter);

		if(gf != null) nameScriptsCharacter("characters/" + gf.curCharacter, gf.charName);
		nameScriptsCharacter("characters/" + dad.curCharacter, dad.charName);
		nameScriptsCharacter("characters/" + boyfriend.curCharacter, boyfriend.charName);
		#end

		uiGroup = new FlxSpriteGroup();
		comboGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		opponentHoldCovers = new HoldCover(enabledHolds, false);
		playerHoldCovers = new HoldCover(enabledHolds, true);
		add(comboGroup);
		add(noteGroup);
		add(opponentHoldCovers);
		add(playerHoldCovers);

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);

		noteGroup.add(strumLineNotes);

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}else if(ClientPrefs.data.timeBarType == 'Song Name And Time'){
			timeTxt.text = SONG.song + " (0:00)";
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		generateSong();
		PreloadUtil.grabStuffToPreload();
		PreloadUtil.preload();

		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, healthBar.y - 90, FlxG.width - 800, Language.getPhrase("Botplay").toUpperCase(), 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		// botplayTxt.visible = cpuControlled;
		// add(botplayTxt);
		if(ClientPrefs.data.downScroll)
			botplayTxt.y = healthBar.y + 70;

		add(uiGroup); // leaving the ui group for scripts

		var objects:Array<String> = ['healthBar', 'iconP1', 'iconP2', 'scoreTxt', 'timeBar', 'timeTxt'];
		for (i in 0... objects.length) {
			var obj:FlxSprite = Reflect.getProperty(PlayState.instance, objects[i]);
			if (obj != null) obj.cameras = [camHUD];
		}
		uiGroup.cameras = noteGroup.cameras = playerHoldCovers.cameras = opponentHoldCovers.cameras = comboGroup.cameras = [camHUD];

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua', "noteType");
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx', "noteType");
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		var scriptSuffix:String = null;

		if (isBETADCIU)
			scriptSuffix = "-betadciu";
		else if (isBonus)
			scriptSuffix = "-bonus";

		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		if(eventNotes.length > 0)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		startCallback();
		RecalculateRating(false, false);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		if(!ClientPrefs.data.ghostTapping) for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if(Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

		resetRPC();

		hardCodedStage?.createPost();
		callOnScripts('onCreatePost');
		
		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; //cant make it invisible or it won't allow precaching

		super.create();
		Paths.clearUnusedMemory();

		cacheCountdown();
		cachePopUpScore();

		if(eventNotes.length < 1) checkEventNote();

		if (restarted) {
			callOnScripts('onRestartPost');
			restarted = false;
		}
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if(generatedMusic)
		{
			vocals.pitch = value;
			opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.offset = Reflect.hasField(PlayState.SONG, 'offset') ? (PlayState.SONG.offset / value) : 0;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		#if VIDEOS_ALLOWED
		if(videoCutscene != null && videoCutscene.videoSprite != null) videoCutscene.videoSprite.bitmap.rate = value;
		#end
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	function set_psychCamZooming(value:Bool):Bool
	{
		trace("psychCamZooming is deprecated! Use camZoomingSpeed instead.");
		psychCamZooming = value;
		camZoomingSpeed = psychCamZooming ? 1 : 2;

		return value;
	}

	var usedTimeTravel:Bool = false;

	public function doTimeTravel(shiftPressed:Bool = false, ?skipExactly:Int = 0) {
		var multiplier:Int = 1;
		if (shiftPressed)multiplier = 6; //we skippin minutes now

		if (skipExactly != 0)
		{
			if (!usedTimeTravel && skipExactly < FlxG.sound.music.length) 
			{
				usedTimeTravel = true;
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
				Conductor.songPosition = skipExactly;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime - 500 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;
					
						invalidateNote(daNote);
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if(daNote.strumTime - 500 >= Conductor.songPosition) {
						break;
					}
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
				}
				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();
				vocals.time = Conductor.songPosition;
				vocals.play();
				opponentVocals.time = Conductor.songPosition;
				opponentVocals.play();
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						usedTimeTravel = false;
					});
			}
		}
		else
		{
			if (!usedTimeTravel && Conductor.songPosition + 10000 * multiplier < FlxG.sound.music.length) 
			{
				usedTimeTravel = true;
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
				Conductor.songPosition += 10000 * multiplier;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime - 500 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;
					
						invalidateNote(daNote);
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if(daNote.strumTime - 500 >= Conductor.songPosition) {
						break;
					}
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
				}
				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();
				vocals.time = Conductor.songPosition;
				vocals.play();
				opponentVocals.time = Conductor.songPosition;
				opponentVocals.play();
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						usedTimeTravel = false;
					});
			}
		}	
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE) {
		var newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

		Sys.println(text);
	}
	#end

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		var preloadChar = new Character(0, 0, newCharacter);
		startCharacterScripts(preloadChar.curCharacter);
		stopCharacterScripts(preloadChar.curCharacter);
		add(preloadChar);
		remove(preloadChar);
		preloadChar = null;
	}

	public function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			if(Iris.instances.exists(scriptFile))
				doPush = false;

			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function stopCharacterScripts(name:String)
	{
		// different from "startCharacterScripts" cuz kinda hardcoding.
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			#if LUA_ALLOWED stopLuasNamed('characters/' + name + '.lua'); #end
			#if HSCRIPT_ALLOWED stopHScriptsNamed('characters/' + name + '.hx'); #end
		#end
	}

	public function getLuaObject(tag:String):Dynamic {
		#if LUA_ALLOWED
		if(modchartCharacters.exists(tag)) return modchartCharacters.get(tag);
		#end
		if(variables.exists(tag)) return variables.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if (char == gf) {
			char.setPosition(GF_X + gf.positionArray[0], GF_Y + gf.positionArray[1]);
		} else if (char == dad){
			char.setPosition(DAD_X + dad.positionArray[0], DAD_Y + dad.positionArray[1]);

			if(dad.curCharacter.startsWith('gf') || dad.curCharacter.endsWith('speaker') || dad.isSpeakerChar) {
				dad.setPosition(GF_X + dad.positionArray[0], GF_Y + dad.positionArray[1]);
				if(gf != null)
					gf.visible = false;
			}
		} else if (char == boyfriend) {
			char.setPosition(BF_X + boyfriend.playerPositionArray[0], BF_Y + boyfriend.playerPositionArray[1]);
		}

		// if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
		// 	char.setPosition(GF_X, GF_Y);
		// 	char.scrollFactor.set(0.95, 0.95);
		// 	char.danceEveryNumBeats = 2;
		// }
		// char.x += char.positionArray[0];
		// char.y += char.positionArray[1];
	}

	public var videoCutscene:VideoSprite = null;
	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);
			if(forMidSong) videoCutscene.videoSprite.bitmap.rate = playbackRate;

			// Finish callback
			if (!forMidSong)
			{
				function onVideoEnd()
				{
					if (!isDead && generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
					{
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = true;
					inCutscene = false;
					startAndEnd();
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			if (GameOverSubstate.instance != null && isDead) GameOverSubstate.instance.add(videoCutscene);
			else add(videoCutscene);

			if (playOnLoad)
				videoCutscene.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else addTextToDebug("Video not found: " + fileName, FlxColor.RED);
		#else
		else FlxG.log.error("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownOnYourMarks:FlxSprite; // adding this one because some old scripts uses this
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${uiPrefix}UI/ready${uiPostfix}', '${uiPrefix}UI/set${uiPostfix}', '${uiPrefix}UI/go${uiPostfix}'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);

		Paths.sound(introSoundsPrefix + 'intro3' + introSoundsSuffix);
		Paths.sound(introSoundsPrefix + 'intro2' + introSoundsSuffix);
		Paths.sound(introSoundsPrefix + 'intro1' + introSoundsSuffix);
		Paths.sound(introSoundsPrefix + 'introGo' + introSoundsSuffix);
	}

	public var stopCountdown = false;
	var generatedStaticArrows = false; // added this bcuz of a bug with cutscenes

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != LuaUtils.Function_Stop) {
			if (!stopCountdown) {
				if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

				canPause = true;

				if (!generatedStaticArrows) {
					generateStaticArrows(0);
					generateStaticArrows(1);
					for (i in 0...playerStrums.length) {
						setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
						setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
					}
					for (i in 0...opponentStrums.length) {
						setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
						setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
						//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
					}
					generatedStaticArrows = true;
				}

				startedCountdown = true;
				Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
				setOnScripts('startedCountdown', true);
				callOnScripts('onCountdownStarted');

				var swagCounter:Int = 0;
				if (startOnTime > 0) {
					clearNotesBefore(startOnTime);
					setSongTime(startOnTime - 350);
					return true;
				}
				else if (skipCountdown)
				{
					setSongTime(0);
					return true;
				}
				moveCameraSection();

				startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
				{
					characterBopper(tmr.loopsLeft);

					var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
					var introImagesArray:Array<String> = switch(stageUI) {
						case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
						case "normal": ["ready", "set" ,"go"];
						default: ['${uiPrefix}UI/ready${uiPostfix}', '${uiPrefix}UI/set${uiPostfix}', '${uiPrefix}UI/go${uiPostfix}'];
					}
					introAssets.set(stageUI, introImagesArray);

					var isCustomCountdown:Bool = false;
					var introAlts:Array<String> = introAssets.get(stageUI);
					if (stageData.countdownAssets != null && stageData.countdownAssets != []) {
						introAlts = stageData.countdownAssets;
						isCustomCountdown = true;
					}

					var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
					var tick:Countdown = THREE;

					switch (swagCounter)
					{
						case 0:
							countdownOnYourMarks = new FlxSprite().loadGraphic(Paths.image("notes/noStrums")); // in case someone really uses this i can add a thing to customize this later -- ryiuu
							FunkinSound.playOnce(introSoundsPrefix + 'intro3' + introSoundsSuffix, 0.6);
							tick = THREE;
						case 1:
							countdownReady = createCountdownSprite(introAlts[0], antialias, isCustomCountdown);
							FunkinSound.playOnce(introSoundsPrefix + 'intro2' + introSoundsSuffix, 0.6);
							tick = TWO;
						case 2:
							countdownSet = createCountdownSprite(introAlts[1], antialias, isCustomCountdown);
							FunkinSound.playOnce(introSoundsPrefix + 'intro1' + introSoundsSuffix, 0.6);
							tick = ONE;
						case 3:
							countdownGo = createCountdownSprite(introAlts[2], antialias, isCustomCountdown);
							FunkinSound.playOnce(introSoundsPrefix + 'introGo' + introSoundsSuffix, 0.6);
							tick = GO;
						case 4:
							tick = START;
					}

					if(!skipArrowStartTween)
					{
						notes.forEachAlive(function(note:Note) {
							if(ClientPrefs.data.opponentStrums || note.mustPress)
							{
								note.copyAlpha = false;
								note.alpha = note.multAlpha;
								if(ClientPrefs.data.middleScroll && !note.mustPress)
									note.alpha *= 0.35;
							}
						});
					}

					hardCodedStage?.countdownTick(tick, swagCounter);
					callOnLuas('onCountdownTick', [swagCounter]);
					callOnHScript('onCountdownTick', [tick, swagCounter]);

					swagCounter += 1;
				}, 5);
			}
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool, ?custom:Bool=false):FlxSprite
	{
		var fadeEase = FlxEase.cubeInOut;

		if(ClientPrefs.data.perfectPixel == "inGame" || ClientPrefs.data.perfectPixel == "RatingAndCountdownOnly"){
			if(PlayState.isPixelStage && !custom || custom && StringTools.contains(image, "-pixel"))
				fadeEase = EaseUtil.stepped(8);
		}

		//var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		var spr = new FunkinSprite(0, 0, Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();
		if (PlayState.isPixelStage && !custom || custom && StringTools.contains(image, "-pixel")){
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom)); // bruh
		}

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {y: spr.y + 25, alpha: 0}, Conductor.crochet / 1000, {
			ease: fadeEase,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public var calledBy:HScript = null; // so i "game.add..." adds to the script variables too -- its public but i don't recommend to mess with this on scripts...

	// why was this commented?
	override public function add(obj:FlxBasic):FlxBasic
	{
		if (calledBy != null) calledBy.scriptObjects.push(obj);
		return super.add(obj);
	}
	override public function insert(index:Int, obj:FlxBasic):FlxBasic
	{
		if (calledBy != null) calledBy.scriptObjects.push(obj);
		return super.insert(index, obj);
	}
	public function addBehindGF(obj:FlxBasic) {
		if (calledBy != null) calledBy.scriptObjects.push(obj);
		insert(members.indexOf(gf), obj);
	}
	public function addBehindBF(obj:FlxBasic) {
		if (calledBy != null) calledBy.scriptObjects.push(obj);
		insert(members.indexOf(boyfriend), obj);
	}
	public function addBehindDad(obj:FlxBasic) {
		if (calledBy != null) calledBy.scriptObjects.push(obj);
		insert(members.indexOf(dad), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	public dynamic function updateScore(miss:Bool = false, scoreBop:Bool = true)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		updateScoreText();
		if (!miss && scoreBop)
			doScoreBop();

		callOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function updateScoreText()
	{
		var str:String = Language.getPhrase('rating_$ratingName', ratingName);
		if(totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str += ' (${percent}%) - ' + Language.getPhrase(ratingFC);
		}

		var tempScore:String;
		var formattedScore:String = FlxStringUtil.formatMoney(songScore, false);
		if(!instakillOnMiss) tempScore = Language.getPhrase('score_text', 'Score: {1} | Misses: {2} | Rating: {3}', [formattedScore, songMisses, str]);
		else tempScore = Language.getPhrase('score_text_instakill', 'Score: {1} | Rating: {2}', [formattedScore, str]);
		scoreTxt.text = tempScore;
	}

	public static var sicks:Int = 0;
	public static var goods:Int = 0;
	public static var bads:Int = 0;
	public static var shits:Int = 0;

	public dynamic function fullComboFunction()
	{
		sicks = ratingsData[0].hits;
		goods = ratingsData[1].hits;
		bads = ratingsData[2].hits;
		shits = ratingsData[3].hits;

		ratingFC = "";
		if(songMisses == 0)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'MFC';
		}
		else {
			if (songMisses < 10) ratingFC = 'SDCB';
			else ratingFC = 'Clear';
		}
	}

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom)
			return;

		if(scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.smootherStepOut, // i like smootherStepOut
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float)
	{
		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.time = time - Conductor.offset;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.play();

		if (Conductor.songPosition < vocals.length)
		{
			vocals.time = time - Conductor.offset;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
			vocals.play();
		}
		else vocals.pause();

		if (Conductor.songPosition < opponentVocals.length)
		{
			opponentVocals.time = time - Conductor.offset;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
			opponentVocals.play();
		}
		else opponentVocals.pause();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		inst.volume = 1;
		FunkinSound.setMusic(inst);
		inst.play();

		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		opponentVocals.play();

		setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		hardCodedStage?.startSong();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if(autoUpdateRPC) 
			if (isBETADCIU) {
				DiscordClient.changePresence(detailsText, " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
			} else {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
			}

		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private var totalColumns: Int = 4;

	var chartSections:Array<SwagSection>;
	var currentSection:Int = 0;
	var preloadTime:Float = 6000; // miliseconds // 6 seconds instead of 5 because it fix some issues with some charts

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;
		daBpm = songData.bpm;

		curSong = songData.song;

		vocals = new FunkinSound();
		opponentVocals = new FunkinSound();
		try
		{
			if (songData.needsVoices)
			{
				var voiceStatePostfix:String = "";

				if (isBETADCIU)
					voiceStatePostfix = '-betadciu';
				else if (isBonus)
					voiceStatePostfix = '-bonus';

				var voiceStateFinal = voiceStatePostfix.toLowerCase();

				if (SONG.vocalsPostfix != null) 
					voiceStateFinal = SONG.vocalsPostfix.toLowerCase();

				var baseName = (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1)
					? "Player"
					: boyfriend.vocalsFile;

				var testPath = Paths.getPath('songs/${songData.song}/Voices-' + baseName + voiceStateFinal + '.ogg');

				var playerVocals = FileSystem.exists(testPath)
					? Paths.voices(songData.song, baseName + voiceStateFinal)
					: Paths.voices(songData.song, baseName);
					
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));
				
				// Reusing the same variables to save a negligible amount of memory
				baseName = (dad.vocalsFile == null || dad.vocalsFile.length < 1)
					? "Opponent"
					: dad.vocalsFile;

				testPath = Paths.getPath('songs/${songData.song}/Voices-' + baseName + voiceStateFinal + '.ogg');

				var oppVocals = FileSystem.exists(testPath)
					? Paths.voices(songData.song, baseName + voiceStateFinal)
					: Paths.voices(songData.song, baseName);

				if(oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch (e:Dynamic) {}

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FunkinSound();
		try
		{
			// inst.loadEmbedded(Paths.inst(songData.song));
			inst = FunkinSound.load(Paths.inst(songData.song), 1, false, false, false, true);
		}
		catch (e:Dynamic) {}
		// FlxG.sound.list.add(inst); // load() already adds it to the list

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		try
		{
			var eventsChart:SwagSong = Song.getChart('events', songName);
			if(eventsChart != null)
				for (event in eventsChart.events) //Event Notes
					for (i in 0...event[1].length)
						makeEvent(event, i);
		}
		catch(e:Dynamic) {}


		if (ClientPrefs.data.streamedNotes) { // da new note loading system
			var sectionsData:Array<SwagSection> = PlayState.SONG.notes;
			chartSections = PlayState.SONG.notes;
			currentSection = 0;

			if (FileSystem.exists(Paths.txt(songName + "/arrowSwitches"))){
				arrowSwitches = CoolUtil.coolTextFile(Paths.txt(songName + "/arrowSwitches"));
			}
		
			loadUpcomingNotes();

			for (section in sectionsData) {
				for (i in 0...section.sectionNotes.length) {
					var songNotes: Array<Dynamic> = section.sectionNotes[i];
					var noteType: String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
					if (!noteTypes.contains(noteType)) noteTypes.push(noteType);
				}
			}
		} else { // the good n' old' note loading system
			if (FileSystem.exists(Paths.txt(songName + "/arrowSwitches"))) arrowSwitches = CoolUtil.coolTextFile(Paths.txt(songName + "/arrowSwitches"));

			var sectionsData:Array<SwagSection> = PlayState.SONG.notes;

			for (section in sectionsData)
			{
				if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
					daBpm = section.bpm;

				var styles:{ opponent:String, player:String } = getNoteStyles(daSection);
				var lastNoteSkin:String = "";

				for (i in 0...section.sectionNotes.length)
				{
					final songNotes:Array<Dynamic> = section.sectionNotes[i];
					lastNoteSkin = buildNoteFromData(songNotes, section, i, styles, lastNoteSkin);
				}
				daSection++;
			}
		}

		trace('["${SONG.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCaught');
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	var ghostNotesCaught:Int = 0;
	var oldNote:Note = null;
	var daBpm:Float = Conductor.bpm;
	var daSection:Int = 0;
	var arrowSwitches:Array<String> = [];

	var _lastOpponentStyle:String = "";
	var _lastPlayerStyle:String = "";

	function getNoteStyles(section:Int):{ opponent:String, player:String }
	{
		for (line in arrowSwitches)
		{
			var data:Array<String> = line.split(' ');
			if (Std.parseInt(data[0]) == section)
			{
				if (data[2] == 'dad') _lastOpponentStyle = data[1];
				else _lastPlayerStyle = data[1];
			}
		}
		return { opponent: _lastOpponentStyle, player: _lastPlayerStyle };
	}

	function buildNoteFromData(songNotes:Array<Dynamic>, section:SwagSection, noteIndex:Int, styles:{ opponent:String, player:String }, lastNoteSkin:String):String
	{
		var spawnTime:Float  = songNotes[0];
		var noteColumn:Int   = Std.int(songNotes[1] % totalColumns);
		var holdLength:Float = songNotes[2];
		var noteType:String  = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
		if (Math.isNaN(holdLength)) holdLength = 0.0;

		var gottaHitNote:Bool = (songNotes[1] < totalColumns);

		if (noteIndex != 0)
		{
			for (evilNote in unspawnNotes)
			{
				var matches:Bool = (noteColumn == evilNote.noteData
					&& gottaHitNote == evilNote.mustPress
					&& evilNote.noteType == noteType);
				if (matches && Math.abs(spawnTime - evilNote.strumTime) < flixel.math.FlxMath.EPSILON)
				{
					if (evilNote.tail.length > 0)
						for (tail in evilNote.tail)
						{
							tail.destroy();
							unspawnNotes.remove(tail);
						}
					evilNote.destroy();
					unspawnNotes.remove(evilNote);
					ghostNotesCaught++;
				}
			}
		}

		var swagNote:Note = new Note(spawnTime, noteColumn, oldNote);
		swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
		swagNote.animSuffix = (section.altAnim && !gottaHitNote) ? "-alt" : "";
		swagNote.mustPress = gottaHitNote;
		swagNote.sustainLength = holdLength;
		swagNote.dType = section.dType;
		swagNote.noteType = noteType;
		if (gottaHitNote && styles.player != "") swagNote.texture = styles.player;
		else if (!gottaHitNote && styles.opponent != "") swagNote.texture = styles.opponent;
		if (lastNoteSkin != swagNote.texture) spawnNoteSplash(-100000, -100000, swagNote.noteData, swagNote);
		lastNoteSkin = swagNote.texture;

		swagNote.scrollFactor.set();
		unspawnNotes.push(swagNote);

		var curStepCrochet:Float = Math.max((60 / daBpm * 1000 / 4.0) / holdSubdivisions, 10);

		if (section.changeBPM)
			curStepCrochet = 15000 / section.bpm / holdSubdivisions;

		final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
		if (roundSus > 0)
		{
			for (susNote in 0...roundSus)
			{
				oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

				var sustainNote:Note = new Note(spawnTime + (curStepCrochet * susNote), noteColumn, oldNote, true);
				sustainNote.animSuffix = swagNote.animSuffix;
				sustainNote.mustPress = swagNote.mustPress;
				sustainNote.gfNote = swagNote.gfNote;
				sustainNote.dType = swagNote.dType;
				sustainNote.noteType = swagNote.noteType;
				sustainNote.scrollFactor.set();
				sustainNote.parent = swagNote;
				sustainNote.texture = swagNote.texture;

				unspawnNotes.push(sustainNote);
				swagNote.tail.push(sustainNote);

				sustainNote.correctionOffset = swagNote.height / 2;
				if (oldNote.isSustainNote)
				{
					oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
					oldNote.scale.y /= playbackRate;
					oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
				}
				if (ClientPrefs.data.downScroll && !sustainNote.isPixelNote)
					sustainNote.correctionOffset = 0;

				if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2;
				else if (ClientPrefs.data.middleScroll)
				{
					sustainNote.x += 310;
					if (noteColumn > 1) sustainNote.x += FlxG.width / 2 + 25;
				}
			}
		}

		if (swagNote.mustPress) swagNote.x += FlxG.width / 2; // general offset
		else if (ClientPrefs.data.middleScroll)
		{
			swagNote.x += 310;
			if (noteColumn > 1) //Up and Right
				swagNote.x += FlxG.width / 2 + 25;
		}

		if (noteTypes == null) noteTypes = [];
		if (!noteTypes.contains(swagNote.noteType)) noteTypes.push(swagNote.noteType);

		oldNote = swagNote;
		return lastNoteSkin;
	}

	function loadUpcomingNotes()
	{
		var songPos = Conductor.songPosition;

		while (currentSection < chartSections.length)
		{
			var section = chartSections[currentSection];

			var sectionStart = currentSection * 4 * Conductor.stepCrochet;

			if(sectionStart > songPos + preloadTime)
				break;

			if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
				daBpm = section.bpm;

			var styles:{ opponent:String, player:String } = getNoteStyles(currentSection);
			var lastNoteSkin:String = "";

			for (i in 0...section.sectionNotes.length)
			{
				var songNotes:Array<Dynamic> = section.sectionNotes[i];
				lastNoteSkin = buildNoteFromData(songNotes, section, i, styles, lastNoteSkin);
			}

			callOnNoteScripts();
			currentSection++;
		}

		if (!generatedMusic) // so the onSpawnNote is called for the first notes too
			if (unspawnNotes[0] != null)
			{
				var time:Float = spawnTime * playbackRate;
				if(songSpeed < 1) time /= songSpeed;
				if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

				while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
				{
					final dunceNote:Note = unspawnNotes.shift();
					final conds:Bool = usedNoteSkinEvent && dunceNote.texture != (PlayState.SONG.noteStyle != null ? PlayState.SONG.noteStyle : (PlayState.SONG.arrowSkin != null ? PlayState.SONG.arrowSkin : null));
					if (conds) dunceNote.texture = (dunceNote.mustPress ? playerNoteSkin : opponentNoteSkin);
					notes.insert(0, dunceNote);
					dunceNote.spawned = true;

					callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
					callOnHScript('onSpawnNote', [dunceNote]);
				}
			}
	}

	function callOnNoteScripts() { // temporary code, i'll make one that works better later
		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null && script.scriptType == "noteType")
			{
				// trace('Calling onCreate for ' + script.scriptName);
				if (script.exists('onCreate')) script.call('onCreate', []);
			}
		#end
		#if LUA_ALLOWED
		for (script in luaArray)
			if(script != null && script.scriptType == "noteType")
			{
				// trace('Calling onCreate for ' + script.scriptName);
				script.call('onCreate', []);
			}
		#end
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		hardCodedStage?.eventPushed(event);
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Note Skin": // note skin preloading
				var preloadNote:Note = new Note(0,0);
				preloadNote.texture = event.value1;
				spawnNoteSplash(-100000, -100000, 0, preloadNote); // gotta preload that noteSplash
				preloadNote.destroy();

			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				PreloadUtil.charactersToLoad.push(newCharacter);
			case 'Play Sound':
				PreloadUtil.soundsToLoad.push(event.value1);
			case "Change Stage":
				PreloadUtil.stagesToLoad.push(event.value1);
		}
		hardCodedStage?.eventPushedUnique(event);
		callOnScripts('onEventPushedUnique', [event.event, event.value1 != null ? event.value1 : '', event.value2 != null ? event.value2 : '', event.value3 != null ? event.value3 : '', event.strumTime]);
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.value3, event.strumTime], true);
		if(returnedValue != null && returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2],
			value3: event[1][i][3]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.value3 != null ? subEvent.value3 : '', subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	public var skipArrowYPosStartTween:Bool = false;
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				if (skipArrowYPosStartTween) babyArrow.y -= 10;
				babyArrow.alpha = 0;

				if (skipArrowYPosStartTween)
						FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
					else
						FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		hardCodedStage?.openSubState(SubState);
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);
		}

		super.openSubState(SubState);
	}

	public var canResync:Bool = true;
	override function closeSubState()
	{
		super.closeSubState();
		
		hardCodedStage?.closeSubState();
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong && canResync)
			{
				resyncVocals();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);

			paused = false;
			#if VIDEOS_ALLOWED
			PsychVideoSprite.globalResume();
			#end
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}
	}

	#if DISCORD_ALLOWED
	override public function onFocus():Void
	{
		super.onFocus();
		if (!paused && health > 0)
		{
			resetRPC(Conductor.songPosition > 0.0);
		}
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		if (!paused && health > 0 && autoUpdateRPC)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
	}
	#end

	// Updating Discord Rich Presence.
	public var autoUpdateRPC:Bool = true; //performance setting for custom RPC things
	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if(!autoUpdateRPC) return;

		if (showTime)
			if (isBETADCIU) {
				DiscordClient.changePresence(detailsText, " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
			} else {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
			}
		else
			if (isBETADCIU) {
				DiscordClient.changePresence(detailsText, " (" + storyDifficultyText + ")", iconP2.getCharacter());
			} else {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		#end
	}

	public function resyncVocals():Void
	{
		if(finishTimer != null) return;

		trace('resynced vocals at ' + Math.floor(Conductor.songPosition));

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var checkVocals = [vocals, opponentVocals];
		for (voc in checkVocals)
		{
			if (FlxG.sound.music.time < vocals.length)
			{
				voc.time = FlxG.sound.music.time;
				#if FLX_PITCH voc.pitch = playbackRate; #end
				voc.play();
			}
			else voc.pause();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	override public function update(elapsed:Float)
	{
		if(!inCutscene && !paused && !freezeCamera) {
			FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
			var animName:String = boyfriend.getAnimationName();
			var idleAnim:Bool = (animName.startsWith('idle') || animName.startsWith('danceLeft') || animName.startsWith('danceRight'));
			if(!startingSong && !endingSong && idleAnim) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}
		else FlxG.camera.followLerp = 0;
		

		callOnScripts('onUpdate', [elapsed]);
		
		super.update(elapsed);

		if (!startingSong) {
			setOnScripts('songPos',Conductor.songPosition);
		}

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != LuaUtils.Function_Stop) {
				openPauseMenu();
			}
		}

		if(!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1')){
				if (FlxG.keys.pressed.SHIFT){
					ChartingState.lastVisitedSection = curSection;
				}

				openChartEditor();
			}
			else if (controls.justPressed('debug_2'))
				openCharacterEditor();
		}

		if (healthBar.bounds.max != null && health > healthBar.bounds.max)
			health = healthBar.bounds.max;

		updateIconsScale(elapsed);
		if (canIconMove) updateIconsPosition();

		if (startedCountdown && !paused)
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= Conductor.offset)
			{
				Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 5));
				// var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
				// if (timeDiff > 1000 * playbackRate)
				// 	Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
				var rawDiff:Float = (FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition;
				if (Math.abs(rawDiff) > 1000 * playbackRate)
					Conductor.songPosition += 1000 * FlxMath.signOf(rawDiff);
			}
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= Conductor.offset)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.data.timeBarType != 'Song Name' && ClientPrefs.data.timeBarType != 'Song Name And Time') timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
			if (ClientPrefs.data.timeBarType == "Song Name And Time") timeTxt.text = SONG.song + " (" + FlxStringUtil.formatTime(secondsTotal, false) + ")";
		}

		if (camZooming)
		{
			var zoomLerp = Math.exp(-elapsed * 3.125 * camZoomingDecay * camZoomingSpeed * playbackRate);
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, zoomLerp);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, zoomLerp);
		}

		#if debug
		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		#end

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				final conds:Bool = usedNoteSkinEvent && dunceNote.texture != (PlayState.SONG.noteStyle != null ? PlayState.SONG.noteStyle : (PlayState.SONG.arrowSkin != null ? PlayState.SONG.arrowSkin : null));
				if (conds) dunceNote.texture = (dunceNote.mustPress ? playerNoteSkin : opponentNoteSkin);
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				unspawnNotes.shift();
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled)
					keysCheck();
				else
					playerDance();

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						final noteSpeed = songSpeed / playbackRate;
						var i:Int = 0;
						while(i < notes.length)
						{
							var daNote:Note = notes.members[i];
							i++;
							if(daNote == null || !daNote.exists) continue;

							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, Conductor.crochet, noteSpeed);

							if(daNote.mustPress)
							{
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									noteHit(daNote, false);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
									noteHit(daNote, true);

							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									noteMiss(daNote);

								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
						}
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if (strumLineNotes != null && !startingSong && strumLineNotes.length > 0){
			playerHoldCovers.updateHold(elapsed, enabledHolds);
			opponentHoldCovers.updateHold(elapsed, enabledHolds);	
		}

		setOnScripts('botPlay', cpuControlled);
		hardCodedStage?.updatePost(elapsed);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		if (!canIconBop) return;

		if(ClientPrefs.data.ogIconBop) {
			var mult1:Float = FlxMath.lerp((playerIconScale-0.2), iconP1.scale.x, CoolUtil.boundTo((playerIconScale-0.2) - (elapsed * 9 * playbackRate), 0, 1));
			iconP1.scale.set(mult1, mult1);
			iconP1.updateHitbox();

			var mult2:Float = FlxMath.lerp((opponentIconScale-0.2), iconP2.scale.x, CoolUtil.boundTo((opponentIconScale-0.2) - (elapsed * 9 * playbackRate), 0, 1));
			iconP2.scale.set(mult2, mult2);
			iconP2.updateHitbox();
		} else {
			var mult1:Float = FlxMath.lerp((playerIconScale-0.2), iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
			iconP1.scale.set(mult1, mult1);
			iconP1.updateHitbox();

			var mult2:Float = FlxMath.lerp((opponentIconScale-0.2), iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
			iconP2.scale.set(mult2, mult2);
			iconP2.updateHitbox();
		}
	}

	public dynamic function updateIconsPosition()
	{
		var iconOffset:Int = 26;
		var healthPercent:Float = FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01;
		
		if(ClientPrefs.data.ogIconBop){
			iconP1.x = healthBar.x + (healthBar.width * healthPercent - iconOffset);
			iconP2.x = healthBar.x + (healthBar.width * healthPercent) - (iconP2.width - iconOffset);
		}else{
			iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
			iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		}
	}

	var iconsAnimations:Bool = true;
	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		value = FlxMath.roundDecimal(value, 5); //Fix Float imprecision
		if(!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = (healthSet ? 1 : value);
			return health;
		}

		// update health bar
		health = (healthSet ? 1 : value);
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		var isHealthBarPercentLessThan20:Bool = healthBar.percent < 20;
		var isHealthBarPercentGreaterThan80:Bool = healthBar.percent > 80;
	
		iconP1.animation.curAnim.curFrame = (isHealthBarPercentLessThan20 ? 1 : ((isHealthBarPercentGreaterThan80) ? 2 : 0));
		iconP2.animation.curAnim.curFrame = (isHealthBarPercentGreaterThan80 ? 1 : ((isHealthBarPercentLessThan20) ? 2 : 0));
		return health;
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		if(!cpuControlled)
		{
			for (note in playerStrums)
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		#if VIDEOS_ALLOWED
		PsychVideoSprite.globalPause();
		#end
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) 
			if (isBETADCIU) {
				DiscordClient.changePresence(detailsPausedText, " (" + storyDifficultyText + ")", iconP2.getCharacter());
			} else {
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		#end
	}

	function openChartEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		chartingMode = true;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState((FlxG.keys.pressed.SHIFT ? boyfriend.curCharacter : (FlxG.keys.pressed.CONTROL ? gf.curCharacter : dad.curCharacter))));
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && gameOverTimer == null)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != LuaUtils.Function_Stop)
			{
				FlxG.animationTimeScale = 1;
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;
				canResync = false;
				canPause = false;
				#if VIDEOS_ALLOWED
				if(videoCutscene != null)
				{
					videoCutscene.destroy();
					videoCutscene = null;
				}
				#end

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				
				FlxG.camera.filters = [];

				if(GameOverSubstate.deathDelay > 0)
				{
					gameOverTimer = new FlxTimer().start(GameOverSubstate.deathDelay, function(_)
					{
						vocals.stop();
						opponentVocals.stop();
						FlxG.sound.music.stop();
						openSubState(new GameOverSubstate(boyfriend));
						gameOverTimer = null;
					});
				}
				else
				{
					vocals.stop();
					opponentVocals.stop();
					FlxG.sound.music.stop();
					openSubState(new GameOverSubstate(boyfriend));
				}

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if(autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			var value3:String = '';
			if(eventNotes[0].value3 != null)
				value3 = eventNotes[0].value3;

			triggerEvent(eventNotes[0].event, value1, value2, value3, leStrumTime);
			eventNotes.shift();
		}
	}

	public function searchLuaVar(variable:String, arg:String, result:Bool) {
		#if LUA_ALLOWED
		for (script in luaArray)
		{
			if (script.get(variable, arg) == result){
				return result;
			}
		}
		#end
		return !result;
	}

	public var usedNoteSkinEvent:Bool = false;
	public var opponentNoteSkin:String = "NOTE_assets";
	public var playerNoteSkin:String = "NOTE_assets";

	public function triggerEvent(eventName:String, value1:String, value2:String, value3:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		var flValue3:Null<Float> = Std.parseFloat(value3);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		if(Math.isNaN(flValue3)) flValue3 = null;

		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf') || dad.curCharacter.endsWith('speaker') || dad.isSpeakerChar) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'gf' | 'girlfriend' | "2":
						char = gf;
					case 'dad' | "1":
						char = dad;
					case 'boyfriend' | 'bf' | "0":
						char = boyfriend;
					default:		
						char = modchartCharacters.get(value2);	
						if (char == null) char = dad;
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case "Change Note Skin":
				var target:String = "both";
				switch(value2.toLowerCase().trim()) {
					case "opponent":
						for (strum in opponentStrums) strum.texture = value1;
						opponentNoteSkin = value1;
						target = "opponent";
					case "player":
						for (strum in playerStrums) strum.texture = value1;
						playerNoteSkin = value1;
						target = "player";
					default:
						for (strum in opponentStrums) strum.texture = value1;
						for (strum in playerStrums) strum.texture = value1;
						playerNoteSkin = opponentNoteSkin = value1;
						
				}

				for (daNote in notes.members) {
                    if (daNote != null && daNote.spawned) {
                        var shouldChange = (target == "opponent" && !daNote.mustPress) || (target == "player" && daNote.mustPress) || (target != "opponent" && target != "player");

                        if (shouldChange) {
                            daNote.texture = value1;
                        }
                    }
                }
				usedNoteSkinEvent = true;
			case 'Change Character':
				hardCodedStage?.characterChange(value1, value2);
				callOnScripts('onCharacterChange', [value1, value2]);

				//var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend' | "2":
						FunkinLua.changeCharacterAuto("gf", value2);
					case 'dad' | "opponent" | "1":
						FunkinLua.changeCharacterAuto("dad", value2);
					case 'boyfriend' | 'bf' | "0":
						FunkinLua.changeCharacterAuto("boyfriend", value2);
					default: // lua chars
					{
						var char = modchartCharacters.get(value1);	
						if (char != null){
							FunkinLua.makeLuaCharacter(value1, value2, char.isPlayer);
						}
					}
				}
				reloadHealthBarColors();

				hardCodedStage?.characterChangePost(value1, value2);
				callOnScripts('onCharacterChangePost', [value1, value2]);
			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var trueValue:Dynamic = value2.trim();
					if (trueValue == 'true' || trueValue == 'false') trueValue = trueValue == 'true';
					else if (flValue2 != null) trueValue = flValue2;
					else trueValue = value2;

					var split:Array<String> = value1.split('.');
					if (value1.contains('velocity.')){
						if (PlayState.instance != null){value2 = Std.string(Std.parseInt(value2)*playbackRate);}
					}
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], trueValue);
					} else {
						LuaUtils.setVarInArray(this, value1, trueValue);
					}
				}
				catch(e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}

			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FunkinSound.playOnce(value1, flValue2);
			case "Change Stage":
				if (value1 != null && value1 != "") {
					callOnScripts('onStageChange', [value1]);
					changeStage(value1);
					callOnScripts('onStageChangePost', [value1]);
 				}
		}

		hardCodedStage?.eventCalled(eventName, value1, value2, value3, flValue1, flValue2, flValue3, strumTime);
		callOnScripts('onEvent', [eventName, value1, value2, value3, strumTime]);
	}

	public function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			moveCameraToGirlfriend();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
		if (isDad)
			callOnScripts('onMoveCamera', ['dad']);
		else
			callOnScripts('onMoveCamera', ['boyfriend']);
	}
	
	public function moveCameraToGirlfriend()
	{
		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
		camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
		camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
		tweenCamIn();
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			if(dad == null) return;
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			if(boyfriend == null) return;
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	public var charLuaMoveScript:Bool = true; // if you wanna disable it put it on false on "setProperty".

	public function moveCameraToLuaCharacter(charFocus:String)
	{
		var char = modchartCharacters.get(charFocus);

		if(!modchartCharacters.exists(charFocus)) return;

		if(char.isPlayer)
			camFollow.setPosition(char.getMidpoint().x - 100 - char.cameraPosition[0] + boyfriendCameraOffset[0], char.getMidpoint().y - 100 + char.cameraPosition[1] + boyfriendCameraOffset[1]);
		else
			camFollow.setPosition(char.getMidpoint().x + 150 + char.cameraPosition[0] + opponentCameraOffset[0], char.getMidpoint().y - 100 + char.cameraPosition[1] + opponentCameraOffset[1]);

		if(charLuaMoveScript) callOnScripts('onMoveCamera', [char]);
		if(!char.isPlayer) tweenCamIn();
	}

	public function tweenCamIn() {
		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();

		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}


	public var transitioning = false;
	public var canDoSticker = true;
	public function endSong()
	{
		//Should kill you if you tried to cheat
		if(!startingSong)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			});
			for (daNote in unspawnNotes)
			{
				if(daNote != null && daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie' #if BASE_GAME_FILES, 'debugger' #end]);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(Song.loadedSongName, songScore, storyDifficulty, percent);
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					// FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					canResync = false;
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					canResync = false;
					LoadingState.prepareToSong();
					if (FlxG.keys.pressed.SHIFT){
						PlayState.startOnTime = Conductor.songPosition;
					}	
					LoadingState.loadAndSwitchState(new PlayState(), false, false);
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

				canResync = false;
				if (canDoSticker) openSubState(new substates.StickerSubState(null, (sticker) -> new FreeplayState(sticker)));
				else MusicBeatState.switchState(new FreeplayState());
				// FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;
	public var ratingsAlpha:Float = 1.0; // old scripts again...

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	// pool
	private var _ratingP:FlxTypedGroup<FunkinSprite>;
	private var _comboSprP:FlxTypedGroup<FunkinSprite>;
	private var _comboNumP:FlxTypedGroup<FunkinSprite>;

	private function cachePopUpScore()
	{
		var uiFolder:String = "";
		if (stageUI != "normal")
			uiFolder = uiPrefix + "UI/";

		for (rating in ratingsData)
			Paths.image(uiFolder + rating.image + uiPostfix);
		for (i in 0...10)
			Paths.image(uiFolder + 'num' + i + uiPostfix);

		if (_ratingP == null) {
			_ratingP = new FlxTypedGroup<FunkinSprite>();
			_comboSprP = new FlxTypedGroup<FunkinSprite>();
			_comboNumP = new FlxTypedGroup<FunkinSprite>();
		}
	}

	public var NVScoreTween:Bool = true; // (NV = Nightmare Vision) some people likes this, and its good for recreating mods made on it.


	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
		{
			for (spr in comboGroup)
			{
				if(spr == null) continue;

				comboGroup.remove(spr);
				
				if (Std.isOfType(spr, FunkinSprite)) {
					var _sprite:FunkinSprite = cast spr;
					_sprite.kill();

					if (_sprite.graphic != null && _sprite.graphic.key != null && _sprite.graphic.key.indexOf('num') != -1) _comboNumP.add(_sprite);
					else if (_sprite.graphic != null && _sprite.graphic.key != null && _sprite.graphic.key.indexOf('combo') != -1) _comboSprP.add(_sprite);
					else _ratingP.add(_sprite);
				} else {
					spr.destroy();
				}
			}
		}

		if (ClientPrefs.data.comboCam == "Game") {
			comboGroup.cameras = [camGame];
		}else if (ClientPrefs.data.comboCam == "HUD") {
			comboGroup.cameras = [camHUD];
		}

		var placement:Float = FlxG.width * 0.35;
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		// if(!cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		// }

		var offsetX:Float = 300;
		var offsetY:Float = 0;

		switch(curStage) {
			default: 
				offsetX += GF_X;
				offsetY = GF_Y;
		}

		var uiFolder:String = "";
		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (stageUI != "normal")
		{
			uiFolder = uiPrefix + "UI/";
			antialias = !isPixelStage;
		}

		var UISufShit = uiPostfix;

		var customRatingSkin:Bool = false;

		if (stageData.ratingSkin != null) {
			uiFolder = stageData.ratingSkin[0];
			if (uiFolder.startsWith("weeb/")) uiFolder = uiFolder.substring("weeb/".length); // we don't use the "weeb" path on this new version so yeah.
			if (uiFolder != "") {
				customRatingSkin = true;
				uiPostfix = stageData.ratingSkin[1];
			}
		}

		if (uiPostfix == '-pixel')
			antialias = false;

		if (!showRating || ratingsAlpha == 0){ //just don't run the rest if the rating is invisible
			return;
		}

		var rating:FunkinSprite = _ratingP.recycle(FunkinSprite);
		rating.revive();
		FlxTween.cancelTweensOf(rating);
		rating.velocity.set(0, 0);
		rating.acceleration.set(0, 0);
		rating.loadGraphic(Paths.image(uiFolder + daRating.image + uiPostfix));
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];
		rating.antialiasing = antialias;

		if (ClientPrefs.data.comboCam == "Game") {
			rating.x = -40 + offsetX;
			rating.y = 300 + (30 + offsetY);
		}

		for (i in [rating]) {
			i.alpha = ratingsAlpha;
		}

		var comboSpr:FunkinSprite = _comboSprP.recycle(FunkinSprite);
		comboSpr.revive();
		comboSpr.velocity.set(0, 0);
		comboSpr.acceleration.set(0, 0);
		if (showCombo) comboSpr.loadGraphic(Paths.image(uiFolder + 'combo' + uiPostfix)); // don't render if we don't need it	
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);

		if (isPixelStage && !customRatingSkin || uiPostfix == '-pixel')
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			if (ClientPrefs.data.perfectPixel == "inGame" || ClientPrefs.data.perfectPixel == "RatingAndCountdownOnly"){
				rating.pixelPerfectPosition = true;
				rating.pixelPerfectRender = true;
			}

			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
			if (ClientPrefs.data.perfectPixel == "inGame" || ClientPrefs.data.perfectPixel == "RatingAndCountdownOnly"){ 
				comboSpr.pixelPerfectPosition = true;
				comboSpr.pixelPerfectRender = true;
			}
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var fadeEase = FlxEase.expoOut;

		if(ClientPrefs.data.perfectPixel == "inGame" || ClientPrefs.data.perfectPixel == "RatingAndCountdownOnly"){
			if(NVScoreTween && isPixelStage || NVScoreTween && uiPostfix == '-pixel')
				fadeEase = EaseUtil.stepped(2);
		}

		if(NVScoreTween) {
			if (isPixelStage && !customRatingSkin || uiPostfix == '-pixel'){
				rating.scale.set(0.785 * daPixelZoom, 0.785 * daPixelZoom);
				FlxTween.tween(rating.scale, {x: 0.7 * daPixelZoom, y: 0.7 * daPixelZoom}, 0.5, {ease: fadeEase});
			}else{
				rating.scale.set(0.785, 0.785);
				FlxTween.tween(rating.scale, {x: 0.7, y: 0.7}, 0.5, {ease: fadeEase});
			}
		}

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		var customFade = FlxEase.linear;

		if(ClientPrefs.data.perfectPixel == "inGame" || ClientPrefs.data.perfectPixel == "RatingAndCountdownOnly"){
			if (isPixelStage && !customRatingSkin || uiPostfix == '-pixel')
				customFade = EaseUtil.stepped(2);
		}

		var separatedScore:String = Std.string(combo).lpad('0', 3);
		for (i in 0...separatedScore.length)
		{
			var numScore:FunkinSprite = _comboNumP.recycle(FunkinSprite);
			numScore.revive();
			numScore.velocity.set(0, 0);
			numScore.acceleration.set(0, 0);
			numScore.loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];

			if (ClientPrefs.data.comboCam == "Game") {
				numScore.x = (43 * daLoop) - 90 + offsetX;
				numScore.y = 450 + (30 + offsetY);
			}

			if (isPixelStage && !customRatingSkin || uiPostfix == '-pixel'){
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));

				if(ClientPrefs.data.perfectPixel == "inGame" || ClientPrefs.data.perfectPixel == "RatingAndCountdownOnly"){ 
					numScore.pixelPerfectPosition = true;
					numScore.pixelPerfectRender = true;
				}
			}
			else 
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));

			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;
			numScore.alpha = ratingsAlpha;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				comboGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					_comboNumP.add(numScore);
					numScore.kill();
					comboGroup.remove(numScore, true);
				},
				ease: customFade,
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			ease: customFade,
			startDelay: Conductor.crochet * 0.001 / playbackRate,
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				_comboSprP.add(comboSpr);
				comboSpr.kill();
				comboGroup.remove(comboSpr, true);

				_ratingP.add(rating);
				rating.kill();
				comboGroup.remove(rating, true);
			},
			ease: customFade,
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode)
		{
			#if debug
			//Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end

			if(FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		}
	}

	private function keyPressed(key:Int)
	{
		if(cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = [];
		for (n in notes.members) {
			if (n == null) continue;
			var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			if (canHit && !n.isSustainNote && n.noteData == key) plrInputNotes.push(n);
		}
		plrInputNotes.sort(sortHitNotes);

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}
			goodNoteHit(funnyNote);
		}
		else
		{
			if (ClientPrefs.data.ghostTapping)
				callOnScripts('onGhostTap', [key]);
			else
				noteMissPress(key, null);
		}

		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if(!keysPressed.contains(key)) keysPressed.push(key);

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrums.members[key];
		if (spr.animation.curAnim != null){
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}	
		}
		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrums.length) return;

		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		var spr:StrumNote = playerStrums.members[key];
		if(spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyRelease', [key]);
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
			}
		}
		return -1;
	}

	// Hold notes -- don't know if pulling those arrays out of the key check is a good thing but not recreating them every frame is better for optimization i think
	var holdArray:Array<Bool> = [false,false,false,false];
	var pressArray:Array<Bool> = [false,false,false,false];
	var releaseArray:Array<Bool> = [false,false,false,false];
	private function keysCheck():Void
	{
		// HOLDING
		for (i in 0...keysArray.length) {
			holdArray[i] = controls.pressed(keysArray[i]);
			pressArray[i] = controls.justPressed(keysArray[i]);
			releaseArray[i] = controls.justReleased(keysArray[i]);
		}

		//RELEASING, check for hold covers
		// if (releaseArray.contains(true))
		// {
		// 	if (playerHoldCovers != null && enabledHolds)
		// 	{
		// 		playerHoldCovers.forEach(function(spr:CoverSprite)
		// 		{
		// 			var idToInt:String = spr.spriteId;
		// 			var sprId:Int = Std.parseInt(idToInt.split("-")[1]);
		// 			if (!releaseArray[sprId])
		// 			{
		// 				if (spr.animation.curAnim != null && !spr.animation.curAnim.name.endsWith('p'))
		// 				{
		// 					spr.smoothSprite();
		// 					spr.visible = spr.boom = spr.isPlaying = false;
		// 					spr.animation.stop();
		// 				}
		// 			}
		// 	    });
		// 	}
		// }

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic)
		{
			if (notes.length > 0) {
				for (n in notes) { // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit
						&& n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote) {
						var released:Bool = !holdArray[n.noteData];

						if (!released)
							goodNoteHit(n);
					}
				}
			}

			if (!holdArray.contains(true) || endingSong)
				playerDance();

			#if ACHIEVEMENTS_ALLOWED
			else checkForAchievement(['oversinging']);
			#end
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		if (daNote != null) playerHoldCovers.despawnOnMiss(strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong, daNote.noteData, daNote);

		var dType:Int = 0;
		if (daNote != null) dType = daNote.dType;
		else if (!startingSong) dType = PlayState.SONG.notes[curSection].dType;

		noteMissCommon(daNote.noteData, daNote);
		hardCodedStage?.noteMiss(daNote);
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.dType]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1, ?daNote:Note = null):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		var dType:Int = 0;
		if (daNote != null) dType = daNote.dType;
		else if (!startingSong) dType = PlayState.SONG.notes[curSection].dType;

		noteMissCommon(direction);
		FunkinSound.playOnce('missnote${FlxG.random.int(1, 3)}', FlxG.random.float(0.1, 0.2));
		hardCodedStage?.noteMissPress(direction);
		callOnScripts('noteMissPress', [direction, dType]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = pressMissDamage;
		if(note != null) subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
					childNote.alpha = 0.35;
					childNote.multAlpha = 0.35;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -[REDACTED]
			}

			if (note.missed)
				return;
		}

		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
					child.alpha = 0.35;
					child.multAlpha = 0.35;
				}
			}

			if (note.missed)
				return;
		}

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}

		var lastCombo:Int = combo;
		combo = 0;

		health -= subtract * healthLoss;
		songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		// play character anims
		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

		if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			var canPlay = searchLuaVar('playBFSing', 'bool', false); // char.specialAnim;
			var postfix:String = '';
			if(note != null) postfix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + postfix;
			
			if (canPlay) char.playAnim(animToPlay, true);

			if(char != gf && lastCombo > 5 && gf != null && gf.hasAnimation('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		vocals.volume = 0;
	}

	// just to avoid errors on scripts
	public function goodNoteHit(note:Note):Void { noteHit(note, false); }
	public function opponentNoteHit(note:Note):Void { noteHit(note, true); }

	public function noteHit(note:Note, opponentHit:Bool):Void { // unified it
		if (!opponentHit) {
			if (note.wasGoodHit) return;
			if (cpuControlled && note.ignoreNote) return;
		}

		final isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		final leData:Int = Math.round(Math.abs(note.noteData));
		final leType:String = note.noteType;
		final causesMiss:Bool = !opponentHit && note.hitCausesMiss;

		var result:Dynamic = callOnLuas(opponentHit ? "opponentNoteHitPre" : "goodNoteHitPre", [notes.members.indexOf(note), leData, leType, isSus, note.dType]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			result = callOnHScript(opponentHit ? "opponentNoteHitPre" : "goodNoteHitPre", [note]);

		if (opponentHit) playDad = searchLuaVar('playDadSing', 'bool', false);
		else playBF = searchLuaVar('playBFSing', 'bool', false);

		if (result == LuaUtils.Function_Stop) return;

		if (opponentHit) {
			if (songName != 'tutorial') camZooming = true;
		} else {
			note.wasGoodHit = true;
			if (note.hitsoundVolume > 0 && !note.hitsoundDisabled) FunkinSound.playOnce(note.hitsound, note.hitsoundVolume);
		}

		if (!causesMiss) {
			var shouldAnimate:Bool = opponentHit ? (!note.noAnimation && playDad) : (!note.noAnimation && playBF);

			if (shouldAnimate) {
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))] + note.animSuffix;
				var charsToProcess:Array<{char:Character, animCheck:String}> = [];
				var mainChar:Character = note.gfNote ? gf : (opponentHit ? dad : boyfriend);
				var mainAnimCheck:String = note.gfNote ? 'cheer' : 'hey';

				charsToProcess.push({char: mainChar, animCheck: mainAnimCheck});

				for (key in modchartCharacters.keys()) {
					var modChar:Character = modchartCharacters.get(key);
					if (modChar != null && (opponentHit ? !modChar.isPlayer : modChar.isPlayer)) charsToProcess.push({char: modChar, animCheck: 'hey'});
				}

				for (entry in charsToProcess) {
					var char:Character = entry.char;
					if (char == null || !char.playSingAnim) continue;

					var canPlay:Bool = true;

					if (note.isSustainNote) {
						var holdAnim:String = animToPlay + '-hold';
						if (char.animation.exists(holdAnim)) animToPlay = holdAnim;

						var currentAnim:String = char.animation.curAnim != null ? char.animation.curAnim.name : '';
						if (currentAnim == holdAnim || currentAnim == holdAnim + '-loop') canPlay = false;
					}

					if (!(char.vSliceSustains && note.isSustainNote) && canPlay) char.playAnim(animToPlay, true);

					char.holdTimer = 0;

					if (note.noteType == 'Hey!' && char.hasAnimation('hey')) {
						if (char.animation.exists(entry.animCheck)) {
							char.playAnim(entry.animCheck, true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}

			if (opponentHit) {
				if (opponentVocals.length <= 0) vocals.volume = 1;
				strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
				note.hitByOpponent = true;
			} else {
				if (!cpuControlled) {
					var spr = playerStrums.members[note.noteData];
					if (spr != null && (spr.animation != null && spr.animation.curAnim.name != 'confirm')) spr.playAnim('confirm', true);
				}
				else strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
				vocals.volume = 1;

				if (!note.isSustainNote) {
					combo++;
					if (combo > 9999) combo = 9999;
					popUpScore(note);
				}

				var gainHealth:Bool = true;
				if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
				if (gainHealth) health += note.hitHealth * healthGain;
			}
		} else {
			if (!note.noMissAnimation && playBF) {
				switch (note.noteType) {
					case 'Hurt Note':
						if (boyfriend.hasAnimation('hurt')) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}

			noteMiss(note);
			if (!note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
		}

		if (enabledHolds) {
			final holdCover = opponentHit ? opponentHoldCovers : playerHoldCovers;
			holdCover.spawnOnNoteHit(note, strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong);
		}

		if (opponentHit) hardCodedStage?.opponentNoteHit(note);
		else hardCodedStage?.goodNoteHit(note);

		var result:Dynamic = callOnLuas(opponentHit ? "opponentNoteHit" : "goodNoteHit", [notes.members.indexOf(note), leData, leType, isSus, note.dType]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			callOnHScript(opponentHit ? "opponentNoteHit" : "goodNoteHit", [note]);

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note, strum);
		}
	}

	public function spawnNoteSplash(x:Float = 0, y:Float = 0, ?data:Int = 0, ?note:Note, ?strum:StrumNote) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.babyArrow = strum;
		splash.spawnSplashNote(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		if (psychlua.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}

		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = null;
		FunkinLua.customFunctions.clear();
		#end

		_sharables.clear();
		_sharables = null;
		
		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				script.destroy();
			}

		hscriptArray = null;
		#end
		hardCodedStage?.destroy();

		#if VIDEOS_ALLOWED
		if(videoCutscene != null)
		{
			videoCutscene.destroy();
			videoCutscene = null;
		}
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxG.camera.filters = [];

		#if FLX_PITCH if (FlxG.sound.music != null) FlxG.sound.music.pitch = 1; #end
		FlxG.animationTimeScale = 1;

		NoteRGBShader.globalRgbShaders = [];
		NoteSkinConfig.clear();

		backend.NoteTypesConfig.clearNoteTypesData();

		NoteSplash.configs.clear();
		instance = null;
		super.destroy();
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();

		if (generatedMusic && ClientPrefs.data.streamedNotes) loadUpcomingNotes();

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;
	public var opponentIconScale:Float = 1.2;
	public var playerIconScale:Float = 1.2;
	public var iconBopSpeed:Int = 1;
	public var canIconBop:Bool = true;//this is useful, change my mind.
	public var canIconMove:Bool = true;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		if (curBeat % iconBopSpeed == 0 && canIconBop) {
			iconP1.scale.set(playerIconScale, playerIconScale);
			iconP2.scale.set(opponentIconScale, opponentIconScale);
		
			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}

		characterBopper(curBeat);

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public function characterBopper(beat:Int):Void
	{
		if (gfSpeed == 0) gfSpeed = 1; // sigh...
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.getAnimationName().startsWith('sing') && !gf.stunned)
			gf.dance();

		if (boyfriend != null && beat % boyfriend.danceEveryNumBeats == 0 && !boyfriend.getAnimationName().startsWith('sing') && !boyfriend.stunned)
			boyfriend.dance();

		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();

		for (value in modchartCharacters.keys()) {
			var char:Character = modchartCharacters.get(value);
			if (char != null && beat % char.danceEveryNumBeats == 0 && !char.getAnimationName().startsWith('sing') && !char.stunned)
				char.dance();
		}
	}

	public function playerDance():Void
	{
		var anim:String = boyfriend.getAnimationName();
		if(boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * boyfriend.singDuration && anim.startsWith('sing') && !anim.endsWith('miss'))
			boyfriend.dance();

		for (value in modchartCharacters.keys()) {
			var char:Character = modchartCharacters.get(value);
			var anim:String = char.getAnimationName();
			if(char.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * char.singDuration && anim.startsWith('sing') && !anim.endsWith('miss'))
				char.dance();
		}
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
				setOnScripts('crotchet', Conductor.crochet); // NV
				setOnScripts('stepCrotchet', Conductor.stepCrochet); // NV
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String, ?type:String = "")
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;

			new FunkinLua(luaToLoad, type);
			return true;
		}
		return false;
	}

	public function stopLuasNamed(luaFile:String, ?type:String = "")
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray) {
				if (script.scriptName == luaToLoad) {
					// Because the shaders weren't getting destroyed properly. Changed it to onDestroy
					script.call("onDestroy", []);
					luaArray.remove(script);
					script = null;
					return true;
				}
			}

		}
		return false;
	}

	public function nameScriptsCharacter(file:String, ?name:String = "")
	{
		nameLuaCharacter(file, name);
		nameHScriptCharacter(file, name);
	}

	public function nameLuaCharacter(luaFile:String, ?name:String = "")
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray) {
				if (script.scriptName == luaToLoad) {
					script.set("charNameScript", name);
					return true;
				}
			}
		}
		return false;
	}

	public function nameHScriptCharacter(scriptFile:String, ?name:String = "")
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)){
				var script:HScript = cast (Iris.instances.get(scriptToLoad), HScript);
				script.set("charNameScript", name);
				return true;
			};
		}
		return false;
	}

	public function callLuaFile(luaFile:String, ?callLua:String = "")
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray) {
				if (script.scriptName == luaToLoad) {
					// Custom function call
					script.call(callLua, []);
					return true;
				}
			}

		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String, ?scriptType:String = "")
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad, scriptType);
			return true;
		}
		return false;
	}

	public function stopHScriptsNamed(scriptFile:String, ?scriptType:String = "")
		{
			#if MODS_ALLOWED
			var scriptToLoad:String = Paths.modFolders(scriptFile);
			if(!FileSystem.exists(scriptToLoad))
				scriptToLoad = Paths.getSharedPath(scriptFile);
			#else
			var scriptToLoad:String = Paths.getSharedPath(scriptFile);
			#end
	
			if(FileSystem.exists(scriptToLoad))
			{
				if (Iris.instances.exists(scriptToLoad)){
					var script:HScript = cast (Iris.instances.get(scriptToLoad), HScript);
					if(script.exists('onDestroy')) script.call('onDestroy');
					script.destroy();
					hscriptArray.remove(script);
					script = null;
					return true;
				};
			}
			return false;
		}

	public function callHScriptFile(scriptFile:String, ?callHScript:String = "")
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)){
				var script:HScript = cast (Iris.instances.get(scriptToLoad), HScript);
				if(script.exists(callHScript)) script.call(callHScript);
				return true;
			};
		}
		return false;
	}

	var _sharables:Sharables = new Sharables(); // bcuz we don't have script groups **yet**

	public function initHScript(file:String, ?scriptType:String = "")
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file, scriptType, null, false, _sharables);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			trace('HScript Loaded: $file');
			hscriptArray.push(newScript);
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast (Iris.instances.get(file), HScript);
			if(newScript != null)
				newScript.destroy();
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{
			if(script.closed)
			{
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(script.closed) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for(script in hscriptArray)
		{
			@:privateAccess
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var callValue = script.call(funcToCall, args);
			if(callValue != null)
			{
				var myValue:Dynamic = callValue.returnValue;

				if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			if (spr.animation != null && spr.animation.curAnim.name != 'confirm') spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var accuracy:Float; // old scripts
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true):Void {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != LuaUtils.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				accuracy = CoolUtil.floorDecimal(ratingPercent * 100, 2);
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length-1)
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
		setOnScripts('totalPlayed', totalPlayed);
		setOnScripts('totalNotesHit', totalNotesHit);
		updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode) return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if(cpuControlled) return;

		for (name in achievesToCheck) {
			if(!Achievements.exists(name)) continue;

			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
			{
				switch(name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}

			if(unlock) Achievements.unlock(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end
	public function createRuntimeShader(shaderName:String):ErrorHandledRuntimeShader
	{
		#if (!flash && sys)
		if(!ClientPrefs.data.shaders) return new ErrorHandledRuntimeShader(shaderName);

		if(!runtimeShaders.exists(shaderName) && !initLuaShader(shaderName))
		{
			FlxG.log.warn('Shader $shaderName is missing!');
			return new ErrorHandledRuntimeShader(shaderName);
		}

		var arr:Array<String> = runtimeShaders.get(shaderName);
		return new ErrorHandledRuntimeShader(shaderName, arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (!flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if(FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				//trace('Found shader $name!');
				return true;
			}
		}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
			#else
			FlxG.log.warn('Missing shader $name .frag AND .vert files!');
			#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}

	public function changeStage(id:String, ?preload:Bool = false) {
		removeStage(preload); // Remove current stage	
		curStage = id; // Set new stage name
 		stageData = StageData.getStageFile(curStage); 
 		addStage(false, preload);
		setOnScripts('curStage', curStage);
	}

	public function setStageDetails(stageData:StageFile){
		defaultCamZoom = stageData.defaultZoom;

		var dir:String = stageData.directory;
		if (dir != null) {
			if (Paths.currentLevel != dir) trace('Setting asset folder to ' + ((dir != "") ? '$dir.' : 'default.'));
			Paths.setCurrentLevel(dir);
		}

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) //Backward compatibility
			stageUI = "pixel";

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		return stageData;
	}

	public function removeObjects(stageData:StageFile){
		// if you comment out the else part, the stage loads fine but character layers and positions are messed up.
		if(stageData.objects != null && stageData.objects.length > 0)
		{
			var list:Map<String, FlxSprite> = StageData.removeObjectsFromState(stageData.objects, !stageData.hide_girlfriend ? gf : null, dad, boyfriend, this);
			for (key => spr in list)
				if(!StageData.reservedNames.contains(key))
					variables.remove(key);
		}else{
			if (gf != null) remove(gfGroup);
			remove(dadGroup); 
			remove(boyfriendGroup);

			if (gf != null) remove(gf);
			remove(dad);
			remove(boyfriend);
		}

		// this should help for base stages
		if (ClientPrefs.data.comboCam == "Game") remove(comboGroup);
	}

	public var gfOldChar:String = '';

	public function addObjects(stageData:StageFile){
		if(stageData.objects != null && stageData.objects.length > 0)
		{
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gf : null, dad, boyfriend, this);
			for (key => spr in list)
				if (!StageData.reservedNames.contains(key))
					variables.set(key, spr);
		}
		else
		{
			add(gfGroup); // keeping this bcuz without this the game won't load the stage?????
			add(dadGroup); // keeping this bcuz without this the game won't load the stage?????
			add(boyfriendGroup); // keeping this bcuz without this the game won't load the stage?????

			add(gf);
			add(dad);
			add(boyfriend);
		}

		if(ClientPrefs.data.perfectPixel == "inGame"){
			gf.pixelPerfectPosition = stageData.isPixelStage;
			gf.pixelPerfectRender = stageData.isPixelStage;
			dad.pixelPerfectPosition = stageData.isPixelStage;
			dad.pixelPerfectRender = stageData.isPixelStage;
			boyfriend.pixelPerfectPosition = stageData.isPixelStage;
			boyfriend.pixelPerfectRender = stageData.isPixelStage;
		}

		if(ClientPrefs.data.comboCam == "Game") add(comboGroup);
	}

	/*
	function callGlobal(tag:String)
	{
		if (tag == 'characterChange') {
			stagesFunc(function(stage:BaseStage) stage.characterChange(value1, value2));
		} else if (tag == 'characterChangePost') {
			stagesFunc(function(stage:BaseStage) stage.characterChangePost(value1, value2));
		}

		callOnScripts('onCharacterChangePost', [value1, value2]);
	}
	*/

	public var hardCodedStage:Null<BaseStage>; // oh hey, its nullable now
	public var addedStages:Array<String> = [];
	public var addedStagesHScript:Array<String> = [];

	public function removeStage(?preload:Bool=false) {
		removeObjects(stageData);

		if (hardCodedStage != null) {
			hardCodedStage.destroy();
			stages.remove(hardCodedStage);
			hardCodedStage = null;
		}

		// STAGE SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		#if LUA_ALLOWED 
		stopLuasNamed('stages/' + curStage + '.lua', "stage");
		for (stage in addedStages) stopLuasNamed(stage, "stage"); #end
		#if HSCRIPT_ALLOWED 
		stopHScriptsNamed('stages/' + curStage + '.hx', "stage"); 
		for (stage in addedStagesHScript) stopHScriptsNamed(stage, "stage"); #end
		#end

		var stageVars:Map<String, FlxSprite> = MusicBeatState.getVariables().get("stageVariables");
	
		if (stageVars != null) {
			for (key in stageVars.keys()) {
				var sprite:FlxSprite = stageVars.get(key);

				if (sprite != null) {
					sprite.kill();
					// variables.get("stageVariables").remove(key);
					sprite.destroy();
				}
			}
			stageVars.clear();
		}
	}

	public function addStage(?onlyLuas:Bool=false, ?preload:Bool=false) {
		if(!preload) {
			setStageDetails(stageData); // for some reason they don't add the chars position on them.
		} else {
			var dir:String = stageData.directory;
			if (dir != null) {
				Paths.setCurrentLevel(dir);
				trace('Setting asset folder to ' + ((dir != "") ? '$dir.' : 'default.'));
			}
		}

		hardCodedStage = StageData.returnStage(curStage);

		addObjects(stageData);

		// STAGE SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		#if LUA_ALLOWED startLuasNamed('stages/' + curStage + '.lua', "stage"); #end
		#if HSCRIPT_ALLOWED if (!onlyLuas) startHScriptsNamed('stages/' + curStage + '.hx', "stage"); #end
		#end

		if(!preload){
			hardCodedStage?.createPost();
			callLuaFile('stages/' + curStage + '.lua', 'onCreatePost');
			callHScriptFile('stages/' + curStage + '.hx', 'onCreatePost');
		}
	}

	// just testing
	function set_boyfriend(value:Character):Character {
		if (value != null) value.playSingAnim = true;
		return boyfriend = value;
	}

	function set_dad(value:Character):Character {
		if (value != null) value.playSingAnim = true;
		return dad = value;
	}

	function set_gf(value:Character):Character {
		if (value != null) value.playSingAnim = true;
		return gf = value;
	}
}
