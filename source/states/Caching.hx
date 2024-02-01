package states;

import lime.app.Application;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.ui.FlxBar;
import haxe.Exception;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import sys.FileSystem;
import sys.io.File;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

using StringTools;

class Caching extends MusicBeatState
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


	override function create()
	{
        FlxG.mouse.visible = false;

        FlxG.worldBounds.set(0,0);

        bitmapData = new Map<String,FlxGraphic>();

        text = new FlxText(FlxG.width / 2, FlxG.height / 2 + 300,0,"Loading...");
        text.size = 34;
        text.alignment = FlxTextAlign.CENTER;
        text.alpha = 0;

        kadeLogo = new FlxSprite(FlxG.width / 2, FlxG.height / 2).loadGraphic(Paths.image('KadeEngineLogo'));
        kadeLogo.x -= kadeLogo.width / 2;
        kadeLogo.y -= kadeLogo.height / 2 + 100;
        text.y -= kadeLogo.height / 2 - 125;
        text.x -= 170;
        kadeLogo.setGraphicSize(Std.int(kadeLogo.width * 0.6));

        kadeLogo.alpha = 0;

		PlayerSettings.init();

		#if windows
		DiscordClient.initialize();

		Application.current.onExit.add (function (exitCode) {
			DiscordClient.shutdown();
		 });
		 
		#end

		
		Highscore.load();

		FlxG.save.bind('funkin', 'ninjamuffin99');

		KadeEngineData.initSave();


        if (FlxG.save.data.cacheImages)
        {
            trace("caching images...");

            for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/characters")))
            {
                if (!i.endsWith(".png"))
                    continue;
                images.push(i);
            }
        }

        trace("caching music...");

        for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/songs")))
        {
            music.push(i);
        }
    

        toBeDone = Lambda.count(images) + Lambda.count(music);

        var bar = new FlxBar(10,FlxG.height - 50,FlxBarFillDirection.LEFT_TO_RIGHT,FlxG.width,40,null,"done",0,toBeDone);
        bar.color = FlxColor.PURPLE;

        add(bar);

        add(kadeLogo);
        add(text);

        trace('starting caching..');
        
        // update thread

        sys.thread.Thread.create(() -> {
            while(!loaded)
            {
                if (toBeDone != 0 && done != toBeDone)
                    {
                        var alpha = HelperFunctions.truncateFloat(done / toBeDone * 100,2) / 100;
                        kadeLogo.alpha = alpha;
                        text.alpha = alpha;
                        text.text = "Loading... (" + done + "/" + toBeDone + ")";
                    }
            }
        
        });

        // cache thread

        sys.thread.Thread.create(() -> {
            cache();
        });

        super.create();
    }

    var calledDone = false;

    override function update(elapsed) 
    {
        super.update(elapsed);
    }


    function cache()
    {

        trace("LOADING: " + toBeDone + " OBJECTS.");

        for (i in images)
        {
            var replaced = i.replace(".png","");
            var data:BitmapData = BitmapData.fromFile("assets/shared/images/characters/" + i);
            trace('id ' + replaced + ' file - assets/shared/images/characters/' + i + ' ${data.width}');
            var graph = FlxGraphic.fromBitmapData(data);
            graph.persist = true;
            graph.destroyOnNoUse = false;
            bitmapData.set(replaced,graph);
            done++;
        }

        for (i in music)
        {
            FlxG.sound.cache(Paths.inst(i));
            FlxG.sound.cache(Paths.voices(i));
            trace("cached " + i);
            done++;
        }


        trace("Finished caching...");

        loaded = true;

        trace(Assets.cache.hasBitmapData('GF_assets'));

        FlxG.switchState(new TitleState());
    }

}