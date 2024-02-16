package luafiles;

import flixel.addons.ui.FlxInputText;

import backend.WeekData;
import objects.HealthIcon;
import objects.Character;
import objects.Stage;

import shaders.Shaders;
import openfl.display.BlendMode;
import Type.ValueType;

import substates.GameOverSubstate;

typedef LuaTweenOptions = {
	type:FlxTweenType,
	startDelay:Float,
	onUpdate:Null<String>,
	onStart:Null<String>,
	onComplete:Null<String>,
	loopDelay:Float,
	ease:EaseFunction
}

class LuaUtils
{
	public static function getLuaTween(options:Dynamic)
	{
		return {
			type: getTweenTypeByString(options.type),
			startDelay: options.startDelay,
			onUpdate: options.onUpdate,
			onStart: options.onStart,
			onComplete: options.onComplete,
			loopDelay: options.loopDelay,
			ease: getTweenEaseByString(options.ease)
		};
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
	{
		if (value == "true") value = true; //stupid fix but whatever

		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1)
		{
			var target:Dynamic = null;
			if(PlayState.instance.variables.exists(splitProps[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else if (PlayState.instance.Stage.swagBacks.exists(splitProps[0]))
			{
				var retVal:Dynamic = PlayState.instance.Stage.swagBacks.get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else if (Stage.instance.swagBacks.exists(splitProps[0]))
			{
				var retVal:Dynamic = Stage.instance.swagBacks.get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if(i >= splitProps.length-1) //Last array
					target[j] = value;
				else //Anything else
					target = target[j];
			}
			return target;
		}

		if(allowMaps && isMap(instance))
		{
			//trace(instance);
			instance.set(variable, value);
			return value;
		}

		if(PlayState.instance.variables.exists(variable))
		{
			PlayState.instance.variables.set(variable, value);
			return value;
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
		return value;
	}
	public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any
	{
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1)
		{
			var target:Dynamic = null;
			if(PlayState.instance.variables.exists(splitProps[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else if (PlayState.instance.Stage.swagBacks.exists(splitProps[0]))
				{
					var retVal:Dynamic = PlayState.instance.Stage.swagBacks.get(splitProps[0]);
					if(retVal != null)
						target = retVal;
				}
				else if (Stage.instance.swagBacks.exists(splitProps[0]))
				{
					var retVal:Dynamic = Stage.instance.swagBacks.get(splitProps[0]);
					if(retVal != null)
						target = retVal;
				}
			else
				target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}
		
		if(allowMaps && isMap(instance))
		{
			//trace(instance);
			return instance.get(variable);
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
			var retVal:Dynamic = Stage.instance.swagBacks.get(variable);
				if(retVal != null)
					return retVal;
		}
		return Reflect.getProperty(instance, variable);
	}

	public static function getModSetting(saveTag:String, ?modName:String = null)
	{
		#if MODS_ALLOWED
		if(FlxG.save.data.modSettings == null) FlxG.save.data.modSettings = new Map<String, Dynamic>();

		var settings:Map<String, Dynamic> = FlxG.save.data.modSettings.get(modName);
		var path:String = Paths.mods('$modName/data/settings.json');
		if(FileSystem.exists(path))
		{
			if(settings == null || !settings.exists(saveTag))
			{
				if(settings == null) settings = new Map<String, Dynamic>();
				var data:String = File.getContent(path);
				try
				{
					//FunkinLua.luaTrace('getModSetting: Trying to find default value for "$saveTag" in Mod: "$modName"');
					var parsedJson:Dynamic = tjson.TJSON.parse(data);
					for (i in 0...parsedJson.length)
					{
						var sub:Dynamic = parsedJson[i];
						if(sub != null && sub.save != null && !settings.exists(sub.save))
						{
							if(sub.type != 'keybind' && sub.type != 'key')
							{
								if(sub.value != null)
								{
									//FunkinLua.luaTrace('getModSetting: Found unsaved value "${sub.save}" in Mod: "$modName"');
									settings.set(sub.save, sub.value);
								}
							}
							else
							{
								//FunkinLua.luaTrace('getModSetting: Found unsaved keybind "${sub.save}" in Mod: "$modName"');
								settings.set(sub.save, {keyboard: (sub.keyboard != null ? sub.keyboard : 'NONE'), gamepad: (sub.gamepad != null ? sub.gamepad : 'NONE')});
							}
						}
					}
					FlxG.save.data.modSettings.set(modName, settings);
				}
				catch(e:Dynamic)
				{
					var errorTitle = 'Mod name: ' + Mods.currentModDirectory;
					var errorMsg = 'An error occurred: $e';
					#if windows
					lime.app.Application.current.window.alert(errorMsg, errorTitle);
					#end
					trace('$errorTitle - $errorMsg');
				}
			}
		}
		else
		{
			FlxG.save.data.modSettings.remove(modName);
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			PlayState.instance.addTextToDebug('getModSetting: $path could not be found!', FlxColor.RED);
			#else
			FlxG.log.warn('getModSetting: $path could not be found!');
			#end
			return null;
		}

		if(settings.exists(saveTag)) return settings.get(saveTag);
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		PlayState.instance.addTextToDebug('getModSetting: "$saveTag" could not be found inside $modName\'s settings!', FlxColor.RED);
		#else
		FlxG.log.warn('getModSetting: "$saveTag" could not be found inside $modName\'s settings!');
		#end
		#end
		return null;
	}
	
	public static function isMap(variable:Dynamic)
	{
		/*switch(Type.typeof(variable)){
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return true;
			default:
				return false;
		}*/

		//trace(variable);
		if(variable.exists != null && variable.keyValueIterator != null) return true;
		return false;
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length-1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length-1];
		}
		if(allowMaps && isMap(leArray)) leArray.set(variable, value);
		else Reflect.setProperty(leArray, variable, value);
		return value;
	}
	public static function getGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length-1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length-1];
		}

		if(allowMaps && isMap(leArray)) return leArray.get(variable);
		return Reflect.getProperty(leArray, variable);
	}

	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true, ?allowMaps:Bool = false):Dynamic
	{
		var obj:Dynamic = getObjectDirectly(split[0], checkForTextsToo);
		var end = split.length;
		if(getProperty) end = split.length-1;

		for (i in 1...end) obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?allowMaps:Bool = false):Dynamic
	{
		switch(objectName)
		{
			case 'this' | 'instance' | 'game':
				return PlayState.instance;
			
			default:
				if (objectName == 'dadGroup' || objectName == 'boyfriendGroup' || objectName == 'gfGroup'){
					objectName = objectName.substring(0, objectName.length-5);
				}

				var obj:Dynamic = null;

				if (Stage.instance.swagBacks.exists(objectName)){
					obj = Stage.instance.swagBacks.get(objectName);
				}
				else if (PlayState.instance.Stage.swagBacks.exists(objectName)){
					obj = PlayState.instance.Stage.swagBacks.get(objectName);
				}
				else if(PlayState.instance.getLuaObject(objectName) != null){
					obj = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
				}
				

				if(obj == null){
					obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
				}

				if (obj == null){
					obj = getActorByName(objectName);
				}

				return obj;
		}
	}

	inline public static function getTextObject(name:String):FlxText
	{
		return #if LUA_ALLOWED PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : #end Reflect.getProperty(PlayState.instance, name);
	}

	public static function getActorByName(id:String):Dynamic
	{
		// pre defined names
		switch(id)
		{
			case 'boyfriend' | 'bf':
				return PlayState.instance.boyfriend;
		}

		if (id.contains('stage-'))
		{
			var daID:String = id.split('-')[1];
			return PlayState.instance.Stage.swagBacks[daID];
		}

		if (Std.parseInt(id) == null)
			return Reflect.getProperty(getTargetInstance(),id);

		return PlayState.instance.strumLineNotes.members[Std.parseInt(id)];
	}
	
	public static function isOfTypes(value:Any, types:Array<Dynamic>)
	{
		for (type in types)
		{
			if(Std.isOfType(value, type)) return true;
		}
		return false;
	}
	
	public static inline function getTargetInstance()
	{
		var instance:Dynamic = Stage.instance;

		if (PlayState.instance != null){
			instance = (PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance);
		}

		return instance;
	}

	//because we don't use groups
	public static inline function getLowestCharacterGroup():FlxSprite
	{
		return getLowestCharacter();
	}

	public static inline function getLowestCharacter():FlxSprite
	{
		var group:FlxSprite = PlayState.instance.gf;
		var pos:Int = PlayState.instance.members.indexOf(group);

		var newPos:Int = PlayState.instance.members.indexOf(PlayState.instance.boyfriend);
		if(newPos < pos)
		{
			group = PlayState.instance.boyfriend;
			pos = newPos;
		}
		
		newPos = PlayState.instance.members.indexOf(PlayState.instance.dad);
		if(newPos < pos)
		{
			group = PlayState.instance.dad;
			pos = newPos;
		}
		return group;
	}
	
	public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Int = 24, loop:Bool = false)
	{
		var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
		if(obj != null && obj.animation != null)
		{
			if(indices == null)
				indices = [0];
			else if(Std.isOfType(indices, String))
			{
				var strIndices:Array<String> = cast (indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length) {
					myIndices.push(Std.parseInt(strIndices[i]));
				}
				indices = myIndices;
			}

			obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
			if(obj.animation.curAnim == null)
			{
				if(obj.playAnim != null) obj.playAnim(name, true);
				else obj.animation.play(name, true);
			}
			return true;
		}
		return false;
	}
	
	public static function loadFrames(spr:FlxSprite, image:String, spriteType:String)
	{
		switch(spriteType.toLowerCase().trim())
		{
			//case "texture" | "textureatlas" | "tex":
				//spr.frames = AtlasFrameMaker.construct(image);

			//case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				//spr.frames = AtlasFrameMaker.construct(image, null, true);

			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);

			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}	

	public static function resetTextTag(tag:String) {
		#if LUA_ALLOWED
		if(!PlayState.instance.modchartTexts.exists(tag)) {
			return;
		}

		var target:FlxText = PlayState.instance.modchartTexts.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartTexts.remove(tag);
		#end
	}

	public static function resetInputTextTag(tag:String) {
		#if LUA_ALLOWED
		if(!PlayState.instance.modchartInputTexts.exists(tag)) {
			return;
		}
		
		var pee:FlxInputText = PlayState.instance.modchartInputTexts.get(tag);
		pee.kill();
		PlayState.instance.remove(pee, true);
		pee.destroy();
		PlayState.instance.modchartInputTexts.remove(tag);
		#end
	}

	public static function resetSpriteTag(tag:String = "") {
		if(!PlayState.instance.modchartSprites.exists(tag) && !Stage.instance.swagBacks.exists(tag)) {
			return;
		}
		
		if (PlayState.instance != null)
		{
			if(PlayState.instance.modchartSprites.exists(tag))
			{
				var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				pee.kill();
				
				PlayState.instance.remove(pee, true);
				pee.destroy();
				PlayState.instance.modchartSprites.remove(tag);
				return;
			}
			
			if(Stage.instance.swagBacks.exists(tag))
			{
				var pee:ModchartSprite = Stage.instance.swagBacks.get(tag);
				pee.kill();
					
				PlayState.instance.remove(pee, true);
				pee.destroy();
				Stage.instance.swagBacks.remove(tag);
				return;
			}
		}
	}

	public static function resetIconTag(tag:String) {
		if(!PlayState.instance.modchartIcons.exists(tag)) {
			return;
		}
		
		var pee:HealthIcon = PlayState.instance.modchartIcons.get(tag);
		pee.kill();
		PlayState.instance.remove(pee, true);
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

	public static function cancelTween(tag:String) {
		#if LUA_ALLOWED
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
		#end
	}

	public static function tweenPrepare(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = LuaUtils.getObjectDirectly(variables[0]);
		if(variables.length > 1) sexyProp = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(variables), variables[variables.length-1]);
		return sexyProp;
	}

	public static function cancelTimer(tag:String) {
		#if LUA_ALLOWED
		if(PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
		#end
	}

	//buncho string stuffs
	public static function getTweenTypeByString(?type:String = '') {
		switch(type.toLowerCase().trim())
		{
			case 'backward': return FlxTweenType.BACKWARD;
			case 'looping'|'loop': return FlxTweenType.LOOPING;
			case 'persist': return FlxTweenType.PERSIST;
			case 'pingpong': return FlxTweenType.PINGPONG;
		}
		return FlxTweenType.ONESHOT;
	}

	public static function getTweenEaseByString(?ease:String = '') {
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

	public static function blendModeFromString(blend:String):BlendMode {
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
	
	public static function typeToString(type:Int):String {
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

	public static function cameraFromString(cam:String):FlxCamera 
	{
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
			case 'camnotes' | 'notes': return PlayState.instance.camNotes;
		}

		//modded cameras
		if (Std.isOfType(PlayState.instance.variables.get(cam), FlxCamera)){
			return PlayState.instance.variables.get(cam);
		}

		return PlayState.instance.camGame;
	}
	

	public static function getEffectFromString(?effect:String = '', ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic , ?val4:Dynamic = ""):ShaderEffect {
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
}