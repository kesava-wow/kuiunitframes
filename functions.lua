--[[
	oUF Kui
	Kesava-Auchindoun
	All rights reserved

	Element/frame helper functions
]]
local addon,ns=...
local oUF = oUF
-------------------------------------------------------------------- geometry --
do
	local styles = { -- sizes
		['player'] = { 197, 15 },
		['target'] = { 197, 25 },
	}
	local geometry = { -- positions
		['player'] = { 'player', { 'TOPRIGHT', ActionButton7, 'BOTTOMLEFT', -1.1, 15.1 }},
		['player_power'] = { 'player', { 'TOPLEFT', ActionButton12, 'BOTTOMRIGHT', 1.1, 15.1 }},
		['target'] = { 'target', { 'BOTTOMLEFT', ActionButton1, 'TOPLEFT', -.1, 1.1 }},
	}

    local SetPoint = function(frame,point_tbl)
        if type(point_tbl[2]) == 'string' then
            point_tbl[2] = _G[point_tbl[2]]
        end

        frame:SetPoint(unpack(point_tbl))
    end

	ns.SetFrameGeometry = function(self)
		if geometry[self.unit] then
			local geotable = geometry[self.unit]
			local style = geotable[1]
			local point = geotable[2]
			local relpoint = geotable[3]

			if style and styles[style] then
				self:SetSize(unpack(styles[style]))
			end

			if point then
                self:ClearAllPoints()
                SetPoint(self,point)
			end

			if relpoint then
                SetPoint(self,relpoint)
			end
		end
	end

    local text_geo = {
        ['default'] = {
            ['name'] = { 'LEFT',  5, -1 },
            ['health'] = { 'RIGHT', -5, 0 },
        }
    }

    ns.SetTextGeometry = function(frame,text,geokey,rel)
        local geotable
        if frame.unit and text_geo[frame.unit] and text_geo[frame.unit][geokey] then
            geotable = text_geo[frame.unit][geokey]
        else
            if text_geo['default'][geokey] then
                geotable = text_geo['default'][geokey]
            else
                return
            end
        end

        local point,relpoint

        if type(geotable[1]) == 'table' then
            point = geotable[1]
            relpoint = geotable[2]
        else
            point = geotable
        end

        text:ClearAllPoints()
        SetPoint(text,point)

        if relpoint then
            SetPoint(text,relpoint,frame)
        end
    end
end
--------------------------------------------------------------- dropdown menu --
do
	local dropdown = CreateFrame('Frame', addon..'UnitDropDownMenu', UIParent, 'UIDropDownMenuTemplate')

	ns.UnitMenu = function(self)
		dropdown:SetParent(self)
		return ToggleDropDownMenu(1,nil,dropdown,'cursor',-3,0)
	end

	local function DropdownInit(self)
		local unit = self:GetParent().unit
		if not unit then return end
		local menu,name,id

		if UnitIsUnit(unit,'player') then
			menu = 'SELF'
		elseif UnitIsUnit(unit,'vehicle') then
			menu = 'VEHICLE'
		elseif UnitIsUnit(unit,'pet') then
			menu = 'PET'
		elseif UnitIsPlayer(unit) then
			id = UnitInRaid(unit)
			if id then
				menu = 'RAID_PLAYER'
				name = GetRaidRosterInfo(id)
			elseif UnitInParty(unit) then
				menu = 'PARTY'
			else
				menu = 'PLAYER'
			end
		else
			menu = 'TARGET'
			name = RAID_TARGET_ICON
		end

		if menu then
			UnitPopup_ShowMenu(self,menu,unit,name,id)
		end
	end

	UIDropDownMenu_Initialize(dropdown, DropdownInit, 'MENU')
end
--------------------------------------------------------- status bar creation --
do
	local texture = 'Interface\\AddOns\\Kui_Media\\t\\bar'
	local SetKuiStatusBarColor = function(self,r,g,b)
		-- set colour of bg too
		self.bg:SetVertexColor(r,g,b)
		self:SetStatusBarColor_(r,g,b)
	end

	ns.CreateStatusBar = function(parent)
		local bar = CreateFrame('StatusBar',nil,parent)
		bar:SetStatusBarTexture(texture)

		bar.bg = bar:CreateTexture(nil,'BACKGROUND')
		bar.bg:SetTexture(texture)
		bar.bg:SetAllPoints(bar)
		bar.bg:SetAlpha(.3)

		if bar.bg then
			bar.SetStatusBarColor_ = bar.SetStatusBarColor
			bar.SetStatusBarColor = SetKuiStatusBarColor
		end

		return bar
	end
end
----------------------------------------------------------------------- hooks --
------------------------------------------------------------------- mouseover --
do
	ns.UnitOnEnter = function(frame,...)
		UnitFrame_OnEnter(frame,...)
	end
	ns.UnitOnLeave = function(frame,...)
		UnitFrame_OnLeave(frame,...)
	end
end
