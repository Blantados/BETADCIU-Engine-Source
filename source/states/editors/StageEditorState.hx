package states.editors;

import flixel.FlxObject;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import openfl.net.FileReference;
import flixel.math.FlxMath;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import lime.system.Clipboard;
import flixel.animation.FlxAnimation;
import lime.utils.Assets;
import flixel.graphics.frames.FlxAtlasFrames;

import objects.Stage;
import objects.Character;
import objects.Boyfriend;

import luafiles.ModchartState;
import luafiles.DebugLuaText;

using StringTools;

/**
	*DEBUG MODE
 */
class StageEditorState extends MusicBeatState
{
	var Stage:Stage;
	var ghoststage:Stage;
	var positioningstage:Stage;
	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	//var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daStage:String = "stage";
	var goToPlayState:Bool = true;
	var camFollow:FlxObject;

	public function new(daStage:String = "stage", goToPlayState:Bool = true)
	{
		super();
		this.daStage = daStage;
		this.goToPlayState = goToPlayState;

		if (daStage.contains('-embed')){
			daStage = "stage";
		}
	}

	var UI_box:FlxUITabMenu;
	var UI_stagebox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var changeBGbutton:FlxButton;
	var stageList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;
	var dad:Character;
	var gf:Character;
	var boyfriend:Character;

	var script:String = "";
	var indent:String = "";

	function scriptLine(line:String, space:Int = 0)
	{
		script += indent+line + "\n";
		for(i in 0...script.length)
		{
			if (i < space)
				script += "\n";
		}
	}

	override function create()
	{
		FlxG.sound.playMusic(Paths.music("kawaruslow"), 0.7);

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

		var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

		loadStage(false);

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		var tipTextArray:Array<String> = 
		"\nW/S - Previous/Next Animation
		\nSpace - Play Animation
		\nArrow Keys - Move Character Offset
		\nT - Reset Current Offset
		\nHold Shift to Move 10x faster\n".split("\n");

		for (i in 0...tipTextArray.length-1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camMenu];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

		FlxG.camera.follow(camFollow);

		var tabs = [
			//{name: "Offsets", label: "Offsets"},
			{name: "Settings", label: "Settings"},
		];
		
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: "Stage", label: "Stage"},
			{name: "Stage Objects", label: "Stage Objects"},
		];
		UI_stagebox = new FlxUITabMenu(null, tabs, true);
		UI_stagebox.cameras = [camMenu];

		UI_stagebox.resize(350, 400);
		UI_stagebox.x = UI_box.x - 100;
		UI_stagebox.y = UI_box.y + UI_box.height;
		UI_stagebox.scrollFactor.set();
		add(UI_stagebox);
		add(UI_box);

		addStageUI();
		addSettingsUI();
		addStageObjectsUI();

		FlxG.mouse.visible = true;
		reloadStageOptions();

		super.create();
	}

	function reloadObjectsDropDown() {
		var objects:Array<String> = [];

		for (key in Stage.swagBacks.keys()) {
			
			objects.push(key);
		}
		if(objects.length < 1) objects.push("NO OBJECTS"); //Prevents crash

		if (currentObject == null)
			currentObject = changeSpriteClass(Stage.swagBacks[objects[0]]);

		for (key in Stage.swagBacks.keys()) {
			if (Stage.swagBacks.get(key) == currentObject)
				reloadObjectInfo(key);
		}
		
		objectDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(objects, true));
	}

	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var playerPositionXStepper:FlxUINumericStepper;
	var playerPositionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;
	var playerPositionCameraXStepper:FlxUINumericStepper;
	var playerPositionCameraYStepper:FlxUINumericStepper;

	var gfPositionXStepper:FlxUINumericStepper;
	var gfPositionYStepper:FlxUINumericStepper;
	var gfPositionCameraXStepper:FlxUINumericStepper;
	var gfPositionCameraYStepper:FlxUINumericStepper;

	var focusPlayerCheckBox:FlxUICheckBox;
	var camZoomStepper:FlxUINumericStepper;

	function addStageUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Stage";

		positionXStepper = new FlxUINumericStepper(15, 35, 10, Stage.dadXOffset, -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, Stage.dadYOffset, -9000, 9000, 0);

		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, Stage.opponentCameraOffset[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, Stage.opponentCameraOffset[0], -9000, 9000, 0);

		playerPositionXStepper = new FlxUINumericStepper(positionXStepper.x, positionCameraXStepper.y + 40, 10, Stage.bfXOffset, -9000, 9000, 0);
		playerPositionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionCameraYStepper.y + 40, 10, Stage.bfYOffset, -9000, 9000, 0);

		playerPositionCameraXStepper = new FlxUINumericStepper(playerPositionXStepper.x, playerPositionXStepper.y + 40, 10, Stage.boyfriendCameraOffset[0], -9000, 9000, 0);
		playerPositionCameraYStepper = new FlxUINumericStepper(playerPositionYStepper.x, playerPositionYStepper.y + 40, 10, Stage.boyfriendCameraOffset[1], -9000, 9000, 0);

		gfPositionXStepper = new FlxUINumericStepper(positionXStepper.x, playerPositionCameraXStepper.y + 40, 10, Stage.bfXOffset, -9000, 9000, 0);
		gfPositionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, playerPositionCameraYStepper.y + 40, 10, Stage.bfYOffset, -9000, 9000, 0);

		gfPositionCameraXStepper = new FlxUINumericStepper(gfPositionXStepper.x, gfPositionXStepper.y + 40, 10, Stage.girlfriendCameraOffset[0], -9000, 9000, 0);
		gfPositionCameraYStepper = new FlxUINumericStepper(gfPositionYStepper.x, gfPositionYStepper.y + 40, 10, Stage.girlfriendCameraOffset[1], -9000, 9000, 0);

		camZoomStepper = new FlxUINumericStepper(15, gfPositionCameraYStepper.y + 40, 0.05, 1, 0.05, 100, 2);

		focusPlayerCheckBox = new FlxUICheckBox(positionYStepper.x + 80, positionYStepper.y, null, null, "Focus Player", 100);
		focusPlayerCheckBox.checked = focusPlayer;
		focusPlayerCheckBox.callback = function() {
			focusPlayer = !focusPlayer;
		};

		var freeCameraCheckBox = new FlxUICheckBox(positionYStepper.x + 80, focusPlayerCheckBox.y + 40, null, null, "Free Camera", 100);
		freeCameraCheckBox.checked = freeCamera;
		freeCameraCheckBox.callback = function() {
			freeCamera = !freeCamera;
		};

		var saveStageJsonButton:FlxButton = new FlxButton(focusPlayerCheckBox.x, 150, "Save Stage JSON", function() {
			saveStageJson();
		});

		var saveStageLuaButton:FlxButton = new FlxButton(focusPlayerCheckBox.x, saveStageJsonButton.y + 50, "Save Stage\nLua", function() {
			saveStageLua();
		});

		saveStageJsonButton.setGraphicSize(80, 30);
		saveStageJsonButton.updateHitbox();
		
		saveStageLuaButton.setGraphicSize(80, 30);
		saveStageLuaButton.updateHitbox();

		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, "Opponent X/Y:"));
		tab_group.add(new FlxText(playerPositionXStepper.x, playerPositionXStepper.y - 18, 0, "Player X/Y:"));
		tab_group.add(new FlxText(gfPositionXStepper.x, gfPositionXStepper.y - 18, 0, "GF X/Y:"));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, "Camera X/Y:"));
		tab_group.add(new FlxText(playerPositionCameraXStepper.x, playerPositionCameraXStepper.y - 18, 0, "Player Camera X/Y:"));
		tab_group.add(new FlxText(gfPositionCameraXStepper.x, gfPositionCameraXStepper.y - 18, 0, "GF Camera X/Y:"));
		tab_group.add(new FlxText(15, camZoomStepper.y - 18, 0, "Cam Zoom:"));

		tab_group.add(focusPlayerCheckBox);
		tab_group.add(freeCameraCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(gfPositionXStepper);
		tab_group.add(gfPositionYStepper);
		tab_group.add(gfPositionCameraXStepper);
		tab_group.add(gfPositionCameraYStepper);
		tab_group.add(playerPositionXStepper);
		tab_group.add(playerPositionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(playerPositionCameraXStepper);
		tab_group.add(playerPositionCameraYStepper);
		tab_group.add(saveStageJsonButton);
		tab_group.add(saveStageLuaButton);
		tab_group.add(camZoomStepper);
		UI_stagebox.addGroup(tab_group);
	}

	var objectDropDown:FlxUIDropDownMenu;
	var objectXStepper:FlxUINumericStepper;
	var objectYStepper:FlxUINumericStepper;
	var objectScaleXStepper:FlxUINumericStepper;
	var objectScaleYStepper:FlxUINumericStepper;
	var objectScrollFactorXStepper:FlxUINumericStepper;
	var objectScrollFactorYStepper:FlxUINumericStepper;
	var objectOrderStepper:FlxUINumericStepper;
	var objectAlphaStepper:FlxUINumericStepper;
	public var currentObject:FlxSprite; // we need to access curAnim

	var objectInputText:FlxUIInputText;
	var objectNameInputText:FlxUIInputText;

	var animationDropDown:FlxUIDropDownMenu;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;

	function addStageObjectsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Stage Objects";

		objectDropDown = new FlxUIDropDownMenu(15, 30, FlxUIDropDownMenu.makeStrIdLabelArray([""], true), function(pressed:String) {
			currentObject = changeSpriteClass(Stage.swagBacks[objectDropDown.selectedLabel]);
			reloadObjectInfo(objectDropDown.selectedLabel);
		});

		objectInputText = new FlxUIInputText(15, 70, 80, '', 8);
		objectNameInputText = new FlxUIInputText(objectInputText.x, objectInputText.y + 35, 150, '', 8);

		objectXStepper = new FlxUINumericStepper(175, 30, 10, 0, -9000, 9000, 0);
		objectYStepper = new FlxUINumericStepper(objectXStepper.x + 60, objectXStepper.y, 10, 0, -9000, 9000, 0);

		objectScaleXStepper = new FlxUINumericStepper(objectXStepper.x, objectXStepper.y + 40, 0.1, 1, -9000, 9000, 1);
		objectScaleYStepper = new FlxUINumericStepper(objectYStepper.x, objectYStepper.y + 40, 0.1, 1, -9000, 9000, 1);

		objectScrollFactorXStepper = new FlxUINumericStepper(objectXStepper.x, objectScaleXStepper.y + 40, 0.1, 1, -9000, 9000, 1);
		objectScrollFactorYStepper = new FlxUINumericStepper(objectXStepper.x + 60, objectScaleYStepper.y + 40, 0.1, 1, -9000, 9000, 1);

		objectOrderStepper = new FlxUINumericStepper(objectXStepper.x, objectScrollFactorXStepper.y + 40, 1, 1, 0, 100, 0);
		objectAlphaStepper = new FlxUINumericStepper(objectXStepper.x+80, objectScrollFactorXStepper.y + 40, 0.05, 1, 0, 1, 2);

		animationInputText = new FlxUIInputText(15, objectNameInputText.y + 120, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenu(15, animationInputText.y - 55, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			if (currentObject.numFrames <= 1)
				return;
			
			var selectedAnimation:Int = Std.parseInt(pressed);
			var daAnim:String = currentObjectAnimationList[selectedAnimation].name;
			trace('anim should be '+ daAnim);
			
			currentObject.animation.play(daAnim);

			if (currentObject.animation.getByName(daAnim) != null)
			{
				var daFrameName:String = currentObject.animation.frameName;
				animationInputText.text = currentObject.animation.curAnim.name;
				animationNameInputText.text = daFrameName.substr(0, daFrameName.length-4);
				animationLoopCheckBox.checked = currentObject.animation.curAnim.looped;
				animationNameFramerate.value = currentObject.animation.curAnim.frameRate;
	
				if (currentObject.animation.curAnim.frames != null)
				{
					animationIndicesInputText.text = "";

					var animIndices:String = "";
					
					if (checkXMLAnimLength(currentObject.graphic.key, animationNameInputText.text) != currentObject.animation.curAnim.frames.length)
					{
						var framesBefore:Int = checkXMLAnimLength(currentObject.graphic.key, animationNameInputText.text, true);

						for (i in 0...currentObject.animation.curAnim.frames.length)
							animIndices += (currentObject.animation.curAnim.frames[i]-framesBefore)+(i != currentObject.animation.curAnim.frames.length-1 ? ',' : "");
					}
					
					animationIndicesInputText.text = animIndices;
				}
			}	
			else
				addTextToDebug("Animation doesn't exist!");			
		});

		var addUpdateButton:FlxButton = new FlxButton(20, 340, "Add/Update", function() {
			if (objectInputText.text == null)
				return;

			var leSprite:FlxSprite;
			var image:String = objectNameInputText.text;
			var rawPic:Dynamic;
			var rawXml:String;

			if(image != null && image.length > 0) {	
				Paths.cacheImage(image, true);
				rawPic = Paths.currentTrackedAssets.get(image);

				if (rawPic == null)
				{
					addTextToDebug("Image doesn't exist!");
					return;
				}
			}
			else
			{
				addTextToDebug("No Image Input!");
				return;
			}

			(Stage.swagBacks.exists(objectInputText.text) ? leSprite = Stage.swagBacks.get(objectInputText.text) : leSprite = new FlxSprite(objectXStepper.value, objectYStepper.value));

			if (leSprite.numFrames > 1)
			{
				if (FileSystem.exists(FileSystem.absolutePath("assets/shared/images/"+image+".xml")))
					rawXml = File.getContent(FileSystem.absolutePath("assets/shared/images/"+image+".xml"));
				else
					rawXml = File.getContent(Paths.xmlNew('images/' + image));

				leSprite.frames = FlxAtlasFrames.fromSparrow(rawPic,rawXml);
			}
			else
				leSprite.loadGraphic(rawPic);

			Stage.swagBacks.set(objectInputText.text, leSprite);
			remove(leSprite);
			insert(Std.int(objectOrderStepper.value), leSprite);
			currentObject = leSprite;
			reloadSwagBacks();
			
			//genBoyOffsets();
			trace('Added/Updated Object: ' + objectInputText.text);
		});

		var removeButton:FlxButton = new FlxButton(130, 340, "Remove", function() {
			if (Stage.swagBacks.exists(objectInputText.text))
			{
				var leSprite:Dynamic = Stage.swagBacks.get(objectInputText.text);
				leSprite.destroy();

				Stage.swagBacks.remove(objectInputText.text);

				trace('Removed Object: ' + objectInputText.text);
			}
		});

		var reloadAllButton:FlxButton = new FlxButton(240, 340, "Reload All Assets", function() {
			for (key in Stage.swagBacks.keys())
			{
				var leSprite:FlxSprite = Stage.swagBacks.get(key);
				var daPath:String = leSprite.graphic.key;
				var isAnimated:Bool = leSprite.numFrames > 1;

				Paths.currentTrackedAssets.remove(daPath);
				Paths.clearStoredMemory2(daPath, 'image');

				if (isAnimated){
					leSprite.frames = Paths.getAtlasFromData(daPath, "sparrow");
				}
				else{
					var rawPic = Paths.returnGraphic(daPath);
					
					leSprite.loadGraphic(rawPic);
				}
			}
		});

		/*playerPositionCameraXStepper = new FlxUINumericStepper(playerPositionXStepper.x, playerPositionXStepper.y + 40, 10, Stage.boyfriendCameraOffset[0], -9000, 9000, 0);
		playerPositionCameraYStepper = new FlxUINumericStepper(playerPositionYStepper.x, playerPositionYStepper.y + 40, 10, Stage.boyfriendCameraOffset[1], -9000, 9000, 0);

		gfPositionXStepper = new FlxUINumericStepper(positionXStepper.x, playerPositionCameraXStepper.y + 40, 10, Stage.bfXOffset, -9000, 9000, 0);
		gfPositionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, playerPositionCameraYStepper.y + 40, 10, Stage.bfYOffset, -9000, 9000, 0);

		gfPositionCameraXStepper = new FlxUINumericStepper(gfPositionXStepper.x, gfPositionXStepper.y + 40, 10, Stage.girlfriendCameraOffset[0], -9000, 9000, 0);
		gfPositionCameraYStepper = new FlxUINumericStepper(gfPositionYStepper.x, gfPositionYStepper.y + 40, 10, Stage.girlfriendCameraOffset[1], -9000, 9000, 0);

		camZoomStepper = new FlxUINumericStepper(15, gfPositionCameraYStepper.y + 40, 0.05, 1, 0.05, 100, 2);

		focusPlayerCheckBox = new FlxUICheckBox(gfPositionCameraYStepper.x + 80, gfPositionCameraYStepper.y, null, null, "Focus Player", 100);
		focusPlayerCheckBox.checked = focusPlayer;
		focusPlayerCheckBox.callback = function() {
			focusPlayer = !focusPlayer;
		};

		var saveStageJsonButton:FlxButton = new FlxButton(focusPlayerCheckBox.x, 150, "Save Stage JSON", function() {
			saveStageJson();
		});

		var saveStageLuaButton:FlxButton = new FlxButton(focusPlayerCheckBox.x, saveStageJsonButton.y + 50, "Save Stage\nLua", function() {
			saveStageLua();
		});

		saveStageJsonButton.setGraphicSize(80, 30);
		saveStageJsonButton.updateHitbox();
		
		saveStageLuaButton.setGraphicSize(80, 30);
		saveStageLuaButton.updateHitbox();*/

		tab_group.add(objectXStepper);
		tab_group.add(objectYStepper);
		tab_group.add(objectScaleXStepper);
		tab_group.add(objectScaleYStepper);
		tab_group.add(objectScrollFactorXStepper);
		tab_group.add(objectScrollFactorYStepper);
		tab_group.add(objectOrderStepper);
		tab_group.add(objectAlphaStepper);
		tab_group.add(objectInputText);
		tab_group.add(objectNameInputText);
		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(reloadAllButton);
		
		tab_group.add(new FlxText(objectInputText.x, objectInputText.y - 18, 0, 'Object name:'));
		tab_group.add(new FlxText(objectNameInputText.x, objectNameInputText.y - 18, 0, "Object's image name:"));
		tab_group.add(new FlxText(objectXStepper.x, objectXStepper.y - 18, 0, "Object X/Y:"));
		tab_group.add(new FlxText(objectOrderStepper.x, objectOrderStepper.y - 18, 0, "Object Order:"));
		tab_group.add(new FlxText(objectAlphaStepper.x, objectAlphaStepper.y - 18, 0, "Object Alpha:"));
		tab_group.add(new FlxText(objectScaleXStepper.x, objectScaleXStepper.y - 18, 0, "Object Scale X/Y:"));
		tab_group.add(new FlxText(objectScrollFactorXStepper.x, objectScrollFactorYStepper.y - 18, 0, "Object ScrollFactor X/Y:"));
		tab_group.add(new FlxText(objectDropDown.x, objectDropDown.y - 18, 0, "Stage Objects:"));

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationDropDown);
		tab_group.add(objectDropDown);

		UI_stagebox.addGroup(tab_group);
	}

	function reloadObjectInfo(objName:String)
	{
		objectNameInputText.text = (currentObject.graphic.key != null ? currentObject.graphic.key : "NO IMAGE");
		objectInputText.text = objName;
		objectXStepper.value = currentObject.x;
		objectYStepper.value = currentObject.y;

		objectScaleXStepper.value = currentObject.scale.x;
		objectScaleYStepper.value = currentObject.scale.y;

		objectScrollFactorXStepper.value = currentObject.scrollFactor.x;
		objectScrollFactorYStepper.value = currentObject.scrollFactor.y;
		objectAlphaStepper.value = currentObject.alpha;
		objectOrderStepper.value = 0;

		var swagArray:Array<String> = [];
		for (key in Stage.swagBacks.keys())
		{
			swagArray.push(key);
		}
		for (i in 0...swagArray.length)
		{
			if (Stage.swagBacks.get(swagArray[i]) == currentObject)
			{
				objectOrderStepper.value = i;
			}
		}
		reloadAnimationDropDown();
	}

	var currentObjectAnimationList:Array<FlxAnimation> = [];

	public function checkXMLAnimLength(xmlPath:String, frameName:String, ?framesBefore:Bool = false)
	{
		//i swear this is gonna take me another five hours... wait it only took 10 minutes? neat.
		var rawXml:String;

		if (FileSystem.exists(FileSystem.absolutePath("assets/shared/images/"+xmlPath+".xml")))
			rawXml = File.getContent(FileSystem.absolutePath("assets/shared/images/"+xmlPath+".xml"));
		else
			rawXml = File.getContent(Paths.xmlNew('images/' + xmlPath));

		var daXml:Xml = Xml.parse(rawXml);
		var fast = new haxe.xml.Access(daXml);
		var users = fast.node.TextureAtlas;
		var animNo:Int = 0;
		var framesBeforeAnim:Int = 0;

		for (SubTexture in users.nodes.SubTexture) {
			var name = Std.string(SubTexture.att.name);
			var nameCut = name.substr(0, name.length - 4);
			
			if (animNo == 0)
				framesBeforeAnim++;

			if (nameCut == frameName)
				animNo++;
		}

		if (framesBefore)
			return framesBeforeAnim;

		return animNo;
	}

	function reloadAnimationDropDown() {
		var anims:Array<String> = [];
		
		var daObject:FlxSprite = currentObject; // convert or it won't read it right

		if (daObject.numFrames > 1)
		{
			var daAnims:Array<FlxAnimation> = daObject.animation.getAnimationList();

			currentObjectAnimationList = daAnims;
		
			for (i in 0...daAnims.length)
				anims.push(daAnims[i].name);
		}
	
		if(anims.length < 1) anims.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(anims, true));
	}

	var focusPlayer:Bool = false;

	var stageDropDown:FlxUIDropDownMenu;
	function addSettingsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		stageDropDown = new FlxUIDropDownMenu(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray([""], true), function(stage:String)
		{
			daStage = stageList[Std.parseInt(stage)];
			loadStage();
			updatePresence();
			reloadStageDropDown();
		});
		stageDropDown.selectedLabel = daStage;
		reloadStageDropDown();

		var reloadStage:FlxButton = new FlxButton(140, 20, "Reload Stage", function()
		{
			loadStage();
			reloadStageDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			daStage = "stage";
			loadStage();
		});

		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;

		tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 18, 0, "Character:"));
		tab_group.add(reloadStage);
		tab_group.add(stageDropDown);
		tab_group.add(reloadStage);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);
	}

	function reloadStageOptions() {
		if(UI_stagebox != null) {		
			focusPlayerCheckBox.checked = focusPlayer;
			//freeCameraCheckBox.checked = freeCamera;
			camZoomStepper.value = Stage.camZoom;
			positionXStepper.value = Stage.dadYOffset;
			positionYStepper.value = Stage.dadYOffset;
			playerPositionXStepper.value = Stage.bfXOffset;
			playerPositionYStepper.value = Stage.bfYOffset;
			positionCameraXStepper.value = Stage.opponentCameraOffset[0];
			positionCameraYStepper.value = Stage.opponentCameraOffset[1];
			playerPositionCameraXStepper.value = Stage.boyfriendCameraOffset[0];
			playerPositionCameraYStepper.value = Stage.boyfriendCameraOffset[1];

			gfPositionXStepper.value = Stage.gfXOffset;
			gfPositionYStepper.value = Stage.gfYOffset;
			gfPositionCameraXStepper.value = Stage.girlfriendCameraOffset[0];
			gfPositionCameraYStepper.value = Stage.girlfriendCameraOffset[1];

			for (key in Stage.swagBacks.keys())
			{
				currentObject = changeSpriteClass(Stage.swagBacks[key]);
			}
					
			reloadObjectsDropDown();
			updatePresence();
		}
	}

	function changeSpriteClass(spr:Dynamic):FlxSprite
	{
		return spr;
	}

	function reloadStageDropDown() {
		var stagesLoaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		stageList = [];
		if (Mods.currentModDirectory != 'BETADCIU')
		{
				//READDED
				var directories:Array<String> = [Paths.mods('stages/'), Paths.mods(Mods.currentModDirectory + '/stages/'), Paths.getPreloadPath('stages/')];
				for (i in 0...directories.length) {
					var directory:String = directories[i];
					if(FileSystem.exists(directory)) {
						for (file in FileSystem.readDirectory(directory)) {
							var path = haxe.io.Path.join([directory, file]);
							if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
								var stageToCheck:String = file.substr(0, file.length - 5);
								if(!stagesLoaded.exists(stageToCheck)) {
									stageList.push(stageToCheck);
									stagesLoaded.set(stageToCheck, true);
								}
							}
						}
					}
				}
		}

		//so I"ll use this instead
		if (FileSystem.exists(Paths.modFolders("data/stageList.txt")))
			stageList = CoolUtil.coolTextFile2(Paths.modFolders("data/stageList.txt"));
		else
			stageList = CoolUtil.coolTextFile(Paths.txt("stageList"));
		#else
		stageList = CoolUtil.coolTextFile(Paths.txt("stageList"));
		#end

		stageDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(stageList, true));
		stageDropDown.selectedLabel = daStage;
	}


	function loadStage(?reload:Bool = true) {
		if (daStage.contains('-embed')){
			addTextToDebug("ACCESS DENIED: STAGE IS EMBEDDED!", 0xFFFF0000);
			return;
		}

		script = "";

		if (reload)
		{
			remove(gf);
			remove(dad);
			remove(boyfriend);

			if (Stage.isCustomStage && Stage.luaArray.length >= 1)
			{
				for (i in Stage.luaArray)
				{
					Stage.luaArray.remove(i);
					i.stop();
				}
				Stage.luaArray = [];
			}

			for (i in Stage.toAdd)
			{
				remove(i);
				i.destroy();
			}	

			for (ii in 0...3)
			{
				for (i in Stage.layInFront[ii])
				{
					remove(i);
					i.destroy();
				}	
			}

			Stage.swagBacks.clear();
				
			remove(Stage);
			Stage.destroy();
		}

		Stage = new Stage(daStage, false);

		addCharacters();

		for (i in Stage.toAdd)
		{
			add(i);
		}	
		
		for (index => array in Stage.layInFront)
		{
			switch (index)
			{
				case 0:
					add(gf);
					gf.scrollFactor.set(0.95, 0.95);
					for (bg in array)
						add(bg);	
				case 1:
					add(dad);
					for (bg in array)
						add(bg);	
				case 2:
					add(boyfriend);

					for (bg in array)
						add(bg);
			}
		}	

		if (Stage.hideGirlfriend)
			gf.alpha = 0;

		reloadStageOptions();
	}

	function addBGLine(bg:FlxSprite, place:Dynamic = -1)
	{
		indent = "\t";

		var daPlace:String = place;

		if (place == -1)
			daPlace = "false";

		if (place == 2){
			daPlace == "true";
		}
			
		var name:String = "";

		for (key in Stage.swagBacks.keys())
		{
			if (Stage.swagBacks.get(key) == bg)
				name = key;
		}

		if (bg.numFrames > 1)
		{
			scriptLine("makeAnimatedLuaSprite('"+name+"', '"+bg.graphic.key+"', "+bg.x+", "+bg.y+")");

			var anims:Array<FlxAnimation> = bg.animation.getAnimationList();

			for (i in 0...anims.length)
			{
				var curAnimName:String = bg.animation.curAnim.name;

				bg.animation.play(anims[i].name);

				var daFrameName:String = bg.animation.frameName;
				var daFrameNameCut:String = daFrameName.substr(0,daFrameName.length-4);
				var animIndices:String = "";

				if (checkXMLAnimLength(bg.graphic.key, daFrameNameCut) != bg.animation.curAnim.frames.length)
				{
					var framesBefore:Int = checkXMLAnimLength(bg.graphic.key, daFrameNameCut, true);

					for (i in 0...bg.animation.curAnim.frames.length)
						animIndices += (bg.animation.curAnim.frames[i]-framesBefore)+(i != bg.animation.curAnim.frames.length-1 ? ',' : "");
				}
				
				if (animIndices != "")
					scriptLine("addAnimationByIndices"+(anims[i].looped ? "Loop" : "")+"('"+name+"', '"+anims[i].name+"', '"+daFrameNameCut+"', '"+animIndices+"', "+anims[i].frameRate+")");
				else
					scriptLine("addAnimationByPrefix('"+name+"', '"+anims[i].name+"', '"+daFrameNameCut+"', "+anims[i].frameRate+", "+anims[i].looped+")");
				bg.animation.play(curAnimName);
			}
		}	
		else
		{
			scriptLine("makeLuaSprite('"+name+"', '"+bg.graphic.key+"', "+bg.x+", "+bg.y+")");
		}

		scriptLine("addLuaSprite('"+name+"', "+daPlace+")");

		indent = "";
	}

	function addExtraLines(bg:Dynamic)
	{
		indent = "\t";

		var name:String = "";

		for (key in Stage.swagBacks.keys())
		{
			if (Stage.swagBacks.get(key) == bg)
				name = key;
		}

		if (bg.scale.x != 1)
			scriptLine("scaleObject('" + name +"', " + bg.scale.x + ", " + bg.scale.y + (bg.offset.x == 0 ? ", false" : "") + ")");

		if (bg.scrollFactor.x != 1)
			scriptLine("setScrollFactor('"+name+"', "+bg.scrollFactor.x+", "+bg.scrollFactor.y+")");

		if (bg.alpha != 1)
			scriptLine("setProperty('"+name+".alpha', "+bg.alpha+")");

		if (bg.flipX != false)
			scriptLine("setProperty('"+name+".flipX', "+bg.flipX+")");

		scriptLine("");

		indent = "";
	}

	function updateCharPos(char:String) {
		switch(char)
		{
			case "dad":
			{
				dad.setPosition(100, 100);
				dad.x += dad.positionArray[0];
				dad.y += dad.positionArray[1];
				dad.x += Stage.dadXOffset;
				dad.y += Stage.dadYOffset;
			}
			case "gf":
			{
				gf.setPosition(400, 130);
				gf.x += gf.positionArray[0];
				gf.y += gf.positionArray[1];
				gf.x += Stage.gfXOffset;
				gf.y += Stage.gfYOffset;
			}
			case "bf" | "boyfriend":
			{
				boyfriend.setPosition(770, 450);
				boyfriend.x += boyfriend.positionArray[0];
				boyfriend.y += boyfriend.positionArray[1] - 350;	
				boyfriend.x += Stage.bfXOffset;
				boyfriend.y += Stage.bfYOffset;
			}
		}
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if (sender == camZoomStepper)
			{
				Stage.camZoom = camZoomStepper.value;
			}
			else if(sender == positionXStepper)
			{
				Stage.dadXOffset = positionXStepper.value;
				updateCharPos("dad");
			}	
			else if(sender == positionYStepper)
			{
				Stage.dadYOffset = positionYStepper.value;
				updateCharPos("dad");
			}
			else if(sender == playerPositionXStepper)
			{
				Stage.bfXOffset = playerPositionXStepper.value;
				updateCharPos("bf");
			}
			else if(sender == playerPositionYStepper)
			{
				Stage.bfYOffset = playerPositionYStepper.value;
				updateCharPos("bf");
			}
			else if(sender == gfPositionXStepper)
			{
				Stage.gfXOffset = gfPositionXStepper.value;
				updateCharPos("gf");
			}
			else if(sender == gfPositionYStepper)
			{
				Stage.gfYOffset = gfPositionYStepper.value;
				updateCharPos("gf");
			}
			else if(sender == positionCameraXStepper)
			{
				Stage.opponentCameraOffset[0] = positionCameraXStepper.value;
			}
			else if(sender == positionCameraYStepper)
			{
				Stage.opponentCameraOffset[1] = positionCameraYStepper.value;
			}
			else if(sender == gfPositionCameraXStepper)
			{
				Stage.girlfriendCameraOffset[0] = positionCameraXStepper.value;
			}
			else if(sender == gfPositionCameraYStepper)
			{
				Stage.girlfriendCameraOffset[1] = positionCameraYStepper.value;
			}
			else if(sender == playerPositionCameraXStepper)
			{
				Stage.boyfriendCameraOffset[0] = playerPositionCameraXStepper.value;
			}
			else if(sender == playerPositionCameraYStepper)
			{
				Stage.boyfriendCameraOffset[1] = playerPositionCameraYStepper.value;
			}
			else if(sender == objectXStepper)
			{
				currentObject.x = objectXStepper.value;
			}	
			else if(sender == objectYStepper)
			{
				currentObject.y = objectYStepper.value;
			}
			else if(sender == objectScaleXStepper)
			{
				currentObject.scale.x = objectScaleXStepper.value;
				currentObject.updateHitbox();
			}	
			else if(sender == objectScaleYStepper)
			{
				currentObject.scale.y = objectScaleYStepper.value;
				currentObject.updateHitbox();
			}
			else if(sender == objectScrollFactorXStepper)
			{
				currentObject.scrollFactor.x = objectScrollFactorXStepper.value;
			}	
			else if(sender == objectScrollFactorYStepper)
			{
				currentObject.scrollFactor.y = objectScrollFactorYStepper.value;
			}
			else if(sender == objectOrderStepper)
			{
				if (Stage.swagBacks.exists(objectInputText.text))
				{
					remove(currentObject, true);
					insert(Std.int(objectOrderStepper.value), currentObject);

					//modifies swagbacks
					reloadSwagBacks();
				}
			}	
			else if(sender == objectAlphaStepper)
			{
				currentObject.alpha = objectAlphaStepper.value;
			}
		}
	}

	function reloadSwagBacks()
	{
		var newSwagBacks: Map<String, Dynamic> = new Map();
		var swagArray:Array<String> = [];
		Stage.swagBacks.remove(objectInputText.text);

		for (key in Stage.swagBacks.keys())
		{
			swagArray.push(key);
		}

		for (i in 0...swagArray.length)
		{
			if (i == Std.int(objectOrderStepper.value))
				newSwagBacks.set(objectInputText.text, changeSpriteClass(currentObject));

			newSwagBacks.set(swagArray[i], Stage.swagBacks.get(swagArray[i]));
		}

		Stage.swagBacks = newSwagBacks;
		reloadObjectsDropDown();
	}

	public static var gfName:String = "gf";
	public static var dadName:String = "gf";
	public static var boyfriendName:String = "gf";
	
	function addCharacters()
	{
		gf = new Character(400, 130, gfName);
		gf.scrollFactor.set(0.95, 0.95);

		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];

		dad = new Character(100, 100, dadName);
	
		dad.x += dad.positionArray[0];
		dad.y += dad.positionArray[1];

		boyfriend = new Boyfriend(770, 450, boyfriendName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1] - 350;
		
		boyfriend.x += Stage.bfXOffset;
		boyfriend.y += Stage.bfYOffset;
		dad.x += Stage.dadXOffset;
		dad.y += Stage.dadYOffset;
		gf.x += Stage.gfXOffset;
		gf.y += Stage.gfYOffset;
	}

	function updatePresence() {
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Stage Editor", "Stage: " + daStage);
		#end
	}

	override function beatHit()
	{
		super.beatHit();

		Stage.beatHit();

		Stage.callOnLuas("onBeatHit", [curBeat]);

		var chars:Array<Character> = [gf, dad, boyfriend];

		for (i in 0...chars.length)
		{
			if (chars[i] != null)
				chars[i].dance();
		}
	}

	override function stepHit()
	{
		super.stepHit();

		Stage.stepHit();

	}

	var freeCamera:Bool = false;

	override function update(elapsed:Float)
	{
		var inputTexts:Array<FlxUIInputText> = [objectInputText, objectNameInputText];
		for (i in 0...inputTexts.length) {
			if(inputTexts[i].hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				super.update(elapsed);
				return;
			}
		}

		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

		if (!freeCamera)
		{
			if (!focusPlayer && (camFollow.x != dad.getMidpoint().x + 150 + dad.cameraPosition[0] + (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[0] : 0) || camFollow.y != dad.getMidpoint().y - 100 + dad.cameraPosition[1] + (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[1] : 0)))
			{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
	
				camFollow.x += dad.cameraPosition[0] + (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[0] : 0);
				camFollow.y += dad.cameraPosition[1] + (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[1] : 0);
			}
	
			if (focusPlayer && (camFollow.x != boyfriend.getMidpoint().x - 100 - boyfriend.cameraPosition[0] - (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[0] : 0) || camFollow.y != boyfriend.getMidpoint().y - 100 - boyfriend.cameraPosition[1] - (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[1] : 0) ))
			{
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
				camFollow.x -= boyfriend.cameraPosition[0] - (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[0] : 0);
				camFollow.y += boyfriend.cameraPosition[1] + (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[1] : 0);
			}	

			if (FlxG.camera.zoom != Stage.camZoom)
				FlxG.camera.zoom = FlxMath.lerp(Stage.camZoom, FlxG.camera.zoom, 0.95);
		}
	
		Conductor.songPosition += FlxG.elapsed * 1000;

		if (FlxG.keys.justPressed.ESCAPE) {
			MusicBeatState.switchState(new PlayState());
			FlxG.mouse.visible = false;
			return;
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

		if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}
		if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		//camMenu.zoom = FlxG.camera.zoom;
		
		Stage.update(elapsed);

		super.update(elapsed);
	}
	

	var _file:FileReference;

	/*private function saveOffsets()
	{
		var data:String = "";
		for (anim => offsets in stage.animOffsets) {
			data += anim + " " + offsets[0] + " " + offsets[1] + "\n";
		}

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, dastage + "Offsets.txt");
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

	function saveStageJson() {
		//we don"t do isPixelStage here.
		
		var json = {
			"directory": "",
			"defaultZoom": Stage.camZoom,
			"isPixelStage": false,

			"boyfriend": [770 + Stage.bfXOffset, 100 + Stage.bfYOffset],
			"girlfriend": [400 + Stage.gfXOffset, 130 + Stage.gfYOffset],
			"opponent": [100 + Stage.dadXOffset, 100 + Stage.dadYOffset],

			"camera_boyfriend": [Stage.boyfriendCameraOffset[0], Stage.boyfriendCameraOffset[1]],
			"camera_girlfriend": [Stage.girlfriendCameraOffset[0], Stage.girlfriendCameraOffset[1]],
			"camera_opponent": [Stage.opponentCameraOffset[0], Stage.opponentCameraOffset[1]]
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daStage + ".json");
		}
	}

	function saveStageLua()
	{
		scriptLine("function onCreate()");

		for (i in Stage.toAdd)
		{
			addBGLine(i, -1);
			addExtraLines(i);
		}	
		
		for (index => array in Stage.layInFront)
		{
			switch (index)
			{
				case 0:
					for (bg in array)
					{
						addBGLine(bg, index);
						addExtraLines(bg);
					}			
				case 1:
					for (bg in array)
					{
						addBGLine(bg, index);
						addExtraLines(bg);
					}			
				case 2:
					for (bg in array)
					{
						addBGLine(bg, true);
						addExtraLines(bg);
					}			
			}
		}	

		scriptLine("end");

		if (script != "")
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(script, daStage + ".lua");
		}
	}

	function ClipboardAdd(prefix:String = ""):String {
		if(prefix.toLowerCase().endsWith("v")) //probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length-1);
		}

		var text:String = prefix + Clipboard.text.replace("\n", "");
		return text;
	}

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
}
