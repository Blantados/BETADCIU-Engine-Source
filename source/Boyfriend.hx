package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;

using StringTools;

class Boyfriend extends Character
{

	public function new(x:Float, y:Float, ?char:String = 'bf', ?isPlayer:Bool = true)
	{
		super(x, y, char, isPlayer);
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null && !debugMode)
		{
			if (animation.curAnim.name.startsWith('sing')){
				holdTimer += elapsed;
			}
			else
				holdTimer = 0;
			
			if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished) {
				if (animOffsets.exists('idle')) {
					playAnim('idle', true, false, 10);
				} else {
					dance();
				}
			}

			if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished)
			{
				playAnim('deathLoop');
			}
		}

		super.update(elapsed);
	}
}
