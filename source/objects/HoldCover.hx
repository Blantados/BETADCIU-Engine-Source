package objects;

import openfl.Assets;
import flixel.FlxSprite;
import objects.Note;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxTimer;
import states.PlayState;

using StringTools;

//Most of the Original code from Mr.Bruh (mr.bruh69)
//Ported to haxe and edited by glowsoony // thanks man!

class CoverSprite extends FlxSprite
{
	public var boom:Bool = false;
	public var isPlaying:Bool = false;
	public var activatedSprite:Bool = true;
	public var useRGBShader:Bool = false;

	public var spriteId:String = "";
	public var texture(default, set):String = null;

	public var hColor:String = "";
	public var noteIndex:Int = 0;

	private function set_texture(value:String):String {
		if(texture != value) {
			value = reloadCover(value);
		}
		return value;
	}

	public function reloadCover(newTexture:String = '', postfix:String = '') {
		initFrames(noteIndex, hColor, newTexture);
		initAnimations(noteIndex, hColor);

		return newTexture;
	}

	public function initFrames(i:Int, hColor:String, skin:String = "")
	{
		this.hColor = hColor;
		this.noteIndex = i;

		trace("SKIN IS " + skin);
		if (Paths.fileExists('images/holdCovers/$skin/holdCover$hColor.png', IMAGE)){
			this.frames = Paths.getSparrowAtlas(skin.length > 0 ? 
				'holdCovers/$skin/holdCover$hColor' : 
				'holdCovers/holdCover$hColor');
		}
		else{
			this.frames = Paths.getSparrowAtlas('holdCovers/holdCover$hColor');
		}	
	}

	public function initAnimations(i:Int, hColor:String)
	{
		this.animation.addByPrefix(Std.string(i), 'holdCover$hColor', 24, true);
		this.animation.addByPrefix(Std.string(i) + 'p', 'holdCoverEnd$hColor', 24, false);
	}

	public function smoothSprite()
	{
		this.antialiasing = ClientPrefs.data.antialiasing;
		if (texture.contains('pixel') || !ClientPrefs.data.antialiasing)
			this.antialiasing = false;
	}
}

class HoldCover extends FlxTypedSpriteGroup<CoverSprite>
{
	public var enabled:Bool = true;
	public var isPlayer:Bool = false;

	public function new(enabled:Bool, isPlayer:Bool)
	{
		this.enabled = enabled;
		this.isPlayer = isPlayer;
		super(0, 0, 4);
		for (i in 0...maxSize)
			addHolds(i);
	}

	public function addHolds(i:Int)
	{
		var colors:Array<String> = ["Purple", "Blue", "Green", "Red", "Purple", "Blue", "Green", "Red"];
		var hColor:String = colors[i];
		var hold:CoverSprite = new CoverSprite();
		hold.initFrames(i, hColor);
		hold.initAnimations(i, hColor);
		hold.boom = false;
		hold.isPlaying = false;
		hold.visible = false;
		hold.activatedSprite = enabled;
		hold.spriteId = '$hColor-$i';
		this.add(hold);
	}

	public function spawnOnNoteHit(note:Note, isReady:Bool):Void
	{
		if (note == null) return;
		var noteData:Int = note.noteData;
		var isSus:Bool = note.isSustainNote;
		var isHoldEnd:Bool = false;
		if (note.animation.curAnim != null) isHoldEnd = note.animation.curAnim.name.endsWith('end');

		if (enabled && isReady)
		{
			var data:Int = noteData;

			if (isSus)
			{
				var coverSprite = this.members[data];

				if (note.texture != null && note.texture.length > 0 && coverSprite.texture != note.texture) {
					coverSprite.texture = note.texture;
				}

				coverSprite.smoothSprite();
				
			

				if (isHoldEnd)
				{
					if (isPlayer)
					{
						coverSprite.isPlaying = false;
						coverSprite.boom = true;
						coverSprite.animation.play(Std.string(data) + 'p');
					}
					else
					{
						coverSprite.isPlaying = false;
						coverSprite.boom = false;
						hideHoldCoverLater(data, 0.075);
					}
				}
				else
				{
					if (coverSprite.isPlaying == false)
					{
						if (coverSprite.boom == false){
							coverSprite.visible = true;
						}
							
						coverSprite.animation.play(Std.string(data));
						coverSprite.isPlaying = false;
					}
				}
			}
		}
	}

	public function despawnOnMiss(isReady:Bool, direciton:Int, ?note:Note = null):Void
	{
		var noteData:Int = (note != null ? note.noteData : direciton);
		if (enabled && isReady)
		{
			var data:Int = noteData;
			this.members[data].smoothSprite();
			this.members[data].isPlaying = false;
			this.members[data].boom = false;
			this.members[data].visible = false;
			this.members[data].animation.stop();
		}
	}

	private function hideHoldCoverLater(data:Int, delay:Float):Void
	{
		var timer:FlxTimer = new FlxTimer();
		var tag:String = "hideHoldCoverFromStrum" + data;
		PlayState.instance.variables.set(tag, timer.start(delay, function(timer:FlxTimer)
		{
		this.members[data].visible = false;
		PlayState.instance.variables.remove(tag);
		}));
	}

	public function updateHold(elapsed:Float, isReady:Bool):Void
	{
		if (enabled && isReady)
		{
			for (i in 0...this.members.length)
			{
			if (this.members[i].x != ni(i, "x") - 110)
			{
				this.members[i].x = ni(i, "x") - 110;
			}
			if (this.members[i].y != ni(i, "y") - 100)
			{
				this.members[i].y = ni(i, "y") - 100;
			}
			if (this.members[i].alpha != ni(i, "alpha"))
			{
				this.members[i].alpha = ni(i, "alpha");
			}

			if (this.members[i].boom == true)
			{
				if (this.members[i].animation.curAnim.finished)
				{
				this.members[i].visible = false;
				this.members[i].boom = false;
				}
			}
			}
		}
  	}

	function ni(note, info):Float
	{
		if (enabled && PlayState.instance != null && !PlayState.instance.inCutscene)
		{
		var game:PlayState = PlayState.instance;
		if (game == null) return 110;
		else
		{
			if (game.strumLineNotes != null)
			{
				if (info == "x") return game.strumLineNotes.members[isPlayer ? note + 4 : note].x;
				else if (info == "y") return game.strumLineNotes.members[isPlayer ? note + 4 : note].y;
				else if (info == "alpha") return game.strumLineNotes.members[isPlayer ? note + 4 : note].alpha;
			}
			return 0;
		}
		}
		return 0;
	}
}
