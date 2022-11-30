local seg_time = 30
local total_day_time = seg_time*16

local day_segs = 10
local dusk_segs = 4
local night_segs = 2

--default day composition. changes in winter, etc
local day_time = seg_time * day_segs
local dusk_time = seg_time * dusk_segs
local night_time = seg_time * night_segs


local REFRESH_TUNING = {
	MOSQUITOSWARM_GROWTH = {
		OFFSPRING_TIME = total_day_time * 5,
		DESOLATION_RESPAWN_TIME = total_day_time * 50,
		DEAD_DECAY_TIME = total_day_time * 30,
	},

	MOSQUITOSWARM_COCOON_GROW_TIME =
	{
		{base=1.5*day_time, random=0.5*day_time},   --short
		{base=5*day_time, random=2*day_time},   --normal
		{base=5*day_time, random=2*day_time},   --tall
		{base=1*day_time, random=0.5*day_time}   --old
	},

	MOSQUITOSWARM_RESTOCK = 15,

	FUMEAGATOR_TARGETRANGE = 12,
	FUMEAGATOR_DAMAGE = 50,
	FUMEAGATOR_HEALTH = 1200,
	FUMEAGATOR_ATTACKRANGE = 5.5,
	FUMEAGATOR_ATTACKPERIOD = 2.5,
	FUMEAGATOR_FUMEPERIOD = 20,

	SHROOMBRELLA = {
		PRESERVER = {
			0.75,
			0.5,
			0.25,
			1,
		}
	}
}

for key, value in pairs(REFRESH_TUNING) do
    TUNING[key] = value
end
