// this file is for modchart things, this is to declutter playstate.hx

// Lua
import openfl.display3D.textures.VideoTexture;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
#if desktop
import flixel.tweens.FlxEase;
import openfl.filters.ShaderFilter;
import openfl.Lib;
import flixel.tweens.FlxTween;
import flixel.addons.display.FlxBackdrop;
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
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.effects.FlxFlicker;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.ui.FlxInputText;
import flixel.util.FlxAxes;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import openfl.system.System;
import lime.utils.Assets;
import flixel.math.FlxMath;
import openfl.display.BlendMode;
import flixel.tweens.misc.ColorTween;
import flash.media.Sound;
import lime.media.AudioBuffer;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import flixel.math.FlxRect;
import animateatlas.AtlasFrameMaker;

import Type.ValueType;
import Shaders;
import DialogueBoxPsych;

//why is detected's modchart confusing!?
import LuaClass.LuaGame;
import LuaClass.LuaWindow;
import LuaClass.LuaSprite;
import LuaClass.LuaCamera;
import LuaClass.LuaNote;
import LuaClass.LuaReceptor;

#if desktop
import Sys;
import sys.io.File;
import sys.FileSystem;
#end

#if hscript
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
#end


#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

using StringTools;

class ModchartState 
{
	//public static var shaders:Array<LuaShader> = null;
	public static var Function_Stop = 1;
	public static var Function_Continue = 0;
	public static var Function_StopLua:Dynamic = 2;

	#if desktop
	public var lua:State = null;
	#end
	
	public var scriptName:String = '';
	var gonnaClose:Bool = false;
	public var closed:Bool = false;

	public static var shownNotes:Array<LuaNote> = [];

	public var blam:Dynamic = "";

	#if hscript
	public static var hscript:HScript = null;
	#end

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

	var lastCalledFunction:String = '';

	public function callPsych(func:String, args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		if(closed) return Function_Continue;

		lastCalledFunction = func;
		try {
			if(lua == null) return Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL)
					luaTrace("ERROR (" + func + "): attempt to call a " + typeToString(type) + " value", false, false, FlxColor.RED);

				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK) {
				var error:String = getErrorMessage(status);
				luaTrace("ERROR (" + func + "): " + error, false, false, FlxColor.RED);
				return Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = Function_Continue;

			Lua.pop(lua, 1);
			return result;
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

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, ?color:FlxColor = FlxColor.WHITE) {
		#if desktop
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
			position = getInstance().members.indexOf(daChar);
		}
		
		resetCharacterTag(tag);
		var leSprite:Character = new Character(0, 0, character, isPlayer);
		leSprite.flipMode = flipped;
		PlayState.instance.modchartCharacters.set(tag, leSprite); //yes
		var shit:Character = PlayState.instance.modchartCharacters.get(tag);
		getInstance().add(shit);

		if (position >= 0) //this should keep them in the same spot if they switch
		{
			getInstance().remove(shit, true);
			getInstance().insert(position, shit);
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

	function getActorByName(id:String):Dynamic
	{
		// pre defined names
		switch(id)
		{
			case 'boyfriend' | 'bf':
                @:privateAccess
				return PlayState.instance.boyfriend;
			case 'gf':
                @:privateAccess
				return PlayState.instance.gf;
			case 'camFollow':
                @:privateAccess
				return PlayState.instance.camFollow;
			case 'camHUD':
                @:privateAccess
				return PlayState.instance.camHUD;
			case 'camGame':
                @:privateAccess
				return FlxG.camera;
			case 'camGame.scroll':
                @:privateAccess
				return FlxG.camera.scroll;
		}

		if (id.contains('stage-'))
		{
			var daID:String = id.split('-')[1];
			return PlayState.instance.Stage.swagBacks[daID];
		}

		if (Std.parseInt(id) == null)
			return Reflect.getProperty(getInstance(),id);

		return PlayState.instance.strumLineNotes.members[Std.parseInt(id)];
	}

	//Kade why tf is it not like in PlayState???

	function changeGFCharacter(id:String, x:Float, y:Float)
	{		
		PlayState.instance.removeObject(PlayState.instance.gf);
		//PlayState.instance.gf = new Character(x, y, null);
		PlayState.instance.destroyObject(PlayState.instance.gf);
		PlayState.instance.gf = new Character(x, y, id);
		PlayState.instance.gf.scrollFactor.set(0.95, 0.95);
		PlayState.instance.addObject(PlayState.instance.gf);

		if (FlxG.save.data.poltatoPC)
			PlayState.instance.gf.setPosition(PlayState.instance.gf.x + 100, PlayState.instance.gf.y + 170);

		PlayState.instance.startCharacterLua(PlayState.instance.gf.curCharacter);
		
	}

	function changeDadCharacter(id:String, x:Float, y:Float)
	{		
		//this is why i don't use exTricky
		var wasExTricky:Bool = false;
		var isExTricky:Bool = false;
		
		if (PlayState.instance.dad.curCharacter == 'exTricky')
			wasExTricky = true;

		if (id == 'exTricky')
			isExTricky = true;
		
		if (wasExTricky)
		{
			PlayState.instance.removeObject(PlayState.instance.dad.exSpikes);
			PlayState.instance.destroyObject(PlayState.instance.dad.exSpikes);
		}

		PlayState.instance.removeObject(PlayState.instance.dadTrail);
		PlayState.instance.removeObject(PlayState.instance.dad);
		PlayState.instance.destroyObject(PlayState.instance.dad);
		PlayState.instance.dad = new Character(x, y, id);
		PlayState.instance.addObject(PlayState.instance.dadTrail);
		PlayState.instance.dadTrail.resetTrail();
		PlayState.instance.addObject(PlayState.instance.dad);

		if (isExTricky)
			PlayState.instance.addObject(PlayState.instance.dad.exSpikes);

		if (PlayState.newIcons)
		{
			if (PlayState.swapIcons)
				PlayState.instance.iconP2.changeIcon(PlayState.instance.dad.healthIcon);
		}
		else
			PlayState.instance.iconP2.useOldSystem(PlayState.instance.dad.healthIcon);

		if (PlayState.instance.defaultBar)
		{
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + PlayState.instance.dad.iconColor), FlxColor.fromString('#' + PlayState.instance.boyfriend.iconColor));
			PlayState.instance.healthBar.updateBar();
		}	

		PlayState.instance.startCharacterLua(PlayState.instance.dad.curCharacter);
	
	}

	function changeBoyfriendCharacter(id:String, x:Float, y:Float)
	{	
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;						
		if (PlayState.instance.boyfriend.animation.curAnim.name.startsWith('sing'))
		{
			animationName = PlayState.instance.boyfriend.animation.curAnim.name;
			animationFrame = PlayState.instance.boyfriend.animation.curAnim.curFrame;
		}

		PlayState.instance.removeObject(PlayState.instance.bfTrail);
		PlayState.instance.removeObject(PlayState.instance.boyfriend);
		PlayState.instance.destroyObject(PlayState.instance.boyfriend);
		PlayState.instance.boyfriend = new Boyfriend(x, y, id);
		PlayState.instance.addObject(PlayState.instance.bfTrail);
		PlayState.instance.bfTrail.resetTrail();
		PlayState.instance.addObject(PlayState.instance.boyfriend);

		if (PlayState.newIcons)
		{
			if (PlayState.swapIcons)
				PlayState.instance.iconP1.changeIcon(PlayState.instance.boyfriend.healthIcon);
			else
				''; //do nothing
		}
		else
			PlayState.instance.iconP1.useOldSystem(PlayState.instance.boyfriend.healthIcon);

		if (PlayState.instance.defaultBar)
		{
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + PlayState.instance.dad.iconColor), FlxColor.fromString('#' + PlayState.instance.boyfriend.iconColor));
			PlayState.instance.healthBar.updateBar();
		}	

		if (PlayState.instance.boyfriend.animOffsets.exists(animationName))
			PlayState.instance.boyfriend.playAnim(animationName, true, false, animationFrame);

		PlayState.instance.startCharacterLua(PlayState.instance.boyfriend.curCharacter);
	}

	//does this work. right? -- future me here. yes it does.
	public static function changeStage(id:String)
	{	
		PlayState.instance.removeObject(PlayState.instance.gf);
		PlayState.instance.removeObject(PlayState.instance.dad);
		PlayState.instance.removeObject(PlayState.instance.boyfriend);

		if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
		{
			for (i in PlayState.instance.Stage.luaArray)
			{
				PlayState.instance.Stage.luaArray.remove(i);
				i.die();
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
		
		PlayState.instance.Stage = new Stage(id);
		PlayState.curStage = PlayState.instance.Stage.curStage;
		PlayState.instance.defaultCamZoom = PlayState.instance.Stage.camZoom;

		for (i in PlayState.instance.Stage.toAdd)
		{
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

		if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
			PlayState.instance.Stage.callOnLuas('onCreatePost', []); //i swear if this starts crashing stuff i'mma cry

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

		PlayState.instance.removeObject(PlayState.instance.bfTrail);
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

		PlayState.instance.addObject(PlayState.instance.bfTrail);
		PlayState.instance.bfTrail.resetTrail();
		PlayState.instance.addObject(PlayState.instance.boyfriend);

		if (PlayState.newIcons)
		{
			if (PlayState.swapIcons)
				PlayState.instance.iconP1.changeIcon(PlayState.instance.boyfriend.healthIcon);
		}
		else
			PlayState.instance.iconP1.useOldSystem(PlayState.instance.boyfriend.healthIcon);

		if (PlayState.instance.defaultBar)
		{
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + PlayState.instance.dad.iconColor), FlxColor.fromString('#' + PlayState.instance.boyfriend.iconColor));
			PlayState.instance.healthBar.updateBar();
		}	

		if (PlayState.instance.boyfriend.animOffsets.exists(animationName))
			PlayState.instance.boyfriend.playAnim(animationName, true, false, animationFrame);

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy)
			Paths.clearStoredMemory2(bfPath);

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

		PlayState.instance.removeObject(PlayState.instance.dadTrail);
		PlayState.instance.removeObject(PlayState.instance.dad);
		PlayState.instance.destroyObject(PlayState.instance.dad);
		PlayState.instance.dad = new Character(0, 0, id, flipped);

		var charOffset = new CharacterOffsets(id, flipped);
		var charX:Float = charOffset.daOffsetArray[0];
		var charY:Float =  charOffset.daOffsetArray[1] + (flipped ? 350 : 0);

		if (flipped)
			PlayState.instance.dad.flipMode = true;

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

		PlayState.instance.addObject(PlayState.instance.dadTrail);
		PlayState.instance.dadTrail.resetTrail();
		PlayState.instance.addObject(PlayState.instance.dad);

		if (PlayState.newIcons)
		{
			if (PlayState.swapIcons)
				PlayState.instance.iconP2.changeIcon(PlayState.instance.dad.healthIcon);
		}
		else
			PlayState.instance.iconP2.useOldSystem(PlayState.instance.dad.healthIcon);

		if (PlayState.instance.defaultBar)
		{
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + PlayState.instance.dad.iconColor), FlxColor.fromString('#' + PlayState.instance.boyfriend.iconColor));
			PlayState.instance.healthBar.updateBar();
		}	

		if (PlayState.instance.dad.animOffsets.exists(animationName))
			PlayState.instance.dad.playAnim(animationName, true, false, animationFrame);

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy && daCurChar != PlayState.instance.dad.curCharacter)
			Paths.clearStoredMemory2(dadPath);

		PlayState.instance.startCharacterLua(PlayState.instance.dad.curCharacter);
	}

	public static function changeGFAuto(id:String, ?dontDestroy:Bool = false)
	{		
		PlayState.instance.removeObject(PlayState.instance.gf);
		PlayState.instance.destroyObject(PlayState.instance.gf);
		PlayState.instance.gf = new Character(0, 0, id);
		PlayState.instance.gf.x = PlayState.instance.Stage.gfXOffset + 400 + PlayState.instance.gf.positionArray[0];
		PlayState.instance.gf.y = PlayState.instance.Stage.gfYOffset + 130 + PlayState.instance.gf.positionArray[1];
		PlayState.instance.gf.scrollFactor.set(0.95, 0.95);
		PlayState.instance.addObject(PlayState.instance.gf);

		if (FlxG.save.data.poltatoPC)
			PlayState.instance.gf.setPosition(PlayState.instance.gf.x + 100, PlayState.instance.gf.y + 170);

		var gfPath:String = '';

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy)
			gfPath = 'shared:assets/shared/images/'+PlayState.instance.gf.charPath;

		if (FlxG.save.data.uncacheCharacterSwitch && !dontDestroy)
			Paths.clearStoredMemory2(gfPath);

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

    public function new(path:String, ?isStageLua:Bool = false)
    {
		// for detected
		//instance = this;

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
			
		if (PlayState.instance.isDetected && PlayState.instance != null)
			shownNotes = [];

		scriptName = path;

		if (ogPath.contains('assets/shared'))
			scriptName = ogPath;

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
				Lua.close(lua);
				lua = null;

				PlayState.instance.luaArray.remove(this);
				PlayState.instance.luaArray = [];

				return;
			}
		} catch(e:Dynamic) {
			trace(e);
			return;
		}

		trace('lua file loaded succesfully:' + path);
			
		//shaders = new Array<LuaShader>();	

		// get some fukin globals up in here bois

		set('Function_StopLua', Function_StopLua);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue); //i have no idea how this works
		set('endDaSong', true);
		set('luaDebugMode', true);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		set("difficulty", PlayState.storyDifficulty);
		set("bpm", PlayState.SONG.bpm);
		set("curBpm", Conductor.bpm);
		set("scrollspeed", FlxG.save.data.scrollSpeed != 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed);
		set("fpsCap", FlxG.save.data.fpsCap);
		set("downscroll", FlxG.save.data.downscroll);
		set("flashing", FlxG.save.data.flashing);
		set("distractions", FlxG.save.data.distractions);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('seenCutscene', PlayState.seenCutscene);
		set('scriptName', scriptName);

		set("curStep", 0);
		set("daSection", 0);
		set("curBeat", 0);
		set("crochet", Conductor.crochet);
		set("stepCrochet", Conductor.stepCrochet);
		set("safeZoneOffset", Conductor.safeZoneOffset);

		set("cameraZoom", FlxG.camera.zoom);

		set("cameraAngle", FlxG.camera.angle);
	
		set("followBFXOffset",0);
		set("followBFYOffset",0);
		set("followDadXOffset",0);
		set("followDadYOffset",0);

		set("curSection", 0);

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
		set("newIcons", false);
		set("swapIcons", true);
		set("playDadSing", true);
		set("playBFSing", true);

		if (PlayState.instance != null)
		{
			set("hudWidth", PlayState.instance.camHUD.width);
			set("hudHeight", PlayState.instance.camHUD.height);
	
			set("hudZoom", PlayState.instance.camHUD.zoom);
			set("camHudAngle", PlayState.instance.camHUD.angle);

			set('playbackRate', PlayState.instance.playbackRate);
		}
	
		// callbacks

		// sprites

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
			cameraFromString(camera).filtersEnabled = bool;
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
								luaTrace('The script "' + cervix + '" is already running!');

							return;
						}
					}
				}
				PlayState.instance.luaArray.push(new ModchartState(cervix)); 
				return;
			}
			luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
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

		Lua_helper.add_callback(lua,"animationSwap", function(char:String, anim1:String, anim2:String) {
			var shit = getObjectDirectly2(char);

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
				var shit:Dynamic = getObjectDirectly2(id);
				PlayState.instance.destroyObject(shit);
			}
		});

		Lua_helper.add_callback(lua,"removeGroupObject", function(obj:String, index:Int = 0) {
			var shit:Dynamic = Reflect.getProperty(getInstance(), obj);

			shit.forEach(function(spr:Dynamic)
			{			
				if (spr.ID == index)		
					PlayState.instance.removeObject(spr);
			});
		});

		Lua_helper.add_callback(lua,"destroyGroupObject", function(obj:String, index:Int = 0) {
			//i have no idea if this works.... it works
			var shit:Dynamic = Reflect.getProperty(getInstance(), obj);

			shit.forEach(function(spr:Dynamic)
			{			
				if (spr.ID == index)		
					spr.destroy();
			});
		});

		Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartSprites.exists(tag)) {
				return;
			}
			
			var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
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

		Lua_helper.add_callback(lua, "removeLuaIcon", function(tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartIcons.exists(tag)) {
				return;
			}
			
			var pee:ModchartIcon = PlayState.instance.modchartIcons.get(tag);
			if(destroy) {
				pee.kill();
			}

			if(pee.wasAdded) {
				getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if(destroy) {
				pee.destroy();
				PlayState.instance.modchartIcons.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "getSongPosition", function() {
			return Conductor.songPosition;
		});

		Lua_helper.add_callback(lua,"setScrollFactor", function(obj:String , scrollX:Float, scrollY:Float, ?bg:Bool = false) {
			if(getObjectDirectly(obj)!=null) {
				getObjectDirectly(obj).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(getInstance(), obj);
			if(object != null) {	
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

		Lua_helper.add_callback(lua,"getScrollFactor", function(id:String , x:String) {
			var shit:Dynamic = getObjectDirectly2(id);
			(x == 'x' ? return shit.scrollFactor.x : return shit.scrollFactor.y);
		});

		Lua_helper.add_callback(lua,"changeAnimOffset", function(id:String , x:Float, y:Float) {
			var shit:Dynamic = getObjectDirectly2(id);
			shit.addOffset(x, y); // it may say addoffset but it actually changes it instead of adding to the existing offset so this works.
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


		Lua_helper.add_callback(lua,"checkDownscroll", function() {
			return FlxG.save.data.downscroll;
		});

		Lua_helper.add_callback(lua,"getScared", function(id:String) {
			PlayState.instance.Stage.swagBacks[id].getScared();
		});

		// hud/camera

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
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
			
		});
		Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
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

		Lua_helper.add_callback(lua, "close", function(printMessage:Bool = false) {
			closed = true;
			return closed;
		});

		Lua_helper.add_callback(lua,"changeDadIcon", function(id:String) {
			PlayState.instance.iconP2.useOldSystem(id);
		});

		Lua_helper.add_callback(lua,"changeBFIcon", function(id:String) {
			PlayState.instance.iconP1.useOldSystem(id);
		});

		Lua_helper.add_callback(lua,"changeIcon", function(char:String, id:String) {

			trace('run dammit!');

			if(PlayState.instance.modchartIcons.exists(char)) {
				PlayState.instance.modchartIcons.get(char).changeIcon(id);
				return;
			}

			switch(char)
			{
				case 'bf' | 'boyfriend' | 'iconP1':
					trace('changing bf icon');
					PlayState.instance.iconP1.changeIcon(id);
					trace('changed bf icon');
				default:
					trace('changing p2 icon');
					PlayState.instance.iconP2.changeIcon(id);
					trace('changed p2 icon');
			}				
		});

		Lua_helper.add_callback(lua,"softCountdown", function(id:String) {
			PlayState.instance.softCountdown(id);
		});

		Lua_helper.add_callback(lua,"fixTrail", function(id:String) {
			PlayState.instance.fixTrailShit(id);
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
			var shit:Dynamic = getObjectDirectly2(id);
			shit.resetTrail();
		});

		Lua_helper.add_callback(lua,"generateNumberFromRange", function(min:Float, max:Float) {
			return FlxG.random.float(min, max);
		});

		Lua_helper.add_callback(lua,"exeStatic", function(?id:String, color:Int = 0) {
			PlayState.instance.staticHitMiss(color);
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
			getActorByName(id).stopIdle = bool;
		});

		Lua_helper.add_callback(lua,"setDownscroll", function(id:Bool) {
			FlxG.save.data.downscroll = id;
		});

		Lua_helper.add_callback(lua,"removeObject", function(id:String) {
			var shit:Dynamic = getObjectDirectly2(id);
			PlayState.instance.removeObject(shit);
		});

		Lua_helper.add_callback(lua,"addObject", function(id:String) {
			var shit:Dynamic = getObjectDirectly2(id);
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

		Lua_helper.add_callback(lua, "cameraShake", function(camera:String, intensity:Float, duration:Float) {
			cameraFromString(camera).shake(intensity, duration);
		});

		Lua_helper.add_callback(lua, "objectShake", function(camera:String, intensity:Float, duration:Float) {
			getObjectDirectly(camera).shake(intensity, duration);
		});
		
		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float,forced:Bool) {
			if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			cameraFromString(camera).flash(colorNum, duration,null,forced);
		});
		Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float,forced:Bool, ?fadeOut:Bool = false) {
			if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			cameraFromString(camera).fade(colorNum, duration,fadeOut,null,forced);
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
			luaTrace('setDefaultCamZoom is deprecated! Use setProperty("defaultCamZoom", "zoomAmount") instead.', false, true);
			PlayState.instance.defaultCamZoom = zoomAmount;
		});

		Lua_helper.add_callback(lua,"setHudZoom", function(zoomAmount:Float) {
			luaTrace('setHudZoom is deprecated! Use setProperty("camHUD.zoom", "zoomAmount") instead.', false, true);
			PlayState.instance.camHUD.zoom = zoomAmount;
		});

		Lua_helper.add_callback(lua,"changeCamSpeed", function(camFollowSpeed:Float = 0.04) { //i know psych has that camSpeed stuff but I don't feel like changing to Psych's camera system
			FlxG.camera.follow(PlayState.instance.camFollow, LOCKON, camFollowSpeed * (30 / (cast (Lib.current.getChildAt(0), Main)).getFPS()));	
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
			PlayState.instance.chromOn = bool;
		});

		Lua_helper.add_callback(lua,"offCamFollow", function(id:String) {
			PlayState.instance.camFollowIsOn = false;
		});

		Lua_helper.add_callback(lua,"resetCamFollow", function(id:String) {
			PlayState.instance.camFollowIsOn = true;
		});

		Lua_helper.add_callback(lua,"snapCam", function(x:Float, y:Float) {
			PlayState.instance.camFollowIsOn = false;
		//	PlayState.instance.defaultCamFollow = false;
			{
				var camPosition:FlxObject;
				camPosition = new FlxObject(0, 0, 1, 1);
				camPosition.setPosition(x, y);
				FlxG.camera.focusOn(camPosition.getPosition());
			}
		});

		Lua_helper.add_callback(lua,"resetSnapCam", function(id:String) {
			//The string does absolutely nothing
			//PlayState.instance.defaultCamFollow = true;
		});
		
		Lua_helper.add_callback(lua,"resetCamEffects", function(id:String) {
			PlayState.instance.camFollowIsOn = true;
		});

		Lua_helper.add_callback(lua,"stopCameraEffects", function(id:String) { //how convenient
			cameraFromString(id).stopFX();
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

		Lua_helper.add_callback(lua,"getArrayLength", function(obj:String) {
			var shit:Dynamic = Reflect.getProperty(getInstance(), obj);

			return shit.length;
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
				PlayState.instance.Stage.swagBacks[id].velocity.x = x;
			}
			else {
				getActorByName(id).velocity.x = x;
			}				
		});
		
		Lua_helper.add_callback(lua,"playActorAnimation", function(obj:String,anim:String,force:Bool = false,reverse:Bool = false, ?frame:Int = 0) {
			var char:Character = getObjectDirectly(obj);

			if (char != null && Std.isOfType(char, Character)){ //what am I doing? of course it'll be a character
				char.playAnim(anim, force, reverse, frame);
				return;
			} 
			luaTrace('playActorAnimation: Couldnt find object: ' + obj, false, false, FlxColor.RED);
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
			var shit:Dynamic = getObjectDirectly2(id);
			FlxFlicker.flicker(shit, duration, interval);
		});

		Lua_helper.add_callback(lua,"setActorAlpha", function(alpha:Float,id:String, ?bg:Bool = false) {
			if (bg){
				PlayState.instance.Stage.swagBacks[id].alpha = alpha;
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
				PlayState.instance.Stage.swagBacks[id].visible = alpha;
			}
			else {
				getActorByName(id).visible = alpha;
			}	
		});

		Lua_helper.add_callback(lua,"setActorY", function(y:Int,id:String, ?bg:Bool = false) {
			if (bg){
				PlayState.instance.Stage.swagBacks[id].y = y;
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

		Lua_helper.add_callback(lua,"setActorScale", function(scale:Float,id:String, ?bg:Bool = false) {
			var shit:Dynamic = getObjectDirectly2(id);
			shit.setGraphicSize(Std.int(shit.width * scale));
			shit.updateHitbox();	
		});
		
		Lua_helper.add_callback(lua, "setActorScaleXY", function(scaleX:Float, scaleY:Float, id:String)
		{
			getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scaleX), Std.int(getActorByName(id).height * scaleY));
		});

		Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			if(PlayState.instance.getLuaObject(obj)!=null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.setGraphicSize(x, y);
				if(updateHitbox) shit.updateHitbox();
				return;
			}

			var killMe:Array<String> = obj.split('.');
			var poop:FlxSprite = getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				poop = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
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
				return PlayState.instance.Stage.swagBacks[id].x;
			else
				return getActorByName(id).x;
		});

		Lua_helper.add_callback(lua,"getCameraZoom", function (id:String) {
			return PlayState.instance.defaultCamZoom;
		});

		Lua_helper.add_callback(lua,"getActorY", function (id:String, ?bg:Bool = false) {
			if (bg)
				return PlayState.instance.Stage.swagBacks[id].y;
			else
				return getActorByName(id).y;
		});

		Lua_helper.add_callback(lua,"getActorXMidpoint", function (id:String, ?graphic:Bool = false) {
			var shit:Dynamic = getObjectDirectly2(id);

			if (graphic)
				return shit.getGraphicMidpoint().x;

			return shit.getMidpoint().x;
		});

		Lua_helper.add_callback(lua,"getActorYMidpoint", function (id:String, ?graphic:Bool = false) {
			var shit:Dynamic = getObjectDirectly2(id);

			if (graphic)
				return shit.getGraphicMidpoint().y;

			return shit.getMidpoint().y;
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
			FlxTween.tween(PlayState.instance.Stage.swagBacks[id], {alpha: toAlpha}, time, {ease: FlxEase.circIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenFadeOut", function(id:String, toAlpha:Float, time:Float, ease:String, onComplete:String) {
			FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenFadeOutBG", function(id:String, toAlpha:Float, time:Float, onComplete:String) {
			FlxTween.tween(PlayState.instance.Stage.swagBacks[id], {alpha: toAlpha}, time, {ease: FlxEase.circOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
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
			var shit:Dynamic = getObjectDirectly2(id);
			shit.shader = newShader.shader;
			newShader.hue = hue / 360;
		});

		Lua_helper.add_callback(lua,"changeSaturation", function(id:String, sat:Int) {
			var newShader:ColorSwap = new ColorSwap();
			var shit:Dynamic = getObjectDirectly2(id);
			shit.shader = newShader.shader;
			newShader.saturation = sat / 100;
		});

		Lua_helper.add_callback(lua,"changeBrightness", function(id:String, bright:Int) {
			var newShader:ColorSwap = new ColorSwap();
			var shit:Dynamic = getObjectDirectly2(id);
			shit.shader = newShader.shader;
			newShader.brightness = bright / 100;
		});

		//change as a group. you should probably use this one
		Lua_helper.add_callback(lua,"changeHSB", function(id:String, hue:Int = 0, sat:Int = 0, bright:Int = 0) {
			var newShader:ColorSwap = new ColorSwap();
			newShader.hue = hue / 360;
			newShader.saturation = sat / 100;
			newShader.brightness = bright / 100;

			var shit:FlxSprite = changeSpriteClass(getObjectDirectly(id));
			shit.shader = newShader.shader;
		});

		Lua_helper.add_callback(lua,"changeGroupHue", function(obj:String, hue:Int) {
			var shit:Dynamic = Reflect.getProperty(getInstance(), obj);

			shit.forEach(function(thing:Dynamic)
			{
				var newShader:ColorSwap = new ColorSwap();
				newShader.hue = hue / 360;
				thing.shader = newShader.shader;
			});
		});

		Lua_helper.add_callback(lua,"changeGroupMemberHue", function(obj:String, index:Int, hue:Int) {
			var shit:Dynamic = Reflect.getProperty(getInstance(), obj)[index];

			if(Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup))
				shit = Reflect.getProperty(getInstance(), obj).members[index];

			var newShader:ColorSwap = new ColorSwap();
			newShader.hue = hue / 360;
			shit.shader = newShader.shader;

		});

		Lua_helper.add_callback(lua,"playStrumAnim", function(isDad:Bool, id:Int, ?time:Float = 0.15) {
			PlayState.instance.StrumPlayAnim(isDad, id, time);	
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

		Lua_helper.add_callback(lua, "doTweenScaleX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
			var penisExam:Dynamic = tweenShit(tag, vars);
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
			var penisExam:Dynamic = tweenShit(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {"scale.y": value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);

						if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.luaArray.length >= 1)
							PlayState.instance.Stage.callOnLuas('onTweenCompleted', [tag]);
					}
				}));
			} else {
				luaTrace('doTweenScaleY: Couldnt find object: ' + vars, false, false, FlxColor.RED);
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
		
		Lua_helper.add_callback(lua, "startVideo", function(videoFile:String) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				PlayState.instance.startVideo(videoFile);
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

		Lua_helper.add_callback(lua, "endSong", function(hmm:String) {
			PlayState.instance.KillNotes();
			PlayState.instance.endSong();
		});

		//idk if I wanna add events. alright I added the ones that are usable without that much tinkering.
		Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic) {
			var value1:String = arg1;
			var value2:String = arg2;
			PlayState.instance.triggerEventNote(name, value1, value2);
		});

		Lua_helper.add_callback(lua, "getPropertyPsych", function(variable:String) {
			luaTrace('getPropertyPsych is deprecated. Use getProperty instead.');

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
				else if(PlayState.instance.modchartTexts.exists(killMe[0]))
					coverMeInPiss = PlayState.instance.modchartTexts.get(killMe[0]);
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
			luaTrace('setPropertyPsych is deprecated. Use getProperty instead.');

			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = null;
				if(PlayState.instance.modchartSprites.exists(killMe[0]))
					coverMeInPiss = PlayState.instance.modchartSprites.get(killMe[0]);
				else if(PlayState.instance.modchartTexts.exists(killMe[0]))
					coverMeInPiss = PlayState.instance.modchartTexts.get(killMe[0]);
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

		//i have no idea why I added the Psych in the first place
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

		Lua_helper.add_callback(lua, "doGroupTweenY", function(tag:String, obj:String, index:Int, value:Dynamic, duration:Float, ease:String) {
			//if this works i might use this over the noteTween stuff. though realistically there aren't many other flxgroups.
			cancelTween(tag);
			var shit:Dynamic = Reflect.getProperty(getInstance(), obj);
			var testicle:Dynamic = null;

			shit.forEach(function(spr:Dynamic)
			{			
				if (spr.ID == index)		
					testicle = spr;
			});

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
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

		Lua_helper.add_callback(lua, "arrayContains", function(obj:String, value:Dynamic) {
			var leArray:Dynamic = Reflect.getProperty(getInstance(), obj);

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
				real.cameras = [cameraFromString(camera)];
				return true;
			}

			if (Stage.instance.swagBacks.exists(obj))
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
			var shit:Dynamic = getObjectDirectly(obj);
			if(shit != null) {
				shit.blend = blendModeFromString(blend);
				return true;
			}
			luaTrace("setBlendMode: Object " + obj + " doesn't exist!");
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

		Lua_helper.add_callback(lua, "cancelTween", function(tag:String) {
			cancelTween(tag);
		});

		//used for testing. might as well leave it here.
		Lua_helper.add_callback(lua, "indexOf", function(tag:String, thing:String, ?last:Bool) {
			if (last)
				return tag.lastIndexOf(thing);

			return tag.indexOf(thing);
		});

		Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			PlayState.preloadChar = new Character(0, 0, name);
			PlayState.instance.startCharacterLua(name);
		});

		Lua_helper.add_callback(lua, "startCharLua", function(name:String) {
			PlayState.instance.startCharacterLua(name);
		});

		Lua_helper.add_callback(lua, "precacheSound", function(name:String) {
			return name; //lol
		});

		Lua_helper.add_callback(lua, "precacheImage", function(name:String) {
			Paths.returnGraphic(name);
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
				spr.loadGraphic(Paths.returnGraphic(image), animated, gX, gY);
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

		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
			tag = tag.replace('.', '');
			if (!isStageLua){resetSpriteTag(tag);}
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

			if (isStageLua){
				Stage.instance.swagBacks.set(tag, leSprite);
			}
			else{
				PlayState.instance.modchartSprites.set(tag, leSprite);
			}
			leSprite.active = true;
		});

		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float,spriteType:String="sparrow", width:Int = 0, height:Int = 0) {
			tag = tag.replace('.', '');
			if (!isStageLua){resetSpriteTag(tag);}
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			loadFrames(leSprite, image, spriteType);
			if (isStageLua){
				Stage.instance.swagBacks.set(tag, leSprite);
			}
			else{
				PlayState.instance.modchartSprites.set(tag, leSprite);
			}
			leSprite.antialiasing = true;
		});

		Lua_helper.add_callback(lua, "makeLuaBackdrop", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
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
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});

		Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int, height:Int, color:String) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(object != null) {
				object.makeGraphic(width, height, colorNum);
			}
		});

		Lua_helper.add_callback(lua, "addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return addAnimByIndices(obj, name, prefix, indices, framerate, false);
		});
		Lua_helper.add_callback(lua, "addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
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

		Lua_helper.add_callback(lua, "addAnimation", function(obj:String, name:String, indices:String, framerate:Int = 24, loop:Bool = true) {
			var strIndices:Array<String> = indices.trim().split(',');
			var die:Array<Int> = [];
			for (i in 0...strIndices.length) {
				die.push(Std.parseInt(strIndices[i]));
			}

			if(PlayState.instance.modchartSprites.exists(obj)) {
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
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
			var spr:Dynamic = getObjectDirectly(obj);

			if(spr != null) {
				spr.animation.play(name, forced);
			}
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

		Lua_helper.add_callback(lua, "setClipRectAngle", function(obj:String, degrees:Float) {
			var daRect:FlxRect = getVarInArray(getPropertyLoopThingWhatever([obj, 'clipRect']), 'clipRect');

			if(daRect != null) {
				daRect.getRotatedBounds(degrees);

				var killMe:Array<String> = obj.split('.');
				var object:FlxSprite = getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					object = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}

				object.clipRect = daRect;
				return true;
			}
			luaTrace("setClipRectAngle: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});


		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String) {
			if(!color.startsWith('0x')) color = '0xff' + color;
			return Std.parseInt(color);
		});

		Lua_helper.add_callback(lua, "objectColorTransform", function(obj:String, color:String) {
			var spr:Dynamic = getObjectDirectly2(obj);

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

		Lua_helper.add_callback(lua, "objectColorTween", function(obj:String, duration:Float, color:String, color2:String, ?ease:String = 'linear') {
			var spr:Dynamic = getObjectDirectly2(obj);

			if(spr != null) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				var colorNum2:Int = Std.parseInt(color2);
				if(!color2.startsWith('0x')) colorNum2 = Std.parseInt('0xff' + color2);

				FlxTween.color(spr, duration, colorNum, colorNum2, {ease: getFlxEaseByString()});
			}
		});

		Lua_helper.add_callback(lua, "inBetweenColor", function(color:String, color2:String, diff:Float, ?remove0:Bool = false) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			var colorNum2:Int = Std.parseInt(color2);
			if(!color2.startsWith('0x')) colorNum2 = Std.parseInt('0xff' + color2);

			var color = FlxColor.interpolate(colorNum, colorNum2, diff);
			var daColor = color.toHexString();

			if (remove0)
				daColor = daColor.substring(2);

			return daColor;
		});

		Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, place:Dynamic) {
			if (isStageLua)
			{
				if (Stage.instance.swagBacks.exists(tag))
				{
					var shit = Stage.instance.swagBacks.get(tag);
		
					if (place == -1 || place == false)
						Stage.instance.toAdd.push(shit);
					else
					{
						if (place == true){place = 2;}
						Stage.instance.layInFront[place].push(shit);
					}
				}
			}
			else
			{
				if(PlayState.instance.modchartSprites.exists(tag)) {
					var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
					if(!shit.wasAdded) {
						if(place == 2 || place == true)
						{
							getInstance().add(shit);
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
						shit.wasAdded = true;
						//trace('added a thing: ' + tag);
					}
				}
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
		Lua_helper.add_callback(lua, "noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
			cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		//wow very convenient
		Lua_helper.add_callback(lua, "makeHealthIcon", function(tag:String, character:String, player:Bool = false) {
			tag = tag.replace('.', '');
			resetIconTag(tag);
			var leSprite:ModchartIcon = new ModchartIcon(character, player);
			PlayState.instance.modchartIcons.set(tag, leSprite); //yes
			var shit:ModchartIcon = PlayState.instance.modchartIcons.get(tag);
			shit.cameras = [PlayState.instance.camHUD];
			getInstance().add(shit);
		});
		
		//because the naming is stupid
		Lua_helper.add_callback(lua, "makeLuaIcon", function(tag:String, character:String, player:Bool = false) {
			tag = tag.replace('.', '');
			resetIconTag(tag);
			var leSprite:ModchartIcon = new ModchartIcon(character, player);
			PlayState.instance.modchartIcons.set(tag, leSprite); //yes
			var shit:ModchartIcon = PlayState.instance.modchartIcons.get(tag);
			shit.cameras = [PlayState.instance.camHUD];
			getInstance().add(shit);
		});
		
		Lua_helper.add_callback(lua, "changeAddedIcon", function(tag:String, character:String){
			var shit:ModchartIcon = PlayState.instance.modchartIcons.get(tag);
			shit.useOldSystem(character);
		});

		Lua_helper.add_callback(lua, "makeLuaCharacter", function(tag:String, character:String, isPlayer:Bool = false, flipped:Bool = false) {
			makeLuaCharacter(tag, character, isPlayer, flipped);
		});

		Lua_helper.add_callback(lua, "changeLuaCharacter", function(tag:String, character:String){
			var shit:Character = PlayState.instance.modchartCharacters.get(tag);
			makeLuaCharacter(tag, character, shit.isPlayer, shit.flipMode);
		});

		Lua_helper.add_callback(lua, "makeLuaTrail", function(tag:String, character:String, color:String) {
			resetTrailTag(tag);
			if (getObjectDirectly(character) != null)
			{
				var leObj:Dynamic = getObjectDirectly(character);
				var leSprite:DeltaTrail = new DeltaTrail(leObj, null, 4, 12 / 60, 0.25, 0.069);

				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
				leSprite.color = colorNum;
	
				PlayState.instance.modchartTrails.set(tag, leSprite); //yes
				var shit:DeltaTrail = PlayState.instance.modchartTrails.get(tag);
				getInstance().remove(leSprite, true);
				getInstance().insert(getInstance().members.indexOf(leObj)-1, leSprite);
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

			getInstance().remove(pee, true);

			if(destroy) {
				pee.destroy();
				PlayState.instance.modchartTrails.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "animExists", function(tag:String, anim:String){
			var shit:Dynamic = getObjectDirectly2(tag);
			
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
			var leObj:FlxBasic = getObjectDirectly(killMe[0]);
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

		Lua_helper.add_callback(lua, "characterDance", function(character:String) {
			if(PlayState.instance.modchartCharacters.exists(character)) {
				var spr:Character = PlayState.instance.modchartCharacters.get(character);
				spr.dance();
			}
			else
				getObjectDirectly(character).dance();
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
		
		Lua_helper.add_callback(lua, "setOffset", function(id:String, x:Float, y:Float) {
			var shit:Dynamic = getObjectDirectly2(id);
			shit.offset.set(x, y);
		});

		// LUA TEXTS
		Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
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

		//input text
		Lua_helper.add_callback(lua, "makeLuaInputText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetInputTextTag(tag);
			var leText:ModchartInputText = new ModchartInputText(x, y, width, text);
			PlayState.instance.modchartInputTexts.set(tag, leText);
		});

		Lua_helper.add_callback(lua, "addLuaInputText", function(tag:String) {
			if(PlayState.instance.modchartInputTexts.exists(tag)) {
				var shit:ModchartInputText = PlayState.instance.modchartInputTexts.get(tag);
				if(!shit.wasAdded) {
					getInstance().add(shit);
					shit.wasAdded = true;
					//trace('added a thing: ' + tag);
				}
			}
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

		Lua_helper.add_callback(lua,"setPlaybackRate", function(x:Float) {
			PlayState.instance.set_playbackRate(x);

			if (PlayState.instance != null)
				FlxG.camera.follow(PlayState.instance.camFollow, LOCKON, (PlayState.instance.cameraSpeed*0.04) * x * (30 / (cast (Lib.current.getChildAt(0), Main)).getFPS()));
		});

		Lua_helper.add_callback(lua, "updateHitbox", function(obj:String) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				shit.updateHitbox();
				return;
			}

			if(PlayState.instance.modchartCharacters.exists(obj)) {
				var shit:Character = PlayState.instance.modchartCharacters.get(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(poop != null) {
				poop.updateHitbox();
				return;
			}
			luaTrace('updateHibox: Couldnt find object: ' + obj);
		});
		Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(getInstance(), group)[index].updateHitbox();
		});

		//SHADER SHIT

		Lua_helper.add_callback(lua, "addChromaticAbberationEffect", function(camera:String,chromeOffset:Float = 0.005) {
			
			PlayState.instance.addShaderToCamera(camera, new ChromaticAberrationEffect(chromeOffset));
			
		});

		Lua_helper.add_callback(lua, "addEffect", function(camera:String,effect:String, ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic, ?val4:Dynamic) {
			
			PlayState.instance.addShaderToCamera(camera, getEffectFromString(effect, val1, val2, val3, val4));
			
		});
		Lua_helper.add_callback(lua, "clearEffects", function(camera:String) {
			PlayState.instance.clearShaderFromCamera(camera);
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

		//new psych shaders
		// shader shit
		Lua_helper.add_callback(lua, "initLuaShader", function(name:String, glslVersion:Int = 120) {
			if(!FlxG.save.data.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return initLuaShader(name, glslVersion);
			#else
			luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		Lua_helper.add_callback(lua, "setSpriteShader", function(obj:String, shader:String) {
			if(!FlxG.save.data.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			if(!PlayState.instance.runtimeShaders.exists(shader) && !initLuaShader(shader))
			{
				luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var killMe:Array<String> = obj.split('.');
			var leObj:FlxSprite = getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				var arr:Array<String> = PlayState.instance.runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			#else
			luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxSprite = getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});


		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getBool(prop);
			#else
			luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			Lua.pushnil(lua);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			Lua.pushnil(lua);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getInt(prop);
			#else
			luaTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			Lua.pushnil(lua);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			Lua.pushnil(lua);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getFloat(prop);
			#else
			luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			Lua.pushnil(lua);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			Lua.pushnil(lua);
			return null;
			#end
		});


		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setBool(prop, value);
			#else
			luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setBoolArray(prop, values);
			#else
			luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setInt(prop, value);
			#else
			luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setIntArray(prop, values);
			#else
			luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setFloat(prop, value);
			#else
			luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setFloatArray(prop, values);
			#else
			luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.returnGraphic(bitmapdataPath);
			if(value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
			}
			#else
			luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
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
	

		if (PlayState.instance != null && PlayState.instance.isDetected)
		{
			for (i in 0...PlayState.instance.strumLineNotes.length) {
				var member = PlayState.instance.strumLineNotes.members[i];
				trace(PlayState.instance.strumLineNotes.members[i].x + " " + PlayState.instance.strumLineNotes.members[i].y + " " + PlayState.instance.strumLineNotes.members[i].angle + " | strum" + i);
				//set("strum" + i + "X", Math.floor(member.x));
				set("defaultStrum" + i + "X", Math.floor(member.x));
				//set("strum" + i + "Y", Math.floor(member.y));
				set("defaultStrum" + i + "Y", Math.floor(member.y));
				//set("strum" + i + "Angle", Math.floor(member.angle));
				set("defaultStrum" + i + "Angle", Math.floor(member.angle));
				set("defaultStrum" + i + "Alpha", Math.floor(member.alpha));
				trace("Adding strum" + i);
				
				if (PlayState.instance.isDetected)
					new LuaReceptor(member, "receptor_" + i).Register(lua);
			}

			if (PlayState.instance.isDetected)
			{
				new LuaGame().Register(lua);
				new LuaWindow().Register(lua);
			}
		}
		
		//dumb group dancer shit
		// default strums
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
	
	public function getObjectDirectly2(id:String):Dynamic
	{
		var shit:Dynamic = "long string of text so there's no way someone names it this";

		if(Stage.instance.swagBacks.exists(id))
			shit = Stage.instance.swagBacks.get(id);
		else if(PlayState.instance.Stage.swagBacks.exists(id))
			shit = PlayState.instance.Stage.swagBacks.get(id);
		else if(PlayState.instance.getLuaObject(id) != null)
			shit = PlayState.instance.getLuaObject(id);
		else if (PlayState.instance != null)
			shit = getActorByName(id);

		return shit;
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
			case 'camnotes' | 'notes': return PlayState.instance.camNotes;
		}
		return PlayState.instance.camGame;
	}

	inline function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	function cancelTimer(tag:String) {
		if(PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);

			return;
		}

		var daTimer:Dynamic = Reflect.getProperty(getInstance(), tag);
		if(Std.isOfType(daTimer, FlxTimer)) {
			daTimer.cancel();
			daTimer.destroy();
			return;
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
	}

	function resetInputTextTag(tag:String) {
		if(!PlayState.instance.modchartInputTexts.exists(tag)) {
			return;
		}
		
		var pee:ModchartInputText = PlayState.instance.modchartInputTexts.get(tag);
		pee.kill();

		PlayState.instance.remove(pee, true);
		pee.destroy();
		PlayState.instance.modchartInputTexts.remove(tag);
	}

	function resetSpriteTag(tag:String) {
		if(!PlayState.instance.modchartSprites.exists(tag) && !PlayState.instance.Stage.swagBacks.exists(tag)) {
			return;
		}
		
		if(PlayState.instance.modchartSprites.exists(tag))
		{
			var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			pee.kill();
			if(pee.wasAdded) {
				PlayState.instance.remove(pee, true);
			}
			pee.destroy();
			PlayState.instance.modchartSprites.remove(tag);
		}
		
		if(PlayState.instance.Stage.swagBacks.exists(tag))
		{
			var pee:ModchartSprite = PlayState.instance.Stage.swagBacks.get(tag);
			pee.kill();
			PlayState.instance.remove(pee, true);
			pee.destroy();
			PlayState.instance.Stage.swagBacks.remove(tag);
		}
	}

	function resetIconTag(tag:String) {
		if(!PlayState.instance.modchartIcons.exists(tag)) {
			return;
		}
		
		var pee:ModchartIcon = PlayState.instance.modchartIcons.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartIcons.remove(tag);
	}

	public static function resetCharacterTag(tag:String) {
		if(!PlayState.instance.modchartCharacters.exists(tag)) {
			return;
		}
		
		var pee:Dynamic = PlayState.instance.modchartCharacters.get(tag);
		pee.kill();
		PlayState.instance.remove(pee, true);
		pee.destroy();
		PlayState.instance.modchartCharacters.remove(tag);
	}

	public static function resetTrailTag(tag:String) {
		if(!PlayState.instance.modchartTrails.exists(tag)) {
			return;
		}
		
		var pee:Dynamic = PlayState.instance.modchartTrails.get(tag);
		pee.kill();

		pee.destroy();
		PlayState.instance.modchartTrails.remove(tag);
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
			case 'desaturation': return new DesaturationEffect(val1);
			case 'fisheye': return new FishEyeEffect(val1);
		}
		return new GreyscaleEffect();
	}

	function loadFrames(spr:FlxSprite, image:String, spriteType:String)
	{
		if (!Paths.currentTrackedAssets.exists(image))
			Paths.cacheImage(image);

		switch(spriteType.toLowerCase().trim())
		{
			case "texture" | "textureatlas"|"tex":
				spr.frames = AtlasFrameMaker.construct(image);
			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);
			case "packer" |"packeratlas"|"pac":
				spr.frames = Paths.getPackerAtlas(image);
			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}

		if (FlxG.save.data.poltatoPC)
		{
			spr.scale.set(2, 2);
			spr.updateHitbox();
		}
	}

	public static inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}

	#if (!flash && sys)
	public function getShader(obj:String):FlxRuntimeShader
	{
		var killMe:Array<String> = obj.split('.');
		var leObj:FlxSprite = getObjectDirectly(killMe[0]);
		if(killMe.length > 1) {
			leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
		}

		if(leObj != null) {
			var shader:Dynamic = leObj.shader;
			var shader:FlxRuntimeShader = shader;
			return shader;
		}
		return null;
	}
	#end
	
	function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!FlxG.save.data.shaders) return false;

		#if (!flash && sys)
		if(PlayState.instance.runtimeShaders.exists(name))
		{
			luaTrace('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
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
					PlayState.instance.runtimeShaders.set(name, [frag, vert]);
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

}
#end

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public var animPrefixes:Map<String, String> = new Map<String, String>();
	//public var isInFront:Bool = false;
}

class ModchartBackdrop extends FlxBackdrop
{
	public var wasAdded:Bool = false;
	//public var isInFront:Bool = false;
}

class ModchartIcon extends HealthIcon
{
	public var wasAdded:Bool = false;
	//public var isInFront:Bool = false;
}

class ModchartInputText extends FlxInputText
{
	public var wasAdded:Bool = false;
	//public var isInFront:Bool = false;
}

class ModchartText extends FlxText
{
	public var wasAdded:Bool = false;
	public function new(x:Float, y:Float, text:String, width:Float)
	{
		super(x, y, width, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cameras = [PlayState.instance.camHUD];
		scrollFactor.set();
		borderSize = 2;
	}
}

class DebugLuaText extends FlxText
{
	private var disableTime:Float = 6;
	public var parentGroup:FlxTypedGroup<DebugLuaText>; 
	public function new(text:String, parentGroup:FlxTypedGroup<DebugLuaText>, color:FlxColor) {
		this.parentGroup = parentGroup;
		super(10, 10, 0, text, 16);
		setFormat(Paths.font("vcr.ttf"), 20, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		disableTime -= elapsed;
		if(disableTime <= 0) {
			kill();
			parentGroup.remove(this);
			destroy();
		}
		else if(disableTime < 1) alpha = disableTime;
	}
}

#if hscript
class HScript
{
	public static var parser:Parser = new Parser();
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables()
	{
		return interp.variables;
	}

	public function new()
	{
		interp = new Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		//interp.variables.set('CustomSubstate', CustomSubstate);
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		interp.variables.set('StringTools', StringTools);

		interp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		interp.variables.set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		interp.variables.set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		HScript.parser.line = 1;
		HScript.parser.allowTypes = true;
		return interp.execute(HScript.parser.parseString(codeToRun));
	}
}
#end
