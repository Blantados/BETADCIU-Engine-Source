package states;


import backend.Controls.KeyboardScheme;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import openfl.Lib;
import flixel.math.FlxMath;
import flixel.addons.display.FlxBackdrop;

using StringTools;

class MainMenuState extends MusicBeatState
{

	public static var finishedFunnyMove:Bool = false;

	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	#if !switch
	var optionShit:Array<String> = ['betadciu', 'bonus songs', 'story mode', 'freeplay', 'donate', 'options'];
	#else
	var optionShit:Array<String> = ['betadciu', 'bonus songs', 'story mode', 'freeplay'];
	#end

	var newGaming:FlxText;
	var newGaming2:FlxText;
	var newInput:Bool = true;
	var menuItem:FlxSprite;
	public static var mainMusic = true;

	public static var kadeEngineVer:String = "BETADCIU Engine";
	public static var gameVer:String = "0.2.8";
	public static var betadciuVer:String = "1.8";

	var bg:FlxSprite;
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	var curoffset:Float = 100;
	var scale:Float = 0.85;

	var firstTime:Bool = true;

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
			FlxG.sound.playMusic(Paths.music('newMenu'));
			mainMusic = true;
		}

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-100).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.10;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		if (firstTime)
		{
			camFollow = new FlxObject(700, 94, 1, 1);
			//camFollow.screenCenter();
			add(camFollow);
			firstTime = false;
		}

		magenta = new FlxSprite(-100).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.10;
		magenta.setGraphicSize(Std.int(magenta.width * 1.2));
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
		var optionshit:Int = optionShit.length;

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(curoffset, FlxG.height * 1.6);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = tex;
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			//menuItem.screenCenter(X);
			menuItems.add(menuItem);

			FlxTween.tween(menuItem,{y: 60 + (i * 170) + offset},1 + (i * 0.25) ,{ease: FlxEase.expoInOut, onComplete: function(flxTween:FlxTween) 
				{ 
					finishedFunnyMove = true; 
					changeItem();
				}});

		}

		FlxG.camera.follow(camFollow, null, 0.06 * (120 / (cast (Lib.current.getChildAt(0), Main)).getFPS()));

		var versionShit:FlxText = new FlxText(FlxG.width * 0.755, FlxG.height - 32, 0,kadeEngineVer + " Version " + betadciuVer + "\nFriday Night Funkin' Version " + gameVer, 12);
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
			
		/*var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);

		camFollow.setPosition(FlxMath.lerp(camFollow.x, camFollow.x, lerpVal), FlxMath.lerp(camFollow.y, camFollow.y, lerpVal));*/

		if (!selectedSomethin)
		{
			if (controls.UP_P && finishedFunnyMove)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);	
			}

			if (controls.DOWN_P && finishedFunnyMove)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK && finishedFunnyMove)
			{
				curSelected = 0;
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT && finishedFunnyMove)
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
							FlxTween.tween(spr, {alpha: 0}, 1.2, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxTween.tween(spr, {x: curoffset+120}, 1.3, {
								ease: FlxEase.expoOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});

							FlxTween.tween(spr, {"scale.x": scale + 0.1,"scale.y": scale + 0.1}, 1.2, {
								ease: FlxEase.cubeOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});

							FlxFlicker.flicker(spr, 1, 0.06, true, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'betadciu':
										finishedFunnyMove = false;
										MusicBeatState.switchState(new BETADCIUState());
										trace("BETADCIU Menu Selected");

									case 'story mode':
										finishedFunnyMove = false;
										MusicBeatState.switchState(new StoryMenuState());
										trace("Story Mode Menu Selected");

									case 'bonus songs':
										finishedFunnyMove = false;
										MusicBeatState.switchState(new BonusSongsState());
										trace("Bonus Songs Menu Selected");

									case 'neonight':
										finishedFunnyMove = false;
										MusicBeatState.switchState(new NeonightState());
										trace("Neonight Menu Selected");

									case 'vitor':
										finishedFunnyMove = false;
										MusicBeatState.switchState(new VitorState());
										trace("Vitor Menu Selected");
									
									case 'options':
										finishedFunnyMove = false;
										MusicBeatState.switchState(new options.OptionsState());

									case 'extras':
										finishedFunnyMove = false;
										MusicBeatState.switchState(new GuestBETADCIUState());
										trace("Extras Menu Selected");

									case 'freeplay':
										finishedFunnyMove = false;
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
		if (finishedFunnyMove)
		{
			curSelected += huh;

			if (curSelected >= menuItems.length)
				curSelected = 0;
			if (curSelected == -2)
				curSelected = menuItems.length - 2;
			if (curSelected < 0)
				curSelected = menuItems.length - 1;
		}

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');

			if (spr.ID == curSelected && finishedFunnyMove)
			{
				spr.animation.play('selected');

				if (spr.ID < 6)
					camFollow.setPosition(700, spr.getGraphicMidpoint().y);
					//trace(spr.getGraphicMidpoint().y);
			}

			spr.updateHitbox();
		});

		/*var selectedX:Array<Float> = [100, 100, 100, 100];
		var selectedY:Array<Float> = [60, 240, 420, 600];
		var staticX:Array<Float> = [100, 100, 100, 100];
		var staticY:Array<Float> = [60, 240, 420, 600];

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
		}*/
	}
}
