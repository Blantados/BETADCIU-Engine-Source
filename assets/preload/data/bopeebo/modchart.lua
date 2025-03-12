
function start(song) 

end

local camX = 0
local camY = 0

function update(elapsed) 
	local currentBeat = (songPos / 1000)*(bpm/60)

	local camX = getCameraX()
	local camY = getCameraY()

	if bounceCam then
	end

end

function beatHit(beat) 

	if curBeat % 8 == 7 then
		characterPlayAnim('boyfriend', 'hey', true)
	end

	if curBeat >= 128 then
		setProperty('vocals.volume', 0)
	end

end

function stepHit(step) 

end