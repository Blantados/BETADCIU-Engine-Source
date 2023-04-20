package editors;

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
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import Character;
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

import ModchartState;

using StringTools;

class ModpackMaker extends MusicBeatState {
	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	public var camFollow:FlxObject;

	var UI_box:FlxUITabMenu;

	public function new()
	{
		super();
	}

	//LET'S FUCKING GO!!! I CAN NOW CREATE MODPACKS WITH THE CLICK OF A BUTTON!!!

	override function create()
	{	
		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		add(luaDebugGroup);
		luaDebugGroup.cameras = [camMenu];

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		var titleText:FlxText = new FlxText(50, 50, 0, 48);
		titleText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER);
		titleText.text = "MODPACK MAKER!!!";
		titleText.borderColor = FlxColor.BLACK;
		titleText.borderSize = 3;
		titleText.cameras = [camMenu];
		titleText.borderStyle = FlxTextBorderStyle.OUTLINE;
		add(titleText);

		var descText:FlxText = new FlxText(50, 600, 1180, "A helpful tool that allows you to make Modpacks from Master Folders.", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		descText.screenCenter();
		descText.y += 270;
		add(descText);
		
		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.camera.follow(camFollow);

		var tabs = [
			{name: 'Setup', label: 'Setup'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(350, 350);
		UI_box.x = FlxG.width - 360;
		UI_box.y = 25;
		UI_box.scrollFactor.set(1, 1);
		add(UI_box);

		addSetupUI();
		UI_box.selected_tab_id = 'Setup';

		FlxG.mouse.visible = true;
		reloadSetupOptions();

		inModpackMaker = true;

		super.create();
	}
	
	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

	var directoryDropDown:FlxUIDropDownMenuCustom;
	var songDirectoryDropDown:FlxUIDropDownMenuCustom;

	var swagDirectory:String;
	var swagSongDirectory:String;

	function addSetupUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Setup";

		directoryDropDown = new FlxUIDropDownMenuCustom(15, 45, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String) {
			swagDirectory = directoryDropDown.selectedLabel;
			reloadDirectoryDropDown("data");
		});
		blockPressWhileScrolling.push(directoryDropDown);

		songDirectoryDropDown = new FlxUIDropDownMenuCustom(directoryDropDown.x + 170, 45, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String) {
			swagSongDirectory = songDirectoryDropDown.selectedLabel;
		});
		blockPressWhileScrolling.push(directoryDropDown);

		var addUpdateButton:FlxButton = new FlxButton(directoryDropDown.x, 275, "Create Modpack", function() {
			copyAndWriteFiles();
		});

		addUpdateButton.setGraphicSize(80, 30);
		addUpdateButton.updateHitbox();

		tab_group.add(new FlxText(directoryDropDown.x, directoryDropDown.y - 18, 0, 'Mod Directory:'));
		tab_group.add(new FlxText(songDirectoryDropDown.x, songDirectoryDropDown.y - 18, 0, 'Song Directory:'));

		var swagArray:Array<Dynamic> = [directoryDropDown, songDirectoryDropDown, addUpdateButton];
	
		for (i in 0...swagArray.length){
			tab_group.add(swagArray[i]);
		}			

		UI_box.addGroup(tab_group);
	}

	var swagSuf:String = "";
	public static var luaImageList:Array<String> = [];
	public static var luaSoundList:Array<String> = [];
	public static var luaFontList:Array<String> = [];

	function copyAndWriteFiles()
	{
		//just copy everything here. it's not like these take up a lot of space anyway.
		for (dataType in ["shaders", "custom_events", "custom_notetypes"])
		{
			var folder:String = Paths.modFolders(swagDirectory+"/"+dataType+"/");
			var modpackFolder:String = Paths.modFolders("Da Modpack"+"/"+dataType+"/");

			if (!FileSystem.exists(modpackFolder)){
				FileSystem.createDirectory(modpackFolder);
			}

			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					var initPath:String = folder + file;
					var modifiedPath:String = modpackFolder + file;

					sys.io.File.copy(initPath, modifiedPath);
				}
			}
		}

		for (dataType in ["data", "songs"]) {
			var folder:String = Paths.modFolders(swagDirectory+"/"+dataType+"/"+swagSongDirectory+"/");
			var modpackFolder:String = Paths.modFolders("Da Modpack"+"/"+dataType+"/"+swagSongDirectory+"/");
			
			if (!FileSystem.exists(modpackFolder)){
				FileSystem.createDirectory(modpackFolder);
			}

			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					var initPath:String = folder + file;
					var modifiedPath:String = modpackFolder + file;
					
					if(file.endsWith('.lua'))
					{
						// i'll do some reading shit with this later. for now leave it blank
						var openLua:ModchartState = new ModchartState(initPath, true);
						openLua.call("onCreate", []);
					}

					if (dataType == "data")
					{
						if (file.endsWith(".json") && file.startsWith(swagSongDirectory)){							
							var path:String = initPath;			
							var rawJson:Dynamic;

							rawJson = (FileSystem.exists(path) ?  File.getContent(path).trim() : Assets.getText(path).trim());

							var json:Song.SwagSong = cast Json.parse(rawJson).song;

							if (json.noteStyle != null && json.noteStyle.length > 0){
								var noteFolder:String = Paths.modFolders(swagDirectory+"/images/notes/");
								var noteModpackFolder:String = Paths.modFolders("Da Modpack/images/notes/");

								if (!FileSystem.exists(noteModpackFolder)){
									FileSystem.createDirectory(noteModpackFolder);
								}

								for (file in FileSystem.readDirectory(noteFolder))
								{
									var daInitPath:String = noteFolder + file;
									var daModifiedPath:String = noteModpackFolder + file;

									if (file == json.noteStyle+".png" || file == json.noteStyle+".xml" || file == json.noteStyle+"ENDS.png" || file == "noteSplashes-"+json.noteStyle+".png" || file == "noteSplashes-"+json.noteStyle+".xml"){
										sys.io.File.copy(daInitPath, daModifiedPath);
									}	
								}
							}
						}
						if (file == 'arrowSwitches.txt')
						{
							var stuff:Array<String> = CoolUtil.coolTextFile2(initPath);
							var noteFolder:String = Paths.modFolders(swagDirectory+"/images/notes/");
							var noteModpackFolder:String = Paths.modFolders("Da Modpack/images/notes/");

							if (!FileSystem.exists(noteModpackFolder)){
								FileSystem.createDirectory(noteModpackFolder);
							}

							if (stuff != [])
							{
								for (i in 0...stuff.length)
								{
									var data:Array<String> = stuff[i].split(' ');
				
									for (file in FileSystem.readDirectory(noteFolder))
									{
										var daInitPath:String = noteFolder + file;
										var daModifiedPath:String = noteModpackFolder + file;

										if (file == data[1]+".png" || file == data[1]+".xml" || file == data[1]+"ENDS.png" || file == "noteSplashes-"+data[1]+".png" || file == "noteSplashes-"+data[1]+".xml"){
											sys.io.File.copy(daInitPath, daModifiedPath);
										}	
									}
								}
							}
						}

						if (file == "preload"+swagSuf+".txt")
						{
							var characters:Array<String> = CoolUtil.coolTextFile2(initPath);
							var charFolder:String = Paths.modFolders(swagDirectory+"/characters/");
							var charModpackFolder:String = Paths.modFolders("Da Modpack/characters/");

							if (!FileSystem.exists(charModpackFolder)){
								FileSystem.createDirectory(charModpackFolder);
							}
	
							for (i in 0...characters.length)
							{
								var data:Array<String> = characters[i].split(' ');
								
								for (file in FileSystem.readDirectory(charFolder))
								{
									var charInitPath:String = charFolder + file;
									var charModifiedPath:String = charModpackFolder + file;

									if (file == characters[i]+".json" || file == characters[i]+".lua"){
										if (file == characters[i]+".json")
										{
											var path:String = charInitPath;
											
											var rawJson:Dynamic;

											rawJson = (FileSystem.exists(path) ?  File.getContent(path) : Assets.getText(path));
		
											var json:Character.CharacterFile = cast Json.parse(rawJson);

											var imagePath:String = json.image;
											var iconPath:String = "icons/icon-"+json.healthicon;

											if (json.gameover_character != null){
												
											}

											for (swagFolder in ["characters", "icons"])
											{
												var daFolder:String = Paths.modFolders(swagDirectory+"/images/");
												var daModpackFolder:String = Paths.modFolders("Da Modpack/images/");

												var killMe:Array<String> = imagePath.split('/');

												if (swagFolder == "icons"){
													killMe = iconPath.split('/');
												}

												if (killMe.length > 0){
													for (i in 0...killMe.length-1) {
														daFolder +=  killMe[i] + "/";
														daModpackFolder +=  killMe[i] + "/";
													}
												}

												if (!FileSystem.exists(daModpackFolder)){
													FileSystem.createDirectory(daModpackFolder);
												}

												for (file in FileSystem.readDirectory(daFolder))
												{
													var daInitPath:String = daFolder + file;
													var daModifiedPath:String = daModpackFolder + file;

													if (file == killMe[killMe.length-1]+".png" || file == killMe[killMe.length-1]+".xml"){
														sys.io.File.copy(daInitPath, daModifiedPath);
													}	
												}
											}
										}

										if (file == characters[i]+".lua")
										{
											var openLua:ModchartState = new ModchartState(charInitPath, true);
											openLua.call("onCreate", []);
										}

										sys.io.File.copy(charInitPath, charModifiedPath);
									}
								}
							}
						}

						if (file == "preload-stage"+swagSuf+".txt")
						{
							var stages:Array<String> = CoolUtil.coolTextFile2(initPath);
							var stageFolder:String = Paths.modFolders(swagDirectory+"/stages/");
							var stageModpackFolder:String = Paths.modFolders("Da Modpack/stages/");

							if (!FileSystem.exists(stageModpackFolder)){
								FileSystem.createDirectory(stageModpackFolder);
							}
	
							for (i in 0...stages.length)
							{								
								for (file in FileSystem.readDirectory(stageFolder))
								{
									var stageInitPath:String = stageFolder + file;
									var stageModifiedPath:String = stageModpackFolder + file;

									if (file == stages[i]+".json" || file == stages[i]+".lua"){
										if(file.endsWith('.json'))
										{
											var rawJson:Dynamic;

											rawJson = (FileSystem.exists(stageInitPath) ?  File.getContent(stageInitPath) : Assets.getText(stageInitPath));

											var stageData:StageData.StageFile = cast Json.parse(rawJson);
											
											if (stageData.ratingSkin != null)
											{
												var killMe:Array<String> = stageData.ratingSkin[0].split('/');

												var ratingFolder:String = Paths.modFolders(swagDirectory+"/images/");
												var ratingModpackFolder:String = Paths.modFolders("Da Modpack/images/");

												if (killMe.length > 0){
													for (i in 0...killMe.length-1) {
														ratingFolder +=  killMe[i] + "/";
														ratingModpackFolder +=  killMe[i] + "/";
													}
												}

												if (FileSystem.exists(ratingFolder))
												{
													if (!FileSystem.exists(ratingModpackFolder)){
														FileSystem.createDirectory(ratingModpackFolder);
													}
	
													for (file in FileSystem.readDirectory(ratingFolder))
													{
														var ratingInitPath:String = ratingFolder + file;
														var ratingModifiedPath:String = ratingModpackFolder + file;
	
														if (!FileSystem.isDirectory(ratingInitPath) && (file.endsWith(stageData.ratingSkin[1]+".png") || file.endsWith(stageData.ratingSkin[1]+".xml"))){
															sys.io.File.copy(ratingInitPath, ratingModifiedPath);
														}
													}
												}
											}
											
											if (stageData.countdownAssets != null){
												
												for (daImage in stageData.countdownAssets)
												{
													var killMe:Array<String> = daImage.split('/');

													var daFolder:String = Paths.modFolders(swagDirectory+"/images/");
													var daModpackFolder:String = Paths.modFolders("Da Modpack/images/");
	
													if (killMe.length > 0){
														for (i in 0...killMe.length-1) {
															daFolder +=  killMe[i] + "/";
															daModpackFolder +=  killMe[i] + "/";
														}
													}
	
													if (FileSystem.exists(daFolder))
													{
														if (!FileSystem.exists(daModpackFolder)){
															FileSystem.createDirectory(daModpackFolder);
														}
		
														for (file in FileSystem.readDirectory(daFolder))
														{
															var daInitPath:String = daFolder + file;
															var daModifiedPath:String = daModpackFolder + file;
		
															if (file == killMe[killMe.length-1]+".png" || file == killMe[killMe.length-1]+".xml"){
																sys.io.File.copy(daInitPath, daModifiedPath);
															}	
														}
													}
												}
											}
										}
										if(file.endsWith('.lua'))
										{
											var openLua:ModchartState = new ModchartState(stageInitPath, true, false);
											openLua.call("onCreate", []);
										}

										sys.io.File.copy(stageInitPath, stageModifiedPath);
									}
								}
							}
						}
					}
					
					sys.io.File.copy(initPath, modifiedPath);
				}
			}

			if (luaImageList != null)
			{
				for (image in luaImageList)
				{
					var killMe:Array<String> = image.split('/');

					var daFolder:String = Paths.modFolders(swagDirectory+"/images/");
					var daModpackFolder:String = Paths.modFolders("Da Modpack/images/");

					if (killMe.length > 0){
						for (i in 0...killMe.length-1) {
							daFolder +=  killMe[i] + "/";
							daModpackFolder +=  killMe[i] + "/";
						}
					}

					if (!FileSystem.exists(daModpackFolder)){
						FileSystem.createDirectory(daModpackFolder);
					}

					for (file in FileSystem.readDirectory(daFolder))
					{
						var daInitPath:String = daFolder + file;
						var daModifiedPath:String = daModpackFolder + file;

						if (file == killMe[killMe.length-1]+".png" || file == killMe[killMe.length-1]+".xml"){
							sys.io.File.copy(daInitPath, daModifiedPath);
						}	
					}
				}

				luaImageList = [];	
			}

			if (luaFontList != null)
			{
				for (font in luaFontList)
				{
					var killMe:Array<String> = font.split('/');

					var daFolder:String = Paths.modFolders(swagDirectory+"/fonts/");
					var daModpackFolder:String = Paths.modFolders("Da Modpack/fonts/");

					if (killMe.length > 0){
						for (i in 0...killMe.length-1) {
							daFolder +=  killMe[i] + "/";
							daModpackFolder +=  killMe[i] + "/";
						}
					}

					if (!FileSystem.exists(daModpackFolder)){
						FileSystem.createDirectory(daModpackFolder);
					}

					for (file in FileSystem.readDirectory(daFolder))
					{
						var daInitPath:String = daFolder + file;
						var daModifiedPath:String = daModpackFolder + file;

						if (file == killMe[killMe.length-1] || file == killMe[killMe.length-1]){
							sys.io.File.copy(daInitPath, daModifiedPath);
						}	
					}
				}

				luaFontList = [];	
			}

			if (luaSoundList != null)
			{
				for (sound in luaSoundList)
				{
					var killMe:Array<String> = sound.split('/');

					var daFolder:String = Paths.modFolders(swagDirectory+"/sounds/");
					var daModpackFolder:String = Paths.modFolders("Da Modpack/sounds/");

					if (killMe.length > 0){
						for (i in 0...killMe.length-1) {
							daFolder +=  killMe[i] + "/";
							daModpackFolder +=  killMe[i] + "/";
						}
					}

					if (!FileSystem.exists(daModpackFolder)){
						FileSystem.createDirectory(daModpackFolder);
					}

					for (file in FileSystem.readDirectory(daFolder))
					{
						var daInitPath:String = daFolder + file;
						var daModifiedPath:String = daModpackFolder + file;

						if (file == killMe[killMe.length-1]+".ogg" || file == killMe[killMe.length-1]+".mp3"){
							sys.io.File.copy(daInitPath, daModifiedPath);
						}	
					}
				}

				luaSoundList = [];	
			}
		}
	}

	public static var inModpackMaker:Bool = false;
	
	override function update(elapsed:Float)
	{
		var blockInput:Bool = false;

		if(!blockInput) {
			if (FlxG.keys.justPressed.ESCAPE) {
				MusicBeatState.switchState(new options.OptionsState());
				FlxG.mouse.visible = false;
				inModpackMaker = false;
				return;
			}
		}

		super.update(elapsed);
	}

	function reloadDirectoryDropDown(type:String) {
		switch (type.toLowerCase())
		{
			case "data":
				var directories:Array<String> = [];
				var modsFolder:String = Paths.modFolders(swagDirectory+"/data/");
				if(FileSystem.exists(modsFolder)) {
					for (folder in FileSystem.readDirectory(modsFolder)) {
						var path = haxe.io.Path.join([modsFolder, folder]);
						if (sys.FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(folder) && !directories.contains(folder)) {
							directories.push(folder);
						}
					}
				}

				if(directories.length < 1){
					directories.push('NO DIRECTORIES'); //Prevents crash
				}

				songDirectoryDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(directories, true));
			default:
			{
				var directories:Array<String> = Paths.getModDirectories();
		
				if(directories.length < 1){
					directories.push('NO DIRECTORIES'); //Prevents crash
				}

				directoryDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(directories, true));
			}
		}
		
	}

	function reloadSetupOptions() {
		if(UI_box != null) {
			reloadDirectoryDropDown("");
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
}