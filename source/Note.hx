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
	public var downscroll:Bool = false; //just use false for upscroll
	var pre:String;
	var suf:String;

	//detected
	public var modAngle:Float = 0; // The angle set by modcharts

	public var rating:String = "shit";

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var noAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var gfNote:Bool = false;
	public var ignoreNote:Bool = false;
	public var canMiss:Bool = false;
	public var noRating:Bool = false;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

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
					ignoreNote = mustPress;
					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
				case 'No Animation':
					noAnimation = true;
				case 'GF Sing': 
					gfNote = true;
			}
			noteType = value;
		}
		return value;
	}


	public function new(_strumTime:Float, _noteData:Int, ?_prevNote:Note, ?sustainNote:Bool = false, ?noteTypeOld:String = "", style:String = 'normal')
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

		/*if (PlayState.SONG.song.toLowerCase() == 'bonedoggle')
		{
			swagWidth = swidths[3] * 0.7; //factor not the same as noteScale
			noteScale = scales[3];
		}

		if (style == 'exe' && mania == 3)
		{
			swagWidth = swidths[0] * 0.7; //factor not the same as noteScale
			noteScale = scales[0];
		}*/
		
		x += 50 - posRest[mania];
		
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;

		if (PlayState.SONG.mania == 2)
			x -= tooMuch;

		strumTime = _strumTime;

		if (this.strumTime < 0 )
			this.strumTime = 0;

//		if (PlayState.curStage == 'auditorHell' && noteType == 4)
//			auditorNotes = true;

		noteData = _noteData % Main.keyAmmo[mania];
		
		var daStage:String = PlayState.curStage;

		if(isSustainNote) 
		{ 
		/*	switch (noteType)
			{
				case 2: markov = true;
				case 3: danger = true;
				case 4: burning = true;
				case 5: staticNote = true;
				case 6: bomb = true;
			}	*/		
		}

		//defaults if no noteStyle was found in chart
		var noteTypeCheck:String = 'normal';

		loadNoteAnims(style, sustainNote);

		var frameN:Array<String> = ['purple', 'blue', 'green', 'red'];
		switch (mania)
		{
			case 1:
				frameN = ['purple', 'green', 'red', 'yellow', 'blue', 'dark'];
			case 2:
				frameN = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'violet', 'black', 'dark'];
			case 3:
				frameN = ['purple', 'blue', 'white', 'green', 'red'];
			case 4:
				frameN = ['purple', 'green', 'red', 'white', 'yellow', 'blue', 'dark'];
		}

		if(_noteData > -1) {
			x += swidths[mania] * swagWidth * (noteData % Main.keyAmmo[mania]);
			if (!isSustainNote)
				animation.play(frameN[noteData] + 'Scroll');
		}

		if (style == "guitar"){
			offset.x = -15;
			offset.y = -30;
		}

		if ((FlxG.save.data.downscroll || downscroll) && sustainNote) 
			flipY = true;

		if (isSustainNote && prevNote != null)
		{
			noteScore * 0.2;
			alpha = 0.6;

			offsetX += width / 2;

			animation.play(frameN[noteData] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (style == "guitar")
			{
				offsetX -= 20;
				offset.x = -15;
			}

			if (isPixel)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(frameN[prevNote.noteData] + 'hold');

				if(FlxG.save.data.scrollSpeed != 1)
					prevNote.scale.y *= Conductor.stepCrochet / 100 * (1.5 * (0.7 - noteScale + 1)) * FlxG.save.data.scrollSpeed;
				else
					prevNote.scale.y *= Conductor.stepCrochet / 100 * (1.5 * (0.7 - noteScale + 1)) * PlayState.SONG.speed;

				prevNote.updateHitbox();
			}
		}

		x += offsetX;
	}

	var isPixel:Bool = false;

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

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if ((FlxG.save.data.downscroll || downscroll) && isSustainNote)
			flipY = true;

		if (modifiedByLua)
			angle = modAngle;

		//we added event arrows so this isn't needed.
		//if (noteData == -1)
			//this.kill(); //removes psych event arrows when porting charts from psych.

		if(isSustainNote) 
		{ 
		/*	switch (noteType)
			{
				case 2 | 3 | 4 | 5 | 6:
					this.kill();
			}	*/
		}

		if (mustPress)
		{
			/*switch (noteType)
			{
				case 4 | 6 | 8 | 9 | 10:
					if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * 0.6)
						&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.4)) // also they're almost impossible to hit late!
						canBeHit = true;
					else
						canBeHit = false;
				case 2:
					if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * 0.3)
						&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.2)) // also they're almost impossible to hit late!
						canBeHit = true;
					else
						canBeHit = false;
				default:
			}*/

			if (burning && PlayState.curStage == 'auditorHell' || burning && auditorNotes) // the auditor ones
			{
				if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * 0.3)
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.2)) // also they're almost impossible to hit late!
					canBeHit = true;
				else
					canBeHit = false;
			}
			else
			{
				if (isSustainNote)
				{
					if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * 1.5)
						&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
						canBeHit = true;
					else
						canBeHit = false;
				}
				else
				{
					if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
						&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
						canBeHit = true;
					else
						canBeHit = false;
				}
			}
		
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset * Conductor.timeScale && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
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
			case 'pixel': //| 'pixel-corrupted' | 'neon' | 'doki-pixel':
				var suf:String = "";
				isPixel = true;
				switch (style)
				{
					case 'pixel-corrupted':
						suf = '-corrupted';
					case 'neon':
						suf = '-neon';
					case 'doki-pixel':
						suf = '-doki';
				}	

				if (isSustainNote)
					loadGraphic(Paths.image('notes/arrowEnds'+suf), true, 7, 6);
				else
					loadGraphic(Paths.image('notes/arrows-pixels'+suf), true, 17, 17);

				addAnims(true);
		
			case 'noStrums':
				loadGraphic(Paths.image('notes/noStrums'), true, 17, 17);
				animation.add('green', [0]);
				animation.add('red', [0]);
				animation.add('blue', [0]);
				animation.add('purple', [0]);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				antialiasing = false;

				var colorScroll:Array<String> = ['purple', 'blue', 'green', 'red'];
				var length:Int = 4;

				for (i in 0...length)
				{
					animation.add(colorScroll[i]+'Scroll', [0]);
					animation.add(colorScroll[i]+'hold', [0], 12, false);
					animation.add(colorScroll[i]+'holdend', [0], 24, false);
				}

			default:
				if (Assets.exists(Paths.image('notes/'+style)))
				{
					frames = Paths.getSparrowAtlas('notes/'+style);
	
					if (frames == null)
					{
						if (mania > 0)
							frames = Paths.getSparrowAtlas('notes/shaggyNotes');
						else
							frames = Paths.getSparrowAtlas('notes/NOTE_assets');
					}
					
					addAnims();
				}
				else
				{
					if (FileSystem.exists(Paths.modsImages('notes/'+style)))
						style = 'notes/'+style;
					
					if (FileSystem.exists(Paths.modsImages(style)))
					{
						if (!Paths.currentTrackedAssets.exists(style))
							Paths.cacheImage(style);

						var rawPic:Dynamic = Paths.currentTrackedAssets.get(style);

						if (!FileSystem.exists(Paths.modsXml(style)))
						{
							if (isSustainNote)
							{
								if (!Paths.currentTrackedAssets.exists(style+'ENDS'))
									Paths.cacheImage(style+'ENDS');
		
								var rawPic2:Dynamic = Paths.currentTrackedAssets.get(style+'ENDS');
								loadGraphic(rawPic2, true, 7, 6);
							}
							else
								loadGraphic(rawPic, true, 17, 17);

							addAnims(true);
						}
						else
						{
							var rawXml = File.getContent(Paths.modsXml(style));
						
							frames = FlxAtlasFrames.fromSparrow(rawPic, rawXml);
							checkNoteXML(rawXml);
	
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
							if (mania > 0)
								frames = Paths.getSparrowAtlas('notes/shaggyNotes');
							else
								frames = Paths.getSparrowAtlas('notes/NOTE_assets');

							
							addAnims();
						}
					}
				}
		}

		/*switch (noteType)
		{
			case 2:
				if (PlayState.SONG.noteStyle.contains('pixel') || PlayState.isPixel)
				{
					loadGraphic(Paths.image('notes/arrows-pixels'), true, 17, 17);
					animation.add('greenScroll', [22]);
					animation.add('redScroll', [23]);
					animation.add('blueScroll', [21]);
					animation.add('purpleScroll', [20]);

					antialiasing = false;
					setGraphicSize(Std.int(width * PlayState.daPixelZoom));
					updateHitbox();
				}
				else
				{
					frames = Paths.getSparrowAtlas('notes/markov');

					animation.addByPrefix('greenScroll', 'markov green0');
					animation.addByPrefix('redScroll', 'markov red0');
					animation.addByPrefix('blueScroll', 'markov blue0');
					animation.addByPrefix('purpleScroll', 'markov purple0');

					animation.addByPrefix('purpleholdend', 'markov pruple end hold');
					animation.addByPrefix('greenholdend', 'markov green hold end');
					animation.addByPrefix('redholdend', 'markov red hold end');
					animation.addByPrefix('blueholdend', 'markov blue hold end');

					animation.addByPrefix('purplehold', 'markov purple hold piece');
					animation.addByPrefix('greenhold', 'markov green hold piece');
					animation.addByPrefix('redhold', 'markov red hold piece');
					animation.addByPrefix('bluehold', 'markov blue hold piece');

					setGraphicSize(Std.int(width * 0.7));
					updateHitbox();
					antialiasing = true;
				}
			case 3:
				if (PlayState.SONG.noteStyle.contains('pixel') || PlayState.isPixel)
				{
					loadGraphic(Paths.image('notes/warningNotePixel'), true, 16, 16);

					animation.add('greenScroll', [0]);
					animation.add('redScroll', [0]);
					animation.add('blueScroll', [0]);
					animation.add('purpleScroll', [0]);
					pixelBurn = true;

					setGraphicSize(Std.int(width * PlayState.daPixelZoom));
					updateHitbox();
					antialiasing = false;
				}
				else
				{
					switch (noteTypeStyle)
					{
						case 'hank':
							loadGraphic(Paths.image('notes/bullet'), true, 150, 150);

							animation.add('greenScroll', [0]);
							animation.add('redScroll', [3]);
							animation.add('blueScroll', [1]);
							animation.add('purpleScroll', [2]);
		
							setGraphicSize(Std.int(width * noteScale));
							updateHitbox();
							antialiasing = true;	
							return;
						case 'bite':
							frames = Paths.getSparrowAtlas('notes/biteNotes');

							animation.addByPrefix('greenScroll', 'green0');
							animation.addByPrefix('redScroll', 'red0');
							animation.addByPrefix('blueScroll', 'blue0');
							animation.addByPrefix('purpleScroll', 'purple0');
		
							animation.addByPrefix('purpleholdend', 'pruple end hold');
							animation.addByPrefix('greenholdend', 'green hold end');
							animation.addByPrefix('redholdend', 'red hold end');
							animation.addByPrefix('blueholdend', 'blue hold end');
		
							animation.addByPrefix('purplehold', 'purple hold piece');
							animation.addByPrefix('greenhold', 'green hold piece');
							animation.addByPrefix('redhold', 'red hold piece');
							animation.addByPrefix('bluehold', 'blue hold piece');

							setGraphicSize(Std.int(width * 0.7));
							updateHitbox();
							antialiasing = true;
							return;
						case 'mami':
							loadGraphic(Paths.image('notes/holynote'), true, 157, 154);
						default:
							loadGraphic(Paths.image('notes/warningNote'), true, 157, 154);
					}
						
					animation.add('greenScroll', [0]);
					animation.add('redScroll', [0]);
					animation.add('blueScroll', [0]);
					animation.add('purpleScroll', [0]);

					setGraphicSize(Std.int(width * noteScale));
					updateHitbox();
					antialiasing = true;
				}	
			case 4:
				if (PlayState.SONG.noteStyle.contains('pixel') || PlayState.isPixel)
				{
					loadGraphic(Paths.image('notes/NOTE_fire-pixel'), true, 21, 31);
					
					animation.add('greenScroll', [6, 7, 6, 8], 8);
					animation.add('redScroll', [9, 10, 9, 11], 8);
					animation.add('blueScroll', [3, 4, 3, 5], 8);
					animation.add('purpleScroll', [0, 1 ,0, 2], 8);
					offsetX -= 5;

					setGraphicSize(Std.int(width * PlayState.daPixelZoom));
					updateHitbox();
					antialiasing = false;
				}
				else
				{
					if (auditorNotes)
					{
						isAuditorNote = true;

						frames = Paths.getSparrowAtlas('notes/ALL_deathnotes');
						animation.addByPrefix('greenScroll', 'Green Arrow');
						animation.addByPrefix('redScroll', 'Red Arrow');
						animation.addByPrefix('blueScroll', 'Blue Arrow');
						animation.addByPrefix('purpleScroll', 'Purple Arrow');

						setGraphicSize(Std.int(width * 0.7));
						updateHitbox();
						antialiasing = true;	

						offsetX -= 165;
					}
					else
					{
						frames = Paths.getSparrowAtlas('notes/NOTE_fire');
						if(!FlxG.save.data.downscroll){
							animation.addByPrefix('blueScroll', 'blue fire');
							animation.addByPrefix('greenScroll', 'green fire');
						}
						else{
							animation.addByPrefix('greenScroll', 'blue fire');
							animation.addByPrefix('blueScroll', 'green fire');
						}
						animation.addByPrefix('redScroll', 'red fire');
						animation.addByPrefix('purpleScroll', 'purple fire');
	
						if((FlxG.save.data.downscroll || downscroll))
							flipY = true;
	
						offsetX -= 40;
	
						setGraphicSize(Std.int(width * noteScale));
						updateHitbox();
						antialiasing = true;	
					}	
				}	
			case 5:
				if (noteTypeStyle == 'neonNote')
				{
					loadGraphic(Paths.image('notes/exeNotes-neon'), true, 17, 17);
					
					animation.add('greenScroll', [6]);
					animation.add('redScroll', [7]);
					animation.add('blueScroll', [5]);
					animation.add('purpleScroll', [4]);

					setGraphicSize(Std.int(width * PlayState.daPixelZoom));
					updateHitbox();
					antialiasing = false;
				}
				else
				{
					if (PlayState.SONG.noteStyle == '1930' || PlayState.SONG.noteStyle == 'bw')
					{
						frames = Paths.getSparrowAtlas('notes/staticNotes1930');
						blackStatic = true;
					}
					else
						frames = Paths.getSparrowAtlas('notes/staticNotes');
	
					animation.addByPrefix('greenScroll', 'green static');
					animation.addByPrefix('redScroll', 'red static');
					animation.addByPrefix('blueScroll', 'blue static');
					animation.addByPrefix('purpleScroll', 'purple static');
	
					setGraphicSize(Std.int(width * 0.7));
					
					updateHitbox();
					antialiasing = true;

					offsetX -= 2;
				}
			case 6:
				if (PlayState.SONG.player2 == 'whittyCrazy')
				{
					loadGraphic(Paths.image('notes/bombNote'), true, 222, 152);

					animation.add('greenScroll', [0]);
					animation.add('redScroll', [0]);
					animation.add('blueScroll', [0]);
					animation.add('purpleScroll', [0]);
	
					setGraphicSize(Std.int(width * noteScale));
					updateHitbox();
					antialiasing = true;

					offsetX -= 43;
				}
				else
				{	
					suf = "";		
					if (mickeyNotes) suf = '_mickey';
					
					frames = Paths.getSparrowAtlas('notes/HURTNOTE_assets'+suf);

					animation.addByPrefix('greenScroll', 'green0');
					animation.addByPrefix('redScroll', 'red0');
					animation.addByPrefix('blueScroll', 'blue0');
					animation.addByPrefix('purpleScroll', 'purple0');

					animation.addByPrefix('purpleholdend', 'pruple end hold');
					animation.addByPrefix('greenholdend', 'green hold end');
					animation.addByPrefix('redholdend', 'red hold end');
					animation.addByPrefix('blueholdend', 'blue hold end');

					animation.addByPrefix('purplehold', 'purple hold piece');
					animation.addByPrefix('greenhold', 'green hold piece');
					animation.addByPrefix('redhold', 'red hold piece');
					animation.addByPrefix('bluehold', 'blue hold piece');

					setGraphicSize(Std.int(width * 0.7));
					updateHitbox();
					antialiasing = true;
				}
			
			case 7:
				frames = Paths.getSparrowAtlas('notes/NOTE_rushia');

				animation.addByPrefix('greenScroll', 'green alone0');
				animation.addByPrefix('redScroll', 'red alone0');
				animation.addByPrefix('blueScroll', 'blue alone0');
				animation.addByPrefix('purpleScroll', 'purple alone0');

				animation.addByPrefix('purpleholdend', 'purple tail');
				animation.addByPrefix('greenholdend', 'green tail');
				animation.addByPrefix('redholdend', 'red tail');
				animation.addByPrefix('blueholdend', 'blue tail');

				animation.addByPrefix('purplehold', 'purple hold');
				animation.addByPrefix('greenhold', 'green hold');
				animation.addByPrefix('redhold', 'red hold');
				animation.addByPrefix('bluehold', 'blue hold');

				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				antialiasing = true;
			case 8:
				frames = Paths.getSparrowAtlas('notes/NOTE_haato');

				animation.addByPrefix('greenScroll', 'green alone0');
				animation.addByPrefix('redScroll', 'red alone0');
				animation.addByPrefix('blueScroll', 'blue alone0');
				animation.addByPrefix('purpleScroll', 'purple alone0');

				animation.addByPrefix('purpleholdend', 'purple tail');
				animation.addByPrefix('greenholdend', 'green tail');
				animation.addByPrefix('redholdend', 'red tail');
				animation.addByPrefix('blueholdend', 'blue tail');

				animation.addByPrefix('purplehold', 'purple hold');
				animation.addByPrefix('greenhold', 'green hold');
				animation.addByPrefix('redhold', 'red hold');
				animation.addByPrefix('bluehold', 'blue hold');

				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				antialiasing = true;
			case 9:
				loadGraphic(Paths.image('notes/scytheNotes'), true, 150, 150);

				animation.add('greenScroll', [2]);
				animation.add('redScroll', [1]);
				animation.add('blueScroll', [3]);
				animation.add('purpleScroll', [0]);

				setGraphicSize(Std.int(width * noteScale));
				updateHitbox();
				antialiasing = true;	
			case 10:
				if (noteTypeStyle == 'neonNote')
				{
					loadGraphic(Paths.image('notes/exeNotes-neon'), true, 17, 17);
					
					animation.add('greenScroll', [2]);
					animation.add('redScroll', [3]);
					animation.add('blueScroll', [1]);
					animation.add('purpleScroll', [0]);

					setGraphicSize(Std.int(width * PlayState.daPixelZoom));
					updateHitbox();
					antialiasing = false;
				}
				else
				{
					frames = Paths.getSparrowAtlas('notes/PhantomNote');
					animation.addByPrefix('greenScroll', 'green withered');
					animation.addByPrefix('redScroll', 'red withered');
					animation.addByPrefix('blueScroll', 'blue withered');
					animation.addByPrefix('purpleScroll', 'purple withered');
	
					setGraphicSize(Std.int(width * 0.7));
						
					updateHitbox();
					antialiasing = true;
				}
			
		}*/

		if (burning && !pixelBurn && PlayState.curStage != 'auditorHell' && !isAuditorNote || bomb)
			setGraphicSize(Std.int(width * 0.86));
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
			updateHitbox();

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
			updateHitbox();
			antialiasing = true;
		}
	}
}