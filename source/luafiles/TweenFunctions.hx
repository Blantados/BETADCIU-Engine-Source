package luafiles;

import objects.StrumNote;

class TweenFunctions
{
	public static function implement(funk:ModchartState)
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
		Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
		});

		Lua_helper.add_callback(lua, "cancelTween", function(tag:String) {
			LuaUtils.cancelTween(tag);
		});
		Lua_helper.add_callback(lua, "cancelTweensOf", function(obj:String) {
			var spr:Dynamic = LuaUtils.getObjectDirectly(obj);

			if(spr != null) {
				FlxTween.cancelTweensOf(spr);
			}
		});
		Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			if (game != null){duration = duration / game.playbackRate;}
			var spr:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(spr != null) {
				var curColor:FlxColor = spr.color;
				curColor.alphaFloat = spr.alpha;
				game.modchartTweens.set(tag, FlxTween.color(spr, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						game.modchartTweens.remove(tag);
						game.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			} else {
				ModchartState.luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		Lua_helper.add_callback(lua,"doTweenColor2", function(tag:String, vars:String, duration:Float, initColor:FlxColor, finalColor:FlxColor) {
			if (game != null){duration = duration / game.playbackRate;}
			var spr:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(spr != null) {
				game.modchartTweens.set(tag, FlxTween.color(spr, duration, initColor, finalColor, {
					onComplete: function(twn:FlxTween) {
						ModchartState.callOnCompleted("tween", tag);
					}
				}));
			} else {
				ModchartState.luaTrace('doTweenColor2: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		Lua_helper.add_callback(lua, "doTweenNum", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			if (game != null){duration = duration / game.playbackRate;}
			var spr:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(spr != null) {
				game.modchartTweens.set(tag, FlxTween.num(spr, value, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						ModchartState.callOnCompleted("tween", tag);
					}
				}));
			} else {
				ModchartState.luaTrace('doTweenZoom: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		Lua_helper.add_callback(lua, "objectColorTween", function(obj:String, duration:Float, color:String, color2:String, ?ease:String = 'linear') {
			var spr:Dynamic = LuaUtils.getObjectDirectly(obj);

			if(spr != null) {
				FlxTween.color(spr, duration, CoolUtil.colorFromString(color), CoolUtil.colorFromString(color2), {ease: LuaUtils.getTweenEaseByString()});
			}
		});

		//NOTES
		Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String, ?player:Bool = false) {
			if (game != null){duration = duration / game.playbackRate;}
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (player)
				testicle = game.playerStrums.members[note];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						ModchartState.callOnCompleted('tween', tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String, ?player:Bool = false) {
			if (game != null){duration = duration / game.playbackRate;}
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (player)
				testicle = game.playerStrums.members[note];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						ModchartState.callOnCompleted('tween', tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			if (game != null){duration = duration / game.playbackRate;}
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						ModchartState.callOnCompleted('tween', tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			if (game != null){duration = duration / game.playbackRate;}
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						ModchartState.callOnCompleted('tween', tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			if (game != null){duration = duration / game.playbackRate;}
			LuaUtils.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if(testicle != null) {
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						ModchartState.callOnCompleted('tween', tag);
					}
				}));
			}
		});

		
		//Old Stuff
		Lua_helper.add_callback(lua,"tweenAnglePsych", function(id:String, toAngle:Int, time:Float, ease:String, onComplete:String) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			FlxTween.tween(shit, {angle: toAngle}, time, {ease:  LuaUtils.getTweenEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenXPsych", function(id:String, toX:Int, time:Float, ease:String, onComplete:String) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			FlxTween.tween(shit, {x: toX}, time, {ease:  LuaUtils.getTweenEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenYPsych", function(id:String, toY:Int, time:Float, ease:String, onComplete:String) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			FlxTween.tween(shit, {y: toY}, time, {ease:  LuaUtils.getTweenEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenZoomPsych", function(id:String, toZoom:Int, time:Float, ease:String, onComplete:String) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			FlxTween.tween(shit, {zoom: toZoom}, time, {ease:  LuaUtils.getTweenEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenScale", function(id:String, scale:Float, time:Float, ease:String, onComplete:String) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);
			FlxTween.tween(shit, {"scale.x": scale, "scale.y": scale}, time, {ease:  LuaUtils.getTweenEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});			
		});

		Lua_helper.add_callback(lua,"tweenAlpha", function(id:String, toAlpha:Float, time:Float, ease:String, onComplete:String) {
			var shit:Dynamic = LuaUtils.getObjectDirectly(id);

			if (shit != null)
				FlxTween.tween(shit, {alpha: toAlpha}, time, {ease:  LuaUtils.getTweenEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenColor", function(vars:String, duration:Float, initColor:FlxColor, finalColor:FlxColor, ?tag:String) {
			if (game != null){duration = duration / game.playbackRate;}
			if (tag == null){tag = vars+'TweenCol';}
			
			var spr:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if(spr != null) {
				game.modchartTweens.set(tag, FlxTween.color(spr, duration, initColor, finalColor, {
					onComplete: function(twn:FlxTween) {
						ModchartState.callOnCompleted("tween", tag);
					}
				}));
			} else {
				ModchartState.luaTrace('tweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

				
		Lua_helper.add_callback(lua,"tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});
						
		Lua_helper.add_callback(lua,"tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String) {
			FlxTween.tween(FlxG.camera, {zoom:toZoom}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(game.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});
						
		Lua_helper.add_callback(lua,"tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(game.camHUD, {angle:toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String) {
			FlxTween.tween(game.camHUD, {zoom:toZoom}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPos", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPosQuad", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.quadInOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.linear, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenCameraPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});
						
		Lua_helper.add_callback(lua,"tweenCameraAngleOut", function(toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenCameraZoomOut", function(toZoom:Float, time:Float, ease:String, onComplete:String) {
			FlxTween.tween(FlxG.camera, {zoom:toZoom}, time, {ease: LuaUtils.getTweenEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenHudPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(game.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});
						
		Lua_helper.add_callback(lua,"tweenHudAngleOut", function(toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(game.camHUD, {angle:toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenHudZoomOut", function(toZoom:Float, time:Float, onComplete:String) {
			FlxTween.tween(game.camHUD, {zoom:toZoom}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPosOut", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPosXAngleOut", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPosYAngleOut", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenAngleOut", function(id:String, toAngle:Int, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.cubeOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenCameraPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});
						
		Lua_helper.add_callback(lua,"tweenCameraAngleIn", function(toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(FlxG.camera, {angle:toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenCameraZoomIn", function(toZoom:Float, time:Float, ease:String, onComplete:String) {
			FlxTween.tween(FlxG.camera, {zoom:toZoom}, time, {ease: LuaUtils.getTweenEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenHudPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(game.camHUD, {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});
						
		Lua_helper.add_callback(lua,"tweenHudAngleIn", function(toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(game.camHUD, {angle:toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenHudZoomIn", function(toZoom:Float, time:Float, onComplete:String) {
			FlxTween.tween(game.camHUD, {zoom:toZoom}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,["camera"]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPosIn", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {x: toX, y: toY}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPosXAngleIn", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {x: toX, angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenPosYAngleIn", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {y: toY, angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenAngleIn", function(id:String, toAngle:Int, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {angle: toAngle}, time, {ease: FlxEase.cubeIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenFadeIn", function(id:String, toAlpha:Float, time:Float, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {alpha: toAlpha}, time, {ease: FlxEase.circIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenFadeInBG", function(id:String, toAlpha:Float, time:Float, onComplete:String) {
			FlxTween.tween(game.Stage.swagBacks[id], {alpha: toAlpha}, time, {ease: FlxEase.circIn, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenFadeOut", function(id:String, toAlpha:Float, time:Float, ease:String, onComplete:String) {
			FlxTween.tween(LuaUtils.getActorByName(id), {alpha: toAlpha}, time, {ease: LuaUtils.getTweenEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenFadeOutBG", function(id:String, toAlpha:Float, time:Float, onComplete:String) {
			FlxTween.tween(game.Stage.swagBacks[id], {alpha: toAlpha}, time, {ease: FlxEase.circOut, onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {tweenCall(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenFadeOutOneShot", function(id:String, toAlpha:Float, time:Float) {
			FlxTween.tween(LuaUtils.getActorByName(id), {alpha: toAlpha}, time, {type: FlxTweenType.ONESHOT});
		});
	}

	public static function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
	{
		#if LUA_ALLOWED
		var game = PlayState.instance;

		if (game != null){duration = duration / game.playbackRate;}
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		if(target != null) {
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween) {
					PlayState.instance.modchartTweens.remove(tag);
					PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
				}
			}));
		} else {
			ModchartState.luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		}
		#end
	}

	//i can't change the one in ModchartState to static
	public static function tweenCall(func:String, args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		return ModchartState.lastCalledScript.call(func, args);
		#end
	}
}


