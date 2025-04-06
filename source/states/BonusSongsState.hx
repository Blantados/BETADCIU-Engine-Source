package states;

import flash.text.TextField;
import flixel.addons.display.FlxGridOverlay;
import lime.utils.Assets;
import flixel.effects.FlxFlicker;
import states.editors.ChartingState;

import backend.WeekData;
import backend.Song;

#if windows
import Sys;
#end

import objects.HealthIcon;

using StringTools;

class BonusSongsState extends MusicBeatState
{
	var songs:Array<FreeplayState.SongMetadata> = [];

	var selector:FlxText;
	public static var curSelected:Int = 0;
	var curDifficulty:Int = 2;

	var scoreText:FlxText;
	var infoText:FlxText;
	var diffText:FlxText;
	var comboText:FlxText;
	var copyrightText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	var bgPixel:FlxSprite;
	var infoBG:FlxSprite;

	var blackScreen:FlxSprite;
	var enterText:Alphabet;
	var otherText:FlxText;

	var inUnlockMenu:Bool;
	public static var canMove:Bool;
	public var warning:Bool = false;
	private static var lastDifficultyName:String = '';

	private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		WeekData.reloadWeekFiles(false, 2);

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
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1]);
			}
		}
		WeekData.setDirectoryFromWeek();

		if (songs.length < 1)
		{
			addSong('Placeholder', 0, 'face');
			warning = true;
			trace('warn em bro!');
		}

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
	
		inUnlockMenu = false;
		canMove = true;
			
		//FlxG.sound.cache(PlayState.existsInCTS("unlock"));

		 #if desktop
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In Bonus Song Menu", null);
		 #end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		var lamentCombo:String = '';
		var rootsCombo:String = '';
		var spookyCombo:String = '';
		var ughCombo:String = '';
		var argumentCombo:String = '';
		var unholyCombo:String = '';

		#if !switch
		lamentCombo = Highscore.getCombo('Lament', 2);
		rootsCombo = Highscore.getCombo('Roots', 2);
		spookyCombo = Highscore.getCombo('Spooky-Fight', 2);
		ughCombo = Highscore.getCombo('Ugh', 2);
		argumentCombo = Highscore.getCombo('Argument', 2);
		unholyCombo = Highscore.getCombo('Unholy-Worship', 2);
		#end

		if (TitleState.curWacky[1].contains('uncorruption') && Main.seenMessage)
			addSong('Restore', 6, 'senpai-glitch');
	
		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = FlxColor.fromRGB(112,167,240);
		add(bg);
		
		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.isFreeplayItem = true;
			songText.screenCenter(X); 			
			songText.changeX = false;
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

		infoText = new FlxText(FlxG.width * 0.7, 105, FlxG.height, "", 20);
		infoText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		infoText.text = 'This song contains copyrighted' 
		+ '\ncontent. Press P for Alternate'
		+ '\nInst.';

		copyrightText = new FlxText(FlxG.width * 0.7, 155, FlxG.height, "", 32);
		copyrightText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
		if (!Main.noCopyright) 
			copyrightText.text = '\nAlternate Inst: Off';
		else 
			copyrightText.text = '\nAlternate Inst: On';
		
		infoBG = new FlxSprite(scoreText.x - 6, 100).makeGraphic(Std.int(FlxG.width * 0.35), 132, 0xFF000000);
		infoBG.alpha = 0.6;
		add(infoBG);

		add(infoText);
		add(copyrightText);

		blackScreen = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 0.9), Std.int(FlxG.height * 0.5), FlxColor.BLACK);
		blackScreen.screenCenter();
		blackScreen.scrollFactor.set();
		blackScreen.alpha = 0.9;
		blackScreen.visible = false;
		add(blackScreen);

		var daSong:String = 'Deathmatch';

		if (!FlxG.save.data.deathHoloUnlocked)
			daSong = 'Deathmatch';
		else
			daSong = 'Deathmatch Holo\n';

		enterText = new Alphabet(0, 0, daSong + " Unlocked", true);
		enterText.screenCenter();
		enterText.y -= 100;
		enterText.visible = false;
		add(enterText);
		
		otherText = new FlxText(0, 0, FlxG.width, "" , 44);
		otherText.setFormat('Pixel Arial 11 Bold', 44, FlxColor.WHITE, CENTER);
		if (!FlxG.save.data.deathHoloUnlocked)
		{
			otherText.text = "Asset Password:"
			+ "\nsenpaiandtankman11";
		}		
		else
		{
			otherText.text = "No locked assets."
			+ "\nPress Enter to Continue";
		}	
		
		otherText.screenCenter();
		otherText.y += 50;
		otherText.visible = false;
		add(otherText);

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

		/*if (FlxG.save.data.deathUnlocked && !FlxG.save.data.seenDeathPassword)
		{
			FlxG.sound.play(PlayState.existsInCTS('unlock'));
			blackScreen.visible = true;
			enterText.visible = true;
			otherText.visible = true;
			inUnlockMenu = true;
			FlxG.save.data.seenDeathPassword = true;
		}

		if (FlxG.save.data.deathHoloUnlocked && !FlxG.save.data.seenDeathHoloPassword)
		{
			FlxG.sound.play(PlayState.existsInCTS('unlock'));
			blackScreen.visible = true;
			enterText.visible = true;
			otherText.visible = true;
			inUnlockMenu = true;
			FlxG.save.data.seenDeathHoloPassword = true;
		}*/
			
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

			var daText = new FlxText(0, 0, 0, "No Bonus Songs Detected! \n Press enter to return to main menu.", 48);
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

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new FreeplayState.SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
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
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7){
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (inUnlockMenu)
			canMove = false;

		if (inUnlockMenu && FlxG.keys.justPressed.ENTER)
		{		
			FlxTween.tween(enterText, {alpha: 0}, 0.5);
			FlxTween.tween(otherText, {alpha: 0}, 0.5);
			FlxTween.tween(blackScreen, {alpha: 0}, 0.5);

			new FlxTimer().start(0.75, function(tmr:FlxTimer)
			{
				inUnlockMenu = false;
				canMove = true;
			});
		}

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		comboText.text = combo + '\n';

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT && !FlxG.keys.pressed.ALT;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (warning && accepted)
			MusicBeatState.switchState(new MainMenuState());
		
		if (upP && canMove){
			changeSelection(-shiftMult);
			changeDiff();
		}
		if (downP && canMove){
			changeSelection(shiftMult);
			changeDiff();
		}

		if (controls.LEFT_P && canMove)
			changeDiff(-1);
		if (controls.RIGHT_P && canMove)
			changeDiff(1);

		if (controls.BACK && canMove)
			MusicBeatState.switchState(new MainMenuState());

		if (accepted && canMove)
		{
			persistentUpdate = false;
			
			var daSongName:String = songs[curSelected].songName.toLowerCase();
			var path:String = daSongName+'/'+daSongName+'-'+CoolUtil.difficulties[curDifficulty].toLowerCase();

			if (!FileSystem.exists(Paths.json(path)) && !FileSystem.exists(Paths.modFolders('data/'+path+'.json')))
			{
				trace('No ' + CoolUtil.difficulties[curDifficulty] + ' Difficulty');

				CoolUtil.difficulties = ['Hard'];
				curDifficulty = 0;
			}

			PlayState.isStoryMode = false;
			PlayState.isBETADCIU = false;
			PlayState.isNeonight = false;
			PlayState.isVitor = false;
			PlayState.isBonus = true;
			PlayState.storyDifficulty = curDifficulty;
			canMove = false;

			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());

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
							if (Main.hiddenSongs.contains(songs[curSelected].songName.toLowerCase()) && !Main.isHidden || PlayState.SONG.song == 'Restore' && !Main.restoreUnlocked)
								LoadingState.loadAndSwitchState(new GoFindTheSecretState());
							else
								if (ClientPrefs.data.multicoreLoading) { // redirect to playstate since this doesn't have the multi thread loading **yet**
									LoadingState.loadAndSwitchState(new PlayState());
									return;
								}
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

		if (infoText.visible == true && FlxG.keys.justPressed.P)
		{
			Main.noCopyright = !Main.noCopyright;
			if (!Main.noCopyright) 
			{
				FlxG.sound.play(PlayState.existsInCTS('cancelMenu'));
				copyrightText.text = '\nAlternate Inst: Off';
			}
			else 
			{
				FlxG.sound.play(PlayState.existsInCTS('confirmMenu'));
				copyrightText.text = '\nAlternate Inst: On';
			}
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

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
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		//intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

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

		if (songs[curSelected].songName.toLowerCase() == 'sharkventure')
		{
			infoBG.visible = true;
			infoText.visible = true;
			copyrightText.visible = true;	
		}
		else if (songs[curSelected].songName.toLowerCase() != 'sharkventure')
		{
			infoBG.visible = false;
			infoText.visible = false;
			copyrightText.visible = false;		
		}
	}
}