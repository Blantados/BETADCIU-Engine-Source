package objects;

import openfl.utils.Assets;
import haxe.io.Path;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

//codename engine yeah! i want to make character.hx a little less bloated... also texture atlas

class FunkinSprite extends FlxSprite{
    public var animateAtlas:FlxAnimate = null;
    @:noCompletion public var atlasPlayingAnim:String;
    @:noCompletion public var atlasPath:String;

    public var animOffsets:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();

    public function addOffset(name:String, x:Float = 0, y:Float = 0)
    {
        animOffsets[name] = [x, y];
    }

    public inline function getAnimOffset(name:String) {
		if (animOffsets[name] != null)
			return animOffsets[name];
		return [0,0];
	}
}