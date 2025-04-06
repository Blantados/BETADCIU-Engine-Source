package luafiles;

import Type.ValueType;
import haxe.Constraints;

import substates.GameOverSubstate;
import objects.Stage;

//
// Functions that use a high amount of Reflections, which are somewhat CPU intensive
// These functions are held together by duct tape
//

class ReflectionFunctions
{
	static final instanceStr:Dynamic = "##MODCHARTSTATE_STRINGTOOBJ";
	public static function implement(funk:ModchartState)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "getProperty", function(variable:String, ?allowMaps:Bool = false) {
			var split:Array<String> = variable.split('.');

			if (Stage.instance.swagBacks.exists(split[0])){
				return Stage.instance.getProperty(variable);
			}

			if(split.length > 1)
				return LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split, true, true, allowMaps), split[split.length-1], allowMaps);
			return LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable, allowMaps);
		});
		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false) {
			var split:Array<String> = variable.split('.');

			if (variable.contains('velocity.')){
				if (PlayState.instance != null){value *= PlayState.instance.playbackRate;}
			}

			if (Stage.instance.swagBacks.exists(split[0]))
			{
				Stage.instance.setProperty(variable, value);
				return true;
			}

			if(split.length > 1) {
				LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split, true, true, allowMaps), split[split.length-1], value, allowMaps);
				return true;
			}
			LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, value, allowMaps);
			return true;
		});
		Lua_helper.add_callback(lua, "getPropertyFromClass", function(classVar:String, variable:String, ?allowMaps:Bool = false) {
			classVar = checkForOldClassVars(classVar);
			
			var myClass:Dynamic = Type.resolveClass(classVar);
			if(myClass == null)
			{
				ModchartState.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length-1)
					obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

				return LuaUtils.getVarInArray(obj, split[split.length-1], allowMaps);
			}
			return LuaUtils.getVarInArray(myClass, variable, allowMaps);
		});
		Lua_helper.add_callback(lua, "setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = false) {
			classVar = checkForOldClassVars(classVar);

			var myClass:Dynamic = Type.resolveClass(classVar);
			if(myClass == null)
			{
				ModchartState.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length-1)
					obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

				LuaUtils.setVarInArray(obj, split[split.length-1], value, allowMaps);
				return value;
			}
			LuaUtils.setVarInArray(myClass, variable, value, allowMaps);
			return value;
		});
		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false) {
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = LuaUtils.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = LuaUtils.getGroupStuff(realObject.members[index], variable, allowMaps);
				
				if(PlayState.instance.Stage.swagGroup.exists(obj)) 
					result = PlayState.instance.Stage.swagGroup.get(obj);

				return result;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = LuaUtils.getGroupStuff(leArray, variable, allowMaps);
				return result;
			}
			ModchartState.luaTrace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false) {
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = LuaUtils.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				if(PlayState.instance.Stage.swagGroup.exists(obj)) 
					realObject = PlayState.instance.Stage.swagGroup.get(obj);

				LuaUtils.setGroupStuff(realObject.members[index], variable, value, allowMaps);
				return value;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return value;
				}
				LuaUtils.setGroupStuff(leArray, variable, value, allowMaps);
			}
			return value;
		});
		Lua_helper.add_callback(lua, "removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(Std.isOfType(groupOrArray, FlxTypedGroup)) {
				if(PlayState.instance.Stage.swagGroup.exists(obj)) 
					groupOrArray = PlayState.instance.Stage.swagGroup.get(obj);

				var sex = groupOrArray.members[index];
				if(!dontDestroy)
					sex.kill();
				groupOrArray.remove(sex, true);
				if(!dontDestroy)
					sex.destroy();
				return;
			}
			groupOrArray.remove(groupOrArray[index]);
		});
		
		Lua_helper.add_callback(lua, "callMethod", function(funcToRun:String, ?args:Array<Dynamic> = null) {
			return callMethodFromObject(PlayState.instance, funcToRun, parseInstances(args));
			
		});
		Lua_helper.add_callback(lua, "callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic> = null) {
			return callMethodFromObject(Type.resolveClass(className), funcToRun, parseInstances(args));
		});

		Lua_helper.add_callback(lua, "createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic> = null) {
			variableToSave = variableToSave.trim().replace('.', '');
			if(!PlayState.instance.variables.exists(variableToSave))
			{
				if(args == null) args = [];
				var myType:Dynamic = Type.resolveClass(className);
		
				if(myType == null)
				{
					ModchartState.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
					return false;
				}

				var obj:Dynamic = Type.createInstance(myType, args);
				if(obj != null)
					PlayState.instance.variables.set(variableToSave, obj);
				else
					ModchartState.luaTrace('createInstance: Failed to create $variableToSave, arguments are possibly wrong.', false, false, FlxColor.RED);

				return (obj != null);
			}
			else ModchartState.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "addInstance", function(objectName:String, ?inFront:Bool = false) {
			if(PlayState.instance.variables.exists(objectName))
			{
				var obj:Dynamic = PlayState.instance.variables.get(objectName);
				if (inFront)
					LuaUtils.getTargetInstance().add(obj);
				else
				{
					if(!PlayState.instance.isDead)
						PlayState.instance.insert(PlayState.instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), obj);
					else
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
				}
			}
			else ModchartState.luaTrace('addInstance: Can\'t add what doesn\'t exist~ ($objectName)', false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "instanceArg", function(instanceName:String, ?className:String = null) {
			var retStr:String ='$instanceStr::$instanceName';
			if(className != null) retStr += '::$className';
			return retStr;
		});

		//Old Kade Reflect Stuff
		Lua_helper.add_callback(lua,"getActorX", function (id:String, ?bg:Bool = false) {
			if (bg)
				return PlayState.instance.Stage.swagBacks[id].x;
			else
				return LuaUtils.getActorByName(id).x;
		});

		Lua_helper.add_callback(lua,"getActorY", function (id:String, ?bg:Bool = false) {
			if (bg)
				return PlayState.instance.Stage.swagBacks[id].y;
			else
				return LuaUtils.getActorByName(id).y;
		});

			
		Lua_helper.add_callback(lua,"getActorAngle", function(id:String) {
			return LuaUtils.getActorByName(id).angle;
		});

		Lua_helper.add_callback(lua,"getActorWidth", function (id:String) {
			return LuaUtils.getActorByName(id).width;
		});

		Lua_helper.add_callback(lua,"getActorHeight", function (id:String) {
			return LuaUtils.getActorByName(id).height;
		});

		Lua_helper.add_callback(lua,"getActorAlpha", function(id:String) {
			return LuaUtils.getActorByName(id).alpha;
		});

		Lua_helper.add_callback(lua,"getActorXMidpoint", function (id:String, ?graphic:Bool = false) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);

			if (graphic)
				return shit.getGraphicMidpoint().x;

			return shit.getMidpoint().x;
		});

		Lua_helper.add_callback(lua,"getActorYMidpoint", function (id:String, ?graphic:Bool = false) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);

			if (graphic)
				return shit.getGraphicMidpoint().y;

			return shit.getMidpoint().y;
		});

		Lua_helper.add_callback(lua,"setActorX", function(x:Int,id:String, ?bg:Bool = false) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			shit.x = x;
		});

		Lua_helper.add_callback(lua,"setActorY", function(y:Int,id:String, ?bg:Bool = false) {
			if (bg){
				PlayState.instance.Stage.swagBacks[id].y = y;
			}
			else {
				LuaUtils.getActorByName(id).y = y;
			}	
		});

		Lua_helper.add_callback(lua,"setActorAlpha", function(alpha:Float,id:String, ?bg:Bool = false) {
			if (bg){
				PlayState.instance.Stage.swagBacks[id].alpha = alpha;
			}
			else {
				LuaUtils.getActorByName(id).alpha = alpha;
			}
		});

		Lua_helper.add_callback(lua,"setActorVisibility", function(alpha:Bool,id:String, ?bg:Bool = false) {
			if (bg){
				PlayState.instance.Stage.swagBacks[id].visible = alpha;
			}
			else {
				LuaUtils.getActorByName(id).visible = alpha;
			}	
		});

		Lua_helper.add_callback(lua,"setActorAccelerationY", function(y:Int,id:String) {
			LuaUtils.getActorByName(id).acceleration.y = y;
		});
		
		Lua_helper.add_callback(lua,"setActorDragY", function(y:Int,id:String) {
			LuaUtils.getActorByName(id).drag.y = y;
		});
		
		Lua_helper.add_callback(lua,"setActorVelocityY", function(y:Int,id:String) {
			LuaUtils.getActorByName(id).velocity.y = y;
		});
		
		Lua_helper.add_callback(lua,"setActorAngle", function(angle:Int,id:String) {
			LuaUtils.getActorByName(id).angle = angle;
		});

		Lua_helper.add_callback(lua,"setActorScale", function(scale:Float,id:String, ?bg:Bool = false) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			shit.setGraphicSize(Std.int(shit.width * scale));
			shit.updateHitbox();	
		});
		
		Lua_helper.add_callback(lua, "setActorScaleXY", function(scaleX:Float, scaleY:Float, id:String)
		{
			LuaUtils.getActorByName(id).setGraphicSize(Std.int(LuaUtils.getActorByName(id).width * scaleX), Std.int(LuaUtils.getActorByName(id).height * scaleY));
		});

		Lua_helper.add_callback(lua, "setActorFlipX", function(flip:Bool, id:String)
		{
			LuaUtils.getActorByName(id).flipX = flip;
		});
		

		Lua_helper.add_callback(lua, "setActorFlipY", function(flip:Bool, id:String)
		{
			LuaUtils.getActorByName(id).flipY = flip;
		});
	
		
		Lua_helper.add_callback(lua,"setActorAccelerationX", function(x:Int,id:String) {
			LuaUtils.getActorByName(id).acceleration.x = x;
		});
		
		Lua_helper.add_callback(lua,"setActorDragX", function(x:Int,id:String) {
			LuaUtils.getActorByName(id).drag.x = x;
		});
		
		Lua_helper.add_callback(lua,"setActorVelocityX", function(x:Int,id:String, ?bg:Bool = false) {
			if (bg){
				PlayState.instance.Stage.swagBacks[id].velocity.x = x;
			}
			else {
				LuaUtils.getActorByName(id).velocity.x = x;
			}				
		});
	}

	static function parseInstances(args:Array<Dynamic>)
	{
		for (i in 0...args.length)
		{
			var myArg:String = cast args[i];
			if(myArg != null && myArg.length > instanceStr.length)
			{
				var index:Int = myArg.indexOf('::');
				if(index > -1)
				{
					myArg = myArg.substring(index+2);
					//trace('Op1: $myArg');
					var lastIndex:Int = myArg.lastIndexOf('::');

					var split:Array<String> = myArg.split('.');
					args[i] = (lastIndex > -1) ? Type.resolveClass(myArg.substring(0, lastIndex)) : PlayState.instance;
					for (j in 0...split.length)
					{
						//trace('Op2: ${Type.getClass(args[i])}, ${split[j]}');
						args[i] = LuaUtils.getVarInArray(args[i], split[j].trim());
						//trace('Op3: ${args[i] != null ? Type.getClass(args[i]) : null}');
					}
				}
			}
		}
		return args;
	}

	static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic> = null)
	{
		if(args == null) args = [];

		var split:Array<String> = funcStr.split('.');
		var funcToRun:Function = null;
		var obj:Dynamic = classObj;
		//trace('start: ' + obj);
		if(obj == null)
		{
			return null;
		}

		for (i in 0...split.length)
		{
			obj = LuaUtils.getVarInArray(obj, split[i].trim());
			//trace(obj, split[i]);
		}

		funcToRun = cast obj;
		//trace('end: $obj');
		return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
	}

	static function checkForOldClassVars(classVar:String){
		switch(classVar){
			case "ClientPrefs": classVar = "backend.ClientPrefs";
			case "Conductor": classVar = "backend.Conductor";
			case "LoadingState": classVar = "states.LoadingState";
			case "ModchartState": classVar = "luafiles.ModchartState";
			case "PlayState": classVar = "states.PlayState";
		}

		return classVar;
	}
}