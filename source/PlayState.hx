package;

import webm.WebmPlayer;
import flixel.input.keyboard.FlxKey;
import haxe.Exception;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import lime.graphics.Image;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetManifest;
import openfl.utils.AssetLibrary;
import flixel.system.FlxAssets;

import lime.app.Application;
import lime.media.AudioContext;
import lime.media.AudioManager;
import openfl.Lib;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxTiledSprite;
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.ColorMatrixFilter;
import CharacterEditorState;

import Note.EventNote;
import openfl.events.KeyboardEvent;

#if windows
import Discord.DiscordClient;
#end
#if windows
import Sys;
import sys.FileSystem;
#end

#if sys
import lime.media.AudioBuffer;
import flash.media.Sound;
#end
import openfl.system.System;

import ModchartState;
import Shaders;

//detected
#if desktop
import LuaClass.LuaCamera;
import LuaClass.LuaNote;
#end

using StringTools;

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

	public var minusHealth:Bool = false;
	public var tabiZoom:Bool = false;
	public static var mania:Int = 0;

	public var tordCam:Array<FlxPoint> = [new FlxPoint(391.2,-1094.15),new FlxPoint(290.9,-1094.15),new FlxPoint(450.9,-1094.15),new FlxPoint(374.9,-1174.15),new FlxPoint(570.9,-974.15)];

	public var cjCloneLinesSing:Array<String> = ["SUFFER","INCORRECT", "INCOMPLETE", "INSUFFICIENT", "INVALID", "CORRECTION", "MISTAKE", "REDUCE", "ERROR", "FAULTY", "IMPROBABLE", "IMPLAUSIBLE", "MISJUDGED", "ABUSE"];
	public var exTrickyLinesSing:Array<String> = ["SUFFER","INCORRECT", "INCOMPLETE", "INSUFFICIENT", "INVALID", "CORRECTION", "MISTAKE", "REDUCE", "ERROR", "ADJUSTING", "IMPROBABLE", "IMPLAUSIBLE", "MISJUDGED"];
	public var auditorLinesSing:Array<String> = ["SUFFER","INCORRECT", "INCOMPLETE", "INSUFFICIENT", "INVALID", "CORRECTION", "MISTAKE", "REDUCE", "ERROR", "ADJUSTING", "IMPROBABLE", "IMPLAUSIBLE", "MISJUDGED"];
	public var trickyLinesSing:Array<String> = ["SUFFER","INCORRECT", "INCOMPLETE", "INSUFFICIENT", "INVALID", "CORRECTION", "MISTAKE", "REDUCE", "ERROR", "ADJUSTING", "IMPROBABLE", "IMPLAUSIBLE", "MISJUDGED"];

	var songLength:Float = 0;
	var lolText:FlxText;

	public var picoCutscene:Bool = false;

	//cam moving shenanigans
	var bfCamX:Int = 0;
	var bfCamY:Int = 0;
	var dadCamX:Int = 0;
	var dadCamY:Int = 0;

	//sus
	var flashSprite:FlxSprite = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width *2), Std.int(FlxG.height*2), 0xFFb30000);
	var _cb = 0;
	var _b = 0;
	
	var vg:FlxSprite;
	var wind:FlxSound = new FlxSound().loadEmbedded(Paths.sound('soundTest', 'shared'),true);
	
	#if windows
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

	//dialogue shenanigans
	var doof:DialogueBox;
	var doof2:DialogueBox;
	var doof3:DialogueBox;
	var doof4:DialogueBox;

	public var healthSet:Bool = false;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	var tstatic:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.image('bruhtf', 'shared'), true, 150, 150);
	var rushiaScreamOverlay:FlxSprite;
	var zipperScreamOverlay:FlxSprite;
	var periScreamOverlay:FlxSprite;
	var rushiaOverlayFrame:Int = 0;
	static var rushiaOverlayFrameMax:Int = 27;

	var tStaticSound:FlxSound = new FlxSound().loadEmbedded(Paths.sound("soundTest","shared"));

	public var strumLine:FlxSprite;
	private var curSection:Int = 0;

	//flipped it so it doesn't mess with some of my luas that use camFollow
	public var camFollow:FlxObject;
	public var camFollowPos:FlxPoint;
	public static var prevCamFollow:FlxObject;
	public static var prevCamFollowPos:FlxPoint;

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
	private var combo:Int = 0;
	public var misses:Int = 0;
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
	public var cameraSpeed:Float = 1;

	//detected
	public var camSustains:FlxCamera;
	public var camNotes:FlxCamera;

	public static var newIcons:Bool = false;
	public static var swapIcons:Bool = true;
	public var playDad:Bool = true;
	public var playBF:Bool = true;

	var notesHitArray:Array<Date> = [];
	var currentFrames:Int = 0;

	public var dialogue:Array<String> = ['dad:blah blah blah', 'bf:coolswag'];
	public var extra2:Array<String> = ['dad:blah blah blah', 'bf:coolswag'];
	public var extra3:Array<String> = ['dad:blah blah blah', 'bf:coolswag'];

	//YO MAMA
	public var yoMamaBG:FlxSprite;
	public var brody:FlxSprite;

	public var eyes:FlxSprite;
	public var eyes2:FlxSprite;

	public static var triggeredFlip:Bool = false;

	// all the damn sprites
	var normbg:FlxSprite;
	var whiteflash:FlxSprite;
	var blackScreen:FlxSprite;
	var stageFront:FlxSprite;
	var stageFront2:FlxSprite;
	var bg2:FlxSprite;
	var bg:FlxSprite;
	var babyArrow:FlxSprite;
	var daSign:FlxSprite;
	var wBg:FlxSprite;
	var nwBg:FlxSprite;
	var wstageFront:FlxSprite;

	var daSection:Int = 0;

	public var circ1:FlxSprite;

	//for gospel sarv floating
	var tween:FlxTween;
	var doingFloatShit:Bool = false;
	var doingBoyfriendFloatShit:Bool = false;
	var shouldFloat:Bool = false;

	var removedTrail:Bool = false;
	public var daJumpscare:FlxSprite = new FlxSprite(0, 0);

	var songName:FlxText;
	public var tabiTrail:FlxTrail;
	var altAnim:String = "";
	var bfAltAnim:String = "";

	var fc:Bool = true;
	var comboSpr:FlxSprite;

	var rock:FlxSprite;
	var dadrock:FlxSprite;
	var gf_rock:FlxSprite;
	var burst:FlxSprite;

	public var isLullaby:Bool = false;

	var wiggleShit:WiggleEffect = new WiggleEffect();

	public var songScore:Int = 0;
	public var songScoreDef:Int = 0;
	public var scoreTxt:FlxText;
	var replayTxt:FlxText;

	public static var campaignScore:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	public static var daPixelZoom:Float = 6;

	public static var theFunne:Bool = true;
	public var inCutscene:Bool = false;
	public static var seenCutscene:Bool = false;
	public static var repPresses:Int = 0;
	public static var repReleases:Int = 0;
	public var floatshit:Float = 0;

	var ringCounter:FlxSprite;
	var counterNum:FlxText;
	var cNum:Int = 0;

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

	private var shakeCam2:Bool = false;
	var shootArray:Array<Int> = [];
	// control arrays, order L D U R dumbass
	var holdArray:Array<Bool> = [];
	var pressArray:Array<Bool> = [];	
	var releaseArray:Array<Bool> = [];

	// API stuff
	
	public function addObject(object:FlxBasic) { add(object); }
	public function removeObject(object:FlxBasic) { remove(object); }
	public function destroyObject(object:FlxBasic) { object.destroy(); }

	var pixelNotes:Array<String> = ['pixel', 'neon', 'pixel-corrupted', 'pixel-combined', 'guitar']; //guitar notes also have zero offsets
	var skipIntroSongs:Array<String> = ['endless', 'four-way-fracture', 'killer-scream']; //skip the damn 3, 2, 1 go!
	var pixelSwap:Bool = false;
	var usesStageHx:Bool = false;
	public var defaultBar:Bool = true;
	public var skipCountdown:Bool = false;

	//neonight stuff
	//yeah no i found a vastly superior way of doin the damn arrow switches.
	public var changeArrows:Bool = false;
	public var splashSkin:String = '';

	public var Stage:Stage;
	public var PreloadStage:PreloadStage;

	public var bfTrail:DeltaTrail;
	public var dadTrail:DeltaTrail;
	public var bfStrumStyle:String = "";
	public var camFollowSpeed:Float = 0.04; // so I can modify how fast the camera moves
	var isMania = false;

	//exe
	var blackFuck:FlxSprite;
	var startCircle:FlxSprite;
	var startText:FlxSprite;
	var xOff:Array<Int> = [-15, 0, 0, 15];
	var yOff:Array<Int> = [0, 15, -15, 0];
	var dontHitNotes:Array<String> = ['2, 4, 6, 8, 9, 10'];
	var daP3Static:FlxSprite = new FlxSprite(0, 0);
	var daNoteStatic:FlxSprite = new FlxSprite(0, 0);

	//hypno shit
	var trance:Float = 0;
	public var canHitPendulum:Bool = false;
	public var hitPendulum:Bool = false;
	var pendulum:Pendulum;
	var pendulumShadow:FlxTypedGroup<FlxSprite>;
	var pendulumDrain:Bool = true;
	var skippedFirstPendulum:Bool = false;
	var psyshockCooldown:Int = 80;
	var psyshocking:Bool = false;

	var songLowercase:String = "";
	public var hasDialogue = true;	
	var songPercent:Float = 0;

	public var pixelStrumsBF:Bool = false;
	public var pixelStrumsDad:Bool = false;

	public var camFollowIsOn:Bool = true;
	public var lockedCamera:Bool = false;

	//more lua shit taken from psych
	public var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartIcons:Map<String, ModchartIcon> = new Map<String, ModchartIcon>(); //should also help for cosmic
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartCharacters:Map<String, Character> = new Map<String, Character>(); //worth a shot
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartInputTexts:Map<String, ModchartInputText> = new Map<String, ModchartInputText>(); //because monochrome
	public var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	public var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	public var shader_chromatic_abberation:ChromaticAberrationEffect;
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];
	public var shaderUpdates:Array<Float->Void> = [];

	public var isDetected:Bool = false;
	public var isDead:Bool = false; //Don't mess with this on Lua!!!

	override public function create()
	{
		instance = this;

		MainMenuState.mainMusic = false; //to fix that weird bug with the inst still playing if you quit really fast

		picoCutscene = false;
		isPixel = false;
		newIcons = false;
		swapIcons = false;
		hasDialogue = false; //remove this when you readd dialogue

		GameOverSubstate.characterName = 'bf';
		GameOverSubstate.deathSoundName = 'fnf_loss_sfx';
		GameOverSubstate.loopSoundName = 'gameOver';
		GameOverSubstate.endSoundName = 'gameOverEnd';

		mania = SONG.mania;
		isMania = (SONG.mania > 0);

		isLullaby = (SONG.song.toLowerCase() == 'safety-lullaby');

		isDetected = (SONG.song.toLowerCase() == 'detected');

		if (SONG.song.toLowerCase() == 'four-way-fracture')
		{
			/*daP3Static.frames = Paths.getSparrowAtlas('sonic/exe/Phase3Static');
			daP3Static.animation.addByPrefix('P3Static', 'Phase3Static instance 1', 24, false);
			add(daP3Static);
			daP3Static.animation.play('P3Static');
			remove(daP3Static);

			daNoteStatic.frames = Paths.getSparrowAtlas('sonic/exe/hitStatic');
			daNoteStatic.animation.addByPrefix('static', 'staticANIMATION', 24, false);
			daNoteStatic.animation.play('static');

			remove(daNoteStatic);

			xOff.insert(2, 0);
			yOff.insert(2, 0);*/
		}
	
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
		
		if (isBETADCIU && storyDifficulty == 5)
		{
			if (!FlxG.save.data.stageChange && FileSystem.exists(Paths.lua(SONG.song.toLowerCase()  + "/modchart-guest-noStage")))
				suf = '-guest-noStage';	
			else
			{
				suf = '-guest';	

				if(FileSystem.exists(Paths.lua(SONG.song.toLowerCase()  + "/modchart-guest-noStage")))
					changeArrows = true;
			}
		}

		if (isBETADCIU && FileSystem.exists(Paths.lua(SONG.song.toLowerCase()  + "/modchart-betadciu")))
			suf = '-betadciu';
			
		switch (SONG.song.toLowerCase())
		{
			case 'hill-of-the-void':
				changeArrows = true;
				if (!FlxG.save.data.stageChange)
					suf = '-noStage';	

			/*case 'epiphany':
				if (storyDifficulty == 5)
					duoDad = true;
			case 'haachama-ex' | 'shinkyoku':
				duoDad = true;
				duoBoyfriend = true;
			case 'triple-trouble':
				if (isBETADCIU)
				{
					SONG.player2 = 'soul-tails';
					SONG.player1 = 'bf-updike';
					duoDad = true;
					duoBoyfriend = true;
				}
			case 'four-way-fracture':
				trioDad = true;
				trioBoyfriend = true;
			case 'ghost-vip':
				if (storyDifficulty == 5)
					changeArrows = true;
			case 'kaboom':
				if (suf == '-betadciu')
					SONG.player2 = 'demoman';
			case 'omnipresent':
				trioDad = true; //max dads on stage is 3. selever, me, and senpai.
				duoBoyfriend = true; //max bfs on stage is 2 with sunday and rushia */
		}

		FlxG.mouse.visible = false;
		
		if (FlxG.save.data.fpsCap > 290)
			(cast (Lib.current.getChildAt(0), Main)).setFPSCap(800);
		
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;

		misses = 0;

		repPresses = 0;
		repReleases = 0;

		resetSpookyText = true;

		// pre lowercasing the song name (create)
		songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle': songLowercase = 'dadbattle';
			case 'philly-nice': songLowercase = 'philly';
			case 'scary-swings': songLowercase = 'scary swings';
			case 'my-sweets': songLowercase = 'my sweets';
		}
		
		#if windows
		executeModchart = FileSystem.exists(Paths.lua(songLowercase  + "/modchart" + suf));
		#end
		#if !cpp
		executeModchart = false; // FORCE disable for non cpp targets
		#end

		trace('Mod chart: ' + executeModchart + " - " + Paths.lua(songLowercase + "/modchart" + suf));

		#if windows
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

		if (SONG.song.toLowerCase() == 'crucify' && isNeonight && !FlxG.save.data.stageChange)
		//	SONG.noteStyle = 'darker';

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
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
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

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		cjCloneLinesSing = CoolUtil.coolTextFile(Paths.txt('cjCloneSingStrings'));
		exTrickyLinesSing = CoolUtil.coolTextFile(Paths.txt('trickyExSingStrings'));
		auditorLinesSing = CoolUtil.coolTextFile(Paths.txt('auditorSingStrings'));
		trickyLinesSing = CoolUtil.coolTextFile(Paths.txt('trickySingStrings'));

		whiteflash = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 100), Std.int(FlxG.height * 100), FlxColor.WHITE);
		whiteflash.scrollFactor.set();

		blackScreen = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 100), Std.int(FlxG.height * 100), FlxColor.BLACK);
		blackScreen.scrollFactor.set();
	
		trace('INFORMATION ABOUT WHAT U PLAYIN WIT:\nFRAMES: ' + Conductor.safeFrames + '\nZONE: ' + Conductor.safeZoneOffset + '\nTS: ' + Conductor.timeScale + '\nBotPlay : ' + FlxG.save.data.botplay);
	
		//dialogue shit. disabled for now. might re add in the future.
		switch (songLowercase)
		{
			/*case 'tutorial':
				dialogue = ["Hey you're pretty cute.", 'Use the arrow keys to keep up \nwith me singing.'];
			case 'bopeebo':
				dialogue = [
					'HEY!',
					"You think you can just sing\nwith my daughter like that?",
					"If you want to date her...",
					"You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = ["Not too shabby boy.", ""];
			case 'dadbattle':
				dialogue = [
					"gah you think you're hot stuff?",
					"If you can beat me here...",
					"Only then I will even CONSIDER letting you\ndate my daughter!"
				];
			case 'senpai' | 'roses' | 'thorns' | 'whittyvssarv' | 'gun-buddies' | 'battle': 
				dialogue = CoolUtil.coolTextFile(Paths.txt(songLowercase+'/'+songLowercase+'Dialogue'));
			case 'ballistic':
				dialogue = CoolUtil.coolTextFile(Paths.txt('ballistic/startDialogue'));
				extra2 = CoolUtil.coolTextFile(Paths.txt('ballistic/afterCutsceneDialogue'));	
				extra3 = CoolUtil.coolTextFile(Paths.txt('ballistic/endDialogue'));	*/		
			default:
				if (FileSystem.exists(Paths.txt(songLowercase  + "/dialogue")))
				{
					dialogue = CoolUtil.coolTextFile2(Paths.txt(songLowercase+"/dialogue"));	

					if (FileSystem.exists(Paths.txt(songLowercase  + "/endDialogue")))
						extra3 = CoolUtil.coolTextFile2(Paths.txt(songLowercase+'/endDialogue'));
				}
				else
					hasDialogue = false;	
		}

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

		Stage = new Stage(stageCheck);
		defaultCamZoom = Stage.camZoom;
		curStage = Stage.curStage;
		usesStageHx = true;

		for (i in Stage.toAdd)
			add(i);

		#if debug
		if (isLullaby)
		{
			lolText = new FlxText(0, 0, FlxG.width - 100, "0", 48);
			lolText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			lolText.cameras = [camOther];
			add(lolText);
		}
		#end

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

		if (FileSystem.exists(Paths.txt(songLowercase  + "/arrowSwitches" + suf)) && !(isBETADCIU && storyDifficulty == 5))
			changeArrows = true;

		/*if (FileSystem.exists(Paths.txt(songLowercase  + "/preload-stage"+suf)) && !customLoaded) // the loading screen should load this
		{
			var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload-stage"+suf));

			for (i in 0...characters.length)
			{
				var data:Array<String> = characters[i].split(' ');
				PreloadStage = new PreloadStage(data[0], true);
				trace ('stages are ' + data[0]);
			}

			curStage = SONG.stage;
		}*/

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

		dad = new Character(100, 100, SONG.player2);
		//trace('found dad character');

		/*if (duoDad)
		{
			switch (SONG.song.toLowerCase())
			{
				case 'epiphany':
					if (storyDifficulty == 5) 
						dad1 = new Character(16, -140, 'bigmonika');
				case 'haachama-ex':
					dad1 = new Character(16, -140, 'amor-ex');
				case 'spectral-spat':
					dad1 = new Character(-100, 100, 'garcellodead');
			}				
		}*/

		var camPos:FlxPoint;

		if (gf.getGraphicMidpoint().x <= -1000 || gf.getGraphicMidpoint().x >= 1500)
			camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);
		else
			camPos = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
			
		switch (SONG.player2)
		{
			case 'gf' | 'gf-crucified' | 'gf1' | 'gf2' | 'gf3' | 'gf4' | 'gf5':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}
			case 'tordbot':
				dad.x += 330;
				dad.y -= 1524.75;
				camPos.set(391.2, -1094.15);
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
		//trace('found boyfriend character');

		dadTrail = new DeltaTrail(dad, null, 4, 12 / 60, 0.25, 0.069);
		dadTrail.active = false;
		dadTrail.color = FlxColor.fromString('#' + dad.trailColor);
		add(dadTrail);

		bfTrail = new DeltaTrail(boyfriend, null, 4, 12 / 60, 0.25, 0.069);
		bfTrail.active = false;
		bfTrail.color = FlxColor.fromString('#' + boyfriend.trailColor);
		add(bfTrail);

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'neon':
				dad.scale.set(0.85, 0.85);
				boyfriend.scale.set(0.86, 0.86);
				gf.scale.set(0.86, 0.86);
				dad.x += 250;
				dad.y += 150;
				boyfriend.x += 100;
			
			case 'schoolEvil' | 'schoolEvild4':
				evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				add(evilTrail);

				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;

			case 'curse':
				boyfriend.setZoom(1.1);
				if (!dad.curCharacter.contains('tabi'))
					dad.setZoom(1.1);
				if (curSong == 'Their-Battle')
					gf.setZoom(1.2);
				else
					gf.setZoom(1.1);

				boyfriend.x += 300;
				dad.x -= 400;
				gf.y -= 110;
				gf.x -= 50;

			case 'day':
				boyfriend.x += Stage.bfXOffset;
				boyfriend.y += Stage.bfYOffset;
				dad.x += Stage.dadXOffset;
				dad.y += Stage.dadYOffset;
				gf.x += Stage.gfXOffset;
				gf.y += Stage.gfYOffset;
				camPos.x = 536.63;
				camPos.y = 449.94;
			case 'hallway':
				camPos.x = 1176.3;
				camPos.y = 515.87;
				boyfriend.x += 585;
				boyfriend.y += 65;
				gf.x += 180;
				gf.y -= 20;
				dad.x += 17;
				dad.y += 63;
				gf.color = FlxColor.fromHSL(gf.color.hue, gf.color.saturation, 0.5, 1);
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

		add(gf);

		/*if (SONG.song.toLowerCase() == 'casanova' && dad.curCharacter == 'selever'){
			blackScreen = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 100), Std.int(FlxG.height * 100), FlxColor.BLACK);
			blackScreen.scrollFactor.set();
			blackScreen.alpha = 0;
			add(blackScreen);

			circ1 = new FlxSprite(dad.x-200,dad.y - 150).loadGraphic(Paths.image('sacredmass/churchselever/circ'));
			circ1.setGraphicSize(Std.int(circ1.width * 0.5));
			circ1.alpha = 0;
			add(circ1);
		}*/

		if (usesStageHx)
		{
			for (index => array in Stage.layInFront)
			{
				switch (index)
				{
					case 0:
						for (bg in array)
							add(bg);
				}
			}
		}

		add(dad);

		if (usesStageHx)
		{
			for (index => array in Stage.layInFront)
			{
				switch (index)
				{
					case 1:
						for (bg in array)
							add(bg);
				}
			}
		}

		if (SONG.player2 == 'exTricky')
			add(dad.exSpikes);

		add(boyfriend);

		if (usesStageHx)
		{
			for (index => array in Stage.layInFront)
			{
				switch (index)
				{
					case 2:
						for (bg in array)
							add(bg);
				}
			}
		}

		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);

		/*switch (curStage)
		{
			case 'polus' | 'reactor' | 'reactor-m':
				flashSprite.alpha = 0;
				flashSprite.scrollFactor.set(0,0);
				flashSprite.screenCenter();
				add(flashSprite);
			case 'street3':
				if (SONG.song.toLowerCase() == 'really-happy' && dad.curCharacter.contains('yuri-crazy')) {
					blackScreen = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					blackScreen.scrollFactor.set();
					add(blackScreen);
				
					eyes = new FlxSprite(0, 0).loadGraphic(Paths.image('doki/eyes1'));
					eyes.cameras = [camHUD];
					eyes.antialiasing = true;
					add(eyes);
		
					eyes2 = new FlxSprite(0, 0).loadGraphic(Paths.image('doki/eyes2'));
					eyes2.cameras = [camHUD];
					eyes2.antialiasing = true;
					add(eyes2);
					
					if (!executeModchart) {
						eyes.alpha = 0;
						eyes2.alpha = 0;
						blackScreen.alpha = 0;
					}
				} 
		}

		switch (songLowercase)
		{
			case 'you-cant-run':
				if (isBETADCIU && storyDifficulty == 5)
				{
					vg = new FlxSprite().loadGraphic(Paths.image('sonic/exe/RedVG'), true, 1280, 720);
					vg.animation.add('red', [0]);
					vg.animation.add('gray', [1]);
					vg.animation.play('red');
					vg.alpha = 0;
					vg.cameras = [camOther];
					add(vg);
				}	
		}*/

		if (loadRep)
		{
			FlxG.watch.addQuick('rep rpesses',repPresses);
			FlxG.watch.addQuick('rep releases',repReleases);
			
			FlxG.save.data.botplay = true;
			FlxG.save.data.scrollSpeed = rep.replay.noteSpeed;
			FlxG.save.data.downscroll = rep.replay.isDownscroll;
			// FlxG.watch.addQuick('Queued',inputsQueued);
		}

		if (hasDialogue) //cuz like I don't want to have the portraits load on songs with no dialogue
		{
			doof = new DialogueBox(false, dialogue);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
	
			doof2 = new DialogueBox(false, dialogue);
			doof2.scrollFactor.set();
			doof2.finishThing = doPicoCutscene;
	
			doof3 = new DialogueBox(false, extra2);
			doof3.scrollFactor.set();
			doof3.finishThing = startCountdown;
	
			doof4 = new DialogueBox(false, extra3);
			doof4.scrollFactor.set();
			doof4.finishThing = endSong;
		}

		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();
		
		if (FlxG.save.data.downscroll)
			strumLine.y = FlxG.height - 165;

		if (FlxG.save.data.psychUI)
		{
			timeTxt = new FlxText(50 + (FlxG.width / 2) - 248, 19, 400, "", 32);
			timeTxt.screenCenter(X);
			timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.scrollFactor.set();
			timeTxt.alpha = 0;
			timeTxt.borderSize = 2;
			if(FlxG.save.data.downscroll) timeTxt.y = FlxG.height - 44;
	
			/*if(ClientPrefs.timeBarType == 'Song Name')
			{
				timeTxt.text = SONG.song;
			}*/
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
	
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		switch (songLowercase) //cuz weird camera moving thingy
		{
			case 'you-cant-run': FlxG.camera.follow(camFollow, LOCKON, 0.06 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));	
			case 'four-way-fracture': FlxG.camera.follow(camFollow, LOCKON, 0.12 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
			case 'omnipresent': FlxG.camera.follow(camFollow, LOCKON, 0.08 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
			default: FlxG.camera.follow(camFollow, LOCKON, camFollowSpeed * (30 / (cast (Lib.current.getChildAt(0), Main)).getFPS()));			
		}
	
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;

		FlxG.camera.focusOn(camFollow.getPosition());
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		if (FlxG.save.data.songPosition) // I dont wanna talk about this code :(
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
			case 'storm': healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBarWhite'));
			case 'hunger' | 'aspirer': healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBarStarv'));
			case 'deathmatch-holo': healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBarCorrupt'));
			default: healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar')); 
		}

		if (FlxG.save.data.psychUI)
			healthBarBG.y = FlxG.height * 0.89;
		
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
			/*case 'garStage' | 'garStageDead' | 'garStageRise':
				healthBar.createFilledBar(0xFF8E40A5, 0xFF66FF33);
				defaultBar = false;	
			case 'hungryhippo' | 'hungryhippo-blantad':
				healthBar.createFilledBar(0xFF6495ED, 0xFF66FF33);
				defaultBar = false;	
			case 'street1' | 'street2' | 'street3':
				healthBar.createFilledBar(0xFF373737, 0xFF808080);	
				defaultBar = false;	
			case 'emptystage2':
				healthBar.createFilledBar(0xFF000000, 0xFF000000);
				defaultBar = false;	*/
			default:
				healthBar.createFilledBar(FlxColor.fromString('#' + dad.iconColor), FlxColor.fromString('#' + boyfriend.iconColor));				
		}	

		add(healthBar);

		replayTxt = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 75, healthBarBG.y + (FlxG.save.data.downscroll ? 100 : -100), 0, "REPLAY", 20);
		replayTxt.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		replayTxt.scrollFactor.set();
		if (loadRep)
		{
			add(replayTxt);
		}
		// Literally copy-paste of the above, fu

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		if (FlxG.save.data.psychUI)
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

		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];

		if (FlxG.save.data.psychUI)
		{
			timeBar.cameras = [camHUD];
			timeBarBG.cameras = [camHUD];
			timeTxt.cameras = [camHUD];
		}

		if (hasDialogue)
		{
			doof.cameras = [camHUD];
			doof2.cameras = [camHUD];
			doof3.cameras = [camHUD];
			doof4.cameras = [camHUD];
		}
	
		if (FlxG.save.data.songPosition)
		{
			songPosBG.cameras = [camHUD];
			songPosBar.cameras = [camHUD];
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

		if (loadRep)
			replayTxt.cameras = [camHUD];

		startingSong = true;

		/*if (curStage == 'motherland' || curStage == 'concert')
		{
			add(tstatic);
			tstatic.alpha = 0;
			tstatic.setGraphicSize(Std.int(tstatic.width * 12));
			tstatic.x += 600;

			if (curStage == 'concert')
				tstatic.y += 300;
		}*/
		
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

		if (luaArray.length >= 1)
		{
			callOnLuas('start', []);			
			callOnLuas('onCreate', []); //psych	
		}
		
		if (executeModchart && isDetected)
		{
			//new LuaCamera(camGame, "camGame").Register(ModchartState.instance.lua);
			//new LuaCamera(camHUD, "camHUD").Register(ModchartState.instance.lua);
			//new LuaCamera(camNotes, "camNotes").Register(ModchartState.instance.lua);
		}

		if (Stage.isCustomStage && Stage.luaArray.length >= 1)
			Stage.callOnLuas('onCreatePost', []);	

		if (isStoryMode || showCutscene)
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
				/*case 'senpai' | 'thorns' | 'whittyvssarv' | 'battle' | 'gun-buddies' | 'tutorial' | 'bopeebo' | 'fresh' | 'dadbattle':
					schoolIntro(doof);
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'ballistic':
					changeDadCharacter(60, 400, 'pico');
					picoIntro(doof2);
				case 'lore':
					playCutscene('shiftcomplete');
					toggleHealthShit(true);
					add(blackScreen);*/
				default:
					regularIntro(songLowercase);
			}
		}
		else
			regularIntro(songLowercase);	

		if (!loadRep)
			rep = new Replay("na");

		if(SONG.song.toLowerCase() == 'reactor') {
		//	camFollow.setPosition(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y - 100);
		}
	
		super.create();

		CustomFadeTransition.nextCamera = camOther;

		/*if (SONG.player2.contains('hypno'))
		{
			pendulum = new Pendulum();
			
			if (SONG.player2 == 'hypno') {
				pendulumShadow = new FlxTypedGroup<FlxSprite>();
				
				pendulum.frames = Paths.getSparrowAtlas('hypno/Pendelum', 'shared');
				pendulum.animation.addByPrefix('idle', 'Pendelum instance 1', 24, true);
				pendulum.animation.play('idle');
				pendulum.antialiasing = true; // fuck you ASH
				
				pendulum.scale.set(1.3, 1.3);
				pendulum.updateHitbox();
				pendulum.origin.set(65, 0);
				pendulum.angle = -9;
				add(pendulumShadow);
				add(pendulum);

				tranceActive = true;

				
			}
		}*/
	}

	function regularIntro(song:String)
	{
		switch (song)
		{
			case 'expurgation':
				if (dad.curCharacter != 'exTricky')
				{
					dad.visible = false;
	
					camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					var spawnAnim = new FlxSprite(dad.x - 575, dad.y - 232);
					spawnAnim.frames = Paths.getSparrowAtlas('characters/CJCLONEENTER');
	
					spawnAnim.animation.addByPrefix('start','Entrance',24,false);
	
					add(spawnAnim);
	
					spawnAnim.animation.play('start');
					var p = new FlxSound().loadEmbedded(Paths.sound("tricky/fourth/Trickyspawn", 'shared'));
					var pp = new FlxSound().loadEmbedded(Paths.sound("tricky/fourth/TrickyGlitch", 'shared'));
					p.play();
					spawnAnim.animation.finishCallback = function(pog:String)
						{
							pp.fadeOut();
							dad.visible = true;
							remove(spawnAnim);
							startCountdown();
						}
					new FlxTimer().start(0.001, function(tmr:FlxTimer)
						{
							if (spawnAnim.animation.frameIndex == 24)
							{
								pp.play();
							}
							else
								tmr.reset(0.001);
						});
				}
				else
				{
					dad.visible = false;
					camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					var spawnAnim = new FlxSprite(-150,-380);
					spawnAnim.frames = Paths.getSparrowAtlas('characters/EXTRICKYENTER','shared');
	
					spawnAnim.animation.addByPrefix('start','Entrance',24,false);
	
					add(spawnAnim);
	
					spawnAnim.animation.play('start');
					var p = new FlxSound().loadEmbedded(Paths.sound("tricky/fourth/Trickyspawn", 'shared'));
					var pp = new FlxSound().loadEmbedded(Paths.sound("tricky/fourth/TrickyGlitch", 'shared'));
					p.play();
					spawnAnim.animation.finishCallback = function(pog:String)
						{
							pp.fadeOut();
							dad.visible = true;
							remove(spawnAnim);
							startCountdown();
						}
					new FlxTimer().start(0.001, function(tmr:FlxTimer)
						{
							if (spawnAnim.animation.frameIndex == 24)
							{
								pp.play();
							}
							else
								tmr.reset(0.001);
						});
				}
			case 'killer-scream':
				toggleHealthShit(true);
				startCountdown();
			/*case 'endless' | 'triple-trouble' | 'you-cant-run' | 'four-way-fracture':
				if (!(SONG.song.toLowerCase() == 'you-cant-run' && isBonus)) //so it doesn't play on my you can't run
				{
					var suf:String = "";
					switch (song)
					{
						case 'endless': suf = 'Majin';
						case 'triple-trouble' | 'four-way-fracture': suf = 'TripleTrouble';
						case 'you-cant-run': suf = 'YouCantRun';
					}
					
					doSonicIntro(suf, true);
					startCountdown();
				}	
				if (SONG.song.toLowerCase() == 'you-cant-run' && isBonus)
					startCountdown();*/		
			default:
				startCountdown();
		}	
	}

	public function doStopSign(sign:Int = 0, fuck:Bool = false)
	{
		trace('sign ' + sign);
		daSign = new FlxSprite(0,0);

		daSign.frames = Paths.getSparrowAtlas('madness/tricky/fourth/mech/Sign_Post_Mechanic');

		daSign.setGraphicSize(Std.int(daSign.width * 0.67));

		daSign.cameras = [camHUD];

		switch(sign)
		{
			case 0:
				daSign.animation.addByPrefix('sign','Signature Stop Sign 1',24, false);
				daSign.x = FlxG.width - 650;
				daSign.angle = -90;
				daSign.y = -300;
			case 1:
				/*daSign.animation.addByPrefix('sign','Signature Stop Sign 2',20, false);
				daSign.x = FlxG.width - 670;
				daSign.angle = -90;*/ // this one just doesn't work???
			case 2:
				daSign.animation.addByPrefix('sign','Signature Stop Sign 3',24, false);
				daSign.x = FlxG.width - 780;
				daSign.angle = -90;
				if (FlxG.save.data.downscroll)
					daSign.y = -395;
				else
					daSign.y = -980;
			case 3:
				daSign.animation.addByPrefix('sign','Signature Stop Sign 4',24, false);
				daSign.x = FlxG.width - 1070;
				daSign.angle = -90;
				daSign.y = -145;
		}
		add(daSign);
		daSign.flipX = fuck;
		daSign.animation.play('sign');
		daSign.animation.finishCallback = function(pog:String)
			{
				trace('ended sign');
				remove(daSign);
			}
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
		var textState = new TextSubState(realTimer, word);
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

	public function fixTrailShit(id:String):Void 
	{
		switch (id)
		{
			case 'dadTrail':
				dadTrail.destroy();
				dadTrail = new DeltaTrail(dad, null, 4, 12 / 60, 0.25, 0.069);
				dadTrail.active = false;
				dadTrail.color = FlxColor.fromString('#' + dad.trailColor);
				insert(members.indexOf(dad), dadTrail);
			case 'bfTrail':
				bfTrail.destroy();
				remove(boyfriend);
				bfTrail = new DeltaTrail(boyfriend, null, 4, 12 / 60, 0.25, 0.069);
				bfTrail.active = false;
				bfTrail.color = FlxColor.fromString('#' + boyfriend.trailColor);
				add(bfTrail);
				add(boyfriend);
			case 'tabiTrail':
				tabiTrail = new FlxTrail(dad, null, 4, 24, 0.6, 0.9);
				add(tabiTrail);
			case 'dadTrail-super':
				dadTrail.destroy();
				remove(dad);
				dadTrail = new DeltaTrail(dad, null, 4, 12 / 60, 0.25, 0.069);
				dadTrail.active = false;
				dadTrail.color = FlxColor.fromString('#' + dad.trailColor);
				add(dadTrail);
				add(dad);
		}
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
			boyfriend.stunned = true;

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

			if (luaArray.length >= 1)
				callOnLuas('onGameOver', []); //psych	

			openSubState(new GameOverSubstate(daX, daY));

			#if windows
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("GAME OVER -- " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy),"\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
			#end
		}		
	}

	public var luaArray:Array<ModchartState> = [];
	public static var pushedLuas:Array<ModchartState> = [];
	public var closeLuas:Array<ModchartState> = [];

	public static var startCharLuas:Array<String> = [];

	public function getLuaObject(tag:String, ?text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(modchartInputTexts.exists(tag)) return modchartInputTexts.get(tag);
		if(modchartIcons.exists(tag)) return modchartIcons.get(tag);
		if(modchartCharacters.exists(tag)) return modchartCharacters.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		return null;
	}


	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = ModchartState.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == ModchartState.Function_StopLua && !ignoreStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == ModchartState.Function_Continue;
			if(!bool) {
				returnVal = cast ret;
			}
		}
		#end
		//trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if windows
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
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
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					case 'dad':
						char = dad;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2))
						{
							var obj:Dynamic = value2;
							var value2:Character = obj;
							char = obj;
						} 
		
						switch(val2) {
							case 0: char = dad;
							case 1: char = boyfriend;
							case 2: char = gf;
						}
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

				camFollowIsOn = true;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					camFollowIsOn = false;
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
			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1) {
					ModchartState.setVarInArray(ModchartState.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					ModchartState.setVarInArray(this, value1, value2);
				}
			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch (charType){
					case 0: ModchartState.changeBFAuto(value2);	
					case 1: ModchartState.changeDadAuto(value2);
					case 2: ModchartState.changeGFAuto(value2);
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);

		if (Stage.isCustomStage && Stage.luaArray.length >= 1)
			Stage.callOnLuas('onEvent', [eventName, value1, value2]);	
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function startCharacterLua(name:String)
	{
		#if desktop
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
				if(modchartSprites.exists(cam))
					Reflect.setProperty(modchartSprites.get(cam),"shader",effect.shader);
				else if(modchartIcons.exists(cam))
					Reflect.setProperty(modchartIcons.get(cam),"shader",effect.shader);
				else if(modchartTexts.exists(cam))
					Reflect.setProperty(modchartTexts.get(cam),"shader",effect.shader);
				else if(modchartCharacters.exists(cam))
					Reflect.setProperty(modchartCharacters.get(cam),"shader",effect.shader);
				else {
					var OBJ = Reflect.getProperty(PlayState.instance,cam);
					Reflect.setProperty(OBJ,"shader", effect.shader);
				}		
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
		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud': 
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other': 
				camOtherShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camGame.setFilters(newCamEffects);
			default: 
				if(modchartSprites.exists(cam))
					Reflect.setProperty(modchartSprites.get(cam),"shader",null);
				else if(modchartIcons.exists(cam))
					Reflect.setProperty(modchartIcons.get(cam),"shader",null);
				else if(modchartTexts.exists(cam))
					Reflect.setProperty(modchartTexts.get(cam),"shader",null);
				else if(modchartCharacters.exists(cam))
					Reflect.setProperty(modchartCharacters.get(cam),"shader",null);
				else {
					var OBJ = Reflect.getProperty(PlayState.instance,cam);
					Reflect.setProperty(OBJ,"shader", null);
				}		
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

	function changeDadCharacter(x:Float, y:Float, character:String)
	{
		dad.destroy();
		dad = new Character(x, y, character);
		add(dad);
		iconP2.useOldSystem(dad.healthIcon);

		if (defaultBar)
		{
			healthBar.createFilledBar(FlxColor.fromString('#' + dad.iconColor), FlxColor.fromString('#' + boyfriend.iconColor));
			healthBar.updateBar();
		}
	}

	function changeGFCharacter(x:Float, y:Float, character:String)
	{
		gf.destroy();
		gf = new Character(x, y, character);
		gf.scrollFactor.set(0.95, 0.95);
		add(gf);
	}

	function changeBoyfriendCharacter(x:Float, y:Float, character:String)
	{
		boyfriend.destroy();
		boyfriend = new Boyfriend(x, y, character);
		add(boyfriend);
		iconP1.useOldSystem(boyfriend.healthIcon);

		if (defaultBar)
		{
			healthBar.createFilledBar(FlxColor.fromString('#' + dad.iconColor), FlxColor.fromString('#' + boyfriend.iconColor));
			healthBar.updateBar();
		}
	}

	function corruptBG(id:String)
	{
		switch (id)
		{
			case 'corrupt':
				Stage.swagBacks['bgSkyEvil'].alpha = 1;
				Stage.swagBacks['bgSchoolEvil'].alpha = 1;
				Stage.swagBacks['fgTreesEvil'].alpha = 1;
				Stage.swagBacks['bgStreetEvil'].alpha = 1;
				Stage.swagBacks['bgTrees'].alpha = 0;	
			case 'normal':
				Stage.swagBacks['bgSkyEvil'].alpha = 0;
				Stage.swagBacks['bgSchoolEvil'].alpha = 0;
				Stage.swagBacks['fgTreesEvil'].alpha = 0;
				Stage.swagBacks['bgStreetEvil'].alpha = 0;
				Stage.swagBacks['bgTrees'].alpha = 1;			
		}
	}

	function doFloatShit()
	{
		doingFloatShit = true;
		
		tween = FlxTween.linearMotion(dad, dad.x, dad.y, dad.x, dad.y - 100, 2, true, {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
	}

	function doBFFloatShit()
	{
		doingBoyfriendFloatShit = true;
		
		tween = FlxTween.linearMotion(boyfriend, boyfriend.x, boyfriend.y, boyfriend.x, boyfriend.y - 100, 2, true, {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
	}

	function doPicoCutscene():Void
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
	}

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

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 5, FlxG.height * 5, FlxColor.BLACK);
		black.scrollFactor.set();
		black.screenCenter();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy', 'week6');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase() == 'roses' || StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase() == 'thorns')
		{
			remove(black);

			if (StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase() == 'thorns')
				add(red);
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase() == 'thorns')
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
						add(dialogueBox);
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function picoIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		strumLineNotes.visible = false;
		scoreTxt.visible = false;
		healthBarBG.visible = false;
		healthBar.visible = false;
		iconP1.visible = false;
		iconP2.visible = false;

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);

		wind.fadeIn();

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;
					wind.fadeOut();
					add(dialogueBox);
				}
				else
					doPicoCutscene();

				remove(black);
			}
		});
	}

	function picoIntroPart2(?dialogueBox:DialogueBox):Void
	{
		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			if (dialogueBox != null)
			{
				inCutscene = true;
				wind.fadeOut();
				add(dialogueBox);
			}
			else
				startCountdown();
		});
	}

	function picoEnd(?dialogueBox:DialogueBox):Void
	{
		persistentUpdate = false;

		changeBoyfriendCharacter(875, 400, 'bf-cesar');

		camHUD.zoom = 0;

		var botan:FlxSprite = new FlxSprite(dad.x - 220, dad.y - 50);
		botan.frames = Paths.getSparrowAtlas('whitty/lmaoBotan');
		botan.animation.addByPrefix('idle', 'Pico Worried', 24, false);
		botan.flipX = true;
		add(botan);

		var pico:FlxSprite = new FlxSprite(dad.x + 220, dad.y - 20);
		pico.frames = Paths.getSparrowAtlas('whitty/lmaoPico');
		pico.animation.addByPrefix('idle', 'Pico Look Down', 24, false);
		add(pico);

		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		strumLineNotes.visible = false;
		scoreTxt.visible = false;
		healthBarBG.visible = false;
		healthBar.visible = false;
		iconP1.visible = false;
		iconP2.visible = false;
		dad.visible = false;
		picoCutscene = true;

		camZooming = false;
		inCutscene = true;
		startedCountdown = false;
		generatedMusic = false;
		canPause = false;

		wBg.alpha = 1;
		wstageFront.alpha = 1;

		camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);

		wind.fadeIn();

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				new FlxTimer().start(1, function(swagtmr:FlxTimer)
				{
					if (dialogueBox != null)
					{
						inCutscene = true;
						wind.fadeOut();
						add(dialogueBox);
					}
					else
					{
						endSong();
					}
				});
				remove(black);
			}
		});
	}

	public var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	var luaWiggles:Array<WiggleEffect> = [];

	#if windows
	public static var luaModchart:ModchartState = null;
	#end

	var daStartAlpha:Float = 1;
	var ready:FlxSprite;
	var set:FlxSprite;
	var go:FlxSprite;

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

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	public function startCountdown():Void
	{
		if (!stopCountdown)
		{
			inCutscene = false;

			/*if (curStage == 'cgstage')
			{
				FlxTween.tween(Stage.c1, {alpha: 1}, 1, {
					startDelay: 0.2,
					ease: FlxEase.linear});
			}*/
				
			if (songLowercase == 'Ballistic' && showCutscene == true)
			{
				strumLineNotes.visible = true;
				scoreTxt.visible = true;
				healthBarBG.visible = true;
				healthBar.visible = true;
				iconP1.visible = true;
				iconP2.visible = true;
			}

			/*if (dad.curCharacter == 'zardy')
			{
				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					if (dad.alpha != 1)
					{
						dad.alpha += 0.1;
						tmr.reset(0.1);
					}
				});
			}*/

			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;			

			generateStaticArrows(0, dad.noteSkin, !skipArrowStartTween, daStartAlpha);
			generateStaticArrows(1, boyfriend.noteSkin, !skipArrowStartTween, daStartAlpha);	
		
			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;

			var swagCounter:Int = 0;

			if (luaArray.length >= 1)
				callOnLuas('onStartCountdown', []);	

			if (Stage.isCustomStage && Stage.luaArray.length >= 1)
				Stage.callOnLuas('onStartCountdown', []);	

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

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				dad.dance();
				gf.dance();
				boyfriend.dance();

				if (modchartCharacters != [])
				{
					for (value in modchartCharacters.keys())
					{
						daChar = modchartCharacters.get(value);
						
						daChar.dance();
					}
				}

				/*switch (curStage)
				{
					case 'mallSoft':
						Stage.swagBacks['momDadBG'].animation.play('idle');
						Stage.swagBacks['softBFBG'].animation.play('idle');
						Stage.swagBacks['gfBG'].dance();
				}*/

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', "set", "go"]);

				if (usesStageHx)
					introAssets.set(curStage, Stage.introAssets);

				var introAlts:Array<String> = introAssets.get('default');
				var altSuffix:String = "";

				for (value in introAssets.keys())
				{
					if (value == curStage)
					{
						introAlts = introAssets.get(value);

						if (usesStageHx && Stage.altSuffix != '')
							altSuffix = Stage.altSuffix;
						else
							altSuffix = '';
					}
				}

				#if MODS_ALLOWED
				if (!FileSystem.exists(Paths.modsSounds('sounds', 'intro3'+altSuffix)) && !FileSystem.exists(Paths.sound('intro3'+altSuffix))) {
				#else
				if (!OpenFlAssets.exists(Paths.sound('intro3'+altSuffix))) {
				#end
					altSuffix = '';
				}

				
				switch (swagCounter)
				{
					case 0:
						switch (curStage) {
							default:
								FlxG.sound.play(existsInCTS('intro3' + altSuffix), 0.6);
						}
						switch (curStage) {
							case 'day' | 'sunset' | 'night':
								var three:FlxSprite = new FlxSprite().loadGraphic(Paths.image('b&b/3', 'shared'));
								three.scrollFactor.set();
								three.screenCenter();
								add(three);
								FlxTween.tween(three, {y: three.y += 100, alpha: 0}, Conductor.crochet / 1000, {
									ease: FlxEase.cubeInOut,
									onComplete: function(twn:FlxTween)
									{
										three.destroy();
									}
								});
							default:
								'';
						}
					case 1:
						ready = new FlxSprite().loadGraphic(existsInCTA(introAlts[0]));
						ready.scrollFactor.set();
						ready.updateHitbox();
	
						if (curStage.startsWith('school') || pixelStages.contains(curStage))
							ready.setGraphicSize(Std.int(ready.width * daPixelZoom));
	
						if (curStage == 'DorklyHill')
							ready.cameras = [camHUD];

						ready.screenCenter();
						add(ready);
						FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								ready.destroy();
							}
						});
						switch (curStage) {
							default:
								FlxG.sound.play(existsInCTS('intro2' + altSuffix), 0.6);
						}
					case 2:
						set = new FlxSprite().loadGraphic(existsInCTA(introAlts[1]));
						set.scrollFactor.set();
	
						if (curStage.startsWith('school') || pixelStages.contains(curStage))
							set.setGraphicSize(Std.int(set.width * daPixelZoom));

						if (curStage == 'DorklyHill')
							set.cameras = [camHUD];
	
						set.screenCenter();
						add(set);
						FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								set.destroy();
							}
						});
						switch (curStage) {
							default:
								FlxG.sound.play(existsInCTS('intro1' + altSuffix), 0.6);
						}
					case 3:
						go = new FlxSprite().loadGraphic(existsInCTA(introAlts[2]));
						go.scrollFactor.set();
	
						if (curStage.startsWith('school') || pixelStages.contains(curStage))
							go.setGraphicSize(Std.int(go.width * daPixelZoom));
	
						if (curStage == 'DorklyHill')
							go.cameras = [camHUD];

						go.updateHitbox();
	
						go.screenCenter();
						add(go);
						FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								go.destroy();
							}
						});
						switch (curStage) {
							default:
								FlxG.sound.play(existsInCTS('introGo' + altSuffix), 0.6);
						}
						/*if (SONG.song.toLowerCase() == "casanova" && dad.curCharacter == 'selever') 
						{
							circ1.alpha = 1;
							FlxTween.tween(circ1, {angle: 360, alpha: 0, "scale.x":1, "scale.y":1, x: dad.x-100, y:dad.y}, 2.5, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									remove(circ1);
								}
							});
							
							FlxTween.tween(blackScreen, {alpha: 0.7}, 0.5, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									FlxTween.tween(blackScreen, {alpha: 0}, 0.5, {
									ease: FlxEase.cubeInOut,
									onComplete: function(twn:FlxTween)
										{
											blackScreen.destroy();
										}
									});
								}
							});
							FlxTween.tween(FlxG.camera, {zoom: 1.2}, 0.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.9, {
										ease: FlxEase.quadInOut,
									});
								}
							});
							dad.playAnim('hey');
						}*/
					}

				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
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
			}

			if (SONG.song.toLowerCase() == 'killer-scream')
				startTimer.finished = true;*/
		}
	}

	public function softCountdown(?style:String):Void
	{
		inCutscene = false;

		var dankCounter:Int = 0;

		var dankTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);

			if (usesStageHx)
				introAssets.set(curStage, Stage.introAssets);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			for (value in introAssets.keys())
			{
				if (value == curStage)
				{
					introAlts = introAssets.get(value);

					if (usesStageHx && Stage.altSuffix != '')
						altSuffix = Stage.altSuffix;
					else
						altSuffix = '';
				}
			}

			#if MODS_ALLOWED
			if (!FileSystem.exists(Paths.modsSounds('sounds', 'intro3'+altSuffix)) && !FileSystem.exists(Paths.sound('intro3'+altSuffix))) {
			#else
			if (!OpenFlAssets.exists(Paths.sound('intro3'+altSuffix))) {
			#end
				altSuffix = '';
			}
			
			switch (dankCounter)
			{
				case 0:
					switch (curStage) {
						default:
							FlxG.sound.play(existsInCTS('intro3' + altSuffix), 0.6);
					}
					switch (curStage) {
						case 'day' | 'sunset' | 'night':
							var three:FlxSprite = new FlxSprite().loadGraphic(Paths.image('b&b/3', 'shared'));
							three.scrollFactor.set();
							three.screenCenter();
							add(three);
							FlxTween.tween(three, {y: three.y += 100, alpha: 0}, Conductor.crochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									three.destroy();
								}
							});
						default:
							'';
					}
				case 1:
					ready = new FlxSprite().loadGraphic(existsInCTA(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (curStage.startsWith('school') || pixelStages.contains(curStage))
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					if (curStage == 'DorklyHill')
						ready.cameras = [camHUD];

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					switch (curStage) {
						default:
							FlxG.sound.play(existsInCTS('intro2' + altSuffix), 0.6);
					}
				case 2:
					set = new FlxSprite().loadGraphic(existsInCTA(introAlts[1]));
					set.scrollFactor.set();

					if (curStage.startsWith('school') || pixelStages.contains(curStage))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					if (curStage == 'DorklyHill')
						set.cameras = [camHUD];

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					switch (curStage) {
						default:
							FlxG.sound.play(existsInCTS('intro1' + altSuffix), 0.6);
					}
				case 3:
					go = new FlxSprite().loadGraphic(existsInCTA(introAlts[2]));
					go.scrollFactor.set();

					if (curStage.startsWith('school') || pixelStages.contains(curStage))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					if (curStage == 'DorklyHill')
						go.cameras = [camHUD];

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					switch (curStage) {
						default:
							FlxG.sound.play(existsInCTS('introGo' + altSuffix), 0.6);
					}
					/*if (SONG.song.toLowerCase() == "casanova" && dad.curCharacter == 'selever') 
					{
						circ1.alpha = 1;
						FlxTween.tween(circ1, {angle: 360, alpha: 0, "scale.x":1, "scale.y":1, x: dad.x-100, y:dad.y}, 2.5, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(circ1);
							}
						});
						
						FlxTween.tween(blackScreen, {alpha: 0.7}, 0.5, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								FlxTween.tween(blackScreen, {alpha: 0}, 0.5, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
									{
										blackScreen.destroy();
									}
								});
							}
						});
						FlxTween.tween(FlxG.camera, {zoom: 1.2}, 0.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.9, {
									ease: FlxEase.quadInOut,
								});
							}
						});
						dad.playAnim('hey');
					}*/
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

		
		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;


		if (luaArray.length >= 1) //detected stuff
			callOnLuas('onSongStart', []);	

		/*switch (SONG.song.toLowerCase())
		{
			case 'killer-scream':
				toggleHealthShit(false);
		}*/

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

		FlxG.sound.music.onComplete = songOutro;
		vocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		if (FlxG.save.data.psychUI)
		{
			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}

		if (FlxG.save.data.songPosition)
		{
			remove(songPosBG);
			remove(songPosBar);
			remove(songName);

			songPosBG = new FlxSprite(0, 10).loadGraphic(Paths.image('healthBar'));
			if (FlxG.save.data.downscroll)
				songPosBG.y = FlxG.height * 0.9 + 45; 
			songPosBG.screenCenter(X);
			songPosBG.scrollFactor.set();
			add(songPosBG);

			songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
				'songPositionBar', 0, songLength - 1000);
			songPosBar.numDivisions = 1000;
			songPosBar.scrollFactor.set();
			songPosBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
			add(songPosBar);

			var songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - 20,songPosBG.y,0,SONG.song, 16);
			if (FlxG.save.data.downscroll)
				songName.y -= 3;
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			songName.scrollFactor.set();
			add(songName);

			songPosBG.cameras = [camHUD];
			songPosBar.cameras = [camHUD];
			songName.cameras = [camHUD];
		}
		
		// Song check real quick
		switch(curSong)
		{
			case 'Bopeebo' | 'Philly Nice' | 'Blammed' | 'Cocoa' | 'Eggnog': allowedToHeadbang = true;
			default: allowedToHeadbang = false;
		}
		
		#if windows
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
		#end
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
		{
			if (!Assets.exists(Paths.voices(PlayState.SONG.song)))
			{
				if (Paths.currentTrackedSounds.exists(Paths.voices2(PlayState.SONG.song)))
					vocals = new FlxSound().loadEmbedded(Paths.currentTrackedSounds.get(Paths.voices2(PlayState.SONG.song)));
				else
					vocals = new FlxSound().loadEmbedded(Sound.fromFile(Paths.voices2(PlayState.SONG.song)));
			}
			else
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		}		
		else
			vocals = new FlxSound();

		trace('loaded vocals');

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		// Per song offset check
		#if windows
			// pre lowercasing the song name (generateSong)
			var songPath = 'assets/data/' + songLowercase + '/';
			
			if (FileSystem.exists(songPath))
			{
				for(file in sys.FileSystem.readDirectory(songPath))
				{
					var path = haxe.io.Path.join([songPath, file]);
					if(!sys.FileSystem.isDirectory(path))
					{
						if(path.endsWith('.offset'))
						{
							trace('Found offset file: ' + path);
							songOffset = Std.parseFloat(file.substring(0, file.indexOf('.off')));
							break;
						}else {
							trace('Offset file not found. Creating one @: ' + songPath);
							sys.io.File.saveContent(songPath + songOffset + '.offset', '');
						}
					}
				}
			}
		#end
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

		for (section in noteData)
		{
			var suf:String = "";
			if (isNeonight)
			{
				if (!FlxG.save.data.stageChange)
					suf = '-neo-noStage';				
				else
					suf = '-neo';				
			}

			if (isBETADCIU && storyDifficulty == 5)
			{
				if (!FlxG.save.data.stageChange)
					suf = '-guest-noStage';				
				else
					suf = '-guest';
			}

			/*if (isBETADCIU && storyDifficulty == 5)
			{
				switch (SONG.song.toLowerCase())
				{
					case 'you-cant-run': //setting the different notes and shit
						if (daSection == 17)Note.mickeyNotes = true;
						if (daSection == 25)Note.mickeyNotes = false;
						if (daSection == 73)Note.auditorNotes = true;
						if (daSection == 81)Note.auditorNotes = false;
				}
			}*/
			
			if (FileSystem.exists(Paths.txt(songLowercase  + "/arrowSwitches" + suf)))
			{
				var stuff:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/arrowSwitches" + suf));
	
				for (i in 0...stuff.length)
				{
					var data:Array<String> = stuff[i].split(' ');

					if (daSection == Std.parseInt(data[0]))
					{
						if (data[2] == 'dad')
							SONG.dadNoteStyle = data[1];
						if (data[2] == 'bf')
							SONG.bfNoteStyle = data[1];
					}
				}
			}
			
			var mn:Int = Main.keyAmmo[mania]; //new var to determine max notes
			var coolSection:Int = Std.int(section.lengthInSteps / 4);
			var playerNotes:Array<Int> = [0, 1, 2, 3, 8, 9, 10, 11];

			//trying to use old system with the new mania stuff
			switch (mania)
			{
				case 0:
					playerNotes = [0, 1, 2, 3, 8, 9, 10, 11];
				case 1:
					playerNotes = [0, 1, 2, 3, 4, 5, 12, 13, 14, 15, 16, 17];
				case 2:
					playerNotes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 18, 19, 20, 21, 22, 23, 24, 25, 26];
				case 3:
					playerNotes = [0, 1, 2, 3, 4, 10, 11, 12, 13, 14];
				case 4:
					playerNotes = [0, 1, 2, 3, 4, 5, 6, 14, 15, 16, 17, 18, 19, 20];
			}

			for (songNotes in section.sectionNotes)
			{
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
				var swagNote:Note;

				if (changeArrows)
					swagNote = new Note(daStrumTime, daNoteData, oldNote, false, daType, (gottaHitNote ? SONG.bfNoteStyle : SONG.dadNoteStyle));
				else
					swagNote = new Note(daStrumTime, daNoteData, oldNote, false, daType, (gottaHitNote ? alt2 : alt));

				swagNote.sustainLength = songNotes[2];
				swagNote.noteType = songNotes[3];
				swagNote.scrollFactor.set(0, 0);
				swagNote.dType = section.dType;

				if (swagNote.noteType == 'Special Sing')
					trace(swagNote.noteType);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note;
					if (changeArrows)
						sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, daType, (gottaHitNote ? SONG.bfNoteStyle : SONG.dadNoteStyle));
					else
						sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, daType, (gottaHitNote ? alt2 : alt));
					
					sustainNote.scrollFactor.set();
					sustainNote.dType = section.dType;
					sustainNote.noteType = songNotes[3];

				//	if (sustainNote.noteType == 11)
				//		sustainNote.dType = 1;

					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else
				{
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}

			daSection += 1;
			daBeats += 1;
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

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
		eventNotes.sort(sortByTime);
		}
		checkEventNote();

		generatedMusic = true;
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
			case 'Change Stage':
				PreloadStage = new PreloadStage(event.value1, true);
				trace ('stages are ' + event.value1);

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
				if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

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
			var babyArrow:StrumNote = new StrumNote(50, strumLine.y, i, player, style);
			babyArrow.downScroll = FlxG.save.data.downScroll;
			if (!isStoryMode && tweenShit)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: daAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
				hudArrXPos.push(babyArrow.x);
				hudArrYPos.push(babyArrow.y);
			}
			else
			{
				opponentStrums.add(babyArrow);
				hudArrDadXPos.push(babyArrow.x);
				hudArrDadYPos.push(babyArrow.y);
			}

			if (isMania && SONG.noteStyle != 'exe')
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

			#if windows
			DiscordClient.changePresence("PAUSED on " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "Acc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
			#end
			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
		}

		for (tween in modchartTweens) {
			tween.active = false;
		}
		for (timer in modchartTimers) {
			timer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if windows
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses, iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), iconRPC);
			}
			#end
		}

		for (tween in modchartTweens) {
			tween.active = true;
		}
		for (timer in modchartTimers) {
			timer.active = true;
		}

		super.closeSubState();
	}
	

	public function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();

		#if windows
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC);
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
	var health1:Bool = false;
	var pressedOnce:Bool = false;

	var dadY:Float;

	public function toggleHealthShit(id:Bool) //cuz modcharts don't hide them immediately for some reason
	{
		if (id)
		{
			healthBarBG.visible = false;
			healthBar.visible = false;
			iconP1.visible = false;
			iconP2.visible = false;
			scoreTxt.visible = false;
		}

		if (!id)
		{
			healthBarBG.visible = true;
			healthBar.visible = true;
			iconP1.visible = true;
			iconP2.visible = true;
			scoreTxt.visible = true;
		}
	}

	var healthDrop:Float = 0;
	var rotInd:Int = 0;
	var checkedShaggy:Bool = false;	
	var DAD_X:Float = 0;
	var DAD_Y:Float = 0;
	var addedShit:Bool = false;

	public var currentLuaIndex = 0;

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (usesStageHx)
			Stage.update(elapsed);

		health -= healthDrop;

		if (camFollowSpeed != cameraSpeed*0.04) //well i tried
		{
			FlxG.camera.follow(PlayState.instance.camFollow, LOCKON, (cameraSpeed*0.04) * (30 / (cast (Lib.current.getChildAt(0), Main)).getFPS()));
			camFollowSpeed = (cameraSpeed*0.04);
		}
			
		if (modchartCharacters != [])
		{
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
		}

		switch (SONG.song.toLowerCase())
		{
			case 'senpai':
				if (DialogueBox.curCharacter == 'senpai-angry' && dad.curCharacter != 'senpai-angry')
					changeDadCharacter(250, 460, 'senpai-angry');
				else if (DialogueBox.curCharacter == 'senpai' && dad.curCharacter != 'senpai')
					changeDadCharacter(250, 460, 'senpai');			
			case 'ballistic':
				if (DialogueBox.curCharacter == 'pico-dark' && dad.curCharacter != 'picoCrazy')
					changeDadCharacter(100, 400, 'picoCrazy');
			case 'bi-nb':
				if (chromOn){
		
					ch = FlxG.random.int(1,5) / 1000;
					ch = FlxG.random.int(1,5) / 1000;
					ShadersHandler.setChrome(ch);
					ShadersHandler.setRadialBlur(640+(FlxG.random.int(-10,10)),360+(FlxG.random.int(-10,10)),FlxG.random.float(0.001,0.005));
				}else{
					ShadersHandler.setChrome(0);
					ShadersHandler.setRadialBlur(0,0,0);
					
				}	
		}

		/*switch (curStage)
		{
			case 'pokecenter':
				/*if (!dad.curCharacter.contains('hypno'))
				{
					dad.doMissThing = false;
					dad.color = FlxColor.fromHSL(dad.color.hue, dad.color.saturation, 0.65, 1);
				}
			case 'hallway':
				gf.doMissThing = false;
				gf.color = FlxColor.fromHSL(gf.color.hue, gf.color.saturation, 0.5, 1);
		}*/

		//it's here now. I think I can turn this into a lua? I'll do it 
		var coolTankmen:Array<String> = ['tankman', 'tankman-bw'];
		var noSwapSenpais:Array<String> = ['hd-senpai-dark', 'bf-hd-senpai-dark', 'bf-hd-senpai-worried', 'hd-senpai-happy'];

		/*if (!disableSenTanIcons)
		{
			if (coolTankmen.contains(boyfriend.curCharacter))
			{
				var bwShit:String = "";
	
				switch (boyfriend.curCharacter)
				{
					case 'tankman': bwShit = "";		
					case 'tankman-bw': bwShit = '-bw';		
				}
	
				if (dad.curCharacter.contains('senpai') && !dad.curCharacter.contains('angry') && !dad.curCharacter.contains('ghosty'))
				{
					if (iconP1.animation.name != 'tankman-happy' + bwShit)
						iconP1.useOldSystem('tankman-happy' + bwShit);
				}			
				else
				{
					if (iconP1.animation.name != 'tankman' + bwShit)
						iconP1.useOldSystem('tankman' + bwShit);			
				}							
			}
		
			if (coolTankmen.contains(dad.curCharacter))
			{
				var bwShit:String = "";
	
				switch (dad.curCharacter)
				{
					case 'tankman': bwShit = "";		
					case 'tankman-bw': bwShit = '-bw';		
				}
	
				if (boyfriend.curCharacter.contains('senpai') && !boyfriend.curCharacter.contains('angry') && !boyfriend.curCharacter.contains('ghosty'))
				{
					if (iconP2.animation.name != 'tankman-happy' + bwShit)
						iconP2.useOldSystem('tankman-happy' + bwShit);
				}		
				else 
				{
					if (iconP2.animation.name != 'tankman' + bwShit)
						iconP2.useOldSystem('tankman' + bwShit);	
				}
			}
	
			if (dad.curCharacter.contains('2vplus-senpai') && !noSwapSenpais.contains(dad.curCharacter))
			{
				var bwShit:String = "";
	
				switch (dad.curCharacter)
				{
					case '2vplus-senpai-giddy-bw': bwShit = '-bw';	
					case '2vplus-senpai-giddy-b3' | '2vplus-senpai-angry-b3': bwShit = '-b3';
					case 'hd-senpai-old' | 'hd-senpai-giddy-old': bwShit = '-old';
				}
	
				//if senpai is dad
				if ((boyfriend.curCharacter.contains('tankman') || boyfriend.curCharacter.contains('monika') || boyfriend.curCharacter.contains('aloe') || boyfriend.curCharacter.contains('bf-nene')))
				{
					if (iconP2.animation.name != '2vplus-senpai-giddy' + bwShit)
						iconP2.useOldSystem('2vplus-senpai-giddy' + bwShit);
				}		
				else
				{
					if (iconP2.animation.name != '2vplus-senpai' + bwShit)
						iconP2.useOldSystem('2vplus-senpai' + bwShit);		
				}	
			}
	
			if (boyfriend.curCharacter.contains('2vplus-senpai') && !noSwapSenpais.contains(boyfriend.curCharacter))
			{
				var bwShit:String = "";
	
				switch (boyfriend.curCharacter)
				{
					case '2vplus-senpai-giddy-bw': bwShit = '-bw';	
					case '2vplus-senpai-giddy-b3' | '2vplus-senpai-angry-b3': bwShit = '-b3';
				}
				
				if ((dad.curCharacter.contains('tankman') || dad.curCharacter.contains('monika') || dad.curCharacter.contains('aloe') || dad.curCharacter.contains('bf-nene')))
				{
					if (iconP1.animation.name != '2vplus-senpai-giddy' + bwShit)
						iconP1.useOldSystem('2vplus-senpai-giddy' + bwShit);
				}
					
				else
				{
					if (iconP1.animation.name != '2vplus-senpai' + bwShit)
						iconP1.useOldSystem('2vplus-senpai' + bwShit);	
				}	
			}
		}
	

		if (curStage == 'genocide')
		{
			Stage.vignette.alpha = 1 - (health / 2);

			if (!addedShit)
			{
				filters.push(ShadersHandler.chromaticAberration);
				filters.push(ShadersHandler.brightShader);
				addedShit = true;
			}
		
			ShadersHandler.setBrightness(((health / 2) - 1 < 0) ? 0 : (((health / 2) - 1) * 2) / 32);
			ShadersHandler.setContrast(((health / 2) - 1 < 0) ? 1 : 1 + ((health / 2) - 1) / 8);
		}*/

		if (shakeCam2)
			FlxG.camera.shake(0.0025, 0.10);

		if(health1 && !pressedOnce)
		{
			if (FlxG.keys.justPressed.SPACE)
			{
				health += 0.7;
				pressedOnce = true;
			}
		}

		#if debug
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

		if (healthSet) health = 1;

		/*if ((dad.curCharacter == 'sarvente-lucifer' || dad.curCharacter == 'sh-carol') && !doingFloatShit)
			doFloatShit();

		if (dad.curCharacter != 'sarvente-lucifer' && dad.curCharacter != 'sh-carol' && doingFloatShit)
			doingFloatShit = false;

		if (boyfriend.curCharacter != 'sarvente-lucifer' && boyfriend.curCharacter != 'sh-carol' && doingFloatShit)
			doingBoyfriendFloatShit = false;

		if ((boyfriend.curCharacter == 'sarvente-lucifer' || boyfriend.curCharacter == 'sh-carol') && !doingBoyfriendFloatShit)
			doBFFloatShit();

		if (!dad.curCharacter.contains('spirit') && !removedTrail && curStage == 'schoolEvild4')
			remove(evilTrail);
			removedTrail = true;

		if (dad.curCharacter == "tordbot")
		{
			if (dad.animation.curAnim.name == "singLEFT") camFollow.setPosition(tordCam[0].x, tordCam[0].y);
			if (dad.animation.curAnim.name == "singRIGHT") camFollow.setPosition(tordCam[1].x, tordCam[1].y);
			if (dad.animation.curAnim.name == "singUP") camFollow.setPosition(tordCam[2].x, tordCam[2].y);
			if (dad.animation.curAnim.name == "singDOWN") camFollow.setPosition(tordCam[3].x, tordCam[3].y);
		}*/

		//because psych can run it before song starts.
		callOnLuas('onUpdate', [elapsed]);
		
		#if windows
		if (songStarted && luaArray.length >= 1)
		{
			setOnLuas('songPos',Conductor.songPosition);
			setOnLuas('hudZoom', camHUD.zoom);
			setOnLuas('cameraZoom',FlxG.camera.zoom);
			callOnLuas('update', [elapsed]);

			for (i in luaWiggles)
			{
				trace('wiggle le gaming');
				i.update(elapsed);
			}

			/*for (i in 0...strumLineNotes.length) {
				var member = strumLineNotes.members[i];
				member.x = luaArray[0].get("strum" + i + "X", "float");
				member.y = luaArray[0].get("strum" + i + "Y", "float");
				member.angle = luaArray[0].get("strum" + i + "Angle", "float");
			}*/

			if (luaArray[0].get("showOnlyStrums",'bool'))
			{
				healthBarBG.visible = false;
				healthBar.visible = false;
				iconP1.visible = false;
				iconP2.visible = false;
				scoreTxt.visible = false;
			}
			else
			{
				healthBarBG.visible = true;
				healthBar.visible = true;
				iconP1.visible = true;
				iconP2.visible = true;
				scoreTxt.visible = true;
			}

			var p1 = luaArray[0].get("strumLine1Visible",'bool');
			var p2 = luaArray[0].get("strumLine2Visible",'bool');

			for (i in 0...4)
			{
				opponentStrums.members[i].visible = p1;
				if (i <= playerStrums.length)
					playerStrums.members[i].visible = p2;
			}
		}

		#end

		#if windows
		if (luaArray.length >= 1)
		{
			if (luaArray[0].get("newIcons",'bool'))
				newIcons = true;
			else
				newIcons = false;

			var iconSwitch = luaArray[0].get("swapIcons",'bool');
			swapIcons = iconSwitch;
		}
		#end

		// reverse iterate to remove oldest notes first and not invalidate the iteration
		// stop iteration as soon as a note is not removed
		// all notes should be kept in the correct order and this is optimal, safe to do every frame/update
		{
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
		}

		if (FlxG.keys.justPressed.NINE)
			iconP1.swapOldIcon(boyfriend.healthIcon);

		super.update(elapsed);

		if (FlxG.save.data.psychUI)
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + misses + ' | Rating: ' + Ratings.generateRatingName(accuracy) + ' (' + HelperFunctions.truncateFloat(accuracy, 2) + '%)' + ' - ' + Ratings.GenerateLetterRankPsych(accuracy);//peeps wanted no integer rating
		else
			scoreTxt.text = Ratings.CalculateRanking(songScore,songScoreDef,nps,maxNPS,accuracy);

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				trace('GITAROO MAN EASTER EGG');
				MusicBeatState.switchState(new GitarooPause());
			}
			else
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN && !inCutscene){
			openChartEditor();
		}

		/*floatshit += 0.03;
		
		if (dad.curCharacter == 'nonsense-god' || dad.curCharacter == 'pshaggy' || dad.curCharacter == 'makocorrupt')
			dad.y += Math.sin(floatshit);

		if (dad.curCharacter == 'missingno')
		{
			if (!Math.isNaN(dadY)) 
				dad.y = dadY + ((Math.sin((Conductor.songPosition / 16000) * (180 / Math.PI))) * 5);
			else
				dadY = dad.y;
		}*/
	
		if (dad.curCharacter == 'wbshaggy')
		{
			rotInd++;
			var rot = rotInd / 6;

			if (!checkedShaggy)
			{
				DAD_X = dad.x;
				DAD_Y = dad.y;
				checkedShaggy = true;
			}

			dad.x = DAD_X + Math.cos(rot / 3) * 20 + 20;
			dad.y = DAD_Y + Math.cos(rot / 5) * 40 - 20;
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp((playerIconScale-0.2), iconP1.scale.x, CoolUtil.boundTo((playerIconScale-0.2) - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp((opponentIconScale-0.2), iconP2.scale.x, CoolUtil.boundTo((opponentIconScale-0.2) - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > maxHealth)
			health = maxHealth;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else if (healthBar.percent > 80 && iconP1.hasWinning)
			iconP1.animation.curAnim.curFrame = 2;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else if (healthBar.percent < 20 && iconP2.hasWinning)
			iconP2.animation.curAnim.curFrame = 2;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			MusicBeatState.switchState(new Charting()); */

		if (FlxG.keys.justPressed.FOUR)
		{
			persistentUpdate = false;

			MusicBeatState.switchState(new CharacterEditorState(dad.curCharacter));
		}

		if (FlxG.keys.justPressed.TWO)
		{
			persistentUpdate = false;

			MusicBeatState.switchState(new CharacterEditorState(boyfriend.curCharacter));
		}

		#if debug
		if(FlxG.keys.justPressed.THREE) //Go 10 seconds into the future, credit: Shadow Mario#9396
		{ 
			var shiftPressed:Bool = false;

			if (FlxG.keys.pressed.SHIFT)shiftPressed = true;
			doTimeTravel(shiftPressed);
		}
		#end


		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;
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
					//songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			// Make sure Girlfriend cheers only for certain songs
			if(allowedToHeadbang)
			{
				// Don't animate GF if something else is already animating her (eg. train passing)
				if(gf.animation.curAnim.name == 'danceLeft' || gf.animation.curAnim.name == 'danceRight' || gf.animation.curAnim.name == 'idle')
				{
					// Per song treatment since some songs will only have the 'Hey' at certain times
					switch(curSong)
					{
						case 'Philly Nice':
						{
							// General duration of the song
							if(curBeat < 250)
							{
								// Beats to skip or to stop GF from cheering
								if(curBeat != 184 && curBeat != 216)
								{
									if(curBeat % 16 == 8)
									{
										// Just a garantee that it'll trigger just once
										if(!triggeredAlready)
										{
											gf.playAnim('cheer');
											triggeredAlready = true;
										}
									}else triggeredAlready = false;
								}
							}
						}
						case 'Bopeebo':
						{
							// Where it starts || where it ends
							if(curBeat > 5 && curBeat < 130)
							{
								if(curBeat % 8 == 7)
								{
									if(!triggeredAlready)
									{
										gf.playAnim('cheer');
										triggeredAlready = true;
									}
								}else triggeredAlready = false;
							}
						}
						case 'Blammed':
						{
							if(curBeat > 30 && curBeat < 190)
							{
								if(curBeat < 90 || curBeat > 128)
								{
									if(curBeat % 4 == 2)
									{
										if(!triggeredAlready)
										{
											gf.playAnim('cheer');
											triggeredAlready = true;
										}
									}else triggeredAlready = false;
								}
							}
						}
						case 'Cocoa':
						{
							if(curBeat < 170)
							{
								if(curBeat < 65 || curBeat > 130 && curBeat < 145)
								{
									if(curBeat % 16 == 15)
									{
										if(!triggeredAlready)
										{
											gf.playAnim('cheer');
											triggeredAlready = true;
										}
									}else triggeredAlready = false;
								}
							}
						}
						case 'Eggnog':
						{
							if(curBeat > 10 && curBeat != 111 && curBeat < 220)
							{
								if(curBeat % 8 == 7)
								{
									if(!triggeredAlready)
									{
										gf.playAnim('cheer');
										triggeredAlready = true;
									}
								}else triggeredAlready = false;
							}
						}
					}
				}
			}
			
			#if windows
			if (luaArray.length >= 1)
				setOnLuas("mustHitSection",PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			#end

			if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				#if windows
				if (luaArray.length >= 1)
					callOnLuas('playerTwoTurn', []);
				#end

				if (camFollowIsOn)
				{
					if (curStage == 'night') {
						var coolGlowyLights = Stage.swagGroup['coolGlowyLights'];
						var coolGlowyLightsMirror = Stage.swagGroup['coolGlowyLightsMirror'];
	
						for (i in coolGlowyLights) {
							i.flipX = false;
						}
						for (i in coolGlowyLightsMirror) {
							i.flipX = true;
						}	
					}
	
					var offsetX = 0;
					var offsetY = 0;
	
					lockedCamera = false;
	
					if (curSong == 'Gun-Buddies')
						offsetY = 50;
	
					switch (curStage)
					{
						case 'curse': offsetX = 430;
						case 'stadium' | 'ripdiner' | 'motherland' | 'hallway' | 'concert': lockedCamera = true;
						case 'clubroomevil': if (storyDifficulty == 5 && dad.curCharacter != 'bigmonika') lockedCamera = true;
						case 'reactor' | 'reactor-m': camFollowIsOn = false;
						default: lockedCamera = false;
					}
	
					#if windows
					if (luaArray.length >= 1)
					{
						offsetX = luaArray[0].get("followDadXOffset", "float");
						offsetY = luaArray[0].get("followDadYOffset", "float");
					}
					#end
					if(SONG.player2 != "tordbot")
					{
						camFollow.setPosition(dad.getMidpoint().x + 150 + offsetX, dad.getMidpoint().y - 100 + offsetY);
	
						if (dad.isCustom && !lockedCamera)
						{
							camFollow.x += dad.cameraPosition[0];
							camFollow.y += dad.cameraPosition[1];
						}
					}		
	
					/*switch (curStage)
					{
						case 'day':
							camFollow.x = 536.63 + offsetX;
							camFollow.y = 449.94 + offsetY;
						case 'mind':
							camFollow.x = dad.getMidpoint().x + 350 + offsetX;
						case 'prologue':
							camFollow.x = dad.getMidpoint().x + 200 + offsetX;
						case 'night':
							camFollow.x = FlxMath.lerp(295.92, camFollow.x, 0.1) + offsetX;
							camFollow.y = FlxMath.lerp(447.52, camFollow.y, 0.1) + offsetY;
						case 'stadium':
							camFollow.x = 530 + offsetX;
							camFollow.y = 610 + offsetY;
							lockedCamera = true;
						case 'ripdiner':
							camFollow.x = 736 + offsetX;
							camFollow.y = 544.5 + offsetY;
							lockedCamera = true;
						case 'ITB':
							camFollow.x = FlxMath.lerp(272.46, camFollow.x, 0.1) + offsetX;
							camFollow.y = FlxMath.lerp(420.96, camFollow.y, 0.1) + offsetY;
						case 'clubroomevil':
							if (storyDifficulty == 5 && dad.curCharacter != 'bigmonika' && curStep < 2344)
							{
								camFollow.y = dad1.getMidpoint().y + 50 + offsetY;
								camFollow.x = dad1.getMidpoint().x - 250 + offsetX;
							}	
							else if (storyDifficulty == 5)
							{
								camFollow.y = dad1.getMidpoint().y - 75 + offsetY;
								camFollow.x = dad1.getMidpoint().x + offsetX;
							}
						case 'motherland':
							if (defaultCamZoom >= 1.7)
							{
								camFollow.y = gf.getGraphicMidpoint().y + 110 + offsetY;
								camFollow.x = gf.getGraphicMidpoint().x - 480 + offsetX;
							}
							else if (defaultCamZoom == 0.80)
							{
								camFollow.y = gf.getGraphicMidpoint().y + 90 + offsetY;
								camFollow.x = gf.getGraphicMidpoint().x - 250 + offsetX;
							}
							else
							{
								camFollow.y = gf.getGraphicMidpoint().y - 60 + offsetY;
								camFollow.x = gf.getGraphicMidpoint().x - 200 + offsetX;
							}
						case 'hallway':
							camFollow.x = 657.81 + offsetX;
							switch (dad.curCharacter) {
								case 'austin':
									camFollow.y = 400.56 + offsetY;
								default:
									camFollow.y = 501.56 + offsetY;
							}
						case 'concert':
							camFollow.y = gf.getMidpoint().y - 25 + offsetY;
							camFollow.x = gf.getMidpoint().x - 25 + offsetX;
					}*/
	
					if (!lockedCamera && !dad.isCustom)
					{
						switch (dad.curCharacter)
						{
							case 'mom' | 'b3-mom-sad' | 'b3-mom-mad' | 'mom-sad-blue':
								camFollow.y = dad.getMidpoint().y - 50 + offsetY;
							case 'duet-sm':
								camFollow.y = dad.getMidpoint().y - 400 + offsetY;
								camFollow.x = dad.getMidpoint().x + 0 + offsetX;
							case 'yukichi-police':  
								camFollow.x = dad.getMidpoint().x + 423 + offsetX;
								camFollow.y = dad.getMidpoint().y - 280 + offsetY;
							case 'bf-annie':
								camFollow.x = dad.getMidpoint().x + 250 + offsetX;
								camFollow.y = dad.getMidpoint().y - 150 + offsetY;
							case 'annie-bw':
								camFollow.x = dad.getMidpoint().x + 200;	
								camFollow.y = dad.getMidpoint().y - 200;	
							case 'bf-whitty-pixel':
								camFollow.y = dad.getMidpoint().y - 300;
								camFollow.x = dad.getMidpoint().x + 60;
							case 'bitdad' | 'bitdadBSide':
								camFollow.y = dad.getMidpoint().y - 75;
								camFollow.x = dad.getMidpoint().x + 200;
							case 'bitdadcrazy':
								camFollow.y = dad.getMidpoint().y - 75;
								camFollow.x = dad.getMidpoint().x + 230;
							case 'senpai' | 'senpai-angry' | 'senpai-giddy' | 'glitch' | 'glitch-angry' | 'monika' | 'monster-pixel' | 'monika-angry' | 'green-monika' | 'neon' 
							| 'baldi-angry-pixel' | 'matt-angry' | 'mario-angry' | 'colt-angry' | 'kristoph-angry' | 'chara-pixel' | 'colt-angryd2' | 'colt-angryd2corrupted' 
							| 'jackson' | 'miku-pixel' | 'josuke':
								camFollow.y = dad.getMidpoint().y - 430 + offsetY;
								camFollow.x = dad.getMidpoint().x - 100 + offsetX;
							case 'neon-bigger':
								camFollow.y = dad.getMidpoint().y - 380 + offsetY;
								camFollow.x = dad.getMidpoint().x - 100 + offsetX;
							case 'cassandra' | 'cassandra-bw':
								camFollow.y = dad.getMidpoint().y + 75 + offsetY;
							case 'bf-gf-pixel' | 'bf-botan-pixel' | 'bf-sky-pixel' | 'bf-glitch-pixel':
								camFollow.x = dad.getMidpoint().x + 125;
								camFollow.y = dad.getMidpoint().y - 225;
							case 'lane-pixel':
								camFollow.x = dad.getMidpoint().x + 110;
								camFollow.y = dad.getMidpoint().y - 325;
							case 'monika-finale':
								camFollow.y = dad.getMidpoint().y - 390;
								camFollow.x = dad.getMidpoint().x - 250;
							case 'gf-crucified':
								camFollow.y = dad.getMidpoint().y + offsetY;
							case 'anchor-bowl':
								camFollow.y = dad.getMidpoint().y + 50 + offsetY;
							case 'eteled2':
								camFollow.y = dad.getMidpoint().y - 200 + offsetY;
							case 'bigmonika':
								camFollow.y = dad.getMidpoint().y - 75 + offsetY;
								camFollow.x = dad.getMidpoint().x + offsetX;
							case 'crazygf' | 'sunky':
								camFollow.y = dad.getMidpoint().y - 100 + offsetY;
								camFollow.x = dad.getMidpoint().x + 149 + offsetX;	
							case 'shadowbonnie-pixel':
								camFollow.y = dad.getMidpoint().y + 100 + offsetY;		
							case 'TDoll' | 'TDollAlt':
								camFollow.y = dad.getMidpoint().y - 200 + offsetY;
								camFollow.x = dad.getMidpoint().x + 130 + offsetX;	
							case 'mel':
								camFollow.y = dad.getMidpoint().y - 50 + offsetY;
							case 'richard2':
								camFollow.x = dad.getMidpoint().x + 100 + offsetX;
							case 'baldi-angry':
								camFollow.y = dad.getMidpoint().y + 50 + offsetY;
								camFollow.x = dad.getMidpoint().x + 100 + offsetX;	
						}
					}		
	
					if (dad.curCharacter == 'mom')
						vocals.volume = 1;
	
					//if (SONG.song.toLowerCase() == 'tutorial-remix' || SONG.player2 == 'tordbot')
					//	tweenCamIn();
	
					if (curStage == 'curse')
						FlxTween.tween(FlxG.camera, {zoom: 0.6}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	
					/*if (SONG.song.toLowerCase() == 'endless' || SONG.song.toLowerCase() == 'you-cant-run' || SONG.song.toLowerCase() == 'omnipresent' || SONG.song.toLowerCase() == 'four-way-fracture')
					{
						camFollow.x += dadCamX;
						camFollow.y += dadCamY;
					}*/
				}
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				#if windows
				if (luaArray.length >= 1)
					callOnLuas('playerOneTurn', []);
				#end

				if (camFollowIsOn)
				{
					var offsetX = 0;
					var offsetY = 0;
					var lockedCamera:Bool = false;
	
					if (curSong == 'Gun-Buddies')
						offsetY = 50;
	
					switch (curStage)
					{
						case 'curse': offsetX = -330;
						case 'stadium' | 'ripdiner' | 'motherland' | 'hallway' | 'concert': lockedCamera = true;
						case 'clubroomevil': if(storyDifficulty == 5) lockedCamera = true;
					}
	
					#if windows
					if (luaArray.length >= 1)
					{
						offsetX = luaArray[0].get("followBFXOffset", 'float');
						offsetY = luaArray[0].get("followBFYOffset", 'float');
					}
					#end
	
					camFollow.setPosition(boyfriend.getMidpoint().x - 100 + offsetX, boyfriend.getMidpoint().y - 100 + offsetY);
	
					if (boyfriend.isCustom && !lockedCamera)
					{
						camFollow.x -= boyfriend.cameraPosition[0] - (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[0] : 0);
						camFollow.y += boyfriend.cameraPosition[1] + (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[1] : 0);
					}
					
					switch (curStage)
					{
						/*case 'hungryhippo':
							camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
						case 'cgstage':
							camFollow.y = boyfriend.getMidpoint().y - 230 + offsetY;
						case 'mall' | 'mallSoft' | 'sofdeez':
							camFollow.y = boyfriend.getMidpoint().y - 200 + offsetY;
						case 'school' | 'grillbys' | 'school-baldi' | 'mushroom-kingdom' | 'eddhouse-pixel':
							camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
							camFollow.y = boyfriend.getMidpoint().y - 200 + offsetY;
						case 'school-switch':
							camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
							camFollow.y = boyfriend.getMidpoint().y - 200 + offsetY;
						case 'school-monika':
							switch (curSong.toLowerCase())
							{
								case 'shinkyoku':
									camFollow.x = boyfriend.getMidpoint().x - 300 + offsetX;
									camFollow.y = boyfriend.getMidpoint().y - 200 + offsetY;
								default:
									camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
									camFollow.y = boyfriend.getMidpoint().y - 200 + offsetY;
							}
						case 'schoolnoon':
							camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
							camFollow.y = boyfriend.getMidpoint().y - 200 + offsetY;
						case 'schoolEvil' | 'schoolEvild4' | 'school-monika-finale':
							camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
							camFollow.y = boyfriend.getMidpoint().y - 200 + offsetY;
						case 'day' | 'sunset':
							camFollow.x = 818.96 + offsetX;
							camFollow.y = 475.95 + offsetY;
						case 'garage':
							camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
						case 'night':
							camFollow.x = FlxMath.lerp(790.36, camFollow.x, 0.1) + offsetX;
							camFollow.y = FlxMath.lerp(480.91, camFollow.y, 0.1) + offsetY;
						case 'ITB':
							camFollow.x = FlxMath.lerp(626.31, camFollow.x, 0.1) + offsetX;
							camFollow.y = FlxMath.lerp(420.96, camFollow.y, 0.1) + offsetY;
						case 'stadium':
							camFollow.x = 844.5 + offsetX;
							camFollow.y = 610 + offsetY;
						case 'ripdiner':
							camFollow.x = 736 + offsetX;
							camFollow.y = 544.5 + offsetY;
							lockedCamera = true;
						case 'motherland':
							if (defaultCamZoom >= 1.7)
							{
								camFollow.y = gf.getGraphicMidpoint().y + 110 + offsetY;
								camFollow.x = gf.getGraphicMidpoint().x + 480 + offsetX;
							}
							else if (defaultCamZoom == 0.80)
							{
								camFollow.y = gf.getGraphicMidpoint().y + 90 + offsetY;
								camFollow.x = gf.getGraphicMidpoint().x + 250 + offsetX;
							}
							else
							{
								camFollow.y = gf.getGraphicMidpoint().y - 60 + offsetY;
								camFollow.x = gf.getGraphicMidpoint().x + 200 + offsetX;
							}
						case 'clubroomevil':
							if (storyDifficulty == 5)
							{
								camFollow.y = dad1.getMidpoint().y + 50 + offsetY;
								camFollow.x = dad1.getMidpoint().x + 250 + offsetX;
							}		
						case 'airplane':
							camFollow.setPosition(boyfriend.getMidpoint().x - 300 + offsetX, boyfriend.getMidpoint().y - 300 + offsetY);
						case 'hallway':
							camFollow.x = 1176.3 + offsetX;
							switch (boyfriend.curCharacter) {
								case 'austin':
									camFollow.y = 400.87 + offsetY;
								default:
									camFollow.y = 515.87 + offsetY;
							}
						case 'concert':
							camFollow.y = gf.getMidpoint().y - 25 + offsetY;
							camFollow.x = gf.getMidpoint().x - 25 + offsetX;
						case 'dokiclubroom-sayori' | 'dokiclubroom-natsuki' | 'dokiclubroom-yuri' | 'dokiclubroom-monika':
							camFollow.y = boyfriend.getMidpoint().y - 200 + offsetY;
						case 'exestage2':
							camFollow.x = boyfriend.getMidpoint().x - 170;
						case 'trollgestage':
							camFollow.x = boyfriend.getMidpoint().x - 200;
							camFollow.y = boyfriend.getMidpoint().y - 250;*/
					}
	
					if (SONG.song.toLowerCase() == 'tutorial-remix')
					//	FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	
					if (!lockedCamera && !boyfriend.isCustom)
					{
						switch (boyfriend.curCharacter)
						{
							case 'sky-mad' | 'sky-pissed':
								camFollow.y = boyfriend.getMidpoint().y - 70 + offsetY;
								camFollow.x = boyfriend.getMidpoint().x - 220 + offsetX;
							case 'baldi-angry':
								camFollow.y = boyfriend.getMidpoint().y + 50 + offsetY;
								camFollow.x = boyfriend.getMidpoint().x + 50 + offsetX;
							case 'parents-christmas':
								camFollow.y = boyfriend.getMidpoint().y - 50 + offsetY;
								camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
							case 'mokey':
								camFollow.y = boyfriend.getMidpoint().y + 200 + offsetY;
								camFollow.x = boyfriend.getMidpoint().x - 100 + offsetX;
							case 'daidem':
								camFollow.y = boyfriend.getMidpoint().y + offsetY;
								camFollow.x = boyfriend.getMidpoint().x - 250 + offsetX;
							case 'peri':
								camFollow.y = boyfriend.getMidpoint().y - 50 + offsetY;
							case 'piconjo':
								camFollow.y = boyfriend.getMidpoint().y - 300 + offsetY;
								camFollow.x = boyfriend.getMidpoint().x - 250 + offsetX;
							case 'bf-dad':
								camFollow.x = boyfriend.getMidpoint().x - 250 + offsetX;
							case 'mia' | 'mia-lookstraight':
								camFollow.x = boyfriend.getMidpoint().x - 150 + offsetX;
							case 'myra':
								camFollow.y = boyfriend.getMidpoint().y - 80 + offsetY;
								camFollow.x = boyfriend.getMidpoint().x - 150 + offsetX;
							case 'mom' | 'mom-shaded':
								camFollow.y = boyfriend.getMidpoint().y - 50 + offsetY;
								camFollow.x = boyfriend.getMidpoint().x - 250 + offsetX;
							case 'austin':
								camFollow.x = boyfriend.getMidpoint().x - 90;
								camFollow.y = boyfriend.getMidpoint().y - 30;
							case 'bf-mom' | 'bf-mom-car':
								camFollow.x = boyfriend.getMidpoint().x - 250 + offsetX;
							case 'cassandra':
								camFollow.y = boyfriend.getMidpoint().y + 100 + offsetY;
								camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
							case 'bana' | 'bana-wire':
								camFollow.y = boyfriend.getMidpoint().y + offsetY;
								camFollow.x = boyfriend.getMidpoint().x - 150 + offsetX;
							case 'henry-angry':
								camFollow.x = boyfriend.getMidpoint().x - 250;
							case 'bf-annie':
								camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;	
							case 'annie-bw' | 'phil' | 'nene' | 'picoCrazy' | 'nene-bw':
								camFollow.x = boyfriend.getMidpoint().x - 300 + offsetX;	
							case 'senpai' | 'blantad-pixel' | 'glitch' | 'glitch-angry' | 'senpai-angry' | 'senpai-giddy' | 'miku-pixel' 
							| 'mangle-angry' | 'monster-pixel' | 'jackson' | 'matt-angry' | 'mario-angry' | 'colt-angry' | 'colt-angryd2' 
							| 'colt-angryd2corrupted' | 'bf-senpai-tankman' | 'neon-bigger' | 'josuke' | 'tricky-pixel':
								camFollow.x = boyfriend.getMidpoint().x - 400 + offsetX;
								camFollow.y = boyfriend.getMidpoint().y - 400 + offsetY;
							case 'monika' | 'monika-angry':
								if (curStage.contains('school') || pixelStages.contains(curStage))
								{
									camFollow.x = boyfriend.getMidpoint().x - 400 + offsetX;
									camFollow.y = boyfriend.getMidpoint().y - 430 + offsetY;
								}
								else
								{
									camFollow.x = boyfriend.getMidpoint().x - 450 + offsetX;
									camFollow.y = boyfriend.getMidpoint().y - 480 + offsetY;
								}	
							case 'neon':
								camFollow.x = boyfriend.getMidpoint().x - 450 + offsetX;
								camFollow.y = boyfriend.getMidpoint().y - 400 + offsetY;
							case 'brother':
								camFollow.y = boyfriend.getMidpoint().y + 25;
							case 'spooky-pixel':
								camFollow.x = boyfriend.getMidpoint().x - 250;
								camFollow.y = boyfriend.getMidpoint().y - 100;
							case 'spooky':
								camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
								camFollow.y = boyfriend.getMidpoint().y + offsetY;
							case 'bf-pico-pixel':
								camFollow.x = boyfriend.getMidpoint().x - 300;
								camFollow.y = boyfriend.getMidpoint().y - 250;
							case 'bf-botan-pixel':
								camFollow.x = boyfriend.getMidpoint().x - 300;
								camFollow.y = boyfriend.getMidpoint().y - 150;
							case 'bf-whitty-pixel':
								camFollow.x = boyfriend.getMidpoint().x - 350;
								camFollow.y = boyfriend.getMidpoint().y - 300;
							case 'whitty':
								camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;	
							case 'bf-gf' | 'ruv' | 'tabi' | 'garcellodead':
								camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
							case 'bf-senpai-worried':
								camFollow.x = boyfriend.getMidpoint().x - 300 + offsetX;	
							case 'henry':
								camFollow.x = boyfriend.getMidpoint().x - 200;
							case 'tabi-glitcher' | 'tabi-wire':
								camFollow.x = boyfriend.getMidpoint().x - 300 + offsetX;
							case 'bf-senpai-pixel-angry':
								camFollow.x = boyfriend.getMidpoint().x - 200;
								camFollow.y = boyfriend.getMidpoint().y - 200;
							case 'gura-amelia' | 'gura-amelia-walfie' | 'gura-amelia-corrupt' | 'gura-amelia-bw':
								camFollow.x = boyfriend.getMidpoint().x - 200;
							case 'gold-side' | 'gold-side-blue':
								camFollow.x = boyfriend.getMidpoint().x - 50 + offsetX;
								camFollow.y = boyfriend.getMidpoint().y - 50 + offsetY;
							case 'dust-sans':
								camFollow.x = boyfriend.getMidpoint().x - 101 + offsetX;
								camFollow.y = boyfriend.getMidpoint().y - 100 + offsetY;
							case 'auditor':
								camFollow.x = boyfriend.getMidpoint().x - 200 + offsetX;
							case 'bf-demoncesar-pixel':
								camFollow.x = boyfriend.getMidpoint().x - 300 + offsetX;
								camFollow.y = boyfriend.getMidpoint().y - 250 + offsetY;
						}
		
						/*if (!curStage.contains('school'))
						{
							switch (boyfriend.curCharacter)
							{
								case 'bf-pixel' | 'bf-pixeld3' | 'bf-pixeld3BSide' | 'bf-pixel-neon' | 'bf-tankman-pixel' | 'bf-demoncesar-pixel' | 'bf-tankman-pixel-happy' | 'bf-sonic-pixel':
									camFollow.x = boyfriend.getMidpoint().x - 310 + offsetX;
									camFollow.y = boyfriend.getMidpoint().y - 190 + offsetY;
							}	
						}
	
						if (SONG.song.toLowerCase() == 'endless' || SONG.song.toLowerCase() == 'you-cant-run' || SONG.song.toLowerCase() == 'omnipresent' || SONG.song.toLowerCase() == 'four-way-fracture')
						{
							camFollow.x += bfCamX;
							camFollow.y += bfCamY;
						}*/
					}
				}
			}
		}

		if (camZooming)
		{
			if (psychCamZooming)
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
				camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));

				if (isDetected)
				{
					camNotes.zoom = camHUD.zoom;
					camSustains.zoom = camHUD.zoom;
				}
			}
			else
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
				camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);

				if (isDetected)
				{
					camNotes.zoom = camHUD.zoom;
					camSustains.zoom = camHUD.zoom;
				}
			}	
		}

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

				if (isDetected && executeModchart)
				{
					currentLuaIndex++;
					var n = new LuaNote(dunceNote, currentLuaIndex);
					//n.Register(ModchartState.instance.lua);
					ModchartState.shownNotes.push(n);
					dunceNote.LuaNote = n;
					dunceNote.luaID = currentLuaIndex;
				}

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);

				if (isDetected)
					currentLuaIndex++;
			}
		}

		if (spookyRendered) // move shit around all spooky like
		{
			spookyText.angle = FlxG.random.int(-5,5); // change its angle between -5 and 5 so it starts shaking violently.
			//tstatic.x = tstatic.x + FlxG.random.int(-2,2); // move it back and fourth to repersent shaking.
			if (tstatic.alpha != 0)
				tstatic.alpha = FlxG.random.float(0.1,0.5); // change le alpha too :)

			if (curStage.contains('auditorHell') && Stage.tstatic.alpha != 0)
				Stage.tstatic.alpha = FlxG.random.float(0.1,0.5); // change le alpha too :)
		}

		if (generatedMusic)
		{
			if (isLullaby)
				pendulumDrain = true;

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			var roundedSpeed:Float = FlxMath.roundDecimal(FlxG.save.data.scrollSpeed == 1 ? SONG.speed : FlxG.save.data.scrollSpeed, 2);
			var center:Float;

			notes.forEachAlive(function(daNote:Note)
			{	
				if (daNote.canBeHit && daNote.mustPress && isLullaby)
					pendulumDrain = false;

				if (!daNote.mustPress)
					minusHealth = true;

				// instead of doing stupid y > FlxG.height
				// we be men and actually calculate the time :)
				if (daNote.tooLate)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
					daNote.active = true;

				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
			//	var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
			//	var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				if (FlxG.save.data.downscroll || daNote.downscroll) //Downscroll
				{
					//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * PlayState.SONG.speed * daNote.multSpeed);
				}
				else //Upscroll
				{
					//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * PlayState.SONG.speed * daNote.multSpeed);
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				//strumAngle += daNote.offsetAngle;
				//strumAlpha *= daNote.multAlpha;

				center = strumY + Note.swagWidth / 2;

				var angleDir = strumDirection * Math.PI / 180;

				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if (!daNote.modifiedByLua)
				{
					if (FlxG.save.data.downscroll || daNote.downscroll)
					{
						daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);		

						if(daNote.isSustainNote)
						{
							// Remember = minus makes notes go up, plus makes them go down
							if(daNote.animation.curAnim.name.endsWith('end') && daNote.prevNote != null)
								daNote.y += daNote.prevNote.height;
							else
								daNote.y += daNote.height / 2;

							// If not in botplay, only clip sustain notes when properly hit, botplay gets to clip it everytime
							if(!FlxG.save.data.botplay)
							{
								if((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit) && daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= (strumLine.y + Note.swagWidth / 2))
								{
									// Clip to strumline
									var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}else if (!daNote.burning && !daNote.blackStatic && !daNote.ignoreNote)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);

								if (daNote.mustPress && daNote.downscroll)
									swagRect.height = (center - daNote.y) / daNote.scale.y + 20;
								else
									swagRect.height = (center - daNote.y) / daNote.scale.y;

								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
					}else
					{
						daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);		
							
						
						if(daNote.isSustainNote)
						{
							//daNote.y -= daNote.height / 2;

							if(!FlxG.save.data.botplay)
							{
								if((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit) && daNote.y + daNote.offset.y * daNote.scale.y <= (center))
								{
									// Clip to strumline
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}else if (!daNote.burning && !daNote.blackStatic && !daNote.ignoreNote)
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}
				}

				#if windows
				if (luaArray.length >= 1)
				{
					if (luaArray[0].get("dadNotesInvisible",'bool'))
					{
						if (!daNote.mustPress)
							daNote.visible = false;
					}		
					else
					{
						if (!daNote.mustPress)
							daNote.visible = true;
					}					
				}
				#end

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					switch (curSong)
					{
						case 'Tutorial' | 'Tutorial-Remix' | 'Get Out' | 'Their-Battle' | 'Ghost-VIP':
							camZooming = false;
						default:
							camZooming = true;
					}

					dad.altAnim = "";

					#if windows
					if (luaArray.length >= 1)
					{
						if (luaArray[0].get("dadAltAnim",'bool'))
							dad.altAnim = '-alt';
						else
							dad.altAnim = "";
					}
					#end

					if (daNote.noteType == "Alt Animation")
						dad.altAnim = '-alt';

					/*if (dad.curCharacter == 'blantad-scream' && dad.altAnim == '-alt' && iconP2.animation.name != 'blantad-scream2')
					{
						iconP2.useOldSystem('blantad-scream2');
						healthBar.createFilledBar(FlxColor.fromString('#' + 'FF0015FE'), FlxColor.fromString('#' + boyfriend.iconColor));
						healthBar.updateBar();
					}

					if (dad.curCharacter == 'blantad-scream' && dad.altAnim != '-alt' && iconP2.animation.name != 'blantad')
					{
						iconP2.useOldSystem('blantad');
						healthBar.createFilledBar(FlxColor.fromString('#' + dad.iconColor), FlxColor.fromString('#' + boyfriend.iconColor));
						healthBar.updateBar();
					}

					if (dad.curCharacter == 'midas-double' && dad.altAnim == '-alt' && iconP2.animation.name != 'midas-shadow')
					{
						iconP2.useOldSystem('midas-shadow');
						healthBar.createFilledBar(FlxColor.fromString('#' + 'FF8256B8'), FlxColor.fromString('#' + boyfriend.iconColor));
						healthBar.updateBar();
					}

					if (dad.curCharacter == 'midas-double' && dad.altAnim != '-alt' && iconP2.animation.name != 'midas')
					{
						iconP2.useOldSystem('midas');
						healthBar.createFilledBar(FlxColor.fromString('#' + dad.iconColor), FlxColor.fromString('#' + boyfriend.iconColor));
						healthBar.updateBar();
					}*/
						
					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							dad.altAnim = '-alt';

						switch (curSong)
						{
							case 'Ballistic':
								if (shootStepsBallistic.contains(curStep) && !inCutscene  && dad.curCharacter == 'picoCrazy')
									dad.altAnim = '-alt';
						}					
					}

					var dDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

					/*if (SONG.song.toLowerCase() == 'endless' || SONG.song.toLowerCase() == 'you-cant-run' || SONG.song.toLowerCase() == 'omnipresent' || SONG.song.toLowerCase() == 'four-way-fracture')
					{
						dadCamX = xOff[daNote.noteData];
						dadCamY = yOff[daNote.noteData];
					}*/

					playDad = true;

					#if desktop
					if (luaArray.length >= 1)
					{
						if (luaArray[0].get("playDadSing",'bool'))
							playDad = true;
						else
							playDad = false;
					}
					#end

					#if windows
					if (luaArray.length >= 1)
						callOnLuas('dadPreNoteHit', [daNote.noteData, daNote.isSustainNote, daNote.noteType, daNote.dType]);
					#end

					switch (mania)
					{
						case 1:
							dDir = ['LEFT', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'RIGHT'];
						case 2:
							dDir = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
						case 3:
							dDir = ['LEFT', 'DOWN', 'UP', 'UP', 'RIGHT'];
						case 4:
							if (dad.curCharacter.contains('-9key'))
								dDir = ['LEFT', 'UP', 'RIGHT', 'UP3', 'LEFT2', 'DOWN', 'RIGHT2'];
							else
								dDir = ['LEFT', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'RIGHT'];
						default:
							dDir = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
					}
					
					if (playDad && !daNote.noAnimation)
						dad.playAnim('sing' + dDir[daNote.noteData] + dad.altAnim, true);

					switch(dad.curCharacter)
					{
						/*case 'cjClone': // 50% chance
							if (FlxG.random.bool(50) && !spookyRendered && !daNote.isSustainNote && curStage == 'auditorHell') // create spooky text :flushed:
							//	createSpookyText(cjCloneLinesSing[FlxG.random.int(0,cjCloneLinesSing.length)]);
						case 'exTricky': // 60% chance
							if (FlxG.random.bool(50) && !spookyRendered && !daNote.isSustainNote) // create spooky text :flushed:
							//	createSpookyText(exTrickyLinesSing[FlxG.random.int(0,exTrickyLinesSing.length)]);
						case 'tricky' | 'tricky-small':
							//if (FlxG.random.bool(45) && !spookyRendered && !daNote.isSustainNote) // create spooky text :flushed:
							//	createSpookyText(trickyLinesSing[FlxG.random.int(0,trickyLinesSing.length)]);
						case 'b3-mom-mad':
							health -= 0.03;
						case 'taki':
							if (curSong.toLowerCase() != 'crucify')
								health -= 0.02;*/
					}

					/*if (daNote.noteType == 3)
					{
						switch (dad.curCharacter)
						{
							case 'tankman-animations':
								if (curStep > 4120 && curStep < 4128 && SONG.song.toLowerCase() == 'omnipresent')
									dad.playAnim('dodge-speak');
								else
									dad.playAnim('dodge');
						}
					}
					
					if (daNote.noteType == 7)
					{
						switch (dad.curCharacter)
						{
							case 'auditor':
								if (FlxG.random.bool(45) && !spookyRendered && !daNote.isSustainNote) // create spooky text :flushed:
									createAuditorText(auditorLinesSing[FlxG.random.int(0,auditorLinesSing.length)]);
							case 'tricky' | 'tricky-small':
								if (FlxG.random.bool(45) && !spookyRendered && !daNote.isSustainNote) // create spooky text :flushed:
									createSpookyText(trickyLinesSing[FlxG.random.int(0,trickyLinesSing.length)]);
							case 'zipper':
								rushiaOverlayFrame = rushiaOverlayFrameMax;
								zipperScreamOverlay.alpha = 0.8;
								rushiaScreamOverlay.alpha = 0.2;
							case 'peri':
								rushiaOverlayFrame = rushiaOverlayFrameMax;
								periScreamOverlay.alpha = 0.8;
								periScreamOverlay.animation.play('idle');
								rushiaScreamOverlay.alpha = 0.2;
							default:
								rushiaOverlayFrame = rushiaOverlayFrameMax;
								rushiaScreamOverlay.alpha = 0.2;
						}					
					} 
					switch (SONG.song.toLowerCase())
					{
						case 'crucify':
							health -= 0.02;
							if (!dad.curCharacter.contains('gf') && gf.animOffsets.exists('scared'))
							{
								gf.playAnim('scared');
							}
						case 'hunger':
							health += 0.01;
					}*/

					if (usesStageHx)
						Stage.noteHit(false, notes.members.indexOf(daNote), Std.int(Math.abs(daNote.noteData)), daNote.isSustainNote,  daNote.noteType, daNote.dType);
					
					#if windows
					if (luaArray.length >= 1)
					{
						callOnLuas('dadNoteHit', [daNote.noteData, daNote.isSustainNote, daNote.noteType, daNote.dType]);
						callOnLuas('opponentNoteHit', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.dType]);
					}
					#end

					var time:Float = 0.15;
					if(daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
						time += 0.15;
					}

					StrumPlayAnim(true, Std.int(Math.abs(daNote.noteData)), time);

					#if windows
					if (luaArray.length >= 1)
						callOnLuas('playerTwoSing', [Math.abs(daNote.noteData), Conductor.songPosition]);
					#end

					if (playDad)
						dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.active = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				if (daNote.mustPress && !daNote.modifiedByLua)
				{
					daNote.visible = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
					if (!daNote.isSustainNote)
						daNote.angle = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].angle;
					daNote.alpha = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;

					if (daNote.isSustainNote)
						daNote.alpha -= 0.4;

					if (daNote.alpha < 0)
						daNote.alpha = 0;
				}
				else if (!daNote.wasGoodHit && !daNote.modifiedByLua)
				{
					daNote.visible = opponentStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
					if (!daNote.isSustainNote)
						daNote.angle = opponentStrums.members[Math.floor(Math.abs(daNote.noteData))].angle;
					daNote.alpha = opponentStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;

					if (daNote.isSustainNote)
						daNote.alpha -= 0.4;

					if (daNote.alpha < 0)
						daNote.alpha = 0;
				}
				
				//trace(daNote.y);
				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				if ((daNote.mustPress && daNote.tooLate && !FlxG.save.data.downscroll || daNote.mustPress && daNote.tooLate && FlxG.save.data.downscroll) && daNote.mustPress && !daNote.burning)
				{
					if (daNote.isSustainNote && daNote.wasGoodHit)
					{
						daNote.kill();
						notes.remove(daNote, true);
					}
					if (daNote.danger)
					{
						health -= 1;
						totalDamageTaken += 1;
						interupt = true;
						if (theFunne)
							noteMiss(daNote.noteData, daNote);
					}
					else
					{
						/*switch (daNote.noteType)
						{
							case 2:
								vocals.volume = 1;
							case 3:
								health -= 1;
								if (theFunne)
									noteMiss(daNote.noteData, daNote);
							case 4 | 6 | 8 | 9 | 10:
								''; //nothing
							case 5:
								if (!daNote.blackStatic)
								{
									noteMiss(daNote.noteData, daNote);
									health -= 0.2;
									staticHitMiss();
									vocals.volume = 0;
									FlxG.sound.play(Paths.sound('ring'), .7);
								}	
								else
									''; //nothing					
							default:
								
						}	*/

						if (daNote.canMiss)
							callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.dType]); //yeah i didn't know how else to do this

						if (theFunne && !writing && !daNote.ignoreNote && !daNote.canMiss)
						{
							health -= 0.02;
							totalDamageTaken += 0.02;
							interupt = true;
							vocals.volume = 0;	
							noteMiss(daNote.noteData, daNote);
						}
					}

					daNote.destroy();
					daNote.kill();
					notes.remove(daNote, true);
				}
			});

			//hypno shit
			if (isLullaby) 
			{
				trance -= 0.0015 / ((!pendulumDrain) ? reducedDrain : 1);
	
				/*tranceThing.alpha = trance / 2;
				if (trance > 1) {
					tranceSound.volume = trance - 1;
				} else {
					tranceSound.volume = 0;
				}*/
				
				if (trance > 2) 
				{
					trance = 2;
					death();
				}
				
				if (trance < -0.25)
					trance = -0.25;
	
				if (FlxG.keys.justPressed.SPACE && !inCutscene) 
				{
					if (canHitPendulum) 
					{
						canHitPendulum = false;
						hitPendulum = true;
						trance -= 0.02;
					} 
					else 
						losePendulum(true);
				}
			}
		}

		checkEventNote();

		if (!inCutscene)
			keyShit();

		for (i in shaderUpdates){
			i(elapsed);
		}

		#if debug
		if (FlxG.keys.justPressed.ONE && !inCutscene)
		{
			KillNotes();
			FlxG.sound.music.onComplete();
		}
		#end

		callOnLuas('onUpdatePost', [elapsed]);
	}

	var reducedDrain:Float = 4;

	function losePendulum(forced:Bool = false) {
		
		trance += 0.2 / ((!forced && !pendulumDrain) ? reducedDrain : 1);
		trace("BAD");
	}

	function psyshock() 
	{
		//psyshockParticle.setPosition(dad.x, dad.y);
		//psyshockParticle.playAnim("psyshock particle", true);
		//psyshockParticle.alpha = 1;
		
		//psyshockParticle.animation.finishCallback = function (lol:String) {
		//	psyshockParticle.alpha = 0;
		//};
		
		trance += (0.45 / ((!pendulumDrain) ? (reducedDrain / 2) : 1));
		
	//	FlxG.sound.play(Paths.sound('Psyshock', 'shared'), 1);
		if (FlxG.save.data.flashing)
			camHUD.flash(FlxColor.fromString('0xFFFFAFC1'), 1, null, true);
	}

	public function createSpookyText(text:String, x:Float = -1111111111111, y:Float = -1111111111111, ?isBF:Bool = false):Void
	{
		spookySteps = curStep;
		spookyRendered = true;
		FlxG.sound.play(Paths.sound('tricky/staticSound','shared'));

		if (curStage.contains('auditorHell'))
			Stage.tstatic.alpha = 0.5;
		else
			tstatic.alpha = 0.5;
		
		if (isBF)
			spookyText = new FlxText((x == -1111111111111 ? FlxG.random.float(boyfriend.x + 40,boyfriend.x + 120) : x), (y == -1111111111111 ? FlxG.random.float(boyfriend.y + 200, boyfriend.y + 300) : y));
		else
			spookyText = new FlxText((x == -1111111111111 ? FlxG.random.float(dad.x + 40,dad.x + 120) : x), (y == -1111111111111 ? FlxG.random.float(dad.y + 200, dad.y + 300) : y));

		spookyText.setFormat(Paths.font("impact.ttf"), 128, FlxColor.RED);
		spookyText.bold = true;
		spookyText.text = text;
		add(spookyText);
	}

	public function createBFSpookyText(text:String, x:Float = -1111111111111, y:Float = -1111111111111):Void
	{
		spookySteps = curStep;
		spookyRendered = true;
		if (curStage.contains('auditorHell'))
			Stage.tstatic.alpha = 0.5;
		else
			tstatic.alpha = 0.5;
		FlxG.sound.play(Paths.sound('tricky/staticSound','shared'));

		spookyText = new FlxText((x == -1111111111111 ? FlxG.random.float(boyfriend.x + 40,boyfriend.x + 120) : x), (y == -1111111111111 ? FlxG.random.float(boyfriend.y + 200, boyfriend.y + 300) : y));
		spookyText.setFormat(Paths.font("impact.ttf"), 128, FlxColor.RED);
		spookyText.bold = true;
		spookyText.text = text;
		add(spookyText);
	}

	var effect:FlxSprite;
	var auditorEffect:Bool = false;

	public function createAuditorText(text:String, x:Float = -1111111111111, y:Float = -1111111111111, ?isBF:Bool = false):Void
	{
		spookySteps = curStep;
		spookyRendered = true;
		if (curStage.contains('auditorHell'))
			Stage.tstatic.alpha = 0.5;
		else
			tstatic.alpha = 0.5;
		FlxG.sound.play(Paths.sound('tricky/staticSound','shared'));

		var posX = 1.1;
		var posY = 1.1;

		if (isBF)
		{
			posX = FlxG.random.float(boyfriend.x + 40,boyfriend.x + 120);
			posY = FlxG.random.float(boyfriend.y + 200, boyfriend.y + 300);
		}
		else
		{
			posX = FlxG.random.float(dad.x + 40,dad.x + 120);
			posY = FlxG.random.float(dad.y + 200, dad.y + 300);
		}

		auditorEffect = true;
		
		spookyText = new FlxText(posX, posY);
		spookyText.setFormat("WithoutSans-Black", 90, FlxColor.BLACK);

		spookyText.setBorderStyle(OUTLINE, FlxColor.RED, 0.7);
		effect = new FlxSprite(posX, posY).loadGraphic(Paths.image('madness/tricky/texteffect'));
		
		spookyText.bold = true;
		spookyText.text = text;
		if (posY > 279 && posX < -190)
			{
				var posX = -259;
		        var posY = 243;

				add(effect);
				add(spookyText);
			}
		else
			{
				add(effect);
				add(spookyText);
			}	
	}

	function songOutro():Void
	{
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		canPause = false;
		updateTime = false;

		if (FlxG.save.data.psychUI)
		{
			timeBarBG.visible = false;
			timeBar.visible = false;
			timeTxt.visible = false;
		}

		if (isStoryMode || showCutscene)
		{
			switch (curSong.toLowerCase())
			{
				case 'ballistic':
					picoEnd(doof4);
				default:
				{
					if (luaArray.length >= 1)
					{
						#if desktop
						var ret:Dynamic = callOnLuas('onEndSong', []);
						#else
						var ret:Dynamic = ModchartState.Function_Continue;
						#end
	
						if(luaArray[0].get('endDaSong','bool') != false)
							endSong();		
					}
					else
						endSong();
				}		
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
				{
					if (luaArray.length >= 1)
					{
						#if desktop
						var ret:Dynamic = callOnLuas('onEndSong', []);
						#else
						var ret:Dynamic = ModchartState.Function_Continue;
						#end
	
						if(luaArray[0].get('endDaSong','bool') != false)
							endSong();		
					}
					else
						endSong();
				}		
			}
		}			
	}

	var wind2:FlxSound;

	function doCustomNightMenu()
	{
		inCutscene = true;

		wind2 = new FlxSound().loadEmbedded(Paths.sound('custom_menu', 'shared'),true);
		toggleHealthShit(true);
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.returnGraphic('FNAF/ourple/customnightmenu'));
		bg.antialiasing = true;
		bg.screenCenter();
		bg.cameras = [camHUD];
		bg.active = false;
		add(bg);
		
		wind2.fadeIn();

		camHUD.fade(Std.parseInt('0xFF000000'), 1,true,null,true);

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			var bg2:FlxSprite = new FlxSprite().makeGraphic(720, 240, Std.parseInt('0xFF0000AF'));
			bg2.antialiasing = true;
			bg2.screenCenter();
			bg2.active = false;
			bg2.cameras = [camHUD];
			add(bg2);

			var lolText:FlxText = new FlxText(0, 0, 0, "Yeah this isn't a real menu.", 32);
			lolText.font = 'Pixel Arial 11 Bold';
			lolText.color = 0xFFFFFFFF;
			lolText.cameras = [camHUD];
			lolText.screenCenter();
			add(lolText);

			new FlxTimer().start(1.5, function(tmr:FlxTimer)
			{
				camHUD.fade(Std.parseInt('0xFF000000'), 1,false,null,true);
			});	

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				endSong();
				wind2.stop();
				wind2.destroy();
			});	
		});
	}

	public function endSong():Void
	{
		if (!loadRep)
			rep.SaveReplay(saveNotes);
		else
		{
			FlxG.save.data.botplay = false;
			FlxG.save.data.scrollSpeed = 1;
			FlxG.save.data.downscroll = false;
		}

		if (FlxG.save.data.fpsCap > 290)
			(cast (Lib.current.getChildAt(0), Main)).setFPSCap(290);

		canPause = false;
		isPixel = false;
		showCutscene = false;
		if (songLowercase == 'ballistic')
			picoCutscene = false;

		FlxG.sound.music.volume = 0;
		vocals.volume = 0;

		if (SONG.validScore)
		{
			// adjusting the highscore song name to be compatible
			// would read original scores if we didn't change packages
			var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");
			switch (songHighscore) {
				case 'Dad-Battle': songHighscore = 'Dadbattle';
				case 'Philly-Nice': songHighscore = 'Philly';
				case 'Scary-Swings': songHighscore = 'Scary Swings';
				case 'My-Sweets': songHighscore = 'My Sweets';
			}

			#if !switch
			Highscore.saveScore(songHighscore, Math.round(songScore), storyDifficulty);
			Highscore.saveCombo(songHighscore, Ratings.GenerateLetterRank(accuracy), storyDifficulty);
			#end

			trace('here?');
		}

		if (chartingMode)
		{
			openChartEditor();
			return;
		}

		if (isStoryMode)
		{
			campaignScore += Math.round(songScore);

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}

				MusicBeatState.switchState(new StoryMenuState());

				// if ()
				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			else
			{
				
				// adjusting the song name to be compatible
				var songFormat = StringTools.replace(PlayState.storyPlaylist[0], " ", "-");
				switch (songFormat) {
					case 'Dad-Battle': songFormat = 'Dadbattle';
					case 'Philly-Nice': songFormat = 'Philly';
					case 'Scary-Swings': songFormat = 'Scary Swings';
					case 'My-Sweets': songFormat = 'My Sweets';
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
				if (storyDifficulty == 5)
					MusicBeatState.switchState(new GuestBETADCIUState());
				else
					MusicBeatState.switchState(new BETADCIUState());
			}
			else 
			{
				if (isBonus)		
					MusicBeatState.switchState(new BonusSongsState());
				else if (isNeonight)
					MusicBeatState.switchState(new NeonightState());
				else if (isVitor)
					MusicBeatState.switchState(new VitorState());
				else
					MusicBeatState.switchState(new FreeplayState());

				//not sure if this would lag it more or less.
				/*var bools:Array<Bool> = [isBonus, isNeonight, isVitor];
				var states:Array<FlxState> = [new BonusSongsState(), new NeonightState(), new VitorState()];

				for (i in 0...bools.length)
				{
					if (bools[i])
					{
						MusicBeatState.switchState(states[i]);
						return;
					}
				}

				MusicBeatState.switchState(new FreeplayState());
				return;*/
			}
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

	var endingSong:Bool = false;

	var hits:Array<Float> = [];

	var timeShown = 0;
	var currentTimingShown:FlxText = null;
	public var ratingsAlpha:Float = 1.0;

	private function popUpScore(daNote:Note):Void
		{
			var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
			var wife:Float = EtternaFunctions.wife3(noteDiff, Conductor.timeScale);
			// boyfriend.playAnim('hey');
			vocals.volume = 1;
	
			var placement:String = Std.string(combo);
	
			var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
			coolText.screenCenter();
			coolText.x = FlxG.width * 0.55;
	
			var rating:FlxSprite = new FlxSprite();
			var score:Float = 350;

			if (FlxG.save.data.accuracyMod == 1)
				totalNotesHit += wife;

			var daRating = daNote.rating;

			switch(daRating)
			{
				case 'miss':
					daRating = 'shit'; //because i'm tired of it saying miss not found or smthn like that
					combo = 0;
				case 'shit':
					score = -300;
					combo = 0;
					if (cNum == 0)
					{
						misses++;
						health -= 0.0475;
						totalDamageTaken += 0.0475;
					}		
					ss = false;
					shits++;
					if (FlxG.save.data.accuracyMod == 0)
						totalNotesHit += 0.25;
				case 'bad':
					score = 0;
					if (cNum == 0)
					{
						health -= 0.02;
						totalDamageTaken += 0.02;
					}			
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

			if(FlxG.save.data.noteSplash && daRating == 'sick')
			{
				if (!isMania)
					spawnNoteSplash(daNote.x, daNote.y, daNote.noteData);	
			}

			/*switch (daNote.noteType)
			{
				case 2:
					health -= 2;
				case 4:
					if (daNote.isAuditorNote)
					{
						health -= 2; //ded
						FlxG.sound.play(Paths.sound('tricky/death', 'shared'));
					}
					else
					{
						if (daNote.noteType == 4) health -= 1;
					
						FlxG.sound.play(Paths.sound('burnSound'));
						noteMiss(daNote.noteData, daNote);
						playerStrums.forEach(function(spr:StrumNote)
						{
							if (pressArray[spr.ID] && spr.ID == daNote.noteData)
							{
								var smoke:FlxSprite = new FlxSprite(spr.x - spr.width + 15, spr.y - spr.height);
								smoke.frames = Paths.getSparrowAtlas('madness/tricky/Smoke');
								smoke.animation.addByPrefix('boom','smoke',24,false);
								smoke.animation.play('boom');
								smoke.setGraphicSize(Std.int(smoke.width * 0.6));
								smoke.cameras = [camHUD];
								add(smoke);
								smoke.animation.finishCallback = function(name:String) {
									remove(smoke);	
								}
							}
						});		
					}	
				case 5:
					if (daNote.blackStatic)
					{				
						health -= 0.2;
						staticHitMiss();
						noteMiss(daNote.noteData, daNote);
						vocals.volume = 0;
						FlxG.sound.play(Paths.sound('ring'), .7);
					}
				case 6:
					health -= 0.2;
					if (PlayState.SONG.player2 == 'whittyCrazy')
					{
						FlxG.sound.play(Paths.sound('burnSound'));
						noteMiss(daNote.noteData, daNote);
						playerStrums.forEach(function(spr:StrumNote)
						{
							if (pressArray[spr.ID] && spr.ID == daNote.noteData)
							{
								var smoke:FlxSprite = new FlxSprite(spr.x - spr.width + 15, spr.y - spr.height);
								smoke.frames = Paths.getSparrowAtlas('madness/tricky/Smoke');
								smoke.animation.addByPrefix('boom','smoke',24,false);
								smoke.animation.play('boom');
								smoke.setGraphicSize(Std.int(smoke.width * 0.6));
								smoke.cameras = [camHUD];
								add(smoke);
								smoke.animation.finishCallback = function(name:String) {
									remove(smoke);	
								}
							}
						});		
					}
				case 8:
					add(blackScreen);
					FlxTween.tween(blackScreen, {alpha: 0}, 5, {
						onComplete: function(tween:FlxTween)
						{
							blackScreen.destroy();
						},
					});
					FlxTween.color(healthBar, 2.20, FlxColor.RED, FlxColor.WHITE, {ease: FlxEase.quadOut});
					FlxTween.color(iconP1, 2.20, FlxColor.RED, FlxColor.WHITE, {ease: FlxEase.quadOut});
					FlxTween.color(iconP2, 2.20, FlxColor.RED, FlxColor.WHITE, {ease: FlxEase.quadOut});
					health -= 0.25;
					maxHealth -= 0.45;
					camGame.shake(0.08, 0.06, null, true);
                	camHUD.shake(0.021, 0.012, null, true);
					FlxG.sound.play(Paths.sound('funnyWord'));
					healthbarshake(3.0);
				case 9:
					health -= 0.25;
					noteMiss(daNote.noteData, daNote);
					camGame.shake(0.08, 0.06, null, true);
                	camHUD.shake(0.021, 0.012, null, true);
				case 10:
					var fuckyou:Int = 0;
					healthDrop += 0.00025;
					if (healthDrop == 0.00025)
					{
						new FlxTimer().start(0.1, function(sex:FlxTimer)
						{
							fuckyou += 1;
		
							if (fuckyou >= 100)
								healthDrop = 0;
		
							if (!paused && fuckyou < 100)
								sex.reset();
						});
					}
					else
						fuckyou = 0;
			}*/

			// trace('Wife accuracy loss: ' + wife + ' | Rating: ' + daRating + ' | Score: ' + score + ' | Weight: ' + (1 - wife));

			if (daRating != 'shit' || daRating != 'bad')
			{
	
	
			songScore += Math.round(score);
			songScoreDef += Math.round(ConvertScore.convertScore(noteDiff));
	
			var pixelShitPart1:String = "";
			var pixelShitPart2:String = '';
			var suf:String = "";

			var offsetX:Float = 0;
			var offsetY:Float = 0;

			switch (curStage)
			{
				/*case 'neon':
					offsetX = 170;
					offsetY = 170;
				case 'market':
					offsetX = 100;
					offsetY = 500;
				case 'neopolis':
					pixelShitPart1 = 'weeb/pixelUI/neon/';
				case 'school-monika' | 'school':
					offsetX = 0;
					offsetY = 0;*/
				default:
					if (usesStageHx)
					{
						offsetX = Stage.gfXOffset;
						offsetY = Stage.gfYOffset;
						pixelShitPart1 = Stage.pixelShitPart1;
						pixelShitPart2 = Stage.pixelShitPart2;
					}	
			}


			if (curStage.startsWith('school') || pixelStages.contains(curStage))
			{
				if (curStage.contains('monika'))suf = 'monika/';
				pixelShitPart1 = 'weeb/pixelUI/'+suf;
				pixelShitPart2 = '-pixel';
			}

			if (isPixel)
			{
				switch (dad.curCharacter)
				{
				//	case 'monika' | 'monika-angry' | 'monika-finale':
				//		pixelShitPart1 = 'weeb/pixelUI/monika/';
					default:
						pixelShitPart1 = 'weeb/pixelUI/';
				}	
				pixelShitPart2 = '-pixel';	
			}

			rating.loadGraphic(existsInCTA(pixelShitPart1 + daRating + pixelShitPart2));
			rating.screenCenter();
			rating.y += 200 + offsetY;
			rating.x = coolText.x - 40 + offsetX;
			rating.y -= 60;
			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);
			rating.velocity.x -= FlxG.random.int(0, 10);
			rating.alpha = ratingsAlpha;

			var msTiming = HelperFunctions.truncateFloat(noteDiff, 3);
			if(FlxG.save.data.botplay) msTiming = 0;							   
			
			comboSpr = new FlxSprite().loadGraphic(existsInCTA(pixelShitPart1 + 'combo' + pixelShitPart2));
			comboSpr.screenCenter();
			comboSpr.x = coolText.x;
			comboSpr.y += 200;
			comboSpr.acceleration.y = 600;
			comboSpr.velocity.y -= 150;
			comboSpr.alpha = ratingsAlpha;

			comboSpr.velocity.x += FlxG.random.int(1, 10);
			add(rating);
	
			if (!curStage.startsWith('school') && !isPixel && !pixelStages.contains(curStage) && pixelShitPart2 != '-pixel')
			{
				rating.setGraphicSize(Std.int(rating.width * 0.7));
				rating.antialiasing = true;
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
				comboSpr.antialiasing = true;
			}
			else
			{
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
			}
	
			comboSpr.updateHitbox();
			rating.updateHitbox();

			var seperatedScore:Array<Int> = [];
	
			var comboSplit:Array<String> = (combo + "").split('');

			// make sure we have 3 digits to display (looks weird otherwise lol)
			if (comboSplit.length == 1)
			{
				seperatedScore.push(0);
				seperatedScore.push(0);
			}
			else if (comboSplit.length == 2)
				seperatedScore.push(0);

			for(i in 0...comboSplit.length)
			{
				var str:String = comboSplit[i];
				seperatedScore.push(Std.parseInt(str));
			}
	
			var daLoop:Int = 0;
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(existsInCTA(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
				numScore.screenCenter();
				numScore.x = coolText.x + (43 * daLoop) - 90 + offsetX;
				numScore.y += 80 + 200 + offsetY;

				if (!curStage.startsWith('school') && !isPixel && !pixelStages.contains(curStage) && pixelShitPart2 != '-pixel')
				{
					numScore.antialiasing = true;
					numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				}
				else
				{
					numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
				}
				numScore.updateHitbox();
	
				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);
				numScore.alpha = ratingsAlpha;
	
				add(numScore);
		
				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002
				});
	
				daLoop++;
			}
			/* 
				trace(combo);
				trace(seperatedScore);
			 */
	
			coolText.text = Std.string(seperatedScore);
			// add(coolText);
	
			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001,
				onUpdate: function(tween:FlxTween)
				{
					if (currentTimingShown != null)
						currentTimingShown.alpha -= 0.02;
					timeShown++;
				}
			});

			FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					coolText.destroy();
					comboSpr.destroy();
					if (currentTimingShown != null && timeShown >= 20)
					{
						remove(currentTimingShown);
						currentTimingShown = null;
					}
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});
	
			curSection += 1;
			}
		}

	var pixelStages:Array<String> = ['grillbys', 'mushroom-kingdom', 'eddhouse-pixel', 'DorklyHill', 'missingno'];

	public function NearlyEquals(value1:Float, value2:Float, unimportantDifference:Float = 10):Bool
	{
		return Math.abs(FlxMath.roundDecimal(value1, 1) - FlxMath.roundDecimal(value2, 1)) < unimportantDifference;
	}

	public function existsInCTA(key:String)
	{
		var daThing:Dynamic;

		if (!Paths.currentTrackedAssets.exists(key))
			Paths.cacheImage(key);

		daThing = Paths.currentTrackedAssets.get(key);

		return daThing;
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
		var s1 = controls.S1;
		var s2 = controls.S2;
		var s3 = controls.S3;
		var s4 = controls.S4;
		var s5 = controls.S5;
		var s6 = controls.S6;

		var s1P = controls.S1_P;
		var s2P = controls.S2_P;
		var s3P = controls.S3_P;
		var s4P = controls.S4_P;
		var s5P = controls.S5_P;
		var s6P = controls.S6_P;

		var s1R = controls.S1_R;
		var s2R = controls.S2_R;
		var s3R = controls.S3_R;
		var s4R = controls.S4_R;
		var s5R = controls.S5_R;
		var s6R = controls.S6_R;

		var n0 = controls.N0;
		var n1 = controls.N1;
		var n2 = controls.N2;
		var n3 = controls.N3;
		var n4 = controls.N4;
		var n5 = controls.N5;
		var n6 = controls.N6;
		var n7 = controls.N7;
		var n8 = controls.N8;

		var n0P = controls.N0_P;
		var n1P = controls.N1_P;
		var n2P = controls.N2_P;
		var n3P = controls.N3_P;
		var n4P = controls.N4_P;
		var n5P = controls.N5_P;
		var n6P = controls.N6_P;
		var n7P = controls.N7_P;
		var n8P = controls.N8_P;

		var n0R = controls.N0_R;
		var n1R = controls.N1_R;
		var n2R = controls.N2_R;
		var n3R = controls.N3_R;
		var n4R = controls.N4_R;
		var n5R = controls.N5_R;
		var n6R = controls.N6_R;
		var n7R = controls.N7_R;
		var n8R = controls.N8_R;

		callOnLuas("setControls", []); // mainly for bonedoggle

		switch (mania)
		{
			case 1:
				holdArray = [s1, s2, s3, s4, s5, s6];
				pressArray = [s1P, s2P, s3P, s4P, s5P, s6P];
				releaseArray = [s1R, s2R, s3R, s4R, s5R, s6R];
			case 2:
				holdArray = [n0, n1, n2, n3, n4, n5, n6, n7, n8];
				pressArray = [n0P, n1P, n2P, n3P, n4P, n5P, n6P, n7P, n8P];
				releaseArray = [n0R, n1R, n2R, n3R, n4R, n5R, n6R, n7R, n8R];
			case 3:
				holdArray = [controls.LEFT, controls.DOWN, controls.T3, controls.UP, controls.RIGHT];
				pressArray = [controls.LEFT_P, controls.DOWN_P, controls.T3_P, controls.UP_P, controls.RIGHT_P];
				releaseArray = [controls.LEFT_R, controls.DOWN_R, controls.T3_R, controls.UP_R, controls.RIGHT_R];
			case 4:
				holdArray = [controls.U1, controls.U2, controls.U3, controls.U4, controls.U5, controls.U6, controls.U7];
				pressArray = [controls.U1_P, controls.U2_P, controls.U3_P, controls.U4_P, controls.U5_P, controls.U6_P, controls.U7_P];
				releaseArray = [controls.U1_R, controls.U2_R, controls.U3_R, controls.U4_R, controls.U5_R, controls.U6_R, controls.U7_R];
			default:
				holdArray = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
				pressArray = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
				releaseArray = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];
		}

		callOnLuas("setControlsPost", []); // mainly for bonedoggle
		
		#if windows
		if (luaArray.length >= 1){
		if (controls.LEFT_P){callOnLuas('keyPressed',["left"]);};
		if (controls.DOWN_P){callOnLuas('keyPressed',["down"]);};
		if (controls.UP_P){callOnLuas('keyPressed',["up"]);};
		if (controls.RIGHT_P){callOnLuas('keyPressed',["right"]);};
		};
		#end
	
		// Prevent player input if botplay is on
		if(FlxG.save.data.botplay)
		{
			switch (mania)
			{
				case 1:
					holdArray = [false, false, false, false, false, false];
					pressArray = [false, false, false, false, false, false];
					releaseArray = [false, false, false, false, false, false];
				case 2:
					holdArray = [false, false, false, false, false, false, false, false, false];
					pressArray = [false, false, false, false, false, false, false, false, false];
					releaseArray = [false, false, false, false, false, false, false, false, false];
				case 3:
					holdArray = [false, false, false, false, false];
					pressArray = [false, false, false, false, false];
					releaseArray = [false, false, false, false, false];
				case 4:
					holdArray = [false, false, false, false, false, false, false];
					pressArray = [false, false, false, false, false, false, false];
					releaseArray = [false, false, false, false, false, false, false];
				default:
					holdArray = [false, false, false, false];
					pressArray = [false, false, false, false];
					releaseArray = [false, false, false, false];
			}			
		} 
		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}
	
		// PRESSES, check for note hits
		if (pressArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			if (playBF)
				boyfriend.holdTimer = 0;

			/*if (modchartCharacters != [])
			{
				for (value in modchartCharacters.keys())
				{
					daChar = modchartCharacters.get(value);
					
					if ((daChar.isPlayer && daChar.flipMode == false || !daChar.isPlayer && daChar.flipMode == true))
						daChar.holdTimer = 0;
				}
			}*/
	
			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later
			var directionsAccounted:Array<Bool> = []; // we don't want to do judgments for more than one presses

			switch (mania)
			{
				case 1: directionsAccounted = [false, false, false, false, false, false];						
				case 2: directionsAccounted = [false, false, false, false, false, false, false, false, false];				
				case 3: directionsAccounted = [false, false, false, false, false];				
				case 4: directionsAccounted = [false, false, false, false, false, false, false];				
				default: directionsAccounted = [false, false, false, false];			
			}		
			
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

			trace('\nCURRENT LINE:\n' + directionsAccounted);
	
			for (note in dumbNotes)
			{
				FlxG.log.add("killing dumb ass note at " + note.strumTime);
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
						if (songLowercase == 'storm')
							scoreTxt.color = FlxColor.BLACK;
						else
							scoreTxt.color = FlxColor.WHITE;

						if (coolNote.burning)
							{
								if (curStage == 'auditorHell')
								{
									// lol death
									health = 0;
									shouldBeDead = true;
									FlxG.sound.play(Paths.sound('tricky/death', 'shared'));
								}
							}
						else
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

			if(dontCheck && possibleNotes.length > 0 && FlxG.save.data.ghost && !FlxG.save.data.botplay && !writing)
			{
				if (mashViolations > 8)
				{
					trace('mash violations ' + mashViolations);
					scoreTxt.color = FlxColor.RED;
					noteMiss(0,null);
				}
				else
					mashViolations++;
			}

		}
		
		notes.forEachAlive(function(daNote:Note)
		{
			if(FlxG.save.data.downscroll && daNote.y > playerStrums.members[daNote.noteData].y - 20 ||
			!FlxG.save.data.downscroll && daNote.y < playerStrums.members[daNote.noteData].y + 20 || daNote.downscroll && daNote.y > playerStrums.members[daNote.noteData].y)
			{
				// Force good note hit regardless if it's too late to hit it or not as a fail safe
				if(FlxG.save.data.botplay && daNote.canBeHit && daNote.mustPress ||
				FlxG.save.data.botplay && daNote.tooLate && daNote.mustPress)
				{
					if(loadRep)
					{
						//trace('ReplayNote ' + tmpRepNote.strumtime + ' | ' + tmpRepNote.direction);
						if(rep.replay.songNotes.contains(HelperFunctions.truncateFloat(daNote.strumTime, 2)))
						{
							goodNoteHit(daNote);

							if (playBF)
								boyfriend.holdTimer = 0;
						}
					}else 
					{
						if (!daNote.burning && !daNote.blackStatic && !daNote.ignoreNote)
						{
							goodNoteHit(daNote);

							if (playBF)
								boyfriend.holdTimer = 0;
						}		
					}
				}
			}
		});
		
		if (boyfriend.holdTimer > Conductor.stepCrochet * boyfriend.singDuration * 0.001 && (!holdArray.contains(true) || FlxG.save.data.botplay))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))	
				boyfriend.dance();
		}

		if (modchartCharacters != [])
		{
			for (value in modchartCharacters.keys())
			{
				daChar = modchartCharacters.get(value);
				
				if ((daChar.isPlayer && daChar.flipMode == false || !daChar.isPlayer && daChar.flipMode == true))
				{
					if (daChar.holdTimer > Conductor.stepCrochet * daChar.singDuration * 0.001 && (!holdArray.contains(true) || FlxG.save.data.botplay))
					{
						if (daChar.animation.curAnim.name.startsWith('sing') && !daChar.animation.curAnim.name.endsWith('miss'))	
							daChar.dance();
					}
				}
			}
		}
	
		if (!FlxG.save.data.botplay)
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

	function noteMiss(direction:Int = 1, daNote:Note):Void
	{
		if (!boyfriend.stunned)
		{
			interupt = true;
			minusHealth = true;
			health -= 0.05;
			totalDamageTaken += 0.05;
			if (combo > 5 && gf.animOffsets.exists('sad'))
				gf.playAnim('sad');

			combo = 0;
			misses++;

			//var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
			//var wife:Float = EtternaFunctions.wife3(noteDiff, FlxG.save.data.etternaMode ? 1 : 1.7);

			if (FlxG.save.data.accuracyMod == 1)
				totalNotesHit -= 1;

			songScore -= 10;

			FlxG.sound.play(existsInCTS('missnote'+FlxG.random.int(1,3)), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			var sDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
			switch (mania)
			{
				case 1: sDir = ['LEFT', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'RIGHT'];		
				case 2: sDir = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'UP', 'RIGHT'];	
				case 3: sDir = ['LEFT', 'DOWN', 'UP', 'UP', 'RIGHT'];		
				case 4:
					if (boyfriend.curCharacter.contains('-9key')){sDir = ['LEFT', 'UP', 'RIGHT', 'UP3', 'LEFT2', 'DOWN', 'RIGHT2'];}
					else{sDir = ['LEFT', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'RIGHT'];}
				default: sDir = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
				
			}

			var dType:Int = 0;

			if (daNote != null)
				dType = daNote.dType;
			else if (songStarted)
				dType = PlayState.SONG.notes[Std.int(curStep / 16)].dType;
			
			playBF = true;

			#if desktop
			if (luaArray.length >= 1)
			{
				if (luaArray[0].get("playBFSing",'bool'))
					playBF = true;
				else
					playBF = false;
			}
			#end
			
			if (playBF)
				boyfriend.playAnim('sing' + sDir[direction] + 'miss' + boyfriend.bfAltAnim, true);
			
			#if windows
			if (luaArray.length >= 1)
			{
				callOnLuas('playerOneMiss', [direction, Conductor.songPosition, dType]);

				if (daNote != null)
					callOnLuas('noteMiss', [notes.members.indexOf(daNote), direction, daNote.noteType, daNote.isSustainNote, dType]);
				else
					callOnLuas('noteMissPress', [direction, dType]);
			}
			#end

			updateAccuracy();
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

	public function staticHitMiss(?color:Int = 0)
	{
		trace ('lol you missed the static note!');

		var daNoteStatic:FlxSprite = new FlxSprite(0,0);

		daNoteStatic.frames = Paths.getSparrowAtlas('sonic/exe/hitStatic');

		daNoteStatic.setGraphicSize(FlxG.width, FlxG.height);

		daNoteStatic.screenCenter();

		if (color != 0)
		{
			var newShader:ColorSwap = new ColorSwap();
			daNoteStatic.shader = newShader.shader;

			if (color > 180) color = 180;
			if (color < -180) color = -180;
			newShader.hue = color / 360;
		}
		
		daNoteStatic.cameras = [camHUD];

		daNoteStatic.animation.addByPrefix('static','staticANIMATION', 24, false);
		daNoteStatic.animation.addByPrefix('greystatic','greystaticANIMATION', 24, false);

		switch (curStage)
		{
			case 'emptystage2' | 'street1' | 'street2' | 'street3':
				daNoteStatic.animation.play('greystatic');
			default:
				daNoteStatic.animation.play('static');
		}
		
		shakeCam2 = true;

		new FlxTimer().start(0.8, function(tmr:FlxTimer)
		{
			shakeCam2 = false;
		});

		if (SONG.song.toLowerCase() != 'killer-scream')
			FlxG.sound.play(Paths.sound("hitStatic1"));

		if (SONG.song.toLowerCase() == 'killer-scream')
			daNoteStatic.alpha = 0.5;

		add(daNoteStatic);

		daNoteStatic.animation.finishCallback = function(pog:String)
		{
			trace('ended HITSTATICLAWL');
			remove(daNoteStatic);
		}
	}

	public function doStaticSign(lestatic:Int = 0, ?leopa:Bool = true)
	{
		trace ('static MOMENT HAHAHAH ' + lestatic );
		var daStatic:FlxSprite = new FlxSprite(0, 0);

		daStatic.frames = Paths.getSparrowAtlas('sonic/exe/daSTAT');

		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		
		daStatic.screenCenter();

		daStatic.cameras = [camOther];

		switch(lestatic)
		{
			case 0:
				daStatic.animation.addByPrefix('static','staticFLASH',24, false);
		}

		add(daStatic);

		if (leopa)
		{
			if (daStatic.alpha != 0)
				daStatic.alpha = FlxG.random.float(0.1, 0.5);
		}
		else
			daStatic.alpha = 1;

		FlxG.sound.play(Paths.sound('staticBUZZ'));

		if (daStatic.alpha != 0)
			daStatic.alpha = FlxG.random.float(0.1, 0.5);

		daStatic.animation.play('static');

		daStatic.animation.finishCallback = function(pog:String)
		{
			trace('ended static');
			remove(daStatic);
		}
	}

	public function doJumpscare()
	{
		trace ('JUMPSCARE aaaa');
		
		/*switch (dad.curCharacter)
		{
			case 'exe-bw':
				daJumpscare.frames = Paths.getSparrowAtlas('sonic/exe/sonicJUMPSCARE1930');
			default:
				daJumpscare.frames = Paths.getSparrowAtlas('sonic/exe/sonicJUMPSCARE');
		}*/
		
		daJumpscare.animation.addByPrefix('jump','sonicSPOOK',24, false);
		
		daJumpscare.screenCenter();

		daJumpscare.scale.x = 1.1;
		daJumpscare.scale.y = 1.1;

		daJumpscare.y += 370;

		daJumpscare.cameras = [camHUD];

		switch (dad.curCharacter)
		{
			case 'exe-bw':
				''; //it's part of the music
			default:
				FlxG.sound.play(Paths.sound('jumpscare'), 1);
				FlxG.sound.play(Paths.sound('datOneSound'), 1);
		}
		
		add(daJumpscare);

		daJumpscare.animation.play('jump');

		daJumpscare.animation.finishCallback = function(pog:String)
		{
			trace('ended jump');
			remove(daJumpscare);
		}
	}

	public function doSimpleJump(?isRushiaNote:Bool = false)
	{
		trace ('SIMPLE JUMPSCARE');

		var simplejump:FlxSprite = new FlxSprite().loadGraphic(Paths.image('sonic/exe/simplejump'));
	
		simplejump.setGraphicSize(FlxG.width, FlxG.height);
			
		simplejump.screenCenter();
	
		simplejump.cameras = [camHUD];
		
		var timer:Float = 0.1;

		if (!isRushiaNote)
		{
			FlxG.sound.play(Paths.sound('sppok', 'exe'), 1);
			FlxG.camera.shake(0.0025, 0.50);
			timer = 0.2;
		}
			
		add(simplejump);

		new FlxTimer().start(timer, function(tmr:FlxTimer)
		{
			trace('ended simple jump');
			remove(simplejump);
		});
	}

	function updateAccuracy() 
		{
			totalPlayed += 1;
			accuracy = Math.max(0,totalNotesHit / totalPlayed * 100);
			accuracyDefault = Math.max(0, totalNotesHitDefault / totalPlayed * 100);
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

		/* if (loadRep)
		{
			if (controlArray[note.noteData])
				goodNoteHit(note, false);
			else if (rep.replay.keyPresses.length > repPresses && !controlArray[note.noteData])
			{
				if (NearlyEquals(note.strumTime,rep.replay.keyPresses[repPresses].time, 4))
				{
					goodNoteHit(note, false);
				}
			}
		} */
		
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

	function goodNoteHit(note:Note, resetMashViolation = true):Void
	{
		minusHealth = false;
			
		if (mashing != 0)
			mashing = 0;

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.CalculateRating(noteDiff);

		// add newest note to front of notesHitArray
		// the oldest notes are at the end and are removed first
		if (!note.isSustainNote)
			notesHitArray.unshift(Date.now());

		if (!resetMashViolation && mashViolations >= 1)
			mashViolations--;

		if (mashViolations < 0)
			mashViolations = 0;

		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote && !note.noRating) //i'll replace this when I find something better
			{
				popUpScore(note);
				combo += 1;
			}
			else
				totalNotesHit += 1;

			boyfriend.bfAltAnim = '';

			#if windows
			if (luaArray.length >= 1)
			{
				if (luaArray[0].get("bfAltAnim",'bool'))
					boyfriend.bfAltAnim = '-alt';
			}
			#end

			if (note.noteType == "Alt Animation")
				boyfriend.bfAltAnim = '-alt';

			if (SONG.notes[Math.floor(curStep / 16)] != null)
			{
				if (SONG.notes[Math.floor(curStep / 16)].bfAltAnim)
					boyfriend.bfAltAnim = '-alt';	
		
				if (curSong == 'Treacherous-Dads')
				{
					if (bfTransformSteps.contains(curStep) && !inCutscene)
						boyfriend.bfAltAnim = '-alt';
				}
			}

			playBF = true;

			#if desktop
			if (luaArray.length >= 1)
			{
				if (luaArray[0].get("playBFSing",'bool'))
					playBF = true;
				else
					playBF = false;
			}
			#end

			#if windows
			if (luaArray.length >= 1)
				callOnLuas('bfPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
			#end

			//before playing anims
			/*switch (note.noteType)
			{
				case 7:
					switch (boyfriend.curCharacter)
					{
						case 'rushia': //omnipresent
							FlxG.camera.shake(0.025, 0.1);
							camHUD.shake(0.010, 0.1);
							rushiaOverlayFrame = rushiaOverlayFrameMax;
							rushiaScreamOverlay.alpha = 0.2;
							boyfriend.bfAltAnim = '-alt';
					}

					switch (boyfriend1.curCharacter)
					{
						case 'rushia': //omnipresent
							FlxG.camera.shake(0.025, 0.1);
							camHUD.shake(0.010, 0.1);
							rushiaOverlayFrame = rushiaOverlayFrameMax;
							rushiaScreamOverlay.alpha = 0.2;
							boyfriend.bfAltAnim = '-alt';
					}
			}*/

			var sDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

			switch (mania)
			{
				case 1: sDir = ['LEFT', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'RIGHT'];	
				case 2: sDir = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
				case 3: sDir = ['LEFT', 'DOWN', 'UP', 'UP', 'RIGHT'];			
				case 4:
					if (boyfriend.curCharacter.contains('-9key')){sDir = ['LEFT', 'UP', 'RIGHT', 'UP3', 'LEFT2', 'DOWN', 'RIGHT2'];}		
					else{sDir = ['LEFT', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'RIGHT'];}
				default: sDir = ['LEFT', 'DOWN', 'UP', 'RIGHT'];	
			}

			if (playBF && !note.noAnimation)
				boyfriend.playAnim('sing' + sDir[note.noteData] + boyfriend.bfAltAnim, true);

			/*if (SONG.song.toLowerCase() == 'endless' || SONG.song.toLowerCase() == 'you-cant-run' || SONG.song.toLowerCase() == 'omnipresent' || SONG.song.toLowerCase() == 'four-way-fracture')
			{
				bfCamX = xOff[note.noteData];
				bfCamY = yOff[note.noteData];
			}*/
				
			#if windows
			if (luaArray.length >= 1)
				callOnLuas('playerOneSing', [note.noteData, Conductor.songPosition]);
			#end

			if(!loadRep && note.mustPress)
				saveNotes.push(HelperFunctions.truncateFloat(note.strumTime, 2));

			/*switch (SONG.song.toLowerCase())
			{
				case 'hunger':
					health -= 0.01;
				case 'ghost-vip':
					if (curStep >= 3248 && curStep < 3296)
					{
						if (FlxG.random.bool(45) && !spookyRendered && !note.isSustainNote) // create spooky text :flushed:
							createBFSpookyText(trickyLinesSing[FlxG.random.int(0,trickyLinesSing.length)]);
					}	
					if (curStep == 3304 && !spookyRendered)
						createBFSpookyText('HANK!!!');
			}*/
			switch (curStage)
			{
				/*case 'auditorHell2':
					//if (FlxG.random.bool(45) && !spookyRendered && !note.isSustainNote && boyfriend.curCharacter == 'auditor') // create spooky text :flushed:
						createAuditorText(auditorLinesSing[FlxG.random.int(0,auditorLinesSing.length)], 1, 1, true);*/
				default:
					if (usesStageHx)
						Stage.noteHit(true, notes.members.indexOf(note), Std.int(Math.abs(note.noteData)), note.isSustainNote, note.noteType, note.dType);
			}

			#if windows
				if (luaArray.length >= 1)
				{
					callOnLuas('bfNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
					callOnLuas('goodNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote, note.dType]);
				}
					
			#end
			

			if(FlxG.save.data.botplay) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)), time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
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
	var resetSpookyText:Bool = true;

	function resetSpookyTextManual():Void
	{
		trace('reset spooky');
		spookySteps = curStep;
		spookyRendered = true;
		tstatic.alpha = 0.5;
		FlxG.sound.play(Paths.sound('tricky/staticSound','shared'));
		resetSpookyText = true;
	}

	function manuallymanuallyresetspookytextmanual()
	{
		remove(spookyText);
		spookyRendered = false;
		tstatic.alpha = 0;
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {//
		var skin:String = "";
		skin = splashSkin;
		
		if(note != null) {
			skin = splashSkin;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin);
		grpNoteSplashes.add(splash);
	}

	public function spawnStartingNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {//
		var skin:String = "";
		skin = splashSkin;
		
		if(note != null) {
			skin = splashSkin;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin);
		splash.alpha = 0.0001;
		grpNoteSplashes.add(splash);
	}

	function ruvShake():Void
	{
		/*FlxG.camera.shake(0.005, 0.1);
		ruvShakeBeat = curBeat;
	
		if (curSong == 'Ugh' && curStep >= 890 && curStep < 894)
			FlxG.camera.shake(0.03, 0.1);
		
		if (gf.animation.getByName('scared') != null)
			gf.playAnim('scared', true);*/
	}

	public function bgFlash():Void
	{
		flashSprite.alpha = 0.4;		
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

	public function addTextToDebug(text:String, color:FlxColor) {
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

	public function doP3Static()
	{
		trace('p3static XDXDXD');

		daP3Static.frames = Paths.getSparrowAtlas('sonic/exe/Phase3Static');
		daP3Static.animation.addByPrefix('P3Static', 'Phase3Static instance 1', 24, false);

		daP3Static.screenCenter();

		daP3Static.scale.x = 4;
		daP3Static.scale.y = 4;
		daP3Static.alpha = 0.5;

		daP3Static.cameras = [camOther];

		add(daP3Static);

		daP3Static.animation.play('P3Static');

		daP3Static.animation.finishCallback = function(pog:String)
		{
			trace('ended p3static');
			daP3Static.alpha = 0;

			remove(daP3Static);
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

	public function doSonicIntro(suf:String, ?intro:Bool = false)
	{
		if (intro)
		{
			blackFuck = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
			startCircle = new FlxSprite();
			startText = new FlxSprite();

			add(blackFuck);
			add(startCircle);
			add(startText);

			startCircle.cameras = [camOther];
			startText.cameras = [camOther];
			blackFuck.cameras = [camOther];
		}

		startCircle.alpha = 1;
		startText.alpha = 1;
		blackFuck.alpha = 1;

		startCircle.loadGraphic(Paths.image('sonic/exe/StartScreens/Circle'+suf));
		startCircle.x += 777;
		startText.loadGraphic(Paths.image('sonic/exe/StartScreens/Text'+suf));
		startText.x -= 1200;
		new FlxTimer().start(0.6, function(tmr:FlxTimer)
		{
			FlxTween.tween(startCircle, {x: 0}, 0.5);
			FlxTween.tween(startText, {x: 0}, 0.5);
		});

		new FlxTimer().start(1.9, function(tmr:FlxTimer)
		{
			FlxTween.tween(startCircle, {alpha: 0}, 1);
			FlxTween.tween(startText, {alpha: 0}, 1);
			FlxTween.tween(blackFuck, {alpha: 0}, 1);
		});
	}

	public function doP3Jump(character:String)
	{
		trace('SIMPLE JUMPSCARE');

		var doP3JumpTAILS:FlxSprite = new FlxSprite().loadGraphic(Paths.image('sonic/exe/JUMPSCARES/'+character));

		doP3JumpTAILS.setGraphicSize(FlxG.width, FlxG.height);

		doP3JumpTAILS.screenCenter();

		doP3JumpTAILS.cameras = [camOther];

		FlxG.camera.shake(0.0025, 0.50);

		add(doP3JumpTAILS);

		if (FileSystem.exists(Paths.sound('P3Jumps/'+character+'ScreamLOL', 'shared')))
			FlxG.sound.play(Paths.sound('P3Jumps/'+character+'ScreamLOL', 'shared'), .1);
		else
		{
			if (curStep >= 0 && curStep < 1280) 
				FlxG.sound.play(Paths.sound('P3Jumps/sunkyScreamLOL', 'shared'), .1);
			if (curStep >= 1296 && curStep < 2807)
				FlxG.sound.play(Paths.sound('P3Jumps/majinScreamLOL', 'shared'), .1);
			if (curStep >= 2807)
				FlxG.sound.play(Paths.sound('P3Jumps/lord-xScreamLOL', 'shared'), .1);
		}

		new FlxTimer().start(0.2, function(tmr:FlxTimer)
		{
			trace('ended simple jump');
			remove(doP3JumpTAILS);
		});

		var balling:FlxSprite = new FlxSprite(0, 0);

		balling.frames = Paths.getSparrowAtlas('sonic/exe/daSTAT');
		balling.animation.addByPrefix('static', 'staticFLASH', 24, false);

		balling.setGraphicSize(FlxG.width, FlxG.height);

		balling.screenCenter();

		balling.cameras = [camOther];

		add(balling);

		FlxG.sound.play(Paths.sound('staticBUZZ'));

		if (balling.alpha != 0)
			balling.alpha = FlxG.random.float(0.1, 0.5);

		balling.animation.play('static');

		balling.animation.finishCallback = function(pog:String)
		{
			trace('ended static');
			remove(balling);
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

	public var video:MP4Handler;

	public function playCutscene(name:String, ?unskippable:Bool = false)
	{
		inCutscene = true;

		video = new MP4Handler();
		video.finishCallback = function()
		{
			inCutscene = false;

			if (luaArray.length >= 1)
				callOnLuas('onVideoCompleted',[name]);
			else
				startCountdown(); //if you wanna change it then change it

			//startCountdown();

			/*if (SONG.song.toLowerCase() == 'lore')
			{
				toggleHealthShit(false);
				remove(blackScreen);
				blackScreen.destroy();
			}*/
		}
		video.playVideo(Paths.video(name));
	}

	function playEndCutscene(name:String)
	{
		inCutscene = true;

		video = new MP4Handler();
		video.finishCallback = function()
		{
			if (isStoryMode)
			{
				SONG = Song.loadFromJson(storyPlaylist[0].toLowerCase());
				LoadingState.loadAndSwitchState(new PlayState());
			}
			else
				endSong();
		}
		video.playVideo(Paths.video(name));
	}

	override function stepHit()
	{
		super.stepHit();

		if (curStage == 'reactor' || curStage == 'polus' || curStage == 'polus2' || curStage == 'reactor-m')
			if (flashSprite.alpha > 0)
				flashSprite.alpha -= 0.08;

		if (SONG.notes[Std.int(curStep / 16)].dadCrossfade)
		{
			dadTrail.active = true;
		}			
		else if (!SONG.notes[Std.int(curStep / 16)].dadCrossfade)
		{
			dadTrail.active = false;
			dadTrail.resetTrail();	
		}
			
		if (SONG.notes[Std.int(curStep / 16)].bfCrossfade)
			bfTrail.active = true;	

		else if (!SONG.notes[Std.int(curStep / 16)].bfCrossfade)
		{
			bfTrail.active = false;
			bfTrail.resetTrail();
		}		

		if (usesStageHx)
			Stage.stepHit();

		dad.altAnim = "";

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			#if windows
			if (luaArray.length >= 1)
			{
				if (luaArray[0].get("dadAltAnim",'bool'))
					dad.altAnim = '-alt';
				else
					dad.altAnim = "";
			}
			#end

			if (SONG.notes[Math.floor(curStep / 16)].altAnim)
				dad.altAnim = '-alt';	
	
		}

		boyfriend.bfAltAnim = "";

		#if windows
		if (luaArray.length >= 1)
		{
			if (luaArray[0].get("bfAltAnim",'bool'))
				boyfriend.bfAltAnim = '-alt';
		}
		#end

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].bfAltAnim)
				boyfriend.bfAltAnim = '-alt';

			if (curSong == 'Treacherous-Dads')
			{
				if (bfTransformSteps.contains(curStep) && !inCutscene)
					boyfriend.bfAltAnim = '-alt';
			}
		}

		if (curSong == 'Ballistic' && dad.curCharacter == "picoCrazy")
		{
			if(shootStepsBallistic.contains(curStep) && !inCutscene)
			{
				FlxG.sound.play(Paths.sound("shooters"), 1);
				FlxG.camera.shake(0.01, 0.15);
				new FlxTimer().start(0.3, function(tmr:FlxTimer)
				{
					dad.playAnim("idle", true);
				});
			}
		}

		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
			resyncVocals();

		if (isLullaby) 
		{
			if (psyshockCooldown <= 0) 
			{	
				psyshock();

				if (dad.curCharacter == 'hypno') {
					dad.playAnim('psyshock', true);
					psyshocking = true;
					new FlxTimer().start(Conductor.stepCrochet * 4 / 1000, function(tmr:FlxTimer)
					{
						psyshocking = false;
					});
					psyshockCooldown = FlxG.random.int(70, 150);
				} else 
					psyshockCooldown = FlxG.random.int(60, 90);
			} else {
				psyshockCooldown--;
			}
		}

		/*switch (SONG.song.toLowerCase())
		{
			case 'safety-lullaby':
				#if debug
					lolText.text = Std.string(trance); //tracking this is bs
				#end
				switch (curStep % 16) {
					case 7 | 15:
						canHitPendulum = true;
					case 10 | 2:
						canHitPendulum = false;
						if (!hitPendulum)
						{
							if (skippedFirstPendulum)
								losePendulum();
							else
								skippedFirstPendulum = true;
						} 
						else						
							hitPendulum = false;
				}
			case 'you-cant-run':
				if ((curStep == 80 || curStep == 785) && vg != null) // MaliciousBunny did this
				{
					new FlxTimer().start(.085, function(sex:FlxTimer)
					{
						if (curStep >= 528 && curStep <= 784)
							vg.visible = false;
						else
							vg.visible = true;
	
						if (!paused)
							vg.alpha += 0.1;
						if (vg.alpha < 1)
						{
							sex.reset();
						}
						if (vg.alpha == 1)
						{
							new FlxTimer().start(.085, function(sex2:FlxTimer)
							{
								if (!paused)
									vg.alpha -= 0.1;
								if (vg.alpha > 0)
								{
									sex2.reset();
								}
								if (vg.alpha == 0)
									sex.reset();
							});
						}
					});
				}
		}

		switch (curSong.toLowerCase())
		{
			case 'endless':
				switch (curStep)
				{
					case 888:
						camFollowIsOn = false;
						lockedCamera = true;
						camFollow.setPosition(GameDimensions.width / 2 + 50, GameDimensions.height / 4 * 3 + 280);	
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
						funCountdown('three');
					case 891:
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
						funCountdown('two');
					case 896:
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
						funCountdown('one');
					case 899:
						camFollowIsOn = true;
						lockedCamera = false;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.7, {ease: FlxEase.cubeInOut});
						funCountdown('go');
				}	
		}


			if (curSong == 'Treacherous-Dads') 
			{
				switch (curStep)
				{
					case 272 | 276 | 284 | 304 | 512 | 514 | 518 | 672 | 780 | 806 | 896 | 898 | 900 | 902 | 988 | 1035 | 1048 | 1052 | 1054 | 1080 | 1082 | 1084 | 1086 | 1152 | 1184:
						changeStaticNotes("pixel-corrupted");
						corruptBG('corrupt');
						changeDadCharacter(100, 175, 'bitdadcrazy');
						gf.alpha = 0;
					case 274 | 278 | 288 | 312 | 648 | 680 | 1040 | 1051 | 1053 | 1055 | 1081 | 1083 | 1085 | 1087 | 1160 | 1192:
						changeStaticNotes("pixel");
						corruptBG('normal');
						gf.alpha = 1;
						changeDadCharacter(100, 175, 'bitdadBSide');	
					case 368 | 752 | 760:
						dad.playAnim('switch', false);
						gf.playAnim('switch', false);
						iconP1.useOldSystem('bf-pixeld3');
						iconP2.useOldSystem('bitdad');
					case 370 | 373 | 380 | 628 | 636 | 754 | 758 | 762 | 1012 | 1020:
						iconP1.useOldSystem('bf-pixeld3BSide');
						iconP2.useOldSystem('bitdadBSide');
					case 371 | 374 | 378 | 382 | 626 | 630 | 634 | 638 | 756 | 764 | 1010 | 1014 | 1018 | 1022:
						iconP1.useOldSystem('bf-pixeld3');
						iconP2.useOldSystem('bitdad');
					case 376 | 624 | 632 | 1008 | 1016:
						dad.playAnim('switch', false);
						gf.playAnim('switch', false);
						iconP1.useOldSystem('bf-pixeld3BSide');
						iconP2.useOldSystem('bitdadBSide');
					case 383 | 768:
						changeStaticNotes("pixel");
						changeGFCharacter(580, 430, 'gf-pixeld4');
						changeDadCharacter(100, 175, 'bitdad');
						changeBoyfriendCharacter(970, 670, 'bf-pixeld3');
					case 513 | 516 | 520 | 784 | 812 | 897 | 899 | 901 | 903 | 992:
						changeStaticNotes("pixel");
						corruptBG('normal');
						gf.alpha = 1;
						changeDadCharacter(100, 175, 'bitdad');
					case 640:
						changeStaticNotes("pixel-corrupted");
						corruptBG('corrupt');
						changeGFCharacter(580, 430, 'gf-pixeld4BSide');
						gf.alpha = 0;
						changeDadCharacter(100, 175, 'bitdadcrazy');
						changeBoyfriendCharacter(970, 670, 'bf-pixeld3BSide');		
					case 1024:
						changeStaticNotes("pixel");
						changeGFCharacter(580, 430, 'gf-pixeld4BSide');
						changeDadCharacter(100, 175, 'bitdadBSide');				
						changeBoyfriendCharacter(970, 670, 'bf-pixeld3BSide');
				}
			}*/

		#if windows
		if (luaArray.length >= 1)
		{
			setOnLuas('curStep',curStep);
			callOnLuas('stepHit',[curStep]);
			callOnLuas('onStepHit', [curBeat]);
		}
		#end

		if (spookyRendered && spookySteps + 3 < curStep)
		{
			if (resetSpookyText)
			{
				remove(spookyText);
				spookyRendered = false;

				if (auditorEffect)
				{
					remove(effect);
					auditorEffect = false;
				}
			}
			tstatic.alpha = 0;

			if (curStage.contains('auditorHell'))
				Stage.tstatic.alpha = 0.1;
		}

		// yes this updates every step.
		// yes this is bad
		// but i'm doing it to update misses and accuracy
		#if windows
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), "Acc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses  , iconRPC,true,  songLength - Conductor.songPosition);
		#end

	}

	var ruvShakeBeat:Int = 0;
	var reactorBeats = [1, 16, 32, 48, 64, 72, 80, 88, 96, 104, 112, 120, 126, 127, 128, 132, 136, 140, 144, 148, 152, 156, 160, 164, 168, 172, 176, 180, 184, 188, 448, 456, 464, 472, 476, 478, 480, 484, 488, 492, 496, 500, 504, 508, 512, 516, 520, 524, 528, 532, 536, 540, 544, 548, 552, 556, 560, 564, 568, 572, 576, 580, 584, 588, 592, 596, 600, 604];
	var danceLeft:Bool = false;
	var camtween:FlxTween;
	var camtween2:FlxTween;

	var daChar:Character;
	var daBFChar:Character;

	public var opponentIconScale:Float = 1.2;
	public var playerIconScale:Float = 1.2;

	override function beatHit()
	{
		super.beatHit();

		if (usesStageHx)
			Stage.beatHit();

		/*switch (SONG.song.toLowerCase())
		{
			case 'reactor':
				switch (curBeat)
				{
					case 128 | 319 | 607:
						defaultCamZoom = 0.7;
						camFollow.setPosition(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
					case 191 | 383:
						defaultCamZoom = 0.5;
						camFollow.setPosition(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y - 100);
					case 480:
						defaultCamZoom = 0.9;
						camFollow.setPosition(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
				}

				if (curBeat >= 128 && curBeat < 191 && camZooming && FlxG.camera.zoom < 1.35)
				{
					FlxG.camera.zoom += 0.025;
					camHUD.zoom += 0.03;
				}
				//drop 2
				if (curBeat >= 319 && curBeat < 383 && camZooming && FlxG.camera.zoom < 1.35)
				{
					FlxG.camera.zoom += 0.025;
					camHUD.zoom += 0.03;
				}
				
				if (curBeat >= 480 && curBeat < 607 && camZooming && FlxG.camera.zoom < 1.35)
				{
					FlxG.camera.zoom += 0.035;
					camHUD.zoom += 0.03;
				}

				if(reactorBeats.contains(curBeat) && !inCutscene)
					bgFlash();
			case 'bi-nb':
				if (curBeat > 0 && !shadersLoaded)
				{
					shadersLoaded = true;
					// also comment filters.push if your planning to do a disable shaders option
					filters.push(ShadersHandler.chromaticAberration);
					//filters.push(ShadersHandler.radialBlur); //this crashes it for some reason
				}	
		}

		if(curSong == 'Sussus-Moogus') // sussus flashes
		{
			var sussusBeats = [94, 95, 288, 296, 304, 312, 318, 319];
			var _b = 0;

			flashSprite.alpha = 0;
			flashSprite.scrollFactor.set(0, 0);
			
			if(curBeat == 97 || curBeat == 192 || curBeat == 320)
				_cb = 1;
				if(curBeat > 98 && curBeat < 160 || curBeat > 192 && curBeat < 224 || curBeat > 320 && curBeat < 382 || curBeat == 98 || curBeat == 160 || curBeat == 192 || curBeat == 224 || curBeat == 320 || curBeat == 382)
				{
					_cb++;
					if(_cb == 2)
					{
						bgFlash();
						_cb = 0;
					}
				}
			if(sussusBeats.contains(curBeat) && !inCutscene)
				bgFlash();
		}

		if (SONG.song.toLowerCase() == 'city-funk')
		{
			camZooming = false;
			if(camtween != null) {
				camtween.cancel();
			}
			camHUD.zoom = 1.077;
			camtween = FlxTween.tween(camHUD, {zoom: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					camtween = null;
				}
			});

			if(camtween2 != null) {
				camtween2.cancel();
			}
			camHUD.y = 20;
			camtween2 = FlxTween.tween(camHUD, {y: 0}, 0.2, {ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween) {
					camtween2 = null;
				}
			});

			danceLeft = !danceLeft;

			if (danceLeft)
			{
				iconP1.angle = 10;
				iconP2.angle = 10;
			}
			else
			{
				iconP1.angle = -10;
				iconP2.angle = -10;
			}
		}

		if (curSong == 'Norway') 
		{
			switch (curBeat)
			{
				case 64:
					Stage.swagBacks['gfBG'].gone();
				case 96:
					Stage.swagBacks['gfBG'].goBack();
			}
		}*/

		if (generatedMusic)
		{ 
			notes.sort(FlxSort.byY, (FlxG.save.data.downscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));
		}

		#if windows
		if (luaArray.length >= 1)
		{
			setOnLuas('curBeat',curBeat);
			callOnLuas('beatHit', [curBeat]);
			callOnLuas('onBeatHit', [curBeat]);
		}
		#end

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');

				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection && !dad.specialAnim)
			{
				switch (dad.curCharacter)
				{
					default:
						if (!dad.animation.curAnim.name.startsWith('sing'))
							dad.dance();
				}

				if (modchartCharacters != [])
				{
					for (value in modchartCharacters.keys())
					{
						daChar = modchartCharacters.get(value);
						
						if ((!daChar.isPlayer && daChar.flipMode == false || daChar.isPlayer && daChar.flipMode == true) && !daChar.animation.curAnim.name.startsWith("sing"))
							daChar.dance();
					}
				}
			}
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		wiggleShit.update(Conductor.crochet);

		if (FlxG.save.data.camzoom)
		{
			// HARDCODING FOR MILF ZOOMS!
			/*if ((curSong.toLowerCase() == 'milf' || curSong.toLowerCase() == 'milf-g') && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}*/
	
			if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0 && !inCutscene)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			/*if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 2 == 0 && curSong.toLowerCase() == 'ballistic')
			{
				FlxG.camera.zoom += 0.020;
				camHUD.zoom += 0.035;
			}*/
	
			iconP1.scale.set(playerIconScale, playerIconScale);
			iconP2.scale.set(opponentIconScale, opponentIconScale);

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}

		if (!boyfriend.animation.curAnim.name.startsWith("sing"))
		{
			switch (boyfriend.curCharacter)
			{
				/*case 'hex-bw':
					if (!boyfriend.animation.curAnim.name.contains('wink'))
						boyfriend.dance();
				case 'bf-aloe' | 'bf-aloe-confused':
					if (!boyfriend.animation.curAnim.name.contains('special'))
						boyfriend.dance();
				case 'bf-cesar' | 'bf-demoncesar':
					if (!boyfriend.animation.curAnim.name.contains('transition') && !picoCutscene)
						boyfriend.dance();	
				case 'sarv-ruv' | 'sarv-ruv-both':
					if (!boyfriend.animation.curAnim.name.contains('3'))
						boyfriend.dance();	
				case 'blantad-watch' | 'blantad-teleport' | 'blantad-handscutscene':
					if (!boyfriend.animation.curAnim.name.contains('special'))
						boyfriend.dance();		*/	
				default:
					boyfriend.dance();		
			}	
		}

		if (!dad.animation.curAnim.name.startsWith("sing") && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && !dad.specialAnim)
		{
			switch (dad.curCharacter)
			{
				/*case 'senpaighosty':
					if (!dad.animation.curAnim.name.contains('disappear'))
						dad.dance();
				case 'cjClone' | 'exTricky':
					if (!dad.animation.curAnim.name.contains('Hank'))
						dad.dance();
				case 'gura-amelia':
					if (!dad.animation.curAnim.name.contains('ah') && !dad.animation.curAnim.name.contains('chu'))
						dad.dance();
				case 'sky-annoyed':
					if (!dad.animation.curAnim.name.contains('special'))
						dad.dance();
				case 'cj-ruby' | 'cj-ruby-both':
					if (!dad.animation.curAnim.name.contains('2'))
						dad.dance();
				case 'bb-tired' | 'bb':
					if (curBeat % 4 == 0)
						dad.dance();*/
				default:
					dad.dance();	
			}		
		}

		if (modchartCharacters != [])
		{
			for (value in modchartCharacters.keys())
			{
				daChar = modchartCharacters.get(value);
				
				if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
				{
					if ((!daChar.isPlayer && daChar.flipMode == false || daChar.isPlayer && daChar.flipMode == true) && !daChar.animation.curAnim.name.startsWith("sing") && !daChar.specialAnim)
						daChar.dance();
				}

				if ((daChar.isPlayer && daChar.flipMode == false || !daChar.isPlayer && daChar.flipMode == true) && !daChar.animation.curAnim.name.startsWith("sing") && !daChar.specialAnim)
					daChar.dance();
			}
		}

		if (curBeat % gfSpeed == 0)
			gf.dance();

		if (boyfriend.curCharacter == 'bf-tankman-pixel' && dad.curCharacter != 'senpai-giddy' && !boyfriend.animation.curAnim.name.startsWith("sing"))
			boyfriend.animation.getByName('idle').frames = boyfriend.animation.getByName('idle-alt').frames;
	}

	var curLight:Int = 0;
}

class Pendulum extends FlxSprite
{
	public var daTween:FlxTween;
	public function new()
	{
		super();
		daTween = FlxTween.tween(this, {x: this.x}, 0.001, {});
	}
}