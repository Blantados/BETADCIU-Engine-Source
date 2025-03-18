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

//new loading
import flixel.addons.util.FlxAsyncLoop;
import haxe.Json;

using StringTools;

//haven't started this yet
class CustomLoading extends MusicBeatState
{
    var toCache = 0;
    var finishedCache = 0;

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

    var bg:FlxSprite;
    var titlestatebg:FlxBackdrop;

    //new loading stuff:
    public var loadBar:FlxBar;
    public var initLoop:FlxAsyncLoop;
    public var charList:Array<String> = [];
    public var stageList:Array<String> = [];
    public var curCacheIndex:Int = 0;

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

        if (PlayState.isNeonight){
            suf = "-neo" + (FlxG.save.data.stageChange ? "" : "-noStage");				
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

        text = new FlxText(0, FlxG.height - 80, FlxG.width - 100,"Loading "+ PlayState.SONG.song + (isABETADCIU ? " But Every Turn A Different Cover is Used..." : "..."),32);
        text.size = 32;
        text.alignment = FlxTextAlign.CENTER;
        text.borderColor = FlxColor.BLACK;
		text.borderSize = 3;
		text.borderStyle = FlxTextBorderStyle.OUTLINE;
        text.screenCenter(X);
    
        kadeLogo = new FlxSprite(FlxG.width / 2, FlxG.height / 2).loadGraphic(Paths.image('KadeEngineLogo'));
        kadeLogo.x -= kadeLogo.width / 2 - 200;
        kadeLogo.y -= kadeLogo.height / 2 + 100;
        kadeLogo.setGraphicSize(Std.int(kadeLogo.width * 0.8));
        kadeLogo.x += 100;

       // kadeLogo.alpha = 0;

        //trace("caching music...");
    
        toCache = 0;
        finishedCache = 0;

        if (FileSystem.exists(Paths.txt(songLowercase  + "/preload" + suf)))
        {
            charList = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload" + suf));
            toCache += charList.length;
        }

        if (FileSystem.exists(Paths.txt(songLowercase  + "/preload-stage" + suf)) && FlxG.save.data.stageChange)
        {
            stageList = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload-stage" + suf));
            toCache += stageList.length;
        }

		initLoop = new FlxAsyncLoop(toCache, cacheItem, 1);
        add(initLoop);
		
		// create a fancy progress bar
		loadBar = new FlxBar(0, 0, LEFT_TO_RIGHT, FlxG.width - 120, 50, null, "", 0, 100, true);
        loadBar.createFilledBar(0xFF000000, bg.color);
		loadBar.value = 0;
		loadBar.screenCenter();
        loadBar.y = (text.y - loadBar.height / 2) + (text.height / 2);

        var loadBarBG:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(loadBar.width) + 20, Std.int(loadBar.height) + 20, FlxColor.BLACK);
        loadBarBG.screenCenter(X);
        loadBarBG.y = loadBar.y - (loadBarBG.height / 2) + (loadBar.height / 2);

        add(loadBarBG);
        add(loadBar);
        
        add(kadeLogo);
        add(text);
        

        new FlxTimer().start(2, function(tmr:FlxTimer)
        {
            initLoop.start();
            //cache();
        });

        super.create();
    }

    override function update(elapsed) 
    {
        if (FlxG.keys.justPressed.ESCAPE)
        {
            persistentUpdate = false;
            LoadingState.loadAndSwitchState(new PlayState());
        }

        if (initLoop.finished && !loaded)
        {
            initLoop.kill();
            initLoop.destroy(); 

            PlayState.curStage = PlayState.SONG.stage;
            Assets.cache.clear("shared:assets/shared/images/characters/jsons"); //it doesn't take that much time to read from the json anyway.
            trace("Finished caching...");
    
            loaded = true;
            LoadingState.loadAndSwitchState(new PlayState());
        }

        super.update(elapsed);
    }

    
    public function cacheItem(){
        var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle': songLowercase = 'dadbattle';
			case 'philly-nice': songLowercase = 'philly';
			case 'scary-swings': songLowercase = 'scary swings';
			case 'my-sweets': songLowercase = 'my sweets';
		}
        
        var listToCheck:Array<String> = [];
        
        if (listIsPopulated(charList)){
            listToCheck = charList;
        }else if (listIsPopulated(stageList)){
            listToCheck = stageList;
        }

        if (listToCheck.length < 1){
            return;
        }

        if (listIsPopulated(charList) && listIsPopulated(stageList) && curCacheIndex == charList.length){
            curCacheIndex = 0;
            listToCheck = stageList;
        }

        var itemData:Array<String> = listToCheck[curCacheIndex].split(' ');
        
        if (listToCheck == charList){
            var charFile:CharacterFile = loadCharFile(itemData[0]);
            var charImage = charFile.image;

            var imagePath = Paths.image(charImage);
				
            if (!Paths.currentTrackedAssets.exists(charImage)){
                {
                    if (Assets.exists(imagePath) && !FileSystem.exists(imagePath) && !FileSystem.exists(Paths.modsImages(imagePath)))
                        Paths.cacheImage(charImage, 'shared', false, !charFile.no_antialiasing);
                    else
                        trace("are these even loading " + charImage);
                        Paths.cacheImage(charImage, 'preload', false, !charFile.no_antialiasing);	
                }		
            }

            var charLuaFile:String = 'images/characters/luas/' + itemData[0];

            if (FileSystem.exists(Paths.modFolders('characters/' + itemData[0] + '.lua')) || FileSystem.exists(FileSystem.absolutePath("assets/shared/" + charLuaFile + '.lua')) || FileSystem.exists(Paths.lua2(charLuaFile))){
                PlayState.startCharLuas.push(itemData[0]);
            }       

            trace("Character " + itemData[0] + " found!");
        }else if (listToCheck == stageList){
            sys.thread.Thread.create(() -> {
                var loadedStage = new Stage(itemData[0], true);
                trace("Stage " + itemData[0] + " found!");
            });   
        }

        finishedCache++;
        curCacheIndex++;

        loadBar.value = (finishedCache / toCache) * 100;
    }

    /*function cache()
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
                finishedCache++;
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
                finishedCache++;
            }

            PlayState.curStage = PlayState.SONG.stage;
        }
    }*/

    public function listIsPopulated(list:Array<String>){
        return list != null && list.length > 0;
    }

    public function loadCharFile(char:String){
        var characterPath:String = 'images/characters/jsons/' + char;

		var path:String = Paths.jsonNew(characterPath);

		#if MODS_ALLOWED
        if (FileSystem.exists(Paths.modFolders('characters/'+char+'.json')) || Assets.exists(Paths.modFolders('characters/'+char+'.json'))){
            path = Paths.modFolders('characters/'+char+'.json');
        }
		#end

		if (!FileSystem.exists(path) && !Assets.exists(path))
		{
			trace('oh no missingno');
			path = Paths.jsonNew('images/characters/jsons/' + Character.DEFAULT_CHARACTER); //If a character couldn't be found, change to bf just to prevent a crash
		}

		var rawJson:Dynamic;
		rawJson = (FileSystem.exists(path) ?  File.getContent(path) : Assets.getText(path));

		var json:CharacterFile = cast Json.parse(rawJson);
		return json;
    }
}