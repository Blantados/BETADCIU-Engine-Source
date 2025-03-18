import objects.ABotSpeaker;
import funkin.vis.dsp.SpectralAnalyzer;

var abot:ABotSpeaker;

function onCreate(){
    abot = new ABotSpeaker(game.gf.x - 40, game.gf.y + 327);
    abot.scrollFactor.set(0.95, 0.95);
    abot.antialiasing = ClientPrefs.data.antialiasing;

    for (i in [abot.bg, abot.eyeBg, abot.eyes, abot.speaker]) {
        if (i == abot.bg) continue;
        i.shader = game.gf.shader;
    }
    for (i in abot.vizSprites) i.shader = game.gf.shader;

	if(gf.curCharacter != 'nene'){
        abot.bg.visible = false;
        abot.eyeBg.visible = false;
        abot.eyes.visible = false;
        abot.speaker.visible = false;
	}

    game.addBehindGF(abot);
    game.variables.set("abot", abot);
}

var startVis:Bool = true;

function onBeatHit(){
    if (curBeat % game.gfSpeed == 0){
		abot.speaker.anim.play('anim', true);
    }
}

var abotAppears:Bool = true;

function onStepHit(){
    if (startVis){ // "onSongStart" function don't work
        abot.snd = FlxG.sound.music;
        startVis = false;
    }

    if(gf.curCharacter == 'nene'){
        abotAppears = true;
    }else{
        abotAppears = false;
    }

	if(abotAppears){
        abot.bg.visible = true;
        abot.eyeBg.visible = true;
        abot.eyes.visible = true;
        abot.speaker.visible = true;
	}else{
        abot.bg.visible = false;
        abot.eyeBg.visible = false;
        abot.eyes.visible = false;
        abot.speaker.visible = false;
    }
}

function onSectionHit(){
    if(!mustHitSection) lookLeft();

    if(mustHitSection) lookRight();
}

var lookingAtRight:Bool = true;

function lookLeft(){
    if(lookingAtRight) abot.eyes.anim.play('lookleft', true);
    lookingAtRight = false;
}

function lookRight(){
    if(!lookingAtRight) abot.eyes.anim.play('lookright', true);
    lookingAtRight = true;
}