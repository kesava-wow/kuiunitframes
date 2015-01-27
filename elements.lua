--[[
	oUF Kui
	Kesava-Auchindoun
	All rights reserved

	Element creation functions
]]
local addon,ns=...
local oUF = oUF
------------------------------------------------------------------ health bar --
local function CreateHealthBar(self)
	self.Health = ns.CreateStatusBar(self)
	self.Health:SetPoint('TOPLEFT',1,-1)
	self.Health:SetPoint('BOTTOMRIGHT',-1,1)
	self.Health:SetStatusBarColor(.59,.05,.05)

	self.Health.frequentUpdates = true
	self.Health.Smooth = true

	if self.unit ~= 'player' then
		self.Health.colorReaction = true
		self.Health.colorClass = true
		self.Health.colorDisconnected = true
		self.Health.colorTapping = true
	end
end
-------------------------------------------------------------------- portrait --
local function CreatePortrait(self)
	self.Portrait = CreateFrame('PlayerModel',nil,self)
	self.Portrait.type = '3D'
	self.Portrait:SetAllPoints(self.Health)

	self.Portrait.shade = self.Portrait:CreateTexture(nil,'OVERLAY')
	self.Portrait.shade:SetTexture('Interface\\AddOns\\Kui_Media\\t\\innerShade')
	self.Portrait.shade:SetAllPoints(self)
	self.Portrait.shade:SetBlendMode('BLEND')
	self.Portrait.shade:SetVertexColor(0,0,0,.8)

	self.Health:SetAlpha(.7)
	self.Health:SetFrameLevel(2)
	self.Portrait:SetFrameLevel(1)
end
------------------------------------------------------------------------ mana --
local function CreatePowerBar(self)
	self.Power = ns.CreateStatusBar(self)
	-- mana bar location is different per-layout

	self.Power.frequentUpdates = true
	self.Power.Smooth = true
	self.Power.colorDisconnected = true
	self.Power.colorTapping = true
	self.Power.colorPower = true
end
---------------------------------------------------------- generic background --
function CreateBackground(self, frame)
    if frame then
        frame = CreateFrame('Frame',nil,self)
    else
        frame = self
    end

	frame:SetBackdrop({
		bgFile=kui.m.t.solid,
		edgeFile=kui.m.t.solid,
		edgeSize=1,
		insets={top=1,bottom=1,left=1,right=1}
	})
	frame:SetBackdropColor(0,0,0,.8)
	frame:SetBackdropBorderColor(0,0,0,1)

    return frame
end
------------------------------------------------------------------- main base --
function ns.CreateMainElements(self)
	-- create frame elements
	CreateHealthBar(self)
	CreatePortrait(self)
end
----------------------------------------------------------------- player base --
function ns.CreatePlayerElements(self)
	CreateHealthBar(self)
	CreatePortrait(self)

	-- power bar
	-- create power bar background on opposite side of action buttons
    local powerbg = CreateBackground(self, true)
    self.powerbg = powerbg

    powerbg.unit = 'player_power'
    ns.SetFrameGeometry(powerbg)

	CreatePowerBar(self)
	self.Power:SetParent(powerbg)
	self.Power:SetPoint('TOPLEFT',1,-1)
	self.Power:SetPoint('BOTTOMRIGHT',-1,1)
	self.Power:SetAlpha(.7)

    -- class bars container
    self.ClassBars = {
        class = select(2,UnitClass('PLAYER')),
        width = 197,
        height = 6,
        point = { 'TOPLEFT', ActionButton7, 'BOTTOMLEFT', 0, -1 }
    }
end
------------------------------------------------------------------ frame init --
function ns.InitFrame(self)
	self.menu = ns.UnitMenu
	self:SetScript('OnEnter', ns.UnitOnEnter)
	self:SetScript('OnLeave', ns.UnitOnLeave)
	self:RegisterForClicks('AnyUp')

	-- create backdrop & border
    CreateBackground(self)
	self:SetBackdropColor(0,0,0,.2)
	ns.SetFrameGeometry(self)
end
