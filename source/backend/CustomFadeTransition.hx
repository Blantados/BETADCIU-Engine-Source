package backend;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	private var leTween:FlxTween = null;
	var isTransIn:Bool = false;
	var transitionSprite:FlxSprite;

	var duration:Float;
	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
		var width:Int = Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
		var height:Int = Std.int(FlxG.height / Math.max(camera.zoom, 0.001));
		transitionSprite = new FlxSprite(-2600);
		transitionSprite.loadGraphic(Paths.image('transition thingy'));
		transitionSprite.scrollFactor.set(0, 0);
		add(transitionSprite);

		if(isTransIn){
			transitionSprite.x = -620;

			FlxTween.tween(transitionSprite, { x: 1280 }, 0.4, {
				onComplete: function(twn:FlxTween)
				{
					close();
				}
			});
		}else{
			transitionSprite.x = -2600;

			FlxTween.tween(transitionSprite, { x: -620 }, 0.4, {
				onComplete: function(twn:FlxTween)
				{
					finishCallback();
					finishCallback = null; // pls don't remove this.
				}
			});
		}

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	// Don't delete this
	override function close():Void
	{
		if(finishCallback != null)
		{
			finishCallback();
			finishCallback = null;
		}

		super.close();
	}
}
