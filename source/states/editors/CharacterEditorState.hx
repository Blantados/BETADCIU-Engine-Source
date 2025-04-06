package states.editors;

import flixel.FlxObject;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import lime.system.Clipboard;
import flixel.animation.FlxAnimation;
import lime.utils.Assets;
import flixel.graphics.frames.FlxAtlasFrames;

import objects.HealthIcon;
import objects.Character;
import objects.CharacterOffsets;

import luafiles.ModchartState;
import luafiles.DebugLuaText;

import animateatlas.AtlasFrameMaker;

using StringTools;

/**
	*DEBUG MODE
 */
class CharacterEditorState extends MusicBeatState
{
	var char:Character;
	var ghostChar:Character;
	var positioningChar:Character;
	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var charLayer:FlxTypedGroup<Character>;
	var animsTxtGroup:FlxTypedGroup<FlxText>;
	//var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var goToPlayState:Bool = true;
	var camFollow:FlxObject;

	public function new(daAnim:String = 'spooky', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;

		if (daAnim.contains('-embed')){
			daAnim = "bf";
		}
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var changeBGbutton:FlxButton;
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;
	public static var inCharEditor:Bool = false;

	var anims = null;

	override function create()
	{
		FlxG.sound.playMusic(Paths.music('kawaruslow'), 0.7);
		inCharEditor = true;

		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

		CustomFadeTransition.nextCamera = camMenu;

		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		add(luaDebugGroup);
		luaDebugGroup.cameras = [camMenu];

		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);
		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);

		var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

		changeBGbutton = new FlxButton(FlxG.width - 360, 25, "", function()
		{
			onPixelBG = !onPixelBG;
			reloadBGs();
		});
		changeBGbutton.cameras = [camMenu];

		loadChar(!daAnim.startsWith('bf'), false);

		healthBarBG = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('healthBar'));
		healthBarBG.scrollFactor.set();
		add(healthBarBG);
		healthBarBG.cameras = [camHUD];

		leHealthIcon = new HealthIcon(char.healthIcon, false);
		leHealthIcon.y = FlxG.height - 150;
		add(leHealthIcon);
		leHealthIcon.cameras = [camHUD];

		animsTxtGroup = new FlxTypedGroup<FlxText>();
		add(animsTxtGroup);
		animsTxtGroup.cameras = [camHUD];

		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		reloadAnimList();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		var tipTextArray:Array<String> = "E/Q - Camera Zoom In/Out
		\nR - Reset Camera Zoom
		\nJKLI - Move Camera
		\nW/S - Previous/Next Animation
		\nSpace - Play Animation
		\nArrow Keys - Move Character Offset
		\nT - Reset Current Offset
		\nHold Shift to Move 10x faster\n".split('\n');

		for (i in 0...tipTextArray.length-1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 13 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

		FlxG.camera.follow(camFollow);

		var tabs = [
			//{name: 'Offsets', label: 'Offsets'},
			{name: 'Settings', label: 'Settings'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camMenu];

		UI_characterbox.resize(350, 350);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);
		add(changeBGbutton);
		
		//addOffsetsUI();
		addSettingsUI();

		addCharacterUI();
		addAnimationsUI();
		UI_characterbox.selected_tab_id = 'Character';

		FlxG.mouse.visible = true;
		reloadCharacterOptions();

		super.create();
	}

	var onPixelBG:Bool = false;
	var OFFSET_X:Float = 300;
	function reloadBGs() {
		var i:Int = bgLayer.members.length-1;
		while(i >= 0) {
			var memb:FlxSprite = bgLayer.members[i];
			if(memb != null) {
				memb.kill();
				bgLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();
		var playerXDifference = 0;
		if(char.isPlayer) playerXDifference = 670;

		if(onPixelBG) {
			var playerYDifference:Float = 0;
			if(char.isPlayer) {
				playerXDifference += 200;
				playerYDifference = 220;
			}

			var bgSky:BGSprite = new BGSprite('weeb/weebSky', OFFSET_X - (playerXDifference / 2) - 300, 0 - playerYDifference, 0.1, 0.1);
			bgLayer.add(bgSky);
			bgSky.antialiasing = false;

			var repositionShit = -200 + OFFSET_X - playerXDifference;

			var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, -playerYDifference + 6, 0.6, 0.90);
			bgLayer.add(bgSchool);
			bgSchool.antialiasing = false;

			var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, -playerYDifference, 0.95, 0.95);
			bgLayer.add(bgStreet);
			bgStreet.antialiasing = false;

			var widShit = Std.int(bgSky.width * 6);
			var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800 - playerYDifference);
			bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
			bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
			bgTrees.animation.play('treeLoop');
			bgTrees.scrollFactor.set(0.85, 0.85);
			bgLayer.add(bgTrees);
			bgTrees.antialiasing = false;

			bgSky.setGraphicSize(widShit);
			bgSchool.setGraphicSize(widShit);
			bgStreet.setGraphicSize(widShit);
			bgTrees.setGraphicSize(Std.int(widShit * 1.4));

			bgSky.updateHitbox();
			bgSchool.updateHitbox();
			bgStreet.updateHitbox();
			bgTrees.updateHitbox();
			changeBGbutton.text = "Regular BG";
		} else {
			var bg:BGSprite = new BGSprite('stageback', -600 + OFFSET_X - playerXDifference, -300, 0.9, 0.9);
			bgLayer.add(bg);

			var stageFront:BGSprite = new BGSprite('stagefront', -650 + OFFSET_X - playerXDifference, 500, 0.9, 0.9);
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			bgLayer.add(stageFront);

			positioningChar = new Character(100 + OFFSET_X, 350, 'bf-placement', false);
			positioningChar.debugMode = true;
			positioningChar.alpha = 0.4;
			positioningChar.flipX = !char.isPlayer;
			positioningChar.dance();
			bgLayer.add(positioningChar);

			changeBGbutton.text = "Pixel BG";
		}
	}

	function fixTheDamnOffsets()
	{
		if (!char.isCustom)
		{
			for (i in 0...char.animationsArray.length)
			{
				if (char.animOffsets.get(char.animationsArray[i].anim) != null)
				{
					var daOffset = char.animOffsets.get(char.animationsArray[i].anim);
					char.animationsArray[i].offsets = [Std.int(daOffset[0]), Std.int(daOffset[1])];
				}

				if (char.animPlayerOffsets.get(char.animationsArray[i].anim) != null)
				{
					var daPlayerOffset = char.animPlayerOffsets.get(char.animationsArray[i].anim);
					char.animationsArray[i].playerOffsets = [Std.int(daPlayerOffset[0]), Std.int(daPlayerOffset[1])];
				}	
			}
		}
	}

	/*var animationInputText:FlxUIInputText;
	function addOffsetsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Offsets";

		animationInputText = new FlxUIInputText(15, 30, 100, 'idle', 8);
		
		var addButton:FlxButton = new FlxButton(animationInputText.x + animationInputText.width + 23, animationInputText.y - 2, "Add", function()
		{
			var theText:String = animationInputText.text;
			if(theText != '') {
				var alreadyExists:Bool = false;
				for (i in 0...animList.length) {
					if(animList[i] == theText) {
						alreadyExists = true;
						break;
					}
				}

				if(!alreadyExists) {
					char.animOffsets.set(theText, [0, 0]);
					animList.push(theText);
				}
			}
		});
			
		var removeButton:FlxButton = new FlxButton(animationInputText.x + animationInputText.width + 23, animationInputText.y + 20, "Remove", function()
		{
			var theText:String = animationInputText.text;
			if(theText != '') {
				for (i in 0...animList.length) {
					if(animList[i] == theText) {
						if(char.animOffsets.exists(theText)) {
							char.animOffsets.remove(theText);
						}

						animList.remove(theText);
						if(char.animation.curAnim.name == theText && animList.length > 0) {
							char.playAnim(animList[0], true);
						}
						break;
					}
				}
			}
		});
			
		var saveButton:FlxButton = new FlxButton(animationInputText.x, animationInputText.y + 35, "Save Offsets", function()
		{
			saveOffsets();
		});

		tab_group.add(new FlxText(10, animationInputText.y - 18, 0, 'Add/Remove Animation:'));
		tab_group.add(addButton);
		tab_group.add(removeButton);
		tab_group.add(saveButton);
		tab_group.add(animationInputText);
		UI_box.addGroup(tab_group);
	}*/

	var TemplateCharacter:String = '{
			"animations": [
				{
					"loop": false,
					"offsets": [
						0,
						0
					],
					"playerOffsets": [
						0,
						0
					],
					"fps": 24,
					"anim": "idle",
					"indices": [],
					"name": "Dad idle dance"
				},
				{
					"offsets": [
						0,
						0
					],
					"playerOffsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singLEFT",
					"loop": false,
					"name": "Dad Sing Note LEFT"
				},
				{
					"offsets": [
						0,
						0
					],
					"playerOffsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singDOWN",
					"loop": false,
					"name": "Dad Sing Note DOWN"
				},
				{
					"offsets": [
						0,
						0
					],
					"playerOffsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singUP",
					"loop": false,
					"name": "Dad Sing Note UP"
				},
				{
					"offsets": [
						0,
						0
					],
					"playerOffsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singRIGHT",
					"loop": false,
					"name": "Dad Sing Note RIGHT"
				}
			],
			"no_antialiasing": false,
			"image": "characters/DADDY_DEAREST",
			"position": [
				0,
				0
			],
			"playerposition": [
				0,
				0
			],
			"healthicon": "face",
			"flip_x": false,
			"healthbar_colors": [
				161,
				161,
				161
			],
			"camera_position": [
				0,
				0
			],
			"player_camera_position": [
				0,
				0
			],
			"sing_duration": 4,
			"scale": 1
		}';

	var charDropDown:FlxUIDropDownMenu;
	function addSettingsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		var check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = daAnim.startsWith('bf');
		check_player.callback = function()
		{
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			reloadBGs();
			char.flipAnims();
			
			char.playAnim(char.animation.name, true);
			
			ghostChar.flipX = char.flipX;

			updateTextColors();

			if (char.isPlayer)		
				char.setPosition(char.playerPositionArray[0] + OFFSET_X + 100, char.playerPositionArray[1]);
			else		
				char.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);

			updatePointerPos();
		};

		charDropDown = new FlxUIDropDownMenu(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(character:String)
		{
			daAnim = characterList[Std.parseInt(character)];
			check_player.checked = daAnim.startsWith('bf');
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
			reloadCharacterOptions();
		});
		charDropDown.selectedLabel = daAnim;
		blockPressWhileScrolling.push(charDropDown);
		reloadCharacterDropDown();

		var reloadCharacter:FlxButton = new FlxButton(140, 10, "Reload Char", function()
		{
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
			reloadCharacterOptions();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 40, "Load Template", function()
		{
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);
			var characters:Array<Character> = [char, ghostChar];
			for (character in characters)
			{
				character.animOffsets.clear();
				character.animationsArray = parsedJson.animations;
				for (anim in character.animationsArray)
				{
					character.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
				if(character.animationsArray[0] != null) {
					character.playAnim(character.animationsArray[0].anim, true);
				}

				character.singDuration = parsedJson.sing_duration;
				character.positionArray = parsedJson.position;
				character.cameraPosition = parsedJson.camera_position;
				character.playerCameraPosition = parsedJson.player_camera_position;
				
				if (parsedJson.spriteType != null)
					character.spriteType = parsedJson.spriteType.toUpperCase();
				else
					character.spriteType = "SPARROW";

				character.charPath = parsedJson.image + '.png';
				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.healthIcon = parsedJson.healthicon;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.setPosition(character.positionArray[0] + OFFSET_X + 100, character.positionArray[1]);
			}

			reloadCharacterImage();
			reloadCharacterDropDown();
			reloadCharacterOptions();
			resetHealthBarColor();
			updatePointerPos();
			reloadAnimList();
		});
			
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;
		
		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(charDropDown);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);
	}
	
	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;
	var noteSkinInputText:FlxUIInputText;
	var spriteTypeDropDown:FlxUIDropDownMenu;

	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var playerPositionXStepper:FlxUINumericStepper;
	var playerPositionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var playerPositionCameraXStepper:FlxUINumericStepper;
	var playerPositionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;
	var psychPlayerCheckBox:FlxUICheckBox;

	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;

	function addCharacterUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
			if(char.animation.curAnim != null) {
				char.playAnim(char.animation.curAnim.name, true);
			}
		});

		var decideIconColor:FlxButton = new FlxButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
			{
				var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));
				healthColorStepperR.value = coolColor.red;
				healthColorStepperG.value = coolColor.green;
				healthColorStepperB.value = coolColor.blue;
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperB, null); 
			});

		var copyOffset:FlxButton = new FlxButton(reloadImage.x - 100, reloadImage.y + 30, "Copy Offsets", function()
		{
			for (i in 0...char.animationsArray.length)
			{
				char.animationsArray[i].playerOffsets = char.animationsArray[i].offsets;	
			}
		});

		healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, leHealthIcon.getCharacter(), 8);

		singDurationStepper = new FlxUINumericStepper(15, healthIconInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.05, 1, 0.05, 100, 2);

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = char.flipX;
		if(char.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function() {
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if(char.isPlayer) char.flipX = !char.flipX;
			
			ghostChar.flipX = char.flipX;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.callback = function() {
			char.antialiasing = !noAntialiasingCheckBox.checked;
			char.noAntialiasing = noAntialiasingCheckBox.checked;

			ghostChar.antialiasing = char.antialiasing;
			ghostChar.noAntialiasing = char.noAntialiasing;
		};

		psychPlayerCheckBox = new FlxUICheckBox(flipXCheckBox.x, noAntialiasingCheckBox.y + 40, null, null, "Player Character", 80);
		psychPlayerCheckBox.checked = char.isPsychPlayer;
		psychPlayerCheckBox.callback = function() {
			char.isPsychPlayer = psychPlayerCheckBox.checked;
			ghostChar.isPsychPlayer = char.isPsychPlayer;
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionArray[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionArray[1], -9000, 9000, 0);
		
		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, char.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, char.cameraPosition[1], -9000, 9000, 0);

		playerPositionXStepper = new FlxUINumericStepper(positionXStepper.x, positionCameraXStepper.y + 40, 10, char.playerPositionArray[0], -9000, 9000, 0);
		playerPositionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionCameraYStepper.y + 40, 10, char.playerPositionArray[1], -9000, 9000, 0);

		playerPositionCameraXStepper = new FlxUINumericStepper(playerPositionXStepper.x, playerPositionXStepper.y + 40, 10, char.playerCameraPosition[0], -9000, 9000, 0);
		playerPositionCameraYStepper = new FlxUINumericStepper(playerPositionYStepper.x, playerPositionYStepper.y + 40, 10, char.playerCameraPosition[1], -9000, 9000, 0);

		noteSkinInputText = new FlxUIInputText(15, playerPositionXStepper.y, 75, 'normal', 8);
		blockPressWhileTypingOn.push(noteSkinInputText);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 140, "Save Character", function() {
			saveCharacter();
		});

		spriteTypeDropDown  = new FlxUIDropDownMenu(15, playerPositionCameraXStepper.y, FlxUIDropDownMenu.makeStrIdLabelArray(['SPARROW', 'PACKER', 'GENERICXML', 'JSON', 'TEXTURE']),
		function(dataString:String)
		{
			char.spriteType = dataString.toLowerCase();
			ghostChar.spriteType = char.spriteType;
		});
		blockPressWhileScrolling.push(spriteTypeDropDown);

		healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, char.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, char.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, char.healthColorArray[2], 0, 255, 0);

		var stepperArray:Array<FlxUINumericStepper> = [positionXStepper, positionYStepper, playerPositionXStepper, playerPositionYStepper, positionCameraXStepper, positionCameraYStepper, playerPositionCameraXStepper, playerPositionCameraYStepper, healthColorStepperR, healthColorStepperG, healthColorStepperB, singDurationStepper, scaleStepper];

		for (i in stepperArray){
			blockPressWhileTypingOnStepper.push(i);
		}
	
		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, noteSkinInputText.y - 18, 0, 'Noteskin:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(playerPositionXStepper.x, playerPositionXStepper.y - 18, 0, 'Character Player X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(new FlxText(playerPositionCameraXStepper.x, playerPositionCameraXStepper.y - 18, 0, 'Player Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(new FlxText(spriteTypeDropDown.x, spriteTypeDropDown.y - 18, 0, 'Sprite Type:'));

		blockPressWhileTypingOn.push(imageInputText);
		blockPressWhileTypingOn.push(healthIconInputText);
		blockPressWhileTypingOn.push(noteSkinInputText);

		var toAdd:Array<Dynamic> = [imageInputText, healthIconInputText, noteSkinInputText, reloadImage, copyOffset, decideIconColor, flipXCheckBox, noAntialiasingCheckBox, psychPlayerCheckBox, saveCharacterButton];

		for (i in 0...stepperArray.length){
			if (i < toAdd.length)
				tab_group.add(toAdd[i]);
				
			tab_group.add(stepperArray[i]);
		}
		
		tab_group.add(spriteTypeDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	var ghostDropDown:FlxUIDropDownMenu;
	var animationDropDown:FlxUIDropDownMenu;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	function addAnimationsUI() 
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";
		
		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		blockPressWhileTypingOn.push(animationInputText);
		blockPressWhileTypingOn.push(imageInputText);
		blockPressWhileTypingOn.push(healthIconInputText);
		blockPressWhileTypingOn.push(animationNameInputText);
		blockPressWhileTypingOn.push(animationIndicesInputText);

		blockPressWhileTypingOnStepper.push(animationNameFramerate);

		animationDropDown = new FlxUIDropDownMenu(15, animationInputText.y - 55, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimArray = char.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationNameFramerate.value = anim.fps;

			var indicesStr:String = (anim.indices != null ? anim.indices.toString() : "");
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});
		blockPressWhileScrolling.push(animationDropDown);

		ghostDropDown = new FlxUIDropDownMenu(animationDropDown.x + 150, animationDropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			ghostChar.visible = false;
			char.alpha = 1;
			if(selectedAnimation > 0) {
				ghostChar.visible = true;
				ghostChar.playAnim(ghostChar.animationsArray[selectedAnimation-1].anim, true);
				char.alpha = 0.85;
			}
		});
		blockPressWhileScrolling.push(ghostDropDown);

		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 130, "Add/Update", function() {
		var indices:Array<Int> = [];
		var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
		if(indicesStr.length > 1) {
			for (i in 0...indicesStr.length) {
				var index:Int = Std.parseInt(indicesStr[i]);
				if(indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) {
					indices.push(index);
				}
			}
		}

		var lastAnim:String = '';
		if(char.animationsArray[curAnim] != null) {
			lastAnim = char.animationsArray[curAnim].anim;
		}

		var lastOffsets:Array<Int> = [0, 0];
		for (anim in char.animationsArray) {
			if(animationInputText.text == anim.anim) {
				lastOffsets = anim.offsets;
				if(char.animation.getByName(animationInputText.text) != null) {
					char.animation.remove(animationInputText.text);
				}
				char.animationsArray.remove(anim);
			}
		}

		var lastPlayerOffsets:Array<Int> = [0, 0];
		for (anim in char.animationsArray) {
			if(animationInputText.text == anim.anim) {

				if(anim.playerOffsets != null && anim.playerOffsets.length > 1)
					lastPlayerOffsets = anim.playerOffsets;
				else if(anim.offsets != null && anim.offsets.length > 1)
					lastPlayerOffsets = anim.offsets;
			
				if(char.animation.getByName(animationInputText.text) != null) {
					char.animation.remove(animationInputText.text);
				}
				char.animationsArray.remove(anim);
			}
		}

			var newAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets,
				playerOffsets: lastPlayerOffsets
			};
			if(indices != null && indices.length > 0) {
				if (newAnim.name == "") //texture atlas
					char.animation.add(newAnim.anim, newAnim.indices, newAnim.fps, newAnim.loop);
				else{
					char.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);

					if (char.useAtlas){
						char.atlasChar.anim.addByAnimIndices(newAnim.anim, newAnim.indices, newAnim.fps);
					}
				}
					
			} else {
				char.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
			}
			
			if(!char.animOffsets.exists(newAnim.anim)) {
				char.addOffset(newAnim.anim, 0, 0);
			}
			char.animationsArray.push(newAnim);

			if(lastAnim == animationInputText.text) {
				var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
				if(leAnim != null && leAnim.frames.length > 0) {
					char.playAnim(lastAnim, true);
				} else {
					for(i in 0...char.animationsArray.length) {
						if(char.animationsArray[i] != null) {
							leAnim = char.animation.getByName(char.animationsArray[i].anim);
							if(leAnim != null && leAnim.frames.length > 0) {
								char.playAnim(char.animationsArray[i].anim, true);
								curAnim = i;
								break;
							}
						}
					}
				}
			}

			reloadAnimationDropDown();
			reloadAnimList();
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 130, "Remove", function() {
			for (anim in char.animationsArray) {
				if(animationInputText.text == anim.anim) {
					var resetAnim:Bool = false;
					if(char.animation.curAnim != null && anim.anim == char.animation.curAnim.name) resetAnim = true;

					if(char.animation.getByName(anim.anim) != null) {
						char.animation.remove(anim.anim);
					}
					if(char.animOffsets.exists(anim.anim)) {
						char.animOffsets.remove(anim.anim);
					}
					char.animationsArray.remove(anim);

					if(resetAnim && char.animationsArray.length > 0) {
						char.playAnim(char.animationsArray[0].anim, true);
					}
					reloadAnimationDropDown();
					reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		var swagArray:Array<Dynamic> = [animationInputText, animationNameInputText, animationIndicesInputText, animationNameFramerate, animationLoopCheckBox, addUpdateButton, removeButton, ghostDropDown, animationDropDown];
	
		for (i in 0...swagArray.length){
			tab_group.add(swagArray[i]);
		}

		UI_characterbox.addGroup(tab_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == healthIconInputText) {
				leHealthIcon.changeIcon(healthIconInputText.text);
				char.healthIcon = healthIconInputText.text;
				updatePresence();
			}
			else if(sender == noteSkinInputText) {
				char.noteSkin = noteSkinInputText.text;
			}
			else if(sender == imageInputText) {
				char.imageFile = imageInputText.text;
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
				if(sender == healthIconInputText) {
					leHealthIcon.changeIcon(healthIconInputText.text);
					char.healthIcon = healthIconInputText.text;
					updatePresence();
				}
				else if(sender == noteSkinInputText) {
					char.noteSkin = noteSkinInputText.text;
				}
				else if(sender == imageInputText) {
					char.imageFile = imageInputText.text;
				}
			} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
				if (sender == scaleStepper)
				{
					reloadCharacterImage();
					char.jsonScale = sender.value;
					char.setGraphicSize(Std.int(char.width * char.jsonScale));
					char.updateHitbox();
					reloadGhost();
					updatePointerPos();
	
					if(char.animation.curAnim != null) {
						char.playAnim(char.animation.curAnim.name, true);
					}
				}
				else if(sender == positionXStepper)
				{
					char.positionArray[0] = positionXStepper.value;
					if (!char.isPlayer)
						char.x = char.positionArray[0] + OFFSET_X + 100;
					updatePointerPos();
				}
				else if(sender == singDurationStepper)
				{
					char.singDuration = singDurationStepper.value;//ermm you forgot this??
				}
				else if(sender == positionYStepper)
				{
					char.positionArray[1] = positionYStepper.value;
					if (!char.isPlayer)
						char.y = char.positionArray[1];
					updatePointerPos();
				}
				else if(sender == playerPositionXStepper)
				{
					char.playerPositionArray[0] = playerPositionXStepper.value;
					if (char.isPlayer)
						char.x = char.playerPositionArray[0] + OFFSET_X + 100;
					updatePointerPos();
				}
				else if(sender == playerPositionYStepper)
				{
					char.playerPositionArray[1] = playerPositionYStepper.value;
					if (char.isPlayer)
						char.y = char.playerPositionArray[1];
					updatePointerPos();
				}
				else if(sender == positionCameraXStepper)
				{
					char.cameraPosition[0] = positionCameraXStepper.value;
					updatePointerPos();
				}
				else if(sender == positionCameraYStepper)
				{
					char.cameraPosition[1] = positionCameraYStepper.value;
					updatePointerPos();
				}
				else if(sender == playerPositionCameraXStepper)
				{
					char.playerCameraPosition[0] = playerPositionCameraXStepper.value;
					updatePointerPos();
				}
				else if(sender == playerPositionCameraYStepper)
				{
					char.playerCameraPosition[1] = playerPositionCameraYStepper.value;
					updatePointerPos();
				}
				else if(sender == healthColorStepperR)
				{
					char.healthColorArray[0] = Math.round(healthColorStepperR.value);
					healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				}
				else if(sender == healthColorStepperG)
				{
					char.healthColorArray[1] = Math.round(healthColorStepperG.value);
					healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				}
				else if(sender == healthColorStepperB)
				{
					char.healthColorArray[2] = Math.round(healthColorStepperB.value);
					healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				}
			}
		}
	}

	function reloadCharacterImage() {
		var lastAnim:String = '';
		if(char.animation.curAnim != null) {
			lastAnim = char.animation.curAnim.name;
		}

		var anims:Array<AnimArray> = char.animationsArray.copy();

		var daPath:String = char.graphic.key;

		//if (char.spriteType == "TEXTURE")
		//	daPath = daPath + "/spritemap";

		Paths.currentTrackedAssets.remove(daPath);
		Paths.clearStoredMemory2(daPath, 'image');
		
		var canUseAtlas:Bool = false;

		#if flxanimate
		var animToFind:String = Paths.getPath('images/' + char.imageFile + '/Animation.json', TEXT, null, true);
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind)){
			canUseAtlas = true;
		}
		#end
		
		if (!canUseAtlas){	
			char.frames = Paths.getAtlasFromData(char.imageFile, char.spriteType);
		}
		else{
			char.frames = Paths.getAtlasFromData("characters/blank", "SPARROW");

			remove(char.atlasChar);
			char.destroyAtlas();
			#if flxanimate
			char.atlasChar = new FlxAnimate(char.x, char.y, Paths.getPath("images/" + char.imageFile, TEXT, null, true));
			char.atlasChar.showPivot = false;
			#end
			add(char.atlasChar);
		}
	
		if(char.animationsArray != null && char.animationsArray.length > 0) {
			for (anim in char.animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;
				if(animIndices != null && animIndices.length > 0) {
					if (animName == "")
						char.animation.add(animAnim, animIndices, animFps, animLoop);
					else
						char.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				} else {
					char.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}
		} else {
			char.quickAnimAdd('idle', 'BF idle dance');
		}
		
		if(lastAnim != '') {
			char.playAnim(lastAnim, true);
		} else {
			char.dance();
		}
		ghostDropDown.selectedLabel = '';
		reloadGhost();
	}

	function reloadAnimList():Void
	{
		var daLoop:Int = 0;

		var i:Int = animsTxtGroup.members.length-1;
		while(i >= 0) {
			var memb:FlxText = animsTxtGroup.members[i];
			if(memb != null) {
				memb.kill();
				animsTxtGroup.remove(memb);
				memb.destroy();
			}
			--i;
		}
		animsTxtGroup.clear();

		var text:FlxText = animsTxtGroup.recycle(FlxText);
		text.x = 10;
		text.y = 32 + (20 * daLoop);
		text.fieldWidth = 400;
		text.fieldHeight = 20;
		text.text = "Offsets:";
		text.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		text.scrollFactor.set();
		text.borderSize = 1;
		animsTxtGroup.add(text);
		daLoop++;

		for (anim in anims)
		{
			var text:FlxText = animsTxtGroup.recycle(FlxText);
			text.x = 10;
			text.y = 32 + (20 * daLoop);
			text.fieldWidth = 400;
			text.fieldHeight = 20;
			text.text = anim.anim + ": " + anim.offsets;
			text.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			animsTxtGroup.add(text);

			daLoop++;
		}

		daLoop++;

		var text:FlxText = animsTxtGroup.recycle(FlxText);
		text.x = 10;
		text.y = 32 + (20 * daLoop);
		text.fieldWidth = 400;
		text.fieldHeight = 20;
		text.text = "Player Offsets:";
		text.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		text.scrollFactor.set();
		text.borderSize = 1;
		animsTxtGroup.add(text);
		daLoop++;

		for (anim in anims)
		{
			var text:FlxText = animsTxtGroup.recycle(FlxText);
			text.x = 10;
			text.y = 32 + (20 * daLoop);
			text.fieldWidth = 400;
			text.fieldHeight = 20;
			text.text = anim.anim + ": " + (anim.playerOffsets != null ? anim.playerOffsets : anim.offsets);
			text.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			animsTxtGroup.add(text);

			daLoop++;
		}

		textAnim.visible = true;
		if(animsTxtGroup.length < 1) {
			var text:FlxText = new FlxText(10, 38, 0, "ERROR! No animations found.", 15);
			text.scrollFactor.set();
			text.borderSize = 1;
			animsTxtGroup.add(text);
			textAnim.visible = false;
		}
	}

	//more lua shit taken from psych
	public var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	
	public function addTextToDebug(text:String, ?color:FlxColor = FlxColor.RED) {
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
	}

	function loadChar(isDad:Bool, blahBlahBlah:Bool = true) {
		#if !blantBuild
		if (daAnim.contains('-embed')){
			addTextToDebug("ACCESS DENIED: CHARACTER IS EMBEDDED!", 0xFFFF0000);
			daAnim = "bf";
			loadChar(isDad, blahBlahBlah);

			return;
		}
		#end
		
		var i:Int = charLayer.members.length-1;
		while(i >= 0) {
			var memb:Character = charLayer.members[i];
			if(memb != null) {
				memb.kill();
				charLayer.remove(memb);

				if(memb.useAtlas){
					remove(memb.atlasChar);
					memb.atlasChar.destroy();
				}
				memb.destroy();
			}
			--i;
		}
		charLayer.clear();

		ghostChar = new Character(0, 0, daAnim, !isDad);
		ghostChar.debugMode = true;
		ghostChar.alpha = 0.6;

		char = new Character(0, 0, daAnim, !isDad);
		char.debugMode = true;
		char.loadCharacter(daAnim, !isDad); //fixes the offset issues

		anims = char.animationsArray;

		if(anims[0] != null) {
			char.playAnim(anims[0].anim, true);
		}



		charLayer.add(ghostChar);
		charLayer.add(char);

		if (!char.isCustom)
		{
			var offset = new CharacterOffsets(daAnim, false);
			char.positionArray[0] = offset.daOffsetArray[0];
			char.positionArray[1] = offset.daOffsetArray[1];

			var daOffset = new CharacterOffsets(daAnim, true);
			char.playerPositionArray[0] = daOffset.daOffsetArray[0];

			if (daOffset.hasOffsets)
				char.playerPositionArray[1] = daOffset.daOffsetArray[1] + 350;

			fixTheDamnOffsets();
		}

		var posArrToCheck = isDad ? char.positionArray : char.playerPositionArray;
		char.setPosition(posArrToCheck[0] + OFFSET_X + 100, posArrToCheck[1]);
		
		if (char.useAtlas){
			add(char.atlasChar);
		}

		/* THIS FUNCTION WAS USED TO PUT THE .TXT OFFSETS INTO THE .JSON

		for (anim => offset in char.animOffsets) {
			var leAnim:AnimArray = findAnimationByName(anim);
			if(leAnim != null) {
				leAnim.offsets = [offset[0], offset[1]];
			}
		}*/

		if(blahBlahBlah) {
			reloadAnimList();
		}
		reloadCharacterOptions();
		reloadBGs();
		updatePointerPos();
	}

	function updatePointerPos() {
		var x:Float = char.getMidpoint().x;
		var y:Float = char.getMidpoint().y;
		if(!char.isPlayer) {
			x += 150 + char.cameraPosition[0];
			y -= 100 - char.cameraPosition[1];
		} else {
			x -= 100 + char.playerCameraPosition[0];
			y -= 100 - char.playerCameraPosition[1];
		}
	
		x -= cameraFollowPointer.width / 2;
		y -= cameraFollowPointer.height / 2;
		cameraFollowPointer.setPosition(x, y);
	}

	function findAnimationByName(name:String):AnimArray {
		for (anim in char.animationsArray) {
			if(anim.anim == name) {
				return anim;
			}
		}
		return null;
	}

	function reloadCharacterOptions() {
		if(UI_characterbox != null) {
			
			imageInputText.text = char.imageFile;
	
			healthIconInputText.text = char.healthIcon;
			noteSkinInputText.text = char.noteSkin;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.jsonScale;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			resetHealthBarColor();
			leHealthIcon.changeIcon(healthIconInputText.text);
			positionXStepper.value = char.positionArray[0];
			positionYStepper.value = char.positionArray[1];
			playerPositionXStepper.value = char.playerPositionArray[0];
			playerPositionYStepper.value = char.playerPositionArray[1];
			positionCameraXStepper.value = char.cameraPosition[0];
			positionCameraYStepper.value = char.cameraPosition[1];
			playerPositionCameraXStepper.value = char.playerCameraPosition[0];
			playerPositionCameraYStepper.value = char.playerCameraPosition[1];
			psychPlayerCheckBox.checked = char.isPsychPlayer;
			

			if (char.spriteType != null)
				spriteTypeDropDown.selectedLabel = Std.string(char.spriteType).toUpperCase();
			else
				spriteTypeDropDown.selectedLabel = "SPARROW";

			reloadAnimationDropDown();
			updatePresence();
		}
	}

	function reloadAnimationDropDown() {
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (anim in char.animationsArray) {
			if (anim.playerOffsets == null && anim.offsets != null)
				anim.playerOffsets = anim.offsets;
			anims.push(anim.anim);
			ghostAnims.push(anim.anim);
		}
		if(anims.length < 1) anims.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(anims, true));
		ghostDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(ghostAnims, true));
		reloadGhost();
	}

	function reloadGhost() {
		ghostChar.frames = char.frames;
		for (anim in char.animationsArray) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			if(animIndices != null && animIndices.length > 0) {
				if (animName == "")
					ghostChar.animation.add(animAnim, animIndices, animFps, animLoop);
				else
					ghostChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			} else {
				ghostChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
			}

			if(anim.offsets != null && anim.offsets.length > 1) {
				ghostChar.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}

			if(anim.playerOffsets != null && anim.playerOffsets.length > 1) {
				ghostChar.addPlayerOffset(anim.anim, anim.playerOffsets[0], anim.playerOffsets[1]);
			}
		}

		char.alpha = 0.85;
		ghostChar.visible = true;
		if(ghostDropDown.selectedLabel == '') {
			ghostChar.visible = false;
			char.alpha = 1;
		}
		ghostChar.color = 0xFF666688;
		
		ghostChar.setGraphicSize(Std.int(ghostChar.width * char.jsonScale));
		ghostChar.updateHitbox();
	}

	function reloadCharacterDropDown() {
		var charsLoaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		characterList = ["bf"];

		if (Mods.currentModDirectory != 'BETADCIU')
		{
			if (FileSystem.exists(Paths.modFolders('data/characterList.txt'))){
				characterList = CoolUtil.coolTextFile2(Paths.modFolders('data/characterList.txt'));
			}
			
			 //READDED
			 var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Mods.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];
			 for (i in 0...directories.length) {
				 var directory:String = directories[i];
				 if(FileSystem.exists(directory)) {
					 for (file in FileSystem.readDirectory(directory)) {
						 var path = haxe.io.Path.join([directory, file]);
						 if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
							 var charToCheck:String = file.substr(0, file.length - 5);
							 if(!characterList.contains(charToCheck)) {
								 characterList.push(charToCheck);
								 charsLoaded.set(charToCheck, true);
							 }
						 }
					 }
				 }
			 }
		}
		else
		{
			//FOR BETADCIU
			if (FileSystem.exists(Paths.modFolders('data/characterList.txt')))
				characterList = CoolUtil.coolTextFile2(Paths.modFolders('data/characterList.txt'));
			else
				characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end

		charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = daAnim;
	}

	function runColorConversion()
	{
		var coolColor = FlxColor.fromString('#' + char.iconColor);

		char.healthColorArray[0] = coolColor.red;
		char.healthColorArray[1] = coolColor.green;
		char.healthColorArray[2] = coolColor.blue;
	}
	function resetHealthBarColor() {

		if (!char.isCustom)
			runColorConversion();

		healthColorStepperR.value = char.healthColorArray[0];
		healthColorStepperG.value = char.healthColorArray[1];
		healthColorStepperB.value = char.healthColorArray[2];
		healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
	}

	function updatePresence() {
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.getCharacter());
		#end
	}

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenu> = [];

	override function update(elapsed:Float)
	{
		if (FlxG.keys.pressed.ALT && FlxG.keys.justPressed.FIVE){
			var idleAnim = findAnimationByName(char.danceIdle ? "danceRight" : "idle");
			var idleOffsets = [];

			if (idleAnim == null){
				idleAnim = char.animationsArray[0];
			}

			if (char.isPlayer){
				idleOffsets = idleAnim.playerOffsets;

				for (anim in char.animationsArray){
					if (anim.anim == "idle" || anim.anim == "danceRight"){
						continue;
					}

					anim.playerOffsets = [anim.playerOffsets[0] - idleOffsets[0], anim.playerOffsets[1] - idleOffsets[1]];
				}

				idleAnim.playerOffsets = [0, 0];

				char.playerPositionArray[0] += idleOffsets[0];
				char.playerPositionArray[1] += idleOffsets[1];
			}
			else{
				idleOffsets = idleAnim.offsets;

				for (anim in char.animationsArray){
					if (anim.anim == "idle" || anim.anim == "danceRight"){
						continue;
					}

					anim.offsets = [anim.offsets[0] - idleOffsets[0], anim.offsets[1] - idleOffsets[1]];
				}

				idleAnim.offsets = [0, 0];
				char.positionArray[0] += idleOffsets[0];
				char.positionArray[1] += idleOffsets[1];
			}

			char.playAnim(char.animation.curAnim.name, true);
		}
		
		if(char.animationsArray[curAnim] != null) {
			textAnim.text = char.animationsArray[curAnim].anim;

			var curAnim:FlxAnimation = char.animation.getByName(char.animationsArray[curAnim].anim);
			if(curAnim == null || curAnim.frames.length < 1) {
				textAnim.text += ' (ERROR!)';
			}
		} else {
			textAnim.text = '';
		}

		var blockInput:Bool = false;

		if (!blockInput) {
			for (inputText in blockPressWhileTypingOn) {
				if(inputText.hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;
				if(leText.hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			for (dropDownMenu in blockPressWhileScrolling) {
				if(dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			if (FlxG.keys.justPressed.ESCAPE) {
				MusicBeatState.switchState(new PlayState());
				FlxG.mouse.visible = false;
				inCharEditor = false;
				return;
			}
			
			if (FlxG.keys.justPressed.R) {
				FlxG.camera.zoom = 1;
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
			}

			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I)
					camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					camFollow.y += addToCam;

				if (FlxG.keys.pressed.J)
					camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					camFollow.x += addToCam;
			}

			if(char.animationsArray.length > 0) {
				if (FlxG.keys.justPressed.W){
					curAnim -= 1;
				}

				if (FlxG.keys.justPressed.S){
					curAnim += 1;
				}

				if (curAnim < 0){
					curAnim = char.animationsArray.length - 1;
				}
					
				if (curAnim >= char.animationsArray.length)
					curAnim = 0;

				if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
				{
					char.playAnim(char.animationsArray[curAnim].anim, true);
					reloadAnimList();
				}

				if (FlxG.keys.justPressed.R)
				{
					if (char.isPlayer)
					{
						char.animationsArray[curAnim].playerOffsets = [0, 0];
						char.addPlayerOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].playerOffsets[0], char.animationsArray[curAnim].playerOffsets[1]);
						ghostChar.addPlayerOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].playerOffsets[0], char.animationsArray[curAnim].playerOffsets[1]);
						reloadAnimList();
					}
					else
					{
						char.animationsArray[curAnim].offsets = [0, 0];
					
						char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
						ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
						reloadAnimList();
					}	
				}

				var controlArray:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
				
				for (i in 0...controlArray.length) {
					if(controlArray[i]) {
						var holdShift = FlxG.keys.pressed.SHIFT;
						var multiplier = 1;
						if (holdShift)
							multiplier = 10;
						if (FlxG.keys.pressed.ALT)
							multiplier = 50;

						var arrayVal = 0;
						if(i > 1) arrayVal = 1;

						var negaMult:Int = 1;
						if(i % 2 == 1) negaMult = -1;

						if (char.isPlayer)
						{
							char.animationsArray[curAnim].playerOffsets[arrayVal] += negaMult * multiplier;
							char.addPlayerOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].playerOffsets[0], char.animationsArray[curAnim].playerOffsets[1]);
							ghostChar.addPlayerOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].playerOffsets[0], char.animationsArray[curAnim].playerOffsets[1]);
						}
						else
						{
							char.animationsArray[curAnim].offsets[arrayVal] += negaMult * multiplier;
							char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
							ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
						}
					
						char.playAnim(char.animationsArray[curAnim].anim, false);
						if(ghostChar.animation.curAnim != null && char.animation.curAnim != null && char.animation.curAnim.name == ghostChar.animation.curAnim.name) {
							ghostChar.playAnim(char.animation.curAnim.name, false);
						}
						reloadAnimList();
					}
				}

				updateTextColors(); 
			}
		}

		//camMenu.zoom = FlxG.camera.zoom;
		ghostChar.setPosition(char.x, char.y);
		super.update(elapsed);
	}

	var _file:FileReference;
	/*private function saveOffsets()
	{
		var data:String = '';
		for (anim => offsets in char.animOffsets) {
			data += anim + ' ' + offsets[0] + ' ' + offsets[1] + '\n';
		}

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daAnim + "Offsets.txt");
		}
	}*/

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter() {
		var json = {
			"animations": char.animationsArray,
			"image": char.imageFile,
			"scale": char.jsonScale,
			"sing_duration": char.singDuration,
			"healthicon": char.healthIcon,
			"spriteType": char.spriteType,
		
			"position":	char.positionArray,
			"playerposition": char.playerPositionArray,
			"camera_position": char.cameraPosition,
			"player_camera_position": char.playerCameraPosition,
			"noteSkin": char.noteSkin,
		
			"flip_x": char.originalFlipX,
			"no_antialiasing": char.noAntialiasing,
			"isPlayerChar": char.isPsychPlayer,
			"healthbar_colors": char.healthColorArray
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$daAnim.json');
		}
	}

	function ClipboardAdd(prefix:String = ''):String {
		if(prefix.toLowerCase().endsWith('v')) //probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length-1);
		}

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}

	inline function updateTextColors()
	{
		var playerSplit = 0;

		for (i in 0...animsTxtGroup.members.length)
		{
			var text = animsTxtGroup.members[i];
			text.color = FlxColor.WHITE;

			if(text.text.split(':')[0] == char.animation.curAnim.name){
				if ((char.isPlayer && i > 1 + anims.length) || (!char.isPlayer && i < 1 + anims.length)){
					text.color = 0xFF66A9E8;
				}
			}
		}
	}
}
