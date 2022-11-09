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

		switch(texture)
		{
			case '-holofunk':
				switch (note)
				{
					case 0: this.x += 30;
					case 1: this.y += 30;
					case 2: this.y += 30;
					case 3: this.x += 30;
				}
				alpha = 0.75;
				scale.set(1.2 * (FlxG.save.data.poltatoPC ? 2 : 1) , 1.2 * (FlxG.save.data.poltatoPC ? 2 : 1));
			case '-fever':
				alpha = 0.6;
				scale.set(1.08 * (FlxG.save.data.poltatoPC ? 2 : 1) , 1.08 * (FlxG.save.data.poltatoPC ? 2 : 1));
				if(note == 0 || note == 3)
					offset.set((0.291 * this.width) - 150, (0.315 * this.height) - 150);
				else
					offset.set((0.33 * this.width) - 150, (0.315 * this.height) - 150);
			default:
				alpha = 0.6;
				scale.set(1 * (FlxG.save.data.poltatoPC ? 2 : 1) , 1 * (FlxG.save.data.poltatoPC ? 2 : 1));
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

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + note + '-' + animNum, true);
		animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	function loadAnims(skin:String) {

		var rawPic:Dynamic;
		var rawXml:String = "";
		var daPath:String = "noteSplashes" + skin;

		if (Paths.currentModDirectory == 'BETADCIU' || FileSystem.exists(Paths.modsImages("notes/noteSplashes" + skin)))
			daPath = "notes/noteSplashes" + skin;

		if (Paths.checkImagePaths(daPath))
			frames = Paths.getSparrowAtlas(daPath);
		else
			frames = Paths.getSparrowAtlas("notes/noteSplashes");
			
		if (FlxG.save.data.polatoPC)
		{
			scale.set(scale.x*2, scale.y*2);
			updateHitbox();
		}

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