package options;

import states.MainMenuState;

import flash.text.TextField;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxBackdrop;

using StringTools;

class OptionsState extends MusicBeatState
{
	#if debug
	var options:Array<String> = ['BETADCIU', 'Controls', 'Graphics', 'Visuals and UI', 'Gameplay',"Legacy Options Menu", "Modpack Maker"];
	#else
	var options:Array<String> = ['BETADCIU', 'Controls', 'Graphics', 'Visuals and UI', 'Gameplay'];
	#end
	
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	
	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'BETADCIU':
				openSubState(new options.BETADCIUOptionsSubState());
				// trace('in BETADCIU Options menu');
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new KeyBindMenu());
			case 'Replays':
				MusicBeatState.switchState(new states.LoadReplayState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new options.NoteOffsetState());
			case 'Legacy Options Menu':
				MusicBeatState.switchState(new options.OptionsMenuKade());
			// #if debug
			case 'Modpack Maker':
				LoadingState.loadAndSwitchState(new states.editors.ModpackMaker());
			// #end
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var titlestatebg:FlxBackdrop;
		
		titlestatebg = new FlxBackdrop(Paths.image('titleGrid'), XY);
		titlestatebg.velocity.set(200, 110);
		titlestatebg.updateHitbox();
		titlestatebg.alpha = 0.5;
		titlestatebg.screenCenter(X);
		add(titlestatebg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		if (FlxG.sound.music.volume == 0 || !FlxG.sound.music.playing)
			{
				FlxG.sound.music.volume = 1;
				FlxG.sound.playMusic(Paths.music('songSelect'));
			}
	
			if (FlxG.sound.music.playing || MainMenuState.mainMusic)
			{
				FlxG.sound.playMusic(Paths.music('songSelect'));
				MainMenuState.mainMusic = false;
			}
			if (!FlxG.sound.music.playing || MainMenuState.mainMusic == false)
			{
				FlxG.sound.playMusic(Paths.music('songSelect'));
				MainMenuState.mainMusic = false;
			}	

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UP_P) {
			changeSelection(-1);
		}
		if (controls.DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new states.MainMenuState());
		}

		if (controls.ACCEPT) {
			openSelectedSubstate(options[curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}