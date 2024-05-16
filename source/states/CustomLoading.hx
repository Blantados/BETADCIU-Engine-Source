package states;

import lime.app.Application;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.ui.FlxBar;
import haxe.Exception;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import flixel.addons.display.FlxBackdrop;

import objects.Character;
import objects.Stage;

using StringTools;

//haven't started this yet
class CustomLoading extends MusicBeatState
{
    var toBeDone = 0;
    var done = 0;

    var loaded = false;

    var text:FlxText;
    var kadeLogo:FlxSprite;

    public static var bitmapData:Map<String,FlxGraphic>;

    var images = [];
    var music = [];
    var charts = [];
    var character:Character;
    var Stage:Stage;
    var suf:String = '';
    var bar:FlxBar;

    var bg:FlxSprite;
    var titlestatebg:FlxBackdrop;

    public var isABETADCIU:Bool = false;

	override function create()
	{
        persistentUpdate = true;
        FlxG.mouse.visible = false;

        FlxG.worldBounds.set(0,0);

        bg = new FlxSprite().loadGraphic(Paths.image('menuBGTemplate2'));
        bg.color = FlxG.random.color();
        add(bg);

        titlestatebg = new FlxBackdrop(Paths.image('titleGrid'), XY);
		titlestatebg.velocity.set(200, 110);
		titlestatebg.updateHitbox();
		titlestatebg.alpha = 0.4;
		titlestatebg.screenCenter(X);
		add(titlestatebg);

        var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle': songLowercase = 'dadbattle';
			case 'philly-nice': songLowercase = 'philly';
			case 'scary-swings': songLowercase = 'scary swings';
			case 'my-sweets': songLowercase = 'my sweets';
		}

        PlayState.customLoaded = true;

        if (PlayState.isBETADCIU || PlayState.isNeonight || PlayState.isVitor)
            isABETADCIU = true;

        // the suffixes. will add more later
        if (PlayState.isBETADCIU && FileSystem.exists(Paths.lua(songLowercase  + "/modchart-betadciu")))
			suf = '-betadciu';

        if (PlayState.isNeonight)
		{
			if (!FlxG.save.data.stageChange)
				suf = '-neo-noStage';				
			else
				suf = '-neo';				
		}
        
		if (PlayState.isVitor)
			suf = '-vitor';		

        if (PlayState.isBETADCIU && CoolUtil.difficulties[0] == "Guest")
        {
            if (!FlxG.save.data.stageChange && FileSystem.exists(Paths.lua(PlayState.SONG.song.toLowerCase()  + "/modchart-guest-noStage")))
                suf = '-guest-noStage';
            else
                suf = '-guest';	
        }

        text = new FlxText(25, FlxG.height / 2 + 175,FlxG.width - 100,"Loading "+ PlayState.SONG.song + (isABETADCIU ? " But Every Turn A Different Cover is Used..." : "..."),32);
        text.size = 32;
        text.alignment = FlxTextAlign.CENTER;
        text.borderColor = FlxColor.BLACK;
		text.borderSize = 3;
		text.borderStyle = FlxTextBorderStyle.OUTLINE;
    
        kadeLogo = new FlxSprite(FlxG.width / 2, FlxG.height / 2).loadGraphic(Paths.image('KadeEngineLogo'));
        kadeLogo.x -= kadeLogo.width / 2 - 200;
        kadeLogo.y -= kadeLogo.height / 2 + 100;
        kadeLogo.setGraphicSize(Std.int(kadeLogo.width * 0.8));
        kadeLogo.x += 100;

       // kadeLogo.alpha = 0;

        //trace("caching music...");
    
        toBeDone = 0;

        if (FileSystem.exists(Paths.txt(songLowercase  + "/preload" + suf)))
        {
            var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload" + suf));
            toBeDone += characters.length;
        }

        if (FileSystem.exists(Paths.txt(songLowercase  + "/preload-stage" + suf)))
        {
            var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload-stage" + suf));
            toBeDone += characters.length;
        }
            

        add(kadeLogo);
        add(text);
        
        new FlxTimer().start(2, function(tmr:FlxTimer)
        {
             cache();
        });
       
        trace('starting caching..');
        
        // update thread

        sys.thread.Thread.create(() -> {
           //
        });

        // cache thread

        super.create();
    }

    var calledDone = false;

    override function update(elapsed) 
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ESCAPE)
        {
            persistentUpdate = false;
            LoadingState.loadAndSwitchState(new PlayState());
        }
    }


    function cache()
    {
        var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle': songLowercase = 'dadbattle';
			case 'philly-nice': songLowercase = 'philly';
			case 'scary-swings': songLowercase = 'scary swings';
			case 'my-sweets': songLowercase = 'my sweets';
		}

        if (FileSystem.exists(Paths.txt(songLowercase  + "/preload" + suf)))
        {
            var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload" + suf));
            for (i in 0...characters.length)
            {
                var data:Array<String> = characters[i].split(' ');
                character = new Character (0, 0, data[0]);

                var luaFile:String = 'images/characters/luas/' + data[0];

                if (FileSystem.exists(Paths.modFolders('characters/'+data[0]+'.lua')) || FileSystem.exists(FileSystem.absolutePath("assets/shared/"+luaFile+'.lua')) || FileSystem.exists(Paths.lua2(luaFile)))
                    PlayState.startCharLuas.push(data[0]);

                trace ('found ' + data[0]);
                done++;
            }
        }   
        
        if (FileSystem.exists(Paths.txt(songLowercase  + "/preload-stage"+suf)) && FlxG.save.data.stageChange)
        {
            var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload-stage"+suf));

            for (i in 0...characters.length)
            {
                var data:Array<String> = characters[i].split(' ');
                Stage = new Stage(data[0], true);
                trace ('stages are ' + data[0]);
            }

            PlayState.curStage = PlayState.SONG.stage;
        }

        Assets.cache.clear("shared:assets/shared/images/characters/jsons"); //it doesn't take that much time to read from the json anyway.

        trace("Finished caching...");

        loaded = true;

        LoadingState.loadAndSwitchState(new PlayState());
    }

}