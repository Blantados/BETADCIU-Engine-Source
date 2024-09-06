package luafiles;

import flixel.group.*;
import flixel.FlxBasic;
import objects.Stage;

//Ryiuu here -- props to glowsoony he helped A LOT with this
class SpriteGroupFunctions
{
  public static function implement(funk:ModchartState)
  {
    var lua = funk.lua;
    Lua_helper.add_callback(lua, "makeLuaSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
      try
      {
        tag = tag.replace('.', '');
        LuaUtils.resetSpriteTag(tag);
        var group:FlxSpriteGroup = new FlxSpriteGroup(x, y, maxSize);
        if (funk.isStageLua && !funk.preloading) Stage.instance.swagBacks.set(tag, group);
        else
          PlayState.instance.modchartSprites.set(tag, group);
      }
      catch (e:haxe.Exception)
      {
        trace('MakeLuaSpriteGroup ERROR ! ${e.message}');
      }
    });

    Lua_helper.add_callback(lua, 'groupInsertSprite', function(tag:String, obj:String, index:Int, pos:Int, removeFromGroup:Bool = false) {
      try
      {
        var group:FlxSpriteGroup = PlayState.instance.modchartSprites.get(tag);

        var real = cast(PlayState.instance.getLuaObject(obj), FlxSprite);
				if(real!=null){
          if (removeFromGroup) group.remove(real, true);
          group.insert(pos, real);  
					return true;
				}

        if (Stage.instance.swagBacks.exists(obj))
        {
          var real:FlxSprite = changeSpriteClass(Stage.instance.swagBacks.get(obj));

          if (removeFromGroup) group.remove(real, true);
          group.insert(pos, real);  
					return true;
        }  

        var killMe:Array<String> = obj.split('.');
				var object:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(object != null) {
          var convertedSprite:FlxSprite = cast(object, FlxSprite);
          if (removeFromGroup) group.remove(convertedSprite, true);
          group.insert(pos, convertedSprite);  
					return true;
				}
        return false;
      }
      catch (e:haxe.Exception)
      {
        trace('groupInsert Error ! ${e.message}');
        return false;
      }
    });

    Lua_helper.add_callback(lua, 'groupRemoveSprite', function(tag:String, obj:String, splice:Bool = false) {
      try
      {
        var group:FlxSpriteGroup = PlayState.instance.modchartSprites.get(tag);

        var real = cast(PlayState.instance.getLuaObject(obj), FlxSprite);
				if(real!=null){
          if (group != null) group.remove(real, splice);
					return true;
				}

        if (Stage.instance.swagBacks.exists(obj))
        {
          var real:FlxSprite = changeSpriteClass(Stage.instance.swagBacks.get(obj));

          if (group != null) group.remove(real, splice);
          return true;
        }    

        var killMe:Array<String> = obj.split('.');
				var object:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(object != null) {
          var convertedSprite:FlxSprite = cast(object, FlxSprite);
          if (group != null) group.remove(convertedSprite, splice);
					return true;
				}
        return false;
      }
      catch (e:haxe.Exception)
      {
        trace('groupRemove Error ! ${e.message}');
        return false;
      }
    });

    Lua_helper.add_callback(lua, 'groupAddSprite', function(tag:String, obj:String) {
      try
      {
        var group:FlxSpriteGroup = PlayState.instance.modchartSprites.get(tag);

        var real = cast(PlayState.instance.getLuaObject(obj), FlxSprite);
				if(real!=null){
          if (group != null) group.add(real);
					return true;
				}

        if (Stage.instance.swagBacks.exists(obj))
        {
          var real:FlxSprite = changeSpriteClass(Stage.instance.swagBacks.get(obj));

          if (group != null) group.add(real);
          return true;
        }    

        var killMe:Array<String> = obj.split('.');
				var object:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
				}
	
				if(object != null) {
          var convertedSprite:FlxSprite = cast(object, FlxSprite);
          if (group != null) group.add(convertedSprite);
					return true;
				}
        return false;
      }
      catch (e:haxe.Exception)
      {
        trace('groupAdd Error ! ${e.message + e.stack}');
        return false;
      }
    });

    Lua_helper.add_callback(lua, 'setGroupCameras', function(tag:String, cams:Array<String>) {
      try
      {
        var group:FlxSpriteGroup = PlayState.instance.modchartSprites.get(tag);
        var cameras:Array<FlxCamera> = [];
        for (i in 0...cams.length)
        {
          cameras.push(LuaUtils.cameraFromString(cams[i]));
        }
        if (group != null) group.cameras = cameras;
      }
      catch (e:haxe.Exception)
      {
        trace('setGroupCams Error ! ${e.message + e.stack}');
      }
    });

    Lua_helper.add_callback(lua, 'setGroupCamera', function(tag:String, cam:String) {
      try
      {
        var group:FlxSpriteGroup = PlayState.instance.modchartSprites.get(tag);
        if (group != null) group.camera = LuaUtils.cameraFromString(cam);
      }
      catch (e:haxe.Exception)
      {
        trace('setGroupCam Error ! ${e.message + e.stack}');
      }
    });
  }
  static function changeSpriteClass(tag:Dynamic):FlxSprite {
		return tag;
	}
}
