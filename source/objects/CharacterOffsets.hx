package objects;

import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.app.Application;

using StringTools;

//bcuz god damn it. those offset things in playstate take up a bunch of space

class CharacterOffsets
{
	public var daOffsetArray:Array<Float> = [0, 0, 0, 0, 0, 0];
	public var hasOffsets:Bool = true;

	public function new(curCharacter:String = 'dad', isPlayer:Bool = false, ?isGF:Bool = false)
	{
		//in order this is +x, +y, +camPosX, +camPosY, +camPosX from midpoint, +camPosY from midpoint.
		daOffsetArray = [0, 0, 0, 0, 0, 0];

		if (isGF)
		{
			switch(curCharacter)
			{
				case 'gf-peri-whitty': daOffsetArray = [-230, -80, 0, 0, 0, 0];
				case 'gf-tea-tankmen': daOffsetArray = [-200, -80, 0, 0, 0, 0];
				case 'gf-sarv':  daOffsetArray = [105, 15, 0, 0, 0, 0];
				case 'gf-bf-radio': daOffsetArray = [-20, 0, 0, 0, 0, 0];
				case 'gf-edd': 
					if (!PlayState.curStage.contains('school'))
						daOffsetArray = [100, 300, 0, 0, 0, 0];
				case 'gf-judgev2': daOffsetArray = [50, 80, 0, 0, 0, 0];
				case 'gf-christmas': daOffsetArray = [-50, 0, 0, 0, 0, 0];
			}
			return;
		}
		if (!isPlayer)
		{
			switch (curCharacter)
			{
				case 'spooky-pelo' | 'tankman' | 'tankman-animations':
					daOffsetArray = [0, 200, 0, 0, 0, 0];
				case 'matt':
					daOffsetArray = [20, 310, 0, 0, 0, 0];
				case 'spooky' | 'gura-amelia' | 'gura-amelia-bw' | 'amesame-shutup':
					daOffsetArray = [-100, 190, 0, 0, 0, 0];
					if (curCharacter == 'spooky') daOffsetArray[1] = 200;
				case 'void':
					daOffsetArray = [-350, -30, 0, 0, 0, 0];
				case 'pompom-mad':
					daOffsetArray = [0, 255, 0, 0, 0, 0];
				case 'hallow':
					daOffsetArray = [-120, 50, 0, 0, 0, 0];
				case 'bf-sans-new':
					daOffsetArray = [-120, 250, 0, 0, 0, 0];
				case 'bf' | 'bf-confused':
					daOffsetArray = [0, 350, 0, 0, 0, 0];
				case 'taki':
					daOffsetArray = [-90, -100, 0, 0, 0, 0];
				case 'oswald-happy' | 'oswald-angry':
					daOffsetArray = [-90, 240, 0, 0, 0, 0];
				case 'mia' | 'mia-lookstraight' | 'mia-wire':
					daOffsetArray = [80, 140, 0, 0, 250, -100];			
				case 'sayori':
					daOffsetArray = [0, 110, 400, 0, 0, 0];
				case 'natsuki':
					daOffsetArray = [60, 170, 400, 0, 0, 0];
				case 'yuri-crazy' | 'yuri-crazy-bw':
					daOffsetArray = [20, 112, 400, 0, 0, 0];
				case 'yuri':
					daOffsetArray = [20, 0, 400, 0, 0, 0];
				case 'monika-real':
					daOffsetArray = [-80, -10, 400, 0, 0, 0];
				case 'bigmonika':
					daOffsetArray = [0, 0, 0, 0, -100, -200];	
				case 'yukichi-police':
					daOffsetArray = [-70, 130, 0, 0, 0, 0];
				case 'exe' | 'exe-bw':
					daOffsetArray = [100, 175, 0, 0, 0, 0];
				case 'duet-sm':
					daOffsetArray = [150, 380, 0, 0, 300, 0];
				case 'sunky':
					daOffsetArray = [-210, 130, 0, 0, 0, 0];
				case 'cj-ruby' | 'cj-ruby-both':
					daOffsetArray = [-50, 0, 0, 0, 0, 0];
				case 'bosip' | 'demoncass':
					daOffsetArray = [0, -50, 0, 0, 0, 0];
				case 'hex-virus' | 'agoti-wire' | 'agoti-glitcher' | 'agoti-mad' | 'haachama' | 'haachama-blue':
					daOffsetArray = [0, 100, 0, 0, 0, 0];	
				case 'whittyCrazy' | 'whittyCrazy-9key':
					daOffsetArray = [-105, 20, 400, 0, 0, 0];
				case 'ruv':
					daOffsetArray = [0, -70, 0, 0, 0, 0];	
				case 'sarvente' | 'sarvente-dark' | 'sarvente-worried' | 'sarvente-worried-blue':
					daOffsetArray = [-85, -25, 0, 0, 0, 0];	
				case 'monster-christmas' | 'monster':
					daOffsetArray = [-60, 90, 0, 0, 0, 0];	
					if (curCharacter == 'monster-christmas') daOffsetArray[1] = 50;
				case 'dad' | 'shaggy' | 'lila' | 'kapi' | 'kapi-angry':
					daOffsetArray = [0, -10, 400, 0, 0, 0];
					if (curCharacter == 'kapi') daOffsetArray[1] = -40;
				case 'whitty' | 'whitty-b3':
					daOffsetArray = [20, 10, 400, 0, 0, 0];
				case 'midas' | 'midas-double' | 'midas-r':
					daOffsetArray = [20, -10, 400, 0, 0, 0];
				case 'beepie':
					daOffsetArray = [-25, 215, 0, 0, 0, 0];
				case 'dad-mad':
					daOffsetArray = [-30, -10, 400, 0, 0, 0];
				case 'bf-blantad':
					daOffsetArray = [0, -75, 0, 0, 0, 0];	
				case 'annie-bw' | 'phil' | 'alya':
					daOffsetArray = [0, 350, 600, 0, 150, -100];	
				case 'pico' | 'picoCrazy':
					daOffsetArray = [-40, 300, 600, 0, 150, -100];	
				case 'bob2' | 'peri':
					daOffsetArray = [70, 50, 0, 0, 0, 0];
					if (curCharacter == 'peri') daOffsetArray[0] = -50;
				case 'botan':
					daOffsetArray = [-135, 245, 0, 0, 0, 0];
				case 'neko-crazy':
					daOffsetArray = [-50, 230, 0, 0, 300, 0];
				case 'nene' | 'liz':
					daOffsetArray = [0, 300, 600, 0, 0, 0];
				case 'bf-carol':
					daOffsetArray = [-50, 340, 600, 0, 0, 0];
				case 'kou':
					daOffsetArray = [-20, 270, 600, 0, 0, 0];
				case 'bf-annie':
					daOffsetArray = [-50, 350, 600, 0, 0, 0];
				case 'bf-frisk' | 'bf-gf' | 'bf-aloe' | 'bf-kaity' | 'bf-six' | 'bf-aloe-deathless':
					daOffsetArray = [-30, 350, 600, 0, 0, 0];		
				case 'mario':
					daOffsetArray = [70, 200, 0, 0, 0, 0];	
				case 'little-man':
					daOffsetArray = [150, 640, 0, 0, 0, 0];	
				case 'retro':
					daOffsetArray = [35, -80, 600, 0, 0, 0];	
				case 'bf-sonic':
					daOffsetArray = [-100, 350, 0, 0, 0, 0];
				case 'bico-christmas':
					daOffsetArray = [-500, 100, 0, 0, 0, 0];
				case 'senpai' | 'monika' | 'senpai-angry' | 'kristoph-angry' | 'senpai-giddy' | 'baldi-angry-pixel' | 'mangle-angry' | 'monika-angry' | 'green-monika' | 'neon' 
				| 'matt-angry' | 'jackson' | 'mario-angry' | 'colt-angryd2' | 'colt-angryd2corrupted' | 'miku-pixel' | 'josuke':
					if (PlayState.curStage.contains('school'))
						daOffsetArray = [150, 360, 0, 0, 300, 0];
					else
						daOffsetArray = [160, 260, 0, 0, 300, 0];
				case 'monika-finale':
					daOffsetArray = [15, 460, 0, 0, 300, 0];
				case 'lane-pixel':
					daOffsetArray = [210, 490, 0, 0, 300, -200];
				case 'bf-gf-pixel' | 'bf-pixel' | 'bf-botan-pixel':
					daOffsetArray = [150, 460, 0, 0, 300, 0];
				case 'bf-sky':
					daOffsetArray = [50, 230, 0, 0, 300, 0];
				case 'bf-whitty-pixel':
					daOffsetArray = [150, 400, 0, 0, 300, 0];
				case 'gura-amelia-pixel':
					daOffsetArray = [140, 400, 0, 0, 300, 0];
				case 'bitdad' | 'bitdadBSide' | 'bitdadcrazy':
					daOffsetArray = [0, 75, 0, 0, 300, 0];
				case 'spirit' | 'spirit-glitchy':
					daOffsetArray = [-150, 100, 0, 0, 300, 200];
				case 'sky-annoyed':
					daOffsetArray = [-130, 120, 0, 0, 0, 0];
				case 'sky-happy':
					daOffsetArray = [30, 230, 0, 0, 0, 0];
				case 'impostor' | 'impostor2':
					daOffsetArray = [-150, 400, 400, -200, 0, 0];
					if (curCharacter == 'impostor2')
						daOffsetArray[0] = -70;
				case 'bob' | 'angrybob':
					daOffsetArray = [-40, 280, 600, 0, 0, 0];
				case 'glitched-bob':
					daOffsetArray = [-20, 285, 600, 0, 0, 0];
				case 'austin':
					daOffsetArray = [-40, -130, 0, 0, 0, 0];
				case 'cjClone' | 'cj' | 'cj-new':
					if (PlayState.SONG.song.toLowerCase() == 'expurgation')
						daOffsetArray = [-250, -150, 0, 0, 0, 0];
					else
						daOffsetArray = [0, 0, 0, 0, 0, 0];		
				case 'exTricky':
					daOffsetArray = [-250, -365, 0, 0, 0, 0];							
				case 'momi':
					daOffsetArray = [-90, 60, 0, 0, 300, 0];
				case 'sh-carol' | 'sarvente-lucifer':
					daOffsetArray = [-65, -15, 0, 0, 0, 0];
				case 'roro':
					daOffsetArray = [-200, 0, 0, 0, 0, 0];
				case 'rosie' | 'rosie-angry' | 'rosie-furious':
					daOffsetArray = [-50, 100, 0, 0, 0, 0];
				case 'brody':
					daOffsetArray = [0, 110, 0, 0, 300, 0];
				case 'selever' | 'teto':
					daOffsetArray = [-50, -65, 0, 0, 300, 0];
					if (curCharacter == 'teto') daOffsetArray[1] == -50;
				case 'camellia' | 'camelliahalloween':
					daOffsetArray = [-300, -50, 0, 0, 0, 0];
				case 'exe-front':
					daOffsetArray = [-120, 50, 0, 0, 0, 0];
				case 'bf-pixeld4BSide' | 'bf-pixeld4' | 'bf-demoncesar-pixel':
					if (!PlayState.curStage.contains('school'))
						daOffsetArray = [300, 150, 0, 0, 0, 0];
				case 'rebecca':
					daOffsetArray = [-20, 0, 0, 500, 150, 100];
					if (!PlayState.curStage.contains('hungryhippo'))	
						daOffsetArray[1] = -50;
				case 'baldi-angry':
					daOffsetArray = [10, -70, 0, 500, 150, 100];
				case 'betty' | 'betty-bw':
					daOffsetArray = [0, 200, 0, 0, 0, 0];
				case 'woody':
					daOffsetArray = [65, 430, 0, 0, 0, 0];
				case 'twinsone' | 'twinstwo':
					daOffsetArray = [-160, -50, 0, 0, 0, 0];
				case 'neonight':
					daOffsetArray = [-110, 110, 0, 0, 0, 0];
				case 'arch':
					daOffsetArray = [-155, -280, 0, 0, 0, 0];
				case 'hd-spirit-drip' | 'hd-spirit':
					daOffsetArray = [-30, 0, 0, 0, 0, 0];
				case 'geese':
					daOffsetArray = [-21, -15, 0, 0, 0, 0];
				case 'exe-revie':
					daOffsetArray = [20, -30, 0, 0, 0, 0];
				case 'faker-transform':
					daOffsetArray = [-110, -40, 0, 0, 0, 0];
				case 'faker':
					daOffsetArray = [-30, 120, 0, 0, 0, 0];
				case 'taeyai':
					daOffsetArray = [-105, -50, 0, 0, 0, 0];
				case 'tom2'  | 'matt2' | 'edd2' | 'garcellotired' | 'garcellodead':
					daOffsetArray = [-115, 0, 0, 0, 0, 0];
				case 'kalisa':
					daOffsetArray = [-180, 145, 0, 0, 0, 0];
				case 'sunday':
					daOffsetArray = [55, 255, 0, 0, 0, 0];
				case 'sunday-guitar':
					daOffsetArray = [70, 260, 0, 0, 0, 0];
				case 'calli':
					daOffsetArray = [10, -10, 0, 0, 0, 0];
				case 'kazuki':
					daOffsetArray = [-40, 20, 0, 0, 0, 0];
				case 'sakuroma':
					daOffsetArray = [-240, -260, 0, 0, 0, 0];
				case 'cg5' | 'exgf':
					daOffsetArray = [50, 10, 0, 0, 0, 0];
					if (curCharacter == 'exgf') daOffsetArray[1] == -30;
				case 'richard2' | 'richard1':
					daOffsetArray = [-130, 40, 0, 0, 0, 0];
				case 'chara':
					daOffsetArray = [-5, 300, 0, 0, 0, 0];
				case 'happymouse2' | 'happymouse2-bw' | 'happymouse' | 'happymouse-bw':
					daOffsetArray = [-75, 60, 0, 0, 0, 0];
				case 'soul-tails' | 'soul-tails-bw':
					daOffsetArray = [70, 265, 0, 0, 0, 0];
				case 'cablecrow':
					daOffsetArray = [-240, -160, 0, 0, 0, 0];
				case 'tabi-crazy':
					daOffsetArray = [-30, 50, 0, 0, 0, 0];
				case 'sonic' | 'sonic-forced' | 'sonic-mad':
					daOffsetArray = [-150, 180, 0, 0, 0, 0];
					if (curCharacter == 'sonic-mad') daOffsetArray[0] == -120;
				case 'auditor':
					daOffsetArray = [-250, -50, 0, 0, 0, 0];
				case 'shadowbonnie-pixel':
					daOffsetArray = [70, -90, 0, 0, 0, 0];
				case 'beast-sonic':
					daOffsetArray = [-100, -80, 0, 0, 0, 0];
				case 'TDoll' | 'TDollAlt' | 'snow':
					daOffsetArray = [-80, 120, 0, 0, 0, 0];
					if (curCharacter == 'snow') daOffsetArray[0] = -70;
				case 'mami-holy':
					daOffsetArray = [-230, -50, 0, 0, 0, 0];
				case 'daidem':
					daOffsetArray = [-20, -150, 0, 0, 0, 0];
				case 'cassandra':
					daOffsetArray = [-10, 40, 0, 0, 0, 0];
				case 'sarvente-transform':
					daOffsetArray = [-200, -200, 0, 0, 0, 0];
				case 'sky-mad':
					daOffsetArray = [-50, 170, 0, 0, 0, 0];
				case 'ace' | 'kadedev' | 'parents-christmas' | 'parents-christmas-angel' | 'daisysoul' | 'fujiwara' | 'miku' | 'bana' | 'bana-wire' | 'mackiepom' | 'updike': //for characters who literally change one value
					daOffsetArray = [0, 0, 0, 0, 0, 0];
					switch (curCharacter)
					{
						case 'ace': daOffsetArray[1] = 25;
						case 'kadedev': daOffsetArray[0] = 60;
						case 'parents-christmas' | 'parents-christmas-angel': daOffsetArray[0] = -500;
						case 'daisysoul': daOffsetArray[0] = -25;
						case 'fujiwara' | 'mackiepom': daOffsetArray[1] = -20;
						case 'miku': daOffsetArray[0] = -40;
						case 'bana' | 'bana-wire': daOffsetArray[1] = 30;
						case 'updike': daOffsetArray[0] = -100;
					}
				case 'tricky' | 'lord-x':
					daOffsetArray = [-90, 100, 0, 0, 0, 0];
					if (curCharacter == 'lord-x') daOffsetArray[1] = 30;
				case 'bf-sticky-scream':
					daOffsetArray = [80, 365, 0, 0, 0, 0];
				case 'herobrine':
					daOffsetArray = [100, 200, 0, 0, 0, 0];
				case 'cc':
					daOffsetArray = [20, 170, 0, 0, 0, 0];
				case 'henry-angry':
					daOffsetArray = [90, 300, 0, 0, 0, 0];
				case 'lexi' | 'lexi-b3':
					daOffsetArray = [30, 160, 0, 0, 0, 0];
				case 'alucard':
					daOffsetArray = [-20, 0, 0, 0, 0, 0];
				case 'bf-sky-pixel':
					daOffsetArray = [80, 500, 0, 0, 0, 0];
				case 'bf-glitch-pixel':
					daOffsetArray = [150, 450, 0, 0, 0, 0];
				case 'foks':
					daOffsetArray = [0, 350, 0, 0, 0, 0];
				case 'agoti':
					daOffsetArray = [-70, -80, 0, 0, 0, 0];
				case 'freddy':
					daOffsetArray = [40, -40, 0, 0, 0, 0];
				case 'mel':
					daOffsetArray = [-80, 0, 0, 0, 0, 0];
				case 'neon-bigger':
					daOffsetArray = [100, 230, 0, 0, 0, 0];
				case 'opheebop':
					daOffsetArray = [-40, 120, 0, 0, 0, 0];
				case 'zardy':
					daOffsetArray = [-180, -30, 0, 0, 0, 240];
				case 'maijin-new' | 'majin-new-b3' | 'majin-new':
					daOffsetArray = [-30, 150, 0, 0, 0, 0];
				case 'tornsketchy':
					daOffsetArray = [-110, 150, 0, 0, 0, 0];
				case 'starecrown':
					daOffsetArray = [-140, -70, 0, 0, 0, 0];
				case 'yukichi-mad-city' | 'yukichi-mad':
					daOffsetArray = [-50, 0, 0, 0, 0, 0];
				case 'anders' | 'cyrix' | 'papyrus':
					daOffsetArray = [0, 0, 0, 0, 0, 0];
				case 'pompom':
					daOffsetArray = [30, 190, 0, 0, 0, 0];
				case 'hubert':
					daOffsetArray = [80, -20, 0, 0, 0, 0];
				case 'jevil': daOffsetArray = [50, 180, 0, 0, 0, 0];
				case 'jester': daOffsetArray = [-30, 210, 0, 0, 0, 0];
				case 'dr-springheel': daOffsetArray = [40, -90, 0, 0, 0, 0];
				case 'glitch-angry': daOffsetArray = [190, 270, 0, 0, 0, 0];
				default:
					daOffsetArray = [0, 0, 0, 0, 0, 0];
					hasOffsets = false;
			}
		}
		else if (isPlayer)
		{
			switch (curCharacter)
			{
				case 'mia' | 'mia-lookstraight' | 'mia-wire': daOffsetArray = [20, -220, 0, 0, 0, 0];
				case 'jevil': daOffsetArray = [-20, -170, 0, 0, 0, 0];
				case 'jester': daOffsetArray = [30, -140, 0, 0, 0, 0];
				case 'henry-angry': daOffsetArray = [150, -80, 0, 0, 0, 0];
				case 'taki': daOffsetArray = [-190, -450, 0, 0, 0, 0];
				case 'oswald-angry': daOffsetArray = [60, -110, 0, 0, 0, 0];
				case 'dr-springheel': daOffsetArray = [-120, -440, 0, 0, 0, 0];

				case 'updike' | 'bf-annie':
					daOffsetArray = [-50, 0, 0, 0, 0, 0];
					if (curCharacter == 'bf-annie') daOffsetArray[1] = -20;
				case 'void':
					daOffsetArray = [-150, -380, 0, 0, 0, 0];
				case 'cg5' | 'exgf':
					daOffsetArray = [-20, -340, 0, 0, 0, 0];
				case 'hallow':
					daOffsetArray = [-200, -300, 0, 0, 0, 0];
				case 'bomberman':
					daOffsetArray = [20, -170, 0, 0, 0, 0];
				case 'drunk-annie':
					daOffsetArray = [-230, -310, 0, 0, 0, 0];
				case 'twinsone' | 'twinstwo':
					daOffsetArray = [-120, -400, 0, 0, 0, 0];
				case 'makocorrupt':
					daOffsetArray = [-270, -450, 0, 0, 0, 0];
				case 'zipper':
					daOffsetArray = [-250, -340, 0, 0, 0, 0];
				case 'kazuki':
					daOffsetArray = [60, -310, 0, 0, 0, 0];
				case 'sakuroma':
					daOffsetArray = [-140, -620, 0, 0, 0, 0];	
				case 'baldi-angry':
					daOffsetArray = [-300, -420, 0, 500, 150, 100];
				case 'hex-virus' | 'hex-wire' | 'hex-virus-shaded':
					daOffsetArray = [-50, -220, 0, 0, 0, 0];
				case 'alya':
					daOffsetArray = [30, -10, 0, 0, 0, 0];
				case 'monika-real' | 'monika-real-sad-blue':
					daOffsetArray = [-155, -355, 0, 0, 0, 0];
				case 'cc':
					daOffsetArray = [-80, -180, 0, 0, 0, 0];
				case 'herobrine':
					daOffsetArray = [-750, 200, 0, 0, 0, 0];
				case 'hank':
					daOffsetArray = [-10, -170, 0, 0, 0, 0];
				case 'gold-side' | 'gold-side-blue':
					daOffsetArray = [30, -250, 0, 0, 0, 0];
				case 'auditor':
					daOffsetArray = [-130, -420, 0, 0, 0, 0];
				case 'sayori':
					daOffsetArray = [-50, -280, -400, 0, 0, 0];
				case 'retro' | 'sanford':
					daOffsetArray = [-60, -450, -400, 0, 0, 0];
					if (curCharacter == 'sanford') daOffsetArray[1] = -50;
				case 'natsuki':
					daOffsetArray = [0, -180, -400, 0, 0, 0];
				case 'impostor' | 'impostor2':
					daOffsetArray = [-170, 40, 0, 0, 0, 0];
				case 'yuri' | 'yuri-crazy' | 'yuri-crazy-bw':
					daOffsetArray = [-30, -238, -400, 0, 0, 0];
				case 'crazygf' | 'crazygf-bw':
					daOffsetArray = [50, -80, 0, 0, 0, 0];
				case 'bf-nene' | 'bf-nene-scream':
					daOffsetArray = [0, -70, 0, 0, 0, 0];
				case 'pico' | 'annie-bw' | 'phil' | 'nene' | 'ridzak':
					daOffsetArray = [0, -50, 0, 0, 0, 0];
					if (curCharacter == 'ridzak') daOffsetArray[0] = 60;
				case 'kou':
					daOffsetArray = [10, -80, 0, 0, 0, 0];
				case 'nene2':
					daOffsetArray = [-40, -40, 0, 0, 0, 0];
				case 'bf-demoncesar' | 'bf-demoncesar-trollge' | 'bf-demoncesar-bw' | 'bf-trollge-cas':
					daOffsetArray = [0, -50, 0, 0, 0, 0];
				case 'demongf' | 'demongf-city':
					daOffsetArray = [100, -100, 0, 0, 0, 0];
				case 'bf-cesar':
					daOffsetArray = [105, -50, 0, 0, 0, 0];
				case 'sunday':
					daOffsetArray = [55, -100, 0, 0, 0, 0];
				case 'monster' | 'monster-christmas':
					daOffsetArray = [20, -260, 0, 0, -100, -100];
					if (curCharacter == 'monster-christmas') daOffsetArray[1] = -300;
				case 'haachama':
					daOffsetArray = [20, -250, 0, 0, 0, 0];
				case 'opheebop':
					daOffsetArray = [-20, -230, 0, 0, 0, 0];
				case 'maijin-new' | 'majin-new-b3' | 'majin-new':
					daOffsetArray = [-150, -200, 0, 0, 0, 0];
				case 'senpai' | 'monika' | 'senpai-angry' | 'kristoph-angry' | 'senpai-giddy' | 'baldi-angry-pixel' | 'mangle-angry' | 'monika-angry' | 'green-monika' | 'neon' 
					| 'matt-angry' | 'jackson' | 'mario-angry' | 'colt-angryd2corrupted' | 'miku-pixel' | 'colt-angry-d2' | 'tricky-pixel' | 'blantad-pixel':
					if (PlayState.curStage.contains('school'))
						daOffsetArray = [0, -200, 0, 0, 0, 0];
					else
						daOffsetArray = [120, -70, 0, 0, 0, 0];
				case 'glitch-angry': daOffsetArray = [120, -80, 0, 0, 0, 0];
				case 'colt-angry':
					daOffsetArray = [120, -90, 0, 0, 0, 0];
				case 'bf-whitty-pixel':
					daOffsetArray = [0, -170, 0, 0, 0, 0];
				case 'gura-amelia' | 'spooky' | 'amesame-shutup':
					daOffsetArray = [10, -145, 0, 0, 0, 0];
				case 'bana' | 'bana-wire':
					daOffsetArray = [-100, -270, 0, 0, 0, 0];
				case 'cassandra':
					daOffsetArray = [0, -330, 0, 0, 0, 0];
				case 'tom2' | 'matt2' | 'edd2' | 'garcellotired' | 'garcellodead':
					daOffsetArray = [-270, -350, 0, 0, 0, 0];
				case 'bf-exgf':
					daOffsetArray = [-140, -410, 0, 0, 0, 0];
				case 'bf-blantad' | 'bb' | 'anchor' | 'agoti':
					daOffsetArray = [0, -400, 0, 0, 0, 0];
					if (curCharacter == 'anchor') daOffsetArray[0] = -90;	
				case 'dad' | 'hex' | 'bf-senpai-worried' | 'parents-christmas' | 'henry-blue' | 'whitty' | 'miku'
				| 'lila' | 'lila-pelo' | 'myra' | 'blantad-new' | 'blantad-watch' | 'blantad-blue' | 'blantad-scream' | 'bf-hd-senpai-angry' | 'bf-hd-senpai-dark' 
				| 'tabi-wire' | 'tabi-glitcher' | 'tabi' | 'ruv' | 'cj-ruby':
					daOffsetArray = [0, -350, 0, 0, 0, 0];
					if (curCharacter == 'ruv') daOffsetArray[1] = -420;
				case 'sarvente' | 'sarvente-dark' | 'sarvente-worried-blue':
					daOffsetArray = [-20, -375, 0, 0, 0, 0];	
				case 'mom-car' | 'mom' | 'bf-mom-car' | 'bf-mom' | 'coco' | 'coco-car':
					daOffsetArray = [10, -380, 0, 0, 0, 0];
					if (curCharacter.contains('coco'))daOffsetArray[1] = -400;
				case 'sarv-ruv' | 'sarv-ruv-both':
					daOffsetArray = [-100, -350, 0, 0, 0, 0];
				case 'sky-mad' | 'sky-pissed':
					daOffsetArray = [-50, -180, 0, 0, 0, 0];
				case 'botan':
					daOffsetArray = [50, -95, 0, 0, 0, 0];
				case 'bob':
					daOffsetArray = [-170, -70, 0, 0, 0, 0];
				case 'bosip':
					daOffsetArray = [0, -400, 0, 0, 0, 0];
				case 'bf-botan-pixel':
					daOffsetArray = [40, -90, 0, 0, 0, 0];
				case 'liz':
					daOffsetArray = [-50, -45, 0, 0, 0, 0];
				case 'selever':
					daOffsetArray = [40, -375, 0, 0, -100, -100];
				case 'bf-pump':
					daOffsetArray = [0, 50, 0, 0, 0, 0];
				case 'tord' | 'tom':
					daOffsetArray = [10, -250, 0, 0, 0, 0];
				case 'tankman' | 'bf-senpai-tankman':
					daOffsetArray = [0, -150, 0, 0, 0, 0];
				case 'ruby' | 'ruby-worried-night' | 'ruby-worried':
					daOffsetArray = [30, -370, 0, 0, 0, 0];
				case 'sh-carol' | 'sarvente-lucifer':
					daOffsetArray = [0, -625, 0, 0, 0, 0];
				case 'skye-r':
					daOffsetArray = [-100, -350, 0, 0, 0, 0];
				case 'taeyai':
					daOffsetArray = [0, -350, 0, 0, 0, 0];
				case 'bf-bbpanzu':
					daOffsetArray = [-30, -190, 0, 0, 0, 0];
				case 'bf-sky':
					daOffsetArray = [60, -110, 0, 0, 0, 0];
				case 'bf-tc':
					daOffsetArray = [30, -230, 0, 0, 0, 0];
				case 'ghostbros':
					daOffsetArray = [30, -100, 0, 0, 0, 0];
				case 'bf-sticky-scream':
					daOffsetArray = [-30, 5, 0, 0, 0, 0];
				case 'neonight':
					daOffsetArray = [-110, -250, 0, 0, 0, 0];
				case 'bf-aloe' | 'bf-aloe-confused' | 'bf-aloe-corrupt' | 'bf-aloe-bw' | 'bf-aloe-past' | 'bf-aloe-deathless':
					daOffsetArray = [30, -20, 0, 0, 0, 0];
				case 'macy':
					daOffsetArray = [20, -295, 0, 0, 0, 0];
				case 'ace':
					daOffsetArray = [-40, -315, 0, 0, 0, 0];
				case 'ron':
					daOffsetArray = [20, -90, 0, 0, 0, 0];
				case 'ash':
					daOffsetArray = [-30, -305, 0, 0, 0, 0];
				case 'jack':
					daOffsetArray = [75, -120, 0, 0, 0, 0];
				case 'tabi-crazy':
					daOffsetArray = [-80, -290, 0, 0, 0, 0];
				case 'nonsense' | 'nonsense-pissed' | 'nonsense-mad':
					daOffsetArray = [40, -220, 0, 0, 0, 0];
				case 'dust-sans':
					daOffsetArray = [-230, -360, 0, 0, 0, 0];
				case 'tails':
					daOffsetArray = [-110, -200, 0, 0, 0, 0];
				case 'bf-aloe-b3':
					daOffsetArray = [30, -20, 0, 0, 0, 0];
				case 'starecrown':
					daOffsetArray = [-240, -420, 0, 0, 0, 0];
				case 'henry':
					daOffsetArray = [-30, -470, 0, 0, 0, 0];
				case 'bf-pixeld4BSide' | 'bf-pixeld4' | 'bf-demoncesar-pixel' | 'bf-pixel' | 'bf-sonic-pixel' | 'bf-tankman-pixel' | 'bf-tankman-pixel-happy' | 'bf-senpai-pixel':
					if (!PlayState.curStage.contains('school'))
					{
						daOffsetArray = [190, 150, 0, 0, 0, 0];
						if (curCharacter.contains('tankman'))
						{
							daOffsetArray[0] -= 20;
							daOffsetArray[1] -= 20;
						}
					}
				case 'bf-carol':
					daOffsetArray = [-50, -10, 0, 0, 0, 0];
				case 'bf-gf' | 'bf-gf-demon':
					daOffsetArray = [60, -30, 0, 0, 0, 0];
				case 'trollge':
					daOffsetArray = [30, -315, 0, 0, 0, 0];
				case 'cyrix-crazy' | 'bf-dad':
					daOffsetArray = [0, -350, 0, 0, 0, 0];
				case 'yukichi-mad-city' | 'yukichi-mad':
					daOffsetArray = [-150, -350, 0, 0, 0, 0];
				case 'cj':
					daOffsetArray = [0, -350, 0, 0, 0, 0];
				default:
					daOffsetArray = [0, 0, 0, 0, 0, 0];
					hasOffsets = false;
			}
		}
	}
}