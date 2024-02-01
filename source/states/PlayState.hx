package states;

import flixel.FlxGame;
import flixel.FlxState;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.FlxSubState;
import flixel.addons.ui.FlxInputText;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.ui.FlxBar;
import flixel.util.FlxPool;
import flixel.util.FlxSort;
import flixel.util.FlxGradient;
import flixel.util.FlxCollision;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxAssets;
import flixel.addons.plugin.screengrab.FlxScreenGrab;

import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.filters.BlurFilter;
import openfl.filters.ColorMatrixFilter;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.AssetManifest;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetType;
import openfl.events.KeyboardEvent;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import lime.graphics.Image;
import lime.app.Application;
import lime.media.AudioContext;
import lime.media.AudioManager;

import backend.Section.SwagSection;
import backend.Song;
import backend.Song.SwagSong;
import backend.Replay;
import backend.WeekData;
import backend.HelperFunctions;
import backend.ConvertScore;
import backend.EtternaFunctions;
import backend.Ratings;
import substates.GameOverSubstate;
import flixel.animation.FlxAnimationController;

import haxe.Json;
import haxe.Exception;

import states.editors.ChartingState;
import states.editors.CharacterEditorState;
import states.editors.StageEditorState;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
#end

import objects.Note;
import objects.Stage;
import objects.Character;
import objects.Boyfriend;
import objects.StrumNote;
import objects.NoteSplash;
import objects.HealthIcon;
import objects.DeltaTrail;
import objects.Note.EventNote;
import objects.CharacterOffsets;

#if sys
import lime.media.AudioBuffer;
import flash.media.Sound;
#end

#if LUA_ALLOWED
import luafiles.LuaClass.LuaCamera;
import luafiles.LuaClass.LuaNote;
#end

import openfl.system.System;

import cutscenes.DialogueBoxPsych;
import cutscenes.DialogueBox;

import shaders.Shaders;
import shaders.WiggleEffect;
import shaders.WiggleEffect.WiggleEffectType;
import shaders.MotionBlur;

import states.MainMenuState;

#if LUA_ALLOWED
import luafiles.*;
#else
import luafiles.ModchartState;
import luafiles.LuaUtils;
import luafiles.HScript;
import luafiles.DebugLuaText;
#end

using StringTools;

#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler;
#else import vlc.MP4Handler as VideoHandler; #end
#end

class PlayState extends MusicBeatState
{
	public static var instance:PlayState;

	//Filter array for bitmap bullshit ya for shaders
	public var filters:Array<BitmapFilter> = [];
	public var filterList:Array<BitmapFilter> = [];
	public var camfilters:Array<BitmapFilter> = [];
	var shadersLoaded:Bool = false;
	public var chromOn:Bool = false;
	var ch = 2 / 1000;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var isBETADCIU:Bool = false;
	public static var isNeonight:Bool = false;
	public static var isVitor:Bool = false;
	public static var isBonus:Bool = false;
	public static var customLoaded:Bool = false;
	public static var showCutscene:Bool = false;
	public static var downScrollEvent:Bool = false;
	public static var isPixel:Bool = false;
	public static var upScrollEvent:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var weekSong:Int = 0;
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;

	public var disableSenTanIcons = false;
	public var stopCountdown = false;

	var camMovement:Float = 0.09;
	public var shakeCam:Bool = false;

	public static var songPosBG:FlxSprite;
	public static var songPosBar:FlxBar;

	var evilTrail:FlxTrail;
	var usedTimeTravel:Bool = false;
	var trailShit:Bool = false;

	var shootStepsBallistic:Array<Int> = [284, 368, 384, 422, 430, 454, 462, 542, 656, 686, 750, 846, 878, 894, 910, 926, 976, 977, 1024, 1025, 1056, 1120, 1198, 1230, 1262, 1294, 1574, 1606, 1696, 1712, 1760, 1776, 1832, 1848, 1906, 1952, 2018, 2036, 2078];
	var bfTransformSteps:Array<Int> = [368, 369, 371, 372, 374, 375, 378, 379, 382, 383, 624, 625, 628, 629, 632, 633, 636, 637, 752, 753, 756, 757, 760, 761, 764, 765, 1008, 1009, 1012, 1013, 1016, 1017, 1020, 1021, 1024];

	public static var rep:Replay;
	public static var loadRep:Bool = false;

	public static var noteBools:Array<Bool> = [false, false, false, false];

	public var tabiZoom:Bool = false;
	public var mania:Int = 0;

	public var tordCam:Array<FlxPoint> = [new FlxPoint(391.2,-1094.15),new FlxPoint(290.9,-1094.15),new FlxPoint(450.9,-1094.15),new FlxPoint(374.9,-1174.15),new FlxPoint(570.9,-974.15)];

	var songLength:Float = 0;

	public var picoCutscene:Bool = false;
	
	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var vocals:FlxSound;
	public var inst:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public static var preloadChar:Character;
	public static var chartingMode:Bool = false;

	var blackScreen:FlxSprite;

	//dialogue shenanigans
	var doof:DialogueBox;
	public var dialogue:Array<String> = ['dad:blah blah blah', 'bf:coolswag'];
	var dialogueJson:DialogueFile = null;

	public var healthSet:Bool = false;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var strumLine:FlxSprite;

	//flipped it so it doesn't mess with some of my luas that use camFollow
	public var camFollow:Dynamic;
	public var camFollowPos:FlxObject;
	public static var prevCamFollow:Dynamic;
	public static var prevCamFollowPos:FlxObject;

	public var cameraSystem(default, set):String = "kade"; // so that you can toggle.

	public var strumLineNotes:FlxTypedGroup<StrumNote> = null;
	public var playerStrums:FlxTypedGroup<StrumNote> = null;
	public var opponentStrums:FlxTypedGroup<StrumNote> = null;
	
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var psychCamZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;//
	public var health:Float = 1; //making public because sethealth doesnt work without it
	public var maxHealth:Float = 2; //making public because sethealth doesnt work without it
	public var combo:Int = 0;
	public var songMisses:Int = 0;
	public var songHits:Int = 0;

	public var accuracy:Float = 0.00;
	private var accuracyDefault:Float = 0.00;
	private var totalNotesHit:Float = 0;
	private var totalNotesHitDefault:Float = 0;
	private var totalPlayed:Int = 0;
	private var ss:Bool = false;

	var healthBarBG:FlxSprite;
	public var healthBar:FlxBar; //pls don't die
	private var songPositionBar:Float = 0;

	//we do a bit of trollin
	public var timeBarBG:FlxSprite;
	public var timeBar:FlxBar;
	public var timeTxt:FlxText;
	public var updateTime:Bool = false;

	private var generatedMusic:Bool = false;
	public var startingSong:Bool = false;

	public var iconP1:HealthIcon; //making these public again because i may be stupid
	public var iconP2:HealthIcon; //what could go wrong?
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;
	public var camGame:FlxCamera;
	public var cameraSpeed(default, set):Float = 1;

	//detected
	public var camSustains:FlxCamera;
	public var camNotes:FlxCamera;

	public var playDad:Bool = true;
	public var playBF:Bool = true;

	var notesHitArray:Array<Date> = [];
	var currentFrames:Int = 0;

	public var triggeredFlip:Bool = false;

	var daSection:Int = 0;

	var removedTrail:Bool = false;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	var songName:FlxText;
	var altAnim:String = "";
	var bfAltAnim:String = "";

	var fc:Bool = true;
	var comboSpr:FlxSprite;

	public static var deathCounter:Int = 0;

	//var wiggleShit:WiggleEffect = new WiggleEffect();

	public var songScore:Int = 0;
	public var songScoreDef:Int = 0;
	public var scoreTxt:FlxText;
	var replayTxt:FlxText;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	public static var daPixelZoom:Float = 6;

	public static var theFunne:Bool = true;
	public var inCutscene:Bool = false;
	public static var seenCutscene:Bool = false;
	public static var repPresses:Int = 0;
	public static var repReleases:Int = 0;
	public var floatshit:Float = 0;

	public static var timeCurrently:Float = 0;
	public static var timeCurrentlyR:Float = 0;
	
	// Will fire once to prevent debug spam messages and broken animations
	private var triggeredAlready:Bool = false;
	
	// Will decide if she's even allowed to headbang at all depending on the song
	private var allowedToHeadbang:Bool = false;
	// Per song additive offset
	public static var songOffset:Float = 0;
	// Replay shit
	private var saveNotes:Array<Float> = [];

	public var executeModchart = false;
	
	//note shit
	public static var alt:String;
	public static var alt2:String;

	var shootArray:Array<Int> = [];
	// control arrays, order L D U R dumbass
	var holdArray:Array<Bool> = [];
	var pressArray:Array<Bool> = [];	
	var releaseArray:Array<Bool> = [];

	// API stuff
	
	public function addObject(object:FlxBasic) { add(object); }
	public function removeObject(object:FlxBasic) { remove(object); }
	public function destroyObject(object:FlxBasic) { object.destroy(); }

	var pixelSwap:Bool = false;
	var usesStageHx:Bool = false;
	public var defaultBar:Bool = true;
	public var skipCountdown:Bool = false;

	public var splashSkin:String = '';

	public var Stage:Stage = null;
	public var PreloadStage:Stage = null;

	public var bfStrumStyle:String = "";
	public var camFollowSpeed:Float = 0.04; // so I can modify how fast the camera moves
	var isMania = false;

	var songLowercase:String = "";
	public var hasDialogue = false;	
	var songPercent:Float = 0;

	public var isCameraOnForcedPos:Bool = false;

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	#end

	#if LUA_ALLOWED
	public var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartIcons:Map<String, HealthIcon> = new Map<String, HealthIcon>(); //should also help for cosmic
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartCharacters:Map<String, Character> = new Map<String, Character>(); //worth a shot
	public var modchartCameras:Map<String, FlxCamera> = new Map<String, FlxCamera>(); // FUCK!!!
	public var modchartTrails:Map<String, DeltaTrail> = new Map<String, DeltaTrail>(); // modchart 	trails for real this time
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartInputTexts:Map<String, FlxInputText> = new Map<String, FlxInputText>(); //because monochrome
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	public var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	#end

	public var shader_chromatic_abberation:ChromaticAberrationEffect;
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];
	public var shaderUpdates:Array<Float->Void> = [];

	public var isDetected:Bool = false;
	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var isPaused:Bool = false; //because sometimes you used paused without actually pausing the game

	public var playbackRate(default, set):Float = 1;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	public var playerSingAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	public var startedLua:Bool = false;

	public var engineDebugKeys:Array<FlxKey> = [FlxKey.ONE, FlxKey.TWO, FlxKey.THREE, FlxKey.FOUR, FlxKey.FIVE, FlxKey.SIX, FlxKey.SEVEN, FlxKey.EIGHT, FlxKey.NINE];
	public static var inPlayState:Bool = false; //there's gotta be an easier way for this to be read.

	override public function create()
	{
		instance = this;

		MainMenuState.mainMusic = false; //to fix that weird bug with the inst still playing if you quit really fast

		picoCutscene = false;
		isPixel = false;

		GameOverSubstate.resetVariables();
		playbackRate = 1;
		startingFPS = Main.getFPSStatic();
	
		var suf:String = "";
		if (isNeonight)
		{
			if (!FlxG.save.data.stageChange)
				suf = '-neo-noStage';				
			else
				suf = '-neo';				
		}
		if (isVitor)
			suf = '-vitor';		

		if (CoolUtil.difficulties[0] == "Guest")
			suf = '-guest';

		if (isBETADCIU && FileSystem.exists(Paths.lua(SONG.song.toLowerCase()  + "/modchart-betadciu")))
			suf = '-betadciu';

		FlxG.mouse.visible = false;
		
		if (FlxG.save.data.fpsCap > 240)
			(cast (Lib.current.getChildAt(0), Main)).setFPSCap(240);
		
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;

		songMisses = 0;

		repPresses = 0;
		repReleases = 0;

		// pre lowercasing the song name (create)
		songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle': songLowercase = 'dadbattle';
			case 'philly-nice': songLowercase = 'philly';
		}
		
		#if desktop
		executeModchart = FileSystem.exists(Paths.lua(songLowercase  + "/modchart" + suf));
		#end
		#if !cpp
		executeModchart = false; // FORCE disable for non cpp targets
		#end

		trace('Mod chart: ' + executeModchart + " - " + Paths.lua(songLowercase + "/modchart" + suf));

		#if desktop
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty)
		{
			case 0:	storyDifficultyText = "Easy";
			case 1: storyDifficultyText = "Normal";
			case 2: storyDifficultyText = "Hard";
			case 3: storyDifficultyText = "Neonight Ver.";		
			case 4: storyDifficultyText = "Vitor0502 Ver.";
		}

		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode: Week " + storyWeek;
		if (isBETADCIU || isNeonight || isVitor)
			detailsText = SONG.song + " But Every Turn A Different Cover is Used";
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | songMisses: " + songMisses  , iconRPC);
		#end

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camSustains = new FlxCamera();
		camSustains.bgColor.alpha = 0;
		camNotes = new FlxCamera();
		camNotes.height = 1300;
		camNotes.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camSustains, false);
		FlxG.cameras.add(camNotes, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		//FlxCamera.defaultCameras = [camGame];
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		add(luaDebugGroup);
		luaDebugGroup.cameras = [camOther];
		
		if(FlxG.save.data.distractions && SONG.stage == 'garage'){
			camGame.setFilters(filters);
			camGame.filtersEnabled = true;
			camHUD.setFilters(camfilters);
			camHUD.filtersEnabled = true;
		}

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial', 'tutorial');
		
		mania = SONG.mania;
		isMania = (SONG.mania > 0);

		isDetected = (SONG.song.toLowerCase() == 'detected');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		blackScreen = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 4), Std.int(FlxG.height * 4), FlxColor.BLACK);
		blackScreen.scrollFactor.set();
	
		trace('INFORMATION ABOUT WHAT U PLAYIN WIT:\nFRAMES: ' + Conductor.safeFrames + '\nZONE: ' + Conductor.safeZoneOffset + '\nTS: ' + Conductor.timeScale + '\nBotPlay : ' + FlxG.save.data.botplay);
	
		//defaults if no stage was found in chart
		var stageCheck:String = 'stage';
		
		if (SONG.stage == null) {
			switch(storyWeek)
			{
				case 2: stageCheck = 'halloween';
				case 3: stageCheck = 'philly';
				case 4: stageCheck = 'limo';
				case 5: if (songLowercase == 'winter-horrorland') {stageCheck = 'mallEvil';} else {stageCheck = 'mall';}
				case 6: if (songLowercase == 'thorns') {stageCheck = 'schoolEvil';} else {stageCheck = 'school';}
				case 7: stageCheck = 'tank';
				//i should check if its stage (but this is when none is found in chart anyway)
			}
		} else {stageCheck = SONG.stage;}

		Stage = new Stage(stageCheck, false);
		defaultCamZoom = Stage.camZoom;
		curStage = Stage.curStage;
		usesStageHx = true;

		setCameraOffsets();

		for (i in Stage.toAdd)
			add(i);

		//defaults if no gf was found in chart
		var gfCheck:String = 'gf';
		
		if (SONG.gfVersion == null) {
			switch(storyWeek)
			{
				case 4: gfCheck = 'gf-car';
				case 5: gfCheck = 'gf-christmas';
				case 6: gfCheck = 'gf-pixel';
			}
		} else {gfCheck = SONG.gfVersion;}

		var gfVersion:String = 'gf';

		gfVersion = gfCheck;

		if (FileSystem.exists(Paths.txt(songLowercase  + "/preload" + suf)))
		{
			var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload" + suf));

			for (i in 0...characters.length) // whoops. still need to load the luas
			{
				var data:Array<String> = characters[i].split(' ');
				startCharLuas.push(characters[i]);
			}
		}

		if (Stage.hideGirlfriend)
			gfVersion = 'emptygf';

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		var gfOffset = new CharacterOffsets(SONG.gfVersion, false, true);
		var daGFX:Float = gfOffset.daOffsetArray[0];
		var daGFY:Float = gfOffset.daOffsetArray[1];

		if (gf.isCustom)
		{
			gf.x += gf.positionArray[0];
			gf.y += gf.positionArray[1];
		}	
			
		gf.x += daGFX;
		gf.y += daGFY;

		comboGroup = new FlxSpriteGroup(FlxG.width * 0.55, (FlxG.height * 0.5) - 60);

		dad = new Character(100, 100, SONG.player2);
		//trace('found dad character');

		var camPos:FlxPoint;

		if (gf.getGraphicMidpoint().x <= -1000 || gf.getGraphicMidpoint().x >= 1500)
			camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);
		else
			camPos = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
			
		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}
			default:
				if (dad.isCustom)
				{
					dad.x += dad.positionArray[0];
					dad.y += dad.positionArray[1];
				}	
				else
				{
					//this should save me like 200 lines or smthn
					var offset = new CharacterOffsets(SONG.player2, false);
					var daX:Float = offset.daOffsetArray[0];
					var daY:Float = offset.daOffsetArray[1];

					if (offset.daOffsetArray[0] == 0 && offset.daOffsetArray[1] == 0 && offset.hasOffsets == false)
					{
						offset = new CharacterOffsets(SONG.player2, true);
						daX = offset.daOffsetArray[0];
						daY = offset.daOffsetArray[1] + 350;
					}
						
					dad.x += daX;
					dad.y += daY;
				}	
		}
		
		boyfriend = new Boyfriend(770, 450, SONG.player1);

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			default:
				if (usesStageHx)
				{
					boyfriend.x += Stage.bfXOffset;
					boyfriend.y += Stage.bfYOffset;
					dad.x += Stage.dadXOffset;
					dad.y += Stage.dadYOffset;
					gf.x += Stage.gfXOffset;
					gf.y += Stage.gfYOffset;
					boyfriend.scrollFactor.set(Stage.bfScrollFactor[0], Stage.bfScrollFactor[1]);
					dad.scrollFactor.set(Stage.dadScrollFactor[0], Stage.dadScrollFactor[1]);
					gf.scrollFactor.set(Stage.gfScrollFactor[0], Stage.gfScrollFactor[1]);
				}		
		}

		switch (SONG.player1)
		{
			default:
				if (boyfriend.isCustom)
				{
					boyfriend.x += boyfriend.positionArray[0];
					boyfriend.y += boyfriend.positionArray[1] - 350;
				}	
				else
				{
					var offset = new CharacterOffsets(SONG.player1, true);
					var daX:Float = offset.daOffsetArray[0];
					var daY:Float = offset.daOffsetArray[1];

					if (offset.daOffsetArray[0] == 0 && offset.daOffsetArray[1] == 0 && !SONG.player1.startsWith('bf') && offset.hasOffsets == false)
					{
						offset = new CharacterOffsets(SONG.player1, false);
						daX = offset.daOffsetArray[0];
						daY = offset.daOffsetArray[1] - 350;
					}

					boyfriend.x += daX;
					boyfriend.y += daY;
				}		
		}

		if (usesStageHx)
		{
			for (index => array in Stage.layInFront)
			{
				switch (index)
				{
					case 0:
						add(gf);
						for (bg in array)
							add(bg);
					case 1:
						add(dad);
						for (bg in array)
							add(bg);
					case 2:
						add(boyfriend);
						for (bg in array)
							add(bg);
				}
			}
		}
		else
		{
			add(gf);
			add(dad);
			add(boyfriend);
		}

		add(comboGroup);

		if (loadRep)
		{
			FlxG.watch.addQuick('rep rpesses',repPresses);
			FlxG.watch.addQuick('rep releases',repReleases);
			
			FlxG.save.data.botplay = true;
			FlxG.save.data.scrollSpeed = rep.replay.noteSpeed;
			FlxG.save.data.downscroll = rep.replay.isDownscroll;
			// FlxG.watch.addQuick('Queued',inputsQueued);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
			hasDialogue = true;
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
			hasDialogue = true;
		}

		if (hasDialogue) //cuz like I don't want to have the portraits load on songs with no dialogue
		{
			doof = new DialogueBox(false, dialogue);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
		}

		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();
		
		if (FlxG.save.data.downscroll)
			strumLine.y = FlxG.height - 165;

		if (ClientPrefs.data.psychUI)
		{
			timeTxt = new FlxText(50 + (FlxG.width / 2) - 248, 19, 400, "", 32);
			timeTxt.screenCenter(X);
			timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.scrollFactor.set();
			timeTxt.alpha = 0;
			timeTxt.borderSize = 2;
			if(FlxG.save.data.downscroll) timeTxt.y = FlxG.height - 44;
	
			if(ClientPrefs.data.timeBarType == 'Song Name')
			{
				timeTxt.text = SONG.song;
				timeTxt.size = 24;
				timeTxt.y += 3;
			}

			updateTime = true;
	
			timeBarBG = new FlxSprite(0, 0).loadGraphic(Paths.image('healthBar'));
			timeBarBG.scale.x = 400/600;
			timeBarBG.updateHitbox();
			timeBarBG.screenCenter(X);
			timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
			timeBarBG.scrollFactor.set();
			timeBarBG.alpha = 0;
			timeBarBG.color = FlxColor.BLACK;
			add(timeBarBG);
	
			timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
				'songPercent', 0, 1);
			timeBar.scrollFactor.set();
			timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
			timeBar.numDivisions = 200; //How much lag this causes?? Should i tone it down to idk, 400 or 200? I made it 200.
			timeBar.alpha = 0;
			add(timeBar);
			add(timeTxt);
		}
		
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.00001;

		playerStrums = new FlxTypedGroup<StrumNote>();
		opponentStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		if (SONG.song == null)
			trace('song is null???');
		else
			trace('song looks gucci');

		generateSong(SONG.song);

		trace('generated');

		// add(strumLine);

		createCamSystem(camPos.x, camPos.y);

		FlxG.camera.zoom = defaultCamZoom;
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		FlxG.fixedTimestep = false;
		moveCameraSection();

		if (ClientPrefs.data.songPosition && !ClientPrefs.data.psychUI) // I dont wanna talk about this code :(
		{
			songPosBG = new FlxSprite(0, 10).loadGraphic(Paths.image('healthBar'));
			if (FlxG.save.data.downscroll)
				songPosBG.y = FlxG.height * 0.9 + 45; 
			songPosBG.screenCenter(X);
			songPosBG.scrollFactor.set();
			add(songPosBG);
			
			songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
				'songPositionBar', 0, 90000);
			songPosBar.scrollFactor.set();
			songPosBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
			add(songPosBar);

			var songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - 20,songPosBG.y,0,SONG.song, 16);
			if (FlxG.save.data.downscroll)
				songName.y -= 3;
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			songName.scrollFactor.set();
			add(songName);
			songName.cameras = [camHUD];
		}

		switch (songLowercase)
		{
			default: healthBarBG = new FlxSprite(0, FlxG.height * 0.89).loadGraphic(Paths.image('healthBar')); 
		}
		
		if (FlxG.save.data.downscroll)
			healthBarBG.y = 50;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();

		switch (curStage)
		{
			default:
				healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));				
		}	

		add(healthBar);

		replayTxt = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 75, healthBarBG.y + (FlxG.save.data.downscroll ? 100 : -100), 0, "REPLAY", 20);
		replayTxt.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		replayTxt.scrollFactor.set();
		if (loadRep){
			add(replayTxt);
		}
		// Literally copy-paste of the above, fu

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		if (ClientPrefs.data.psychUI)
		{
			scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 1.25;
			add(scoreTxt);
		}
		else
		{
			scoreTxt = new FlxText(FlxG.width / 2 - 235, healthBarBG.y + 50, 0, "", 20);
			if (!FlxG.save.data.accuracyDisplay)
				scoreTxt.x = healthBarBG.x + healthBarBG.width / 2;

			scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		}
		
		switch (songLowercase)
		{
			case 'storm': scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.BLACK, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.WHITE);
			case 'hunger' | 'aspirer': scoreTxt.setFormat(Paths.font("starv.ttf"), 16, FlxColor.WHITE, CENTER);	
		}
		
		scoreTxt.scrollFactor.set();													  
		add(scoreTxt);

		if (isDetected)
			strumLineNotes.cameras = [camNotes];
		else
			strumLineNotes.cameras = [camHUD];

		//we gotta leave these two out
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];

		var objects:Array<String> = ['healthBar', 'healthBarBG', 'iconP1', 'iconP2', 'scoreTxt'];
		
		if (ClientPrefs.data.psychUI)
			objects = objects.concat(['timeBar', 'timeBarBG', 'timeTxt']);

		if (ClientPrefs.data.songPosition && !ClientPrefs.data.psychUI)
			objects = objects.concat(['songPosBG', 'songPosBar']);

		if (hasDialogue)
			objects = objects.concat(['doof']);

		if (loadRep)
			objects.push('replayTxt');

		for (i in 0... objects.length)
		{
			var obj:FlxSprite = Reflect.getProperty(PlayState.instance, objects[i]);

			if (obj != null)
				obj.cameras = [camHUD];
		}

		if (isDetected)
		{
			if (executeModchart)
			{
				camNotes.zoom = camHUD.zoom;
				camNotes.x = camHUD.x;
				camNotes.y = camHUD.y;
				camNotes.angle = camHUD.angle;
			}
		}

		startingSong = true;
		
		trace('starting');

		// SONG SPECIFIC SCRIPTS
		#if desktop
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if desktop
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file) && !file.contains('modchart'))
					{
						if (file == 'script.lua') //making sure it's the first one;
							luaArray.insert(0, new ModchartState(folder + file));
						else
							luaArray.push(new ModchartState(folder + file));

						filesPushed.push(file);
					}
				}
			}
		}
		#end

		#if desktop
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if desktop
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new ModchartState(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		#if desktop
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
				luaArray.push(new ModchartState(luaToLoad));
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new ModchartState(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new ModchartState(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new ModchartState(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_events/' + event + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new ModchartState(luaToLoad));
			}
			#end
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		startCharacterLua(gf.curCharacter);
		startCharacterLua(dad.curCharacter);
		startCharacterLua(boyfriend.curCharacter);

		for(i in 0...startCharLuas.length)
		{
			startCharacterLua(startCharLuas[i]);
			startCharLuas.remove(startCharLuas[i]);
		}
			
		if (executeModchart)
			luaArray.insert(0, new ModchartState(Paths.lua(songLowercase  + "/modchart" + suf)));

		switch (mania)
		{
			case 1: singAnimations = ['singLEFT', 'singUP', 'singRIGHT', 'singLEFT', 'singDOWN', 'singRIGHT'];	
			case 2: singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'singUP', 'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
			case 3: singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singUP', 'singRIGHT'];			
			case 4: singAnimations = ['singLEFT', 'singUP', 'singRIGHT', 'singUP', 'singLEFT', 'singDOWN', 'singRIGHT'];
			default: singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];	
		}

		playerSingAnimations = singAnimations;

		setOnLuas("mustHitSection", PlayState.SONG.notes[curSection].mustHitSection); //just so we can check the first section
		callOnLuas('start', []);			
		callOnLuas('onCreate', []); //psych	

		if ((isStoryMode || showCutscene))
		{
			switch (songLowercase)
			{
				case "winter-horrorland":
					blackScreen = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(songLowercase == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				default:
					regularIntro(songLowercase);
			}
		}
		else
			regularIntro(songLowercase);	

		updateAccuracy();

		callOnLuas('onCreatePost', []);
			
		if (!loadRep)
			rep = new Replay("na");
	
		super.create();

		CustomFadeTransition.nextCamera = camOther;
		inPlayState = true;
	}

	function regularIntro(song:String)
	{
		switch (song)
		{
			default:
				startCountdown();
		}	
	}

	override function destroy() {
		#if LUA_ALLOWED
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		ModchartState.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				script.call('onDestroy');
				script.destroy();
			}

		while (hscriptArray.length > 0)
			hscriptArray.pop();
		#end

		FlxG.animationTimeScale = 1;
		FlxG.sound.music.pitch = 1;
		inPlayState = false;
		super.destroy();
	}

	public var totalDamageTaken:Float = 0;

	var shouldBeDead:Bool = false;

	public var interupt = false;

	var writing:Bool = false;

	public function startWriting(timer:Int = 15, word:String = ''):Void {
		canPause = false;
		writing = true;
		persistentUpdate = true;
		persistentDraw = true;
		var realTimer = timer;
		var textState = new substates.TextSubState(realTimer, word);
		textState.win = finishedWriting;
		textState.lose = death;
		textState.cameras = [camHUD];
		FlxG.autoPause = false;
		openSubState(textState);
	}

	public function finishedWriting():Void {
		canPause = true;
		writing = false;
	}

	public function fixTrailShit(daTrail:FlxTrail, daChar:Character):Void 
	{
		daTrail.destroy();
		daTrail = new DeltaTrail(daChar, null, 4, 12 / 60, 0.25, 0.069);
		daTrail.active = false;
		daTrail.color = FlxColor.fromString('#' + daChar.trailColor);
		insert(members.indexOf(daChar), daTrail);
	}

	var fuckingREACTOROFFSET:Float = 0;
	public var stopDeath:Bool = false;

	public function death():Void
	{
		if (SONG.song.toLowerCase() == 'monochrome')
		{
			boyfriend.stunned = true;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			FlxTween.tween(dad, {alpha: 0}, 1, {ease: FlxEase.linear, onComplete: function (twn:FlxTween){
				remove(dad);
			}});

			FlxTween.tween(Stage.swagBacks['stageFront'], {alpha: 0}, 1, {ease: FlxEase.linear, onComplete: function (twn:FlxTween){
				remove(Stage.swagBacks['stageFront']);
			}});

			FlxTween.tween(healthBar, {alpha: 0}, 1, {ease: FlxEase.linear, onComplete: function (twn:FlxTween) {
				healthBar.visible = false;
				healthBarBG.visible = false;
				scoreTxt.visible = false;
				iconP1.visible = false;
				iconP2.visible = false;
			}});
			FlxTween.tween(healthBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
			FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
			FlxTween.tween(iconP1, {alpha: 0}, 1, {ease: FlxEase.linear});
			FlxTween.tween(iconP2, {alpha: 0}, 1, {ease: FlxEase.linear});
			for (i in playerStrums) {
				FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
			}
			new FlxTimer().start(1.2, function(tmr:FlxTimer)
			{
				MusicBeatState.resetState();
			});
		}
		if(!stopDeath)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
		
			if(ret != ModchartState.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;
				
				vocals.stop();
				FlxG.sound.music.stop();

				var daX = boyfriend.getScreenPosition().x;
				var daY = boyfriend.getScreenPosition().y;

				/*if (SONG.song.toLowerCase() == 'epiphany')
				{
					daX = dad1.getScreenPosition().x;
					daY = dad1.getScreenPosition().y;
				}*/

				isDead = true;

				openSubState(new GameOverSubstate(daX, daY));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("GAME OVER -- " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy),"\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | songMisses: " + songMisses  , iconRPC);
				#end
			}
		}		
	}

	public var luaArray:Array<ModchartState> = [];
	public static var pushedLuas:Array<ModchartState> = [];
	public var closeLuas:Array<ModchartState> = [];

	public static var startCharLuas:Array<String> = [];

	public function getLuaObject(tag:String, ?text:Bool=true):FlxSprite {
		#if LUA_ALLOWED
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(modchartInputTexts.exists(tag)) return modchartInputTexts.get(tag);
		if(modchartIcons.exists(tag)) return modchartIcons.get(tag);
		if(modchartCharacters.exists(tag)) return modchartCharacters.get(tag);
		if(modchartTrails.exists(tag)) return modchartTrails.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		#end
		return null;
	}
		
	//why?
	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gf), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriend), obj);
	}
	public function addBehindDad (obj:FlxBasic)
	{
		insert(members.indexOf(dad), obj);
	}

	override function sectionHit()
	{
		super.sectionHit();

		//readSection(curSection + 1);

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos){
				moveCameraSection();
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}

			setOnLuas("mustHitSection", SONG.notes[curSection].mustHitSection);
			//setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			if (cameraSystem.toLowerCase() == "psych"){
				camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			}
			else{
				camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);	
			}

			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
		
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			(SONG.notes[curSection].mustHitSection ? callOnLuas('playerOneTurn', []) : callOnLuas('playerTwoTurn', []));
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
			callOnLuas('playerTwoTurn', []);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
			callOnLuas('playerOneTurn', []);
		}
	}

	var cameraTwn:FlxTween;

	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			if (cameraSystem.toLowerCase() == "psych"){
				camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			}
			else{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			}

			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			//tweenCamIn();
		}
		else
		{
			if (cameraSystem.toLowerCase() == "psych"){
				camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			}
			else{
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			}

			
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
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

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = luafiles.ModchartState.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [luafiles.ModchartState.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = ModchartState.Function_Continue;
		#if LUA_ALLOWED
		var stageExclusions:Array<String> = ["onCreate", "onUpdate"];

		if (Stage != null && Stage.isCustomStage && Stage.isLuaStage && !(stageExclusions.contains(event)))
			Stage.callOnLuas(event, args);	

		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [ModchartState.Function_Continue];

		var arr:Array<ModchartState> = [];
		for (script in luaArray) {
			if(script.closed)
			{
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(event, args);
			if((myValue == ModchartState.Function_StopLua || myValue == ModchartState.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
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
		//trace(event, returnVal);
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = luafiles.ModchartState.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(luafiles.ModchartState.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len) {
			var script:HScript = hscriptArray[i];
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try {
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
					{
						var len:Int = e.message.indexOf('\n') + 1;
						if(len <= 0) len = e.message.length;
						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
					}
				}
				else
				{
					myValue = callValue.returnValue;
					if((myValue == ModchartState.Function_StopHScript || myValue == ModchartState.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
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
		if (Stage != null && Stage.isCustomStage && Stage.isLuaStage)
			Stage.setOnLuas(variable, arg);	

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

			if(!instancesExclude.contains(variable))
				instancesExclude.push(variable);
			script.set(variable, arg);
		}
		#end
	}

	public function searchLuaVar(variable:String, arg:String, result:Bool) {
		#if LUA_ALLOWED
		//if (Stage != null && Stage.isCustomStage && Stage.isLuaStage)
		//	Stage.setOnLuas(variable, arg);	

		for (script in luaArray)
		{
			if (script.get(variable, arg) == result){
				return result;
			}
		}
		#end
		return !result;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 1;
				gfSpeed = value;

			case 'Change Stage':
				ModchartState.changeStage(value1);

			case 'Add Camera Zoom':
				if(FlxG.save.data.camzoom && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
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
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend' | "2":
						char = gf;
					case 'dad' | "1":
						char = dad;
					case 'boyfriend' | 'bf' | "0":
						char = boyfriend;
					default:
						char = modchartCharacters.get(value1);	
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

					if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
					
					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}
			case 'Set Property':
				var killMe:Array<String> = value1.split('.');

				if (value1.contains('velocity.')){
					if (PlayState.instance != null){value2 = Std.string(Std.parseInt(value2)*playbackRate);}
				}

				if(killMe.length > 1) {
					if (Std.isOfType(LuaUtils.getObjectDirectly(killMe[0]), Character) && killMe[killMe.length-1] == 'color')
					{
						var killMeh:Array<String> = [killMe[0], 'doMissThing'];
						if(killMeh.length > 1) {
							var coverMeInPiss:Dynamic = Reflect.getProperty(this, killMeh[0]);
							for (i in 1...killMeh.length-1) {
								coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMeh[i]);
							}
							Reflect.setProperty(coverMeInPiss, killMeh[killMeh.length-1], 'false');
						}
					}

					LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1], value2);
				} else {
					LuaUtils.setVarInArray(this, value1, value2);
				}
			case 'Change Character':
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend' | "2":
						ModchartState.changeGFAuto(value2);
					case 'dad' | "opponent" | "1":
						ModchartState.changeDadAuto(value2);
					case 'boyfriend' | 'bf' | "0":
						ModchartState.changeBFAuto(value2);	
					default:
					{
						var char = modchartCharacters.get(value1);	

						if (char != null){
							ModchartState.makeLuaCharacter(value1, value2, char.isPlayer, char.flipMode);
						}
						
					}		
				}
			case 'BG Freaks Expression':
				if(Stage.swagBacks['bgGirls'] != null)
				{
					if (value1 != null)
						Stage.swagBacks['bgGirls'].setDanceType(value1);
					else
						Stage.swagBacks['bgGirls'].swapDanceType();
				}
			case 'Change Scroll Speed':
				if (FlxG.save.data.scrollSpeed != 1)
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * val1;

				if(val2 <= 0)
					songSpeed = newValue;
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'images/characters/jsons/' + name;
		if (FileSystem.exists(Paths.modFolders('characters/'+name+'.lua'))){
			luaFile = Paths.modFolders('characters/'+name+'.lua');
			doPush = true;
		}
		else if(FileSystem.exists(FileSystem.absolutePath("assets/shared/"+luaFile+'.lua'))) {
			luaFile = "assets/shared/"+luaFile+'.lua';
			doPush = true;
		} else if (FileSystem.exists(Paths.lua2(luaFile))) {
			luaFile = Paths.lua2(luaFile);
			doPush = true;
		}
		
		if(doPush)
		{
			trace (name +' has lua!');
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new ModchartState(luaFile));
		}
		#end
	}

	public function addShaderToCamera(cam:String,effect:ShaderEffect) //STOLE FROM ANDROMEDA
	{
		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud':
					camHUDShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camHUDShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
					camOtherShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camOtherShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
					camGameShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camGameShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGame.setFilters(newCamEffects);
			default:
				var obj = null;
				for (map in [modchartSprites, modchartIcons, modchartTexts, modchartCharacters, modchartInputTexts]) {
					if (map.exists(cam)) {
						obj = map.get(cam);
						break;
					}
				}
				if (obj == null) {
					obj = Reflect.getProperty(PlayState.instance, cam);
				}
				Reflect.setProperty(obj, "shader", effect.shader);
		}	  
  }

	public function removeShaderFromCamera(cam:String,effect:ShaderEffect)
	{
		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud': 
				camHUDShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camHUDShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
				}
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other': 
				camOtherShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camOtherShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
				}
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camGameShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
				}
				camGame.setFilters(newCamEffects);
			default: 
				camGameShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camGameShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
				}
				camGame.setFilters(newCamEffects);
		}	  
	}

	public function clearShaderFromCamera(cam:String)
	{  
		var newCamEffects:Array<BitmapFilter>=[];

		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud': 
				camHUDShaders = [];
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other': 
				camOtherShaders = [];
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders = [];
				camGame.setFilters(newCamEffects);
			default: 
				var obj = null;
				for (map in [modchartSprites, modchartIcons, modchartTexts, modchartCharacters, modchartInputTexts]) {
					if (map.exists(cam)) {
						obj = map.get(cam);
						break;
					}
				}
				if (obj == null) {
					obj = Reflect.getProperty(PlayState.instance, cam);
				}
				Reflect.setProperty(obj, "shader", null);
		}
	}

	var daTexts: Map<String, String> = new Map<String, String>();
	
	function callRedText(sprite:FlxSprite, effect:Int)
	{
		var texteffect:FlxGlitchEffect = new FlxGlitchEffect();
		var daText:FlxEffectSprite;

		//effect uses int number
		switch (effect)
		{
			case 1:
				texteffect = new FlxGlitchEffect(8,12,0.2,HORIZONTAL);
			case 2:
				texteffect = new FlxGlitchEffect(9,15,0.4,VERTICAL);
			case 3:
				texteffect = new FlxGlitchEffect(13,13,0.5,HORIZONTAL);
			case 4:
				texteffect = new FlxGlitchEffect(15,16,0.1,VERTICAL);
			case 5:
				texteffect = new FlxGlitchEffect(16,11,0.3,HORIZONTAL);
		}
	
		daText = new FlxEffectSprite (sprite, [texteffect]);
		daText.cameras = [camOther];
		daText.alpha = 0;
		add(daText);

		// i hate } and );
		FlxTween.tween(daText, {alpha: 1}, 0.8, {ease:FlxEase.quadInOut, onComplete: function (twn:FlxTween)
		{
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					FlxTween.tween(daText, {alpha: 0}, 0.8, {ease:FlxEase.quadInOut, onComplete: function (twn:FlxTween)
						{
							daText.destroy();
							sprite.destroy();

							var daPath:String = "";

							for (key in daTexts.keys())
							{
								if (key == Std.string(sprite))
									daPath = daTexts.get(Std.string(sprite));
							}

							@:privateAccess

							var obj = FlxG.bitmap._cache.get(daPath);
							
							if (obj != null)
							{
								trace ('found da image');
								openfl.Assets.cache.removeBitmapData(daPath);
								@:privateAccess
								FlxG.bitmap._cache.remove(daPath);
								obj.destroy();
							}

							System.gc();
						}
					});
				});
			}
		});
	}

	/*function doPicoCutscene():Void
	{
		doof3 = new DialogueBox(false, extra2);
		doof3.scrollFactor.set();
		doof3.cameras = [camHUD];
		doof3.finishThing = startCountdown;

		wind.fadeIn();
		
		new FlxTimer().start(1.2, function(tmr:FlxTimer)
		{
			dad.playAnim('pissed');

			new FlxTimer().start(1, function(tmr:FlxTimer) {
				FlxG.sound.play(Paths.sound("shooters"), 1);
				FlxG.camera.flash(FlxColor.WHITE, 2, false);
				gf.playAnim('scared', true);
				boyfriend.playAnim('scared', true);
				Stage.swagBacks['wBg'].alpha = 0;
				Stage.swagBacks['wstageFront'].alpha = 0;
				Stage.swagBacks['funneEffect'].visible = true;
			});

			new FlxTimer().start(3, function(tmr:FlxTimer) {
				picoIntroPart2(doof3);
			});
		});
	}*/

	public function doGremlin(hpToTake:Int, duration:Int,persist:Bool = false)
	{
		interupt = false;

		grabbed = true;
		
		totalDamageTaken = 0;

		var gramlan:FlxSprite = new FlxSprite(0,0);

		gramlan.frames = Paths.getSparrowAtlas('madness/tricky/fourth/mech/HP GREMLIN');

		gramlan.setGraphicSize(Std.int(gramlan.width * 0.76));

		gramlan.cameras = [camHUD];

		gramlan.x = iconP1.x;
		gramlan.y = healthBarBG.y - 325;

		gramlan.animation.addByIndices('come','HP Gremlin ANIMATION',[0,1], "", 24, false);
		gramlan.animation.addByIndices('grab','HP Gremlin ANIMATION',[2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24], "", 24, false);
		gramlan.animation.addByIndices('hold','HP Gremlin ANIMATION',[25,26,27,28],"",24);
		gramlan.animation.addByIndices('release','HP Gremlin ANIMATION',[29,30,31,32,33],"",24,false);

		gramlan.antialiasing = true;

		add(gramlan);

		if(FlxG.save.data.downscroll){
			gramlan.flipY = true;
			gramlan.y -= 150;
		}
		
		// over use of flxtween :)

		var startHealth = health;
		var toHealth = (hpToTake / 100) * startHealth; // simple math, convert it to a percentage then get the percentage of the health

		var perct = toHealth / 2 * 100;

		trace('start: $startHealth\nto: $toHealth\nwhich is prect: $perct');

		var onc:Bool = false;

		FlxG.sound.play(Paths.sound('tricky/fourth/GremlinWoosh'));

		gramlan.animation.play('come');
		new FlxTimer().start(0.14, function(tmr:FlxTimer) {
			gramlan.animation.play('grab');
			FlxTween.tween(gramlan,{x: iconP1.x - 140},1,{ease: FlxEase.elasticIn, onComplete: function(tween:FlxTween) {
				trace('I got em');
				gramlan.animation.play('hold');
				FlxTween.tween(gramlan,{
					x: (healthBar.x + 
					(healthBar.width * (FlxMath.remapToRange(perct, 0, 100, 100, 0) * 0.01) 
					- 26)) - 75}, duration,
				{
					onUpdate: function(tween:FlxTween) { 
						// lerp the health so it looks pog
						if (interupt && !onc && !persist)
						{
							onc = true;
							trace('oh shit');
							gramlan.animation.play('release');
							gramlan.animation.finishCallback = function(pog:String) { gramlan.alpha = 0;}
						}
						else if (!interupt || persist)
						{
							var pp = FlxMath.lerp(startHealth,toHealth, tween.percent);
							if (pp <= 0)
								pp = 0.1;
							health = pp;
						}

						if (shouldBeDead)
							health = 0;
					},
					onComplete: function(tween:FlxTween)
					{
						if (interupt && !persist)
						{
							remove(gramlan);
							grabbed = false;
						}
						else
						{
							trace('oh shit');
							gramlan.animation.play('release');
							if (persist && totalDamageTaken >= 0.7)
								health -= totalDamageTaken; // just a simple if you take a lot of damage wtih this, you'll loose probably.
							gramlan.animation.finishCallback = function(pog:String) { remove(gramlan);}
							grabbed = false;
						}
					}
				});
			}});
		});
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
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			//precacheList.set('dialogue', 'sound');
			//precacheList.set('dialogueClose', 'sound');
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
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{	
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}	


	public var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	var luaWiggles:Array<WiggleEffect> = [];

	var daStartAlpha:Float = 1;
	public var countdownOnYourMarks:FlxSprite;
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

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

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;

		Conductor.songPosition = time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			FlxG.sound.music.pitch = playbackRate;
		}
		vocals.play();
	
		songTime = time;
	}
	
	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	public function startCountdown():Void
	{
		if (!stopCountdown)
		{
			inCutscene = false;
				
			if (songLowercase == 'ballistic' && showCutscene)
			{
				for (i in [strumLineNotes, scoreTxt, healthBarBG, healthBar, iconP1, iconP2]){
					i.visible = true;
				}
			}

			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;			

			generateStaticArrows(0, dad.noteSkin, !skipArrowStartTween, daStartAlpha);
			generateStaticArrows(1, boyfriend.noteSkin, !skipArrowStartTween, daStartAlpha);	

			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			}

			//kade engine
			for (i in 0...strumLineNotes.length){
				var member = PlayState.instance.strumLineNotes.members[i];
				setOnLuas("defaultStrum" + i + "X", Math.floor(member.x));
				setOnLuas("defaultStrum" + i + "Y", Math.floor(member.y));
				setOnLuas("defaultStrum" + i + "Angle", Math.floor(member.angle));
				setOnLuas("defaultStrum" + i + "Alpha", Math.floor(member.alpha));
			}
		
			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;

			var swagCounter:Int = 0;

			callOnLuas('onStartCountdown', []);	
			spawnStartingNoteSplash(0, 0, 0); //to prevent notesplash lag

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned){
						gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned){
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned){
					dad.dance();
				}

				for (value in modchartCharacters.keys())
				{
					daChar = modchartCharacters.get(value);
					
					if (tmr.loopsLeft % daChar.danceEveryNumBeats == 0 && daChar.animation.curAnim != null && !daChar.animation.curAnim.name.startsWith('sing') && !daChar.stunned){
						daChar.dance();
					}			
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', "set", "go"]);

				if (usesStageHx){
					introAssets.set(curStage, Stage.introAssets);
				}
					
				var introAlts:Array<String> = introAssets.get('default');
				var altSuffix:String = "";
				var altPrefix:String = "";

				for (value in introAssets.keys())
				{
					if (value == curStage)
					{
						introAlts = introAssets.get(value);

						if (usesStageHx && Stage.altSuffix != '')
							altSuffix = Stage.altSuffix;

						if (usesStageHx && Stage.altPrefix != '')
							altPrefix = Stage.altPrefix;
					}
				}

				#if MODS_ALLOWED
				if (!FileSystem.exists(Paths.modsSounds('sounds', altPrefix + 'intro3' + altSuffix)) && !FileSystem.exists(Paths.sound(altPrefix + 'intro3' + altSuffix))) {
				#else
				if (!OpenFlAssets.exists(Paths.sound(altPrefix + 'intro3' + altSuffix))) {
				#end
					altSuffix = '';
				}
				
				// added stuff to check if you have a graphic for the 3
				switch (swagCounter)
				{
					case 0:
						var dedicatedPath = (introAlts.length > 3 ? introAlts[0] : "notes/noStrums");

						countdownOnYourMarks = new FlxSprite().loadGraphic(Paths.returnGraphic(dedicatedPath));
						setupCountdownSprite("countdownOnYourMarks", dedicatedPath, altPrefix + "intro3" + altSuffix);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.returnGraphic(introAlts[introAlts.length - 3]));
						setupCountdownSprite("countdownReady", introAlts[introAlts.length - 3], altPrefix + "intro2" + altSuffix);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.returnGraphic(introAlts[introAlts.length - 2]));
						setupCountdownSprite("countdownSet", introAlts[introAlts.length - 2], altPrefix + "intro1" + altSuffix);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.returnGraphic(introAlts[introAlts.length - 1]));
						setupCountdownSprite("countdownGo", introAlts[introAlts.length - 1], altPrefix + "introGo" + altSuffix);
				}

				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
			}, 5);

			/*if (SONG.song.toLowerCase() == 'expurgation')
			{
				new FlxTimer().start(25, function(tmr:FlxTimer) {
					if (curStep < 2400)
					{
						if (canPause && !paused && health >= 1.5 && !grabbed)
							doGremlin(40,3);
						trace('checka ' + health);
						tmr.reset(25);
					}
				});
			}*/
		}
	}

	public function setupCountdownSprite(spr:String, graphicName:String, soundName:String)
	{
		var countdown:FlxSprite = Reflect.getProperty(PlayState.instance, spr);
		countdown.scrollFactor.set();
						
		if (graphicName.contains("-pixel")){
			countdown.setGraphicSize(Std.int(countdown.width * daPixelZoom));
		}
			
		countdown.cameras = [camHUD];
		countdown.updateHitbox();
		countdown.screenCenter();
		add(countdown);
		
		FlxTween.tween(countdown, {y: countdown.y + 25, alpha: 0}, Conductor.crochet / 1000 / playbackRate, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				countdown.destroy();
			}
		});
		FlxG.sound.play(existsInCTS(soundName), 0.6);
	}

	public function softCountdown(?style:String):Void
	{
		inCutscene = false;

		var dankCounter:Int = 0;

		var dankTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
		{
			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);

			if (usesStageHx){
				introAssets.set(curStage, Stage.introAssets);
			}
				
			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";
			var altPrefix:String = "";

			for (value in introAssets.keys())
			{
				if (value == curStage)
				{
					introAlts = introAssets.get(value);

					if (usesStageHx && Stage.altSuffix != '')
						altSuffix = Stage.altSuffix;

					if (usesStageHx && Stage.altPrefix != '')
						altPrefix = Stage.altPrefix;
				}
			}

			#if MODS_ALLOWED
			if (!FileSystem.exists(Paths.modsSounds('sounds', altPrefix + 'intro3' + altSuffix)) && !FileSystem.exists(Paths.sound(altPrefix + 'intro3' + altSuffix))) {
			#else
			if (!OpenFlAssets.exists(Paths.sound(altPrefix + 'intro3' + altSuffix))) {
			#end
				altSuffix = '';
			}
			
			// added stuff to check if you have a graphic for the 3
			switch (dankCounter)
			{
				case 0:
					var dedicatedPath = (introAlts.length > 3 ? introAlts[0] : "notes/noStrums");

					countdownOnYourMarks = new FlxSprite().loadGraphic(Paths.returnGraphic(dedicatedPath));
					setupCountdownSprite("countdownOnYourMarks", dedicatedPath, altPrefix + "intro3" + altSuffix);
				case 1:
					countdownReady = new FlxSprite().loadGraphic(Paths.returnGraphic(introAlts[introAlts.length - 3]));
					setupCountdownSprite("countdownReady", introAlts[introAlts.length - 3], altPrefix + "intro2" + altSuffix);
				case 2:
					countdownSet = new FlxSprite().loadGraphic(Paths.returnGraphic(introAlts[introAlts.length - 2]));
					setupCountdownSprite("countdownSet", introAlts[introAlts.length - 2], altPrefix + "intro1" + altSuffix);
				case 3:
					countdownGo = new FlxSprite().loadGraphic(Paths.returnGraphic(introAlts[introAlts.length - 1]));
					setupCountdownSprite("countdownGo", introAlts[introAlts.length - 1], altPrefix + "introGo" + altSuffix);
			}

			dankCounter += 1;
		}, 5);
	}


	var grabbed = false;

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	public var songTime:Float = 0;
	public static var startOnTime:Float = 0;
	public var skipArrowStartTween:Bool = false; //for lua

	public var songStarted = false;

	public function startSong():Void
	{
		startingSong = false;
		songStarted = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		callOnLuas('onSongStart', []);	

		if (!paused)
		{
			if (!Assets.exists(Paths.inst(PlayState.SONG.song)))
			{
				if (Paths.currentTrackedSounds.exists(Paths.inst2(PlayState.SONG.song)))
					FlxG.sound.playMusic(Paths.currentTrackedSounds.get(Paths.inst2(PlayState.SONG.song)), 1, false);
				else
					FlxG.sound.playMusic(Sound.fromFile(Paths.inst2(PlayState.SONG.song)), 1, false);
			}
			else
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		}

		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = songOutro;
		vocals.play();

		if (ClientPrefs.data.psychUI && startOnTime <= 0)
		{
			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}

			
		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
			timeBar.alpha = 1;
			timeTxt.alpha = 1;
			timeBarBG.alpha = 1;
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
	
		if (ClientPrefs.data.songPosition && !ClientPrefs.data.psychUI)
		{
			songPosBG = new FlxSprite(0, 10).loadGraphic(Paths.image('healthBar'));
			songPosBG.screenCenter(X);
			songPosBG.scrollFactor.set();
			add(songPosBG);

			if (FlxG.save.data.downscroll) {
				songPosBG.y = FlxG.height * 0.9 + 45; 
			}

			songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
				'songPositionBar', 0, songLength - 1000);
			songPosBar.numDivisions = 1000;
			songPosBar.scrollFactor.set();
			songPosBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
			add(songPosBar);

			var songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - 20,songPosBG.y,0,SONG.song, 16);
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			songName.scrollFactor.set();
			add(songName);

			if (FlxG.save.data.downscroll){
				songName.y -= 3;
			}
		}
		
		// Song check real quick
		switch(curSong)
		{
			case 'Bopeebo' | 'Philly Nice' | 'Blammed' | 'Cocoa' | 'Eggnog': allowedToHeadbang = true;
			default: allowedToHeadbang = false;
		}
		
		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | songMisses: " + songMisses  , iconRPC);
		#end
	}

	var debugNum:Int = 0;

	var opponentSectionNoteStyle:String = "";
	var playerSectionNoteStyle:String = "";

	public var daSongData:SwagSong;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		opponentSectionNoteStyle = "";
		playerSectionNoteStyle = "";

		songSpeed = (FlxG.save.data.scrollSpeed != 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed);

		var songData = SONG;
		daSongData = songData;
		
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
		{
			if (!Assets.exists(Paths.voices(PlayState.SONG.song)))
			{
				if (Paths.currentTrackedSounds.exists(Paths.voices2(PlayState.SONG.song)))
					vocals = FlxG.sound.list.recycle(FlxSound).loadEmbedded(Paths.currentTrackedSounds.get(Paths.voices2(PlayState.SONG.song)));
				else
					vocals = FlxG.sound.list.recycle(FlxSound).loadEmbedded(Sound.fromFile(Paths.voices2(PlayState.SONG.song)));
			}
			else
				vocals = FlxG.sound.list.recycle(FlxSound).loadEmbedded(Paths.voices(PlayState.SONG.song));
		}		
		else
			vocals = FlxG.sound.list.recycle(FlxSound);

		trace('loaded vocals');

		vocals.looped = false;
		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var playerCounter:Int = 0;
		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0],
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		
		//readSection(0);
		//readSection(1);

		oldReadSection(false);
		//oldReadSection(true);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = daSongData.notes;

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(!noteTypeMap.exists(songNotes[3])) {
					noteTypeMap.set(songNotes[3], true);
				}
			}
		}

		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0],
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();

		generatedMusic = true;

		opponentSectionNoteStyle = "";
		playerSectionNoteStyle = "";
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				preloadChar = new Character(0, 0, newCharacter);
				startCharacterLua(preloadChar.curCharacter);
			//case 'Change Stage':
				//disabled since it seems to cause crashes for the release build. just use preload-stage.txt
				/*if (event.value1 == curStage)
					return;

				PreloadStage = new Stage(event.value1, true);
				trace ('stages are ' + event.value1);*/

			/*case 'Dadbattle Spotlight':
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);


			case 'Philly Glow':
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);


				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!FlxG.save.data.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('philly/particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);*/
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public function setCameraOffsets()
	{
		opponentCameraOffset = [(Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[0] : 0), (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[1] : 0)];
		girlfriendCameraOffset = [(Stage.girlfriendCameraOffset != null ? Stage.girlfriendCameraOffset[0] : 0), (Stage.girlfriendCameraOffset != null ? Stage.girlfriendCameraOffset[1] : 0)];
		boyfriendCameraOffset = [(Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[0] : 0), (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[1] : 0)];
	}
	
	var hudArrXPos:Array<Float>;
	var hudArrYPos:Array<Float>;
	var hudArrDadXPos:Array<Float>;
	var hudArrDadYPos:Array<Float>;

	function generateStaticArrows(player:Int, style:String, tweenShit:Bool = true, daAlpha:Float = 1):Void
	{
		switch (player)
		{
			case 1:
				hudArrXPos = [];
				hudArrYPos = [];
				bfStrumStyle = style;
			case 0:
				hudArrDadXPos = [];
				hudArrDadYPos = [];
		}

		for (i in 0...Main.keyAmmo[mania])
		{	
			var babyArrow:StrumNote = new StrumNote(47, strumLine.y, i, player, style);
			babyArrow.downScroll = FlxG.save.data.downscroll;
			if (!isStoryMode && tweenShit)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: daAlpha}, 1, {ease: FlxEase.circOut, startDelay: (0.5 + (0.2 * i) / playbackRate)});
			}

			var strums:FlxTypedGroup<StrumNote> = player == 1 ? playerStrums : opponentStrums;
			var xPos:Array<Float> = player == 1 ? hudArrXPos : hudArrDadXPos;
			var yPos:Array<Float> = player == 1 ? hudArrYPos : hudArrDadYPos;

			strums.add(babyArrow);
			xPos.push(babyArrow.x);
			yPos.push(babyArrow.y);

			if (isMania)
				babyArrow.x -= Note.posRest[mania];
			
			opponentStrums.forEach(function(spr:FlxSprite)
			{					
				spr.centerOffsets(); //CPU arrows start out slightly off-center
			});

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			#if desktop
			DiscordClient.changePresence("PAUSED on " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "Acc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | songMisses: " + songMisses  , iconRPC);
			#end
			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong){
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished){
				startTimer.active = true;
			}
				
			paused = false;
			pauseCameraEffects = false;

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | songMisses: " + songMisses, iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), iconRPC);
			}
			#end

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
		}

		super.closeSubState();
	}
	

	public function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();

		#if desktop
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | songMisses: " + songMisses  , iconRPC);
		#end
	}

	public var paused:Bool = false;
	public var startedCountdown:Bool = false;
	public var canPause:Bool = true;
	public var spookyText:FlxText;
	public var spookyRendered:Bool = false;
	public var spookySteps:Int = 0;
	public var nps:Int = 0;
	public var maxNPS:Int = 0;

	public static var songRate = 1.5;

	var shake:Bool = false;
	var pressedOnce:Bool = false;

	public var currentLuaIndex = 0;

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	function openChartEditor()
	{
		PlayState.instance.callOnLuas('onExitSong', []);

		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var pauseCameraEffects:Bool = false;

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		pauseCameraEffects = true;

		// 1 / 1000 chance for Gitaroo Man easter egg
		if (FlxG.random.bool(0.1))
		{
			cancelMusicFadeTween();
			MusicBeatState.switchState(new states.GitarooPause());
		}
		else
		{
			if(FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}

			isPaused = true;
			openSubState(new substates.PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	var cpuControlled:Bool = false;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (usesStageHx)
			Stage.update(elapsed);
			
		for (value in modchartCharacters.keys())
		{
			daChar = modchartCharacters.get(value);
			
			if ((daChar.isPlayer && daChar.flipMode == false || !daChar.isPlayer && daChar.flipMode == true))
			{
				if (daChar.animation.curAnim.name.startsWith('sing'))
					daChar.holdTimer += elapsed;
				else
					daChar.holdTimer = 0;
			}					
		}

		if (cpuControlled != FlxG.save.data.botplay)
			cpuControlled = FlxG.save.data.botplay;

		//because psych can run it before song starts.
		callOnLuas('onUpdate', [elapsed]);
		
		#if desktop
		if (songStarted)
		{
			setOnLuas('songPos',Conductor.songPosition);
			setOnLuas('hudZoom', camHUD.zoom);
			setOnLuas('cameraZoom',FlxG.camera.zoom);
			callOnLuas('update', [elapsed]);

			if (luaWiggles != [])
			{
				for (i in luaWiggles)
				{
					trace('wiggle le gaming');
					i.update(elapsed);
				}
			}
		}
		#end

		// reverse iterate to remove oldest notes first and not invalidate the iteration
		// stop iteration as soon as a note is not removed
		// all notes should be kept in the correct order and this is optimal, safe to do every frame/update
		/*{
			var balls = notesHitArray.length-1;
			while (balls >= 0)
			{
				var cock:Date = notesHitArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(cock);
				else
					balls = 0;
				balls--;
			}
			nps = notesHitArray.length;
			if (nps > maxNPS)
				maxNPS = nps;
		}*/

		if(cameraSystem.toLowerCase() == "psych" && camFollowPos != null && !inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', [], false);
			if(ret != ModchartState.Function_Stop) {
				openPauseMenu();
			}
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		health = (healthSet ? 1 : (health > maxHealth ? maxHealth : health));

		var iconScaleShit:Array<Array<Dynamic>> = [[iconP1, playerIconScale], [iconP2, opponentIconScale]];

		for (i in 0...iconScaleShit.length){
			var spr:HealthIcon = iconScaleShit[i][0];
			var scale:Float = iconScaleShit[i][1];
			
			var mult:Float = FlxMath.lerp((scale-0.2), spr.scale.x, CoolUtil.boundTo((scale-0.2) - (elapsed * 9 * playbackRate), 0, 1));
			spr.scale.set(mult, mult);
			spr.updateHitbox();
		}

		var iconOffset:Int = 26;
		var healthPercent:Float = FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01;
		iconP1.x = healthBar.x + (healthBar.width * healthPercent - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * healthPercent) - (iconP2.width - iconOffset);

		var isHealthBarPercentLessThan20:Bool = healthBar.percent < 20;
		var isHealthBarPercentGreaterThan80:Bool = healthBar.percent > 80;
	
		iconP1.animation.curAnim.curFrame = (isHealthBarPercentLessThan20 ? 1 : ((isHealthBarPercentGreaterThan80 && iconP1.hasWinning) ? 2 : 0));
		iconP2.animation.curAnim.curFrame = (isHealthBarPercentGreaterThan80 ? 1 : ((isHealthBarPercentLessThan20 && iconP2.hasWinning) ? 2 : 0));

		if (FlxG.keys.anyJustPressed(engineDebugKeys)){
			checkDebugKeys();
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
			/*@:privateAccess
			{
				FlxG.sound.music._channel.
			}*/
			songPositionBar = Conductor.songPosition;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.data.timeBarType == 'Time Elapsed'){
						songCalc = curTime;
					} 

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.data.timeBarType != 'Song Name'){
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
					}
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			var zoomValue:Float = CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate * (psychCamZooming ? 1 : 2)), 0, 1); // the * 2 makes it closer to kade's 0.95

			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, zoomValue);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, zoomValue);

			if (isDetected)
			{
				camNotes.zoom = camHUD.zoom;
				camSustains.zoom = camHUD.zoom;
			}
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		FlxG.watch.addQuick("songPos", Conductor.songPosition);

		if (health <= 0 || FlxG.keys.justPressed.R && !inCutscene)
			death();

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				//callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);

				/*if (isDetected && executeModchart)
				{
					currentLuaIndex++;
					var n = new LuaNote(dunceNote, currentLuaIndex);
					//n.Register(ModchartState.instance.lua);
					ModchartState.shownNotes.push(n);
					dunceNote.LuaNote = n;
					dunceNote.luaID = currentLuaIndex;
				}*/

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);

				if (isDetected)
					currentLuaIndex++;
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene){
				if (!cpuControlled){
					keyShit();
				} else {
					playerCharsDance();
				}

				if (notes.length > 0){
					if (startedCountdown){
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						var swagDownscroll:Bool = FlxG.save.data.downscroll;
				
						//this just looks so much nicer
						notes.forEachAlive(function(daNote:Note)
						{
							updateNote(daNote, fakeCrochet, swagDownscroll);
						});	
					}
				}
				else{
					notes.forEachAlive(function(daNote:Note)
					{
						daNote.canBeHit = false;
						daNote.wasGoodHit = false;
					});
				}
			}
		}

		if (shaderUpdates != [])
		{
			for (i in shaderUpdates){
				i(elapsed);
			}
		}
		
		checkEventNote();

		callOnLuas('onUpdatePost', [elapsed]);
	}

	function updateNote(daNote:Note, fakeCrochet:Float, swagDownscroll:Bool)
	{
		if (daNote.tooLate)
		{
			daNote.active = false;
			daNote.visible = false;
		}
		else
			daNote.active = true;

		var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
		if(!daNote.mustPress) strumGroup = opponentStrums;
		var strumData = strumGroup.members[Math.floor(Math.abs(daNote.noteData))];

		var strumX:Float = strumData.x;
		var strumY:Float = strumData.y;
		var strumAngle:Float = strumData.angle;
		var strumDirection:Float = strumData.direction;
		var strumAlpha:Float = strumData.alpha;
		var strumScroll:Bool = false;

		if ((swagDownscroll && !daNote.flipScroll) || (!swagDownscroll && daNote.flipScroll))
			strumScroll = true;

		strumX += daNote.offsetX;
		strumY += daNote.offsetY;

		daNote.distance = ((strumScroll ? 0.45 : -0.45) * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);

		var angleDir = strumDirection * Math.PI / 180;

		if(daNote.copyX)
			daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

		var center:Float = strumY + Note.swagWidth / 2;
		
		if (!daNote.modifiedByLua && daNote.copyY)
		{
			daNote.y = (strumY + Math.sin(angleDir) * daNote.distance);	
			
			// Simplify conditions.
			var canClipNote:Bool = cpuControlled && !daNote.ignoreNote;
			var mustClipNote:Bool = !cpuControlled && (!daNote.mustPress || daNote.wasGoodHit || (daNote.prevNote != null && daNote.prevNote.wasGoodHit && !daNote.canBeHit));

			if (strumScroll)
			{
				if(daNote.isSustainNote)
				{
					if (daNote.animation.curAnim.name.endsWith('end')) {
						daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
						daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
						if(daNote.isPixel) {
							daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
						}
					}
					daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
					daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					
					var canClipToCenter = daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center;
					
					if(!cpuControlled || canClipNote)
					{
						if(canClipNote || (mustClipNote && canClipToCenter))
						{
							var swagRect = (daNote.clipRect != null ? daNote.clipRect : new FlxRect());
			
							swagRect.x = 0;
							swagRect.width = daNote.frameWidth * 2;
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;
				
							daNote.clipRect = swagRect;
						}
					}
				}
			}
			else
			{
				if(daNote.isSustainNote)
				{
					//daNote.y -= daNote.height / 2;

					var canClipToCenter = daNote.y + daNote.offset.y * daNote.scale.y <= center;
					
					if(!cpuControlled || canClipNote)
					{
						if(canClipNote || (mustClipNote && canClipToCenter))
						{
							var swagRect = (daNote.clipRect != null ? daNote.clipRect : new FlxRect());
			
							swagRect.x = 0;
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.width = daNote.width / daNote.scale.x;
							swagRect.height = (daNote.height / daNote.scale.y) - swagRect.y;
							
							daNote.clipRect = swagRect;
						}
					}
				}
			}
		}

		if (!daNote.modifiedByLua)
		{
			daNote.visible = strumData.visible;

			if (!daNote.isSustainNote && daNote.angle != strumData.angle)
				daNote.angle = strumData.angle;

			if (daNote.copyAlpha){
				daNote.alpha = Math.max(strumData.alpha - (daNote.isSustainNote ? 0.4 : 0), 0);
			}
		}

		if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
			opponentNoteHit(daNote);

		if(((swagDownscroll && !daNote.flipScroll) || (!swagDownscroll && daNote.flipScroll)) && daNote.y > playerStrums.members[daNote.noteData].y - 20 ||
		((!swagDownscroll && !daNote.flipScroll) || (swagDownscroll && daNote.flipScroll)) && daNote.y < playerStrums.members[daNote.noteData].y + 20)
		{
			// Force good note hit regardless if it's too late to hit it or not as a fail safe

			if (cpuControlled && daNote.mustPress && (daNote.canBeHit || daNote.tooLate))
			{
				if(loadRep)
				{
					if(rep.replay.songNotes.contains(HelperFunctions.truncateFloat(daNote.strumTime, 2))){
						goodNoteHit(daNote);
					}
				}else 
				{
					if (!daNote.ignoreNote && !daNote.burning && !daNote.blackStatic){
						goodNoteHit(daNote);	
					}
				}
			}
		}

		// Kill extremely late notes and cause misses
		if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
		{
			if (daNote.mustPress)
			{
				if (daNote.canMiss)
					callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.dType]); //yeah i didn't know how else to do this

				if (theFunne && !daNote.canMiss && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) 
				{
					health -= 0.02;
					totalDamageTaken += 0.02;
					interupt = true;
					vocals.volume = 0;	
					noteMiss(daNote.noteData, daNote);
				}
			}
		
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
	}

	function checkDebugKeys()
	{
		if (FlxG.keys.justPressed.NINE)
			iconP1.swapOldIcon(boyfriend.healthIcon);

		if (FlxG.keys.justPressed.SEVEN && !inCutscene){
			if (FlxG.keys.pressed.SHIFT){
				ChartingState.lastSection = curSection;
			}
			openChartEditor();
		}

		if (FlxG.keys.justPressed.EIGHT) // swapping some stuff around
		{
			PlayState.instance.callOnLuas('onExitSong', []);
			persistentUpdate = false;

			MusicBeatState.switchState(new CharacterEditorState((FlxG.keys.pressed.SHIFT ? boyfriend.curCharacter : (FlxG.keys.pressed.CONTROL ? gf.curCharacter : dad.curCharacter)))); // so you can access both characters
		}

		if (FlxG.keys.justPressed.TWO)
		{
			PlayState.instance.callOnLuas('onExitSong', []);
			persistentUpdate = false;

			StageEditorState.gfName = gf.curCharacter;
			StageEditorState.dadName = dad.curCharacter;
			StageEditorState.boyfriendName = boyfriend.curCharacter;
			MusicBeatState.switchState(new StageEditorState(Stage.curStage));
		}

			
		#if debug
		if (FlxG.keys.justPressed.ONE && !inCutscene)
		{
			KillNotes();
			FlxG.sound.music.onComplete();
		}

		if(FlxG.keys.justPressed.THREE) //Go 10 seconds into the future, credit: Shadow Mario#9396
		{ 
			setSongTime(Conductor.songPosition + (10000 * (FlxG.keys.pressed.SHIFT ? 6 : 1)));
			clearNotesBefore(Conductor.songPosition);

			//readSection(curSection);
			//readSection(curSection + 1);
		}

		// so the song can play in the background.
		if(FlxG.keys.justPressed.FOUR) {
			FlxG.autoPause = !FlxG.autoPause;
		}

		if (FlxG.keys.justPressed.FIVE)
		{
			if (FlxG.keys.pressed.SHIFT)
			{
				FlxG.save.data.uncacheCharacterSwitch = !FlxG.save.data.uncacheCharacterSwitch;
				trace ('Character Uncaching set to '+FlxG.save.data.uncacheCharacterSwitch);
			}
			else
			{
				FlxG.save.data.botplay = !FlxG.save.data.botplay;
				trace ('Botplay set to '+FlxG.save.data.botplay);
			}
		}
		
		if (FlxG.keys.justPressed.SIX)
			healthSet = !healthSet;
		#end
	}

	function songOutro():Void
	{
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		canPause = false;
		updateTime = false;
		endingSong = true;

		if (ClientPrefs.data.psychUI)
		{
			timeBarBG.visible = false;
			timeBar.visible = false;
			timeTxt.visible = false;
		}

		switch (curSong.toLowerCase())
		{
			default:
			{
				var ret:Dynamic = callOnLuas('onEndSong', [], false);
					
				if(ret != ModchartState.Function_Stop)
					endSong();		
			}		
		}
	}

	var wind2:FlxSound;
	public var transitioning = false;

	public function endSong():Void
	{
		//i don't feel like fixing replays so they work with psych mods.
		/*if (!loadRep){
			rep.SaveReplay(saveNotes);
		}
		else
		{
			FlxG.save.data.botplay = false;
			FlxG.save.data.scrollSpeed = 1;
			FlxG.save.data.downscroll = false;
		}*/

		trace('ending song');
		deathCounter = 0;

		if (FlxG.save.data.fpsCap > 240)
			(cast (Lib.current.getChildAt(0), Main)).setFPSCap(240);

		canPause = false;
		isPixel = false;
		showCutscene = false;

		FlxG.sound.music.volume = 0;
		vocals.volume = 0;

		if (!transitioning)
		{
			if (SONG.validScore)
			{
				// adjusting the highscore song name to be compatible
				// would read original scores if we didn't change packages
				var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");
				switch (songHighscore) {
					case 'Dad-Battle': songHighscore = 'Dadbattle';
					case 'Philly-Nice': songHighscore = 'Philly';
				}
	
				#if !switch
				Highscore.saveScore(songHighscore, Math.round(songScore), storyDifficulty);
				Highscore.saveCombo(songHighscore, Ratings.GenerateLetterRank(accuracy), storyDifficulty);
				#end
			}
			playbackRate = 1;
	
			if (chartingMode)
			{
				openChartEditor();
				return;
			}
	
			PlayState.instance.callOnLuas('onExitSong', []);
	
			if (isStoryMode)
			{
				campaignScore += Math.round(songScore);
				campaignMisses += songMisses;
	
				storyPlaylist.remove(storyPlaylist[0]);
	
				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('newMenu'));
	
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
	
					MusicBeatState.switchState(new states.StoryMenuState());
	
					if (SONG.validScore){
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
					}

					FlxG.save.data.weekCompleted = states.StoryMenuState.weekCompleted;
					FlxG.save.flush();
				}
				else
				{
					
					// adjusting the song name to be compatible
					var songFormat = StringTools.replace(PlayState.storyPlaylist[0], " ", "-");
					switch (songFormat) {
						case 'Dad-Battle': songFormat = 'Dadbattle';
						case 'Philly-Nice': songFormat = 'Philly';
					}
	
					var poop:String = Highscore.formatSong(songFormat, storyDifficulty);
	
					trace('LOADING NEXT SONG');
					trace(poop);
	
					if (StringTools.replace(PlayState.storyPlaylist[0], " ", "-").toLowerCase() == 'eggnog')
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;
	
						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}
	
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;
	
					PlayState.SONG = Song.loadFromJson(poop, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();
	
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else 
			{
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				
				if (isBETADCIU)
				{
					if (CoolUtil.difficulties[0] == "Guest")
						MusicBeatState.switchState(new states.GuestBETADCIUState());
					else
						MusicBeatState.switchState(new states.BETADCIUState());
				}
				else 
				{
					if (isBonus)		
						MusicBeatState.switchState(new states.BonusSongsState());
					else if (isNeonight)
						MusicBeatState.switchState(new states.NeonightState());
					else if (isVitor)
						MusicBeatState.switchState(new states.VitorState());
					else
						MusicBeatState.switchState(new states.FreeplayState());
				}
			}

			transitioning = true;
		}
	}

	var healthBarShakeIntensity:Array<Int> = [10, -15, 8, -5, 3, -1];

	public function healthbarshake(intensity:Float)
	{
		for (i in 0... healthBarShakeIntensity.length)
		{
			new FlxTimer().start(0.00001 + (0.05 * i), function(tmr:FlxTimer)
			{
				iconP1.y += (healthBarShakeIntensity[i] * intensity);
				iconP2.y += (healthBarShakeIntensity[i] * intensity);
				healthBar.y += (healthBarShakeIntensity[i] * intensity);
				healthBarBG.y += (healthBarShakeIntensity[i] * intensity);
			});
		}
	}

	public var endingSong:Bool = false;

	var hits:Array<Float> = [];

	var timeShown = 0;
	var currentTimingShown:FlxText = null;
	public var ratingsAlpha:Float = 1.0;
	public var showRating:Bool = true;

	//i'm taking this combo group thing. currently combos lag a lot.
	public var comboGroup:FlxSpriteGroup;
	public var coolText:FlxText = new FlxText(0, 0, 0, "lol", 32);

	private function popUpScore(daNote:Note = null):Void
	{
		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		coolText.text = placement;
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;

		var score:Float = 350;

		if (FlxG.save.data.accuracyMod == 1){
			var wife:Float = EtternaFunctions.wife3(noteDiff, Conductor.timeScale / playbackRate);
			totalNotesHit += wife;
		}
		
		var daRating = daNote.rating;

		switch(daRating)
		{
			case 'miss':
				daRating = 'shit'; //because i'm tired of it saying miss not found or smthn like that
				combo = 0;
			case 'shit':
				score = -300;
				combo = 0;
				ss = false;
				shits++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.25;
			case 'bad':
				score = 0;	
				ss = false;
				bads++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.50;
			case 'good':
				score = 200;
				ss = false;
				goods++;
				if (health < maxHealth)
					health += 0.02;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.75;
			case 'sick':
				if (health < maxHealth)
					health += 0.0475;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 1;
				sicks++;
		}

		if(FlxG.save.data.noteSplash && daRating == 'sick' && !isMania){
			spawnNoteSplash(daNote.x, daNote.y, daNote.noteData);
		}

		songScore += Math.round(score);
		songScoreDef += Math.round(ConvertScore.convertScore(noteDiff));

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';
		var suf:String = "";

		var offsetX:Float = 0;
		var offsetY:Float = 0;

		switch (curStage)
		{
			default:
				if (usesStageHx)
				{
					offsetX = Stage.gfXOffset;
					offsetY = Stage.gfYOffset;
					pixelShitPart1 = Stage.pixelShitPart1;
					pixelShitPart2 = Stage.pixelShitPart2;
				}	
		}

		if (isPixel)
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';	
		}

		if (!showRating || ratingsAlpha == 0){ //just don't run the rest if the rating is invisible
			return;
		}

		// imageExists makes it lag. just make sure you have the files there.

		var ratingPath:String = pixelShitPart1 + daRating + pixelShitPart2;
		var ratingGraphic = Paths.returnGraphic(ratingPath);

		var rating:FlxSprite = comboGroup.recycle(FlxSprite);
		CoolUtil.resetSprite(rating, -40 + (400 + offsetX) + 300, 300 + (130 + offsetY));
		comboGroup.remove(rating, true);
		rating.loadGraphic(ratingGraphic);
		rating.acceleration.y = 550 * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		
		//i'll add this back when it's needed.
		/*ratingPath = pixelShitPart1 + "combo" + pixelShitPart2;
		ratingGraphic = Paths.returnGraphic(Paths.imageExists(ratingPath) ? ratingPath : "combo");

		var comboSpr:FlxSprite = comboGroup.recycle(FlxSprite).loadGraphic(ratingGraphic);
		CoolUtil.resetSprite(comboSpr, -40 + (400 + offsetX) + 400, 400 + (130 + offsetY));
		comboGroup.remove(comboSpr, true);
		comboSpr.acceleration.y = 600 * playbackRate;
		comboSpr.velocity.y -= 150 * playbackRate;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;*/

		for (i in [rating])
		{
			if (FlxG.save.data.poltatoPC){
				i.scale.set(i.scale.x * 2, i.scale.y * 2);
			}

			i.setGraphicSize(Std.int(i.width * 0.7 * (isPixel || pixelShitPart2 == '-pixel' ? daPixelZoom : 1)));
			i.antialiasing = !(isPixel || pixelShitPart2 == '-pixel');

			i.updateHitbox();
			i.alpha = ratingsAlpha;
		}
		
		comboGroup.add(rating);

		var separatedScore:String = CoolUtil.addZeros(Std.string(combo), 3);

		if (combo == 0 || combo >= 10) {
			//comboGroup.add(comboSpr);
			for (i in 0...separatedScore.length)
			{
				ratingPath = pixelShitPart1 + 'num' + separatedScore.charAt(i) + pixelShitPart2;
				ratingGraphic = Paths.returnGraphic(ratingPath); //Paths.returnGraphic(Paths.imageExists(ratingPath) ?  : 'num' + separatedScore.charAt(i)); 

				var numScore:FlxSprite = comboGroup.recycle(FlxSprite).loadGraphic(ratingGraphic);

				CoolUtil.resetSprite(numScore, (43 * i) - 90 + offsetX + 680, 450 + (130 + offsetY));
				comboGroup.remove(numScore, true);

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);

				if (FlxG.save.data.poltatoPC){
					numScore.scale.set(numScore.scale.x * 2, numScore.scale.y * 2);
				}

				numScore.setGraphicSize(Std.int(numScore.width * (isPixel || pixelShitPart2 == '-pixel' ? daPixelZoom : 0.5)));
				numScore.antialiasing = !(isPixel || pixelShitPart2 == '-pixel');
				
				numScore.updateHitbox();
				numScore.alpha = ratingsAlpha;

				comboGroup.add(numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2/ playbackRate, {
					onComplete: function(tween:FlxTween)
					{
						numScore.exists = false;
					},
					startDelay: Conductor.crochet * 0.002/ playbackRate
				});
			}
		}

		coolText.text = Std.string(separatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2/ playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				//coolText.destroy();
				//comboSpr.exists = false;
				rating.exists = false;
			},
			startDelay: Conductor.crochet * 0.001/ playbackRate
		});

		/*FlxTween.tween(comboSpr, {alpha: 0}, 0.2/ playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				//coolText.destroy();
				comboSpr.exists = false;
				rating.exists = false;
			},
			startDelay: Conductor.crochet * 0.001/ playbackRate
		});*/
	}

	public function NearlyEquals(value1:Float, value2:Float, unimportantDifference:Float = 10):Bool
	{
		return Math.abs(FlxMath.roundDecimal(value1, 1) - FlxMath.roundDecimal(value2, 1)) < unimportantDifference;
	}

	public static function existsInCTS(key:String, ?folder:String)
	{
		var daThing:Dynamic = null;

		if (!Paths.currentTrackedSounds.exists(key))
			Paths.currentTrackedSounds.set(key, (FileSystem.exists(Paths.sound(key)) ? Sound.fromFile(Paths.sound(key)) : OpenFlAssets.getSound(Paths.sound(key))));

		daThing = Paths.currentTrackedSounds.get(key);

		if(daThing == null) //no good sound if sound not found
		{
			Paths.currentTrackedSounds.set(key, OpenFlAssets.getSound(Paths.sound('nogood')));
			daThing = Paths.currentTrackedSounds.get(key);
		}
			
		return daThing;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	var upHold:Bool = false;
	var downHold:Bool = false;
	var rightHold:Bool = false;
	var leftHold:Bool = false;	

	private function keyShit():Void // I've invested in emma stocks
	{
		callOnLuas("setControls", []); // mainly for bonedoggle

		var daControls:Array<String> = [];

		switch(mania)
		{
			case 1: daControls = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'];
			case 2: daControls = ['N1', 'N2', 'N3', 'N4', 'N5', 'N6', 'N7', 'N8'];
			case 3: daControls = ['LEFT', 'DOWN', 'T3', 'UP', 'RIGHT'];
			case 4: daControls = ['S1', 'S2', 'S3', 'T3', 'S4', 'S5', 'S6'];
			default: daControls = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
		}

		holdArray = [];
		pressArray = [];
		releaseArray = [];

		for (i in 0...daControls.length)
		{
			holdArray.push(getControl(daControls[i]));
			pressArray.push(getControl(daControls[i]+'_P'));
			releaseArray.push(getControl(daControls[i]+'_R'));
		}

		callOnLuas("setControlsPost", []); // mainly for bonedoggle
		
		#if LUA_ALLOWED
		if (controls.LEFT_P){callOnLuas('keyPressed',["left"]);};
		if (controls.DOWN_P){callOnLuas('keyPressed',["down"]);};
		if (controls.UP_P){callOnLuas('keyPressed',["up"]);};
		if (controls.RIGHT_P){callOnLuas('keyPressed',["right"]);};
		#end
		
		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && !boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}
	
		// PRESSES, check for note hits
		if (pressArray.contains(true) && !boyfriend.stunned && generatedMusic)
		{
			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later
			var directionsAccounted:Array<Bool> = []; // we don't want to do judgments for more than one presses

			directionsAccounted = [for (i in 0...Main.keyAmmo[mania]) false];	
			
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (!directionsAccounted[daNote.noteData])
					{
						if (directionList.contains(daNote.noteData))
						{
							directionsAccounted[daNote.noteData] = true;
							for (coolNote in possibleNotes)
							{
								if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
								{ // if it's the same note twice at < 10ms distance, just delete it
									// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
									dumbNotes.push(daNote);
									break;
								}
								else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
								{ // if daNote is earlier than existing note (coolNote), replace
									possibleNotes.remove(coolNote);
									possibleNotes.push(daNote);
									break;
								}
							}
						}
						else
						{
							possibleNotes.push(daNote);
							directionList.push(daNote.noteData);
						}
					}
				}
			});
	
			for (note in dumbNotes)
			{
			//	FlxG.log.add("killing dumb ass note at " + note.strumTime);
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
	
			possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
	
			var dontCheck = false;

			for (i in 0...pressArray.length)
			{
				if (pressArray[i] && !directionList.contains(i))
					dontCheck = true;
			}

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0 && !dontCheck)
			{
				if (!FlxG.save.data.ghost)
				{
					for (shit in 0...pressArray.length)
						{ // if a direction is hit that shouldn't be
							if (pressArray[shit] && !directionList.contains(shit) && !writing)
							{
								interupt = true;
								noteMiss(shit, null);
							}		
						}
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.noteData])
					{
						if (mashViolations != 0)
							mashViolations--;
							
						goodNoteHit(coolNote);		
					}
				}
			}
			else if (!FlxG.save.data.ghost)
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit] && !writing)
					{
						interupt = true;
						noteMiss(shit, null);
					}		
			}

			if(dontCheck && possibleNotes.length > 0 && FlxG.save.data.ghost && !cpuControlled && !writing)
			{
				if (mashViolations > 8)
				{
					trace('mash violations ' + mashViolations);
					//scoreTxt.color = FlxColor.RED;
					noteMiss(0,null);
				}
				else
					mashViolations++;
			}

		}
		
		playerCharsDance();
	
		if (!cpuControlled)
		{
			playerStrums.forEach(function(spr:StrumNote)
			{
				if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
				if (!holdArray[spr.ID])
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			});
		}	
	}

	function playerCharsDance()
	{
		if (boyfriend.holdTimer > Conductor.stepCrochet * boyfriend.singDuration * 0.001 / playbackRate && (!holdArray.contains(true) || cpuControlled))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))	
				boyfriend.dance();
		}

		for (value in modchartCharacters.keys())
		{
			daChar = modchartCharacters.get(value);
			
			if ((daChar.isPlayer && daChar.flipMode == false || !daChar.isPlayer && daChar.flipMode == true))
			{
				if (daChar.holdTimer > Conductor.stepCrochet * daChar.singDuration * 0.001 / playbackRate && (!holdArray.contains(true) || cpuControlled))
				{
					if (daChar.animation.curAnim.name.startsWith('sing') && !daChar.animation.curAnim.name.endsWith('miss'))	
						daChar.dance();
				}
			}
		}
	}

	function noteMiss(direction:Int = 1, daNote:Note):Void
	{
		if (!boyfriend.stunned)
		{
			interupt = true;

			var damage:Float = 0.0475;

			if (daNote != null)
				damage = daNote.missHealth;

			health -= damage;
			totalDamageTaken += damage;

			if (combo > 5 && gf.animOffsets.exists('sad'))
				gf.playAnim('sad');

			combo = 0;

			if (!endingSong)
				songMisses++;

			if (FlxG.save.data.accuracyMod == 1)
				totalNotesHit -= 1;

			songScore -= 10;

			FlxG.sound.play(existsInCTS('missnote'+FlxG.random.int(1,3)), FlxG.random.float(0.1, 0.2));

			var dType:Int = 0;
			var char:Character = boyfriend;

			if (daNote != null)
			{
				dType = daNote.dType;

				if (daNote.gfNote)
					char = gf;
			}
			else if (songStarted)
				dType = PlayState.SONG.notes[curSection].dType;
			
			playBF = searchLuaVar('playBFSing', 'bool', false);
			
			if (playBF)
				char.playAnim(playerSingAnimations[direction] + 'miss' + char.bfAltAnim, true);
			
			callOnLuas('playerOneMiss', [direction, Conductor.songPosition, dType]);

			if (daNote != null)
				callOnLuas('noteMiss', [notes.members.indexOf(daNote), direction, daNote.noteType, daNote.isSustainNote, dType]);
			else
				callOnLuas('noteMissPress', [direction, dType]);

			updateAccuracy(true);
		}
	}

	/*function badNoteCheck()
		{
			// just double pasting this shit cuz fuk u
			// REDO THIS SYSTEM!
			var upP = controls.UP_P;
			var rightP = controls.RIGHT_P;
			var downP = controls.DOWN_P;
			var leftP = controls.LEFT_P;
	
			if (leftP)
				noteMiss(0);
			if (upP)
				noteMiss(2);
			if (rightP)
				noteMiss(3);
			if (downP)
				noteMiss(1);
			updateAccuracy();
		}
	*/

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	
	function updateAccuracy(?badHit:Bool = false) 
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);

		if(ret != ModchartState.Function_Stop)
		{
			ratingPercent = HelperFunctions.truncateFloat(accuracy, 2) / 100;
			ratingName = Ratings.generateRatingName(accuracy);
			ratingFC = Ratings.GenerateLetterRankPsych(accuracy);
		}

		if (ClientPrefs.data.psychUI)
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' (' + ratingPercent * 100 + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
		else
			scoreTxt.text = Ratings.CalculateRanking(songScore,songScoreDef,nps,maxNPS,accuracy);

		totalPlayed += 1;
		accuracy = Math.max(0,totalNotesHit / totalPlayed * 100);
		accuracyDefault = Math.max(0, totalNotesHitDefault / totalPlayed * 100);

		callOnLuas('onUpdateScore', [badHit]);
		
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	function getKeyPresses(note:Note):Int
	{
		var possibleNotes:Array<Note> = []; // copypasted but you already know that

		notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
			{
				possibleNotes.push(daNote);
				possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
			}
		});
		if (possibleNotes.length == 1)
			return possibleNotes.length + 1;
		return possibleNotes.length;
	}
	
	var mashing:Int = 0;
	var mashViolations:Int = 0;

	var etternaModeScore:Int = 0;

	function noteCheck(controlArray:Array<Bool>, note:Note):Void // sorry lol
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.CalculateRating(noteDiff);
		
		if (controlArray[note.noteData])
		{
			goodNoteHit(note, (mashing > getKeyPresses(note)));
			
			/*if (mashing > getKeyPresses(note) && mashViolations <= 2)
			{
				mashViolations++;

				goodNoteHit(note, (mashing > getKeyPresses(note)));
			}
			else if (mashViolations > 2)
			{
				// this is bad but fuck you
				playerStrums.members[0].animation.play('static');
				playerStrums.members[1].animation.play('static');
				playerStrums.members[2].animation.play('static');
				playerStrums.members[3].animation.play('static');
				health -= 0.4;
				trace('mash ' + mashing);
				if (mashing != 0)
					mashing = 0;
			}
			else
				goodNoteHit(note, false);*/

		}
	}

	function opponentNoteHit(note:Note):Void
	{
		switch (curSong)
		{
			case 'Tutorial' | 'Tutorial-Remix' | 'Get Out' | 'Their-Battle' | 'Ghost-VIP':
				camZooming = false;
			default:
				camZooming = true;
		}

		dad.altAnim = "";
			
		if (SONG.notes[curSection] != null)
		{
			if (SONG.notes[curSection].altAnim){
				note.animSuffix = "-alt";
			}					
		}

		if (note.animSuffix != "")
			dad.altAnim = note.animSuffix;

		var dDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

		playDad = searchLuaVar('playDadSing', 'bool', false);

		callOnLuas('dadPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
		
		if (playDad)
		{
			if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
				dad.playAnim('hey', true);
				dad.specialAnim = true;
				dad.heyTimer = 0.6;
			}
			else if (!note.noAnimation)
			{
				var char:Character = dad;
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + dad.altAnim;
				if(note.gfNote) {
					char = gf;
				}

				if(char != null)
				{
					char.playAnim(animToPlay, true);
					char.holdTimer = 0;
				}
			}
		}
		
		callOnLuas('dadNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote, note.dType]);
		callOnLuas('playerTwoSing', [Math.abs(note.noteData), Conductor.songPosition]);

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}

		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)), time);
		note.hitByOpponent = true;

		if (SONG.needsVoices)
			vocals.volume = 1;

		note.active = false;

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note, resetMashViolation = true):Void
	{			
		if (mashing != 0)
			mashing = 0;

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.CalculateRating(noteDiff);

		if(note.hitCausesMiss) {
			noteMiss(note);

			if(!note.noteSplashDisabled && !note.isSustainNote) {
				spawnNoteSplashOnNote(note);
			}

			if(!note.noMissAnimation)
			{
				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}

			note.wasGoodHit = true;
			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
			return;
		}

		// add newest note to front of notesHitArray
		// the oldest notes are at the end and are removed first
		//if (!note.isSustainNote)
		//	notesHitArray.unshift(Date.now());

		if (!resetMashViolation && mashViolations >= 1)
			mashViolations--;

		if (mashViolations < 0)
			mashViolations = 0;

		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote && !note.noRating) //i'll replace this when I find something better
			{
				combo += 1;
				songHits++;
				popUpScore(note);
			}
			else
				totalNotesHit += 1;

			var char:Character = boyfriend;
			
			if (note.gfNote && gf != null)
				char = gf;

			char.bfAltAnim = '';
			playBF = searchLuaVar('playBFSing', 'bool', false);

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].bfAltAnim){
					note.animSuffix = "-alt";
				}					
			}

			if (note.animSuffix != "")
				char.bfAltAnim = note.animSuffix;

			callOnLuas('bfPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);

			if (playBF && !note.noAnimation)
			{
				char.playAnim(playerSingAnimations[note.noteData] + char.bfAltAnim, true);
				char.holdTimer = 0;	
			}
		
			if(!loadRep && note.mustPress)
				saveNotes.push(HelperFunctions.truncateFloat(note.strumTime, 2));

			#if LUA_ALLOWED
			callOnLuas('playerOneSing', [note.noteData, Conductor.songPosition]);
			callOnLuas('bfNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote, note.dType]);
			#end
			
			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)), time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID){	
						spr.playAnim('confirm', true);
					}
				});
			}
			
			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
			
			updateAccuracy();
		}
	}
		

	var fastCarCanDrive:Bool = true;
	
	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {//
		var skin:String = "";
		skin = splashSkin;
		
		if(note != null && note.noteSplashTexture != null) {
			skin = note.noteSplashTexture;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin);
		grpNoteSplashes.add(splash);
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(FlxG.save.data.noteSplash && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnStartingNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {//
		var skin:String = "";
		skin = splashSkin;
		
		if(note != null && note.noteSplashTexture != null) {
			skin = note.noteSplashTexture;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin);
		splash.alpha = 0.0001;
		grpNoteSplashes.add(splash);
	}

	var danced:Bool = false;

	var stepOfLast = 0;

	public function funCountdown(number:String = 'three') // why tf were they separate functions!? this works perfectly fine
	{
		switch (number)
		{
			case 'three':
				var three:FlxSprite = new FlxSprite().loadGraphic(Paths.image('sonic/exe/three'));
				three.scrollFactor.set();
				three.updateHitbox();
				three.screenCenter();
				three.y -= 100;
				three.alpha = 0.5;
				add(three);
				FlxTween.tween(three, {y: three.y += 100, alpha: 0}, Conductor.crochet / 1000, {
					ease: FlxEase.cubeOut,
					onComplete: function(twn:FlxTween)
					{
						three.destroy();
					}
				});
			case 'two':
				var two:FlxSprite = new FlxSprite().loadGraphic(Paths.image('sonic/exe/two'));
				two.scrollFactor.set();
				two.screenCenter();
				two.y -= 100;
				two.alpha = 0.5;
				add(two);
				FlxTween.tween(two, {y: two.y += 100, alpha: 0}, Conductor.crochet / 1000, {
					ease: FlxEase.cubeOut,
					onComplete: function(twn:FlxTween)
					{
						two.destroy();
					}
				});
			case 'one':
				var one:FlxSprite = new FlxSprite().loadGraphic(Paths.image('sonic/exe/one'));
				one.scrollFactor.set();
				one.screenCenter();
				one.y -= 100;
				one.alpha = 0.5;

				add(one);
				FlxTween.tween(one, {y: one.y += 100, alpha: 0}, Conductor.crochet / 1000, {
					ease: FlxEase.cubeOut,
					onComplete: function(twn:FlxTween)
					{
						one.destroy();
					}
				});
			case 'go': // go is not a number lol
				var gofun:FlxSprite = new FlxSprite().loadGraphic(Paths.image('sonic/exe/gofun'));
				gofun.scrollFactor.set();
				gofun.screenCenter();
				gofun.y -= 100;
				gofun.alpha = 0.5;

				add(gofun);
				FlxTween.tween(gofun, {y: gofun.y += 100, alpha: 0}, Conductor.crochet / 1000, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn:FlxTween)
					{
						gofun.destroy();
					}
				});
		}
	}

	public function addTextToDebug(text:String, ?color:FlxColor = FlxColor.RED) {
		if (luaDebugGroup != null)
		{
			luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
				spr.y += 20;
			});
	
			if(luaDebugGroup.members.length > 34) {
				var blah = luaDebugGroup.members[34];
				blah.destroy();
				luaDebugGroup.remove(blah);
			}
			luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		}
	}

	public function doTimeTravel(shiftPressed:Bool = false, ?skipExactly:Int = 0)
	{
		var multiplier:Int = 1;
		if (shiftPressed)multiplier = 6; //we skippin minutes now

		if (skipExactly != 0)
		{
			if (!usedTimeTravel && skipExactly < FlxG.sound.music.length) 
			{
				usedTimeTravel = true;
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition = skipExactly;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime - 500 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;
					
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
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
				Conductor.songPosition += 10000 * multiplier;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime - 500 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;
					
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
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
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						usedTimeTravel = false;
					});
			}
		}	
	}

	public function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public function startVideo(name:String, ?skippable:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;
		canPause = false;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			doVideoFinish(name);
			return;
		}

		var video:VideoHandler = new VideoHandler();
			#if (hxCodec >= "3.0.0")
			// Recent versions
			video.play(filepath);
			video.onEndReached.add(function()
			{
				video.dispose();
				doVideoFinish(name);
				return;
			}, true);
			#else
			// Older versions
			video.playVideo(filepath);
			video.finishCallback = function()
			{
				doVideoFinish(name);
				return;
			}
			#end
		#else
		FlxG.log.warn('Platform not supported!');
		doVideoFinish(name);
		return;
		#end
	}

	function doVideoFinish(name:String){
		clearNotesBefore(Conductor.songPosition);
		canPause = true;
		inCutscene = false;
		var ret:Dynamic = callOnLuas("onVideoCompleted", [name], false);
	
		if(ret != ModchartState.Function_Stop) {
			startAndEnd();
		}
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!FlxG.save.data.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!FlxG.save.data.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
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

				if (FileSystem.exists(vert))
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
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function set_cameraSpeed(value:Float):Float
	{
		cameraSpeed = value;
		camFollowSpeed = (cameraSpeed*0.04);
		adjustCamFollow();
		
		return value;
	}

	function set_cameraSystem(value:String):String
	{
		var currentCamPos:Array<Float> = [];

		if (camFollow != null){
			currentCamPos = [camFollow.x, camFollow.y]; 
		}

		var systems:Array<String> = ["camFollow", "camFollowPos", "prevCamFollow", "prevCamFollowPos"];

		for (i in systems)
		{
			var obj:FlxBasic = Reflect.getProperty(PlayState.instance, i);

			if (obj != null){
				remove(obj);
				obj.destroy();
			}
		}
		
		cameraSystem = value;
		createCamSystem(currentCamPos[0], currentCamPos[1]);
		
		return value;
	}

	public function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		//Conductor.safeZoneOffset = (FlxG.save.data.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		adjustCamFollow();

		return value;
	}

	function createCamSystem(daX:Float, daY:Float)
	{
		if (cameraSystem.toLowerCase() == "psych"){
			camFollow = new FlxPoint();
			camFollowPos = new FlxObject(0, 0, 1, 1);
	
			snapCamFollowToPos(daX, daY);

			if (prevCamFollow != null)
			{
				camFollow = prevCamFollow;
				prevCamFollow = null;
			}
			if (prevCamFollowPos != null)
			{
				camFollowPos = prevCamFollowPos;
				prevCamFollowPos = null;
			}

			add(camFollowPos);
		}
		else{
			camFollow = new FlxObject(0, 0, 1, 1);
			camFollow.setPosition(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);

			if (prevCamFollow != null)
			{
				camFollow = prevCamFollow;
				prevCamFollow = null;
			}

			add(camFollow);
		}
	
		if (cameraSystem.toLowerCase() == "psych"){
			FlxG.camera.follow(camFollowPos, LOCKON, 1);
		}
		else{
			FlxG.camera.follow(camFollow, LOCKON, (cameraSpeed*0.04) * playbackRate * (30 / Main.getFPSStatic()) * (120 / Main.getFPSStatic()));			
		} 

		FlxG.camera.focusOn((cameraSystem.toLowerCase() == "psych" ? camFollow : camFollow.getPosition()));
	}

	public function adjustCamFollow():Void
	{
		var fps = Main.getFPSStatic();

		if (cameraSystem.toLowerCase() != "psych")
		{
			if (camFollow != null){
				FlxG.camera.follow(camFollow, LOCKON, (cameraSpeed*0.04) * playbackRate * (30 / fps) * (120 / fps));
			}
		}
	}

	var startingFPS:Float;

	override function stepHit()
	{
		super.stepHit();

		/*if (SONG.notes[curSection].dadCrossfade)
			dadTrail.active = true;
		else if (!SONG.notes[curSection].dadCrossfade)
		{
			dadTrail.active = false;
			dadTrail.resetTrail();	
		}
			
		if (SONG.notes[curSection].bfCrossfade)
			bfTrail.active = true;	

		else if (!SONG.notes[curSection].bfCrossfade)
		{
			bfTrail.active = false;
			bfTrail.resetTrail();
		}*/

		if (usesStageHx)
			Stage.stepHit();

		dad.altAnim = "";
		boyfriend.bfAltAnim = "";

		var notes = SONG.notes[curSection];
		if (notes != null)
		{
			if (notes.altAnim) dad.altAnim = '-alt';
			if (notes.bfAltAnim) boyfriend.bfAltAnim = '-alt';
		}

		var time = FlxG.sound.music.time;
		var length = FlxG.sound.music.length;
		var position = Conductor.songPosition;
		if (time > position + (20 * playbackRate) || time < position - (20 * playbackRate))
			resyncVocals();

		//dumb fix while I try to fix the fps drops
		var fps = Main.getFPSStatic();
		if (fps < startingFPS - 20 || fps > startingFPS + 20)
		{
			var speed = (cameraSpeed * 0.04) * playbackRate * (30 / fps) * (120 / fps);
			FlxG.camera.follow(camFollow, LOCKON, speed);
			startingFPS = fps;
		}
			
		setOnLuas('curStep',curStep);
		callOnLuas('stepHit',[curStep]);
		callOnLuas('onStepHit', [curStep]);

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "Acc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | songMisses: " + songMisses  , iconRPC,true,  songLength - Conductor.songPosition);
		#end

	}

	var daChar:Character;

	public var opponentIconScale:Float = 1.2;
	public var playerIconScale:Float = 1.2;
	public var iconBopSpeed:Int = 1;

	override function beatHit()
	{
		super.beatHit();

		if (usesStageHx)
			Stage.beatHit();

		if (generatedMusic){ 
			notes.sort(FlxSort.byY, (FlxG.save.data.downscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));
		}

		setOnLuas('curBeat',curBeat);
		callOnLuas('beatHit', [curBeat]);
		callOnLuas('onBeatHit', [curBeat]);

		// FlxG.log.add('change bpm' + SONG.notes[curSection].changeBPM);
		//wiggleShit.update(Conductor.crochet);

		if (FlxG.save.data.camzoom)
		{
			if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0 && !inCutscene)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}
	
			if (curBeat % iconBopSpeed == 0)
			{
				iconP1.scale.set(playerIconScale, playerIconScale);
				iconP2.scale.set(opponentIconScale, opponentIconScale);
	
				iconP1.updateHitbox();
				iconP2.updateHitbox();
			}
		}

		if (gf != null) {
			danceIfPossible(gf);
		}
		
		danceIfPossible(boyfriend);
		danceIfPossible(dad);
		
		for (value in modchartCharacters.keys()) {
			daChar = modchartCharacters.get(value);
			danceIfPossible(daChar);
		}
	}

	var curLight:Int = 0;

	function danceIfPossible(character: Character): Void {
		var danceNo:Int = character.danceEveryNumBeats;

		if (character == gf){
			danceNo = Math.round(gfSpeed * character.danceEveryNumBeats);
		}

		if (curBeat % danceNo == 0 && character.animation.curAnim != null && !character.animation.curAnim.name.startsWith('sing') && !character.stunned) {
			character.dance();
		}
	}

	//this is experimental as shit
		
	function readSection(sectionNumber:Int, ?checkNoteTypes:Bool = false){
		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = daSongData.notes;

		var suf:String = "";
		var stuff:Array<String> = [];

		if (FileSystem.exists(Paths.txt(songLowercase  + "/arrowSwitches" + suf))){
			stuff = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/arrowSwitches" + suf));
		}

		var section = noteData[sectionNumber];

		if (stuff != [])
		{
			for (i in 0...stuff.length)
			{
				var data:Array<String> = stuff[i].split(' ');

				if (sectionNumber == Std.parseInt(data[0])){
					(data[2] == 'dad' ? opponentSectionNoteStyle = data[1] : playerSectionNoteStyle = data[1]);
				}
			}
		}
		
		var mn:Int = Main.keyAmmo[mania]; //new var to determine max notes
		var coolSection:Int = Std.int(section.lengthInSteps / 4);
		var playerNotes:Array<Int> = [];

		//trying to use old system with the new mania stuff

		playerNotes = [for (i in 0...mn) i];
		playerNotes = playerNotes.concat([for (i in (mn * 2)...(mn * 3)) i]);

		for (songNotes in section.sectionNotes)
		{
			if (songNotes == null) continue;

			alt = dad.noteSkin;
			alt2 = boyfriend.noteSkin;
		
			var daStrumTime:Float = songNotes[0];
			var daNoteData:Int = Std.int(songNotes[1] % mn);

			var gottaHitNote:Bool = section.mustHitSection;

			if (!playerNotes.contains(songNotes[1]))
				gottaHitNote = !section.mustHitSection;
			
			var oldNote:Note;

			if (unspawnNotes.length > 0)
				oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
			else
				oldNote = null;

			var daType = songNotes[3];

			if (!checkNoteTypes && !(daType == null || daType == "")){
				continue;
			}

			var swagNote:Note;
			swagNote = new Note(daStrumTime, daNoteData, oldNote, false, daType, (gottaHitNote ? (playerSectionNoteStyle != "" ? playerSectionNoteStyle : alt2) : (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : alt)));
			swagNote.sustainLength = songNotes[2];
			swagNote.mustPress = gottaHitNote;
			swagNote.gfNote = (section.gfSection && (songNotes[1] < Main.keyAmmo[mania]));
			swagNote.scrollFactor.set(0, 0);
			swagNote.dType = section.dType;
			swagNote.noteType = songNotes[3];
			swagNote.noteSection = daSection;
			if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

			var susLength:Float = swagNote.sustainLength;

			susLength = susLength / Conductor.stepCrochet;
			unspawnNotes.push(swagNote);

			var floorSus:Int = Math.floor(susLength);
			if(floorSus > 0) 
			{
				for (susNote in 0...floorSus+1)
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true, daType, (gottaHitNote ? (playerSectionNoteStyle != "" ? playerSectionNoteStyle : alt2) : (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : alt)));
					sustainNote.mustPress = gottaHitNote;
					sustainNote.gfNote = (section.gfSection && (songNotes[1] < Main.keyAmmo[mania]));
					sustainNote.noteType = swagNote.noteType;
					sustainNote.dType = swagNote.dType;
					sustainNote.noteSection = daSection;
					sustainNote.scrollFactor.set();
					swagNote.tail.push(sustainNote);
					sustainNote.parent = swagNote;
					unspawnNotes.push(sustainNote);

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset
				}
			}

			if (swagNote.mustPress){
				swagNote.x += FlxG.width / 2; // general offset
			}
		}

		daSection += 1;
		//daBeats += 1;

		unspawnNotes.sort(sortByShit);
	}

	function oldReadSection(?onlyNoteTypes:Bool = true)
	{
		var noteData:Array<SwagSection>;

		// NEW SHIT	
		noteData = daSongData.notes;

		var suf:String = "";
		var stuff:Array<String> = [];

		if (FileSystem.exists(Paths.txt(songLowercase  + "/arrowSwitches" + suf))){
			stuff = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/arrowSwitches" + suf));
		}

		for (section in noteData)
		{	
			if (stuff != [])
			{
				for (i in 0...stuff.length)
				{
					var data:Array<String> = stuff[i].split(' ');

					if (daSection == Std.parseInt(data[0])){
						(data[2] == 'dad' ? opponentSectionNoteStyle = data[1] : playerSectionNoteStyle = data[1]);
					}
				}
			}
			
			var mn:Int = Main.keyAmmo[mania]; //new var to determine max notes
			var coolSection:Int = Std.int(section.lengthInSteps / 4);
			var playerNotes:Array<Int> = [];

			//trying to use old system with the new mania stuff

			playerNotes = [for (i in 0...mn) i];
			playerNotes = playerNotes.concat([for (i in (mn * 2)...(mn * 3)) i]);

			for (songNotes in section.sectionNotes)
			{
				if (songNotes == null) continue;

				alt = dad.noteSkin;
				alt2 = boyfriend.noteSkin;
			
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % mn);

				var gottaHitNote:Bool = section.mustHitSection;

				if (!playerNotes.contains(songNotes[1]))
					gottaHitNote = !section.mustHitSection;
				
				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var daType = songNotes[3];

				if (onlyNoteTypes && (daType == null || daType == "")){
					continue;
				}

				var swagNote:Note;
				swagNote = new Note(daStrumTime, daNoteData, oldNote, false, daType, (gottaHitNote ? (playerSectionNoteStyle != "" ? playerSectionNoteStyle : alt2) : (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : alt)));
				swagNote.sustainLength = songNotes[2];
				swagNote.mustPress = gottaHitNote;
				swagNote.gfNote = (section.gfSection && (songNotes[1] < Main.keyAmmo[mania]));
				swagNote.scrollFactor.set(0, 0);
				swagNote.dType = section.dType;
				swagNote.noteType = songNotes[3];
				swagNote.noteSection = daSection;
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) 
				{
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true, daType, (gottaHitNote ? (playerSectionNoteStyle != "" ? playerSectionNoteStyle : alt2) : (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : alt)));
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < Main.keyAmmo[mania]));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.dType = swagNote.dType;
						sustainNote.noteSection = daSection;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				if (swagNote.mustPress){
					swagNote.x += FlxG.width / 2; // general offset
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}

			daSection += 1;
			//daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);
	}
}