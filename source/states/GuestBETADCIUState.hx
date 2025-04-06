package states;

import flash.text.TextField;
import flixel.addons.display.FlxGridOverlay;
import lime.utils.Assets;
import flixel.effects.FlxFlicker;
import states.editors.ChartingState;

import haxe.xml.Access;
import haxe.xml.Fast;

import objects.HealthIcon;

import backend.WeekData;
import backend.Song;

using StringTools;

class GuestBETADCIUState extends MusicBeatState
{
	var songs:Array<SongMetadata2> = [];

	var selector:FlxText;
	public static var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var comboText:FlxText;
	var text2:FlxText;
	var text3:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';
	var canMove:Bool = true;
	public var warning:Bool = false;
	private static var lastDifficultyName:String = '';

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	public static var downscroll:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public var ytIcon:FlxSprite;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		WeekData.reloadWeekFiles(false, 5);

		persistentUpdate = true;

		for (i in 0...WeekData.weeksList.length) {
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];
			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
					colors = [146, 113, 253];

				var textColors:Array<Int> = leWeek.ytInfo[2];
				if(textColors == null || textColors.length < 3)
					textColors = [146, 113, 253];

				addSong(song[0], i, song[1], leWeek.ytInfo[0], leWeek.ytInfo[1], FlxColor.fromRGB(textColors[0], textColors[1], textColors[2]));
			}
		}
		WeekData.setDirectoryFromWeek();

		if (songs.length < 1)
		{
			addSong('Placeholder', 0, 'face', 'Snow The Fox', "https://www.youtube.com/c/SnowTheFox", FlxColor.fromRGB(185, 69, 69));
			warning = true;
			trace('warn em bro!');
		}
		
		FlxG.mouse.visible = true;

		if (FlxG.sound.music.volume == 0 || !FlxG.sound.music.playing)
		{
			FlxG.sound.music.volume = 1;
			FlxG.sound.playMusic(Paths.music('newMenu'));
		}

		 #if desktop
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In Guest BETADCIU Menu", null);
		 #end

		var isDebug:Bool = false;

		canMove = true;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFfd719b;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.isFreeplayItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		comboText = new FlxText(diffText.x + 200, diffText.y, 0, "", 24);
		comboText.font = diffText.font;
		add(comboText);

		add(scoreText);

		ytIcon = new FlxSprite();
		ytIcon.frames = Paths.getSparrowAtlas('extraIcons');
		readXML(File.getContent(Paths.xmlNew('images/extraIcons')));

		if (daNames.length > 0)
		{
			for (i in 0...daNames.length)
				ytIcon.animation.addByPrefix(daNames[i], daNames[i], 0, false);
		}

		ytIcon.setGraphicSize(Std.int(ytIcon.width * 1.2));
		ytIcon.screenCenter();
		ytIcon.x += 350;
		ytIcon.y -= 50;
		add(ytIcon);

		var text1 = new FlxText(0, ytIcon.y + 220, 0, "This BETADCIU was made by:", 32);
		text1.setFormat(Paths.font("Aller_Rg.ttf"), 36, FlxColor.WHITE, CENTER);
		text1.borderColor = FlxColor.BLACK;
		text1.x = ytIcon.x - ((text1.width - ytIcon.width)/2);
		text1.borderSize = 3;
		text1.borderStyle = FlxTextBorderStyle.OUTLINE;
		text1.bold = true;
		add(text1);

		text2 = new FlxText(ytIcon.x - 150, text1.y + 60, 0, "", 36);
		text2.setFormat('Pixel Arial 11 Bold', 36, FlxColor.RED, CENTER);
		text2.borderColor = FlxColor.BLACK;
		text2.borderSize = 3;
		text2.borderStyle = FlxTextBorderStyle.OUTLINE;
		text2.bold = true;
		add(text2);

		text3 = new FlxText(0, text2.y + 65, 0, "Link to their channel!", 40);
		text3.setFormat(Paths.font("Aller_Rg.ttf"), 40, FlxColor.fromString('#FF0078D4'), CENTER);
		text3.borderColor = FlxColor.BLACK;
		text3.borderSize = 3;
		text3.borderStyle = FlxTextBorderStyle.OUTLINE;
		text3.x = ytIcon.x - ((text3.width - ytIcon.width)/2);
		text3.bold = true;
		add(text3);

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");
 
		if (warning)
		{
			var blackScreen = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 1), Std.int(FlxG.height * 0.5), FlxColor.BLACK);
			blackScreen.screenCenter();
			blackScreen.scrollFactor.set();
			blackScreen.alpha = 0.6;
			blackScreen.visible = false;
			add(blackScreen);

			blackScreen.visible = true;
			canMove = false;

			var daText = new FlxText(0, 0, 0, "No BETADCIUs Detected! \n Press enter to return to main menu.", 48);
			daText.setFormat(Paths.font("phantomMuff.ttf"), 48, FlxColor.WHITE, CENTER);
			daText.screenCenter();
			daText.x += 20;
			daText.y -= 100;
			add(daText);

			var daText2 = new FlxText(0, 0, Std.int(FlxG.width * 0.45), "Press enter to return to the main menu.", 44);
			daText2.setFormat(Paths.font("phantomMuff.ttf"), 44, FlxColor.WHITE, CENTER);
			daText2.screenCenter();
			daText2.y += 100;
			add(daText2);
		}

		super.create();
	}

	public function readXML(rawXml:String)
	{
		//i swear this is gonna take me another five hours... wait it only took 10 minutes? neat.
		var daXml:Xml = Xml.parse(rawXml);
		var fast = new haxe.xml.Access(daXml);
		var users = fast.node.TextureAtlas;
		for (SubTexture in users.nodes.SubTexture) {
			var name = Std.string(SubTexture.att.name);
			var nameCut = name.substr(0, name.length - 4);
			daNames.push(nameCut);
		}
	}

	var daNames:Array<String> = [];

	public function addSong(songName:String, weekNum:Int, songCharacter:String, ytName:String, link:String, textColor:Int)
	{
		songs.push(new SongMetadata2(songName, weekNum, songCharacter, ytName, link, textColor));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}*/

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.mouse.overlaps(text3)) //this is like...  way easier than that isOnBtt stuff
		{
			text3.color = 0xFF77BDFF;
			if (FlxG.mouse.justPressed && canMove)
			{
				if (songs[curSelected].link.startsWith('https://www.youtube.com'))
					fancyOpenURL(songs[curSelected].link);
				else
					trace('invalid link');
				
				/*switch (songs[curSelected].songName.toLowerCase(""))
				{
					case 'epiphany' | 'bonedoggle':
						fancyOpenURL("https://www.youtube.com/channel/UCCAE5-m4RfHeVOQq5OY02AQ");
					case "rabbit's-luck":
						fancyOpenURL("https://www.youtube.com/c/spres");
					case 'arch':
						fancyOpenURL("https://www.youtube.com/c/ajthefunky");
					case 'ghost-vip':
						fancyOpenURL("https://www.youtube.com/channel/UCtpdsQyTqsGGWmMFODgaUrQ");
					case 'you-cant-run':
						fancyOpenURL("https://www.youtube.com/c/lylace");
				}*/
			}
		}
		else if (!FlxG.mouse.overlaps(text3))
			text3.color = 0xFF0078D4;

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		comboText.text = combo + '\n';

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT && !FlxG.keys.pressed.ALT;

		if (warning && accepted)
			MusicBeatState.switchState(new BETADCIUState());

		if (upP && canMove)
		{
			changeSelection(-1);
		}
		if (downP && canMove)
		{
			changeSelection(1);
		}

		if (controls.BACK && canMove)
		{
			MusicBeatState.switchState(new BETADCIUState());
		}

		if (accepted && canMove)
		{
			persistentUpdate = false;
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.isNeonight = false;
			PlayState.isVitor = false;
			PlayState.isBETADCIU = true;
			PlayState.isBonus = false;
			PlayState.storyDifficulty = curDifficulty;
			canMove = false;
			
			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			var llll = FlxG.sound.play(PlayState.existsInCTS('confirmMenu')).length;

			if (songs.length < 2) // the tween doesn't finish if it's just one song
			{
				new FlxTimer().start(llll/1000, function(tmr:FlxTimer)
				{
					if (FlxG.keys.pressed.ALT){
						MusicBeatState.switchState(new ChartingState());
					}else{
						if (Main.hiddenSongs.contains(songs[curSelected].songName.toLowerCase()) && !Main.isHidden || PlayState.SONG.song == 'Restore' && !Main.restoreUnlocked || PlayState.SONG.song == 'Deathmatch-Holo' && !Main.deathHolo)
							LoadingState.loadAndSwitchState(new GoFindTheSecretState());
						else
							if (ClientPrefs.data.multicoreLoading) { // redirect to playstate since this doesn't have the multi thread loading **yet**
								LoadingState.loadAndSwitchState(new PlayState());
								return;
							}
							LoadingState.loadAndSwitchState(new CustomLoading());
				}
				});
			}
			
			grpSongs.forEach(function(e:Alphabet){
				if (e.text != songs[curSelected].songName){
					FlxTween.tween(e, {x: -6000}, llll / 1000,{onComplete:function(e:FlxTween){
					
						if (FlxG.keys.pressed.ALT){
							MusicBeatState.switchState(new ChartingState());
						}else{
							if (Main.hiddenSongs.contains(songs[curSelected].songName.toLowerCase()) && !Main.isHidden || PlayState.SONG.song == 'Restore' && !Main.restoreUnlocked || PlayState.SONG.song == 'Deathmatch-Holo' && !Main.deathHolo)
								LoadingState.loadAndSwitchState(new GoFindTheSecretState());
							else
								LoadingState.loadAndSwitchState(new CustomLoading());
						}
					}});
				}else{
					FlxFlicker.flicker(e);
					trace(curSelected);
					FlxTween.tween(e, {x: e.x + 20}, llll/1000);
				}	
			});
		}
	}

	public function changeIcon():Void
	{
		ytIcon.animation.play(songs[curSelected].ytName);
		text2.text = (songs[curSelected].ytName);
		text2.color = (songs[curSelected].textColor);
		text2.x = ytIcon.x - ((text2.width - ytIcon.width)/2);

		/*switch (songs[curSelected].songName.toLowerCase())
		{
			case 'epiphany' | 'bonedoggle':
			{
				ytIcon.animation.play('snow');
				text2.text = "Snow The Fox";
				text2.color = 0xFFB94545;
				text2.x = 790;
			}
			case "rabbit's-luck":
			{
				ytIcon.animation.play('spres');
				text2.text = 'spres';
				text2.color = 0xFF3F47CC;
				text2.x = 910;
			}
			case 'arch':
			{
				ytIcon.animation.play('aj');
				text2.text = "AjTheFunky";
				text2.color = 0xFFFF7FB8;
				text2.x = 840;
			}	
			case 'ghost-vip':
			{
				ytIcon.animation.play('lno');
				text2.text = "LiterallyNoOne";
				text2.color = 0xFF444561;
				text2.x = 790;
			}		
			case 'you-cant-run':
			{
				ytIcon.animation.play('lylace');
				text2.text = "Lylace";
				text2.color = 0xFF691A6B;
				text2.x = 900;
			}
			case "its-complicated":
			{
				ytIcon.animation.play('tc');
				text2.text = 'Tactical Cupcakes';
				text2.color = 0xB8076F;
				text2.x = 790;
			}
			case 'buildstroll':
			{
				ytIcon.animation.play('chxwy');
				text2.text = "Chxwy";
				text2.color = 0xFF3D026C;
				text2.x = 910;
			}	
			case 'ballistic':
			{
				ytIcon.animation.play('mewrk');
				text2.text = "Mewrk";
				text2.color = 0xFF444561;
				text2.x = 910;
			}		
		}*/
	}

	function changeDiff(change:Int = 0)
	{
		//curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		// adjusting the highscore song name to be compatible (changeDiff)
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		switch (songHighscore) {
			case 'Dad-Battle': songHighscore = 'Dadbattle';
			case 'Philly-Nice': songHighscore = 'Philly';
		}
		
			
		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString2() + ' >';
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(PlayState.existsInCTS('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		changeIcon();
		// selector.y = (70 * curSelected) + 30;

		var bullShitX:Int = 0;
		var bullShitY:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShitY - curSelected;
			bullShitY++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		
		if (!warning)
		{
			var diffStr:String = WeekData.getCurrentWeek().difficulties;
			if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5
	
			if(diffStr != null && diffStr.length > 0)
			{
				var diffs:Array<String> = diffStr.split(',');
				var i:Int = diffs.length - 1;
				while (i > 0)
				{
					if(diffs[i] != null)
					{
						diffs[i] = diffs[i].trim();
						if(diffs[i].length < 1) diffs.remove(diffs[i]);
					}
					--i;
				}
	
				if(diffs.length > 0 && diffs[0].length > 0)
				{
					CoolUtil.difficulties = diffs;
				}
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		combo = Highscore.getCombo(songs[curSelected].songName, curDifficulty);
		#end

		diffText.text = "< HARD >";
	}
}

class SongMetadata2
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var folder:String = "";

	public var ytName:String = "";
	public var link:String = "";
	public var textColor:Int = -7179779;

	public function new(song:String, week:Int, songCharacter:String, ytName:String, link:String, textColor:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		
		this.ytName = ytName;
		this.link = link;
		this.textColor = textColor;

		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
