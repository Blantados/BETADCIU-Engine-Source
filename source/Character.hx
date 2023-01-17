package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import lime.app.Application;
import flash.display.BitmapData;
import flixel.graphics.FlxGraphic;
import haxe.xml.Fast;

#if desktop
import Sys;
import sys.FileSystem;
import sys.io.File;
#end

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import flixel.text.FlxText;
import haxe.xml.Access;
import flixel.math.FlxMath;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var playerAnimations:Array<AnimArray>; //bcuz garcello
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var playerposition:Array<Float>; //bcuz dammit some of em don't exactly flip right
	var camera_position:Array<Float>;
	var player_camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var noteSkin:String;
	var isPlayerChar:Bool;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	var playerOffsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var animPlayerOffsets:Map<String, Array<Dynamic>>; //for saving as jsons lol
	public var debugMode:Bool = false;
	public var idleSuffix:String = '';

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var isCustom:Bool = false;
	public var altAnim:String = '';
	public var bfAltAnim:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle" "-- why didn't i think of this?"
	
	public var isPixel:Bool = false;
	public var noteSkin:String;
	public var isPsychPlayer:Bool;
	public var healthIcon:String = 'bf';
	public var doMissThing:Bool = false;
	public var iconColor:String;
	public var trailColor:String;
	public var curColor:FlxColor;

	public var holdTimer:Float = 0;

	public var daZoom:Float = 1;

	public var tex:FlxAtlasFrames;
	public var exSpikes:FlxSprite;
	public var charPath:String;

	public static var colorPreString:FlxColor;
	public static var colorPreCut:String; 
	var weZoomed:Bool = false;
	public var flipMode:Bool = false;

	var pre:String = "";

	//psych method. yay!
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var positionArray:Array<Float> = [0, 0];
	public var playerPositionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var playerCameraPosition:Array<Float> = [0, 0];
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var animationsArray:Array<AnimArray> = [];
	public var stopIdle:Bool = false;

	public var stunned:Bool = false;
	
	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
		animPlayerOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		healthIcon = character;
		this.isPlayer = isPlayer;
		iconColor = isPlayer ? 'FF66FF33' : 'FFFF0000';
		trailColor = isPlayer ? "FF0026FF" : "FFAA0044";
		curColor = 0xFFFFFFFF;
				
		antialiasing = true;
		isCustom = false;
		pre = "";

		if (PlayState.instance != null)
			noteSkin = PlayState.SONG.noteStyle;
		
		//should now only be using the default psych json stuff

		switch (curCharacter)
		{
			//using the psych method instead of modding plus. main reason is to make it easier for me to port them here
			default:
				isCustom = true;

				var characterPath:String = 'images/characters/jsons/' + curCharacter;

				var path:String = Paths.jsonNew(characterPath);
				
				#if MODS_ALLOWED
					if (FileSystem.exists(Paths.modFolders('characters/'+curCharacter+'.json')) || Assets.exists(Paths.modFolders('characters/'+curCharacter+'.json')))
						path = Paths.modFolders('characters/'+curCharacter+'.json');
				#end
			
				if (!FileSystem.exists(path) && !Assets.exists(path))
				{
					trace('oh no missingno');
					path = Paths.jsonNew('images/characters/jsons/' + DEFAULT_CHARACTER); //If a character couldn't be found, change to bf just to prevent a crash
					curCharacter = DEFAULT_CHARACTER;
				}

				var rawJson:Dynamic;

				(FileSystem.exists(path) ? rawJson = File.getContent(path) : rawJson = Assets.getText(path));
				
				var json:CharacterFile = cast Json.parse(rawJson);

				if (json.noteSkin != null){noteSkin = json.noteSkin;}
				if (json.isPlayerChar){isPsychPlayer = json.isPlayerChar;}
					
				if ((noteSkin == "" || noteSkin == 'normal' || noteSkin == 'default') && PlayState.SONG != null)
					noteSkin = PlayState.SONG.noteStyle;	

				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				var imagePath = Paths.image(json.image);

				if (!Paths.currentTrackedAssets.exists(json.image))
				{
					if (Assets.exists(imagePath) && !FileSystem.exists(imagePath) && !FileSystem.exists(Paths.modsImages(imagePath)))
						Paths.cacheImage(json.image, 'shared', false, !noAntialiasing);
					else
						Paths.cacheImage(json.image, 'preload', false, !noAntialiasing);	
				}

				charPath = json.image + '.png'; //cuz we only use pngs anyway
				imageFile = json.image; //psych

				if(FileSystem.exists(Paths.txtNew('images/' + json.image)))
					frames = Paths.getPackerAtlas(json.image);
				else 
					frames = Paths.getSparrowAtlas(json.image);

				if(FlxG.save.data.poltatoPC)
				{	
					json.scale *= 2;
					
					if (isPlayer && json.playerposition != null)
						json.playerposition = [json.playerposition[0] + 100, json.playerposition[1] + 170];
					else
						json.position = [json.position[0] + 100, json.position[1] + 170];
				}

				if(json.scale != 1) {
					jsonScale = json.scale;

					(FlxG.save.data.poltatoPC ? scale.set(jsonScale, jsonScale) : setGraphicSize(Std.int(width * jsonScale))); // is this different?
					updateHitbox();
				}

				healthIcon = json.healthicon;
				
				(isPlayer && json.playerposition != null ? positionArray = json.playerposition : positionArray = json.position);
				(json.playerposition != null ? playerPositionArray = json.playerposition : playerPositionArray = json.position);
				(isPlayer && json.player_camera_position != null ? cameraPosition = json.player_camera_position : cameraPosition = json.camera_position);
				(json.player_camera_position != null ? playerCameraPosition = json.player_camera_position : playerCameraPosition = json.camera_position);
				
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				//cuz the way bar colors are calculated here is like in B&B
				colorPreString = FlxColor.fromRGB(healthColorArray[0], healthColorArray[1], healthColorArray[2]);
				colorPreCut = colorPreString.toHexString();

				iconColor = colorPreCut.substring(2);

				antialiasing = !noAntialiasing;

				animationsArray = json.animations;

				if (isPlayer && json.playerAnimations != null)
					animationsArray = json.playerAnimations;

				if(animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;
						if(animIndices != null && animIndices.length > 0) {
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						} else {
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if (isPlayer)
						{
							if(anim.playerOffsets != null && anim.playerOffsets.length > 1) {
								addOffset(anim.anim, anim.playerOffsets[0], anim.playerOffsets[1]);
							}
							else if(anim.offsets != null && anim.offsets.length > 1) {
								addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
							}
						}
						else
						{
							if(anim.offsets != null && anim.offsets.length > 1) {
								addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
							}
						}

						if(anim.playerOffsets != null && anim.playerOffsets.length > 1) {
							addPlayerOffset(anim.anim, anim.playerOffsets[0], anim.playerOffsets[1]);
						}
					
					}
				} else {
					quickAnimAdd('idle', 'BF idle dance');
					quickAnimAdd('singUP', 'BF idle dance');
					quickAnimAdd('singDOWN', 'BF idle dance');
					quickAnimAdd('singLEFT', 'BF idle dance');
					quickAnimAdd('singRIGHT', 'BF idle dance');
				}

				if (animOffsets.exists('danceRight'))
					playAnim('danceRight');
				else
					playAnim('idle');
		}

		if(animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null)
			danceIdle = true;

		if(animation.getByName('singUPmiss') == null)
			doMissThing = true; //if for some reason you only have an up miss, why?

		originalFlipX = flipX;

		dance();

		if (isPlayer)
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf') && !isPsychPlayer)
				flipAnims();
		}

		if (!isPlayer)
		{
			// Flip for just bf
			if (curCharacter.startsWith('bf') || isPsychPlayer)
				flipAnims();
		}
	}

	var txtToFind:String;
	var rawPic:Dynamic;
	var rawXml:String;

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed;
				if(heyTimer <= 0)
				{
					if(specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}
	
			if (flipMode)
			{
				if (isPlayer)
				{
					if (animation.curAnim.name.startsWith('sing'))
						holdTimer += elapsed;
		
					if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001)
					{
						dance();
						holdTimer = 0;
					}
				}
			}
			else
			{
				if (!isPlayer)
				{
					if (animation.curAnim.name.startsWith('sing'))
						holdTimer += elapsed;
		
					if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001 / (PlayState.instance != null ? 1 : PlayState.instance.playbackRate))
					{
						dance();
						holdTimer = 0;
					}
				}
			}

			if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
				playAnim(animation.curAnim.name + '-loop');
			
			if (curCharacter.startsWith('gf') && animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
				playAnim('danceRight');
		}
	
		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */

	public function dance()
	{
		if (!debugMode && !specialAnim)
		{
			switch (curCharacter)
			{
				default:
					if (danceIdle)
					{
						if (!stopIdle)
						{
							danced = !danced;
		
							if (isPlayer)
							{
								if (danced)
									playAnim('danceRight' + bfAltAnim + idleSuffix);
								else
									playAnim('danceLeft' + bfAltAnim + idleSuffix);
							}
							else
							{
								if (danced)
									playAnim('danceRight' + altAnim + idleSuffix);
								else
									playAnim('danceLeft' + altAnim + idleSuffix);
							}	
						}
					}
					else
					{
						if (!stopIdle)
						{
							if (isPlayer)
								playAnim('idle' + bfAltAnim + idleSuffix);
							else
								playAnim('idle' + altAnim + idleSuffix);	
						}
					}
			}
		
			if (color != curColor && doMissThing)
				color = curColor;
		}
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function setZoom(?toChange:Float = 1, ?isPixel:Bool = false):Void
	{
		daZoom = toChange;

		var daMulti:Float = 1;

		(FlxG.save.data.poltatoPC ? daMulti *= 2 : daMulti *= 1);

		if (isPixel && !isCustom)
			daMulti = 6;

		if (isCustom)
			daMulti = jsonScale;
			
		var daValue:Float = toChange * daMulti;
		scale.set(daValue, daValue);
	}

	public function loadOffsetFile(character:String)
	{
		var offset:Array<String>;
		
		if (isPlayer)
		{
			if (Assets.exists(Paths.txtNew('images/characters/offsets/' + character + "PlayerOffsets", 'shared')))
				offset = CoolUtil.coolTextFile(Paths.txtNew('images/characters/offsets/' + character + "PlayerOffsets", 'shared'));
			else if (Assets.exists(Paths.txtNew('images/characters/offsets/' + character + "Offsets", 'shared')))
				offset = CoolUtil.coolTextFile(Paths.txtNew('images/characters/offsets/' + character + "Offsets", 'shared'));
			else
				offset = CoolUtil.coolTextFile(Paths.txtNew('images/characters/offsets/noOffsets', 'shared'));
		}
		else
		{
			if (Assets.exists(Paths.txtNew('images/characters/offsets/' + character + "Offsets", 'shared')))
				offset = CoolUtil.coolTextFile(Paths.txtNew('images/characters/offsets/' + character + "Offsets", 'shared'));
			else if (Assets.exists(Paths.txtNew('images/characters/offsets/' + character + "PlayerOffsets", 'shared')))
				offset = CoolUtil.coolTextFile(Paths.txtNew('images/characters/offsets/' + character + "PlayerOffsets", 'shared'));	
			else
				offset = CoolUtil.coolTextFile(Paths.txtNew('images/characters/offsets/noOffsets', 'shared'));
		}

		for (i in 0...offset.length)
		{
			var data:Array<String> = offset[i].split(' ');
			addOffset(data[0], Std.parseInt(data[1]), Std.parseInt(data[2]));
		}
		
		//for saving playerOffsets in jsons
		if (Assets.exists(Paths.txtNew('images/characters/offsets/' + character + "PlayerOffsets", 'shared')))
		{
			var playerOffset:Array<String>;

			playerOffset = CoolUtil.coolTextFile(Paths.txtNew('images/characters/offsets/' + character + "PlayerOffsets", 'shared'));

			for (i in 0...playerOffset.length)
			{
				var data:Array<String> = playerOffset[i].split(' ');
				addPlayerOffset(data[0], Std.parseInt(data[1]), Std.parseInt(data[2]));
			}
		}
		else
		{
			for (i in 0...offset.length)
			{
				var data:Array<String> = offset[i].split(' ');
				addPlayerOffset(data[0], Std.parseInt(data[1]), Std.parseInt(data[2]));
			}
		}
	}

	var missed:Bool = false;

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		missed = false;

		if (AnimName.endsWith('alt') && animation.getByName(AnimName) == null)
			AnimName = AnimName.split('-')[0];

		if (AnimName == 'laugh' && animation.getByName(AnimName) == null)
			AnimName = 'singUP';

		if (AnimName.endsWith('2') && animation.getByName(AnimName) == null && curCharacter == 'hex-9key')
			AnimName = AnimName.substr(0, AnimName.length - 1);

		if (AnimName.endsWith('miss') && animation.getByName(AnimName) == null)
		{
			AnimName = AnimName.substr(0, AnimName.length - 4);

			if (doMissThing)
				missed = true;
		}

		if (AnimName.endsWith('miss') && curCharacter == 'bf-sky' && doMissThing)
			missed = true;

		if (animation.getByName(AnimName) == null) // if it's STILL null, just play idle, and if you REALLY messed up, it'll look in the xml for a valid anim
		{
			if(danceIdle && animation.getByName('danceRight') != null)
				AnimName = 'danceRight';
			else if (animation.getByName('idle') != null)
				AnimName = 'idle';
			else{
				if (graphic.key == 'bruhtf')
					quickAnimAdd(AnimName, CoolUtil.findFirstAnim(Assets.getText(Paths.xmlNew('images/bruhtf'))));
				else{
					var path:String = Paths.xmlNew('images/' + imageFile);

					quickAnimAdd(AnimName, CoolUtil.findFirstAnim((FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path))));
				}
			}
				
		}

		animation.play(AnimName, Force, Reversed, Frame);


		if (missed)
			color = 0xCFAFFF;
		else if (color != curColor && doMissThing)
			color = curColor;

		var daOffset = animOffsets.get(AnimName);

		if (debugMode && isPlayer)
			daOffset = animPlayerOffsets.get(AnimName);
		
		if (debugMode)
		{
			if (animOffsets.exists(AnimName) && !isPlayer || animPlayerOffsets.exists(AnimName) && isPlayer)
				offset.set(daOffset[0] * daZoom, daOffset[1] * daZoom);
			else
				offset.set(0, 0);
		}
		else
		{
			if (animOffsets.exists(AnimName))
				offset.set(daOffset[0] * daZoom, daOffset[1] * daZoom);
			else
				offset.set(0, 0);
		}
	
		if (curCharacter.startsWith('gf') && animOffsets.exists('singLEFT'))
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function addPlayerOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animPlayerOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		addAnimationByPrefix(name, anim, 24, false);
	}

	public function getCharPath(path:String, ?library:String)
	{	
		charPath = path + '.png'; //cuz we only use pngs anyway
		imageFile = path; //psych

		return Paths.getSparrowAtlas(path, library);
	}

	//so that I can convert em to psych faster
	public function addAnimationByPrefix(name:String, prefix:String, framerate:Int = 24, loop:Bool = false)
	{
		var newAnim:AnimArray = {
			anim: name,
			name: prefix,
			fps: Math.round(framerate),
			loop: loop,
			indices: [],
			offsets: [0, 0],
			playerOffsets: [0, 0]
		};

		animation.addByPrefix(name, prefix, framerate, loop);
		animationsArray.push(newAnim);
	}

	public function addAnimationByIndices(name:String, prefix:String, indices:Array<Int>, string:String, framerate:Int = 24, loop:Bool = false)
	{
		//string isn't used. just placed for easy conversion.
		var newAnim:AnimArray = {
			anim: name,
			name: prefix,
			fps: Math.round(framerate),
			loop: loop,
			indices: indices,
			offsets: [0, 0],
			playerOffsets: [0, 0]
		};

		animation.addByIndices(name, prefix, indices, "", framerate, loop);
		animationsArray.push(newAnim);
	}

	public function flipAnims()
	{
		if (animation.getByName('singRIGHT') != null && animation.getByName('singLEFT') != null)
		{
			var oldRight = animation.getByName('singRIGHT').frames;
			animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
			animation.getByName('singLEFT').frames = oldRight;
		}

		// IF THEY HAVE MISS ANIMATIONS??
		if (animation.getByName('singRIGHTmiss') != null && animation.getByName('singLEFTmiss') != null)
		{
			var oldMiss = animation.getByName('singRIGHTmiss').frames;
			animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
			animation.getByName('singLEFTmiss').frames = oldMiss;
		}
		if (animation.getByName('singRIGHT-alt') != null && animation.getByName('singLEFT-alt') != null)
		{
			var oldAlt = animation.getByName('singRIGHT-alt').frames;
			animation.getByName('singRIGHT-alt').frames = animation.getByName('singLEFT-alt').frames;
			animation.getByName('singLEFT-alt').frames = oldAlt;
		}

		if (animation.getByName('singRIGHT-loop') != null && animation.getByName('singLEFT-loop') != null)
		{
			var oldLoop = animation.getByName('singRIGHT-loop').frames;
			animation.getByName('singRIGHT-loop').frames = animation.getByName('singLEFT-loop').frames;
			animation.getByName('singLEFT-loop').frames = oldLoop;
		}

		if (curCharacter.contains('9key'))
		{
			var oldRight = animation.getByName('singRIGHT2').frames;
			animation.getByName('singRIGHT2').frames = animation.getByName('singLEFT2').frames;
			animation.getByName('singLEFT2').frames = oldRight;
		}
	}
}