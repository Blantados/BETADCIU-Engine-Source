package backend;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import backend.Conductor.BPMChangeEvent;
import backend.MusicBeatState;
// import states.substates.MusicBeatSubstate;

class CustomFadeTransition extends MusicBeatSubstate
{
	public static var finishCallback:Void->Void;

	private var leTween:FlxTween = null;

	public static var nextCamera:FlxCamera;

	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var transitionSprite:FlxSprite;

	public function new(duration:Float, isTransIn:Bool)
	{
		super();

		this.isTransIn = isTransIn;

		var width:Int = Std.int(FlxG.width);
		var height:Int = Std.int(FlxG.height);
		
		transitionSprite = new FlxSprite(-2600);
		transitionSprite.loadGraphic(Paths.image('transition thingy'));
		//transitionSprite.frames = Paths.getSparrowAtlas('circle thing', 'preload');
		//transitionSprite.animation.addByPrefix('transition', 'kevin_normal', 60, false);
		transitionSprite.scrollFactor.set(0, 0);
		add(transitionSprite);

		if (isTransIn)
		{
			//transitionSprite.animation.play('transition', true, true, 28);
			//transitionSprite.animation.callback = function(anim, framenumber, frameindex)
			//{
				//if (framenumber == 0)
					//close();
			//}

			transitionSprite.x = -620;

			FlxTween.tween(transitionSprite, { x: 1280 }, 0.4, {
				onComplete: function(twn:FlxTween)
				{
					close();
				}
			});
		}
		else
		{
			// transitionSprite.animation.play('transition', true);
			// transitionSprite.animation.callback = function(anim, framenumber, frameindex)
			// {
				//if (finishCallback != null && framenumber == 28)
				//{
					//finishCallback();
				//}
			//}

			transitionSprite.x = -2600;

			FlxTween.tween(transitionSprite, { x: -620 }, 0.4, {
				onComplete: function(twn:FlxTween)
				{
					finishCallback();
				}
			});

		}

		if (nextCamera != null)
		{
			transitionSprite.cameras = [nextCamera];
		}
		nextCamera = null;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	override function destroy()
	{
		if (leTween != null)
		{
			finishCallback();
			leTween.cancel();
		}
		super.destroy();
	}
}
