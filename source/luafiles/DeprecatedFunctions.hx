package luafiles;

import objects.Stage;
import objects.Character;
//
// This is simply where i store deprecated functions for it to be more organized.
// I would suggest not messing with these, as it could break mods.
//

class DeprecatedFunctions
{
	public static function implement(funk:ModchartState)
	{
		var lua:State = funk.lua;
		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		Lua_helper.add_callback(lua, "addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			ModchartState.luaTrace("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead", false, true);
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		Lua_helper.add_callback(lua, "objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			//ModchartState.luaTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true); // i still use this
			if(LuaUtils.getObjectDirectly(obj) != null) {
				LuaUtils.getObjectDirectly(obj).animation.play(name, forced, false, startFrame);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(spr != null) {
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}
			return false;
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
		Lua_helper.add_callback(lua, "luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			ModchartState.luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag))
				PlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, CoolUtil.colorFromString(color));
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			ModchartState.luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			ModchartState.luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if(pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
			ModchartState.luaTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).animation.play(name, forced);
			}
		});
		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(tag:String, camera:String = '') {
			ModchartState.luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			ModchartState.luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			ModchartState.luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			ModchartState.luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getPropertyLuaSprite", function(tag:String, variable:String) {
			ModchartState.luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
				}
				return Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), variable);
			}
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
			ModchartState.luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
					return true;
				}
				Reflect.setProperty(PlayState.instance.modchartSprites.get(tag), variable, value);
				return true;
			}
			ModchartState.luaTrace("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			ModchartState.luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);

		});
		Lua_helper.add_callback(lua, "musicFadeOut", function(duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration, toValue);
			ModchartState.luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});

		Lua_helper.add_callback(lua, "getPropertyPsych", function(variable:String) {
			ModchartState.luaTrace('getPropertyPsych is deprecated. Use getProperty instead.');

			var killMe:Array<String> = variable.split('.');
			
			if (Stage.instance.swagBacks.exists(killMe[0])){
				return Stage.instance.getProperty(variable);
			}

			if(killMe.length > 1) {
				return LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
			}
			return LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable);
		});

		Lua_helper.add_callback(lua, "setPropertyPsych", function(variable:String, value:Dynamic) {
			ModchartState.luaTrace('setPropertyPsych is deprecated. Use setProperty instead.');

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

				if (Std.isOfType(LuaUtils.getObjectDirectly(killMe[0]), Character) && killMe[killMe.length-1] == 'color')
					LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(killMe), 'doMissThing', "false");
	
				LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1], value);
				return true;
			}
			LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, value);
			return true;
		});

		Lua_helper.add_callback(lua,"updateHealthbar", function(leftHex:String = "", rightHex:String = ""){
			var left:FlxColor = Std.parseInt("0x" + leftHex);
			var right:FlxColor = Std.parseInt("0x" + rightHex);
	
			var dad = PlayState.instance.dad;
			var boyfriend = PlayState.instance.boyfriend;
	
			if (leftHex == ""){
				left = Std.parseInt(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]).toHexString());
			}
	
			if (rightHex == ""){
				right = Std.parseInt(FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]).toHexString());
			}
	
			PlayState.instance.healthBar.createFilledBar(left, right);
			PlayState.instance.healthBar.updateBar();
		});

		Lua_helper.add_callback(lua, "fadeCamPsych", function(camera:String, color:String, duration:Float, fadeOut:Bool = false, forced:Bool) {
			if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration,fadeOut,null,forced);
		});

		Lua_helper.add_callback(lua, "flashCamPsych", function(camera:String, color:String, duration:Float, forced:Bool) {
			if (PlayState.instance != null){duration = duration / PlayState.instance.playbackRate;}
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration,null,forced);
		});

		Lua_helper.add_callback(lua,"setDefaultCamZoom", function(zoomAmount:Float) {
			ModchartState.luaTrace('setDefaultCamZoom is deprecated! Use setProperty("defaultCamZoom", "zoomAmount") instead.', false, true);
			PlayState.instance.defaultCamZoom = zoomAmount;
		});

		Lua_helper.add_callback(lua,"setHudZoom", function(zoomAmount:Float) {
			ModchartState.luaTrace('setHudZoom is deprecated! Use setProperty("camHUD.zoom", "zoomAmount") instead.', false, true);
			PlayState.instance.camHUD.zoom = zoomAmount;
		});
	}
}