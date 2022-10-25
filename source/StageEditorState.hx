package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxInputText;
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
import flixel.math.FlxMath;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import Stage;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import lime.system.Clipboard;
import flixel.animation.FlxAnimation;
import lime.utils.Assets;
import flixel.graphics.frames.FlxAtlasFrames;

#if desktop
import Sys;
import sys.FileSystem;
import sys.io.File;
#end

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
	}

	var UI_box:FlxUITabMenu;
	var UI_stagebox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var changeBGbutton:FlxButton;
	var leHealthIcon:HealthIcon;
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
			tipText.cameras = [camHUD];
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
		UI_box.cameras = [camHUD];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: "Stage", label: "Stage"},
			{name: "Stage Objects", label: "Stage Objects"},
		];
		UI_stagebox = new FlxUITabMenu(null, tabs, true);
		UI_stagebox.cameras = [camHUD];

		UI_stagebox.resize(350, 350);
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
		currentObject = Stage.swagBacks[objects[0]];
		reloadObjectInfo();

		objectDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(objects, true));
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

	var objectDropDown:FlxUIDropDownMenuCustom;
	var objectXStepper:FlxUINumericStepper;
	var objectYStepper:FlxUINumericStepper;
	var objectScaleXStepper:FlxUINumericStepper;
	var objectScaleYStepper:FlxUINumericStepper;
	var objectScrollFactorXStepper:FlxUINumericStepper;
	var objectScrollFactorYStepper:FlxUINumericStepper;
	var currentObject:Dynamic;


	function addStageObjectsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Stage Objects";

		objectDropDown = new FlxUIDropDownMenuCustom(15, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([""], true), function(pressed:String) {
			var selectedObject:Int = Std.parseInt(pressed);
			var objects:Array<String> = [];
			for (key in Stage.swagBacks.keys()) {
				objects.push(key);
			}
			if(objects.length < 1) objects.push("NO OBJECTS"); //Prevents crash
			currentObject = Stage.swagBacks[objects[selectedObject]];
			reloadObjectInfo();
		});

		objectXStepper = new FlxUINumericStepper(15, 75, 10, 0, -9000, 9000, 0);
		objectYStepper = new FlxUINumericStepper(objectXStepper.x + 60, objectXStepper.y, 10, 0, -9000, 9000, 0);

		objectScaleXStepper = new FlxUINumericStepper(objectXStepper.x, objectXStepper.y + 40, 10, 1, -9000, 9000, 0);
		objectScaleYStepper = new FlxUINumericStepper(objectYStepper.x, objectYStepper.y + 40, 10, 1, -9000, 9000, 0);

		objectScrollFactorXStepper = new FlxUINumericStepper(objectXStepper.x, objectScaleXStepper.y + 40, 10, 1, -9000, 9000, 0);
		objectScrollFactorYStepper = new FlxUINumericStepper(objectXStepper.x + 60, objectScaleYStepper.y + 40, 10, 1, -9000, 9000, 0);

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

		tab_group.add(new FlxText(objectXStepper.x, objectXStepper.y - 18, 0, "Object X/Y:"));

		tab_group.add(objectXStepper);
		tab_group.add(objectYStepper);

		tab_group.add(new FlxText(objectScaleXStepper.x, objectScaleXStepper.y - 18, 0, "Object Scale X/Y:"));

		tab_group.add(objectScaleXStepper);
		tab_group.add(objectScaleYStepper);

		tab_group.add(new FlxText(objectScrollFactorXStepper.x, objectScrollFactorYStepper.y - 18, 0, "Object ScrollFactor X/Y:"));

		tab_group.add(objectScrollFactorXStepper);
		tab_group.add(objectScrollFactorYStepper);

		tab_group.add(new FlxText(objectDropDown.x, objectDropDown.y - 18, 0, "Stage Objects:"));

		tab_group.add(objectDropDown);
		UI_stagebox.addGroup(tab_group);
	}
	
	function reloadObjectInfo()
	{
		objectXStepper.value = currentObject.x;
		objectYStepper.value = currentObject.y;

		objectScaleXStepper.value = currentObject.scale.x;
		objectScaleYStepper.value = currentObject.scale.y;

		objectScrollFactorXStepper.value = currentObject.scrollFactor.x;
		objectScrollFactorYStepper.value = currentObject.scrollFactor.y;
	}

	var focusPlayer:Bool = false;

	var stageDropDown:FlxUIDropDownMenuCustom;
	function addSettingsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		stageDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([""], true), function(stage:String)
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
				currentObject = Stage.swagBacks[key];
			}
			
			
			reloadObjectsDropDown();
			updatePresence();
		}
	}

	function reloadStageDropDown() {
		var stagesLoaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		stageList = [];
		/* //I don"t like this. It"s good for everything that ISN"T BETADCIU.
		var directories:Array<String> = [Paths.mods("characters/"), Paths.mods(Paths.currentModDirectory + "/characters/"), Paths.getPreloadPath("characters/")];
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith(".json")) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(!charsLoaded.exists(charToCheck)) {
							stageList.push(charToCheck);
							charsLoaded.set(charToCheck, true);
						}
					}
				}
			}
		}*/ 

		//so I"ll use this instead
		if (FileSystem.exists(Paths.modFolders("data/stageList.txt")))
			stageList = CoolUtil.coolTextFile2(Paths.modFolders("data/stageList.txt"));
		else
			stageList = CoolUtil.coolTextFile(Paths.txt("stageList"));
		#else
		stageList = CoolUtil.coolTextFile(Paths.txt("stageLists"));
		#end

		stageDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(stageList, true));
		stageDropDown.selectedLabel = daStage;
	}

	function loadStage(?reload:Bool = true) {
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
					i.die();
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

		reloadStageOptions();
	}

	function addBGLine(bg:Dynamic, place:Dynamic = -1)
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
				scriptLine("addAnimationByPrefix('"+name+"', '"+anims[i].name+"', '"+anims[i].name+"', "+anims[i].frameRate+", "+anims[i].looped+")");
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
			scriptLine("scaleObject('"+name+"', "+bg.scale.x+", "+bg.scale.y+")");

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
			}	
			else if(sender == objectScaleYStepper)
			{
				currentObject.scale.y = objectScaleYStepper.value;
			}
			else if(sender == objectScrollFactorXStepper)
			{
				currentObject.scrollFactor.x = objectScrollFactorXStepper.value;
			}	
			else if(sender == objectScrollFactorYStepper)
			{
				currentObject.scrollFactor.y = objectScrollFactorYStepper.value;
			}
		}
	}

	function addCharacters()
	{
		gf = new Character(400, 130, PlayState.SONG.gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];

		dad = new Character(100, 100, PlayState.SONG.player2);
	
		dad.x += dad.positionArray[0];
		dad.y += dad.positionArray[1];

		boyfriend = new Boyfriend(770, 450, PlayState.SONG.player1);

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

		var chars:Array<Character> = [gf, dad, boyfriend];

		for (i in 0...chars.length)
		{
			if (chars[i] != null)
				chars[i].dance();
		}
	}

	override function update(elapsed:Float)
	{
		if (!focusPlayer && camFollow.x != dad.getMidpoint().x + 150 + dad.cameraPosition[0] + (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[0] : 0))
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);

			camFollow.x += dad.cameraPosition[0] + (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[0] : 0);
			camFollow.y += dad.cameraPosition[1] + (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[1] : 0);
		}

		if (focusPlayer && camFollow.x != boyfriend.getMidpoint().x - 100 - boyfriend.cameraPosition[0] - (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[0] : 0))
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[0] : 0);
			camFollow.y += boyfriend.cameraPosition[1] + (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[1] : 0);
		}	

		Conductor.songPosition += FlxG.elapsed * 1000;

		if (FlxG.keys.justPressed.ESCAPE) {
			MusicBeatState.switchState(new PlayState());
			FlxG.mouse.visible = false;
			return;
		}
		
		if (FlxG.camera.zoom != Stage.camZoom)
			FlxG.camera.zoom = FlxMath.lerp(Stage.camZoom, FlxG.camera.zoom, 0.95);

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

		camMenu.zoom = FlxG.camera.zoom;
		
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
}
