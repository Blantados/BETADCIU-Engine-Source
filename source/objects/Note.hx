package objects;

import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import objects.StrumNote;

import flixel.math.FlxRect;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String,
	value3:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

typedef NoteAnimArray = {
    var anim:String;
    var offsets:Array<Int>;

    @:optional var name:String;
    @:optional var fps:Int;
    @:optional var loop:Bool;
    @:optional var indices:Array<Int>;
}

typedef NoteConfig = {
	@:optional var strumAnimations:Array<NoteAnimArray>;
	@:optional var noteAnimations:Array<NoteAnimArray>;
	@:optional var rgbEnabled:Bool;
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends OffsettableSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	// Implemented here so I can add offsets to the notes. Particularly the tail
	public static var configs:Map<String, NoteConfig> = new Map();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;
	public var dType:Int = 0;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	//Weekend notes implementation... kinda
	var separateSheets:Bool = false;
	var separateXMLExists:Bool = false;
	public var noteAnimSuffixes:Array<String> = ["0", " hold piece", " hold end"]; // To accommodate for other namings

	// I don't like using isPixelStage;
	public var isPixelNote:Bool = false; // Needs to be global for use in other functions

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value){
			value = reloadNote(value); // Value could be updated inside reloadNote
		}

		texture = value;
		return value;
	}

	public function defaultRGB(?pixelShit:Bool=false)
	{
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];
		if(pixelShit) arr = ClientPrefs.data.arrowRGBPixel[noteData];

		if (arr != null && noteData > -1 && noteData <= arr.length)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
		defaultRGB();

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					//reloadNote('HURTNOTE_assets');
					//this used to change the note texture to HURTNOTE_assets.png,
					//but i've changed it to something more optimized with the implementation of RGBPalette:

					// note colors
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if(noteData > -1)
		{
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
			texture = '';

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData < colArray.length) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.data.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (isPixelNote || separateSheets)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;

				if(isPixelNote) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); //Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if(isPixelNote)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGB[noteData] : ClientPrefs.data.arrowRGBPixel[noteData];
			
			if (arr != null && noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}
			
			globalRgbShaders[noteData] = newRGB;
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this

	public var isLegacyNoteSkin:Bool = false;

	public function reloadNote(texture:String = '', postfix:String = '') {
		rgbShader.enabled = true; // It should always set back to true in case texture is empty or texture.length < 1;

		if(texture == null) texture = "";
		if(postfix == null) postfix = '';

		if(texture.length < 1) {
			// if (PlayState.SONG != null && PlayState.SONG.noteStyle != null){
			// 	texture = PlayState.SONG != null ? PlayState.SONG.noteStyle : null;
			// } else{
			// 	texture = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			// }

			if(texture == null || texture.length < 1) texture = defaultNoteSkin + postfix;
		}
		else rgbShader.enabled = false;

		separateSheets = false;
		separateXMLExists = false;
		isLegacyNoteSkin = false;

		var skin:String = texture + postfix;
		if (texture == 'pixel') {
			rgbShader.enabled = true;
			texture = "NOTE_assets-pixel";
			skin = texture + postfix;
		}else if (texture == 'normal') {
			rgbShader.enabled = true;
			texture = "NOTE_assets";
			skin = texture + postfix;
		}
		var notePath:String = texture;

		var isCustomNoteSkin:Bool = false;
		var CustomNoteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		for (i in 0...CustomNoteSkins.length) {
			if (CustomNoteSkins[i] == skin) isCustomNoteSkin = true;
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var wasPixelNote:Bool = isPixelNote;
		isPixelNote = false;
		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = isPixelNote ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';


		var pathSplit:Array<String> = skin.split('/');
		var curSkin = skin;

		for (noteDirectory in ["noteSkins/", "notes/", "pixelUI/noteSkins/", "pixelUI/Notes/"]) {
			final fullPath = '$noteDirectory$skin';
			final weekendPath = '$fullPath/notes';
			var jsonPath = fullPath;

			if (Paths.fileExists('images/$weekendPath.png', IMAGE)) {
				separateSheets = true;
				final jsonName = pathSplit[pathSplit.length - 1];
				
				jsonPath = '$noteDirectory$skin/$jsonName';
				skin = weekendPath;
			} else if (Paths.fileExists('images/$fullPath.png', IMAGE)) {
				skin = fullPath;
			}

			if (Paths.fileExists('images/$jsonPath.json', TEXT)) {
				final json = getNoteConfig('images/$jsonPath');
				rgbShader.enabled = json.rgbEnabled != null ? json.rgbEnabled : false;

				if (json.noteAnimations != null) {
					for (anim in json.noteAnimations) {
						addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
					}
				}
			}

			if (curSkin != skin){
				isLegacyNoteSkin = (noteDirectory == "notes/");
				if (noteDirectory.startsWith("pixelUI/") || StringTools.contains(skin, "-pixel")) {
					isPixelNote = true;
				}
				break;
			}
		}
		
		if (noteType != 'Hurt Note') defaultRGB(isPixelNote);

		if (isLegacyNoteSkin && !isCustomNoteSkin) rgbShader.enabled = false;
		
		if(isPixelNote) {
			if(isSustainNote) {
				var graphic = Paths.image(skin + 'ENDS' + skinPostfix);
				try{
					loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				} catch(e) {
					var fallbackShit = Paths.image('pixelUI/' + Note.defaultNoteSkin + '-pixelENDS' + skinPostfix);
					graphic = fallbackShit;
					loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				}
				originalHeight = graphic.height / 2;
			} else {
				var graphic = Paths.image(skin + skinPostfix);
				try {
					loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
				} catch(e) {
					var fallbackShit = Paths.image('pixelUI/' + Note.defaultNoteSkin + skinPostfix);
					graphic = fallbackShit;
					var graphic = Paths.image('pixelUI/' + Note.defaultNoteSkin + '-pixel' + skinPostfix);
					loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
				}
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			loadNoteFrames(skin, separateSheets);
			loadNoteAnims();
			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if(isSustainNote) {
			scale.y = lastScaleY;
			if (wasPixelNote && !isPixelNote) offsetX += 30;
			if (isPixelNote && !wasPixelNote) offsetX -= 5;
		}
		updateHitbox();
		

		if(animName != null)
			animation.play(animName, true);

		return texture;
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteFrames(skin:String, ?separateSheets:Bool = false){
		if (separateSheets && isSustainNote){
			if (Paths.fileExists("images/" + skin + "_hold.xml", IMAGE)){
				frames = Paths.getSparrowAtlas(skin + "_hold");
				separateXMLExists = true;
			}else{
				var rawPic:Dynamic = Paths.image(skin + "_hold");
				loadGraphic(rawPic, true, 52, 87);
			}
		}else{
			try {
				frames = Paths.getSparrowAtlas(skin);
			} catch(e){
				texture = Note.defaultNoteSkin;
			}
		}
	}

	function loadNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if (separateSheets){
			if (isSustainNote) {
				if (separateXMLExists){
					animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + noteAnimSuffixes[2], 24, true);
					animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + noteAnimSuffixes[1], 24, true);
				}else{
					animation.add(colArray[noteData] + 'holdend', [noteData * 2 + 1]);
					animation.add(colArray[noteData] + 'hold', [noteData * 2]);
				}
			}else{
				var dirScroll:Array<String> = ["Left", "Down", "Up", "Right"];
				animation.addByPrefix(colArray[noteData]+"Scroll", "note" + dirScroll[noteData]);
			}
		}else{
			if (isSustainNote)
			{
				attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
				animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
				animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
			}
			else animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');
		}
		
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if(isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		} else animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		if (frames == null) {
			// trace('Warning: Frames are null. Cannot add animation "$name" with prefix "$prefix".');
			return;
		}
		
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote)
			{
				if(isPixelNote)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}

	public static function dummy():NoteConfig
	{
		return {
			strumAnimations: [
				{
					offsets: [
						0,
						0
					],
					anim: "confirm"
				},
				{
					offsets: [
						0,
						0
					],
					anim: "pressed"
				},
				{
					offsets: [
						0,
						0
					],
					anim: "static"
				}
			],
			rgbEnabled: true
		};
	}

	public static function getNoteConfig(jsonPath:String){
		try
		{
			if (!configs.exists(jsonPath)){
				configs.set(jsonPath, cast tjson.TJSON.parse(Paths.getTextFromFile('$jsonPath.json')));
			}
			
			return configs.get(jsonPath);
		}
		return dummy();
	}
}
