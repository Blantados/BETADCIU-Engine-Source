package luafiles;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

import shaders.Shaders;
import openfl.filters.ShaderFilter;

class ShaderFunctions
{
	public static function implement(funk:ModchartState)
	{
		var lua = funk.lua;
		var game:PlayState = PlayState.instance;

		// shader shit
		Lua_helper.add_callback(lua, "initLuaShader", function(name:String, ?glslVersion:Int = 120) {
			if(!FlxG.save.data.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return initLuaShader(name, glslVersion);
			#else
			ModchartState.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		Lua_helper.add_callback(lua, "setSpriteShader", function(obj:String, shader:String, ?keepOtherShaders:Bool = true) {
			if(!FlxG.save.data.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			if(!game.runtimeShaders.exists(shader) && !initLuaShader(shader))
			{
				ModchartState.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var split:Array<String> = obj.split('.');
			var leObj:Dynamic = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				var arr:Array<String> = game.runtimeShaders.get(shader);
				var daShader:FlxRuntimeShader = new FlxRuntimeShader(arr[0], arr[1]); 

				if (Std.isOfType(leObj, FlxCamera)){
					var daFilters = (leObj.filters != null && keepOtherShaders) ? leObj.filters : [];
					
					daFilters.push(new ShaderFilter(daShader));

					leObj.setFilters(daFilters);
				}
				else{
					var daObj:FlxSprite = leObj;
					daObj.shader = daShader;
				}
				
				return true;
			}
			#else
			ModchartState.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String, ?shader:String = "") {
			var split:Array<String> = obj.split('.');
			var leObj:Dynamic = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				if (Std.isOfType(leObj, FlxCamera)){
					var newCamEffects = [];

					if (shader != "" && shader.length > 0)
					{
						var daFilters = [];
						var swagFilters = [];

						if (leObj.filters != null){
							daFilters = leObj.filters;
							swagFilters = leObj.filters;
						}

						var arr:Array<String> = PlayState.instance.runtimeShaders.get(shader);
						
						for (i in 0...daFilters.length){	
							var filter:ShaderFilter = daFilters[i];

							if (filter.shader.glFragmentSource == processFragmentSource(arr[0])){
								swagFilters.remove(filter);
								break;
							}
						}
						
						newCamEffects = swagFilters;
					}
					
					leObj.setFilters(newCamEffects);
				}
				else{
					var daObj:FlxSprite = leObj;
					daObj.shader = null;
				}
			}
			return false;
		});


		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if (shader == null)
			{
				ModchartState.luaTrace("getShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
			#else
			ModchartState.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if (shader == null)
			{
				ModchartState.luaTrace("getShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			ModchartState.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if (shader == null)
			{
				ModchartState.luaTrace("getShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
			#else
			ModchartState.luaTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if (shader == null)
			{
				ModchartState.luaTrace("getShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			ModchartState.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if (shader == null)
			{
				ModchartState.luaTrace("getShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
			#else
			ModchartState.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if (shader == null)
			{
				ModchartState.luaTrace("getShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			ModchartState.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});


		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if(shader == null)
			{
				ModchartState.luaTrace("setShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			ModchartState.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if(shader == null)
			{
				ModchartState.luaTrace("setShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			ModchartState.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if(shader == null)
			{
				ModchartState.luaTrace("setShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			ModchartState.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if(shader == null)
			{
				ModchartState.luaTrace("setShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			ModchartState.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if(shader == null)
			{
				ModchartState.luaTrace("setShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			ModchartState.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if(shader == null)
			{
				ModchartState.luaTrace("setShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			ModchartState.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return true;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String, ?swagShader:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, swagShader);
			if(shader == null)
			{
				ModchartState.luaTrace("setShaderSampler2D: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.returnGraphic(bitmapdataPath);
			if(value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
			#else
			ModchartState.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});

		//Old Stuff
		Lua_helper.add_callback(lua, "addChromaticAbberationEffect", function(camera:String,chromeOffset:Float = 0.005) {	
			game.addShaderToCamera(camera, new ChromaticAberrationEffect(chromeOffset));
		});

		Lua_helper.add_callback(lua, "addEffect", function(camera:String,effect:String, ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic) {
			game.addShaderToCamera(camera, LuaUtils.getEffectFromString(effect, val1, val2, val3));		
		});
		Lua_helper.add_callback(lua, "clearEffects", function(camera:String) {
			game.clearShaderFromCamera(camera);
		});
	}
	
	public static function getShader(obj:String, ?swagShader:String):FlxRuntimeShader
	{
		return ModchartState.getShader(obj, swagShader);
	}

	public static function processFragmentSource(value:String):String
	{
		if (value != null){
			@:privateAccess
			value = value.replace("#pragma header", FlxRuntimeShader.BASE_FRAGMENT_HEADER).replace("#pragma body", FlxRuntimeShader.BASE_FRAGMENT_BODY);
		}
		
		return value;
	}

	#if (!flash && sys)
	public static function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!FlxG.save.data.shaders) return false;

		#if (!flash && sys)
		if(PlayState.instance.runtimeShaders.exists(name))
		{
			ModchartState.luaTrace('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

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
		ModchartState.luaTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		ModchartState.luaTrace('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}
	#end
}