package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
using StringTools;
/**
	*DEBUG MODE
 */
class PositionDebug extends FlxState
{
	var UI_box:FlxUITabMenu;
	var bf:Boyfriend;
	var dad:Character;
	var char:Character;
	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var layeringbullshit:FlxTypedGroup<FlxSprite>;
	var animList:Array<String> = [];
	var offsetList:Array<Int> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;
	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var player:FlxUICheckBox;
	var _file:FileReference;
	var ghostBF:Character;
	public static var isBF:Bool = false;
	public static var isDad:Bool = false;

	private function saveLevel()
	{
		var data:String = '';

		var offsetFile = new CharacterOffsets(daAnim, (isDad ? false : true));
		var offsets = offsetFile.daOffsetArray;

		offsetFile.daOffsetArray[0] += totalX;
		offsetFile.daOffsetArray[1] += totalY;

		data = Std.string(offsetFile.daOffsetArray[0]) + " " + Std.string(offsetFile.daOffsetArray[1]) + " 0 0 0 0";

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

			if (isBF)
				_file.save(data.trim(), char.curCharacter + "StagePlayerOffsets.txt");
			else
				_file.save(data.trim(), char.curCharacter + "StageOffsets.txt");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	public function new(daAnim:String = 'spooky')
	{
		super();
		this.daAnim = daAnim;
	}

	var characterTab:FlxUI;
	var cumfart:FlxUIDropDownMenu;

	override function create()
	{
		FlxG.mouse.visible = true;
		FlxG.sound.music.stop();
		var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0, 0);
		add(gridBG);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camGame = new FlxCamera();

		FlxG.cameras.add(camGame);
		FlxG.cameras.add(camHUD);
		FlxCamera.defaultCameras = [camGame];

		layeringbullshit = new FlxTypedGroup<FlxSprite>();
		add(layeringbullshit);

		UI_box = new FlxUITabMenu(null,[{name:"Character",label:"Character"}],false);
		UI_box.cameras = [camHUD];
		UI_box.resize(300, 200);
		UI_box.x = (FlxG.width / 2) + 250;
		UI_box.y = 20;
		add(UI_box);

		characterTab = new FlxUI(null, UI_box);
		characterTab.name = "Character";

		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		cumfart = new FlxUIDropDownMenu(50, 50, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			daAnim =characters[Std.parseInt(character)];
			displayCharacter(daAnim);
		});
		cumfart.selectedLabel = daAnim;

		player = new FlxUICheckBox(175, 50, null, null, "flipX", 100);
		player.checked = false;
		player.callback = function()
		{
			char.flipX= player.checked;	
		};

		var saveButton:FlxButton = new FlxButton(50, 125, "Save", function()
		{
			saveLevel();
		});

		var regenButton:FlxButton = new FlxButton(150, 125, "Regen List", function()
		{
			regenerateCharacterList();
		});

		characterTab.add(cumfart);
		characterTab.add(player);
		characterTab.add(saveButton);
		characterTab.add(regenButton);
		UI_box.addGroup(characterTab);
		dumbTexts = new FlxTypedGroup<FlxText>();
		dumbTexts.cameras = [camHUD];
		add(dumbTexts);

		textAnim = new FlxText(300, 16);
		textAnim.size = 26;
		textAnim.scrollFactor.set();
		add(textAnim);

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);
		camGame.follow(camFollow);

		var lolText = new FlxText(0, 0, 0, (isDad ? "Opponent" : "Player") + " Mode", 32);
		lolText.font = 'Pixel Arial 11 Bold';
		lolText.color = 0xFFFFFFFF;
		lolText.borderColor = FlxColor.BLACK;
		lolText.alignment = LEFT;
		lolText.borderSize = 3;
		lolText.borderStyle = FlxTextBorderStyle.OUTLINE;
		lolText.cameras = [camHUD];
		lolText.screenCenter();
		lolText.x -= FlxG.width / 2 - 150;
		lolText.y += FlxG.height / 2 - 	50;
		add(lolText);

		displayCharacter(daAnim);

		super.create();
	}

	var reset:Bool = false;

	function regenerateCharacterList()
	{
		characterTab.remove(cumfart);

		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		cumfart = new FlxUIDropDownMenu(50, 50, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			daAnim =characters[Std.parseInt(character)];
			displayCharacter(daAnim);
		});
		cumfart.selectedLabel = daAnim;

		characterTab.add(cumfart);
	}

	function displayCharacter(daAnim:String){
		totalX = 0;
		totalY = 0;

		dumbTexts.forEach(function(text:FlxText)
		{
			dumbTexts.remove(text,true);
		});
		dumbTexts.clear();

		animList=[];

		if(dad!=null)
			layeringbullshit.remove(dad);

		if(bf!=null)
			layeringbullshit.remove(bf);

		if(ghostBF!=null)
			layeringbullshit.remove(ghostBF);

		var daChar:String = 'sarvente';

		daChar = 'bf';
			
		var offsetFile = new CharacterOffsets(daAnim, (isDad ? false : true));
		var offsets = offsetFile.daOffsetArray;

		var offsetFile2 = new CharacterOffsets(daChar, (isDad ? false : true));
		var offsets2 = offsetFile2.daOffsetArray;

		ghostBF = new Character(0, 0, daChar);
		ghostBF.debugMode = true;
		ghostBF.x += offsets2[0];
		ghostBF.y += offsets2[1];
		ghostBF.flipX = (isBF ? true : false);
		layeringbullshit.add(ghostBF);	

		if (isDad)
		{
			dad = new Character(0, 0, daAnim);
			dad.x += offsets[0];
			dad.y += offsets[1];
			dad.debugMode = true;
			layeringbullshit.add(dad);

			char = dad;
			dad.flipX = player.checked;
		}
		else if (isBF)
		{
			bf = new Boyfriend(0, 0, daAnim);
			bf.x += offsets[0];
			bf.y += offsets[1];
			bf.debugMode = true;
			layeringbullshit.add(bf);

			char = bf;
			bf.flipX = player.checked;
		}

		genBoyOffsets();
	}

	function genBoyOffsets(pushList:Bool = true):Void
	{
		var daLoop:Int = 0;

		var offsetFile = new CharacterOffsets(daAnim, (isDad ? false : true));
		var offsets = offsetFile.daOffsetArray;

		if (isBF)
		{
			if (bf.isCustom)
			{
				offsetFile.daOffsetArray[0] = bf.positionArray[0];
				offsetFile.daOffsetArray[1] = bf.positionArray[1] - 350;
			}
		}
		else
		{
			if (dad.isCustom)
			{
				offsetFile.daOffsetArray[0] = dad.positionArray[0];
				offsetFile.daOffsetArray[1] = dad.positionArray[1];
			}
		}

		offsetFile.daOffsetArray[0] += totalX;
		offsetFile.daOffsetArray[1] += totalY;

		if (isBF)
		{
			bf.x = 0 + offsetFile.daOffsetArray[0];
			bf.y = 0 + offsetFile.daOffsetArray[1];
		}
		else
		{
			dad.x = 0 + offsetFile.daOffsetArray[0];
			dad.y = 0 + offsetFile.daOffsetArray[1];
		}

		var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, 'daOffsetArray: ' + offsets, 15);
		text.scrollFactor.set();
		text.color = FlxColor.BLUE;
		dumbTexts.add(text);
	}

	function updateTexts():Void
	{
		dumbTexts.forEach(function(text:FlxText)
		{
			text.kill();
			dumbTexts.remove(text, true);
		});
		dumbTexts.clear();
	}

	var totalX:Int = 0;
	var totalY:Int = 0;

	override function update(elapsed:Float)
	{
		ghostBF.flipX = char.flipX;

		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.mouse.visible = false;
			LoadingState.loadAndSwitchState(new PlayState());
		}
		
		if (FlxG.keys.justPressed.TWO)
		{
			FlxG.mouse.visible = false;
			FlxG.switchState(new AnimationDebug((isDad ? dad.curCharacter : bf.curCharacter)));
			AnimationDebug.isDad = isDad;
			AnimationDebug.isBF = isBF;
		}

		if (FlxG.keys.justPressed.THREE)
		{
			FlxG.switchState(new PositionDebug((isDad ? dad.curCharacter : bf.curCharacter)));
			PositionDebug.isBF = isDad;
			PositionDebug.isDad = !isDad;	
		}

		if (FlxG.keys.justPressed.X)
		{
			if(isDad)
				dad.flipX = !dad.flipX;
			else
				bf.flipX = !bf.flipX;
		}
			
		if (FlxG.keys.justPressed.E)
			camGame.zoom += 0.25;
		if (FlxG.keys.justPressed.Q)
			camGame.zoom -= 0.25;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90;
			else
				camFollow.velocity.x = 0;
		}
		else
		{
			camFollow.velocity.set();
		}

		var upP = FlxG.keys.anyJustPressed([UP]);
		var rightP = FlxG.keys.anyJustPressed([RIGHT]);
		var downP = FlxG.keys.anyJustPressed([DOWN]);
		var leftP = FlxG.keys.anyJustPressed([LEFT]);

		var holdShift = FlxG.keys.pressed.SHIFT;
		var holdAlt = FlxG.keys.pressed.ALT;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;
		if (holdShift && holdAlt)
			multiplier = 50;

		if (upP || rightP || downP || leftP)
		{
			updateTexts();
			if (upP)
			{
				char.y -= 1 * multiplier;
				totalY -= 1 * multiplier;
			}	
			if (downP)
			{
				char.y += 1 * multiplier;
				totalY += 1 * multiplier;
			}				
			if (leftP)
			{
				char.x -= 1 * multiplier;
				totalX -= 1 * multiplier;
			}
				
			if (rightP)
			{
				char.x += 1 * multiplier;
				totalX += 1 * multiplier;
			}
			updateTexts();
			genBoyOffsets(false);

			if (ghostBF.animOffsets.exists('danceLeft'))
				ghostBF.playAnim('danceLeft');
			else
				ghostBF.playAnim('idle');
		}

		super.update(elapsed);
	}
}