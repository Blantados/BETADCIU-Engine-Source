package editors;

import flixel.addons.ui.FlxUIText;
import haxe.zip.Writer;
import Conductor.BPMChangeEvent;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.FlxObject;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import haxe.io.Bytes;
import flash.geom.Rectangle;
import flixel.util.FlxSort;
import flixel.addons.ui.FlxUISlider;

#if desktop
import Sys;
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class ChartingState extends MusicBeatState
{
	public static var noteTypeList:Array<String> = //Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
	[
		'',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'Auditor Note',
		'Static Note',
		'blah',
		'blah',
		'Haato Note',
		'Scythe Note',
		'Phantom Note',
		'GF Sing',
		'No Animation'
	];
	private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();
	var curRenderedNoteType:FlxTypedGroup<FlxText> = new FlxTypedGroup<FlxText>();

	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public var curSec:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dad Battle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;
	var writingNotesText:FlxText;
	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var hiddenSongs:Array<String> =['norway', 'haachama', 'high-school-conflict', 'hunger', 'sorrow'];
	var eventStuff:Array<Dynamic> =
	[
		['', "Nothing. Yep, that's right."],
		//['Dadbattle Spotlight', "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"],
		['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
		['Set GF Speed', "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
		//['Philly Glow', "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."],
		//['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
		['Add Camera Zoom', "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		//['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		['Play Animation', "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
		['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
		['Alt Idle Animation', "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
		['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
		['Change Character', "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"],
		['Change Stage', "Changes the Stage\nValue 1: Stage's Name\nValue 2:Free value for use with onEvent"],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Set Property', "Value 1: Variable name\nValue 2: New value"]
	];
	var curEventSelected:Int = 0;

	var gridBG:FlxSprite;

	var _song:SwagSong;

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;

	var tempBpm:Float = 0;
	var gridBlackLine:FlxSprite;
	var gridBlackLine2:FlxSprite;
	var vocals:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;
	var currentType:Int = 0;

	var waveformSprite:FlxSprite;

	private var lastNote:Note;
	var camPos:FlxObject;
	public var ignoreWarnings = false;

	var tipTextGroup:FlxTypedGroup<FlxText>;

	override function create()
	{
		curSec = lastSection;

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = {
				song: 'Test',
				notes: [],
				events: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				noteStyle: 'normal',
				dadNoteStyle: 'normal',
				bfNoteStyle: 'normal',
				stage: 'stage',
				mania: 0,
				speed: 1,
				validScore: false
			};
		}	

		var keys:Int = Main.keyAmmo[_song.mania];

		ignoreWarnings = FlxG.save.data.ignoreWarnings;

		if(_song.notes[curSec].lengthInSteps != 16){
			trace('haha we found no lengthInSteps');
			_song.notes[curSec].lengthInSteps = 16;
		}
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * ((keys * 2) + 1), GRID_SIZE * _song.notes[curSec].lengthInSteps);
		gridBG.x -= GRID_SIZE;
		add(gridBG);

		gridBlackLine = new FlxSprite(gridBG.x + (gridBG.width - GRID_SIZE) / 2 + GRID_SIZE).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);

		gridBlackLine2 = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine2);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		loadAudioBuffer();
		// sections = _song.notes;

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		leftIcon = new HealthIcon(_song.player1);
		rightIcon = new HealthIcon(_song.player2);

		if (leftIcon.animation.name == 'face')
			leftIcon.changeIcon('bf');
		if (rightIcon.animation.name == 'face')
			rightIcon.changeIcon('dad');

		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(158, -100);

		var eventIcon:FlxSprite = new FlxSprite(-90, -90).loadGraphic(Paths.image('eventArrow'));
		eventIcon.setGraphicSize(30, 30);
		add(eventIcon);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 9), 4);
		strumLine.x -= GRID_SIZE;
		add(strumLine);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + 360, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = 640 + GRID_SIZE / 2;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var text:String = 
		"W/S or Mouse Wheel - Change Conductor's strum time
		\nA/D - Go to the previous/next section
		\nHold Shift to move 4x faster. Hold Alt to move 32x faster.
		\nLeft/Right - Change Snap
		\nUp/Down - Change Conductor's Strum Time with Snapping
		\nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		\nALT + Left Bracket / Right Bracket - Reset Song Playback Rate
		\nHold Control and click on an arrow to select it
		\n
		\nEsc - Test your chart inside Chart Editor
		\nEnter - Play your chart (Hold Shift to start at current time)
		\nQ/E - Decrease/Increase Note Sustain Length
		\nSpace - Stop/Resume song";

		tipTextGroup = new FlxTypedGroup<FlxText>();
		add(tipTextGroup);

		var tipTextArray:Array<String> = text.split('\n');
		for (i in 0...tipTextArray.length) {
			var tipText:FlxText = new FlxText(UI_box.x, UI_box.y + UI_box.height + 8, 0, tipTextArray[i], 16);
			tipText.y += i * 12;
			tipText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
			//tipText.borderSize = 2;
			tipText.scrollFactor.set();
			tipTextGroup.add(tipText);
		}
		
		add(UI_box);
		
		addChartingUI();
		addSongUI();
		addSectionUI();
		addEventsUI();
		addNoteUI();
		updateHeads();
		updateWaveform();

		add(curRenderedNotes);
		add(curRenderedSustains);
		add(curRenderedNoteType);

		//loadEvents(); // it doesn't load the events unless I do this
		updateGrid();

		super.create();
	}

	//so i don't have to rechart any special notes. i'll just use this

	function reloadSpecificNotes()
	{
		/*for (ii in 0..._song.notes.length)
		{
			for (i in 0..._song.notes[ii].sectionNotes.length)
			{
				var note = _song.notes[ii].sectionNotes[i];

				if (PlayState.curStage == 'auditorHell' && note[1] > 7)
				{
					note[3] = 4;
					note[1] = note[1] - 8;
					_song.notes[ii].sectionNotes[i] = note;
				}
				
				updateGrid();
			}
		}

		for (i in 0..._song.notes[curSec].sectionNotes.length)
		{
			var note = _song.notes[curSec].sectionNotes[i];

			note[3] = "D Type Note";
			_song.notes[curSec].sectionNotes[i] = note;
			
			updateGrid();
		}*/

		for (ii in 0..._song.notes.length)
		{
			for (note in _song.notes[ii].sectionNotes)
			{
				if(!Std.isOfType(note[3], String)) //idk if this works
				{
					note[3] = noteTypeIntMap.get(note[3]);
					note.noteType = note[3];
				}
			}

			updateGrid();
		}
	}

	var setDaOldBPM:Bool = false;

	function fitNotesToBpm(oldBPM:Float)
	{
		//MATH!! I only really use this when I make a remix with a different bpm from the original. Don't wanna have to rechart the entire song
		trace('change from '+oldBPM);
		
		for (ii in 0..._song.notes.length)
		{
			for (note in _song.notes[ii].sectionNotes)
			{
				note[0] = (note[0] / stepCrochetFormula(oldBPM)) * (stepCrochetFormula(tempBpm));
				note.strumTime = note[0];

				note[2] = (note[2] / stepCrochetFormula(oldBPM)) * (stepCrochetFormula(tempBpm));
				note.sustainLength = note[2];
			}
		}

		for (event in _song.events)
		{
			event[0] = (event[0] / stepCrochetFormula(oldBPM)) * (stepCrochetFormula(tempBpm));
			event.strumTime = event[0];
		}

		setDaOldBPM = true;

		updateGrid();
	}

	function stepCrochetFormula(bpm:Float)
	{
		var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
		var stepCrochet:Float = crochet / 4; // steps in milliseconds
		
		return stepCrochet;
	}

	#if desktop
	var waveformEnabled:FlxUICheckBox;
	var waveformUseInstrumental:FlxUICheckBox;
	#end

	var sliderRate:FlxUISlider;

	var check_warnings:FlxUICheckBox = null;

	function addChartingUI():Void
	{
		var tab_group_chart = new FlxUI(null, UI_box);
		tab_group_chart.name = "Charting";
		
		#if desktop
		waveformEnabled = new FlxUICheckBox(10, 90, null, null, "Visible Waveform", 100);
		if (FlxG.save.data.chart_waveform == null) FlxG.save.data.chart_waveform = false;
		waveformEnabled.checked = FlxG.save.data.chart_waveform;
		waveformEnabled.callback = function()
		{
			FlxG.save.data.chart_waveform = waveformEnabled.checked;
			updateWaveform();
		};

		waveformUseInstrumental = new FlxUICheckBox(waveformEnabled.x + 120, waveformEnabled.y, null, null, "Waveform for Instrumental", 100);
		waveformUseInstrumental.checked = false;
		waveformUseInstrumental.callback = function()
		{
			updateWaveform();
		};
		#end

		var check_mute_inst = new FlxUICheckBox(10, 310, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var check_mute_vocals = new FlxUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, null, null, "Mute Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function()
		{
			if(vocals != null) {
				var vol:Float = 1;

				if (check_mute_vocals.checked)
					vol = 0;

				vocals.volume = vol;
			}
		};

		var instVolume:FlxUINumericStepper = new FlxUINumericStepper(15, 270, 0.1, 1, 0.1, 10, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'song_instvol';

		var voicesVolume:FlxUINumericStepper = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0.1, 10, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'song_vocalvol';

		check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Progress Warnings", 100);
		if (FlxG.save.data.ignoreWarnings == null) FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;

		check_warnings.callback = function()
		{
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		};

		oldBpmInputText = new FlxUIInputText(130, 145, 90, Std.string(tempBpm));
		oldBpmInputText.focusLost = openOldBpmMenu;
		blockPressWhileTypingOn.push(oldBpmInputText);

		#if !html5
		sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 165, 0.5, 3, 150, null, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		tab_group_chart.add(sliderRate);
		#end

		tab_group_chart.add(new FlxText(130, oldBpmInputText.y - 30, 0, 'Old BPM (Fits chart from this \nBPM to Song BPM)'));
		tab_group_chart.add(oldBpmInputText);

		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 15, 0, 'Voices Volume'));

		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);
		tab_group_chart.add(check_warnings);
		#if desktop
		tab_group_chart.add(waveformEnabled);
		tab_group_chart.add(waveformUseInstrumental);
		#end

		UI_box.addGroup(tab_group_chart);
	}

	var oldBpmInputText:FlxUIInputText;

	function openOldBpmMenu() //do you really have to do it like this?
	{
		openSubState(new Prompt('Is this the correct BPM?', 0, function(){fitNotesToBpm(Std.parseFloat(oldBpmInputText.text));}, null,ignoreWarnings));
	}

	//KADE ENGINE!!!
	function shiftNotes(measure:Int = 0, step:Int = 0, ms:Int = 0):Void
	{
		var newSong = [];

		var millisecadd = (((measure * 4) + step / 4) * (60000 / _song.bpm)) + ms;
		var totaladdsection = Std.int((millisecadd / (60000 / _song.bpm) / 4));
		trace(millisecadd, totaladdsection);
		if (millisecadd > 0)
		{
			for (i in 0...totaladdsection)
			{
				newSong.unshift(newSection());
			}
		}
		for (daSection1 in 0..._song.notes.length)
		{
			newSong.push(newSection(16, _song.notes[daSection1].mustHitSection, _song.notes[daSection1].altAnim, _song.notes[daSection1].bfAltAnim));
		}

		for (daSection in 0...(_song.notes.length))
		{
			var aimtosetsection = daSection + Std.int((totaladdsection));
			if (aimtosetsection < 0)
				aimtosetsection = 0;
			newSong[aimtosetsection].mustHitSection = _song.notes[daSection].mustHitSection;
			updateHeads();
			newSong[aimtosetsection].altAnim = _song.notes[daSection].altAnim;
			newSong[aimtosetsection].bfAltAnim = _song.notes[daSection].bfAltAnim;
			// trace("section "+daSection);
			for (daNote in 0...(_song.notes[daSection].sectionNotes.length))
			{
				var newtiming = _song.notes[daSection].sectionNotes[daNote][0] + millisecadd;
				if (newtiming < 0)
				{
					newtiming = 0;
				}
				var futureSection = Math.floor(newtiming / 4 / (60000 / _song.bpm));
				_song.notes[daSection].sectionNotes[daNote][0] = newtiming;
				newSong[futureSection].sectionNotes.push(_song.notes[daSection].sectionNotes[daNote]);

				// newSong.notes[daSection].sectionNotes.remove(_song.notes[daSection].sectionNotes[daNote]);
			}
		}
		// trace("DONE BITCH");
		_song.notes = newSong;
		updateGrid();
		updateSectionUI();
		updateNoteUI();
	}

	var characters:Array<String>;
	var stages:Array<String>;
	var noteStyles:Array<String>;

	var player1DropDown:FlxUIDropDownMenuCustom;
	var player2DropDown:FlxUIDropDownMenuCustom;
	var gfVersionDropDown:FlxUIDropDownMenuCustom;
	var noteStyleDropDown:FlxUIDropDownMenuCustom;
	var stageDropDown:FlxUIDropDownMenuCustom;

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;
		blockPressWhileTypingOn.push(UI_songTitle);

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			//if the song is playing and you have autoPause disabled, it'll crash.
			FlxG.sound.music.pause();
			vocals.pause();

			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
			loadAudioBuffer();
			updateWaveform();
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){loadJson(_song.song.toLowerCase()); }, null,ignoreWarnings));
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);


		var clear_notes:FlxButton = new FlxButton(320, 340, 'Clear notes', function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){for (sec in 0..._song.notes.length) {
				_song.notes[sec].sectionNotes = [];
			}
			updateGrid();
		}, null,ignoreWarnings));

		});

		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;

		var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function()
		{
			loadEvents();
		});

		var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, 'Save Events', function ()
		{
			//if the song is playing and you have autoPause disabled, it'll crash.
			FlxG.sound.music.pause();
			vocals.pause();
			
			saveEvents();
		});

		var clear_events:FlxButton = new FlxButton(320, 310, 'Clear events', function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, clearEvents, null,ignoreWarnings));
		});
		
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 0.1, 1, 1.0, 5000.0, 1);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		
		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperMania:FlxUINumericStepper = new FlxUINumericStepper(stepperSpeed.x + 105, stepperSpeed.y, 1, 0, 0, 4, 0);
		stepperMania.value = _song.mania;
		stepperMania.name = 'song_mania';

		loadArrayTexts();

		var player1DropDown = new FlxUIDropDownMenuCustom(10, stepperSpeed.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;

		var gfVersionDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, player1DropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.gfVersion = characters[Std.parseInt(character)];
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		
		var player2DropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, gfVersionDropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.player2;

		var stageDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true), function(stage:String)
		{
			_song.stage = stages[Std.parseInt(stage)];
		});
		stageDropDown.selectedLabel = _song.stage;

		var noteStyleDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x + 140, gfVersionDropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(noteStyles, true), function(noteStyle:String)
		{
			_song.noteStyle = noteStyles[Std.parseInt(noteStyle)];
		});
		noteStyleDropDown.selectedLabel = _song.noteStyle;

		var reloadDropDowns:FlxButton = new FlxButton(player1DropDown.x + 140, player2DropDown.y, "Reload Dropdowns", function()
		{
			loadArrayTexts();
		
			var dropDowns:Array<FlxUIDropDownMenuCustom> = [player1DropDown, player2DropDown, gfVersionDropDown, stageDropDown, noteStyleDropDown];
			var dropDownsData:Array<Array<String>> = [CoolUtil.coolTextFile(Paths.txt('characterList')), CoolUtil.coolTextFile(Paths.txt('characterList')), CoolUtil.coolTextFile(Paths.txt('characterList')), CoolUtil.coolTextFile(Paths.txt('stageList')), CoolUtil.coolTextFile(Paths.txt('noteStyleList'))];
			var dropDownsLabel:Array<String> = [_song.player1, _song.player2, _song.gfVersion, _song.stage, _song.noteStyle];

			for (i in 0...dropDowns.length){
				dropDowns[i].setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(dropDownsData[i], true));
				dropDowns[i].selectedLabel = dropDownsLabel[i];
			}
		});

		reloadDropDowns.setGraphicSize(80, 30);
		reloadDropDowns.updateHitbox();

		var stepperShiftNoteDial:FlxUINumericStepper = new FlxUINumericStepper(10, player2DropDown.y + 50, 1, 0, -1000, 1000, 0);
		stepperShiftNoteDial.name = 'song_shiftnote';

		var stepperShiftNoteDialStep:FlxUINumericStepper = new FlxUINumericStepper(10, stepperShiftNoteDial.y + 30, 1, 0, -1000, 1000, 0);
		stepperShiftNoteDialStep.name = 'song_shiftnotems';

		var stepperShiftNoteDialMs:FlxUINumericStepper = new FlxUINumericStepper(10, stepperShiftNoteDialStep.y + 30, 1, 0, -1000, 1000, 2);
		stepperShiftNoteDialMs.name = 'song_shiftnotems';

		var shiftNoteButton:FlxButton = new FlxButton(10, stepperShiftNoteDialMs.y + 20, "Shift", function()
		{
			shiftNotes(Std.int(stepperShiftNoteDial.value), Std.int(stepperShiftNoteDialStep.value), Std.int(stepperShiftNoteDialMs.value));
		});

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		// Define the controls as an array of objects
		var controls:Array<Dynamic> = [
			{ label: "Shift All Notes by # Sections", control: stepperShiftNoteDial},
			{ label: 'Shift All Notes by # Steps', control: stepperShiftNoteDialStep },
			{ label: 'Shift All Notes by # ms', control: stepperShiftNoteDialMs },
			{ control: shiftNoteButton },
			{ control: reloadDropDowns },
			{ control: check_voices },
			{ control: clear_notes },
			{ control: clear_events },
			{ control: saveEvents },
			{ control: saveButton },
			{ control: reloadSong },
			{ control: reloadSongJson },
			{ control: loadAutosaveBtn },
			{ control: loadEventJson },
			{ label: "Song BPM:", control: stepperBPM },
			{ label: "Song Speed:", control: stepperSpeed },
			{ label: "Song Mania:", control: stepperMania },
			{ label: "Note Style:", control: noteStyleDropDown },
			{ label: "Stage:", control: stageDropDown },
			{ label: "Opponent:", control: player2DropDown },
			{ label: "Girlfriend:", control: gfVersionDropDown },
			{ label: "Player:", control: player1DropDown }
		];

		// Loop over the controls and add them to tab_group_song
		for (control in controls) {
			if (control.label != null) {
				tab_group_song.add(new FlxText(control.control.x, control.control.y - 15, 0, control.label));
			}
			tab_group_song.add(control.control);
		}
		
		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(camPos);
	}

	function clearEvents() {
		_song.events = [];
		updateGrid();
	}

	function loadArrayTexts()
	{
		characters = CoolUtil.coolTextFile(Paths.txt('characterList'));
		stages = CoolUtil.coolTextFile(Paths.txt('stageList'));
		noteStyles = CoolUtil.coolTextFile(Paths.txt('noteStyleList'));
	}
	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_gfSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;
	var check_bfAltAnim:FlxUICheckBox;
	var check_dadCrossfade:FlxUICheckBox;
	var check_bfCrossfade:FlxUICheckBox;
	var stepperDType:FlxUINumericStepper;

	var typeNameTxt:FlxText;
	var typeNames:Array<String> = ['Normal', 'Alt Anim', 'Markov', 'Danger', 'Tricky', 'EXE', 'Bomb', 'Rushia', 'Haato', 'Scythe', 'Phantom', 'D Type'];

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 15, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSec].lengthInSteps;
		stepperLength.name = "section_length";

		check_mustHitSection = new FlxUICheckBox(10, stepperLength.y + 30, null, null, "Camera Points to P1?", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;
		
		check_gfSection = new FlxUICheckBox(check_mustHitSection.x + 120, check_mustHitSection.y, null, null, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(10, check_mustHitSection.y + 30, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_bfAltAnim = new FlxUICheckBox(check_altAnim.x + 120, check_altAnim.y, null, null, "Player Alt Animation", 100);
		check_bfAltAnim.name = 'check_bfAltAnim';

		check_changeBPM = new FlxUICheckBox(10, check_altAnim.y + 30, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 30, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		stepperDType = new FlxUINumericStepper(130, stepperSectionBPM.y, 1, 0, 0, 999, 0);
		stepperDType.value = 0;
		stepperDType.name = 'section_dtype';

		check_dadCrossfade = new FlxUICheckBox(check_altAnim.x, stepperDType.y + 30, null, null, "Opponent Crossfade", 100);
		check_dadCrossfade.name = 'check_dadCrossfade';

		check_bfCrossfade = new FlxUICheckBox(check_altAnim.x + 120, check_dadCrossfade.y, null, null, "Player Crossfade", 100);
		check_bfCrossfade.name = 'check_bfCrossfade';

		var check_eventsSec:FlxUICheckBox = null;
		var check_notesSec:FlxUICheckBox = null;
		
		var copyButton:FlxButton = new FlxButton(10, check_dadCrossfade.y + 30, "Copy Section", function()
		{
			notesCopied = [];
			sectionToCopy = curSec;
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				notesCopied.push(note);
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if(endThing > event[0] && event[0] >= startThing)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		});

		var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function()
		{
			if(notesCopied == null || notesCopied.length < 1)
			{
				return;
			}

			var addToTime:Float = Conductor.stepCrochet * (_song.notes[curSec].lengthInSteps * (curSec - sectionToCopy));
			//trace('Time to add: ' + addToTime);

			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
				if(note[1] < 0)
				{
					if(check_eventsSec.checked)
					{
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...note[2].length)
						{
							var eventToPush:Array<Dynamic> = note[2][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						_song.events.push([newStrumTime, copiedEventArray]);
					}
				}
				else
				{
					if(check_notesSec.checked)
					{
						if(note[4] != null) {
							copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
						} else {
							copiedNote = [newStrumTime, note[1], note[2], note[3]];
						}
						_song.notes[curSec].sectionNotes.push(copiedNote);
					}
				}
			}
			updateGrid();
		});

		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear Section", function()
		{
			if(check_notesSec.checked){
				_song.notes[curSec].sectionNotes = [];
			}

			if(check_eventsSec.checked)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while(i > -1) {
					var event:Array<Dynamic> = _song.events[i];
					if(event != null && endThing > event[0] && event[0] >= startThing)
					{
						_song.events.remove(event);
					}
					--i;
				}
			}
			updateGrid();
			updateNoteUI();
		});
		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;

		check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;

		var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 30, "Swap Section", function()
		{
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				var half = Main.keyAmmo[_song.mania];
				note[1] = (note[1] + half) % (half * 2);
				_song.notes[curSec].sectionNotes[i] = note;
			}
			updateGrid();
		});

		var stepperCopyLast:FlxUINumericStepper = new FlxUINumericStepper(110, swapSection.y + 30, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopyLast);

		var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function()
		{
			var sectionNum:Int = Std.int(stepperCopyLast.value);

			var value:Int = Std.int(sectionNum);
			if(value == 0) return;

			var daSec = FlxMath.maxInt(curSec, value);

			for (note in _song.notes[daSec - value].sectionNotes)
			{
				var newStrumTime = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
				var copiedNote:Array<Dynamic> = [];

				if(check_notesSec.checked)
				{
					if(note[4] != null) {
						copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
					} else {
						copiedNote = [newStrumTime, note[1], note[2], note[3]];
					}
					_song.notes[daSec].sectionNotes.push(copiedNote);
				}
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
				if(endThing > event[0] && event[0] >= startThing)
				{					
					if(check_eventsSec.checked)
					{
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...event[1].length)
						{
							var eventToPush:Array<Dynamic> = event[1][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						_song.events.push([strumTime, copiedEventArray]);
					}
				}
			}
			updateGrid();
		});

		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();

		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1];
				if (boob>3){
					boob -= 4;
				}else{
					boob += 4;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes){
			_song.notes[curSec].sectionNotes.push(i);

			}

			updateGrid();
		});
		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1]%4;
				boob = 3 - boob;
				if (note[1] > 3) boob += 4;

				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				//duetNotes.push(copiedNote);
			}

			for (i in duetNotes){
			//_song.notes[curSec].sectionNotes.push(i);

			}

			updateGrid();
		});

		var swagArray:Array<Dynamic> = [stepperLength, check_mustHitSection, check_gfSection, check_altAnim, check_bfAltAnim, check_changeBPM, stepperSectionBPM, stepperDType, check_dadCrossfade, check_bfCrossfade, copyButton, pasteButton, clearSectionButton, check_notesSec, check_eventsSec, swapSection, stepperCopyLast, copyLastButton, duetButton, mirrorButton];
		for (i in 0...swagArray.length){
			tab_group_section.add(swagArray[i]);
		}

		tab_group_section.add(new FlxText(75 , stepperLength.x,'Section Length (in steps)'));
		tab_group_section.add(new FlxText(stepperDType.x + 60, stepperDType.y,'Section dType'));
		tab_group_section.add(new FlxText(stepperCopyLast.x + 60, stepperCopyLast.y,'sections back'));

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var stepperNoteType:FlxUINumericStepper;
	var strumTimeInputText:FlxUIInputText;

	var tab_group_note:FlxUI;
	var noteTypeDropDown:FlxUIDropDownMenuCustom;
	
	function addNoteUI():Void
	{
		tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		writingNotesText = new FlxUIText(20,100, 0, "");
		writingNotesText.setFormat("Arial",20,FlxColor.WHITE,FlxTextAlign.LEFT,FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);

		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * _song.notes[curSec].lengthInSteps * 4);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
		blockPressWhileTypingOn.push(strumTimeInputText);

			var key:Int = 0;
		var displayNameList:Array<String> = [];
		while (key < noteTypeList.length) {
			displayNameList.push(noteTypeList[key]);
			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);
			key++;
		}

		#if desktop
		var directories:Array<String> = [Paths.mods('custom_notetypes/'), Paths.mods(Paths.currentModDirectory + '/custom_notetypes/')];
		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.lua')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!noteTypeMap.exists(fileToCheck)) {
							displayNameList.push(fileToCheck);
							noteTypeMap.set(fileToCheck, key);
							noteTypeIntMap.set(key, fileToCheck);
							key++;
						}
					}
				}
			}
		}
		#end

		for (i in 1...displayNameList.length) {
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		noteTypeDropDown = new FlxUIDropDownMenuCustom(10, 105, FlxUIDropDownMenuCustom.makeStrIdLabelArray(displayNameList, true), function(character:String)
		{
			currentType = Std.parseInt(character);
			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				curSelectedNote[3] = noteTypeIntMap.get(currentType);
				updateGrid();
			}
		});

		tab_group_note.add(writingNotesText);
		tab_group_note.add(new FlxText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);
		UI_box.addGroup(tab_group_note);
	}

	var eventDropDown:FlxUIDropDownMenuCustom;
	var descText:FlxText;
	var selectedEventText:FlxText;

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];
	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;

	function addEventsUI():Void
	{
		var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = 'Events';

		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];

		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_events/'));
		directories.push(Paths.mods(Paths.currentModDirectory + '/custom_events/'));
		for(mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/custom_events/'));
		#end

		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!eventPushedMap.exists(fileToCheck)) {
							eventPushedMap.set(fileToCheck, true);
							eventStuff.push([fileToCheck, File.getContent(path)]);
						}
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end

		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length) {
			leEvents.push(eventStuff[i][0]);
		}

		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		tab_group_event.add(text);
		eventDropDown = new FlxUIDropDownMenuCustom(20, 50, FlxUIDropDownMenuCustom.makeStrIdLabelArray(leEvents, true), function(pressed:String) {
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];
				if (curSelectedNote != null &&  eventStuff != null) {
				if (curSelectedNote != null && curSelectedNote[2] == null){
				curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];

				}
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(eventDropDown);

		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);
		value1InputText = new FlxUIInputText(20, 110, 100, "");
		blockPressWhileTypingOn.push(value1InputText);

		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);
		value2InputText = new FlxUIInputText(20, 150, 100, "");
		blockPressWhileTypingOn.push(value2InputText);

		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				if(curSelectedNote[1].length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
				{
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);
				}

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if(curEventSelected < 0) curEventSelected = 0;
				else if(curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length) curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);
		tab_group_event.add(removeButton);

		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		tab_group_event.add(addButton);

		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		tab_group_event.add(moveLeftButton);

		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(eventDropDown);

		UI_box.addGroup(tab_group_event);
	}

	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		if (FileSystem.exists(Paths.inst2(daSong)))
			FlxG.sound.playMusic(Sound.fromFile(Paths.inst2(daSong)), 0.6);
		else
			FlxG.sound.playMusic(Paths.inst(daSong), 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		if (FileSystem.exists(Paths.voices2(daSong)))
			vocals = new FlxSound().loadEmbedded(Sound.fromFile(Paths.voices2(daSong)));
		else
			vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));

		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if(vocals != null) {
				vocals.pause();
				vocals.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			vocals.play();
		};
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Camera Points to P1?':
					_song.notes[curSec].mustHitSection = check.checked;
					updateGrid();
					updateHeads();
				case 'GF section':
					_song.notes[curSec].gfSection = check.checked;
					updateGrid();
					updateHeads();
				case 'Change BPM':
					_song.notes[curSec].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation": _song.notes[curSec].altAnim = check.checked;
				case "Player Alt Animation": _song.notes[curSec].bfAltAnim = check.checked;
				case "Opponent Crossfade": _song.notes[curSec].dadCrossfade = check.checked;	
				case "Player Crossfade": _song.notes[curSec].bfCrossfade = check.checked;	
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			switch (wname)
			{
				case 'section_length':
					nums.value = Math.max(nums.value, 4);
					_song.notes[curSec].lengthInSteps = Std.int(nums.value);
					updateGrid();
				case 'song_speed':
					_song.speed = Math.max(nums.value, 0);
				case 'song_bpm':
					tempBpm = Math.max(Std.int(nums.value), 1);
					Conductor.mapBPMChanges(_song);
					Conductor.changeBPM(tempBpm);
				case 'song_mania':
					_song.mania = Std.int(Math.max(nums.value, 0));
					updateGrid();
				case 'note_susLength':
					if (curSelectedNote == null) return;
					curSelectedNote[2] = Math.max(nums.value, 0);
					updateGrid();
				case 'section_bpm':
					_song.notes[curSec].bpm = Math.max(Std.int(nums.value), 1);
					updateGrid();
				case "song_vocalvol":
					vocals.volume = Math.max(nums.value, 0.1);
				case "section_dtype":
					_song.notes[curSec].dType = Std.int(nums.value);
					updateGrid();
				case "song_instvol":
					FlxG.sound.music.volume = Math.max(nums.value, 0.1);
			}
		}
		else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(curSelectedNote != null)
			{
				if(sender == value1InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][1] = value1InputText.text;
						updateGrid();
					}
				}
				else if(sender == value2InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][2] = value2InputText.text;
						updateGrid();
					}
				}
				else if(sender == strumTimeInputText) {
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if(Math.isNaN(value)) value = 0;
					curSelectedNote[0] = value;
					updateGrid();
				}
			}
		}
		else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
		{
			switch (sender)
			{
				case 'playbackSpeed':
					playbackSpeed = Std.int(sliderRate.value);
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[curSec].changeBPM)
				return _song.notes[curSec].lengthInSteps * (_song.notes[curSec].bpm / _song.bpm);
			else
				return _song.notes[curSec].lengthInSteps;
	}*/
	function stepStartTime(step):Float
	{
		return _song.bpm / (step / 4) / 60;
	}

	function sectionStartTime(?add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	var writingNotes:Bool = false;
	var playbackSpeed:Float = 1;

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		//if (FlxG.keys.justPressed.FIVE)
			//reloadSpecificNotes();

		if (bpmTxt.x != UI_box.x + 340)
			bpmTxt.x = UI_box.x + 340;

		if (FlxG.keys.justPressed.ESCAPE)
		{
			lastSection = curSec;
			autosaveSong();
			LoadingState.loadAndSwitchState(new EditorPlayState(sectionStartTime()));
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

		if(!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;
				if(leText.hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			for (dropDownMenu in blockPressWhileScrolling) {
				if(dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

		if (oldBpmInputText.hasFocus && setDaOldBPM){
			setDaOldBPM = false;
		}

		//i like... never use this. also it's annoying when doing alt+tab to check something else
		/*if (FlxG.keys.justPressed.ALT && !FlxG.keys.justPressed.ENTER && UI_box.selected_tab == 0)
		{
			writingNotes = !writingNotes;
		}*/ 

		if (writingNotes)
			writingNotesText.text = "WRITING NOTES";
		else
			writingNotesText.text = "";

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		else if (vocals != null)
			Conductor.songPosition = vocals.time;
		else
			Conductor.songPosition = FlxG.sound.music.time; // it went back again?

		_song.song = typingShit.text;

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];

		if ((upP || rightP || downP || leftP) && writingNotes)
		{
			for(i in 0...controlArray.length)
			{
				if (controlArray[i])
				{
					for (n in 0..._song.notes[curSec].sectionNotes.length)
						{
							var note = _song.notes[curSec].sectionNotes[n];
							if (note == null)
								continue;
							if (note[0] == Conductor.songPosition && note[1] % (Main.keyAmmo[_song.mania]) == i)
							{
								trace('GAMING');
								_song.notes[curSec].sectionNotes.remove(note);
							}
						}
					trace('adding note');
					_song.notes[curSec].sectionNotes.push([Conductor.songPosition, i, 0]);
					updateGrid();
				}
			}

		}

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSec].lengthInSteps));
	
		camPos.y = strumLine.y;
		//strumLine.x = 0;

		if (curBeat % 4 == 0 && curStep >= 16 * (curSec + 1))
		{
			if (_song.notes[curSec + 1] == null)
			{
				addSection();
			}

			changeSection(curSec + 1, false);
		}

		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
			playbackSpeed = 1;
		//

		if (playbackSpeed <= 0.5)
			playbackSpeed = 0.5;
		if (playbackSpeed >= 3)
			playbackSpeed = 3;

		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;


		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else
						{
							//trace('tryin to delete note...');
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSec].lengthInSteps))
				{
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSec].lengthInSteps))
		{
			var arX = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			dummyArrow.x = arX;
		
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (!typingShit.hasFocus && !blockInput)
		{
			if (FlxG.keys.justPressed.ENTER)
			{
				lastSection = curSec;
				autosaveSong();

				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				vocals.stop();

				if (FlxG.keys.pressed.SHIFT){
					PlayState.startOnTime = Conductor.songPosition;
				}

				LoadingState.loadAndSwitchState(new PlayState());
			}
	
			if (FlxG.keys.justPressed.E){	
				changeNoteSustain(Conductor.stepCrochet * (FlxG.keys.pressed.SHIFT ? (curSelectedNote[2] != 0 ? 4 : 3) : 1));
			}
			if (FlxG.keys.justPressed.Q){
				changeNoteSustain(-Conductor.stepCrochet * (FlxG.keys.pressed.SHIFT ? (curSelectedNote[2] != 0 ? 4 : 3) : 1));
			}
	
			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 2;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 3)
						UI_box.selected_tab = 0;
				}
			}
			/*if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.Z && lastNote != null)
				{
					trace(curRenderedNotes.members.contains(lastNote) ? "delete note" : "add note");
					if (curRenderedNotes.members.contains(lastNote))
						deleteNote(lastNote);
					else 
						addNote(lastNote);
				}
			}*/

			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;
			if (FlxG.keys.pressed.ALT)
				shiftThing = 32;

			if (!writingNotes)
			{
				if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
					changeSection(curSec + shiftThing);
				if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
				{
					if(curSec <= 0) {
						changeSection(_song.notes.length-1); // what?
					} else {
						changeSection(curSec - shiftThing);
					}
				}
			}	

			if(FlxG.sound.music.time < 0) {
				FlxG.sound.music.pause();
				FlxG.sound.music.time = 0;
			}
			else if(FlxG.sound.music.time > FlxG.sound.music.length) {
				FlxG.sound.music.pause();
				FlxG.sound.music.time = 0;
				changeSection();
			}
			
			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					vocals.pause();
				}
				else
				{
					vocals.play();
					FlxG.sound.music.play();
				}
			}

			if (FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
				vocals.time = FlxG.sound.music.time;
			}

			if (!FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = 700 * FlxG.elapsed;

					if (FlxG.keys.pressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
			else
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = Conductor.stepCrochet * 2;

					if (FlxG.keys.justPressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
		}

		_song.bpm = tempBpm;

		/* if (FlxG.keys.justPressed.UP)
				Conductor.changeBPM(Conductor.bpm + 1);
			if (FlxG.keys.justPressed.DOWN)
				Conductor.changeBPM(Conductor.bpm - 1); */

		bpmTxt.text = bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ "\nSection: "
			+ curSec 
			+ "\nCurStep: " 
			+ curStep
			+ "\nCurBeat: " 
			+ curBeat;
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	override function beatHit() 
	{
		super.beatHit();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSec = sec;

			//-- so apparently psych 0.6.2 got rid of lengthInSteps which would cause older builds and other engines to not read the chart properly. this should fix it.
			if(_song.notes[curSec].lengthInSteps != 16){
				trace('haha we found no lengthInSteps');
				_song.notes[curSec].lengthInSteps = 16;
			}

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
		}
		else
		{
			changeSection();
		}

		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSec];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_bfAltAnim.checked = sec.bfAltAnim;
		check_dadCrossfade.checked = sec.dadCrossfade;
		check_bfCrossfade.checked = sec.bfCrossfade;
		stepperDType.value = sec.dType;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
		var healthIconP1:String = loadHealthIconFromCharacter(_song.player1);
		var healthIconP2:String = loadHealthIconFromCharacter(_song.player2);

		if (check_mustHitSection.checked)
		{
			leftIcon.changeIcon(healthIconP1);
			rightIcon.changeIcon(healthIconP2);
			if (leftIcon.animation.name == 'face'){leftIcon.changeIcon('bf');}
			if (rightIcon.animation.name == 'face'){rightIcon.changeIcon('dad');}
		}
		else
		{
			leftIcon.changeIcon(healthIconP2);
			rightIcon.changeIcon(healthIconP1);
			if (leftIcon.animation.name == 'face'){leftIcon.changeIcon('dad');}
			if (rightIcon.animation.name == 'face'){rightIcon.changeIcon('bf');}
		}
		if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
	}

	function loadHealthIconFromCharacter(char:String) {
		var characterPath:String = 'images/characters/jsons/' + char;

		var path:String = Paths.jsonNew(characterPath);

		#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders('characters/'+char+'.json')) || Assets.exists(Paths.modFolders('characters/'+char+'.json')))
				path = Paths.modFolders('characters/'+char+'.json');
		#end

		if (!FileSystem.exists(path) && !Assets.exists(path))
		{
			trace('oh no missingno');
			path = Paths.jsonNew('images/characters/jsons/' + Character.DEFAULT_CHARACTER); //If a character couldn't be found, change to bf just to prevent a crash
		}

		var rawJson:Dynamic;

		(FileSystem.exists(path) ? rawJson = File.getContent(path) : rawJson = Assets.getText(path));

		var json:Character.CharacterFile = cast Json.parse(rawJson);
		return json.healthicon;
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null) 
		{
			noteTypeDropDown.selectedLabel = '';

			if(curSelectedNote[3] != null) 
			{
				currentType = noteTypeMap.get(curSelectedNote[3]);
				if(currentType <= 0) {
					noteTypeDropDown.selectedLabel = '';
				} else {
					noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
				}
			}			

			if(curSelectedNote[2] != null) 
				stepperSusLength.value = curSelectedNote[2];
			else 
			{
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = Std.parseInt(eventDropDown.selectedId);
				if(selected > 0 && selected < eventStuff.length) {
					descText.text = eventStuff[selected][1];
				}
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}

			strumTimeInputText.text = '' + curSelectedNote[0];
		} 
	}

	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null) section = curSec;
		var val:Null<Float> = null;
		
		//if(_song.notes[section] != null) val = _song.notes[section].sectionBeats;
		if(_song.notes[section] != null) val = _song.notes[curSec].lengthInSteps / 4;
		return val != null ? val : 4;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if(addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % Main.keyAmmo[_song.mania], null, null, "", _song.noteStyle);
		if(daSus != null) { //Common note
			if(!Std.isOfType(i[3], String)) //Convert old note type to new note type format
			{
				i[3] = noteTypeIntMap.get(i[3]);
			}
			if(i.length > 3 && (i[3] == null || i[3].length < 1))
			{
				i.remove(i[3]);
			}
			note.sustainLength = daSus;
			note.noteType = i[3];
		} else { 
			note.loadGraphic(Paths.image('eventArrow'));
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if(i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE);

		if (daNoteInfo == -1)
			note.x = Math.floor(0 * GRID_SIZE) - GRID_SIZE;

		note.y = (GRID_SIZE * (isNextSection ? 16 : 0)) * _song.notes[curSec].lengthInSteps + Math.floor(getYfromStrum((daStrumTime - sectionStartTime(isNextSection ? 1 : 0)) % (Conductor.stepCrochet * _song.notes[curSec].lengthInSteps), false));
		
		return note;
	}

	function getYfromStrum(strumTime:Float, ?doZoomCalc:Bool = false):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	var waveformPrinted:Bool = true;
	var audioBuffers:Array<AudioBuffer> = [null, null];

	function loadAudioBuffer() {
		if(audioBuffers[0] != null) {
			audioBuffers[0].dispose();
		}
		audioBuffers[0] = null;
		#if desktop
		if(FileSystem.exists(FileSystem.absolutePath('songs/' + _song.song.toLowerCase() + '/Inst.ogg'))) {
			audioBuffers[0] = AudioBuffer.fromFile(FileSystem.absolutePath('songs/' + _song.song.toLowerCase() + '/Inst.ogg'));
			//trace('Custom vocals found');
		}
		else { #end
			var leVocals:String = Paths.getPath(_song.song.toLowerCase() + '/Inst.' + Paths.SOUND_EXT, SOUND, 'songs');
			if (Assets.exists(leVocals)) { //Vanilla inst
				audioBuffers[0] = AudioBuffer.fromFile('./' + leVocals.substr(6));
				//trace('Inst found');
			}
		#if desktop
		}
		#end

		if(audioBuffers[1] != null) {
			audioBuffers[1].dispose();
		}
		audioBuffers[1] = null;
		#if desktop
		if(FileSystem.exists(FileSystem.absolutePath('songs/' + _song.song.toLowerCase() + '/Voices.ogg'))) {
			audioBuffers[0] = AudioBuffer.fromFile(FileSystem.absolutePath('songs/' + _song.song.toLowerCase() + '/Voices.ogg'));
			//trace('Custom vocals found');
		} else { #end
			var leVocals:String = Paths.getPath(_song.song.toLowerCase() + '/Voices.' + Paths.SOUND_EXT, SOUND, 'songs');
			if (Assets.exists(leVocals)) { //Vanilla voices
				audioBuffers[1] = AudioBuffer.fromFile('./' + leVocals.substr(6));
				//trace('Voices found, LETS FUCKING GOOOO');
			}
		#if desktop
		}
		#end
	}
	
	function updateWaveform() {
		#if desktop
		if(waveformPrinted) {
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8), Std.int(gridBG.height), 0x00FFFFFF);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		var checkForVoices:Int = 1;
		if(waveformUseInstrumental.checked) checkForVoices = 0;

		if(!waveformEnabled.checked || audioBuffers[checkForVoices] == null) {
			//trace('Epic fail on the waveform lol');
			return;
		}

		var sampleMult:Float = audioBuffers[checkForVoices].sampleRate / 44100;
		var index:Int = Std.int(sectionStartTime() * 44.0875 * sampleMult);
		var drawIndex:Int = 0;

		var steps:Int = _song.notes[curSec].lengthInSteps;
		if(Math.isNaN(steps) || steps < 1) steps = 16;
		var samplesPerRow:Int = Std.int(((Conductor.stepCrochet * steps * 1.1 * sampleMult) / 16) /  _song.notes[curSec].lengthInSteps);
		if(samplesPerRow < 1) samplesPerRow = 1;
		var waveBytes:Bytes = audioBuffers[checkForVoices].data.toBytes();
		
		var min:Float = 0;
		var max:Float = 0;
		while (index < (waveBytes.length - 1))
		{
			var byte:Int = waveBytes.getUInt16(index * 4);

			if (byte > 65535 / 2)
				byte -= 65535;

			var sample:Float = (byte / 65535);

			if (sample > 0)
			{
				if (sample > max)
					max = sample;
			}
			else if (sample < 0)
			{
				if (sample < min)
					min = sample;
			}

			if ((index % samplesPerRow) == 0)
			{
				// trace("min: " + min + ", max: " + max);

				/*if (drawIndex > gridBG.height)
				{
					drawIndex = 0;
				}*/

				var pixelsMin:Float = Math.abs(min * (GRID_SIZE * 8));
				var pixelsMax:Float = max * (GRID_SIZE * 8);
				waveformSprite.pixels.fillRect(new Rectangle(Std.int((GRID_SIZE * 4) - pixelsMin), drawIndex, pixelsMin + pixelsMax, 1), FlxColor.BLUE);
				drawIndex++;

				min = 0;
				max = 0;

				if(drawIndex > gridBG.height) break;
			}

			index++;
		}
		waveformPrinted = true;
		#end
	}

	var curKeys:Int = 4;
	var keys:Int = 4;

	function updateGrid():Void
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();

		curKeys = keys;

		switch (_song.mania)
		{
			case 0:
				keys = 4;
			case 1:
				keys = 6;
			case 2:
				keys = 9;
			case 3:
				keys = 5;
			case 4:
				keys = 7;
		}

		#if desktop
		if(waveformEnabled != null) {
			updateWaveform();
		}
		#end

		if (curKeys != keys || gridBG.height != GRID_SIZE * _song.notes[curSec].lengthInSteps)
		{
			remove(gridBG);
			gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * ((keys * 2) + 1), GRID_SIZE * _song.notes[curSec].lengthInSteps);
			gridBG.x -= GRID_SIZE;
			add(gridBG);

			remove(gridBlackLine);
			gridBlackLine = new FlxSprite(gridBG.x + (gridBG.width - GRID_SIZE) / 2 + GRID_SIZE).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
			add(gridBlackLine);
	
			remove(gridBlackLine2);
			gridBlackLine2 = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
			add(gridBlackLine2);
		}

		var designatedXPos = (640 + GRID_SIZE / 2 + (_song.mania > 0 ? 160 : 0));
		if (UI_box.x != designatedXPos)
		{
			UI_box.x = designatedXPos;
			tipTextGroup.forEach(function(text:FlxText)
			{
				text.x = UI_box.x;
			});
		}
	
		var sectionInfo:Array<Dynamic> = _song.notes[curSec].sectionNotes;

		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSec].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSec)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						trace('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		var beats:Float = getSectionBeats();
		for (i in sectionInfo)
		{	
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];
			var daType = i[3];

			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);

			if (daSus > 0)
			{
				var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
				note.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * _song.notes[curSec].lengthInSteps, 0, gridBG.height)));
				if(sustainVis.height < 1) sustainVis.height = 1; //Prevents error of invalid height
				curRenderedSustains.add(sustainVis);
			}

			if(i[3] != null && note.noteType != null && note.noteType.length > 0) {
				var typeInt:Null<Int> = noteTypeMap.get(i[3]);
				var theType:String = '' + typeInt;
				if(typeInt == null) theType = '?';

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}

			note.mustPress = _song.notes[curSec].mustHitSection;
			if(i[1] > 3) note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (i in _song.events)
		{
			if(endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, false);
				curRenderedNotes.add(note);

				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
				if(note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if(note.eventLength > 1) daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
				//trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
			}
		}
	}

	function setupSusNote(note:Note, beats:Float):FlxSprite {
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * (_song.notes[curSec].lengthInSteps / 16)) + (GRID_SIZE * (_song.notes[curSec].lengthInSteps / 16)) - GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * (_song.notes[curSec].lengthInSteps / 16) / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1; //Prevents error of invalid height

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		return spr;
	}

	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		return GRID_SIZE * beats * 4 * (_song.notes[curSec].lengthInSteps / 16) * value + gridBG.y;
	}

	private function addSection(lengthInSteps:Int = 16, sectionBeats:Int = 4):Void
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			bfAltAnim: false,
			dadCrossfade: false,
			bfCrossfade: false,
			dType: 0
		};

		_song.notes.push(sec);
	}

	private function newSection(lengthInSteps:Int = 16, mustHitSection:Bool = false, altAnim:Bool = true, bfAltAnim:Bool = true, ?sectionBeats:Int = 4):SwagSection
	{
		//do nothing fuck you
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			bfAltAnim: false,
			dadCrossfade: false,
			bfCrossfade: false,
			dType: 0
		};

		return sec;
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if(noteDataToCheck > -1)
		{
			if(note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					break;
				}
			}
		}
		else
		{
			for (i in _song.events)
			{
				if(i != curSelectedNote && i[0] == note.strumTime)
				{
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					changeEventSelected();
					break;
				}
			}
		}
	
		updateGrid();
		updateNoteUI();
	}

	function changeEventSelected(change:Int = 0)
	{
		if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
		{
			curEventSelected += change;
			if(curEventSelected < 0) curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if(curEventSelected >= curSelectedNote[1].length) curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;
		
		lastNote = note;

		if (noteDataToCheck > -1)
		{
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					if(i == curSelectedNote) curSelectedNote = null;
					//FlxG.log.add('FOUND EVIL NOTE');
					_song.notes[curSec].sectionNotes.remove(i);
					break;
				}
			}
		}
		else //Events
		{
			for (i in _song.events)
			{
				if(i[0] == note.strumTime)
				{
					if(i == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					//FlxG.log.add('FOUND EVIL EVENT');
					_song.events.remove(i);
					break;
				}
			}
		}
		
		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote(?n:Note):Void
	{
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		//Very rough way of adding burning notes, if Kade wants to make this better, go ahead.
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE) + (FlxG.keys.pressed.ALT ? 8 : 0);

		var noteSus = 0;
		var noteType = currentType;

		if(noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, noteTypeIntMap.get(noteType)]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		}
		else
		{
			var event = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;
			_song.events.push([noteStrum, [[event, text1, text2]]]);
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
			changeEventSelected();
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			//_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus]);
		}

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;

			for (i in _song.notes)
			{
				var swagLength = i.lengthInSteps;

				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;

				daLength += swagLength;

				if (sec != null && sec == i)
				{
					trace('swag loop??');
					break;
				}
			}

			return daLength;
	}*/
	private var daSpacing:Float = 0.3;

	function loadLevel():Void
	{
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		if (CoolUtil.difficulties[PlayState.storyDifficulty] != "Normal")
			PlayState.SONG = Song.loadFromJson(song.toLowerCase()+"-"+CoolUtil.difficulties[PlayState.storyDifficulty], song.toLowerCase());		
		else
			PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());

		if (Main.hiddenSongs.contains(song.toLowerCase()) && !Main.isHidden || song.toLowerCase() == 'restore' && !Main.restoreUnlocked || song.toLowerCase() == 'deathmatch-holo' && !Main.deathHolo)
			LoadingState.loadAndSwitchState(new GoFindTheSecretState());
		else
			LoadingState.loadAndSwitchState(new ChartingState());	
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		LoadingState.loadAndSwitchState(new ChartingState());
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function saveLevel()
	{
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	private function loadEvents()
	{
		var songName:String = Paths.formatToSongPath(_song.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson(songName + '/events')) || #end FileSystem.exists(file))
		#else
		if (OpenFlAssets.exists(file))
		#end
		{
			trace('events found!');
			_song.events = [];
			updateGrid();
			var events:SwagSong = Song.loadFromJson('events', songName);
			_song.events = events.events;
			changeSection(curSec);
		}
	}

	private function saveEvents()
	{
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var eventsSong:Dynamic = {
			events: _song.events
		};
		var json = {
			"song": eventsSong
		}

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}