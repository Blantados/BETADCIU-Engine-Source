package options;

import flash.text.TextField;
import flixel.addons.display.FlxGridOverlay;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import openfl.Lib;

using StringTools;

class BETADCIUOptionsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'BETADCIU';
		rpcTitle = 'BETADCIU Settings Menu'; //for Discord Rich Presence
		
		var option:Option = new Option('Stage Preloading',
			"HIGHLY Recommended if you have more than 8GB of RAM",
			'stageChange',
			'bool');
		addOption(option);
		
		var option:Option = new Option('Uncache Characters',
			"Uncache characters when they switch out. Reduces memory usage as you play the song but might lag a bit.",
			'uncacheCharacterSwitch',
			'bool');
		addOption(option);
		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	override function destroy()
	{
		if(changedMusic) FlxG.sound.playMusic(Paths.music('newMenu'));
		super.destroy();
	}
}