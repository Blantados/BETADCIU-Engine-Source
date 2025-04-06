package states;

import flixel.effects.FlxFlicker;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;

import lime.utils.Assets;
import flash.text.TextField;

import states.editors.ChartingState;
import backend.WeekData;
import backend.Song;

import objects.HealthIcon;

using StringTools;

class BETADCIUState extends MusicBeatState
{
	var songs:Array<FreeplayState.SongMetadata> = [];

	var selector:FlxText;
	public static var curSelected:Int = 0;
	var curDifficulty:Int = 2;

	var scoreText:FlxText;
	var enterText:FlxText;
	var diffText:FlxText;
	var comboText:FlxText;
	var passwordText:FlxInputText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	public static var downscroll:Bool = false;
	public static var inMain:Bool = true;
	public static var canMove:Bool = true;
	public var warning:Bool = false;
	var extras:FlxSprite;
	var neonight:FlxSprite;
	var vitor:FlxSprite;
	var blackScreen:FlxSprite;

	var bg:FlxSprite;
	var bgManifest:FlxSprite;
	var bgStorm:FlxSprite;

	private static var lastDifficultyName:String = '';

	private var iconArray:Array<HealthIcon> = [];

	var intendedColor:Int;
	var colorTween:FlxTween;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		WeekData.reloadWeekFiles(false, 1);

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
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}

		if (songs.length < 1)
		{
			addSong('Placeholder', 0, 'face', 0xFFFFFFFF);
			warning = true;
			trace('warn em bro!');
		}
	
		WeekData.setDirectoryFromWeek();

		if (!FlxG.sound.music.playing || MainMenuState.mainMusic)
		{
			FlxG.sound.playMusic(Paths.music('songSelect'));
			MainMenuState.mainMusic = false;
		}	

		if (FlxG.sound.music.volume == 0 || !FlxG.sound.music.playing)
		{
			FlxG.sound.music.volume = 1;
			FlxG.sound.playMusic(Paths.music('songSelect'));
		}

		Main.isMegalo = false;

		 #if desktop
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In BETADCIU Menu", null);
		 #end

		var isDebug:Bool = false;

		FlxG.mouse.visible = true;
		inMain = true;
		canMove = true;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.x = 0;
		add(bg);

		bgManifest = new FlxSprite().loadGraphic(Paths.image('menuBGStorm'));
		bgManifest.color = FlxColor.RED;
		bgManifest.scrollFactor.x = 0;
		bgManifest.alpha = 0;
		add(bgManifest);

		bgStorm = new FlxSprite().loadGraphic(Paths.image('menuBGStorm'));
		bgStorm.scrollFactor.x = 0;
		bgStorm.alpha = 0;
		add(bgStorm);

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

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

		changeSelection();
		changeDiff();

		extras = new FlxSprite(1064, 720-66).loadGraphic(Paths.image('extras'), true, 360, 110);
		extras.animation.add('idle', [0]);
		extras.animation.add('hover', [1]);
		extras.scrollFactor.set();
		extras.setGraphicSize(Std.int(extras.width * 0.6));
		extras.updateHitbox();
		extras.antialiasing = true;
		add(extras);

		neonight = new FlxSprite(1064, 720-132).loadGraphic(Paths.image('neonight'), true, 360, 110);
		neonight.animation.add('idle', [0]);
		neonight.animation.add('hover', [1]);
		neonight.scrollFactor.set();
		neonight.setGraphicSize(Std.int(neonight.width * 0.6));
		neonight.updateHitbox();
		neonight.antialiasing = true;
		add(neonight);

		vitor = new FlxSprite(1064, 720-198).loadGraphic(Paths.image('vitor'), true, 360, 110);
		vitor.animation.add('idle', [0]);
		vitor.animation.add('hover', [1]);
		vitor.scrollFactor.set();
		vitor.setGraphicSize(Std.int(vitor.width * 0.6));
		vitor.updateHitbox();
		vitor.antialiasing = true;
		add(vitor);

		blackScreen = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 1), Std.int(FlxG.height * 0.5), FlxColor.BLACK);
		blackScreen.screenCenter();
		blackScreen.scrollFactor.set();
		blackScreen.alpha = 0.6;
		blackScreen.visible = false;
		add(blackScreen);

		enterText = new FlxText(0, 0, 0, "Enter Password:", 48);
		enterText.setFormat('Pixel Arial 11 Bold', 48, FlxColor.WHITE, CENTER);
		enterText.screenCenter();
		enterText.y -= 100;
		enterText.visible = false;
		add(enterText);

		passwordText = new FlxInputText(0, 300, 550, '', 36, FlxColor.WHITE, FlxColor.BLACK);
		passwordText.fieldBorderColor = FlxColor.WHITE;
		passwordText.fieldBorderThickness = 3;
		passwordText.maxLength = 20;
		passwordText.screenCenter(X);
		passwordText.y += 75;
		passwordText.visible = false;
		add(passwordText);

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		changeBGColor();

		if (warning)
		{
			blackScreen.visible = true;
			canMove = false;
			inMain = false;

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

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new FreeplayState.SongMetadata(songName, weekNum, songCharacter, color));
	}

	public function changeBGColor():Void
	{
		if (songs[curSelected].songName.toLowerCase() == 'manifest' || songs[curSelected].songName.toLowerCase() == 'storm')
		{
			if (songs[curSelected].songName.toLowerCase() == 'manifest')
				FlxTween.tween(bgManifest, {alpha: 1}, 0.5);
			if (songs[curSelected].songName.toLowerCase() == 'storm')
				FlxTween.tween(bgStorm, {alpha: 1}, 0.5);
		}
		else
		{
			var newColor:Int = songs[curSelected].color;
			if(newColor != intendedColor) {
				if(colorTween != null) {
					colorTween.cancel();
				}
				intendedColor = newColor;
				colorTween = FlxTween.color(bg, 0.5, bg.color, intendedColor, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
				});
			}

			if (bgManifest.alpha > 0)
				FlxTween.tween(bgManifest, {alpha: 0}, 0.5);
			if (bgStorm.alpha > 0)
				FlxTween.tween(bgStorm, {alpha: 0}, 0.5);

			/*switch (songs[curSelected].songName.toLowerCase())
			{
				case 'city-funk':
					songCol = 0xFF4343AF;
				case 'shotgun-shell':
					songCol = 0xFFBA1E24;
				case 'safety-lullaby':
					songCol = 0xFFF9DF44;
				case 'for-hire':
					songCol = 0xFF0033FF;
				case 'triple-trouble' | 'four-way-fracture':
					songCol = 0xFF2A0576;
				default:
					songCol = CoolUtil.dominantColor(iconArray[curSelected]);
			}*/
		}
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

	function isOnBtt(xx:Float, yy:Float, dis:Float)
	{
		var xDis = xx - FlxG.mouse.x;
		var yDis = yy - FlxG.mouse.y;
		if (Math.sqrt(Math.pow(xDis, 2) + Math.pow(yDis, 2)) < dis)
		{
			return(true);
		}
		else return(false);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.mouse.overlaps(extras))
		{
			extras.animation.play('hover');
			if (FlxG.mouse.justPressed && canMove)
			{
				//blackScreen.visible = true;
				//enterText.visible = true;
				//passwordText.visible = true;
				//canMove = false;

				MusicBeatState.switchState(new GuestBETADCIUState());
			}
		}
		else if (!FlxG.mouse.overlaps(extras))
		{
			extras.animation.play('idle');
		}

		if (FlxG.mouse.overlaps(neonight))
		{
			neonight.animation.play('hover');
			if (FlxG.mouse.justPressed && canMove)
			{
				MusicBeatState.switchState(new NeonightState());
			}
		}
		else if (!FlxG.mouse.overlaps(neonight))
		{
			neonight.animation.play('idle');
		}

		if (FlxG.mouse.overlaps(vitor))
		{
			vitor.animation.play('hover');
			if (FlxG.mouse.justPressed && canMove)
			{
				MusicBeatState.switchState(new VitorState());
			}
		}
		else if (!FlxG.mouse.overlaps(vitor))
		{
			vitor.animation.play('idle');
		}

		if (passwordText.visible == true)
			inMain = false;

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		comboText.text = combo + '\n';

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT && !FlxG.keys.pressed.ALT;

		if (warning && accepted)
			MusicBeatState.switchState(new MainMenuState());

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (upP && inMain && canMove){
			changeSelection(-shiftMult);
			changeDiff();
		}
		if (downP && inMain && canMove){
			changeSelection(shiftMult);
			changeDiff();
		}

		if (controls.BACK && inMain && canMove)
		{
			persistentUpdate = false;

			if(colorTween != null) {
				colorTween.cancel();
			}
			
			//unloadAssets();
			FlxG.sound.play(PlayState.existsInCTS('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (accepted && inMain && canMove)
		{
			persistentUpdate = false;
			if (FlxG.random.bool(20) && songs[curSelected].songName.toLowerCase() == 'hill-of-the-void')
			{
				curDifficulty = 1;
				Main.isMegalo = true;
				trace ('sans');
			}

			PlayState.isBETADCIU = true; //gotta move this cuz of the format thing

			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;	
			PlayState.isNeonight = false;
			PlayState.isVitor = false;
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

		#if debug
			if (FlxG.keys.justPressed.FIVE)
			{
				Main.isHidden = !Main.isHidden;
			}
		#end

		if (FlxG.keys.justPressed.ESCAPE && !inMain && !warning)
		{
			blackScreen.visible = false;
			enterText.visible = false;
			passwordText.visible = false;
			passwordText.text = '';
			inMain = true;
			canMove = true;
		}	
	
		var wrongPass:Bool = false;

	// i like don't care anymore. I don't even know how funkipedia managed to find them all... just uh good job i guess.
		if (passwordText.text != "" && FlxG.keys.justPressed.ENTER)
		{	
			switch (passwordText.text)
			{
				case 'dont overwork': startSong('Hunger');
				case 'osu mania': startSong('Diva');
				case 'double trouble': startSong('Shinkyoku');
				case 'norway when': startSong('Norway');
				case 'holofunk yeah': startSong('Sorrow');
				case 'good night': startSong('Safety-Lullaby');
				default: wrongPass = true;
			}	
		} 
			
		if (wrongPass && !inMain)
		{
			FlxG.sound.play(PlayState.existsInCTS('missnote'+FlxG.random.int(1,3)));
			passwordText.text = '';
			wrongPass = false;
		}
	}

	function startSong(songName:String):Void
	{
		FlxG.sound.music.stop();
		FlxG.sound.play(PlayState.existsInCTS('ANGRY_TEXT_BOX', 'shared'));
		Main.isHidden = true;

		var songFormat = StringTools.replace(songName, " ", "-");
		switch (songFormat) {
			case 'Dad-Battle': songFormat = 'Dadbattle';
			case 'Philly-Nice': songFormat = 'Philly';
			case 'Scary-Swings': songFormat = 'Scary Swings';
		}

		var poop:String = Highscore.formatSong(songFormat, curDifficulty);

		PlayState.SONG = Song.loadFromJson(poop, songName);
		PlayState.isStoryMode = false;
		PlayState.isBETADCIU = true;
		PlayState.isBonus = false;
		PlayState.isVitor = false;
		PlayState.isNeonight = false;
		PlayState.storyDifficulty = curDifficulty;
		PlayState.storyWeek = 8;
		trace('CUR WEEK: EXTRA WEEK');
		LoadingState.loadAndSwitchState(new PlayState());
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
			
		changeBGColor();
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
	}
}