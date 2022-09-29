package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxKeyManager;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

#if windows
import Sys;
import sys.FileSystem;
import sys.io.File;
#end

//from senpai and tankman mod. old system was messy but didn't want to use psych's dialogue system since well... this engine is for BETADCIUs not story stuff.

using StringTools;

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;
	var animName:String;
	var realCharacter:String;

	public static var curCharacter:String = '';
	public static var oldCharacter:String = '';

	var dialogue:Alphabet;
	var dialogueList:Array<String> = [];

	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagDialogue:FlxTypeText;
	public static var detectDialogue:FlxText; //for those switch character commands

	var dropText:FlxText;

	public var finishThing:Void->Void;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;
	var portraitLeftPixel:FlxSprite;
	var portraitRightPixel:FlxSprite;
	var isPixelBox:Bool;
	var tex:FlxAtlasFrames;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;

	public static var curEmotion:String = 'normal';
	public static var emotion:String = '';
	public static var oldEmotion:String = '';
	public static var isLeft:Bool = false;
	public static var isRight:Bool = false;
	public static var isLeftPixel:Bool = false;
	public static var isRightPixel:Bool = false;
	var curFlip:String = 'false';
	var canFlip:Bool = false;

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{
		super();

		isPixelBox = false;
		canFlip = false;
		isLeft = false;
		isRight = false;
		isLeftPixel = false;
		isRightPixel = false;

		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'senpai-medley' | 'high-school-conflict' | 'monika':
				FlxG.sound.playMusic(Paths.music('Lunchbox', 'week6'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			case 'thorns':
				FlxG.sound.playMusic(Paths.music('LunchboxScary', 'week6'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			case 'fading-senpai':
				FlxG.sound.playMusic(Paths.music('city_ambience'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			case 'whittyvssarv' | 'gun-buddies':
				FlxG.sound.playMusic(Paths.music('gunsDialogue'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
		}

		bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83, function(tmr:FlxTimer)
		{
			bgFade.alpha += (1 / 5) * 0.7;
			if (bgFade.alpha > 0.7)
				bgFade.alpha = 0.7;
		}, 5);

		box = new FlxSprite(-20, 45);
		
		var hasDialog = false;
		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'senpai-medley':
				hasDialog = true;
				isPixelBox = true;
				FlxG.sound.play(Paths.sound('HAPPY_TEXT_BOX'));
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
			case 'your-reality' | 'monika':
				hasDialog = true;
				isPixelBox = true;
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
			case 'high-school-conflict' | 'bara-no-yume' | 'shinkyoku' | 'your-demise' | 'roots':
				hasDialog = true;
				isPixelBox = true;
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-monika');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
				if (PlayState.SONG.song.toLowerCase() == 'shinkyoku' || PlayState.SONG.song.toLowerCase() == 'bara-no-yume')
					FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
			case 'ugh':
				hasDialog = true;
				isPixelBox = true;
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH', [4], "", 24);

			case 'thorns':
				hasDialog = true;
				isPixelBox = true;
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn', [11], "", 24);

				var face:FlxSprite = new FlxSprite(320, 170).loadGraphic(Paths.image('weeb/spiritFaceForward'));
				face.setGraphicSize(Std.int(face.width * 6));
				add(face);
			case 'fading-senpai' | 'keep-going' | 'ectospasm' | 'checking':
				hasDialog = true;
				isPixelBox = true;
				box.frames = Paths.getSparrowAtlas('garBox');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn', [11], "", 24);
				if (PlayState.SONG.song.toLowerCase() == 'checking')
					FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
			default:
				hasDialog = true;
				canFlip = true;
				box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
				box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
				box.animation.addByPrefix('normal', 'speech bubble normal', 24, true);
		}

		if (!isPixelBox)
		{
			box.y += 320;
			box.x += 500;
			box.antialiasing = true;
		}

		this.dialogueList = dialogueList;
		
		if (!hasDialog)
			return;
		
		portraitLeftPixel = new FlxSprite(-20, 40);
		portraitLeftPixel.frames = Paths.getSparrowAtlas('dialogue/senpaiPort');
		portraitLeftPixel.animation.addByPrefix('normal', 'normal', 24, false);
		portraitLeftPixel.setGraphicSize(Std.int(portraitLeftPixel.width * PlayState.daPixelZoom * 0.9));
		portraitLeftPixel.updateHitbox();
		portraitLeftPixel.scrollFactor.set();
		add(portraitLeftPixel);
		portraitLeftPixel.visible = false;

		portraitRightPixel = new FlxSprite(0, 40);
		portraitRightPixel.frames = Paths.getSparrowAtlas('dialogue/bfPixelPort');
		portraitRightPixel.animation.addByPrefix('normal', 'normal', 24, false);
		portraitRightPixel.setGraphicSize(Std.int(portraitRightPixel.width * PlayState.daPixelZoom * 0.9));
		portraitRightPixel.updateHitbox();
		portraitRightPixel.scrollFactor.set();
		add(portraitRightPixel);
		portraitRightPixel.visible = false;

		portraitLeft = new FlxSprite(-40, 20);
		portraitLeft.frames = Paths.getSparrowAtlas('dialogue/picoPort');
		portraitLeft.animation.addByPrefix('normal', 'normal', 24, false);
		portraitLeft.scrollFactor.set();
		portraitLeft.antialiasing = true;
		add(portraitLeft);
		portraitLeft.visible = false;

		portraitRight = new FlxSprite(-60, 20);
		portraitRight.frames = Paths.getSparrowAtlas('dialogue/tankmanPort');
		portraitRight.animation.addByPrefix('normal', 'normal', 24, false);
		portraitRight.scrollFactor.set();
		portraitRight.antialiasing = true;
		add(portraitRight);
		portraitRight.visible = false;
		
		box.animation.play('normalOpen');
		if (isPixelBox)
		{
			box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		}
		box.updateHitbox();
		add(box);

		box.screenCenter(X);
		if (PlayState.curStage.contains('school') || PlayState.curStage.contains('garStage'))
		{
			trace('DONT MOVE IT');
		}
		else
			box.x += 50;

		portraitLeftPixel.screenCenter(X);

		var imagePath:Array<String>;

		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'fading-senpai' | 'keep-going' | 'ectospasm' | 'checking':
				imagePath = ['garcello/hand_textbox', ''];
			default:
				imagePath = ['weeb/pixelUI/hand_textbox', 'week6'];
		}
		handSelect = new FlxSprite(FlxG.width * 0.9, FlxG.height * 0.9).loadGraphic(Paths.image(imagePath[0]));
		add(handSelect);

		if (imagePath[0] != 'weeb/pixelUI/hand_textbox')
			handSelect.antialiasing = true;

		if (!talkingRight)
		{
			// box.flipX = true;
		}

		dropText = new FlxText(242, 502, Std.int(FlxG.width * 0.6), "", 32);
		dropText.font = 'Pixel Arial 11 Bold';
		dropText.color = 0xFFD89494;
		add(dropText);

		detectDialogue = new FlxText(242, 502, Std.int(FlxG.width * 0.6), "", 32);
		detectDialogue.font = 'Pixel Arial 11 Bold';
		detectDialogue.color = 0xFFD89494;
		detectDialogue.alpha = 0;

		swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
		swagDialogue.font = 'Pixel Arial 11 Bold';
		swagDialogue.color = 0xFF3F2021;
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		add(swagDialogue);

		dialogue = new Alphabet(0, 80, "", false, true);
		// dialogue.x = 90;
		// add(dialogue);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	override function update(elapsed:Float)
	{
		detectDialogue.text = dialogueList[0];
		
		// HARD CODING CUZ IM STUPDI
		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'roses' | 'ugh':
				portraitLeftPixel.visible = false;
			case 'thorns':
				portraitLeftPixel.color = FlxColor.BLACK;
				swagDialogue.color = FlxColor.WHITE;
				dropText.color = FlxColor.BLACK;
			case 'keep-going':
				swagDialogue.color = FlxColor.WHITE;
				dropText.color = FlxColor.BLACK;
			case 'fading-senpai' | 'checking' | 'ectospasm':
				swagDialogue.color = 0xFF0DF07E;
				dropText.color = FlxColor.BLACK;		
		}

		dropText.text = swagDialogue.text;
	
		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
			{
				box.animation.play('normal');
				dialogueOpened = true;
			}
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		if (FlxG.keys.justPressed.ANY  && dialogueStarted == true)
		{
			remove(dialogue);
				
			FlxG.sound.play(Paths.sound('clickText'), 0.8);

			if (dialogueList[1] == null && dialogueList[0] != null || FlxG.keys.justPressed.ESCAPE)
			{
				if (!isEnding)
				{
					isEnding = true;

					if (PlayState.SONG.song.toLowerCase() == 'senpai' || PlayState.SONG.song.toLowerCase() == 'thorns')
						FlxG.sound.music.fadeOut(2.2, 0);

					new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						box.alpha -= 1 / 5;
						bgFade.alpha -= 1 / 5 * 0.7;
						portraitLeftPixel.visible = false;
						portraitRightPixel.visible = false;
						portraitLeft.visible = false;
						portraitRight.visible = false;
						swagDialogue.alpha -= 1 / 5;
						dropText.alpha = swagDialogue.alpha;
					}, 5);

					new FlxTimer().start(1.2, function(tmr:FlxTimer)
					{
						finishThing();
						kill();
					});
				}
			}
			else
			{
				dialogueList.remove(dialogueList[0]);
				startDialogue();
			}
		}
		
		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function sideCheck():Void
	{
		var leftCharacters:Array<String> = ['hdSenpai', 'hdSpirit', 'shaggy', 'pico', 'botan', 'blantad', '016', 'selever', 'tea', 'dad'];
		var rightCharacters:Array<String> = ['aloe', 'nene', 'tankman', 'gf', 'fever'];
		var leftPixelCharacters:Array<String> = ['monika', 'senpai'];
		var rightPixelCharacters:Array<String> = ['bfPixel', 'tankmanPixel'];

		if (leftCharacters.contains(curCharacter))
		{
			isLeft = true;
			isRight = false;
			isLeftPixel = false;
			isRightPixel = false;
		}
		if (rightCharacters.contains(curCharacter))
		{
			isLeft = false;
			isRight = true;	
			isLeftPixel = false;
			isRightPixel = false;
		}
		if (leftPixelCharacters.contains(curCharacter))
		{
			isLeft = false;	
			isRight = false;
			isLeftPixel = true;	
			isRightPixel = false;		
		}
		if (rightPixelCharacters.contains(curCharacter))
		{
			isLeft = false;	
			isRight = false;
			isLeftPixel = false;	
			isRightPixel = true;		
		}
	}

	function startDialogue():Void
	{
		cleanDialog();
		// var theDialog:Alphabet = new Alphabet(0, 70, dialogueList[0], false, true);
		// dialogue = theDialog;
		// add(theDialog);

		// swagDialogue.text = ;
		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);

		sideCheck();

		var portPath:String = 'dialogue/'+curCharacter+'Port';

		if (FileSystem.exists(Paths.modsImages(portPath)))
		{
			if (!Paths.currentTrackedAssets.exists(portPath))
				Paths.cacheImage(portPath);

			tex = FlxAtlasFrames.fromSparrow(Paths.currentTrackedAssets.get(portPath), File.getContent(Paths.modsXml(portPath)));
		}
		else
			tex = Paths.getSparrowAtlas(portPath);
	
		//da actual code
		if (isLeft)
		{
			portraitLeftPixel.visible = false;
			portraitRightPixel.visible = false;
			portraitRight.visible = false;

			if (canFlip)
				box.flipX = true;	

			if (curFlip == 'true')
			{
				portraitLeft.flipX = true;
				if (canFlip)
					box.flipX = false;
			}			
			else
			{
				portraitLeft.flipX = false;
				if (canFlip)
					box.flipX = true;
			}
							
			switch (curCharacter)
			{
				case 'pico' | 'botan':
					portraitLeft.y = FlxG.height - 600;
					if (curFlip == 'true')
						portraitLeft.x = 725;	
					else
						portraitLeft.x = 100;
				case 'selever':
					portraitLeft.y = FlxG.height - 575;
					if (curFlip == 'true')
						portraitLeft.x = 800;	
					else
						portraitLeft.x = 200;
				default:
					portraitLeft.y = FlxG.height - 690;
					if (curFlip == 'true')
						portraitLeft.x = 725;	
					else
					{
						portraitLeft.x = (curCharacter != '016' ? 100 : 0);
					}					
			}

			if (curEmotion != null)
				emotion = curEmotion;
			else
				emotion = 'normal';
					
			if (curCharacter != oldCharacter || curEmotion != oldEmotion)
			{				
				portraitLeft.visible = true;
				portraitLeft.alpha = 0;
				new FlxTimer().start(0.08, function(tmr:FlxTimer)
				{
					portraitLeft.alpha += 1 / 4;
				}, 4);
				portraitLeft.frames = tex;
				portraitLeft.antialiasing = true;
				portraitLeft.animation.addByPrefix(emotion, emotion, 24, (emotion == 'speaking' ? true : false));
				portraitLeft.animation.play(emotion);
			}	

			swagDialogue.completeCallback = function()
			{
				if (emotion == 'speaking')
					portraitLeft.animation.play('normal');
			}	
		}
		if (isRight)
		{
			portraitLeftPixel.visible = false;
			portraitRightPixel.visible = false;
			portraitLeft.visible = false;

			if (canFlip)
				box.flipX = false;

			if (curFlip == 'true')
			{
				portraitRight.flipX = true;
				if (canFlip)
					box.flipX = true;
			}			
			else
			{
				portraitRight.flipX = false;
				if (canFlip)
					box.flipX = false;
			}

			switch (curCharacter)
			{
				case 'tankman':
					portraitRight.y = FlxG.height - 690;
					if (curFlip == 'true')
						portraitRight.x = 100;	
					else
						portraitRight.x = 725;
				default:
					portraitRight.y = FlxG.height - 600;
					if (curFlip == 'true')
						portraitRight.x = 100;	
					else
						portraitRight.x = (curCharacter != 'gf' ? 725 : 800);
			}

			if (curEmotion != null)
				emotion = curEmotion;
			else
				emotion = 'normal';
				
			if (curCharacter != oldCharacter || curEmotion != oldEmotion)
			{
				portraitRight.visible = true;
				portraitRight.alpha = 0;
				new FlxTimer().start(0.08, function(tmr:FlxTimer)
				{
					portraitRight.alpha += 1 / 4;
				}, 4);
				portraitRight.frames = tex;
				portraitRight.antialiasing = true;
				portraitRight.animation.addByPrefix(emotion, emotion, 24, false);
				portraitRight.animation.play(emotion);
			}
		}
		if (isLeftPixel)
		{		
			portraitRightPixel.visible = false;
			portraitRight.visible = false;
			portraitLeft.visible = false;

			if (canFlip)
				box.flipX = true;	

			if (curFlip == 'true')
			{
				if (!curCharacter.contains('monika'))
					portraitLeftPixel.flipX = true;
				if (canFlip)
					box.flipX = false;
			}			
			else
			{
				portraitLeftPixel.flipX = false;
				if (canFlip)
					box.flipX = true;
			}

			if (curEmotion != null)
				emotion = curEmotion;
			else
				emotion = 'normal';
	
			switch (curCharacter)
			{
				default:
					portraitLeftPixel.y = (isPixelBox ? 35 : 45);
					if (curFlip == 'true')
						portraitLeftPixel.x = 750;	
					else
						portraitLeftPixel.x = (isPixelBox ? 190 : 140);
			}
					
			if (curCharacter != oldCharacter || curEmotion != oldEmotion)
			{				
				portraitLeftPixel.visible = true;
				portraitLeftPixel.alpha = 0;
				new FlxTimer().start(0.08, function(tmr:FlxTimer)
				{
					portraitLeftPixel.alpha += 1 / 4;
				}, 4);
				portraitLeftPixel.frames = tex;
				
				if (emotion == 'speaking')
					portraitLeftPixel.animation.addByPrefix('idle', 'idle', 24, false);

				portraitLeftPixel.animation.addByPrefix(emotion, emotion, 24, (emotion == 'speaking' ? true : false));
				portraitLeftPixel.animation.play(emotion);
			}	

			swagDialogue.completeCallback = function()
			{
				if (emotion == 'speaking')
				{
					trace('should now play idle');
					portraitLeftPixel.animation.play('idle', true);
				}
			}	
		}
		if (isRightPixel)
		{		
			portraitLeftPixel.visible = false;
			portraitRight.visible = false;
			portraitLeft.visible = false;

			if (canFlip)
				box.flipX = true;	

			if (curFlip == 'true')
			{
				portraitRightPixel.flipX = true;
				if (canFlip)
					box.flipX = false;
			}			
			else
			{
				portraitRightPixel.flipX = false;
				if (canFlip)
					box.flipX = true;
			}
							
			switch (curCharacter)
			{
				default:
					portraitRightPixel.y = 35;
					if (curFlip == 'true')
						portraitRightPixel.x = 190;
					else
						portraitRightPixel.x = 750;					
			}

			if (curEmotion != null)
				emotion = curEmotion;
			else
				emotion = 'normal';
					
			if (curCharacter != oldCharacter || curEmotion != oldEmotion)
			{				
				portraitRightPixel.visible = true;
				portraitRightPixel.alpha = 0;
				new FlxTimer().start(0.08, function(tmr:FlxTimer)
				{
					portraitRightPixel.alpha += 1 / 4;
				}, 4);
				portraitRightPixel.frames = tex;
				portraitRightPixel.animation.addByPrefix(emotion, emotion, 24, false);
				portraitRightPixel.animation.play(emotion);
			}	
		}
	}

	var splitData:Array<String>;

	function cleanDialog():Void
	{
		splitData = dialogueList[0].split(":");
		oldCharacter = curCharacter;
		curCharacter = splitData[1];
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

		splitData = dialogueList[0].split("|");
		oldEmotion = curEmotion;
		curEmotion = splitData[1];
		if (splitData[1] != null)
		{
			dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();
		}		

		splitData = dialogueList[0].split("--");
		curFlip = splitData[1];
		if (splitData[1] != null)
			dialogueList[0] = dialogueList[0].substr(splitData[1].length + 4).trim();
		if (splitData[1] == null)
			curFlip = 'false';
	}
}
