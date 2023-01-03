package;

import Controls.KeyboardScheme;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;

#if desktop
import Discord.DiscordClient;
#end

using StringTools;

class MainMenuState extends MusicBeatState
{
	var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	#if !switch
	var optionShit:Array<String> = ['betadciu', 'bonus songs', 'neonight', 'vitor', 'donate', 'options', 'extras', 'freeplay'];
	#else
	var optionShit:Array<String> = ['betadciu', 'bonus songs', 'neonight', 'vitor', 'extras', 'freeplay'];
	#end

	var newGaming:FlxText;
	var newGaming2:FlxText;
	var newInput:Bool = true;
	var menuItem:FlxSprite;
	public static var mainMusic = true;

	public static var kadeEngineVer:String = "BETADCIU Engine";
	public static var gameVer:String = "0.2.8";
	public static var betadciuVer:String = "Version 1.4";

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	override function create()
	{
		FlxG.mouse.visible = false;
		activated = false;

		PlayState.customLoaded = false;
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		if (!FlxG.sound.music.playing || !mainMusic)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.18;
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		add(magenta);
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var tex = Paths.getSparrowAtlas('FNF_main_menu_assets');
		var menuItemX:Array<Float> = [100, 680, 100, 800, 150, 800, 150, 800];
		var menuItemY:Array<Float> = [60, 60, 240, 240, 420, 420, 600, 600];
		var menuItemSize:Array<Float> = [0.75, 0.65, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85];

		for (i in 0...optionShit.length)
		{
			menuItem = new FlxSprite(menuItemX[i], menuItemY[i]);
			menuItem.frames = tex;
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.setGraphicSize(Std.int(menuItem.width * menuItemSize[i]) * (FlxG.save.data.poltatoPC ? 2 : 1));
			menuItem.updateHitbox();
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
			menuItem.centerOffsets();
		}

		FlxG.camera.follow(camFollow, null, 0.06);

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, gameVer + " FNF - " + kadeEngineVer + " " + betadciuVer, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		if (FlxG.save.data.dfjk)
			controls.setKeyboardScheme(KeyboardScheme.Solo, true);
		else
			controls.setKeyboardScheme(KeyboardScheme.Duo(true), true);

		changeItem();

		Main.isHidden = false;
		
		super.create();
	}

	var selectedSomethin:Bool = false;
	var activated:Bool = false;
	var itemX:Array<Float> = [];

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
			
		if (!selectedSomethin)
		{
			if (controls.UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-2);	
			}

			if (controls.DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(2);
			}

			if (controls.RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.BACK)
			{
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					#if linux
					Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
					#else
					FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
					#end
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 1.3, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'betadciu':
										MusicBeatState.switchState(new BETADCIUState());
										trace("BETADCIU Menu Selected");

									case 'bonus songs':
										MusicBeatState.switchState(new BonusSongsState());
										trace("Bonus Songs Menu Selected");

									case 'neonight':
										MusicBeatState.switchState(new NeonightState());
										trace("Neonight Menu Selected");

									case 'vitor':
										MusicBeatState.switchState(new VitorState());
										trace("Vitor Menu Selected");
									
									case 'options':
										MusicBeatState.switchState(new OptionsMenu());

									case 'extras':
										MusicBeatState.switchState(new GuestBETADCIUState());
										trace("Extras Menu Selected");

									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
										trace("Freeplay Menu Selected");

								}
							});
						}
					});
				}
			}
		}
		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected == -2)
			curSelected = menuItems.length - 2;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');

				if (spr.ID < 6)
					camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
			}

			spr.updateHitbox();
		});

		var selectedX:Array<Float> = [40, 600, 60, 750, 100, 750, 110, 750];
		var selectedY:Array<Float> = [50, 50, 230, 230, 410, 410, 590, 580];
		var staticX:Array<Float> = [100, 680, 100, 800, 150, 800, 150, 800];
		var staticY:Array<Float> = [60, 60, 240, 240, 420, 420, 600, 600];

		for (i in 0...menuItems.members.length)
		{
			if (menuItems.members[i].animation.curAnim.name == 'selected')
			{
				menuItems.members[i].x = selectedX[i];
				menuItems.members[i].y = selectedY[i];
			}
			else if (menuItems.members[i].animation.curAnim.name != 'selected')
			{
				menuItems.members[i].x = staticX[i];
				menuItems.members[i].y = staticY[i];
			}
		}
	}
}
