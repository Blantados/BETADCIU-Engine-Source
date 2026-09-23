package psychlua;

import backend.WeekData;

import flixel.FlxBasic;
import flixel.math.FlxRandom;
import flixel.FlxState;
import flixel.util.FlxDestroyUtil;
import objects.Character;
import objects.Bopper;
import psychlua.LuaUtils;
import psychlua.CustomSubstate;
import substates.GameOverSubstate;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

import states.MainMenuState;

#if HSCRIPT_ALLOWED
import extensions.hscript.*;

import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;

import haxe.ValueException;

typedef HScriptInfos = {
	> haxe.PosInfos,
	var ?funcName:String;
	var ?showLine:Null<Bool>;
	#if LUA_ALLOWED
	var ?isLua:Null<Bool>;
	#end
}

@:access(crowplexus.iris.Iris)
@:access(states.PlayState)
class HScript extends IrisEx implements IFlxDestroyable
{
	public var filePath:String;
	public var modFolder:String;
	public var returnValue:Dynamic;
	public var scriptObjects:Array<FlxBasic> = [];

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	public static function initHaxeModule(parent:FunkinLua)
	{
		if(parent.hscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
	{
		var hs:HScript = try parent.hscript catch (e) null;
		if(hs == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			try {
				parent.hscript = new HScript(parent, code, varsToBring);
			}
			catch(e:IrisError) {
				var pos:HScriptInfos = cast {fileName: parent.scriptName, isLua: true};
				if(parent.lastCalledFunction != '') pos.funcName = parent.lastCalledFunction;
				Iris.error(Printer.errorToString(e, false), pos);
				parent.hscript = null;
			}
		}
		else
		{
			try
			{
				hs.scriptCode = code;
				hs.varsToBring = varsToBring;
				hs.parse(true);
				var ret:Dynamic = hs.execute();
				hs.returnValue = ret;
			}
			catch(e:IrisError)
			{
				var pos:HScriptInfos = cast hs.interp.posInfos();
				pos.isLua = true;
				if(parent.lastCalledFunction != '') pos.funcName = parent.lastCalledFunction;
				Iris.error(Printer.errorToString(e, false), pos);
				hs.returnValue = null;
			}
		}
	}
	#end

	public var scriptType:String = '';

	public var origin:String;
	public var scriptName:String = null;
	override public function new(?parent:Dynamic, ?file:String, ?scriptType:String = "", ?varsToBring:Any = null, ?manualRun:Bool = false, ?shareables:Sharables)
	{
		if (file == null)
			file = '';

		filePath = file;
		this.scriptType = scriptType;
		if (filePath != null && filePath.length > 0)
		{
			this.origin = filePath;
			#if MODS_ALLOWED
			var myFolder:Array<String> = filePath.split('/');
			if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
			#end
		}
		var scriptThing:String = file;

		if(parent == null && file != null)
		{
			var f:String = file.replace('\\', '/');
			if(f.contains('/') && !f.contains('\n')) {
				scriptThing = File.getContent(f);
				scriptName = f;
			}
		}
		#if LUA_ALLOWED
		if (scriptName == null && parent != null)
			scriptName = parent.scriptName;
		#end
		super(scriptThing, new IrisConfig(scriptName, false, false), shareables);
		var customInterp:InterpEx = new InterpEx(FlxG.state, shareables);
		customInterp.showPosOnLog = false;
		this.interp = customInterp;
		#if LUA_ALLOWED
		parentLua = parent;
		if (parent != null)
		{
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}
		#end
		preset();
		this.varsToBring = varsToBring;
		if (!manualRun) {
			var ret:Dynamic = null;
			try {
				ret = execute();
				returnValue = ret;
			} catch(e:IrisError) {
				returnValue = null;
				this.destroy();
				throw e;
			}
		}
	}
	
	var varsToBring(default, set):Any = null;
	override function preset() {
		super.preset();
		
		set('StringTools', StringTools);
		
		set('Type', Type);
		set("script", this);
		set("Dynamic", Dynamic);
		
		set('StringMap', haxe.ds.StringMap);
		set('IntMap', haxe.ds.IntMap);
		set('ObjectMap', haxe.ds.ObjectMap);
		
		set("Main", Main);
		set("Lib", openfl.Lib);
		set("Assets", lime.utils.Assets);
		set("OpenFlAssets", openfl.utils.Assets);
		
		set('curBpm', Conductor.bpm);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('crotchet', Conductor.crochet); // NV
		set('stepCrotchet', Conductor.stepCrochet); // NV
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('Function_StopLua', LuaUtils.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('curBeat', 0);
		set('curStep', 0);
		set('curSection', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);
		set('version', MainMenuState.betadciuEngineVersion.trim());
		// set('Defines', backend.Defines); // not yet
		
		// set flixel related stuff
		set('FlxG', flixel.FlxG);
		set('FlxSprite', flixel.FlxSprite);
		set("FlxTypedGroup", flixel.group.FlxGroup.FlxTypedGroup);
		set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		set('FlxCamera', extensions.flixel.FlxCameraEx);
		set('PsychCamera', backend.PsychCamera);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set("FlxSound", flixel.sound.FlxSound);
		set('FlxText', flixel.text.FlxText);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('ErrorHandledRuntimeShader', shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set("FlxFlicker", flixel.effects.FlxFlicker);
		set('FlxSpriteUtil', flixel.util.FlxSpriteUtil);
		set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		set("FlxTiledSprite", flixel.addons.display.FlxTiledSprite);
		set('FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
		set('FlxObject', flixel.FlxObject);
		
		set('FlxCameraFollowStyle', flixel.FlxCamera.FlxCameraFollowStyle);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);

		set('FlxAnimate', animate.FlxAnimate);
		set("FlxAnimateFrames", animate.FlxAnimateFrames);
		set("FlxSpriteElement", animate.internal.elements.FlxSpriteElement);

		set('Controls', Controls.instance);
		set('controls', Controls.instance); // in lower case bcuz default psych use this in lower case

		// abstracts
		set("FlxTextAlign", backend.MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		set('FlxAxes', backend.MacroUtil.buildAbstract(flixel.util.FlxAxes));
		set("FlxKey", backend.MacroUtil.buildAbstract(flixel.input.keyboard.FlxKey));
		set('BlendMode', backend.MacroUtil.buildAbstract(openfl.display.BlendMode));

		set("keyToString", (key:Int) -> { return flixel.input.keyboard.FlxKey.toStringMap.get(key); });
		set("keyFromString", (str:String) -> { return flixel.input.keyboard.FlxKey.fromStringMap.get(str); });

		// FNF-specific Things
		set('Paths', Paths);
		set("MusicBeatState", backend.MusicBeatState);
		set("Conductor", backend.Conductor);
		set('ClientPrefs', ClientPrefs);
		set("CoolUtil", backend.CoolUtil);
		// set('WindowUtil', backend.WindowUtil);
		set("StageData", backend.StageData);
		set('PlayState', PlayState);
		set("GameOverSubstate", substates.GameOverSubstate);
		set('FunkinSound', backend.system.sound.FunkinSound);

		// custom
		set('FlxColor', CustomFlxColor);
		set('Random', CustomFlxRandom);

		// objects
		set('Note', objects.Note);
		set("Bar", objects.Bar);
		#if VIDEOS_ALLOWED
		set("PsychVideoSprite", objects.PsychVideoSprite);
		#end
		set('Bopper', objects.Bopper);
		set("BackgroundDancer", states.stages.objects.BackgroundDancer);
		set("BackgroundGirls", states.stages.objects.BackgroundGirls);
		set("HealthIcon", objects.HealthIcon);
		set('Character', Character);
		set("NoteSplash", objects.NoteSplash);
		set("BGSprite", objects.BGSprite);
		set("StrumNote", objects.StrumNote);
		set('Alphabet', Alphabet);
		set("AttachedSprite", objects.AttachedSprite);
		
		set("CutsceneHandler", cutscenes.CutsceneHandler);
		set('DialogueBox', cutscenes.DialogueBox);

		set('inGameOver', false);

		set('scriptObjects', scriptObjects);

		if (FlxG.state is PlayState) {
			set("inPlaystate", true);
			set('bpm', PlayState.SONG.bpm);
			set('scrollSpeed', PlayState.SONG.speed);
			set('songName', PlayState.SONG.song);
			set('isStoryMode', PlayState.isStoryMode);
			set('difficulty', PlayState.storyDifficulty);
			set('weekRaw', PlayState.storyWeek);
			set('seenCutscene', PlayState.seenCutscene);
			set('week', WeekData.getCurrentWeek().weekName);
			set('difficultyName', Difficulty.getString());
			set('songLength', FlxG.sound.music.length);
			set('instakillOnMiss', PlayState.instance.instakillOnMiss);
			set('botPlay', PlayState.instance.cpuControlled);
			set('practice', PlayState.instance.practiceMode);
			set('startedCountdown', false);
			set('mustHitSection', PlayState.SONG?.notes[0]?.mustHitSection ?? false);

			set('game', FlxG.state);
			set("global", MusicBeatState.getVariables());
			set('getInstance', function():FlxState {
				return PlayState.instance == null ? FlxG.state : PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
			});

			set('setVar', (varName:String, val:Dynamic) -> MusicBeatState.getVariables().set(varName, val));
			set('getVar', (varName:String) -> MusicBeatState.getVariables().get(varName));

			set('initScript', (path:String, ?type:String = "") -> {
				PlayState.instance.startHScriptsNamed(path, type);
			});
		} else {
			set("inPlaystate", false);
		}

		set("newShader", (?fragFile:String, ?vertFile:String) -> {
			var fragPath = fragFile != null ? Paths.fragment(fragFile) : null;
			var vertPath = vertFile != null ? Paths.vertex(vertFile) : null;
			
			if (fragPath != null)
				if (Paths.exists(fragPath)) fragPath = Paths.getContent(fragPath);
			
			if (vertPath != null)
				if (Paths.exists(vertPath)) vertPath = Paths.getContent(vertPath);
			
			return new flixel.addons.display.FlxRuntimeShader(fragPath, vertPath);
		});

		// default psych stuff
		#if sys
		set('File', File);
		set('FileSystem', FileSystem);
		#end
		set('Countdown', backend.BaseStage.Countdown);
		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end
		set('CustomSubstate', CustomSubstate);

		// some really useful variables that for some reason doesn't comes in the og code
		set('camGame', PlayState.instance.camGame);
		set('camHUD', PlayState.instance.camHUD);
		set('camOther', PlayState.instance.camOther);
		set('boyfriend', PlayState.instance.boyfriend);
		set('dad', PlayState.instance.dad);
		set('gf', PlayState.instance.gf);
		set('defaultCamZoom', PlayState.instance.defaultCamZoom);
		//

		// Functions & Variables
		set('removeVar', function(name:String)
		{
			if(MusicBeatState.getVariables().exists(name))
			{
				MusicBeatState.getVariables().remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});
		set('getModSetting', function(saveTag:String, ?modName:String = null) {
			if(modName == null)
			{
				if(this.modFolder == null)
				{
					Iris.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', this.interp.posInfos());
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});

		// Keyboard & Gamepads
		set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name:String) FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

		set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadJustPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		set('gamepadPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		set('gamepadReleased', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		set('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_P;
				case 'down': return Controls.instance.NOTE_DOWN_P;
				case 'up': return Controls.instance.NOTE_UP_P;
				case 'right': return Controls.instance.NOTE_RIGHT_P;
				default: return Controls.instance.justPressed(name);
			}
			return false;
		});
		set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT;
				case 'down': return Controls.instance.NOTE_DOWN;
				case 'up': return Controls.instance.NOTE_UP;
				case 'right': return Controls.instance.NOTE_RIGHT;
				default: return Controls.instance.pressed(name);
			}
			return false;
		});
		set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_R;
				case 'down': return Controls.instance.NOTE_DOWN_R;
				case 'up': return Controls.instance.NOTE_UP_R;
				case 'right': return Controls.instance.NOTE_RIGHT_R;
				default: return Controls.instance.justReleased(name);
			}
			return false;
		});

		// For adding your own callbacks
		// not very tested but should work
		#if LUA_ALLOWED
		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);

			FunkinLua.customFunctions.set(name, func);
		});

		// this one was tested
		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			
			if(funk != null) funk.addLocalCallback(name, func);
			else Iris.error('createCallback ($name): 3rd argument is null', this.interp.posInfos());
		});
		#end

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';

				switch(libName){
					case "ModchartState": libName = "FunkinLua";
				}

				if (libPackage == "luafiles"){
					libPackage = "psychlua";
				}

				if(libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:IrisError) {
				Iris.error(Printer.errorToString(e, false), this.interp.posInfos());
			}
		});
		#if LUA_ALLOWED
		set('parentLua', parentLua);
		#else
		set('parentLua', null);
		#end
		set('this', this);
		set('ModchartState', FunkinLua); // lazy ass fix for some scripts ported from betadciu engine

		// you don't need to add stageVars anymore.
		set('add', function(tag:FlxBasic, ?name:String = null){
			scriptObjects.push(tag);
			FlxG.state.add(tag);
			if (name != null && !MusicBeatState.getVariables().exists(name)) MusicBeatState.getVariables().set(name, tag);
		});

		set('insert', function(position:Int, tag:FlxBasic, ?name:String = null){ 
			scriptObjects.push(tag);
			FlxG.state.insert(position, tag);
			if (name != null && !MusicBeatState.getVariables().exists(name)) MusicBeatState.getVariables().set(name, tag);
		});

		set('addBehindGF', function(tag:FlxBasic, ?name:String = null){
			scriptObjects.push(tag);
			FlxG.state.insert(PlayState.instance.members.indexOf(PlayState.instance.gf), tag);
			if (name != null && !MusicBeatState.getVariables().exists(name)) MusicBeatState.getVariables().set(name, tag);
		});
		set('addBehindBF', function(tag:FlxBasic, ?name:String = null){
			scriptObjects.push(tag);
			FlxG.state.insert(PlayState.instance.members.indexOf(PlayState.instance.boyfriend), tag);
			if (name != null && !MusicBeatState.getVariables().exists(name)) MusicBeatState.getVariables().set(name, tag);
		});
		set('addBehindDad', function(tag:FlxBasic, ?name:String = null){
			scriptObjects.push(tag);
			FlxG.state.insert(PlayState.instance.members.indexOf(PlayState.instance.dad), tag);
			if (name != null && !MusicBeatState.getVariables().exists(name)) MusicBeatState.getVariables().set(name, tag);
		});
		//

		set('getColorFromHex', function(color:String):Int {
			if (color == null) return 0xFFFFFFFF;

			if (color.length >= 4 && color.substr(0,4) == "0xFF")
				color = color.substr(4);
			if (color.length >= 2 && color.substr(0,2) == "0x")
				color = color.substr(2);
			if (color.length >= 1 && color.substr(0,1) == "#")
				color = color.substr(1);

			return FlxColor.fromString("#" + color);
		});

		set("include", function(path:String) { // just testing
			var scriptText:String = Paths.getTextFromFile(path);

			if(scriptText == null)
			{
				trace('Script not found: ' + path);
				return;
			}

			this.scriptCode += "\n" + scriptText;

			this.parse(true);
			this.execute();
		});

		set('buildTarget', LuaUtils.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			if (funk.scriptType == "modpack")
				return null;

			initHaxeModuleCode(funk, codeToRun, varsToBring);
			if (funk.hscript != null)
			{
				final retVal:IrisCall = funk.hscript.call(funcToRun, funcArgs);
				if (retVal != null)
				{
					return (LuaUtils.isLuaSupported(retVal.returnValue)) ? retVal.returnValue : null;
				}
				else if (funk.hscript.returnValue != null)
				{
					return funk.hscript.returnValue;
				}
			}
			return null;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			if (funk.scriptType == "modpack")
				return null;

			if (funk.hscript != null)
			{
				final retVal:IrisCall = funk.hscript.call(funcToRun, funcArgs);
				if (retVal != null)
				{
					return (LuaUtils.isLuaSupported(retVal.returnValue)) ? retVal.returnValue : null;
				}
			}
			else
			{
				var pos:HScriptInfos = cast {fileName: funk.scriptName, showLine: false};
				if (funk.lastCalledFunction != '') pos.funcName = funk.lastCalledFunction;
				Iris.error("runHaxeFunction: HScript has not been initialized yet! Use \"runHaxeCode\" to initialize it", pos);
			}
			return null;
		});
		// This function is unnecessary because import already exists in HScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			var str:String = '';

			switch(libName){
				case "ModchartState": libName = "FunkinLua";
			}

			if (libPackage == "luafiles"){
				libPackage = "psychlua";
			}
			
			if (libPackage.length > 0)
				str = libPackage + '.';
			else if (libName == null)
				libName = '';

			var c:Dynamic = Type.resolveClass(str + libName);
			if (c == null)
				c = Type.resolveEnum(str + libName);

			if (funk.hscript == null)
				initHaxeModule(funk);

			var pos:HScriptInfos = cast funk.hscript.interp.posInfos();
			pos.showLine = false;
			if (funk.lastCalledFunction != '')
				 pos.funcName = funk.lastCalledFunction;

			try {
				if (c != null)
					funk.hscript.set(libName, c);
			}
			catch (e:IrisError) {
				Iris.error(Printer.errorToString(e, false), pos);
			}
			FunkinLua.lastCalledScript = funk;
			if (FunkinLua.getBool('luaDebugMode') && FunkinLua.getBool('luaDeprecatedWarnings'))
				Iris.warn("addHaxeLibrary is deprecated! Import classes through \"import\" in HScript!", pos);
		});
	}
	#end

	override function call(funcToRun:String, ?args:Array<Dynamic>):IrisCall {
		if (funcToRun == null || interp == null) return null;

		if (!exists(funcToRun)) {
			Iris.error('No function named: $funcToRun', this.interp.posInfos());
			return null;
		}

		try {
			var func:Dynamic = interp.variables.get(funcToRun); // function signature
			if (PlayState.instance != null) PlayState.instance.calledBy = this;
			final ret = Reflect.callMethod(null, func, args ?? []);
			if (PlayState.instance != null) PlayState.instance.calledBy = null;
			return {funName: funcToRun, signature: func, returnValue: ret};
		}
		catch(e:IrisError) {
			if (PlayState.instance != null) PlayState.instance.calledBy = null;
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			#if LUA_ALLOWED
			if (parentLua != null)
			{
				pos.isLua = true;
				if (parentLua.lastCalledFunction != '') pos.funcName = parentLua.lastCalledFunction;
			}
			#end
			Iris.error(Printer.errorToString(e, false), pos);
		}
		catch (e:ValueException) {
			if (PlayState.instance != null) PlayState.instance.calledBy = null;
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			#if LUA_ALLOWED
			if (parentLua != null)
			{
				pos.isLua = true;
				if (parentLua.lastCalledFunction != '') pos.funcName = parentLua.lastCalledFunction;
			}
			#end
			Iris.error('$e', pos);
		}
		return null;
	}

	override public function destroy()
	{
		origin = null;
		#if LUA_ALLOWED parentLua = null; #end

		if (scriptObjects != null) {
			for (obj in scriptObjects) {
				if (obj != null) {
					FlxG.state.remove(obj, true);
					obj.destroy();
				}
			}
			scriptObjects = [];
		}

		super.destroy();
	}

	function set_varsToBring(values:Any) {
		if (varsToBring != null)
			for (key in Reflect.fields(varsToBring))
				if (exists(key.trim()))
					interp.variables.remove(key.trim());

		if (values != null)
		{
			for (key in Reflect.fields(values))
			{
				key = key.trim();
				set(key, Reflect.field(values, key));
			}
		}

		return varsToBring = values;
	}
}

class CustomFlxColor {
	public static var TRANSPARENT(default, null):Int = FlxColor.TRANSPARENT;
	public static var BLACK(default, null):Int = FlxColor.BLACK;
	public static var WHITE(default, null):Int = FlxColor.WHITE;
	public static var GRAY(default, null):Int = FlxColor.GRAY;

	public static var GREEN(default, null):Int = FlxColor.GREEN;
	public static var LIME(default, null):Int = FlxColor.LIME;
	public static var YELLOW(default, null):Int = FlxColor.YELLOW;
	public static var ORANGE(default, null):Int = FlxColor.ORANGE;
	public static var RED(default, null):Int = FlxColor.RED;
	public static var PURPLE(default, null):Int = FlxColor.PURPLE;
	public static var BLUE(default, null):Int = FlxColor.BLUE;
	public static var BROWN(default, null):Int = FlxColor.BROWN;
	public static var PINK(default, null):Int = FlxColor.PINK;
	public static var MAGENTA(default, null):Int = FlxColor.MAGENTA;
	public static var CYAN(default, null):Int = FlxColor.CYAN;

	public static function fromInt(Value:Int):Int 
		return cast FlxColor.fromInt(Value);

	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
		return cast FlxColor.fromRGB(Red, Green, Blue, Alpha);

	public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);

	public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);

	public static function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromHSB(Hue, Sat, Brt, Alpha);

	public static function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromHSL(Hue, Sat, Light, Alpha);

	public static function fromString(str:String):Int
		return cast FlxColor.fromString(str);
}

@:access(flixel.math.FlxRandom)
class CustomFlxRandom
{
	@:inheritDoc(flixel.math.FlxRandom.resetInitialSeed)
	public static inline function resetInitialSeed():Int
	{
		return FlxG.random.initialSeed = FlxRandom.rangeBound(Std.int(Math.random() * FlxMath.MAX_VALUE_INT));
	}
	
	@:inheritDoc(flixel.math.FlxRandom.int)
	public function int(min:Int = 0, max:Int = FlxMath.MAX_VALUE_INT, ?excludes:Array<Int>):Int
	{
		return FlxG.random.int(min, max, excludes);
	}
	
	@:inheritDoc(flixel.math.FlxRandom.float)
	public static function float(min:Float = 0, max:Float = 1, ?excludes:Array<Float>):Float
	{
		return FlxG.random.float(min, max, excludes);
	}
	
	@:inheritDoc(flixel.math.FlxRandom.floatNormal)
	public function floatNormal(mean:Float = 0, stdDev:Float = 1):Float
	{
		return FlxG.random.floatNormal(mean, stdDev);
	}
	
	@:inheritDoc(flixel.math.FlxRandom.bool)
	public static inline function bool(chance:Float = 50):Bool
	{
		return float(0, 100) < chance;
	}
	
	@:inheritDoc(flixel.math.FlxRandom.sign)
	public static inline function sign(chance:Float = 50):Int
	{
		return bool(chance) ? 1 : -1;
	}
	
	@:inheritDoc(flixel.math.FlxRandom.weightedPick)
	public static function weightedPick(weightsArray:Array<Float>):Int
	{
		return FlxG.random.weightedPick(weightsArray);
	}
	
	@:inheritDoc(flixel.math.FlxRandom.getObject)
	public static function getObject<T>(objects:Array<T>, ?weightsArray:Array<Float>, startIndex:Int = 0, ?endIndex:Null<Int>)
	{
		var selected:Null<T> = null;
		
		if (objects.length != 0)
		{
			weightsArray ??= [for (i in 0...objects.length) 1];
			
			endIndex ??= objects.length - 1;
			
			startIndex = Std.int(FlxMath.bound(startIndex, 0, objects.length - 1));
			endIndex = Std.int(FlxMath.bound(endIndex, 0, objects.length - 1));
			
			// Swap values if reversed
			if (endIndex < startIndex)
			{
				startIndex = startIndex + endIndex;
				endIndex = startIndex - endIndex;
				startIndex = startIndex - endIndex;
			}
			
			if (endIndex > weightsArray.length - 1)
			{
				endIndex = weightsArray.length - 1;
			}
			
			final arrayHelper = [for (i in startIndex...endIndex + 1) weightsArray[i]];
			
			selected = objects[startIndex + weightedPick(arrayHelper)];
		}
		
		return selected;
	}
	
	@:inheritDoc(flixel.math.FlxRandom.shuffle)
	public static function shuffle<T>(array:Array<T>):Void
	{
		var maxValidIndex = array.length - 1;
		for (i in 0...maxValidIndex)
		{
			var j = FlxG.random.int(i, maxValidIndex);
			var tmp = array[i];
			array[i] = array[j];
			array[j] = tmp;
		}
	}
	
	@:inheritDoc(flixel.math.FlxRandom.color)
	public static function color(?min:FlxColor, ?max:FlxColor, ?alpha:Int, greyScale:Bool = false):FlxColor
	{
		return FlxG.random.color(min, max, alpha, greyScale);
	}
}
#else
class HScript
{
	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
	}
	#end
}
#end
