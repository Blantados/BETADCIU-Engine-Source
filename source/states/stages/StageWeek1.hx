package states.stages;

import states.stages.objects.*;
import objects.Character;

class StageWeek1 extends BaseStage
{
	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleFog:DadBattleFog;

	public static var inGameplay:Bool = true;
	override function create()
	{
		var stageVars:Map<String, FlxSprite> = new Map<String, FlxSprite>(); // offset menu fix.

		if(FlxG.state is options.NoteOffsetState){ 
			inGameplay = false;
		}
		
		if (inGameplay){
			if (!PlayState.instance.variables.exists("stageVariables")){
				PlayState.instance.variables.set("stageVariables", new Map<String, FlxSprite>());
			}
			stageVars = PlayState.instance.variables.get("stageVariables");
		}

		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		if (inGameplay) stageVars.set("bg", bg);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		if (inGameplay) stageVars.set("stageFront", stageFront);
		add(stageFront);
		if(!ClientPrefs.data.lowQuality) {
			var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			if (inGameplay) stageVars.set("stageLight", stageLight);
			add(stageLight);
			var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			stageLight.flipX = true;
			if (inGameplay) stageVars.set("stageLight2", stageLight);
			add(stageLight);

			var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			if (inGameplay) stageVars.set("stageCurtains", stageCurtains);
			add(stageCurtains);
		}
	}
	override function eventPushed(event:objects.Note.EventNote)
	{
		if (PlayState.curStage.toLowerCase() != "stage" || PlayState.curStage.toLowerCase() != "stageweek1") 
			return; 

		switch(event.event)
		{
			case "Dadbattle Spotlight":
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				PlayState.instance.variables.get("stageVariables").set("dadbattleBlack", dadbattleBlack);
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				PlayState.instance.variables.get("stageVariables").set("dadbattleLight", dadbattleLight);
				add(dadbattleLight);

				dadbattleFog = new DadBattleFog();
				dadbattleFog.visible = false;
				PlayState.instance.variables.get("stageVariables").set("dadbattleFog", dadbattleFog);
				add(dadbattleFog);
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, value3:String, flValue1:Null<Float>, flValue2:Null<Float>, flValue3:Null<Float>, strumTime:Float)
	{
		if (PlayState.curStage.toLowerCase() != "stage" || PlayState.curStage.toLowerCase() != "stageweek1") 
			return; 

		switch(eventName)
		{
			case "Dadbattle Spotlight":
				if(flValue1 == null) flValue1 = 0;
				var val:Int = Math.round(flValue1);

				switch(val)
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleFog.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
						FlxTween.tween(dadbattleFog, {alpha: 0.7}, 1.5, {ease: FlxEase.quadInOut});

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleFog, {alpha: 0}, 0.7, {onComplete: function(twn:FlxTween) dadbattleFog.visible = false});
				}
		}
	}
	override public function destroy():Void {
		super.destroy();
	}
}