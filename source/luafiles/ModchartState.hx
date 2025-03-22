package luafiles;


// Lua
import openfl.display3D.textures.VideoTexture;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
#if desktop
import openfl.filters.ShaderFilter;
import openfl.Lib;
import flixel.addons.display.FlxBackdrop;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import lime.app.Application;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxPoint;
import flixel.effects.FlxFlicker;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.util.FlxAxes;
import openfl.system.System;
import lime.utils.Assets;
import openfl.display.BlendMode;
import flixel.tweens.misc.ColorTween;
import flash.media.Sound;
import lime.media.AudioBuffer;
import flixel.util.FlxSpriteUtil;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import flixel.math.FlxRect;

import flixel.addons.display.FlxShaderMaskCamera;

import Type.ValueType;
import cutscenes.DialogueBoxPsych;

import shaders.Shaders;
import shaders.ColorSwap;

//why is detected's modchart confusing!?
import luafiles.LuaClass.*;
import luafiles.LuaClass.LuaNote;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

import openfl.filters.BitmapFilter;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;

import objects.*;
import states.editors.ModpackMaker;

//bruh.
import states.StoryMenuState;
import states.GuestBETADCIUState;
import states.BETADCIUState;
import states.BonusSongsState;
import states.NeonightState;
import states.VitorState;
import states.FreeplayState;

import backend.Song;
import backend.Highscore;

import luafiles.LuaUtils;
import luafiles.LuaUtils.LuaTweenOptions;
#if SScript
import luafiles.HScript;
#end
import luafiles.DebugLuaText;
import luafiles.ModchartSprite;
import luafiles.ModchartText;
import luafiles.ModchartText.*;
import luafiles.CustomSubstate;

import substates.PauseSubState;

using StringTools;

class ModchartState 
{
	public static var Function_Stop:Dynamic = "##MODCHARTSTATE_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##MODCHARTSTATE_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##MODCHARTSTATE_FUNCTIONSTOPLUA";
	public static var Function_StopHScript:Dynamic = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
	public static var Function_StopAll:Dynamic = "##PSYCHLUA_FUNCTIONSTOPALL";

	#if LUA_ALLOWED
	public var lua:State = null;
	#end
	
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var gonnaClose:Bool = false;
	public var closed:Bool = false;

	public static var shownNotes:Array<LuaNote> = [];

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var blam:Dynamic = "";

	#if SScript
	public var hscript:HScript = null;
	#end
	
	public var lastCalledFunction:String = '';
	public static var lastCalledScript:ModchartState = null;

	public function call(func:String, args:Array<Dynamic>, ?type : String):Dynamic {
		#if LUA_ALLOWED
		if(closed) return Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		try {
			if(lua == null) return Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL)
					luaTrace(scriptName + ": ERROR (" + func + "): attempt to call a " + typeToString(type) + " value", false, false, FlxColor.RED);

				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK) {
				var error:String = getErrorMessage(status);
				luaTrace(scriptName + ": ERROR (" + func + "): " + error, false, false, FlxColor.RED);
				return Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);

			Lua.pop(lua, 1);
			return result == null ? Function_Continue : result;
		}
		catch (e:Dynamic) {
			trace(e);
		}
		#end
		return Function_Continue;
	}

	function typeToString(type:Int):String {
		#if LUA_ALLOWED
		switch(type) {
			case Lua.LUA_TBOOLEAN: return "boolean";
			case Lua.LUA_TNUMBER: return "number";
			case Lua.LUA_TSTRING: return "string";
			case Lua.LUA_TTABLE: return "table";
			case Lua.LUA_TFUNCTION: return "function";
		}
		if (type <= Lua.LUA_TNIL) return "nil";
		#end
		return "unknown";
	}

	function getErrorMessage(status:Int):String {
		#if LUA_ALLOWED
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
		#end
		return null;
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

	static function toLua(l:State, val:Any):Dynamic {
		switch (Type.typeof(val)) {
			case Type.ValueType.TNull:
				return null;
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

	function getLuaErrorMessage(l) {
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);
		return v;
	}

	public function set(var_name : String, object : Dynamic){
		// trace('setting variable ' + var_name + ' to ' + object);

		Convert.toLua(lua, object);
		Lua.setglobal(lua, var_name);
	}

	public function get(var_name : String, type : String) : Dynamic {
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

	function doFunction(id:String, ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic, ?val4:Dynamic)
	{
		//this is dumb but idk how else to do it and i don't wanna make multiple functions for different playstate functions so yeah.
		switch (id)
		{
			case 'funCountdown': PlayState.instance.funCountdown(val1);
			case 'softCountdown': PlayState.instance.softCountdown();
			case 'startCountdown': PlayState.instance.startCountdown();
			case 'resyncVocals': PlayState.instance.resyncVocals();	
			case 'doTimeTravel': PlayState.instance.doTimeTravel(val1, val2);		
			case 'uncacheImage': Paths.clearStoredMemory2(val1, 'image');	
			case 'uncacheSound': Paths.clearStoredMemory2(val1, 'sound');			
			case 'cacheImage': Paths.cacheImage(val1, val2);
			case 'spawnStartingNoteSplash': PlayState.instance.spawnStartingNoteSplash(0, 0, 0);	
		}
	}

	public static function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, ?color:FlxColor = FlxColor.WHITE) {
		#if LUA_ALLOWED
		if (lastCalledScript.preloading) //otherwise it'll warn a lot for objects with scales
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

	#if LUA_ALLOWED
	public static function getBool(variable:String) {
		var result:String = null;

		var lua:State = lastCalledScript.lua;

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

	public static function makeLuaCharacter(tag:String, character:String, isPlayer:Bool = false, flipped:Bool = false)
	{
		tag = tag.replace('.', '');

		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;	
		var position:Int = -1;
							
		if (PlayState.instance.modchartCharacters.get(tag) != null)
		{
			var daChar:Character = PlayState.instance.modchartCharacters.get(tag);
			animationName = daChar.animation.curAnim.name;
			animationFrame = daChar.animation.curAnim.curFrame;
			position = LuaUtils.getTargetInstance().members.indexOf(daChar);
		}
		
		LuaUtils.resetCharacterTag(tag);
		var leSprite:Character = new Character(0, 0, character, isPlayer);
		leSprite.flipMode = flipped;
		PlayState.instance.modchartCharacters.set(tag, leSprite); //yes
		var shit:Character = PlayState.instance.modchartCharacters.get(tag);
		LuaUtils.getTargetInstance().add(shit);

		if (position >= 0) //this should keep them in the same spot if they switch
		{
			LuaUtils.getTargetInstance().remove(shit, true);
			LuaUtils.getTargetInstance().insert(position, shit);
		}

		var charOffset = new CharacterOffsets(character, flipped);
		var charX:Float = charOffset.daOffsetArray[0];
		var charY:Float =  charOffset.daOffsetArray[1] + (flipped ? 350 : 0);

		if (!isPlayer)
		{
			if (flipped)
				shit.flipMode = true;
	
			if (!shit.isCustom)
			{
				if (flipped)
				{
					if (charX == 0 && charOffset.daOffsetArray[1] == 0 && !charOffset.hasOffsets)
					{
						var charOffset2 = new CharacterOffsets(character, false);
						charX = charOffset2.daOffsetArray[0];
						charY = charOffset2.daOffsetArray[1];
					}
				}
				else
				{
					if (charX == 0 && charY == 0 && !charOffset.hasOffsets)
					{
						var charOffset2 = new CharacterOffsets(character, true);
						charX = charOffset2.daOffsetArray[0];
						charY = charOffset2.daOffsetArray[1] + 350;
					}
				}
			}
	
			if (shit.isCustom)
			{
				charX = shit.positionArray[0];
				charY = shit.positionArray[1];
			}
	
			shit.x = PlayState.instance.Stage.dadXOffset + charX + 100;
			shit.y = PlayState.instance.Stage.dadYOffset + charY + 100;
		}
		else
		{
			if (flipped)
				shit.flipMode = true;
	
			var charOffset = new CharacterOffsets(character, !flipped);
			var charX:Float = charOffset.daOffsetArray[0];
			var charY:Float =  charOffset.daOffsetArray[1] - (!flipped ? 0 : 350);
	
			if (!shit.isCustom)
			{
				if (flipped)
				{
					if (charX == 0 && charOffset.daOffsetArray[1] == 0)
					{
						var charOffset2 = new CharacterOffsets(character, true);
						charX = charOffset2.daOffsetArray[0];
						charY =  charOffset2.daOffsetArray[1];
					}
				}
				else
				{
					if (charX == 0 && charY == 0 && !shit.curCharacter.startsWith('bf'))
					{
						var charOffset2 = new CharacterOffsets(character, false);
						charX = charOffset2.daOffsetArray[0];
						charY =  charOffset2.daOffsetArray[1] - 350;
					}
				}	
			}
	
			if (shit.isCustom)
			{
				charX = shit.positionArray[0];
				charY = shit.positionArray[1] - 350;
			}
	
			shit.x = PlayState.instance.Stage.bfXOffset + charX + 770;
			shit.y = PlayState.instance.Stage.bfYOffset + charY + 450;
		}

		if (shit.animOffsets.exists(animationName))
			shit.playAnim(animationName, true, false, animationFrame);

		PlayState.instance.startCharacterLua(shit.curCharacter);
	}

	//Kade why tf is it not like in PlayState???

	function changeGFCharacter(id:String, x:Float, y:Float)
	{		
		changeGFAuto(id);
		PlayState.instance.gf.x = x;
		PlayState.instance.gf.y = y;
	}

	function changeDadCharacter(id:String, x:Float, y:Float)
	{		
		changeDadAuto(id, false, false);
		PlayState.instance.dad.x = x;
		PlayState.instance.dad.y = y;
	}

	function changeBoyfriendCharacter(id:String, x:Float, y:Float)
	{	
		changeBFAuto(id, false, false);
		PlayState.instance.boyfriend.x = x;
		PlayState.instance.boyfriend.y = y;
	}

	//does this work. right? -- future me here. yes it does.
	public static function changeStage(id:String)
	{	
		for (i in [PlayState.instance.gf, PlayState.instance.dad, PlayState.instance.boyfriend, PlayState.instance.comboGroup]){
			PlayState.instance.removeObject(i);
		}

		if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.isLuaStage)
		{
			for (lua in PlayState.instance.Stage.luaArray)
			{
				lua.call("onDestroy", []);
				PlayState.instance.Stage.luaArray.remove(lua);
				lua.stop();
			}

			PlayState.instance.Stage.luaArray = [];
		}

		for (i in PlayState.instance.Stage.toAdd)
		{
			PlayState.instance.removeObject(i);
			PlayState.instance.destroyObject(i);
		}	

		for (ii in 0...3)
		{
			for (i in PlayState.instance.Stage.layInFront[ii])
			{
				PlayState.instance.removeObject(i);
				PlayState.instance.destroyObject(i);
			}	
		}
		
		PlayState.instance.Stage.swagBacks.clear();
			
		PlayState.instance.removeObject(PlayState.instance.Stage);
		PlayState.instance.destroyObject(PlayState.instance.Stage);
		
		PlayState.instance.Stage = new Stage(id, false);
		PlayState.curStage = PlayState.instance.Stage.curStage;
		PlayState.instance.defaultCamZoom = PlayState.instance.Stage.camZoom;

		for (i in PlayState.instance.Stage.toAdd){
			PlayState.instance.addObject(i);
		}	
		
		for (index => array in PlayState.instance.Stage.layInFront)
		{
			switch (index)
			{
				case 0:
					PlayState.instance.addObject(PlayState.instance.gf);
					PlayState.instance.gf.scrollFactor.set(0.95, 0.95);
					for (bg in array)
						PlayState.instance.addObject(bg);
				case 1:
					PlayState.instance.addObject(PlayState.instance.dad);
					for (bg in array)
						PlayState.instance.addObject(bg);
				case 2:
					PlayState.instance.addObject(PlayState.instance.boyfriend);

					for (bg in array)
						PlayState.instance.addObject(bg);
			}
		}	

		PlayState.instance.addObject(PlayState.instance.comboGroup);

		if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1){
			PlayState.instance.Stage.callOnLuas('onCreatePost', []); //i swear if this starts crashing stuff i'mma cry
		}
			
		PlayState.instance.setCameraOffsets();

		//trace(PlayState.instance.Stage.luaArray.length);
	}

	// this is better. easier to port shit from playstate.
	function changeGFCharacterBetter(x:Float, y:Float, id:String)
	{		
		changeGFCharacter(id, x, y);
	}

	function changeDadCharacterBetter(x:Float, y:Float, id:String)
	{		
		changeDadCharacter(id, x, y);
	}

	function changeBoyfriendCharacterBetter(x:Float, y:Float, id:String)
	{							
		changeBoyfriendCharacter(id, x, y);
	}

	//trying to do some auto stuff so i don't have to set manual x and y values
	public static function changeBFAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false)
	{	
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;						
		if (PlayState.instance.boyfriend.animation.curAnim.name.startsWith('sing'))
		{
			animationName = PlayState.instance.boyfriend.animation.curAnim.name;
			animationFrame = PlayState.instance.boyfriend.animation.curAnim.curFrame;
		}

		var bfPath:String = "";

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy)
			bfPath = 'shared:assets/shared/images/'+PlayState.instance.boyfriend.charPath;

		PlayState.instance.removeObject(PlayState.instance.boyfriend);
		PlayState.instance.destroyObject(PlayState.instance.boyfriend);
		PlayState.instance.boyfriend = new Boyfriend(0, 0, id, !flipped);
		PlayState.instance.boyfriend.flipMode = flipped;

		var charOffset = new CharacterOffsets(id, !flipped);
		var charX:Float = charOffset.daOffsetArray[0];
		var charY:Float =  charOffset.daOffsetArray[1] - (!flipped ? 0 : 350);

		if (!PlayState.instance.boyfriend.isCustom)
		{
			if (flipped)
			{
				if (charX == 0 && charOffset.daOffsetArray[1] == 0)
				{
					var charOffset2 = new CharacterOffsets(id, true);
					charX = charOffset2.daOffsetArray[0];
					charY =  charOffset2.daOffsetArray[1];
				}
			}
			else
			{
				if (charX == 0 && charY == 0 && !PlayState.instance.boyfriend.curCharacter.startsWith('bf'))
				{
					var charOffset2 = new CharacterOffsets(id, false);
					charX = charOffset2.daOffsetArray[0];
					charY =  charOffset2.daOffsetArray[1] - 350;
				}
			}	
		}

		if (PlayState.instance.boyfriend.isCustom)
		{
			charX = PlayState.instance.boyfriend.positionArray[0];
			charY = PlayState.instance.boyfriend.positionArray[1] - 350;
		}

		PlayState.instance.boyfriend.x = PlayState.instance.Stage.bfXOffset + charX + 770;
		PlayState.instance.boyfriend.y = PlayState.instance.Stage.bfYOffset + charY + 450;

		//PlayState.instance.addObject(PlayState.instance.bfTrail);
		//PlayState.instance.bfTrail.resetTrail();
		PlayState.instance.addObject(PlayState.instance.boyfriend);

		PlayState.instance.iconP1.changeIcon(PlayState.instance.boyfriend.healthIcon);
		
		if (PlayState.instance.defaultBar)
		{
			var dad = PlayState.instance.dad;
			var boyfriend = PlayState.instance.boyfriend;
			
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			PlayState.instance.healthBar.updateBar();
		}	

		if (PlayState.instance.boyfriend.animOffsets.exists(animationName))
			PlayState.instance.boyfriend.playAnim(animationName, true, false, animationFrame);

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy)
			Paths.clearStoredMemory2(bfPath);

		PlayState.instance.setOnScripts('boyfriendName', PlayState.instance.boyfriend.curCharacter);
		PlayState.instance.startCharacterLua(PlayState.instance.boyfriend.curCharacter);
	}

	public static function changeDadAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false)
	{	
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;						
		if (PlayState.instance.dad.animation.curAnim.name.startsWith('sing'))
		{
			animationName = PlayState.instance.dad.animation.curAnim.name;
			animationFrame = PlayState.instance.dad.animation.curAnim.curFrame;
		}

		var dadPath:String = '';
		var daCurChar:String = PlayState.instance.dad.curCharacter;

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy)
			dadPath = 'shared:assets/shared/images/'+PlayState.instance.dad.charPath;

		//PlayState.instance.removeObject(PlayState.instance.dadTrail);
		PlayState.instance.removeObject(PlayState.instance.dad);
		PlayState.instance.destroyObject(PlayState.instance.dad);
		PlayState.instance.dad = new Character(0, 0, id, flipped);
		PlayState.instance.dad.flipMode = flipped;

		var charOffset = new CharacterOffsets(id, flipped);
		var charX:Float = charOffset.daOffsetArray[0];
		var charY:Float =  charOffset.daOffsetArray[1] + (flipped ? 350 : 0);

		if (!PlayState.instance.dad.isCustom)
		{
			if (flipped)
			{
				if (charX == 0 && charOffset.daOffsetArray[1] == 0 && !charOffset.hasOffsets)
				{
					var charOffset2 = new CharacterOffsets(id, false);
					charX = charOffset2.daOffsetArray[0];
					charY = charOffset2.daOffsetArray[1];
				}
			}
			else
			{
				if (charX == 0 && charY == 0 && !charOffset.hasOffsets)
				{
					var charOffset2 = new CharacterOffsets(id, true);
					charX = charOffset2.daOffsetArray[0];
					charY = charOffset2.daOffsetArray[1] + 350;
				}
			}
		}

		if (PlayState.instance.dad.isCustom)
		{
			charX = PlayState.instance.dad.positionArray[0];
			charY = PlayState.instance.dad.positionArray[1];
		}

		PlayState.instance.dad.x = PlayState.instance.Stage.dadXOffset + charX + 100;
		PlayState.instance.dad.y = PlayState.instance.Stage.dadYOffset + charY + 100;
		PlayState.instance.addObject(PlayState.instance.dad);

		PlayState.instance.iconP2.changeIcon(PlayState.instance.dad.healthIcon);
			
		if (PlayState.instance.defaultBar)
		{
			var dad = PlayState.instance.dad;
			var boyfriend = PlayState.instance.boyfriend;

			PlayState.instance.healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			PlayState.instance.healthBar.updateBar();
		}	

		if (PlayState.instance.dad.animOffsets.exists(animationName))
			PlayState.instance.dad.playAnim(animationName, true, false, animationFrame);

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy && daCurChar != PlayState.instance.dad.curCharacter)
			Paths.clearStoredMemory2(dadPath);

		PlayState.instance.setOnScripts('dadName', PlayState.instance.dad.curCharacter);
		PlayState.instance.startCharacterLua(PlayState.instance.dad.curCharacter);
	}

	public static function changeGFAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false)
	{		
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;						
		if (PlayState.instance.gf.animation.curAnim.name.startsWith('sing'))
		{
			animationName = PlayState.instance.gf.animation.curAnim.name;
			animationFrame = PlayState.instance.gf.animation.curAnim.curFrame;
		}

		PlayState.instance.removeObject(PlayState.instance.gf);
		PlayState.instance.destroyObject(PlayState.instance.gf);
		PlayState.instance.gf = new Character(0, 0, id, flipped);
		PlayState.instance.gf.flipMode = flipped;
		PlayState.instance.gf.x = PlayState.instance.Stage.gfXOffset + 400 + PlayState.instance.gf.positionArray[0];
		PlayState.instance.gf.y = PlayState.instance.Stage.gfYOffset + 130 + PlayState.instance.gf.positionArray[1];
		PlayState.instance.gf.scrollFactor.set(0.95, 0.95);
		PlayState.instance.addObject(PlayState.instance.gf);

		if (FlxG.save.data.poltatoPC)
			PlayState.instance.gf.setPosition(PlayState.instance.gf.x + 100, PlayState.instance.gf.y + 170);

		var gfPath:String = '';

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy)
			gfPath = 'shared:assets/shared/images/'+PlayState.instance.gf.charPath;

		if (PlayState.instance.gf.animOffsets.exists(animationName))
			PlayState.instance.gf.playAnim(animationName, true, false, animationFrame);

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy)
			Paths.clearStoredMemory2(gfPath);

		PlayState.instance.setOnScripts('gfName', PlayState.instance.gf.curCharacter);
		PlayState.instance.startCharacterLua(PlayState.instance.gf.curCharacter);
	}

	function changeStageOffsets(char:String, x:Float = -10000, ?y:Float = -10000) //in case you need to change or test the stage offsets for the auto commands
	{
		switch (char)
		{
			case 'boyfriend' | 'bf':
				if (x != -10000)
					PlayState.instance.Stage.bfXOffset = x;
				if (y != -10000)
					PlayState.instance.Stage.bfYOffset = y;
			case 'gf':
				if (x != -10000)
					PlayState.instance.Stage.gfXOffset = x;
				if (y != -10000)
					PlayState.instance.Stage.gfYOffset = y;
			default:
				if (x != -10000)
					PlayState.instance.Stage.dadXOffset = x;
				if (y != -10000)
					PlayState.instance.Stage.dadYOffset = y;
		}
	}

    public function stop() {	
		#if desktop
		if(lua == null) {
			return;
		}

		Lua.close(lua);
		lua = null;
		#end
	}
    // LUA SHIT

	public var isStageLua:Bool = false;
	public var preloading:Bool = false;

    public function new(path:String, ?preloading:Bool = false, ?isStageLua:Bool = false)
    {
		// for detected
		//instance = this;
		this.isStageLua = isStageLua;

		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		if (isStageLua){path = Paths.stageLua(path);}

		var ogPath:String = "";
		
		if (path.contains('assets/shared')) //in case I wanna take from shared
		{
			ogPath = path;
			path = FileSystem.absolutePath(path);
		}
			
		if(PlayState.instance == FlxG.state && PlayState.instance.isDetected)
			shownNotes = [];

		this.preloading = preloading;
		scriptName = path.trim();

		var myFolder:Array<String> = this.scriptName.split('/');
		#if MODS_ALLOWED
		if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
			this.modFolder = myFolder[1];
		#end

		if (ogPath.contains('assets/shared'))
			scriptName = ogPath;

		if (scriptName.contains("-embed")) //kill me
		{
			var luaPath = 'assets/stages/embeddedStage.lua';

			File.saveContent(luaPath, Assets.getText(scriptName));
			path = luaPath;
		}

		try{
			var result:Dynamic = LuaL.dofile(lua, path);
			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				trace('Error on lua script! ' + resultStr);
				#if windows
				lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
				#else
				luaTrace('Error loading lua script: "$script"\n' + resultStr, true, false, FlxColor.RED);
				#end
				lua = null;

				if (isStageLua)
				{
					Stage.instance.luaArray.remove(this);
					Stage.instance.luaArray = [];
				}
				else
				{
					PlayState.instance.luaArray.remove(this);
					PlayState.instance.luaArray = [];
				}
				/*
				var daArray = (isStageLua ? Stage.instance.luaArray : PlayState.instance.luaArray);

				for (luaInstance in daArray)
				{
					if(luaInstance.lua == null){
						daArray.remove(luaInstance);
					}
				}*/

				return;
			}
		} catch(e:Dynamic) {
			trace(e);
			return;
		}

		trace('lua file loaded succesfully:' + path);

		if (scriptName.contains("-embed")) //kill me
		{
			var luaPath = 'assets/stages/embeddedStage.lua';
			var luaPath2 = 'assets/stages/stage.lua';

			File.saveContent(luaPath, Assets.getText(luaPath2));
			path = scriptName;
		}
			
		//shaders = new Array<LuaShader>();	

		// get some fukin globals up in here bois

		set('Function_StopLua', Function_StopLua);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue); //i have no idea how this works
		set('luaDebugMode', true);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);
		set('inGameOver', false);

		set("difficulty", PlayState.storyDifficulty);
		set("curBpm", Conductor.bpm);
		set("downscroll", FlxG.save.data.downscroll);
		set("flashing", FlxG.save.data.flashing);
		set("distractions", FlxG.save.data.distractions);
		set('songLength', FlxG.sound.music.length);
		set('seenCutscene', PlayState.seenCutscene);
		set('scriptName', scriptName);

		set('shadersEnabled', ClientPrefs.data.shaders);

		if (PlayState.SONG != null)
		{
			set("bpm", PlayState.SONG.bpm);
			set('songName', PlayState.SONG.song);
			set('songPath', Paths.formatToSongPath(PlayState.SONG.song));

			// Character shit
			set('boyfriendName', PlayState.SONG.player1);
			set('dadName', PlayState.SONG.player2);
			set('gfName', PlayState.SONG.gfVersion);

			set("scrollspeed", FlxG.save.data.scrollSpeed != 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed);
		}
		else{
			set('songName', "");
		}

		set('currentModDirectory', Mods.currentModDirectory);

		var difficultyName:String = CoolUtil.difficulties[PlayState.storyDifficulty];
		set('difficultyName', difficultyName);
		set('difficultyPath', Paths.formatToSongPath(difficultyName));

		set("curStep", 0);
		set("daSection", 0);
		set("curBeat", 0);
		set("crochet", Conductor.crochet);
		set("stepCrochet", Conductor.stepCrochet);
		set("safeZoneOffset", Conductor.safeZoneOffset);

		set("cameraZoom", FlxG.camera.zoom);
		set("cameraAngle", FlxG.camera.angle);
		set("curSection", 0);
		set("songPos", 0);

		set("bfAltAnim", false);
		set("dadAltAnim", false);
		set("bfNotesVisible", true);
		set("dadNotesInvisible", false);

		set("showOnlyStrums", false);
		set("strumLine1Visible", true);
		set("strumLine2Visible", true);

		set("screenWidth",FlxG.width);
		set("screenHeight",FlxG.height);
		set("windowWidth",FlxG.width);
		set("windowHeight",FlxG.height);

		set("mustHitSection", false);
		set('gfSection', false);
		set("playDadSing", true);
		set("playBFSing", true);

		if(PlayState.instance == FlxG.state)
		{
			set("hudWidth", PlayState.instance.camHUD.width);
			set("hudHeight", PlayState.instance.camHUD.height);
	
			set("hudZoom", PlayState.instance.camHUD.zoom);
			set("camHudAngle", PlayState.instance.camHUD.angle);
		}

		for (i in 0...4) {
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		set('playbackRate', 1);
		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
	
		// callbacks

		// sprites

		if (preloading) //only the necessary functions for preloading are included
		{
			Lua_helper.add_callback(lua, "debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
				if (text1 == null) text1 = '';
				if (text2 == null) text2 = '';
				if (text3 == null) text3 = '';
				if (text4 == null) text4 = '';
				if (text5 == null) text5 = '';

				if (ModpackMaker.inModpackMaker){
					trace('' + text1 + text2 + text3 + text4 + text5);
				}
				else{
					luaTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
				}
				
			});
			
			Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
				if (ModpackMaker.inModpackMaker && image != null && image.length > 0){
					ModpackMaker.luaImageList.push(image);
					return;
				}

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
				leSprite.active = true;

				if (!preloading)
					Stage.instance.swagBacks.set(tag, leSprite);
			});

			Lua_helper.add_callback(lua, "makeLuaSprite2", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
				if (ModpackMaker.inModpackMaker && image != null && image.length > 0){
					ModpackMaker.luaImageList.push(image);
					return;
				}

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
				leSprite.active = false;

				if (!preloading)
					Stage.instance.swagBacks.set(tag, leSprite);
			});

			Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float,spriteType:String="sparrow") {
				if (ModpackMaker.inModpackMaker && image != null && image.length > 0){
					ModpackMaker.luaImageList.push(image);
					return;
				}

				tag = tag.replace('.', '');
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
				
				loadFrames(leSprite, image, spriteType);
				leSprite.antialiasing = true;
				leSprite.active = true;

				if (!preloading)
					Stage.instance.swagBacks.set(tag, leSprite);
			});

			Lua_helper.add_callback(lua, "makeLuaBackdrop", function(tag:String, image:String, x:Float, y:Float, ?axes:String = "XY") {
				if (ModpackMaker.inModpackMaker && image != null && image.length > 0){
					ModpackMaker.luaImageList.push(image);
					return;
				}

				tag = tag.replace('.', '');

				var leSprite:FlxBackdrop = null;

				if(image != null && image.length > 0) {

					var rawPic:Dynamic;

					if (!Paths.currentTrackedAssets.exists(image))
						Paths.cacheImage(image);

					rawPic = Paths.currentTrackedAssets.get(image);	
					
					leSprite = new FlxBackdrop(rawPic, FlxAxes.fromString(axes), Std.int(x), Std.int(y));
				}

				if (leSprite == null)
					return;

				leSprite.antialiasing = true;
				leSprite.active = true;

				if (!preloading)
					Stage.instance.swagBacks.set(tag, leSprite);
			});

			Lua_helper.add_callback(lua, "makeHealthIcon", function(tag:String, character:String, player:Bool = false) {
				if (ModpackMaker.inModpackMaker){
					ModpackMaker.luaImageList.push('icons/icon-'+character);
				}
				else{
					Paths.returnGraphic('icons/icon-'+character);
				}
			});

			Lua_helper.add_callback(lua, "imageExists", function(image:String, ?library:String) {
				return Paths.imageExists2(image, library);
			});

			Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String, ?gridX:Int, ?gridY:Int) {
				if (ModpackMaker.inModpackMaker){
					ModpackMaker.luaImageList.push(image);
				}
				else{
					Paths.returnGraphic(image);
				}
			});

			Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
				tag = tag.replace('.', '');
				var leText:ModchartText = new ModchartText(x, y, text, width);
			});

			Lua_helper.add_callback(lua, "precacheSound", function(name:String, ?path:String = "sounds") {
				if (ModpackMaker.inModpackMaker){
					ModpackMaker.luaSoundList.push(name);
				}
				else{
					Paths.returnSound(path, name);
				}
			});

			Lua_helper.add_callback(lua, "precacheFont", function(name:String) {
				if (ModpackMaker.inModpackMaker){
					ModpackMaker.luaFontList.push(name);
				}
				return name; // this doesn't actually preload the font.
			});

			Lua_helper.add_callback(lua, "precacheImage", function(name:String) {
				if (ModpackMaker.inModpackMaker){
					ModpackMaker.luaImageList.push(name);
				}
				else{
					Paths.returnGraphic(name);
				}
			});

			Lua_helper.add_callback(lua, "getProperty", function(variable:String) {
				return 0;
			});

			Lua_helper.add_callback(lua, "getPropertyFromClass", function(variable:String) {
				return true;
			});

			Lua_helper.add_callback(lua, "getColorFromHex", function(color:String) {
				if(!color.startsWith('0x')) color = '0xff' + color;
				return Std.parseInt(color);
			});

			// because sink
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

			Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String) {
				if (ModpackMaker.inModpackMaker){
					ModpackMaker.luaFontList.push(newFont);
				}
			});

			Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapDataPath:String) {
				#if (!flash && MODS_ALLOWED && sys)
				if (ModpackMaker.inModpackMaker){
					ModpackMaker.luaImageList.push(bitmapDataPath);
				}
				else{
					Paths.returnGraphic(bitmapDataPath);
				}
				#end
			});

			Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic) {
				var killMe:Array<String> = variable.split('.');
			
				if (ModpackMaker.inModpackMaker){
					if (variable.contains('altSuffix') || variable.contains('altPrefix')){
						var checkFiles:Array<String> = ["intro1", "intro2", "intro3", "introGo"];
						
						for (snd in checkFiles){
							ModpackMaker.luaSoundList.push((variable.contains('altSuffix') ? snd + value : value + snd));
						}
					}
				}
				
				return true;
			});

			Lua_helper.add_callback(lua, "playSound", function(sound:String, ?volume:Float = 1, ?tag:String = null) {
				if (ModpackMaker.inModpackMaker){
					ModpackMaker.luaSoundList.push(sound);
				}
			});

			Lua_helper.add_callback(lua, "getRunningScripts", function(){
				var runningScripts:Array<String> = [];
			
				return runningScripts;
			});
	
			//because we have to add em otherwise it'll only load the first sprite... for most luas. if you set it up where you make the sprites first and then all the formatting stuff ->
			//then it shouldn't be a problem
			
			var otherCallbacks:Array<String> = ['makeGraphic', 'objectPlayAnimation', "makeLuaCharacter", "playAnim", "getMapKeys"];
			var addCallbacks:Array<String> = ['addAnimationByPrefix', 'addAnimationByIndices', 'addAnimationByIndicesLoop', 'addLuaSprite', 'addLuaText', "addOffset", "addClipRect", "addAnimation"];
			var setCallbacks:Array<String> = ['setScrollFactor', 'setObjectCamera', 'scaleObject', 'screenCenter', 'setTextSize', 'setTextBorder', 'setTextString', "setTextAlignment", "setTextColor", "setPropertyFromClass", "setBlendMode"];
			var shaderCallbacks:Array<String> = ["runHaxeCode", "addHaxeLibrary", "initLuaShader", "setSpriteShader", "setShaderFloat", "setShaderFloatArray", "setShaderBool", "setShaderBoolArray", "setGlobalFromScript", "triggerEvent"];
		
			otherCallbacks = otherCallbacks.concat(addCallbacks);
			otherCallbacks = otherCallbacks.concat(setCallbacks);
			otherCallbacks = otherCallbacks.concat(shaderCallbacks);

			for (i in 0...otherCallbacks.length){
				Lua_helper.add_callback(lua, otherCallbacks[i], function(?val1:String){
					//do almost nothing
					return true;
				});
			}

			var numberCallbacks:Array<String> = ["getObjectOrder", "setObjectOrder"];

			for (i in 0...numberCallbacks.length){
				Lua_helper.add_callback(lua, numberCallbacks[i], function(?val1:String){
					//do almost nothing
					return 0;
				});
			}
		}
		else
		{
			Lua_helper.add_callback(lua,"doFunction", doFunction);
			Lua_helper.add_callback(lua,"changeDadCharacter", changeDadCharacter);
			Lua_helper.add_callback(lua,"changeBoyfriendCharacter", changeBoyfriendCharacter);
			Lua_helper.add_callback(lua,"changeGFCharacter", changeGFCharacter);
			Lua_helper.add_callback(lua,"changeStage", changeStage);
			Lua_helper.add_callback(lua,"changeDadCharacterBetter", changeDadCharacterBetter);
			Lua_helper.add_callback(lua,"changeBoyfriendCharacterBetter", changeBoyfriendCharacterBetter);
			Lua_helper.add_callback(lua,"changeGFCharacterBetter", changeGFCharacterBetter);

			//the auto stuff
			Lua_helper.add_callback(lua,"changeBFAuto", changeBFAuto);
	
			//cuz sometimes i type boyfriend instead of bf
			Lua_helper.add_callback(lua,"changeBoyfriendAuto", changeBFAuto);
	
			Lua_helper.add_callback(lua,"changeDadAuto", changeDadAuto);
	
			Lua_helper.add_callback(lua,"changeGFAuto", changeGFAuto);
	
			Lua_helper.add_callback(lua,"changeStageOffsets", changeStageOffsets);
	
			Lua_helper.add_callback(lua,"fileExists", function(key:String) {
				if(FileSystem.exists(FileSystem.absolutePath(key))) {
					return true;
				}
				return false;
			});
	
			Lua_helper.add_callback(lua, "toggleCamFilter", function(bool:Bool, camera:String = '') {
				LuaUtils.cameraFromString(camera).filtersEnabled = bool;
			});
	
			Lua_helper.add_callback(lua, "setVar", function(varName:String, value:Dynamic) {
				PlayState.instance.variables.set(varName, value);
				return value;
			});
			
			Lua_helper.add_callback(lua, "getVar", function(varName:String) {
				return PlayState.instance.variables.get(varName);
			});	
	
			Lua_helper.add_callback(lua, "addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false, ?traceMsg:Bool = true) { //would be dope asf. 
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
							{
								if(traceMsg)
									luaTrace('The lua script "' + cervix + '" is already running!');
	
								return;
							}
						}
					}
					PlayState.instance.luaArray.push(new ModchartState(cervix)); 
					return;
				}
				luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
			});

			Lua_helper.add_callback(lua, "addHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false, ?traceMsg:Bool = true) { //I wonder if this will cause a crash -- future me here. okay it didn't.
				var cervix = luaFile + ".hx";
				var scriptFound = false;
				if(FileSystem.exists(FileSystem.absolutePath("assets/shared/"+cervix))) {
					cervix = FileSystem.absolutePath("assets/shared/"+cervix);
					scriptFound = true;
				}
				else if (FileSystem.exists(Paths.modFolders(cervix)))
				{
					cervix = Paths.modFolders(cervix);
					scriptFound = true;
				}
				else {
					cervix = Paths.getPreloadPath(cervix);
					if(FileSystem.exists(cervix)) {
						scriptFound = true;
					}
				}

				if(scriptFound)
				{
					if(!ignoreAlreadyRunning)
						for (script in PlayState.instance.hscriptArray)
							if(script.origin == cervix)
							{
								if(traceMsg) luaTrace('The hscript script "' + cervix + '" is already running!');
								return;
							}

					PlayState.instance.initHScript(cervix);
					return;
				}
				luaTrace("addHScript: Script doesn't exist!", false, false, FlxColor.RED);
			});

			Lua_helper.add_callback(lua, "removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf. 
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
							{
								//luaTrace('The script "' + cervix + '" is already running!');
								
									PlayState.instance.luaArray.remove(luaInstance); 
								return;
							}
						}
	
						for (luaInstance in PlayState.instance.Stage.luaArray)
						{
							if(luaInstance.scriptName == cervix)
							{
								//luaTrace('The script "' + cervix + '" is already running!');
								
									PlayState.instance.Stage.luaArray.remove(luaInstance); 
								return;
							}
						}
					}
					return;
				}
				luaTrace("removeLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
			});

			Lua_helper.add_callback(lua, "removeHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf. 
				var cervix = luaFile + ".hx";
				var scriptFound = false;
				if(FileSystem.exists(FileSystem.absolutePath("assets/shared/"+cervix))) {
					cervix = FileSystem.absolutePath("assets/shared/"+cervix);
					scriptFound = true;
				}
				else if (FileSystem.exists(Paths.modFolders(cervix)))
				{
					cervix = Paths.modFolders(cervix);
					scriptFound = true;
				}
				else {
					cervix = Paths.getPreloadPath(cervix);
					if(FileSystem.exists(cervix)) {
						scriptFound = true;
					}
				}
	
				if(scriptFound)
				{
					if(!ignoreAlreadyRunning)
					{
						for (script in PlayState.instance.hscriptArray)
							if(script.origin == cervix)
							{
								//trace('Closing script ' + (script.origin != null ? script.origin : luaFile));
								script.destroy();
								return;
							}
					}
					return;
				} 
				luaTrace("removeHScript: Script doesn't exist!", false, false, FlxColor.RED);
			});
	
			//because the regular close function isn't working for me
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
				luaTrace("closeLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
			});
	
			Lua_helper.add_callback(lua, "getRunningScripts", function(){
				var runningScripts:Array<String> = [];
				for (idx in 0...PlayState.instance.luaArray.length)
					runningScripts.push(PlayState.instance.luaArray[idx].scriptName);
	
	
				return runningScripts;
			});

			Lua_helper.add_callback(lua, "getRunningHScripts", function(){
				var runningScripts:Array<String> = [];
				for (idx in 0...PlayState.instance.hscriptArray.length)
					runningScripts.push(PlayState.instance.hscriptArray[idx].scriptFile);
	
	
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

			Lua_helper.add_callback(lua, "callOnHScript", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
				if(excludeScripts == null) excludeScripts = [];
				if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
				PlayState.instance.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});

			Lua_helper.add_callback(lua, "callOnScripts", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
				if(excludeScripts == null) excludeScripts = [];
				if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
				PlayState.instance.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
	
			Lua_helper.add_callback(lua, "callScript", function(?luaFile:String, ?funcName:String, ?args:Array<Dynamic>){
				if(luaFile==null){
					#if (linc_luajit >= "0.0.6")
					LuaL.error(lua, "bad argument #1 to 'callScript' (string expected, got nil)");
					#end
					return null;
				}
				if(funcName==null){
					#if (linc_luajit >= "0.0.6")
					LuaL.error(lua, "bad argument #2 to 'callScript' (string expected, got nil)");
					#end
					return null;
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
	
							return null;
						}
	
					}
				}
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

							var ret = Convert.fromLua(luaInstance.lua, -1);
							Lua.pop(luaInstance.lua,1); // remove the global

							return ret;
						}
	
					}
				}
				return null;
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
				return null;
			});

			Lua_helper.add_callback(lua, "setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
				if(exclusions == null) exclusions = [];
				if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
				PlayState.instance.setOnLuas(varName, arg, exclusions);
			});

			Lua_helper.add_callback(lua, "setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
				if(exclusions == null) exclusions = [];
				if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
				PlayState.instance.setOnHScript(varName, arg, exclusions);
			});

			Lua_helper.add_callback(lua, "setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) { //why not.
				if(exclusions == null) exclusions = [];
				if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
				PlayState.instance.setOnScripts(varName, arg, exclusions);
			});

			Lua_helper.add_callback(lua,"animationSwap", function(char:String, anim1:String, anim2:String) {
				var shit = LuaUtils.getObjectDirectly(char);
	
				if (shit.animation.getByName(anim1) != null)
				{
					var oldRight = shit.animation.getByName(anim1).frames;
					shit.animation.getByName(anim1).frames = shit.animation.getByName(anim2).frames;
					shit.animation.getByName(anim2).frames = oldRight;
				}
			});
	
			Lua_helper.add_callback(lua,"destroyObject", function(id:String, ?bg:Bool = false) {
				if (bg)
					PlayState.instance.Stage.destroyObject(PlayState.instance.Stage.swagBacks[id]);
				else
				{
					var shit:Dynamic = LuaUtils.getObjectDirectly(id);
					PlayState.instance.destroyObject(shit);
				}
			});
	
			Lua_helper.add_callback(lua,"removeGroupObject", function(obj:String, index:Int = 0) {
				var shit:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
	
				shit.forEach(function(spr:Dynamic)
				{			
					if (spr.ID == index)		
						PlayState.instance.removeObject(spr);
				});
			});
	
			Lua_helper.add_callback(lua,"destroyGroupObject", function(obj:String, index:Int = 0) {
				//i have no idea if this works.... it works
				var shit:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
	
				shit.forEach(function(spr:Dynamic)
				{			
					if (spr.ID == index)		
						spr.destroy();
				});
			});
	
			Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true) {
				if(!PlayState.instance.modchartSprites.exists(tag) && !Stage.instance.swagBacks.exists(tag)) {
					return;
				}
				

				var pee:FlxSprite = (Stage.instance.swagBacks.exists(tag) ? Stage.instance.swagBacks.get(tag) : PlayState.instance.modchartSprites.get(tag));
				if(destroy) {
					pee.kill();
				}
	
				LuaUtils.getTargetInstance().remove(pee, true);
				if(destroy) {
					pee.destroy();
					PlayState.instance.modchartSprites.remove(tag);
				}
			});
	
			Lua_helper.add_callback(lua, "removeLuaIcon", function(tag:String, destroy:Bool = true) {
				if(!PlayState.instance.modchartIcons.exists(tag)) {
					return;
				}
				
				var pee:HealthIcon = PlayState.instance.modchartIcons.get(tag);
				if(destroy) {
					pee.kill();
				}
	
				LuaUtils.getTargetInstance().remove(pee, true);
				if(destroy) {
					pee.destroy();
					PlayState.instance.modchartIcons.remove(tag);
				}
			});
	
			Lua_helper.add_callback(lua, "getSongPosition", function() {
				return Conductor.songPosition;
			});
	
			Lua_helper.add_callback(lua,"setScrollFactor", function(obj:String , scrollX:Float, scrollY:Float, ?bg:Bool = false) {
				if(LuaUtils.getObjectDirectly(obj)!=null) {
					LuaUtils.getObjectDirectly(obj).scrollFactor.set(scrollX, scrollY);
					return;
				}
	
				var object:FlxObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
				if(object != null) {	
					object.scrollFactor.set(scrollX, scrollY);
				}
			});
	
			Lua_helper.add_callback(lua,"getScrollFactor", function(id:String , x:String) {
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				(x == 'x' ? return shit.scrollFactor.x : return shit.scrollFactor.y);
			});
	
			Lua_helper.add_callback(lua,"changeAnimOffset", function(id:String , x:Float, y:Float) {
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				shit.addOffset(x, y); // it may say addoffset but it actually changes it instead of adding to the existing offset so this works.
			});
	
			//the better version
			Lua_helper.add_callback(lua, "addOffset", function(obj:String, anim:String, x:Float, y:Float) {
				if (LuaUtils.getObjectDirectly(obj) != null){
					var spr = LuaUtils.getObjectDirectly(obj);

					if (Std.isOfType(spr, ModchartSprite)){
						spr.animOffsets.set(anim, [x,y]);	
					}

					if (Std.isOfType(spr, Character)){
						spr.addOffset(anim, [x,y]);	
					}

					return true;
				}

				if(PlayState.instance.modchartSprites.exists(obj)) {
					PlayState.instance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
					return true;
				}
	
				var mChar:Character = PlayState.instance.modchartCharacters.get(obj);
				if(mChar != null) {
					mChar.addOffset(anim, x, y);
					return true;
				}
	
				var char:Character = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
				if(char != null) {
					char.addOffset(anim, x, y);
					return true;
				}
				return false;
			});
	
	
			Lua_helper.add_callback(lua,"checkDownscroll", function() {
				return FlxG.save.data.downscroll;
			});
	
			Lua_helper.add_callback(lua,"getScared", function(id:String) {
				PlayState.instance.Stage.swagBacks[id].getScared();
			});
	
			// hud/camera

			Lua_helper.add_callback(lua, "setHealthBarColors", function(left:String, right:String) {
				var left_color:Null<FlxColor> = null;
				var right_color:Null<FlxColor> = null;
				if (left != null && left != '')
					left_color = CoolUtil.colorFromString(left);
				if (right != null && right != '')
					right_color = CoolUtil.colorFromString(right);

				PlayState.instance.healthBar.createFilledBar(left_color, right_color);
				PlayState.instance.healthBar.updateBar();
			});

			Lua_helper.add_callback(lua, "setTimeBarColors", function(left:String, right:String) {
				var left_color:Null<FlxColor> = null;
				var right_color:Null<FlxColor> = null;
				if (left != null && left != '')
					left_color = CoolUtil.colorFromString(left);
				if (right != null && right != '')
					right_color = CoolUtil.colorFromString(right);
				
				PlayState.instance.timeBar.createFilledBar(left_color, right_color);
				PlayState.instance.timeBar.updateBar();
			});	
	
			Lua_helper.add_callback(lua,"getDominantColor", function(sprite:String){
				var shit:Dynamic = LuaUtils.getObjectDirectly(sprite);
	
				var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(shit));
				var daColor = coolColor.toHexString();
	
				return daColor;
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
				if((tag == null || tag.length < 1) && FlxG.sound.music != null)
					FlxG.sound.music.stop();
				else if (tag == 'vocals')
					PlayState.instance.vocals.stop();
				else if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
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
				if(PlayState.instance == FlxG.state){duration = duration / PlayState.instance.playbackRate;}

				if(tag == null || tag.length < 1) {
					FlxG.sound.music.fadeIn(duration, fromValue, toValue);
				} else if(PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
				}
				
			});
			Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
				if(PlayState.instance == FlxG.state){duration = duration / PlayState.instance.playbackRate;}
				
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

			Lua_helper.add_callback(lua, "getSoundPitch", function(tag:String) {
				if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
					return PlayState.instance.modchartSounds.get(tag).pitch;
				}
				return 0;
			});
			Lua_helper.add_callback(lua, "setSoundPitch", function(tag:String, value:Float, doPause:Bool = false) {
				if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
					var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
					if(theSound != null) {
						var wasResumed:Bool = theSound.playing;
						if (doPause) theSound.pause();
						theSound.pitch = value;
						if (doPause && wasResumed) theSound.play();
					}
				}
			});
	
			Lua_helper.add_callback(lua, "close", function(printMessage:Bool = false) {
				closed = true;
				return closed;
			});
	
			Lua_helper.add_callback(lua,"changeDadIcon", function(id:String) {
				PlayState.instance.iconP2.changeIcon(id);
			});
	
			Lua_helper.add_callback(lua,"changeBFIcon", function(id:String) {
				PlayState.instance.iconP1.changeIcon(id);
			});
	
			Lua_helper.add_callback(lua,"changeIcon", function(obj:String, iconName:String) {
				var killMe:Array<String> = obj.split('.');
				var object:HealthIcon = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(object != null) {
					object.changeIcon(iconName);
					return true;
				}
				luaTrace("changeIcon: Icon " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return false;
			});
	
			Lua_helper.add_callback(lua,"softCountdown", function(id:String) {
				PlayState.instance.softCountdown(id);
			});
	
			Lua_helper.add_callback(lua,"uncacheObject", function(id:String) {
				Assets.cache.clear(id);
			});
	
			Lua_helper.add_callback(lua,"removeCurrentTrackedAsset", function(id:String) {
				Paths.currentTrackedAssets.remove(id);
			});
	
			Lua_helper.add_callback(lua,"removeCurrentTrackedSound", function(id:String) {
				Paths.currentTrackedSounds.remove(id);
			});
	
			Lua_helper.add_callback(lua,"resetTrail", function(id:String) {
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				shit.resetTrail();
			});
	
			Lua_helper.add_callback(lua,"generateNumberFromRange", function(min:Float, max:Float) {
				return FlxG.random.float(min, max);
			});
	
			Lua_helper.add_callback(lua,"changeDadIconNew", function(id:String) {
				PlayState.instance.iconP2.changeIcon(id);
			});
	
			Lua_helper.add_callback(lua,"changeBFIconNew", function(id:String) {
				PlayState.instance.iconP1.changeIcon(id);
			});
	
			Lua_helper.add_callback(lua,"stopIdle", function(id:String, bool:Bool) {
				if (PlayState.instance.modchartCharacters.exists(id))
				{
					PlayState.instance.modchartCharacters.get(id).stopIdle = bool;
					return;
				}
				LuaUtils.getActorByName(id).stopIdle = bool;
			});
	
			Lua_helper.add_callback(lua,"setDownscroll", function(id:Bool) {
				FlxG.save.data.downscroll = id;
			});
	
			Lua_helper.add_callback(lua,"removeObject", function(id:String) {
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				PlayState.instance.removeObject(shit);
			});
	
			Lua_helper.add_callback(lua,"addObject", function(id:String) {
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				PlayState.instance.addObject(shit);
			});
	
			Lua_helper.add_callback(lua,"changeNotes", function(style:String, character:String, ?noteTypeStyle:String = "") {
				switch (character)
				{
					case 'boyfriend' | 'bf':
						PlayState.instance.notes.forEach(function(daNote:Note)
						{
							if (daNote.mustPress)
							{
								if (daNote.noteType != "")
									PlayState.instance.callOnLuas('onNoteChange', [style, noteTypeStyle]); //i really don't wanna use this but I will if I have to
								else
									daNote.reloadNote(style, noteTypeStyle);
	
								if (daNote.isSustainNote)
								{
									if (FlxG.save.data.downscroll)
										if(daNote.animation.curAnim.name.endsWith('end') && daNote.prevNote != null)
											daNote.y -= daNote.prevNote.height;
										else
											daNote.y -= daNote.height / 2;
									else
										daNote.y += daNote.height/2;
								}
							}
						});
					default:
						PlayState.instance.notes.forEach(function(daNote:Note)
						{
							if (!daNote.mustPress)
							{
								if (daNote.noteType != "")
									PlayState.instance.callOnLuas('onNoteChange', [style, noteTypeStyle]); //i really don't wanna use this but I will if I have to
								else
									daNote.reloadNote(style, noteTypeStyle);
	
								if (daNote.isSustainNote)
								{
									if (FlxG.save.data.downscroll)
										if(daNote.animation.curAnim.name.endsWith('end') && daNote.prevNote != null)
											daNote.y -= daNote.prevNote.height;
										else
											daNote.y -= daNote.height / 2;
									else
										daNote.y += daNote.height/2;
								}
							}
						});
				}
			});
	
			Lua_helper.add_callback(lua,"changeNotes2", function(style:String, character:String, ?noteTypeStyle:String = "") {
				for (i in 0...PlayState.instance.unspawnNotes.length)
				{
					var daNote = PlayState.instance.unspawnNotes[i];
					switch (character)
					{
						case 'boyfriend' | 'bf':
							if (daNote.mustPress)
								daNote.reloadNote(style, noteTypeStyle);
						default:
							if (!daNote.mustPress)
								daNote.reloadNote(style, noteTypeStyle);
					}
				}
			});
	
			Lua_helper.add_callback(lua,"changeIndividualNotes", function(style:String, i:Int, ?noteTypeStyle:String = "") {
				PlayState.instance.unspawnNotes[i].reloadNote(style, noteTypeStyle);
			});
	
			Lua_helper.add_callback(lua,"characterZoom", function(id:String, zoomAmount:Float, ?isSenpai:Bool = false) {
				if(PlayState.instance.modchartCharacters.exists(id)) {
					var spr:Character = PlayState.instance.modchartCharacters.get(id);
					spr.setZoom(zoomAmount, isSenpai);
				}
				else
					LuaUtils.getObjectDirectly(id).setZoom(zoomAmount, isSenpai);
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
				LuaUtils.cameraFromString(camera).fade(c, d, f);
			});

			Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String) {
				var isDad:Bool = false;
				if(target == 'dad') {
					isDad = true;
				}
				PlayState.instance.moveCamera(isDad);
				return isDad;
			});	
	
			Lua_helper.add_callback(lua, "cameraShake", function(camera:String, intensity:Float, duration:Float) {
				if(PlayState.instance == FlxG.state){duration = duration / PlayState.instance.playbackRate;}
				LuaUtils.cameraFromString(camera).shake(intensity, duration);
			});
	
			Lua_helper.add_callback(lua, "objectShake", function(camera:String, intensity:Float, duration:Float) {
				if(PlayState.instance == FlxG.state){duration = duration / PlayState.instance.playbackRate;}
				LuaUtils.getObjectDirectly(camera).shake(intensity, duration);
			});
			
			Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float,forced:Bool) {
				if(PlayState.instance == FlxG.state){duration = duration / PlayState.instance.playbackRate;}
				LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration,null,forced);
			});
			Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float,forced:Bool, ?fadeOut:Bool = false) {
				if(PlayState.instance == FlxG.state){duration = duration / PlayState.instance.playbackRate;}
				LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration,fadeOut,null,forced);
			});
	
			Lua_helper.add_callback(lua, "flashCam", function (r:Int,g:Int,b:Int, d:Float, f:Bool, ?camera:String) {
				var c:FlxColor = new FlxColor();
				c.setRGB(r, g, b);
				LuaUtils.cameraFromString(camera).flash(c, d, f);
			});
	
			Lua_helper.add_callback(lua, "flashCamHUD", function (r:Int,g:Int,b:Int, d:Float, f:Bool) {
				var c:FlxColor = new FlxColor();
				c.setRGB(r, g, b);
				PlayState.instance.camHUD.flash(c, d, f);
			});
	
			Lua_helper.add_callback(lua, "inAndOutCam", function (d:Float, d2:Float, d3:Float, ?camera:String) 
			{
				LuaUtils.cameraFromString(camera).fade(FlxColor.WHITE, d, false, function()
				{
					new FlxTimer().start(d2, function(tmr:FlxTimer)
					{
						LuaUtils.cameraFromString(camera).fade(FlxColor.WHITE, d3, true);
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
	
			Lua_helper.add_callback(lua,"changeCamSpeed", function(camFollowSpeed:Float = 0.04) { //i know psych has that camSpeed stuff but I don't feel like changing to Psych's camera system
				FlxG.camera.follow(PlayState.instance.camFollow, LOCKON, camFollowSpeed * (30 / (cast (Lib.current.getChildAt(0), Main)).getFPS()) * (120 / Main.getFPSStatic()));	
			});
	
			Lua_helper.add_callback(lua,"setCamFollow", function(x:Float, y:Float) {
				PlayState.instance.isCameraOnForcedPos = true;
				PlayState.instance.camFollow.setPosition(x, y);
			});
	
			Lua_helper.add_callback(lua,"offCamFollow", function(id:String) {
				PlayState.instance.isCameraOnForcedPos = false;
			});

			Lua_helper.add_callback(lua,"snapCam", function(x:Float, y:Float) {
				PlayState.instance.isCameraOnForcedPos = true;
				
				var camPosition:FlxObject = new FlxObject(0, 0, 1, 1);
				camPosition.setPosition(x, y);
				FlxG.camera.focusOn(camPosition.getPosition());
			});
	
			Lua_helper.add_callback(lua,"resetSnapCam", function(id:String) {
				//The string does absolutely nothing
				//PlayState.instance.defaultCamFollow = true;
			});

			Lua_helper.add_callback(lua,"cameraSnap", function(camera:String, x:Float, y:Float) {
				PlayState.instance.isCameraOnForcedPos = true;
				
				var camPosition:FlxObject = new FlxObject(0, 0, 1, 1);
				camPosition.setPosition(x, y);
				LuaUtils.cameraFromString(camera).focusOn(camPosition.getPosition());
			});
	
			Lua_helper.add_callback(lua,"stopCameraEffects", function(id:String) { //how convenient
				LuaUtils.cameraFromString(id).stopFX();
			});
	
			Lua_helper.add_callback(lua,"miscCamFollow", function(camera:String, x:Float, y:Float) {
					var camPosition:FlxObject;
					camPosition = new FlxObject(0, 0, 1, 1);
					camPosition.setPosition(x, y);
	
					LuaUtils.cameraFromString(camera).follow(camPosition, LOCKON, 0.04 * (30 / (cast (Lib.current.getChildAt(0), Main)).getFPS()));
			});
	
			// strumline
	
			Lua_helper.add_callback(lua, "setStrumlineY", function(y:Float)
			{
				PlayState.instance.strumLine.y = y;
			});
	
			Lua_helper.add_callback(lua,"getArrayLength", function(obj:String) {
				var shit:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
	
				return shit.length;
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
			
			Lua_helper.add_callback(lua,"setActorScreenCenter", function(id:String, ?pos:String = 'xy') {
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				switch(pos.trim().toLowerCase())
				{
					case 'x': shit.screenCenter(X);	
					case 'y': shit.screenCenter(Y);	
					default: shit.screenCenter(XY);	
				}			
			});
	
			Lua_helper.add_callback(lua,"screenCenter", function(id:String, ?pos:String) { //same thing. just for psych
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				switch(pos.trim().toLowerCase())
				{
					case 'x': shit.screenCenter(X);	
					case 'y': shit.screenCenter(Y);	
					default: shit.screenCenter(XY);	
				}					
			});

			Lua_helper.add_callback(lua, "objectsOverlap", function(obj1:String, obj2:String) {
				var namesArray:Array<String> = [obj1, obj2];
				var objectsArray:Array<FlxSprite> = [];
				for (i in 0...namesArray.length)
				{
					var real = PlayState.instance.getLuaObject(namesArray[i]);
					if(real!=null) {
						objectsArray.push(real);
					} else {
						objectsArray.push(Reflect.getProperty(LuaUtils.getTargetInstance(), namesArray[i]));
					}
				}
	
				if(!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
				{
					return true;
				}
				return false;
			});	
			
			Lua_helper.add_callback(lua,"playActorAnimation", function(obj:String,anim:String,force:Bool = false,reverse:Bool = false, ?frame:Int = 0) {
				var char:Character = LuaUtils.getObjectDirectly(obj);
	
				if (char != null && Std.isOfType(char, Character)){ //what am I doing? of course it'll be a character
					char.playAnim(anim, force, reverse, frame);
					return;
				} 
				luaTrace('playActorAnimation: Couldnt find object: ' + obj, false, false, FlxColor.RED);
			});
	
			Lua_helper.add_callback(lua,"enablePurpleMiss", function(id:String,toggle:Bool) {
				LuaUtils.getActorByName(id).doMissThing = toggle;
			});
	
			Lua_helper.add_callback(lua,"playBGAnimation", function(id:String,anim:String,force:Bool = false,reverse:Bool = false) {
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				shit.animation.play(anim, force, reverse);
			});
	
			Lua_helper.add_callback(lua,"playBGAnimation2", function(id:String,anim:String,force:Bool = false,reverse:Bool = false) {
				LuaUtils.getActorByName(id).animation.play(anim, force, reverse);
			});
	
			Lua_helper.add_callback(lua,"setAltAnim", function(char:String, alt:String){
				switch (char)
				{
					case 'dad' | 'opponent':
						PlayState.instance.dad.altAnim = alt;
					case 'gf' | 'girlfriend':
						PlayState.instance.gf.altAnim = alt;
					default:
						PlayState.instance.boyfriend.bfAltAnim = alt;
				}
			
			});
	
			Lua_helper.add_callback(lua,"flickerSprite", function (id:String, duration:Float, interval:Float) {
				if(PlayState.instance == FlxG.state){duration = duration / PlayState.instance.playbackRate;}
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				FlxFlicker.flicker(shit, duration, interval);
			});
	
			Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, ?y:Int = 0, ?updateHitbox:Bool = true) {
				if(PlayState.instance.getLuaObject(obj)!=null) {
					var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
					shit.setGraphicSize(x, y);
					if(updateHitbox) shit.updateHitbox();
					return;
				}

				if (Stage.instance.swagBacks.exists(obj)){
					trace('oh shit we found it.');
					return Stage.instance.setGraphicSize(obj, x);
				}
	
				var killMe:Array<String> = obj.split('.');
				var poop:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(poop != null) {
					poop.setGraphicSize(x, y);
					if(updateHitbox) poop.updateHitbox();
					return;
				}
				luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
			});
	
			Lua_helper.add_callback(lua,"stopGFDance", function(stop:Bool) {
				PlayState.instance.picoCutscene = stop;
			});
	
			Lua_helper.add_callback(lua,"isPixel", function(change:Bool) {
				PlayState.isPixel = change;
			});

			Lua_helper.add_callback(lua,"getCameraZoom", function (id:String) {
				return PlayState.instance.defaultCamZoom;
			});

			Lua_helper.add_callback(lua, "getMouseX", function(camera:String) {
				var cam:FlxCamera = LuaUtils.cameraFromString(camera);
				return FlxG.mouse.getScreenPosition(cam).x;
			});
			Lua_helper.add_callback(lua, "getMouseY", function(camera:String) {
				var cam:FlxCamera = LuaUtils.cameraFromString(camera);
				return FlxG.mouse.getScreenPosition(cam).y;
			});
	
			Lua_helper.add_callback(lua, "getMidpointX", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
				if(obj != null) return obj.getMidpoint().x;
	
				return 0;
			});
			Lua_helper.add_callback(lua, "getMidpointY", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
				if(obj != null) return obj.getMidpoint().y;
	
				return 0;
			});
			Lua_helper.add_callback(lua, "getGraphicMidpointX", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
				if(obj != null) return obj.getGraphicMidpoint().x;
	
				return 0;
			});
			Lua_helper.add_callback(lua, "getGraphicMidpointY", function(variable:String) {
				var killMe:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
				if(obj != null) return obj.getGraphicMidpoint().y;
	
				return 0;
			});
	
			Lua_helper.add_callback(lua, "getMouseX", function(camera:String) {
				var cam:FlxCamera = LuaUtils.cameraFromString(camera);
				return FlxG.mouse.getScreenPosition(cam).x;
			});
			Lua_helper.add_callback(lua, "getMouseY", function(camera:String) {
				var cam:FlxCamera = LuaUtils.cameraFromString(camera);
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
	
			Lua_helper.add_callback(lua, "RGBColor", function (r:Int,g:Int,b:Int, alpha:Int = 255) {
				return FlxColor.fromRGB(r, g, b, alpha);
			});
	
			Lua_helper.add_callback(lua, "getStageXOffsets", function (char:String, value:String) {
				switch (char)
				{
					case 'boyfriend' | 'bf':
						return (value == 'y' ? PlayState.instance.Stage.bfYOffset : PlayState.instance.Stage.bfXOffset);
					case 'gf':
						return (value == 'y' ? PlayState.instance.Stage.gfYOffset : PlayState.instance.Stage.gfXOffset);
					default:
						return (value == 'y' ? PlayState.instance.Stage.dadYOffset : PlayState.instance.Stage.dadXOffset);
				}
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
	
			Lua_helper.add_callback(lua,"playStrumAnim", function(isDad:Bool, id:Int, ?time:Float = 0.15) {
				PlayState.instance.StrumPlayAnim(isDad, id, time);	
			});
		
			Lua_helper.add_callback(lua, "startCountdown", function(variable:String) {
				PlayState.instance.startCountdown();
			});
	
			Lua_helper.add_callback(lua, "resetState", function(variable:String) { // monochrome
				MusicBeatState.resetState();
			});
	
			Lua_helper.add_callback(lua, "startSong", function(variable:String) {
				PlayState.instance.startSong();
			});
	
			Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, music:String = null) {
				var path:String;
				#if MODS_ALLOWED
				path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
				if(!FileSystem.exists(path))
				#end
					path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
	
				luaTrace('startDialogue: Trying to load dialogue: ' + path);
	
				#if MODS_ALLOWED
				if(FileSystem.exists(path))
				#else
				if(Assets.exists(path))
				#end
				{
					var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
					if(shit.dialogue.length > 0) {
						PlayState.instance.startDialogue(shit, music);
						luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
						return true;
					} else {
						luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
					}
				} else {
					luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
					if(PlayState.instance.endingSong) {
						PlayState.instance.endSong();
					} else {
						PlayState.instance.startCountdown();
					}
				}
				return false;
			});
			
			Lua_helper.add_callback(lua, "startVideo", function(videoFile:String, ?skippable:Bool = true) {
				#if VIDEOS_ALLOWED
				if(FileSystem.exists(Paths.video(videoFile))) {
					PlayState.instance.startVideo(videoFile, skippable);
					return true;
				} else {
					luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
				}
				return false;
	
				#else
				if(PlayState.instance.endingSong) {
					PlayState.instance.endSong();
				} else {
					PlayState.instance.startCountdown();
				}
				return true;
				#end
			});

			Lua_helper.add_callback(lua, "makeVideoSprite", function(tag:String, videoFile:String, ?x:Float, ?y:Float, ?camera:String="camGame", ?shouldLoop:Bool=false, ?muted:Bool=true) {
                // I hate you FlxVideoSprite....
                #if VIDEOS_ALLOWED
                tag = tag.replace('.', '');
                LuaUtils.resetSpriteTag(tag);
                var leVSprite:PsychVideoSprite = null;
                if(FileSystem.exists(Paths.video(videoFile)) && videoFile != null && videoFile.length > 0) {

                    leVSprite = new PsychVideoSprite();
                    leVSprite.addCallback('onFormat',()->{
                        leVSprite.setPosition(x,y);
                        leVSprite.cameras = [LuaUtils.cameraFromString(camera)];
                    });
                    leVSprite.addCallback('onEnd',()->{
                        if (Stage.instance.swagBacks.exists(tag)) {
                            Stage.instance.swagBacks.get(tag).destroy();
                            Stage.instance.swagBacks.remove(tag);
                        }

                        if (PlayState.instance.modchartSprites.exists(tag)) {
                            PlayState.instance.modchartSprites.get(tag).destroy();
                            PlayState.instance.modchartSprites.remove(tag);
                        }
                            
                        PlayState.instance.callOnLuas('onVideoCompleted', [tag]);
                    });
                    var options:Array<String> = [];
                    if (shouldLoop) options.push(PsychVideoSprite.looping);
                    if (muted) options.push(PsychVideoSprite.muted);

                    leVSprite.load(Paths.video(videoFile), options);
                    leVSprite.antialiasing = true;
                    leVSprite.play();

                    if (isStageLua && !preloading){
                        Stage.instance.swagBacks.set(tag, leVSprite);
                    }
                    else{
                        PlayState.instance.modchartSprites.set(tag, leVSprite);
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

			Lua_helper.add_callback(lua, "endSong", function(hmm:String) {
				PlayState.instance.KillNotes();
				PlayState.instance.endSong();
			});

			Lua_helper.add_callback(lua, "restartSong", function(?skipTransition:Bool = false,?cutscene:Bool = false,?preloadAgain:Bool = false) {
				PlayState.instance.persistentUpdate = false;
				FlxG.camera.followLerp = 0;
				if(skipTransition == true) PauseSubState.restartSong(false,cutscene,preloadAgain);
				else PauseSubState.restartSong(skipTransition,cutscene,preloadAgain);
				return true;
			});

			Lua_helper.add_callback(lua, "exitSong", function(?skipTransition:Bool = false) {
				if(skipTransition)
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
				}

				if(PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());

				if (PlayState.isBETADCIU){
					if (CoolUtil.difficulties[0] == "Guest")
						MusicBeatState.switchState(new states.GuestBETADCIUState());
					else
						MusicBeatState.switchState(new states.BETADCIUState());
				}else{
					if (PlayState.isBonus)		
						MusicBeatState.switchState(new states.BonusSongsState());
					else if (PlayState.isNeonight)
						MusicBeatState.switchState(new states.NeonightState());
					else if (PlayState.isVitor)
						MusicBeatState.switchState(new states.VitorState());
					else
						MusicBeatState.switchState(new states.FreeplayState());
				}

				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
	
				PlayState.changedDifficulty = false;
				PlayState.chartingMode = false;
				PlayState.instance.transitioning = true;
				FlxG.camera.followLerp = 0;

				FlxTransitionableState.skipNextTransIn = false;//visual bug fix
				FlxTransitionableState.skipNextTransOut = false;//visual bug fix

				return true;
			});
	
			//idk if I wanna add events. alright I added the ones that are usable without that much tinkering.
			Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic, ?arg3:Dynamic = "") {
				var value1:String = arg1;
				var value2:String = arg2;
				var value3:String = arg3;
				
				PlayState.instance.triggerEventNote(name, value1, value2, value3);
			});
	
			Lua_helper.add_callback(lua, "arrayContains", function(obj:String, value:Dynamic) {
				var leArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
	
				if (leArray.contains(value))
					return true;
	
				return false;
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
					real.cameras = [LuaUtils.cameraFromString(camera)];
					return true;
				}
	
				if (Stage.instance.swagBacks.exists(obj)) //LET'S GOOOOO IT WORKSS!!!!!!
				{
					var real:FlxSprite = changeSpriteClass(Stage.instance.swagBacks.get(obj));

					if(real != null){
						real.cameras = [LuaUtils.cameraFromString(camera)];
						return true;
					}
				}
	
				var killMe:Array<String> = obj.split('.');
				var object:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(object != null) {
					object.cameras = [LuaUtils.cameraFromString(camera)];
					return true;
				}
				luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return false;
			});
	
			Lua_helper.add_callback(lua, "setBlendMode", function(obj:String, blend:String = '') {
				var shit:Dynamic = LuaUtils.getObjectDirectly(obj);
				if(shit != null) {
					shit.blend = LuaUtils.blendModeFromString(blend);
					return true;
				}
				luaTrace("setBlendMode: Object " + obj + " doesn't exist!");
				return false;
			});
	
			Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
				if(PlayState.instance == FlxG.state){time = time / PlayState.instance.playbackRate;}
				LuaUtils.cancelTimer(tag);
				PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
					if(tmr.finished) {
						PlayState.instance.modchartTimers.remove(tag);
					}
					PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
					//trace('Timer Completed: ' + tag);
				}, loops));
			});
			
			Lua_helper.add_callback(lua, "cancelTimer", function(tag:String) {
				LuaUtils.cancelTimer(tag);
			});
	
			Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String) {
				var charType:Int = 0;
				switch(type.toLowerCase()) {
					case 'dad': charType = 1;
					case 'gf' | 'girlfriend': charType = 2;
				}

				PlayState.instance.charactersToLoad.push(name);
				PlayState.instance.startCharacterLua(name);
			});
	
			Lua_helper.add_callback(lua, "startCharLua", function(name:String) {
				PlayState.instance.startCharacterLua(name);
			});
	
			Lua_helper.add_callback(lua, "precacheSound", function(name:String, ?path:String = "sounds") {
				Paths.returnSound(path, name);
			});
	
			Lua_helper.add_callback(lua, "precacheImage", function(name:String) {
				Paths.returnGraphic(name);
			});

			Lua_helper.add_callback(lua, "precacheFont", function(name:String) {
				return name; // this doesn't actually preload the font.	
			});

			Lua_helper.add_callback(lua, "loadSong", function(?name:String = null, ?difficultyNum:Int = -1) {
				if(name == null || name.length < 1)
					name = PlayState.SONG.song;
				if (difficultyNum == -1)
					difficultyNum = PlayState.storyDifficulty;
	
				var poop = Highscore.formatSong(name, difficultyNum);
				PlayState.SONG = Song.loadFromJson(poop, name);
				PlayState.storyDifficulty = difficultyNum;
				PlayState.instance.persistentUpdate = false;
				LoadingState.loadAndSwitchState(new PlayState());
	
				FlxG.sound.music.pause();
				FlxG.sound.music.volume = 0;
				if(PlayState.instance.vocals != null)
				{
					PlayState.instance.vocals.pause();
					PlayState.instance.vocals.volume = 0;
				}
			});
	
			Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String, ?gridX:Int, ?gridY:Int) {
				var killMe:Array<String> = variable.split('.');
				var spr:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
				var gX = gridX==null?0:gridX;
				var gY = gridY==null?0:gridY;
				var animated = gX!=0 || gY!=0;
	
				if(killMe.length > 1) {
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(spr != null && image != null && image.length > 0)
				{
					spr.loadGraphic(Paths.returnGraphic(image), animated, gX, gY);
				}
			});
			Lua_helper.add_callback(lua, "loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
				var killMe:Array<String> = variable.split('.');
				var spr:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(spr != null && image != null && image.length > 0)
				{
					loadFrames(spr, image, spriteType);
				}
			});
	
			Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
				tag = tag.replace('.', '');
				LuaUtils.resetSpriteTag(tag);
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
	
				if (isStageLua && !preloading){
					Stage.instance.swagBacks.set(tag, leSprite);
				}
				else{
					PlayState.instance.modchartSprites.set(tag, leSprite);
				}
			});

			Lua_helper.add_callback(lua, "makeLuaSprite2", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
				tag = tag.replace('.', '');
				LuaUtils.resetSpriteTag(tag);
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
				leSprite.active = false;
	
				if (isStageLua && !preloading){
					Stage.instance.swagBacks.set(tag, leSprite);
				}
				else{
					PlayState.instance.modchartSprites.set(tag, leSprite);
				}
			});
	
			Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float,spriteType:String="sparrow") {
				tag = tag.replace('.', '');
				LuaUtils.resetSpriteTag(tag);
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
	
				loadFrames(leSprite, image, spriteType);
				if (isStageLua && !preloading){
					Stage.instance.swagBacks.set(tag, leSprite);
				}
				else{
					PlayState.instance.modchartSprites.set(tag, leSprite);
				}
				leSprite.antialiasing = true;
				leSprite.active = true;
			});

			Lua_helper.add_callback(lua, "makeLuaBackdrop", function(tag:String, image:String, x:Float, y:Float, ?axes:String = "XY") {
				tag = tag.replace('.', '');
				LuaUtils.resetSpriteTag(tag);
				var leSprite:ModchartBackdrop = null;
				if(image != null && image.length > 0) {
	
					var rawPic:Dynamic;
	
					if (!Paths.currentTrackedAssets.exists(image))
						Paths.cacheImage(image);
	
					rawPic = Paths.currentTrackedAssets.get(image);	
					
					leSprite = new ModchartBackdrop(rawPic, FlxAxes.fromString(axes), Std.int(x), Std.int(y));
				}
	
				if (leSprite == null)
					return;
	
				leSprite.antialiasing = true;
				if (isStageLua && !preloading){
					Stage.instance.swagBacks.set(tag, leSprite);
				}
				else{
					PlayState.instance.modchartSprites.set(tag, leSprite);
				}
				leSprite.active = true;
			});
	
			Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
				var spr:FlxSprite = LuaUtils.getObjectDirectly(obj, false);
				if(spr != null) spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
			});
	
			Lua_helper.add_callback(lua, "addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:Any, framerate:Int = 24, loop:Bool = false) {
				return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
			});

			Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
				if(LuaUtils.getObjectDirectly(obj)!=null) {
					var cock:FlxSprite = LuaUtils.getObjectDirectly(obj);
					cock.animation.addByPrefix(name, prefix, framerate, loop);
					if(cock.animation.curAnim == null) {
						cock.animation.play(name, true);
					}
					return;
				}
	
				var cock:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
				if(cock != null) {
					cock.animation.addByPrefix(name, prefix, framerate, loop);
					if(cock.animation.curAnim == null) {
						cock.animation.play(name, true);
					}
				}
			});
	
			Lua_helper.add_callback(lua, "addAnimation", function(obj:String, name:String, indices:String, framerate:Int = 24, loop:Bool = true) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
	
				if(LuaUtils.getObjectDirectly(obj)!=null) {
					var cock:FlxSprite = LuaUtils.getObjectDirectly(obj);
					cock.animation.add(name, die, framerate, loop);
					if(cock.animation.curAnim == null) {
						cock.animation.play(name, true);
					}
					return;
				}
				
				var cock:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
				if(cock != null) {
					cock.animation.add(name, die, framerate, loop);
					if(cock.animation.curAnim == null) {
						cock.animation.play(name, true);
					}
				}
			});
	
			Lua_helper.add_callback(lua, "getColorFromString", function(color:String) return FlxColor.fromString(color));

			Lua_helper.add_callback(lua, "getColorFromHex", function(color:String) {
				return CoolUtil.colorFromString(color);
			});
	
			Lua_helper.add_callback(lua, "objectColorTransform", function(obj:String, color:String) {
				var spr:Dynamic = LuaUtils.getObjectDirectly(obj);
	
				if(spr != null) {
					spr.useColorTransform = true;
	
					var daColor:String = color;
					if(!color.startsWith('0x')) daColor = '0xff'+color;
	
					var r, g, b, a:Int = 255;
	
					daColor = daColor.substring(2);
	
					r = Std.parseInt('0x' + daColor.substring(2,4));
					g = Std.parseInt('0x' + daColor.substring(4,6));
					b = Std.parseInt('0x' + daColor.substring(6,8));
					a = Std.parseInt('0x' + daColor.substring(0,2));
	
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
	
			Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, place:Dynamic = false) {
				if (isStageLua)
				{
					if (Stage.instance.swagBacks.exists(tag))
					{
						var shit = Stage.instance.swagBacks.get(tag);
			
						if (place == -1 || place == false || place == "false")
							Stage.instance.toAdd.push(shit);
						else
						{
							if (place == true || place == "true"){place = 2;}
							Stage.instance.layInFront[place].push(shit);
						}
					}
				}
				else
				{
					if(PlayState.instance.modchartSprites.exists(tag)) {
						var shit:Dynamic = PlayState.instance.modchartSprites.get(tag);

						if((Std.isOfType(shit, ModchartSprite) && !shit.wasAdded) || !Std.isOfType(shit, ModchartSprite)) {
							if(place == 2 || place == true)
							{
								LuaUtils.getTargetInstance().add(shit);
							}
							else
							{
								var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gf);
								if(PlayState.instance.members.indexOf(PlayState.instance.boyfriend) < position) {
									position = PlayState.instance.members.indexOf(PlayState.instance.boyfriend);
								} else if(PlayState.instance.members.indexOf(PlayState.instance.dad) < position) {
									position = PlayState.instance.members.indexOf(PlayState.instance.dad);
								}
								PlayState.instance.insert(position, shit);
							}
						}
					}
				}
			});
	
			//wow very convenient
			Lua_helper.add_callback(lua, "makeHealthIcon", function(tag:String, character:String, player:Bool = false) {
				tag = tag.replace('.', '');
				LuaUtils.resetIconTag(tag);
				var leSprite:HealthIcon = new HealthIcon(character, player);
				PlayState.instance.modchartIcons.set(tag, leSprite); //yes
				var shit:HealthIcon = PlayState.instance.modchartIcons.get(tag);
				shit.cameras = [PlayState.instance.camHUD];
				LuaUtils.getTargetInstance().add(shit);
			});
	
			Lua_helper.add_callback(lua, "changeAddedIcon", function(tag:String, character:String){
				var shit:HealthIcon = PlayState.instance.modchartIcons.get(tag);
				shit.changeIcon(character);
			});
			
			//because the naming is stupid
			Lua_helper.add_callback(lua, "makeLuaIcon", function(tag:String, character:String, player:Bool = false) {
				tag = tag.replace('.', '');
				LuaUtils.resetIconTag(tag);
				var leSprite:HealthIcon = new HealthIcon(character, player);
				PlayState.instance.modchartIcons.set(tag, leSprite); //yes
				var shit:HealthIcon = PlayState.instance.modchartIcons.get(tag);
				shit.cameras = [PlayState.instance.camHUD];
				LuaUtils.getTargetInstance().add(shit);
			});
			
			Lua_helper.add_callback(lua, "changeLuaIcon", function(tag:String, character:String){
				var shit:HealthIcon = PlayState.instance.modchartIcons.get(tag);
				shit.changeIcon(character);
			});
	
			Lua_helper.add_callback(lua, "makeLuaCharacter", function(tag:String, character:String, isPlayer:Bool = false, ?flipped:Bool = false) {
				makeLuaCharacter(tag, character, isPlayer, flipped);
			});
	
			Lua_helper.add_callback(lua, "changeLuaCharacter", function(tag:String, character:String){
				var shit:Character = PlayState.instance.modchartCharacters.get(tag);
				makeLuaCharacter(tag, character, shit.isPlayer, shit.flipMode);
			});
	
			Lua_helper.add_callback(lua, "makeLuaTrail", function(tag:String, character:String, color:String) {
				LuaUtils.resetTrailTag(tag);
				if (LuaUtils.getObjectDirectly(character) != null)
				{
					var leObj:Dynamic = LuaUtils.getObjectDirectly(character);
					var leSprite:DeltaTrail = new DeltaTrail(leObj, null, 4, 12 / 60, 0.25, 0.069);
					leSprite.color = CoolUtil.colorFromString(color);
		
					PlayState.instance.modchartTrails.set(tag, leSprite); //yes
					var shit:DeltaTrail = PlayState.instance.modchartTrails.get(tag);
					LuaUtils.getTargetInstance().remove(leSprite, true);
					LuaUtils.getTargetInstance().insert(LuaUtils.getTargetInstance().members.indexOf(leObj)-1, leSprite);
					return;
				}
				luaTrace("makeLuaTrail: Object " + character + " doesn't exist!", false, false, FlxColor.RED);
			});
			Lua_helper.add_callback(lua, "removeLuaTrail", function(tag:String, destroy:Bool = true) {
				if(!PlayState.instance.modchartTrails.exists(tag)) {
					return;
				}
				
				var pee:DeltaTrail = PlayState.instance.modchartTrails.get(tag);
				if(destroy) {
					pee.kill();
				}
	
				LuaUtils.getTargetInstance().remove(pee, true);
	
				if(destroy) {
					pee.destroy();
					PlayState.instance.modchartTrails.remove(tag);
				}
			});
	
			Lua_helper.add_callback(lua, "animExists", function(tag:String, anim:String){
				var shit:Dynamic = LuaUtils.getObjectDirectly(tag);
				
				return shit.animation.getByName(anim) != null;
			});
	
			Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String) {
				var killMe:Array<String> = obj.split('.');
				var leObj:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(leObj != null)
				{
					return LuaUtils.getTargetInstance().members.indexOf(leObj);
				}
				luaTrace("getObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return -1;
			});
	
			Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int) {
				var killMe:Array<String> = obj.split('.');
				var leObj:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if (position <= 0) // i got a bug while fixing confrontation so this is here now.
					position = 0;

				if(leObj != null) {
					LuaUtils.getTargetInstance().remove(leObj, true);
					LuaUtils.getTargetInstance().insert(position, leObj);
					return;
				}
				luaTrace("setObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			});
	
			Lua_helper.add_callback(lua, "playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
			{
				if(LuaUtils.getObjectDirectly(obj) != null) {
					var luaObj:FlxSprite = LuaUtils.getObjectDirectly(obj);
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
	
				var spr:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
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
	
			Lua_helper.add_callback(lua, "characterDance", function(character:String) {
				if(PlayState.instance.modchartCharacters.exists(character)) {
					var spr:Character = PlayState.instance.modchartCharacters.get(character);
					spr.dance();
				}
				else
					LuaUtils.getObjectDirectly(character).dance();
			});
	
			Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float, ?updateHitbox:Bool = true) {
				if(LuaUtils.getObjectDirectly(obj) != null) {
					var poop:FlxSprite = LuaUtils.getObjectDirectly(obj);
					poop.scale.set(x * (FlxG.save.data.poltatoPC ? 2 : 1), y * (FlxG.save.data.poltatoPC ? 2 : 1));
					if(updateHitbox) poop.updateHitbox();
					return;
				}
	
				var poop:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
				if(poop != null) {
					poop.scale.set(x * (FlxG.save.data.poltatoPC ? 2 : 1), y * (FlxG.save.data.poltatoPC ? 2 : 1));
					if(updateHitbox) poop.updateHitbox();
					return;
				}
				
				luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
			});
			
			Lua_helper.add_callback(lua, "setOffset", function(id:String, x:Float, y:Float) {
				var shit:Dynamic = LuaUtils.getObjectDirectly(id);
				shit.offset.set(x, y);
			});
	
			//paths stuff
			Lua_helper.add_callback(lua, "paths", function(tag:String, text:String) {
				switch(tag)
				{
					case 'font': return Paths.font(text);
					case 'image': return Paths.image(text);
					case 'xml': return Paths.xmlNew(text);
					case 'sound': return Paths.sound(text);
					default: return '';
				}
			});

			Lua_helper.add_callback(lua, "getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
				return Paths.getTextFromFile(path, ignoreModFolders);
			});

			Lua_helper.add_callback(lua, "luaSpriteExists", function(tag:String) {
				return PlayState.instance.modchartSprites.exists(tag);
			});
			Lua_helper.add_callback(lua, "luaTextExists", function(tag:String) {
				return PlayState.instance.modchartTexts.exists(tag);
			});
			Lua_helper.add_callback(lua, "luaSoundExists", function(tag:String) {
				return PlayState.instance.modchartSounds.exists(tag);
			});
	
			Lua_helper.add_callback(lua, "updateHitbox", function(obj:String) {
				if(PlayState.instance.getLuaObject(obj)!=null) {
					var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
					shit.updateHitbox();
					return;
				}
	
				var poop:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
				if(poop != null) {
					poop.updateHitbox();
					return;
				}
				luaTrace('updateHitbox: Couldnt find object: ' + obj);
			});
			Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int) {
				if(Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup)) {
					Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
					return;
				}
				Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
			});

			Lua_helper.add_callback(lua, "removeSpriteAnim", function(obj:String, anim:String) {
				var killMe:Array<String> = obj.split('.');
				var leObj:Dynamic = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(leObj != null) {
					var daObj:FlxSprite = leObj;
					daObj.animation.remove(anim);

					if (Std.isOfType(leObj, Character) || Std.isOfType(leObj, ModchartSprite)){
						leObj.animOffsets.remove(anim);
					}
					
					return true;
				}
				return false;
			});

			//masking!
			Lua_helper.add_callback(lua, "addClipRect", function(obj:String, x:Float, y:Float, width:Float, height:Float) {
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
	
			Lua_helper.add_callback(lua, "setClipRectAngle", function(obj:String, degrees:Float) {
				var daRect:FlxRect = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop([obj, 'clipRect']), 'clipRect');
	
				if(daRect != null) {
					daRect.getRotatedBounds(degrees);
	
					var killMe:Array<String> = obj.split('.');
					var object:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
					if(killMe.length > 1) {
						object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
					}
	
					object.clipRect = daRect;
					return true;
				}
				luaTrace("setClipRectAngle: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return false;
			});
	
			Lua_helper.add_callback(lua, "setSpriteMask", function(obj:String, mask:String, ?spriteMask:Bool = true) {
				var killMe:Array<String> = obj.split('.');
				var leObj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}

				//mask
				var killMe2:Array<String> = mask.split('.');
				var leObj2:FlxSprite = LuaUtils.getObjectDirectly(killMe2[0]);
				if(killMe2.length > 1) {
					leObj2 = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe2), killMe2[killMe2.length-1]);
				}
	
				if(leObj != null) {
					PlayState.instance.removeObject(leObj);
					PlayState.instance.modchartSprites.remove(obj);

					if (spriteMask)
						FlxSpriteUtil.alphaMaskFlxSprite(leObj, leObj2, leObj);
					else{
						leObj.useFramePixels = true;
						FlxSpriteUtil.alphaMask(leObj, leObj.framePixels, leObj2.pixels);
					}
						
					PlayState.instance.modchartSprites.set(obj, leObj);
					PlayState.instance.addObject(leObj);

					return true;
				}

				luaTrace("setSpriteMask: "+(leObj == null ? obj : mask)+" not found!", false, false, FlxColor.RED);
				return false;
			});

			// Other stuff
			Lua_helper.add_callback(lua, "stringStartsWith", function(str:String, start:String) {
				return str.startsWith(start);
			});
			Lua_helper.add_callback(lua, "stringEndsWith", function(str:String, end:String) {
				return str.endsWith(end);
			});
			Lua_helper.add_callback(lua, "stringSplit", function(str:String, split:String) {
				return str.split(split);
			});
			Lua_helper.add_callback(lua, "stringTrim", function(str:String) {
				return str.trim();
			});

			Lua_helper.add_callback(lua, "getNotes", function(y:Float)
				{
					Lua.newtable(lua);
		
					for (i in 0...PlayState.instance.notes.members.length)
					{
						var note = PlayState.instance.notes.members[i];
						Lua.pushstring(lua, note.LuaNote.className);
						Lua.rawseti(lua, -2, i);
					}
				});

			// default strums
	
			Lua_helper.add_callback(lua, "getNotes", function(y:Float)
			{
				Lua.newtable(lua);
	
				for (i in 0...PlayState.instance.notes.members.length)
				{
					var note = PlayState.instance.notes.members[i];
					Lua.pushstring(lua, note.LuaNote.className);
					Lua.rawseti(lua, -2, i);
				}
			});

			#if desktop DiscordClient.addLuaCallbacks(lua); #end
			#if hscript HScript.implement(this); #end
			#if flxanimate FlxAnimateFunctions.implement(this); #end
			SpriteGroupFunctions.implement(this);
			ReflectionFunctions.implement(this);
			TweenFunctions.implement(this);
			TextFunctions.implement(this);
			ExtraFunctions.implement(this);
			CustomSubstate.implement(this);
			ShaderFunctions.implement(this);
			DeprecatedFunctions.implement(this);

			/*if (isStageLua){
				isStageLua = false;
			}*/
		}
    }

	public function addLocalCallback(name:String, myFunction:Dynamic)
	{
		#if LUA_ALLOWED
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); //just so that it gets called
		#end
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

			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
			if(pussy.animation.curAnim == null) {
				pussy.animation.play(name, true);
			}
			return true;
		}

		if(LuaUtils.getObjectDirectly(obj) != null) {
			var pussy:FlxSprite = changeSpriteClass(LuaUtils.getObjectDirectly(obj));
			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
			if(pussy.animation.curAnim == null) {
				pussy.animation.play(name, true);
			}
			return true;
		}

		var pussy:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
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

    public function executeState(name,args:Array<Dynamic>)
    {
        return Lua.tostring(lua,call(name, args));
    }


	inline function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>)
	{
		for (type in types)
		{
			if(Std.isOfType(value, type)) return true;
		}
		return false;
	}

	function loadFrames(spr:FlxSprite, image:String, spriteType:String)
	{
		if (!Paths.currentTrackedAssets.exists(image))
			Paths.cacheImage(image);

		var daSpriteType:String = spriteType;

		switch(spriteType.toLowerCase().trim())
		{
			/*case "texture" | "textureatlas"|"tex":
				spr.frames = AtlasFrameMaker.construct(image);
			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);*/
			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);
			default:
				spr.frames = Paths.getAtlasFromData(image, daSpriteType);
		}

		if (FlxG.save.data.poltatoPC)
		{
			spr.scale.set(2, 2);
			spr.updateHitbox();
		}
	}

	//clone functions
	public static function getBuildTarget():String
	{
		#if windows
		return 'windows';
		#elseif linux
		return 'linux';
		#elseif mac
		return 'mac';
		#elseif html5
		return 'browser';
		#elseif android
		return 'android';
		#elseif switch
		return 'switch';
		#else
		return 'unknown';
		#end
	}

	#if (!flash && sys)
	public static function getShader(obj:String, ?swagShader:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:Dynamic = null;
		if(split.length > 1) target = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
		else target = LuaUtils.getObjectDirectly(split[0]);

		if(target == null)
		{
			ModchartState.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
			return null;
		}

		var shader:Dynamic = null;
		
		if (Std.isOfType(target, FlxCamera)){
			var daFilters = (target.filters != null) ? target.filters : [];
			
			if (swagShader != null && swagShader.length > 0){
				var arr:Array<String> = PlayState.instance.runtimeShaders.get(swagShader);
				
				for (i in 0...daFilters.length){	
					var filter:ShaderFilter = daFilters[i];
					
					if (filter.shader.glFragmentSource == ShaderFunctions.processFragmentSource(arr[0])){
						shader = filter.shader;
						break;
					}
				}
			}
			else{
				shader = daFilters[0].shader;
			}
		}
		else{
			shader = target.shader;
		}

		var returnShader:FlxRuntimeShader = shader;	
		return returnShader;
	}
	#end

	public static function callOnCompleted(type:String = "tween", tag:String, ?loops:Int, ?loopsLeft:Int)
	{
		switch (type.toLowerCase())
		{
			case 'timer':
				PlayState.instance.callOnLuas("onTimerCompleted", [tag]);
			default:
				PlayState.instance.callOnLuas("onTweenCompleted", [tag]);
		}	

		(type.toLowerCase() == 'timer' ? PlayState.instance.modchartTimers.remove(tag) : PlayState.instance.modchartTweens.remove(tag));
	}
	
	public static function findScript(scriptFile:String, ext:String = '.lua')
	{
		if(!scriptFile.endsWith(ext)) scriptFile += ext;
		var preloadPath:String = Paths.getSharedPath(scriptFile);
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(scriptFile))
			return scriptFile;
		else if(FileSystem.exists(path))
			return path;

		if(FileSystem.exists(preloadPath))
		#else
		if(Assets.exists(preloadPath))
		#end
		{
			return preloadPath;
		}
		return null;
	}
}
#end
