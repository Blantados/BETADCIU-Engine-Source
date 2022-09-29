package;

import LuaClass.LuaReceptor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import sys.io.File;
import sys.FileSystem;

using StringTools;	

class StrumNote extends FlxSprite
{
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var isMania:Bool = false;
	public var mania:Int = 0;
	public var daStyle = 'style';
	public var pixelNotes:Array<String> = ['pixel', 'neon', 'pixel-corrupted', 'pixel-combined', 'guitar']; //guitar notes also have zero offsets
	
	private var player:Int;

	public var luaObject:LuaReceptor;
	public var modifiedByLua:Bool = false;
	public var modAngle:Float = 0; // The angle set by modcharts
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		reloadNote(value);
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int, style:String) {
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.daStyle = style;
		super(x, y);

		scrollFactor.set();
		isMania = (PlayState.SONG.mania > 0);
		mania = PlayState.SONG.mania;

		loadNoteAnims(style, true);
	}

	public function reloadNote(style:String)
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		PlayState.instance.bfStrumStyle = style;

		loadNoteAnims(style);
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function loadNoteAnims(style:String, ?first:Bool = false)
	{
		daStyle = style;
		
		var suf:String = "";
		
		switch (style)
		{
			case 'pixel':// | 'pixel-corrupted' | 'neon' | 'doki-pixel':
				switch (style)
				{
					case 'pixel-corrupted':
						suf = '-corrupted';
					case 'neon':
						suf = '-neon';
					case 'doki-pixel':
						suf = '-doki';
				}

				loadGraphic(Paths.image('notes/arrows-pixels'+suf), true, 17, 17);
				
				animation.add('green', [6]);
				animation.add('red', [7]);
				animation.add('blue', [5]);
				animation.add('purplel', [4]);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				antialiasing = false;
				
				animation.add('static', [0 + noteData]);
				animation.add('pressed', [4 + noteData, 8 + noteData], 12, false);
				animation.add('confirm', [12 + noteData, 16 + noteData], 24, false);
				
			case 'noStrums':
				loadGraphic(Paths.image('notes/noStrums'), true, 17, 17);
				animation.add('green', [0]);
				animation.add('red', [0]);
				animation.add('blue', [0]);
				animation.add('purple', [0]);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				antialiasing = false;

				
				animation.add('static', [0]);
				animation.add('pressed', [0], 12, false);
				animation.add('confirm', [0], 24, false);

			/*case 'pixel-combined':
				loadGraphic(Paths.image('notes/arrows-pixelscombined'), true, 17, 17);
				animation.add('green', [6]);
				animation.add('red', [7]);
				animation.add('blue', [5]);
				animation.add('purplel', [4]);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				antialiasing = false;

				animation.add('static', [0 + noteData]);
				animation.add('pressed', [4 + noteData, 8 + noteData], 12, false);
				animation.add('confirm', [12 + noteData, 16 + noteData], 24, false);

			case 'guitar':
				frames = Paths.getSparrowAtlas('notes/GH_NOTES');

				antialiasing = true;

				var pPre:Array<String> = ['left', 'down', 'up', 'right'];

				animation.addByPrefix('static', pPre[noteData] + 'NoteBaby');
				animation.addByPrefix('pressed', pPre[noteData] + ' press', 24, false);
				animation.addByPrefix('confirm', pPre[noteData] + ' confirm', 24, false);*/
				
			default:
				if (Assets.exists(Paths.image('notes/'+style)))
				{
					frames = Paths.getSparrowAtlas('notes/'+style);
	
					if (frames == null)
					{
						if (isMania)
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
							loadGraphic(rawPic, true, 17, 17);
							addAnims(true);
						}
						else
						{
							var rawXml = File.getContent(Paths.modsXml(style));
						
							frames = FlxAtlasFrames.fromSparrow(rawPic, rawXml);
							addAnims();
						}
					}

					if (frames == null)
					{
						if (isMania)
							frames = Paths.getSparrowAtlas('notes/shaggyNotes');
						else
							frames = Paths.getSparrowAtlas('notes/NOTE_assets');

						addAnims();
					}
				}
		}

		if (first)
			updateHitbox();
	}

	public function addAnims(?pixel:Bool = false)
	{
		if (pixel)
		{
			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			antialiasing = false;
			
			animation.add('static', [0 + noteData]);
			animation.add('pressed', [4 + noteData, 8 + noteData], 12, false);
			animation.add('confirm', [12 + noteData, 16 + noteData], 24, false);
		}
		else
		{
			antialiasing = true;
			setGraphicSize(Std.int(width * Note.noteScale));
	
			var nSuf:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
			var pPre:Array<String> = ['left', 'down', 'up', 'right'];
			switch (mania)
			{
				case 1:
					nSuf = ['LEFT', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'RIGHT'];
					pPre = ['left', 'up', 'right', 'yel', 'down', 'dark'];
				case 2:
					nSuf = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'SPACE', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
					pPre = ['left', 'down', 'up', 'right', 'white', 'yel', 'violet', 'black', 'dark'];
					x -= Note.tooMuch;
	
					if (PlayState.SONG.song.toLowerCase() == 'bonedoggle')
						pPre = ['left', 'down', 'up', 'right', 'white', 'left', 'down', 'up', 'right'];
				case 3:
					nSuf = ['LEFT', 'DOWN', 'SPACE', 'UP', 'RIGHT'];
					pPre = ['left', 'down', 'white', 'up', 'right'];
				case 4:
					nSuf = ['LEFT', 'UP', 'RIGHT', 'SPACE', 'LEFT', 'DOWN', 'RIGHT'];
					pPre = ['left', 'up', 'right', 'white', 'yel', 'down', 'dark'];
			}
			
			animation.addByPrefix('static', 'arrow' + nSuf[noteData]);
			animation.addByPrefix('pressed', pPre[noteData] + ' press', 24, false);
			animation.addByPrefix('confirm', pPre[noteData] + ' confirm', 24, false);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float) {

		if (modifiedByLua)
			angle = modAngle;

		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		//if(animation.curAnim != null){ //my bad i was upset
		if(animation.curAnim.name == 'confirm' && !pixelNotes.contains(daStyle)) {
			centerOrigin();
		//}
		}	

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if(animation.curAnim == null || animation.curAnim.name == 'static') 
		{
		
		} 
		else 
		{
			if(animation.curAnim.name == 'confirm' && !pixelNotes.contains(daStyle))
				centerOrigin();
		}
	}
}
