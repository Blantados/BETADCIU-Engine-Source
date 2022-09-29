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
	var bf:Boyfriend;
	var camFollow:FlxObject;

	public var stageSuffix:String = "";
	var isSenpai:Bool = false;
	var isCorrupt:Bool = false;
	var noDeathAnim:Bool = false;
	var red = 51;
	var green = 51;
	var blue = 204;
	var deathTimer:FlxTimer = new FlxTimer();

	public static var characterName:String = 'bf';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public var doIdle:Bool = false;
	public var startedMusic:Bool = false;

	public static var instance:GameOverSubstate;

	public function new(x:Float, y:Float)
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		var daCharacter = PlayState.instance.boyfriend.curCharacter;
		var daBf:String = '';

		isCorrupt = false;
		isSenpai = false;
		startedMusic = false;

		if (PlayState.triggeredFlip)
		{
			FlxG.save.data.downScroll = !FlxG.save.data.downScroll;
			PlayState.triggeredFlip = false;
		}			

		switch (daCharacter)
		{
			/*case 'bf-pixel' | 'bf-pixeld4' | 'bf-pixeld4BSide':
				stageSuffix = '-pixel';
				daBf = 'bf-pixel-dead';
			case 'bf-tankman-pixel' | 'bf-pico-pixel' | 'bf-rico-pixel' | 'bf-tom-pixel' | 'bf-sonic-pixel' | 'bf-gf-pixel' | 'bf-wright-pixel' | 'bf-sans-pixel':
				stageSuffix = '-pixel';
				daBf = daCharacter + '-dead';
			case 'bf-aloe' | 'bf-aloe-confused' | 'bf-aloe-car' | 'bf1' | 'bf-aloe-past' | 'bf-aloe-deathless':	
				daBf = 'bf-aloe';
			case 'bf-aloe-corrupt':
				daBf = daCharacter;
				isCorrupt = true;
			case 'bf-nene' | 'bf-nene-scream':
				daBf = 'bf-nene';
			case 'bf-pixel-neon':
				stageSuffix = '-pixel';
				daBf = 'bf-pixel-dead';
			case 'bf-demoncesar' | 'bf-demoncesar-trollge':
				daBf = 'bf-cesar';
			case 'bf-gf' | 'bf-gf-demon':	
				daBf = 'bf-gf';	
			case 'bf-senpai-pixel' | 'bf-senpai-angry-pixel':
				stageSuffix = '-senpai';
				daBf = 'bf-senpai-pixel-dead';
				isSenpai = true;
			case 'bf-senpai-tankman':
				stageSuffix = '-senpaitankman';
				daBf = 'bf-senpai-tankman-pixel-dead';
				isSenpai = true;*/
			default:	
			{
				if (characterName != 'bf')
					daBf = characterName;
				else
					daBf = deathSpritesCheck(daCharacter);								
			}		
		}

		super();

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, daBf);
		add(bf);

		if (isSenpai)
			camFollow = new FlxObject(bf.getMidpoint().x - 300, bf.getMidpoint().y - 500, 1, 1);
		else
			camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);

		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		if (bf.animation.getByName('firstDeath') != null)
		{
			noDeathAnim = false;
			bf.playAnim('firstDeath');
		}
		else
		{
			noDeathAnim = true;
			bf.animation.pause();
		}

		deathTimer.start(2.375, function(tmr:FlxTimer)
		{
			if (!startedMusic)
			{
				startedMusic = true;

				if (!isCorrupt)
					FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));
	
				if (noDeathAnim)
					doIdle = true;
			}
		});
	}

	function deathSpritesCheck(char:String)
	{
		//a simple check to see if a dead spritesheet exists.
		var daChar:String = char;

		//in case you have two or more dashes like bf-aloe-confused. ok this really only works with two dashes but whatever.
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

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			if (PlayState.isPixel)
			{
				PlayState.isPixel = false;
			}

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else if (PlayState.isBETADCIU)
				if (PlayState.storyDifficulty == 5)
					FlxG.switchState(new GuestBETADCIUState());
				else
					FlxG.switchState(new BETADCIUState());
			else if (PlayState.isBonus)
				FlxG.switchState(new BonusSongsState());
			else if (PlayState.isNeonight)
				FlxG.switchState(new NeonightState());
			else if (PlayState.isVitor)
				FlxG.switchState(new VitorState());
			else
				FlxG.switchState(new FreeplayState());
			PlayState.loadRep = false;
		}

		new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		});

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}

		if (noDeathAnim && bf != null)
			bf.setColorTransform(0, 0, 0, 1, red, green, blue);
	}

	override function beatHit()
	{
		super.beatHit();

		if (doIdle)
			bf.dance();
				
		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			deathTimer.destroy();

			if (bf.animation.getByName('deathConfirm') != null)
				bf.playAnim('deathConfirm', true);

			if (noDeathAnim)
			{
				doIdle = false;
				FlxTween.tween(this, {'red': 255, 'blue': 255, 'green': 255}, 0.08);
				bf.animation.pause();
			}
				
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));

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
