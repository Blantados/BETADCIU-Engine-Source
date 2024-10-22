package objects;

import luafiles.LuaClass.LuaReceptor;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;

import shaders.ColorSwap;

import haxe.Json;
import haxe.format.JsonParser;

using StringTools;	

typedef StrumNoteFile = {
	var strumAnimations:Array<Note.NoteAnimArray>;
	var strumOffset:Array<Float>;
}

class StrumNote extends FunkinSprite
{
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var isMania:Bool = false;
	public var mania:Int = 0;
	public var daStyle = "style";
	public var sustainReduce:Bool = true;
	public var strumOffset:Array<Float> = [0, 0];
	
	private var player:Int;

	public var luaObject:LuaReceptor;
	public var modifiedByLua:Bool = false;
	public var modAngle:Float = 0; // The angle set by modcharts
	public var separateSheets:Bool = false;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) reloadNote(value);

		texture = value;
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
		separateSheets = false;
		
		for (key in animOffsets.keys()) {
			animOffsets.remove(key);
		}

		var suf:String = "";
		
		switch (style)
		{
			case "pixel":// | "pixel-corrupted" | "neon" | "doki-pixel":
				loadGraphic(Paths.image("notes/arrows-pixels"+suf), true, 17, 17);
				
				animation.add("green", [6]);
				animation.add("red", [7]);
				animation.add("blue", [5]);
				animation.add("purplel", [4]);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				antialiasing = false;
				
				animation.add("static", [0 + noteData]);
				animation.add("pressed", [4 + noteData, 8 + noteData], 12, false);
				animation.add("confirm", [12 + noteData, 16 + noteData], 24, false);
				
			case "noStrums":
				loadGraphic(Paths.image("notes/noStrums"), true, 17, 17);
				animation.add("green", [0]);
				animation.add("red", [0]);
				animation.add("blue", [0]);
				animation.add("purple", [0]);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				antialiasing = false;

				
				animation.add("static", [0]);
				animation.add("pressed", [0], 12, false);
				animation.add("confirm", [0], 24, false);

			/*case "pixel-combined":
				loadGraphic(Paths.image("notes/arrows-pixelscombined"), true, 17, 17);
				animation.add("green", [6]);
				animation.add("red", [7]);
				animation.add("blue", [5]);
				animation.add("purplel", [4]);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				antialiasing = false;

				animation.add("static", [0 + noteData]);
				animation.add("pressed", [4 + noteData, 8 + noteData], 12, false);
				animation.add("confirm", [12 + noteData, 16 + noteData], 24, false);

			case "guitar":
				frames = Paths.getSparrowAtlas("notes/GH_NOTES");

				antialiasing = true;

				var pPre:Array<String> = ["left", "down", "up", "right"];

				animation.addByPrefix("static", pPre[noteData] + "NoteBaby");
				animation.addByPrefix("pressed", pPre[noteData] + " press", 24, false);
				animation.addByPrefix("confirm", pPre[noteData] + " confirm", 24, false);*/
				
			default:
				var separateStrumPath = Paths.image("notes/" + daStyle + "/notes_strumline");
			
				if (Assets.exists(separateStrumPath) || FileSystem.exists(separateStrumPath)){
					style = "notes/" + daStyle + "/notes_strumline";
					separateSheets = true;

					var strumJsonPath = Paths.jsonNew("images/notes/" + daStyle + "/" + daStyle);

					if (Assets.exists(strumJsonPath) || FileSystem.exists(strumJsonPath)){
						var rawJson:Dynamic = (FileSystem.exists(strumJsonPath) ? File.getContent(strumJsonPath) : Assets.getText(strumJsonPath));
						var json:StrumNoteFile = cast Json.parse(rawJson);
						
						var animationsArray = json.strumAnimations;

						if(animationsArray != null && animationsArray.length > 0) {
							for (anim in animationsArray) {
								addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
							}
						}
						/*var jsonStrumOffset = json.strumOffset;
						strumOffset = (jsonStrumOffset != null, jsonStrumOffset : [0, 0]);*/
					}
				}

				var defaultStrumPath = Paths.image("notes/"+style);

				if (Assets.exists(defaultStrumPath) || FileSystem.exists(defaultStrumPath)){
					style = "notes/" + style;
				}
					
				var stylePath = Paths.image(style);

				if (Assets.exists(stylePath) || FileSystem.exists(stylePath))
				{					
					if (!Paths.currentTrackedAssets.exists(style)){
						Paths.cacheImage(style);
					}
				
					var rawPic:Dynamic = Paths.currentTrackedAssets.get(style);
					var xmlPath:String = Paths.xmlNew('images/' + style);
					
					if (!Assets.exists(xmlPath) && !FileSystem.exists(xmlPath))
					{
						loadGraphic(rawPic);

						width = width / 4;
						height = height / 5;

						loadGraphic(rawPic, true, Math.floor(width), Math.floor(height));
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
					if (isMania)
						frames = Paths.getSparrowAtlas("notes/shaggyNotes");
					else{
						if (Assets.exists(Paths.image("notes/normal/notes_strumline"))){
							separateSheets = true;
							frames = Paths.getSparrowAtlas("notes/normal/notes_strumline");
						}
						else{
							frames = Paths.getSparrowAtlas(mania > 0 ? "notes/shaggyNotes" : "notes/NOTE_assets");
						}
					}

					addAnims();
				}
		}

		if (FlxG.save.data.poltatoPC)
		{
			scale.set(scale.x*2, scale.y*2);
			updateHitbox();
		}

		if (first){
			updateHitbox();
		}
			
	}

	public var isPixel:Bool = false;

	public function addAnims(?pixel:Bool = false)
	{	
		if (pixel)
		{
			isPixel = true;

			animation.add("green", [6]);
			animation.add("red", [7]);
			animation.add("blue", [5]);
			animation.add("purple", [4]);

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			antialiasing = false;
			
			animation.add("static", [0 + noteData]);
			animation.add("pressed", [4 + noteData, 8 + noteData], 12, false);
			animation.add("confirm", [12 + noteData, 16 + noteData], 24, false);
		}
		else
		{
			isPixel = false;

			antialiasing = true;
			setGraphicSize(Std.int(width * Note.noteScale));
	
			if (separateSheets){
				var dirArr:Array<String> = ["Left", "Down", "Up", "Right"];

				animation.addByPrefix("static", "static" + dirArr[noteData]);
				animation.addByPrefix("pressed", "press" + dirArr[noteData], 24, false);
				animation.addByPrefix("confirm", "confirm" + dirArr[noteData], 24, false);
			}
			else{	
				var nSuf:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];
				var pPre:Array<String> = ["left", "down", "up", "right"];

				switch (mania)
				{
					case 1:
						nSuf = ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"];
						pPre = ["left", "up", "right", "yel", "down", "dark"];
					case 2:
						nSuf = ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "UP", "RIGHT"];
						pPre = ["left", "down", "up", "right", "white", "yel", "violet", "black", "dark"];
						x -= Note.tooMuch;
					case 3:
						nSuf = ["LEFT", "DOWN", "SPACE", "UP", "RIGHT"];
						pPre = ["left", "down", "white", "up", "right"];
					case 4:
						nSuf = ["LEFT", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "RIGHT"];
						pPre = ["left", "up", "right", "white", "yel", "down", "dark"];
				}
				
				animation.addByPrefix("static", "arrow" + nSuf[noteData]);
				animation.addByPrefix("pressed", pPre[noteData] + " press", 24, false);
				animation.addByPrefix("confirm", pPre[noteData] + " confirm", 24, false);
			}
		}
	}

	public function postAddedToGroup() {
		playAnim("static");
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
				playAnim("static");
				resetAnim = 0;
			}
		}
		//if(animation.curAnim != null){ //my bad i was upset
		if(animation.curAnim.name == "confirm" && !isPixel) {
			centerOrigin();
		//}
		}	

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		
		if(animation.curAnim.name == "confirm" && !isPixel){
			centerOrigin();
		}

		if (separateSheets && !isPixel){
			offset.x += 32;
			offset.y += 20;
		}

		var daOffsets = getAnimOffset(anim);
		
		offset.x += daOffsets[0];
		offset.y += daOffsets[1];
	}
}
