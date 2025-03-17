function onCreate()
	-- -- background shit

	--still testing. doesn't work quite well for custom stages
	makeLuaSprite('bg', 'stageback', -600, -200);
	addLuaSprite('bg', false);

	makeLuaSprite('stageFront', 'stagefront', -650, 600);
	scaleObject('stageFront', 1.1, 1.1)
	--setProperty('stageFront.scale.x', 1.1)
	--setProperty('stageFront.scale.y', 1.1)
	addLuaSprite('stageFront', false);

	makeLuaSprite('stageCurtains', 'stagecurtains', -500, -300);
	scaleObject('stageCurtains', 0.9, 0.9)
	--setProperty('stageCurtains.scale.x', 0.9)
	--setProperty('stageCurtains.scale.y', 0.9)
	addLuaSprite('stageCurtains', 2);

	-- close(true); --For performance reasons, close this script once the stage is fully loaded, as this script won't be used anymore after loading the stage
end

-- -350 + Math.sin((Conductor.songPosition / 1000) * (Conductor.bpm / 60) * 1.5) * 12.5;

function onUpdate(elapsed)
	-- getSongPosition();
end