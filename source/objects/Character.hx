	package objects;

import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxDestroyUtil;
import lime.app.Application;
import flash.display.BitmapData;
import flixel.graphics.FlxGraphic;
import haxe.xml.Fast;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import haxe.xml.Access;

import objects.FunkinSprite;
import flxanimate.FlxAnimate;
import animateatlas.AtlasFrameMaker;
import luafiles.LuaUtils;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;

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
	var vocals_file:String;
	var noteSkin:String;
	var isPlayerChar:Bool;

	@:optional
	var playerAnimations:Array<AnimArray>; //bcuz garcello
	var spriteType:String;
	var gameover_character:String;
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

class Character extends FunkinSprite
{
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
	public var isPsychPlayer:Null<Bool>;
	public var healthIcon:String = 'bf';
	public var doMissThing:Bool = false;
	public var iconColor:String;
	public var trailColor:String;
	public var curColor:FlxColor = 0xFFFFFFFF;

	public var holdTimer:Float = 0;

	public var daZoom:Float = 1;

	public var tex:FlxAtlasFrames;
	public var charPath:String;

	public static var colorPreString:FlxColor;
	public static var colorPreCut:String; 
	public var flipMode:Bool = false;

	var pre:String = "";

	//psych method. yay!
	public var imageFile:String = '';
	public var preloadImageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var vocalsFile:String = '';
	public var positionArray:Array<Float> = [0, 0];
	public var playerPositionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var playerCameraPosition:Array<Float> = [0, 0];
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var animationsArray:Array<AnimArray> = [];
	public var stopIdle:Bool = false;
	public var skipDance:Bool = false; // hey there's a psych var now! neat!

	public var stunned:Bool = false;
	public var gameOverCharacter:String = "";

	//might try using texture atlas.
	public var spriteType:String;
	
	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place

	public static function getCharacterFile(character:String):CharacterFile{
		var characterPath:String = 'images/characters/jsons/' + character;
		var path:String = Paths.jsonNew(characterPath);

		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders('characters/'+character+'.json')) || Assets.exists(Paths.modFolders('characters/'+character+'.json'))) {
			path = Paths.modFolders('characters/'+character+'.json');
		}
		#end
	
		if (!FileSystem.exists(path) && !Assets.exists(path))
		{
			trace('oh no missingno. Character '+character+" not found.");
			path = Paths.jsonNew('images/characters/jsons/' + DEFAULT_CHARACTER); //If a character couldn't be found, change to bf just to prevent a crash
			character = DEFAULT_CHARACTER;
		}

		var rawJson:Dynamic;

		(FileSystem.exists(path) ? rawJson = File.getContent(path) : rawJson = Assets.getText(path));
		
		var json:CharacterFile = cast Json.parse(rawJson);

		return json;
	}

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);

		loadCharacter(character, isPlayer);
	}

	public function resetCharacterAttributes(?character:String = "bf", ?isPlayer:Bool = false)
	{
		animOffsets = new Map<String, Array<Dynamic>>();
		animPlayerOffsets = new Map<String, Array<Dynamic>>();

		curCharacter = character;
		healthIcon = character;
		this.isPlayer = isPlayer;

		iconColor = isPlayer ? 'FF66FF33' : 'FFFF0000';
		trailColor = isPlayer ? "FF0026FF" : "FFAA0044";
		idleSuffix = "";
		curColor = 0xFFFFFFFF;
		
		antialiasing = true;

		for (i in ['flipMode', 'isCustom', 'stopIdle', 'skipDance', 'doMissThing', 'specialAnim', 'stunned']){
			Reflect.setProperty(this, i, false);		
			//i = false;
		}
	}
	
	public function loadCharacter(?character:String = "bf", ?isPlayer:Bool = false)
	{
		useAtlas = false;

		resetCharacterAttributes(character, isPlayer);

		if (PlayState.instance != null)
			noteSkin = PlayState.SONG.noteStyle;

		switch (curCharacter)
		{
			default:
				isCustom = true;
				isPsychPlayer = false;

				var characterPath:String = 'images/characters/jsons/' + curCharacter;
				var path:String = Paths.jsonNew(characterPath);
				
				#if MODS_ALLOWED
				if (FileSystem.exists(Paths.modFolders('characters/'+curCharacter+'.json')) || Assets.exists(Paths.modFolders('characters/'+curCharacter+'.json'))) {
					path = Paths.modFolders('characters/'+curCharacter+'.json');
				}
				#end
			
				if (!FileSystem.exists(path) && !Assets.exists(path))
				{
					trace('oh no missingno. Character '+curCharacter+" not found.");
					path = Paths.jsonNew('images/characters/jsons/' + DEFAULT_CHARACTER); //If a character couldn't be found, change to bf just to prevent a crash
					curCharacter = DEFAULT_CHARACTER;
				}

				var rawJson:Dynamic;

				rawJson =  (FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path));
				
				var json:CharacterFile = cast Json.parse(rawJson);

				if (json.noteSkin != null){
					noteSkin = json.noteSkin;
				}
				
				if (json.isPlayerChar){
					isPsychPlayer = json.isPlayerChar;
				}
					
				if ((noteSkin == "" || noteSkin == 'normal' || noteSkin == 'default') && PlayState.SONG != null)
					noteSkin = PlayState.SONG.noteStyle;	

				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}
				
				charPath = json.image + '.png'; //cuz we only use pngs anyway
				imageFile = json.image; //psych
				preloadImageFile = imageFile;
				spriteType = (json.spriteType != null ? json.spriteType.toUpperCase() : "SPARROW");

				loadCharacterGraphics();
				
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

				if (json.gameover_character != null){
					gameOverCharacter = json.gameover_character;
				}
				
				positionArray = ((!debugMode && isPlayer && json.playerposition != null) ? json.playerposition : json.position);
				playerPositionArray = (json.playerposition != null ?  json.playerposition : json.position);
				cameraPosition = (isPlayer && json.player_camera_position != null ? json.player_camera_position : json.camera_position);
				playerCameraPosition = (json.player_camera_position != null ? json.player_camera_position : json.camera_position);
				
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2){
					healthColorArray = json.healthbar_colors;
				}
					
				vocalsFile = json.vocals_file != null ? json.vocals_file : '';
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

						if (!useAtlas){
							if(animIndices != null && animIndices.length > 0) {
								animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
							}
							else
								animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}
						#if flxanimate
						else
						{
							animation.addByIndices(animAnim, "blank", generateIndicesAtPoint(0, animIndices.length, true), "", animFps, animLoop);
							atlasChar.anim.addByAnimIndices(animAnim, animIndices, animFps);
						}
						#end

						var offsets:Array<Int> = anim.offsets;
						var playerOffsets:Array<Int> = anim.playerOffsets;
					
						var swagOffsets:Array<Int> = offsets;

						if (!debugMode && isPlayer && playerOffsets != null && playerOffsets.length > 1){
							swagOffsets = playerOffsets;
						}

						if(swagOffsets != null && swagOffsets.length > 1) {
							addOffset(anim.anim, swagOffsets[0], swagOffsets[1]);
						}	
						
						if(playerOffsets != null && playerOffsets.length > 1) {
							addPlayerOffset(anim.anim, playerOffsets[0], playerOffsets[1]);
						}
					
					}
				} 
				else {
					quickAnimAdd('idle', 'BF idle dance');
				}

				(animOffsets.exists('danceRight') ? playAnim('danceRight') : playAnim('idle'));
		}

		if (atlasChar != null)
		{
			atlasChar.antialiasing = ClientPrefs.data.antialiasing;
			atlasChar.flipX = flipX;
			atlasChar.scale.set(jsonScale, jsonScale);
			atlasChar.showPivot = false;

			if (PlayState.instance != null && !states.editors.CharacterEditorState.inCharEditor){
				var leObj:FlxBasic = LuaUtils.getObjectDirectly((isPlayer ? "boyfriend" : "dad"));
				PlayState.instance.addObject(atlasChar);
			}

			atlasChar.anim.play('idle', true);
		}

		if(animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null)
			danceIdle = true;

		if(animation.getByName('singUPmiss') == null)
			doMissThing = true; //if for some reason you only have an up miss, why?

		originalFlipX = flipX;

		recalculateDanceIdle();
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
		if (atlasChar != null) atlasChar.update(elapsed);

		if (!debugMode && !isAnimationNull())
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed;
				if(heyTimer <= 0)
				{
					if(specialAnim && (getAnimationName() == 'hey' || getAnimationName() == 'cheer'))
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && isAnimationFinished())
			{
				specialAnim = false;
				dance();
			}
			
			if ((flipMode && isPlayer) || (!flipMode && !isPlayer))
			{
				if (getAnimationName().startsWith('sing')){
					holdTimer += elapsed;
				}
					
				if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001 / (PlayState.instance != null ? PlayState.instance.playbackRate : 1))
				{
					dance();
					holdTimer = 0;
				}
			}

			var name:String = getAnimationName();
			
			if(isAnimationFinished() && animOffsets.exists('$name-loop'))
				playAnim('$name-loop');
			
			if (curCharacter.startsWith('gf') && getAnimationName() == 'hairFall' && isAnimationFinished())
				playAnim('danceRight');
		}
	
		if (atlasChar != null){
			atlasChar.setPosition(x, y);
			atlasChar.flipX = flipX;
			atlasChar.alpha = alpha;

			if (!isAnimationNull()){
				atlasChar.anim.play(animation.curAnim.name, true, false, animation.curAnim.curFrame);
				atlasChar.anim.pause();
			}
		}

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return animation.curAnim == null;

	inline public function getAnimationName():String
	{
		var name:String = '';
		@:privateAccess
		if(!isAnimationNull()) name = animation.curAnim.name;
		return (name != null) ? name : '';
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return animation.curAnim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		animation.curAnim.finish();
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return animation.curAnim.paused;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		animation.curAnim.paused = value;

		return value;
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */

	public function dance()
	{
		if (!debugMode && !specialAnim && !stopIdle && !skipDance)
		{
			switch (curCharacter)
			{
				default:
					var daAlt:String = (isPlayer ? bfAltAnim : altAnim);

					if (danceIdle)
					{
						danced = !danced;
						playAnim((danced ? "danceRight" : "danceLeft") + daAlt + idleSuffix);
					}
					else
						playAnim("idle" + daAlt + idleSuffix);
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

			if (doMissThing){
				missed = true;
			}
		}

		if (animation.getByName(AnimName) == null) // if it's STILL null, just play idle, and if you REALLY messed up, it'll look in the xml for a valid anim
		{
			if(danceIdle && animation.getByName('danceRight') != null)
				AnimName = 'danceRight';
			else if (animation.getByName('idle') != null)
				AnimName = 'idle';
			else{
				if (FileSystem.exists(Paths.xmlNew('images/' + imageFile)))
				{
					var path:String = Paths.xmlNew('images/' + imageFile);
					quickAnimAdd(AnimName, CoolUtil.findFirstAnim((FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path))));
				}		
				else{
					quickAnimAdd(AnimName, CoolUtil.findFirstAnim(Assets.getText(Paths.xmlNew('images/bruhtf'))));
				}
			}	
		}

		animation.play(AnimName, Force, Reversed, Frame);

		if (missed){
			var realCurColor = curColor;
			color = CoolUtil.blendColors(curColor, 0xFFCFAFFF);
			curColor = realCurColor;
		}
		else if (color != curColor && doMissThing){
			color = curColor;
		}
			

		var daOffset = animOffsets.get(AnimName);

		if (debugMode && isPlayer)
			daOffset = animPlayerOffsets.get(AnimName);
		
		if (debugMode)
		{
			if ((animOffsets.exists(AnimName) && !isPlayer) || (animPlayerOffsets.exists(AnimName) && isPlayer))
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

	public function addPlayerOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animPlayerOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		addAnimationByPrefix(name, anim, 24, false);
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
		//rewrote it
		for (anim in animationsArray){
			if (anim.anim.contains("singRIGHT")){
				var animSplit:Array<String> = anim.anim.split('singRIGHT');

				if (animation.getByName('singRIGHT' + animSplit[1]) != null && animation.getByName('singLEFT' + animSplit[1]) != null)
				{
					var oldRight = animation.getByName('singRIGHT' + animSplit[1]).frames;
					animation.getByName('singRIGHT' + animSplit[1]).frames = animation.getByName('singLEFT' + animSplit[1]).frames;
					animation.getByName('singLEFT' + animSplit[1]).frames = oldRight;
				}
			}
		}
	}

	// Atlas support 
	public var useAtlas:Bool = false;
	public var atlasChar:FlxAnimate;

	public static function generateIndicesAtPoint(point:Int, amount:Int, ?none:Bool):Array<Int>
		{
			var returnArray:Array<Int> = [];
			for (i in 0...amount)
				{
					if (!none) returnArray.push((point - 1) + i);
					else returnArray.push(0);
				}
			return returnArray;
		}

	public var currentIndex:Int = 1;

	public function indicesContinueAmount(amount:Int):Array<Int>
	{
		var theArray:Array<Int> = generateIndicesAtPoint(currentIndex, amount);
		currentIndex += amount;
		return theArray;
	}

	override function set_color(Color:FlxColor):Int
	{
		curColor = Color;
		return super.set_color(Color);
	}

	public function playCommonAnims()
	{
		var commonAnims:Array<String> = ['idle', 'singLEFT', 'singRIGHT', 'singUP', 'singDOWN','singLEFT-miss', 'singRIGHT-miss', 'singUP-miss', 'singDOWN-miss', 'dodge', 'attack'];

		for (anim in commonAnims)
			this.playAnim(anim, true);
	}

	public override function destroy()
	{
		super.destroy();
		destroyAtlas();
	}
	
	public function destroyAtlas()
	{
		if (atlasChar != null)
			atlasChar = FlxDestroyUtil.destroy(atlasChar);
	}	

	public function loadCharacterGraphics() {
		#if flxanimate
		var animToFind:String = Paths.getPath('images/' + imageFile + '/Animation.json', TEXT, null, true);
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind)){
			useAtlas = true;
			preloadImageFile = preloadImageFile + "/spritemap";
	
			var spriteMapPath =  Paths.image(imageFile);
	
			// Assume it's spritemap1 if not spritemap
			if (!Assets.exists(spriteMapPath) && !FileSystem.exists(spriteMapPath) && !FileSystem.exists(Paths.modsImages(spriteMapPath))){
				preloadImageFile = preloadImageFile + "1";
			}
		}
		#end
	
		var imagePath = Paths.image(imageFile);
		
		if (!Paths.currentTrackedAssets.exists(preloadImageFile)){
			if (Assets.exists(imagePath) && !FileSystem.exists(imagePath) && !FileSystem.exists(Paths.modsImages(imagePath))) {
				Paths.cacheImage(preloadImageFile, 'shared', false, !noAntialiasing);
			} else {
				Paths.cacheImage(preloadImageFile, 'preload', false, !noAntialiasing);
			}
		}
	
		if (!useAtlas) {	
			frames = Paths.getAtlasFromData(imageFile, spriteType);
		} else {
			frames = Paths.getAtlasFromData("characters/blank", "SPARROW");
	
			#if flxanimate
			var characterImagePath = Paths.getPath("images/" + imageFile, TEXT, null, true);
			atlasChar = new FlxAnimate(x, y, characterImagePath);
			#end
		}			
	}
	
}
