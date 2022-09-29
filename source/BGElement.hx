package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

//could just convert to flxsprite but i'm lazy.
class BGElement extends FlxSprite
{
	
	var sc:Float = 1;
	var sz:Float = 1;
	var movID:Int = 0;
	var imgName:String = 'none';

	var time:Float = 0;
	public function new(image:String, sX:Float, sY:Float, scroll:Float, size:Float, movid:Int)
	{
		movID = movid;
		x = sX;
		y = sY;
		super(x, y);
		sc = scroll;
		imgName = image;
		loadGraphic(Paths.image(imgName));
		scrollFactor.set(sc, sc);
		antialiasing = true;
		setGraphicSize(Std.int(width * (size)));

		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
