package states;

import flash.text.TextField;
import flixel.addons.display.FlxGridOverlay;
import lime.utils.Assets;
import flixel.effects.FlxFlicker;
import states.editors.ChartingState;

import objects.HealthIcon;
import backend.Song;
import backend.WeekData;

using StringTools;

class NeonightState extends MusicBeatState
{
	var songs:Array<FreeplayState.SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 3;

	var scoreText:FlxText;
	var diffText:FlxText;
	var comboText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';

	var warning:Bool = false;
	var canMove:Bool = true;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	public static var downscroll:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		FlxG.mouse.visible = false;

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		WeekData.reloadWeekFiles(false, 3);

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

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.fadeIn(2, 0, 0.8);
			FlxG.sound.playMusic(Paths.music('neonight'), 0);
		}	

		 #if desktop
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In Neonight BETADCIU Menu", null);
		 #end

		var isDebug:Bool = false;

		MainMenuState.mainMusic = true;

		#if debug
		isDebug = true;
		#end

			//addWeek(['Split-Ex', 'Crucify'], 1, ['amor-ex', 'taki']);
			//addWeek(['Sorrow', 'Shinkyoku'], 2, ['calli', 'duet-sm']);

		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite(-1300, -90).loadGraphic(Paths.image('menuNEO'));
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
		scoreText.setFormat(Paths.font("neo.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		comboText = new FlxText(diffText.x + 100, diffText.y, 0, "", 24);
		comboText.font = diffText.font;
		add(comboText);

		add(scoreText);

		changeSelection();

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

		if (warning)
		{
			var blackScreen = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 1), Std.int(FlxG.height * 0.5), FlxColor.BLACK);
			blackScreen.screenCenter();
			blackScreen.scrollFactor.set();
			blackScreen.visible = false;
			blackScreen.alpha = 0.6;
			add(blackScreen);

			blackScreen.visible = true;
			canMove = false;

			var daText = new FlxText(0, 0, 0, "No BETADCIUs Detected! \n Press enter to return to main menu.", 48);
			daText.setFormat(Paths.font("neo.ttf"), 48, FlxColor.WHITE, CENTER);
			daText.screenCenter();
			daText.x += 20;
			daText.y -= 100;
			add(daText);

			var daText2 = new FlxText(0, 0, Std.int(FlxG.width * 0.45), "Press enter to return to the main menu.", 44);
			daText2.setFormat(Paths.font("neo.ttf"), 44, FlxColor.WHITE, CENTER);
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

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

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
			changeSelection(-1);

		if (downP && canMove)
			changeSelection(1);

		if (controls.BACK && canMove)
			MusicBeatState.switchState(new BETADCIUState());

		if (accepted && canMove)
		{
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.isNeonight = true;
			PlayState.isVitor = false;
			PlayState.isBETADCIU = false;
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
	}

	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent('Fresh');
		#end

		// NGio.logEvent('Fresh');
		FlxG.sound.play(PlayState.existsInCTS('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		combo = Highscore.getCombo(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;
		Mods.currentModDirectory = songs[curSelected].folder;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}

		diffText.text = "< HARD >";
	}
}