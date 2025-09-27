package backend;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.media.AudioBuffer;
import haxe.io.Bytes;

class CoolUtil
{
	public static function checkForUpdates(url:String = null):String {
		if (url == null || url.length == 0)
			url = "https://raw.githubusercontent.com/Blantados/BETADCIU-Engine-Source/Psych-Based/gitVersion.txt";
		var version:String = states.MainMenuState.betadciuEngineVersion.trim();
		if(ClientPrefs.data.checkForUpdates) {
			trace('checking for updates...');
			var http = new haxe.Http(url);
			http.onData = function (data:String)
			{
				var newVersion:String = data.split('\n')[0].trim();
				trace('version online: $newVersion, your version: $version');
				if(newVersion != version) {
					trace('versions arent matching! please update');
					version = newVersion;
					http.onData = null;
					http.onError = null;
					http = null;
				}
			}
			http.onError = function (error) {
				trace('error: $error');
			}
			http.request();
		}
		return version;
	}
	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		//trace(snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		if(FileSystem.exists(path)) daList = File.getContent(path);
		#else
		if(Assets.exists(path)) daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor { // better now.
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		var alpha:Float = 1;

		if(color.startsWith('0x')){
			//alpha stuff
			if (color.length == 10){
				var alphaHex:String = color.substr(2, 2);
				alpha = Std.parseInt("0x" + alphaHex) / 255.0;
			}
			
			color = color.substring(color.length - 6);
		}

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		colorNum.alphaFloat = alpha;

		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth)
		{
			for(row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key => count in countByColor)
		{
			if(count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static  function removeDupe(arr:Array<String>):Array<String> {
		var result:Array<String> = [];
		for (item in arr) {
			if (!result.contains(item)) {
				result.push(item);
			} else {
				trace('heh. just removed a dupe of ${item}. no need to thank me');
			}
		}
		return result;
	}
	
	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch(border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			case 'outline_full', 'outlinefull':
				text.borderStyle = OUTLINE_FULL;
			default:
				text.borderStyle = NONE;
		}
	}

	public static function blendColors(bgColor: Int, ovColor: Int): Int {
        var a_bg = (bgColor >> 24) & 0xFF;
        var r_bg = (bgColor >> 16) & 0xFF;
        var g_bg = (bgColor >> 8) & 0xFF;
        var b_bg = bgColor & 0xFF;
        
        var a_ov = (ovColor >> 24) & 0xFF;
        var r_ov = (ovColor >> 16) & 0xFF;
        var g_ov = (ovColor >> 8) & 0xFF;
        var b_ov = ovColor & 0xFF;

        var alpha = a_ov + (a_bg * (255 - a_ov) / 255);
        var red = r_ov * (a_ov / 255) + r_bg * (1 - (a_ov / 255));
        var green = g_ov * (a_ov / 255) + g_bg * (1 - (a_ov / 255));
        var blue = b_ov * (a_ov / 255) + b_bg * (1 - (a_ov / 255));

        return (Std.int(alpha) << 24) | (Std.int(red) << 16) | (Std.int(green) << 8) | Std.int(blue);
    }

	// Just in case this would have a use anywhere else
	public static function returnSampleLevelAtTime(buffer:AudioBuffer, curTime:Float = 0){
		var sampleMult:Float = buffer.sampleRate / 44100;
		var index:Int = Std.int(curTime * sampleMult);
		var drawIndex:Int = 0;
		var samplesPerRow = 1;
		var waveBytes:Bytes = buffer.data.toBytes();

		var min:Float = 0;
		var max:Float = 0;
		
		var byte:Int = waveBytes.getUInt16(index * 4);

		if (byte > 65535 / 2)
			byte -= 65535;

		var sample:Float = (byte / 65535);

		if (sample > 0)
		{
			if (sample > max)
				max = sample;
		}
		else if (sample < 0)
		{
			if (sample < min)
				min = sample;
		}

		return max + min;
	}

	public static function toTitleCase(str:String):String {
		return str.split(" ").map(function(word) {
			return (word.length > 0) ? word.charAt(0).toUpperCase() + word.substr(1).toLowerCase() : "";
		}).join(" ");
	}
}
