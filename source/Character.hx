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
		noteSkin = PlayState.SONG.noteStyle;
		
		//should now only be using the default psych json stuff

		switch (curCharacter)
		{
			/*case 'gf-special' | 'gf-demon' | 'gf-bw' | 'gf-hex' | 'gf-pico' | 'gf-cassandra-bw' | 'gf-alya-bw' | 'gf-pico-bw' | 'gf-monika-bw' 
			| 'madgf-christmas'	| 'gf-arcade' | 'gf-b3' | 'gf-aloe' | 'gf-pelo-spooky' | 'gf-bf' | 'gf-bf-bw' | 'gf-demona' | 'gf-bw2' | 'gf-mii' | 'gfHalloween' | 'gf-kaguya':
				// GIRLFRIEND CODE
				switch (curCharacter)
				{
					case 'gf-demon': frames = getCharPath('characters/GF_demon_assets');							
					case 'gf-arcade': frames = getCharPath('characters/GF_arcade_assets');					
					case 'gf-special': frames = getCharPath('characters/GF_Special');																	
					case 'madgf-christmas': frames = getCharPath('characters/madgfChristmas');							
					case 'gf-hex': frames = getCharPath('characters/GF_Hex_assets');				
					case 'gf-pico': frames = getCharPath('characters/GF_Pico_assets');				
					case 'gf-cassandra-bw': frames = getCharPath('characters/bw/Cassandra_GF_assets');			
					case 'gf-alya-bw': frames = getCharPath('characters/bw/GF_Alya_assets');					
					case 'gf-pico-bw': frames = getCharPath('characters/bw/GF_Pico_assets');					
					case 'gf-monika-bw': frames = getCharPath('characters/bw/Monika_GF_assets');					
					case 'gf-b3': frames = getCharPath('characters/b3/GF_assets');			
					case 'gf-aloe': frames = getCharPath('characters/GF_Aloe_assets');			
					case 'gf-pelo-spooky': frames = getCharPath('characters/GF_assets_pelo_spooky');
					case 'gf-bf': frames = getCharPath('characters/GF_BF_assets');	
					case 'gf-bf-bw': frames = getCharPath('characters/bw/GF_BF_assets');	
					case 'gf-demona': frames = getCharPath('characters/demona');	
					case 'gfHalloween': frames = getCharPath('characters/GF_assets_halloween');		
					case 'gf-kaguya': frames = getCharPath('characters/Kaguya_GF_assets');	
					case 'gf-mii': frames = getCharPath('characters/GF_MII_assets');			
					case 'gf-bw' | 'gf-bw2': 
						if (curCharacter == 'gf-bw2') pre = '_2';
						frames = getCharPath('characters/bw/GF_assets'+pre);	
				}

				addAnimationByPrefix('cheer', 'GF Cheer', 24, false);
				addAnimationByPrefix('singLEFT', 'GF left note', 24, false);
				addAnimationByPrefix('singRIGHT', 'GF Right Note', 24, false);
				addAnimationByPrefix('singUP', 'GF Up Note', 24, false);
				addAnimationByPrefix('singDOWN', 'GF Down Note', 24, false);
				addAnimationByIndices('sad', 'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
				addAnimationByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				addAnimationByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				addAnimationByIndices('hairBlow', "GF Dancing Beat Hair blowing", [0, 1, 2, 3], "", 24);
				addAnimationByIndices('hairFall', "GF Dancing Beat Hair Landing", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);
				addAnimationByPrefix('scared', 'GF FEAR', 24);
				addAnimationByPrefix('transform', 'GF Transform', 24, false);

				loadOffsetFile('gf');	

				playAnim('danceRight');

			case 'gf-tankman-pixel' | 'gf-pixel-mario' | 'amy-pixel-mario' | 'piper-pixel-mario' | 'piper-pixeld2' | 'gf-pixel-neon' | 'gf-playtime' | 'nogf-pixel' | 'gf-edgeworth-pixel' | 'gf-flowey'
			| 'gf-tea-pixel':
				switch (curCharacter)
				{
					case 'gf-tankman-pixel':
						frames = getCharPath('characters/gfTankmanPixel');
					case 'gf-pixel-mario':
						frames = getCharPath('characters/gfPixelMario');
					case 'amy-pixel-mario':
						frames = getCharPath('characters/amyPixelMario');
					case 'piper-pixel-mario':
						frames = getCharPath('characters/piperPixelMario');
					case 'piper-pixeld2':
						frames = getCharPath('characters/piperPixeld2');
					case 'gf-pixel-neon':
						frames = getCharPath('characters/gfPixelNeon');
					case 'gf-playtime':
						frames = getCharPath('characters/gfPlaytime');
					case 'nogf-pixel':
						frames = getCharPath('characters/nogfPixel');
					case 'gf-edgeworth-pixel':
						frames = getCharPath('characters/gfEdgeworthPixel');
					case 'gf-tea-pixel':
						frames = getCharPath('characters/gfTeaPixel');
					case 'gf-flowey':
						frames = getCharPath('characters/gfFlowey');
				}
				
				
				addAnimationByIndices('singUP', 'GF IDLE', [2], "", 24, false);
				addAnimationByIndices('danceLeft', 'GF IDLE', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				addAnimationByIndices('danceRight', 'GF IDLE', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

				loadOffsetFile('no-gf');

				playAnim('danceRight');

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();
				antialiasing = false;

			case 'gf-edd':
				frames = getCharPath('tord/gfEdd');
				
				addAnimationByIndices('singUP', 'GF IDLE', [2], "", 24, false);
				addAnimationByIndices('danceLeft', 'GF IDLE', [12, 0, 1, 2, 3, 4, 5], "", 24, false);
				addAnimationByIndices('danceRight', 'GF IDLE', [6, 7, 8, 9, 10, 11], "", 24, false);

				loadOffsetFile('no-gf');

				playAnim('danceRight');

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();
				antialiasing = false;

			case 'gf-pixeld4' | 'gf-pixeld4BSide':
				switch (curCharacter)
				{
					case 'gf-pixeld4':
						frames = getCharPath('characters/gfPixeld4');
					case 'gf-pixeld4BSide':
						frames = getCharPath('characters/gfPixeld4BSide');
				}
				
				addAnimationByIndices('singUP', 'GF IDLE', [2], "", 24, false);
				addAnimationByPrefix('switch', 'GF SWITCH', 24, false);
				addAnimationByIndices('danceLeft', 'GF IDLE', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				addAnimationByIndices('danceRight', 'GF IDLE', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

				loadOffsetFile('no-gf');

				playAnim('danceRight');

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();
				antialiasing = false;

			case 'dad-mad':
				// DAD ANIMATION LOADING CODE
				frames = getCharPath('characters/DADDY_DEAREST_D3');
				
				addAnimationByPrefix('idle', 'Dad idle dance', 24, false);
				addAnimationByPrefix('singUP', 'Dad Sing Note UP0', 24, false);
				addAnimationByPrefix('singRIGHT', 'Dad Sing Note RIGHT0', 24, false);
				addAnimationByPrefix('singDOWN', 'Dad Sing Note DOWN0', 24, false);
				addAnimationByPrefix('singLEFT', 'Dad Sing Note LEFT0', 24, false);

				if (isPlayer)
				{
					addOffset('idle');
					addOffset("singUP", -12, 50);
					addOffset("singRIGHT", -40, 10);
					addOffset("singLEFT", 40, 27);
					addOffset("singDOWN", 40, -30);
				}
				else
				{
					addOffset('idle');
					addOffset("singUP", -1, 52);
					addOffset("singRIGHT", -1, 13);
					addOffset("singLEFT", 61, 20);
					addOffset("singDOWN", 5, -29);
				}

				playAnim('idle');

			case 'dad-sad'| 'dad-sad-pixel':
				switch (curCharacter)
				{
					case 'dad-sad':
						frames = getCharPath('characters/DADDY_DEAREST_D3_Sad');
					case 'dad-sad-pixel':
						frames = getCharPath('characters/DADDY_DEAREST_D3_Sad_Pixel');
				}
					
				addAnimationByPrefix('idle', 'Dad idle dance', 24, false);
				
				addAnimationByPrefix('singUP', 'Dad Sing Note UP0', 24, false);
				addAnimationByPrefix('singRIGHT', 'Dad Sing Note RIGHT0', 24, false);
				addAnimationByPrefix('singDOWN', 'Dad Sing Note DOWN0', 24, false);
				addAnimationByPrefix('singLEFT', 'Dad Sing Note LEFT0', 24, false);
				
				if (curCharacter == 'dad-sad-pixel')
				{
					addAnimationByPrefix('idle-alt', 'Dad idle dance', 24, false);
					addAnimationByPrefix('singDOWN-alt', 'Dad Alt Sing Note DOWN0', 24, false);
				}

				addOffset('idle');

				if (isPlayer)
				{				
					addOffset("singUP", -12, 50);
					addOffset("singRIGHT", -40, 10);
					addOffset("singLEFT", 40, 27);
					addOffset("singDOWN", 40, -30);
				}
				else
				{
					addOffset('idle');
					addOffset("singUP", 1, 58);
					addOffset("singRIGHT", -4, 38);
					addOffset("singLEFT", 42, 19);
					addOffset("singDOWN", -1, -20);
					if (curCharacter == 'dad-sad-pixel')
						addOffset("singDOWN-alt", -1, -20);	
				}

				playAnim('idle');

			case 'hd-senpai-giddy-old':
				switch (curCharacter)
				{
					case 'hd-senpai-giddy-old':
						frames = getCharPath('characters/HD_SENPAI_GIDDY');
						iconColor = 'FFFFAA6F';
				}
							
				addAnimationByPrefix('idle', 'Dad idle dance', 24, false);
				addAnimationByPrefix('singUP', 'Dad Sing Note UP', 24, false);
				addAnimationByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24, false);
				addAnimationByPrefix('singDOWN', 'Dad Sing Note DOWN', 24, false);
				addAnimationByPrefix('singLEFT', 'Dad Sing Note LEFT', 24, false);
				addAnimationByPrefix('singDOWN-alt', 'Dad Die', 24, false);
				addAnimationByPrefix('singLEFT-alt', 'Dad UGH', 24, false);

				loadOffsetFile('hd-senpai-giddy');

				playAnim('idle');

			case 'hd-senpai-angry-old':
				switch (curCharacter)
				{
					case 'hd-senpai-angry-old':
						frames = getCharPath('characters/HD_SENPAI_ANGRY');
						iconColor = 'FFFFAA6F';
						healthIcon = 'hd-senpai';
				}
				addAnimationByPrefix('idle', 'Dad idle dance', 24, false);
				addAnimationByPrefix('singUP', 'Dad Sing Note UP', 24, false);
				addAnimationByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24, false);
				addAnimationByPrefix('singDOWN', 'Dad Sing Note DOWN', 24, false);
				addAnimationByPrefix('singLEFT', 'Dad Sing Note LEFT', 24, false);

				loadOffsetFile('hd-senpai-angry');	

				playAnim('idle');

			case 'hd-monika' | 'hd-monika-angry':
				switch (curCharacter)
				{
					case 'hd-monika':
						frames = getCharPath('characters/HD_MONIKA');
					case 'hd-monika-angry':
						frames = getCharPath('characters/HD_MONIKA_ANGRY');
				}
				iconColor = 'FFFFB8E3';
				addAnimationByPrefix('idle', 'Dad idle dance', 24, false);
				addAnimationByPrefix('singUP', 'Dad Sing Note UP', 24, false);
				addAnimationByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24, false);
				addAnimationByPrefix('singDOWN', 'Dad Sing Note DOWN', 24, false);
				addAnimationByPrefix('singLEFT', 'Dad Sing Note LEFT', 24, false);

				loadOffsetFile('hd-monika');

				playAnim('idle');

			case 'bf-senpai-worried' | 'bf-hd-senpai-angry' | 'bf-hd-senpai-giddy' | 'bf-hd-senpai-angry-night' | 'bf-hd-senpai-dark':
				switch (curCharacter)
				{	
					case 'bf-hd-senpai-dark': 
						frames = getCharPath('characters/BF_HD_SENPAI_DARK');
						healthIcon = 'hd-senpai-dark';
					case 'bf-hd-senpai-angry': 
						frames = getCharPath('characters/BF_HD_SENPAI_ANGRY');
						healthIcon = 'hd-senpai';
					case 'bf-hd-senpai-angry-night': 
						frames = getCharPath('characters/BF_HD_SENPAI_ANGRY_NIGHT');
						healthIcon = 'hd-senpai';
					case 'bf-hd-senpai-giddy': 
						frames = getCharPath('characters/BF_HD_SENPAI_GIDDY');
						healthIcon = 'hd-senpai-giddy';
					case 'bf-senpai-worried': 
						frames = getCharPath('characters/HD_SENPAI_WORRIED');	
						healthIcon = 'hd-senpai-worried';
				}
				
				iconColor = 'FFFFAA6F';
				addAnimationByPrefix('idle', 'Dad idle dance', 24, false);
				addAnimationByPrefix('singUP', 'Dad Sing Note UP', 24, false);
				addAnimationByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24, false);
				addAnimationByPrefix('singDOWN', 'Dad Sing Note DOWN', 24, false);
				addAnimationByPrefix('singLEFT', 'Dad Sing Note LEFT', 24, false);

				loadOffsetFile('bf-hd-senpai-angry');

				playAnim('idle');

				flipX = true;

			case 'spooky-pixel':
				frames = getCharPath('characters/spooky_pixel');
				iconColor = 'FFD57E00';
				addAnimationByPrefix('singUP', 'spooky UP NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'spooky DOWN note', 24, false);
				addAnimationByPrefix('singLEFT', 'note sing left', 24, false);
				addAnimationByPrefix('singRIGHT', 'spooky sing right', 24, false);
				addAnimationByIndices('danceLeft', 'spooky dance idle', [0, 2, 6], "", 12, false);
				addAnimationByIndices('danceRight', 'spooky dance idle', [8, 10, 12, 14], "", 12, false);

				loadOffsetFile(curCharacter);

				playAnim('danceRight');

				antialiasing = false;*/

			case 'sarvente-transform': //this one's gotta stay for now since it uses textureatlas
				frames = Paths.getTextureAtlas('sacredmass/churchgospel/pegMePlease');
				healthIcon = 'sarvente-lucifer';
				iconColor = 'FFDA317D';
				
				addAnimationByPrefix('idle', 'SarvTransAnim', 24, false);
				addAnimationByPrefix('transform', 'SarvTransAnim', 24, false);
				addAnimationByPrefix('singUP', 'SarvTransAnim', 24, false);
				addAnimationByPrefix('singDOWN', 'SarvTransAnim', 24, false);
				addAnimationByPrefix('singLEFT', 'SarvTransAnim', 24, false);
				addAnimationByPrefix('singRIGHT', 'SarvTransAnim', 24, false);

				loadOffsetFile('no');

			/*case 'bf-pump' | 'bf-ex-night' | 'bf-ghost' | 'bf-b3' | 'bf-frisk' | 'bf-kitty' 
			| 'bf-sticky-scream' | 'bfHalloween' | 'bf-spongebob' | 'bf-jabibi'
			| 'bf-cryingchild' | 'bf-frisk-bw':
				switch (curCharacter)
				{				
					case 'bf-pump':
						frames = getCharPath('characters/PUMP');
						iconColor = 'FFD57E00';
					case 'bf-ex-night':
						frames = getCharPath('characters/BoyFriend_Assets_EX_night', 'shared');
						noteSkin = 'bf-b&b';
						iconColor = 'FF0EAEFE';
					case 'bf-ghost':
						frames = getCharPath('characters/bfghost');
						noteSkin = 'normal';
						healthIcon = 'bf';
						iconColor = 'FF0EAEFE';
					case 'bf-b3':
						frames = getCharPath('characters/b3/BOYFRIEND');
						iconColor = 'FF66FF33';
					case 'bf-frisk' | 'bf-frisk-bw':
						if (curCharacter == 'bf-frisk-bw') pre = 'bw/';
						frames = getCharPath('characters/'+pre+'frisk');
						iconColor = 'FF5691D8';
					case 'bf-kitty':
						frames = getCharPath('characters/KITTY_KEAREST');
						iconColor = 'FFA30016';
					case 'bf-sticky-scream':
						frames = getCharPath('characters/STICKY');
						iconColor = 'FFFFF29E';
						healthIcon = 'bf-sticky';
					case 'bfHalloween':
						frames = getCharPath('characters/BOYFRIEND_halloween');
						iconColor = 'FF0EAEFE';
						healthIcon = 'bf';
					case 'bf-spongebob':
						frames = getCharPath('characters/SPONGEBOB');
						iconColor = 'FFE9D752';
					case 'bf-jabibi':
						frames = getCharPath('characters/jabibi');
						iconColor = 'FFFF77F4';
					case 'bf-cryingchild':
						frames = getCharPath('characters/CRYINGCHILD');
						iconColor = 'FFFFFFFF';
				}

				addAnimationByPrefix('idle', 'BF idle dance', 24, false);
				addAnimationByPrefix('singUP', 'BF NOTE UP0', 24, false);
				addAnimationByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
				addAnimationByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
				addAnimationByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
				addAnimationByPrefix('hey', 'BF HEY', 24, false);

				if (curCharacter != 'bf-sticky')
					addAnimationByPrefix('singUP-alt', 'BF HEY', 24, false);

				addAnimationByPrefix('firstDeath', "BF dies", 24, false);
				addAnimationByPrefix('deathLoop', "BF Dead Loop", 24, true);
				addAnimationByPrefix('deathConfirm', "BF Dead confirm", 24, false);

				addAnimationByPrefix('scared', 'BF idle shaking', 24);
				addAnimationByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
				addAnimationByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);	
				addAnimationByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
				addAnimationByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);


				if (curCharacter == 'bf-sticky-scream')
				{
					addAnimationByPrefix('singUP-alt', 'boyfriend dodge', 24, false);
					addAnimationByPrefix('singLEFT-alt', 'boyfriend dodge', 24, false);
					addAnimationByPrefix('singDOWN-alt', 'boyfriend dodge', 24, false);
					addAnimationByPrefix('singRIGHT-alt', 'boyfriend dodge', 24, false);
				}

				var loadSelfOffsets:Array<String> = ['bf-b3', 'bf-nene', 'bf-nene-scream', 'bf-sans-new', 'bfHalloween', 'bf-six', 'bf-shirogane'];

				if (loadSelfOffsets.contains(curCharacter)) 
					loadOffsetFile(curCharacter);
				else if (curCharacter == 'bf-sticky-scream')
					loadOffsetFile('bf-sticky');
				else
					loadOffsetFile('bf');
				
				playAnim('idle');

				flipX = true;

			case 'bf-demoncesar-bw' | 'bf-demoncesar-trollge' | 'bf-demoncesar-cas':
				switch (curCharacter)
				{
					case 'bf-demoncesar':
						frames = getCharPath('characters/demonCesar');
						iconColor = 'FFE353C8';
					case 'bf-demoncesar-bw':
						frames = getCharPath('characters/bw/demonCesar');
						iconColor = 'FFE1E1E1';
					case 'bf-demoncesar-trollge':
						frames = getCharPath('characters/demonCesar_trollge');
						iconColor = 'FFB76FA9';
					case 'bf-demoncesar-cas':
						frames = getCharPath('characters/casDEMON');
						iconColor = 'FFE353C8';	
						healthIcon = 'bf-demoncesar';					
				}
				
				if (curCharacter.contains('cas'))
					noteSkin = 'fever';
				else
				{
					switch (PlayState.curStage)
					{
						case 'takiStage':
							noteSkin = 'taki';
						case 'ripdiner':
							noteSkin = 'party-crasher';
						default:
							noteSkin = PlayState.SONG.noteStyle;						
					}
				}	

				addAnimationByPrefix('idle', 'BF idle dance', 24, false);
				addAnimationByPrefix('singUP', 'BF NOTE UP0', 24, false);
				addAnimationByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
				addAnimationByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
				addAnimationByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
				addAnimationByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
				addAnimationByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
				addAnimationByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
				addAnimationByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
				addAnimationByPrefix('hey', 'BF HEY', 24, false);
				addAnimationByPrefix('scared', 'BF idle shaking', 24);

				if (!curCharacter.contains('cas'))
				{
					addAnimationByPrefix('dodge', 'boyfriend dodge', 24, false);
					loadOffsetFile('bf-demoncesar');
				}
					
				if (curCharacter.contains('cas'))
				{
					addAnimationByPrefix('firstDeath', "BF dies", 24, false);
					addAnimationByPrefix('deathLoop', "BF Dead Loop", 24, true);
					addAnimationByPrefix('deathConfirm', "BF Dead confirm", 24, false);
					loadOffsetFile(curCharacter);
				}

				playAnim('idle');

				flipX = true;

			case 'bf-pixel-neon' | 'bf-senpai-pixel-angry' | 'bf-senpai-pixel' | 'bf-wright-pixel' | 'bf-pico-pixel' | 'bf-rico-pixel' | 'bf-sonic-pixel' 
			| 'bf-tom-pixel' | 'bf-sans-pixel' | 'bf-kapi-pixel' | 'bf-demoncesar-pixel' | 'bf-sky-pixel' | 'bf-glitch-pixel':
				switch (curCharacter)
				{
					case 'bf-kapi-pixel':
						frames = getCharPath('characters/bf-kapiPixel');
						iconColor = 'FF3483E3';
					case 'bf-pixel-neon':
						frames = getCharPath('characters/bfPixelNeon');
						iconColor = 'FF4674EE';
						noteSkin = 'neon';
					case 'bf-senpai-pixel-angry':
						frames = getCharPath('characters/bfSenpaiPixelangry');
						iconColor = 'FFFFAA6F';
						noteSkin = 'pixel';
						healthIcon = 'senpai-angry';
					case 'bf-senpai-pixel':
						frames = getCharPath('characters/bfSenpaiPixel');
						iconColor = 'FFFFAA6F';
						healthIcon = 'senpai';
					case 'bf-wright-pixel':
						frames = getCharPath('characters/bf-wrightPixel');
						iconColor = 'FF2D415C';
					case 'bf-pico-pixel':
						frames = getCharPath('characters/bf-picoPixel');
						iconColor = 'FFB7D855';
					case 'bf-rico-pixel':
						frames = getCharPath('characters/bf-ricoPixel');
						iconColor = 'FF7B59E5';
					case 'bf-sonic-pixel':
						frames = getCharPath('characters/bf-sonicPixel');
						iconColor = 'FF7BD6F6';
					case 'bf-tom-pixel':
						frames = getCharPath('characters/bf-tomPixel');
						iconColor = 'FF265D86';
					case 'bf-sans-pixel':
						frames = getCharPath('characters/bf-sansPixel');
						iconColor = 'FF7484E5';
					case 'bf-demoncesar-pixel':
						frames = getCharPath('characters/demonCesarPixel');
						iconColor = 'FFE353C8';
					case 'bf-sky-pixel':
						frames = getCharPath('characters/bf-skyPixel');
						iconColor = 'FFE353C8';
					case 'bf-glitch-pixel':
						frames = getCharPath('characters/bfGlitch');
						iconColor = 'FF32304C';
					default:
						frames = getCharPath('characters/bfPixel');
						iconColor = 'FF0EAEFE';
				}
				
				if (curCharacter == 'bf-sky-pixel')
				{
					addAnimationByIndices('danceLeft', 'BF IDLE', [0, 2, 4], "", 5, false);
					addAnimationByIndices('danceRight', 'BF IDLE', [6, 8], "", 5, false);
					addOffset('danceLeft');
					addOffset('danceRight');
				}	

				addAnimationByPrefix('idle', 'BF IDLE', 24, false);					
				addAnimationByPrefix('singUP', 'BF UP NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'BF DOWN NOTE', 24, false);
				addAnimationByPrefix('singUPmiss', 'BF UP MISS', 24, false);
				addAnimationByPrefix('singDOWNmiss', 'BF DOWN MISS', 24, false);
				addAnimationByPrefix('singLEFT', 'BF LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'BF RIGHT NOTE', 24, false);
				addAnimationByPrefix('singLEFTmiss', 'BF LEFT MISS', 24, false);
				addAnimationByPrefix('singRIGHTmiss', 'BF RIGHT MISS', 24, false);
		
				loadOffsetFile('no');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				if (curCharacter == 'bf-sky-pixel')
					playAnim('danceLeft');
				else
					playAnim('idle');

				width -= 100;
				height -= 100;

				antialiasing = false;

				flipX = true;

			case 'bf-tankman-pixel-dead' | 'bf-pico-pixel-dead' | 'bf-rico-pixel-dead' | 'bf-sans-pixel-dead' | 'bf-gf-pixel-dead' | 'bf-sonic-pixel-dead' 
			| 'bf-tom-pixel-dead' | 'bf-wright-pixel-dead' | 'bf-demoncesar-pixel-dead':
				var name:String = 'bf';
				name = curCharacter.substr(0, curCharacter.length - 11);
				frames = getCharPath('characters/'+name+'PixelsDEAD');
				
				addAnimationByPrefix('singUP', "BF Dies pixel", 24, false);
				addAnimationByPrefix('firstDeath', "BF Dies pixel", 24, false);
				addAnimationByPrefix('deathLoop', "Retry Loop", 24, true);
				addAnimationByPrefix('deathConfirm', "RETRY CONFIRM", 24, false);
				animation.play('firstDeath');

				addOffset('firstDeath');
				addOffset('deathLoop', -37);
				addOffset('deathConfirm', -37);
				playAnim('firstDeath');
				// pixel bullshit
				setGraphicSize(Std.int(width * 6));
				updateHitbox();
				antialiasing = false;
				flipX = true;

			case 'lane-pixel':
				frames = getCharPath('characters/Lane_Pixel_assets');
				iconColor = "FF1F7EFF";
				addAnimationByPrefix('idle', 'Lane Pixel Idle', 24, false);
				addAnimationByPrefix('singUP', 'Lane Pixel Up', 24, false);
				addAnimationByPrefix('singDOWN', 'Lane Pixel Down', 24, false);
				addAnimationByPrefix('singLEFT', 'Lane Pixel Left', 24, false);
				addAnimationByPrefix('singRIGHT', 'Lane Pixel Right', 24, false);

				loadOffsetFile(curCharacter);

				setGraphicSize(Std.int(width * 5));
				updateHitbox();

				playAnim('idle');

				antialiasing = false;

			case 'monika-finale':
				frames = getCharPath('characters/Monika_Finale');
				iconColor = 'FFFFB8E3';
				addAnimationByPrefix('idle', 'MONIKA IDLE', 24, false);
				addAnimationByPrefix('singUP', 'MONIKA UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT', 'MONIKA LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'MONIKA RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'MONIKA DOWN NOTE', 24, false);

				addAnimationByPrefix('singUP-alt', 'MONIKA UP GLITCH', 24, false);
				addAnimationByPrefix('singLEFT-alt', 'MONIKA LEFT GLITCH', 24, false);
				addAnimationByPrefix('singRIGHT-alt', 'MONIKA RIGHT GLITCH', 24, false);
				addAnimationByPrefix('singDOWN-alt', 'MONIKA DOWN GLITCH', 24, false);

				loadOffsetFile(curCharacter);

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;

			case 'bf-botan-pixel':
				frames = getCharPath('characters/bf-botanPixel');
				iconColor = 'FF7DA8C5';
				addAnimationByPrefix('idle', 'Pico Pixel Idle', 24, false);
				addAnimationByPrefix('singUP', 'Pico Pixel Up0', 24, false);
				addAnimationByPrefix('singDOWN', 'Pico Pixel Down0', 24, false);
				addAnimationByPrefix('singUPmiss', 'Pico Pixel Up Miss', 24, false);
				addAnimationByPrefix('singDOWNmiss', 'Pico Pixel Down Miss', 24, false);
				addAnimationByPrefix('singLEFT', 'Pico Pixel Left0', 24, false);
				addAnimationByPrefix('singRIGHT', 'Pico Pixel Right0', 24, false);			
				addAnimationByPrefix('singLEFTmiss', 'Pico Pixel Left Miss', 24, false);
				addAnimationByPrefix('singRIGHTmiss', 'Pico Pixel Right Miss', 24, false);
				
				loadOffsetFile(curCharacter);

				setGraphicSize(Std.int(width * 4.5));
				updateHitbox();

				playAnim('idle');

				antialiasing = false;

				flipX = true;

			case 'bf-whitty-pixel':
				frames = getCharPath('characters/whitty-pixel');
				iconColor = 'FF1D1E35';
				addAnimationByPrefix('idle', 'Whitty Pixel Idle', 24, false);
				addAnimationByPrefix('singUP', 'Whitty Pixel Up0', 24, false);
				addAnimationByPrefix('singDOWN', 'Whitty Pixel Down0', 24, false);
				addAnimationByPrefix('singLEFT', 'Whitty Pixel Left0', 24, false);
				addAnimationByPrefix('singRIGHT', 'Whitty Pixel Right0', 24, false);

				loadOffsetFile(curCharacter);

				setGraphicSize(Std.int(width * 4.5));
				updateHitbox();

				playAnim('idle');

				antialiasing = false;

				flipX = true;

			case 'bf-gf-pixel':
				frames = getCharPath('characters/bf-gfPixel');
				iconColor = 'FF9A1652';
				addAnimationByPrefix('idle', 'BF IDLE', 24, false);
				addAnimationByPrefix('singUP', 'BF UP NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'BF DOWN NOTE', 24, false);
				addAnimationByPrefix('singUPmiss', 'BF UP MISS', 24, false);
				addAnimationByPrefix('singLEFTmiss', 'BF LEFT MISS', 24, false);
				addAnimationByPrefix('singRIGHTmiss', 'BF RIGHT MISS', 24, false);
				addAnimationByPrefix('singDOWNmiss', 'BF DOWN MISS', 24, false);
				addAnimationByPrefix('singLEFT', 'BF LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'BF RIGHT NOTE', 24, false);
				addAnimationByPrefix('singLEFTmiss', 'BF LEFT MISS', 24, false);
				addAnimationByPrefix('singRIGHTmiss', 'BF RIGHT MISS', 24, false);

				loadOffsetFile('no');

				if (!isPlayer)
				{
					addOffset("singRIGHT", -30, 0);
					addOffset("singLEFT", 30, 0);
				}
				else
				{
					addOffset("singRIGHT", -30, 0);
					addOffset("singLEFT", 30, 0);
				}

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				playAnim('idle');

				width -= 100;
				height -= 100;

				antialiasing = false;

				flipX = true;

			case 'bf-tankman-pixel' | 'bf-tankman-pixel-happy':
				frames = getCharPath('characters/bf-tankmanPixel');
				iconColor = 'FF2C2D41';
				healthIcon = 'bf-tankman-pixel';
		
				addAnimationByPrefix('idle', 'BF IDLE', 24, false);
				addAnimationByPrefix('idle-alt', 'BF ALT IDLE', 24, false);
				addAnimationByPrefix('singUP', 'BF UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT', 'BF LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'BF RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'BF DOWN NOTE', 24, false);
				addAnimationByPrefix('singUP-alt', 'BF UGH', 24, false);
				addAnimationByPrefix('singUPmiss', 'BF UP MISS', 24, false);
				addAnimationByPrefix('singLEFTmiss', 'BF LEFT MISS', 24, false);
				addAnimationByPrefix('singRIGHTmiss', 'BF RIGHT MISS', 24, false);
				addAnimationByPrefix('singDOWNmiss', 'BF DOWN MISS', 24, false);

				if (curCharacter == 'bf-tankman-pixel-happy')
					addAnimationByPrefix('idle-alt', 'BF ALT IDLE', 24, false);

				loadOffsetFile('bf-tankman-pixel');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				playAnim('idle-alt');

				width -= 100;
				height -= 100;

				antialiasing = false;

				flipX = true;

			case 'bf-pixeld3' | 'bf-pixeld3BSide':
				var normShit:String = "";
				var altShit:String = "";

				switch (curCharacter)
				{
					case 'bf-pixeld3':
						frames = getCharPath('characters/bfPixeld4');
						normShit = "";
						altShit = " ALT";
						
					case 'bf-pixeld3BSide':
						frames = getCharPath('characters/bfPixeld4');
						normShit = " ALT";
						altShit = "";
				}
				
				addAnimationByPrefix('idle', 'BF'+normShit+' IDLE', 24, false);
				addAnimationByPrefix('idle-alt', 'BF'+altShit+' IDLE', 24, false);
				addAnimationByPrefix('singUP', 'BF'+normShit+' UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT', 'BF'+normShit+' LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'BF'+normShit+' RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'BF'+normShit+' DOWN NOTE', 24, false);		
				addAnimationByPrefix('singUP-alt', 'BF'+altShit+' UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT-alt', 'BF'+altShit+' LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT-alt', 'BF'+altShit+' RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN-alt', 'BF'+altShit+' DOWN NOTE', 24, false);
				addAnimationByPrefix('singUPmiss', 'BF UP MISS', 24, false);
				addAnimationByPrefix('singLEFTmiss', 'BF LEFT MISS', 24, false);
				addAnimationByPrefix('singRIGHTmiss', 'BF RIGHT MISS', 24, false);
				addAnimationByPrefix('singDOWNmiss', 'BF DOWN MISS', 24, false);

				loadOffsetFile('no');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				playAnim('idle');

				width -= 100;
				height -= 100;

				antialiasing = false;

				flipX = true;

			case 'bf-senpai-tankman-dead' | 'bf-senpai-pixel-dead':
				switch (curCharacter)
				{
					case 'bf-senpai-tankman-dead':
						frames = getCharPath('characters/bf-senpai-tankman-dead');
					case 'bf-senpai-pixel-dead':
						frames = getCharPath('characters/bf-senpai-pixel-dead');
				}
				
				addAnimationByPrefix('singUP', "BF Dies pixel", 24, false);
				addAnimationByPrefix('firstDeath', "BF Dies pixel", 24, false);
				addAnimationByPrefix('deathLoop', "senpai retry", 24, true);
				addAnimationByPrefix('deathConfirm', "RETRY CONFIRM", 24, false);

				addOffset('firstDeath', -50, 150);
				addOffset('deathLoop', -50, 150);
				addOffset('deathConfirm', -50, 150);
	
				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				flipX = true;
	
				playAnim('idle');
	
				antialiasing = false;

			case 'neon' | 'miku-pixel' | 'monster-pixel' | 'monika' | 'colt' | 'neon-bigger' | 'glitch' | 'josuke':
				switch (curCharacter)
				{
					case 'glitch':
						frames = getCharPath('characters/glitch');
						iconColor = 'FF0DA554';
						healthIcon = 'glitch';
					case 'neon' | 'neon-bigger':
						frames = getCharPath('characters/neon');
						iconColor = "FF06D22A";
						noteSkin = 'neon';
						healthIcon = 'neon';
					case 'miku-pixel':
						frames = getCharPath('characters/bitmiku');
						iconColor = 'FF32CDCC';
					case 'monster-pixel':
						frames = getCharPath('characters/monsterPixel');
						iconColor = 'FFF3FF6E';
						if (PlayState.SONG.song.toLowerCase() == 'dead-pixel')
							healthIcon = 'monster-pixel-look';
						else
							healthIcon = 'monster-pixel';
					case 'monika':
						frames = getCharPath('characters/monika');
						iconColor = 'FFFFB8E3';
					case 'colt':
						frames = getCharPath('characters/colt');
						iconColor = 'FF584190';
					case 'josuke':
						frames = getCharPath('characters/josuke');
						iconColor = 'FFED7F98';

				}
				addAnimationByPrefix('idle', 'Senpai Idle', 24, false);
				addAnimationByPrefix('singUP', 'SENPAI UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT', 'SENPAI LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'SENPAI RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'SENPAI DOWN NOTE', 24, false);

				var loadSelfOffsets = ['senpai', 'monika', 'colt', 'neon', 'neon-bigger', 'miku-pixel'];

				if (loadSelfOffsets.contains(curCharacter))
				{
					if (curCharacter == 'senpai')
						loadOffsetFile('senpai-angry');
					else
						loadOffsetFile(curCharacter);
				}
					
				else
					loadOffsetFile('senpai');
					
				playAnim('idle');

				if (curCharacter == 'neon')
					setGraphicSize(Std.int(width * 5));
				else
					setGraphicSize(Std.int(width * 6));
				
				updateHitbox();

				antialiasing = false;

			case 'monika-angry':
				frames = getCharPath('characters/monika');
				iconColor = 'FFFFB8E3';

				addAnimationByPrefix('idle', 'Angry Senpai Idle', 24, false);
				addAnimationByPrefix('singUP', 'Angry Senpai UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT', 'Angry Senpai LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'Angry Senpai RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'Angry Senpai DOWN NOTE', 24, false);
				addAnimationByPrefix('idle-alt', 'Green Senpai Idle', 24, false);
				addAnimationByPrefix('singUP-alt', 'Green Senpai UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT-alt', 'Green Senpai LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT-alt', 'Green Senpai RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN-alt', 'Green Senpai DOWN NOTE', 24, false);

				loadOffsetFile(curCharacter);

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;

			case 'green-monika':
				frames = getCharPath('characters/monika');
				iconColor = 'FFFFB8E3';
				addAnimationByPrefix('idle', 'Green Senpai Idle', 24, false);
				addAnimationByPrefix('singUP', 'Green Senpai UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT', 'Green Senpai LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'Green Senpai RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'Green Senpai DOWN NOTE', 24, false);

				loadOffsetFile('monika');

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;

			case 'glitch-angry' | 'kristoph-angry' | 'chara-pixel' | 'jackson' | 'mario-angry' | 'matt-angry' | 'mangle-angry' | 'baldi-angry-pixel' | 'colt-angry' 
			| 'colt-angryd2' | 'senpai-giddy' | 'blantad-pixel' | 'tricky-pixel':
				switch (curCharacter)
				{
					case 'kristoph-angry':
						frames = getCharPath('characters/kristoph');
						iconColor = 'FF9284AD';
					case 'glitch-angry':
						frames = getCharPath('characters/glitch');
						iconColor = 'FF0DA554';
					case 'chara-pixel':
						frames = getCharPath('characters/chara_pixel');
						iconColor = 'FFFF0000';
					case 'jackson':
						frames = getCharPath('characters/jackson');
						iconColor = 'FFC05D68';
					case 'mario-angry':
						frames = getCharPath('characters/mario');
						iconColor = 'FFCC0000';
					case 'matt-angry':
						frames = getCharPath('characters/matt');
						iconColor = 'FFA55BA0';
						healthIcon = 'matt-ew-pixel';
					case 'mangle-angry':
						frames = getCharPath('characters/mangle');
						iconColor = 'FFDA47AD';
					case 'baldi-angry-pixel':
						frames = getCharPath('characters/baldi_pixel');
						iconColor = 'FF18E416';
						healthIcon = 'baldi-pixel';
					case 'colt-angry':
						frames = getCharPath('characters/colt');
						iconColor = 'FF584190';
						healthIcon = 'colt';
					case 'colt-angryd2':
						frames = getCharPath('characters/coltd2');
						iconColor = 'FF584190';
						healthIcon = 'colt';
					case 'senpai-giddy':
						frames = getCharPath('characters/senpaigiddy');
						iconColor = 'FFFFAA6F';
					case 'blantad-pixel':
						frames = getCharPath('characters/blantad-pixel');
						iconColor = 'FF64B3FE';
					case 'tricky-pixel':
						frames = getCharPath('characters/tricky-pixel');
						iconColor = 'FF396357';
				}
				
				addAnimationByPrefix('idle', 'Angry Senpai Idle', 24, false);
				addAnimationByPrefix('singUP', 'Angry Senpai UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT', 'Angry Senpai LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'Angry Senpai RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'Angry Senpai DOWN NOTE', 24, false);

				addAnimationByPrefix('idle-alt', 'Senpai Idle', 24, false);
				addAnimationByPrefix('singUP-alt', 'SENPAI UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT-alt', 'SENPAI LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT-alt', 'SENPAI RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN-alt', 'SENPAI DOWN NOTE', 24, false);

				var loadSelfOffsets:Array<String> = ['senpai-giddy', 'senpai-angry', 'colt-angry', 'tricky-pixel'];

				if (loadSelfOffsets.contains(curCharacter))
				{
					var name = curCharacter.substr(0, curCharacter.length - 6);

					if (curCharacter == 'tricky-pixel') name = curCharacter;

					if (curCharacter.contains('senpai'))
						loadOffsetFile('senpai-angry');
					else
						loadOffsetFile(name);
				}
				else
					loadOffsetFile('senpai');

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;

			case 'colt-angryd2corrupted':
				frames = getCharPath('characters/coltd2');
				iconColor = 'FF584190';
				healthIcon = 'colt';

				addAnimationByPrefix('idle', 'Corrupt Senpai Idle', 24, false);
				addAnimationByPrefix('singUP', 'Corrupt Senpai UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT', 'Corrupt Senpai LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'Corrupt Senpai RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'Corrupt Senpai DOWN NOTE', 24, false);

				loadOffsetFile('colt');

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;

			case 'bitdadcrazy':
				// DAD ANIMATION LOADING CODE
				frames = getCharPath('characters/BitDadCrazy');

				addAnimationByPrefix('idle', 'Dad idle dance', 24, false);
				addAnimationByPrefix('singUP', 'Dad Sing Note UP', 24, false);
				addAnimationByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24, false);
				addAnimationByPrefix('singDOWN', 'Dad Sing Note DOWN', 24, false);
				addAnimationByPrefix('singLEFT', 'Dad Sing Note LEFT', 24, false);

				addOffset('idle');
				addOffset("singUP", -6, 50);
				addOffset("singRIGHT", 0, 27);
				addOffset("singLEFT", -10, 10);
				addOffset("singDOWN", 0, -30);
				playAnim('idle');	

				setGraphicSize(Std.int(width * 0.85));
				updateHitbox();

				antialiasing = false;	
				
			case 'bitdad' | 'bitdadBSide':
				switch (curCharacter)
				{
					case 'bitdad':
						frames = getCharPath('characters/BitDad');
					case 'bitdadBSide':
						frames = getCharPath('characters/BitDadBSide');
				}
				
				addAnimationByPrefix('idle', 'Dad idle dance', 24, false);
				addAnimationByPrefix('switch', 'Dad version switch', 24, false);
				addAnimationByPrefix('singUP', 'Dad Sing Note UP', 24, false);
				addAnimationByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24, false);
				addAnimationByPrefix('singDOWN', 'Dad Sing Note DOWN', 24, false);
				addAnimationByPrefix('singLEFT', 'Dad Sing Note LEFT', 24, false);

				addOffset('idle');
				addOffset('switch');
				addOffset("singUP", 1, 58);
				addOffset("singRIGHT", -4, 38);
				addOffset("singLEFT", 42, 19);
				addOffset("singDOWN", -1, -20);
				playAnim('idle');	

				setGraphicSize(Std.int(width * 1));
				updateHitbox();

				antialiasing = false;	

			case 'matt-ew-pixel':
				frames = getCharPath('characters/matt');
				iconColor = 'FFA55BA0';
				addAnimationByPrefix('idle', 'Senpai Idle', 24, false);
				addAnimationByPrefix('singUP', 'SENPAI UP NOTE', 24, false);
				addAnimationByPrefix('singLEFT', 'SENPAI LEFT NOTE', 24, false);
				addAnimationByPrefix('singRIGHT', 'SENPAI RIGHT NOTE', 24, false);
				addAnimationByPrefix('singDOWN', 'SENPAI DOWN NOTE', 24, false);

				loadOffsetFile(curCharacter);

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;*/

			//using the psych method instead of modding plus. main reason is to make it easier for me to port them here
			default:
				isCustom = true;

				if (curCharacter == 'exTricky')
				{
					exSpikes = new FlxSprite(-250, -70);
					exSpikes.frames = Paths.getSparrowAtlas('characters/FloorSpikes', 'shared');
					exSpikes.visible = false;
					exSpikes.animation.addByPrefix('spike','Floor Spikes', 24, false);
				}

				if (curCharacter.contains('hd-senpai'))
					curCharacter = StringTools.replace(curCharacter, 'hd', '2vplus');

				if (curCharacter == 'twinstwo' || curCharacter == 'twinsone')
					alpha = 0.78;
				
				var characterPath:String = 'images/characters/jsons/' + curCharacter;

				var path:String = Paths.jsonNew(characterPath);
				
				#if desktop
					if (FileSystem.exists(Paths.modFolders('characters/'+curCharacter+'.json')))
						path = Paths.modFolders('characters/'+curCharacter+'.json');
				#end
			
				if (!FileSystem.exists(path) && !Assets.exists(path))
				{
					trace('oh no missingno');
					path = Paths.jsonNew('images/characters/jsons/bf'); //If a character couldn't be found, change to bf just to prevent a crash
					curCharacter = 'bf';
				}

				var rawJson:Dynamic;

				if (FileSystem.exists(path))
					rawJson = File.getContent(path);
				else
					rawJson = Assets.getText(path);
				
				var json:CharacterFile = cast Json.parse(rawJson);

				if (json.noteSkin != null)
					noteSkin = json.noteSkin;

				if (json.isPlayerChar)
					isPsychPlayer = json.isPlayerChar;

				if (noteSkin == "" || noteSkin == 'normal' || noteSkin == 'default')
					noteSkin = PlayState.SONG.noteStyle;	

				var imagePath = Paths.image(json.image);

				if (Assets.exists(imagePath) && !FileSystem.exists(imagePath) && !FileSystem.exists(Paths.modsImages(imagePath)))
				{
					txtToFind = Paths.txtNew('images/' + json.image);
				
					if (!Paths.currentTrackedAssets.exists(json.image))
						Paths.cacheImage(json.image, 'shared');
					
					rawPic = Paths.currentTrackedAssets.get(json.image);

					charPath = json.image + '.png'; //cuz we only use pngs anyway
					imageFile = json.image; //psych

					if(Assets.exists(txtToFind))
						frames = Paths.getPackerAtlas(json.image);
					else 
					{
						rawXml = Assets.getText(Paths.xmlNew('images/' + json.image));

						if(FlxG.save.data.poltatoPC && curCharacter != 'senpai-christmas' && json.scale != 6)
						{	
							rawXml = resizeXML(rawXml, 0.5);
	
							json.scale *= 2;
							
							if (isPlayer && json.playerposition != null)
								json.playerposition = [json.playerposition[0] + 100, json.playerposition[1] + 170];
							else
								json.position = [json.position[0] + 100, json.position[1] + 170];

							if (height < 410)
								json.position[1] -= 100;
						}
		
						frames = FlxAtlasFrames.fromSparrow(rawPic,rawXml);	
					}	
				}
				else //if it's a character added after compiling
				{
					txtToFind= Paths.txtNew('images/' + json.image);
					var modTxtToFind:String = Paths.modsTxt(json.image);

					if (!Paths.currentTrackedAssets.exists(json.image))
						Paths.cacheImage(json.image, 'preload');
					
					rawPic = Paths.currentTrackedAssets.get(json.image);

					charPath = json.image + '.png'; //cuz we only use pngs anyway
					imageFile = json.image; //psych
	
					if(FileSystem.exists(txtToFind))
					{
						rawXml = File.getContent(txtToFind);
						frames = FlxAtlasFrames.fromSpriteSheetPacker(rawPic,rawXml);
					}
					else 
					{
						if (FileSystem.exists(Paths.modsXml(json.image)))
							rawXml = File.getContent(Paths.modsXml(json.image));
						else if (FileSystem.exists(FileSystem.absolutePath("assets/shared/images/"+json.image+".xml")))
							rawXml = File.getContent(FileSystem.absolutePath("assets/shared/images/"+json.image+".xml"));
						else
							rawXml = File.getContent(Paths.xmlNew('images/' + json.image));

						//this took my dumbass 2 hours to figure out.
						if(FlxG.save.data.poltatoPC && curCharacter != 'senpai-christmas' && json.scale != 6)
						{	
							rawXml = resizeXML(rawXml, 0.5);

							json.scale *= 2;
							
							if (isPlayer && json.playerposition != null)
								json.playerposition = [json.playerposition[0] + 230, json.playerposition[1] + 230];
							else
								json.position = [json.position[0] + 230, json.position[1] + 230];
						}

						frames = FlxAtlasFrames.fromSparrow(rawPic,rawXml);
					}		
				}
				
				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				healthIcon = json.healthicon;
				
				if (isPlayer && json.playerposition != null)
					positionArray = json.playerposition;
				else
					positionArray = json.position;

				if (json.playerposition != null)
					playerPositionArray = json.playerposition;
				else
					playerPositionArray = json.position;

				if (isPlayer && json.player_camera_position != null)
					cameraPosition = json.player_camera_position;
				else
					cameraPosition = json.camera_position;

				if (json.player_camera_position != null)
					playerCameraPosition = json.player_camera_position;
				else
					playerCameraPosition = json.camera_position;
				
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

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

		//nah
		//if (curCharacter.contains('dad'))
			//singDuration = 6.1; 

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
		
					if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001)
					{
						dance();
						holdTimer = 0;
					}
				}
			}
			
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
				/*case 'bf-bigmonika-dead':
					if (animation.curAnim.name != 'crashDeath2')
					{
						if (isPlayer)
							playAnim('idle' + bfAltAnim);
						else
							playAnim('idle' + altAnim);	
					}
				case 'tankman':
					if (animation.curAnim.name != 'singDOWN-alt' && animation.curAnim.name != 'singLEFT-alt' && !stopIdle)
					{
						if (isPlayer)
							playAnim('idle' + bfAltAnim);
						else
							playAnim('idle' + altAnim);	
					}
				case 'oswald-happy':
					if (animation.curAnim.name != 'oldtimey' && animation.curAnim.name != 'lucky')
					{
						danced = !danced;
		
						if (isPlayer)
						{
							if (danced)
								playAnim('danceRight' + bfAltAnim);
							else
								playAnim('danceLeft' + bfAltAnim);
						}
						else
						{
							if (danced)
								playAnim('danceRight' + altAnim);
							else
								playAnim('danceLeft' + altAnim);
						}	
					}
				case 'oswald-angry':
					if (animation.curAnim.name != 'hah' && animation.curAnim.name != 'notold')
					{
						danced = !danced;
		
						if (isPlayer)
						{
							if (danced)
								playAnim('danceRight' + bfAltAnim);
							else
								playAnim('danceLeft' + bfAltAnim);
						}
						else
						{
							if (danced)
								playAnim('danceRight' + altAnim);
							else
								playAnim('danceLeft' + altAnim);
						}	
					}
				case 'gf-judgev2':
					if (animation.curAnim.name != 'spooked')
					{
						danced = !danced;
		
						if (isPlayer)
						{
							if (danced)
								playAnim('danceRight' + bfAltAnim);
							else
								playAnim('danceLeft' + bfAltAnim);
						}
						else
						{
							if (danced)
								playAnim('danceRight' + altAnim);
							else
								playAnim('danceLeft' + altAnim);
						}	
					}
				case 'bigmonika':
					if (animation.curAnim.name != 'lastNOTE')
					{
						if (isPlayer)
							playAnim('idle' + bfAltAnim);
						else
							playAnim('idle' + altAnim);	
					}
				case 'amor-ex':
					if (animation.curAnim.name != 'drop')
					{
						if (isPlayer)
							playAnim('idle' + bfAltAnim);
						else
							playAnim('idle' + altAnim);	
					}
				case 'sarvente-transform':
					//she dont' dance bro*/
				default:
					if (danceIdle)
					{
						if (!stopIdle)
						{
							danced = !danced;
		
							if (isPlayer)
							{
								if (danced)
									playAnim('danceRight' + bfAltAnim);
								else
									playAnim('danceLeft' + bfAltAnim);
							}
							else
							{
								if (danced)
									playAnim('danceRight' + altAnim);
								else
									playAnim('danceLeft' + altAnim);
							}	
						}
					}
					else
					{
						if (!stopIdle)
						{
							if (isPlayer)
								playAnim('idle' + bfAltAnim);
							else
								playAnim('idle' + altAnim);	
						}
					}
			}
		
			if (color != curColor && doMissThing)
				color = curColor;
		}
	}

	public function setZoom(?toChange:Float = 1, ?isPixel:Bool = false):Void
	{
		daZoom = toChange;

		var daMulti:Float = 1;

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

		if (animation.getByName(AnimName) == null) // if it's STILL null, just play idle
		{
			if(danceIdle)
				AnimName = 'danceRight';
			else
				AnimName = 'idle';
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

	public function resizeXML(rawXml:String, factor:Float)
	{
		var daXml:Xml = Xml.parse(rawXml);
		var fast = new haxe.xml.Access(daXml);
		var users = fast.node.TextureAtlas;
		for (SubTexture in users.nodes.SubTexture) {
			SubTexture.att.x = Std.string(Std.parseInt(SubTexture.att.x) * factor);
			SubTexture.att.y = Std.string(Std.parseInt(SubTexture.att.y) * factor);
			SubTexture.att.width = Std.string(Std.parseInt(SubTexture.att.width) * factor);
			SubTexture.att.height = Std.string(Std.parseInt(SubTexture.att.height) * factor);

			if (SubTexture.has.frameX)
			{
				SubTexture.att.frameX = Std.string(Std.parseInt(SubTexture.att.frameX) * factor);
				SubTexture.att.frameY = Std.string(Std.parseInt(SubTexture.att.frameY) * factor);
				SubTexture.att.frameWidth = Std.string(Std.parseInt(SubTexture.att.frameWidth) * factor);
				SubTexture.att.frameHeight = Std.string(Std.parseInt(SubTexture.att.frameHeight) * factor);
			}
		}
		return Std.string(daXml);
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

		if (curCharacter.contains('9key'))
		{
			var oldRight = animation.getByName('singRIGHT2').frames;
			animation.getByName('singRIGHT2').frames = animation.getByName('singLEFT2').frames;
			animation.getByName('singLEFT2').frames = oldRight;
		}
	}
}