package states;

import haxe.Json;
import haxe.Http;
import sys.FileSystem;
import sys.io.File;
import openfl.display.Loader;
import openfl.display.Bitmap;
import openfl.events.Event;
import openfl.net.URLRequest;

class OnlineModpackState extends MusicBeatState
{
	var modpacks:Array<Dynamic> = [];
	var grpModpacks:FlxTypedGroup<ModpackListItem>;
	var curSelected:Int = 0;
	var loadingText:FlxText;
	var isDownloading:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF504E00;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpModpacks = new FlxTypedGroup<ModpackListItem>();
		add(grpModpacks);

		loadingText = new FlxText(0, 0, FlxG.width, "Loading Modpacks...", 32);
		loadingText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		loadingText.screenCenter();
		add(loadingText);

		fetchModpacks();

		super.create();
	}

	function fetchModpacks()
	{
		var url = "https://raw.githubusercontent.com/icaroleeb/BETADCIU-Engine-Modpacks/refs/heads/main/modpacks.json";
		var http = new Http(url);
		http.onData = function(data:String) {
			try {
				modpacks = cast Json.parse(data);
				if (modpacks.length > 0) {
					loadingText.visible = false;
					regenerateList();
				} else {
					loadingText.text = "No modpacks found.";
				}
			} catch (e:Dynamic) {
				loadingText.text = "Error parsing modpacks list.";
			}
		}
		http.onError = function(err) {
			loadingText.text = "Failed to connect to the server.";
			FlxTween.tween(loadingText, {alpha: 0}, 0.5, {type: FlxTweenType.PINGPONG});
		}
		http.request();
	}

	function regenerateList()
	{
		grpModpacks.clear();
		for (i in 0...modpacks.length)
		{
			var modFile:String = modpacks[i][0];
			var modAuthor:String = modpacks[i][1];
			
			var modName = modFile.replace(".zip", null).replace("_", " ");

			var item = new ModpackListItem(0, 0, modName, modAuthor);
			item.targetY = i;
			grpModpacks.add(item);
		}
		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isDownloading) return;

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);
		if (controls.BACK) MusicBeatState.switchState(new ModsMenuState());

		if (controls.ACCEPT && modpacks.length > 0)
		{
			downloadModpack(modpacks[curSelected][0]);
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0) curSelected = modpacks.length - 1;
		if (curSelected >= modpacks.length) curSelected = 0;

		var bullShit:Int = 0;
		for (item in grpModpacks.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) item.alpha = 1;
		}
		FunkinSound.playOnce('scrollMenu');
	}

	function downloadModpack(zipName:String)
	{
		isDownloading = true;
		loadingText.text = "Downloading " + zipName + "...";
		loadingText.visible = true;
		loadingText.alpha = 0;
		FlxTween.tween(loadingText, {alpha: 1}, 0.1);

		var zipUrl = "https://github.com/Blantados/BETADCIU-Engine-Modpacks/releases/download/v1.0/" + zipName;
		var localZipPath = Paths.mods() + "tmp_download.zip";
		sys.thread.Thread.create(function() {
			var cmd = 'curl -L -A "Mozilla/5.0" -o "${localZipPath}" "${zipUrl}"';
			var result = Sys.command(cmd);
			
			if (result == 0) {
				try {
					CoolUtil.unzip(localZipPath, Paths.mods());
					FileSystem.deleteFile(localZipPath);
					
					loadingText.text = "Download Complete!";
					FunkinSound.playOnce('confirmMenu');
					
					haxe.Timer.delay(function() {
						isDownloading = false;
						FlxTween.tween(loadingText, {alpha: 0}, 0.5, {
							onComplete: (_) -> loadingText.visible = false
						});
					}, 2000);
				} catch (e:Dynamic) {
					loadingText.text = "Error extracting: " + e;
					isDownloading = false;
				}
			} else {
				loadingText.text = "Download failed (curl error " + result + ")";
				isDownloading = false;
			}
		});
	}
}

class ModpackListItem extends FlxSpriteGroup {
	public var alphabet:Alphabet;
	public var icon:ProfileYoutube;
	public var targetY:Float = 0;

	public function new(x:Float, y:Float, text:String, youtubeUser:String) {
		super(x, y);

		alphabet = new Alphabet(0, 320, text, true);
		alphabet.setScale(0.8, 0.8);
		add(alphabet);

		icon = new ProfileYoutube(youtubeUser);
		add(icon);
	}

	override function update(elapsed:Float) {
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		
		y = FlxMath.lerp(y, (targetY * 130) + 0, lerpVal);
		x = FlxMath.lerp(x, (targetY * 0) + 50, lerpVal);

		icon.x = alphabet.x + alphabet.width + 30; 
		icon.y = alphabet.y + (alphabet.height / 2) - (icon.height / 2);

		super.update(elapsed);
	}
}

class ProfileYoutube extends FlxSprite {
	public function new(username:String) 
	{
		super();
		// makeGraphic(1, 1, FlxColor.TRANSPARENT); 
		createProfile(username);
	}

	function createProfile(username:String)
	{
		var url = "https://unavatar.io/youtube/" + username;

		loadImageFromUrl(url);
	}

	function loadImageFromUrl(url:String) {
		var loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event) {
			var bitmapData = cast(loader.content, Bitmap).bitmapData;
			loadGraphic(bitmapData);
			antialiasing = ClientPrefs.data.antialiasing; 
			setGraphicSize(100, 100);
			updateHitbox();
		});
		
		loader.load(new URLRequest(url));
	}
}