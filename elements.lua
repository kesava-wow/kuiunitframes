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

	self.Health:SetAlpha(.8)
	self.Health:SetFrameLevel(2)
	self.Portrait:SetFrameLevel(1)
end
------------------------------------------------------------------ frame init --
function ns.InitFrame(self)
	self.menu = ns.UnitMenu
	self:SetScript('OnEnter', ns.UnitOnEnter)
	self:SetScript('OnLeave', ns.UnitOnLeave)
	self:RegisterForClicks('AnyUp')

	-- set backdrop & border
	self:SetBackdrop({
		bgFile=kui.m.t.solid,
		edgeFile=kui.m.t.solid,
		edgeSize=1,
		insets={top=1,bottom=1,left=1,right=1}
	})
	self:SetBackdropColor(0,0,0,.2)
	self:SetBackdropBorderColor(0,0,0,1)

	ns.SetFrameGeometry(self)

	-- create frame elements
	CreateHealthBar(self)
	CreatePortrait(self)
end