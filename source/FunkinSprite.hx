package;

import flixel.FlxG;
import openfl.utils.Assets;
import haxe.io.Path;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.util.FlxDestroyUtil;

import animateatlas.FlxAnimate;

//codename engine yeah! i want to make character.hx a little less bloated... also texture atlas

class FunkinSprite extends FlxSprite{
    public var animateAtlas:FlxAnimate = null;
    @:noCompletion public var atlasPlayingAnim:String;
    @:noCompletion public var atlasPath:String;

    /*public static function copyFrom(source:FunkinSprite) {
        var spr = new FunkinSprite();
        @:privateAccess {
            spr.setPosition(source.x, source.y);
            spr.frames = source.frames;
            if (source.animateAtlas != null && source.atlasPath != null)
                spr.loadSprite(source.atlasPath);
            spr.animation.copyFrom(source.animation);
            spr.visible = source.visible;
            spr.alpha = source.alpha;
            spr.antialiasing = source.antialiasing;
            spr.scale.set(source.scale.x, source.scale.y);
            spr.scrollFactor.set(source.scrollFactor.x, source.scrollFactor.y);
        }
        return spr;
    }

    public function loadSprite(path:String, Unique:Bool = false, Key:String = null) {
        var noExt = Path.withoutExtension(path);
        if (CoolUtil.properPathsCheck('$noExt/Animation.json')
            && CoolUtil.properPathsCheck('$noExt/spritemap1.json')
            && CoolUtil.properPathsCheck('$noExt/spritemap1.png')) {
                Assets.cache.clear(noExt);
                atlasPath = noExt;
                animateAtlas = new FlxAnimate(x, y, noExt);
            }
        else {
            frames = CoolUtil.loadFrames(path, Unique, Key, true);
        }
    }

    public function copyAtlasValues() {
        @:privateAccess {
            animateAtlas.cameras = cameras;
            animateAtlas.scrollFactor = scrollFactor;
            animateAtlas.scale = scale;
            animateAtlas.offset = offset;
            animateAtlas.rotOffset = rotOffset;
            animateAtlas.x = x;
            animateAtlas.y = y;
            animateAtlas.angle = angle;
            animateAtlas.alpha = alpha;
            animateAtlas.visible = visible;
            animateAtlas.flipX = flipX;
            animateAtlas.flipY = flipY;
            animateAtlas.shader = shader;
            animateAtlas.antialiasing = antialiasing;
        }
    }*/

    public override function update(elapsed:Float) {
        super.update(elapsed);
        if (animateAtlas != null)
            animateAtlas.update(elapsed);
    }

    public var animOffsets:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();

    public function addOffset(name:String, x:Float = 0, y:Float = 0)
    {
        animOffsets[name] = [x, y];
    }

    /*public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
    {
        if (AnimName == null) return;

        if (animateAtlas != null)  {
            @:privateAccess
            //if (!animateAtlas.anim.animsMap.exists(AnimName) && !animateAtlas.anim.symbolDictionary.exists(AnimName)) return;
            animateAtlas.anim.play(AnimName, Force, Reversed, Frame);
            atlasPlayingAnim = AnimName;
        }
        else {
            if (!animation.exists(AnimName)) return;
            animation.play(AnimName, Force, Reversed, Frame);
        }
        

        var daOffset = getAnimOffset(AnimName);
        rotOffset.set(daOffset.x, daOffset.y);
    }*/

    public inline function getAnimOffset(name:String) {
		if (animOffsets[name] != null)
			return animOffsets[name];
		return [0,0];
	}
}