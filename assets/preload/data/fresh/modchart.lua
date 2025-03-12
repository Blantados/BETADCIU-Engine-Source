
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

	if curBeat == 48 or curBeat == 112 then
		setProperty('gfSpeed', 1)
	end

	if curBeat == 16 or curBeat == 80 then
		setProperty('gfSpeed', 2)
	end

	if curBeat == 16 then
		setProperty('camZooming', true)
	end
end

function stepHit(step) 

end