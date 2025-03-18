package objects;

import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.animation.FlxBaseAnimation;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxTiledSprite;
import flixel.math.FlxRandom;
import flixel.FlxObject;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import flixel.text.FlxText;
import flixel.effects.particles.FlxEmitter; //never have i ever used this until now.
import flixel.effects.particles.FlxParticle;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import openfl.Lib;
import lime.utils.Assets;

import flixel.math.FlxPoint;

import shaders.Shaders;
import backend.StageData;
import luafiles.ModchartState;

import objects.BackgroundDancer;
import objects.BackgroundGirls;

import shaders.RainShader;
import objects.ABotSpeaker;

using StringTools;

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
	public var hasFilter:Bool = false;

	var tankRolling:FlxSprite;
	var tankX:Int = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.float(-90, 45);

	//Philly Streets Stuff

	//var scrollingSky:FlxTiledSprite;
	var rainShader:RainShader;
	var rainFilter:Bool = false;
	//var rainShaderStartIntensity:Float = 0.1; // you can change the rain Intensity example: "setProperty("Stage.rainShaderStartIntensity", 0.4)"
	//var rainShaderEndIntensity:Float = 0.2;
	var _timer:Float = 0;
	var lightsStop:Bool = false;
	var lastChange:Int = 0;
	var changeInterval:Int = 8;
	var carWaiting:Bool = false;
	var carInterruptable:Bool = true;
	var car2Interruptable:Bool = true;
	
	public var altSuffix:String = '';
	public var altPrefix:String = '';
	public var pixelShitPart1:String = '';
	public var pixelShitPart2:String = '';
	public var songLowercase:String = '';
	public var introAssets:Array<String> = ['ready', 'set', 'go'];
	public var preloading:Bool = false;
	public var isCustomStage:Bool = false;
	public var isLuaStage:Bool = false;

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
		hasFilter = false;
		songLowercase = PlayState.SONG.song.toLowerCase();

		instance = this;

		if (!preloading) //clears the filters
		{
			if (PlayState.instance.camGameShaders.length > 0)
			{
				PlayState.instance.clearShaderFromCamera('hud');
				PlayState.instance.clearShaderFromCamera('game');
				PlayState.instance.clearShaderFromCamera('other');
			}
		}

		switch (daStage)
		{
			case 'halloween':
			{	
				var halloweenBG = new FlxSprite(-200, -80);
				switch (daStage)
				{
					case 'halloween':
						halloweenBG.frames = Paths.getSparrowAtlas('halloween_bg', 'week2');
				}
				
				halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
				halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
				halloweenBG.animation.play('idle');
				halloweenBG.antialiasing = true;
				swagBacks['halloweenBG'] = halloweenBG;
				toAdd.push(halloweenBG);
			}
			case 'philly':
			{
				switch (daStage)
				{
					case 'philly': pre = 'philly';
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

			case 'mall':
			{
				camZoom = 0.80;

				pre = 'christmas';
				suf = 'week5';

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

			case 'mallEvil':
			{
				pre = 'christmas';
				suf = 'week5';

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

			case 'school':
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
				bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
				bgGirls.updateHitbox();
				swagBacks['bgGirls'] = bgGirls;
				toAdd.push(bgGirls);

				introAssets = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];

				pixelShitPart1 = 'weeb/pixelUI/';
				pixelShitPart2 = '-pixel';	

				bfXOffset = 140;
				bfYOffset = 50;
				dadXOffset = 110;
				dadYOffset = 50;
			}

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

				bfXOffset = 140;
				bfYOffset = 50;
				dadXOffset = 110;
				dadYOffset = 50;
			}

			case 'tank':
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

			case 'phillyStreets' | 'phillyStreetsErect':
			{
				camZoom = 0.77;

				switch (daStage)
				{
					case 'phillyStreets':
						pre = 'phillyStreets';
					case 'phillyStreetsErect':
						pre = 'phillyStreets/erect';
				}

				suf = 'weekend1';
				
				var skyImage = Paths.image(pre+'/phillySkybox', suf);

				//var scrollingSky = new FlxTiledSprite(skyImage, skyImage.width + 400, skyImage.height, true, false); //this FlxTiledSprite don't fucking work

				var scrollingSky = new FlxBackdrop(skyImage, X, 0, 0);
				scrollingSky.antialiasing = ClientPrefs.data.antialiasing;
				scrollingSky.setPosition(-650, -375);
				scrollingSky.scrollFactor.set(0.1, 0.1);
				scrollingSky.scale.set(0.65, 0.65);
				swagBacks['scrollingSky'] = scrollingSky;
				toAdd.push(scrollingSky);

				var phillySkyline = new FlxSprite(-545, -273).loadGraphic(Paths.image(pre+'/phillySkyline', suf));
				phillySkyline.scrollFactor.set(0.2, 0.2);
				swagBacks['phillySkyline'] = phillySkyline;
				toAdd.push(phillySkyline);

				var phillyForegroundCity = new FlxSprite(625, 94).loadGraphic(Paths.image(pre+'/phillyForegroundCity', suf));
				phillyForegroundCity.scrollFactor.set(0.3, 0.3);
				swagBacks['phillyForegroundCity'] = phillyForegroundCity;
				toAdd.push(phillyForegroundCity);

				if (curStage == 'phillyStreetsErect'){
					var mist5 = new FlxBackdrop(Paths.image(pre+'/mistMid', suf), X);
					mist5.setPosition(-650, -100);
					mist5.scrollFactor.set(0.5, 0.5);
					mist5.blend = "add";
					mist5.color = 0xFF5c5c5c;
					mist5.alpha = 1;
					mist5.velocity.x = 20;
					mist5.scale.set(1.1, 1.1);
					swagBacks['mist5'] = mist5;
					toAdd.push(mist5);
				}

				var phillyConstruction = new FlxSprite(1800, 364).loadGraphic(Paths.image(pre+'/phillyConstruction', suf));
				phillyConstruction.scrollFactor.set(0.7, 1);
				swagBacks['phillyConstruction'] = phillyConstruction;
				toAdd.push(phillyConstruction);

				var phillyHighwayLights = new FlxSprite(284, 305).loadGraphic(Paths.image(pre+'/phillyHighwayLights', suf));
				phillyHighwayLights.scrollFactor.set(1, 1);
				swagBacks['phillyHighwayLights'] = phillyHighwayLights;
				toAdd.push(phillyHighwayLights);
				
				var phillyHighwayLightsLightmap = new FlxSprite(284, 305).loadGraphic(Paths.image('phillyStreets/phillyHighwayLights_lightmap', suf));
				phillyHighwayLightsLightmap.scrollFactor.set(1, 1);
				phillyHighwayLightsLightmap.blend = "add";
				phillyHighwayLightsLightmap.alpha = 0.6;
				swagBacks['phillyHighwayLightsLightmap'] = phillyHighwayLightsLightmap;
				toAdd.push(phillyHighwayLightsLightmap);

				var phillyHighway = new FlxSprite(139, 209).loadGraphic(Paths.image(pre+'/phillyHighway', suf));
				phillyHighway.scrollFactor.set(1, 1);
				swagBacks['phillyHighway'] = phillyHighway;
				toAdd.push(phillyHighway);

				var phillySmog = new FlxSprite(-6, 245).loadGraphic(Paths.image(pre+'/phillySmog', suf));
				phillySmog.scrollFactor.set(0.8, 1);
				swagBacks['phillySmog'] = phillySmog;
				toAdd.push(phillySmog);

				var phillyCars = new FlxSprite(1200, 818);
				phillyCars.frames = Paths.getSparrowAtlas(pre+'/phillyCars', suf);
				phillyCars.scrollFactor.set(0.9, 1);
				phillyCars.animation.addByPrefix('car1', 'car1', 24, false);
				phillyCars.animation.addByPrefix('car2', 'car2', 24, false);
				phillyCars.animation.addByPrefix('car3', 'car3', 24, false);
				phillyCars.animation.addByPrefix('car4', 'car4', 24, false);
				swagBacks['phillyCars'] = phillyCars;
				toAdd.push(phillyCars);

				var phillyCars2 = new FlxSprite(1200, 818);
				phillyCars2.frames = Paths.getSparrowAtlas(pre+'/phillyCars', suf);
				phillyCars2.scrollFactor.set(0.9, 1);
				phillyCars2.animation.addByPrefix('car1', 'car1', 24, false);
				phillyCars2.animation.addByPrefix('car2', 'car2', 24, false);
				phillyCars2.animation.addByPrefix('car3', 'car3', 24, false);
				phillyCars2.animation.addByPrefix('car4', 'car4', 24, false);
				phillyCars2.flipX = true;
				swagBacks['phillyCars2'] = phillyCars2;
				toAdd.push(phillyCars2);

				var phillyTraffic = new FlxSprite(1840, 608);
				phillyTraffic.frames = Paths.getSparrowAtlas(pre+'/phillyTraffic', suf);
				phillyTraffic.scrollFactor.set(0.9, 1);
				phillyTraffic.animation.addByPrefix('redtogreen', 'redtogreen', 24, false);
				phillyTraffic.animation.addByPrefix('greentored', 'greentored', 24, false);
				swagBacks['phillyTraffic'] = phillyTraffic;
				toAdd.push(phillyTraffic);

				var phillyTrafficLightmap = new FlxSprite(1840, 608).loadGraphic(Paths.image(pre+'/phillyTraffic_lightmap', suf));
				phillyTrafficLightmap.scrollFactor.set(0.9, 1);
				phillyTrafficLightmap.blend = "add";
				phillyTrafficLightmap.alpha = 0.6;
				swagBacks['phillyTrafficLightmap'] = phillyTrafficLightmap;
				toAdd.push(phillyTrafficLightmap);

				if (curStage == 'phillyStreetsErect'){
					var mist3 = new FlxBackdrop(Paths.image(pre+'/mistMid', suf), X, 0, 0);
					mist3.setPosition(-650, -100);
					mist3.scrollFactor.set(0.95, 0.95);
					mist3.blend = "add";
					mist3.color = 0xFF5c5c5c;
					mist3.alpha = 0.5;
					mist3.velocity.x = -50;
					mist3.scale.set(0.8, 0.8);
					swagBacks['mist3'] = mist3;
					toAdd.push(mist3);

					var mist4 = new FlxBackdrop(Paths.image(pre+'/mistBack', suf), X, 0, 0);
					mist4.setPosition(-650, -100);
					mist4.scrollFactor.set(0.8, 0.8);
					mist4.blend = "add";
					mist4.color = 0xFF5c5c5c;
					mist4.alpha = 1;
					mist4.velocity.x = 40;
					mist4.scale.set(0.7, 0.7);
					swagBacks['mist4'] = mist4;
					toAdd.push(mist4);

					var gray1 = new FlxSprite(88, 317).loadGraphic(Paths.image(pre+'/greyGradient', suf));
					gray1.scrollFactor.set(1, 1);
					gray1.alpha = 0.3;
					gray1.blend = "add";
					swagBacks['gray1'] = gray1;
					toAdd.push(gray1);
		
					var gray2 = new FlxSprite(88, 317).loadGraphic(Paths.image(pre+'/greyGradient', suf));
					gray2.scrollFactor.set(1, 1);
					gray2.alpha = 0.8;
					gray2.blend = "multiply";
					swagBacks['gray2'] = gray2;
					toAdd.push(gray2);
				}

				var phillyForeground = new FlxSprite(88, 317).loadGraphic(Paths.image(pre+'/phillyForeground', suf));
				phillyForeground.scrollFactor.set(1, 1);
				swagBacks['phillyForeground'] = phillyForeground;
				toAdd.push(phillyForeground);

				var spraycanPile = new FlxSprite(920, 1045).loadGraphic(Paths.image('SpraycanPile', suf));
				spraycanPile.scrollFactor.set(1, 1);
				swagBacks['spraycanPile'] = spraycanPile;
				toAdd.push(spraycanPile);

				if (curStage == 'phillyStreetsErect'){
					var mist0 = new FlxBackdrop(Paths.image(pre+'/mistMid', suf), X, 0, 0);
					mist0.setPosition(-650, -100);
					mist0.scrollFactor.set(1.2, 1.2);
					mist0.blend = "add";
					mist0.color = 0xFF5c5c5c;
					mist0.alpha = 0.6;
					mist0.velocity.x = 172;
					layInFront[2].push(mist0);
					swagBacks['mist0'] = mist0;

					var mist1 = new FlxBackdrop(Paths.image(pre+'/mistMid', suf), X, 0, 0);
					mist1.setPosition(-650, -100);
					mist1.scrollFactor.set(1.1, 1.1);
					mist1.blend = "add";
					mist1.color = 0xFF5c5c5c;
					mist1.alpha = 0.6;
					mist1.velocity.x = 150;
					layInFront[2].push(mist1);
					swagBacks['mist1'] = mist1;
				
					var mist2 = new FlxBackdrop(Paths.image(pre+'/mistBack', suf), X, 0, 0);
					mist2.setPosition(-650, -100);
					mist2.scrollFactor.set(1.2, 1.2);
					mist2.blend = "add";
					mist2.color = 0xFF5c5c5c;
					mist2.alpha = 0.8;
					mist2.velocity.x = -80;
					layInFront[2].push(mist2);
					swagBacks['mist2'] = mist2;
				}

				//if (ClientPrefs.data.shaders) setupRainShader();

				bfXOffset = 1160;
				bfYOffset = 350;
				gfXOffset = 775;
				gfYOffset = 270;
				dadXOffset = 550;
				dadYOffset = 330;

				boyfriendCameraOffset = [-90, 0]; 
				opponentCameraOffset = [55, -50];
			}
			default:
			{
				//lua stages boi
				isCustomStage = true;
				trace('using a custom stage');

				if(!FileSystem.exists(Paths.getPreloadPath('stages/' + curStage + '.json')) && !FileSystem.exists(Paths.modFolders('stages/' + curStage + '.json')) && !Assets.exists(Paths.modFolders('stages/' + curStage + '.json')))
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
				opponentCameraOffset = stageData.camera_opponent;				
				girlfriendCameraOffset = stageData.camera_girlfriend;

				if(boyfriendCameraOffset == null){
					boyfriendCameraOffset = [0, 0];
				} 

				if(opponentCameraOffset == null){
					opponentCameraOffset = [0, 0];
				} 

				if(girlfriendCameraOffset == null){
					girlfriendCameraOffset = [0, 0];
				} 

				hideGirlfriend = stageData.hide_girlfriend;

				if (stageData.ratingSkin != null)
				{
					pixelShitPart1 = stageData.ratingSkin[0];
					pixelShitPart2 = stageData.ratingSkin[1];
				}
				
				if (stageData.countdownAssets != null){
					introAssets = stageData.countdownAssets;
				}
				
				luaArray.push(new ModchartState(curStage, preloading, true));

				if (luaArray.length >= 1){
					isLuaStage = true;
					callOnLuas('onCreate', []);	
				}
			}
		}
	}

	/*/
	function setupRainShader()
	{
		rainShader = new RainShader();
		rainShader.scale = FlxG.height / 200;

		rainShader.intensity = rainShaderStartIntensity;

		if (curStage == 'phillyStreetsErect'){
			rainShader.rainColor = 0xFFa8adb5;
		}
		
		PlayState.instance.camGame.setFilters([new ShaderFilter(rainShader)]);
	}
	/*/

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
			case 'tank':
				moveTank();
			case 'phillyStreets' | 'phillyStreetsErect': 
				swagBacks['scrollingSky'].x -= elapsed * 22;

				/*/
				var remappedIntensityValue:Float = FlxMath.remapToRange(Conductor.songPosition, 0, (FlxG.sound.music != null ? FlxG.sound.music.length : 0),
				rainShaderStartIntensity, rainShaderEndIntensity);
				rainShader.intensity = remappedIntensityValue;
				rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
				rainShader.update(elapsed);
				/*/
		}

		if (isCustomStage && !preloading && isLuaStage)
			callOnLuas('onUpdate', [elapsed]);
	}

	override function stepHit()
	{
		super.stepHit();

		//uncomment if you need it or smthn. I have NEVER used this.

		/*var array = slowBacks[curStep];
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
		}*/
	}

	// Variables and Functions for Stages
	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	public var stopBGDancing:Bool = false;

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
		
		switch (curStage)
		{
			case 'halloween':
				if (FlxG.random.bool(Conductor.bpm > 320 ? 100 : 10) && curBeat > lightningStrikeBeat + lightningOffset)
				{
					lightningStrikeShit();
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
			case 'tank':
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
			case "phillyStreets" | "phillyStreetsErect":
				if (FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && carInterruptable == true)
					{
						if(lightsStop == false)
							driveCar(swagBacks['phillyCars']);
						else
							driveCarLights(swagBacks['phillyCars']);
					}
			
					if(FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && car2Interruptable == true && lightsStop == false)
						driveCarBack(swagBacks['phillyCars2']);
			
					if (curBeat == (lastChange + changeInterval)) changeLights(curBeat);
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

		if (PlayState.instance.boyfriend.animOffsets.exists('scared') && PlayState.instance.boyfriend != null){
			PlayState.instance.boyfriend.playAnim('scared', true);
		}
		if (PlayState.instance.gf.animOffsets.exists('scared') && PlayState.instance.gf != null){
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
		if (fastCar != null)
		{
			fastCar.x = -12600;
			fastCar.y = FlxG.random.int(140, 250);
			if (fastCar.frames != null){
				fastCar.velocity.x = 0;
			}		
		}
		fastCarCanDrive = true;
	}

	public function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		var fastCar = swagBacks['fastCar'];

		if (fastCar != null)
		{
			fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
			fastCarCanDrive = false;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				if (curStage.contains('limo'))
					resetFastCar();		
			});
		}
	}

	// Cars from phillyStreets Stuff

	function changeLights(beat:Int):Void
		{
			lastChange = beat;
			lightsStop = !lightsStop;
	
			if(lightsStop)
			{
				swagBacks['phillyTraffic'].animation.play('greentored');
				changeInterval = 20;
			}
			else
			{
				swagBacks['phillyTraffic'].animation.play('redtogreen');
				changeInterval = 30;
	
				if(carWaiting == true) finishCarLights(swagBacks['phillyCars']);
			}
		}
	
		function finishCarLights(sprite:FlxSprite):Void
		{
			carWaiting = false;
			var duration:Float = FlxG.random.float(1.8, 3);
			var rotations:Array<Int> = [-5, 18];
			var offset:Array<Float> = [306.6, 168.3];
			var startdelay:Float = FlxG.random.float(0.2, 1.2);
	
			var path:Array<FlxPoint> = [
				FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15),
				FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
				FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
			];
	
			FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.sineIn, startDelay: startdelay});
			FlxTween.quadPath(sprite, path, duration, true, {ease: FlxEase.sineIn, startDelay: startdelay, onComplete: function(_) carInterruptable = true});
		}
	
		function driveCarLights(sprite:FlxSprite):Void
		{
			carInterruptable = false;
			FlxTween.cancelTweensOf(sprite);
			var variant:Int = FlxG.random.int(1,4);
			sprite.animation.play('car' + variant);
			var extraOffset = [0, 0];
			var duration:Float = 2;
	
			switch(variant)
			{
				case 1:
					duration = FlxG.random.float(1, 1.7);
				case 2:
					extraOffset = [20, -15];
					duration = FlxG.random.float(0.9, 1.5);
				case 3:
					extraOffset = [30, 50];
					duration = FlxG.random.float(1.5, 2.5);
				case 4:
					extraOffset = [10, 60];
					duration = FlxG.random.float(1.5, 2.5);
			}
			var rotations:Array<Int> = [-7, -5];
			var offset:Array<Float> = [306.6, 168.3];
			sprite.offset.set(extraOffset[0], extraOffset[1]);
	
			var path:Array<FlxPoint> = [
				FlxPoint.get(1500 - offset[0] - 20, 1049 - offset[1] - 20),
				FlxPoint.get(1770 - offset[0] - 80, 994 - offset[1] + 10),
				FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15)
			];
	
			FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.cubeOut} );
			FlxTween.quadPath(sprite, path, duration, true, {ease: FlxEase.cubeOut, onComplete: function(_)
			{
				carWaiting = true;
				if(lightsStop == false) finishCarLights(swagBacks['phillyCars']);
			}});
		}
		
		function driveCar(sprite:FlxSprite):Void
		{
			carInterruptable = false;
			FlxTween.cancelTweensOf(sprite);
			var variant:Int = FlxG.random.int(1,4);
			sprite.animation.play('car' + variant);
	
			var extraOffset = [0, 0];
			var duration:Float = 2;
			switch(variant)
			{
				case 1:
					duration = FlxG.random.float(1, 1.7);
				case 2:
					extraOffset = [20, -15];
					duration = FlxG.random.float(0.6, 1.2);
				case 3:
					extraOffset = [30, 50];
					duration = FlxG.random.float(1.5, 2.5);
				case 4:
					extraOffset = [10, 60];
					duration = FlxG.random.float(1.5, 2.5);
			}
	
			var offset:Array<Float> = [306.6, 168.3];
			sprite.offset.set(extraOffset[0], extraOffset[1]);
	
			var rotations:Array<Int> = [-8, 18];
			var path:Array<FlxPoint> = [
					FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 30),
					FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
					FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
			];
	
			FlxTween.angle(sprite, rotations[0], rotations[1], duration);
			FlxTween.quadPath(sprite, path, duration, true, {onComplete: function(_) carInterruptable = true});
		}
	
		function driveCarBack(sprite:FlxSprite):Void
		{
			car2Interruptable = false;
			FlxTween.cancelTweensOf(sprite);
			var variant:Int = FlxG.random.int(1,4);
			sprite.animation.play('car' + variant);
	
			var extraOffset = [0, 0];
			var duration:Float = 2;
			switch(variant)
			{
				case 1:
					duration = FlxG.random.float(1, 1.7);
				case 2:
					extraOffset = [20, -15];
					duration = FlxG.random.float(0.6, 1.2);
				case 3:
					extraOffset = [30, 50];
					duration = FlxG.random.float(1.5, 2.5);
				case 4:
					extraOffset = [10, 60];
					duration = FlxG.random.float(1.5, 2.5);
			}
	
			var offset:Array<Float> = [306.6, 168.3];
			sprite.offset.set(extraOffset[0], extraOffset[1]);
	
			var rotations:Array<Int> = [18, -8];
			var path:Array<FlxPoint> = [
					FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 60),
					FlxPoint.get(2400 - offset[0], 980 - offset[1] - 30),
					FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 10)
			];
	
			FlxTween.angle(sprite, rotations[0], rotations[1], duration);
			FlxTween.quadPath(sprite, path, duration, true, {onComplete: function(_) car2Interruptable = true});
		}

	public var closeLuas:Array<ModchartState> = [];
	public var luaArray:Array<ModchartState> = [];

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = ModchartState.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == ModchartState.Function_StopLua && !ignoreStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == ModchartState.Function_Continue;
			if(!bool) {
				returnVal = cast ret;
			}
		}
		#end
		//trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (script in luaArray) {
			script.set(variable, arg);
		}
		#end
	}

	public function searchLuaVar(variable:String, arg:String, result:Bool) {
		#if LUA_ALLOWED
		//if (Stage != null && Stage.isCustomStage && Stage.luaArray.length >= 1)
		//	Stage.setOnLuas(variable, arg);	

		for (script in luaArray)
		{
			if (script.get(variable, arg) == result)
			{
				return result;
				break;
			}
		}
		#end
		return !result;
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
}