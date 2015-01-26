--[[
	oUF Kui
	Kesava-Auchindoun
	All rights reserved

	Unit factory

	TODO lots of things, but make damage absorb + healing absorb elements
]]
local addon,ns=...
local oUF = oUF
ns.frames = {}
-------------------------------------------------- Individual unit layout --
local function MainLayout(self, unit)
	if unit == 'player' then
		ns.CreatePlayerElements(self)
	else
		ns.CreateMainElements(self)
	end
end
oUF:RegisterStyle("KuitwoMain", MainLayout)
------------------------------------------------------------ Group layout --
local function GroupLayout(self, unit)
end
oUF:RegisterStyle("KuitwoGroup", GroupLayout)
------------------------------------------------------------- Raid layout --
local function RaidLayout(self, unit)
end
oUF:RegisterStyle("KuitwoRaid", RaidLayout)
------------------------------------------------------------- Arbitrary stuff --
local function SpawnFrame(unit)
	ns.frames[unit] = oUF:Spawn(unit)
	_G['oUF_Kuitwo_'..unit] = ns.frames[unit]
	ns.InitFrame(ns.frames[unit])
end
function SpawnParty()
end
function SpawnRaid()
end

oUF:Factory(function(self)
	oUF.colors.power['MANA'] = { 78/255, 95/255, 190/255 }

	-- replace the default reaction colours
	oUF.colors.reaction[1] = { .7, .2, .1 } -- hated
	oUF.colors.reaction[2] = { .7, .2, .1 } -- hostile
	oUF.colors.reaction[3] = { .9, .4, .1 } -- unfriendly
	oUF.colors.reaction[4] = { 1, .8, 0 }   -- neutral
	oUF.colors.reaction[5] = { .2, .6, .1 } -- friendly
	oUF.colors.reaction[6] = { .4, .8, .2 } -- honored
	oUF.colors.reaction[7] = { .3, .8, .4 } -- revered
	oUF.colors.reaction[8] = { .3, .9, .6 } -- exalted

	-- Spawn individual units ----------------------------------------------
	self:SetActiveStyle("KuitwoMain")
	SpawnFrame('player')
	SpawnFrame('pet')
	SpawnFrame('pettarget')
	SpawnFrame('target')
	SpawnFrame('targettarget')
	SpawnFrame('focus')
	SpawnFrame('focustarget')

	-- Spawn group style units ---------------------------------------------
	self:SetActiveStyle("KuitwoGroup")
	SpawnParty()

	-- Spawn raid style units ----------------------------------------------
	self:SetActiveStyle("KuitwoRaid")
	SpawnRaid()
end)
