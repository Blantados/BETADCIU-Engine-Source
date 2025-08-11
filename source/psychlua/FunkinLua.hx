#if LUA_ALLOWED
package psychlua;

import backend.StageData;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import openfl.Lib;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.math.FlxRect;

import flixel.addons.display.FlxBackdrop;
#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

import cutscenes.DialogueBoxPsych;

import objects.StrumNote;
import objects.Note;
import objects.NoteSplash;
import objects.Character;
import objects.HealthIcon;
import objects.PsychVideoSprite;

import states.MainMenuState;
import states.StoryMenuState;
import states.FreeplayState;

import substates.PauseSubState;
import substates.GameOverSubstate;

import psychlua.LuaUtils;
#if HSCRIPT_ALLOWED
import psychlua.HScript;
#end
import psychlua.DebugLuaText;
import psychlua.ModchartSprite;

import shaders.*; // prob moving the ColorSwap functions to the ShaderFunctions.hx file later

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import haxe.Json;

import funkin.vis.dsp.SpectralAnalyzer;
import funkin.vis.audioclip.frontends.LimeAudioClip;

import options.ModpackMakerState;
import options.ModpackMakerState.ModpackAssetRegistry;

class FunkinLua {
	public var lua:State = null;
	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	public var scriptType:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;

	#if HSCRIPT_ALLOWED
	public var hscript:HScript = null;
	#end

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var audioAnalyzer:SpectralAnalyzer;

	public function new(scriptName:String, ?scriptType:String = "") {
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		//trace('Lua version: ' + Lua.version());
		//trace("LuaJIT version: " + Lua.versionJIT());

		//LuaL.dostring(lua, CLENSE);

		this.scriptName = scriptName.trim();
		this.scriptType = scriptType.trim();

		var game:PlayState = PlayState.instance;
		if(game != null) game.luaArray.push(this);

		var myFolder:Array<String> = this.scriptName.split('/');
		#if MODS_ALLOWED
		if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
			this.modFolder = myFolder[1];
		#end

		// Lua shit
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('version', MainMenuState.psychEngineVersion.trim());
		set('modFolder', this.modFolder);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		

		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
	
	
		set('loadedSongName', Song.loadedSongName);
		set('loadedSongPath', Paths.formatToSongPath(Song.loadedSongName));
		set('chartPath', Song.chartPath);
		set('startedCountdown', false);
	

		set('isStoryMode', PlayState.isStoryMode);
		set('isBETADCIU', PlayState.isBETADCIU);
		set('isBonus', PlayState.isBonus);

		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString(false));
		set('difficultyPath', Difficulty.getFilePath());
		set('difficultyNameTranslation', Difficulty.getString(true));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);


		// Song stuff
		if (PlayState.SONG != null){
			set('bpm', PlayState.SONG.bpm); // kade scripts.
			set('scrollSpeed', PlayState.SONG.speed);
			set('songName', PlayState.SONG.song);
			set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
			set('curStage', PlayState.SONG.stage);
			set('hasVocals', PlayState.SONG.needsVoices);
		}else{
			// Fallbacks in case SONG is null
			set('bpm', 100); // or your default
			set('scrollSpeed', 1.0);
			set('curStage', "stage");
			set('hasVocals', false);
			set('songName', (scriptType == "modpack" ? ModpackMakerState.selectedSongName : ""));
			set('songPath', (scriptType == "modpack" ? Paths.formatToSongPath(ModpackMakerState.selectedSongName) : ""));
		}

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);


		// PlayState-only variables
		if(game != null)
		@:privateAccess
		{
			if (PlayState.SONG != null){
				var curSection:SwagSection = PlayState.SONG.notes[game.curSection];

				set('curSection', game.curSection);
				set('mustHitSection', curSection != null ? (curSection.mustHitSection == true) : false);
				set('altAnim', curSection != null ? (curSection.altAnim == true) : false);
				set('gfSection', curSection != null ? (curSection.gfSection == true) : false);

				set('boyfriendName', game.boyfriend != null ? game.boyfriend.curCharacter : PlayState.SONG.player1);
				set('dadName', game.dad != null ? game.dad.curCharacter : PlayState.SONG.player2);
				set('gfName', game.gf != null ? game.gf.curCharacter : PlayState.SONG.gfVersion);
			}

		
			set("songPos", 0); // kade scrips part 2
			set('curBeat', game.curBeat);
			set('curStep', game.curStep);
			set('curDecBeat', game.curDecBeat);
			set('curDecStep', game.curDecStep);
	
			set('score', game.songScore);
			set('misses', game.songMisses);
			set('hits', game.songHits);
			set('combo', game.combo);
			set('deaths', PlayState.deathCounter);
	
			set('rating', game.ratingPercent);
			set('ratingName', game.ratingName);
			set('ratingFC', game.ratingFC);
			set('totalPlayed', game.totalPlayed);
			set('totalNotesHit', game.totalNotesHit);

			set('inGameOver', GameOverSubstate.instance != null);
			
			set('healthGainMult', game.healthGain);
			set('healthLossMult', game.healthLoss);
	
			#if FLX_PITCH
			set('playbackRate', game.playbackRate);
			#else
			set('playbackRate', 1);
			#end
	
			set('guitarHeroSustains', game.guitarHeroSustains);
			set('instakillOnMiss', game.instakillOnMiss);
			set('botPlay', game.cpuControlled);
			set('practice', game.practiceMode);
	
			for (i in 0...4) {
				set('defaultPlayerStrumX' + i, 0);
				set('defaultPlayerStrumY' + i, 0);
				set('defaultOpponentStrumX' + i, 0);
				set('defaultOpponentStrumY' + i, 0);
			}
	
			// Default character data
			set('defaultBoyfriendX', game.BF_X);
			set('defaultBoyfriendY', game.BF_Y);
			set('defaultOpponentX', game.DAD_X);
			set('defaultOpponentY', game.DAD_Y);
			set('defaultGirlfriendX', game.GF_X);
			set('defaultGirlfriendY', game.GF_Y);
		}

		// Other settings
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		// Noteskin/Splash
		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		// build target (windows, mac, linux, etc.)
		set('buildTarget', LuaUtils.getBuildTarget());

		//
		Lua_helper.add_callback(lua, "getRunningScripts", function() {
			var runningScripts:Array<String> = [];
			
			if (game != null){
				for (script in game.luaArray)
					runningScripts.push(script.scriptName);	
			}
			
			return runningScripts;
		});

		Lua_helper.add_callback(lua, "getRunningHScripts", function(){
			var runningScripts:Array<String> = [];

			if (game != null){
				for (script in game.hscriptArray)
					runningScripts.push(script.scriptName);
			}

			return runningScripts;
		});

		//stole from Wii Funkin' Matt V3
		Lua_helper.add_callback(lua, "initAnalyzer", function(barCount:Int, maxDelta:Float = 0.01, peakHold:Int = 30) {
			initAnalyzer(barCount, maxDelta, peakHold);
			return true;
		});

		Lua_helper.add_callback(lua, "getAudioLevels", function(barCount:Int, maxDelta:Float = 0.01, peakHold:Int = 30) {
			return getAudioLevels();
		});

		addLocalCallback("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (game != null){
				if(exclusions == null) exclusions = [];
				if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
				game.setOnScripts(varName, arg, exclusions);
			}
		});
		addLocalCallback("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (game != null){
				if(exclusions == null) exclusions = [];
				if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
				game.setOnHScript(varName, arg, exclusions);
			}
		});
		addLocalCallback("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (game != null){
				if(exclusions == null) exclusions = [];
				if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
				game.setOnLuas(varName, arg, exclusions);
			}
		});

		addLocalCallback("callOnScripts", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if (game != null){
				if(excludeScripts == null) excludeScripts = [];
				if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
				return game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
			}

			return null;
		});
		addLocalCallback("callOnLuas", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if (game != null){
				if(excludeScripts == null) excludeScripts = [];
				if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
				return game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
			}

			return null;
		});
		addLocalCallback("callOnHScript", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
			if (game != null){
				if(excludeScripts == null) excludeScripts = [];
				if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
				return game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
			}
			return null;
		});

		Lua_helper.add_callback(lua, "callScript", function(luaFile:String, funcName:String, ?args:Array<Dynamic> = null) {
			if(args == null){
				args = [];
			}

			var luaPath:String = findScript(luaFile);
			if(luaPath != null)
				for (luaInstance in game.luaArray)
					if(luaInstance.scriptName == luaPath)
						return luaInstance.call(funcName, args);

			return null;
		});
		Lua_helper.add_callback(lua, "getGlobalFromScript", function(?luaFile:String, ?global:String){ // returns the global from a script
			if(luaFile==null){
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'getGlobalFromScript' (string expected, got nil)");
				#end
				return null;
			}
			if(global==null){
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #2 to 'getGlobalFromScript' (string expected, got nil)");
				#end
				return null;
			}
			var cervix = luaFile + ".lua";
			if(luaFile.endsWith(".lua"))cervix=luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if(FileSystem.exists(Paths.mods(cervix)))
			{
				cervix = Paths.mods(cervix);
				doPush = true;
			}
			else if(FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else {
				cervix = Paths.getSharedPath(cervix);
				if(FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else

			
			cervix = Paths.getSharedPath(cervix);
			if(Assets.exists(cervix)) {
				doPush = true;
			}
			#end
			if(doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if(luaInstance.scriptName == cervix)
					{
						Lua.getglobal(luaInstance.lua, global);

						var ret = Convert.fromLua(luaInstance.lua, -1);
						Lua.pop(luaInstance.lua,1); // remove the global

						return ret;
					}

				}
			}
			return null;
		});
		Lua_helper.add_callback(lua, "setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic){ // set a global from a script
			var cervix = luaFile + ".lua";
			if(luaFile.endsWith(".lua"))cervix=luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if(FileSystem.exists(Paths.mods(cervix)))
			{
				cervix = Paths.mods(cervix);
				doPush = true;
			}
			else if(FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else {
				cervix = Paths.getSharedPath(cervix);
				if(FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getSharedPath(cervix);
			if(Assets.exists(cervix)) {
				doPush = true;
			}
			#end
			if(doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if(luaInstance.scriptName == cervix)
					{
						luaInstance.set(global, val);
					}

				}
			}
			return null;
		});
		Lua_helper.add_callback(lua, "isRunning", function(scriptFile:String) {
			var luaPath:String = findScript(scriptFile);
			if(luaPath != null)
			{
				for (luaInstance in game.luaArray)
					if(luaInstance.scriptName == luaPath)
						return true;
			}

			#if HSCRIPT_ALLOWED
			var hscriptPath:String = findScript(scriptFile, '.hx');
			if(hscriptPath != null)
			{
				for (hscriptInstance in game.hscriptArray)
					if(hscriptInstance.origin == hscriptPath)
						return true;
			}
			#end
			return false;
		});
		Lua_helper.add_callback(lua,"doFunction", doFunction);
		Lua_helper.add_callback(lua, "setVar", function(varName:String, value:Dynamic) {
			MusicBeatState.getVariables().set(varName, ReflectionFunctions.parseSingleInstance(value));
			return value;
		});
		Lua_helper.add_callback(lua, "changeStageData", function(id:String) {
            PlayState.instance.curStage = id;
            PlayState.instance.stageData = StageData.getStageFile(PlayState.instance.curStage); 
            PlayState.instance.setStageDetails(PlayState.instance.stageData);
        });
		Lua_helper.add_callback(lua, "getVar", function(varName:String) {
			return MusicBeatState.getVariables().get(varName);
		});

		Lua_helper.add_callback(lua, "addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false, ?type:String = "") {
			var cervix = luaFile + ".lua";
			if(luaFile.endsWith(".lua"))cervix=luaFile;

			if (scriptType == "modpack"){
				ModpackAssetRegistry.instance.addAsset("", cervix);
				return;
			}

			var luaPath:String = findScript(luaFile);
			if (type == "modpack") type = ""; // just preventing some weird stuff

			if(luaPath != null)
			{
				if(!ignoreAlreadyRunning)
					for (luaInstance in game.luaArray)
						if(luaInstance.scriptName == luaPath)
						{
							luaTrace('addLuaScript: The script "' + luaPath + '" is already running!');
							return;
						}

				new FunkinLua(luaPath, type);
				if (type == "stage") {
					game.addedStages.push(cervix);
					// trace('pushing $cervix');
				}
				// if (type != "") trace('Script added as: $type');
				return;
			}
			luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "addHScript", function(scriptFile:String, ?ignoreAlreadyRunning:Bool = false) {
			#if HSCRIPT_ALLOWED
			if (scriptType == "modpack"){
				ModpackAssetRegistry.instance.addAsset("", scriptFile);
				return;
			}

			var scriptPath:String = findScript(scriptFile, '.hx');
			if(scriptPath != null)
			{
				if(!ignoreAlreadyRunning)
					for (script in game.hscriptArray)
						if(script.origin == scriptPath)
						{
							luaTrace('addHScript: The script "' + scriptPath + '" is already running!');
							return;
						}

				PlayState.instance.initHScript(scriptPath);
				return;
			}
			luaTrace("addHScript: Script doesn't exist!", false, false, FlxColor.RED);
			#else
			luaTrace("addHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		Lua_helper.add_callback(lua, "removeLuaScript", function(luaFile:String) {
			var luaPath:String = findScript(luaFile);
			if(luaPath != null)
			{
				var foundAny:Bool = false;
				for (luaInstance in game.luaArray)
				{
					if(luaInstance.scriptName == luaPath)
					{
						trace('Closing lua script $luaPath');
						luaInstance.stop();
						foundAny = true;
					}
				}
				if(foundAny) return true;
			}

			luaTrace('removeLuaScript: Script $luaFile isn\'t running!', false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "removeHScript", function(scriptFile:String) {
			#if HSCRIPT_ALLOWED
			var scriptPath:String = findScript(scriptFile, '.hx');
			if(scriptPath != null)
			{
				var foundAny:Bool = false;
				for (script in game.hscriptArray)
				{
					if(script.origin == scriptPath)
					{
						trace('Closing hscript $scriptPath');
						script.destroy();
						foundAny = true;
					}
				}
				if(foundAny) return true;
			}

			luaTrace('removeHScript: Script $scriptFile isn\'t running!', false, false, FlxColor.RED);
			return false;
			#else
			luaTrace("removeHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "loadSong", function(?name:String = null, ?difficultyNum:Int = -1) {
			if(name == null || name.length < 1)
				name = Song.loadedSongName;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			FlxG.state.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(game != null && game.vocals != null)
			{
				game.vocals.pause();
				game.vocals.volume = 0;
			}
			FlxG.camera.followLerp = 0;
		});

		Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			if (scriptType.toLowerCase() == "modpack" && image != null && image.length > 0){
				ModpackAssetRegistry.instance.addAsset("images", image);
				return;
			}
			
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			var animated = gridX != 0 || gridY != 0;

			if(split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			}
		});
		Lua_helper.add_callback(lua, "loadFrames", function(variable:String, image:String, spriteType:String = 'auto') {
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null && image != null && image.length > 0)
			{
				LuaUtils.loadFrames(spr, image, spriteType);
			}
		});
		Lua_helper.add_callback(lua, "loadMultipleFrames", function(variable:String, images:Array<String>) {
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null && images != null && images.length > 0)
			{
				spr.frames = Paths.getMultiAtlas(images);
			}
		});
		Lua_helper.add_callback(lua, "animExists", function(tag:String, anim:String){
			var shit:Dynamic = LuaUtils.getObjectDirectly(tag);
			
			return shit.animation.getByName(anim) != null;
		});
		//shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String, ?group:String = null) {
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(obj);
			if(leObj != null)
			{
				if(group != null)
				{
					var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
					if(groupOrArray != null)
					{
						switch(Type.typeof(groupOrArray))
						{
							case TClass(Array): //Is Array
								return groupOrArray.indexOf(leObj);
							default: //Is Group
								return Reflect.getProperty(groupOrArray, 'members').indexOf(leObj); //Has to use a Reflect here because of FlxTypedSpriteGroup
						}
					}
					else
					{
						luaTrace('getObjectOrder: Group $group doesn\'t exist!', false, false, FlxColor.RED);
						return -1;
					}
				}
				var groupOrArray:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
				return groupOrArray.members.indexOf(leObj);
			}
			luaTrace('getObjectOrder: Object $obj doesn\'t exist!', false, false, FlxColor.RED);
			return -1;
		});
		Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int, ?group:String = null) {
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(obj);
			if(leObj != null)
			{
				if(group != null)
				{
					var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
					if(groupOrArray != null)
					{
						switch(Type.typeof(groupOrArray))
						{
							case TClass(Array): //Is Array
								groupOrArray.remove(leObj);
								groupOrArray.insert(position, leObj);
							default: //Is Group
								groupOrArray.remove(leObj, true);
								groupOrArray.insert(position, leObj);
						}
					}
					else luaTrace('setObjectOrder: Group $group doesn\'t exist!', false, false, FlxColor.RED);
				}
				else
				{
					var groupOrArray:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
					groupOrArray.remove(leObj, true);
					groupOrArray.insert(position, leObj);
				}
				return;
			}
			luaTrace('setObjectOrder: Object $obj doesn\'t exist!', false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "mouseClicked", function(?button:String = 'left') {
			var click:Bool = FlxG.mouse.justPressed;
			switch(button.trim().toLowerCase())
			{
				case 'middle':
					click = FlxG.mouse.justPressedMiddle;
				case 'right':
					click = FlxG.mouse.justPressedRight;
			}
			return click;
		});
		Lua_helper.add_callback(lua, "mousePressed", function(?button:String = 'left') {
			var press:Bool = FlxG.mouse.pressed;
			switch(button.trim().toLowerCase())
			{
				case 'middle':
					press = FlxG.mouse.pressedMiddle;
				case 'right':
					press = FlxG.mouse.pressedRight;
			}
			return press;
		});
		Lua_helper.add_callback(lua, "mouseReleased", function(?button:String = 'left') {
			var released:Bool = FlxG.mouse.justReleased;
			switch(button.trim().toLowerCase())
			{
				case 'middle':
					released = FlxG.mouse.justReleasedMiddle;
				case 'right':
					released = FlxG.mouse.justReleasedRight;
			}
			return released;
		});

		Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			LuaUtils.cancelTimer(tag);
			var variables = MusicBeatState.getVariables();
			
			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('timer_$tag');
			variables.set(tag, new FlxTimer().start(time / (game != null ? game.playbackRate : 1), function(tmr:FlxTimer)
			{
				if(tmr.finished) variables.remove(tag);

				if (game != null){
					game.callOnLuas('onTimerCompleted', [originalTag, tmr.loops, tmr.loopsLeft]);
				}
				//trace('Timer Completed: ' + tag);
			}, loops));
			return tag;
		});
		Lua_helper.add_callback(lua, "cancelTimer", function(tag:String) LuaUtils.cancelTimer(tag));

		//stupid bietch ass functions
		Lua_helper.add_callback(lua, "addScore", function(value:Int = 0) {
			game.songScore += value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addMisses", function(value:Int = 0) {
			game.songMisses += value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addHits", function(value:Int = 0) {
			game.songHits += value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setScore", function(value:Int = 0) {
			game.songScore = value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setMisses", function(value:Int = 0) {
			game.songMisses = value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setHits", function(value:Int = 0) {
			game.songHits = value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setHealth", function(value:Float = 1) game.health = value);
		Lua_helper.add_callback(lua, "addHealth", function(value:Float = 0) game.health += value);
		Lua_helper.add_callback(lua, "getHealth", function() return game.health);

		//Identical functions
		Lua_helper.add_callback(lua, "FlxColor", function(color:String) return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromName", function(color:String) return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromString", function(color:String) return FlxColor.fromString(color));

		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String) {
			// Legacy version included #, 0x, and 0xFF since Std.parseInt() was used instead.
			if (color.startsWith("0xFF")) {
				color = color.substr(4); // Remove "0xFF"
			}else{
				var regex = new EReg("^#|^0x", "");
				color = regex.replace(color, "");
			}
			
			return FlxColor.fromString('#$color');
		});

		// precaching
		Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			game.addCharacterToList(name, charType);
		});
		Lua_helper.add_callback(lua, "precacheImage", function(name:String, ?allowGPU:Bool = true) {
			if (scriptType.toLowerCase() == "modpack" && name != null && name.length > 0){
				ModpackAssetRegistry.instance.addAsset("images", name);
				return;
			}

			Paths.image(name, allowGPU);
		});
		Lua_helper.add_callback(lua, "precacheSound", function(name:String) {
			if (scriptType.toLowerCase() == "modpack" && name != null && name.length > 0){
				ModpackAssetRegistry.instance.addAsset("sounds", name);
				return;
			}

			Paths.sound(name);
		});
		Lua_helper.add_callback(lua, "precacheMusic", function(name:String) {
			Paths.music(name);
		});

		// others
		Lua_helper.add_callback(lua, "triggerEvent", function(name:String, ?value1:String = '', ?value2:String = '', ?value3:String = '') {
			if (scriptType == "modpack"){
				if (FileSystem.exists(Paths.modFolders('custom_events/$name.txt'))){
					ModpackAssetRegistry.instance.addAsset("", 'custom_events/$name.txt');
				}
				
				if (FileSystem.exists(Paths.modFolders('custom_events/$name.lua'))){
					ModpackAssetRegistry.instance.addAsset("", 'custom_events/$name.lua');
				}

				return true;
			}

			game.triggerEvent(name, value1, value2, value3, Conductor.songPosition);
			//trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2, ', ' + value3);
			return true;
		});

		Lua_helper.add_callback(lua, "startCountdown", function() {
			game.startCountdown();
			return true;
		});
		Lua_helper.add_callback(lua, "endSong", function() {
			game.KillNotes();
			game.endSong();
			return true;
		});
		Lua_helper.add_callback(lua, "restartSong", function(?skipTransition:Bool = false) {
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		Lua_helper.add_callback(lua, "exitSong", function(?skipTransition:Bool = false) {
			if(skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			if(PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else if (PlayState.isBETADCIU)
				MusicBeatState.switchState(new states.betadciu.BETADCIUState());
			else if (PlayState.isBonus)
				MusicBeatState.switchState(new states.betadciu.BonusSongsState());
			else
				MusicBeatState.switchState(new FreeplayState());

			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

			// FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTopMod();
			return true;
		});
		Lua_helper.add_callback(lua, "getSongPosition", function() {
			return Conductor.songPosition;
		});
		Lua_helper.add_callback(lua, "getCharacterImage", function(characterName:String, ?type:String="sprite") {
			var char = Character.getCharacterFile(characterName);
			var name:String = 'icons/' + char.healthicon;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char.healthicon; //Older versions of betadciu/psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon

			if (type.toLowerCase() == "sprite") return char.image;
			else if (type.toLowerCase() == "icon") return name;
			else {
				luaTrace('getCharacterImage: invalid type!', false, false, FlxColor.RED);
				return null;
			}
		});
		Lua_helper.add_callback(lua, "getCharacterX", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return game.dadGroup.x;
				case 'gf' | 'girlfriend':
					return game.gfGroup.x;
				default:
					return game.boyfriendGroup.x;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterX", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					game.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.x = value;
				default:
					game.boyfriendGroup.x = value;
			}
		});
		Lua_helper.add_callback(lua, "getCharacterY", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return game.dadGroup.y;
				case 'gf' | 'girlfriend':
					return game.gfGroup.y;
				default:
					return game.boyfriendGroup.y;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					game.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.y = value;
				default:
					game.boyfriendGroup.y = value;
			}
		});
		Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String) {
			switch(target.trim().toLowerCase())
			{
				case 'gf', 'girlfriend':
					game.moveCameraToGirlfriend();
				case 'dad', 'opponent':
					game.moveCamera(true);
				default:
					game.moveCamera(false);
			}
		});

		Lua_helper.add_callback(lua, "setCameraScroll", function(x:Float, y:Float) FlxG.camera.scroll.set(x - FlxG.width/2, y - FlxG.height/2));
		Lua_helper.add_callback(lua, "setCameraFollowPoint", function(x:Float, y:Float) game.camFollow.setPosition(x, y));
		Lua_helper.add_callback(lua, "addCameraScroll", function(?x:Float = 0, ?y:Float = 0) FlxG.camera.scroll.add(x, y));
		Lua_helper.add_callback(lua, "addCameraFollowPoint", function(?x:Float = 0, ?y:Float = 0) {
			game.camFollow.x += x;
			game.camFollow.y += y;
		});
		Lua_helper.add_callback(lua, "getCameraScrollX", () -> FlxG.camera.scroll.x + FlxG.width/2);
		Lua_helper.add_callback(lua, "getCameraScrollY", () -> FlxG.camera.scroll.y + FlxG.height/2);
		Lua_helper.add_callback(lua, "getCameraFollowX", () -> game.camFollow.x);
		Lua_helper.add_callback(lua, "getCameraFollowY", () -> game.camFollow.y);

		Lua_helper.add_callback(lua, "cameraShake", function(camera:String, intensity:Float, duration:Float) {
			if (game == null){
				duration = duration / game.playbackRate;	
			}
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});

		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float,forced:Bool) {
			if (game == null){
				duration = duration / game.playbackRate;	
			}

			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});
		Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float, forced:Bool, ?fadeOut:Bool = false) {
			if (game == null){
				duration = duration / game.playbackRate;	
			}
			
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, fadeOut, null, forced);
		});
		Lua_helper.add_callback(lua,"cameraSnap", function(camera:String, x:Float, y:Float) {
			PlayState.instance.isCameraOnForcedPos = true;
			
			var camPosition:FlxObject = new FlxObject(0, 0, 1, 1);
			camPosition.setPosition(x, y);
			LuaUtils.cameraFromString(camera).focusOn(camPosition.getPosition());
		});
		Lua_helper.add_callback(lua,"getMapLength", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var shit:Map<String, Dynamic> = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if(killMe.length > 1)
			{
				shit = Reflect.getProperty(Type.resolveClass(killMe[0]), killMe[1]);

				if (shit == null)
					shit = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
			}
	
			var daArray:Array<String> = [];

			for (key in shit.keys())
				daArray.push(key);
			
			return daArray.length;
		});
		Lua_helper.add_callback(lua,"getMapKeys", function(obj:String, ?getValue:Bool = false) {
			var killMe:Array<String> = obj.split('.');
			var shit:Map<String, Dynamic> = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if(killMe.length > 1)
			{
				shit = Reflect.getProperty(Type.resolveClass(killMe[0]), killMe[1]);

				if (shit == null)
					shit = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
			}

			var daArray:Array<String> = [];

			for (key in shit.keys())
				daArray.push(key);

			if (getValue)
			{
				for (i in 0...daArray.length)
					daArray[i] = shit.get(daArray[i]);
			}
			
			return daArray;
		});
		Lua_helper.add_callback(lua,"getMapKey", function(obj:String, valName:String) {
			var killMe:Array<String> = obj.split('.');
			var shit:Map<String, Dynamic> = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if(killMe.length > 1)
			{
				shit = Reflect.getProperty(Type.resolveClass(killMe[0]), killMe[1]);

				if (shit == null)
					shit = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
			}

			return shit[valName];
		});
		Lua_helper.add_callback(lua,"setMapKey", function(obj:String, valName:String, val:Dynamic) {
			var killMe:Array<String> = obj.split('.');
			var shit:Map<String, Dynamic> = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if(killMe.length > 1)
			{
				shit = Reflect.getProperty(Type.resolveClass(killMe[0]), killMe[1]);

				if (shit == null)
					shit = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
			}

			shit[valName] = val;
		});
		Lua_helper.add_callback(lua, "setRatingPercent", function(value:Float) {
			game.ratingPercent = value;
			game.setOnScripts('rating', game.ratingPercent);
		});
		Lua_helper.add_callback(lua, "setRatingName", function(value:String) {
			game.ratingName = value;
			game.setOnScripts('ratingName', game.ratingName);
		});
		Lua_helper.add_callback(lua, "setRatingFC", function(value:String) {
			game.ratingFC = value;
			game.setOnScripts('ratingFC', game.ratingFC);
		});
		Lua_helper.add_callback(lua, "updateScoreText", function() game.updateScoreText());
		Lua_helper.add_callback(lua, "getMouseX", function(?camera:String = 'game') {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		Lua_helper.add_callback(lua, "getMouseY", function(?camera:String = 'game') {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});

		Lua_helper.add_callback(lua, "getMidpointX", function(variable:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getMidpoint().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getMidpointY", function(variable:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getMidpoint().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "getGraphicMidpointX", function(variable:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getGraphicMidpoint().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getGraphicMidpointY", function(variable:String) {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getGraphicMidpoint().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "getScreenPositionX", function(variable:String, ?camera:String = 'game') {
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getScreenPositionY", function(variable:String, ?camera:String = 'game') {
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}
			if(obj != null) return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).y;

			return 0;
		});
		Lua_helper.add_callback(lua, "characterDance", function(character:String) {
			if (game != null){
				switch(character.toLowerCase()) {
					case 'dad': game.dad.dance();
					case 'gf' | 'girlfriend': if(game.gf != null) game.gf.dance();
					default: game.boyfriend.dance();
				}
			}
		});

		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
			if (scriptType.toLowerCase() == "modpack" && image != null && image.length > 0){
				ModpackAssetRegistry.instance.addAsset("images", image);
				return;
			}

			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}

			var variables = MusicBeatState.getVariables();
			variables.set(tag, leSprite);

			switch(scriptType.toLowerCase()){
				case "stage":
					if (!variables.exists("stageVariables")){
						variables.set("stageVariables", new Map<String, FlxSprite>());
					}
		
					var stageVars = variables.get("stageVariables");
					stageVars.set(tag, leSprite);
			}

			leSprite.active = true;
		});
		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = 'auto') {
			if (scriptType.toLowerCase() == "modpack" && image != null && image.length > 0){
				ModpackAssetRegistry.instance.addAsset("images", image);
				return;
			}
			
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			if(image != null && image.length > 0)
			{
				LuaUtils.loadFrames(leSprite, image, spriteType);
			}

			var variables = MusicBeatState.getVariables();
			variables.set(tag, leSprite);

			switch(scriptType.toLowerCase()){
				case "stage":
					if (!variables.exists("stageVariables")){
						variables.set("stageVariables", new Map<String, FlxSprite>());
					}
		
					var stageVars = variables.get("stageVariables");
					stageVars.set(tag, leSprite);
			}
		});
		Lua_helper.add_callback(lua, "makeLuaBackdrop", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?axes:String = "XY") {
			if (scriptType.toLowerCase() == "modpack" && image != null && image.length > 0){
				ModpackAssetRegistry.instance.addAsset("images", image);
				return;
			}
			
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:FlxBackdrop = new FlxBackdrop("", FlxAxes.fromString(axes), Std.int(x), Std.int(y));
			if(image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}

			var variables = MusicBeatState.getVariables();
			variables.set(tag, leSprite);

			switch(scriptType.toLowerCase()){
				case "stage":
					if (!variables.exists("stageVariables")){
						variables.set("stageVariables", new Map<String, FlxSprite>());
					}
		
					var stageVars = variables.get("stageVariables");
					stageVars.set(tag, leSprite);
			}

			leSprite.active = true;
		});
		Lua_helper.add_callback(lua, "makeAnimatedLuaBackdrop", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?axes:String = "XY", ?spriteType:String = 'auto') {
			if (scriptType.toLowerCase() == "modpack" && image != null && image.length > 0){
				ModpackAssetRegistry.instance.addAsset("images", image);
				return;
			}
			
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:FlxBackdrop = new FlxBackdrop("", FlxAxes.fromString(axes), Std.int(x), Std.int(y));
			if(image != null && image.length > 0)
			{
				LuaUtils.loadFrames(leSprite, image, spriteType);
			}

			var variables = MusicBeatState.getVariables();
			variables.set(tag, leSprite);

			switch(scriptType.toLowerCase()){
				case "stage":
					if (!variables.exists("stageVariables")){
						variables.set("stageVariables", new Map<String, FlxSprite>());
					}
		
					var stageVars = variables.get("stageVariables");
					stageVars.set(tag, leSprite);
			}

			leSprite.active = true;
		});
		Lua_helper.add_callback(lua, "makeVideoSprite", function(tag:String, videoFile:String, ?x:Float, ?y:Float, ?camera:String="camGame", ?shouldLoop:Bool=false, ?muted:Bool=true) {
			// I hate you FlxVideoSprite....
			#if VIDEOS_ALLOWED
			if (scriptType.toLowerCase() == "modpack"){
				ModpackAssetRegistry.instance.addAsset("videos", videoFile);
				return;
			}

			var variables = MusicBeatState.getVariables();
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leVSprite:PsychVideoSprite = null;
			if(FileSystem.exists(Paths.video(videoFile)) && videoFile != null && videoFile.length > 0) {

				leVSprite = new PsychVideoSprite();
				leVSprite.addCallback('onFormat',()->{
					leVSprite.setPosition(x,y);
					leVSprite.cameras = [LuaUtils.cameraFromString(camera)];
				});
				leVSprite.addCallback('onEnd',()->{
					if (variables.exists(tag)) {
						variables.get(tag).destroy();
						variables.remove(tag);
					}
						
					game.callOnLuas('onVideoFinished', [tag]);
				});
				var options:Array<String> = [];
				if (shouldLoop) options.push(PsychVideoSprite.looping);
				if (muted) options.push(PsychVideoSprite.muted);

				leVSprite.load(Paths.video(videoFile), options);
				leVSprite.antialiasing = true;
				leVSprite.play();

				variables.set(tag, leVSprite);
				
				switch(scriptType.toLowerCase()){
					case "stage":
						if (!variables.exists("stageVariables")){
							variables.set("stageVariables", new Map<String, PsychVideoSprite>());
						}
			
						var stageVars = variables.get("stageVariables");
						stageVars.set(tag, leVSprite);
				}
			} else {
				luaTrace('makeVideoSprite: The video file "' + videoFile + '" cannot be found!', FlxColor.RED);
				return;
			}
			leVSprite.active = true;
			#else
			luaTrace('Nuh Uh!!... - Platform not supported!');
			#end
		});
		Lua_helper.add_callback(lua, "makeLuaCamera", function(tag:String, ?x:Float = 0.0, ?y:Float = 0.0, ?resX:Int = 1280, ?resY:Int = 720, ?zoom:Float = 1.0) { // creates the camera
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);

			var leCamera:FlxCamera = new FlxCamera(x, y, resX, resY, zoom);
			leCamera.bgColor = 0x00000000; // transparent bg for the camera

			var variables = MusicBeatState.getVariables();
			variables.set(tag, leCamera);
		});
		Lua_helper.add_callback(lua, "setupCameraFollow", function(tag:String, ?x:Float=null, ?y:Float=null) { // creates the camera follow point
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);

			// sets to the og camPos if it's null
			if (x == null) x = PlayState.instance.girlfriendCameraOffset[0] + PlayState.instance.gf.getGraphicMidpoint().x + PlayState.instance.gf.cameraPosition[0];
			if (y == null) y = PlayState.instance.girlfriendCameraOffset[1] + PlayState.instance.gf.getGraphicMidpoint().y + PlayState.instance.gf.cameraPosition[1];

			var leFollowPoint:FlxObject = new FlxObject();
    		leFollowPoint.setPosition(x, y);

			var variables = MusicBeatState.getVariables();
			variables.set(tag, leFollowPoint);
		});
		Lua_helper.add_callback(lua, "setCameraFollow", function(tag:String, ?followPoint:String=null, ?speed:Float=0) { // sets the follow point to the camera
			var variables = MusicBeatState.getVariables();

			var leCamera:FlxCamera = game.getLuaObject(tag);
			var daFollow:FlxObject = game.getLuaObject(followPoint);
			var daSpeed:Float = speed;

			if (leCamera == null) {
				luaTrace("setCameraFollow: Camera " + tag + " doesn't exist!", false, false, FlxColor.RED);
				return;
			}

			if (daFollow == null) daFollow = game.camFollow;
			if (daSpeed == 0) daSpeed = (game.cameraSpeed*0.04) * game.playbackRate;

			leCamera.follow(daFollow, FlxCameraFollowStyle.LOCKON, daSpeed);
		});
		Lua_helper.add_callback(lua, "addLuaCamera", function(tag:String, ?copyGame:Bool=false) { // add the camera
			var leCamera:FlxCamera = game.getLuaObject(tag);
			
			if (leCamera != null)
				FlxG.cameras.add(leCamera, copyGame)
			else
				luaTrace("addLuaCamera: Camera " + tag + " doesn't exist!", false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "removeLuaCamera", function(tag:String, ?destroy:Bool=false) { // add the camera
			var leCamera:FlxCamera = game.getLuaObject(tag);
			
			if (leCamera != null)
				FlxG.cameras.remove(leCamera, destroy)
			else
				luaTrace("removeLuaCamera: Camera " + tag + " doesn't exist!", false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "reorderCameras", function(cameraNames:Array<String>) { 
			@:privateAccess
			var defaultCameras:Array<FlxCamera> = FlxG.cameras.defaults;
			var copiedCameras:Array<FlxCamera> = defaultCameras.slice(0, defaultCameras.length); // Need to create a copy since we remove from FlxG.cameras

			for (camName in cameraNames) {
				var leCamera:FlxCamera = LuaUtils.cameraFromString(camName);

				if (leCamera != null){
					FlxG.cameras.remove(leCamera, false);
				}	
			}

			for (camName in cameraNames) {
			
				var leCamera:FlxCamera = LuaUtils.cameraFromString(camName);
			
				if (leCamera != null){
					@:privateAccess
					var isDefault = copiedCameras.indexOf(leCamera) != -1;
					FlxG.cameras.add(leCamera, isDefault);
				}
			}
		});
		Lua_helper.add_callback(lua, "addClipRect", function(obj:String, x:Float, y:Float, width:Float, height:Float) { // no way this shit worked without changing anything
			var killMe:Array<String> = obj.split('.');
			var object:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);

			if(killMe.length > 1) {
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
			}

			if(object != null) {
				var swagRect = (object.clipRect != null ? object.clipRect : new FlxRect());
				swagRect.x = x;
				swagRect.y = y;
				swagRect.width = width;
				swagRect.height = height;
				
				object.clipRect = swagRect;
				return true;
			}
			luaTrace("addClipRect: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
			if(game.getLuaObject(obj)!=null) {
				var spr:FlxSprite = game.getLuaObject(obj);
				spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
				return;
			}

			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null) {
				spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
				return;
			}

			luaTrace('makeGraphic: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Float = 24, loop:Bool = true) {
			var obj:FlxSprite = cast LuaUtils.getObjectDirectly(obj);
			if(obj != null && obj.animation != null)
			{
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if(obj.animation.curAnim == null)
				{
					var dyn:Dynamic = cast obj;
					if(dyn.playAnim != null) dyn.playAnim(name, true);
					else dyn.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "addAnimation", function(obj:String, name:String, frames:Any, framerate:Float = 24, loop:Bool = true) {
			return LuaUtils.addAnimByIndices(obj, name, null, frames, framerate, loop);
		});

		Lua_helper.add_callback(lua, "addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:Any, framerate:Float = 24, loop:Bool = false) {
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		Lua_helper.add_callback(lua, "playAnim", function(obj:String, name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj);
			if (obj != null){
				if(obj.playAnim != null)
				{
					obj.playAnim(name, forced, reverse, startFrame);
					return true;
				}
				else
				{
					if(obj.anim != null) obj.anim.play(name, forced, reverse, startFrame); //FlxAnimate
					else obj.animation.play(name, forced, reverse, startFrame);
					return true;
				}
			}
			return false;
		});
		Lua_helper.add_callback(lua, "addOffset", function(obj:String, anim:String, x:Float, y:Float) {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj);
			if(obj != null && obj.addOffset != null)
			{
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			if(game.getLuaObject(obj) != null) {
				game.getLuaObject(obj).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

		Lua_helper.add_callback(lua, "objectColorTransform", function(obj:String, color:String) {
			var spr:Dynamic = LuaUtils.getObjectDirectly(obj);

			if (spr != null) {
				spr.useColorTransform = true;

				// Use CoolUtil.colorFromString which already handles hex parsing and alpha
				var parsedColor:FlxColor = CoolUtil.colorFromString(color);

				// Extract RGBA components
				var r:Int = parsedColor.red;
				var g:Int = parsedColor.green;
				var b:Int = parsedColor.blue;
				var a:Int = parsedColor.alpha;

				spr.setColorTransform(0, 0, 0, 1, r, g, b, a);
			}
		});


		Lua_helper.add_callback(lua, "inBetweenColor", function(color:String, color2:String, diff:Float, ?remove0:Bool = false) {
			var color = FlxColor.interpolate(CoolUtil.colorFromString(color), CoolUtil.colorFromString(color2), diff);
			var daColor = color.toHexString();

			if (remove0)
				daColor = daColor.substring(2);

			return daColor;
		});
		Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, ?inFront:Bool = false) {
			var mySprite:FlxSprite = MusicBeatState.getVariables().get(tag);
			if(mySprite == null) return;

			var instance = LuaUtils.getTargetInstance();
			if(inFront)
				instance.add(mySprite);
			else
			{
				if(PlayState.instance == null || !PlayState.instance.isDead)
					instance.insert(instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), mySprite);
				else
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
			}
		});
		Lua_helper.add_callback(lua, "changeCharacter", function(tag:String, character:String, ?flipped:Bool = false) {
			switch(tag.toLowerCase().trim()) {
				case 'gf' | 'girlfriend' | "2":
					if (flipped == null) flipped = PlayState.instance.gf.flipMode;
					changeGFAuto(character, flipped);
				case 'dad' | "opponent" | "1":
					if (flipped == null) flipped = PlayState.instance.dad.flipMode;
					changeDadAuto(character, flipped);
				case 'boyfriend' | 'bf' | 'player' | "0":
					if (flipped == null) flipped = PlayState.instance.boyfriend.flipMode;
					changeBFAuto(character, flipped);	
				default: 
					var shit:Character = PlayState.instance.modchartCharacters.get(tag);
					if (flipped == null && shit != null) shit.flipMode = flipped;
					if(shit != null) makeLuaCharacter(tag, character, shit.isPlayer, shit.flipMode);
					else luaTrace("changeCharacter: " + tag + " doesn't exist!", false, false, FlxColor.RED);		
			}
		});
		Lua_helper.add_callback(lua, "makeLuaCharacter", function(tag:String, character:String, isPlayer:Bool = false, ?flipped:Bool = false) {
			makeLuaCharacter(tag, character, isPlayer, flipped);
		});
		Lua_helper.add_callback(lua, "flipCharacterAnim", function(character:String) {
			switch(character.toLowerCase()) {
				case 'dad':
					PlayState.instance.dad.flipAnims();
				case 'gf' | 'girlfriend':
					PlayState.instance.gf.flipAnims();
				default:
					if(PlayState.instance.modchartCharacters.exists(character)) {
						var spr:Character = PlayState.instance.modchartCharacters.get(character);
						spr.flipAnims();
						return;
					}
					PlayState.instance.boyfriend.flipAnims();
			}
		});
		Lua_helper.add_callback(lua, "changeStage", function(id:String) {
			PlayState.instance.removeStage(); // Remove current stage
			PlayState.instance.curStage = id; // Set new stage name
			PlayState.instance.stageData = StageData.getStageFile(PlayState.instance.curStage); 
			PlayState.instance.addStage();
			PlayState.instance.setOnScripts('curStage', PlayState.instance.curStage);
		});
		Lua_helper.add_callback(lua, "makeHealthIcon", function(tag:String, character:String, player:Bool = false) {
			if (scriptType.toLowerCase() == "modpack"){
				ModpackAssetRegistry.instance.addAsset("images", 'icons/icon-'+character);
				return;
			}

			makeIcon(tag, character, player);
		});
		Lua_helper.add_callback(lua, "changeIcon", function(tag:String, character:String){
			var shit:HealthIcon = game.variables.get(tag);
			shit.changeIcon(character);
		});
		Lua_helper.add_callback(lua,"characterZoom", function(id:String, zoomAmount:Float, ?isSenpai:Bool = false) {
			if(PlayState.instance.modchartCharacters.exists(id)) {
				var spr:Character = PlayState.instance.modchartCharacters.get(id);
				spr.setZoom(zoomAmount, isSenpai);
			}
			else
				LuaUtils.getObjectDirectly(id).setZoom(zoomAmount, isSenpai);
		});
		Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Float, y:Float = 0, updateHitbox:Bool = true) {
			if(game.getLuaObject(obj)!=null) {
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.setGraphicSize(x, y);
				if(updateHitbox) shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(poop != null) {
				poop.setGraphicSize(x, y);
				if(updateHitbox) poop.updateHitbox();
				return;
			}
			luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
			if(game != null && game.getLuaObject(obj)!=null) {
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.scale.set(x, y);
				if(updateHitbox) shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(poop != null) {
				poop.scale.set(x, y);
				if(updateHitbox) poop.updateHitbox();
				return;
			}
			luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "updateHitbox", function(obj:String) {
			if(game != null && game.getLuaObject(obj)!=null) {
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(poop != null) {
				poop.updateHitbox();
				return;
			}
			luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true, ?group:String = null) {
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if(obj == null || obj.destroy == null)
				return;
			
			var groupObj:Dynamic = null;
			if(group == null) groupObj = LuaUtils.getTargetInstance();
			else groupObj = LuaUtils.getObjectDirectly(group);

			groupObj.remove(obj, true);
			if(destroy)
			{
				MusicBeatState.getVariables().remove(tag);
				obj.destroy();
			}
		});

		Lua_helper.add_callback(lua, "luaSpriteExists", function(tag:String) {
			var obj:FlxSprite = MusicBeatState.getVariables().get(tag);
			return (obj != null && (Std.isOfType(obj, ModchartSprite) || Std.isOfType(obj, ModchartAnimateSprite)));
		});
		Lua_helper.add_callback(lua, "luaTextExists", function(tag:String) {
			var obj:FlxText = MusicBeatState.getVariables().get(tag);
			return (obj != null && Std.isOfType(obj, FlxText));
		});
		Lua_helper.add_callback(lua, "luaSoundExists", function(tag:String) {
			var obj:FlxSound = MusicBeatState.getVariables().get('sound_$tag');
			return (obj != null && Std.isOfType(obj, FlxSound));
		});

		Lua_helper.add_callback(lua, "setHealthBarColors", function(left:String, right:String) {
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			game.healthBar.setColors(left_color, right_color);
		});
		Lua_helper.add_callback(lua, "setTimeBarColors", function(left:String, right:String) {
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			game.timeBar.setColors(left_color, right_color);
		});

		Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, camera:Dynamic = 'game') {
			if (game != null){
				var real:FlxBasic = game.getLuaObject(obj);
				var realCam:Dynamic = camera;

				if (Std.isOfType(realCam, String)){
					realCam = LuaUtils.cameraFromString(camera);
				}

				if(real != null && realCam != null) {
					real.cameras = [realCam];
					return true;
				}

				var split:Array<String> = obj.split('.');
				var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}

				if(object != null && realCam != null) {
					object.cameras = [realCam];
					return true;
				}
			}
		
			luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setBlendMode", function(obj:String, blend:String = '') {
			var real:FlxSprite = game.getLuaObject(obj);
			if(real != null) {
				real.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}

			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null) {
				spr.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}
			luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "screenCenter", function(obj:String, ?pos:String = 'xy') {
			var spr:FlxObject = game.getLuaObject(obj);

			if(spr==null){
				var split:Array<String> = obj.split('.');
				spr = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
			}

			if(spr != null)
			{
				switch(pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			luaTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "objectsOverlap", function(obj1:String, obj2:String) {
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxBasic> = [];
			for (i in 0...namesArray.length)
			{
				var real:FlxBasic = game.getLuaObject(namesArray[i]);
				if(real != null)
					objectsArray.push(real);
				else
					objectsArray.push(Reflect.getProperty(LuaUtils.getTargetInstance(), namesArray[i]));
			}
			return (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]));
		});
		Lua_helper.add_callback(lua, "getPixelColor", function(obj:String, x:Int, y:Int) {
			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(spr != null) return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});

		// Returns the actual object itself. I modified setObjectCamera to accept the actual camera object too.
		Lua_helper.add_callback(lua, "getObjectCamera", function(obj:String) {
			var real:FlxBasic = game.getLuaObject(obj);
			
			if(real != null) {
				return real.camera;
			}

			var split:Array<String> = obj.split('.');
			var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(object != null) {
				return object.camera;
			}
			luaTrace("getObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return game.camGame;
		});

		//change individual values
		Lua_helper.add_callback(lua,"changeHue", function(id:String, hue:Int) {
			var newShader:ColorSwap = new ColorSwap();
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			shit.shader = newShader.shader;
			newShader.hue = hue / 360;
		});
		Lua_helper.add_callback(lua,"changeSaturation", function(id:String, sat:Int) {
			var newShader:ColorSwap = new ColorSwap();
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			shit.shader = newShader.shader;
			newShader.saturation = sat / 100;
		});
		Lua_helper.add_callback(lua,"changeBrightness", function(id:String, bright:Int) {
			var newShader:ColorSwap = new ColorSwap();
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			shit.shader = newShader.shader;
			newShader.brightness = bright / 100;
		});
		//change as a group. you should probably use this one
		Lua_helper.add_callback(lua,"changeHSB", function(id:String, hue:Int = 0, sat:Int = 0, bright:Int = 0) {
			var newShader:ColorSwap = new ColorSwap();
		
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			shit.shader = newShader.shader;
			newShader.hue = hue / 360;
			newShader.saturation = sat / 100;
			newShader.brightness = bright / 100;
		});
		Lua_helper.add_callback(lua,"changeGroupHue", function(obj:String, hue:Int) {
			var shit:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			shit.forEach(function(thing:Dynamic)
			{
				var newShader:ColorSwap = new ColorSwap();
				newShader.hue = hue / 360;
				thing.shader = newShader.shader;
			});
		});
		Lua_helper.add_callback(lua,"changeGroupMemberHue", function(obj:String, index:Int, hue:Int) {
			var shit:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj)[index];

			if(Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), obj), FlxTypedGroup))
				shit = Reflect.getProperty(LuaUtils.getTargetInstance(), obj).members[index];

			var newShader:ColorSwap = new ColorSwap();
			newShader.hue = hue / 360;
			shit.shader = newShader.shader;
		});
		Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, ?music:String = null) {
			var path:String;
			var songPath:String = Paths.formatToSongPath(Song.loadedSongName);
			#if TRANSLATIONS_ALLOWED
			path = Paths.getPath('data/$songPath/${dialogueFile}_${ClientPrefs.data.language}.json', TEXT);
			#if MODS_ALLOWED
			if(!FileSystem.exists(path))
			#else
			if(!Assets.exists(path, TEXT))
			#end
			#end
				path = Paths.getPath('data/$songPath/$dialogueFile.json', TEXT);

			luaTrace('startDialogue: Trying to load dialogue: ' + path);

			#if MODS_ALLOWED
			if(FileSystem.exists(path))
			#else
			if(Assets.exists(path, TEXT))
			#end
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if(shit.dialogue.length > 0)
				{
					game.startDialogue(shit, music);
					luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				}
				else luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
			}
			else
			{
				luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				if(game.endingSong)
					game.endSong();
				else
					game.startCountdown();
			}
			return false;
		});
		Lua_helper.add_callback(lua, "startVideo", function(videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile)))
			{
				if (scriptType.toLowerCase() == "modpack"){
					ModpackAssetRegistry.instance.addAsset("videos", videoFile);
					return true;
				}

				if(game.videoCutscene != null)
				{
					game.remove(game.videoCutscene);
					game.videoCutscene.destroy();
				}
				game.videoCutscene = game.startVideo(videoFile, forMidSong, canSkip, shouldLoop, playOnLoad);
				return true;
			}
			else
			{
				luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			}
			return false;

			#else
			PlayState.instance.inCutscene = true;
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				PlayState.instance.inCutscene = false;
				if(game.endingSong)
					game.endSong();
				else
					game.startCountdown();
			});
			return true;
			#end
		});

		Lua_helper.add_callback(lua, "playMusic", function(sound:String, ?volume:Float = 1, ?loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		Lua_helper.add_callback(lua, "playSound", function(sound:String, ?volume:Float = 1, ?tag:String = null, ?loop:Bool = false) {
			if (scriptType.toLowerCase() == "modpack" && sound != null && sound.length > 0){
				ModpackAssetRegistry.instance.addAsset("sounds", sound);
				return null;
			}

			if(tag != null && tag.length > 0)
			{
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables = MusicBeatState.getVariables();
				var oldSnd = variables.get(tag);
				if(oldSnd != null)
				{
					oldSnd.stop();
					oldSnd.destroy();
				}

				variables.set(tag, FlxG.sound.play(Paths.sound(sound), volume, loop, null, true, function()
				{
					if(!loop) variables.remove(tag);
					if(game != null) game.callOnLuas('onSoundFinished', [originalTag]);
				}));
				return tag;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
			return null;
		});
		Lua_helper.add_callback(lua, "stopSound", function(tag:String) {
			if(tag == null || tag.length < 1)
			{
				if(FlxG.sound.music != null)
					FlxG.sound.music.stop();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables = MusicBeatState.getVariables();
				var snd:FlxSound = variables.get(tag);
				if(snd != null)
				{
					snd.stop();
					variables.remove(tag);
				}
			}
		});
		Lua_helper.add_callback(lua, "pauseSound", function(tag:String) {
			if(tag == null || tag.length < 1)
			{
				if(FlxG.sound.music != null)
					FlxG.sound.music.pause();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.pause();
			}
		});
		Lua_helper.add_callback(lua, "resumeSound", function(tag:String) {
			if(tag == null || tag.length < 1)
			{
				if(FlxG.sound.music != null)
					FlxG.sound.music.play();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.play();
			}
		});
		Lua_helper.add_callback(lua, "soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if (game == null){
				duration = duration / game.playbackRate;	
			}

			if(tag == null || tag.length < 1)
			{
				if(FlxG.sound.music != null)
					FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null)
					snd.fadeIn(duration, fromValue, toValue);
			}
		});
		Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
			if (game == null){
				duration = duration / game.playbackRate;	
			}
			
			if(tag == null || tag.length < 1)
			{
				if(FlxG.sound.music != null)
					FlxG.sound.music.fadeOut(duration, toValue);
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null)
					snd.fadeOut(duration, toValue);
			}
		});
		Lua_helper.add_callback(lua, "soundFadeCancel", function(tag:String) {
			if(tag == null || tag.length < 1)
			{
				if(FlxG.sound.music != null && FlxG.sound.music.fadeTween != null)
					FlxG.sound.music.fadeTween.cancel();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null && snd.fadeTween != null)
					snd.fadeTween.cancel();
			}
		});
		Lua_helper.add_callback(lua, "getSoundVolume", function(tag:String) {
			if(tag == null || tag.length < 1)
			{
				if(FlxG.sound.music != null)
					return FlxG.sound.music.volume;
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) return snd.volume;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundVolume", function(tag:String, value:Float) {
			if(tag == null || tag.length < 1)
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				if(FlxG.sound.music != null)
				{
					FlxG.sound.music.volume = value;
					return;
				}
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.volume = value;
			}
		});
		Lua_helper.add_callback(lua, "getSoundTime", function(tag:String) {
			if(tag == null || tag.length < 1)
			{
				return FlxG.sound.music != null ? FlxG.sound.music.time : 0;
			}
			tag = LuaUtils.formatVariable('sound_$tag');
			var snd:FlxSound = MusicBeatState.getVariables().get(tag);
			return snd != null ? snd.time : 0;
		});
		Lua_helper.add_callback(lua, "setSoundTime", function(tag:String, value:Float) {
			if(tag == null || tag.length < 1)
			{
				if(FlxG.sound.music != null)
				{
					FlxG.sound.music.time = value;
					return;
				}
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null) snd.time = value;
			}
		});
		Lua_helper.add_callback(lua, "getSoundPitch", function(tag:String) {
			#if FLX_PITCH
			tag = LuaUtils.formatVariable('sound_$tag');
			var snd:FlxSound = MusicBeatState.getVariables().get(tag);
			return snd != null ? snd.pitch : 1;
			#else
			luaTrace("getSoundPitch: Sound Pitch is not supported on this platform!", false, false, FlxColor.RED);
			return 1;
			#end
		});
		Lua_helper.add_callback(lua, "setSoundPitch", function(tag:String, value:Float, ?doPause:Bool = false) {
			#if FLX_PITCH
			tag = LuaUtils.formatVariable('sound_$tag');
			var snd:FlxSound = MusicBeatState.getVariables().get(tag);
			if(snd != null)
			{
				var wasResumed:Bool = snd.playing;
				if (doPause) snd.pause();
				snd.pitch = value;
				if (doPause && wasResumed) snd.play();
			}
			
			if(tag == null || tag.length < 1)
			{
				if(FlxG.sound.music != null)
				{
					var wasResumed:Bool = FlxG.sound.music.playing;
					if (doPause) FlxG.sound.music.pause();
					FlxG.sound.music.pitch = value;
					if (doPause && wasResumed) FlxG.sound.music.play();
					return;
				}
			}
			else
			{
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if(snd != null)
				{
					var wasResumed:Bool = snd.playing;
					if (doPause) snd.pause();
					snd.pitch = value;
					if (doPause && wasResumed) snd.play();
				}
			}
			#else
			luaTrace("setSoundPitch: Sound Pitch is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});

		// mod settings
		addLocalCallback("getModSetting", function(saveTag:String, ?modName:String = null) {
			#if MODS_ALLOWED
			if(modName == null)
			{
				if(this.modFolder == null)
				{
					FunkinLua.luaTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
			#else
			luaTrace("getModSetting: Mods are disabled in this build!", false, false, FlxColor.RED);
			#end
		});
		//

		Lua_helper.add_callback(lua, "Paths", function(type:String, tag:String):Dynamic {
			switch(type.toLowerCase()) { // adding the others later... if i don't forget about it...
				case 'image': return Paths.image(Std.string(tag));
				case 'sound': return Paths.sound(Std.string(tag));
				case 'music': return Paths.music(Std.string(tag));
				case 'font': return Paths.font(Std.string(tag));
				default: 
					luaTrace('Paths: invalid type!', false, false, FlxColor.RED);
					return null;
			}
		});

		Lua_helper.add_callback(lua, "debugPrint", function(text:Dynamic = '', color:String = 'WHITE') PlayState.instance.addTextToDebug(text, CoolUtil.colorFromString(color)));

		addLocalCallback("close", function() {
			closed = true;
			trace('Closing script $scriptName');
			return closed;
		});

		#if DISCORD_ALLOWED DiscordClient.addLuaCallbacks(lua); #end
		#if ACHIEVEMENTS_ALLOWED Achievements.addLuaCallbacks(lua); #end
		#if TRANSLATIONS_ALLOWED Language.addLuaCallbacks(lua); #end
		HScript.implement(this);
		#if flxanimate FlxAnimateFunctions.implement(this); #end
		ReflectionFunctions.implement(this);
		TextFunctions.implement(this);
		TweenFunctions.implement(this);
		ExtraFunctions.implement(this);
		CustomSubstate.implement(this);
		ShaderFunctions.implement(this);
		DeprecatedFunctions.implement(this);
		SpriteGroupFunctions.implement(this);

		for (name => func in customFunctions)
		{
			if(func != null)
				Lua_helper.add_callback(lua, name, func);
		}

		try{
			var isString:Bool = !FileSystem.exists(scriptName);
			var result:Dynamic = null;
			if(!isString)
				result = LuaL.dofile(lua, scriptName);
			else
				result = LuaL.dostring(lua, scriptName);

			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				trace(resultStr);
				#if windows
				lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
				#else
				luaTrace('$scriptName\n$resultStr', true, false, FlxColor.RED);
				#end
				lua = null;
				return;
			}
			if(isString) scriptName = 'unknown';
		} catch(e:Dynamic) {
			trace(e);
			return;
		}
		trace('lua file loaded succesfully:' + scriptName);

		call('onCreate', []);
	}

	//main
	public var lastCalledFunction:String = '';
	public static var lastCalledScript:FunkinLua = null;
	public function call(func:String, args:Array<Dynamic>):Dynamic {
		if(closed) return LuaUtils.Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		try {
			if(lua == null) return LuaUtils.Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL)
					luaTrace("ERROR (" + func + "): attempt to call a " + LuaUtils.typeToString(type) + " value", false, false, FlxColor.RED);

				Lua.pop(lua, 1);
				return LuaUtils.Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK) {
				var error:String = getErrorMessage(status);
				luaTrace("ERROR (" + func + "): " + error, false, false, FlxColor.RED);
				return LuaUtils.Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = LuaUtils.Function_Continue;

			Lua.pop(lua, 1);
			if(closed) stop();
			return result;
		}
		catch (e:Dynamic) {
			trace(e);
		}
		return LuaUtils.Function_Continue;
	}

	public function set(variable:String, data:Dynamic) {
		if(lua == null) {
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
	}

	public function stop() {
		closed = true;

		if(lua == null) {
			return;
		}
		Lua.close(lua);
		lua = null;
		#if HSCRIPT_ALLOWED
		if(hscript != null)
		{
			hscript.destroy();
			hscript = null;
		}
		#end
	}

	function doFunction(id:String, ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic, ?val4:Dynamic) {
		//this is dumb but idk how else to do it and i don't wanna make multiple functions for different playstate functions so yeah.
		switch (id)
		{
			case 'startCountdown': PlayState.instance.startCountdown();
			case 'resyncVocals': PlayState.instance.resyncVocals();	
			case 'doTimeTravel': PlayState.instance.doTimeTravel(val1, val2);		
			case 'uncacheImage': Paths.clearAssetFromMemory(val1, 'image');	
			case 'uncacheSound': Paths.clearAssetFromMemory(val1, 'sound');			
			case 'cacheImage': Paths.image(val1, ClientPrefs.data.cacheOnGPU);
		}
	}

	public static function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) {
				return;
			}
			PlayState.instance.addTextToDebug(text, color);
		}
	}

		private function convert(v : Any, type : String) : Dynamic { // I didn't write this lol
		if( Std.isOfType(v, String) && type != null ) {
		var v : String = v;
		if( type.substr(0, 4) == 'array' ) {
			if( type.substr(4) == 'float' ) {
			var array : Array<String> = v.split(',');
			var array2 : Array<Float> = new Array();

			for( vars in array ) {
				array2.push(Std.parseFloat(vars));
			}

			return array2;
			} else if( type.substr(4) == 'int' ) {
			var array : Array<String> = v.split(',');
			var array2 : Array<Int> = new Array();

			for( vars in array ) {
				array2.push(Std.parseInt(vars));
			}

			return array2;
			} else {
			var array : Array<String> = v.split(',');
			return array;
			}
		} else if( type == 'float' ) {
			return Std.parseFloat(v);
		} else if( type == 'int' ) {
			return Std.parseInt(v);
		} else if( type == 'bool' ) {
			if( v == 'true' ) {
			return true;
			} else {
			return false;
			}
		} else {
			return v;
		}
		} else {
		return v;
		}
	}

	public function get(var_name : String, type : String) : Dynamic {
		if(lua == null) {
			return false;
		}

		var result : Any = null;

		// trace('getting variable ' + var_name + ' with a type of ' + type);

		Lua.getglobal(lua, var_name);
		result = Convert.fromLua(lua,-1);
		Lua.pop(lua,1);

		if( result == null ) {
		return null;
		} else {
		var result = convert(result, type);
		//trace(var_name + ' result: ' + result);
		return result;
		}
	}

	public static function getBool(variable:String) {
		if(lastCalledScript == null) return false;

		var lua:State = lastCalledScript.lua;
		if(lua == null) return false;

		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if(result == null) {
			return false;
		}
		return (result == 'true');
	}

	function findScript(scriptFile:String, ext:String = '.lua')
	{
		if(!scriptFile.endsWith(ext)) scriptFile += ext;
		var path:String = Paths.getPath(scriptFile, TEXT);
		#if MODS_ALLOWED
		if(FileSystem.exists(path))
		#else
		if(Assets.exists(path, TEXT))
		#end
		{
			return path;
		}
		#if MODS_ALLOWED
		else if(FileSystem.exists(scriptFile))
		#else
		else if(Assets.exists(scriptFile, TEXT))
		#end
		{
			return scriptFile;
		}
		return null;
	}

	public function getErrorMessage(status:Int):String {
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null) v = v.trim();
		if (v == null || v == "") {
			switch(status) {
				case Lua.LUA_ERRRUN: return "Runtime Error";
				case Lua.LUA_ERRMEM: return "Memory Allocation Error";
				case Lua.LUA_ERRERR: return "Critical Error";
			}
			return "Unknown Error";
		}

		return v;
		return null;
	}

	public function addLocalCallback(name:String, myFunction:Dynamic)
	{
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); //just so that it gets called
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end

	public function initLuaShader(name:String)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (!flash && sys)
		if(runtimeShaders.exists(name))
		{
			var shaderData:Array<String> = runtimeShaders.get(name);
			if(shaderData != null && (shaderData[0] != null || shaderData[1] != null))
			{
				luaTrace('Shader $name was already initialized!');
				return true;
			}
		}

		var foldersToCheck:Array<String> = [Paths.getSharedPath('shaders/')];
		#if MODS_ALLOWED
		foldersToCheck.push(Paths.mods('shaders/'));
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if(FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		luaTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		luaTrace('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}

	public static function makeIcon(tag:String, character:String, isPlayer:Bool) // making it as a standalone function so i can use on other states
	{
		tag = tag.replace('.', '');
		LuaUtils.destroyObject(tag);
		var leSprite:HealthIcon = new HealthIcon(character, isPlayer);
		PlayState.instance.variables.set(tag, leSprite); //yes
		var shit:HealthIcon = PlayState.instance.variables.get(tag);
		shit.cameras = [PlayState.instance.camHUD];
		LuaUtils.getTargetInstance().add(shit);
	}
	
	public static function makeLuaCharacter(tag:String, character:String, isPlayer:Bool = false, flipped:Bool = false) {
		tag = tag.replace('.', '');

		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;	
		var position:Int = -1;
		var oldChar:String = "";
							
		if (PlayState.instance.modchartCharacters.get(tag) != null)
		{
			var daChar:Character = PlayState.instance.modchartCharacters.get(tag);
			oldChar = daChar.curCharacter;

			if (daChar.isAnimateAtlas){
				if (daChar.getAnimationName().startsWith('sing')) {
					animationName = Std.string(daChar.atlas.anim.curInstance);
					animationFrame = Std.int(daChar.atlas.anim.curFrame);
				}
			} else {
				if (daChar.animation.curAnim.name.startsWith('sing')) {
					animationName = daChar.animation.curAnim.name;
					animationFrame = daChar.animation.curAnim.curFrame;
				}		
			}
			position = LuaUtils.getTargetInstance().members.indexOf(daChar);
		}
		
		LuaUtils.resetCharacterTag(tag);
		var leSprite:Character = new Character(0, 0, character, isPlayer);
		//leSprite.flipMode = flipped;
		PlayState.instance.modchartCharacters.set(tag, leSprite); //yes
		var shit:Character = PlayState.instance.modchartCharacters.get(tag);
		LuaUtils.getTargetInstance().add(shit);

		if (position >= 0) //this should keep them in the same spot if they switch
		{
			LuaUtils.getTargetInstance().remove(shit, true);
			LuaUtils.getTargetInstance().insert(position, shit);
		}

		var stageData:StageFile = StageData.getStageFile(PlayState.SONG.stage);
		var charX:Float = 0;
		var charY:Float = (flipped ? 350 : 0);

		if (!isPlayer)
		{
			//if (flipped) shit.flipMode = true;
	
			charX = shit.positionArray[0];
			charY = shit.positionArray[1];
	
			shit.x = PlayState.instance.DAD_X + charX;
			shit.y = PlayState.instance.DAD_Y + charY;
		}
		else
		{
			//if (flipped) shit.flipMode = true;
	
			var charX:Float = 0;
			var charY:Float =  (!flipped ? 0 : 350);
		
			charX = shit.playerPositionArray[0];
			charY = shit.playerPositionArray[1];
	
			shit.x = PlayState.instance.BF_X + charX;
			shit.y = PlayState.instance.BF_Y + charY;
		}

		if (shit.animOffsets.exists(animationName)) shit.playAnim(animationName, true, false, animationFrame);

		if (oldChar != "") shit.pastCharacter = oldChar;
		PlayState.instance.startCharacterScripts(shit.curCharacter);
	}

	//trying to do some auto stuff so i don't have to set manual x and y values
	public static function changeBFAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false) {	
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;				
		var oldChar:String = PlayState.instance.boyfriend.curCharacter;
		
		try {
			if (PlayState.instance.boyfriend.isAnimateAtlas){
				if (PlayState.instance.boyfriend.getAnimationName().startsWith('sing')) {
					animationName = Std.string(PlayState.instance.boyfriend.atlas.anim.curInstance);
					animationFrame = Std.int(PlayState.instance.boyfriend.atlas.anim.curFrame);
				}
			} else {
				if (PlayState.instance.boyfriend.animation.curAnim.name.startsWith('sing')) {
					animationName = PlayState.instance.boyfriend.animation.curAnim.name;
					animationFrame = PlayState.instance.boyfriend.animation.curAnim.curFrame;
				}		
			}
		} catch (e:Dynamic) {
			// do absolutely nothing
		}
		
		//PlayState.instance.stopCharacterScripts(PlayState.instance.boyfriend.curCharacter);
		PlayState.instance.boyfriend.destroyAtlas();
		PlayState.instance.remove(PlayState.instance.boyfriend);
		PlayState.instance.boyfriend.destroy();
		PlayState.instance.boyfriend = new Character(0, 0, id, !flipped);
		PlayState.instance.boyfriend.flipMode = flipped;

		var isFlipped = PlayState.instance.boyfriend.flipMode;
		var charX:Float = 0;
		var charY:Float = (isFlipped ? 350 : 0);

		var charX:Float = 0;
		var charY:Float =  (!isFlipped ? 0 : 350);
		
		charX = PlayState.instance.boyfriend.playerPositionArray[0];
		charY = PlayState.instance.boyfriend.playerPositionArray[1];
	
		PlayState.instance.boyfriend.x = PlayState.instance.BF_X + charX;
		PlayState.instance.boyfriend.y = PlayState.instance.BF_Y + charY;

		PlayState.instance.add(PlayState.instance.boyfriend);

		PlayState.instance.iconP1.changeIcon(PlayState.instance.boyfriend.healthIcon);
		
		/*if (PlayState.instance.defaultBar)
		{
			var dad = PlayState.instance.dad;
			var boyfriend = PlayState.instance.boyfriend;
			
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			PlayState.instance.healthBar.updateBar();
		}	*/
		PlayState.instance.reloadHealthBarColors();

		if (PlayState.instance.boyfriend.animOffsets.exists(animationName))
			PlayState.instance.boyfriend.playAnim(animationName, true, false, animationFrame);

		PlayState.instance.boyfriend.pastCharacter = oldChar;
		PlayState.instance.setOnScripts('boyfriendName', PlayState.instance.boyfriend.curCharacter);
		PlayState.instance.startCharacterScripts(PlayState.instance.boyfriend.curCharacter);
	}

	public static function changeDadAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false) {	
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;						
		var oldChar:String = PlayState.instance.dad.curCharacter;

		try {
			if (PlayState.instance.dad.isAnimateAtlas){
				if (PlayState.instance.dad.getAnimationName().startsWith('sing')) {
					animationName = Std.string(PlayState.instance.dad.atlas.anim.curInstance);
					animationFrame = Std.int(PlayState.instance.dad.atlas.anim.curFrame);
				}
			} else {
				if (PlayState.instance.dad.animation.curAnim.name.startsWith('sing')) {
					animationName = PlayState.instance.dad.animation.curAnim.name;
					animationFrame = PlayState.instance.dad.animation.curAnim.curFrame;
				}		
			}
		} catch (e:Dynamic) {
			// do absolutely nothing
		}

		//PlayState.instance.stopCharacterScripts(PlayState.instance.dad.curCharacter);
		PlayState.instance.dad.destroyAtlas();
		PlayState.instance.remove(PlayState.instance.dad);
		PlayState.instance.dad.destroy();
		PlayState.instance.dad = new Character(0, 0, id, flipped);
		PlayState.instance.dad.flipMode = flipped;

		var isFlipped = PlayState.instance.dad.flipMode;
		var charX:Float = 0;
		var charY:Float = (isFlipped ? 350 : 0);

		var charX:Float = 0;
		var charY:Float =  (!isFlipped ? 0 : 350);
		
		charX = PlayState.instance.dad.positionArray[0];
		charY = PlayState.instance.dad.positionArray[1];
	
		PlayState.instance.dad.x = PlayState.instance.DAD_X + charX;
		PlayState.instance.dad.y = PlayState.instance.DAD_Y + charY;

		//PlayState.instance.addObject(PlayState.instance.bfTrail);
		//PlayState.instance.bfTrail.resetTrail();
		PlayState.instance.add(PlayState.instance.dad);

		PlayState.instance.iconP2.changeIcon(PlayState.instance.dad.healthIcon);
		
		/*if (PlayState.instance.defaultBar)
		{
			var dad = PlayState.instance.dad;
			var boyfriend = PlayState.instance.boyfriend;
			
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			PlayState.instance.healthBar.updateBar();
		}*/

		PlayState.instance.reloadHealthBarColors();

		if (PlayState.instance.dad.animOffsets.exists(animationName))
			PlayState.instance.dad.playAnim(animationName, true, false, animationFrame);

		PlayState.instance.dad.pastCharacter = oldChar;
		PlayState.instance.setOnScripts('dadName', PlayState.instance.dad.curCharacter);
		PlayState.instance.startCharacterScripts(PlayState.instance.dad.curCharacter);
	}

	public static function changeGFAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false) { // not tested but i'm almost 100% sure it works		
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;		
		var oldChar:String = PlayState.instance.gf.curCharacter;

		try {
			if (PlayState.instance.gf.isAnimateAtlas){
				if (PlayState.instance.gf.getAnimationName().startsWith('sing')) {
					animationName = Std.string(PlayState.instance.gf.atlas.anim.curInstance);
					animationFrame = Std.int(PlayState.instance.gf.atlas.anim.curFrame);
				}
			} else {
				if (PlayState.instance.gf.animation.curAnim.name.startsWith('sing')) {
					animationName = PlayState.instance.gf.animation.curAnim.name;
					animationFrame = PlayState.instance.gf.animation.curAnim.curFrame;
				}		
			}
		} catch (e:Dynamic) {
			// do absolutely nothing
		}

		//PlayState.instance.stopCharacterScripts(PlayState.instance.gf.curCharacter);
		PlayState.instance.gf.destroyAtlas();
		PlayState.instance.remove(PlayState.instance.gf);
		PlayState.instance.gf.destroy();
		PlayState.instance.gf = new Character(0, 0, id, flipped);
		PlayState.instance.gf.flipMode = flipped;
		var stageData:StageFile = PlayState.instance.stageData;
		PlayState.instance.gf.x = PlayState.instance.GF_X + PlayState.instance.gf.positionArray[0];
		PlayState.instance.gf.y = PlayState.instance.GF_Y + PlayState.instance.gf.positionArray[1];
		// PlayState.instance.gf.scrollFactor.set(0.95, 0.95);
		PlayState.instance.add(PlayState.instance.gf);

		if (PlayState.instance.gf.animOffsets.exists(animationName))
			PlayState.instance.gf.playAnim(animationName, true, false, animationFrame);

		PlayState.instance.gf.pastCharacter = oldChar;
		PlayState.instance.setOnScripts('gfName', PlayState.instance.gf.curCharacter);
		PlayState.instance.startCharacterScripts(PlayState.instance.gf.curCharacter);
	}

	#if (!flash && MODS_ALLOWED && sys)
	public static function getShader(obj:String, ?swagShader:String):FlxRuntimeShader {// putting this too bcuz im lazy to fix all my scripts
		var shader:Dynamic = null;
		shader = ShaderFunctions.getShader(obj, swagShader);
		return shader;
	}
	#end

	public static function callOnCompleted(type:String = "tween", tag:String, ?loops:Int, ?loopsLeft:Int) {
		var variables = MusicBeatState.getVariables();
		switch (type.toLowerCase())
		{
			case 'timer':
				if (variables.get(tag) != null) variables.remove(tag);
				if(PlayState.instance != null) PlayState.instance.callOnLuas('onTimerCompleted', [tag]);
			default:
				var twn:FlxTween = variables.get(tag);
 				if(twn != null)
 				{
 					twn.cancel();
 					twn.destroy();
 					variables.remove(tag);
 				}
				if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
		}
	}

	public function initAnalyzer(barCount:Int, maxDelta:Float = 0.01, peakHold:Int = 30) {
		@:privateAccess
		if (FlxG.sound.music == null || FlxG.sound.music._channel == null || FlxG.sound.music._channel.__audioSource == null) return;

		@:privateAccess
		audioAnalyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, barCount, maxDelta, peakHold);

		#if desktop
		audioAnalyzer.fftN = 256;
		#end
	}

	public function getAudioLevels() {
		var levels = audioAnalyzer.getLevels();
		return [for (i in levels) i.value];
	}
}
#end
