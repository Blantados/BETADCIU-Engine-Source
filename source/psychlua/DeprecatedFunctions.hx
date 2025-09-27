package psychlua;

import objects.Character;
import objects.HealthIcon;
import flixel.FlxObject;
//
// This is simply where i store deprecated functions for it to be more organized.
// I would suggest not messing with these, as it could break mods.
//

class DeprecatedFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		Lua_helper.add_callback(lua, "addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			FunkinLua.luaTrace("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead", false, true);
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		Lua_helper.add_callback(lua, "objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			FunkinLua.luaTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance.getLuaObject(obj) != null) {
				PlayState.instance.getLuaObject(obj).animation.play(name, forced, false, startFrame);
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
			FunkinLua.luaTrace("characterPlayAnim is deprecated! Use playAnim instead", false, true);
			switch(character.toLowerCase()) {
				case 'dad':
					if(PlayState.instance.dad.hasAnimation(anim))
						PlayState.instance.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if(PlayState.instance.gf != null && PlayState.instance.gf.hasAnimation(anim))
						PlayState.instance.gf.playAnim(anim, forced);
				default:
					if(PlayState.instance.modchartCharacters.exists(character)) {
						var spr:Character = PlayState.instance.modchartCharacters.get(character);

						if(spr.hasAnimation(anim))
							spr.playAnim(anim, forced);
						return;
					}
					if(PlayState.instance.boyfriend.hasAnimation(anim))
						PlayState.instance.boyfriend.playAnim(anim, forced);
			}
		});
		Lua_helper.add_callback(lua,"playActorAnimation", function(obj:String,anim:String,force:Bool = false,reverse:Bool = false, ?frame:Int = 0) { // some kade/betadciu engine scripts uses this
			var char:Character = LuaUtils.getObjectDirectly(obj);

			if (char != null && Std.isOfType(char, Character)){ //what am I doing? of course it'll be a character
				char.playAnim(anim, force, reverse, frame);
				return;
			} 
			FunkinLua.luaTrace('playActorAnimation: Couldnt find object: ' + obj, false, false, FlxColor.RED);
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
		Lua_helper.add_callback(lua, "luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			FunkinLua.luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if(MusicBeatState.getVariables().exists(tag))
				MusicBeatState.getVariables().get(tag).makeGraphic(width, height, CoolUtil.colorFromString(color));
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			FunkinLua.luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				var cock:ModchartSprite = MusicBeatState.getVariables().get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "changeAddedIcon", function(tag:String, character:String){
			var shit:HealthIcon = PlayState.instance.variables.get(tag);
			shit.changeIcon(character);
		});
		Lua_helper.add_callback(lua, "makeLuaIcon", function(tag:String, character:String, player:Bool = false) {
			FunkinLua.makeIcon(tag, character, player);
		});
		Lua_helper.add_callback(lua, "changeLuaIcon", function(tag:String, character:String){
			var shit:HealthIcon = PlayState.instance.variables.get(tag);
			shit.changeIcon(character);
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			FunkinLua.luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = MusicBeatState.getVariables().get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if(pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "updateHealthbar", function(?left:String = "", ?right:String = "") { // directly from betadciu engine -- future me here: old code didn't worked so i just pasted the new one
			if (left.length == 8) left = left.substring(left.length-2);
			else if (left.length == 10) left = left.substring(left.length-4);

			if (right.length == 8) right = right.substring(right.length-2);
			else if (right.length == 10) right = right.substring(right.length-4);

			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			PlayState.instance.healthBar.setColors(left_color, right_color);
		});
		Lua_helper.add_callback(lua, "luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
			FunkinLua.luaTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).animation.play(name, forced);
			}
		});
		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(tag:String, camera:String = '') {
			FunkinLua.luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			FunkinLua.luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			FunkinLua.luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			FunkinLua.luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				var shit:ModchartSprite = MusicBeatState.getVariables().get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getPropertyLuaSprite", function(tag:String, variable:String) {
			FunkinLua.luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(MusicBeatState.getVariables().get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
				}
				return Reflect.getProperty(MusicBeatState.getVariables().get(tag), variable);
			}
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
			FunkinLua.luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(MusicBeatState.getVariables().get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
					return true;
				}
				Reflect.setProperty(MusicBeatState.getVariables().get(tag), variable, value);
				return true;
			}
			FunkinLua.luaTrace("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			FunkinLua.luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);

		});
		Lua_helper.add_callback(lua, "musicFadeOut", function(duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration, toValue);
			FunkinLua.luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});
		Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
			FunkinLua.luaTrace('updateHitboxFromGroup is deprecated! Use updateHitbox instead.', false, true);
		});
		Lua_helper.add_callback(lua,"changeBFAuto", function(?id:String="bf", ?flipped:Bool=false) {
			FunkinLua.changeBFAuto(id, flipped);
			FunkinLua.luaTrace('changeBFAuto is deprecated! Use changeCharacter instead.', false, true);
		});
		Lua_helper.add_callback(lua,"changeBoyfriendAuto", function(?id:String="bf", ?flipped:Bool=false) {
			FunkinLua.changeBFAuto(id, flipped);
			FunkinLua.luaTrace('changeBoyfriendAuto is deprecated! Use changeCharacter instead.', false, true);
		});
		Lua_helper.add_callback(lua,"changeDadAuto", function(?id:String="bf", ?flipped:Bool=false) {
			FunkinLua.changeDadAuto(id, flipped);
			FunkinLua.luaTrace('changeDadAuto is deprecated! Use changeCharacter instead.', false, true);
		});
		Lua_helper.add_callback(lua,"changeGFAuto", function(?id:String="bf", ?flipped:Bool=false) {
			FunkinLua.changeGFAuto(id, flipped);
			FunkinLua.luaTrace('changeGFAuto is deprecated! Use changeCharacter instead.', false, true);
		});		
		Lua_helper.add_callback(lua, "changeLuaCharacter", function(tag:String, character:String){
			var shit:Character = PlayState.instance.modchartCharacters.get(tag);
			if(shit != null) FunkinLua.makeLuaCharacter(tag, character, shit.isPlayer, shit.flipMode);
			else FunkinLua.luaTrace("changeLuaCharacter: " + tag + " doesn't exist!", false, false, FlxColor.RED);
			FunkinLua.luaTrace('changeLuaCharacter is deprecated! Use changeCharacter instead.', false, true);
		});
		Lua_helper.add_callback(lua,"setCamFollow", function(?x:Float, ?y:Float) {
			var trueX = x;
			var trueY = y;
			PlayState.instance.isCameraOnForcedPos = false;
			if(trueX != null || trueX != null)
			{
				PlayState.instance.isCameraOnForcedPos = true;
				PlayState.instance.camFollow.x = trueX;
				PlayState.instance.camFollow.y = trueY;
				FunkinLua.luaTrace('setCamFollow is deprecated! Use setCameraFollowPoint instead.', false, true);
				return;
			}
			FunkinLua.luaTrace('setCamFollow: Camera Follow Cannot be set to null.', false, true, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "getActorXMidpoint", function(variable:String, ?graphic:Bool = false) { // im not porting the other kade reflect stuff. im just porting this because some scripts still uses this... yeah, even with the getMidPointX available
			var shit:Dynamic = LuaUtils.getObjectDirectly(variable);

			if (graphic)
				return shit.getGraphicMidpoint().x;

			return shit.getMidpoint().x;
		});
		Lua_helper.add_callback(lua, "getActorYMidpoint", function(variable:String, ?graphic:Bool = false) { // im not porting the other kade reflect stuff. im just porting this because some scripts still uses this... yeah, even with the getMidPointY available
			var shit:Dynamic = LuaUtils.getObjectDirectly(variable);

			if (graphic)
				return shit.getGraphicMidpoint().y;

			return shit.getMidpoint().y;
		});
	}
}