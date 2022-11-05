package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.animation.FlxBaseAnimation;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxRandom;
import flixel.math.FlxMath;
import flixel.FlxObject;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import flixel.text.FlxText;
import flixel.effects.particles.FlxEmitter; //never have i ever used this until now.
import flixel.effects.particles.FlxParticle;
import StageData;
import StageModchartState;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import openfl.Lib;
import lime.utils.Assets;

#if desktop
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;
import Shaders;

class Stage extends MusicBeatState
{
	public static var instance:Stage = null;

	public var curStage:String = '';//
	public var camZoom:Float; // The zoom of the camera to have at the start of the game
	public var hideLastBG:Bool = false; // True = hide last BGs and show ones from slowBacks on certain step, False = Toggle visibility of BGs from SlowBacks on certain step
	// Use visible property to manage if BG would be visible or not at the start of the game
	public var tweenDuration:Float = 2; // How long will it tween hiding/showing BGs, variable above must be set to True for tween to activate
	public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
	// Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
	public var swagBacks:Map<String,
		Dynamic> = new Map(); // Store BGs here to use them later (for example with slowBacks, using your custom stage event or to adjust position in stage debug menu(press 8 while in PlayState with debug build of the game))
	public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; // Store Groups
	public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup/swagBacks and script it in stepHit/beatHit function of this file!!)
	public var animatedBacks2:Array<FlxSprite> = []; //doesn't interrupt if animation is playing, unlike animatedBacks
	public var layInFront:Array<Array<Dynamic>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment), fourth [3] in front of arrows and stuff 
	public var slowBacks:Map<Int,
		Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"
	public var toHUD:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toCamHUD.push(bgVar);"
	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	// All of the above must be set or used in your stage case code block!!
	public var bfScrollFactor:Array<Float> = [1, 1]; //ye damn scroll factors!
	public var dadScrollFactor:Array<Float> = [1, 1];
	public var gfScrollFactor:Array<Float> = [0.95, 0.95];

	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];

	var pre:String = ""; //lol
	var suf:String = ""; //lol2

	//moving the offset shit here too
	public var gfXOffset:Float = 0;
	public var dadXOffset:Float = 0;
	public var bfXOffset:Float = 0;
	public var gfYOffset:Float = 0;
	public var dadYOffset:Float = 0;
	public var bfYOffset:Float = 0;
	public var hideGirlfriend:Bool = false;

	var fastCarCanDrive:Bool = false;

	//camellia stuff
	public var addedAmogus:Bool = false;
	public var concertZoom:Bool = false;
	public var crowd_front:FlxSprite;
	public var crowd_front2:FlxSprite;
	public var crowd_front3:FlxSprite;
	public var crowd_front4:FlxSprite;
	public var jabibi_amogus:FlxSprite;
	public var speaker_left:FlxSprite;
	public var speaker_right:FlxSprite;
	public var crowd_back:FlxSprite;
	public var crowd_back2:FlxSprite;
	public var crowd_back3:FlxSprite;
	public var crowd_back4:FlxSprite;
	public var timing:Float = 0.25;
	public var zoomLevel:Float = 0.41;
	public var easeThing = FlxEase.expoInOut;
	
	public var tstatic:FlxSprite;
	public var vg:FlxSprite;
	public var hasFilter:Bool = false;
	public var vignette:FlxSprite;
	public var light:FlxSprite;
	public var light2:FlxSprite;
	public var c1:FlxSprite;
	var tankRolling:FlxSprite;
	var tankX:Int = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.float(-90, 45);
	public var blantadBG:FlxSprite;

	public var red:FlxSprite;
	public var purple:FlxSprite;
	public var green:FlxSprite;
	public var blue:FlxSprite;

	public var red2:FlxSprite;
	public var purple2:FlxSprite;
	public var green2:FlxSprite;
	public var blue2:FlxSprite;
	public var circ1new:FlxSprite;
	public var funneEffect:FlxSprite;
	public var altSuffix:String = '';
	public var pixelShitPart1:String = '';
	public var pixelShitPart2:String = '';
	public var songLowercase:String = '';
	public var introAssets:Array<String> = ['ready', 'set', 'go'];
	public var preloading:Bool = false;

	public var isCustomStage:Bool = false;

	public var animOffsets:Map<String, Array<Dynamic>>;

	public function addObject(object:FlxBasic) { add(object); }
	public function removeObject(object:FlxBasic) { remove(object); }
	public function destroyObject(object:FlxBasic) { object.destroy(); }

	public function new(daStage:String, ?preloading:Bool = false)
	{
		super();
		this.curStage = daStage;
		this.preloading = preloading;
		camZoom = 1.05; // Don't change zoom here, unless you want to change zoom of every stage that doesn't have custom one --shouldn't this just be 0.9 since most stages use that?
		pre = "";
		suf = "";
		fastCarCanDrive = false;
		addedAmogus = false;
		concertZoom = false;
		hasFilter = false;
		songLowercase = PlayState.SONG.song.toLowerCase();

		instance = this;

		if (!preloading) //clears the filters
		{
			if (PlayState.instance.camGameShaders.length > 0 || PlayState.instance.camGameShaders.length > 0)
			{
				PlayState.instance.clearShaderFromCamera('hud');
				PlayState.instance.clearShaderFromCamera('game');
				PlayState.instance.clearShaderFromCamera('other');
			}
		}

		switch (daStage)
		{
			case 'halloween' | 'halloweenmanor' | 'halloween-pelo':
			{	
				var halloweenBG = new FlxSprite(-200, -80);
				switch (daStage)
				{
					case 'halloween':
						halloweenBG.frames = Paths.getSparrowAtlas('halloween_bg', 'week2');
					case 'halloweenmanor':
						halloweenBG.frames = Paths.getSparrowAtlas('manor_bg', 'week2');
					case 'halloween-pelo':
						halloweenBG.frames = Paths.getSparrowAtlas('halloween_bg_pelo', 'week2');
						camZoom = 0.9;
				}
				
				halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
				halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
				halloweenBG.animation.play('idle');
				halloweenBG.antialiasing = true;
				swagBacks['halloweenBG'] = halloweenBG;
				toAdd.push(halloweenBG);
			}
			case 'philly' | 'phillyannie':
			{
				switch (daStage)
				{
					case 'philly': pre = 'philly';
					case 'phillyannie': pre = 'annie';
				}

				var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image(pre+'/sky', 'week3'));
				bg.scrollFactor.set(0.1, 0.1);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image(pre+'/city', 'week3'));
				city.scrollFactor.set(0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				swagBacks['city'] = city;
				toAdd.push(city);

				var phillyCityLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['phillyCityLights'] = phillyCityLights;
				toAdd.push(phillyCityLights);

				for (i in 0...5)
				{
					var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image(pre+'/win' + i, 'week3'));
					light.scrollFactor.set(0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					light.antialiasing = FlxG.save.data.antialiasing;
					phillyCityLights.add(light);
				}

				var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image(pre+'/behindTrain', 'week3'));
				swagBacks['streetBehind'] = streetBehind;
				toAdd.push(streetBehind);

				var phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image(pre+'/train', 'week3'));
				swagBacks['phillyTrain'] = phillyTrain;
				toAdd.push(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image(pre+'/street', 'week3'));
				swagBacks['street'] = street;
				toAdd.push(street);
			}
			/*case 'philly-wire':
			{
				camZoom = 1.05;

				var pre:String = 'philly';
				var pre2:String = 'wire';

				var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image(pre+'/sky', 'week3'));
				bg.scrollFactor.set(0.1, 0.1);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image(pre+'/city', 'week3'));
				city.scrollFactor.set(0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				swagBacks['city'] = city;
				toAdd.push(city);

				var phillyCityLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['phillyCityLights'] = phillyCityLights;
				toAdd.push(phillyCityLights);

				for (i in 0...5)
				{
					var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image(pre+'/win' + i, 'week3'));
					light.scrollFactor.set(0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					light.antialiasing = FlxG.save.data.antialiasing;
					phillyCityLights.add(light);
					swagBacks['light' + i] = light;	
				}

				var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image(pre+'/behindTrain', 'week3'));
				swagBacks['streetBehind'] = streetBehind;
				toAdd.push(streetBehind);

				var phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image(pre+'/train', 'week3'));
				swagBacks['phillyTrain'] = phillyTrain;
				toAdd.push(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image(pre+'/street', 'week3'));
				swagBacks['street'] = street;
				toAdd.push(street);

				//wire shit
				var wirebg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image(pre2+'/sky', 'week3'));
				wirebg.scrollFactor.set(0.1, 0.1);
				swagBacks['wirebg'] = wirebg;
				toAdd.push(wirebg);

				var wirecity:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image(pre2+'/city', 'week3'));
				wirecity.scrollFactor.set(0.3, 0.3);
				wirecity.setGraphicSize(Std.int(wirecity.width * 0.85));
				wirecity.updateHitbox();
				swagBacks['wirecity'] = wirecity;
				toAdd.push(wirecity);

				var wirephillyCityLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['wirephillyCityLights'] = wirephillyCityLights;
				toAdd.push(wirephillyCityLights);

				for (i in 0...1)
				{
					var wirelight:FlxSprite = new FlxSprite(wirecity.x).loadGraphic(Paths.image(pre2+'/win' + i, 'week3'));
					wirelight.scrollFactor.set(0.3, 0.3);
					wirelight.visible = false;
					wirelight.setGraphicSize(Std.int(wirelight.width * 0.85));
					wirelight.updateHitbox();
					wirelight.antialiasing = FlxG.save.data.antialiasing;
					wirephillyCityLights.add(wirelight);
					swagBacks['wirelight' + i] = wirelight;	
				}

				var wirestreetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image(pre2+'/behindTrain', 'week3'));
				swagBacks['wirestreetBehind'] = wirestreetBehind;
				toAdd.push(wirestreetBehind);

				var wirephillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image(pre2+'/train', 'week3'));
				swagBacks['wirephillyTrain'] = wirephillyTrain;
				toAdd.push(wirephillyTrain);

				var wirestreet:FlxSprite = new FlxSprite(-40, wirestreetBehind.y).loadGraphic(Paths.image(pre2+'/street', 'week3'));
				swagBacks['wirestreet'] = wirestreet;
				toAdd.push(wirestreet);

				var gfBG = new GirlfriendBG(300, 210, 'characters/gfBana', 'GF Dancing Beat Bana');
				gfBG.scrollFactor.set(0.95, 0.95);
				gfBG.setGraphicSize(Std.int(gfBG.width * 0.8));
				gfBG.updateHitbox();
				swagBacks['gfBG'] = gfBG;
				toAdd.push(gfBG);

				var gfBG2 = new GirlfriendBG(300, 210, 'characters/gfBana_WIRE', 'GF Dancing Beat Bana');
				gfBG2.scrollFactor.set(0.95, 0.95);
				gfBG2.setGraphicSize(Std.int(gfBG2.width * 0.8));
				gfBG2.updateHitbox();
				swagBacks['gfBG2'] = gfBG2;
				toAdd.push(gfBG2);	
			}*/
			case 'limo':
			{
				camZoom = 0.9;

				var skyBG:FlxSprite = new FlxSprite(-120, -150).loadGraphic(Paths.image('limo/limoSunset', 'week4'));
				skyBG.scrollFactor.set(0.1, 0.1);
				swagBacks['skyBG'] = skyBG;
				toAdd.push(skyBG);

				var bgLimo:FlxSprite = new FlxSprite(-200, 480);
				bgLimo.frames = Paths.getSparrowAtlas('limo/bgLimo', 'week4');
				bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
				bgLimo.animation.play('drive');
				bgLimo.scrollFactor.set(0.4, 0.4);
				swagBacks['bgLimo'] = bgLimo;
				toAdd.push(bgLimo);
	
				var grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
				swagGroup['grpLimoDancers'] = grpLimoDancers;
				toAdd.push(grpLimoDancers);

				for (i in 0...5)
				{
					var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
					dancer.scrollFactor.set(0.4, 0.4);
					grpLimoDancers.add(dancer);
					swagBacks['dancer' + i] = dancer;
				}

				var limo = new FlxSprite(-120, 550);
				limo.frames = Paths.getSparrowAtlas('limo/limoDrive', 'week4');
				limo.animation.addByPrefix('drive', "Limo stage", 24);
				limo.animation.play('drive');
				limo.antialiasing = true;
				layInFront[0].push(limo);
				swagBacks['limo'] = limo;

				var fastCar = new FlxSprite(-12600, 160).loadGraphic(Paths.image('limo/fastCarLol', 'week4'));
				swagBacks['fastCar'] = fastCar;
				toAdd.push(fastCar);

				fastCarCanDrive = true;
				resetFastCar();

				bfXOffset = 260;
				bfYOffset = -250;
				boyfriendCameraOffset = [-150, 0]; // 200 is a lil much
			}

			/*case 'limoholo':
			{
				camZoom = 0.9;
	
				var skyBG:FlxSprite = new FlxSprite(-120, -100).loadGraphic(Paths.image('holofunk/limoholo/limoSunset'));
				skyBG.scrollFactor.set(0.1, 0.1);
				swagBacks['skyBG'] = skyBG;
				toAdd.push(skyBG);
				
				var bgLimo:FlxSprite = new FlxSprite(-200, 480);
				bgLimo.frames = Paths.getSparrowAtlas('holofunk/limoholo/bgLimo');
				bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
				bgLimo.animation.play('drive');
				bgLimo.scrollFactor.set(0.4, 0.4);
				swagBacks['bgLimo'] = bgLimo;
				toAdd.push(bgLimo);

				var grpLimoDancersHolo = new FlxTypedGroup<BackgroundDancerHolo>();
				swagGroup['grpLimoDancersHolo'] = grpLimoDancersHolo;
				toAdd.push(grpLimoDancersHolo);

				for (i in 0...5)
				{
					var dancer:BackgroundDancerHolo = new BackgroundDancerHolo((370 * i) + 200, bgLimo.y - 360);
					dancer.scrollFactor.set(0.4, 0.4);
					grpLimoDancersHolo.add(dancer);
					swagBacks['dancer' + i] = dancer;
				}

				var limo = new FlxSprite(-120, 550);
				limo.frames = Paths.getSparrowAtlas('holofunk/limoholo/limoDrive');
				limo.animation.addByPrefix('drive', "Limo stage", 24);
				limo.animation.play('drive');
				limo.antialiasing = true;
				layInFront[0].push(limo);
				swagBacks['limo'] = limo;

				var fastCar = new FlxSprite(-12600, 160).loadGraphic(Paths.image('holofunk/limoholo/fastCarLol'));
				swagBacks['fastCar'] = fastCar;
				toAdd.push(fastCar);

				fastCarCanDrive = true;
				resetFastCar();

				bfXOffset = 260;
				bfYOffset = -250;
			}

			case 'limoholo-night':
			{
				camZoom = 0.9;

				var upperSky = new FlxSprite(-250, -1100).loadGraphic(Paths.image('holofunk/limoholo/upperSky'));
				upperSky.scrollFactor.set(0.1, 0.1);
				upperSky.setGraphicSize(Std.int(upperSky.width * 1.4));
				upperSky.updateHitbox();
				swagBacks['upperSky'] = upperSky;
				toAdd.push(upperSky);
				
				var upperSky2 = new FlxSprite(-2000, -1100).loadGraphic(Paths.image('holofunk/limoholo/upperSky'));
				upperSky2.scrollFactor.set(0.1, 0.1);
				upperSky2.setGraphicSize(Std.int(upperSky2.width * 1.4));
				upperSky2.updateHitbox();
				swagBacks['upperSky2'] = upperSky2;
				toAdd.push(upperSky2);

				var skyBG:FlxSprite = new FlxSprite(-120, -100).loadGraphic(Paths.image('holofunk/limoholo/limoNight'));
				skyBG.scrollFactor.set(0.1, 0.1);
				swagBacks['skyBG'] = skyBG;
				toAdd.push(skyBG);

				if (songLowercase == 'hands')
				{
					var cloudGroup2 = new FlxTypedGroup<Cloud2>(12);
					swagGroup['cloudGroup2'] = cloudGroup2;
					toAdd.push(cloudGroup2);
				}
		
				var bgLimo = new FlxSprite(-200, 480);
				bgLimo.frames = Paths.getSparrowAtlas('holofunk/limoholo/bgLimo');
				bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
				bgLimo.animation.play('drive');
				bgLimo.scrollFactor.set(0.4, 0.4);
				swagBacks['bgLimo'] = bgLimo;
				toAdd.push(bgLimo);

				if (songLowercase == 'hands')
				{
					var bgLimoOhNo = new FlxSprite(-380, 390);
					bgLimoOhNo.frames = Paths.getSparrowAtlas('holofunk/limoholo/bgLimoOhNo');
					bgLimoOhNo.animation.addByPrefix('drive', "BG limo PINK", 24);
					bgLimoOhNo.animation.play('drive');
					bgLimoOhNo.scrollFactor.set(0.4, 0.4);
					swagBacks['bgLimoOhNo'] = bgLimoOhNo;
					toAdd.push(bgLimoOhNo);
				}
				
				var grpLimoDancersHolo = new FlxTypedGroup<BackgroundDancerHolo>();
				swagGroup['grpLimoDancersHolo'] = grpLimoDancersHolo;
				toAdd.push(grpLimoDancersHolo);

				for (i in 0...5)
				{
					var dancer:BackgroundDancerHolo = new BackgroundDancerHolo((370 * i) + 130, bgLimo.y - 360);
					dancer.scrollFactor.set(0.4, 0.4);
					swagBacks['dancer'+i] = dancer;
					grpLimoDancersHolo.add(dancer);
				}

				var limo = new FlxSprite(-120, 550);
				limo.frames = Paths.getSparrowAtlas('holofunk/limoholo/limoDrive');
				limo.animation.addByPrefix('drive', "Limo stage", 24);
				limo.animation.play('drive');
				limo.antialiasing = true;
				layInFront[0].push(limo);
				swagBacks['limo'] = limo;

				if (songLowercase == 'hands')
				{
					blantadBG = new FlxSprite(100, -100);
					blantadBG.frames = Paths.getSparrowAtlas('holofunk/limoholo/FlyingBlantad');
					blantadBG.animation.addByPrefix('idle', "FlyingBlantados", 24, false);
					blantadBG.animation.addByPrefix('tele', 'tele2', 24, false);
					blantadBG.scrollFactor.set(0.9, 0.9);
					blantadBG.setGraphicSize(Std.int(blantadBG.width * 0.65));
					blantadBG.updateHitbox();
					blantadBG.antialiasing = true;
					swagBacks['blantadBG'] = blantadBG;
					animatedBacks2.push(blantadBG);
					toAdd.push(blantadBG);

					var limoOhNo = new FlxSprite(-225, 370);
					limoOhNo.frames = Paths.getSparrowAtlas('holofunk/limoholo/limoDriveOhNo');
					limoOhNo.animation.addByPrefix('drive', "BeforeFly", 24);
					limoOhNo.animation.addByPrefix('driveFlying', "Flying", 24);
					limoOhNo.animation.play('drive');
					limoOhNo.antialiasing = true;
					layInFront[0].push(limoOhNo);
					swagBacks['limoOhNo'] = limoOhNo;
				}	

				var fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('holofunk/limoholo/fastCarLol'));
				swagBacks['fastCar'] = fastCar;
				toAdd.push(fastCar);

				if (songLowercase == 'hands')
				{
					var gfBG = new GirlfriendBG(475, 525, 'holofunk/limoholo/shoppingCartBottom', 'GF Dancing Beat Hair blowing CAR');
					gfBG.antialiasing = true;
					gfBG.scrollFactor.set(0.95, 0.95);
					swagBacks['gfBG'] = gfBG;
					toAdd.push(gfBG);

					var cloudGroup = new FlxTypedGroup<Cloud>(25);
					swagGroup['cloudGroup'] = cloudGroup;
					toAdd.push(cloudGroup);
				}	
				
				bfXOffset = 260;
				bfYOffset = -250;

				resetFastCar();
			}*/

			case 'mall' | 'sofdeez': //sof deez nuts
			{
				camZoom = 0.80;

				switch (curStage)
				{
					case 'mall':
						pre = 'christmas';
						suf = 'week5';
					case 'sofdeez':
						pre = 'skye';
						suf = 'week1';
				}

				var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image(pre+'/bgWalls', suf));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var upperBoppers = new FlxSprite(-240, -90);

				if ((PlayState.SONG.player2 == 'bico-christmas' || PlayState.SONG.player2.contains('pico') && PlayState.SONG.player2 != 'piconjo') && PlayState.instance != null) {
					upperBoppers.frames = Paths.getSparrowAtlas('christmas/upperBopNoPico', 'week5');
				}
				else {
					upperBoppers.frames = Paths.getSparrowAtlas(pre+'/upperBop', suf);
				}
				
				upperBoppers.animation.addByPrefix('idle', "Upper Crowd Bob", 24, false);
				upperBoppers.antialiasing = FlxG.save.data.antialiasing;
				upperBoppers.scrollFactor.set(0.33, 0.33);
				upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
				upperBoppers.updateHitbox();
				swagBacks['upperBoppers'] = upperBoppers;
				toAdd.push(upperBoppers);
				animatedBacks.push(upperBoppers);

				var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image(pre+'/bgEscalator', suf));
				bgEscalator.antialiasing = FlxG.save.data.antialiasing;
				bgEscalator.scrollFactor.set(0.3, 0.3);
				bgEscalator.active = false;
				bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
				bgEscalator.updateHitbox();
				swagBacks['bgEscalator'] = bgEscalator;
				toAdd.push(bgEscalator);

				var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image(pre+'/christmasTree', suf));
				tree.antialiasing = FlxG.save.data.antialiasing;
				tree.scrollFactor.set(0.40, 0.40);
				swagBacks['tree'] = tree;
				toAdd.push(tree);

				var bottomBoppers:FlxSprite;

				if (pre == 'skye')
				{
					bottomBoppers = new FlxSprite(-540, -210);
					bottomBoppers.scrollFactor.set(1, 1);
				}		
				else
				{
					bottomBoppers = new FlxSprite(-300, 140);
					bottomBoppers.scrollFactor.set(0.9, 0.9);
				}
					
				bottomBoppers.frames = Paths.getSparrowAtlas(pre+'/bottomBop', suf);//
				bottomBoppers.animation.addByPrefix('idle', 'Bottom Level Boppers', 24, false);
				bottomBoppers.antialiasing = FlxG.save.data.antialiasing;
				
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				swagBacks['bottomBoppers'] = bottomBoppers;
				toAdd.push(bottomBoppers);
				animatedBacks.push(bottomBoppers);

				var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image(pre+'/fgSnow', suf));
				fgSnow.active = false;
				fgSnow.antialiasing = FlxG.save.data.antialiasing;
				swagBacks['fgSnow'] = fgSnow;
				toAdd.push(fgSnow);

				var santa = new FlxSprite(-840, 150);
				santa.frames = Paths.getSparrowAtlas(pre+'/santa', suf);
				santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
				santa.antialiasing = FlxG.save.data.antialiasing;
				swagBacks['santa'] = santa;
				toAdd.push(santa);
				animatedBacks.push(santa);
			}
			/*case 'mallSoft':
			{
				camZoom = 0.80;

				var bg = new FlxSprite(-1000, -500).loadGraphic(Paths.image('soft/christmas/bgWalls'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var upperBoppers = new FlxSprite(-240, -90);
				var bottomBoppers = new FlxSprite(-150, 0);

				if ((songLowercase == 'ugh-remix' || songLowercase == 'hope') && PlayState.instance != null) {			
					upperBoppers.frames = Paths.getSparrowAtlas('soft/christmas/angrybogosbinted');
					bottomBoppers.frames = Paths.getSparrowAtlas('soft/christmas/bopit');
				}
				else {		
					upperBoppers.frames = Paths.getSparrowAtlas('soft/christmas/normalfuckerspng');	
					bottomBoppers.frames = Paths.getSparrowAtlas('soft/christmas/bop1');
				}
				
				upperBoppers.animation.addByPrefix('idle', "Upper Crowd Bob", 24, false);
				upperBoppers.antialiasing = true;
				upperBoppers.scrollFactor.set(0.33, 0.33);
				upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
				upperBoppers.updateHitbox();
				swagBacks['upperBoppers'] = upperBoppers;
				toAdd.push(upperBoppers);
				animatedBacks.push(upperBoppers);

				var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('soft/christmas/bgEscalator'));
				bgEscalator.antialiasing = true;
				bgEscalator.scrollFactor.set(0.3, 0.3);
				bgEscalator.active = false;
				bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
				bgEscalator.updateHitbox();
				swagBacks['bgEscalator'] = bgEscalator;
				toAdd.push(bgEscalator);

				var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('soft/christmas/christmasTree'));
				tree.antialiasing = true;
				tree.scrollFactor.set(0.40, 0.40);
				swagBacks['tree'] = tree;
				toAdd.push(tree);

				bottomBoppers.animation.addByPrefix('idle', 'Bottom Level Boppers', 24, false);
				bottomBoppers.antialiasing = true;
				bottomBoppers.scrollFactor.set(0.9, 0.9);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();			
				swagBacks['bottomBoppers'] = bottomBoppers;
				toAdd.push(bottomBoppers);
				animatedBacks.push(bottomBoppers);

				if (songLowercase == 'ugh-remix' && PlayState.instance != null)
				{
					var blantadBG2 = new FlxSprite(-300, 120);
					blantadBG2.frames = Paths.getSparrowAtlas('soft/christmas/allAloneRIP');
					blantadBG2.animation.addByPrefix('bop', 'blantad', 24, false);
					blantadBG2.antialiasing = true;
					blantadBG2.scrollFactor.set(0.9, 0.9);
					add(blantadBG2);
				}

				var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('soft/christmas/fgSnow'));
				fgSnow.active = false;
				fgSnow.antialiasing = true;
				swagBacks['fgSnow'] = fgSnow;
				toAdd.push(fgSnow);

				var santa = new FlxSprite(-840, 150);
				santa.frames = Paths.getSparrowAtlas('soft/christmas/santa1');
				santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
				santa.antialiasing = true;
				swagBacks['santa'] = santa;
				layInFront[2].push(santa);
				animatedBacks.push(santa);
				
				if (songLowercase == 'ugh-remix' && PlayState.instance != null)
				{
					var gfBG = new GirlfriendBG(1164, 426, 'characters/softPico_Christmas', 'GF Dancing Beat');
					gfBG.antialiasing = true;
					gfBG.scrollFactor.set(0.9, 0.9);
					gfBG.setGraphicSize(Std.int(gfBG.width * 0.8));
					gfBG.updateHitbox();
					swagBacks['gfBG'] = gfBG;
					toAdd.push(gfBG);

					var momDadBG = new FlxSprite(-400, 110);
					momDadBG.frames = Paths.getSparrowAtlas('characters/parents_xmas_soft');
					momDadBG.animation.addByPrefix('idle', 'Parent Christmas Idle', 24, false);
					momDadBG.antialiasing = true;
					swagBacks['momDadBG'] = momDadBG;
					toAdd.push(momDadBG);

					var softBFBG = new FlxSprite (1594, 440);
					softBFBG.frames = Paths.getSparrowAtlas('characters/softie_crimmus2');
					softBFBG.animation.addByPrefix('idle', 'BF idle dance', 24, false);
					softBFBG.setGraphicSize(Std.int(softBFBG.width * 0.9));
					softBFBG.updateHitbox();
					softBFBG.antialiasing = true;
					swagBacks['softBFBG'] = softBFBG;
					toAdd.push(softBFBG);
				}
			}*/
			case 'mallEvil' | 'mallAnnie':
			{
				switch (daStage)
				{
					case 'mallEvil':
						pre = 'christmas';
						suf = 'week5';
					case 'mallAnnie':
						pre = 'annie';
						suf = 'week3';
				}

				var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image(pre+'/evilBG', suf));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image(pre+'/evilTree', suf));
				evilTree.antialiasing = FlxG.save.data.antialiasing;
				evilTree.scrollFactor.set(0.2, 0.2);
				swagBacks['evilTree'] = evilTree;
				toAdd.push(evilTree);

				var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image(pre+'/evilSnow', suf));
				evilSnow.antialiasing = FlxG.save.data.antialiasing;
				swagBacks['evilSnow'] = evilSnow;
				toAdd.push(evilSnow);
			}

			case 'school' | 'school-sad':
			{
				curStage = 'school';
				altSuffix = '-pixel';

				var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/weebSky', 'week6'));
				bgSky.scrollFactor.set(0.1, 0.1);
				swagBacks['bgSky'] = bgSky;
				toAdd.push(bgSky);

				var repositionShit = -200;

				var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('weeb/weebSchool', 'week6'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				swagBacks['bgSchool'] = bgSchool;
				toAdd.push(bgSchool);

				var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreet', 'week6'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				swagBacks['bgStreet'] = bgStreet;
				toAdd.push(bgStreet);

				var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('weeb/weebTreesBack', 'week6'));
				fgTrees.scrollFactor.set(0.9, 0.9);
				swagBacks['fgTrees'] = fgTrees;
				toAdd.push(fgTrees);

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees', 'week6');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				swagBacks['bgTrees'] = bgTrees;
				toAdd.push(bgTrees);

				var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
				treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals', 'week6');
				treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
				treeLeaves.animation.play('leaves');
				treeLeaves.scrollFactor.set(0.85, 0.85);
				swagBacks['treeLeaves'] = treeLeaves;
				toAdd.push(treeLeaves);

				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				fgTrees.setGraphicSize(Std.int(widShit * 0.8));
				treeLeaves.setGraphicSize(widShit);

				fgTrees.updateHitbox();
				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();
				treeLeaves.updateHitbox();

				var bgGirls = new BackgroundGirls(-100, 190);
				bgGirls.scrollFactor.set(0.9, 0.9);

				if (songLowercase.contains('roses') && songLowercase != 'roses-remix' || daStage == 'school-sad')
					bgGirls.getScared();

				bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
				bgGirls.updateHitbox();
				swagBacks['bgGirls'] = bgGirls;
				toAdd.push(bgGirls);

				introAssets = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
			}

			//all the different schools for roses remix to make use of the new stage switch system since the old one sucks
			/*case 'grillbys' | 'school-baldi' | 'mushroom-kingdom' | 'eddhouse-pixel':
			{
				var bgPre:String = "";
				var bgPre2:String = "";
				altSuffix = '-pixel';

				switch (daStage)
				{
					case 'grillbys':
						pre = 'weeb/undertale/';
						bgPre = 'weeb/bgFreaksUTMJ';
					case 'mushroom-kingdom':
						pre = 'weeb/mario/';
						bgPre = 'weeb/bgFreaksSFNAF';
						bgPre2 = 'weeb/bgFreaksBSAA';
					case 'school-baldi':
						pre = 'weeb/baldi/';
						bgPre = 'weeb/bgFreaksSFNAF';
					case 'eddhouse-pixel':
						pre = 'weeb/matt/';
						bgPre = 'weeb/bgFreaksEdd';
				}
				var bgSky = new FlxSprite().loadGraphic(Paths.image(pre+'weebSky'));
				bgSky.scrollFactor.set(0.1, 0.1);
				swagBacks['bgSky'] = bgSky;
				toAdd.push(bgSky);

				var repositionShit = -200;

				var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image(pre+'weebSchool'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				swagBacks['bgSchool'] = bgSchool;
				toAdd.push(bgSchool);

				var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image(pre+'weebStreet'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				swagBacks['bgStreet'] = bgStreet;
				toAdd.push(bgStreet);

				var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image(pre+'weebTreesBack'));
				fgTrees.scrollFactor.set(0.9, 0.9);
				swagBacks['fgTrees'] = fgTrees;
				toAdd.push(fgTrees);

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				var treetex = Paths.getPackerAtlas(pre+'weebTrees');
				bgTrees.frames = treetex;
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				swagBacks['bgTrees'] = bgTrees;
				toAdd.push(bgTrees);

				var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
				treeLeaves.frames = Paths.getSparrowAtlas(pre+'petals');
				treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
				treeLeaves.animation.play('leaves');
				treeLeaves.scrollFactor.set(0.85, 0.85);
				swagBacks['treeLeaves'] = treeLeaves;
				toAdd.push(treeLeaves);

				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				fgTrees.setGraphicSize(Std.int(widShit * 0.8));
				treeLeaves.setGraphicSize(widShit);

				fgTrees.updateHitbox();
				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();
				treeLeaves.updateHitbox();

				var bgGirls = new BackgroundGirlsSwitch(-100, 190, bgPre);
				bgGirls.scrollFactor.set(0.9, 0.9);

				if (daStage == 'eddhouse-pixel' || daStage == 'mushroom-kingdom')
					bgGirls.getScared();

				bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
				bgGirls.updateHitbox();
				swagBacks['bgGirls'] = bgGirls;
				toAdd.push(bgGirls);

				if (daStage == 'mushroom-kingdom')
				{
					var bgGirls2 = new BackgroundGirlsSwitch(-100, 190 , bgPre2);
					bgGirls2.scrollFactor.set(0.9, 0.9);
	
					if (daStage == 'mushroom-kingdom')
						bgGirls2.getScared();
	
					bgGirls2.setGraphicSize(Std.int(bgGirls2.width * PlayState.daPixelZoom));
					bgGirls2.updateHitbox();
					swagBacks['bgGirls2'] = bgGirls2;
					toAdd.push(bgGirls2);

					var amyPixelBG = new GirlfriendBG(500, 150, 'characters/amyPixelMario', 'GF IDLE');
					amyPixelBG.scrollFactor.set(0.9, 0.9);
					amyPixelBG.antialiasing = false;
					amyPixelBG.setGraphicSize(Std.int(amyPixelBG.width * 5.5));
					amyPixelBG.updateHitbox();
					swagBacks['amyPixelBG'] = amyPixelBG;
					toAdd.push(amyPixelBG);

					var fgStreetMario = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/mario/weebFG'));
					fgStreetMario.scrollFactor.set(0.95, 0.95);
					fgStreetMario.setGraphicSize(widShit);
					fgStreetMario.updateHitbox();
					swagBacks['fgStreetMario'] = fgStreetMario;
					layInFront[2].push(fgStreetMario);
				}
				
				if (daStage == 'eddhouse-pixel')
				{
					var monikaBG = new FlxSprite(-300, 100);
					monikaBG.frames = Paths.getSparrowAtlas('weeb/monika_bg');
					monikaBG.animation.addByPrefix('idle', 'monika bg0', 24, false);
					monikaBG.animation.addByPrefix('still', 'monika bg still0', 24, false);
					monikaBG.animation.addByPrefix('jumpscare', 'monika jumpscare0', 24, false);
					monikaBG.animation.addByPrefix('ghost', 'ghost bg0', 24, false);
					monikaBG.animation.addByPrefix('just-monika', 'just monika bg0', 24, false);
					monikaBG.animation.play('still');
					monikaBG.antialiasing = true;
					monikaBG.setGraphicSize(Std.int(monikaBG.width * 0.8));
					monikaBG.updateHitbox();
					swagBacks['monikaBG'] = monikaBG;
					layInFront[0].push(monikaBG);
				}

				introAssets = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
			}

			case 'schoolnoon':
			{
				curStage = 'schoolnoon';

				camZoom = 1.05;

				var bgSky = new FlxSprite().loadGraphic(Paths.image('corruption/weeb/weebSkynoon'));
				bgSky.scrollFactor.set(0.1, 0.1);
				swagBacks['bgSky'] = bgSky;
				toAdd.push(bgSky);

				var bgSkyEvil = new FlxSprite().loadGraphic(Paths.image('corruption/weeb/weebSkyEvil'));
				bgSkyEvil.scrollFactor.set(0.1, 0.1);
				bgSkyEvil.alpha = 0;
				swagBacks['bgSkyEvil'] = bgSkyEvil;
				toAdd.push(bgSkyEvil);

				var repositionShit = -200;

				var bgSchool = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('corruption/weeb/weebSchoolnoon'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				swagBacks['bgSchool'] = bgSchool;
				toAdd.push(bgSchool);

				var bgSchoolEvil = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('corruption/weeb/weebSchoolEvil'));
				bgSchoolEvil.scrollFactor.set(0.6, 0.90);
				bgSchoolEvil.alpha = 0;
				swagBacks['bgSchoolEvil'] = bgSchoolEvil;
				toAdd.push(bgSchoolEvil);

				var bgStreet = new FlxSprite(repositionShit).loadGraphic(Paths.image('corruption/weeb/weebStreetnoon'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				swagBacks['bgStreet'] = bgStreet;
				toAdd.push(bgStreet);

				var bgStreetEvil = new FlxSprite(repositionShit).loadGraphic(Paths.image('corruption/weeb/weebStreetEvil'));
				bgStreetEvil.scrollFactor.set(0.95, 0.95);
				bgStreetEvil.alpha = 0;
				swagBacks['bgStreetEvil'] = bgStreetEvil;
				toAdd.push(bgStreetEvil);

				var fgTrees = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('corruption/weeb/weebTreesBacknoon'));
				fgTrees.scrollFactor.set(0.9, 0.9);
				swagBacks['fgTrees'] = fgTrees;
				toAdd.push(fgTrees);

				var fgTreesEvil = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('corruption/weeb/weebTreesBackEvil'));
				fgTreesEvil.scrollFactor.set(0.9, 0.9);
				fgTreesEvil.alpha = 0;
				swagBacks['fgTreesEvil'] = fgTreesEvil;
				toAdd.push(fgTreesEvil);

				var bgTrees = new FlxSprite(repositionShit - 380, -800);
				var treetex = Paths.getPackerAtlas('corruption/weeb/weebTreesnoon');
				bgTrees.frames = treetex;
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				swagBacks['bgTrees'] = bgTrees;
				toAdd.push(bgTrees);

				var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
				treeLeaves.frames = Paths.getSparrowAtlas('corruption/weeb/petalsnoon');
				treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
				treeLeaves.animation.play('leaves');
				treeLeaves.scrollFactor.set(0.85, 0.85);
				swagBacks['treeLeaves'] = treeLeaves;
				toAdd.push(treeLeaves);

				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				fgTrees.setGraphicSize(Std.int(widShit * 0.8));
				treeLeaves.setGraphicSize(widShit);
				bgSkyEvil.setGraphicSize(widShit);
				bgSchoolEvil.setGraphicSize(widShit);
				fgTreesEvil.setGraphicSize(Std.int(widShit * 0.8));
				bgStreetEvil.setGraphicSize(widShit);

				fgTrees.updateHitbox();
				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();
				treeLeaves.updateHitbox();
				fgTreesEvil.updateHitbox();
				bgSkyEvil.updateHitbox();
				bgSchoolEvil.updateHitbox();
				bgStreetEvil.updateHitbox();

				altSuffix = '-pixelcorrupted';
				introAssets = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
			}*/

			case 'schoolEvil':
			{
				camZoom = 1.05;

				var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
				var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

				var bg:FlxSprite = new FlxSprite(400, 200);

				switch (daStage)
				{
					case 'schoolEvil': 
						bg.frames = Paths.getSparrowAtlas('weeb/animatedEvilSchool', 'week6');
						altSuffix = '-pixel';
				}

				bg.animation.addByPrefix('idle', 'background 2', 24);
				bg.animation.play('idle');
				bg.scrollFactor.set(0.8, 0.9);
				bg.scale.set(6, 6);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				introAssets = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
			}

			/*case 'school-monika':
			{
				camZoom = 1.05;
				altSuffix = '-pixel';

				var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/monika/weebSky'));
				bgSky.scrollFactor.set(0.1, 0.1);
				swagBacks['bgSky'] = bgSky;
				toAdd.push(bgSky);

				var repositionShit = -200;

				var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('weeb/monika/weebSchool'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				swagBacks['bgSchool'] = bgSchool;
				toAdd.push(bgSchool);

				var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/monika/weebStreet'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				swagBacks['bgStreet'] = bgStreet;
				toAdd.push(bgStreet);

				var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('weeb/monika/weebTreesBack'));
				fgTrees.scrollFactor.set(0.9, 0.9);
				swagBacks['fgTrees'] = fgTrees;
				toAdd.push(fgTrees);

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				var treetex = Paths.getPackerAtlas('weeb/monika/weebTrees');
				bgTrees.frames = treetex;
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				swagBacks['bgTrees'] = bgTrees;
				toAdd.push(bgTrees);

				var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
				treeLeaves.frames = Paths.getSparrowAtlas('weeb/monika/petals');
				treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
				treeLeaves.animation.play('leaves');
				treeLeaves.scrollFactor.set(0.85, 0.85);
				swagBacks['treeLeaves'] = treeLeaves;
				toAdd.push(treeLeaves);

				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				fgTrees.setGraphicSize(Std.int(widShit * 0.8));
				treeLeaves.setGraphicSize(widShit);

				fgTrees.updateHitbox();
				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();
				treeLeaves.updateHitbox();

				if (songLowercase == "dreams of roses" || songLowercase == "shinkyoku" || songLowercase == "bara no yume")
				{
					var bgGirls2 = new BackgroundGirlsSwitch(-600, 190, 'weeb/monika/bgFreaks');
					bgGirls2.scrollFactor.set(0.9, 0.9);
		
					bgGirls2.setGraphicSize(Std.int(bgGirls2.width * PlayState.daPixelZoom));
					bgGirls2.updateHitbox();
						
					swagBacks['bgGirls2'] = bgGirls2;
					toAdd.push(bgGirls2);
					bgGirls2.dance();
				}

				introAssets = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
			}*/

			case 'tank' | 'tank2':
			{
				camZoom = 0.9;
				
				var yellow:FlxSprite = new FlxSprite().makeGraphic(10, 10, FlxColor.fromRGB(234, 152, 53));
				yellow.setPosition(-350, 700);
				yellow.scale.set(200, 200);
				yellow.scrollFactor.set();
				swagBacks['yellow'] = yellow;
				toAdd.push(yellow);

				var tankSky:FlxSprite = new FlxSprite(-400, -400).loadGraphic(existsInCTA('tank/tankSky'));
				tankSky.antialiasing = true;
				tankSky.scrollFactor.set(0, 0);
				swagBacks['tankSky'] = tankSky;
				toAdd.push(tankSky);
				
				var tankClouds:FlxSprite = new FlxSprite(-700, -100).loadGraphic(existsInCTA('tank/tankClouds'));
				tankClouds.antialiasing = true;
				tankClouds.scrollFactor.set(0.1, 0.1);
				swagBacks['tankClouds'] = tankClouds;
				toAdd.push(tankClouds);
				
				var tankMountains:FlxSprite = new FlxSprite(-300, -20).loadGraphic(existsInCTA('tank/tankMountains'));
				tankMountains.antialiasing = true;
				tankMountains.setGraphicSize(Std.int(tankMountains.width * 1.1));
				tankMountains.scrollFactor.set(0.2, 0.2);
				tankMountains.updateHitbox();
				swagBacks['tankMountains'] = tankMountains;
				toAdd.push(tankMountains);
				
				var tankBuildings:FlxSprite = new FlxSprite(-200, 0).loadGraphic(existsInCTA('tank/tankBuildings'));
				tankBuildings.antialiasing = true;
				tankBuildings.setGraphicSize(Std.int(tankBuildings.width * 1.1));
				tankBuildings.scrollFactor.set(0.3, 0.3);
				tankBuildings.updateHitbox();
				swagBacks['tankBuildings'] = tankBuildings;
				toAdd.push(tankBuildings);
				
				var tankRuins:FlxSprite = new FlxSprite(-200, 0).loadGraphic(existsInCTA('tank/tankRuins'));
				tankRuins.antialiasing = true;
				tankRuins.setGraphicSize(Std.int(tankRuins.width * 1.1));
				tankRuins.scrollFactor.set(0.35, 0.35);
				tankRuins.updateHitbox();
				swagBacks['tankRuins'] = tankRuins;
				toAdd.push(tankRuins);

				var smokeLeft:FlxSprite = new FlxSprite(-200, -100).loadGraphic(existsInCTA('tank/smokeLeft'));
				smokeLeft.frames = existsInCTAAnimated('tank/smokeLeft');
				smokeLeft.animation.addByPrefix('idle', 'SmokeBlurLeft', 24, true);
				smokeLeft.animation.play('idle');
				smokeLeft.scrollFactor.set (0.4, 0.4);
				smokeLeft.antialiasing = true;
				swagBacks['smokeLeft'] = smokeLeft;
				toAdd.push(smokeLeft);

				var smokeRight:FlxSprite = new FlxSprite(1100, -100).loadGraphic(existsInCTA('tank/smokeRight'));
				smokeRight.frames = existsInCTAAnimated('tank/smokeRight');
				smokeRight.animation.addByPrefix('idle', 'SmokeRight', 24, true);
				smokeRight.animation.play('idle');
				smokeRight.scrollFactor.set (0.4, 0.4);
				smokeRight.antialiasing = true;
				swagBacks['smokeRight'] = smokeRight;
				toAdd.push(smokeRight);
				
				var tankWatchtower = new FlxSprite(100, 50);
				tankWatchtower.frames = existsInCTAAnimated('tank/tankWatchtower');
				tankWatchtower.animation.addByPrefix('idle', 'watchtower gradient color', 24, false);
				tankWatchtower.animation.play('idle');
				tankWatchtower.scrollFactor.set(0.5, 0.5);
				tankWatchtower.antialiasing = true;
				swagBacks['tankWatchtower'] = tankWatchtower;
				toAdd.push(tankWatchtower);

				tankRolling = new FlxSprite(300,300);
				tankRolling.frames = existsInCTAAnimated('tank/tankRolling');
				tankRolling.animation.addByPrefix('idle', 'BG tank w lighting ', 24, true);
				tankRolling.scrollFactor.set(0.5, 0.5);
				tankRolling.antialiasing = true;
				tankRolling.animation.play('idle');	
				swagBacks['tankRolling'] = tankRolling;
				toAdd.push(tankRolling);	
				
				var tankGround:FlxSprite = new FlxSprite(-420, -150).loadGraphic(existsInCTA('tank/tankGround'));
				tankGround.setGraphicSize(Std.int(tankGround.width * 1.15));
				tankGround.updateHitbox();
				tankGround.antialiasing = true;
				swagBacks['tankGround'] = tankGround;
				toAdd.push(tankGround);

				var tank0 = new FlxSprite(-500, 650);
				tank0.frames = existsInCTAAnimated('tank/tank0');
				tank0.animation.addByPrefix('idle', 'fg tankhead far right', 24, false);
				tank0.scrollFactor.set(1.7, 1.5);
				tank0.antialiasing = true;
				swagBacks['tank0'] = tank0;
				layInFront[2].push(tank0);

				var tank1 = new FlxSprite(-300, 750);
				tank1.frames = existsInCTAAnimated('tank/tank1');
				tank1.animation.addByPrefix('idle', 'fg', 24, false);
				tank1.scrollFactor.set(2, 0.2);
				tank1.antialiasing = true;
				swagBacks['tank1'] = tank1;
				layInFront[2].push(tank1);

				var tank2 = new FlxSprite(450, 940);
				tank2.frames = existsInCTAAnimated('tank/tank2');
				tank2.animation.addByPrefix('idle', 'foreground', 24, false);
				tank2.scrollFactor.set(1.5, 1.5);
				tank2.antialiasing = true;
				swagBacks['tank2'] = tank2;
				layInFront[2].push(tank2);

				var tank4 = new FlxSprite(1300, 900);
				tank4.frames = existsInCTAAnimated('tank/tank4');
				tank4.animation.addByPrefix('idle', 'fg', 24, false);
				tank4.scrollFactor.set(1.5, 1.5);
				tank4.antialiasing = true;
				swagBacks['tank4'] = tank4;
				layInFront[2].push(tank4);

				var tank5 = new FlxSprite(1620, 700);
				tank5.frames = existsInCTAAnimated('tank/tank5');
				tank5.animation.addByPrefix('idle', 'fg', 24, false);
				tank5.scrollFactor.set(1.5, 1.5);
				tank5.antialiasing = true;
				swagBacks['tank5'] = tank5;
				layInFront[2].push(tank5);

				var tank3 = new FlxSprite(1300, 1200);
				tank3.frames = existsInCTAAnimated('tank/tank3');
				tank3.animation.addByPrefix('idle', 'fg', 24, false);
				tank3.scrollFactor.set(1.5, 1.5);
				tank3.antialiasing = true;
				swagBacks['tank3'] = tank3;
				layInFront[2].push(tank3);

				bfXOffset = 40;
				gfXOffset = -120;
				gfYOffset = -80;
				dadXOffset = -80;
			}

			//let's try this shall we?
			/*
			case 'night' | 'night2':
			{
				camZoom = 0.75;
				curStage = 'night';

				var theEntireFuckingStage:FlxTypedGroup<FlxSprite>;

				theEntireFuckingStage = new FlxTypedGroup<FlxSprite>();
				swagGroup['theEntireFuckingStage'] = theEntireFuckingStage;
				toAdd.push(theEntireFuckingStage);

				var bg1:FlxSprite = new FlxSprite(-970, -580).loadGraphic(Paths.image('b&b/night/BG1'));
				bg1.antialiasing = true;
				bg1.scale.set(0.8, 0.8);
				bg1.scrollFactor.set(0.3, 0.3);
				bg1.active = false;
				theEntireFuckingStage.add(bg1);

				var bg2:FlxSprite = new FlxSprite(-1240, -650).loadGraphic(Paths.image('b&b/night/BG2'));
				bg2.antialiasing = true;
				bg2.scale.set(0.5, 0.5);
				bg2.scrollFactor.set(0.6, 0.6);
				bg2.active = false;
				theEntireFuckingStage.add(bg2);

				if (daStage == 'night2')
				{
					var mini = new FlxSprite(818, 189);
					mini.frames = Paths.getSparrowAtlas('b&b/night/bobsip','shared');
					mini.animation.addByPrefix('idle', 'bobsip', 24, false);
					mini.animation.play('idle');
					mini.scale.set(0.5, 0.5);
					mini.scrollFactor.set(0.6, 0.6);
					theEntireFuckingStage.add(mini);			
				}

				var bg3:FlxSprite = new FlxSprite(-630, -330).loadGraphic(Paths.image('b&b/night/BG3'));
				bg3.antialiasing = true;
				bg3.scale.set(0.8, 0.8);
				bg3.active = false;
				theEntireFuckingStage.add(bg3);

				var bg4:FlxSprite = new FlxSprite(-1390, -740).loadGraphic(Paths.image('b&b/night/BG4'));
				bg4.antialiasing = true;
				bg4.scale.set(0.6, 0.6);
				bg4.active = false;
				theEntireFuckingStage.add(bg4);

				var bg5:FlxSprite = new FlxSprite(-34, 90);
				bg5.antialiasing = true;
				bg5.scale.set(1.4, 1.4);
				bg5.frames = Paths.getSparrowAtlas('b&b/night/pixelthing');
				bg5.animation.addByPrefix('idle', 'pixelthing', 24);
				bg5.animation.play('idle');
				swagBacks['bg5'] = bg5;
				toAdd.push(bg5);

				var pc = new FlxSprite(115, 166);
				pc.frames = Paths.getSparrowAtlas('characters/pc');
				pc.animation.addByPrefix('idle', 'PC idle', 24, false);
				pc.animation.addByPrefix('singUP', 'PC Note UP', 24, false);
				pc.animation.addByPrefix('singDOWN', 'PC Note DOWN', 24, false);
				pc.animation.addByPrefix('singLEFT', 'PC Note LEFT', 24, false);
				pc.animation.addByPrefix('singRIGHT', 'PC Note RIGHT', 24, false);
				swagBacks['pc'] = pc;
				toAdd.push(pc);

				theEntireFuckingStage = new FlxTypedGroup<FlxSprite>();
				swagGroup['theEntireFuckingStage'] = theEntireFuckingStage;
				toAdd.push(theEntireFuckingStage);

				var phillyCityLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['phillyCityLights'] = phillyCityLights;
				toAdd.push(phillyCityLights);

				var coolGlowyLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['coolGlowyLights'] = coolGlowyLights;
				toAdd.push(coolGlowyLights);

				var coolGlowyLightsMirror = new FlxTypedGroup<FlxSprite>();
				swagGroup['coolGlowyLightsMirror'] = coolGlowyLightsMirror;
				toAdd.push(coolGlowyLightsMirror);

				for (i in 0...4)
				{
					var light:FlxSprite = new FlxSprite().loadGraphic(Paths.image('b&b/night/light' + i));
					light.scrollFactor.set(0, 0);
					if (!preloading)
						light.cameras = [PlayState.instance.camHUD];
					light.visible = false;
					light.updateHitbox();
					light.antialiasing = true;
					phillyCityLights.add(light);
					swagBacks['light' + i] = light;

					var glow:FlxSprite = new FlxSprite().loadGraphic(Paths.image('b&b/night/Glow' + i));
					glow.scrollFactor.set(0, 0);
					if (!preloading)
						glow.cameras = [PlayState.instance.camHUD];
					glow.visible = false;
					glow.updateHitbox();
					glow.antialiasing = true;
					coolGlowyLights.add(glow);
					swagBacks['glow' + i] = glow;

					var glow2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('b&b/night/Glow' + i));
					glow2.scrollFactor.set(0, 0);
					if (!preloading)
						glow2.cameras = [PlayState.instance.camHUD];
					glow2.visible = false;
					glow2.updateHitbox();
					glow2.antialiasing = true;
					coolGlowyLightsMirror.add(glow2);
					swagBacks['glow2' + i] = glow2;
				}

				var areYouReady = new FlxTypedGroup<FlxSprite>();
				swagGroup['areYouReady'] = areYouReady;
				toAdd.push(areYouReady);

				for (i in 0...3) {
					var shit:FlxSprite = new FlxSprite();
					switch (i) {
						case 0:
							shit = new FlxSprite().loadGraphic(Paths.image('b&b/ARE'));
						case 1:
							shit = new FlxSprite().loadGraphic(Paths.image('b&b/YOU'));
						case 2:
							shit = new FlxSprite().loadGraphic(Paths.image('b&b/READY'));
					}
					if (!preloading)
						shit.cameras = [PlayState.instance.camHUD];
					shit.visible = false;
					areYouReady.add(shit);
					swagBacks['shit' + i] = shit;
				} 
			}

			/*case 'city-christmas':
			{
				//f me. i need a way to convert psych lua's for stages too.

				camZoom = 4;

				var sky:FlxSprite = new FlxSprite().loadGraphic(Paths.image('city/sky'));
				sky.antialiasing = false;
				sky.setPosition(200, 115);
				sky.scrollFactor.set(0.5, 0.5);
				swagBacks['sky'] = sky;
				toAdd.push(sky);	
				
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('city/bg'));
				bg.antialiasing = false;
				bg.setPosition(0, 0);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var layer3:FlxSprite = new FlxSprite();
				layer3.frames = Paths.getSparrowAtlas('city/layer3');
				layer3.antialiasing = false;
				layer3.setPosition(0, 0);
				layer3.animation.addByPrefix('idle', 'idle', 2, true);
				layer3.animation.play('idle');
				swagBacks['layer3'] = layer3;
				toAdd.push(layer3);
		
				var layer2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('city/layer2'));
				layer2.antialiasing = false;
				layer2.setPosition(0, 0);
				swagBacks['layer2'] = layer2;
				toAdd.push(layer2);

				var layer1:FlxSprite = new FlxSprite();
				layer1.frames = Paths.getSparrowAtlas('city/layer1');
				layer1.antialiasing = false;
				layer1.setPosition(30, 0);
				layer1.animation.addByPrefix('idle', 'idle', 2, true);
				layer1.animation.play('idle');
				swagBacks['layer1'] = layer1;
				toAdd.push(layer1);
		
				var snow:FlxSprite = new FlxSprite().loadGraphic(Paths.image('city/snow'));
				snow.antialiasing = false;
				snow.setPosition(0, 0);
				swagBacks['snow'] = snow;
				toAdd.push(snow);

				var crtscreen:FlxSprite = new FlxSprite().loadGraphic(Paths.image('city/crtscreen'));
				crtscreen.antialiasing = false;
				crtscreen.setPosition(0, 0);
				crtscreen.scrollFactor.set(160, 90); //???
				crtscreen.scale.set(4,4);
				if (!preloading)
					crtscreen.cameras = [PlayState.instance.camOther];
				swagBacks['crtscreen'] = crtscreen;
				layInFront[2].push(crtscreen);
			
				var bars:FlxSprite = new FlxSprite().loadGraphic(Paths.image('city/bars'));
				bars.antialiasing = false;
				bars.scrollFactor.set(160, 90); //???'
				bars.scale.set(4,4);
				bars.screenCenter();
				if (!preloading)
					bars.cameras = [PlayState.instance.camOther];
				swagBacks['bars'] = bars;
				layInFront[2].push(bars);		
			}

			case 'hellsKitchen':
			{
				camZoom = 0.9;

				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('holofunk/christmas/evilBG'));
				bg.antialiasing = true;
				bg.setPosition(-600, -300);
				bg.scrollFactor.set(0.9, 0.9);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				//idk where this is used. Oh it's used when the fire erupts
				/*var fireGlow:FlxSprite = new FlxSprite().loadGraphic(Paths.image('holofunk/christmas/fireGlow'));
				fireGlow.antialiasing = true;
				fireGlow.setPosition(-610, -375);
				fireGlow.scrollFactor.set(0.9, 0.9);
				swagBacks['fireGlow'] = fireGlow;
				toAdd.push(fireGlow);

				var tree:FlxSprite = new FlxSprite().loadGraphic(Paths.image('holofunk/christmas/evilTree'));
				tree.antialiasing = true;
				tree.setPosition(300, -100);
				tree.scrollFactor.set(0.9, 0.9);
				swagBacks['tree'] = tree;
				toAdd.push(tree);

				var overlay:FlxSprite = new FlxSprite().loadGraphic(Paths.image('holofunk/christmas/overlayEvil'));
				overlay.antialiasing = true;
				overlay.scrollFactor.set(0.9, 0.9);
				if (!preloading)
					overlay.cameras = [PlayState.instance.camOther];
				swagBacks['overlay'] = overlay;
				toAdd.push(overlay);

				pixelShitPart1 = 'holofunk/ui/';
				bfXOffset = 320;
				bfYOffset = 300;
				gfYOffset = 300;
				dadYOffset = 300;
			}

			case 'polus' | 'polus2':
			{
				camZoom = 0.9;

				var sky:FlxSprite = new FlxSprite(-834.3, -620.5).loadGraphic(Paths.image('impostor/polus/polusSky'));
				sky.antialiasing = true;
				sky.scrollFactor.set(0.5, 0.5);
				sky.active = false;
				swagBacks['sky'] = sky;
				toAdd.push(sky);	

				var rocks:FlxSprite = new FlxSprite(-915.8, -411.3).loadGraphic(Paths.image('impostor/polus/polusrocks'));
				rocks.updateHitbox();
				rocks.antialiasing = true;
				rocks.scrollFactor.set(0.6, 0.6);
				rocks.active = false;
				swagBacks['rocks'] = rocks;
				toAdd.push(rocks);
				
				var hills:FlxSprite = new FlxSprite(-1238.05, -180.55).loadGraphic(Paths.image('impostor/polus/polusHills'));
				hills.updateHitbox();
				hills.antialiasing = true;
				hills.scrollFactor.set(0.9, 0.9);
				hills.active = false;
				swagBacks['hills'] = hills;
				toAdd.push(hills);

				var warehouse:FlxSprite = new FlxSprite(-458.35, -315.6).loadGraphic(Paths.image('impostor/polus/polusWarehouse'));
				warehouse.updateHitbox();
				warehouse.antialiasing = true;
				warehouse.scrollFactor.set(0.9, 0.9);
				warehouse.active = false;
				swagBacks['warehouse'] = warehouse;
				toAdd.push(warehouse);

				if (daStage == 'polus2')
				{
					var crowd:FlxSprite = new FlxSprite(-280.5, 240.8);
					crowd.frames = Paths.getSparrowAtlas('impostor/polus/CrowdBop');
					crowd.animation.addByPrefix('idle', 'CrowdBop', 24, false);
					crowd.animation.play('idle');
					crowd.scrollFactor.set(1, 1);
					crowd.antialiasing = true;
					crowd.updateHitbox();
					crowd.scale.set(1.5, 1.5);
					swagBacks['crowd'] = crowd;
					animatedBacks.push(crowd);
					toAdd.push(crowd);
					
					var deadBF = new FlxSprite(532.95, 465.95).loadGraphic(Paths.image('impostor/polus/bfdead'));
					deadBF.antialiasing = true;
					deadBF.scrollFactor.set(1, 1);
					deadBF.updateHitbox();	
					swagBacks['deadBF'] = deadBF;
					layInFront[0].push(deadBF);
				}

				var ground:FlxSprite = new FlxSprite(-580.9, 241.85).loadGraphic(Paths.image('impostor/polus/polusGround'));
				ground.updateHitbox();
				ground.antialiasing = true;
				ground.scrollFactor.set(1, 1);
				ground.active = false;
				swagBacks['ground'] = ground;
				toAdd.push(ground);
			}	

			case 'reactor' | 'reactor-m':
			{
				camZoom = 0.5;
				
				var bg:FlxSprite = new FlxSprite(-2300,-1700).loadGraphic(Paths.image('impostor/reactor/reactor background'));
				bg.setGraphicSize(Std.int(bg.width * 0.7));
				bg.antialiasing = true;
				bg.scrollFactor.set(1, 1);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				if (daStage == 'reactor')
				{
					var yellow = new FlxSprite(-400, 150);
					yellow.frames = Paths.getSparrowAtlas('impostor/reactor/susBoppers');
					yellow.animation.addByPrefix('idle', 'yellow sus', 24, false);
					yellow.animation.play('idle');
					yellow.setGraphicSize(Std.int(yellow.width * 0.7));
					yellow.antialiasing = true;
					yellow.scrollFactor.set(1, 1);
					yellow.active = true;
					swagBacks['yellow'] = yellow;
					toAdd.push(yellow);
				}
	
				var pillar1:FlxSprite = new FlxSprite(-2300,-1700).loadGraphic(Paths.image('impostor/reactor/back pillars'));
				pillar1.setGraphicSize(Std.int(pillar1.width * 0.7));
				pillar1.antialiasing = true;
				pillar1.scrollFactor.set(1, 1);
				pillar1.active = false;
				swagBacks['pillar1'] = pillar1;
				toAdd.push(pillar1);

				if (daStage == 'reactor')
				{
					var dripster = new FlxSprite(1375, 150);
					dripster.frames = Paths.getSparrowAtlas('impostor/reactor/susBoppers');
					dripster.animation.addByPrefix('idle', 'blue sus', 24, false);
					dripster.animation.play('idle');
					dripster.setGraphicSize(Std.int(dripster.width * 0.7));
					dripster.antialiasing = true;
					dripster.scrollFactor.set(1, 1);
					dripster.active = true;
					swagBacks['dripster'] = dripster;
					toAdd.push(dripster);	
				}
				
				var pillar2:FlxSprite = new FlxSprite(-2300,-1700).loadGraphic(Paths.image('impostor/reactor/middle pillars'));
				pillar2.setGraphicSize(Std.int(pillar2.width * 0.7));
				pillar2.antialiasing = true;
				pillar2.scrollFactor.set(1, 1);
				pillar2.active = false;
				swagBacks['pillar2'] = pillar2;
				toAdd.push(pillar2);

				if (daStage == 'reactor')
				{
					var amogus = new FlxSprite(1670, 250);
					amogus.frames = Paths.getSparrowAtlas('impostor/reactor/susBoppers');
					amogus.animation.addByPrefix('idle', 'white sus', 24, false);
					amogus.animation.play('idle');
					amogus.setGraphicSize(Std.int(amogus.width * 0.7));
					amogus.antialiasing = true;
					amogus.scrollFactor.set(1, 1);
					amogus.active = true;
					swagBacks['amogus'] = amogus;
					toAdd.push(amogus);

					var brown = new FlxSprite(-850, 190);
					brown.frames = Paths.getSparrowAtlas('impostor/reactor/susBoppers');
					brown.animation.addByPrefix('idle', 'brown sus', 24, false);
					brown.animation.play('idle');
					brown.setGraphicSize(Std.int(brown.width * 0.7));
					brown.antialiasing = true;
					brown.scrollFactor.set(1, 1);
					brown.active = true;
					swagBacks['brown'] = brown;
					toAdd.push(brown);
				}

				var pillar3:FlxSprite = new FlxSprite(-2300,-1700).loadGraphic(Paths.image('impostor/reactor/front pillars'));
				pillar3.setGraphicSize(Std.int(pillar3.width * 0.7));
				pillar3.antialiasing = true;
				pillar3.scrollFactor.set(1, 1);
				pillar3.active = false;
				swagBacks['pillar3'] = pillar3;
				toAdd.push(pillar3);

				var path:String;
				if (daStage == 'reactor-m')
					path = Paths.image('impostor/reactor/the device');
				else
					path = Paths.image('impostor/reactor/ball of big ol energy');

				var orb = new FlxSprite(-460,-1300).loadGraphic(path);
				orb.setGraphicSize(Std.int(orb.width * 0.7));
				orb.antialiasing = true;
				orb.scrollFactor.set(1, 1);
				orb.active = false;
				swagBacks['orb'] = orb;
				toAdd.push(orb);

				var cranes:FlxSprite = new FlxSprite(-735, -1500).loadGraphic(Paths.image('impostor/reactor/upper cranes'));
				cranes.setGraphicSize(Std.int(cranes.width * 0.7));
				cranes.antialiasing = true;
				cranes.scrollFactor.set(1, 1);
				cranes.active = false;
				swagBacks['cranes'] = cranes;
				toAdd.push(cranes);

				var console1:FlxSprite = new FlxSprite(-260,150).loadGraphic(Paths.image('impostor/reactor/center console'));
				console1.setGraphicSize(Std.int(console1.width * 0.7));
				console1.antialiasing = true;
				console1.scrollFactor.set(1, 1);
				console1.active = false;
				swagBacks['console1'] = console1;
				toAdd.push(console1);

				if (daStage == 'reactor-m')
				{
					var fortnite1 = new FlxSprite();
					fortnite1.frames = Paths.getSparrowAtlas('impostor/reactor/fortnite1');
					fortnite1.animation.addByPrefix('idle', 'Bottom Level Boppers', 24, false);
					fortnite1.animation.play('idle');
					fortnite1.antialiasing = true;
					fortnite1.scrollFactor.set(1, 1);
					fortnite1.active = true;
					fortnite1.setPosition(-850, -200);
					swagBacks['fortnite1'] = fortnite1;
					toAdd.push(fortnite1);

					var fortnite2 = new FlxSprite();
					fortnite2.frames = Paths.getSparrowAtlas('impostor/reactor/fortnite2');
					fortnite2.animation.addByPrefix('idle', 'Bottom Level Boppers', 24, false);
					fortnite2.animation.play('idle');
					fortnite2.antialiasing = true;
					fortnite2.scrollFactor.set(1, 1);
					fortnite2.active = true;
					fortnite2.setPosition(1000, -200);
					swagBacks['fortnite2'] = fortnite2;
					toAdd.push(fortnite2);
				}

				var console2:FlxSprite = new FlxSprite(-1380,450).loadGraphic(Paths.image('impostor/reactor/side console'));
				console2.setGraphicSize(Std.int(console2.width * 0.7));
				console2.antialiasing = true;
				console2.scrollFactor.set(1, 1);
				console2.active = false;
				swagBacks['console2'] = console2;
				toAdd.push(console2);
				
				var ass2 = new FlxSprite(0, FlxG.height * 1).loadGraphic(Paths.image('impostor/vignette')); 
				ass2.scrollFactor.set();
				ass2.screenCenter();
				if (!preloading)
					ass2.cameras = [PlayState.instance.camHUD];
				swagBacks['ass2'] = ass2;
				layInFront[2].push(ass2);
			}

			case 'bfroom':
			{
				camZoom = 1;

				var bg = new FlxSprite().loadGraphic(Paths.image('bg_doxxie'));
				bg.setPosition(-184.35, -315.45);
				swagBacks['bg'] = bg;
				toAdd.push(bg);
			}

			case 'gfroom':
			{
				camZoom = 0.9;

				var sky:FlxSprite = new FlxSprite(100, 100).loadGraphic(Paths.image('philly/sky', 'week3'));
				sky.scrollFactor.set(1, 1);
				sky.setGraphicSize(Std.int(sky.width * 0.7));
				sky.updateHitbox();
				swagBacks['sky'] = sky;
				toAdd.push(sky);

				var city:FlxSprite = new FlxSprite(190, 100).loadGraphic(Paths.image('philly/city', 'week3'));
				city.scrollFactor.set(1, 1);
				city.setGraphicSize(Std.int(city.width * 0.55));
				city.updateHitbox();
				swagBacks['city'] = city;
				toAdd.push(city);

				var phillyCityLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['phillyCityLights'] = phillyCityLights;
				toAdd.push(phillyCityLights);

				for (i in 0...5)
				{
					var light:FlxSprite = new FlxSprite(city.x, city.y).loadGraphic(Paths.image('philly/win' + i, 'week3'));
					light.scrollFactor.set(1, 1);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.55));
					light.updateHitbox();
					light.antialiasing = true;
					phillyCityLights.add(light);
					swagBacks['light' + i] = light;
				}

				var bg = new FlxSprite(-600, -200).loadGraphic(Paths.image('RoomBG'));
				bg.setGraphicSize(Std.int(bg.width * 1.8));
				bg.updateHitbox();
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var tv = new FlxSprite(-370, 148).loadGraphic(Paths.image('tvLight'));
				tv.setGraphicSize(Std.int(tv.width * 1.8));
				tv.updateHitbox();
				tv.antialiasing = true;
				tv.scrollFactor.set(0.9, 0.9);
				tv.active = false;
				swagBacks['tv'] = tv;
				toAdd.push(tv);

				if (songLowercase == 'you-cant-run')
				{
					var tv2 = new FlxSprite(-370, 148).loadGraphic(Paths.image('tvSchool'));
					tv2.setGraphicSize(Std.int(tv2.width * 1.8));
					tv2.updateHitbox();
					tv2.antialiasing = true;
					tv2.scrollFactor.set(0.9, 0.9);
					tv2.active = false;
					swagBacks['tv2'] = tv2;
					toAdd.push(tv2);
				}		
			}
			
			case 'space': 
			{
				camZoom = 0.7;

				var spaceBG:FlxSprite = new FlxSprite(-450, -160).loadGraphic(Paths.image('space/spaceBG'));
				spaceBG.setGraphicSize(Std.int(spaceBG.width * 1.5));
				spaceBG.updateHitbox();
				spaceBG.antialiasing = true;
				spaceBG.scrollFactor.set(0.1, 0.1);
				spaceBG.active = false;
				swagBacks['spaceBG'] = spaceBG;
				toAdd.push(spaceBG);

				var holoBoppers = new FlxSprite(-410, -360);
				holoBoppers.frames = Paths.getSparrowAtlas('space/holoBop');
				holoBoppers.animation.addByPrefix('idle', 'Holo Boppers', 24, false);
				holoBoppers.antialiasing = true;
				holoBoppers.scrollFactor.set(0.2, 0.2);
				holoBoppers.setGraphicSize(Std.int(holoBoppers.width * 1.2));
				holoBoppers.updateHitbox();
				swagBacks['holoBoppers'] = holoBoppers;
				animatedBacks.push(holoBoppers);
				toAdd.push(holoBoppers);	
				
				new FlxTimer().start(3.2, function(tmr:FlxTimer)
				{
					if(holoBoppers.y == -330) FlxTween.tween(holoBoppers, {y: -360}, 3.1, 
						{ease: FlxEase.quadInOut});
					else  FlxTween.tween(holoBoppers, {y: -330}, 3.1, 
						{ease: FlxEase.quadInOut});
				}, 0);		

				var spacerocks:FlxSprite = new FlxSprite(-360, -30).loadGraphic(Paths.image('space/spacerocks'));	
				spacerocks.updateHitbox();			
				spacerocks.antialiasing = true;
				spacerocks.scrollFactor.set(0.4, 0.4);
				spacerocks.active = false;
				swagBacks['spacerocks'] = spacerocks;
				toAdd.push(spacerocks);

				new FlxTimer().start(3, function(tmr:FlxTimer)
				{
					if(spacerocks.y == -65) FlxTween.tween(spacerocks, {y: -30}, 2.9, 
						{ease: FlxEase.quadInOut});
					else  FlxTween.tween(spacerocks, {y: -65}, 2.9, 
						{ease: FlxEase.quadInOut});
				}, 0);

				var spacestage:FlxSprite = new FlxSprite(-500, -220).loadGraphic(Paths.image('space/spacestage'));
				spacestage.setGraphicSize(Std.int(spacestage.width * 1.2));
				spacestage.updateHitbox();
				spacestage.antialiasing = true;
				spacestage.active = false;
				swagBacks['spacestage'] = spacestage;
				toAdd.push(spacestage);

				var spacerocksFG:FlxSprite = new FlxSprite(-1620, -160).loadGraphic(Paths.image('space/spacerocksFG'));
				spacerocksFG.setGraphicSize(Std.int(spacerocksFG.width * 1.3));
				spacerocksFG.updateHitbox();			
				spacerocksFG.antialiasing = true;
				spacerocksFG.scrollFactor.set(1.6, 1.6);
				spacerocksFG.active = false;
				swagBacks['spacerocksFG'] = spacerocksFG;
				toAdd.push(spacerocksFG);

				new FlxTimer().start(3, function(tmr:FlxTimer)
				{
					if(spacerocksFG.y == -120) FlxTween.tween(spacerocksFG, {y: -160}, 2.9, 
						{ease: FlxEase.quadInOut});
					else  FlxTween.tween(spacerocksFG, {y: -120}, 2.9, 
						{ease: FlxEase.quadInOut});
				}, 0);
			}

			case 'nyan':
			{
				camZoom = 0.9;

				var bg = new FlxSprite().loadGraphic(Paths.image('nyan/nyancatbg'));
				swagBacks['bg'] = bg;
				bg.setPosition(-750, -575);
				toAdd.push(bg);

				var gfRock = new FlxSprite().loadGraphic(Paths.image('nyan/ROCKgf'));
				gfRock.setGraphicSize(Std.int(gfRock.width * 2));
				gfRock.updateHitbox();
				gfRock.setPosition(-400, -770);
				swagBacks['gfRock'] = gfRock;
				toAdd.push(gfRock);

				var bfRock = new FlxSprite().loadGraphic(Paths.image('nyan/ROCKbf'));
				swagBacks['bfRock'] = bfRock;
				bfRock.setPosition(420, 100);
				layInFront[1].push(bfRock);
			}

			case 'pillars':
			{
				camZoom = 0.55;

				var white:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 5, FlxG.height * 5, FlxColor.fromRGB(255, 230, 230));
				white.screenCenter();
				white.scrollFactor.set();
				swagBacks['white'] = white;
				toAdd.push(white);

				var void:FlxSprite = new FlxSprite(0, 0);
				void.frames = Paths.getSparrowAtlas('entity/agoti/the_void');
				void.animation.addByPrefix('move', 'VoidShift', 50, true);
				void.animation.play('move');
				void.setGraphicSize(Std.int(void.width * 2.5));
				void.screenCenter();
				void.y += 250;
				void.x += 55;
				void.antialiasing = true;
				void.scrollFactor.set(0.7, 0.7);
				swagBacks['void'] = void;
				toAdd.push(void);

				var bgpillar:FlxSprite = new FlxSprite(-1000, -700);
				bgpillar.frames = Paths.getSparrowAtlas('entity/agoti/Pillar_BG_Stage');
				bgpillar.animation.addByPrefix('move', 'Pillar_BG', 24, true);
				bgpillar.animation.play('move');
				bgpillar.setGraphicSize(Std.int(bgpillar.width * 1.25));
				bgpillar.antialiasing = true;
				bgpillar.scrollFactor.set(0.7, 0.7);
				swagBacks['bgpillar'] = bgpillar;
				toAdd.push(bgpillar);

				if (PlayState.isNeonight && songLowercase == 'crucify')
				{
					var rock:FlxSprite = new FlxSprite().loadGraphic(Paths.image('entity/agoti/rock'));
					rock.setPosition(600,250);
					rock.scrollFactor.set(0.95, 0.95);
					swagBacks['rock'] = rock;
					toAdd.push(rock);
				}

				var speaker = new FlxSprite(-650, 600);
				speaker.frames = Paths.getSparrowAtlas('entity/agoti/LoudSpeaker_Moving');
				speaker.animation.addByPrefix('bop', 'StereoMoving', 24, false);
				speaker.updateHitbox();
				speaker.antialiasing = true;
				swagBacks['speaker'] = speaker;
				toAdd.push(speaker);

				bfXOffset = 100;
			}

			case 'dokiclubroom-sayori' | 'dokiclubroom-natsuki' | 'dokiclubroom-yuri' | 'dokiclubroom-monika':
			{
				camZoom = 0.75;

				var posX = -700;
				var posY = -520;
		
				if (songLowercase != 'obsession')
				{
					var vignette = new FlxSprite(0, 0).loadGraphic(Paths.image('doki/vignette'));
					vignette.antialiasing = true;
					vignette.scrollFactor.set();
					vignette.alpha = 0;	
					if (!preloading)
						vignette.cameras = [PlayState.instance.camHUD];
					vignette.setGraphicSize(Std.int(vignette.width / FlxG.width));
					vignette.updateHitbox();
					vignette.screenCenter(XY);
				}

				// antialiasing doesn't work on backdrops *sniffles*
				var sparkleBG = new FlxBackdrop(Paths.image('doki/clubroom/YuriSparkleBG'), 0.1, 0, true, false);
				sparkleBG.velocity.set(-16, 0);
				sparkleBG.visible = false;
				if (!preloading)
				sparkleBG.setGraphicSize(Std.int(sparkleBG.width / PlayState.instance.defaultCamZoom));
				sparkleBG.updateHitbox();
				sparkleBG.screenCenter(XY);

				var sparkleFG = new FlxBackdrop(Paths.image('doki/clubroom/YuriSparkleFG'), 0.1, 0, true, false);
				sparkleFG.velocity.set(-48, 0);
				if (!preloading)
					sparkleFG.setGraphicSize(Std.int((sparkleFG.width * 1.2) / PlayState.instance.defaultCamZoom));
				sparkleFG.updateHitbox();
				sparkleFG.screenCenter(XY);

				var bakaOverlay = new FlxSprite(0, 0);
				bakaOverlay.frames = Paths.getSparrowAtlas('doki/clubroom/BakaBGDoodles');
				bakaOverlay.antialiasing = true;
				bakaOverlay.animation.addByPrefix('normal', 'Normal Overlay', 24, true);
				bakaOverlay.animation.addByPrefix('party rock is', 'Rock Overlay', 24, true);
				bakaOverlay.animation.play('normal');
				bakaOverlay.scrollFactor.set();
				bakaOverlay.visible = false;
				if (!preloading)
					bakaOverlay.cameras = [PlayState.instance.camHUD];
				bakaOverlay.setGraphicSize(Std.int(FlxG.width / FlxG.save.data.zoom));
				bakaOverlay.updateHitbox();
				bakaOverlay.screenCenter(XY);

				swagBacks['bakaOverlay'] = bakaOverlay;
				toAdd.push(bakaOverlay);
					
				var staticshock = new FlxSprite(0, 0);
				staticshock.frames = Paths.getSparrowAtlas('doki/clubroom/staticshock');
				staticshock.antialiasing = true;
				staticshock.animation.addByPrefix('idle', 'hueh', 24, true);
				staticshock.animation.play('idle');
				staticshock.scrollFactor.set();
				staticshock.alpha = .6;
				staticshock.blend = SUBTRACT;
				staticshock.visible = false;
				if (!preloading)
					staticshock.cameras = [PlayState.instance.camHUD];
				staticshock.setGraphicSize(Std.int(staticshock.width / FlxG.save.data.zoom));
				staticshock.updateHitbox();
				staticshock.screenCenter(XY);

				var deskfront = new FlxSprite(posX, posY).loadGraphic(Paths.image('doki/clubroom/DesksFront'));
				deskfront.setGraphicSize(Std.int(deskfront.width * 1.6));
				deskfront.updateHitbox();
				deskfront.antialiasing = true;
				deskfront.scrollFactor.set(1.3, 0.9);

				var closet:FlxSprite = new FlxSprite(posX, posY).loadGraphic(Paths.image('doki/clubroom/DDLCfarbg'));
				closet.setGraphicSize(Std.int(closet.width * 1.6));
				closet.updateHitbox();
				closet.antialiasing = true;
				closet.scrollFactor.set(0.9, 0.9);
				swagBacks['closet'] = closet;
				toAdd.push(closet);

				var clubroom:FlxSprite = new FlxSprite(posX, posY).loadGraphic(Paths.image('doki/clubroom/DDLCbg'));
				clubroom.setGraphicSize(Std.int(clubroom.width * 1.6));
				clubroom.updateHitbox();
				clubroom.antialiasing = true;
				clubroom.scrollFactor.set(1, 0.9);
				swagBacks['clubroom'] = clubroom;
				toAdd.push(clubroom);

				// Time to add these BG dorks

				var monika = new FlxSprite(0, 0);
				monika.frames = Paths.getSparrowAtlas('doki/bgdoki/monika');
				monika.animation.addByPrefix('idle', "Moni BG", 24, false);
				monika.antialiasing = true;
				monika.scrollFactor.set(1, 0.9);
				monika.setGraphicSize(Std.int(monika.width * .7));
				monika.updateHitbox();

				var sayori = new FlxSprite(0, 0);
				sayori.frames = Paths.getSparrowAtlas('doki/bgdoki/sayori');
				sayori.animation.addByPrefix('idle', "Sayori BG", 24, false);
				sayori.antialiasing = true;
				sayori.scrollFactor.set(1, 0.9);
				sayori.setGraphicSize(Std.int(sayori.width * .7));
				sayori.updateHitbox();

				var natsuki = new FlxSprite(0, 0);
				natsuki.frames = Paths.getSparrowAtlas('doki/bgdoki/natsuki');
				natsuki.animation.addByPrefix('idle', "Natsu BG", 24, false);
				natsuki.antialiasing = true;
				natsuki.scrollFactor.set(1, 0.9);
				natsuki.setGraphicSize(Std.int(natsuki.width * .7));
				natsuki.updateHitbox();

				var protag = new FlxSprite(0, 0);
				protag.frames = Paths.getSparrowAtlas('doki/bgdoki/protag');
				protag.animation.addByPrefix('idle', "Protag-kun BG", 24, false);
				protag.antialiasing = true;
				protag.scrollFactor.set(1, 0.9);
				protag.setGraphicSize(Std.int(protag.width * .7));
				protag.updateHitbox();

				var yuri = new FlxSprite(0, 0);
				yuri.frames = Paths.getSparrowAtlas('doki/bgdoki/yuri');
				yuri.animation.addByPrefix('idle', "Yuri BG", 24, false);
				yuri.antialiasing = true;
				yuri.scrollFactor.set(1, 0.9);
				yuri.setGraphicSize(Std.int(yuri.width * .7));
				yuri.updateHitbox();

				swagBacks['sparkleBG'] = sparkleBG;
				toAdd.push(sparkleBG);

				pixelShitPart1 = 'doki/ui/';

				switch (daStage)
				{
					case "dokiclubroom-sayori":
					{
						// Sayori week
						swagBacks['yuri'] = yuri;
						toAdd.push(yuri);
						yuri.x = -74;
						yuri.y = 176;
						swagBacks['natsuki'] = natsuki;
						toAdd.push(natsuki);
						natsuki.x = 1088;
						natsuki.y = 275;
					}
					case "dokiclubroom-natsuki":
					{
						swagBacks['yuri'] = yuri;
						toAdd.push(yuri);
						yuri.x = 130;
						yuri.y = 176;
						swagBacks['sayori'] = sayori;
						toAdd.push(sayori);
						sayori.x = 1050;
						sayori.y = 250;
					}
					case "dokiclubroom-yuri":
					{
						swagBacks['sayori'] = sayori;
						toAdd.push(sayori);
						sayori.x = -49;
						sayori.y = 247;
						swagBacks['natsuki'] = natsuki;
						toAdd.push(natsuki);
						natsuki.x = 1044;
						natsuki.y = 290;
						swagBacks['monika'] = monika;
						toAdd.push(monika);
						monika.x = 1207;
						monika.y = 173;
					}
					case "dokiclubroom-monika":
					{
						swagBacks['sayori'] = sayori;
						toAdd.push(sayori);
						sayori.x = 134;
						sayori.y = 246;
						swagBacks['natsuki'] = natsuki;
						toAdd.push(natsuki);
						natsuki.x = 1044;
						natsuki.y = 290;
						swagBacks['yuri'] = yuri;
						toAdd.push(yuri);
						yuri.x = -74;
						yuri.y = 176;
					}
				}
			}

			case 'clubroomevil':
			{
				camZoom = 0.8;

				var scale = 1;
				var posX = -350;
				var posY = -167;

				var space = new FlxBackdrop(Paths.image('doki/bigmonika/Sky'), 0.1, 0.1);
				space.velocity.set(-10, 0);
				// space.scale.set(1.65, 1.65);
				swagBacks['space'] = space;
				toAdd.push(space);
				
				var bg:FlxSprite = new FlxSprite(posX, posY).loadGraphic(Paths.image('doki/bigmonika/BG'));
				bg.antialiasing = true;
				// bg.scale.set(2.3, 2.3);
				bg.scrollFactor.set(0.4, 0.6);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var stageFront:FlxSprite = new FlxSprite(-452, -77).loadGraphic(Paths.image('doki/bigmonika/FG'));
				stageFront.antialiasing = true;
				// stageFront.scale.set(1.5, 1.5);
				stageFront.scrollFactor.set(1, 1);
				swagBacks['stageFront'] = stageFront;
				toAdd.push(stageFront);

				var popup = new FlxSprite(312, 432);
				popup.frames = Paths.getSparrowAtlas('doki/bigmonika/bigika_delete');
				popup.animation.addByPrefix('idle', "PopUpAnim", 24, false);
				popup.antialiasing = true;
				popup.scrollFactor.set(1, 1);
				popup.setGraphicSize(Std.int(popup.width * 1));
				popup.updateHitbox();
				popup.animation.play('idle', true);
				if (songLowercase != 'epiphany') popup.visible = false;
				swagBacks['popup'] = popup;
				layInFront[2].push(popup);

				pixelShitPart1 = 'doki/ui/';	
			}

			case 'ITB':
			{
				camZoom = 0.70;

				var bg17:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 5'));
				bg17.antialiasing = true;
				bg17.scrollFactor.set(0.3, 0.3);
				bg17.active = false;
				swagBacks['bg17'] = bg17;
				toAdd.push(bg17);

				var bg16:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 4'));
				bg16.antialiasing = true;
				bg16.scrollFactor.set(0.4, 0.4);
				bg16.active = false;
				swagBacks['bg16'] = bg16;
				toAdd.push(bg16);

				var bg15:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 3'));
				bg15.antialiasing = true;
				bg15.scrollFactor.set(0.6, 0.6);
				bg15.active = false;
				swagBacks['bg15'] = bg15;
				toAdd.push(bg15);

				var bg14:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 2'));
				bg14.antialiasing = true;
				bg14.scrollFactor.set(0.7, 0.7);
				bg14.active = false;
				swagBacks['bg14'] = bg14;
				toAdd.push(bg14);

				var bg1:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 1 (back tree)'));
				bg1.antialiasing = true;
				bg1.scrollFactor.set(0.7, 0.7);
				bg1.active = false;
				swagBacks['bg1'] = bg1;
				toAdd.push(bg1);

				var bg13:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 1 (Tree)'));
				bg13.antialiasing = true;
				bg13.active = false;
				swagBacks['bg13'] = bg13;
				toAdd.push(bg13);

				var bg4:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 1 (flower and grass)'));
				bg4.antialiasing = true;
				bg4.active = false;
				swagBacks['bg4'] = bg4;
				toAdd.push(bg4);

				var phillyCityLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['phillyCityLights'] = phillyCityLights;
				toAdd.push(phillyCityLights);

				var bg9:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/layer 1 (light 1)'));
				bg9.antialiasing = true;
				bg9.scrollFactor.set(0.8, 0.8);
				bg9.alpha = 0;
				bg9.active = false;
				phillyCityLights.add(bg9);
				swagBacks['bg9'] = bg9;

				var bg10:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 1 (Light 2)'));
				bg10.antialiasing = true;
				bg10.scrollFactor.set(0.8, 0.8);
				bg10.alpha = 0;
				bg10.active = false;
				phillyCityLights.add(bg10);
				swagBacks['bg10'] = bg10;

				var bg5:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 1 (Grass 2)'));
				bg5.antialiasing = true;
				bg5.active = false;
				swagBacks['bg5'] = bg5;
				toAdd.push(bg5);

				var bg8:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 1 (Lamp)'));
				bg8.antialiasing = true;
				bg8.active = false;
				swagBacks['bg8'] = bg8;
				layInFront[0].push(bg8);

				var bg6:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 1 (Grass)'));
				bg6.antialiasing = true;
				bg6.active = false;
				swagBacks['bg6'] = bg6;
				layInFront[0].push(bg6);

				var bg7:FlxSprite = new FlxSprite(-701, -300).loadGraphic(Paths.image('b&b/ITB/Layer 1 (Ground)'));
				bg7.antialiasing = true;
				bg7.active = false;
				swagBacks['bg7'] = bg7;
				layInFront[0].push(bg7);
			}
				

			case 'neopolis':
			{
				camZoom = 1.05;

				var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/weebSkyNeon'));
				bgSky.scrollFactor.set(0.1, 0.1);
				swagBacks['bgSky'] = bgSky;
				toAdd.push(bgSky);

				var repositionShit = -200;

				var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreetNeon'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				swagBacks['bgStreet'] = bgStreet;
				toAdd.push(bgStreet);

				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);

				bgSky.updateHitbox();
				bgStreet.updateHitbox();

				if (songLowercase == 'roses-remix')
				{
					var bgGirls = new BackgroundGirlsSwitch(-100, 190, 'weeb/bgFreaksUTMJ');
					bgGirls.scrollFactor.set(0.9, 0.9);
	
					bgGirls.getScared();
	
					bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
					bgGirls.updateHitbox();
					swagBacks['bgGirls'] = bgGirls;
					toAdd.push(bgGirls);

					var bfPixelBG = new FlxSprite(1050, 400);
					bfPixelBG.frames = Paths.getSparrowAtlas('characters/bfPixelNeon');
					bfPixelBG.animation.addByPrefix('idle', 'BF IDLE', 24, false);
					bfPixelBG.antialiasing = false;
					bfPixelBG.scrollFactor.set(0.9, 0.9);
					bfPixelBG.setGraphicSize(Std.int(bfPixelBG.width * 5.75));
					bfPixelBG.updateHitbox();
					swagBacks['bfPixelBG'] = bfPixelBG;
					toAdd.push(bfPixelBG);
				}
			}

			case 'school-monika-finale':
			{
				camZoom = 1.05;
				altSuffix = '-pixel';

				if (songLowercase == 'epiphany')
					camZoom = 0.9;

				var posX = 50;
				var posY = 200;

				var space = new FlxBackdrop(Paths.image('doki/monika/FinaleBG_1'));
				space.velocity.set(-10, 0);
				space.antialiasing = false;
				space.scrollFactor.set(0.1, 0.1);
				space.scale.set(1.65, 1.65);
				swagBacks['space'] = space;
				toAdd.push(space);

				var bg2 = new FlxSprite(70, posY).loadGraphic(Paths.image('doki/monika/FinaleBG_2'));
				bg2.antialiasing = false;
				bg2.scale.set(2.3, 2.3);
				bg2.scrollFactor.set(0.4, 0.6);
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);

				var stageFront2 = new FlxSprite(posX, posY).loadGraphic(Paths.image('doki/monika/FinaleFG'));
				stageFront2.antialiasing = false;
				stageFront2.scale.set(1.5, 1.5);
				stageFront2.scrollFactor.set(1, 1);
				swagBacks['stageFront2'] = stageFront2;
				toAdd.push(stageFront2);

				if (PlayState.SONG.player2 != 'monika-finale' && songLowercase != 'epiphany')
				{
					var monikaFinaleBG = new FlxSprite(155, -5);
					monikaFinaleBG.frames = Paths.getSparrowAtlas('doki/monika/Monika_Finale_BG');
					monikaFinaleBG.animation.addByPrefix('idle', 'MONIKA IDLE', 24, false);
					monikaFinaleBG.antialiasing = false;
					monikaFinaleBG.setGraphicSize(Std.int(monikaFinaleBG.width * 7.3)); // i have no idea why it's * 7 and not * 6 
					monikaFinaleBG.updateHitbox();
					monikaFinaleBG.scrollFactor.set(1, 1);
					swagBacks['monikaFinaleBG'] = monikaFinaleBG;
					toAdd.push(monikaFinaleBG);
				}

				dadYOffset = -69;
				dadXOffset = 300;
				bfXOffset = 200;
				bfYOffset = 260;
				gfXOffset = 180;
				gfYOffset = 300;
			}

			case 'cg5stage':
			{
				camZoom = 0.9;

				var bg = new FlxSprite(-535, -166).loadGraphic(Paths.image('cg5/mixroom', 'week1'));
				bg.antialiasing = true;
				bg.setGraphicSize(Std.int(bg.width * 0.9));
				bg.updateHitbox();
				bg.scrollFactor.set(1, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var stageFront = new FlxSprite(-507, -117).loadGraphic(Paths.image('cg5/recordroom', 'week1'));
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(1, 0.9);
				stageFront.active = false;
				stageFront.setGraphicSize(Std.int(stageFront.width * 0.9));
				stageFront.updateHitbox();
				swagBacks['stageFront'] = stageFront;
				layInFront[0].push(stageFront);

				var stageFront2 = new FlxSprite(-507, -117).loadGraphic(Paths.image('cg5/room_lights', 'week1'));
				stageFront2.antialiasing = true;
				stageFront2.scrollFactor.set(1, 0.9);
				stageFront2.active = false;
				stageFront2.setGraphicSize(Std.int(stageFront2.width * 0.9));
				stageFront2.updateHitbox();
				swagBacks['stageFront2'] = stageFront2;
				layInFront[0].push(stageFront2);
			}

			case 'acrimony':
			{
				camZoom = 0.98;

				var schoolBg:FlxSprite = new FlxSprite(-550, -900).loadGraphic(Paths.image('maginage/Schoolyard'));
				schoolBg.antialiasing = true;
				schoolBg.scrollFactor.set(0.85, 0.98);
				schoolBg.setGraphicSize(Std.int(schoolBg.width * 0.65));
				schoolBg.updateHitbox();
				swagBacks['schoolBg'] = schoolBg;
				toAdd.push(schoolBg);

				var modCrowdBig = new FlxSprite(-290, 55);
				modCrowdBig.frames = Paths.getSparrowAtlas('maginage/Crowd2');
				modCrowdBig.animation.addByPrefix('bop', 'Crowd2_Idle', 24, false);
				modCrowdBig.antialiasing = true;
				modCrowdBig.scrollFactor.set(0.9, 0.95);
				modCrowdBig.updateHitbox();
				swagBacks['modCrowdBig'] = modCrowdBig;
				toAdd.push(modCrowdBig);
			}

			case 'sunshine' | 'withered':
			{
				camZoom = 1.05;
				switch (daStage)
				{
					case 'sunshine': pre = 'happy';
					case 'withered': pre = 'slightlyannoyed_';				
				}

				var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('bob/'+pre+'sky'));
				bg.updateHitbox();
				bg.active = false;
				bg.antialiasing = true;
				bg.scrollFactor.set(0.1, 0.1);
				swagBacks['bg'] = bg;
				toAdd.push(bg);
				
				var ground:FlxSprite = new FlxSprite(-537, -158).loadGraphic(Paths.image('bob/'+pre+'ground'));
				ground.updateHitbox();
				ground.active = false;
				ground.antialiasing = true;
				swagBacks['ground'] = ground;
				toAdd.push(ground);
			}

			case 'hungryhippo' | 'hungryhippo-blantad':
			{		
				camZoom = 0.6;

				if (daStage == 'hungryhippo-blantad'){
					suf = '_blantad';
				}
				var bg = new FlxSprite(-800, -600).loadGraphic(Paths.image('rebecca/hungryhippo_bg'+suf));
		
				bg.scrollFactor.set(1.0, 1.0);
				swagBacks['bg'] = bg;
				toAdd.push(bg);
			}

			case 'alleysoft':
			{
				camZoom = 0.8;
				var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('soft/alleybg'));
				bg.antialiasing = true;
				bg.scrollFactor.set(1, 1);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var stageFront:FlxSprite = new FlxSprite(-630,-200).loadGraphic(Paths.image('soft/alleyfloor'));
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(1, 1);
				stageFront.active = false;
				swagBacks['stageFront'] = stageFront;
				toAdd.push(stageFront);
				
				var stageCurtains:FlxSprite = new FlxSprite(-200, -100).loadGraphic(Paths.image('soft/alleycat'));
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				stageCurtains.antialiasing = true;
				stageCurtains.scrollFactor.set(1.3, 1.3);
				stageCurtains.active = false;
				swagBacks['stageCurtains'] = stageCurtains;
				toAdd.push(stageCurtains);
			}

			case 'pokecenter':
			{
				var consistentPosition:Array<Float> = [-300, -600];
				var resizeBG:Float = 0.7;
				camZoom = 0.7;
				
				var bg:FlxSprite = new FlxSprite(consistentPosition[0], consistentPosition[1]).loadGraphic(Paths.image('hypno/Hypno bg background'));
				bg.setGraphicSize(Std.int(bg.width * resizeBG));
				bg.updateHitbox();
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var midGround:FlxSprite = new FlxSprite(consistentPosition[0], consistentPosition[1]).loadGraphic(Paths.image('hypno/Hypno bg midground'));
				midGround.setGraphicSize(Std.int(midGround.width * resizeBG));
				midGround.updateHitbox();
				swagBacks['midGround'] = midGround;
				toAdd.push(midGround);

				var foreground = new FlxSprite(consistentPosition[0], consistentPosition[1]).loadGraphic(Paths.image('hypno/Hypno bg foreground'));
				foreground.setGraphicSize(Std.int(foreground.width * resizeBG));
				foreground.updateHitbox();
				swagBacks['foreground'] = foreground;
				layInFront[2].push(foreground);
			}

			/*case 'out':
			{
				camZoom = 0.8;

				var sky:FlxSprite = new FlxSprite(-1204, -456).loadGraphic(Paths.image('shaggy/OBG/sky'));
				sky.scrollFactor.set(0.15, 0.15);
				swagBacks['sky'] = sky;
				toAdd.push(sky);

				var clouds:FlxSprite = new FlxSprite(-988, -260).loadGraphic(Paths.image('shaggy/OBG/clouds'));
				clouds.scrollFactor.set(0.25, 0.25);
				swagBacks['clouds'] = clouds;
				toAdd.push(clouds);

				var backMount:FlxSprite = new FlxSprite(-700, -40).loadGraphic(Paths.image('shaggy/OBG/backmount'));
				backMount.scrollFactor.set(0.4, 0.4);
				swagBacks['backMount'] = backMount;
				toAdd.push(backMount);

				var middleMount:FlxSprite = new FlxSprite(-240, 200).loadGraphic(Paths.image('shaggy/OBG/middlemount'));
				middleMount.scrollFactor.set(0.6, 0.6);
				swagBacks['middleMount'] = middleMount;
				toAdd.push(middleMount);

				var ground:FlxSprite = new FlxSprite(-660, 624).loadGraphic(Paths.image('shaggy/OBG/ground'));
				swagBacks['ground'] = ground;
				toAdd.push(ground);
			}

			case 'airplane1' | 'airplane2':
			{
				camZoom = 0.6;
				curStage = 'airplane';

				switch (daStage)
				{
					case  'airplane1':
						suf = 'Sky Clear';
					case 'airplane2':
						suf = 'Sky Storm';
				}

				var sky:FlxSprite = new FlxSprite(-600, -600).loadGraphic(Paths.image('rich/'+suf));
				sky.antialiasing = FlxG.save.data.anitialiasing;
				sky.scrollFactor.set(0.6, 0.6);
				swagBacks['sky'] = sky;
				toAdd.push(sky);

				var bg:FlxSprite = new FlxSprite(-600, -600).loadGraphic(Paths.image('rich/Background'));
				bg.antialiasing = FlxG.save.data.anitialiasing;
				bg.scrollFactor.set(1, 1);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var theGraph:FlxSprite = new FlxSprite(646, -20).loadGraphic(Paths.image('rich/TV'));
				theGraph.antialiasing = FlxG.save.data.anitialiasing;
				theGraph.scrollFactor.set(1, 1);
				theGraph.active = false;
				swagBacks['theGraph'] = theGraph;
				toAdd.push(theGraph);

				var graphPointer = new FlxObject(1140, 200, 0, 0);
				swagBacks['graphPointer'] = graphPointer;
				toAdd.push(graphPointer);

				graphPosition = graphPointer.y;

				var grpGraph = new FlxTypedGroup<FlxSprite>();
				swagGroup['grpGraph'] = grpGraph;
				toAdd.push(grpGraph);
				
				var grpGraphIndicators = new FlxTypedGroup<FlxSprite>();
				swagGroup['grpGraphIndicators'] = grpGraphIndicators;
				toAdd.push(grpGraphIndicators);

				for (i in 0...3) {
					var indic:FlxSprite = new FlxSprite(681, 234);
					indic.visible = false;
					switch (i) {
						case 0:
							indic.loadGraphic(Paths.image('rich/Graph STABLE'));
							indic.visible = true;
						case 1:
							indic.loadGraphic(Paths.image('rich/Graph UP'));
						case 2:
							indic.loadGraphic(Paths.image('rich/Graph DOWN'));
					}
					swagBacks['indic' + i] = indic;		
				}
				neutralGraphPos = graphPointer.y;
				graphBurstTimer = FlxG.random.int(90, 150);

				var bg2:FlxSprite = new FlxSprite(-600, 600).loadGraphic(Paths.image('rich/Foreground'));
				bg2.antialiasing = FlxG.save.data.antialiasing;
				bg2.scrollFactor.set(1.3, 1.3);
				bg2.active = false;
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);
			}

			case 'street1' | 'street2' | 'street3':
			{
				camZoom = 0.9;

				var bg = new FlxSprite(-500, -200).loadGraphic(Paths.image(daStage));
				bg.setGraphicSize(Std.int(bg.width * 0.9));
				bg.updateHitbox();
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;		
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				if (songLowercase == 'happy')
					PlayState.instance.daJumpscare.frames = Paths.getSparrowAtlas('sonic/exe/sonicJUMPSCARE1930');

				introAssets = ['bw/flipped/ready', 'bw/flipped/set', 'bw/flipped/go'];
				pixelShitPart1 = 'bw/flipped/';
			}	

			case 'zardymaze':
			{
				camZoom = 0.9;

				var zardyBackground = new FlxSprite(-600, -200);
				zardyBackground.frames = Paths.getSparrowAtlas('zardy/Maze');
				zardyBackground.animation.addByPrefix('Maze','Stage', 16);
				zardyBackground.antialiasing = true;
				zardyBackground.scrollFactor.set(0.9, 0.9);
				zardyBackground.animation.play('Maze');
				swagBacks['zardyBackground'] = zardyBackground;
				toAdd.push(zardyBackground);
			}

			case 'missingno':
			{
				camZoom = 0.6;

				var resizeBG:Float = 6;
				var consistentPosition:Array<Float> = [-670, -240];

				var background:FlxSprite = new FlxSprite(consistentPosition[0] + 30, consistentPosition[1]);
				
				background.frames = Paths.getSparrowAtlas('hypno/missingno/bg');
				background.animation.addByPrefix('idle', 'sky', 24, true);
				background.animation.play('idle');
				background.scale.set(resizeBG, resizeBG);
				background.updateHitbox();
				background.scrollFactor.set(0.3, 0.3);
				swagBacks['background'] = background;
				toAdd.push(background);

				var missingnoOcean = new FlxSprite(consistentPosition[0], consistentPosition[1]);
				missingnoOcean.frames = Paths.getSparrowAtlas('hypno/missingno/BG_Assets');
				missingnoOcean.animation.addByPrefix('idle', 'Bg Ocean', 24, true);
				missingnoOcean.animation.play('idle');
				missingnoOcean.scale.set(resizeBG, resizeBG);
				missingnoOcean.updateHitbox();
				missingnoOcean.scrollFactor.set(0.4, 0.4);
				swagBacks['missingnoOcean'] = missingnoOcean;
				toAdd.push(missingnoOcean);

				var ground:FlxSprite = new FlxSprite(consistentPosition[0], consistentPosition[1]);
				ground.frames = Paths.getSparrowAtlas('hypno/missingno/BG_Assets');
				ground.animation.addByPrefix('idle', 'Bg Wave', 24, true);
				ground.animation.play('idle');
				ground.scale.set(resizeBG, resizeBG);
				ground.updateHitbox();
				swagBacks['ground'] = ground;
				toAdd.push(ground);

				pixelShitPart1 = 'weeb/pixelUI/';
				pixelShitPart2 = '-pixel';

				bfXOffset = -190;
				bfYOffset = -170;
				gfXOffset = -200;
				dadXOffset = -150;
				dadYOffset = -50;
			}	

			case 'FMMstage' | 'FMMstagedusk' | 'FMMstagenight':
			{
				var time:String = '';

				camZoom = 0.6;
				curStage = 'FMMstage';

				switch (daStage)
				{
					case 'FMMstage':
						time = 'Day';
					case 'FMMstagedusk':
						time = 'Dusk';
					case 'FMMstagenight':
						time = 'Night';
				}
				var bg:FlxSprite = new FlxSprite(-1000, -350).loadGraphic(Paths.image('FMMStage/FMM'+time+'BG'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var FMMBuildings:FlxSprite = new FlxSprite(-1290, -380).loadGraphic(Paths.image('FMMStage/FMM'+time+'Buildings'));
				FMMBuildings.setGraphicSize(Std.int(FMMBuildings.width * 1.1));
				FMMBuildings.updateHitbox();
				FMMBuildings.antialiasing = true;
				FMMBuildings.scrollFactor.set(0.7, 0.7);
				FMMBuildings.active = false;
				swagBacks['FMMBuildings'] = FMMBuildings;
				toAdd.push(FMMBuildings);

				var FMMRail:FlxSprite = new FlxSprite(-1290, -490).loadGraphic(Paths.image('FMMStage/FMM'+time+'Rail'));
				FMMRail.setGraphicSize(Std.int(FMMRail.width * 1.1));
				FMMRail.updateHitbox();
				FMMRail.antialiasing = true;
				FMMRail.scrollFactor.set(0.8, 0.8);
				FMMRail.active = false;
				swagBacks['FMMRail'] = FMMRail;
				toAdd.push(FMMRail);

				var FMMFront:FlxSprite = new FlxSprite(-1290, -475).loadGraphic(Paths.image('FMMStage/FMM'+time+'Front'));
				FMMFront.setGraphicSize(Std.int(FMMFront.width * 1.1));
				FMMFront.updateHitbox();
				FMMFront.antialiasing = true;
				FMMFront.scrollFactor.set(0.9, 0.9);
				FMMFront.active = false;
				swagBacks['FMMFront'] = FMMFront;
				toAdd.push(FMMFront);
			}

			case 'emptystage2':
			{
				camZoom = 0.8;
			
				var bg = new FlxSprite(-600, -200).loadGraphic(Paths.image('emptystageback'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				introAssets = ['bw/ready', 'bw/set', 'bw/go'];

				if (songLowercase == 'storm')
					pixelShitPart1 = 'bw/';
			}

			case 'sunkStage':
			{
				camZoom = 0.9;
			
				var bg = new FlxSprite(-400, 0).loadGraphic(Paths.image('sonic/exe/SunkBG'));
				bg.antialiasing = true;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				bg.scrollFactor.set(0.95, 0.95);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);
			}

			case 'mind':
            {
        		camZoom = 0.8;
				curStage = 'mind';

				var bg:FlxSprite = new FlxSprite(-600, -145).loadGraphic(Paths.image('corruption/tormentor/TormentorBG'));
				bg.updateHitbox();
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);	

				var funnytv:FlxSprite = new FlxSprite(120, 145);
				funnytv.frames = Paths.getSparrowAtlas('corruption/tormentor/TormentorStatic');
				funnytv.animation.addByPrefix('idle', 'Tormentor Static', 24);
				funnytv.animation.play('idle');
				funnytv.scrollFactor.set(0.9, 0.9);
				funnytv.setGraphicSize(Std.int(funnytv.width * 1.3));
				swagBacks['funnytv'] = funnytv;
				toAdd.push(funnytv);	
            }

			case 'mind2':
            {
        		camZoom = 0.8;

				var wBg = new FlxSprite(-600, -145).loadGraphic(Paths.image('corruption/tormentor/shit'));
				wBg.updateHitbox();
				wBg.antialiasing = true;
				wBg.scrollFactor.set(0.9, 0.9);
				wBg.active = false;
				swagBacks['shaggy/WBG'] = wBg;
				toAdd.push(wBg);

				var bg2 = new FlxSprite(-600, -145).loadGraphic(Paths.image('corruption/tormentor/fuck'));
				bg2.updateHitbox();
				bg2.antialiasing = true;
				bg2.scrollFactor.set(0.9, 0.9);
				bg2.active = false;
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);

				var bg = new FlxSprite(-600, -145).loadGraphic(Paths.image('corruption/tormentor/TormentorBG'));
				bg.updateHitbox();
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);	

				var funnytv = new FlxSprite(120, 145);
				funnytv.frames = Paths.getSparrowAtlas('corruption/tormentor/TormentorStatic');
				funnytv.animation.addByPrefix('idle', 'Tormentor Static', 24);
				funnytv.animation.play('idle');
				funnytv.scrollFactor.set(0.9, 0.9);
				funnytv.setGraphicSize(Std.int(funnytv.width * 1.3));
				swagBacks['funnytv'] = funnytv;
				toAdd.push(funnytv);	

				var moreDark = new FlxSprite(0, 0).loadGraphic(Paths.image('corruption/tormentor/dark'));
				if (!preloading)
					moreDark.cameras = [PlayState.instance.camHUD];
				moreDark.antialiasing = true;
				swagBacks['moreDark'] = moreDark;
				toAdd.push(moreDark);	

            }

			case 'momiStage':
			{
				camZoom = 0.9;

				var bg:FlxSprite = new FlxSprite(-175.3, -225.95).loadGraphic(Paths.image('momi/bg'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 1);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);	
				FlxG.sound.cache(Paths.sound("carPass1"));
					
				var dust = new FlxSprite( -238.3, 371.55);
				dust.frames = Paths.getSparrowAtlas("momi/dust");
				dust.animation.addByPrefix("bop", "dust", 24, false);
				dust.scrollFactor.set(1.2, 1.2);
				dust.visible = false;
				dust.animation.play("bop");
				swagBacks['dust'] = dust;
				layInFront[2].push(dust);	
					
				var car = new FlxSprite( -1514.4, 199.8);
				car.scrollFactor.set(1.2,1.2);
				car.frames = Paths.getSparrowAtlas("momi/car");
				car.animation.addByPrefix("go", "car", 24, false);
				car.visible = true;
				car.animation.play("go");
				swagBacks['car'] = car;
				layInFront[2].push(car);
				if(songLowercase == "gura-nazel")dust.visible = true;
			}

			case 'studio':
			{
				camZoom = 0.9;

				var speakerScale:Float = 0.845;

				var bg_back:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('studio/studio_evenfurtherback'));
				bg_back.setGraphicSize(Std.int(bg_back.width * 0.845));
				bg_back.screenCenter();
				bg_back.antialiasing = true;
				bg_back.scrollFactor.set(0.85, 0.85);
				bg_back.active = false;
				bg_back.x += 32;
				swagBacks['bg_back'] = bg_back;
				toAdd.push(bg_back);	

				var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('studio/studio_back'));
				bg.setGraphicSize(Std.int(bg.width * 0.845));
				bg.screenCenter();
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);	

				var cy_spk1 = new FlxSprite(0, 0);
				cy_spk1.frames = Paths.getSparrowAtlas("studio/studio_speaker");
				cy_spk1.animation.addByPrefix('idle', 'speaker', 24);
				cy_spk1.animation.play('idle');
				cy_spk1.antialiasing = true;
				cy_spk1.scale.x = speakerScale;
				cy_spk1.scale.y = speakerScale;
				cy_spk1.screenCenter();
				cy_spk1.scrollFactor.set(0.9, 0.9);
				cy_spk1.x += -672;
				cy_spk1.y += -32;
				swagBacks['cy_spk1'] = cy_spk1;
				animatedBacks.push(cy_spk1);
				toAdd.push(cy_spk1);	

				var cy_spk2 = new FlxSprite(0, 0);
				cy_spk2.frames = Paths.getSparrowAtlas("studio/studio_speaker");
				cy_spk2.animation.addByPrefix('idle', 'speaker', 24);
				cy_spk2.animation.play('idle');
				cy_spk2.antialiasing = true;
				cy_spk2.scale.x = speakerScale;
				cy_spk2.scale.y = speakerScale;
				cy_spk2.screenCenter();
				cy_spk2.scrollFactor.set(0.9, 0.9);
				cy_spk2.x += 640;
				cy_spk2.y += -32;
				cy_spk2.flipX = true;
				swagBacks['cy_spk2'] = cy_spk2;
				animatedBacks.push(cy_spk2);
				toAdd.push(cy_spk2);	

				var bg_fx:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('studio/studio_fx'));
				bg_fx.setGraphicSize(Std.int(bg.width * 0.845));
				bg_fx.screenCenter();
				bg_fx.antialiasing = true;
				bg_fx.scrollFactor.set(0.9, 0.9);
				bg_fx.active = false;
				swagBacks['bg_fx'] = bg_fx;
				toAdd.push(bg_fx);	
			}

			case 'studio-crash':
			{
				camZoom = 0.9;

				var cy_crash = new FlxSprite(0, 0);
				cy_crash.frames = Paths.getSparrowAtlas("studio/crash_back");
				cy_crash.animation.addByPrefix('code', 'code', 24, true);
				cy_crash.antialiasing = true;
				cy_crash.setGraphicSize(Std.int(cy_crash.width * 1.75));
				cy_crash.screenCenter();
				cy_crash.antialiasing = true;
				cy_crash.scrollFactor.set(0.85, 0.85);
				cy_crash.x += 32;
				cy_crash.y += 80;
				cy_crash.animation.play('code');
				swagBacks['cy_crash'] = cy_crash;
				toAdd.push(cy_crash);
			}	
			
			case 'ron':
			{
				camZoom = 0.9;

				var bg:FlxSprite = new FlxSprite(-100,10).loadGraphic(Paths.image('bob/happyRon_sky'));
				bg.updateHitbox();
				bg.scale.x = 1.2;
				bg.scale.y = 1.2;
				bg.active = false;
				bg.antialiasing = true;
				bg.scrollFactor.set(0.1, 0.1);
				swagBacks['bg'] = bg;
				toAdd.push(bg);	

				var ground:FlxSprite = new FlxSprite(-537, -250).loadGraphic(Paths.image('bob/happyRon_ground'));
				ground.updateHitbox();
				ground.active = false;
				ground.antialiasing = true;
				swagBacks['ground'] = ground;
				toAdd.push(ground);	
			}

			case 'kbStreet': 
			{
				camZoom = 0.8125;

				//Back Layer - Normal
				var streetBG = new FlxSprite(-750, -145).loadGraphic(Paths.image('qt/streetBack'));
				streetBG.antialiasing = true;
				streetBG.scrollFactor.set(0.9, 0.9);
				swagBacks['streetBG'] = streetBG;
				toAdd.push(streetBG);	

				//Front Layer - Normal
				var streetFront:FlxSprite = new FlxSprite(-820, 710).loadGraphic(Paths.image('qt/streetFront'));
				streetFront.setGraphicSize(Std.int(streetFront.width * 1.15));
				streetFront.updateHitbox();
				streetFront.antialiasing = true;
				streetFront.scrollFactor.set(0.9, 0.9);
				streetFront.active = false;
				swagBacks['streetFront'] = streetFront;
				toAdd.push(streetFront);	

				var qt_tv01 = new FlxSprite(-62, 540);
				qt_tv01.frames = Paths.getSparrowAtlas('qt/TV_V5');
				qt_tv01.animation.addByPrefix('idle', 'TV_Idle', 24, true);
				qt_tv01.animation.addByPrefix('eye', 'TV_brutality', 24, true); //Replaced the hex eye with the brutality symbols for more accurate lore.
				qt_tv01.animation.addByPrefix('error', 'TV_Error', 24, true);	
				qt_tv01.animation.addByPrefix('404', 'TV_Bluescreen', 24, true);		
				qt_tv01.animation.addByPrefix('alert', 'TV_Attention', 32, false);		
				qt_tv01.animation.addByPrefix('watch', 'TV_Watchout', 24, true);
				qt_tv01.animation.addByPrefix('drop', 'TV_Drop', 24, true);
				qt_tv01.animation.addByPrefix('sus', 'TV_sus', 24, true);
				qt_tv01.setGraphicSize(Std.int(qt_tv01.width * 1.2));
				qt_tv01.updateHitbox();
				qt_tv01.antialiasing = true;
				qt_tv01.scrollFactor.set(0.89, 0.89);
				qt_tv01.animation.play('idle');
				swagBacks['qt_tv01'] = qt_tv01;
				toAdd.push(qt_tv01);	
			
				var qt_gas01 = new FlxSprite();
				qt_gas01.frames = Paths.getSparrowAtlas('qt/Gas_Release');
				qt_gas01.animation.addByPrefix('burst', 'Gas_Release', 38, false);	
				qt_gas01.animation.addByPrefix('burstALT', 'Gas_Release', 49, false);
				qt_gas01.animation.addByPrefix('burstFAST', 'Gas_Release', 76, false);	
				qt_gas01.setGraphicSize(Std.int(qt_gas01.width * 2.5));	
				qt_gas01.antialiasing = true;
				qt_gas01.scrollFactor.set();
				qt_gas01.alpha = 0.72;
				qt_gas01.setPosition(-180,250);
				qt_gas01.angle = -31;	
				swagBacks['qt_gas01'] = qt_gas01;
				layInFront[2].push(qt_gas01);			

				var qt_gas02 = new FlxSprite();
				qt_gas02.frames = Paths.getSparrowAtlas('qt/Gas_Release');
				qt_gas02.animation.addByPrefix('burst', 'Gas_Release', 38, false);	
				qt_gas02.animation.addByPrefix('burstALT', 'Gas_Release', 49, false);
				qt_gas02.animation.addByPrefix('burstFAST', 'Gas_Release', 76, false);	
				qt_gas02.setGraphicSize(Std.int(qt_gas02.width * 2.5));
				qt_gas02.antialiasing = true;
				qt_gas02.scrollFactor.set();
				qt_gas02.alpha = 0.72;
				qt_gas02.setPosition(1320,250);
				qt_gas02.angle = 31;
				swagBacks['qt_gas02'] = qt_gas02;
				layInFront[2].push(qt_gas02);
			}

			case 'room-space': 
			{
                camZoom = 0.8;
				
				var space:FlxSprite = new FlxSprite(-800, -370).loadGraphic(Paths.image('nonsense/Outside_Space'));
				space.setGraphicSize(Std.int(space.width * 0.8));
				space.antialiasing = true;
				space.scrollFactor.set(0.8, 0.8);
				space.active = false;
				swagBacks['space'] = space;
				toAdd.push(space);	
				
				var spaceTex = Paths.getSparrowAtlas('nonsense/BACKGROUND_space');

				var NHroom = new FlxSprite( -800, -370);
				NHroom.frames = spaceTex;
				NHroom.animation.addByPrefix('space', 'Wall Broken anim', 24, true);
				NHroom.animation.play('space');
				NHroom.setGraphicSize(Std.int(NHroom.width * 0.9));
				NHroom.antialiasing = true;
				swagBacks['NHroom'] = NHroom;
				toAdd.push(NHroom);
			}

			case 'melonfarm': 
			{
				var bg:FlxSprite = new FlxSprite(-90, -20).loadGraphic(Paths.image('fever/melonfarm/sky'));
				bg.scrollFactor.set(0.1, 0.1);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var city:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('fever/melonfarm/bg'));
				swagBacks['city'] = city;
				toAdd.push(city);	

				var street:FlxSprite = new FlxSprite(-70).loadGraphic(Paths.image('fever/melonfarm/street'));
				swagBacks['street'] = street;
				toAdd.push(street);	
			}

			/*case 'skybroke':
			{
				camZoom = 0.9;

				var manifestBG = new FlxSprite(-388, -232);
				manifestBG.frames = Paths.getSparrowAtlas('sky/bg_annoyed');
				manifestBG.animation.addByPrefix('idle', 'bg2', 24, false);
				manifestBG.animation.addByIndices('noflash', "bg2", [5], "", 24, false);
				manifestBG.scrollFactor.set(0.4, 0.4);
				manifestBG.antialiasing = true;
				manifestBG.animation.play('noflash');
				swagBacks['manifestBG'] = manifestBG;
				toAdd.push(manifestBG);	

				var manifestHole = new FlxSprite (160, -70);
				manifestHole.frames = Paths.getSparrowAtlas('sky/manifesthole');
				manifestHole.animation.addByPrefix('idle', 'manifest hole', 24, false);
				manifestHole.animation.addByIndices('noflash', "manifest hole", [5], "", 24, false);
				manifestHole.scrollFactor.set(0.7, 1);
				manifestHole.setGraphicSize(Std.int(manifestHole.width * 0.9));
				manifestHole.updateHitbox();
				manifestHole.animation.play('noflash');
				manifestHole.antialiasing = true;
				swagBacks['manifestHole'] = manifestHole;
				toAdd.push(manifestHole);	
				
				bfXOffset = 60;
				bfYOffset = -140;
				bfYOffset = -140;
				dadXOffset = -40;
				dadYOffset = -140;
				gfXOffset = -40;
				gfYOffset = -170;
			}

			case 'churchgospel':
			{
				camZoom = 0.7;

				var blackbg:FlxSprite = new FlxSprite(-500, -850).loadGraphic(Paths.image('sacredmass/churchgospel/blackbg'));
				blackbg.setGraphicSize(Std.int(blackbg.width * 1.2));
				blackbg.updateHitbox();
				blackbg.antialiasing = true;
				blackbg.scrollFactor.set(0.9, 0.9);
				blackbg.active = false;
				swagBacks['blackbg'] = blackbg;
				toAdd.push(blackbg);	

				var circ0 = new FlxSprite(-500, -850).loadGraphic(Paths.image('sacredmass/churchgospel/circ0'));
				circ0.setGraphicSize(Std.int(circ0.width * 1.2));
				circ0.updateHitbox();
				circ0.antialiasing = true;
				circ0.scrollFactor.set(0.9, 0.9);
				circ0.active = false;
				swagBacks['circ0'] = circ0;
				toAdd.push(circ0);	

				circ1new = new FlxSprite(288, -459).loadGraphic(Paths.image('sacredmass/churchgospel/circ1new'));
				circ1new.setGraphicSize(Std.int(circ1new.width * 1.2));
				circ1new.updateHitbox();
				circ1new.antialiasing = true;
				circ1new.scrollFactor.set(0.9, 0.9);
				circ1new.active = false;	
				swagBacks['circ1new'] = circ1new;
				toAdd.push(circ1new);	

				var circ2 = new FlxSprite(-500, -850).loadGraphic(Paths.image('sacredmass/churchgospel/circ2'));
				circ2.setGraphicSize(Std.int(circ2.width * 1.2));
				circ2.updateHitbox();
				circ2.antialiasing = true;
				circ2.scrollFactor.set(0.9, 0.9);
				circ2.active = false;
				swagBacks['circ2'] = circ2;
				toAdd.push(circ2);	

				var bg = new FlxSprite(-500, -850).loadGraphic(Paths.image('sacredmass/churchgospel/bg'));
				bg.setGraphicSize(Std.int(bg.width * 1.2));
				bg.updateHitbox();
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);	

				var floor:FlxSprite = new FlxSprite(-500, -850).loadGraphic(Paths.image('sacredmass/churchgospel/floor'));
				floor.setGraphicSize(Std.int(floor.width * 1.2));
				floor.updateHitbox();
				floor.antialiasing = true;
				floor.scrollFactor.set(0.9, 0.9);
				floor.active = false;
				swagBacks['floor'] = floor;
				toAdd.push(floor);	

				var pillars:FlxSprite = new FlxSprite(-500, -850).loadGraphic(Paths.image('sacredmass/churchgospel/pillars'));
				pillars.setGraphicSize(Std.int(pillars.width * 1.2));
				pillars.updateHitbox();
				pillars.antialiasing = true;
				pillars.scrollFactor.set(0.9, 0.9);
				pillars.active = false;
				swagBacks['pillars'] = pillars;
				toAdd.push(pillars);

				gfXOffset = -100;
				gfYOffset = -70;
				dadXOffset = -100;
				dadYOffset = 100;
				bfXOffset = 100;
				bfYOffset = 100;
			}

			case 'destroyedpaper':
			{		
				camZoom = 0.75;

				var bg:FlxSprite = new FlxSprite(-230, -95);
				bg.frames = Paths.getSparrowAtlas('Sketchy/destroyedpaperjig');
				bg.animation.addByPrefix('idle', 'DestroyedPaper', 24);
				bg.setGraphicSize(Std.int(bg.width * 0.5));
				bg.animation.play('idle');
				bg.scrollFactor.set(0.8, 1.0);
				bg.scale.set(2.3, 2.3);
				bg.antialiasing = true;
				swagBacks['bg'] = bg;
				toAdd.push(bg);	

				var rips:FlxSprite = new FlxSprite(-230, -95);
				rips.frames = Paths.getSparrowAtlas('Sketchy/PaperRips');
				rips.animation.addByPrefix('idle', 'Ripping Graphic', 24);
				rips.setGraphicSize(Std.int(rips.width * 0.5));
				rips.animation.play('idle');
				rips.scrollFactor.set(1.0, 1.0);
				rips.scale.set(2.0, 2.0);
				rips.antialiasing = true;
				swagBacks['rips'] = rips;
				toAdd.push(rips);	
			}*/

			/*case 'staged2' | 'staged3':
			{
				var stageShit:String = '';
				
				stageShit = daStage;

				camZoom = 0.9;
				
				if (daStage == 'staged3')
				{
					var bg = new FlxSprite(-260, -220);
					bg.frames = Paths.getSparrowAtlas('corruption/staged3/stageback');
					bg.animation.addByPrefix('idle', 'stageback animated', 24, true);
					bg.setGraphicSize(Std.int(bg.width * 1.1));
					bg.updateHitbox();
					bg.antialiasing = true;
					bg.scrollFactor.set(0.9, 0.9);
					bg.animation.play('idle');
					swagBacks['bg'] = bg;
					toAdd.push(bg);	
				}	

				if (daStage == 'staged2')
				{
					var bg = new FlxSprite(-600, -200).loadGraphic(Paths.image('corruption/staged2/stageback'));
					bg.antialiasing = true;
					bg.scrollFactor.set(0.9, 0.9);
					bg.active = false;
					swagBacks['bg'] = bg;
					toAdd.push(bg);	

					var ladder:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('corruption/staged2/ladder'));
					ladder.antialiasing = true;
					ladder.scrollFactor.set(0.9, 0.9);
					ladder.active = false;
					swagBacks['ladder'] = ladder;
					toAdd.push(ladder);	
				}
				
				var stageFront = new FlxSprite(-650, 600).loadGraphic(Paths.image('corruption/'+stageShit+'/stagefront'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				swagBacks['stageFront'] = stageFront;
				toAdd.push(stageFront);	

				var stageCurtains = new FlxSprite(-500, -300).loadGraphic(Paths.image('corruption/'+stageShit+'/stagecurtains'));
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				stageCurtains.antialiasing = true;
				stageCurtains.scrollFactor.set(1.3, 1.3);
				stageCurtains.active = false;
				swagBacks['stageCurtains'] = stageCurtains;
				layInFront[2].push(stageCurtains);	
			}

			case 'curse':
			{
				camZoom = 0.8;
				
				var bg = new FlxSprite(-600, -300).loadGraphic(Paths.image('tabi/normal_stage'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);	

				var sumtable:FlxSprite = new FlxSprite(-600, -300).loadGraphic(Paths.image('tabi/sumtable'));
				sumtable.antialiasing = true;
				sumtable.scrollFactor.set(0.9, 0.9);
				sumtable.active = false;
				swagBacks['sumtable'] = sumtable;
				layInFront[2].push(sumtable);	
			}

			case 'neko-bedroom':
			{
				camZoom = 0.7;

				var bedroom = new FlxSprite(-600, -200).loadGraphic(Paths.image('neko/bg_bedroom'));
				bedroom.antialiasing = true;
				bedroom.scrollFactor.set(0.97, 0.97);
				bedroom.active = false;
				swagBacks['bedroom'] = bedroom;
				toAdd.push(bedroom);	
			}

			case 'garStage' | 'eddhouse2':
			{
				camZoom = 0.9;

				switch (daStage)
				{
					case 'garStage': pre = 'garcello';
					case 'eddhouse2': pre = 'tord';
				}

				var bg = new FlxSprite(-500, -170).loadGraphic(Paths.image(pre+'/garStagebg'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);	

				var stageFront:FlxSprite = new FlxSprite(-500, -200).loadGraphic(Paths.image(pre+'/garStage'));
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				swagBacks['stageFront'] = stageFront;
				toAdd.push(stageFront);	

				bfXOffset = 100;
				dadXOffset = -100;
			}

			case 'arcade4':
			{
				camZoom = 0.9;

				var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('kapi/closed'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);	

				var bottomBoppers = new FlxSprite(-600, -200);
				bottomBoppers.frames = Paths.getSparrowAtlas('kapi/bgFreaks');
				bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
				bottomBoppers.antialiasing = true;
				bottomBoppers.scrollFactor.set(0.92, 0.92);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				swagBacks['bottomBoppers'] = bottomBoppers;
				toAdd.push(bottomBoppers);

				var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('kapi/stagefront'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				swagBacks['stageFront'] = stageFront;
				toAdd.push(stageFront);

				var phillyCityLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['phillyCityLights'] = phillyCityLights;
				toAdd.push(phillyCityLights);

				for (i in 0...4)
				{
					var light:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('kapi/win' + i));
					light.scrollFactor.set(0.9, 0.9);
					light.visible = false;
					light.updateHitbox();
					light.antialiasing = true;
					phillyCityLights.add(light);
					swagBacks['light' + i] = light;		
				}

				var upperBoppers = new FlxSprite(-600, -200);
				upperBoppers.frames = Paths.getSparrowAtlas('kapi/upperBop');
				upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
				upperBoppers.antialiasing = true;
				upperBoppers.scrollFactor.set(1.05, 1.05);
				upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 1));
				upperBoppers.updateHitbox();
				swagBacks['upperBoppers'] = upperBoppers;
				toAdd.push(upperBoppers);
			}	
			case 'stadium':
			{
				camZoom = 0.575;

				var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('b3/stadium'));
				bg.antialiasing = true;
				bg.scrollFactor.set(1, 1);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var upperBoppers = new FlxSprite(-600, -255);
				upperBoppers.frames = Paths.getSparrowAtlas('b3/mia_boppers');
				upperBoppers.animation.addByPrefix('idle', "Back Crowd Bop", 24, false);
				upperBoppers.antialiasing = true;
				upperBoppers.scrollFactor.set(1, 1);
				upperBoppers.updateHitbox();
				upperBoppers.animation.play('idle');
				swagBacks['upperBoppers'] = upperBoppers;
				toAdd.push(upperBoppers);
				animatedBacks.push(upperBoppers);

				var bottomBoppers = new FlxSprite(-600, -266);
				bottomBoppers.frames = Paths.getSparrowAtlas('b3/mia_boppers');
				bottomBoppers.animation.addByPrefix('idle', "Front Crowd Bop", 24, false);
				bottomBoppers.antialiasing = true;
				bottomBoppers.scrollFactor.set(1, 1);
				bottomBoppers.updateHitbox();
				bottomBoppers.animation.play('idle');
				swagBacks['bottomBoppers'] = bottomBoppers;
				toAdd.push(bottomBoppers);
				animatedBacks.push(bottomBoppers);

				var lights:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('b3/lights'));
				lights.antialiasing = true;
				lights.scrollFactor.set(1, 1);
				lights.active = false;
				swagBacks['lights'] = lights;
				layInFront[2].push(lights);

				bfXOffset = 150;
				bfYOffset = 300;
				dadXOffset = -25;
				dadYOffset = 300;
				gfXOffset = -65;
				gfYOffset = 200;
				pixelShitPart1 = 'b3/';
			}
			case 'throne':
			{		
				camZoom = 0.69;

				var bg = new FlxSprite(-550, -243).loadGraphic(Paths.image('anchor/watah'));
				bg.scrollFactor.set(0.1, 0.1);
				bg.setGraphicSize(Std.int(bg.width * 1.5));
				bg.updateHitbox();
				bg.antialiasing = true;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var bg2 = new FlxSprite(-1271, -724).loadGraphic(Paths.image('anchor/throne'));
				bg2.scrollFactor.set(0.9, 0.9);
				bg2.setGraphicSize(Std.int(bg2.width * 1.95));
				bg2.updateHitbox();
				bg2.antialiasing = true;
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);

				var bottomBoppers = new FlxSprite(-564, 2);
				bottomBoppers.frames = Paths.getSparrowAtlas('anchor/feesh3');
				bottomBoppers.animation.addByPrefix('idle', 'ikan', 24, false);
				bottomBoppers.antialiasing = true;
				bottomBoppers.scrollFactor.set(0.9, 0.9);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 0.95));
				bottomBoppers.updateHitbox();
				swagBacks['bottomBoppers'] = bottomBoppers;
				toAdd.push(bottomBoppers);
				animatedBacks.push(bottomBoppers);
						
				var bgcrowd = new FlxSprite(-1020, 460);
				bgcrowd.frames = Paths.getSparrowAtlas('anchor/front');
				bgcrowd.animation.addByPrefix('idle', 'ikan', 24, false);
				bgcrowd.antialiasing = true;
				bgcrowd.setGraphicSize(Std.int(bgcrowd.width * 1.2));
				bgcrowd.updateHitbox();
				swagBacks['bgcrowd'] = bgcrowd;
				layInFront[2].push(bgcrowd);
				animatedBacks.push(bgcrowd);
			}

			case 'prologue':
			{
				camZoom = 0.9;

				var bg:FlxSprite = new FlxSprite(-100, -100).loadGraphic(Paths.image('prologue/rooftopsky'));
				bg.scrollFactor.set(0.1, 0.1);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('prologue/distantcity'));
				city.scrollFactor.set(0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				swagBacks['city'] = city;
				toAdd.push(city);

				var phillyCityLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['phillyCityLights'] = phillyCityLights;
				toAdd.push(phillyCityLights);

				for (i in 0...5)
				{
						var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('prologue/win' + i));
						light.scrollFactor.set(0.3, 0.3);
						light.visible = false;
						light.setGraphicSize(Std.int(light.width * 0.85));
						light.updateHitbox();
						light.antialiasing = true;
						phillyCityLights.add(light);
						swagBacks['light' + i] = light;	
				}

				var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('prologue/poll'));
				swagBacks['streetBehind'] = streetBehind;
				toAdd.push(streetBehind);
					
				var street:FlxSprite = new FlxSprite(-130, streetBehind.y).loadGraphic(Paths.image('prologue/rooftop'));
				swagBacks['street'] = street;
				toAdd.push(street);
			}	

			case 'ripdiner':
			{
				camZoom = 0.5;
				var bg:FlxSprite = new FlxSprite(-820, -200).loadGraphic(Paths.image('fever/lastsongyukichi','shared'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var bottomBoppers3 = new FlxSprite(-800, -180);
				bottomBoppers3.frames = Paths.getSparrowAtlas('fever/CROWD1');
				bottomBoppers3.animation.addByPrefix('idle', "CROWD1", 24, false);
				bottomBoppers3.animation.play('idle');
				bottomBoppers3.scrollFactor.set(0.9, 0.9);
				swagBacks['bottomBoppers3'] = bottomBoppers3;		
				layInFront[2].push(bottomBoppers3);
				animatedBacks.push(bottomBoppers3);

				bfXOffset = 100;
				bfYOffset = 180;
				dadYOffset = 180;
				gfXOffset = -70;
				gfYOffset = 200;
				bfScrollFactor = [0.9, 0.9];
				gfScrollFactor = [0.9, 0.9];		
			}

			case 'genocide':
			{
				camZoom = 0.8;

				var siniFireBehind = new FlxTypedGroup<SiniFire>();
				swagGroup['siniFireBehind'] = siniFireBehind;
				
				var siniFireFront = new FlxTypedGroup<SiniFire>();
				swagGroup['siniFireFront'] = siniFireFront;
			
				
				var genocideBG = new FlxSprite(-600, -300).loadGraphic(Paths.image('tabi/fire/wadsaaa'));
				genocideBG.antialiasing = true;
				genocideBG.scrollFactor.set(0.9, 0.9);
				swagBacks['genocideBG'] = genocideBG;		
				toAdd.push(genocideBG);

				for (i in 0...2)
				{
					var daFire:SiniFire = new SiniFire(genocideBG.x + (720 + (((95 * 10) / 2) * i)), genocideBG.y + 180, true, false, 30, i * 10, 84);
					daFire.antialiasing = true;
					daFire.scrollFactor.set(0.9, 0.9);
					daFire.scale.set(0.4, 1);
					daFire.y += 50;
					siniFireBehind.add(daFire);
					swagBacks['daFire' + i] = daFire;	
				}
				
				toAdd.push(siniFireBehind);
				
				var genocideBoard = new FlxSprite(genocideBG.x, genocideBG.y).loadGraphic(Paths.image('tabi/fire/boards'));
				genocideBoard.antialiasing = true;
				genocideBoard.scrollFactor.set(0.9, 0.9);
				swagBacks['genocideBoard'] = genocideBoard;		
				toAdd.push(genocideBoard);
				
				var fire1:SiniFire = new SiniFire(genocideBG.x + (-100), genocideBG.y + 889, true, false, 30);
				fire1.antialiasing = true;
				fire1.scrollFactor.set(0.9, 0.9);
				fire1.scale.set(2.5, 1.5);
				fire1.y -= fire1.height * 1.5;
				fire1.flipX = true;
				swagBacks['fire1'] = fire1;	
				siniFireFront.add(fire1);
				
				var fire2:SiniFire = new SiniFire((fire1.x + fire1.width) - 80, genocideBG.y + 889, true, false, 30);
				fire2.antialiasing = true;
				fire2.scrollFactor.set(0.9, 0.9);
				fire2.y -= fire2.height * 1;
				swagBacks['fire2'] = fire2;	
				siniFireFront.add(fire2);
				
				var fire3:SiniFire = new SiniFire((fire2.x + fire2.width) - 30, genocideBG.y + 889, true, false, 30);
				fire3.antialiasing = true;
				fire3.scrollFactor.set(0.9, 0.9);
				fire3.y -= fire3.height * 1;
				swagBacks['fire3'] = fire3;	
				siniFireFront.add(fire3);

				var fire4:SiniFire = new SiniFire((fire3.x + fire3.width) - 10, genocideBG.y + 889, true, false, 30);
				fire4.antialiasing = true;
				fire4.scrollFactor.set(0.9, 0.9);
				fire4.scale.set(1.5, 1.5);
				fire4.y -= fire4.height * 1.5;
				swagBacks['fire4'] = fire4;	
				siniFireFront.add(fire4);
				
				toAdd.push(siniFireFront);
				
				var path:String = "";

				if (PlayState.isNeonight && songLowercase == 'crucify')
					path = Paths.image('tabi/fire/glowyfurniture2');
				else
					path = Paths.image('tabi/fire/glowyfurniture');

				var fuckYouFurniture:FlxSprite = new FlxSprite(genocideBG.x, genocideBG.y).loadGraphic(path);
				fuckYouFurniture.antialiasing = true;
				fuckYouFurniture.scrollFactor.set(0.9, 0.9);
				swagBacks['fuckYouFurniture'] = fuckYouFurniture;		
				toAdd.push(fuckYouFurniture);

				var destBoombox:FlxSprite = new FlxSprite(400, 130).loadGraphic(Paths.image('tabi/fire/Destroyed_boombox'));
				destBoombox.y += (destBoombox.height - 648) * -1;
				destBoombox.y += 150;
				destBoombox.x -= 110;
				destBoombox.scale.set(1.2, 1.2);
				swagBacks['destBoombox'] = destBoombox;		
				toAdd.push(destBoombox);

				var sumsticks:FlxSprite = new FlxSprite(-600, -300).loadGraphic(Paths.image('tabi/fire/overlayingsticks'));
				sumsticks.antialiasing = true;
				sumsticks.scrollFactor.set(0.9, 0.9);
				sumsticks.active = false;
				swagBacks['sumsticks'] = sumsticks;		
				layInFront[2].push(sumsticks);

				vignette = new FlxSprite().loadGraphic(Paths.image('tabi/fire/vignette'));
				vignette.width = 1280;
				vignette.height = 720;
				vignette.x = 0;
				vignette.y = 0;
				if (!preloading)
					vignette.cameras = [PlayState.instance.camOther];
				vignette.updateHitbox();				
				vignette.alpha = 1;
				swagBacks['vignette'] = vignette;		
				layInFront[2].push(vignette);
			}

			case 'neon':
			{
				camZoom = 0.7;
				var hscriptPath = 'shootin/neon/';

				var bg = new FlxSprite(-430, -438).loadGraphic(Paths.image(hscriptPath + 'sky'));
				bg.scrollFactor.set(0.1, 0.1);
				bg.antialiasing = true;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var city = new FlxSprite(-2000, -300).loadGraphic(Paths.image(hscriptPath + 'city'));
				city.antialiasing = true;
   				city.updateHitbox();
				swagBacks['city'] = city;
				toAdd.push(city);

				var phillyCityLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['phillyCityLights'] = phillyCityLights;
				toAdd.push(phillyCityLights);

				for (i in 0...5)
				{
					var light:FlxSprite = new FlxSprite(-120, 117).loadGraphic(Paths.image(hscriptPath + 'win' + i + ''));
					light.visible = false;
					light.antialiasing = true;
					phillyCityLights.add(light);
					swagBacks['light' + i] = light;	
				}

				var streetBehind = new FlxSprite(-40, 10).loadGraphic(Paths.image(hscriptPath + 'behindTrain'));
				streetBehind.antialiasing = true;
				swagBacks['streetBehind'] = streetBehind;
				toAdd.push(streetBehind);

				var phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image(hscriptPath + 'train'));
				phillyTrain.antialiasing = true;
				swagBacks['phillyTrain'] = phillyTrain;
				toAdd.push(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				var street = new FlxSprite(-120, 117).loadGraphic(Paths.image(hscriptPath + 'street'));
				street.antialiasing = true;
				swagBacks['street'] = street;
				toAdd.push(street);

				if (songLowercase == 'technokinesis')
				{
					var chara = new FlxSprite(250, 300);
					chara.frames = Paths.getSparrowAtlas('characters/chara');
					chara.animation.addByPrefix('idle', "chara0", 24, false);
					swagBacks['chara'] = chara;
					toAdd.push(chara);
				}


			}
			case 'studioLot':
			{
				camZoom = 0.9;

				var bg:FlxSprite = new FlxSprite(-300, -400).loadGraphic(Paths.image('studioLot/sky'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var mountainback:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('studioLot/mountainback'));
				mountainback.updateHitbox();
				mountainback.scrollFactor.set(0.9, 0.9);
				mountainback.active = false;
				swagBacks['mountainback'] = mountainback;
				toAdd.push(mountainback);

				var moutainsfoward:FlxSprite = new FlxSprite(-500, 100).loadGraphic(Paths.image('studioLot/moutainsfoward'));
				moutainsfoward.updateHitbox();
				moutainsfoward.scrollFactor.set(0.9, 0.9);
				moutainsfoward.active = false;
				swagBacks['moutainsfoward'] = moutainsfoward;
				toAdd.push(moutainsfoward);

				var bushes:FlxSprite = new FlxSprite(-100, -700).loadGraphic(Paths.image('studioLot/bushes'));
				bushes.updateHitbox();
				bushes.antialiasing = FlxG.save.data.antialiasing;
				bushes.scrollFactor.set(0.9, 0.9);
				bushes.active = false;
				swagBacks['bushes'] = bushes;
				toAdd.push(bushes);

				var studio:FlxSprite = new FlxSprite(0, -1000).loadGraphic(Paths.image('studioLot/studio'));
				studio.updateHitbox();
				studio.scrollFactor.set(0.9, 0.9);
				studio.active = false;
				swagBacks['studio'] = studio;
				toAdd.push(studio);

				var ground:FlxSprite = new FlxSprite(-1200, 560).loadGraphic(Paths.image('studioLot/ground'));
				ground.setGraphicSize(Std.int(ground.width * 2));
				ground.updateHitbox();
				ground.scrollFactor.set(0.9, 0.9);
				ground.active = false;
				swagBacks['ground'] = ground;
				toAdd.push(ground);

				bfXOffset = 100;
				dadYOffset = 30;
				bfYOffset = 30;
			}

			case 'incident':
			{
				camZoom = 1.4;
				var bgt:FlxSprite = new FlxSprite(-500, -260).loadGraphic(Paths.image('BB1'));
				bgt.active = false;				
				swagBacks['bgt'] = bgt;
				toAdd.push(bgt);

				if(PlayState.SONG.gfVersion != 'gf-trollge')
				{
					var trashcan:FlxSprite = new FlxSprite(565, 420).loadGraphic(Paths.image('trashcan'));
					trashcan.scrollFactor.set(0.95, 0.95);
					trashcan.active = false;			
					swagBacks['trashcan'] = trashcan;
					toAdd.push(trashcan);
				}
			}

			case 'stare': 
			{
				camZoom = 0.9;

				var starecrownBG = new FlxSprite(-400, -175);
				starecrownBG.frames = Paths.getSparrowAtlas('starecrown/Maze');
				starecrownBG.animation.addByPrefix('idle', 'Stage');
				starecrownBG.animation.play('idle');
				starecrownBG.antialiasing = true;
				starecrownBG.scrollFactor.set(0.3, 0.3);
				starecrownBG.setGraphicSize(Std.int(starecrownBG.width * 1.5));
				starecrownBG.updateHitbox();
				swagBacks['starecrownBG'] = starecrownBG;
				toAdd.push(starecrownBG);
			}

			case 'garStageRise':
			{
				camZoom = 0.9;
				
				var bg = new FlxSprite(-500, -170).loadGraphic(Paths.image('garcello/garStagebgRise'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var stageFront:FlxSprite = new FlxSprite(-500, -200).loadGraphic(Paths.image('garcello/garStageRise'));
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				swagBacks['stageFront'] = stageFront;
				toAdd.push(stageFront);
			}

			case 'garStageDead':
			{
				camZoom = 0.9;

				var bg:FlxSprite = new FlxSprite(-500, -170).loadGraphic(Paths.image('garcello/garStagebgAlt'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.7, 0.7);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var smoker:FlxSprite = new FlxSprite(0, -290);
				smoker.frames = Paths.getSparrowAtlas('garcello/garSmoke');
				smoker.setGraphicSize(Std.int(smoker.width * 1.7));
				smoker.alpha = 0.3;
				smoker.animation.addByPrefix('garsmoke', "smokey", 13);
				smoker.animation.play('garsmoke');
				smoker.scrollFactor.set(0.7, 0.7);
				swagBacks['smoker'] = smoker;
				toAdd.push(smoker);

				var bgAlley:FlxSprite = new FlxSprite(-500, -200).loadGraphic(Paths.image('garcello/garStagealt'));
				bgAlley.antialiasing = true;
				bgAlley.scrollFactor.set(0.9, 0.9);
				bgAlley.active = false;
				swagBacks['bgAlley'] = bgAlley;
				toAdd.push(bgAlley);

				var corpse:FlxSprite = new FlxSprite(-230, 540).loadGraphic(Paths.image('garcello/gardead'));
				corpse.antialiasing = true;
				corpse.scrollFactor.set(0.9, 0.9);
				corpse.active = false;
				swagBacks['corpse'] = corpse;
				toAdd.push(corpse);

				var smoke:FlxSprite = new FlxSprite(0, 0);
				smoke.frames = Paths.getSparrowAtlas('garcello/garSmoke');
				smoke.setGraphicSize(Std.int(smoke.width * 1.6));
				smoke.animation.addByPrefix('garsmoke', "smokey", 15);
				smoke.animation.play('garsmoke');
				smoke.scrollFactor.set(1.1, 1.1);
				swagBacks['smoke'] = smoke;
				layInFront[2].push(smoke);
			}

			case 'operaStage' | 'operaStage-old':
			{
				camZoom = 0.9;

				switch (daStage)
				{
					case 'operaStage': pre = 'operastage';
					case 'operaStage-old': pre = 'operastage_old';
				}
	
				var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('backgrounds/'+pre+'/stageback','shared'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('backgrounds/'+pre+'/stagefront','shared'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				swagBacks['stageFront'] = stageFront;
				toAdd.push(stageFront);
			}

			/*case 'motherland':
			{
				camZoom = 0.55;

				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('holofunk/russia/motherBG'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				bg.setPosition(-705, -705);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				if (songLowercase == 'killer-scream')
				{
					var bluescreen:FlxSprite = new FlxSprite().loadGraphic(Paths.image('holofunk/russia/bluescreen'));
					bluescreen.antialiasing = true;
					bluescreen.scrollFactor.set(0.9, 0.9);
					bluescreen.active = false;
					bluescreen.setPosition(-655, -505);
					bluescreen.setGraphicSize(Std.int(bluescreen.width * 1.4));
					bluescreen.updateHitbox();
					swagBacks['bluescreen'] = bluescreen;
					toAdd.push(bluescreen);
				}
				
				var bg2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('holofunk/russia/motherFG'));
				bg2.antialiasing = true;
				bg2.scrollFactor.set(0.9, 0.9);
				bg2.active = false;
				bg2.setGraphicSize(Std.int(bg2.width * 1.1));
				bg2.updateHitbox();
				bg2.setPosition(-735, -670);
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);

				var plants:FlxSprite = new FlxSprite(-705, -705).loadGraphic(Paths.image('holofunk/russia/plants'));
				plants.antialiasing = true;
				plants.scrollFactor.set(1.3, 1.3);
				plants.active = false;
				plants.setGraphicSize(Std.int(plants.width * 1.5));
				plants.updateHitbox();
				plants.setPosition(-1415, -1220);
				swagBacks['plants'] = plants;
				layInFront[2].push(plants);

				if (songLowercase == 'killer-scream')
				{
					var blackScreen = new FlxSprite(-1000, -500).makeGraphic(Std.int(FlxG.width * 5), Std.int(FlxG.height * 5), FlxColor.BLACK);
					swagBacks['blackScreen'] = blackScreen;
					layInFront[2].push(blackScreen);

					if (!preloading)
						blackScreen.cameras = [PlayState.instance.camOther];
				}

				bfXOffset = 20;
				bfYOffset = 100;
				gfXOffset = -150;
				gfYOffset = 90;
				dadXOffset = -145;
				dadYOffset = 90;

				introAssets = ['holofunk/ui/ready', 'holofunk/ui/set', 'holofunk/ui/go'];
			}

			case 'glitcher':
			{
				camZoom = 0.9;

				var glitcherBG = new FlxSprite(-600, -200).loadGraphic(Paths.image('hex/stageback_glitcher'));
				glitcherBG.antialiasing = true;
				glitcherBG.scrollFactor.set(0.9, 0.9);
				glitcherBG.active = false;
				swagBacks['glitcherBG'] = glitcherBG;
				toAdd.push(glitcherBG);

				var glitcherFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('hex/stagefront_glitcher'));
				glitcherFront.setGraphicSize(Std.int(glitcherFront.width * 1.1));
				glitcherFront.updateHitbox();
				glitcherFront.antialiasing = true;
				glitcherFront.scrollFactor.set(0.9, 0.9);
				glitcherFront.active = false;
				swagBacks['glitcherFront'] = glitcherFront;
				toAdd.push(glitcherFront);

				var wireBG = new FlxSprite(-600, -200).loadGraphic(Paths.image('hex/WIREStageBack'));
				wireBG.antialiasing = true;
				wireBG.scrollFactor.set(0.9, 0.9);
				wireBG.active = false;
				swagBacks['wireBG'] = wireBG;
				toAdd.push(wireBG);
			}

			case 'hallway':
			{
				camZoom = 0.63;

				var bg:FlxSprite = new FlxSprite(-360, -210).loadGraphic(Paths.image('eteled/glitchhallway'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(1, 1);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);
				
				//yeah i'll add these when i do the actual glitching stuff so... not rn
				
				/*var foregroundGlitch = new FlxSprite(0, 0);
				foregroundGlitch.frames = Paths.getSparrowAtlas('glitch effects/glitchAnim', 'eteled');
				foregroundGlitch.animation.addByPrefix('idle', 'g', 24, true);
				foregroundGlitch = new FlxSprite(0, 0);
				foregroundGlitch.frames = Paths.getSparrowAtlas('glitch effects/noise2', 'eteled');
				foregroundGlitch.animation.addByPrefix('idle', 'f', 24, true);
				foregroundGlitch = new FlxSprite(0, 0);
				foregroundGlitch.frames = Paths.getSparrowAtlas('glitch effects/noise2R', 'eteled');
				foregroundGlitch.animation.addByPrefix('idle', 'f', 24, true);
				foregroundGlitch = new FlxSprite(0, 0);
				foregroundGlitch.frames = Paths.getSparrowAtlas('glitch effects/sheet', 'eteled');
				foregroundGlitch.animation.addByPrefix('idle', 'Idle', 24, true);
				foregroundGlitch = new FlxSprite(0, 0);
				foregroundGlitch.frames = Paths.getSparrowAtlas('glitch effects/sheeto2', 'eteled');
				foregroundGlitch.animation.addByPrefix('idle', 'n', 24, true);				
			}

			case "concert":
			{
				camZoom = 0.59;

				var sky:FlxSprite = new FlxSprite(-1275, -625).loadGraphic(Paths.image('camelliastage2/sky'));
				sky.scrollFactor.set(1, 1);
				sky.scale.set(0.85, 0.85);
				sky.antialiasing = true;
				sky.active = false;
				toAdd.push(sky);

				var back_buildings:FlxSprite = new FlxSprite(-1275, -625).loadGraphic(Paths.image('camelliastage2/farbuildings'));
				back_buildings.scrollFactor.set(1, 1);
				back_buildings.scale.set(0.85, 0.85);
				back_buildings.antialiasing = true;
				back_buildings.active = false;
				toAdd.push(back_buildings);

				var buildings:FlxSprite = new FlxSprite(-1275, -625).loadGraphic(Paths.image('camelliastage2/buildings'));
				buildings.scrollFactor.set(1, 1);
				buildings.scale.set(0.85, 0.85);
				buildings.antialiasing = true;
				buildings.active = false;
				toAdd.push(buildings);

				// I'll fix it later
				var concertLights = new FlxTypedGroup<FlxSprite>();
				swagGroup['concertLights'] = concertLights;
				toAdd.push(concertLights);

				for (i in 1...5)
				{
					var light:FlxSprite = new FlxSprite(-1275, -625).loadGraphic(Paths.image('camelliastage2/win' + i));
					light.visible = false;
					light.scale.set(0.85, 0.85);
					// light.setGraphicSize(Std.int(light.width * 0.85));
					light.antialiasing = true;
					concertLights.add(light);
					swagBacks['light' + i] = light;
				}

				concertLights.members[1].visible = true;

				crowd_back = new FlxSprite(-1275, -625).loadGraphic(Paths.image('camelliastage2/backcrowd'));
				crowd_back.scrollFactor.set(1, 1);
				crowd_back.scale.set(0.85, 0.85);
				crowd_back.antialiasing = true;
				toAdd.push(crowd_back);

				crowd_back2 = new FlxSprite(-1275, -625).loadGraphic(Paths.image('camelliastage2/backcrowd_notricky'));
				crowd_back2.scrollFactor.set(1, 1);
				crowd_back2.scale.set(0.85,0.85);
				crowd_back2.antialiasing = true;
				crowd_back2.alpha = 0;
				toAdd.push(crowd_back2);

				crowd_back3 = new FlxSprite(-1275, -625).loadGraphic(Paths.image('camelliastage2/backcrowd_nosticky'));
				crowd_back3.scrollFactor.set(1, 1);
				crowd_back3.scale.set(0.85,0.85);
				crowd_back3.antialiasing = true;
				crowd_back3.alpha = 0;
				toAdd.push(crowd_back3);

				var stage:FlxSprite = new FlxSprite(-1275, -625).loadGraphic(Paths.image('camelliastage2/stage'));
				stage.scrollFactor.set(1, 1);
				stage.scale.set(0.85, 0.85);
				stage.antialiasing = true;
				stage.active = false;
				toAdd.push(stage);

				speaker_left = new FlxSprite(-450, 45);
				speaker_left.frames = Paths.getSparrowAtlas('camelliastage2/speaker_left');
				speaker_left.animation.addByPrefix('bop', 'speaker 20', 24, false);
				speaker_left.scrollFactor.set(1, 1);
				speaker_left.antialiasing = true;
				speaker_left.scale.set(0.75, 0.75);
				toAdd.push(speaker_left);

				speaker_right = new FlxSprite(1225, 45);
				speaker_right.frames = Paths.getSparrowAtlas('camelliastage2/speaker_right');
				speaker_right.animation.addByPrefix('bop', 'speaker 10', 24, false);
				speaker_right.scrollFactor.set(1, 1);
				speaker_right.antialiasing = true;
				speaker_right.scale.set(0.75, 0.75);
				toAdd.push(speaker_right);

				var speaker_left2 = new FlxSprite(-325, 55);
				speaker_left2.frames = Paths.getSparrowAtlas('camelliastage2/speakerleft');
				speaker_left2.animation.addByPrefix('bop', 'speaker', 24, false);
				speaker_left2.scrollFactor.set(1, 1);
				speaker_left2.antialiasing = true;
				speaker_left2.scale.set(0.5, 0.5);
				swagBacks['speaker_left'] = speaker_left2;
				toAdd.push(speaker_left2);

				var speaker_right2 = new FlxSprite(790, 55);
				speaker_right2.frames = Paths.getSparrowAtlas('camelliastage2/speakerleft');
				speaker_right2.animation.addByPrefix('bop', 'speaker', 24, false);
				speaker_right2.scrollFactor.set(1, 1);
				speaker_right2.antialiasing = true;
				speaker_right2.scale.set(0.5, 0.5);
				speaker_right2.flipX = true;
				swagBacks['speaker_right'] = speaker_right2;
				toAdd.push(speaker_right2);

				var gardead = new FlxSprite().loadGraphic(Paths.image('garcello/gardead'));
				gardead.setPosition(970, 680);
				gardead.flipX = true;
				swagBacks['gardead'] = gardead;
				layInFront[1].push(gardead);

				crowd_front = new FlxSprite(-1275, -225).loadGraphic(Paths.image('camelliastage2/frontcrowd'));
				crowd_front.scrollFactor.set(1, 1);
				crowd_front.scale.set(0.85, 0.85);
				crowd_front.antialiasing = true;
				layInFront[2].push(crowd_front);

				crowd_front2 = new FlxSprite(-1275, -225).loadGraphic(Paths.image('camelliastage2/frontcrowd_nowhitty'));
				crowd_front2.scrollFactor.set(1, 1);
				crowd_front2.scale.set(0.85, 0.85);
				crowd_front2.antialiasing = true;
				layInFront[2].push(crowd_front2);

				crowd_front3 = new FlxSprite(-1275, -225).loadGraphic(Paths.image('camelliastage2/frontcrowd_nocarol'));
				crowd_front3.scrollFactor.set(1, 1);
				crowd_front3.scale.set(0.85, 0.85);
				crowd_front3.antialiasing = true;
				layInFront[2].push(crowd_front3);

				crowd_front4 = new FlxSprite(-1275, -225).loadGraphic(Paths.image('camelliastage2/frontcrowd_nomiku'));
				crowd_front4.scrollFactor.set(1, 1);
				crowd_front4.scale.set(0.85, 0.85);
				crowd_front4.antialiasing = true;
				layInFront[2].push(crowd_front4);

				if (FlxG.random.bool(10))
				{
					jabibi_amogus = new FlxSprite(-1275, -625).loadGraphic(Paths.image('camelliastage2/jabibiamogus'));
					jabibi_amogus.scrollFactor.set(1, 1);
					jabibi_amogus.scale.set(0.85, 0.85);
					jabibi_amogus.antialiasing = true;
					layInFront[2].push(jabibi_amogus);
					addedAmogus = true;
					trace("sus");
				}

				var blackScreen = new FlxSprite().makeGraphic(Std.int(FlxG.width * 5), Std.int(FlxG.height * 5), (FlxColor.fromString('#' + '101010')));
				blackScreen.screenCenter();
				if (!preloading)
					blackScreen.cameras = [PlayState.instance.camOther];
				swagBacks['blackScreen'] = blackScreen;
				layInFront[2].push(blackScreen);

				var undertale = new FlxSprite();
				undertale.frames = Paths.getSparrowAtlas('UndertaleEncounter');
				undertale.animation.addByPrefix('idle', 'Soul Anim', 24, false);
				undertale.antialiasing = true;
				if (!preloading)
					undertale.cameras = [PlayState.instance.camOther];
				undertale.screenCenter();
				swagBacks['undertale'] = undertale;
				layInFront[2].push(undertale);

				bfXOffset = 350;
				bfYOffset = 80;
				dadXOffset = -200;
				dadYOffset = 50;
				pixelShitPart1 = 'camelliastage2/ui/';
			}

			/*case 'exestage':
			{
				camZoom = 1.0;

				var bgspec = new FlxSprite(-600, -600).makeGraphic(3840, 2160, (FlxColor.fromString('#' + 'D60000'))); // some parts are too low and can be seen with maijin
				bgspec.antialiasing = true;
				bgspec.scrollFactor.set(0.63, 1);
				bgspec.active = false;
				swagBacks['bgspec'] = bgspec;
				toAdd.push(bgspec);

				var sSKY:FlxSprite = new FlxSprite(-222, 134).loadGraphic(Paths.image('sonic/exe/PolishedP1/SKY'));
				sSKY.antialiasing = true;
				sSKY.scrollFactor.set(0.63, 1);
				sSKY.active = false;
				swagBacks['sSKY'] =sSKY;
				toAdd.push(sSKY);

				var hills:FlxSprite = new FlxSprite(-264, -156 + 150).loadGraphic(Paths.image('sonic/exe/PolishedP1/HILLS'));
				hills.antialiasing = true;
				hills.scrollFactor.set(0.73, 1);
				hills.active = false;
				swagBacks['hills'] = hills;
				toAdd.push(hills);

				var bg2:FlxSprite = new FlxSprite(-345, -289 + 170).loadGraphic(Paths.image('sonic/exe/PolishedP1/FLOOR2'));
				bg2.updateHitbox();
				bg2.antialiasing = true;
				bg2.scrollFactor.set(0.83, 1);
				bg2.active = false;
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);

				var bg:FlxSprite = new FlxSprite(-297, -246 + 150).loadGraphic(Paths.image('sonic/exe/PolishedP1/FLOOR1'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.93, 1);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var eggman:FlxSprite = new FlxSprite(-218, -219 + 150).loadGraphic(Paths.image('sonic/exe/PolishedP1/EGGMAN'));
				eggman.updateHitbox();
				eggman.antialiasing = true;
				eggman.scrollFactor.set(0.95, 1);
				eggman.active = false;
				swagBacks['eggman'] = eggman;
				toAdd.push(eggman);

				var tail:FlxSprite = new FlxSprite(-199 - 150, -259 + 150).loadGraphic(Paths.image('sonic/exe/PolishedP1/TAIL'));
				tail.updateHitbox();
				tail.antialiasing = true;
				tail.scrollFactor.set(0.97, 1);
				tail.active = false;
				swagBacks['tail'] = tail;
				toAdd.push(tail);

				var knuckle:FlxSprite = new FlxSprite(185 + 100, -350 + 150).loadGraphic(Paths.image('sonic/exe/PolishedP1/KNUCKLE'));
				knuckle.updateHitbox();
				knuckle.antialiasing = true;
				knuckle.scrollFactor.set(0.99, 1);
				knuckle.active = false;
				swagBacks['knuckle'] = knuckle;
				toAdd.push(knuckle);

				var sticklol:FlxSprite = new FlxSprite(-100, 50);
				sticklol.frames = Paths.getSparrowAtlas('sonic/exe/PolishedP1/TailsSpikeAnimated');
				sticklol.animation.addByPrefix('a', 'Tails Spike Animated instance 1', 4, true);
				sticklol.setGraphicSize(Std.int(sticklol.width * 1.2));
				sticklol.updateHitbox();
				sticklol.antialiasing = true;
				sticklol.scrollFactor.set(1, 1);
				swagBacks['sticklol'] = sticklol;
				toAdd.push(sticklol);
				sticklol.animation.play('a', true);

				bfXOffset = 50;
				bfYOffset = 25;
				dadXOffset = 70;
				dadYOffset = 25;

				pixelShitPart1 = 'sonic/exe/ui/';			
			}

			case 'TDStage':
			{
				camZoom = 0.9;

				var bgspec = new FlxSprite().loadGraphic(Paths.image('sonic/exe/TailsBG'));
				bgspec.setGraphicSize(Std.int(bgspec.width * 1.2));
				bgspec.antialiasing = true;
				bgspec.scrollFactor.set(.91, .91);
				bgspec.x -= 370;
				bgspec.y -= 130;
				bgspec.active = false;
				swagBacks['bgspec'] = bgspec;
				toAdd.push(bgspec);

				if (FlxG.save.data.distractions && !preloading)
				{
					PlayState.instance.addShaderToCamera('game', new VCRDistortionEffect2());
					PlayState.instance.addShaderToCamera('hud', new VCRDistortionEffect2());
				}
					
			}

			/*case 'sonicFUNSTAGE' | 'sonicFUNSTAGE-majinless':
			{
				camZoom = 0.9;
				if (daStage.contains('majinless')) suf = ' Empty';

				var funsky:FlxSprite = new FlxSprite(-600, 0).loadGraphic(Paths.image('sonic/exe/FunInfiniteStage/sonicFUNsky'));
				funsky.setGraphicSize(Std.int(funsky.width * 0.9));
				funsky.antialiasing = true;
				funsky.scrollFactor.set(0.8, 0.8);
				funsky.active = false;
				swagBacks['funsky'] = funsky;
				toAdd.push(funsky);

				var funbush:FlxSprite = new FlxSprite(-42, 371).loadGraphic(Paths.image('sonic/exe/FunInfiniteStage/Bush2'));
				funbush.antialiasing = true;
				funbush.scrollFactor.set(0.8, 0.8);
				funbush.active = false;
				swagBacks['funbush'] = funbush;
				toAdd.push(funbush);

				var funpillarts2ANIM = new FlxSprite(182, 100); // Zekuta why...
				funpillarts2ANIM.frames = Paths.getSparrowAtlas('sonic/exe/FunInfiniteStage/Majin Boppers Back'+suf);
				funpillarts2ANIM.animation.addByPrefix('idle', 'MajinBop2 instance 1', 24);
				// funpillarts2ANIM.setGraphicSize(Std.int(funpillarts2ANIM.width * 0.7));
				funpillarts2ANIM.antialiasing = true;
				funpillarts2ANIM.scrollFactor.set(1, 1);
				swagBacks['funpillarts2ANIM'] = funpillarts2ANIM;
				toAdd.push(funpillarts2ANIM);
				animatedBacks.push(funpillarts2ANIM);
				
				var funbush2:FlxSprite = new FlxSprite(132, 554).loadGraphic(Paths.image('sonic/exe/FunInfiniteStage/Bush 1'));
				funbush2.antialiasing = true;
				funbush2.scrollFactor.set(0.8, 0.8);
				funbush2.active = false;
				swagBacks['funbush2'] = funbush2;
				toAdd.push(funbush2);

				var funpillarts1ANIM = new FlxSprite(-169, 33);
				funpillarts1ANIM.frames = Paths.getSparrowAtlas('sonic/exe/FunInfiniteStage/Majin Boppers Front'+suf);
				funpillarts1ANIM.animation.addByPrefix('idle', 'MajinBop1 instance 1', 24);
				// funpillarts1ANIM.setGraphicSize(Std.int(funpillarts1ANIM.width * 0.7));
				funpillarts1ANIM.antialiasing = true;
				funpillarts1ANIM.scrollFactor.set(1, 1);
				swagBacks['funpillarts1ANIM'] = funpillarts1ANIM;
				toAdd.push(funpillarts1ANIM);
				animatedBacks.push(funpillarts1ANIM);
			
				var funfloor:FlxSprite = new FlxSprite(-340, 860).loadGraphic(Paths.image('sonic/exe/FunInfiniteStage/floor BG'));
				funfloor.antialiasing = true;
				funfloor.scrollFactor.set(1, 1);
				funfloor.active = false;
				swagBacks['funfloor'] = funfloor;
				toAdd.push(funfloor);
				
				var funboppers1ANIM = new FlxSprite(1126, 953);
				funboppers1ANIM.frames = Paths.getSparrowAtlas('sonic/exe/FunInfiniteStage/majin FG1');
				funboppers1ANIM.animation.addByPrefix('idle', 'majin front bopper1', 24, false);
				funboppers1ANIM.antialiasing = true;
				funboppers1ANIM.scrollFactor.set(1, 1);
				swagBacks['funboppers1ANIM'] = funboppers1ANIM;
				layInFront[2].push(funboppers1ANIM);
				animatedBacks.push(funboppers1ANIM);

				var funboppers2ANIM = new FlxSprite(-293, 921);
				funboppers2ANIM.frames = Paths.getSparrowAtlas('sonic/exe/FunInfiniteStage/majin FG2');
				funboppers2ANIM.animation.addByPrefix('idle', 'majin front bopper2', 24, false);
				funboppers2ANIM.antialiasing = true;
				funboppers2ANIM.scrollFactor.set(1, 1);
				swagBacks['funboppers2ANIM'] = funboppers2ANIM;
				layInFront[2].push(funboppers2ANIM);
				animatedBacks.push(funboppers2ANIM);

				bfYOffset = 300;
				bfXOffset = 80;
				dadYOffset = 300;
				gfYOffset = 200;
				pixelShitPart1 = 'sonic/exe/ui/';
			}

			case 'exestage2': // i fixed the bgs and shit!!! - razencro part 1
			{
				camZoom = 0.9;

				var sSKY:FlxSprite = new FlxSprite(-538.2, -440.8).loadGraphic(Paths.image('sonic/exe/SonicP2/sky'));
				sSKY.antialiasing = true;
				sSKY.scrollFactor.set(0.63, 1);
				sSKY.active = false;
				sSKY.scale.x = 1.4;
				sSKY.scale.y = 1.4;
				swagBacks['sSKY'] = sSKY;
				toAdd.push(sSKY);

				var trees:FlxSprite = new FlxSprite(-377, -298.3).loadGraphic(Paths.image('sonic/exe/SonicP2/backtrees'));
				trees.antialiasing = true;
				trees.scrollFactor.set(0.73, 1);
				trees.active = false;
				trees.scale.x = 1.2;
				trees.scale.y = 1.2;
				swagBacks['trees'] = trees;
				toAdd.push(trees);

				var bg2:FlxSprite = new FlxSprite(-397.8, -334.65).loadGraphic(Paths.image('sonic/exe/SonicP2/trees'));
				bg2.updateHitbox();
				bg2.antialiasing = true;
				bg2.scrollFactor.set(0.83, 1);
				bg2.active = false;
				bg2.scale.x = 1.2;
				bg2.scale.y = 1.2;
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);

				var bg:FlxSprite = new FlxSprite(-403, -240.2).loadGraphic(Paths.image('sonic/exe/SonicP2/ground'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.93, 1);
				bg.active = false;
				bg.scale.x = 1.2;
				bg.scale.y = 1.2;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var bgspec = new FlxSprite(-428.5 + 750, -449.35 + 572).loadGraphic(Paths.image("sonic/exe/SonicP2/GreenHill"));
				bgspec.antialiasing = false;
				bgspec.scrollFactor.set(1, 1);
				bgspec.active = false;
				bgspec.visible = false;
				bgspec.scale.x = 8;
				bgspec.scale.y = 8;
				swagBacks['bgspec'] = bgspec;
				toAdd.push(bgspec);

				dadYOffset = -140;
				bfXOffset = 165;
				bfYOffset = -140;
				gfXOffset = 85;
				gfYOffset = -115;

				pixelShitPart1 = 'sonic/exe/ui/';			

				//camPos.set(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);
			}

			case 'ballisticAlley':
			{
				camZoom = 0.9;

				var nwBg = new FlxSprite(-600, -200);
				nwBg.frames = Paths.getSparrowAtlas('whitty/BallisticBackground');
				nwBg.antialiasing = true;
				nwBg.scrollFactor.set(0.9, 0.9);
				nwBg.active = true;
				nwBg.animation.addByPrefix('start', 'Background Whitty Start', 24, false);
				nwBg.animation.addByPrefix('gaming', 'Background Whitty Startup', 24, false);
				nwBg.animation.addByPrefix('gameButMove', 'Background Whitty Moving', 16, true);	
				nwBg.animation.play("gameButMove");	
				swagBacks['nwBg'] = nwBg;
				toAdd.push(nwBg);

				funneEffect = new FlxSprite(-600, -200).loadGraphic(Paths.image('whitty/thefunnyeffect'));
				funneEffect.alpha = 0.5;
				funneEffect.scrollFactor.set();
				funneEffect.visible = true;
				if (!preloading)
					funneEffect.cameras = [PlayState.instance.camHUD];
				swagBacks['funneEffect'] = funneEffect;
				layInFront[2].push(funneEffect);

				if ((PlayState.isStoryMode || PlayState.showCutscene) && songLowercase == 'ballistic') //pico cutscene stuff
				{
					var wBg = new FlxSprite(-500, -300).loadGraphic(Paths.image('whitty/whittyBack'));
					swagBacks['wBg'] = wBg;
					toAdd.push(wBg);
	
					var wstageFront = new FlxSprite(-650, 600).loadGraphic(Paths.image('whitty/whittyFront'));
					wstageFront.setGraphicSize(Std.int(wstageFront.width * 1.1));
					wstageFront.updateHitbox();
					wstageFront.antialiasing = true;
					wstageFront.scrollFactor.set(0.9, 0.9);
					wstageFront.active = false;
					swagBacks['wstageFront'] = wstageFront;
					toAdd.push(wstageFront);

					funneEffect.visible = false;
				}
			}

			/*case 'trioStage' | 'trioStage-sonic' | 'trioStage-FWF': // i fixed the bgs and shit!!! - razencro part 1
			{
				camZoom = 0.9;

				var path:String = "sonic/exe/Phase3/Glitch";
				var path2:String = "sonic/exe/Phase3/Grass";

				if (daStage == 'trioStage-FWF')
				{
					path = 'sonic/exe/FunInfiniteStage/sonicFUNsky';
					path2 = 'sonic/exe/Phase3/GrassFWF';

					var cableJump:FlxSprite = new FlxSprite();
					cableJump.frames = Paths.getSparrowAtlas('zardy/CableJump');
					cableJump.animation.addByPrefix('jump', 'CableJump', 24, true);
					cableJump.setGraphicSize(FlxG.width, FlxG.height);
					cableJump.screenCenter();
					if (!preloading)
						cableJump.cameras = [PlayState.instance.camOther];
					swagBacks['cableJump'] = cableJump;
					layInFront[2].push(cableJump);

					vg = new FlxSprite().loadGraphic(Paths.image('sonic/exe/RedVGSolo'));
					vg.alpha = 0;
					if (!preloading)
						vg.cameras = [PlayState.instance.camOther];
					swagBacks['vg'] = vg;
					layInFront[2].push(vg);
				}
					
				var sSKY:FlxSprite = new FlxSprite(-621.1, -395.65).loadGraphic(Paths.image(path));
				sSKY.antialiasing = true;
				sSKY.scrollFactor.set(0.8, 1);
				sSKY.active = false;
				sSKY.scale.x = 1.2;
				sSKY.scale.y = 1.2;
				swagBacks['sSKY'] = sSKY;
				toAdd.push(sSKY);

				var p3staticbg = new FlxSprite(0, 0);
				p3staticbg.frames = Paths.getSparrowAtlas('sonic/exe/NewTitleMenuBG');
				p3staticbg.animation.addByPrefix('P3Static', 'TitleMenuSSBG instance 1', 24, true);
				p3staticbg.animation.play('P3Static');
				p3staticbg.scrollFactor.set(0.9, 1);
				p3staticbg.screenCenter();
				p3staticbg.x -= 100;
				p3staticbg.scale.x = 5.5;
				p3staticbg.scale.y = 5.5;

				if (daStage == 'trioStage')
					p3staticbg.visible = false;

				if (daStage == 'trioStage-FWF')
				{
					var newShader:ColorSwap = new ColorSwap();
					p3staticbg.shader = newShader.shader;
					newShader.hue = -125 / 360;
				}

				swagBacks['p3staticbg'] = p3staticbg;
				toAdd.push(p3staticbg);

				var trees:FlxSprite = new FlxSprite(-607.35, -401.55).loadGraphic(Paths.image('sonic/exe/Phase3/Trees'));
				trees.antialiasing = true;
				trees.scrollFactor.set(0.85, 1);
				trees.active = false;
				trees.scale.x = 1.2;
				trees.scale.y = 1.2;
				swagBacks['trees'] = trees;
				toAdd.push(trees);
				
				var bg2:FlxSprite = new FlxSprite(-623.5, -410.4).loadGraphic(Paths.image('sonic/exe/Phase3/Trees2'));
				bg2.updateHitbox();
				bg2.antialiasing = true;
				bg2.scrollFactor.set(0.9, 1);
				bg2.active = false;
				bg2.scale.x = 1.2;
				bg2.scale.y = 1.2;
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);

				var bg:FlxSprite = new FlxSprite(-630.4, -266).loadGraphic(Paths.image(path2));
				bg.antialiasing = true;
				bg.scrollFactor.set(1, 1);
				bg.active = false;
				bg.scale.x = 1.2;
				bg.scale.y = 1.2;
				bg.y -= (daStage == 'trioStage-FWF' ? 100 : 0);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var bgspec = new FlxSprite(-428.5 + 50, -449.35 + 25).makeGraphic(2199, 1203, FlxColor.BLACK);
				bgspec.antialiasing = true;
				bgspec.scrollFactor.set(0.9, 1);
				bgspec.active = false;
				bgspec.visible = false;

				bgspec.scale.x = 1.2;
				bgspec.scale.y = 1.2;
				swagBacks['bgspec'] = bgspec;
				toAdd.push(bgspec);

				if (songLowercase == 'triple-trouble' && PlayState.isBETADCIU)
				{
					var chika = new FlxSprite();
					chika.frames = Paths.getSparrowAtlas('don da yo');
					chika.animation.addByPrefix('idle', 'Don Da Yo', 60, false);
					chika.antialiasing = true;	
					if (!preloading)
						chika.cameras = [PlayState.instance.camHUD];
					swagBacks['chika'] = chika;
					toAdd.push(chika);

					var kb_attack_saw = new FlxSprite();
					kb_attack_saw.frames = Paths.getSparrowAtlas('qt/attackv6');
					kb_attack_saw.animation.addByPrefix('fire', 'kb_attack_animation_fire', 24, false);	
					kb_attack_saw.animation.addByPrefix('prepare', 'kb_attack_animation_prepare', 24, false);	
					kb_attack_saw.setGraphicSize(Std.int(kb_attack_saw.width * 1.15));
					kb_attack_saw.antialiasing = true;
					kb_attack_saw.flipX = true;
					kb_attack_saw.setPosition(60,400);
					swagBacks['kb_attack_saw'] = kb_attack_saw;
					layInFront[2].push(kb_attack_saw);

					var kb_attack_alert = new FlxSprite();
					kb_attack_alert.frames = Paths.getSparrowAtlas('qt/attack_alert');
					kb_attack_alert.animation.addByPrefix('alert', 'kb_attack_animation_alert', 24, false);	
					kb_attack_alert.antialiasing = true;
					kb_attack_alert.setGraphicSize(Std.int(kb_attack_alert.width * 1.5));
					if (!preloading)
						kb_attack_alert.cameras = [PlayState.instance.camHUD];
					kb_attack_alert.screenCenter();
					swagBacks['kb_attack_alert'] = kb_attack_alert;
					layInFront[2].push(kb_attack_alert);		
				}

				bfXOffset = -300;
				bfYOffset = -75;
				dadXOffset = -300;
				dadYOffset = -75;
				bfScrollFactor = [1.1, 1];
				dadScrollFactor = [1.1, 1];
				pixelShitPart1 = 'sonic/exe/ui/';
			}
			case 'facility':
			{
				camZoom = 0.9;
						
				var fac_bg = new FlxSprite( -104.35, -108.25).loadGraphic(Paths.image("whitty/wallbg"),true,2781,1631);
				fac_bg.animation.add("shitfart", [0], 0);
				fac_bg.animation.add("shitfartflip", [1], 1);
				fac_bg.animation.play("shitfart");
				swagBacks['fac_bg'] = fac_bg;
				toAdd.push(fac_bg);

				var headlight = new FlxSprite( 891.2, 166.75).loadGraphic(Paths.image("whitty/light"));
				headlight.blend = "add";
				swagBacks['headlight'] = headlight;
				toAdd.push(headlight);

				bfXOffset = 660;
				bfYOffset = 230;
				gfXOffset = 575;
				gfYOffset = 430;
				dadXOffset = 310;
				dadYOffset = 250;
				gfScrollFactor = [1, 1];
			}

			case 'trollgestage':
			{
				camZoom = 0.6;

				var bg:FlxSprite = new FlxSprite(-600, -700).loadGraphic(Paths.image('trollgestage'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var bg2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('tabi/fire/vignette')); //they're almost the same. i'm not adding two of em
				bg2.antialiasing = FlxG.save.data.antialiasing;
				bg2.active = false;
				bg2.alpha = 0.5;
				if (!preloading)
					bg2.cameras = [PlayState.instance.camHUD];
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);
			}

			case 'auditorHell' | 'auditorHell2': //cuz i aint replacing the original till i get everything working. also this is primarily used for switching in the stage for exTricky so like... screw not adding the hole.
			{
				camZoom = 0.55;

				var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('madness/tricky/fourth/bg'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 4));
				swagBacks['bg'] = bg;
				toAdd.push(bg);
						
				var energyWall:FlxSprite = new FlxSprite(1350,-690).loadGraphic(Paths.image("madness/tricky/fourth/Energywall"));
				energyWall.antialiasing = true;
				energyWall.scrollFactor.set(0.9, 0.9);
				swagBacks['energyWall'] = energyWall;
				toAdd.push(energyWall);
				
				var stageFront:FlxSprite = new FlxSprite(-350, -355).loadGraphic(Paths.image('madness/tricky/fourth/daBackground'));
				stageFront.antialiasing = true;
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.55));
				swagBacks['stageFront'] = stageFront;
				toAdd.push(stageFront);

				if (daStage == 'auditorHell')
				{
					var cover2 = new FlxSprite(-180,755).loadGraphic(Paths.image('madness/tricky/fourth/covercrackless'));
					cover2.antialiasing = true;
					cover2.setGraphicSize(Std.int(cover2.width * 1.55));
					swagBacks['cover2'] = cover2;
					layInFront[0].push(cover2);

					if (PlayState.isVitor)
					{
						cloneOne = new FlxSprite(0,0);
						cloneTwo = new FlxSprite(0,0);
						cloneOne.frames = Paths.getSparrowAtlas('madness/tricky/fourth/Clone');
						cloneTwo.frames = Paths.getSparrowAtlas('madness/tricky/fourth/Clone');
						cloneOne.alpha = 0;
						cloneTwo.alpha = 0;
						cloneOne.animation.addByPrefix('clone','Clone',24,false);
						cloneTwo.animation.addByPrefix('clone','Clone',24,false);

						swagBacks['cloneOne'] = cloneOne;
						layInFront[1].push(cloneOne);
						swagBacks['cloneTwo'] = cloneTwo;
						layInFront[1].push(cloneTwo);
					}
				}

				var hole = new FlxSprite(50,530).loadGraphic(Paths.image('madness/tricky/fourth/Spawnhole_Ground_BACK'));
				hole.setGraphicSize(Std.int(hole.width * 1.55));
				hole.antialiasing = true;
				swagBacks['hole'] = hole;
				toAdd.push(hole);

				var cover = new FlxSprite(-180,755).loadGraphic(Paths.image('madness/tricky/fourth/cover'));
				cover.antialiasing = true;
				cover.setGraphicSize(Std.int(cover.width * 1.55));
				swagBacks['cover'] = cover;
				layInFront[2].push(cover);
				
				var converHole = new FlxSprite(7,578).loadGraphic(Paths.image('madness/tricky/fourth/Spawnhole_Ground_COVER'));
				converHole.antialiasing = true;
				converHole.setGraphicSize(Std.int(converHole.width * 1.3));
				swagBacks['converHole'] = converHole;
				layInFront[2].push(converHole);

				if (daStage == 'auditorHell' && !PlayState.isVitor)
				{
					hole.alpha = 0;
					converHole.alpha = 0;
					cover.alpha = 0;
				}

				tstatic = new FlxSprite(0,0).loadGraphic(Paths.image('madness/tricky/TrickyStatic'), true, 320, 180);
				tstatic.antialiasing = true;
				tstatic.scrollFactor.set(0,0);
				tstatic.setGraphicSize(Std.int(tstatic.width * 8.3));
				tstatic.animation.add('static', [0, 1, 2], 24, true);
				tstatic.animation.play('static');
				tstatic.alpha = 0.1;
				tstatic.setGraphicSize(Std.int(tstatic.width * 12));
				tstatic.x += 600;
				swagBacks['tstatic'] = tstatic; //so that it also destroys the static
				layInFront[2].push(tstatic);

				bfYOffset = -160;
				bfXOffset = 350;
				gfXOffset = 345;
				gfYOffset = -25;	
			}

			case 'trickystage':
			{
				camZoom = 0.47;
				
				var bg:FlxSprite = new FlxSprite();
				bg.frames = Paths.getSparrowAtlas('madness/auditor/trickyweek/trickybg');
				bg.animation.addByPrefix('idle', 'bg static', 24, false);
				bg.animation.addByPrefix('flash', 'bg flash', 24, false);
				bg.animation.play('idle');
				bg.setGraphicSize(Std.int(bg.width * 1.3));
				bg.updateHitbox();
				bg.setPosition(-1570, -520);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var wall:FlxSprite = new FlxSprite();
				wall.frames = Paths.getSparrowAtlas('madness/auditor/trickyweek/rightwallbg');
				wall.animation.addByPrefix('idle', 'rightwallbg static', 24, false);
				wall.animation.addByPrefix('flash', 'rightwallbg flash', 24, false);
				wall.animation.play('idle');
				wall.setGraphicSize(Std.int(wall.width * 1.3));
				wall.updateHitbox();
				wall.setPosition(1000, -330);
				swagBacks['wall'] = wall;
				layInFront[2].push(wall);

				if (PlayState.isBETADCIU)
				{
					var punch:FlxSprite = new FlxSprite();
					punch.frames = Paths.getSparrowAtlas('picopunch');
					punch.animation.addByPrefix('punch', 'FinalPunch', 24, false);
					punch.animation.play('punch');
					punch.setPosition(350, 0);
					swagBacks['punch'] = punch;
					layInFront[2].push(punch);

					var nikusawall:FlxSprite = new FlxSprite().loadGraphic(Paths.image('madness/auditor/trickyweek/wallpalette'), true, 1, 1);
					nikusawall.animation.add('flash', [0,1,2,3,4], 24, false);
					nikusawall.animation.add('static', [4], 24, false);
					nikusawall.animation.play('static');
					nikusawall.setGraphicSize(Std.int(nikusawall.width * 600));
					nikusawall.updateHitbox();
					nikusawall.setPosition(1150, -560);
					swagBacks['nikusawall'] = nikusawall;
					layInFront[2].push(nikusawall);
				}

				var alarm:FlxSprite = new FlxSprite();
				alarm.frames = Paths.getSparrowAtlas('madness/auditor/trickyweek/alarm');
				alarm.animation.addByPrefix('idle', 'alarm light', 24, true);
				alarm.setGraphicSize(Std.int(alarm.width * 0.8));
				alarm.updateHitbox();

				//cuz I did some rescaling stuff
				alarm.setGraphicSize(Std.int(alarm.width * 1.3));
				alarm.updateHitbox();
				alarm.setPosition(1140, -280);
			
				alarm.animation.play('idle', true);
				swagBacks['alarm'] = alarm;
				layInFront[2].push(alarm);

				bfXOffset = 400;
			}

			/*case 'factory':
			{
				camZoom = 0.7;
				
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('factory'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.9, 0.9);
				bg.setPosition(-500, -330);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var bg2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('shadow'));
				bg2.antialiasing = FlxG.save.data.antialiasing;
				bg2.scrollFactor.set(0.5, 0.5);
				bg2.setPosition(-500, -100);
				bg2.active = false;
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);
			}
			case 'minigames':
			{
				camZoom = 0.5;

				var bgs = new FlxTypedGroup<FlxSprite>();
				swagGroup['bgs'] = bgs;
				toAdd.push(bgs);

				for (i in 0...5)
				{
					var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('FNAF/shadowbonnie/bg'+i));
					bg.setGraphicSize(Std.int(bg.width * 1.7));
					bg.updateHitbox();
					bg.screenCenter();
					bg.visible = false;
					bg.antialiasing = false;
					bg.x -= 30;
					bg.y += 50;
					bgs.add(bg);
					swagBacks['bg' + i] = bg;	
				}

				var lines = new FlxSprite().loadGraphic(Paths.image('FNAF/shadowbonnie/lines'));
				lines.screenCenter();
				if (!preloading)
					lines.cameras = [PlayState.instance.camOther];
				swagBacks['lines'] = lines;
				layInFront[2].push(lines);
			}
			case 'loggostage2':
			{
				camZoom = 0.9;

				var space:FlxSprite = new FlxSprite().loadGraphic(Paths.image('impostor/xmas/space'));
				space.antialiasing = FlxG.save.data.antialiasing;
				space.setGraphicSize(Std.int(space.width * 3.5));
				space.updateHitbox();
				space.setPosition(-750, -600);
				space.active = false;
				swagBacks['space'] = space;
				toAdd.push(space);

				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('impostor/xmas/placeholder Hell'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.setGraphicSize(Std.int(bg.width * 3.5));
				bg.updateHitbox();
				bg.setPosition(-750, -600);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var boppers:FlxSprite = new FlxSprite();
				boppers.frames = Paths.getSparrowAtlas('impostor/xmas/people');
				boppers.animation.addByPrefix('idle', 'the guys', 24, false);
				boppers.antialiasing = FlxG.save.data.antialiasing;
				boppers.setGraphicSize(Std.int(boppers.width * 3.5));
				boppers.updateHitbox();
				boppers.setPosition(-750, -600);
				swagBacks['boppers'] = boppers;
				toAdd.push(boppers);
				animatedBacks2.push(boppers);

				var lines = new FlxSprite().loadGraphic(Paths.image('impostor/xmas/dark'));
				lines.screenCenter();
				if (!preloading)
					lines.cameras = [PlayState.instance.camOther];
				swagBacks['lines'] = lines;
				layInFront[2].push(lines);
			}

			case 'careystage':
			{
				camZoom = 0.9;

				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('xmas/bg'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.8, 0.8);
				bg.scale.set(1.5, 1.5);
				bg.setPosition(-600, -200);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var snow:FlxSprite = new FlxSprite().loadGraphic(Paths.image('xmas/snow'));
				snow.antialiasing = FlxG.save.data.antialiasing;
				snow.setPosition(0, 700);
				snow.active = false;
				swagBacks['snow'] = snow;
				layInFront[0].push(snow);

				var snowFront:FlxSprite = new FlxSprite();
				snowFront.frames = Paths.getSparrowAtlas('xmas/snow1');
				snowFront.animation.addByPrefix('idle', 'Snow', 24, true);
				snowFront.antialiasing = FlxG.save.data.antialiasing;
				snowFront.animation.play('idle');
				snowFront.setPosition(100, 0);
				snowFront.scale.set(2.5, 2.5);
				swagBacks['snowFront'] = snowFront;
				layInFront[0].push(snowFront);

				var snow2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('xmas/snow2'));
				snow2.antialiasing = FlxG.save.data.antialiasing;
				snow2.setPosition(150, 800);
				snow2.active = false;
				swagBacks['snow2'] = snow2;
				layInFront[2].push(snow2);

				var gradient:FlxSprite = new FlxSprite().loadGraphic(Paths.image('xmas/gradient'));
				gradient.antialiasing = FlxG.save.data.antialiasing;
				if (!preloading)
					gradient.cameras = [PlayState.instance.camHUD];
				gradient.alpha = 0.7;
				gradient.active = false;
				swagBacks['gradient'] = gradient;
				layInFront[2].push(gradient);	

				bfXOffset = 200; //maybe i could move em here instead
			}

			case 'snowbg': //thx mate
			{
				camZoom = 0.7;

				var castle = new FlxSprite().loadGraphic(Paths.image('snow/castle'));
				castle.setGraphicSize(3114,2145);
				castle.updateHitbox();
				castle.x = -281;
				castle.y = -762;
				castle.antialiasing = true;
				castle.scrollFactor.set(0.75, 1);
				castle.active = false;
				swagBacks['castle'] = castle;
				toAdd.push(castle);

				var crystal = new FlxSprite().loadGraphic(Paths.image('snow/bridge'));
				crystal.updateHitbox();
				crystal.x = -434;
				crystal.y = 258;
				crystal.antialiasing = true;
				crystal.scrollFactor.set(1, 1);
				crystal.active = false;
				swagBacks['crystal'] = crystal;
				toAdd.push(crystal);

				var stage = new FlxSprite().loadGraphic(Paths.image('snow/stage'));
				stage.updateHitbox();
				stage.x = -540;
				stage.y = 1160;
				stage.antialiasing = true;
				stage.scrollFactor.set(1, 1);
				stage.active = false;
				swagBacks['stage'] = stage;
				toAdd.push(stage);

				var snowParticles = new FlxEmitter(-500, 50, 1000);
				for (i in 0...1000) //why load so much!?
				{
					var randoString:String = "";
					if (FlxG.random.bool(50))
					{
						randoString = "Small";
						if (FlxG.random.bool(50))
							randoString = "Medium";
					}
						
					var p = new FlxParticle();
					p.loadGraphic(Paths.image('snow/particle/snow'+ randoString), false);

					p.alpha = FlxG.random.float(0.3, 0.7);
					p.lifespan = 1000000;
					p.exists = false;
					var scale = FlxG.random.float(0.5, 1);
					p.scale.set(scale, scale);
					snowParticles.add(p);
				}
				snowParticles.start(false, 0.05);
				snowParticles.acceleration.set(0, 0, 0, 0, FlxG.width, FlxG.width, FlxG.height, FlxG.height);
				FlxTween.tween(snowParticles, {x: FlxG.width + 500}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
				swagBacks['snowParticles'] = snowParticles;
				layInFront[2].push(snowParticles);
			}

			/*case 'cgstage':
			{
				camZoom = 0.7;

				var bganim = new FlxSprite();
				bganim.screenCenter();
				bganim.scale.set(1.25,1.25);
				bganim.frames = Paths.getSparrowAtlas('weekcg/CGBG');
				bganim.animation.addByPrefix('idle', 'new', 24,false);
				bganim.antialiasing = true;
				bganim.x -= 1250;
				bganim.y -= 980;
				swagBacks['bganim'] = bganim;
				animatedBacks2.push(bganim);
				toAdd.push(bganim);

				var coolboppers = new FlxSprite();
				coolboppers.scale.set(1.3,1.3);
				coolboppers.screenCenter();
				coolboppers.frames = Paths.getSparrowAtlas('weekcg/bopper1');
				coolboppers.animation.addByPrefix('idle', 'crowd1', 24, false);
				coolboppers.x -= 650;
				coolboppers.y -= 80;
				swagBacks['coolboppers'] = coolboppers;
				animatedBacks2.push(coolboppers);
				layInFront[0].push(coolboppers);

				var coolboppers2 = new FlxSprite();
				coolboppers2.scale.set(1.3,1.3);
				coolboppers2.screenCenter();
				coolboppers2.antialiasing = true;
				coolboppers.antialiasing = true;
				coolboppers2.frames = Paths.getSparrowAtlas('weekcg/bopper2');
				coolboppers2.animation.addByPrefix('idle', 'crowd1', 24, false);
				coolboppers2.x -= 700;
				coolboppers2.y -= 110;
				swagBacks['coolboppers2'] = coolboppers2;
				animatedBacks2.push(coolboppers2);
				layInFront[0].push(coolboppers2);

				c1 = new FlxSprite().loadGraphic(Paths.image('weekcg/BGLAYER'));
				c1.screenCenter();
				c1.antialiasing = true;
				c1.scale.set(5,5);
				c1.alpha = 0.00001;
				c1.y -= 20;
				c1.blend = BlendMode.OVERLAY;
				swagBacks['c1'] = c1;
				layInFront[2].push(c1);

				//i'm not loading different ones. just use color swap!
				purple = new FlxSprite().loadGraphic(Paths.image('weekcg/DOWN LIGHT'));
				purple.screenCenter();
				if (!preloading)
					purple.cameras = [PlayState.instance.camOther];
				var newShader:ColorSwap = new ColorSwap();
				purple.shader = newShader.shader;
				newShader.hue = 100 / 360;
				purple.scale.set(0.81,0.81);
				purple.antialiasing = true;
				purple.blend = BlendMode.OVERLAY;
				swagBacks['purple'] = purple;
				layInFront[2].push(purple);

				purple2 = new FlxSprite().loadGraphic(Paths.image('weekcg/DOWN LIGHT'));
				purple2.screenCenter();
				if (!preloading)
					purple2.cameras = [PlayState.instance.camOther];
				var newShader:ColorSwap = new ColorSwap();
				purple2.shader = newShader.shader;
				newShader.hue = 100 / 360;
				purple2.scale.set(0.81,0.81);
				purple2.antialiasing = true;
				purple2.blend = BlendMode.OVERLAY;
				swagBacks['purple2'] = purple2;
				layInFront[2].push(purple2);

				blue = new FlxSprite().loadGraphic(Paths.image('weekcg/DOWN LIGHT'));
				blue.screenCenter();
				if (!preloading)
					blue.cameras = [PlayState.instance.camOther];
				blue.scale.set(0.81,0.81);
				blue.antialiasing = true;
				blue.blend = BlendMode.OVERLAY;
				swagBacks['blue'] = blue;
				layInFront[2].push(blue);

				blue2 = new FlxSprite().loadGraphic(Paths.image('weekcg/DOWN LIGHT'));
				blue2.screenCenter();
				if (!preloading)
					blue2.cameras = [PlayState.instance.camOther];
				blue2.scale.set(0.81,0.81);
				blue2.antialiasing = true;
				blue2.blend = BlendMode.OVERLAY;
				swagBacks['blue2'] = blue2;
				layInFront[2].push(blue2);

				green = new FlxSprite().loadGraphic(Paths.image('weekcg/DOWN LIGHT'));
				green.screenCenter();
				if (!preloading)
					green.cameras = [PlayState.instance.camOther];
				var newShader:ColorSwap = new ColorSwap();
				green.shader = newShader.shader;
				newShader.hue = -75 / 360;
				green.scale.set(0.81,0.81);
				green.antialiasing = true;
				green.blend = BlendMode.OVERLAY;
				swagBacks['green'] = green;
				layInFront[2].push(green);

				green2 = new FlxSprite().loadGraphic(Paths.image('weekcg/DOWN LIGHT'));
				green2.screenCenter();
				if (!preloading)
					green2.cameras = [PlayState.instance.camOther];
				var newShader:ColorSwap = new ColorSwap();
				green2.shader = newShader.shader;
				newShader.hue = -75 / 360;
				green2.scale.set(0.81,0.81);
				green2.antialiasing = true;
				green2.blend = BlendMode.OVERLAY;
				swagBacks['green2'] = green2;
				layInFront[2].push(green2);
				
				red = new FlxSprite().loadGraphic(Paths.image('weekcg/DOWN LIGHT'));
				red.screenCenter();
				if (!preloading)
					red.cameras = [PlayState.instance.camOther];
				var newShader:ColorSwap = new ColorSwap();
				red.shader = newShader.shader;
				newShader.hue = 150 / 360;
				red.scale.set(0.81,0.81);
				red.antialiasing = true;
				red.blend = BlendMode.OVERLAY;
				swagBacks['red'] = red;
				layInFront[2].push(red);

				red2 = new FlxSprite().loadGraphic(Paths.image('weekcg/DOWN LIGHT'));
				red2.screenCenter();
				if (!preloading)
					red2.cameras = [PlayState.instance.camOther];
				var newShader:ColorSwap = new ColorSwap();
				red2.shader = newShader.shader;
				newShader.hue = 150 / 360;
				red2.scale.set(0.81,0.81);
				red2.antialiasing = true;
				red2.blend = BlendMode.OVERLAY;
				swagBacks['red2'] = red2;
				layInFront[2].push(red2);

				purple.alpha = 0.00001;
				green.alpha = 0.00001;
				red.alpha = 0.00001;
				blue.alpha = 0.00001;

				purple2.alpha = 0.00001;
				green2.alpha = 0.00001;
				red2.alpha = 0.00001;
				blue2.alpha = 0.00001;

				gfXOffset = -100;
				gfYOffset = 20;
				dadXOffset = -110;
				dadYOffset = 140;
				bfYOffset = 140;

				gfScrollFactor = [1, 1];

				cgPlayerOverlays = [purple, blue, green, red];
				cgPlayerScales = [purplescale, bluescale, greenscale, redscale];
				cgPlayerTweens = [purpletween, bluetween, greentween, redtween];

				cgOpponentOverlays = [purple2, blue2, green2, red2];
				cgOpponentScales = [purplescale2, bluescale2, greenscale2, redscale2];
				cgOpponentTweens = [purpletween2, bluetween2, greentween2, redtween2];
			}
			/*case 'eddhouse' | 'eddhouse-bot':
			{				
				camZoom = 1.05;
				curStage = 'eddhouse';

				var sky:FlxSprite = new FlxSprite( -162.1, -386.1);
				sky.frames = Paths.getSparrowAtlas("backgrounds/eddsworld/tord/sky");
				sky.animation.addByPrefix("bg_sky1", "bg_sky1");
				sky.animation.addByPrefix("bg_sky2", "bg_sky2");
				sky.active = false;
				sky.updateHitbox();

				if (songLowercase == 'tordbot' || daStage == 'eddhouse-bot')
					sky.animation.play("bg_sky2");
				else
					sky.animation.play("bg_sky1");

				if (daStage != 'eddhouse-bot')
					sky.scrollFactor.set(0.5, 0);
				else
					sky.scrollFactor.set();

				swagBacks['sky'] = sky;
				toAdd.push(sky);
							
				var bg = new FlxSprite( -162.1, -386.1);
				bg.frames = Paths.getSparrowAtlas("backgrounds/eddsworld/tord/bgFront");
				bg.animation.addByPrefix("bg_normal", "bg_normal");
				bg.animation.addByPrefix("bg_destroy", "bg_destroy");
				bg.active = false;
				bg.updateHitbox();
				
				if (songLowercase == 'tordbot' || daStage == 'eddhouse-bot')
					bg.animation.play("bg_destroy");
				else
					bg.animation.play("bg_normal");

				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				swagBacks['bg'] = bg;
				toAdd.push(bg);
				
				if (songLowercase == 'norway' || songLowercase == 'norsky')
				{
					var bfPath:String = 'characters/BOYFRIEND';
					var tordPath:String = 'characters/tord_assets';

					if (songLowercase == 'norsky')
					{
						bfPath = 'characters/BOYFRIEND_TABI';
						tordPath = 'backgrounds/eddsworld/tord/tord_assets';
					}
					
					var tordBG = new FlxSprite(25, 100);
					tordBG.frames = Paths.getSparrowAtlas(tordPath);
					tordBG.animation.addByPrefix('idle', 'tord idle', 24, false);
					tordBG.antialiasing = true;
					tordBG.scrollFactor.set(0.9, 0.9);
					tordBG.setGraphicSize(Std.int(tordBG.width * 0.7));
					tordBG.updateHitbox();
					tordBG.animation.play('idle');
					swagBacks['tordBG'] = tordBG;
					animatedBacks2.push(tordBG);
					toAdd.push(tordBG);

					var bfBG = new FlxSprite(-200, 250);
					bfBG.frames = Paths.getSparrowAtlas(bfPath);
					bfBG.animation.addByPrefix('idle', "BF idle dance", 24, false);
					bfBG.scrollFactor.set(0.9, 0.9);
					bfBG.antialiasing = true;
					bfBG.setGraphicSize(Std.int(bfBG.width * 0.8));
					bfBG.flipX = true;
					bfBG.animation.play('idle');
					swagBacks['bfBG'] = bfBG;
					animatedBacks2.push(bfBG);
					toAdd.push(bfBG);

					if (songLowercase == 'norway')
					{
						var tomBG = new FlxSprite(1250, 0);
						tomBG.frames = Paths.getSparrowAtlas('characters/tom_assets');
						tomBG.animation.addByPrefix('idle', "tord idle", 24, false);
						tomBG.scrollFactor.set(0.9, 0.9);
						tomBG.antialiasing = true;
						tomBG.setGraphicSize(Std.int(tomBG.width * 0.8));
						tomBG.flipX = true;
						tomBG.animation.play('idle');
						swagBacks['tomBG'] = tomBG;
						animatedBacks2.push(tomBG);
						toAdd.push(tomBG);
	
						var gfBG = new GirlfriendBG(750, 20, 'characters/GFBG_assets', 'GF Dancing Beat');
						gfBG.antialiasing = true;
						gfBG.scrollFactor.set(0.9, 0.9);
						gfBG.setGraphicSize(Std.int(gfBG.width * 0.8));
						gfBG.updateHitbox();
						gfBG.dance();
						swagBacks['gfBG'] = gfBG;
						animatedBacks2.push(gfBG);
						toAdd.push(gfBG);

						var mattBG = new FlxSprite(250, -100);
						mattBG.frames = Paths.getSparrowAtlas('characters/matt');
						mattBG.animation.addByPrefix('idle', 'Senpai Idle', 24, false);
						mattBG.scrollFactor.set(0.9, 0.9);
						mattBG.setGraphicSize(Std.int(mattBG.width * 4.5));
						mattBG.updateHitbox();
						mattBG.animation.play('idle');
						swagBacks['mattBG'] = mattBG;
						animatedBacks2.push(mattBG);
						toAdd.push(mattBG);
					}		
				}
				
				bfXOffset = 330;
				dadYOffset = -180;
				bfYOffset = -180;
				gfXOffset = 250;
				gfYOffset = -235;
			}*/

			/*case 'shaggy-mansion':
			{
				var normbg = new FlxSprite(-400, -160).loadGraphic(Paths.image('shaggy/bg_lemon'));
				normbg.setGraphicSize(Std.int(normbg.width * 1.5));
				normbg.antialiasing = true;
				normbg.scrollFactor.set(0.95, 0.95);
				normbg.active = false;
				swagBacks['normbg'] = normbg;
				toAdd.push(normbg);

				bfXOffset = 100;
			}

			case 'shaggy-mansion-combined':
			{
				camZoom = 0.9;

				var sky = new FlxSprite(-850, -850);
				sky.frames = Paths.getSparrowAtlas('shaggy/god_bg');
				sky.animation.addByPrefix('sky', "bg", 30);
				sky.setGraphicSize(Std.int(sky.width * 0.8));
				sky.animation.play('sky');
				sky.scrollFactor.set(0.1, 0.1);
				sky.antialiasing = true;
				swagBacks['sky'] = sky;
				toAdd.push(sky);

				var bgcloud = new FlxSprite(-850, -1250);
				bgcloud.frames = Paths.getSparrowAtlas('shaggy/god_bg');
				bgcloud.animation.addByPrefix('c', "cloud_smol", 30);
				bgcloud.animation.play('c');
				bgcloud.scrollFactor.set(0.3, 0.3);
				bgcloud.antialiasing = true;
				swagBacks['bgcloud'] = bgcloud;
				toAdd.push(bgcloud);

				toAdd.push(new MansionDebris(300, -800, 'norm', 0.4, 1, 0, 1));
				toAdd.push(new MansionDebris(600, -300, 'tiny', 0.4, 1.5, 0, 1));
				toAdd.push(new MansionDebris(-150, -400, 'spike', 0.4, 1.1, 0, 1));
				toAdd.push(new MansionDebris(-750, -850, 'small', 0.4, 1.5, 0, 1));

				toAdd.push(new MansionDebris(-300, -1700, 'norm', 0.75, 1, 0, 1));
				toAdd.push(new MansionDebris(-1000, -1750, 'rect', 0.75, 2, 0, 1));
				toAdd.push(new MansionDebris(-600, -1100, 'tiny', 0.75, 1.5, 0, 1));
				toAdd.push(new MansionDebris(900, -1850, 'spike', 0.75, 1.2, 0, 1));
				toAdd.push(new MansionDebris(1500, -1300, 'small', 0.75, 1.5, 0, 1));
				toAdd.push(new MansionDebris(-600, -800, 'spike', 0.75, 1.3, 0, 1));
				toAdd.push(new MansionDebris(-1000, -900, 'small', 0.75, 1.7, 0, 1));

				var fgcloud = new FlxSprite(-1150, -2900);
				fgcloud.frames = Paths.getSparrowAtlas('shaggy/god_bg');
				fgcloud.animation.addByPrefix('c', "cloud_big", 30);
				fgcloud.animation.play('c');
				fgcloud.scrollFactor.set(0.9, 0.9);
				fgcloud.antialiasing = true;
				swagBacks['fgcloud'] = fgcloud;
				toAdd.push(fgcloud);

				var techo = new FlxSprite(0, -20);
				techo.frames = Paths.getSparrowAtlas('shaggy/god_bg');
				techo.animation.addByPrefix('r', "broken_techo", 30);
				techo.setGraphicSize(Std.int(techo.frameWidth * 1.5));
				techo.animation.play('r');
				techo.scrollFactor.set(0.95, 0.95);
				techo.antialiasing = true;
				swagBacks['techo'] = techo;
				toAdd.push(techo);

				var gf_rock = new FlxSprite(20, 20);
				gf_rock.frames = Paths.getSparrowAtlas('shaggy/god_bg');
				gf_rock.animation.addByPrefix('rock', "gf_rock", 30);
				gf_rock.animation.play('rock');
				gf_rock.scrollFactor.set(0.8, 0.8);
				gf_rock.antialiasing = true;
				gf_rock.alpha = 0;
				swagBacks['gf_rock'] = gf_rock;
				toAdd.push(gf_rock);

				var rock = new FlxSprite(20, 20);
				rock.frames = Paths.getSparrowAtlas('shaggy/god_bg');
				rock.animation.addByPrefix('rock', "rock", 30);
				rock.animation.play('rock');
				rock.scrollFactor.set(1, 1);
				rock.antialiasing = true;
				rock.alpha = 0;
				swagBacks['rock'] = rock;
				toAdd.push(rock);

				var dadrock = new FlxSprite(20, 20);
				dadrock.frames = Paths.getSparrowAtlas('shaggy/god_bg');
				dadrock.animation.addByPrefix('rock', "rock", 30);
				dadrock.animation.play('rock');
				dadrock.scrollFactor.set(1, 1);
				dadrock.antialiasing = true;
				dadrock.alpha = 0;
				dadrock.flipX = true;
				swagBacks['dadrock'] = dadrock;
				toAdd.push(dadrock);

				var normbg = new FlxSprite(-400, -160).loadGraphic(Paths.image('shaggy/bg_lemon'));
				normbg.setGraphicSize(Std.int(normbg.width * 1.5));
				normbg.antialiasing = true;
				normbg.scrollFactor.set(0.95, 0.95);
				normbg.active = false;
				swagBacks['normbg'] = normbg;
				toAdd.push(normbg);

				var burst = new FlxSprite(-1110, 0).loadGraphic(Paths.image('shaggy/redburst'));
				burst.frames = Paths.getSparrowAtlas('shaggy/redburst');
				burst.animation.addByPrefix('burst', "burst", 30, false);
				burst.animation.play('burst');
				burst.antialiasing = true;
				swagBacks['burst'] = burst;
				layInFront[2].push(burst);

				bfXOffset = 100;
			}

			case 'mackiestage':
			{
				camZoom = 0.60;

				var mackiebg:FlxSprite = new FlxSprite(-2150, -1000).loadGraphic(Paths.image('mackie/citybgtwo'));
				mackiebg.antialiasing = true;
				mackiebg.active = false;
				mackiebg.updateHitbox();
				mackiebg.scrollFactor.set(0.1, 0.1);
				mackiebg.scale.set(0.8, 0.8);
				swagBacks['mackiebg'] = mackiebg;
				toAdd.push(mackiebg);

				var mackiemid:FlxSprite = new FlxSprite(-600, -40).loadGraphic(Paths.image('mackie/citymid'));
				mackiemid.antialiasing = true;
				mackiemid.active = false;
				mackiemid.updateHitbox();
				mackiemid.scrollFactor.set(0.8, 0.8);
				swagBacks['mackiemid'] = mackiemid;
				toAdd.push(mackiemid);

				var mackieinterior:FlxSprite = new FlxSprite(-1300, -400).loadGraphic(Paths.image('mackie/interior'));
				mackieinterior.antialiasing = true;
				mackieinterior.active = false;
				mackieinterior.updateHitbox();
				mackieinterior.scrollFactor.set(0.95, 0.95);
				swagBacks['mackieinterior'] = mackieinterior;
				toAdd.push(mackieinterior);

				var alya = new FlxSprite(-900, 150);
				alya.frames = Paths.getSparrowAtlas('mackie/alyabob');
				alya.animation.addByPrefix('idle', 'alya bob', 24, false);
				alya.antialiasing = true;
				alya.scrollFactor.set(0.95, 0.95);
				swagBacks['alya'] = alya;
				toAdd.push(alya);
				animatedBacks.push(alya);

				var mackiecity:FlxSprite = new FlxSprite(-2470, -1140).loadGraphic(Paths.image('mackie/mackiecity'));
				mackiecity.antialiasing = true;
				mackiecity.active = false;
				mackiecity.updateHitbox();
				swagBacks['mackiecity'] = mackiecity;
				toAdd.push(mackiecity);

				var tricky = new FlxSprite(1400, 722);
				tricky.frames = Paths.getSparrowAtlas('mackie/sewertricky');
				tricky.animation.addByPrefix('idle', 'sewertricky', 24, false);
				tricky.antialiasing = true;
				swagBacks['tricky'] = tricky;
				toAdd.push(tricky);
				animatedBacks.push(tricky);

				var anchor = new FlxSprite(-720, 22);
				anchor.frames = Paths.getSparrowAtlas('mackie/anchor');
				anchor.animation.addByPrefix('idle', 'anchorbob', 24, false);
				anchor.antialiasing = true;
				swagBacks['anchor'] = mackiebg;
				toAdd.push(anchor);
				animatedBacks.push(anchor);

				var bgcrowd = new FlxSprite(-1020, 460);
				bgcrowd.frames = Paths.getSparrowAtlas('mackie/crowdbob');
				bgcrowd.animation.addByPrefix('idle', 'crowd bob', 24, false);
				bgcrowd.antialiasing = true;
				swagBacks['bgcrowd'] = bgcrowd;
				layInFront[2].push(bgcrowd);
				animatedBacks.push(bgcrowd);

				var bgcrowdjump = new FlxSprite(-1020, 460);
				bgcrowdjump.frames = Paths.getSparrowAtlas('mackie/crowdjump');
				bgcrowdjump.animation.addByPrefix('idle', 'crowd jump', 24, false);
				bgcrowdjump.antialiasing = true;
				swagBacks['bgcrowdjump'] = bgcrowdjump;
				layInFront[2].push(bgcrowdjump);
				animatedBacks.push(bgcrowdjump);

				dadXOffset = -300;
				bfXOffset = 300;	
			}
	
		/*	case 'julianalley':
			{
				camZoom = 0.7;

				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('whitty/thawal'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.9, 0.9);
				bg.setPosition(-870, -360);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var bg2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('whitty/thagroun'));
				bg2.antialiasing = FlxG.save.data.antialiasing;
				bg2.scrollFactor.set(1, 1);
				bg2.setPosition(-600, -350);
				bg2.active = false;
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);
				
				bfXOffset = 330;
				bfYOffset = 50;
				gfXOffset = 130;
				gfYOffset = 50;
				dadXOffset = 180;
				dadYOffset = 50;
			}

			case 'julianalley-cool':
			{
				camZoom = 0.7;
				
				var bg:FlxSprite = new FlxSprite();
				bg.frames = Paths.getSparrowAtlas('whitty/tha_swag_wal');
				bg.animation.addByPrefix('idle','wal style change',24,true);
				bg.animation.play('idle');
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.9, 0.9);
				bg.setPosition(-870, -360);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var bg2:FlxSprite = new FlxSprite();
				bg2.frames = Paths.getSparrowAtlas('whitty/tha_cool_groun');
				bg2.animation.addByPrefix('idle','flo style change',24,true);
				bg2.animation.play('idle');
				bg2.antialiasing = FlxG.save.data.antialiasing;
				bg2.scrollFactor.set(1, 1);
				bg2.setPosition(-600, -350);
				swagBacks['bg2'] = bg2;
				toAdd.push(bg2);

				bfXOffset = 330;
				bfYOffset = 50;
				gfXOffset = 130;
				gfYOffset = 50;
				dadXOffset = 180;
				dadYOffset = 50;
			}
		
			case 'garage':
			{
				camZoom = 1;

				var aaa = new FlxSprite( -422.05, 284.05);
				aaa.frames = Paths.getSparrowAtlas('sunday/aaa');
				aaa.animation.addByIndices("none", "aaaa",[4],"", 24, false);
				aaa.animation.addByIndices("idle", "aaaa",[0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,4],"", 24, false);
				aaa.animation.play("none");

				var garage = new FlxSprite( -316, -209);
				var speakers = new FlxSprite( -298, 197);
				var glowShit:FlxSprite = new FlxSprite(-255.15,186.55);
			
				if (songLowercase == 'bi-nb')
				{
					garage.frames = Paths.getSparrowAtlas('sunday/bg_binb');
					garage.animation.addByPrefix("idle", "Background");
					garage.animation.addByPrefix("crazy", "bg_binb");
					garage.animation.addByPrefix("notcrazy", "bg_binb_calm",10);
					speakers.frames = Paths.getSparrowAtlas('sunday/rig');
					speakers.animation.addByIndices("idle", "amp",[0],"", 24,true);
					speakers.animation.addByPrefix("boom", "amp boom", 24,true);
					speakers.setPosition(-260.75,243.95);
					swagBacks['garage'] = garage;
					toAdd.push(garage);
				}
				else if (songLowercase == 'marx')
				{
					garage.frames = Paths.getSparrowAtlas('sunday/bg_marx');
					garage.animation.addByPrefix("idle", "Background");
					garage.animation.addByPrefix("crazy", "bg_radicalLeft");
					garage.animation.addByPrefix("notcrazy", "bg_moderateLeft");
					swagBacks['garage'] = garage;
					toAdd.push(garage);

					speakers.frames = Paths.getSparrowAtlas('sunday/rig');
					speakers.animation.addByIndices("idle", "amp",[0],"", 24,true);
					speakers.animation.addByPrefix("boom", "amp boom", 24, true);
					speakers.setPosition( -260.75, 243.95);

					var glowShit:FlxSprite = new FlxSprite(-255.15,186.55);
					glowShit.loadGraphic(Paths.image('sunday/shiny'));
					glowShit.blend = "add";
					glowShit.visible = false;
	
					var carolEnter:FlxSprite = new FlxSprite(795.25-193.95-37, 45.35-237+173);
					carolEnter.frames = Paths.getSparrowAtlas("sunday/carol_enter");
					carolEnter.animation.addByPrefix("wait", "carol interupt", 0, false);
					carolEnter.animation.addByPrefix("enter", "carol interupt", 24, false);
					carolEnter.animation.play("wait");
					swagBacks['carolEnter'] = carolEnter;
					toAdd.push(carolEnter);

					FlxG.sound.cache(Paths.sound("carolTellsSundayToSTFU"));
					var ending:FlxSprite = new FlxSprite().loadGraphic(Paths.image("sunday/ending"));
					ending.scrollFactor.set();				
				}
				else
				{
					garage.frames = Paths.getSparrowAtlas('sunday/bg');
					garage.animation.addByPrefix("idle", "Background");
					garage.animation.addByPrefix("crazy", "bg_with_seizures");
					garage.animation.addByPrefix("notcrazy", "bg_withought_seizures");
					speakers.frames = Paths.getSparrowAtlas('sunday/bigspeakers');
					speakers.animation.addByIndices("idle", "speakers",[0],"", 24,true);
					speakers.animation.addByPrefix("boom", "speakers", 24,true);
					swagBacks['garage'] = garage;
					toAdd.push(garage);
				}

				var fret:FlxSprite = new FlxSprite().loadGraphic(Paths.image("sunday/fret"));
				fret.alpha = 0;
				fret.scrollFactor.set();
				if (!preloading)
					fret.cameras = [PlayState.instance.camHUD];

				garage.antialiasing = true;
				garage.active = true;
				garage.animation.play("idle");

				swagBacks['aaa'] = aaa;
				toAdd.push(aaa);

				speakers.antialiasing = true;
				speakers.active = true;
				swagBacks['speakers'] = speakers;
				toAdd.push(speakers);
				speakers.animation.play("idle");

				swagBacks['glowShit'] = glowShit;
				layInFront[2].push(glowShit);

				swagBacks['fret'] = fret;
				layInFront[2].push(fret);

				bfXOffset = 30;
				bfYOffset = -160;
				gfXOffset = 180;
				gfYOffset = -800;
				dadXOffset = 65;
				dadYOffset = -160;
			}

			//the end of my stuff
			case 'FNAFstage' | 'holostage-corrupt' | 'arcade' | 'ballin' | 'holostage-past' | 'stuco':
			{
				camZoom = 0.9;
				var stageShit:String ='';

				switch (daStage)
				{
						introAssets = ['holofunk/ui/ready', 'holofunk/ui/set', 'holofunk/ui/go'];
					case 'FNAFstage':
						stageShit = 'FNAF/';
					case 'holostage-corrupt':
						stageShit = 'holofunk/stage/corrupt';
						pixelShitPart1 = 'corruption/ui/';
					case 'holostage-past':
						stageShit = 'holofunk/stage/past';
						introAssets = ['bw/flipped/ready', 'bw/flipped/set', 'bw/flipped/go'];
						pixelShitPart1 = 'bw/flipped/';
					case 'arcade':
						stageShit = 'kapi/';
					case 'ballin':
						stageShit = 'hex/';
					case 'stuco':
						stageShit = 'stuco';
				}

				if (daStage == 'holostage-corrupt')
				{
					var bg2 = new FlxSprite(-600, -200).loadGraphic(Paths.image('holofunk/stage/eyes'));
					bg2.antialiasing = true;
					bg2.scrollFactor.set(0.9, 0.9);
					bg2.active = false;
					swagBacks['bg2'] = bg2;
					toAdd.push(bg2);
				}

				var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image(stageShit+'stageback'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image(stageShit+'stagefront'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = FlxG.save.data.antialiasing;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				swagBacks['stageFront'] = stageFront;
				toAdd.push(stageFront);

				var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image(stageShit+'stagecurtains'));
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				stageCurtains.scrollFactor.set(1.3, 1.3);
				stageCurtains.active = false;

				swagBacks['stageCurtains'] = stageCurtains;
				layInFront[2].push(stageCurtains);

				if (daStage == 'holostage-corrupt')
				{
					var bg3 = new FlxSprite(-600, -200).loadGraphic(Paths.image('holofunk/stage/overlay'));
					bg3.antialiasing = true;
					bg3.scrollFactor.set(0.9, 0.9);
					bg3.active = false;
					swagBacks['bg3'] = bg3;
					toAdd.push(bg3);			
				}
			}*/
			case 'stardust':
			{
				camZoom = 0.5;

				var bg = new FlxBackdrop(Paths.image('stardustBg'), 0.1, 0, true, false);
				bg.velocity.set(-1500, 0);
				if (!preloading)
					bg.setGraphicSize(Std.int(bg.width / PlayState.instance.defaultCamZoom));

				bg.offset.x = 1500;
				bg.updateHitbox();
				bg.screenCenter(XY);
				swagBacks['bg'] = bg;
				toAdd.push(bg);

				var floor = new FlxBackdrop(Paths.image('stardustFloor'), 0.1, 0, true, false);
				floor.velocity.set(-1500, 0);	
				if (!preloading)
					floor.setGraphicSize(Std.int(floor.width / PlayState.instance.defaultCamZoom));

				floor.offset.x = 1500;
				floor.updateHitbox();
				floor.screenCenter(XY);
				floor.y -= 325;
				swagBacks['floor'] = floor;
				toAdd.push(floor);

			}
			default:
			{
				//lua stages boi
				isCustomStage = true;
				trace('using a custom stage');

				if(!FileSystem.exists(Paths.getPreloadPath('stages/' + curStage + '.json')) && !FileSystem.exists(Paths.modFolders('stages/' + curStage + '.json')))
				{
					trace('oops we usin the default stage');
					curStage = 'stage'; //defaults to stage if we can't find the path
				}
	
				var stageData:StageFile = StageData.getStageFile(curStage);
				if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
					stageData = {
						directory: "",
						defaultZoom: 0.9,
						isPixelStage: false,
					
						boyfriend: [770, 100],
						girlfriend: [400, 130],
						opponent: [100, 100],
						hide_girlfriend: false,
					
						camera_boyfriend: [0, 0],
						camera_opponent: [0, 0],
						camera_girlfriend: [0, 0],
						camera_speed: 1,

						ratingSkin: ['', ''],
						countdownAssets: ['ready', 'set', 'go']
					};
				}
				
				camZoom = stageData.defaultZoom;
				bfXOffset = stageData.boyfriend[0] - 770;
				bfYOffset = stageData.boyfriend[1] - 100;
				gfXOffset = stageData.girlfriend[0] - 400;
				gfYOffset = stageData.girlfriend[1] - 130;
				dadXOffset = stageData.opponent[0] - 100;
				dadYOffset = stageData.opponent[1] - 100;

				boyfriendCameraOffset = stageData.camera_boyfriend;
				if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
					boyfriendCameraOffset = [0, 0];

				opponentCameraOffset = stageData.camera_opponent;
				if(opponentCameraOffset == null)
					opponentCameraOffset = [0, 0];
				
				girlfriendCameraOffset = stageData.camera_girlfriend;
				if(girlfriendCameraOffset == null)
					girlfriendCameraOffset = [0, 0];

				hideGirlfriend = stageData.hide_girlfriend;

				if (stageData.ratingSkin != null)
				{
					pixelShitPart1 = stageData.ratingSkin[0];
					pixelShitPart2 = stageData.ratingSkin[1];
				}
				
				if (stageData.countdownAssets != null)
					introAssets = stageData.countdownAssets;

				luaArray.push(new StageModchartState(curStage));

				if (luaArray.length >= 1)
					callOnLuas('onCreate', []);	
			}
		}

		switch (daStage)
		{
			/*case 'halloween-pelo':
				bfXOffset = 200;
				gfXOffset = 100;
				dadXOffset = 100;
			case 'snowbg':
				dadXOffset = 400;
				dadYOffset = 550;
				gfXOffset = 500;
				gfYOffset = 550;
				bfXOffset = 900;
				bfYOffset = 550;
			case 'factory':
				bfXOffset = 230;
				gfXOffset = 100;
			case 'school' | 'school-monika' | 'schoolnoon':
				bfXOffset = 200;
				bfYOffset = 220;
				gfXOffset = 180;
				gfYOffset = 300;
			case 'genocide':
				bfXOffset = 300;
				dadXOffset = -270;
			case 'trollgestage':
				bfXOffset = 75;
			case 'pokecenter':
				bfYOffset = -350;	
			case 'airplane1' | 'airplane2':
				gfXOffset = 450;
				gfYOffset = 100;
				bfXOffset = 350;
				bfYOffset = 40;
				dadXOffset = -150;
			case 'reactor' | 'reactor-m':
				gfXOffset = -100;
			case 'day':
				dadXOffset = -150;
				dadYOffset = -11;
				bfXOffset = 191;
				bfYOffset = -20;
				gfXOffset = -70;
				gfYOffset = -50;
			case 'garStage' | 'eddhouse2' | 'garStageRise' | 'garStageDead':
				bfXOffset = 100;
				dadXOffset = 100;			
			case 'glitcher':
				bfXOffset = 150;
				dadXOffset = -100;
			case 'room-space':
				bfXOffset = 330;
			case 'melonfarm': 
				bfXOffset = 180;
				bfYOffset = -50;
			case 'mallEvil' | 'mallAnnie':
				bfXOffset = 320;
			case 'hungryhippo' | 'hungryhippo-blantad':
				dadYOffset = 150;
				if (songLowercase == 'hunger')
				{
					bfXOffset = 100;
					bfYOffset = 210;
				}
			case 'demo':
				bfXOffset = 45;
				bfYOffset = -165;
				gfXOffset = 2000;
				dadXOffset = -60;
				dadYOffset = -175;
			case 'incident':
				bfXOffset = 200;
				bfYOffset = 20;
				gfXOffset = 320;
				gfYOffset = 50;
			case 'polus' | 'polus2':
				dadXOffset = -270;
				dadYOffset = -240;
				gfXOffset = -200;
				gfYOffset = -235;
				bfXOffset = -20;
				bfYOffset = -230;	
			case 'FMMstage':
				bfXOffset = 280;
				bfYOffset = 50;
				dadXOffset = -315;
				dadYOffset = 50;
				gfXOffset = -140;
				gfYOffset = -50;	
			case 'zardymaze':
				dadYOffset = 140;
				gfYOffset = 140;
				bfXOffset = 80;
				bfYOffset = 140;	
			case 'prologue':
				dadYOffset = 50;
				bfYOffset = 150;
			case 'mall' | 'mallSoft' | 'sofdeez':
				bfXOffset = 230;
			case 'emptystage2':
				bfXOffset = 100;
				dadXOffset = -100;
			case 'emptystage3':
				if (songLowercase == 'arch')
				{
					gfXOffset = -100;
					gfYOffset = -325;
					dadXOffset = -520;
					dadYOffset = -220;
					bfXOffset = 60;
					bfYOffset = -220;
				}
			case 'throne':
				bfXOffset = 100;
				dadXOffset = -180;
				gfXOffset = -107;
				gfYOffset = -23;
			case 'momiStage':
				bfXOffset = 160;
				bfYOffset = -100;
				gfXOffset = 60;
				gfYOffset = -118;
				dadXOffset = -33;
				dadYOffset = -82;
			case 'night' | 'night2':
				dadXOffset = -370;
				dadYOffset = 39;
				bfXOffset = 191;
				bfYOffset = -20;
				gfXOffset = 300;
				gfYOffset = -50;
			case 'mind' | 'mind2':
				bfXOffset = -200;
				bfYOffset = 270;
				dadXOffset = -120;
				dadYOffset = 220;
			case 'cg5stage':
				bfXOffset = 100;
				bfYOffset = 100;
				dadXOffset = -50;
				dadYOffset = 100;
			case 'sunkStage':
				dadYOffset = 100;
				bfYOffset = 100;
				gfYOffset = 100;
			case 'alleysoft': 
				gfYOffset = -50;
			case 'clubroomevil':
				dadXOffset = -84;
				dadYOffset = -240;
				bfXOffset = -84;
				bfYOffset = -240;
				gfYOffset = 1870;
			case 'acrimony':
				bfXOffset = 70;
				gfXOffset = 67;
				gfYOffset = 430;
				dadXOffset = -40;*/
		}
	}

	var yy:Float = 0.0;

	var cloudTimer:Float = 0;
	var cloudTimer2:Float = 0;
	var rotRateBl:Float;
	var bl_r:Float = 300;

	var cloneOne:FlxSprite;
	var cloneTwo:FlxSprite;

	function doClone(side:Int)
	{
		switch(side)
		{
			case 0:
				if (cloneOne.alpha == 1)
					return;
				cloneOne.x = PlayState.instance.dad.x - 20;
				cloneOne.y = PlayState.instance.dad.y + 140;
				cloneOne.alpha = 1;

				cloneOne.animation.play('clone');
				cloneOne.animation.finishCallback = function(pog:String) {cloneOne.alpha = 0;}
			case 1:
				if (cloneTwo.alpha == 1)
					return;
				cloneTwo.x = PlayState.instance.dad.x + 390;
				cloneTwo.y = PlayState.instance.dad.y + 140;
				cloneTwo.alpha = 1;

				cloneTwo.animation.play('clone');
				cloneTwo.animation.finishCallback = function(pog:String) {cloneTwo.alpha = 0;}
		}
	}


	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (curStage)
		{
			case 'philly' | 'phillyannie' | 'philly-wire':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
			case 'zardymaze':
				if (swagBacks['zardyBackground'].animation.finished){
					swagBacks['zardyBackground'].animation.play('Maze');
				}
			case 'ITB':
				var phillyCityLights = swagGroup['phillyCityLights'];
				var lightsTimer:Array<Int> = [200, 700];
				for (i in 0...phillyCityLights.members.length) {
					if (lightsTimer[i] == 0) {
						lightsTimer[i] = -1;
						FlxTween.tween(phillyCityLights.members[i], {alpha: 1}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadOut, 
							onComplete: function(tween:FlxTween)
							{
								FlxTween.tween(phillyCityLights.members[i], {alpha: 0}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadIn, 
									onComplete: function(tween:FlxTween)
									{
										var daRando = new FlxRandom();
										lightsTimer[i] = daRando.int(1000, 1500);
									}, 
								});
							}, 
						});
					} else
						lightsTimer[i]--;
				}	
			case 'reactor' | 'reactor-m':
				swagBacks['orb'].scale.x = FlxMath.lerp(0.7, swagBacks['orb'].scale.x, 0.90);
				swagBacks['orb'].scale.y = FlxMath.lerp(0.7, swagBacks['orb'].scale.y, 0.90);
				swagBacks['orb'].alpha = FlxMath.lerp(0.96, swagBacks['orb'].alpha, 0.90);
				swagBacks['ass2'].alpha = FlxMath.lerp(1, swagBacks['ass2'].alpha, 0.90);
			case 'airplane':
				updateGraph();
			case 'city-christmas': //i hope i did this right
				yy = yy + 0.25;
				swagBacks['snow'].y = Math.floor(yy);

				if (yy > 0)
					yy = -120;

				swagBacks['crtscreen'].y = swagBacks['crtscreen'].y + 3;

				if (swagBacks['crtscreen'].y > 12)
					swagBacks['crtscreen'].y = 0;
			case 'tank' | 'tank2':
				moveTank();
			case 'ballisticAlley':
				var health = PlayState.instance.health;
				if (health != 2)
				{
					funneEffect.alpha = health - 0.3;
					if (theFunneNumber < 0.7)
						theFunneNumber = 0.7;
					else if (theFunneNumber > 1.2)
						theFunneNumber = 1.2;
	
					if (theFunneNumber < 1)
						funneEffect.y = -300;
					else
						funneEffect.y = -200;
	
					funneEffect.setGraphicSize(Std.int(funneEffect.width * theFunneNumber));
				}	
			/*case 'limoholo-night':
			{
				if (songLowercase == 'hands')
				{
					var rotRateBl = (curStep / 9.5) * 1.2;
					var cloudGroup = swagGroup['cloudGroup'];
					var cloudGroup2 = swagGroup['cloudGroup2'];
					
					var bl_toy = -8500 + -Math.sin(rotRateBl * 2) * bl_r * 0.45;
					var bl_tox = 50 - Math.cos(rotRateBl) * bl_r;
	
					blantadBG.x += (bl_tox - blantadBG.x) / 12;
					blantadBG.y += (bl_toy - blantadBG.y) / 12;
	
					cloudTimer += elapsed * 10;
					if (cloudTimer > 1)
					{
						cloudTimer--;
						cloudGroup.add(cloudGroup.recycle(Cloud.new));
					}
	
					cloudTimer2 += elapsed * 2;
					if (cloudTimer2 > 1)
					{
						cloudTimer2--;
						cloudGroup2.add(cloudGroup2.recycle(Cloud2.new));
					}
				}	
			}*/
			/*case 'auditorHell':
			{
				if (PlayState.instance.dad.curCharacter != 'exTricky' && swagBacks['hole'].alpha != 0 && PlayState.isVitor)
				{
					swagBacks['hole'].alpha = 0;
					swagBacks['converHole'].alpha = 0;
					swagBacks['cover'].alpha = 0;
					cloneOne.visible = false;
					cloneTwo.visible = false;
				}
			
				if (PlayState.instance.dad.curCharacter == 'exTricky' && swagBacks['hole'].alpha != 1 && PlayState.isVitor)
				{
					swagBacks['hole'].alpha = 1;
					swagBacks['converHole'].alpha = 1;
					swagBacks['cover'].alpha = 1;
					cloneOne.visible = true;
					cloneTwo.visible = true;
				}
			}*/
		}

		if (isCustomStage && !preloading && luaArray.length >= 1)
		{
			callOnLuas('onUpdate', [elapsed]);

			if (PlayState.instance.songStarted)
			{
				setOnLuas("mustHitSection",PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);

				if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
					callOnLuas('playerOneTurn', []);
				else if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
					callOnLuas('playerTwoTurn', []);
			}

			callOnLuas('onUpdatePost', [elapsed]);
		}
	}

	var theFunneNumber:Float = 1;

	override function stepHit()
	{
		super.stepHit();

		var array = slowBacks[curStep];
		if (array != null && array.length > 0)
		{
			if (hideLastBG)
			{
				for (bg in swagBacks)
				{
					if (!array.contains(bg))
					{
						var tween = FlxTween.tween(bg, {alpha: 0}, tweenDuration, {
							onComplete: function(tween:FlxTween):Void
							{
								bg.visible = false;
							}
						});
					}
				}
				for (bg in array)
				{
					bg.visible = true;
					FlxTween.tween(bg, {alpha: 1}, tweenDuration);
				}
			}
			else
			{
				for (bg in array)
					bg.visible = !bg.visible;
			}
		}

		if (isCustomStage && luaArray.length >= 1)
		{
			setOnLuas('curStep',curStep);
			callOnLuas('onStepHit', [curStep]);
		}
			
		switch (songLowercase)
		{
			case "ghost-vip":
			{
				if (curStage == 'concert')
				{
					switch (curStep)
					{
						case 1264:
							crowd_front.alpha = 0;
							crowd_front2.alpha = 0;
							crowd_front3.alpha = 1;
							crowd_front4.alpha = 0;
						case 1328:
							crowd_front.alpha = 0;
							crowd_front2.alpha = 1;
							crowd_front3.alpha = 0;
							crowd_front4.alpha = 0;
						case 1392 | 4528:
							crowd_front.alpha = 1;
							crowd_front2.alpha = 0;
							crowd_front3.alpha = 0;
							crowd_front4.alpha = 0;
						case 4464:
							crowd_front.alpha = 0;
							crowd_front2.alpha = 0;
							crowd_front3.alpha = 0;
							crowd_front4.alpha = 1;

						case 3248:
							crowd_back.alpha = 0;
							crowd_back2.alpha = 1;
							crowd_back3.alpha = 0;
						case 3824:
							crowd_back.alpha = 0;
							crowd_back2.alpha = 0;
							crowd_back3.alpha = 1;
						case 3312 | 3888:
							crowd_back.alpha = 1;
							crowd_back2.alpha = 0;
							crowd_back3.alpha = 0;
					}
				}			
			}
			case 'four-way-fracture':
				if (curStage == 'trioStage-FWF' && vg != null)
				{
					if (curStep == 4208)
					{
						new FlxTimer().start(.0085, function(sex:FlxTimer)
						{
							if (vg != null && !(curStep >= 5264))
							{
								@:privateAccess
								if (!PlayState.instance.paused)
									vg.alpha += 0.005;
								if (vg.alpha < 0.75)
								{
									sex.reset();
								}

								if (vg.alpha > 0.75)
									vg.alpha = 0.75;

								if (vg.alpha == 0.75)
								{
									new FlxTimer().start(.0085, function(sex2:FlxTimer)
									{
										@:privateAccess
										if (!PlayState.instance.paused)
											vg.alpha -= 0.005;
										if (vg.alpha > 0)
										{
											sex2.reset();
										}

										if (vg.alpha < 0)
											vg.alpha = 0;

										if (vg.alpha == 0)
											sex.reset();
									});
								}
							}	
						});
					}

					if (curStep == 5264)
					{
						FlxTween.tween(vg, {alpha: 0}, 0.5, {
							onComplete: function(tween:FlxTween)
							{
								vg.destroy();
							},
						});
					}
				}
		}
	}

	// Variables and Functions for Stages
	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var walked:Bool = false;
	var walkingRight:Bool = true;
	var stopWalkTimer:Int = 0;
	var pastCurLight:Int = 1;
	var curLight2:Int = 0;
	public var stopBGDancing:Bool = false;
	var beatOfFuck:Int = 0;

	override function beatHit()
	{
		super.beatHit();

		if (animatedBacks.length > 0)
		{
			for (bg in animatedBacks)
			{
				if (!stopBGDancing)
					bg.animation.play('idle', true);
			}	
		}

		if (animatedBacks2.length > 0)
		{
			for (bg in animatedBacks2)
			{
				if (!stopBGDancing)
					bg.animation.play('idle');
			}		
		}

		if (isCustomStage && luaArray.length >= 1)
		{
			setOnLuas('curBeat',curBeat);
			callOnLuas('onBeatHit', [curBeat]);
		}
		
		switch (curStage)
		{
			case 'halloween':
				if (FlxG.random.bool(Conductor.bpm > 320 ? 100 : 10) && curBeat > lightningStrikeBeat + lightningOffset)
				{
					lightningStrikeShit();
					trace('spooky');
				}
			case 'limo':
				swagGroup['grpLimoDancers'].forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case 'school':
				swagBacks['bgGirls'].dance();
			case 'tank2' | 'tank':
				if (curBeat % 2 == 0)
				{	
					swagBacks['tankWatchtower'].animation.play('idle', true);
					swagBacks['tank0'].animation.play('idle', true);
					swagBacks['tank1'].animation.play('idle', true);
					swagBacks['tank2'].animation.play('idle', true);
					swagBacks['tank4'].animation.play('idle', true);
					swagBacks['tank5'].animation.play('idle', true);
					swagBacks['tank3'].animation.play('idle', true);
				}
			case "philly":
				if (!trainMoving) {
					trainCooldown += 1;
				}	
				if (curBeat % 8 == 4 && FlxG.random.bool(Conductor.bpm > 320 ? 150 : 30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
					trace('train');
				}
				
				if (curBeat % 4 == 0)
				{
					var phillyCityLights = swagGroup['phillyCityLights'];
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
				}
			/*case 'auditorHell':
				{
					if (PlayState.instance.dad.curCharacter == 'exTricky')
					{
						if (curBeat % 8 == 4 && beatOfFuck != curBeat)
						{
							beatOfFuck = curBeat;
							doClone(FlxG.random.int(0,1));
						}
					}
				}

			case 'philly-wire':
				swagBacks['gfBG'].dance();
				swagBacks['gfBG2'].dance();
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					var phillyCityLights = swagGroup['phillyCityLights'];
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;

					var wirephillyCityLights = swagGroup['wirephillyCityLights'];
					wirephillyCityLights.forEach(function(wirelight:FlxSprite)
					{
						wirelight.visible = false;
					});

					curLight2 = FlxG.random.int(0, wirephillyCityLights.length - 1);

					wirephillyCityLights.members[curLight2].visible = true;
				}
				*/
		
			/*case 'school-monika':
				if (songLowercase == 'shinkyoku')
				swagBacks['bgGirls2'].dance();
			case 'neopolis':
				if (songLowercase == 'roses-remix')
				{
					swagBacks['bgGirls'].dance();
					swagBacks['bfPixelBG'].animation.play('idle');
				}
			case 'arcade4':
				if (curBeat % 2 == 1)
					swagBacks['upperBoppers'].animation.play('bop', true);
				if (curBeat % 2 == 0)
					swagBacks['bottomBoppers'].animation.play('bop', true);
			case 'limoholo' | 'limoholo-night':
				swagGroup['grpLimoDancersHolo'].forEach(function(dancer:BackgroundDancerHolo)
				{
					dancer.dance();
				});
		
				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();

				if (curStage == 'limoholo-night' && songLowercase == 'hands')
					swagBacks['gfBG'].dance();
			case 'school-monika-finale':
				if (PlayState.SONG.player2 != 'monika-finale' && songLowercase != 'epiphany')
					swagBacks['monikaFinaleBG'].animation.play('idle');
			case 'mallSoft':
				swagBacks['gfBG'].dance();
				swagBacks['momDadBG'].animation.play('idle');
				swagBacks['softBFBG'].animation.play('idle');
			case 'pillars':
				swagBacks['speaker'].animation.play('bop');
			case 'kbStreet':
				if(curBeat >= 80 && curBeat <= 208) 
				{
					if (curBeat % 16 == 0)
					{
						swagBacks['qt_gas01'].animation.play('burst');
						swagBacks['qt_gas02'].animation.play('burst');
					}
				}
			case 'minigames':
				var bgs = swagGroup['bgs'];
				bgs.forEach(function(bg:FlxSprite)
				{
					bg.visible = false;
				});

				curLight++;
				if(curLight > 4) curLight = 0;

				bgs.members[curLight].visible = true;
			case 'reactor':
				if(curBeat % 4 == 0) 
				{
					swagBacks['amogus'].animation.play('idle', true);
					swagBacks['dripster'].animation.play('idle', true);
					swagBacks['yellow'].animation.play('idle', true);
					swagBacks['brown'].animation.play('idle', true);
					swagBacks['orb'].scale.set(0.75, 0.75);
					swagBacks['ass2'].alpha = 0.9;
					swagBacks['orb'].alpha = 1;
				}
			case 'reactor-m':
				if(curBeat % 4 == 0) 
				{
					swagBacks['fortnite1'].animation.play('idle', true);
					swagBacks['fortnite2'].animation.play('idle', true);
					swagBacks['orb'].scale.set(0.75, 0.75);
					swagBacks['ass2'].alpha = 0.9;
					swagBacks['orb'].alpha = 1;
				}
			case 'day':
				var mordecai = swagBacks['mordecai'];

				swagBacks['mini'].animation.play('idle', true);
				if (stopWalkTimer == 0) {
					if (walkingRight)
						mordecai.flipX = false;
					else
						mordecai.flipX = true;
					if (walked)
						mordecai.animation.play('walk1');
					else
						mordecai.animation.play('walk2');
					if (walkingRight)
						mordecai.x += 10;
					else
						mordecai.x -= 10;
					walked = !walked;
					if (mordecai.x == 480 && walkingRight) { 
						stopWalkTimer = 10;
						walkingRight = false;
					} else if (mordecai.x == -80 && !walkingRight) { 
						stopWalkTimer = 8;
						walkingRight = true;
					}
				} else 
					stopWalkTimer--;
			case 'dokiclubroom-monika' | 'dokiclubroom-sayori' | 'dokiclubroom-natsuki' | 'dokiclubroom-yuri':
				if (curBeat % 2 == 0)
				{
					if (!curStage.contains('monika'))
						swagBacks['monika'].animation.play('idle', true);

					if (!curStage.contains('sayori'))
						swagBacks['sayori'].animation.play('idle', true);

					if (!curStage.contains('natsuki'))
						swagBacks['natsuki'].animation.play('idle', true);

					if (!curStage.contains('yuri'))
						swagBacks['yuri'].animation.play('idle', true);
				}
			/*case 'skybroke' | 'manifest' | 'manifest-blantad':
			{
				if (FlxG.save.data.flashing && curBeat % PlayState.instance.gfSpeed == 0)
				{
					if (curStage == "manifest" || curStage == "manifest-blantad")
					{
						swagBacks['manifestBG'].animation.play("idle");
						swagBacks['manifestFloor'].animation.play("idle");
					}

					if (songLowercase == 'manifest' && PlayState.isBETADCIU)
						swagBacks['gfCrazyBG'].animation.play('idle');
	
					if(curStage == "skybroke")
					{
						swagBacks['manifestBG'].animation.play('idle');
						swagBacks['manifestHole'].animation.play('idle');
					}
				}			
			}
			case 'night':
				if (!PlayState.instance.dad.animation.curAnim.name.startsWith('sing'))
					swagBacks['pc'].animation.play('idle');
			case "concert":
				if (FlxG.save.data.distractions)
				{
					if (curBeat % 4 == 0)
					{
						var concertLights = swagGroup['concertLights'];
						concertLights.forEach(function(light:FlxSprite)
						{
							light.visible = false;
						});

						curLight = FlxG.random.int(0, concertLights.length - 1, [pastCurLight]);
						pastCurLight = curLight;

						concertLights.members[curLight].visible = true;
					}

					if (curBeat % 2 == 0)
					{
						speaker_left.animation.play("bop", true);
						speaker_right.animation.play("bop", true);
						swagBacks['speaker_left'].animation.play("bop", true);
						swagBacks['speaker_right'].animation.play("bop", true);

						// TODO: make the tweens better looking LMFAO

						FlxTween.tween(crowd_front, {
							"scale.x": 0.87,
							"scale.y": 0.92
						}, 0.05, {
							onComplete: function(flxTween:FlxTween)
							{
								FlxTween.tween(crowd_front, {
									"scale.x": 0.85,
									"scale.y": 0.85
								}, 0.125);
							}
						});

						FlxTween.tween(crowd_front2, {
							"scale.x": 0.87,
							"scale.y": 0.92
						}, 0.05, {
							onComplete: function(flxTween:FlxTween)
							{
								FlxTween.tween(crowd_front2, {
									"scale.x": 0.85,
									"scale.y": 0.85
								}, 0.125);
							}
						});

						FlxTween.tween(crowd_front3, {
							"scale.x": 0.87,
							"scale.y": 0.92
						}, 0.05, {
							onComplete: function(flxTween:FlxTween)
							{
								FlxTween.tween(crowd_front3, {
									"scale.x": 0.85,
									"scale.y": 0.85
								}, 0.125);
							}
						});

						FlxTween.tween(crowd_front4, {
							"scale.x": 0.87,
							"scale.y": 0.92
						}, 0.05, {
							onComplete: function(flxTween:FlxTween)
							{
								FlxTween.tween(crowd_front4, {
									"scale.x": 0.85,
									"scale.y": 0.85
								}, 0.125);
							}
						});

						FlxTween.tween(crowd_back, {
							"scale.x": 0.87,
							"scale.y": 0.92
						}, 0.05, {
							onComplete: function(flxTween:FlxTween)
							{
								FlxTween.tween(crowd_back, {
									"scale.x": 0.85,
									"scale.y": 0.85
								}, 0.125);
							}
						});

						FlxTween.tween(crowd_back2, {
							"scale.x": 0.87,
							"scale.y": 0.92
						}, 0.05, {
							onComplete: function(flxTween:FlxTween)
							{
								FlxTween.tween(crowd_back2, {
									"scale.x": 0.85,
									"scale.y": 0.85
								}, 0.125);
							}
						});

						FlxTween.tween(crowd_back3, {
							"scale.x": 0.87,
							"scale.y": 0.92
						}, 0.05, {
							onComplete: function(flxTween:FlxTween)
							{
								FlxTween.tween(crowd_back3, {
									"scale.x": 0.85,
									"scale.y": 0.85
								}, 0.125);
							}
						});

						if (addedAmogus)
						{
							FlxTween.tween(jabibi_amogus, {
								"scale.x": 0.87,
								"scale.y": 0.92
							}, 0.05, {
								onComplete: function(flxTween:FlxTween)
								{
									FlxTween.tween(jabibi_amogus, {
										"scale.x": 0.85,
										"scale.y": 0.85
									}, 0.125);
								}
							});
						}
					}
				}
			case 'acrimony':
				swagBacks['modCrowdBig'].animation.play('bop', true);*/
		}
	}

	var curLight:Int = 0;
	var danced:Bool = false;

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		swagBacks['halloweenBG'].animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (PlayState.instance.boyfriend.animOffsets.exists('scared')){
			PlayState.instance.boyfriend.playAnim('scared', true);
		}
		if (PlayState.instance.gf.animOffsets.exists('scared')){
		PlayState.instance.gf.playAnim('scared', true);
		}
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;
	var trainSound:FlxSound;

	function trainStart():Void
	{
		trainMoving = true;
		trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			PlayState.instance.gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			var phillyTrain = swagBacks['phillyTrain'];
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		PlayState.instance.gf.playAnim('hairFall');
		swagBacks['phillyTrain'].x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	public function resetFastCar():Void
	{
		var fastCar = swagBacks['fastCar'];
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		if (fastCar.frames != null)
		{
			fastCar.velocity.x = 0;
		}		
		fastCarCanDrive = true;
	}

	public function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		swagBacks['fastCar'].velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			if (curStage.contains('limo'))
				resetFastCar();		
		});
	}

	public var closeLuas:Array<StageModchartState> = [];
	public var luaArray:Array<StageModchartState> = [];

	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		
		var returnVal:Dynamic = StageModchartState.Function_Continue;

		#if windows
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != StageModchartState.Function_Continue) {
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length) {
			luaArray.remove(closeLuas[i]);
			closeLuas[i].die();
		}
		#end

		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if windows
		for (i in 0...luaArray.length) {
			luaArray[i].setVar(variable, arg);
		}
		#end
	}

	//airplane shenanigans
	public var graphMode:Int = 0;
	var graphMoveTimer:Int = -1;
	var graphMove:Float = 0;
	var neutralGraphPos:Float = 0;
	var graphBurstTimer:Int = 0;
	var graphPosition:Float;
	var shinyMode:Bool = false;
	var oldMode:Int = 0;

	public function updateGraph() 
	{
		var graphPointer = swagBacks['graphPointer'];
		var grpGraph = swagGroup['grpGraph'];

		graphPointer.y += graphMove;
		
		var theColor = FlxColor.ORANGE;

		if (shinyMode && graphMoveTimer == 1) {
			graphPointer.y += FlxG.random.float(4, 4.1, [0]);
			neutralGraphPos = graphPointer.y;
		}
		
		if (graphMoveTimer > 0) {
			graphMoveTimer--;
		} else if (graphMoveTimer == 0) {
			graphMove = 0;
			graphMoveTimer = -1;
			if (shinyMode) {
				shinyMode = false;
				graphMode = oldMode;
			}
		}
		switch (graphMode) {
			case 0:
				var a = FlxG.random.int(0, 150);
				
				if (graphBurstTimer > 0) {
					graphBurstTimer--;
				} else if (graphBurstTimer == 0) {
					graphBurstTimer = FlxG.random.int(90, 220);
					//graphBurstTimer = -1;
					if (graphMoveTimer <= 0) {
						graphMove = FlxG.random.float(-0.4, 0.4, [0]);
						graphMoveTimer = FlxG.random.int(8, 20);
					}
				}
				if (graphPointer.y < neutralGraphPos - 30)
					graphPointer.y = neutralGraphPos - 30;
				if (graphPointer.y > neutralGraphPos + 30)
					graphPointer.y = neutralGraphPos + 30;
				
			case 1:
				theColor = FlxColor.GREEN;
				var a = FlxG.random.int(0, 130);
				
				if (graphBurstTimer > 0) {
					graphBurstTimer--;
				} else if (graphBurstTimer == 0) {
					graphBurstTimer = FlxG.random.int(80, 180);
					//graphBurstTimer = -1;
					if (graphMoveTimer <= 0) {
						graphMove = FlxG.random.float(-0.6, 0.2, [0]);
						graphMoveTimer = FlxG.random.int(10, 20);
					}
				}
			case 2:
				theColor = FlxColor.RED;
				var a = FlxG.random.int(0, 130);

				if (graphBurstTimer > 0) {
					graphBurstTimer--;
				} else if (graphBurstTimer == 0) {
					graphBurstTimer = FlxG.random.int(80, 180);
					//graphBurstTimer = -1;
					if (graphMoveTimer <= 0) {
						graphMove = FlxG.random.float(-0.2, 0.5, [0]);
						graphMoveTimer = FlxG.random.int(10, 20);
					}
				}
		}

		if (graphPointer.y < -1)
			graphPointer.y = -1;
		if (graphPointer.y > 225)
			graphPointer.y = 225;
			
		var thePoint = new FlxSprite(graphPointer.x, graphPointer.y).makeGraphic(4, 4, theColor);
		swagBacks['thePoint'] = thePoint;
		grpGraph.add(thePoint);

		graphPosition = swagBacks['thePoint'].y;

		if (grpGraph.length > 0) {
			swagGroup['grpGraph'].forEach(function(spr:FlxSprite)
			{
				spr.x -= 0.5;
				if (spr.x < 676.15)
					grpGraph.remove(spr);
			}); 
		}
		if (FlxG.keys.justPressed.I) {
			switchGraphMode(0);
		}
		if (FlxG.keys.justPressed.O) {
			switchGraphMode(1);
		}
		if (FlxG.keys.justPressed.P) {
			switchGraphMode(2);
		}
	}
	function switchGraphMode(mode:Int) 
	{
		var grpGraphIndicators = swagBacks['grpGraphIndicators'];
		var graphPointer = swagBacks['graphPointer'];

		swagGroup['grpGraphIndicators'].forEach(function(spr:FlxSprite)
		{
			spr.visible = false;
		}); 

		grpGraphIndicators.members[mode].visible = true;
		graphMode = mode;
		switch (mode) {
			case 0:
				neutralGraphPos = graphPointer.y;
		}
	}
	public function zoomingFunctionThing(?camSpeed:Float = 0.55, ?camZoomMult:Float = 1)
	{
		if ((curStage.toLowerCase() == "concert") || PlayState.instance.executeModchart)
		{
			trace("Zooming thing");
			concertZoom = !concertZoom;

			//zooms need to be set otherwise they'll just revert back to the default ones on the next beat
			if (concertZoom)
			{
				FlxTween.tween(PlayState.instance.camGame, {zoom: zoomLevel * camZoomMult}, camSpeed, {ease: easeThing, onComplete: function(twn:FlxTween)
					{
						PlayState.instance.defaultCamZoom = zoomLevel * camZoomMult;
					} 
				});
				FlxTween.tween(PlayState.instance.camHUD, {zoom: 0.73 * camZoomMult}, camSpeed, {ease: easeThing, onComplete: function(twn:FlxTween)
					{
						PlayState.instance.camHUD.zoom = 0.73 * camZoomMult;
					} 
				});
				FlxTween.tween(crowd_front, {y: -625 / camZoomMult}, camSpeed, {ease: easeThing});
				FlxTween.tween(crowd_front2, {y: -625 / camZoomMult}, camSpeed, {ease: easeThing});
				FlxTween.tween(crowd_front3, {y: -625 / camZoomMult}, camSpeed, {ease: easeThing});
				FlxTween.tween(crowd_front4, {y: -625 / camZoomMult}, camSpeed, {ease: easeThing});
				if (addedAmogus)
					FlxTween.tween(jabibi_amogus, {y: -625 / camZoomMult}, camSpeed, {ease: easeThing});
			}
			else
			{
				FlxTween.tween(PlayState.instance.camGame, {zoom: 0.59}, camSpeed, {ease: easeThing, onComplete: function(twn:FlxTween)
					{
						PlayState.instance.defaultCamZoom = 0.59;
					}
				});
				FlxTween.tween(PlayState.instance.camHUD, {zoom: 1}, camSpeed, {ease: easeThing, onComplete: function(twn:FlxTween)
					{
						PlayState.instance.camHUD.zoom = 1;
					} 
				});
				FlxTween.tween(crowd_front, {y: -225}, camSpeed, {ease: easeThing});
				FlxTween.tween(crowd_front2, {y: -225}, camSpeed, {ease: easeThing});
				FlxTween.tween(crowd_front3, {y: -225}, camSpeed, {ease: easeThing});
				FlxTween.tween(crowd_front4, {y: -225}, camSpeed, {ease: easeThing});
				if (addedAmogus)
					FlxTween.tween(jabibi_amogus, {y: -225}, camSpeed, {ease: easeThing});
			}
		}
	}
	public function moveTank()
	{
		if(!PlayState.instance.inCutscene)
		{
			tankAngle += FlxG.elapsed * tankSpeed;
			tankRolling.angle = tankAngle - 90 + 15;
			tankRolling.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankRolling.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	var redtween:FlxTween;
	var greentween:FlxTween;
	var bluetween:FlxTween;
	var purpletween:FlxTween;

	var redscale:FlxTween;
	var greenscale:FlxTween;
	var bluescale:FlxTween;
	var purplescale:FlxTween;

	var redtween2:FlxTween;
	var greentween2:FlxTween;
	var bluetween2:FlxTween;
	var purpletween2:FlxTween;

	var redscale2:FlxTween;
	var greenscale2:FlxTween;
	var bluescale2:FlxTween;
	var purplescale2:FlxTween;

	public function existsInCTA(key:String)
	{
		var daThing:Dynamic;

		if (!Paths.currentTrackedAssets.exists(key))
			Paths.cacheImage(key);

		daThing = Paths.currentTrackedAssets.get(key);

		return daThing;
	}

	public function existsInCTAAnimated(key:String)
	{
		var daThing:Dynamic;

		if (!Paths.currentTrackedAssets.exists(key))
			Paths.cacheImage(key);

		daThing = FlxAtlasFrames.fromSparrow(Paths.currentTrackedAssets.get(key), Assets.getText(Paths.xmlNew('images/'+key)));

		return daThing;
	}

	public function setScrollFactor(name:String, x:Float = 1, y:Float = 1)
	{
		if (swagBacks.exists(name))
		{
			var shit = swagBacks.get(name);

			shit.scrollFactor.set(x, y);
		}
	}

	public function setGraphicSize(name:String, val:Float = 1, ?val2:Float = 1)
	{
		//because this is different apparently

		if (swagBacks.exists(name))
		{
			var shit = swagBacks.get(name);

			shit.setGraphicSize(Std.int(shit.width * val));
			shit.updateHitbox(); 
		}
	}

	public function getProperty(variable:String)
	{
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = null;

			coverMeInPiss = swagBacks.get(killMe[0]);

			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
		}
		return Reflect.getProperty(Stage.instance, swagBacks.get(variable));
	}

	public function setProperty(variable:String, value:Dynamic)
	{
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = null;

			coverMeInPiss = swagBacks.get(killMe[0]);

			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
		}
		return Reflect.setProperty(Stage.instance, swagBacks.get(variable), value);
	}

	public function setObjectCamera(name:String, cam:String)// doesn't work when using lua so I'm just making it call a function instead
	{
		if (swagBacks.exists(name))
		{
			var shit = swagBacks.get(name);
			trace('activate');

			if (!preloading)
			{
				switch (cam.toLowerCase())
				{
					case 'camhud' | 'hud': shit.cameras = [PlayState.instance.camHUD];
					case 'camother' | 'other': shit.cameras = [PlayState.instance.camOther];
					default: shit.cameras = [PlayState.instance.camGame];
				}
			}		
			trace('done!');
		}
	}	

	//i don't like the code for the overlay taking up 300 LINES!!!
	var cgOpponentOverlays:Array<FlxSprite> = [];
	var cgOpponentScales:Array<FlxTween> = [];
	var cgOpponentTweens:Array<FlxTween> = [];
	var cgPlayerOverlays:Array<FlxSprite> = [];
	var cgPlayerScales:Array<FlxTween> = [];
	var cgPlayerTweens:Array<FlxTween> = [];
		
	public function noteHit(?isPlayer:Bool = false, ?i:Int, ?noteData:Int, ?isSustain:Bool = false, ?noteType:String, ?dType:Int)
	{
		if (isCustomStage && luaArray.length >= 1)
		{
			if (isPlayer)
				callOnLuas('goodNoteHit', [i, noteData, noteType, isSustain, dType]);
			else
				callOnLuas('opponentNoteHit', [i, noteData, noteType, isSustain, dType]);
		}
			
		switch (curStage)
		{
			/*case 'churchgospel':
			{
				var spin:Int = FlxG.random.int(1, 3);
				circ1new.angle += (isPlayer ? -spin : spin);
			}
			case 'cgstage':
			{
				if (isPlayer)
				{
					if (!isSustain)
					{
						cgPlayerOverlays[noteData].scale.set(0.81, 0.81);
						for (i in 0...4)
						{
							if (cgPlayerScales[i] != null)
								cgPlayerScales[i].cancel();

							if (cgPlayerTweens[i] != null)
								cgPlayerTweens[i].cancel();
							
							cgPlayerOverlays[i].alpha = 0;
						}

						cgPlayerOverlays[noteData].alpha = 1;

						if (cgPlayerOverlays != [])
						{
							new FlxTimer().start(0.1, function(tmr:FlxTimer)
							{
								cgPlayerScales[noteData] = FlxTween.tween(cgPlayerOverlays[noteData], {"scale.x": 1,"scale.y": 1}, 0.8, {ease: FlxEase.cubeOut});
								cgPlayerTweens[noteData] = FlxTween.tween(cgPlayerOverlays[noteData], {alpha: 0}, 4, {ease: FlxEase.cubeOut});
							});
						}
					}
				}
				else
				{
					if (!isSustain)
					{
						cgOpponentOverlays[noteData].scale.set(0.81, 0.81);
						for (i in 0...4)
						{
							if (cgOpponentScales[i] != null)
								cgOpponentScales[i].cancel();

							if (cgOpponentTweens[i] != null)
								cgOpponentTweens[i].cancel();
							
							cgOpponentOverlays[i].alpha = 0;
						}

						cgOpponentOverlays[noteData].alpha = 1;

						if (cgOpponentOverlays != [])
						{
							new FlxTimer().start(0.1, function(tmr:FlxTimer)
							{
								cgOpponentScales[noteData] = FlxTween.tween(cgOpponentOverlays[noteData], {"scale.x": 1,"scale.y": 1}, 0.8, {ease: FlxEase.cubeOut});
								cgOpponentTweens[noteData] = FlxTween.tween(cgOpponentOverlays[noteData], {alpha: 0}, 4, {ease: FlxEase.cubeOut});
							});
						}	
					}
				}
			}*/
		}
	}
}