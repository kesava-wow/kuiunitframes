--[[
    oUF Kui
    Kesava-Auchindoun
    All rights reserved

    Element creation functions
]]
local addon,ns=...
local oUF = oUF
local kui = LibStub('Kui-1.0')

local function FadeSpark(self)
    local min,max = self:GetMinMaxValues()
    local val = self:GetValue()
    local show_val = (max / 100) * 80
    if val == max then
        self.text:SetAlpha(0)
        self.spark:SetAlpha(0)
        return
    elseif val < show_val then
        self.text:SetAlpha(1)

        if val == 0 then
            self.spark:SetAlpha(0)
        else
            self.spark:SetAlpha(1)
        end
    else
        -- fade text and spark depending on value
        local alpha = 1 - ((val - show_val) / (max - show_val))
        self.text:SetAlpha(alpha)
        self.spark:SetAlpha(alpha)
    end

    -- also update spark colour to match the bar
    local r,g,b = self:GetStatusBarColor()
    self.spark:SetVertexColor(r+.3,g+.3,b+.3)
end

local function CreateStatusBarSpark(bar)
    local texture = bar:GetStatusBarTexture()
    local spark = bar:CreateTexture(nil,'OVERLAY')
    spark:SetTexture('Interface\\AddOns\\Kui_Media\\t\\spark')
    spark:SetWidth(8)

    if bar.reverser then
        spark:SetPoint('TOP', texture, 'TOPLEFT', 1, 4)
        spark:SetPoint('BOTTOM', texture, 'BOTTOMLEFT', 1, -4)
    else
        spark:SetPoint('TOP', texture, 'TOPRIGHT', -1, 4)
        spark:SetPoint('BOTTOM', texture, 'BOTTOMRIGHT', -1, -4)
    end

    bar.spark = spark

    bar:HookScript('OnValueChanged',FadeSpark)
    bar:HookScript('OnMinMaxChanged',FadeSpark)
end

------------------------------------------------------------------ health bar --
local function CreateHealthBar(self)
    self.Health = ns.CreateStatusBar(self)
    self.Health:SetPoint('TOPLEFT',1,-1)
    self.Health:SetPoint('BOTTOMRIGHT',-1,1)
    self.Health:SetStatusBarColor(.59,.05,.05)

    self.Health.frequentUpdates = true
    self.Health.Smooth = true

    if self.unit == 'player' then
        -- also make spark
        CreateStatusBarSpark(self.Health)
    else
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

    if self.unit == 'player' then
        -- power text
        local pp = self.overlay:CreateFontString(nil,'OVERLAY')
        pp:SetFont(kui.m.f.francois, 10, 'THINOUTLINE')
        pp:SetShadowOffset(1,-1)
        pp:SetShadowColor(0,0,0,.5)

        pp:SetPoint('LEFT',self.Power,5,0)

        self:Tag(pp,'[kui:pp]')
        self.Power.text = pp

        -- reverse player power bar
        local bar = self.Power
        local function OnUpdateReverser(self)
            local tex = self.__owner:GetStatusBarTexture()
            local max,width,val =
                select(2, self.__owner:GetMinMaxValues()),
                self.__owner:GetWidth(),
                self.__owner:GetValue()

            tex:ClearAllPoints()
            tex:SetPoint('BOTTOMRIGHT')
            tex:SetPoint('TOPLEFT', self.__owner, 'TOPRIGHT', -((val/max)*width),0)

            self:Hide()
        end
        local function OnChange(self)
            self.reverser:Show()
        end

        bar.reverser = CreateFrame('Frame',nil,bar)
        bar.reverser:Hide()
        bar.reverser:SetScript('OnUpdate',OnUpdateReverser)
        bar.reverser.__owner = bar

        bar:HookScript('OnSizeChanged',OnChange)
        bar:HookScript('OnValueChanged',OnChange)
        bar:HookScript('OnMinMaxChanged',OnChange)

        -- add spark
        CreateStatusBarSpark(self.Power)
    end
end
------------------------------------------------------------------------ text --
local function CreateHealthText(self)
    local hp = self.overlay:CreateFontString(nil,'OVERLAY')
    hp:SetShadowOffset(1,-1)
    hp:SetShadowColor(0,0,0,.5)

    if self.unit == 'player' then
        self.Health.text = hp
    end

    ns.SetTextGeometry(self,hp,'health')

    if self.unit == 'target' then
        local curhp = self.overlay:CreateFontString(nil,'OVERLAY')
        curhp:SetShadowOffset(1,-1)
        curhp:SetShadowColor(0,0,0,.5)

        ns.SetTextGeometry(self,curhp,'curhp')

        self.Health.curhp = curhp
        self:Tag(curhp,'[kui:curhp]')
    end

    self.hp = hp
    self:Tag(self.hp,'[kui:hp]')
end
local function CreateNameText(self)
    local name = self.overlay:CreateFontString(nil,'OVERLAY')
    name:SetShadowOffset(1,-1)
    name:SetShadowColor(0,0,0,.5)

    ns.SetTextGeometry(self,name,'name')

    self.name = name
    self:Tag(self.name,'[name]')
end
------------------------------------------------------------------ frame glow --
local function CreateGlow(self)
    local glow = CreateFrame('Frame',nil,self)
    glow:SetPoint('TOPLEFT', -5, 5)
    glow:SetPoint('BOTTOMRIGHT', 5, -5)
    glow:SetBackdrop({
        edgeFile=kui.m.t.shadow,
        edgeSize=5
    })
    glow:SetBackdropBorderColor(0,0,0,.3)

    self.glow = glow
end
---------------------------------------------------------- generic background --
local function CreateBackground(self, frame)
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
local function CreatePlayerElements(self)
    -- create power bar background on opposite side of action buttons
    local powerbg = CreateBackground(self, true)
    CreateGlow(powerbg)
    self.powerbg = powerbg

    powerbg.framekey = 'player_power'
    ns.SetFrameGeometry(powerbg)

    CreatePowerBar(self)
    self.Power:SetFrameLevel(powerbg:GetFrameLevel()+1)
    self.Power:SetPoint('TOPLEFT',powerbg,1,-1)
    self.Power:SetPoint('BOTTOMRIGHT',powerbg,-1,1)
    self.Power:SetAlpha(.7)

    -- class bars container
    self.ClassBars = {
        class = select(2,UnitClass('PLAYER')),
        width = 197,
        height = 6,
        point = { 'TOPLEFT', ActionButton7, 'BOTTOMLEFT', 0, -1 }
    }
end
function ns.CreateMainElements(self)
    -- create overlay for text/high textures
    self.overlay = CreateFrame('Frame',nil,self)
    self.overlay:SetFrameLevel(7)
    self.overlay:SetAllPoints(self)

    CreateHealthBar(self)
    CreatePortrait(self)

    if self.unit ~= 'targettarget' then
        CreateHealthText(self)
    end

    if self.unit == 'player' then
        CreatePlayerElements(self)
    else
        CreateNameText(self)
    end
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

    CreateGlow(self)

    ns.SetFrameGeometry(self)
end
