package options;

import flash.text.TextField;
import flixel.addons.display.FlxGridOverlay;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import openfl.Lib;

using StringTools;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		/*var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			'bool', //Variable type
			"false"); //Default value
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing',
			'bool',
			"true");
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);*/

		var maxThreads:Int = Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS")); //trying to implement this cool thing i found on Sonic Legacy's source code
		if (maxThreads > 1) {
			var option:Option = new Option('Multi-thread Loading', //Name
			"If checked, the engine can use multiple threads to speed up loading times on some songs.\nRecommended to leave on, unless it causes crashing\nWARNING: Doesn't work with GPU Rendering.", //Description
			'multicoreLoading', //Save data variable name
			'bool'); //Variable type
			addOption(option);

			option.defaultValue = false;

			var option:Option = new Option('Loading Threads', //Name
				'How many threads the game can use to load graphics when using Multi-thread Loading.\nThe maximum amount of threads depends on your processor\nWARNING: Higher count of threads can cause crashes while loading.', //Description
				'loadingThreads', //Save data variable name
				'int' //Variable type
			);

			option.defaultValue = Math.floor(maxThreads/2);
			option.minValue = 1;
			option.maxValue = Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"));
			option.displayFormat = '%v';

			addOption(option);
		}
		
		var option:Option = new Option('Reduced Graphics', //Name
			'If checked, lowers image quality for better performance,\nWarning: Will screw with a lot of character cameras.', //Description
			'poltatoPC', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		var option:Option = new Option('Shaders', //Name
			'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.', //Description
			'shaders', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		option.defaultValue = true;

		//I LOVE KADE ENGINE LEGACY!!!
		var option:Option = new Option('GPU Rendering', //Name
			"If checked, loads sprites into VRAM on the GPU.\nWARNING: Doesn't work with Multi-thread Loading.", //Description
			'useGL', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int');
		addOption(option);

		option.minValue = 60;
		option.maxValue = 240;
		option.defaultValue = 120;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		super();
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; //Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; //Don't judge me ok
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		var framerate = ClientPrefs.data.framerate;

		FlxG.save.flush();
		ClientPrefs.saveSettings();//i didn't find any other way to make this engine work with this.
		//trace(ClientPrefs.data.framerate);

		openfl.Lib.current.stage.frameRate = framerate;
		Main.curFPS = framerate;

		if(framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = framerate;
			FlxG.drawFramerate = framerate;
		}else{
			FlxG.drawFramerate = framerate;
			FlxG.updateFramerate = framerate;
		}
	}
}