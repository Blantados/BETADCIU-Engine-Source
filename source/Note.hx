package;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import sys.io.File;
import sys.FileSystem;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
#if polymod
import polymod.format.ParseRules.TargetSignatureElement;
#end
import PlayState;
import LuaClass.LuaNote;
import Type.ValueType;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var LuaNote:LuaNote;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var modifiedByLua:Bool = false;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;	
	public var noteType(default, set):String = null;

	public var style:String = "";
	public var mania:Int = 0;
	public var dType:Int = 0;
	public var pixelBurn:Bool = false;
	public var blackStatic:Bool = false;
	public static var mickeyNotes:Bool = false;
	public static var auditorNotes:Bool = false;
	public var isAuditorNote:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var noteScore:Float = 1;

	public var luaID:Int = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;

	//different notes
	public var markov:Bool = false;
	public var danger:Bool = false;
	public var burning:Bool = false;
	public var staticNote:Bool = false;
	public var bomb:Bool = false;
	public var neonNote:Bool = false;
	public var biteNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public static var swagWidth:Float = 160 * 0.7;
	public static var noteScale:Float;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;
	public static var tooMuch:Float = 30;
	public static var scales:Array<Float> = [0.7, 0.6, 0.46, 0.66, 0.55];
	public static var swidths:Array<Float> = [160, 120, 90, 140, 110];
	public static var posRest:Array<Int> = [0, 35, 70, 60, 20];
	public var curSpeed:Float;
	public var flipScroll:Bool = false; //just use false for upscroll
	var pre:String;
	var suf:String;

	//detected
	public var modAngle:Float = 0; // The angle set by modcharts

	public var rating:String = "shit";

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var gfNote:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var canMiss:Bool = false;
	public var noRating:Bool = false;
	public var multSpeed(default, set):Float = 1;

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyAngle:Bool = true;
	public var copyVisible:Bool = true;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var animSuffix:String = '';

	public var originalHeightForCalcs:Float = 6;

	public var noteSection:Int = 0;

	public var texture(default, set):String = null;

	private function set_texture(value:String):String {
		reloadNote(value);
		return value;
	}

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_noteType(value:String):String {

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = true; //just let the opponent ignore it too
					reloadNote('HURTNOTE_assets');
					noteSplashTexture = 'HURTnoteSplashes';
					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
					lateHitMult = 0.4;
					earlyHitMult = 0.6;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
				case 'GF Sing': 
					gfNote = true;
			}
			noteType = value;
		}
		return value;
	}


	public function new(_strumTime:Float, _noteData:Int, ?_prevNote:Note, ?sustainNote:Bool = false, ?noteTypeOld:String = "", ?style:String = 'normal')
	{
		super();

		mania = PlayState.SONG.mania;

		if (prevNote == null)
			prevNote = this;

		prevNote = _prevNote;
		isSustainNote = sustainNote;
		
		this.style = style;

		swagWidth = swidths[mania] * 0.7; //factor not the same as noteScale
		noteScale = scales[mania];
		
		x += 50 - posRest[mania];
		
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;

		if (mania == 2)
			x -= tooMuch;

		strumTime = _strumTime;

		noteData = _noteData % Main.keyAmmo[mania];

		texture = style;

		var frameN:Array<String> = ['purple', 'blue', 'green', 'red'];
		switch (mania)
		{
			case 1: frameN = ['purple', 'green', 'red', 'yellow', 'blue', 'dark'];
			case 2: frameN = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'black', 'dark'];
			case 3: frameN = ['purple', 'blue', 'white', 'green', 'red'];
			case 4:	frameN = ['purple', 'green', 'red', 'white', 'yellow', 'blue', 'dark'];
		}

		if(_noteData > -1) {
			x += swidths[mania] * swagWidth * (noteData % Main.keyAmmo[mania]);
			if (!isSustainNote)
				animation.play(frameN[noteData] + 'Scroll');
		}

		if ((FlxG.save.data.downscroll || (!FlxG.save.data.downscroll && flipScroll)) && sustainNote) 
			flipY = true;

		if (isSustainNote && prevNote != null)
		{
			noteScore * 0.2;
			alpha = 0.6;

			offsetX += width / 2;

			animation.play(frameN[noteData] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (isPixel)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(frameN[prevNote.noteData] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05 * (PlayState.instance != null ? PlayState.instance.songSpeed : 1); //idk why but 1.05 doesn't work.					
				prevNote.updateHitbox();
			}
		}

		x += offsetX;
	}

	public var isPixel:Bool = false;

	public function checkNoteXML(rawXml:String)
	{
		//based on the system used in GuestBETADCIUState
		var daXml:Xml = Xml.parse(rawXml);
		var fast = new haxe.xml.Access(daXml);
		var users = fast.node.TextureAtlas;
		for (SubTexture in users.nodes.SubTexture) {
			var name = Std.string(SubTexture.att.name);
			var nameCut = name.substr(0, name.length - 4);
			
			if (nameCut.contains('tail'))
			{
				noteAnimSuffixes = [' alone', ' hold', ' tail'];
				return;
			}
		}
	}

	public var curFlipY:Bool = false;

	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		//this is dumb but it wouldn't work with the other way I did it so....
		if (isSustainNote && prevNote != null) {
			var targetFlipY = (FlxG.save.data.downscroll != flipScroll);
			if (flipY != targetFlipY) {
				flipY = targetFlipY;
			}
		}

		if (modifiedByLua)
			angle = modAngle;

		if (mustPress)
		{			 
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;
		
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset * Conductor.timeScale && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition) {
				wasGoodHit = true;
			}
			
			return;
		}
		
		if (tooLate) {
			alpha = alpha < 0.3 ? alpha : 0.3;
		}
	}

	var reloadedNote:Bool = false;

	// testing for arrow switching mid song. stealing from psych
	public function reloadNote(style2:String, ?noteTypeStyles:String = "") 
	{
		noteTypeStyle = noteTypeStyles;
		reloadedNote = true;

		var lastScaleY:Float = scale.y;
		var wasPixelNote:Bool = isPixel;
		var becomePixelNote:Bool = style2.contains('pixel');

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		loadNoteAnims(style2, isSustainNote);

		if(animName != null)
			animation.play(animName, true);

		if(isSustainNote)
		{
			scale.y = lastScaleY;
	
			if (wasPixelNote && !becomePixelNote) //fixes the scaling
			{
				scale.y /= PlayState.daPixelZoom;
				scale.y *= noteScale;

				offsetX += 3;
			}

			if (becomePixelNote && !wasPixelNote) //fixes the scaling
			{
				scale.y /= noteScale;
				scale.y *= PlayState.daPixelZoom;

				offsetX -= 3;
			}
		}
		
		updateHitbox();

		style = style2;
	}

	public var noteTypeStyle:String = "";

	function loadNoteAnims(style:String, ?sustainNote:Bool = false) 
	{
		switch (style)
		{
			case 'pixel':
				var suf:String = "";
				isPixel = true;

				if (isSustainNote)
				{
					loadGraphic(Paths.image('notes/arrowEnds'+suf), true, 7, 6);
					originalHeightForCalcs = 3;
				}
				else
					loadGraphic(Paths.image('notes/arrows-pixels'+suf), true, 17, 17);

				addAnims(true);
		
			case 'noStrums':
				loadGraphic(Paths.image('notes/noStrums'), true, 17, 17);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				antialiasing = false;

				var colorScroll:Array<String> = ['purple', 'blue', 'green', 'red'];

				for (i in 0...colorScroll.length)
				{
					animation.add(colorScroll[i], [0]);
					animation.add(colorScroll[i]+'Scroll', [0]);
					animation.add(colorScroll[i]+'hold', [0], 12, false);
					animation.add(colorScroll[i]+'holdend', [0], 24, false);
				}

			default:
				if (Assets.exists(Paths.image('notes/'+style))){
					frames = Paths.getSparrowAtlas('notes/'+style);

					addAnims();
				}
				else
				{
					if (FileSystem.exists(Paths.modsImages('notes/'+style)))
						style = 'notes/'+style;
					
					if (FileSystem.exists(Paths.modsImages(style)))
					{
						var rawPic:Dynamic = Paths.returnGraphic(style);

						if (!FileSystem.exists(Paths.modsXml(style)))
						{
							if (isSustainNote)
							{		
								var rawPic2:Dynamic = Paths.returnGraphic(style+'ENDS');

								loadGraphic(rawPic2);

								width = width / 4;
								height = height / 2;

								loadGraphic(rawPic2, true, Math.floor(width), Math.floor(height));
							}
							else{
								loadGraphic(rawPic);

								width = width / 4;
								height = height / 5;

								loadGraphic(rawPic, true, Math.floor(width), Math.floor(height));
							}
								

							addAnims(true);
						}
						else
						{
							frames = Paths.getSparrowAtlas(style);
							addAnims();
						}
					}

					if (frames == null)
					{
						if (isPixel)
						{
							if (isSustainNote)
								loadGraphic(Paths.image('notes/arrowEnds'), true, 7, 6);
							else
								loadGraphic(Paths.image('notes/arrows-pixels'), true, 17, 17);
			
							addAnims(true);
						}
						else
						{
							frames = Paths.getSparrowAtlas(mania > 0 ? 'notes/shaggyNotes' : 'notes/NOTE_assets');
							addAnims();
						}
					}
				}
		}

		if (FlxG.save.data.poltatoPC)
		{
			scale.set(scale.x*2, scale.y*2);
			updateHitbox();
		}
	}

	public var noteAnimSuffixes:Array<String> = ['0', ' hold piece', ' hold end']; //accomodate for other namings

	function addAnims(?pixel:Bool = false)
	{
		if (pixel)
		{
			animation.add('greenScroll', [6]);
			animation.add('redScroll', [7]);
			animation.add('blueScroll', [5]);
			animation.add('purpleScroll', [4]);

			if (isSustainNote)
			{
				animation.add('purpleholdend', [4]);
				animation.add('greenholdend', [6]);
				animation.add('redholdend', [7]);
				animation.add('blueholdend', [5]);

				animation.add('purplehold', [0]);
				animation.add('greenhold', [2]);
				animation.add('redhold', [3]);
				animation.add('bluehold', [1]);
			}

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		
			isPixel = true;
		}
		else
		{
			isPixel = false;
			var colorScroll:Array<String> = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'black', 'dark'];
			var length:Int = 4;

			if (mania > 0)
				length = 9;

			for (i in 0...length)
			{
				animation.addByPrefix(colorScroll[i]+'Scroll', colorScroll[i]+noteAnimSuffixes[0]);
				animation.addByPrefix(colorScroll[i]+'hold', colorScroll[i]+noteAnimSuffixes[1]);
				animation.addByPrefix(colorScroll[i]+'holdend', colorScroll[i]+noteAnimSuffixes[2]);

				if (colorScroll[i] == 'purple' && animation.getByName('purpleholdend') == null)
					animation.addByPrefix(colorScroll[i]+'holdend', 'pruple end hold'); //because purple naming
			}

			setGraphicSize(Std.int(width * noteScale));
			antialiasing = true;
		}

		updateHitbox();
	}
}