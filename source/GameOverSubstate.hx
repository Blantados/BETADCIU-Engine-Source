package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxEase;
import sys.io.File;
import sys.FileSystem;
import lime.utils.Assets;

using Lambda;

class GameOverSubstate extends MusicBeatSubstate
{
	var boyfriend:Boyfriend;
	var camFollow:FlxObject;

	public var stageSuffix:String = "";
	var isSenpai:Bool = false;
	var isCorrupt:Bool = false;
	var noDeathAnim:Bool = false;
	var red = 51;
	var green = 51;
	var blue = 204;
	var deathTimer:FlxTimer = new FlxTimer();

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public var doIdle:Bool = false;
	public var startedMusic:Bool = false;

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float)
	{
		super();

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;

		var daCharacter = PlayState.instance.boyfriend.curCharacter;
		var daBf:String = '';

		isCorrupt = false;
		isSenpai = false;
		startedMusic = false;	

		switch (daCharacter)
		{
			default:	
			{
				if (characterName != 'bf-dead')
					daBf = characterName;
				else
					daBf = deathSpritesCheck(daCharacter);								
			}		
		}

		boyfriend = new Boyfriend(x, y, daBf);
		add(boyfriend);

		if (isSenpai)
			camFollow = new FlxObject(boyfriend.getMidpoint().x - 300, boyfriend.getMidpoint().y - 500, 1, 1);
		else
			camFollow = new FlxObject(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y, 1, 1);

		add(camFollow);

		FlxG.sound.play(Paths.returnSound("sounds", deathSoundName));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		if (boyfriend.animation.getByName('firstDeath') != null)
		{
			noDeathAnim = false;
			boyfriend.playAnim('firstDeath');
		}
		else
		{
			noDeathAnim = true;
			boyfriend.animation.pause();
		}

		deathTimer.start(2.375, function(tmr:FlxTimer)
		{
			if (!startedMusic)
			{
				startedMusic = true;

				if (!isCorrupt)
					FlxG.sound.playMusic(Paths.returnSound("music", loopSoundName));
	
				if (noDeathAnim)
					doIdle = true;
			}
		});
	}

	function deathSpritesCheck(char:String)
	{
		//a simple check to see if a dead spritesheet exists.
		var daChar:String = char;

		//in case you have two or more dashes like boyfriend-aloe-confused. ok this really only works with two dashes but whatever.
		var dashCount:Int = daChar.indexOf('-');

		if (dashCount >= 2)
		{
			daChar = char.split('-')[0];

			for (i in 1...dashCount)
				daChar = daChar + '-' + char.split('-')[i];
		}

		if (FileSystem.exists(Paths.jsonNew('characters/'+daChar+'-dead')) || Assets.exists(Paths.jsonNew('characters/jsons/'+daChar+'-dead')))
			return daChar+'-dead';

		if (FileSystem.exists(Paths.jsonNew('characters/'+char+'-dead')) || Assets.exists(Paths.jsonNew('characters/jsons/'+char+'-dead')))
			return char+'-dead';

		return char;		
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			if (PlayState.isPixel){
				PlayState.isPixel = false;
			}

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else if (PlayState.isBETADCIU)
				if (CoolUtil.difficulties[0] == "Guest")
					MusicBeatState.switchState(new GuestBETADCIUState());
				else
					MusicBeatState.switchState(new BETADCIUState());
			else if (PlayState.isBonus)
				MusicBeatState.switchState(new BonusSongsState());
			else if (PlayState.isNeonight)
				MusicBeatState.switchState(new NeonightState());
			else if (PlayState.isVitor)
				MusicBeatState.switchState(new VitorState());
			else
				MusicBeatState.switchState(new FreeplayState());
			PlayState.loadRep = false;

			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		});

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}

		if (noDeathAnim && boyfriend != null)
			boyfriend.setColorTransform(0, 0, 0, 1, red, green, blue);

		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();

		if (doIdle)
			boyfriend.dance();
				
		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			deathTimer.destroy();

			if (boyfriend.animation.getByName('deathConfirm') != null)
				boyfriend.playAnim('deathConfirm', true);

			if (noDeathAnim)
			{
				doIdle = false;
				FlxTween.tween(this, {'red': 255, 'blue': 255, 'green': 255}, 0.08);
				boyfriend.animation.pause();
			}
				
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.returnSound("music", endSoundName));

			if (PlayState.isPixel)
			{
				PlayState.isPixel = false;
			}
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
