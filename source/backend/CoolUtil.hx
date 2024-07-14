package backend;

import flash.display.BitmapData;
import lime.utils.Assets;
import lime.app.Application;
import openfl.display.BitmapData;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import openfl.utils.Assets;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.FlxGraphic;
import haxe.io.Path;
import flixel.FlxSprite;

using StringTools;

@:allow(PlayState)
class CoolUtil
{
	public static var difficultyArray:Array<String> = ['Easy', "Normal", "Hard", "Neonight", "Vitor0502", ""];
	public static var guestArray:Array<String> = ['Snow The Fox', "spres", 'AjTheFunky', "LiterallyNoOne", 'Lylace', 'Tactical Cupcakes', 'Chxwy', 'Mewrk'];

	public static var defaultDifficulties:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	inline public static function capitalize(text:String){
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}
		
	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if(fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString2():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	public static function resizeXML(rawXml:String, factor:Float)
	{
		var daXml:Xml = Xml.parse(rawXml);
		var fast = new haxe.xml.Access(daXml);
		var users = fast.node.TextureAtlas;
		for (SubTexture in users.nodes.SubTexture) {
			SubTexture.att.x = Std.string(Std.parseInt(SubTexture.att.x) * factor);
			SubTexture.att.y = Std.string(Std.parseInt(SubTexture.att.y) * factor);
			SubTexture.att.width = Std.string(Std.parseInt(SubTexture.att.width) * factor);
			SubTexture.att.height = Std.string(Std.parseInt(SubTexture.att.height) * factor);

			if (SubTexture.has.frameX)
			{
				SubTexture.att.frameX = Std.string(Std.parseInt(SubTexture.att.frameX) * factor);
				SubTexture.att.frameY = Std.string(Std.parseInt(SubTexture.att.frameY) * factor);
				SubTexture.att.frameWidth = Std.string(Std.parseInt(SubTexture.att.frameWidth) * factor);
				SubTexture.att.frameHeight = Std.string(Std.parseInt(SubTexture.att.frameHeight) * factor);
			}
		}
		return Std.string(daXml);
	}

	public static function resetSprite(spr:FlxSprite, x:Float, y:Float) {
		spr.reset(x, y);
		spr.alpha = 1;
		spr.visible = true;
		spr.active = true;
		//spr.antialiasing = FlxSprite.defaultAntialiasing;
		//spr.rotOffset.set();
	}

	public static function resetSpriteAttributes(spr:FlxSprite)
	{
		spr.scale.x = 1;
		spr.scale.y = 1;
		spr.offset.x = 0;
		spr.offset.y = 0;
		spr.shader = null;
		spr.alpha = 1;
		spr.visible = true;
		spr.flipX = false;
		spr.flipY = false;

		spr.centerOrigin();
	}

	public static inline function addZeros(str:String, num:Int) {
		while(str.length < num) str = '0${str}';
		return str;
	}

	public static function findFirstAnim(rawXml:String)
		{
			var daXml:Xml = Xml.parse(rawXml);
			var fast = new haxe.xml.Access(daXml);
			var users = fast.node.TextureAtlas;

			var placeholder:String = "bruhtf";

			for (SubTexture in users.nodes.SubTexture) {
				var name = Std.string(SubTexture.att.name);
				var nameCut = name.substr(0, name.length - 4);

				trace ("returned anim is " + nameCut);
				return nameCut;
			}

			return placeholder;
		}
	
	public static function resizeTxt(rawTxt:String, factor:Float)
	{
		var daTxt:String = "";
		var pack = StringTools.trim(rawTxt);
		var lines:Array<String> = pack.split("\n");

		for (i in 0...lines.length)
		{
			var currImageData = lines[i].split("=");
			var name = StringTools.trim(currImageData[0]);
			var currImageRegion = StringTools.trim(currImageData[1]).split(" ");
			var newCurrImageRegion:Array<String> = [];

			for (i in 0...currImageRegion.length)
			{
				var daNo:Int = Std.parseInt(currImageRegion[i]);
				var newNo:Int = Std.int(daNo*factor);

				newCurrImageRegion.push(Std.string(newNo));
			}

			daTxt += name + " = ";

			for (i in 0...newCurrImageRegion.length){
				daTxt += newCurrImageRegion[i] + (i != newCurrImageRegion.length-1 ? ' ' : "");
			}
		}

		return Std.string(daTxt);
	}

	public static function difficultyString():String
	{
		var guestNumber:Int = 0;

		if (PlayState.storyDifficulty == 5)
		{
			switch (PlayState.SONG.song.toLowerCase())
			{
				case 'epiphany' | 'bonedoggle': guestNumber = 0;
				case "rabbit's-luck": guestNumber = 1;
				case "arch": guestNumber = 2;
				case 'ghost-vip': guestNumber = 3;
				case 'you-cant-run': guestNumber = 4;
				case "its-complicated": guestNumber = 5;
				case "buildstroll": guestNumber = 6;
				case 'ballistic': guestNumber = 7;
			}

			return guestArray[guestNumber];
		}
		else
			return difficultyArray[PlayState.storyDifficulty];
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
			  var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  if(colorOfThisPixel != 0){
				  if(countByColor.exists(colorOfThisPixel)){
				    countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
				  }else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)){
					 countByColor[colorOfThisPixel] = 1;
				  }
			  }
			}
		 }
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
			for(key in countByColor.keys()){
			if(countByColor[key] >= maxCount){
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	inline public static function colorFromString(color:String):FlxColor
	{
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

	public static function loadFrames(path:String, Unique:Bool = false, Key:String = null, SkipAtlasCheck:Bool = false):FlxFramesCollection {
		var noExt = Path.withoutExtension(path);

		if (properPathsCheck('$noExt/1.png')) {
			// MULTIPLE SPRITESHEETS!!

			var graphic = FlxG.bitmap.add("flixel/images/logo/default.png", false, '$noExt/mult');
			var frames = FlxAtlasFrames.findFrame(graphic);
			if (frames != null)
				return frames;

			trace("no frames yet for multiple atlases!!");
			var spritesheets = [];
			var cur = 1;
			var finalFrames = new FlxFramesCollection(graphic, ATLAS);
			while(properPathsCheck('$noExt/$cur.png')) {
				spritesheets.push(loadFrames('$noExt/$cur.png'));
				cur++;
			}
			for(frames in spritesheets)
				if (frames != null && frames.frames != null)
					for(f in frames.frames)
						if (f != null) {
							finalFrames.frames.push(f);
							f.parent = frames.parent;
						}
			return finalFrames;
		} /*else if (!SkipAtlasCheck && properPathsCheck('$noExt/Animation.json')
		&& properPathsCheck('$noExt/spritemap.json')
		&& properPathsCheck('$noExt/spritemap.png')) {
			return AtlasFrameMaker.construct(noExt);
		} */else if (properPathsCheck('$noExt.xml')) {
			return Paths.getSparrowAtlas(noExt);
		} else if (properPathsCheck('$noExt.txt')) {
			return Paths.getPackerAtlas(noExt);
		}

		var graph:FlxGraphic = FlxG.bitmap.add(path, Unique, Key);
		if (graph == null)
			return null;
		return graph.imageFrame;
	}

	public static function properPathsCheck(path:String)
	{
		if (Assets.exists(path) || FileSystem.exists(path) || FileSystem.exists(Paths.modFolders(path)))
			return true;

		return false;
	}

	public static function coolTextFile2(path:String):Array<String>
	{
		var daList:Array<String> = File.getContent(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	
	public static function coolStringFile(path:String):Array<String>
		{
			var daList:Array<String> = path.trim().split('\n');
	
			for (i in 0...daList.length)
			{
				daList[i] = daList[i].trim();
			}
	
			return daList;
		}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

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
			default:
				text.borderStyle = NONE;
		}
	}
}