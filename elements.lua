--[[
    oUF Kui
    Kesava-Auchindoun
    All rights reserved

    Element creation functions
]]
local addon,ns=...
local oUF = oUF
local kui = LibStub('Kui-1.0')

local T_SHADOW = 'interface/addons/kui_unitframes/media/edgefile-glow-sd'
local T_SOLID = 'interface/buttons/white8x8'

-- sort own auras first, then sort by index
local auras_SelfSort = function(a,b)
    if (a.own and b.own) or (not a.own and not b.own) then
        return a.index < b.index
    else
        return a.own and not b.own
    end
end
local auras_PreShowButton = function(self,button)
    button.own = select(7, UnitAura(self.frame.unit, button.index, self.filter))
    button.own = button.own == 'player'

    -- desaturate other buffs on friendlies, or other debuffs on enemies
    if (self.unit_is_friend and self.filter == 'HELPFUL') or
       (not self.unit_is_friend and self.filter == 'HARMFUL')
    then
        button.icon:SetDesaturated(not button.own)
    else
        button.icon:SetDesaturated(false)
    end
end

local function FadeSpark(self)
    if self.spark_fade then
        local val = self:GetValue()
        local min,max,show_val

        if self.inverted then
            max,min = self:GetMinMaxValues()
            show_val = min*.2
        else
            min,max = self:GetMinMaxValues()
            show_val = max*.8
        end

        if val == max then
            self.spark:SetAlpha(0)
            if self.text then
                self.text:SetAlpha(0)
            end
            return
        elseif (self.inverted and val > show_val) or
               (not self.inverted and val < show_val)
        then
            if val == min then
                self.spark:SetAlpha(0)
            else
                self.spark:SetAlpha(1)
            end
            if self.text then
                self.text:SetAlpha(1)
            end
        elseif self.inverted then
            local alpha = (val / show_val)
            self.spark:SetAlpha(alpha)
            if self.text then
                self.text:SetAlpha(alpha)
            end
        else
            -- fade text and spark depending on value
            local alpha = 1 - ((val - show_val) / (max - show_val))
            self.spark:SetAlpha(alpha)
            if self.text then
                self.text:SetAlpha(alpha)
            end
        end
    end

    -- also update spark colour to match the bar
    local r,g,b = self:GetStatusBarColor()
    self.spark:SetVertexColor(r+.3,g+.3,b+.3)
end
local function CreateStatusBarSpark(bar,no_fade)
    local texture = bar:GetStatusBarTexture()
    local spark = bar:CreateTexture(nil,'OVERLAY')
    spark:SetTexture('Interface\\AddOns\\Kui_Media\\t\\spark')
    spark:SetWidth(12)

    if bar:GetReverseFill() then
        spark:SetPoint('TOP', texture, 'TOPLEFT', 1, 4)
        spark:SetPoint('BOTTOM', texture, 'BOTTOMLEFT', 1, -4)
    else
        spark:SetPoint('TOP', texture, 'TOPRIGHT', -1, 4)
        spark:SetPoint('BOTTOM', texture, 'BOTTOMRIGHT', -1, -4)
    end

    bar.spark_fade = not no_fade
    bar.spark = spark

    bar:HookScript('OnValueChanged',FadeSpark)
    bar:HookScript('OnMinMaxChanged',FadeSpark)
end

local function StatusText_UpdateTag(self)
    local prevText = self:GetText()
    self:orig_UpdateTag()

    if self:GetText() == prevText then return end
    if MouseIsOver(self:GetParent()) then return end

    -- flash status text when it changes
    kui.frameFade(self, {
        mode = 'OUT',
        startAlpha = 1,
        endAlpha = .5,
        timeToFade = .5,
        startDelay = .5,
    })
end

local function Player_OnEnter(self)
    -- fade in status text on mouseover
    kui.frameFadeRemoveFrame(self.Health.status)
    self.Health.status:SetAlpha(1)
end
local function Player_OnLeave(self)
    kui.frameFadeRemoveFrame(self.Health.status)
    self.Health.status:SetAlpha(.5)
end
-- event stuff #################################################################
-- hide power bar on units with no power
local function Frame_Power_MinMaxChanged(self)
    if not self:GetParent().unit then return end

    local f = self:GetParent()
    if UnitPowerMax(f.unit) <= 0 then
        f.Power:Hide()
        f.Health:SetPoint('BOTTOMRIGHT',-1,1)
    else
        f.Power:Show()
        f.Health:SetPoint('BOTTOMRIGHT',-1,5)
    end
end
local function AttachEvents(self)
    if self.unit ~= 'target' then return end
    if not self.Power then return end
    self.Power:HookScript('OnMinMaxChanged',Frame_Power_MinMaxChanged)
end
--------------------------------------------------- generic background helper --
local function CreateBackground(self,frame,glow)
    if frame then
        frame = CreateFrame('Frame',nil,self)
    else
        frame = self
    end

    local edgeFile, edgeSize
    if glow then
        edgeFile = T_SHADOW
        edgeSize = 5
    else
        edgeFile = T_SOLID
        edgeSize = 1
    end

    frame:SetBackdrop({
        bgFile   = T_SOLID,
        edgeFile = edgeFile,
        edgeSize = edgeSize,
        insets   = {top=edgeSize,bottom=edgeSize,left=edgeSize,right=edgeSize}
    })
    frame:SetBackdropColor(0,0,0,.8)

    if glow then
        frame:SetBackdropBorderColor(0,0,0,.3)
    else
        frame:SetBackdropBorderColor(0,0,0,1)
    end

    return frame
end
------------------------------------------------------------------ health bar --
local function CreateHealthBar(self)
    self.Health = ns.CreateStatusBar(self)
    self.Health:SetPoint('TOPLEFT',1,-1)
    self.Health:SetPoint('BOTTOMRIGHT',-1,1)
    self.Health:SetStatusBarColor(.59,.05,.05)

    self.Health.frequentUpdates = true
    self.Health.Cutaway = true

    if self.unit == 'player' then
        -- also make spark
        CreateStatusBarSpark(self.Health)

        -- invert health fill
        --self.Health.inverted = true
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
    self.Portrait:SetPoint('TOPLEFT',self.Health)
    self.Portrait:SetPoint('BOTTOMRIGHT',self.Health,0,.1)

    self.Portrait.shade = self.Portrait:CreateTexture(nil,'OVERLAY')
    self.Portrait.shade:SetTexture('Interface\\AddOns\\Kui_Media\\t\\innerShade')
    self.Portrait.shade:SetAllPoints(self)
    self.Portrait.shade:SetBlendMode('BLEND')
    self.Portrait.shade:SetVertexColor(0,0,0,.5)

    self.Health:SetAlpha(.7)
    self.Health:SetFrameLevel(2)
    self.Portrait:SetFrameLevel(1)
end
------------------------------------------------------------- heal prediction --
local function CreateHealthPrediction(self)
    local width = 55 - 2
    local texture = 'Interface\\AddOns\\Kui_Media\\t\\bar'

    local myBar = CreateFrame('StatusBar', nil, self.Health)
    myBar:SetStatusBarTexture(texture)
    myBar:GetStatusBarTexture():SetDrawLayer('BACKGROUND',2)
    myBar:SetPoint('TOP')
    myBar:SetPoint('BOTTOM')
    myBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
    myBar:SetStatusBarColor(0,1,.5,.5)

    local otherBar = CreateFrame('StatusBar', nil, self.Health)
    otherBar:SetStatusBarTexture(texture)
    otherBar:GetStatusBarTexture():SetDrawLayer('BACKGROUND',3)
    otherBar:SetPoint('TOP')
    otherBar:SetPoint('BOTTOM')
    otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
    otherBar:SetStatusBarColor(0,1,0,.5)

    local healAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
    healAbsorbBar:SetStatusBarTexture(texture)
    healAbsorbBar:GetStatusBarTexture():SetDrawLayer('BACKGROUND',5)
    healAbsorbBar:SetPoint('TOP')
    healAbsorbBar:SetPoint('BOTTOM')
    healAbsorbBar:SetPoint('RIGHT', self.Health:GetStatusBarTexture())
    healAbsorbBar:SetStatusBarColor(0,0,0,.5)
    healAbsorbBar:SetReverseFill(true)

    self.Health:HookScript('OnSizeChanged',function(bar,width)
        -- width is set by functions.lua:SetFrameGeometry, and we can't just
        -- set the RIGHT point
        myBar:SetWidth(width)
        otherBar:SetWidth(width)
        healAbsorbBar:SetWidth(width)
    end)

    self.HealthPrediction = {
        myBar = myBar,
        otherBar = otherBar,
        healAbsorbBar = healAbsorbBar,
        maxOverflow = 1.05,
        frequentUpdates = true
    }
end
-- power prediction ############################################################
local function CreatePowerPrediction(self,reverse)
    assert(self.Power)
    local texture = 'Interface\\AddOns\\Kui_Media\\t\\bar'
    local myBar = CreateFrame('StatusBar', nil, self.Power)
    myBar:SetStatusBarTexture(texture)
    myBar:GetStatusBarTexture():SetDrawLayer('BACKGROUND',2)
    myBar:SetPoint('TOP')
    myBar:SetPoint('BOTTOM')
    myBar:SetPoint(reverse and 'LEFT' or 'RIGHT',self.Power:GetStatusBarTexture())
    myBar:SetReverseFill(not reverse)
    myBar:SetStatusBarColor(1,1,1,.3)

    self.Power:HookScript('OnSizeChanged',function(bar,width)
        -- as above, set width dynamically
        myBar:SetWidth(width)
    end)

    self.PowerPrediction = {
        mainBar = myBar,
    }
end
-------------------------------------------------------------------- cast bar --
local function CreateCastBar(self)
    local bar = ns.CreateStatusBar(self,self.unit=='target')

    bar:SetStatusBarColor(.3,.3,.43)
    bar.framekey = self.unit..'_castbar'
    ns.SetFrameGeometry(bar)

    bar.fbg = CreateBackground(bar,true,true)
    bar.fbg:SetPoint('TOPLEFT', bar, -6, 6)
    bar.fbg:SetPoint('BOTTOMRIGHT', bar, 6, -6)

    bar:SetFrameLevel(3)
    bar.fbg:SetFrameLevel(2)

    bar:SetStatusBarTexture(kui.m.t.oldbar)
    bar.bg:SetTexture(kui.m.t.oldbar)

    bar.Text = bar:CreateFontString(nil,'OVERLAY')
    ns.SetTextGeometry(self,bar.Text,'cast_name')

    bar.Time = bar:CreateFontString(nil,'OVERLAY')
    ns.SetTextGeometry(self,bar.Time,'cast_time')

    CreateStatusBarSpark(bar,true)

    self.Castbar = bar

    if self.unit == 'player' or self.unit == 'target' then
        -- create spell icon
        local icon = bar:CreateTexture(nil,'ARTWORK')
        icon:SetTexCoord(.1,.9,.1,.9)

        icon.bg = bar:CreateTexture(nil, 'BACKGROUND')
        icon.bg:SetTexture(T_SOLID)
        icon.bg:SetVertexColor(0, 0, 0)
        icon.bg:SetPoint('TOPLEFT', icon, 'TOPLEFT', -1, 1)
        icon.bg:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', 1, -1)

        icon:SetSize(24,24)

        if self.unit == 'player' then
            icon:SetPoint('RIGHT', bar, 'LEFT', -3, 0)
        else
            icon:SetPoint('LEFT', bar, 'RIGHT', 3, 0)
        end

        bar.Icon = icon
    end

    if self.unit == 'player' then
        -- create safe zone
        local sz = bar:CreateTexture(nil,'OVERLAY')
        bar.SafeZone = sz

        sz:SetTexture(kui.m.t.oldbar)
        sz:SetPoint('TOPRIGHT')
        sz:SetPoint('BOTTOMRIGHT')
        sz:SetVertexColor(.1, .9, .1, .3)
    end
end
------------------------------------------------------------------------ mana --
local function CreatePowerBar(self,reverse)
    self.Power = ns.CreateStatusBar(self,reverse)
    -- mana bar location is different per-layout

    self.Power.frequentUpdates = true
    self.Power.colorDisconnected = true
    self.Power.colorTapping = true
    self.Power.colorPower = true
    self.Power.Cutaway = true

    if self.unit == 'player' then
        -- power text
        local pp = self.overlay:CreateFontString(nil,'OVERLAY')
        pp:SetFont(kui.m.f.francois, 10, 'THINOUTLINE')

        pp:SetPoint('LEFT',self.Power,5,0)

        self:Tag(pp,'[kui:pp]')
        self.Power.text = pp
    end

    CreateStatusBarSpark(self.Power)
    CreatePowerPrediction(self,reverse)
end
------------------------------------------------------------------------ text --
local function CreateHealthText(self)
    local hp = self.overlay:CreateFontString(nil,'OVERLAY')
    ns.SetTextGeometry(self,hp,'health')

    if self.unit == 'player' then
        self.Health.text = hp

        local status = self.overlay:CreateFontString(nil,'OVERLAY')
        ns.SetTextGeometry(self,status,'status')
        self.Health.status = status
        self:Tag(status,'[kui:status]')

        status.orig_UpdateTag = status.UpdateTag
        status.UpdateTag = StatusText_UpdateTag

        self:HookScript('OnEnter', Player_OnEnter)
        self:HookScript('OnLeave', Player_OnLeave)
    end

    if self.unit == 'target' then
        local curhp = self.overlay:CreateFontString(nil,'OVERLAY')

        ns.SetTextGeometry(self,curhp,'curhp')

        self.Health.curhp = curhp
        self:Tag(curhp,'[kui:curhp]')
    end

    self.hp = hp
    self:Tag(self.hp,'[kui:hp]')
end
local function CreateNameText(self)
    local name = self.overlay:CreateFontString(nil,'OVERLAY')
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
        edgeFile=T_SHADOW,
        edgeSize=5
    })
    glow:SetBackdropBorderColor(0,0,0,.3)

    self.glow = glow
end
----------------------------------------------------------------------- auras --
local function CreateAuras(self)
    local buffs = {
        filter = 'HELPFUL',
        point = { 'BOTTOMLEFT', 'RIGHT', 'LEFT' },
        bg = true,
        mouse = true,
        parent = self,
        max = 24,
        size = 15,
        x_spacing = -1,
        y_spacing = 1,
        x_offset = -35,
        y_offset = 17,
        rows = 2,
        sort = auras_SelfSort,
        PreShowButton = auras_PreShowButton
    }
    local debuffs = {
        filter = 'HARMFUL',
        point = { 'BOTTOMRIGHT', 'LEFT', 'RIGHT' },
        bg = true,
        mouse = true,
        parent = self,
        max = 24,
        size = 15,
        x_spacing = 1,
        y_spacing = 1,
        x_offset = 35,
        y_offset = 17,
        rows = 2,
        sort = auras_SelfSort,
        PreShowButton = auras_PreShowButton
    }

    self.KuiAuras = { buffs, debuffs }
end
------------------------------------------------------------------- main base --
local function CreatePlayerElements(self)
    -- create power bar background on opposite side of action buttons
    local powerbg = CreateBackground(self, true)
    CreateGlow(powerbg)
    self.powerbg = powerbg

    powerbg.framekey = 'player_power'
    ns.SetFrameGeometry(powerbg)

    CreatePowerBar(self,true)
    self.Power:SetFrameLevel(powerbg:GetFrameLevel()+1)
    self.Power:SetPoint('TOPLEFT',powerbg,1,-1)
    self.Power:SetPoint('BOTTOMRIGHT',powerbg,-1,1)
    self.Power:SetAlpha(.7)

    -- class bars container
    self.ClassBars = {
        class = select(2,UnitClass('PLAYER')),
        width = 221,
        height = 8,
        point = { 'TOPLEFT', ActionButton7, 'BOTTOMLEFT', .1, -1 }
    }
end
function ns.CreateMainElements(self)
    -- create overlay for text/high textures
    self.overlay = CreateFrame('Frame',nil,self)
    self.overlay:SetFrameLevel(7)
    self.overlay:SetAllPoints(self)

    self.KuiAbsorb = {
        texture = 'Interface\\AddOns\\Kui_RaidFrames\\media\\stippled-bar',
        tile = true,
        drawLayer = { 'BACKGROUND', 4 },
        colour = { .3, .7, 1 },
        alpha = .5
    }

    CreateHealthBar(self)
    CreatePortrait(self)
    CreateHealthPrediction(self)

    if self.unit ~= 'targettarget' then
        CreateHealthText(self)
    end

    if self.unit == 'player' then
        CreatePlayerElements(self)
    else
        CreateNameText(self)
    end

    if self.unit == 'player' or self.unit == 'target' or self.unit == 'focus' then
        CreateCastBar(self)
    end

    if self.unit == 'target' then
        CreateAuras(self)
        CreatePowerBar(self)

        self.Power:SetPoint('TOPLEFT',self.Health,'BOTTOMLEFT',0,-1)
        self.Power:SetPoint('TOPRIGHT',self.Health,'BOTTOMRIGHT')
        self.Power:SetPoint('BOTTOMRIGHT',-1,1)

        -- set initial health bottom right point
        Frame_Power_MinMaxChanged(self)
    end

    AttachEvents(self)
end
------------------------------------------------------------------ frame init --
function ns.InitFrame(self)
    self.menu = ns.UnitMenu
    self:HookScript('OnEnter', ns.UnitOnEnter)
    self:HookScript('OnLeave', ns.UnitOnLeave)
    self:RegisterForClicks('AnyUp')

    -- create backdrop & border
    CreateBackground(self)
    self:SetBackdropColor(0,0,0,.2)

    CreateGlow(self)

    ns.SetFrameGeometry(self)
end
