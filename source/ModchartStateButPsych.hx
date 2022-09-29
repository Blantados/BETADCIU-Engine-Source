// i thought doing this would fix the bug of running a command on one messing with the other but I guess not.

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

import openfl.display3D.textures.VideoTexture;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.app.Application;

import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.addons.transition.FlxTransitionableState;
import openfl.filters.ShaderFilter;
import flixel.effects.FlxFlicker;
import Shaders;
import flash.media.Sound;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
import Type.ValueType;
import Controls;

#if desktop
import Discord;
#end

//why is detected's modchart confusing!?
import LuaClass.LuaGame;
import LuaClass.LuaWindow;
import LuaClass.LuaSprite;
import LuaClass.LuaCamera;
import LuaClass.LuaNote;
import LuaClass.LuaReceptor;

using StringTools;

class ModchartState {
	public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;

	public static var shownNotes:Array<LuaNote> = [];

	#if LUA_ALLOWED
	public var lua:State = null;
	#end
	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	var gonnaClose:Bool = false;

	public var accessedProps:Map<String, Dynamic> = null;
	public function new(script:String) {
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		//trace('Lua version: ' + Lua.version());
		//trace("LuaJIT version: " + Lua.versionJIT());

		LuaL.dostring(lua, CLENSE);
		var result:Dynamic = LuaL.dofile(lua, script);
		var resultStr:String = Lua.tostring(lua, result);
		if(resultStr != null && result != 0) {
			trace('Error on lua script! ' + resultStr);
			#if windows
			lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
			#else
			luaTrace('Error loading lua script: "$script"\n' + resultStr,true,false);
			#end
			lua = null;
			return;
		}
		scriptName = script;
		trace('lua file loaded succesfully:' + script);

		#if (haxe >= "4.0.0")
		accessedProps = new Map();
		#else
		accessedProps = new Map<String, Dynamic>();
		#end

		// Lua shit
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set("crochetReal", Conductor.crochet); //yeah i don't know either
		set("crochet", Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('startedCountdown', false);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);
		set('difficultyName', CoolUtil.difficulties[PlayState.storyDifficulty]);
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);

		set("safeZoneOffset", Conductor.safeZoneOffset);

		set("cameraZoom", FlxG.camera.zoom);

		set("cameraAngle", FlxG.camera.angle);
		
		// Block require and os, Should probably have a proper function but this should be good enough for now until someone smarter comes along and recreates a safe version of the OS library
		set('require', false);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);
		
		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curBeat', 0);
		set('curStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		
		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		for (i in 0...4) {
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		// Some settings, no jokes
		set("scrollspeed", FlxG.save.data.scrollSpeed != 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed);
		set("fpsCap", FlxG.save.data.fpsCap);
		set("downscroll", FlxG.save.data.downscroll);
		set("flashing", FlxG.save.data.flashing);
		set("distractions", FlxG.save.data.distractions);

		set("followBFXOffset",0);
		set("followBFYOffset",0);
		set("followDadXOffset",0);
		set("followDadYOffset",0);

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

		set("newIcons", false);
		set("swapIcons", true);
		set("playDadSing", true);
		set("playBFSing", true);

		#if windows
		set('buildTarget', 'windows');
		#elseif linux
		set('buildTarget', 'linux');
		#elseif mac
		set('buildTarget', 'mac');
		#elseif html5
		set('buildTarget', 'browser');
		#elseif android
		set('buildTarget', 'android');
		#else
		set('buildTarget', 'unknown');
		#end

		Lua_helper.add_callback(lua,"doFunction", doFunction);
		
		Lua_helper.add_callback(lua,"changeDadCharacter", changeDadCharacter);

		Lua_helper.add_callback(lua,"changeBoyfriendCharacter", changeBoyfriendCharacter);

		Lua_helper.add_callback(lua,"changeGFCharacter", changeGFCharacter);

		Lua_helper.add_callback(lua,"changeStage", changeStage);

		Lua_helper.add_callback(lua,"changeDadCharacterBetter", changeDadCharacterBetter);

		Lua_helper.add_callback(lua,"changeBoyfriendCharacterBetter", changeBoyfriendCharacterBetter);

		Lua_helper.add_callback(lua,"changeGFCharacterBetter", changeGFCharacterBetter);

		Lua_helper.add_callback(lua,"changeDad1Character", changeDad1Character);

		Lua_helper.add_callback(lua,"changeBoyfriend1Character", changeBoyfriend1Character);

		Lua_helper.add_callback(lua,"changeDad2Character", changeDad2Character);

		Lua_helper.add_callback(lua,"changeBoyfriend2Character", changeBoyfriend2Character);

		//the auto stuff
		Lua_helper.add_callback(lua,"changeBFAuto", changeBFAuto);

		//cuz sometimes i type boyfriend instead of bf
		Lua_helper.add_callback(lua,"changeBoyfriendAuto", changeBFAuto);

		Lua_helper.add_callback(lua,"changeDadAuto", changeDadAuto);

		Lua_helper.add_callback(lua,"changeGFAuto", changeGFAuto);


		Lua_helper.add_callback(lua,"fileExists", function(key:String) {
			if(FileSystem.exists(FileSystem.absolutePath(key))) {
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "toggleCamFilter", function(bool:Bool, camera:String = '') {
			cameraFromString(camera).filtersEnabled = bool;
		});

		Lua_helper.add_callback(lua, "addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf. 
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
							luaTrace('The script "' + cervix + '" is already running!');
							return;
						}
					}
				}
				PlayState.instance.luaArray.push(new ModchartState(cervix)); 
				return;
			}
			luaTrace("Script doesn't exist!");
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
				}
				return;
			}
			luaTrace("Script doesn't exist!");
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
						{
								PlayState.instance.luaArray.remove(luaInstance); 
								luaInstance.die();
							return;
						}
					}
				}
				return;
			}
			luaTrace("Script doesn't exist!");
		});


		Lua_helper.add_callback(lua,"animationSwap", function(char:String, anim1:String, anim2:String) {
			var shit = getThing(char);

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
				var shit:Dynamic = getThing(id);
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

		Lua_helper.add_callback(lua,"setScrollFactor", function(id:String , x:Float, y:Float, ?bg:Bool = false) {
			var shit:Dynamic = getThing(id);
			
			shit.scrollFactor.set(x, y);
		});

		Lua_helper.add_callback(lua,"getScrollFactor", function(id:String , x:String) {
			var shit:Dynamic = getThing(id);
			if (x == 'x')
				return shit.scrollFactor.x;
			else
				return shit.scrollFactor.y;
		});

		Lua_helper.add_callback(lua,"changeAnimOffset", function(id:String , x:Float, y:Float) {
			getActorByName(id).addOffset(x, y); // it may say addoffset but it actually changes it instead of adding to the existing offset so this works.
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
			var shit:Dynamic = getThing(sprite);

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
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
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

		Lua_helper.add_callback(lua, "close", function(printMessage:Bool) {
			//this always closes the first one for some reason!?
			if(!gonnaClose) {
				if(printMessage) {
					luaTrace('Stopping lua script: ' + scriptName);
				}
				PlayState.instance.closeLuas.push(this);
			}
			gonnaClose = true;
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

		Lua_helper.add_callback(lua,"resetTrail", function(id:String) {
			getActorByName(id).resetTrail();
		});

		Lua_helper.add_callback(lua,"generateNumberFromRange", function(min:Float, max:Float) {
			return FlxG.random.float(min, max);
		});

		Lua_helper.add_callback(lua,"zoomingFunctionThing", function(?camSpeed:Float = 0.55, ?camZoomMult:Float = 1) {
			PlayState.instance.Stage.zoomingFunctionThing(camSpeed, camZoomMult); //only works on concert stage. don't use anywhere else
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
			var shit:Dynamic = getThing(id);
			PlayState.instance.removeObject(shit);
		});

		Lua_helper.add_callback(lua,"addObject", function(id:String) {
			var shit:Dynamic = getThing(id);
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
		
		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float,forced:Bool) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			cameraFromString(camera).flash(colorNum, duration,null,forced);
		});
		Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float,forced:Bool) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			cameraFromString(camera).fade(colorNum, duration,false,null,forced);
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
				var coverMeInPiss:Dynamic = null;

				coverMeInPiss = Reflect.getProperty(getInstance(), killMe[0]);
				
				for (i in 1...killMe.length-1) {
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}

				shit = Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
			}
	
			var daArray:Array<String> = [];

			for (key in shit.keys())
				daArray.push(key);
			
			return daArray.length;
		});

		Lua_helper.add_callback(lua,"getMapKeys", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var shit:Map<String, Dynamic> = Reflect.getProperty(getInstance(), obj);

			if(killMe.length > 1) 
			{
				var coverMeInPiss:Dynamic = null;

				coverMeInPiss = Reflect.getProperty(getInstance(), killMe[0]);
				
				for (i in 1...killMe.length-1) {
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}

				shit = Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
			}

			var daArray:Array<String> = [];

			for (key in shit.keys())
				daArray.push(key);
			
			return daArray;
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
			var shit:Dynamic = getThing(id);
			shit.x = x;
		});
		
		Lua_helper.add_callback(lua,"setActorScreenCenter", function(id:String, ?thing:String) {
			var shit:Dynamic = getThing(id);
			shit.screenCenter();				
		});

		Lua_helper.add_callback(lua,"screenCenter", function(id:String, ?thing:String) { //same thing. just for psych
			var shit:Dynamic = getThing(id);
			shit.screenCenter();				
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
		
		Lua_helper.add_callback(lua,"playActorAnimation", function(id:String,anim:String,force:Bool = false,reverse:Bool = false, ?frame:Int = 0) {
			if (PlayState.instance.modchartCharacters.exists(id))
			{
				var shit:Character = PlayState.instance.modchartCharacters.get(id);
				shit.playAnim(anim, force, reverse, frame);
			}
			else	
				getActorByName(id).playAnim(anim, force, reverse, frame);
		});

		Lua_helper.add_callback(lua,"enablePurpleMiss", function(id:String,toggle:Bool) {
			getActorByName(id).doMissThing = toggle;
		});

		Lua_helper.add_callback(lua,"playBGAnimation", function(id:String,anim:String,force:Bool = false,reverse:Bool = false) {
			var shit:Dynamic = getThing(id);
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

		Lua_helper.add_callback(lua,"flickerActor", function (id:FlxObject, duration:Float, interval:Float) {
			FlxFlicker.flicker(id, duration, interval);
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
			var shit:Dynamic = getThing(id);
			shit.setGraphicSize(Std.int(shit.width * scale));
			shit.updateHitbox();	
		});
		
		Lua_helper.add_callback(lua, "setActorScaleXY", function(scaleX:Float, scaleY:Float, id:String)
		{
			getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scaleX), Std.int(getActorByName(id).height * scaleY));
		});

		Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, y:Int = 0) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				shit.setGraphicSize(x, y);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(poop != null) {
				poop.setGraphicSize(x, y);
				poop.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: ' + obj);
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
			var shit:Dynamic = getThing(id);

			if (graphic)
				return shit.getGraphicMidpoint().x;

			return shit.getMidpoint().x;
		});

		Lua_helper.add_callback(lua,"getActorYMidpoint", function (id:String, ?graphic:Bool = false) {
			var shit:Dynamic = getThing(id);

			if (graphic)
				return shit.getGraphicMidpoint().y;

			return shit.getMidpoint().y;
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

		Lua_helper.add_callback(lua,"tweenColor", function(id:String, time:Float, initColor:FlxColor, finalColor:FlxColor) {
			var shit:Dynamic = getThing(id);
			FlxTween.color(shit, time, initColor, finalColor);
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

		Lua_helper.add_callback(lua,"changeHue", function(id:String, hue:Int) {
			var newShader:ColorSwap = new ColorSwap();
			var shit:Dynamic = getThing(id);
			shit.shader = newShader.shader;
			newShader.hue = hue / 360;
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
			var shit:Dynamic = getThing(id);
			FlxTween.tween(shit, {angle: toAngle}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenXPsych", function(id:String, toX:Int, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
			var shit:Dynamic = getThing(id);
			FlxTween.tween(shit, {x: toX}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenYPsych", function(id:String, toY:Int, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
			var shit:Dynamic = getThing(id);
			FlxTween.tween(shit, {y: toY}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenZoomPsych", function(id:String, toZoom:Int, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
			var shit:Dynamic = getThing(id);
			FlxTween.tween(shit, {zoom: toZoom}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenScale", function(id:String, scale:Float, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
			var shit:Dynamic = getThing(id);
			FlxTween.tween(shit, {"scale.x": scale, "scale.y": scale}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});			
		});

		Lua_helper.add_callback(lua,"tweenScaleXY", function(id:String, scaleX:Float, scaleY:Float, time:Float, ease:String, onComplete:String, ?bg:Bool = false) {
			var shit:Dynamic = getThing(id);
			FlxTween.tween(shit, {"scale.x": scaleX, "scale.y": scaleY}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua,"tweenAlpha", function(id:String, toAlpha:Float, time:Float, ease:String, onComplete:String) {
			var shit:Dynamic = getThing(id);
			FlxTween.tween(shit, {alpha: toAlpha}, time, {ease: getFlxEaseByString(ease), onComplete: function(flxTween:FlxTween) { if (onComplete != '' && onComplete != null) {call(onComplete,[id]);}}});
		});

		Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = getThing(vars);
			cancelTween(tag);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: ' + vars);
			}
		});
		
		Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = getThing(vars);
			cancelTween(tag);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: ' + vars);
			}
		});
		Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = getThing(vars);
			cancelTween(tag);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {angle: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: ' + vars);
			}
		});

		Lua_helper.add_callback(lua, "doTweenScale", function(tag:String, vars:String, value:Dynamic, value2:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = getThing(vars);
			cancelTween(tag);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {"scale.x": value, "scale.y": value2}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: ' + vars);
			}
		});

		Lua_helper.add_callback(lua, "doTweenScaleX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = getThing(vars);
			cancelTween(tag);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {"scale.x": value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: ' + vars);
			}
		});

		Lua_helper.add_callback(lua, "doTweenScaleY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = getThing(vars);
			cancelTween(tag);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {"scale.y": value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: ' + vars);
			}
		});


		Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = getThing(vars);
			cancelTween(tag);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: ' + vars);
			}
		});
		Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = getThing(vars);
			cancelTween(tag);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {zoom: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: ' + vars);
			}
		});
		Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var penisExam:Dynamic = getThing(vars);
			cancelTween(tag);
			if(penisExam != null) {
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
				luaTrace('Couldnt find object: ' + vars);
			}
		});

		Lua_helper.add_callback(lua, "startCountdown", function(variable:String) {
			PlayState.instance.startCountdown();
		});

		Lua_helper.add_callback(lua, "startSong", function(variable:String) {
			PlayState.instance.startSong();
		});

		Lua_helper.add_callback(lua, "playCutscene", function(video:String) {
			PlayState.instance.playCutscene(video);
		});

		Lua_helper.add_callback(lua, "endSong", function(hmm:String) {
			PlayState.instance.KillNotes();
			PlayState.instance.endSong();
		});

		//idk if I wanna add events. alright I added the ones that are usable without that much tinkering.
		Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic) {
			if (name == 'Change Character')
			{
				switch (arg1)
				{
					case 0: changeBFAuto(arg2);
					case 1: changeDadAuto(arg2);
					case 2: changeGFAuto(arg2);
				}
				
				return;
			}

			var value1:String = arg1;
			var value2:String = arg2;
			PlayState.instance.triggerEventNote(name, value1, value2);
		});

		Lua_helper.add_callback(lua, "getPropertyPsych", function(variable:String) {
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

		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic) {
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
			if (PlayState.instance.Stage.swagGroup.exists(obj))
			{
				var shit = PlayState.instance.Stage.swagGroup.get(obj);
				
				if(Std.isOfType(shit, FlxTypedGroup)) {
					return getGroupStuff(shit.members[index], variable);
				}
			}
		
			if(Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup)) {
				return getGroupStuff(Reflect.getProperty(getInstance(), obj).members[index], variable);
			}

			var leArray:Dynamic = Reflect.getProperty(getInstance(), obj);
			var killMe:Array<String> = obj.split('.');

			if (killMe.length > 1) //all this just so I can get a character's camera position
			{
				var coverMeInPiss:Dynamic = null;
				coverMeInPiss = Reflect.getProperty(getInstance(), killMe[0]);

				for (i in 1...killMe.length-1) {
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}

				leArray = Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
			}

			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					return leArray[variable];
				}

				leArray = Reflect.getProperty(getInstance(), obj)[index];
				return getGroupStuff(leArray, variable);
			}
			luaTrace("Object #" + index + " from group: " + obj + " doesn't exist!");
			return null;
		});

		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {

			if (PlayState.instance.Stage.swagGroup.exists(obj))
			{
				trace('swagGroup found');
				var shit = PlayState.instance.Stage.swagGroup.get(obj);
				
				if(Std.isOfType(shit, FlxTypedGroup)) {
					trace('is a FlxTypedGroup');
					return setGroupStuff(shit.members[index], variable, value);
				}
			}

			if(Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup)) {
				setGroupStuff(Reflect.getProperty(getInstance(), obj).members[index], variable, value);
				return;
			}

			var leArray:Dynamic = Reflect.getProperty(getInstance(), obj)[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
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
			if (PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).cameras = [cameraFromString(camera)];
				return true;
			}
			else if(PlayState.instance.modchartTexts.exists(obj)) {
				PlayState.instance.modchartTexts.get(obj).cameras = [cameraFromString(camera)];
				return true;
			}
			else if (PlayState.instance.modchartIcons.exists(obj)) {
					PlayState.instance.modchartIcons.get(obj).cameras = [cameraFromString(camera)];
				return true;
			}
			else if (PlayState.instance.Stage.swagBacks.exists(obj)) {
				PlayState.instance.Stage.setObjectCamera(obj, camera);
				return true;
			}
			else if (Stage.instance.swagBacks.exists(obj)) {
				Stage.instance.setObjectCamera(obj, camera);
				return true;
			}
			else
			{
				var object:Dynamic = Reflect.getProperty(getInstance(), obj);
				if(object != null) {

					if (index != null)
						object[index].cameras = [cameraFromString(camera)];
					else
						object.cameras = [cameraFromString(camera)];

					return true;
				}
			}
			luaTrace("Object " + obj + " doesn't exist!");
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
			var shit:Dynamic = getThing(obj);
			if(shit != null) {
				shit.blend = blendModeFromString(blend);
				return true;
			}
			luaTrace("Object " + obj + " doesn't exist!");
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
			cancelTimer(tag);
			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) {
					PlayState.instance.modchartTimers.remove(tag);
				}
				PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
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
		});

		Lua_helper.add_callback(lua, "precacheSound", function(name:String) {
			return name; //lol
		});

		Lua_helper.add_callback(lua, "precacheImage", function(name:String) {
			return name; //lol
		});

		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0) {
				var rawPic:Dynamic;

				if (!Paths.currentTrackedAssets.exists(image))
					Paths.cacheImage(image);

				rawPic = Paths.currentTrackedAssets.get(image);

				leSprite.loadGraphic(rawPic);						
			}
			leSprite.antialiasing = antialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});

		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float,spriteType:String="sparrow", width:Int = 0, height:Int = 0) {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			
			switch(spriteType.toLowerCase()){
			
				case "texture" | "textureatlas"|"tex":
					leSprite.frames = AtlasFrameMaker.construct(image);
					
				case "packer" |"packeratlas"|"pac":
					leSprite.frames = Paths.getPackerAtlas(image);
				case "xmlless": //for the ones like the pixel notes and stuff.
				{
					var rawPic:Dynamic;

					if (!Paths.currentTrackedAssets.exists(image))
						Paths.cacheImage(image);

					rawPic = Paths.currentTrackedAssets.get(image);
					leSprite.loadGraphic(rawPic, true, width, height);
				}
				default:
				{
					var rawPic:Dynamic;
					var rawXml:String;

					if (!Paths.currentTrackedAssets.exists(image))
						Paths.cacheImage(image);

					rawPic = Paths.currentTrackedAssets.get(image);

					if (FileSystem.exists(FileSystem.absolutePath("assets/shared/images/"+image+".xml")))
						rawXml = File.getContent(FileSystem.absolutePath("assets/shared/images/"+image+".xml"));
					else
						rawXml = File.getContent(Paths.xmlNew('images/' + image));

					leSprite.frames = FlxAtlasFrames.fromSparrow(rawPic,rawXml);
				}
			}
			
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});

		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite2", function(tag:String, image:String,width:Int, height:Int) {
			tag = tag.replace('.', '');
			var leSprite:ModchartSprite = new ModchartSprite(0, 0);
			
			var rawPic:Dynamic;

			if (!Paths.currentTrackedAssets.exists(image))
				Paths.cacheImage(image);

			rawPic = Paths.currentTrackedAssets.get(image);
			leSprite.loadGraphic(rawPic, true, width, height);
			
			PlayState.instance.modchartSprites.set(tag, leSprite);
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
			var strIndices:Array<String> = indices.trim().split(',');
			var die:Array<Int> = [];
			for (i in 0...strIndices.length) {
				die.push(Std.parseInt(strIndices[i]));
			}

			if(PlayState.instance.modchartSprites.exists(obj)) {
				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if(pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
				return;
			}
			if(PlayState.instance.modchartIcons.exists(obj)) {
				var pussy:ModchartIcon = PlayState.instance.modchartIcons.get(obj);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if(pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
				return;
			}
			
			var pussy:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(pussy != null) {
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if(pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});

		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
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
			var spr:Dynamic = getThing(obj);

			if(spr != null) {
				spr.animation.play(name, forced);
			}
		});

		Lua_helper.add_callback(lua, "objectColorTransform", function(obj:String, r:Int, g:Int, b:Int, a:Int) {
			var spr:Dynamic = getThing(obj);

			if(spr != null) {
				spr.useColorTransform = true;
				spr.setColorTransform(0, 0, 0, 1, r, g, b, a);
			}
		});

		Lua_helper.add_callback(lua, "objectColorTween", function(obj:String, duration:Float, color:String, color2:String, ?ease:String = 'linear') {
			var spr:Dynamic = getThing(obj);

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

		Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, front:Bool = false) {
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				if(!shit.wasAdded) {
					if(front)
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
		});

				//Tween shit, but for strums
		Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String, ?player:Bool = false) {
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

		Lua_helper.add_callback(lua, "animExists", function(tag:String, anim:String){
			var shit:Dynamic = getThing(tag);
			
			return shit.animation.getByName(anim) != null;
		});

		Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String) {
			if(PlayState.instance.modchartSprites.exists(obj))
				return getInstance().members.indexOf(PlayState.instance.modchartSprites.get(obj));
			if(PlayState.instance.modchartTexts.exists(obj))
				return getInstance().members.indexOf(PlayState.instance.modchartTexts.get(obj));
			if(PlayState.instance.modchartIcons.exists(obj))
				return getInstance().members.indexOf(PlayState.instance.modchartIcons.get(obj));
			if(PlayState.instance.modchartCharacters.exists(obj))
				return getInstance().members.indexOf(PlayState.instance.modchartCharacters.get(obj));
			if(PlayState.instance.Stage.swagBacks.exists(obj))
				return getInstance().members.indexOf(PlayState.instance.Stage.swagBacks.get(obj));


			var leObj:FlxBasic = Reflect.getProperty(getInstance(), obj);
			if(leObj != null)
			{
				return getInstance().members.indexOf(leObj);
			}
			luaTrace("Object " + obj + " doesn't exist!");
			return -1;
		});

		Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var spr:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				if(spr.wasAdded) {
					getInstance().remove(spr, true);
				}
				getInstance().insert(position, spr);
				return;
			}
			if(PlayState.instance.modchartCharacters.exists(obj)) {
				var spr:Character = PlayState.instance.modchartCharacters.get(obj);
				getInstance().remove(spr, true);
				getInstance().insert(position, spr);
				return;
			}
			if(PlayState.instance.modchartIcons.exists(obj)) {
				var spr:ModchartIcon = PlayState.instance.modchartIcons.get(obj);
				getInstance().remove(spr, true);
				getInstance().insert(position, spr);
				return;
			}
			if(PlayState.instance.modchartTexts.exists(obj)) {
				var spr:ModchartText = PlayState.instance.modchartTexts.get(obj);
				if(spr.wasAdded) {
					getInstance().remove(spr, true);
				}
				getInstance().insert(position, spr);
				return;
			}
			if(PlayState.instance.Stage.swagBacks.exists(obj)) {
				var spr:Dynamic = PlayState.instance.Stage.swagBacks.get(obj);
				getInstance().remove(spr, true);
				getInstance().insert(position, spr);
				return;
			}

			var leObj:FlxBasic = Reflect.getProperty(getInstance(), obj);
			if(leObj != null) {
				getInstance().remove(leObj, true);
				getInstance().insert(position, leObj);
				return;
			}
			luaTrace("Object " + obj + " doesn't exist!");
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
					if(PlayState.instance.boyfriend.animOffsets.exists(anim))
						PlayState.instance.boyfriend.playAnim(anim, forced);
			}
		});

		Lua_helper.add_callback(lua, "characterDance", function(character:String) {
			if(PlayState.instance.modchartCharacters.exists(character)) {
				var spr:Character = PlayState.instance.modchartCharacters.get(character);
				spr.dance();
			}
			else
				getActorByName(character).dance();
		});

		Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var shit:ModchartState.ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return;
			}

			if(Stage.instance.swagBacks.exists(obj)) {
				var shit:StageModchartState.StageModchartSprite = Stage.instance.swagBacks.get(obj);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return;
			}
			
			if(PlayState.instance.Stage.swagBacks.exists(obj)) {
				var shit:StageModchartState.StageModchartSprite = Stage.instance.swagBacks.get(obj);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(poop != null) {
				poop.scale.set(x, y);
				poop.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: ' + obj);
		});
		
		Lua_helper.add_callback(lua, "setOffset", function(id:String, x:Float, y:Float) {
			var shit:Dynamic = getThing(id);
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

		//SHADER SHIT

		Lua_helper.add_callback(lua, "addEffect", function(camera:String,effect:String, ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic, ?val4:Dynamic) {
			
			PlayState.instance.addShaderToCamera(camera, getEffectFromString(effect, val1, val2, val3, val4));
			
		});
		Lua_helper.add_callback(lua, "clearEffects", function(camera:String) {
			PlayState.instance.clearShaderFromCamera(camera);
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

		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		Lua_helper.add_callback(lua, "luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				PlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, colorNum);
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
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
			luaTrace("luaSpritePlayAnimation is deprecated! Use objectPlayAnimation instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).animation.play(name, forced);
			}
		});
		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(tag:String, camera:String = '') {
			luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).cameras = [cameraFromString(camera)];
				return true;
			}
			luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
			}
		});
		Lua_helper.add_callback(lua, "scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
			}
		});
		Lua_helper.add_callback(lua, "getPropertyLuaSprite", function(tag:String, variable:String) {
			luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
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
			luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
				}
				return Reflect.setProperty(PlayState.instance.modchartSprites.get(tag), variable, value);
			}
			luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
		});
		Lua_helper.add_callback(lua, "musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);

		});
		Lua_helper.add_callback(lua, "musicFadeOut", function(duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration, toValue);
			luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});
	
		#end
	}

	inline static function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
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

	function resetSpriteTag(tag:String) {
		if(!PlayState.instance.modchartSprites.exists(tag)) {
			return;
		}
		
		var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartSprites.remove(tag);
	}

	function resetCharacterTag(tag:String) {
		if(!PlayState.instance.modchartCharacters.exists(tag)) {
			return;
		}
		
		var pee:Dynamic = PlayState.instance.modchartCharacters.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartCharacters.remove(tag);
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
		var variables:Array<String> = vars.replace(' ', '').split('.');
		var sexyProp:Dynamic = Reflect.getProperty(getInstance(), variables[0]);
		if(PlayState.instance.modchartSprites.exists(variables[0])) {
			sexyProp = PlayState.instance.modchartSprites.get(variables[0]);
		}
		if(PlayState.instance.modchartTexts.exists(variables[0])) {
			sexyProp = PlayState.instance.modchartTexts.get(variables[0]);
		}

		for (i in 1...variables.length) {
			sexyProp = Reflect.getProperty(sexyProp, variables[i]);
		}
		return sexyProp;
	}

	function cancelTimer(tag:String) {
		if(PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	//Better optimized than using some getProperty shit or idk
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

	function cameraFromString(cam:String):FlxCamera {
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}
		return PlayState.instance.camGame;
	}

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false) {
		#if LUA_ALLOWED
		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) {
				return;
			}
			PlayState.instance.addTextToDebug(text);
			trace(text);
		}
		#end
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
	
	public function call(event:String, args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		if(lua == null) {
			return Function_Continue;
		}

		Lua.getglobal(lua, event);

		for (arg in args) {
			Convert.toLua(lua, arg);
		}

		var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);
		if(result != null && resultIsAllowed(lua, result)) {
			/*var resultStr:String = Lua.tostring(lua, result);
			var error:String = Lua.tostring(lua, -1);
			Lua.pop(lua, 1);*/
			if(Lua.type(lua, -1) == Lua.LUA_TSTRING) {
				var error:String = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if(error == 'attempt to call a nil value') { //Makes it ignore warnings and not break stuff if you didn't put the functions on your lua file
					return Function_Continue;
				}
			}

			var conv:Dynamic = Convert.fromLua(lua, result);
			Lua.pop(lua, 1);
			return conv;
		}
		#end
		return Function_Continue;
	}

	public static function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?noGameOver:Bool = false):Dynamic
	{
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo, noGameOver);
		for (i in 1...killMe.length-1) {
			coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
		}
		return coverMeInPiss;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?noGameOver:Bool = false):Dynamic
	{
		var coverMeInPiss:Dynamic = null;
		if(PlayState.instance.modchartSprites.exists(objectName)) {
			coverMeInPiss = PlayState.instance.modchartSprites.get(objectName);
		} else if(checkForTextsToo && PlayState.instance.modchartTexts.exists(objectName)) {
			coverMeInPiss = PlayState.instance.modchartTexts.get(objectName);
		} else {
			coverMeInPiss = Reflect.getProperty(noGameOver ? PlayState.instance : getInstance(), objectName);
		}
		return coverMeInPiss;
	}

	#if LUA_ALLOWED
	function resultIsAllowed(leLua:State, leResult:Null<Int>) { //Makes it ignore warnings
		switch(Lua.type(leLua, leResult)) {
			case Lua.LUA_TNIL | Lua.LUA_TBOOLEAN | Lua.LUA_TNUMBER | Lua.LUA_TSTRING | Lua.LUA_TTABLE:
				return true;
		}
		return false;
	}
	#end

	public function set(variable:String, data:Dynamic) {
		#if LUA_ALLOWED
		if(lua == null) {
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	#if LUA_ALLOWED
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

	public function die() {
		#if LUA_ALLOWED
		if(lua == null) {
			return;
		}

		if(accessedProps != null) {
			accessedProps.clear();
		}

		Lua.close(lua);
		lua = null;
		#end
	}

	public function makeLuaCharacter(tag:String, character:String, isPlayer:Bool = false, flipped:Bool = false)
	{
		tag = tag.replace('.', '');
		resetCharacterTag(tag);
		var leSprite:Character = new Character(0, 0, character, isPlayer);
		leSprite.flipMode = flipped;
		PlayState.instance.modchartCharacters.set(tag, leSprite); //yes
		var shit:Character = PlayState.instance.modchartCharacters.get(tag);
		PlayState.instance.add(shit);

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

		PlayState.instance.startCharacterLua(shit.curCharacter);
	}

	public function getThing(id:String)
	{
		var shit:Dynamic;

		if(PlayState.instance.modchartSprites.exists(id))
			shit = PlayState.instance.modchartSprites.get(id);
		else if(PlayState.instance.modchartTexts.exists(id))
			shit = PlayState.instance.modchartTexts.get(id);
		else if(PlayState.instance.modchartIcons.exists(id))
			shit = PlayState.instance.modchartIcons.get(id);
		else if(PlayState.instance.modchartCharacters.exists(id))
			shit = PlayState.instance.modchartCharacters.get(id);
		else if(PlayState.instance.Stage.swagBacks.exists(id))
			shit = PlayState.instance.Stage.swagBacks.get(id);
		else if(Stage.instance.swagBacks.exists(id))
			shit = Stage.instance.swagBacks.get(id);
		else
			shit =  getActorByName(id);

		return shit;
	}

	function getActorByName(id:String):Dynamic
	{
		// pre defined names
		switch(id)
		{
			case 'boyfriend' | 'bf':
				return PlayState.instance.boyfriend;
			case 'boyfriend1' | 'bf1':
				return PlayState.instance.boyfriend1;
			case 'boyfriend2' | 'bf2':
                @:privateAccess
				return PlayState.instance.boyfriend2;
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

	function getEffectFromString(?effect:String = '', ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic , ?val4:Dynamic):ShaderEffect {
		switch(effect.toLowerCase().trim()) {
			case 'grayscale' | 'greyscale' : return new GreyscaleEffect();
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
			case 'chromaticabberation': new ChromaticAberrationEffect(val1);
			case 'sketch': new SketchEffect();
		}
		return new GreyscaleEffect();
	}

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

		if (PlayState.instance.changeArrows)
		{
			for (i in 0...Main.keyAmmo[PlayState.SONG.mania])
			{
				PlayState.instance.strumLineNotes.members[i].texture = PlayState.instance.dad.noteSkin;
			}
		}

		if (PlayState.instance.defaultBar)
		{
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + PlayState.instance.dad.iconColor), FlxColor.fromString('#' + PlayState.instance.boyfriend.iconColor));
			PlayState.instance.healthBar.updateBar();
		}	

		PlayState.instance.startCharacterLua(PlayState.instance.dad.curCharacter);
	
	}

	function changeDad1Character(id:String, x:Float, y:Float)
	{		
		PlayState.instance.removeObject(PlayState.instance.dad1Trail);
		PlayState.instance.removeObject(PlayState.instance.dad1);
		PlayState.instance.destroyObject(PlayState.instance.dad1);
		PlayState.instance.dad1 = new Character(x, y, id);
		PlayState.instance.addObject(PlayState.instance.dad1Trail);
		PlayState.instance.dad1Trail.resetTrail();
		PlayState.instance.addObject(PlayState.instance.dad1);
	}

	function changeDad2Character(id:String, x:Float, y:Float)
	{		
		PlayState.instance.removeObject(PlayState.instance.dad2);
		PlayState.instance.destroyObject(PlayState.instance.dad2);
		PlayState.instance.dad2 = new Character(x, y, id);
		PlayState.instance.addObject(PlayState.instance.dad2);

		if (PlayState.instance.defaultBar)
		{
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + PlayState.instance.dad2.iconColor), FlxColor.fromString('#' + PlayState.instance.boyfriend.iconColor));
			PlayState.instance.healthBar.updateBar();
		}	
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

		if (PlayState.instance.changeArrows)
		{
			for (i in Main.keyAmmo[PlayState.SONG.mania]...Main.keyAmmo[PlayState.SONG.mania] * 2)
			{
				PlayState.instance.strumLineNotes.members[i].texture = PlayState.instance.boyfriend.noteSkin;
				PlayState.instance.bfStrumStyle = PlayState.instance.boyfriend.noteSkin;
			}
		}

		if (PlayState.instance.defaultBar)
		{
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + PlayState.instance.dad.iconColor), FlxColor.fromString('#' + PlayState.instance.boyfriend.iconColor));
			PlayState.instance.healthBar.updateBar();
		}	

		if (PlayState.instance.boyfriend.animOffsets.exists(animationName))
			PlayState.instance.boyfriend.playAnim(animationName, true, false, animationFrame);

		PlayState.instance.startCharacterLua(PlayState.instance.boyfriend.curCharacter);
	}

	function changeBoyfriend1Character(id:String, x:Float, y:Float)
	{							
		PlayState.instance.removeObject(PlayState.instance.bf1Trail);
		PlayState.instance.removeObject(PlayState.instance.boyfriend1);
		//PlayState.instance.boyfriend1 = new Boyfriend1(x, y, null);
		PlayState.instance.destroyObject(PlayState.instance.boyfriend1);
		PlayState.instance.boyfriend1 = new Boyfriend(x, y, id);
		PlayState.instance.addObject(PlayState.instance.bf1Trail);
		PlayState.instance.bf1Trail.resetTrail();
		PlayState.instance.addObject(PlayState.instance.boyfriend1);

		if (PlayState.instance.changeArrows)
		{
			for (i in Main.keyAmmo[PlayState.SONG.mania]...Main.keyAmmo[PlayState.SONG.mania] * 2)
			{
				PlayState.instance.strumLineNotes.members[i].texture = PlayState.instance.boyfriend.noteSkin;
				PlayState.instance.bfStrumStyle = PlayState.instance.boyfriend.noteSkin;
			}
		}

		if (PlayState.instance.defaultBar)
		{
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + PlayState.instance.dad.iconColor), FlxColor.fromString('#' + PlayState.instance.boyfriend1.iconColor));
			PlayState.instance.healthBar.updateBar();
		}	
	}

	function changeBoyfriend2Character(id:String, x:Float, y:Float)
	{							
		PlayState.instance.removeObject(PlayState.instance.boyfriend2);
		PlayState.instance.destroyObject(PlayState.instance.boyfriend2);
		PlayState.instance.boyfriend2 = new Boyfriend(x, y, id);
		PlayState.instance.addObject(PlayState.instance.boyfriend2);
		
		if (PlayState.instance.defaultBar)
		{
			PlayState.instance.healthBar.createFilledBar(FlxColor.fromString('#' + PlayState.instance.dad.iconColor), FlxColor.fromString('#' + PlayState.instance.boyfriend2.iconColor));
			PlayState.instance.healthBar.updateBar();
		}	
	}

	//does this work. right? -- future me here. yes it does.
	function changeStage(id:String)
	{	
		PlayState.instance.removeObject(PlayState.instance.gf);
		PlayState.instance.removeObject(PlayState.instance.dad);
		PlayState.instance.removeObject(PlayState.instance.boyfriend);

		if (PlayState.SONG.song.toLowerCase() == 'epiphany' && PlayState.storyDifficulty == 5)
			PlayState.instance.removeObject(PlayState.instance.dad1);

		if (PlayState.instance.trioDad)
		{
			PlayState.instance.removeObject(PlayState.instance.dad1);
			PlayState.instance.removeObject(PlayState.instance.dad2);
		}

		if (PlayState.instance.duoBoyfriend || PlayState.instance.trioBoyfriend)
		{
			PlayState.instance.removeObject(PlayState.instance.boyfriend1);

			if (PlayState.instance.trioBoyfriend)
				PlayState.instance.removeObject(PlayState.instance.boyfriend2);
		}
		
		if (PlayState.instance.Stage.isCustomStage && PlayState.instance.Stage.stageLuaArray.length >= 1)
		{
			trace(PlayState.instance.Stage.stageLuaArray.length);

			for (i in PlayState.instance.Stage.stageLuaArray)
			{
				PlayState.instance.Stage.stageLuaArray.remove(i);
				i.die();
			}
			PlayState.instance.Stage.stageLuaArray = [];
			trace(PlayState.instance.Stage.stageLuaArray.length);
		}

		for (i in PlayState.instance.Stage.toAdd)
		{
			PlayState.instance.removeObject(i);
			PlayState.instance.destroyObject(i);
		}	

		for (i in PlayState.instance.Stage.layInFront[0])
		{
			PlayState.instance.removeObject(i);
			PlayState.instance.destroyObject(i);
		}	

		for (i in PlayState.instance.Stage.layInFront[1])
		{
			PlayState.instance.removeObject(i);
			PlayState.instance.destroyObject(i);
		}	

		for (i in PlayState.instance.Stage.layInFront[2])
		{
			PlayState.instance.removeObject(i);
			PlayState.instance.destroyObject(i);
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
					if (PlayState.SONG.song.toLowerCase() == 'epiphany' && PlayState.storyDifficulty == 5)
						PlayState.instance.addObject(PlayState.instance.dad1);

					if (PlayState.instance.trioDad)
					{
						PlayState.instance.addObject(PlayState.instance.dad1);
						PlayState.instance.addObject(PlayState.instance.dad2);
					}

					PlayState.instance.addObject(PlayState.instance.dad);

					if (PlayState.instance.trioBoyfriend)
					{
						PlayState.instance.addObject(PlayState.instance.boyfriend1);
						PlayState.instance.addObject(PlayState.instance.boyfriend2);
					}
					for (bg in array)
						PlayState.instance.addObject(bg);
				case 2:
					PlayState.instance.addObject(PlayState.instance.boyfriend);

					if (PlayState.instance.duoBoyfriend)
						PlayState.instance.addObject(PlayState.instance.boyfriend1);

					for (bg in array)
						PlayState.instance.addObject(bg);
			}
		}	
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
	public function changeBFAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false)
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

		if (PlayState.instance.changeArrows)
		{
			for (i in Main.keyAmmo[PlayState.SONG.mania]...Main.keyAmmo[PlayState.SONG.mania] * 2)
			{
				PlayState.instance.strumLineNotes.members[i].texture = PlayState.instance.boyfriend.noteSkin;
				PlayState.instance.bfStrumStyle = PlayState.instance.boyfriend.noteSkin;
			}
		}

		PlayState.instance.startCharacterLua(PlayState.instance.boyfriend.curCharacter);
	}

	public function changeDadAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false)
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

		if (PlayState.instance.changeArrows)
		{
			for (i in 0...Main.keyAmmo[PlayState.SONG.mania])
			{
				PlayState.instance.cpuStrums.members[i].texture = PlayState.instance.dad.noteSkin;
			}
		}

		PlayState.instance.startCharacterLua(PlayState.instance.dad.curCharacter);
	}

	function changeGFAuto(id:String, ?dontDestroy:Bool = false)
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

	function doFunction(id:String, ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic, ?val4:Dynamic)
	{
		//this is dumb but idk how else to do it and i don't wanna make multiple functions for different playstate functions so yeah.
		switch (id)
		{
			case 'doP3Static': PlayState.instance.doP3Static();
			case 'doP3Jump': PlayState.instance.doP3Jump(val1);
			case 'funCountdown': PlayState.instance.funCountdown(val1);
			case 'softCountdown': PlayState.instance.softCountdown();
			case 'startCountdown': PlayState.instance.startCountdown();
			case 'doJumpscare': PlayState.instance.doJumpscare();
			case 'startWriting': PlayState.instance.startWriting(val1, val2);		
			case 'doSonicIntro': PlayState.instance.doSonicIntro(val1, val2);	
			case 'doSimpleJump': PlayState.instance.doSimpleJump(val1);		
			case 'resyncVocals': PlayState.instance.resyncVocals();	
			case 'doTimeTravel': PlayState.instance.doTimeTravel(val1, val2);		
			case 'uncacheImage': Paths.clearStoredMemory2(val1);			
			case 'cacheImage': Paths.cacheImage(val1, val2); 
			case 'toggleHealthShit': PlayState.instance.toggleHealthShit(val1);
			case 'spawnStartingNoteSplash': PlayState.instance.spawnStartingNoteSplash(0, 0, 0);	
			case 'doStopSign': PlayState.instance.doStopSign(val1, val2);	
			case 'doGremlin': PlayState.instance.doGremlin(val1, val2, val3);			
			case 'bgFlash': PlayState.instance.bgFlash();
			case 'createBFSpookyText': PlayState.instance.createBFSpookyText(val1);
			case 'createSpookyText': PlayState.instance.createSpookyText(val1);
			case 'createAuditorText': PlayState.instance.createAuditorText(val1, val2, val3, val4);
		}
	}
		


	public static inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
	static inline var CLENSE:String = "
	os.execute = nil;
	os.exit = nil;
	package.loaded.os.execute = nil;
	package.loaded.os.exit = nil;
	process = nil;
	package.loaded.process = nil;

	"; // Fuck this, I can't figure out linc_lua, so I'mma set everything in Lua itself - Super
}

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	//public var isInFront:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = true;
	}
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

class ModchartIcon extends HealthIcon
{
	public var wasAdded:Bool = false;
	//public var isInFront:Bool = false;
}

class DebugLuaText extends FlxText
{
	private var disableTime:Float = 6;
	public var parentGroup:FlxTypedGroup<DebugLuaText>; 
	public function new(text:String, parentGroup:FlxTypedGroup<DebugLuaText>) {
		this.parentGroup = parentGroup;
		super(10, 10, 0, text, 16);
		setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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
