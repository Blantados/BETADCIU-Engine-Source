package;

import flixel.FlxSprite;

#if windows
import Sys;
import sys.FileSystem;
#end

#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import flash.display.BitmapData;
import sys.FileSystem;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
#end

using StringTools;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public var char:String = 'bf';
	public var isPlayer:Bool = false;
	public var isOldIcon:Bool = false;
	public var hasWinning:Bool = true;

	public function new(?char:String = 'bf', ?isPlayer:Bool = false)
	{
		super();

		this.char = char;
		this.isPlayer = isPlayer;

		changeIcon(char);
		scrollFactor.set();
	}

	public function changeIcon(char:String)
	{
		if (!FileSystem.exists(Paths.image('icons/icon-' + char)) && !FileSystem.exists(Paths.modsImages('icons/icon-' + char)) && !Assets.exists(Paths.modsImages('icons/icon-' + char)))
			char = 'face';

		var rawPic:BitmapData;

		//if statements looked better
		if (FileSystem.exists(Paths.modsImages('icons/icon-' + char))){
			rawPic = BitmapData.fromFile(Paths.modsImages('icons/icon-'+char));
		}
		else if (Assets.exists(Paths.modsImages('icons/icon-' + char))){
			rawPic = OpenFlAssets.getBitmapData(Paths.modsImages('icons/icon-'+char));
		}
		else {
			rawPic = BitmapData.fromFile(Paths.image('icons/icon-'+char));
		}

		loadGraphic(rawPic, true, 150, 150);

		antialiasing = true;

		if (char.startsWith('senpai') || char.contains('pixel') || char.startsWith('spirit'))
			antialiasing = false;			

		var animArray:Array<Int> = [];

		for(i in 0...3){
			animArray.push((i <= frames.frames.length - 1 ? i : 0));
		}

		animation.add(char, animArray, 0, false, isPlayer);
		animation.play(char);
	}

	public function swapOldIcon(char:String) 
	{
		var curChar:String = char;

		if (!FileSystem.exists(Paths.image('icons/icon-' + char + '-old')))
			char = 'bf';

		if (isOldIcon)
			char = curChar;

		if(isOldIcon = !isOldIcon) changeIcon(char+'-old');
		else changeIcon(char);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	public function getCharacter():String { //idk what this does
		return char;
	}
}
