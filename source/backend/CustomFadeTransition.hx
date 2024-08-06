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
		transitionSprite.scrollFactor.set(0, 0);
		add(transitionSprite);

		if (isTransIn)
		{
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
			transitionSprite.x = -2600;

			FlxTween.tween(transitionSprite, { x: -620 }, 0.4, {
				onComplete: function(twn:FlxTween)
				{
					finishCallback();
				}
			});

		}

		//quick fix for the character editor/stage editor
		var transitionCamera = new FlxCamera();
		transitionCamera.bgColor.alpha = 0;
		FlxG.cameras.add(transitionCamera, false);

		transitionSprite.cameras = [transitionCamera];
		//
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
