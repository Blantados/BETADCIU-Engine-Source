package psychlua;

import psychlua.LuaUtils.LuaTweenOptions;
import objects.*;

// and it's now back

class TweenFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		var game:PlayState = PlayState.instance;

		Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});
		Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});
		Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});
		Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});
		Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, camera:String, value:Dynamic, duration:Float, ease:String) {
			switch(camera.toLowerCase()) {
				case 'camgame' | 'game': camera = 'camGame';
				case 'camhud' | 'hud': camera = 'camHUD';
				case 'camother' | 'other': camera = 'camOther';
				default:
					var cam:FlxCamera = MusicBeatState.getVariables().get(camera);
					if (cam == null || !Std.isOfType(cam, FlxCamera)) camera = 'camGame';
			}
			return oldTweenFunction(tag, camera, {zoom: value}, duration, ease, 'doTweenZoom');
		});

		Lua_helper.add_callback(lua, "startTween", function(tag:String, vars:String, values:Any = null, duration:Float, ?options:Any = null) {
			if (game != null){duration = duration / game.playbackRate;}
			
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null)
			{
				if(values != null)
				{
					var myOptions:LuaTweenOptions = LuaUtils.getLuaTween(options);
					if(tag != null)
					{
						var variables = MusicBeatState.getVariables();
						var originalTag:String = 'tween_' + LuaUtils.formatVariable(tag);
						variables.set(tag, FlxTween.tween(penisExam, values, duration, myOptions != null ? {
							type: myOptions.type,
							ease: myOptions.ease,
							startDelay: myOptions.startDelay,
							loopDelay: myOptions.loopDelay,
	
							onUpdate: function(twn:FlxTween) {
								if(myOptions.onUpdate != null) game.callOnLuas(myOptions.onUpdate, [originalTag, vars]);
							},
							onStart: function(twn:FlxTween) {
								if(myOptions.onStart != null) game.callOnLuas(myOptions.onStart, [originalTag, vars]);
							},
							onComplete: function(twn:FlxTween) {
								if(twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD) variables.remove(tag);
								if(myOptions.onComplete != null) game.callOnLuas(myOptions.onComplete, [originalTag, vars]);
							}
						} : null));
						return tag;
					}
					else FlxTween.tween(penisExam, values, duration, myOptions != null ? {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: function(twn:FlxTween) {
							if(myOptions.onUpdate != null) game.callOnLuas(myOptions.onUpdate, [null, vars]);
						},
						onStart: function(twn:FlxTween) {
							if(myOptions.onStart != null) game.callOnLuas(myOptions.onStart, [null, vars]);
						},
						onComplete: function(twn:FlxTween) {
							if(myOptions.onComplete != null) game.callOnLuas(myOptions.onComplete, [null, vars]);
						}
					} : null);
				}
				else FunkinLua.luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
			}
			else FunkinLua.luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			return null;
		});

		Lua_helper.add_callback(lua, "cancelTween", function(tag:String) {
			LuaUtils.cancelTween(tag);
		});

		Lua_helper.add_callback(lua, "cancelTweensOf", function(variable:String, ?allowMaps:Bool = false) {
			var split:Array<String> = variable.split('.');
			var result:Dynamic = null;
			
			result = (split.length > 1)
				? LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split, true, allowMaps), split[split.length-1], allowMaps)
				: LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable, allowMaps);

			if(result != null) {
				FlxTween.cancelTweensOf(result);
			}
		});

		Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ?ease:String = 'linear') {
			if (game != null){duration = duration / game.playbackRate;}
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				
				if(tag != null)
				{
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween)
						{
							variables.remove(tag);
							if (game != null) game.callOnLuas('onTweenCompleted', [originalTag, vars]);
						}
					}));
					return tag;
				}
				else FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease)});
			}
			else FunkinLua.luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			return null;
		});


		Lua_helper.add_callback(lua,"doTweenColor2", function(tag:String, vars:String, duration:Float, initColor:FlxColor, finalColor:FlxColor) {
			if (game != null){duration = duration / game.playbackRate;}
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(tag != null)
				{
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.color(penisExam, duration, initColor, finalColor, {ease: LuaUtils.getTweenEaseByString("cubeout"),
						onComplete: function(twn:FlxTween)
						{
							variables.remove(tag);
							if (game != null) game.callOnLuas('onTweenCompleted', [originalTag, vars]);
						}
					}));
					return tag;
				}
				else FlxTween.color(penisExam, duration, initColor, finalColor, {ease: LuaUtils.getTweenEaseByString("cubeout")});
			} else {
				FunkinLua.luaTrace('doTweenColor2: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
			return null;
		});

		Lua_helper.add_callback(lua, "doTweenNum", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			if (game != null){duration = duration / game.playbackRate;}
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(tag != null)
				{
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.num(penisExam, value, duration, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween)
						{
							variables.remove(tag);
							if (game != null) game.callOnLuas('onTweenCompleted', [originalTag, vars]);
						}
					}));
					return tag;
				}
				else FlxTween.num(penisExam, value, duration, {ease: LuaUtils.getTweenEaseByString("cubeout")});
			} else {
				FunkinLua.luaTrace('doTweenZoom: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
			return null;
		});

		Lua_helper.add_callback(lua, "objectColorTween", function(obj:String, duration:Float, color:String, color2:String, ?ease:String = 'linear') {
			var spr:Dynamic = LuaUtils.getObjectDirectly(obj);

			if(spr != null) {
				FlxTween.color(spr, duration, CoolUtil.colorFromString(color), CoolUtil.colorFromString(color2), {ease: LuaUtils.getTweenEaseByString()});
			}
		});

		//Tween shit, but for strums
		Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(tag, note, {x: value}, duration, ease);
		});
		Lua_helper.add_callback(lua, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(tag, note, {y: value}, duration, ease);
		});
		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(tag, note, {angle: value}, duration, ease);
		});
		Lua_helper.add_callback(lua, "noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(tag, note, {alpha: value}, duration, ease);
		});
		Lua_helper.add_callback(lua, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(tag, note, {direction: value}, duration, ease);
		});

		
		// Tween color... the last one
		Lua_helper.add_callback(lua,"tweenColor", function(vars:String, duration:Float, initColor:FlxColor, finalColor:FlxColor, ?tag:String) {
			if (game != null){duration = duration / game.playbackRate;}
			if (tag == null){tag = vars+'TweenCol';}
			
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(tag != null)
				{
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.color(penisExam, duration, initColor, finalColor, {ease: LuaUtils.getTweenEaseByString("cubeout"),
						onComplete: function(twn:FlxTween)
						{
							variables.remove(tag);
							if (game != null) game.callOnLuas('onTweenCompleted', [originalTag, vars]);
						}
					}));
					return tag;
				}else FlxTween.color(penisExam, duration, initColor, finalColor, {ease: LuaUtils.getTweenEaseByString("cubeout")});
			} else {
				FunkinLua.luaTrace('tweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
			return null;
		});
	}

	public static function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
	{
		var game = PlayState.instance;

		if (game == null){
			return null;	
		}else{
			duration = duration / game.playbackRate;
		}
		
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		var variables = MusicBeatState.getVariables();
		if(target != null)
		{
			if(tag != null)
			{
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('tween_$tag');
				variables.set(tag, FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						variables.remove(tag);
						if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, vars]);
					}
				}));
			}
			else FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
			return tag;
		}
		else FunkinLua.luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		return null;
	}

	public static function noteTweenFunction(tag:String, note:Int, data:Dynamic, duration:Float, ease:String)
	{
		var game = PlayState.instance;

		if (game == null){
			return null;	
		}else{
			duration = duration / game.playbackRate;
		}

		var strumNote:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];
		if(strumNote == null) return null;

		if(tag != null)
		{
			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('tween_$tag');
			LuaUtils.cancelTween(tag);

			var variables = MusicBeatState.getVariables();
			variables.set(tag, FlxTween.tween(strumNote, data, duration, {ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					variables.remove(tag);
					if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag]);
				}
			}));
			return tag;
		}
		else FlxTween.tween(strumNote, data, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		return null;
	}
	

	//i can't change the one in FunkinLua to static
	public static function tweenCall(func:String, args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		return FunkinLua.lastCalledScript.call(func, args);
		#end
	}
}


