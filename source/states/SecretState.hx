package states;

import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import lime.app.Application;
import openfl.Assets;

#if windows
import backend.Discord.DiscordClient;
#end

#if cpp
import sys.thread.Thread;
#end

using StringTools;

class SecretState extends MusicBeatState
{
	static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var lolText:FlxText;
	var lolText2:FlxText;
	var bg:FlxSprite;

	override public function create():Void
	{
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF414141;
		add(bg);

		lolText = new FlxText(0, 0, FlxG.width - 100, 32);
		lolText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		lolText.text = "Here's version 1.8 of BETADCIU Engine! All hx files are now organized in folders like 0.7+ Psych so any code that breaks when porting from 0.6 to 0.7+ Psych will probably also need to be fixed for this version. Not sure what else broke along the way so I will be fixing and reuploading all existing modpacks.\n\nMore BETADCIU Modpacks will be released soon! Hope you enjoy the update!";
		lolText.borderColor = FlxColor.BLACK;
		lolText.borderSize = 3;
		lolText.borderStyle = FlxTextBorderStyle.OUTLINE;
		lolText.screenCenter();
		add(lolText);

		lolText2 = new FlxText(0, 200, FlxG.width, 48);
		lolText2.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER);
		lolText2.text = '\n \n \n \n \n \n \n \n \nPress Enter to continue.';
		lolText2.borderColor = FlxColor.BLACK;
		lolText2.borderSize = 3;
		lolText2.borderStyle = FlxTextBorderStyle.OUTLINE;
		lolText2.screenCenter();
		lolText2.y += 50;
		add(lolText2);

		blackScreen = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 100), Std.int(FlxG.height * 100), FlxColor.BLACK);
		blackScreen.scrollFactor.set();
		add(blackScreen);

		new FlxTimer().start(0.5, function(tmr:FlxTimer)
			{
				blackScreen.alpha -= 0.05;

					if (blackScreen.alpha > 0)
					{
						tmr.reset(0.03);
					}
			});

		new FlxTimer().start(0.5, function(tmr2:FlxTimer)
			{
				lolText2.alpha = 1;

					if (lolText2.alpha == 1)
					{
						new FlxTimer().start(0.5, function(tmr3:FlxTimer)
						{
							lolText2.alpha = 0;
			
								if (lolText2.alpha == 0)
								{
									tmr2.reset(0.5);
								}
						});
					}
			});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER)
		{
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	override function beatHit()
	{
		super.beatHit();
	}
}
