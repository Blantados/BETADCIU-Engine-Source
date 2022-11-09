package;

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

using StringTools;

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
}
