function onUpdate(elapsed)
    if getProperty('iconP1.animation.name') == 'spooky' and getProperty('iconP1.flipX') == false and getProperty('boyfriend.curCharacter') == 'spooky' then
        setProperty('iconP1.flipX', true) -- my work here is done
    elseif getProperty('iconP1.animation.name') ~= 'spooky' and getProperty('iconP1.flipX') == true then
        setProperty('iconP1.flipX', false)
        close(true)
    end
end