// because my lazy ass doesn't wanna include a bunch of if(stageMode) stuff to the regular ModchartState

// Lua
import openfl.display3D.textures.VideoTexture;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
#if desktop
import flixel.tweens.FlxEase;
import openfl.filters.ShaderFilter;
import openfl.Lib;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import lime.app.Application;
import flixel.FlxSprite;
import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.system.FlxSound;
import flixel.effects.FlxFlicker;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import Type.ValueType;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import openfl.system.System;
import lime.utils.Assets;
import flixel.math.FlxMath;
import openfl.display.BlendMode;
import flixel.util.FlxAxes;
import flixel.math.FlxRect;
import animateatlas.AtlasFrameMaker;
import ModchartState;
import flixel.addons.display.FlxBackdrop;

#if desktop
import Sys;
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;
import Shaders;
import flash.media.Sound;

class StageModchartState 
{
	//public static var shaders:Array<LuaShader> = null;

	public var lua:State = null;
	public static var Function_Stop = 1;
	public static var Function_Continue = 0;
	public static var Function_StopLua = 2;

	public var blam:Dynamic = "";
	public var scriptName:String = '';
	var gonnaClose:Bool = false;
	public var closed:Bool = false;

	public function call(func_name : String, args : Array<Dynamic>, ?type : String) : Dynamic
	{
		#if LUA_ALLOWED
		if(closed) return Function_Continue;

		if(lua == null) {
			return Function_Continue;
		}

		var result : Any = null;

		Lua.getglobal(lua, func_name);

		for (arg in args) {
			Convert.toLua(lua, arg);
		}

		var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);
		if(result != null && resultIsAllowed(lua, result)) {
			if(Lua.type(lua, -1) == Lua.LUA_TSTRING) {
				var error:String = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if(error == 'attempt to call a nil value') { //Makes it ignore warnings and not break stuff if you didn't put the functions on your lua file
					return Function_Continue;
				}
			}

			return convert(result, type);
		}
		#end
		return Function_Continue;
	}

	#if desktop
	function resultIsAllowed(leLua:State, leResult:Null<Int>) { //Makes it ignore warnings
		switch(Lua.type(leLua, leResult)) {
			case Lua.LUA_TNIL | Lua.LUA_TBOOLEAN | Lua.LUA_TNUMBER | Lua.LUA_TSTRING | Lua.LUA_TTABLE:
				return true;
		}
		return false;
	}
	#end

	static function toLua(l:State, val:Any):Bool {
		switch (Type.typeof(val)) {
			case Type.ValueType.TNull:
				Lua.pushnil(l);
			case Type.ValueType.TBool:
				Lua.pushboolean(l, val);
			case Type.ValueType.TInt:
				Lua.pushinteger(l, cast(val, Int));
			case Type.ValueType.TFloat:
				Lua.pushnumber(l, val);
			case Type.ValueType.TClass(String):
				Lua.pushstring(l, cast(val, String));
			case Type.ValueType.TClass(Array):
				Convert.arrayToLua(l, val);
			case Type.ValueType.TObject:
				objectToLua(l, val);
			default:
				trace("haxe value not supported - " + val + " which is a type of " + Type.typeof(val));
				return false;
		}

		return true;

	}

	static function objectToLua(l:State, res:Any) {

		var FUCK = 0;
		for(n in Reflect.fields(res))
		{
			trace(Type.typeof(n).getName());
			FUCK++;
		}

		Lua.createtable(l, FUCK, 0); // TODONE: I did it

		for (n in Reflect.fields(res)){
			if (!Reflect.isObject(n))
				continue;
			Lua.pushstring(l, n);
			toLua(l, Reflect.field(res, n));
			Lua.settable(l, -3);
		}

	}

	function getType(l, type):Any
	{
		return switch Lua.type(l,type) {
			case t if (t == Lua.LUA_TNIL): null;
			case t if (t == Lua.LUA_TNUMBER): Lua.tonumber(l, type);
			case t if (t == Lua.LUA_TSTRING): (Lua.tostring(l, type):String);
			case t if (t == Lua.LUA_TBOOLEAN): Lua.toboolean(l, type);
			case t: throw 'you don goofed up. lua type error ($t)';
		}
	}

	function getReturnValues(l) {
		var lua_v:Int;
		var v:Any = null;
		while((lua_v = Lua.gettop(l)) != 0) {
			var type:String = getType(l,lua_v);
			v = convert(lua_v, type);
			Lua.pop(l, 1);
		}
		return v;
	}


	private function convert(v : Any, type : String) : Dynamic { // I didn't write this lol
		if( Std.is(v, String) && type != null ) {
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

	function getLuaErrorMessage(l) {
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);
		return v;
	}

	public function setVar(var_name : String, object : Dynamic){
		// trace('setting variable ' + var_name + ' to ' + object);

		Convert.toLua(lua, object);
		Lua.setglobal(lua, var_name);
	}

	public function getVar(var_name : String, type : String) : Dynamic {
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

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, ?color:FlxColor = FlxColor.WHITE) {
		#if desktop
		if (preloading) //otherwise it'll warn a lot for objects with scales
			return;

		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) {
				return;
			}
			PlayState.instance.addTextToDebug(text, color);
			trace(text);
		}
		#end
	}

	#if desktop
	public function getBool(variable:String) {
		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if(result == null) {
			return false;
		}

		// YES! FINALLY IT WORKS
		//trace('variable: ' + variable + ', ' + result);
		return (result == 'true');
	}
	#end

	function getActorByName(id:String):Dynamic
	{
		// pre defined names
		switch(id)
		{
			case 'boyfriend' | 'bf':
				@:privateAccesss
				return PlayState.instance.boyfriend;
		}

		if (Std.parseInt(id) == null)
			return Reflect.getProperty(getInstance(),id);
		
		return false;
		//return PlayState.instance.strumLineNotes.members[Std.parseInt(id)];
	}


	function getPropertyByName(id:String)
	{
		return Reflect.field(PlayState.instance,id);
	}

	function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
		}
		return Reflect.getProperty(leArray, variable);
	}

	function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}

    public function die() {	
		if(lua == null) {
			return;
		}
		
		Lua.close(lua);
		lua = null;
	}
    // LUA SHIT

	public var preloading:Bool = false;

    public function new(path:String, ?preloading:Bool = false)
    {
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		// pre lowercasing the song name (new)
		var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle': songLowercase = 'dadbattle';
			case 'philly-nice': songLowercase = 'philly';
			case 'scary-swings': songLowercase = 'scary swings';
		}

		var result = LuaL.dofile(lua, Paths.stageLua(path)); // execute le file
		var resultStr:String = Lua.tostring(lua, result);

		if (resultStr != null && result != 0)
		{
			Application.current.window.alert("LUA COMPILE ERROR:\n" + resultStr,"Kade Engine Modcharts");//kep this
			trace('oops you screwed up');
			Lua.close(lua);
			lua = null;
			Stage.instance.luaArray.remove(this);
			Stage.instance.luaArray = [];
			return;
		}

		scriptName = Paths.stageLua(path);

		trace('lua file loaded succesfully:' + path);

		this.preloading = preloading;
		
		//shaders = new Array<LuaShader>();	

		// get some fukin globals up in here bois

		setVar('Function_StopLua', Function_StopLua);
		setVar('Function_Stop', Function_Stop);
		setVar('Function_Continue', Function_Continue);

		setVar("difficulty", PlayState.storyDifficulty);
		setVar("bpm", Conductor.bpm);
		setVar("scrollspeed", FlxG.save.data.scrollSpeed != 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed);
		setVar("fpsCap", FlxG.save.data.fpsCap);
		setVar("downscroll", FlxG.save.data.downscroll);
		setVar("flashing", FlxG.save.data.flashing);
		setVar("distractions", FlxG.save.data.distractions);
		setVar('scriptName', scriptName);

		setVar("curStep", 0);
		setVar("daSection", 0);
		setVar("curBeat", 0);
		setVar("crochet", Conductor.crochet);
		setVar("stepCrochet", Conductor.stepCrochet);
		setVar("safeZoneOffset", Conductor.safeZoneOffset);

		setVar("screenWidth",FlxG.width);
		setVar("screenHeight",FlxG.height);
		setVar("windowWidth",FlxG.width);
		setVar("windowHeight",FlxG.height);

		setVar("mustHitSection", false);
		setVar("curStep", 0);
		setVar("curBeat", 0);
		
		setVar('luaDebugMode', true);
		// callbacks

		// sprites

		if (preloading) //only the necessary functions for preloading are included
		{
			Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
				tag = tag.replace('.', '');
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
				if(image != null && image.length > 0) {

					var rawPic:Dynamic;

					if (!Paths.currentTrackedAssets.exists(image))
						Paths.cacheImage(image);

					rawPic = Paths.currentTrackedAssets.get(image);

					leSprite.loadGraphic(rawPic);		
					
					if (FlxG.save.data.poltatoPC)
					{
						leSprite.scale.set(2, 2);
						leSprite.updateHitbox();
					}
				}
				leSprite.antialiasing = antialiasing;

				if (!preloading)
					Stage.instance.swagBacks.set(tag, leSprite);
			});

			Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float,spriteType:String="sparrow") {
				tag = tag.replace('.', '');
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
				
				loadFrames(leSprite, image, spriteType);
				leSprite.antialiasing = true;

				if (!preloading)
					Stage.instance.swagBacks.set(tag, leSprite);
			});

			Lua_helper.add_callback(lua, "makeLuaBackdrop", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
				tag = tag.replace('.', '');

				var leSprite:FlxBackdrop = null;
				
				if(image != null && image.length > 0) {

					var rawPic:Dynamic;

					if (!Paths.currentTrackedAssets.exists(image))
						Paths.cacheImage(image);

					rawPic = Paths.currentTrackedAssets.get(image);	
					
					leSprite = new FlxBackdrop(rawPic, x, y);
				}

				if (leSprite == null)
					return;

				leSprite.antialiasing = antialiasing;
				leSprite.active = true;

				if (!preloading)
					Stage.instance.swagBacks.set(tag, leSprite);
			});

			//because we have to add em otherwise it'll only load the first sprite... for most luas. if you set it up where you make the sprites first and then all the formatting stuff ->
			//then it shouldn't be a problem
			
			var otherCallbacks:Array<String> = ['makeGraphic', 'objectPlayAnimation'];
			var addCallbacks:Array<String> = ['addAnimationByPrefix', 'addAnimationByIndices', 'addAnimationByIndicesLoop', 'addLuaSprite'];
			var setCallbacks:Array<String> = ['setProperty', 'setScrollFactor', 'setObjectCamera', 'setObjectOrder', 'scaleObject', 'screenCenter'];
		
			otherCallbacks = otherCallbacks.concat(addCallbacks);
			otherCallbacks = otherCallbacks.concat(setCallbacks);

			for (i in 0...otherCallbacks.length){
				Lua_helper.add_callback(lua, otherCallbacks[i], function(?string:String){
					//do almost nothing
					return true;
				});
			}
		}
		else
		{	
			Lua_helper.add_callback(lua, "closeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf. 
				var cervix = luaFile + ".lua";
				var doPush = false;
				if(FileSystem.exists(FileSystem.absolutePath("assets/shared/"+cervix))) {
					cervix = FileSystem.absolutePath("assets/shared/"+cervix);
					doPush = true;
				}
				else if (FileSystem.exists(Paths.modFolders(cervix)))
				{
					cervix = Paths.modFolders(cervix);
					doPush = true;
				}
				else {
					cervix = Paths.getPreloadPath(cervix);
					if(FileSystem.exists(cervix)) {
						doPush = true;
					}
				}

				if(doPush)
				{
					if(!ignoreAlreadyRunning)
					{
						for (luaInstance in PlayState.instance.luaArray)
						{
							if(luaInstance.scriptName == cervix)
								luaInstance.closed = true;
						}

						for (luaInstance in PlayState.instance.Stage.luaArray)
						{
							if(luaInstance.scriptName == cervix)
								luaInstance.closed = true;
						}
					}
					return;
				}
				luaTrace("Script doesn't exist!");
			});

			Lua_helper.add_callback(lua, "getRunningScripts", function(){
				var runningScripts:Array<String> = [];
				for (idx in 0...PlayState.instance.luaArray.length)
					runningScripts.push(PlayState.instance.luaArray[idx].scriptName);


				return runningScripts;
			});

			Lua_helper.add_callback(lua, "callOnLuas", function(?funcName:String, ?args:Array<Dynamic>, ignoreStops=false, ignoreSelf=true, ?exclusions:Array<String>){
				if(funcName==null){
					#if (linc_luajit >= "0.0.6")
					LuaL.error(lua, "bad argument #1 to 'callOnLuas' (string expected, got nil)");
					#end
					return;
				}
				if(args==null)args = [];

				if(exclusions==null)exclusions=[];

				Lua.getglobal(lua, 'scriptName');
				var daScriptName = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if(ignoreSelf && !exclusions.contains(daScriptName))exclusions.push(daScriptName);
				PlayState.instance.callOnLuas(funcName, args, ignoreStops, exclusions);
			});

			Lua_helper.add_callback(lua, "callScript", function(?luaFile:String, ?funcName:String, ?args:Array<Dynamic>){
				if(luaFile==null){
					#if (linc_luajit >= "0.0.6")
					LuaL.error(lua, "bad argument #1 to 'callScript' (string expected, got nil)");
					#end
					return;
				}
				if(funcName==null){
					#if (linc_luajit >= "0.0.6")
					LuaL.error(lua, "bad argument #2 to 'callScript' (string expected, got nil)");
					#end
					return;
				}
				if(args==null){
					args = [];
				}
				var cervix = luaFile + ".lua";
				if(luaFile.endsWith(".lua"))cervix=luaFile;
				var doPush = false;
				#if MODS_ALLOWED
				if(FileSystem.exists(Paths.modFolders(cervix)))
				{
					cervix = Paths.modFolders(cervix);
					doPush = true;
				}
				else if(FileSystem.exists(cervix))
				{
					doPush = true;
				}
				else {
					cervix = Paths.getPreloadPath(cervix);
					if(FileSystem.exists(cervix)) {
						doPush = true;
					}
				}
				#else
				cervix = Paths.getPreloadPath(cervix);
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
							luaInstance.call(funcName, args);

							return;
						}

					}
				}
				Lua.pushnil(lua);

			});

			Lua_helper.add_callback(lua, "getGlobalFromScript", function(?luaFile:String, ?global:String){ // returns the global from a script
				if(luaFile==null){
					#if (linc_luajit >= "0.0.6")
					LuaL.error(lua, "bad argument #1 to 'getGlobalFromScript' (string expected, got nil)");
					#end
					return;
				}
				if(global==null){
					#if (linc_luajit >= "0.0.6")
					LuaL.error(lua, "bad argument #2 to 'getGlobalFromScript' (string expected, got nil)");
					#end
					return;
				}
				var cervix = luaFile + ".lua";
				if(luaFile.endsWith(".lua"))cervix=luaFile;
				var doPush = false;
				#if MODS_ALLOWED
				if(FileSystem.exists(Paths.modFolders(cervix)))
				{
					cervix = Paths.modFolders(cervix);
					doPush = true;
				}
				else if(FileSystem.exists(cervix))
				{
					doPush = true;
				}
				else {
					cervix = Paths.getPreloadPath(cervix);
					if(FileSystem.exists(cervix)) {
						doPush = true;
					}
				}
				#else
				cervix = Paths.getPreloadPath(cervix);
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
							if(Lua.isnumber(luaInstance.lua,-1)){
								Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
							}else if(Lua.isstring(luaInstance.lua,-1)){
								Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
							}else if(Lua.isboolean(luaInstance.lua,-1)){
								Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
							}else{
								Lua.pushnil(lua);
							}
							// TODO: table

							Lua.pop(luaInstance.lua,1); // remove the global

							return;
						}

					}
				}
				Lua.pushnil(lua);
			});
			Lua_helper.add_callback(lua, "setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic){ // returns the global from a script
				var cervix = luaFile + ".lua";
				if(luaFile.endsWith(".lua"))cervix=luaFile;
				var doPush = false;
				#if MODS_ALLOWED
				if(FileSystem.exists(Paths.modFolders(cervix)))
				{
					cervix = Paths.modFolders(cervix);
					doPush = true;
				}
				else if(FileSystem.exists(cervix))
				{
					doPush = true;
				}
				else {
					cervix = Paths.getPreloadPath(cervix);
					if(FileSystem.exists(cervix)) {
						doPush = true;
					}
				}
				#else
				cervix = Paths.getPreloadPath(cervix);
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
				Lua.pushnil(lua);
			});

			Lua_helper.add_callback(lua, "toggleCamFilter", function(bool:Bool, camera:String = '') {
				cameraFromString(camera).filtersEnabled = bool;
			});
		

			Lua_helper.add_callback(lua, "getSongPosition", function() {
				return Conductor.songPosition;
			});

			Lua_helper.add_callback(lua,"setScrollFactor", function(id:String , x:Float, y:Float) {
				var shit:Dynamic = getObjectDirectly2(id);
				
				shit.scrollFactor.set(x, y);
			});

			Lua_helper.add_callback(lua,"getScrollFactor", function(id:String , x:String) {
				var shit:Dynamic = getObjectDirectly2(id);
				(x == 'x' ? return shit.scrollFactor.x : return shit.scrollFactor.y);
			});

			Lua_helper.add_callback(lua,"changeAnimOffset", function(id:String , x:Float, y:Float) {
				getActorByName(id).addOffset(x, y); // it may say addoffset but it actually changes it instead of adding to the existing offset so this works.
			});

			Lua_helper.add_callback(lua,"checkDownscroll", function() {
				return FlxG.save.data.downscroll;
			});

			Lua_helper.add_callback(lua,"getScared", function(id:String) {
				Stage.instance.swagBacks[id].getScared();
			});

			Lua_helper.add_callback(lua,"setDownscroll", function(id:Bool) {
				FlxG.save.data.downscroll = id;
			});

			Lua_helper.add_callback(lua,"setupNoteSplash", function(id:String) {
				PlayState.instance.splashSkin = id;
			});

			Lua_helper.add_callback(lua,"removeObject", function(id:String) {
				PlayState.instance.removeObject(getActorByName(id));
			});

			Lua_helper.add_callback(lua,"addObject", function(id:String) {
				PlayState.instance.addObject(getActorByName(id));
			});

			Lua_helper.add_callback(lua,"doStaticSign", function(lestatic:Int = 0, ?leopa:Bool = true) {
				PlayState.instance.doStaticSign(lestatic, leopa);
			});

			Lua_helper.add_callback(lua,"characterZoom", function(id:String, zoomAmount:Float, ?isSenpai:Bool = false) {
				if(PlayState.instance.modchartCharacters.exists(id)) {
					var spr:Character = PlayState.instance.modchartCharacters.get(id);
					spr.setZoom(zoomAmount, isSenpai);
				}
				else
					getActorByName(id).setZoom(zoomAmount, isSenpai);
			});
			
			Lua_helper.add_callback(lua,"setHudAngle", function (x:Float) {
				PlayState.instance.camHUD.angle = x;
			});
			
			Lua_helper.add_callback(lua,"setHealth", function (heal:Float) {
				PlayState.instance.health = heal;
			});

			Lua_helper.add_callback(lua,"minusHealth", function (heal:Float) {
				PlayState.instance.health -= heal;
			});

			Lua_helper.add_callback(lua,"setHudPosition", function (x:Int, y:Int) {
				PlayState.instance.camHUD.x = x;
				PlayState.instance.camHUD.y = y;
			});

			Lua_helper.add_callback(lua,"getHudX", function () {
				return PlayState.instance.camHUD.x;
			});

			Lua_helper.add_callback(lua,"getHudY", function () {
				return PlayState.instance.camHUD.y;
			});

			Lua_helper.add_callback(lua,"getPlayerStrumsY", function (id:Int) {
				return PlayState.instance.strumLineNotes.members[id].y;
			});
			
			Lua_helper.add_callback(lua,"setCamPosition", function (x:Int, y:Int) {
				FlxG.camera.x = x;
				FlxG.camera.y = y;
			});

			Lua_helper.add_callback(lua,"shakeCam", function (i:Float, d:Float) {
				FlxG.camera.shake(i, d);
			});

			Lua_helper.add_callback(lua,"shakeHUD", function (i:Float, d:Float) {
				PlayState.instance.camHUD.shake(i, d);
			});
			Lua_helper.add_callback(lua, "fadeCam", function (r:Int = 255,g:Int = 255,b:Int = 255, d:Float, f:Bool, ?camera:String = 'game') {
				var c:FlxColor = new FlxColor();
				c.setRGB(r, g, b);
				cameraFromString(camera).fade(c, d, f);
			});

			Lua_helper.add_callback(lua, "fadeCamPsych", function(camera:String, color:String, duration:Float, fadeOut:Bool = false, forced:Bool) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
				cameraFromString(camera).fade(colorNum, duration,fadeOut,null,forced);
			});

			Lua_helper.add_callback(lua, "flashCamPsych", function(camera:String, color:String, duration:Float, forced:Bool) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
				cameraFromString(camera).flash(colorNum, duration,null,forced);
			});

			Lua_helper.add_callback(lua, "flashCam", function (r:Int,g:Int,b:Int, d:Float, f:Bool, ?camera:String) {
				var c:FlxColor = new FlxColor();
				c.setRGB(r, g, b);
				cameraFromString(camera).flash(c, d, f);
			});

			Lua_helper.add_callback(lua, "flashCamHUD", function (r:Int,g:Int,b:Int, d:Float, f:Bool) {
				var c:FlxColor = new FlxColor();
				c.setRGB(r, g, b);
				PlayState.instance.camHUD.flash(c, d, f);
			});

			Lua_helper.add_callback(lua, "inAndOutCam", function (d:Float, d2:Float, d3:Float, ?camera:String) 
			{
				cameraFromString(camera).fade(FlxColor.WHITE, d, false, function()
				{
					new FlxTimer().start(d2, function(tmr:FlxTimer)
					{
						cameraFromString(camera).fade(FlxColor.WHITE, d3, true);
					});			
				}	
				);										
			});

			Lua_helper.add_callback(lua,"getCameraX", function () {
				return FlxG.camera.x;
			});

			Lua_helper.add_callback(lua,"getCameraY", function () {
				return FlxG.camera.y;
			});

			Lua_helper.add_callback(lua,"setCamZoom", function(zoomAmount:Float) {
				FlxG.camera.zoom = zoomAmount;
			});

			Lua_helper.add_callback(lua,"addCamZoom", function(zoomAmount:Float) {
				FlxG.camera.zoom += zoomAmount;
			});

			Lua_helper.add_callback(lua,"addHudZoom", function(zoomAmount:Float) {
				PlayState.instance.camHUD.zoom += zoomAmount;
			});

			Lua_helper.add_callback(lua,"setDefaultCamZoom", function(zoomAmount:Float) {
				PlayState.instance.defaultCamZoom = zoomAmount;
			});

			Lua_helper.add_callback(lua,"setHudZoom", function(zoomAmount:Float) {
				PlayState.instance.camHUD.zoom = zoomAmount;
			});

			Lua_helper.add_callback(lua,"setCamFollow", function(x:Float, y:Float) {
				PlayState.instance.camFollowIsOn = false;
				PlayState.instance.camFollow.setPosition(x, y);
			});

			Lua_helper.add_callback(lua,"setDelayedCamFollow", function(time:Float,x:Float, y:Float) {
				PlayState.instance.camFollowIsOn = false;

				new FlxTimer().start(time, function(tmr:FlxTimer)
				{
					PlayState.instance.camFollow.setPosition(x, y);
				});	
			});

			Lua_helper.add_callback(lua,"sundayFilter", function(bool:Bool) {
				//The string does absolutely nothing
				PlayState.instance.chromOn = bool;
			});

			Lua_helper.add_callback(lua,"offCamFollow", function(id:String) {
				//The string does absolutely nothing
				PlayState.instance.camFollowIsOn = false;
			});

			Lua_helper.add_callback(lua,"resetCamFollow", function(id:String) {
				//The string does absolutely nothing
				PlayState.instance.camFollowIsOn = true;
			});

			Lua_helper.add_callback(lua,"snapCam", function(x:Float, y:Float) {
				PlayState.instance.camFollowIsOn = false;
				{
					var camPosition:FlxObject;
					camPosition = new FlxObject(0, 0, 1, 1);
					camPosition.setPosition(x, y);
					FlxG.camera.focusOn(camPosition.getPosition());
				}
			});
			
			Lua_helper.add_callback(lua,"resetCamEffects", function(id:String) {
				PlayState.instance.camFollowIsOn = true;
			});

			Lua_helper.add_callback(lua,"miscCamFollow", function(camera:String, x:Float, y:Float) {
					var camPosition:FlxObject;
					camPosition = new FlxObject(0, 0, 1, 1);
					camPosition.setPosition(x, y);

					cameraFromString(camera).follow(camPosition, LOCKON, 0.04 * (30 / (cast (Lib.current.getChildAt(0), Main)).getFPS()));
			});

			// strumline

			Lua_helper.add_callback(lua, "setStrumlineY", function(y:Float)
			{
				PlayState.instance.strumLine.y = y;
			});

			// actors
			
			Lua_helper.add_callback(lua,"getRenderedNotes", function() {
				return PlayState.instance.notes.length;
			});

			Lua_helper.add_callback(lua,"getRenderedNoteX", function(id:Int) {
				return PlayState.instance.notes.members[id].x;
			});

			Lua_helper.add_callback(lua,"getRenderedNoteY", function(id:Int) {
				return PlayState.instance.notes.members[id].y;
			});

			Lua_helper.add_callback(lua,"getRenderedNoteType", function(id:Int) {
				return PlayState.instance.notes.members[id].noteData;
			});

			Lua_helper.add_callback(lua,"isSustain", function(id:Int) {
				return PlayState.instance.notes.members[id].isSustainNote;
			});

			Lua_helper.add_callback(lua,"isParentSustain", function(id:Int) {
				return PlayState.instance.notes.members[id].prevNote.isSustainNote;
			});

			
			Lua_helper.add_callback(lua,"getRenderedNoteParentX", function(id:Int) {
				return PlayState.instance.notes.members[id].prevNote.x;
			});

			Lua_helper.add_callback(lua,"getRenderedNoteParentY", function(id:Int) {
				return PlayState.instance.notes.members[id].prevNote.y;
			});

			Lua_helper.add_callback(lua,"getRenderedNoteHit", function(id:Int) {
				return PlayState.instance.notes.members[id].mustPress;
			});

			Lua_helper.add_callback(lua,"getRenderedNoteCalcX", function(id:Int) {
				if (PlayState.instance.notes.members[id].mustPress)
					return PlayState.instance.playerStrums.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;
				return PlayState.instance.strumLineNotes.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;
			});

			Lua_helper.add_callback(lua,"anyNotes", function() {
				return PlayState.instance.notes.members.length != 0;
			});

			Lua_helper.add_callback(lua,"getRenderedNoteStrumtime", function(id:Int) {
				return PlayState.instance.notes.members[id].strumTime;
			});

			Lua_helper.add_callback(lua,"getRenderedNoteScaleX", function(id:Int) {
				return PlayState.instance.notes.members[id].scale.x;
			});

			Lua_helper.add_callback(lua,"setRenderedNotePos", function(x:Float,y:Float, id:Int) {
				if (PlayState.instance.notes.members[id] == null)
					throw('error! you cannot set a rendered notes position when it doesnt exist! ID: ' + id);
				else
				{
					PlayState.instance.notes.members[id].modifiedByLua = true;
					PlayState.instance.notes.members[id].x = x;
					PlayState.instance.notes.members[id].y = y;
				}
			});

			Lua_helper.add_callback(lua,"setRenderedNoteAlpha", function(alpha:Float, id:Int) {
				PlayState.instance.notes.members[id].modifiedByLua = true;
				PlayState.instance.notes.members[id].alpha = alpha;
			});

			Lua_helper.add_callback(lua,"setRenderedNoteScale", function(scale:Float, id:Int) {
				PlayState.instance.notes.members[id].modifiedByLua = true;
				PlayState.instance.notes.members[id].setGraphicSize(Std.int(PlayState.instance.notes.members[id].width * scale));
			});

			Lua_helper.add_callback(lua,"setRenderedNoteScale", function(scaleX:Int, scaleY:Int, id:Int) {
				PlayState.instance.notes.members[id].modifiedByLua = true;
				PlayState.instance.notes.members[id].setGraphicSize(scaleX,scaleY);
			});

			Lua_helper.add_callback(lua,"getRenderedNoteWidth", function(id:Int) {
				return PlayState.instance.notes.members[id].width;
			});


			Lua_helper.add_callback(lua,"setRenderedNoteAngle", function(angle:Float, id:Int) {
				PlayState.instance.notes.members[id].modifiedByLua = true;
				PlayState.instance.notes.members[id].angle = angle;
			});

			Lua_helper.add_callback(lua,"setActorX", function(x:Int,id:String, ?bg:Bool = false) {
				var shit:Dynamic = getObjectDirectly2(id);
				shit.x = x;
			});
			
			Lua_helper.add_callback(lua,"setActorScreenCenter", function(id:String, ?pos:String = 'xy') {
				var shit:Dynamic = getObjectDirectly2(id);
				switch(pos.trim().toLowerCase())
				{
					case 'x': shit.screenCenter(X);	
					case 'y': shit.screenCenter(Y);	
					default: shit.screenCenter(XY);	
				}			
			});

			Lua_helper.add_callback(lua,"screenCenter", function(id:String, ?pos:String) { //same thing. just for psych
				var shit:Dynamic = getObjectDirectly2(id);
				switch(pos.trim().toLowerCase())
				{
					case 'x': shit.screenCenter(X);	
					case 'y': shit.screenCenter(Y);	
					default: shit.screenCenter(XY);	
				}					
			});

			Lua_helper.add_callback(lua,"setActorAccelerationX", function(x:Int,id:String) {
				getActorByName(id).acceleration.x = x;
			});
			
			Lua_helper.add_callback(lua,"setActorDragX", function(x:Int,id:String) {
				getActorByName(id).drag.x = x;
			});
			
			Lua_helper.add_callback(lua,"setActorVelocityX", function(x:Int,id:String, ?bg:Bool = false) {
				if (bg){
					Stage.instance.swagBacks[id].velocity.x = x;
				}
				else {
					getActorByName(id).velocity.x = x;
				}				
			});

			Lua_helper.add_callback(lua,"enablePurpleMiss", function(id:String,toggle:Bool) {
				getActorByName(id).doMissThing = toggle;
			});

			Lua_helper.add_callback(lua,"playBGAnimation", function(id:String,anim:String,force:Bool = false,reverse:Bool = false) {
				var shit:Dynamic = getObjectDirectly2(id);
				shit.animation.play(anim, force, reverse);
			});

			Lua_helper.add_callback(lua,"playBGAnimation2", function(id:String,anim:String,force:Bool = false,reverse:Bool = false) {
				getActorByName(id).animation.play(anim, force, reverse);
			});

			Lua_helper.add_callback(lua,"flickerActor", function (id:FlxObject, duration:Float, interval:Float) {
				FlxFlicker.flicker(id, duration, interval);
			});

			Lua_helper.add_callback(lua,"setActorAlpha", function(alpha:Float,id:String, ?bg:Bool = false) {
				if (bg){
					Stage.instance.swagBacks[id].alpha = alpha;
				}
				else {
					getActorByName(id).alpha = alpha;
				}
			});

			/*Lua_helper.add_callback(lua,"boomBoom", function(visible:Bool,id:String, id2:Int) {
				getActorByName(id).members[id2].visible = visible;
			});*/

			Lua_helper.add_callback(lua,"setActorVisibility", function(alpha:Bool,id:String, ?bg:Bool = false) {
				if (bg){
					Stage.instance.swagBacks[id].visible = alpha;
				}
				else {
					getActorByName(id).visible = alpha;
				}	
			});

			Lua_helper.add_callback(lua,"setActorY", function(y:Int,id:String, ?bg:Bool = false) {
				if (bg){
					Stage.instance.swagBacks[id].y = y;
				}
				else {
					getActorByName(id).y = y;
				}	
			});

			Lua_helper.add_callback(lua,"setActorAccelerationY", function(y:Int,id:String) {
				getActorByName(id).acceleration.y = y;
			});
			
			Lua_helper.add_callback(lua,"setActorDragY", function(y:Int,id:String) {
				getActorByName(id).drag.y = y;
			});
			
			Lua_helper.add_callback(lua,"setActorVelocityY", function(y:Int,id:String) {
				getActorByName(id).velocity.y = y;
			});
			
			Lua_helper.add_callback(lua,"setActorAngle", function(angle:Int,id:String) {
				getActorByName(id).angle = angle;
			});

			Lua_helper.add_callback(lua,"setGraphicSize", function(id:String, x:Float) {
				Stage.instance.setGraphicSize(id, x);
			});

			Lua_helper.add_callback(lua,"stopGFDance", function(stop:Bool) {
				PlayState.instance.picoCutscene = stop;
			});

			Lua_helper.add_callback(lua,"isPixel", function(change:Bool) {
				PlayState.isPixel = change;
			});

			Lua_helper.add_callback(lua, "setActorFlipX", function(flip:Bool, id:String)
			{
				getActorByName(id).flipX = flip;
			});
			

			Lua_helper.add_callback(lua, "setActorFlipY", function(flip:Bool, id:String)
			{
				getActorByName(id).flipY = flip;
			});

			Lua_helper.add_callback(lua,"getActorWidth", function (id:String) {
				return getActorByName(id).width;
			});

			Lua_helper.add_callback(lua,"getActorHeight", function (id:String) {
				return getActorByName(id).height;
			});

			Lua_helper.add_callback(lua,"getActorAlpha", function(id:String) {
				return getActorByName(id).alpha;
			});

			Lua_helper.add_callback(lua,"getActorAngle", function(id:String) {
				return getActorByName(id).angle;
			});

			Lua_helper.add_callback(lua,"getActorX", function (id:String, ?bg:Bool = false) {
				if (bg)
					return Stage.instance.swagBacks[id].x;
				else
					return getActorByName(id).x;
			});

			Lua_helper.add_callback(lua,"getCameraZoom", function (id:String) {
				return PlayState.instance.defaultCamZoom;
			});

			Lua_helper.add_callback(lua,"getActorY", function (id:String, ?bg:Bool = false) {
				if (bg)
					return Stage.instance.swagBacks[id].y;
				else
					return getActorByName(id).y;
			});

			Lua_helper.add_callback(lua,"getActorXMidpoint", function (id:String, ?graphic:Bool = false) {
				if (graphic)
					return getActorByName(id).getGraphicMidpoint().x;

				return getActorByName(id).getMidpoint().x;
			});

			Lua_helper.add_callback(lua,"getActorYMidpoint", function (id:String, ?graphic:Bool = false) {
				if (graphic)
					return getActorByName(id).getGraphicMidpoint().y;

				return getActorByName(id).getMidpoint().y;
			});
			
			Lua_helper.add_callback(lua, "getMidpointX", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				var obj:FlxSprite = getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}
				if(obj != null) return obj.getMidpoint().x;

				return 0;
			});
			Lua_helper.add_callback(lua, "getMidpointY", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				var obj:FlxSprite = getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}
				if(obj != null) return obj.getMidpoint().y;

				return 0;
			});
			Lua_helper.add_callback(lua, "getGraphicMidpointX", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				var obj:FlxSprite = getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}
				if(obj != null) return obj.getGraphicMidpoint().x;

				return 0;
			});
			Lua_helper.add_callback(lua, "getGraphicMidpointY", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				var obj:FlxSprite = getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}
				if(obj != null) return obj.getGraphicMidpoint().y;

				return 0;
			});

			Lua_helper.add_callback(lua, "getMouseX", function(camera:String) {
				var cam:FlxCamera = cameraFromString(camera);
				return FlxG.mouse.getScreenPosition(cam).x;
			});
			Lua_helper.add_callback(lua, "getMouseY", function(camera:String) {
				var cam:FlxCamera = cameraFromString(camera);
				return FlxG.mouse.getScreenPosition(cam).y;
			});

			Lua_helper.add_callback(lua,"setWindowPos",function(x:Int,y:Int) {
				Application.current.window.x = x;
				Application.current.window.y = y;
			});

			Lua_helper.add_callback(lua,"getWindowX",function() {
				return Application.current.window.x;
			});

			Lua_helper.add_callback(lua,"getWindowY",function() {
				return Application.current.window.y;
			});

			Lua_helper.add_callback(lua,"resizeWindow",function(Width:Int,Height:Int) {
				Application.current.window.resize(Width,Height);
			});
			
			Lua_helper.add_callback(lua,"getScreenWidth",function() {
				return Application.current.window.display.currentMode.width;
			});

			Lua_helper.add_callback(lua,"getScreenHeight",function() {
				return Application.current.window.display.currentMode.height;
			});

			Lua_helper.add_callback(lua,"getWindowWidth",function() {
				return Application.current.window.width;
			});

			Lua_helper.add_callback(lua,"getWindowHeight",function() {
				return Application.current.window.height;
			});


			// tweens
			
			Lua_helper.add_callback(lua,"tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});
							
			Lua_helper.add_callback(lua,"tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String) {
				FlxTween.tween(FlxG.camera, {zoom:toZoom}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});
							
			Lua_helper.add_callback(lua,"tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(PlayState.instance.camHUD, {angle:toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String) {
				FlxTween.tween(PlayState.instance.camHUD, {zoom:toZoom}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPos", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPosQuad", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.quadInOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenCameraPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});
							
			Lua_helper.add_callback(lua,"tweenCameraAngleOut", function(toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenCameraZoomOut", function(toZoom:Float, time:Float, ease:String, onComplete:String) {
				FlxTween.tween(FlxG.camera, {zoom:toZoom}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenHudPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});
							
			Lua_helper.add_callback(lua,"tweenHudAngleOut", function(toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(PlayState.instance.camHUD, {angle:toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenHudZoomOut", function(toZoom:Float, time:Float, onComplete:String) {
				FlxTween.tween(PlayState.instance.camHUD, {zoom:toZoom}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPosOut", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPosXAngleOut", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPosYAngleOut", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenAngleOut", function(id:String, toAngle:Int, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenCameraPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});
							
			Lua_helper.add_callback(lua,"tweenCameraAngleIn", function(toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenCameraZoomIn", function(toZoom:Float, time:Float, ease:String, onComplete:String) {
				FlxTween.tween(FlxG.camera, {zoom:toZoom}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenHudPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});
							
			Lua_helper.add_callback(lua,"tweenHudAngleIn", function(toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(PlayState.instance.camHUD, {angle:toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenHudZoomIn", function(toZoom:Float, time:Float, onComplete:String) {
				FlxTween.tween(PlayState.instance.camHUD, {zoom:toZoom}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,["camera"]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPosIn", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPosXAngleIn", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenPosYAngleIn", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenAngleIn", function(id:String, toAngle:Int, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenFadeIn", function(id:String, toAlpha:Float, time:Float, onComplete:String) {
				FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {ease: FlxEase.circIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenFadeInBG", function(id:String, toAlpha:Float, time:Float, onComplete:String) {
				FlxTween.tween(Stage.instance.swagBacks[id], {alpha: toAlpha}, time, {ease: FlxEase.circIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenFadeOut", function(id:String, toAlpha:Float, time:Float, ease:String, onComplete:String) {
				FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenFadeOutBG", function(id:String, toAlpha:Float, time:Float, onComplete:String) {
				FlxTween.tween(Stage.instance.swagBacks[id], {alpha: toAlpha}, time, {ease: FlxEase.circOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenFadeOutOneShot", function(id:String, toAlpha:Float, time:Float) {
				FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {type: FlxTweenType.ONESHOT});
			});

			//I actually use this one so I'll give it the extra psych stuff 
			Lua_helper.add_callback(lua,"tweenColor", function(vars:String, duration:Float, initColor:FlxColor, finalColor:FlxColor, ?tag:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}

				if (tag == null){tag = vars+'TweenCol';}
				var penisExam:Dynamic = tweenShit(tag, vars);
				if(penisExam != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration, initColor, finalColor, {
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);

							if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
								PlayState.instance.Stage.callOnLuas('onTweenCompleted', [tag]);

							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else {
					luaTrace('tweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});

			//and then one that's more akin to psych which has tags first as to not mess up the original
			Lua_helper.add_callback(lua,"doTweenColor2", function(tag:String, vars:String, duration:Float, initColor:FlxColor, finalColor:FlxColor) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				var penisExam:Dynamic = tweenShit(tag, vars);
				if(penisExam != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration, initColor, finalColor, {
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);

							if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
								PlayState.instance.Stage.callOnLuas('onTweenCompleted', [tag]);

							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else {
					luaTrace('doTweenColor2: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});

			Lua_helper.add_callback(lua, "RGBColor", function (r:Int,g:Int,b:Int, alpha:Int = 255) {
				return FlxColor.fromRGB(r, g, b, alpha);
			});

			Lua_helper.add_callback(lua,"changeHue", function(id:String, hue:Int) {
				var newShader:ColorSwap = new ColorSwap();
				getObjectDirectly2(id).shader = newShader.shader;
				newShader.hue = hue / 360;
			});

			//change as a group. you should probably use this one
			Lua_helper.add_callback(lua,"changeHSB", function(id:String, hue:Int, sat:Int, bright:Int) {
				var newShader:ColorSwap = new ColorSwap();
				newShader.hue = hue / 360;
				newShader.saturation = sat / 100;
				newShader.brightness = bright / 100;

				var shit:Dynamic = getObjectDirectly2(id);

				if (shit != null)
					shit.shader = newShader.shader;
			});

			Lua_helper.add_callback(lua,"updateHealthbar", function(dadColor:String = "", bfColor:String = ""){
				var opponent:String;
				var player:String;

				if (dadColor == "")
					opponent = PlayState.instance.dad.iconColor;
				else
					opponent = dadColor;

				if (bfColor == "")
					player = PlayState.instance.boyfriend.iconColor;
				else
					player = bfColor;

				PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + opponent), FlxColor.fromString('#' + player));
				PlayState.instance.healthBar.updateBar();
			});

			Lua_helper.add_callback(lua,"returnDominantColor", function(sprite:String, ?remove0:Bool = false){
				var shit:Dynamic = getObjectDirectly2(sprite);

				var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(shit));
				var daColor = coolColor.toHexString();

				if (remove0)
					daColor = daColor.substring(2);

				return daColor;
			});


			//a bunch of psych stuff
			Lua_helper.add_callback(lua,"tweenAnglePsych", function(id:String, toAngle:Int, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
				var shit:Dynamic = getObjectDirectly2(id);
				FlxTween.tween(shit, {angle: toAngle}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenXPsych", function(id:String, toX:Int, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
				var shit:Dynamic = getObjectDirectly2(id);
				FlxTween.tween(shit, {x: toX}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenYPsych", function(id:String, toY:Int, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
				var shit:Dynamic = getObjectDirectly2(id);
				FlxTween.tween(shit, {y: toY}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenZoomPsych", function(id:String, toZoom:Int, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
				var shit:Dynamic = getObjectDirectly2(id);
				FlxTween.tween(shit, {zoom: toZoom}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenScale", function(id:String, scale:Float, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
				var shit:Dynamic = getObjectDirectly2(id);
				FlxTween.tween(shit, {"scale.x": scale, "scale.y": scale}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});			
			});

			Lua_helper.add_callback(lua,"tweenScaleXY", function(id:String, scaleX:Float, scaleY:Float, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
				var shit:Dynamic = getObjectDirectly2(id);
				FlxTween.tween(shit, {"scale.x": scaleX, "scale.y": scaleY}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua,"tweenAlpha", function(id:String, toAlpha:Float, time:Float, ease:String, onComplete:String) {
				var shit:Dynamic = getObjectDirectly2(id);
				FlxTween.tween(shit, {alpha: toAlpha}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
			});

			Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float, ?updateHitbox:Bool = true) {
				if(Stage.instance.swagBacks.exists(obj)) {
					var shit:ModchartSprite = Stage.instance.swagBacks.get(obj);
					shit.scale.set(x * (FlxG.save.data.poltatoPC ? 2 : 1), y * (FlxG.save.data.poltatoPC ? 2 : 1));
					if(updateHitbox)shit.updateHitbox();
					return;
				}
					
				if(PlayState.instance.Stage.swagBacks.exists(obj)) {
					var shit:ModchartSprite = Stage.instance.swagBacks.get(obj);
					shit.scale.set(x * (FlxG.save.data.poltatoPC ? 2 : 1), y * (FlxG.save.data.poltatoPC ? 2 : 1));
					if(updateHitbox)shit.updateHitbox();
					return;
				}

				if(PlayState.instance.getLuaObject(obj)!=null) {
					var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
					shit.scale.set(x * (FlxG.save.data.poltatoPC ? 2 : 1), y * (FlxG.save.data.poltatoPC ? 2 : 1));
					if(updateHitbox) shit.updateHitbox();
					return;
				}

				var killMe:Array<String> = obj.split('.');
				var poop:FlxSprite = getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					poop = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				if(poop != null) {
					poop.scale.set(x * (FlxG.save.data.poltatoPC ? 2 : 1), y * (FlxG.save.data.poltatoPC ? 2 : 1));
					if(updateHitbox) poop.updateHitbox();
					return;
				}
				luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
			});

			Lua_helper.add_callback(lua, "getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
				var excludeArray:Array<String> = exclude.split(',');
				var toExclude:Array<Int> = [];
				for (i in 0...excludeArray.length)
				{
					toExclude.push(Std.parseInt(excludeArray[i].trim()));
				}
				return FlxG.random.int(min, max, toExclude);
			});
			Lua_helper.add_callback(lua, "getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
				var excludeArray:Array<String> = exclude.split(',');
				var toExclude:Array<Float> = [];
				for (i in 0...excludeArray.length)
				{
					toExclude.push(Std.parseFloat(excludeArray[i].trim()));
				}
				return FlxG.random.float(min, max, toExclude);
			});
			Lua_helper.add_callback(lua, "getRandomBool", function(chance:Float = 50) {
				return FlxG.random.bool(chance);
			});

			Lua_helper.add_callback(lua, "setBlendMode", function(obj:String, blend:String = '') {
				var shit:Dynamic = getObjectDirectly2(obj);
				if(shit != null) {
					shit.blend = blendModeFromString(blend);
					return true;
				}
				luaTrace("setBlendMode: Object " + obj + " doesn't exist!");
				return false;
			});

			//tweenShit works here so go with it.
			Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				var penisExam:Dynamic = tweenShit(tag, vars);
				if(penisExam != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							
							if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
								PlayState.instance.Stage.callOnLuas('onTweenCompleted', [tag]);
							
							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else {
					luaTrace('doTweenX: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});
			Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				var penisExam:Dynamic = tweenShit(tag, vars);
				if(penisExam != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							
							if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
								PlayState.instance.Stage.callOnLuas('onTweenCompleted', [tag]);

							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else {
					luaTrace('doTweenY: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});
			Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				var penisExam:Dynamic = tweenShit(tag, vars);
				if(penisExam != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {angle: value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							
							if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
								PlayState.instance.Stage.callOnLuas('onTweenCompleted', [tag]);

							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else {
					luaTrace('doTweenAngle: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});

			Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				var penisExam:Dynamic = tweenShit(tag, vars);
				if(penisExam != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else {
					luaTrace('doTweenAlpha: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});
			Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				var penisExam:Dynamic = tweenShit(tag, vars);
				if(penisExam != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {zoom: value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else {
					luaTrace('doTweenZoom: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});
			Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				var penisExam:Dynamic = tweenShit(tag, vars);
				if(penisExam != null) {
					if (Std.isOfType(penisExam, Character))
					{
						var killMe:Array<String> = [vars, 'doMissThing'];
						if(killMe.length > 1) {
							var coverMeInPiss:Dynamic = Reflect.getProperty(getInstance(), killMe[0]);
							for (i in 1...killMe.length-1) {
								coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
							}
							Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], 'false');
						}
					}

					var color:Int = Std.parseInt(targetColor);
					if(!targetColor.startsWith('0x')) color = Std.parseInt('0xff' + targetColor);

					var curColor:FlxColor = penisExam.color;
					curColor.alphaFloat = penisExam.alpha;
					PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, color, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.modchartTweens.remove(tag);
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						}
					}));
				} else {
					luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});

			Lua_helper.add_callback(lua, "doTweenScaleX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				var penisExam:Dynamic = getObjectDirectly2(vars);
				cancelTween(tag);
				if(penisExam != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {"scale.x": value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);

							if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
								PlayState.instance.Stage.callOnLuas('onTweenCompleted', [tag]);
							
							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else {
					luaTrace('doTweenScaleX: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});

			Lua_helper.add_callback(lua, "doTweenScaleY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				var penisExam:Dynamic = getObjectDirectly2(vars);
				cancelTween(tag);
				if(penisExam != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {"scale.y": value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);

							if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
								PlayState.instance.Stage.callOnLuas('onTweenCompleted', [tag]);

							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				} else {
					luaTrace('doTweenScaleY: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});


			Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic) {
				var value1:String = arg1;
				var value2:String = arg2;
				PlayState.instance.triggerEventNote(name, value1, value2);
			});

			Lua_helper.add_callback(lua, "getPropertyPsych", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) 
				{
					var coverMeInPiss:Dynamic = null;
					if(PlayState.instance.modchartSprites.exists(killMe[0]))
						coverMeInPiss = PlayState.instance.modchartSprites.get(killMe[0]);
					else if(PlayState.instance.modchartIcons.exists(killMe[0]))
						coverMeInPiss = PlayState.instance.modchartIcons.get(killMe[0]);
					else if(PlayState.instance.modchartCharacters.exists(killMe[0]))
						coverMeInPiss = PlayState.instance.modchartCharacters.get(killMe[0]);
					else if(PlayState.instance.Stage.swagBacks.exists(killMe[0]))
						coverMeInPiss = PlayState.instance.Stage.swagBacks.get(killMe[0]);
					else
						coverMeInPiss = Reflect.getProperty(getInstance(), killMe[0]);

					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
				}
				return Reflect.getProperty(getInstance(), variable);
			});

			Lua_helper.add_callback(lua, "setPropertyPsych", function(variable:String, value:Dynamic) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = null;
					if(PlayState.instance.modchartSprites.exists(killMe[0]))
						coverMeInPiss = PlayState.instance.modchartSprites.get(killMe[0]);
					else if(PlayState.instance.modchartIcons.exists(killMe[0]))
						coverMeInPiss = PlayState.instance.modchartIcons.get(killMe[0]);
					else if(PlayState.instance.modchartCharacters.exists(killMe[0]))
						coverMeInPiss = PlayState.instance.modchartCharacters.get(killMe[0]);
					else if(PlayState.instance.Stage.swagBacks.exists(killMe[0]))
						coverMeInPiss = PlayState.instance.Stage.swagBacks.get(killMe[0]);
					else
						coverMeInPiss = Reflect.getProperty(getInstance(), killMe[0]);

					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
				}
				return Reflect.setProperty(getInstance(), variable, value);
			});

			Lua_helper.add_callback(lua, "debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
				if (text1 == null) text1 = '';
				if (text2 == null) text2 = '';
				if (text3 == null) text3 = '';
				if (text4 == null) text4 = '';
				if (text5 == null) text5 = '';
				luaTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
			});

			Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, camera:String = '', ?index:Int = null) {
				var real = PlayState.instance.getLuaObject(obj);
				if(real!=null){
					real.cameras = [cameraFromString(camera)];
					return true;
				}

				if (Stage.instance.swagBacks.exists(obj)) //LET'S GOOOOO IT WORKSS!!!!!!
				{
					var real:FlxSprite = changeSpriteClass(Stage.instance.swagBacks.get(obj));

					if(real!=null){
						real.cameras = [cameraFromString(camera)];
						return true;
					}
				}

				var killMe:Array<String> = obj.split('.');
				var object:FlxSprite = changeSpriteClass(getObjectDirectly(killMe[0]));
				if(killMe.length > 1) {
					object = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				if(object != null) {
					object.cameras = [cameraFromString(camera)];
					return true;
				}
				luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return false;
			});

			Lua_helper.add_callback(lua, "keyJustPressed", function(name:String) {
				var key:Bool = false;
				switch(name) {
					case 'left': key = PlayState.instance.getControl('LEFT_P');
					case 'down': key = PlayState.instance.getControl('DOWN_P');
					case 'up': key = PlayState.instance.getControl('UP_P');
					case 'right': key = PlayState.instance.getControl('RIGHT_P');
					case 'accept': key = PlayState.instance.getControl('ACCEPT');
					case 'back': key = PlayState.instance.getControl('BACK');
					case 'pause': key = PlayState.instance.getControl('PAUSE');
					case 'reset': key = PlayState.instance.getControl('RESET');
					case 'space': key = FlxG.keys.justPressed.SPACE;//an extra key for convinience
				}
				return key;
			});

			Lua_helper.add_callback(lua, "keyPressed", function(name:String) {
				var key:Bool = false;
				switch(name) {
					case 'left': key = PlayState.instance.getControl('LEFT');
					case 'down': key = PlayState.instance.getControl('DOWN');
					case 'up': key = PlayState.instance.getControl('UP');
					case 'right': key = PlayState.instance.getControl('RIGHT');
					case 'space': key = FlxG.keys.pressed.SPACE;//an extra key for convinience
				}
				return key;
			});
			
			Lua_helper.add_callback(lua, "keyReleased", function(name:String) {
				var key:Bool = false;
				switch(name) {
					case 'left': key = PlayState.instance.getControl('LEFT_R');
					case 'down': key = PlayState.instance.getControl('DOWN_R');
					case 'up': key = PlayState.instance.getControl('UP_R');
					case 'right': key = PlayState.instance.getControl('RIGHT_R');
					case 'space': key = FlxG.keys.justReleased.SPACE;//an extra key for convinience
				}
				return key;
			});

			Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
				if (PlayState.instance != null){time = time / PlayState.instance.playbackRate;}
				cancelTimer(tag);
				PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
					if(tmr.finished) {
						PlayState.instance.modchartTimers.remove(tag);
					}
					PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);

					if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
						PlayState.instance.Stage.callOnLuas('onTimerCompleted', [tag]);
					//trace('Timer Completed: ' + tag);
				}, loops));
			});
			
			Lua_helper.add_callback(lua, "cancelTimer", function(tag:String) {
				cancelTimer(tag);
			});

			Lua_helper.add_callback(lua,"getMapLength", function(obj:String) {
				var killMe:Array<String> = obj.split('.');
				var shit:Map<String, Dynamic> = Reflect.getProperty(getInstance(), obj);

				if(killMe.length > 1)
				{
					shit = Reflect.getProperty(Type.resolveClass(killMe[0]), killMe[1]);

					if (shit == null)
						shit = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}
		
				var daArray:Array<String> = [];

				for (key in shit.keys())
					daArray.push(key);
				
				return daArray.length;
			});

			Lua_helper.add_callback(lua,"getMapKeys", function(obj:String, ?getValue:Bool = false) {
				var killMe:Array<String> = obj.split('.');
				var shit:Map<String, Dynamic> = Reflect.getProperty(getInstance(), obj);

				if(killMe.length > 1)
				{
					shit = Reflect.getProperty(Type.resolveClass(killMe[0]), killMe[1]);

					if (shit == null)
						shit = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
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
				var shit:Map<String, Dynamic> = Reflect.getProperty(getInstance(), obj);

				if(killMe.length > 1)
				{
					shit = Reflect.getProperty(Type.resolveClass(killMe[0]), killMe[1]);

					if (shit == null)
						shit = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				return shit[valName];
			});

			Lua_helper.add_callback(lua,"setMapKey", function(obj:String, valName:String, val:Dynamic) {
				var killMe:Array<String> = obj.split('.');
				var shit:Map<String, Dynamic> = Reflect.getProperty(getInstance(), obj);

				if(killMe.length > 1)
				{
					shit = Reflect.getProperty(Type.resolveClass(killMe[0]), killMe[1]);

					if (shit == null)
						shit = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				shit[valName] = val;
			});

			Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String) {
				var charType:Int = 0;
				switch(type.toLowerCase()) {
					case 'dad': charType = 1;
					case 'gf' | 'girlfriend': charType = 2;
				}
				PlayState.preloadChar = new Character(0, 0, name);
			});

			Lua_helper.add_callback(lua, "startCharLua", function(name:String) {
				PlayState.instance.startCharacterLua(name);
			});


			Lua_helper.add_callback(lua, "cacheImage", function(name:String) {
				Paths.cacheImage(name);
			});

			Lua_helper.add_callback(lua, "precacheSound", function(name:String) {
				return name; //lol
			});

			Lua_helper.add_callback(lua, "precacheImage", function(name:String) {
				return name; //lol
			});

			Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String, ?gridX:Int, ?gridY:Int) {
				var killMe:Array<String> = variable.split('.');
				var spr:FlxSprite = getObjectDirectly(killMe[0]);
				var gX = gridX==null?0:gridX;
				var gY = gridY==null?0:gridY;
				var animated = gX!=0 || gY!=0;

				if(killMe.length > 1) {
					spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				if(spr != null && image != null && image.length > 0)
				{
					spr.loadGraphic(Paths.image(image), animated, gX, gY);
				}
			});
			Lua_helper.add_callback(lua, "loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
				var killMe:Array<String> = variable.split('.');
				var spr:FlxSprite = getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				if(spr != null && image != null && image.length > 0)
				{
					loadFrames(spr, image, spriteType);
				}
			});

			Lua_helper.add_callback(lua, "getProperty", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				
				if (Stage.instance.swagBacks.exists(killMe[0])){
					return Stage.instance.getProperty(variable);
				}

				if(killMe.length > 1) {
					return getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}
				return getVarInArray(getInstance(), variable);
			});

			Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic) {			
				var killMe:Array<String> = variable.split('.');

				if (variable.contains('velocity.')){
					if (PlayState.instance != null){value *= PlayState.instance.playbackRate;}
				}
			
				if (Stage.instance.swagBacks.exists(killMe[0]))
				{
					Stage.instance.setProperty(variable, value);
					return true;
				}
					
				if(killMe.length > 1) {
					if (Std.isOfType(getObjectDirectly2(killMe[0]), Character) && killMe[killMe.length-1] == 'color')
					{
						var killMeh:Array<String> = [killMe[0], 'doMissThing'];
						if(killMeh.length > 1) {
							var coverMeInPiss:Dynamic = Reflect.getProperty(getInstance(), killMeh[0]);
							for (i in 1...killMeh.length-1) {
								coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMeh[i]);
							}
							Reflect.setProperty(coverMeInPiss, killMeh[killMeh.length-1], 'false');
						}
					}

					setVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1], value);
					return true;
				}
				setVarInArray(getInstance(), variable, value);
				return true;
			});

			Lua_helper.add_callback(lua, "getPropertyFromClass", function(classVar:String, variable:String) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
				}
				return Reflect.getProperty(Type.resolveClass(classVar), variable);
			});
			Lua_helper.add_callback(lua, "setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
				}
				return Reflect.setProperty(Type.resolveClass(classVar), variable, value);
			});

			Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
				var shitMyPants:Array<String> = obj.split('.');
				var realObject:Dynamic = Reflect.getProperty(getInstance(), obj);
				if(shitMyPants.length>1)
					realObject = getPropertyLoopThingWhatever(shitMyPants, true, false);


				if(Std.isOfType(realObject, FlxTypedGroup))
				{
					var result:Dynamic = getGroupStuff(realObject.members[index], variable);

					if(PlayState.instance.Stage.swagGroup.exists(obj)) 
						result = PlayState.instance.Stage.swagGroup.get(obj);

					if(result == null) Lua.pushnil(lua);
					return result;
				}


				var leArray:Dynamic = realObject;

				if(Std.isOfType(leArray, Array))
					leArray = realObject[index]; //because it's Array<Note>
				
				if(leArray != null) {
					var result:Dynamic = null;
					if(Type.typeof(variable) == ValueType.TInt)
						result = realObject[variable];
					else
						result = getGroupStuff(leArray, variable);

					if(result == null) Lua.pushnil(lua);
					return result;
				}
				luaTrace("Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
				Lua.pushnil(lua);
				return null;
			});

			Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
				var shitMyPants:Array<String> = obj.split('.');
				var realObject:Dynamic = Reflect.getProperty(getInstance(), obj);
				
				if(shitMyPants.length>1)
					realObject = getPropertyLoopThingWhatever(shitMyPants, true, false);

				if(Std.isOfType(realObject, FlxTypedGroup)) {
					if(PlayState.instance.Stage.swagGroup.exists(obj)) 
						realObject = PlayState.instance.Stage.swagGroup.get(obj);

					setGroupStuff(realObject.members[index], variable, value);
					return;
				}

				var leArray:Dynamic = realObject;

				if(Std.isOfType(leArray, Array))
					leArray = realObject[index];

				if(leArray != null) {
					if(Type.typeof(variable) == ValueType.TInt) {
						realObject[variable] = value;
						return;
					}
					setGroupStuff(leArray, variable, value);
				}
			});

			// LUA TEXTS
			Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
				trace('making text');
				tag = tag.replace('.', '');
				
				resetTextTag(tag);
				trace('making text 2');
				var leText:ModchartText = new ModchartText(x, y, text, width);
				PlayState.instance.modchartTexts.set(tag, leText);
				trace('made text');
			});

			Lua_helper.add_callback(lua, "setTextString", function(tag:String, text:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.text = text;
				}
			});
			Lua_helper.add_callback(lua, "setTextSize", function(tag:String, size:Int) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.size = size;
				}
			});
			Lua_helper.add_callback(lua, "setTextWidth", function(tag:String, width:Float) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.fieldWidth = width;
				}
			});
			Lua_helper.add_callback(lua, "setTextBorder", function(tag:String, size:Int, color:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					var colorNum:Int = Std.parseInt(color);
					if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

					obj.borderSize = size;
					obj.borderColor = colorNum;
				}
			});
			Lua_helper.add_callback(lua, "setTextColor", function(tag:String, color:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					var colorNum:Int = Std.parseInt(color);
					if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

					obj.color = colorNum;
				}
			});
			Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.font = Paths.font(newFont);
				}
			});
			Lua_helper.add_callback(lua, "setTextItalic", function(tag:String, italic:Bool) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.italic = italic;
				}
			});
			Lua_helper.add_callback(lua, "setTextAlignment", function(tag:String, alignment:String = 'left') {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.alignment = LEFT;
					switch(alignment.trim().toLowerCase())
					{
						case 'right':
							obj.alignment = RIGHT;
						case 'center':
							obj.alignment = CENTER;
					}
				}
			});

			Lua_helper.add_callback(lua, "getTextString", function(tag:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					return obj.text;
				}
				return null;
			});
			Lua_helper.add_callback(lua, "getTextSize", function(tag:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					return obj.size;
				}
				return -1;
			});
			Lua_helper.add_callback(lua, "getTextFont", function(tag:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					return obj.font;
				}
				return null;
			});
			Lua_helper.add_callback(lua, "getTextWidth", function(tag:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					return obj.fieldWidth;
				}
				return 0;
			});

			Lua_helper.add_callback(lua, "addLuaText", function(tag:String) {
				if(PlayState.instance.modchartTexts.exists(tag)) {
					var shit:ModchartText = PlayState.instance.modchartTexts.get(tag);
					if(!shit.wasAdded) {
						getInstance().add(shit);
						shit.wasAdded = true;
						//trace('added a thing: ' + tag);
					}
				}
			});
			Lua_helper.add_callback(lua, "removeLuaText", function(tag:String, destroy:Bool = true) {
				if(!PlayState.instance.modchartTexts.exists(tag)) {
					return;
				}
				
				var pee:ModchartText = PlayState.instance.modchartTexts.get(tag);
				if(destroy) {
					pee.kill();
				}

				if(pee.wasAdded) {
					getInstance().remove(pee, true);
					pee.wasAdded = false;
				}

				if(destroy) {
					pee.destroy();
					PlayState.instance.modchartTexts.remove(tag);
				}
			});

			Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
				tag = tag.replace('.', '');
				resetSpriteTag(tag);
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
				if(image != null && image.length > 0) {

					var rawPic:Dynamic;

					if (!Paths.currentTrackedAssets.exists(image))
						Paths.cacheImage(image);

					rawPic = Paths.currentTrackedAssets.get(image);

					leSprite.loadGraphic(rawPic);		
					
					if (FlxG.save.data.poltatoPC)
					{
						leSprite.scale.set(2, 2);
						leSprite.updateHitbox();
					}
				}
				leSprite.antialiasing = antialiasing;

				if (!preloading)
					Stage.instance.swagBacks.set(tag, leSprite);
			});

			Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float,spriteType:String="sparrow") {
				tag = tag.replace('.', '');
				resetSpriteTag(tag);
				var leSprite:ModchartSprite = new ModchartSprite(x, y);

				loadFrames(leSprite, image, spriteType);
				leSprite.antialiasing = true;

				if (!preloading){
					Stage.instance.swagBacks.set(tag, leSprite);
				}
			});

			Lua_helper.add_callback(lua, "makeLuaBackdrop", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
				tag = tag.replace('.', '');
				//resetSpriteTag(tag);
				var leSprite:FlxBackdrop = null;
				
				if(image != null && image.length > 0) {

					var rawPic:Dynamic;

					if (!Paths.currentTrackedAssets.exists(image))
						Paths.cacheImage(image);

					rawPic = Paths.currentTrackedAssets.get(image);	
					
					leSprite = new FlxBackdrop(rawPic, x, y);
				}

				if (leSprite == null)
					return;

				leSprite.antialiasing = antialiasing;
				leSprite.active = true;

				if (!preloading)
					Stage.instance.swagBacks.set(tag, leSprite);
			});


			Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int, height:Int, color:String) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				if(Stage.instance.swagBacks.exists(obj)) {
					Stage.instance.swagBacks.get(obj).makeGraphic(width, height, colorNum);
					return;
				}

				var object:FlxSprite = Reflect.getProperty(getInstance(), obj);
				if(object != null) {
					object.makeGraphic(width, height, colorNum);
				}
			});

			Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
				if(Stage.instance.swagBacks.exists(obj)) {
					var cock:FlxSprite = Stage.instance.swagBacks.get(obj);
					cock.animation.addByPrefix(name, prefix, framerate, loop);
					if(cock.animation.curAnim == null) {
						cock.animation.play(name, true);
					}
					return;
				}

				if(getObjectDirectly(obj)!=null) {
					var cock:FlxSprite = getObjectDirectly(obj);
					cock.animation.addByPrefix(name, prefix, framerate, loop);
					if(cock.animation.curAnim == null) {
						cock.animation.play(name, true);
					}
					return;
				}

				var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
				if(cock != null) {
					cock.animation.addByPrefix(name, prefix, framerate, loop);
					if(cock.animation.curAnim == null) {
						cock.animation.play(name, true);
					}
				}
			});
			Lua_helper.add_callback(lua, "addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
				return addAnimByIndices(obj, name, prefix, indices, framerate, false);
			});
			Lua_helper.add_callback(lua, "addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
				return addAnimByIndices(obj, name, prefix, indices, framerate, true);
			});

			Lua_helper.add_callback(lua, "addAnimation", function(obj:String, name:String, indices:String, framerate:Int = 24, loop:Bool = true) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}

				if(Stage.instance.swagBacks.exists(obj)) {
					var cock:ModchartSprite = Stage.instance.swagBacks.get(obj);
					cock.animation.add(name, die, framerate, loop);
					if(cock.animation.curAnim == null) {
						cock.animation.play(name, true);
					}
					return;
				}
				
				var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
				if(cock != null) {
					cock.animation.add(name, die, framerate, loop);
					if(cock.animation.curAnim == null) {
						cock.animation.play(name, true);
					}
				}
			});

			Lua_helper.add_callback(lua, "objectPlayAnimation", function(obj:String, name:String, forced:Bool = false) {
				var spr:Dynamic = getObjectDirectly2(obj);
				if(spr != null) {
					spr.animation.play(name, forced);
				}
			});

			Lua_helper.add_callback(lua, "playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
			{
				if(getObjectDirectly(obj) != null) {
					var luaObj:FlxSprite = getObjectDirectly(obj);
					if(luaObj.animation.getByName(name) != null)
					{
						luaObj.animation.play(name, forced, reverse, startFrame);
						if(Std.isOfType(luaObj, ModchartSprite))
						{
							//convert luaObj to ModchartSprite
							var obj:Dynamic = luaObj;
							var luaObj:ModchartSprite = obj;

							var daOffset = luaObj.animOffsets.get(name);
							if (luaObj.animOffsets.exists(name))
							{
								luaObj.offset.set(daOffset[0], daOffset[1]);
							}
							else
								luaObj.offset.set(0, 0);
						}
						if(Std.isOfType(luaObj, Character))
						{
							//convert luaObj to Character
							var obj:Dynamic = luaObj;
							var luaObj:Character = obj;
							luaObj.playAnim(name, forced, reverse, startFrame);
						}
					}
					return true;
				}

				var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
				if(spr != null) {
					if(spr.animation.getByName(name) != null)
					{
						if(Std.isOfType(spr, Character))
						{
							//convert spr to Character
							var obj:Dynamic = spr;
							var spr:Character = obj;
							spr.playAnim(name, forced, reverse, startFrame);
						}
						else
							spr.animation.play(name, forced, reverse, startFrame);
					}
					return true;
				}
				return false;
			});

			//the better version
			Lua_helper.add_callback(lua, "addOffset", function(obj:String, anim:String, x:Float, y:Float) {
				if(PlayState.instance.modchartSprites.exists(obj)) {
					PlayState.instance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
					return true;
				}

				var mChar:Character = PlayState.instance.modchartCharacters.get(obj);
				if(mChar != null) {
					mChar.addOffset(anim, x, y);
					return true;
				}

				var char:Character = Reflect.getProperty(getInstance(), obj);
				if(char != null) {
					char.addOffset(anim, x, y);
					return true;
				}
				return false;
			});

			Lua_helper.add_callback(lua, "addClipRect", function(obj:String, x:Float, y:Float, width:Float, height:Float) {
				var swagRect = new FlxRect(x, y, width, height);

				var killMe:Array<String> = obj.split('.');
				var object:FlxSprite = getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					object = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				if(object != null) {
					object.clipRect = swagRect;
					return true;
				}
				luaTrace("addClipRect: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return false;
			});


			Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, place:Dynamic = -1) {
				if (Stage.instance.swagBacks.exists(tag))
				{
					var shit = Stage.instance.swagBacks.get(tag);
		
					//if (!shit.wasAdded)
					//{
						if (place == -1 || place == false)
							Stage.instance.toAdd.push(shit);
						else
						{
							if (place == true){place = 2;}
							Stage.instance.layInFront[place].push(shit);
						}
					//	shit.wasAdded = true;
					//}
				}
			});

			Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true) {
				if(!PlayState.instance.modchartSprites.exists(tag) && !PlayState.instance.Stage.swagBacks.exists(tag)) {
					return;
				}
				
				var pee:Dynamic;

				if(PlayState.instance.Stage.swagBacks.exists(tag))
					pee = PlayState.instance.Stage.swagBacks.get(tag);
				else
					pee = PlayState.instance.modchartSprites.get(tag);
				

				if(destroy) {
					pee.kill();
				}

				if(pee.wasAdded) {
					getInstance().remove(pee, true);
					pee.wasAdded = false;
				}

				if(destroy) {
					pee.destroy();
					PlayState.instance.modchartSprites.remove(tag);
				}
			});

			// LUA TEXTS
			Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
				if (PlayState.instance != null)
					return;

				tag = tag.replace('.', '');
				resetTextTag(tag);
				var leText:ModchartText = new ModchartText(x, y, text, width);
				PlayState.instance.modchartTexts.set(tag, leText);
			});

			Lua_helper.add_callback(lua, "setTextString", function(tag:String, text:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.text = text;
				}
			});
			Lua_helper.add_callback(lua, "setTextSize", function(tag:String, size:Int) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.size = size;
				}
			});
			Lua_helper.add_callback(lua, "setTextWidth", function(tag:String, width:Float) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.fieldWidth = width;
				}
			});
			Lua_helper.add_callback(lua, "setTextBorder", function(tag:String, size:Int, color:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					var colorNum:Int = Std.parseInt(color);
					if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

					obj.borderSize = size;
					obj.borderColor = colorNum;
				}
			});
			Lua_helper.add_callback(lua, "setTextColor", function(tag:String, color:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					var colorNum:Int = Std.parseInt(color);
					if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

					obj.color = colorNum;
				}
			});
			Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.font = Paths.font(newFont);
				}
			});
			Lua_helper.add_callback(lua, "setTextItalic", function(tag:String, italic:Bool) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.italic = italic;
				}
			});
			Lua_helper.add_callback(lua, "setTextAlignment", function(tag:String, alignment:String = 'left') {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					obj.alignment = LEFT;
					switch(alignment.trim().toLowerCase())
					{
						case 'right':
							obj.alignment = RIGHT;
						case 'center':
							obj.alignment = CENTER;
					}
				}
			});

			Lua_helper.add_callback(lua, "getTextString", function(tag:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					return obj.text;
				}
				return null;
			});
			Lua_helper.add_callback(lua, "getTextSize", function(tag:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					return obj.size;
				}
				return -1;
			});
			Lua_helper.add_callback(lua, "getTextFont", function(tag:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					return obj.font;
				}
				return null;
			});
			Lua_helper.add_callback(lua, "getTextWidth", function(tag:String) {
				var obj:FlxText = getTextObject(tag);
				if(obj != null)
				{
					return obj.fieldWidth;
				}
				return 0;
			});

			Lua_helper.add_callback(lua, "addLuaText", function(tag:String) {
				if(PlayState.instance.modchartTexts.exists(tag)) {
					var shit:ModchartText = PlayState.instance.modchartTexts.get(tag);
					if(!shit.wasAdded) {
						getInstance().add(shit);
						shit.wasAdded = true;
						//trace('added a thing: ' + tag);
					}
				}
			});
			Lua_helper.add_callback(lua, "removeLuaText", function(tag:String, destroy:Bool = true) {
				if(!PlayState.instance.modchartTexts.exists(tag)) {
					return;
				}
				
				var pee:ModchartText = PlayState.instance.modchartTexts.get(tag);
				if(destroy) {
					pee.kill();
				}

				if(pee.wasAdded) {
					getInstance().remove(pee, true);
					pee.wasAdded = false;
				}

				if(destroy) {
					pee.destroy();
					PlayState.instance.modchartTexts.remove(tag);
				}
			});

					//Tween shit, but for strums
			Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String, ?player:Bool = false) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

				if (player)
					testicle = PlayState.instance.playerStrums.members[note];

				if(testicle != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				}
			});
			Lua_helper.add_callback(lua, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String, ?player:Bool = false) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

				if (player)
					testicle = PlayState.instance.playerStrums.members[note];

				if(testicle != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				}
			});
			Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

				if(testicle != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				}
			});
			Lua_helper.add_callback(lua, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

				if(testicle != null) {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {ease: getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				}
			});

			Lua_helper.add_callback(lua, "cancelTween", function(tag:String) {
				cancelTween(tag);
			});

			Lua_helper.add_callback(lua, "animExists", function(tag:String, anim:String){
				var shit:Dynamic;

				shit = getObjectDirectly2(tag);

				if (PlayState.instance.modchartCharacters.exists(tag))
					shit = PlayState.instance.modchartCharacters.get(tag);
				if (Stage.instance.swagBacks.exists(tag))
					shit = Stage.instance.swagBacks.get(tag);
				
				return shit.animation.getByName(anim) != null;
			});

			Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String) {
				var killMe:Array<String> = obj.split('.');
				var leObj:FlxBasic = getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				if(leObj != null)
				{
					return getInstance().members.indexOf(leObj);
				}
				luaTrace("getObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return -1;
			});
			Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int) {
				var killMe:Array<String> = obj.split('.');
				var leObj:FlxBasic = getObjectDirectly2(killMe[0]);
				if(killMe.length > 1) {
					leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				if(leObj != null) {
					getInstance().remove(leObj, true);
					getInstance().insert(position, leObj);
					return;
				}
				luaTrace("setObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			});

			Lua_helper.add_callback(lua, "playSound", function(sound:String, ?volume:Float = 1, ?tag:String = null) {
				var soundPath:Dynamic;
				var isCustomSound:Bool = false;

				if (Assets.exists(Paths.sound(sound)))
					soundPath = Paths.sound(sound);
				else
				{
					if (FileSystem.exists(Paths.sound(sound)))
					{
						isCustomSound = true;
						soundPath = Paths.sound(sound);
					}
					else
					{
						soundPath = Paths.sound('nogood');
						luaTrace('Sound not found!');
					}
				}

				if(tag != null && tag.length > 0) {
					tag = tag.replace('.', '');
					if(PlayState.instance.modchartSounds.exists(tag)) {
						PlayState.instance.modchartSounds.get(tag).stop();
					}
		
					PlayState.instance.modchartSounds.set(tag, FlxG.sound.play((isCustomSound ? (Paths.currentTrackedSounds.exists(sound) ? Paths.currentTrackedSounds.get(sound) : Sound.fromFile(soundPath)): soundPath), volume, false, function() {
						PlayState.instance.modchartSounds.remove(tag);
						PlayState.instance.callOnLuas('onSoundFinished', [tag]);
					}));
					return;
				}
				if (isCustomSound)
					FlxG.sound.play((Paths.currentTrackedSounds.exists(sound) ? Paths.currentTrackedSounds.get(sound) : Sound.fromFile(soundPath)), volume);
				else
					FlxG.sound.play(soundPath, volume);
			});

			Lua_helper.add_callback(lua, "stopSound", function(tag:String) {
				if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).stop();
					PlayState.instance.modchartSounds.remove(tag);
				}
			});

			Lua_helper.add_callback(lua, "pauseSound", function(tag:String) {
				if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).pause();
				}
			});
			Lua_helper.add_callback(lua, "resumeSound", function(tag:String) {
				if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).play();
				}
			});
			Lua_helper.add_callback(lua, "soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				if(tag == null || tag.length < 1) {
					FlxG.sound.music.fadeIn(duration, fromValue, toValue);
				} else if(PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
				}
				
			});
			Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
				if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
				if(tag == null || tag.length < 1) {
					FlxG.sound.music.fadeOut(duration, toValue);
				} else if(PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).fadeOut(duration, toValue);
				}
			});
			Lua_helper.add_callback(lua, "soundFadeCancel", function(tag:String) {
				if(tag == null || tag.length < 1) {
					if(FlxG.sound.music.fadeTween != null) {
						FlxG.sound.music.fadeTween.cancel();
					}
				} else if(PlayState.instance.modchartSounds.exists(tag)) {
					var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
					if(theSound.fadeTween != null) {
						theSound.fadeTween.cancel();
						PlayState.instance.modchartSounds.remove(tag);
					}
				}
			});
			Lua_helper.add_callback(lua, "getSoundVolume", function(tag:String) {
				if(tag == null || tag.length < 1) {
					if(FlxG.sound.music != null) {
						return FlxG.sound.music.volume;
					}
				} else if(PlayState.instance.modchartSounds.exists(tag)) {
					return PlayState.instance.modchartSounds.get(tag).volume;
				}
				return PlayState.instance.vocals.volume;
			});
			Lua_helper.add_callback(lua, "setSoundVolume", function(tag:String, value:Float) {
				if(tag == null || tag.length < 1) {
					if(FlxG.sound.music != null) {
						FlxG.sound.music.volume = value;
					}
				} else if(PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).volume = value;
				}
			});
			Lua_helper.add_callback(lua, "getActualSoundVolume", function(tag:String) {
				if(tag == null || tag.length < 1) {
					if(FlxG.sound.music != null) {
						return FlxG.sound.music.volume;
					}
				} else if(PlayState.instance.modchartSounds.exists(tag)) {
					return PlayState.instance.modchartSounds.get(tag).getActualVolume();
				}
				return PlayState.instance.vocals.getActualVolume();
			});
			Lua_helper.add_callback(lua, "getSoundTime", function(tag:String) {
				if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
					return PlayState.instance.modchartSounds.get(tag).time;
				}
				return 0;
			});
			Lua_helper.add_callback(lua, "setSoundTime", function(tag:String, value:Float) {
				if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
					var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
					if(theSound != null) {
						var wasResumed:Bool = theSound.playing;
						theSound.pause();
						theSound.time = value;
						if(wasResumed) theSound.play();
					}
				}
			});

			Lua_helper.add_callback(lua, "addEffect", function(camera:String,effect:String, ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic, ?val4:Dynamic) {
				
				PlayState.instance.addShaderToCamera(camera, getEffectFromString(effect, val1, val2, val3, val4));
				
			});
			Lua_helper.add_callback(lua, "clearEffects", function(camera:String) {
				PlayState.instance.clearShaderFromCamera(camera);
			});

			Lua_helper.add_callback(lua, "characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false) {
				switch(character.toLowerCase()) {
					case 'dad':
						if(PlayState.instance.dad.animOffsets.exists(anim))
							PlayState.instance.dad.playAnim(anim, forced);
					case 'gf' | 'girlfriend':
						if(PlayState.instance.gf.animOffsets.exists(anim))
							PlayState.instance.gf.playAnim(anim, forced);
					default: 
						if(PlayState.instance.modchartCharacters.exists(character)) {
							var spr:Character = PlayState.instance.modchartCharacters.get(character);

							if(spr.animOffsets.exists(anim))
								spr.playAnim(anim, forced);
						}
						else if(PlayState.instance.boyfriend.animOffsets.exists(anim))
							PlayState.instance.boyfriend.playAnim(anim, forced);
				}
			});


			Lua_helper.add_callback(lua, "close", function(printMessage:Bool) {
				closed = true;
				return closed;
			});

			Lua_helper.add_callback(lua, "characterDance", function(character:String) {
				if(PlayState.instance.modchartCharacters.exists(character)) {
					var spr:Character = PlayState.instance.modchartCharacters.get(character);
					spr.dance();
				}
				else
					getObjectDirectly(character).dance();
			});
			
			Lua_helper.add_callback(lua, "setOffset", function(id:String, x:Float, y:Float) {
				getActorByName(id).offset.set(x, y);
			});

			Lua_helper.add_callback(lua, "mouseClicked", function(button:String) {
				var boobs = FlxG.mouse.justPressed;
				switch(button){
					case 'middle':
						boobs = FlxG.mouse.justPressedMiddle;
					case 'right':
						boobs = FlxG.mouse.justPressedRight;
				}


				return boobs;
			});
			Lua_helper.add_callback(lua, "mousePressed", function(button:String) {
				var boobs = FlxG.mouse.pressed;
				switch(button){
					case 'middle':
						boobs = FlxG.mouse.pressedMiddle;
					case 'right':
						boobs = FlxG.mouse.pressedRight;
				}
				return boobs;
			});
			Lua_helper.add_callback(lua, "mouseReleased", function(button:String) {
				var boobs = FlxG.mouse.justReleased;
				switch(button){
					case 'middle':
						boobs = FlxG.mouse.justReleasedMiddle;
					case 'right':
						boobs = FlxG.mouse.justReleasedRight;
				}
				return boobs;
			});
		}
    }

	inline function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	function resetTextTag(tag:String) {
		if(!PlayState.instance.modchartTexts.exists(tag)) {
			return;
		}
		
		var pee:ModchartText = PlayState.instance.modchartTexts.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartTexts.remove(tag);

		trace('removed text');
	}

	public function getObjectDirectly2(id:String):Dynamic //but dynamic;
	{
		var shit:Dynamic = "long string of text so there's no way someone names it this";

		if(Stage.instance.swagBacks.exists(id))
			shit = Stage.instance.swagBacks.get(id);
		else if(PlayState.instance.Stage.swagBacks.exists(id))
			shit = PlayState.instance.Stage.swagBacks.get(id);
		else if(PlayState.instance.getLuaObject(id) != null)
			shit = PlayState.instance.getLuaObject(id);
		else if (PlayState.instance != null)
			shit = Reflect.getProperty(PlayState.instance, id);
			
		return shit;
	}

	function getEffectFromString(?effect:String = '', ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic , ?val4:Dynamic):ShaderEffect {
		switch(effect.toLowerCase().trim()) {
			case 'grayscale' | 'greyscale' : return new GreyscaleEffect();
			case 'oldtv' : return new OldTVEffect();
			case 'invert' | 'invertcolor': return new InvertColorsEffect();
			case 'tiltshift': return new TiltshiftEffect(val1,val2);
			case 'grain': return new GrainEffect(val1,val2,val3);
			case 'scanline': return new ScanlineEffect(val1);
			case 'outline': return new OutlineEffect(val1, val2, val3, val4);
			case 'distortion': return new DistortBGEffect(val1, val2, val3);
			case 'vcr': return new VCRDistortionEffect(val1,val2,val3,val4);
			case 'glitch': return new GlitchEffect(val1, val2, val3);
			case 'vcr2': return new VCRDistortionEffect2(); //the tails doll one
			case '3d': return new ThreeDEffect(val1, val2, val3, val4);
			case 'bloom': return new BloomEffect(val1/512.0,val2);
			case 'rgbshiftglitch' | 'rgbshift': return new RGBShiftGlitchEffect(val1, val2);
			case 'pulse': return new PulseEffect(val1,val2,val3);
			case 'chromaticabberation' | 'ca': return new ChromaticAberrationEffect(val1);
			case 'sketch': return new SketchEffect();
		}
		return new GreyscaleEffect();
	}

    public function executeState(name,args:Array<Dynamic>)
    {
        return Lua.tostring(lua,call(name, args));
    }

	function cameraFromString(cam:String):FlxCamera 
	{
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}
		return PlayState.instance.camGame;
	}

	function cancelTimer(tag:String) {
		if(PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	function cancelTween(tag:String) {
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}
	
	function tweenShit(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = getObjectDirectly2(variables[0]);
		if(variables.length > 1) {
			sexyProp = getVarInArray(getPropertyLoopThingWhatever(variables), variables[variables.length-1]);
		}
		return sexyProp;
	}

	public static function getVarInArray(instance:Dynamic, variable:String):Any
	{
		var shit:Array<String> = variable.split('[');
		if(shit.length > 1)
		{
			var blah:Dynamic = null;
			if(PlayState.instance.variables.exists(shit[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(shit[0]);
				if(retVal != null)
					blah = retVal;
			}
			else if (PlayState.instance.Stage.swagBacks.exists(shit[0]))
			{
				var retVal:Dynamic = PlayState.instance.Stage.swagBacks.get(shit[0]);
				if(retVal != null)
					blah = retVal;
			}
			else if (Stage.instance.swagBacks.exists(shit[0]))
			{
				var retVal:Dynamic = Stage.instance.swagBacks.get(shit[0]);
				if(retVal != null)
					blah = retVal;
			}
			else
				blah = Reflect.getProperty(instance, shit[0]);

			for (i in 1...shit.length)
			{
				var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
				blah = blah[leNum];
			}
			return blah;
		}

		if(PlayState.instance.variables.exists(variable))
		{
			var retVal:Dynamic = PlayState.instance.variables.get(variable);
			if(retVal != null)
				return retVal;
		}
		if (PlayState.instance.Stage.swagBacks.exists(variable))
		{
			var retVal:Dynamic = PlayState.instance.Stage.swagBacks.get(variable);
			if(retVal != null)
				return retVal;
		}
		if (Stage.instance.swagBacks.exists(variable))
		{
			var retVal:Dynamic = Stage.instance.swagBacks.get(shit[0]);
				if(retVal != null)
					return retVal;
		}

		return Reflect.getProperty(instance, variable);
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any
	{
		var shit:Array<String> = variable.split('[');
		if(shit.length > 1)
		{
			var blah:Dynamic = null;
			if(PlayState.instance.variables.exists(shit[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(shit[0]);
				if(retVal != null)
					blah = retVal;
			}
			else if (PlayState.instance.Stage.swagBacks.exists(shit[0]))
			{
				var retVal:Dynamic = PlayState.instance.Stage.swagBacks.get(shit[0]);
				if(retVal != null)
					blah = retVal;
			}
			else if (Stage.instance.swagBacks.exists(shit[0]))
			{
				var retVal:Dynamic = Stage.instance.swagBacks.get(shit[0]);
				if(retVal != null)
					blah = retVal;
			}
			else
				blah = Reflect.getProperty(instance, shit[0]);

			for (i in 1...shit.length)
			{
				var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
				if(i >= shit.length-1) //Last array
					blah[leNum] = value;
				else //Anything else
					blah = blah[leNum];
			}
			return blah;
		}
		/*if(Std.isOfType(instance, Map))
			instance.set(variable,value);
		else*/
			
		if(PlayState.instance.variables.exists(variable))
		{
			PlayState.instance.variables.set(variable, value);
			return true;
		}
		if (PlayState.instance.Stage.swagBacks.exists(variable))
		{
			PlayState.instance.Stage.swagBacks.set(variable, value);
			return true;
		}
		else if (Stage.instance.swagBacks.exists(variable))
		{
			Stage.instance.setProperty(variable, value);
			return true;
		}

		Reflect.setProperty(instance, variable, value);
		return true;
	}

	public static function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true):Dynamic
	{
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
		var end = killMe.length;
		if(getProperty)end=killMe.length-1;

		for (i in 1...end) {
			coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
		}
		return coverMeInPiss;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
	{
		if (objectName == 'dadGroup' || objectName == 'boyfriendGroup' || objectName == 'gfGroup'){
			objectName = objectName.substring(0, objectName.length-5); //because we don't use character groups
		}

		var coverMeInPiss:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
		if(coverMeInPiss==null)
			coverMeInPiss = getVarInArray(getInstance(), objectName);

		return coverMeInPiss;
	}

	function getFlxEaseByString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	function resetSpriteTag(tag:String = "") {
		if(!PlayState.instance.modchartSprites.exists(tag) && !Stage.instance.swagBacks.exists(tag)) {
			return;
		}
		
		if (PlayState.instance != null)
		{
			if(PlayState.instance.modchartSprites.exists(tag))
			{
				var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				pee.kill();
				if(pee.wasAdded) {
					PlayState.instance.remove(pee, true);
				}
				pee.destroy();
				PlayState.instance.modchartSprites.remove(tag);
				return;
			}
			
			if(Stage.instance.swagBacks.exists(tag))
			{
				var pee:ModchartSprite = Stage.instance.swagBacks.get(tag);
				pee.kill();
				//if(pee.wasAdded) {
					PlayState.instance.remove(pee, true);
				//}
				pee.destroy();
				Stage.instance.swagBacks.remove(tag);
				return;
			}
		}
	}

	static function addAnimByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false)
	{
		var strIndices:Array<String> = indices.trim().split(',');
		var die:Array<Int> = [];
		for (i in 0...strIndices.length) {
			die.push(Std.parseInt(strIndices[i]));
		}

		if (Stage.instance.swagBacks.exists(obj))
		{
			var bussy:Dynamic = Stage.instance.swagBacks.get(obj);
			var pussy:FlxSprite = changeSpriteClass(bussy);

			pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
			if(pussy.animation.curAnim == null) {
				pussy.animation.play(name, true);
			}
			return true;
		}

		if(getObjectDirectly(obj) != null) {
			var pussy:FlxSprite = changeSpriteClass(getObjectDirectly(obj));
			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
			if(pussy.animation.curAnim == null) {
				pussy.animation.play(name, true);
			}
			return true;
		}

		var pussy:FlxSprite = Reflect.getProperty(getInstance(), obj);
		if(pussy != null) {
			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
			if(pussy.animation.curAnim == null) {
				pussy.animation.play(name, true);
			}
			return true;
		}
		return false;
	}

	static function changeSpriteClass(tag:Dynamic):FlxSprite {
		return tag;
	}

	function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}

	function loadFrames(spr:FlxSprite, image:String, spriteType:String)
	{
		switch(spriteType.toLowerCase().trim())
		{
			case "texture" | "textureatlas"|"tex":
				spr.frames = AtlasFrameMaker.construct(image);
			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);
			case "packer" |"packeratlas"|"pac":
				spr.frames = Paths.getPackerAtlas(image);
			default:
			{
				if (!Paths.currentTrackedAssets.exists(image))
					Paths.cacheImage(image);

				spr.frames = Paths.getSparrowAtlas(image);

				if (FlxG.save.data.poltatoPC)
				{
					spr.scale.set(2, 2);
					spr.updateHitbox();
				}
			}
		}
	}

	public static inline function getInstance()
	{
		//return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;

		var instance:Dynamic = Stage.instance;

		if (PlayState.instance != null){
			instance = (PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance);
		}
		
		return instance;
	}
}
#end