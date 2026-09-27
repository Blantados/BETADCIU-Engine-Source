package objects;

import backend.animation.PsychAnimationController;
import shaders.RGBPalette;
import objects.notes.NoteSkinConfig;

class NoteSplash extends FunkinSprite
{
	public var rgbShader:PixelNoteShaderRef;
	public var texture:String;
	public var config(default, set):SkinAnimConfig;
	public var babyArrow:StrumNote;
	public var noteData:Int = 0;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var inEditor:Bool = false;

	var spawned:Bool = false;
	var noteDataMap:Map<Int, String> = new Map();

	public static var defaultNoteSplash(default, never):String = "noteSplashes/noteSplashes";
	public static var configs:Map<String, SkinAnimConfig> = new Map();

	public function new(?x:Float = 0, ?y:Float = 0, ?splash:String)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		rgbShader = new PixelNoteShaderRef();
		shader = rgbShader.shader;

		loadSplash(splash);
	}
	public var isLegacyNoteSkin:Bool = false;
	public var autoRGB:Bool = true;
	public var maxAnims(default, set):Int = 0;

	public function loadSplash(?splash:String)
	{
		config = null;
		maxAnims = 0;
		if(splash == null)
		{
			splash = defaultNoteSplash;
			if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) splash = PlayState.SONG.splashSkin;
		}

		if (Type.getClassName(Type.getClass(FlxG.state)) == "states.PlayState") {
			if (splash == 'noteSkins/NOTE_assets') splash = defaultNoteSplash; // lets avoid some problems with the default stuff.
			texture = splash;
			var splashPaths:Array<String> = [
				'notes/noteSplashes-$texture',
				'noteSkins/noteSplashes-$texture',
				'noteSplashes/$texture/noteSplashes',
				'noteSplashes/$texture'
			];
			
			isLegacyNoteSkin = false;
			
			for (path in splashPaths) {
				if (Paths.fileExists('images/$path.png', IMAGE)) {
					texture = path;
					isLegacyNoteSkin = (path == 'notes/noteSplashes-$splash');
					break;
				} else {
					texture = "noteSplashes/noteSplashes"; // default if couldn't find anything
				}
			}
		} else
			texture = splash;

		try {
			frames = Paths.getSparrowAtlas(texture);
		} catch (e:Dynamic) {
			frames = null;
			trace("Error loading " + texture + ": " + e);
		}
		// trace(texture);
		if (frames == null)
		{
			texture = defaultNoteSplash;
			frames = Paths.getSparrowAtlas(texture);
			if (frames == null)
			{
				texture = defaultNoteSplash;
				frames = Paths.getSparrowAtlas(texture);
			}
		}

		var path:String = 'images/$texture';
		if (configs.exists(path))
		{
			this.config = configs.get(path);
			for (anim in this.config.animations)
			{
				if (anim.noteData % 4 == 0)
					maxAnims++;
			}
			return;
		}
		else if (Paths.fileExists('$path.json', TEXT))
		{
			var config:Dynamic = haxe.Json.parse(Paths.getTextFromFile('$path.json'));
			if (config != null)
			{
				var tempConfig:SkinAnimConfig = {
					animations: new Map(),
					scale: config.scale,
					allowRGB: config.allowRGB,
					allowPixel: config.allowPixel,
					rgb: config.rgb
				}

				for (i in Reflect.fields(config.animations))
				{
					var anim:SkinAnimData = Reflect.field(config.animations, i);
					tempConfig.animations.set(i, anim);
					if (anim.noteData % 4 == 0)
						maxAnims++;
				}

				this.config = tempConfig;
				configs.set(path, this.config);
				return;
			}
		}

		// Splashes with no json
		var tempConfig:SkinAnimConfig = NoteSkinConfig.createConfig();
		var anim:String = 'note splash';
		var fps:Array<Null<Int>> = [22, 26];
		var offsets:Array<Array<Float>> = [[0, 0]];

		if (checkForAnim("note impact 1 purple")){ // Just assume if one exists, it all exists
			anim = "note impact";
			// tempConfig.allowRGB = false;
		}
		
		if (isLegacyNoteSkin) tempConfig.allowRGB = false;

		if (Paths.fileExists('$path.txt', TEXT)) // Backwards compatibility with 0.7 splash txts
		{
			var configFile:Array<String> = CoolUtil.listFromString(Paths.getTextFromFile('$path.txt'));
			if (configFile.length > 0)
			{
				anim = configFile[0];
				if (configFile.length > 1)
				{
					var framerates:Array<String> = configFile[1].split(' ');
					fps = [Std.parseInt(framerates[0]), Std.parseInt(framerates[1])];
					if (fps[0] == null) fps[0] = 22;
					if (fps[1] == null) fps[1] = 26;

					if (configFile.length > 2)
					{
						offsets = [];
						for (i in 2...configFile.length)
						{
							if (configFile[i].trim() != '')
							{
								var animOffs:Array<String> = configFile[i].split(' ');
								var x:Float = Std.parseFloat(animOffs[0]);
								var y:Float = Std.parseFloat(animOffs[1]);
								if (Math.isNaN(x)) x = 0;
								if (Math.isNaN(y)) y = 0;
								offsets.push([x, y]);
							}
						}
					}
				}
			}
		}

		var failedToFind:Bool = false;
		while (true)
		{
			for (v in Note.colArray)
			{
				var animName:String = (anim == "note impact") ? '$anim ${maxAnims+1} $v' : '$anim $v ${maxAnims+1}';
				if (!checkForAnim(animName))
				{
					failedToFind = true;
					break;
				}
			}
			if (failedToFind) break;
			maxAnims++;
		}

		for (animNum in 0...maxAnims)
		{
			for (i => col in Note.colArray)
			{
				var data:Int = i % Note.colArray.length + (animNum * Note.colArray.length);
				var name:String = animNum > 0 ? '$col' + (animNum + 1) : col;
				var offset:Array<Float> = offsets[FlxMath.wrap(data, 0, Std.int(offsets.length-1))];
				var finalPrefix:String = (anim == "note impact") ? '$anim ${animNum + 1} $col' : '$anim $col ${animNum + 1}';

				addAnimationToConfig(tempConfig, 1, name, finalPrefix, fps, offset, [], data);
			}
		}

		this.config = tempConfig;
		configs.set(path, this.config);
	}

	public function spawnSplashNote(?x:Float = 0, ?y:Float = 0, ?noteData:Int = 0, ?note:Note, ?randomize:Bool = true)
	{
		if (note != null && note.noteSplashData.disabled)
			return;

		aliveTime = 0;

		if (!inEditor)
		{
			var loadedTexture:String = defaultNoteSplash;
			if (note != null && note.noteSplashData.texture != null) {
				loadedTexture = note.noteSplashData.texture;
			}
			else if (note != null && note.texture != null){
				loadedTexture = note.texture;
			}
			else if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0){
				loadedTexture = PlayState.SONG.splashSkin;
			}

			if (texture != loadedTexture) loadSplash(loadedTexture);
		}

		setPosition(x, y);

		if (babyArrow != null)
			setPosition(babyArrow.x - Note.swagWidth * 0.95, babyArrow.y - Note.swagWidth); // To prevent it from being misplaced for one game tick

		if (note != null) {
			noteData = note.noteData;
			config.allowPixel = note.isPixelNote;
		}

		if (randomize && maxAnims > 1)
			noteData = noteData % Note.colArray.length + (FlxG.random.int(0, maxAnims - 1) * Note.colArray.length);

		this.noteData = noteData;
		var anim:String = playDefaultAnim();

		var tempShader:RGBPalette = null;
		if (config.allowRGB)
		{
			NoteRGBShader.initializeGlobalRGBShader(noteData % Note.colArray.length, note != null && note.isPixelNote);
			if (inEditor || (note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
			{
				tempShader = new RGBPalette();
				// If Note RGB is enabled:
				if ((note == null || !note.noteSplashData.useGlobalShader) || inEditor)
				{
					var colors = config.rgb;
					if (colors != null)
					{
						for (i in 0...colors.length)
						{
							if (i > 2) break;

							var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData % Note.colArray.length];
							if (note != null && note.isPixelNote) arr = ClientPrefs.data.arrowRGBPixel[noteData % Note.colArray.length];

							var rgb = colors[i];
							if (rgb == null)
							{
								if (i == 0) tempShader.r = arr[0];
								else if (i == 1) tempShader.g = arr[1];
								else if (i == 2) tempShader.b = arr[2];
								continue;
							}

							var r:Null<Int> = rgb.r; 
							var g:Null<Int> = rgb.g;
							var b:Null<Int> = rgb.b;

							if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
							if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
							if (b == null || Math.isNaN(b) || b < 0) b = arr[2];

							var color:FlxColor = FlxColor.fromRGB(r, g, b);
							if (i == 0) tempShader.r = color;
							else if (i == 1) tempShader.g = color;
							else if (i == 2) tempShader.b = color;
						}
					} else {
						if (note != null && !isLegacyNoteSkin && note.isLegacyNoteSkin && autoRGB) {
							final tones = NoteColorExtractor.generateTones(NoteColorExtractor.getDominantColor(note));

							tempShader.r = tones.highlight;
							tempShader.g = FlxColor.WHITE;
							tempShader.b = tones.shadow;
						} else {
							tempShader.copyValues(NoteRGBShader.globalRgbShaders[noteData % Note.colArray.length]);
						}

						// tempShader.copyValues(NoteRGBShader.globalRgbShaders[noteData % Note.colArray.length]);
					}

					if (note != null)
					{
						if (note.noteSplashData.r != -1) tempShader.r = note.noteSplashData.r;
						if (note.noteSplashData.g != -1) tempShader.g = note.noteSplashData.g;
						if (note.noteSplashData.b != -1) tempShader.b = note.noteSplashData.b;
					}
				}
				else tempShader.copyValues(NoteRGBShader.globalRgbShaders[noteData % Note.colArray.length]);
			}
		}
		rgbShader.copyValues(tempShader);
		if (!config.allowPixel) rgbShader.pixelAmount = 0.00001;
		else if (note != null && note.isPixelNote) rgbShader.pixelAmount = 6;

		offset.set(10, 10);
		var conf:SkinAnimData = config.animations.get(anim);
		var offsets:Array<Float> = [0, 0];
		if (conf != null) offsets = conf.offsets;
		if (offsets != null)
		{
			offset.x += offsets[0];
			offset.y += offsets[1];
		}

		animation.finishCallback = function(name:String) {
			kill();
			spawned = false;
		}

		alpha = ClientPrefs.data.splashAlpha;
		if (note != null) alpha = note.noteSplashData.a;

		antialiasing = ClientPrefs.data.antialiasing;
		if (note != null) {
			antialiasing = note.noteSplashData.antialiasing;
			if (note.isPixelNote && config.allowPixel) antialiasing = false;
		}

		var minFps:Int = 22;
		var maxFps:Int = 26;
		if (conf != null)
		{
			minFps = conf.fps[0];
			if (minFps < 0) minFps = 0;

			maxFps = conf.fps[1];
			if (maxFps < 0) maxFps = 0;
		}

		if (animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);

		spawned = true;
	}
	
	public function playDefaultAnim()
	{
		var anim:String = noteDataMap.get(noteData);
		if (anim != null && animation.exists(anim))
			animation.play(anim, true);

		return anim;
	}

	function checkForAnim(anim:String)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

		return animFrames.length > 0;
	}

	var aliveTime:Float = 0;
	static var buggedKillTime:Float = 0.5; //automatically kills note splashes if they break to prevent it from flooding your HUD
	override function update(elapsed:Float)
	{
		if (spawned)
		{
			aliveTime += elapsed;
			if (animation.curAnim == null && aliveTime >= buggedKillTime)
			{
				kill();
				spawned = false;
			}
		}

		if (babyArrow != null)
		{
			if (copyX)
				x = babyArrow.x - Note.swagWidth * 0.95;

			if (copyY)
				y = babyArrow.y - Note.swagWidth;
		}
		super.update(elapsed);
	}

	public static function createConfig():SkinAnimConfig
	{
		return NoteSkinConfig.createConfig();
	}

	public static function addAnimationToConfig(config:SkinAnimConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>, indices:Array<Int>, noteData:Int):SkinAnimConfig
	{
		if (config == null) config = NoteSkinConfig.createConfig();

		config.animations.set(name, {name: name, noteData: noteData, prefix: prefix, indices: indices, offsets: offsets, fps: fps});
		config.scale = scale;
		return config;
	}

	function set_config(value:SkinAnimConfig):SkinAnimConfig
	{
		return config = NoteSkinConfig.applyConfig(this, animation, value, noteDataMap, true);
	}

	function set_maxAnims(value:Int)
	{
		if (value > 0)
			noteData = Std.int(FlxMath.wrap(noteData, 0, (value * Note.colArray.length) - 1));
		else
			noteData = 0;

		return maxAnims = value;
	}
}