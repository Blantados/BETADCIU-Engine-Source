package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

#if desktop
import sys.io.File;
import sys.FileSystem;
#end

class NoteSplash extends FlxSprite
{
	private var idleAnim:String;
	private var textureLoaded:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);

		var skin:String = '';

		if (Paths.currentModDirectory == 'BETADCIU' || FileSystem.exists(Paths.modsImages("notes/noteSplashes-" + PlayState.instance.bfStrumStyle)))
			skin = '-'+ PlayState.instance.bfStrumStyle;
		else if (FileSystem.exists(Paths.modsImages("noteSplashes-" + PlayState.instance.bfStrumStyle)))
			skin = '-'+ PlayState.instance.bfStrumStyle;
		else
			skin = PlayState.instance.splashSkin;

		if (skin == 'normal' || skin == 'default') skin = "";

		loadAnims(skin);

		setupNoteSplash(x, y, note);
			
		antialiasing = true;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		if (texture == '-holofunk')
		{
			switch (note)
			{
				case 0:
					this.x += 30;
				// offset.set(-20, 0);
				case 1:
					this.y += 30;
				// offset.set(0, -20);
				case 2:
					this.y += 30;
				// offset.set(0, -20);
				case 3:
					this.x += 30;
					// offset.set(-20, 0);
			}
			alpha = 0.75;
			scale.set(1.2, 1.2);
		}
		else
		{
			alpha = 0.6;
			scale.set(1, 1);
			offset.set(0, 0);
		}
		

		if(texture == null) {
			texture = "";
		}
		else 
		{
			if (Paths.currentModDirectory == 'BETADCIU' || FileSystem.exists(Paths.modsImages("notes/noteSplashes-" + PlayState.instance.bfStrumStyle)))
				texture = '-'+ PlayState.instance.bfStrumStyle;
			else if (FileSystem.exists(Paths.modsImages("noteSplashes-" + PlayState.instance.bfStrumStyle)))
				texture = '-'+ PlayState.instance.bfStrumStyle;
			else
				texture = PlayState.instance.splashSkin;
		}

		if(textureLoaded != texture) {
			loadAnims(texture);
		}

		if (texture == '-fever')
		{
			scale.set(1.08, 1.08);
			if(note == 0 || note == 3)
				offset.set((0.291 * this.width) - 150, (0.315 * this.height) - 150);
			else
				offset.set((0.33 * this.width) - 150, (0.315 * this.height) - 150);
		}


		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + note + '-' + animNum, true);
		animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	function loadAnims(skin:String) {

		var rawPic:Dynamic;
		var rawXml:String = "";
		var daPath:String = "noteSplashes" + skin;
		var oops:Bool = false;

		if (Paths.currentModDirectory == 'BETADCIU' || FileSystem.exists(Paths.modsImages("notes/noteSplashes" + skin)))
			daPath = "notes/noteSplashes" + skin;

		if (FileSystem.exists(Paths.modsImages(daPath)))
			rawXml = File.getContent(Paths.modsXml(daPath));
		else if (FileSystem.exists(FileSystem.absolutePath("assets/shared/images/"+daPath+".xml")))
			rawXml = File.getContent(FileSystem.absolutePath("assets/shared/images/"+daPath+".xml"));
		else if (FileSystem.exists(Paths.image(daPath)))
			rawXml = File.getContent(Paths.xmlNew('images/' + daPath));
		else
		{
			frames = Paths.getSparrowAtlas("notes/noteSplashes");
			oops = true;
		}

		if (!Paths.currentTrackedAssets.exists(daPath) && !oops)
			Paths.cacheImage(daPath);

		rawPic = Paths.currentTrackedAssets.get(daPath);

		if (!oops)
			frames = FlxAtlasFrames.fromSparrow(rawPic,rawXml);

		if (frames == null)
			frames = Paths.getSparrowAtlas("notes/noteSplashes");

		for (i in 1...3) {
			animation.addByPrefix("note1-" + i, "note impact " + i + " blue", 24, false);
			animation.addByPrefix("note2-" + i, "note impact " + i + " green", 24, false);
			animation.addByPrefix("note0-" + i, "note impact " + i + " purple", 24, false);
			animation.addByPrefix("note3-" + i, "note impact " + i + " red" , 24, false);
		}

		if (animation.getByName('note1-1') == null && animation.getByName('note2-2') == null) //psych notesplashes?
		{
			for (i in 1...3) {
				animation.addByPrefix("note1-" + i, "note splash blue " + i, 24, false);
				animation.addByPrefix("note2-" + i, "note splash green " + i, 24, false);
				animation.addByPrefix("note0-" + i, "note splash purple " + i, 24, false);
				animation.addByPrefix("note3-" + i, "note splash red " + i, 24, false);
			}
		}
	}

	override function update(elapsed:Float) {
		if(animation.curAnim.finished) kill();

		super.update(elapsed);
	}
}