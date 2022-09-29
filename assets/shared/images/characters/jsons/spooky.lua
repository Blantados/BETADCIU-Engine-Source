function onCreate()
	-- background shit
	

--	close(true); --For performance reasons, close this script once the stage is fully loaded, as this script won't be used anymore after loading the stage
end

flipped = false

function onUpdate(elapsed)
    if getProperty('boyfriend.curCharacter') == 'spooky' and flipped == false then
        setProperty('iconP1.flipX', true) -- my work here is done
        flipped = true  
    end

    if flipped == true and getProperty('boyfriend.curCharacter') ~= 'spooky' then
        setProperty('iconP1.flipX', false)
        flipped = false
    end
end

function opponentNoteHit(id, direction)
	
end

function onBeatHit(beat)
	
end