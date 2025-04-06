package;

import openfl.display.BlendMode;
import openfl.text.TextFormat;
import openfl.display.Application;
import flixel.util.FlxColor;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import debug.FPSCounter;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;

//crash handler stuff
#if CRASH_HANDLER
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

#if VIDEOS_ALLOWED 
import objects.PsychVideoSprite;
#end

import states.TitleState;

using StringTools;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 120; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var watermarks = true; // Whether to put Kade Engine liteartly anywhere
	public static var noCopyright:Bool = false; // For Sharkventure Copyright Stuff
	public static var isHidden:Bool = false; //Lol Hidden Menu Stuff
	public static var seenMessage:Bool = false; //Lol Hidden Restore Shit
	public static var restoreUnlocked:Bool = false; //Lol Hidden Restore Shit
	public static var realDeath:Bool = false; //now unused
	public static var cursedUnlocked:Bool = false; //Lol cursed cocoa Shit
	public static var deathHolo:Bool = false; //Lol Hidden deathmatch Shit
	public static var hiddenSongs:Array<String> = ['hunger', 'diva', 'sorrow', 'shinkyoku', 'norway', 'haachama-ex']; //Lol Hidden  stuff
	public static var keyAmmo:Array<Int> = [4, 6, 9, 5, 7];
	public static var dataJump:Array<Int> = [8, 12, 18];
	public static var isMegalo:Bool = false;
	public static var curFPS:Int = 120;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{

		// quick checks 

		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		initialState = TitleState;
		
		game = new FlxGame(gameWidth, gameHeight, initialState, #if (flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen);

		// FlxG.game._customSoundTray wants just the class, it calls new from
		// create() in there, which gets called when it's added to stage
		// which is why it needs to be added before addChild(game) here
		@:privateAccess
		game._customSoundTray = objects.FunkinSoundTray;	

		addChild(game);

		#if !mobile
		fpsCounter = new FPSCounter(3, 3, 0xFFFFFF);
		addChild(fpsCounter);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		var daBool:Bool = FlxG.save.data.showFPS;
		toggleFPS(daBool);
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if desktop
		@:privateAccess
		openfl.Lib.application.window.onFocusIn.add(onFocusIn);
		openfl.Lib.application.window.onFocusOut.add(onFocusOut);
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
			if (FlxG.cameras != null) {
			  for (cam in FlxG.cameras.list) {
			   if (cam != null && cam.filters != null)
				   resetSpriteCache(cam.flashSprite);
			  }
		   }

		   if (FlxG.game != null)
		   resetSpriteCache(FlxG.game);
	   });
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		    sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	public static function dumpCache()
	{
		///* SPECIAL THANKS TO HAYA
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null)
			{
				Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}
		Assets.cache.clear("songs");
	}
	
	var game:FlxGame;

	public static var fpsCounter:FPSCounter;

	public function toggleFPS(fpsEnabled:Bool):Void {
		fpsCounter.visible = fpsEnabled;
	}

	public function changeFPSColor(color:FlxColor)
	{
		fpsCounter.textColor = color;
	}

	public function getFPS():Float
	{
		return fpsCounter.currentFPS;
	}

	public static function getFPSStatic():Float
	{
		return fpsCounter.currentFPS;
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "BETADCIUEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/Blantados/BETADCIU-Engine-Source\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();
		Sys.exit(1);
	}
	#end

	function onFocusOut() {
		if (Type.getClass(FlxG.state) == PlayState) {
			#if VIDEOS_ALLOWED
			PsychVideoSprite.globalPause();
			#end
		}
	}

	function onFocusIn() {
		if (Type.getClass(FlxG.state) == PlayState && !PlayState.instance.paused) {
			#if VIDEOS_ALLOWED
			PsychVideoSprite.globalResume();
			#end
		}
	}
}
