--[[
-- Monolithic class bars plugin for oUF
-- Runes, shards, etc.
-- By Kesava at curse.com
-- All rights reserved
]]
local kui = LibStub('Kui-1.0')
local cb
-------------------------------------------------------- Utility funtions --
-- Arranges bars into columns depending on which bars are visible
local function ArrangeBars()
    local shown, pv, pc = {}
    -- pv = previous visible bar
    -- pc = previous visible bar which starts a column

    for groupId,group in pairs(cb.container.groups) do
        if not shown[groupId] then
            shown[groupId] = 0
        end

        if not group.rows then
            group.rows = #group.bars
        end

        for _,bar in ipairs(group.bars) do
            if bar.bg:IsShown() then
                shown[groupId] = shown[groupId] + 1
            end
        end

        if shown[groupId] > 0 then
            if group.rows == #group.bars then
                -- automatically adjust bar width to fit container (i.e. when one
                -- bar is hidden, expand the others to fit the total width)
                group.autorows = shown[groupId]
            else
                -- use given number of rows to group bars together
                group.autorows = group.rows or #group.bars
            end

            local rows = group.autorows
            group.width = floor((cb.width / rows) - (cb.container.space * (rows - 1)) / rows)

            -- add 1 to the width of each bar until remainingWidth is 0
            -- i.e ensure bar width matches up correctly with the width of the container
            group.totalWidth = (group.width * rows) + (cb.container.space * (rows - 1))
            group.remainingWidth = cb.width - group.totalWidth

            local vid = 0 -- visible id, [k] - [number of non-shown bars]
            for _,bar in ipairs(group.bars) do
                local group = cb.container.groups[bar.group]

                if bar.bg:IsShown() then
                    vid = vid + 1
                    bar.bg:ClearAllPoints()

                    bar.bg:SetWidth(
                        group.width +
                        (group.remainingWidth > 0 and 1 or 0) +
                        (bar.hasBorder * 2)
                    )

                    if group.remainingWidth > 0 then
                        group.remainingWidth = group.remainingWidth - 1
                    end

                    if not pv then
                        -- first bar
                        -- anchor to the unit frame
                        bar.bg:SetPoint('BOTTOMLEFT', -bar.hasBorder, -bar.hasBorder)
                        pc = bar
                    else
                        -- subsequent bars, find correct position
                        if (vid-1) % group.autorows == 0 then
                            -- first bar in this row
                            -- below the previous row
                            bar.bg:SetPoint('TOPLEFT', pc.bg, 'BOTTOMLEFT',
                                (0 + pc.hasBorder) - bar.hasBorder,
                                -((cb.container.space - pc.hasBorder) - bar.hasBorder))

                            pc = bar
                        else
                            -- right of the previous bar
                            bar.bg:SetPoint('LEFT', pv.bg, 'RIGHT',
                                (cb.container.space + pv.hasBorder) - bar.hasBorder,
                                0)
                        end
                    end

                    pv = bar
                end
            end
        end
    end
end

local function HideBar(self, bar)
    bar.bg:Hide()
    ArrangeBars()
end
local function ShowBar(self, bar)
    bar.bg:Show()
    ArrangeBars()
end

----------------------------------------------------------- Tooltip functions --
--------------------------------------------------------------- Totem tooltip --
local function ShamanTooltip(bar)
    if bar.name then
        local tl, delim = bar.tl, 's'

        if tl > 60 then
            tl      = tl / 60
            delim   = 'm'
        end

        tl = floor(tl)

        return {
            bar.name,
            {
                t = tl .. delim,
                c = { r = .6, g = .6, b = .6 }
            }
        }
    end
end

------------------------------------------------------------ Update functions --
------------------------------------------------------- Update generic powers --
-- must be used as update.f
local function UpdateGeneric(self, event, ...)
    local curr = 0
    if cb.type then
        curr = UnitPower(self.unit, cb.type)
    else
        -- event-driven power; cannot be fetched with UnitPower
        curr = cb.event_function(self.unit)
    end

    for k, bar in ipairs(cb.bars) do
        if curr >= k then
            bar.bg:SetAlpha(1)
        else
            bar.bg:SetAlpha(.3)
        end
    end
end
local function UpdateGenericBar(self,event,...)
    local val = 0
    if cb.type then
        val = UnitPower(self.unit, cb.type)
    else
        val = cb.event_function(self.unit)
    end

    cb.bars[1]:SetValue(val)
end
----------------------------------- Update combo points + anticipation stacks --
local function UpdateComboPoints(self, event, ...)
    local cur = UnitPower('player',SPELL_POWER_COMBO_POINTS)

    for i,bar in ipairs(cb.bars) do
        if cur >= i then
            if cur > 5 and (cur - 5) >= i then
                -- anticipation colour
                bar:SetStatusBarColor(1,.3,.3)
            else
                -- standard colour
                bar:SetStatusBarColor(unpack(cb.o.colour))
            end
            bar.bg:SetAlpha(1)
        else
            bar.bg:SetAlpha(.3)
        end
    end
end
----------------------------------------------------------- Update Totem Bars --
local function UpdateShamanBar(self, bar)
    local haveTotem, totemName, startTime, duration = GetTotemInfo(bar.id)

    if haveTotem then
        bar.name = totemName
        bar.tl   = (startTime + duration - GetTime())

        if bar.tl >= 0 then
            local total = 0

            ShowBar(self, bar)

            bar:SetValue(1 - ((GetTime() - startTime) / duration))
            bar:SetScript('OnUpdate', function(self, elapsed)
                total = total + elapsed

                if total > 0.1 then
                    total = 0

                    local haveTotem, totemName, startTime, duration = GetTotemInfo(self.id)

                    self:SetValue(1 - ((GetTime() - startTime) / duration))
                    self.tl = (startTime + duration - GetTime())
                end
            end)
        else
            bar:SetScript('OnUpdate', nil)
            HideBar(self, bar)
        end
    else
        HideBar(self, bar)
    end
end
---------------------------------------------------------------- Update Runes --
local function UpdateDeathKnightBar(self, bar)
    local type, startTime, duration, charged = GetRuneType(bar.id), GetRuneCooldown(bar.id)
    if not type then return end

    bar:SetStatusBarColor(unpack(self.ClassBars.colours[type]))
    bar.tl = startTime + duration - GetTime()

    if not charged then
        bar:SetValue((GetTime() - startTime) / duration)

        if not bar:GetScript('OnUpdate') then
            bar.bg:SetAlpha(.3)
            bar:SetScript('OnUpdate', function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed

                if self.elapsed > 0.1 then
                    self.elapsed = 0

                    local startTime, duration = GetRuneCooldown(bar.id)
                    bar:SetValue((GetTime() - startTime) / duration)
                end
            end)
        end
    else
        bar.bg:SetAlpha(1)
        bar:SetValue(1)

        bar:SetScript('OnUpdate', nil)
    end
end
----------------------------------------------------------- Update druid bars --
local function UpdateDruid(self, event)
    -- Eclipse -----------------------------------------------------------------
    if  event == 'UPDATE_SHAPESHIFT_FORM' or
        event == 'PLAYER_ENTERING_WORLD' or
        not event
    then
        -- toggle bars depending on form
        if GetShapeshiftFormID() == MOONKIN_FORM then
            ShowBar(self, cb.bars[4])
        else
            HideBar(self, cb.bars[4])
        end
    end

    if cb.bars[4].bg:IsShown() then
        -- set colour based on current direction
        local curr = UnitPower('player', SPELL_POWER_ECLIPSE)
        cb.bars[4]:SetValue(curr < 0 and -curr or curr)

        if curr > 0 then
            -- solar
            cb.bars[4]:SetStatusBarColor(238/255, 200/255, 77/255)
            cb.bars[4].col:SetVertexColor(238/255, 200/255, 77/255, .2)
        else
            -- lunar
            cb.bars[4]:SetStatusBarColor(60/255, 150/255, 220/255)
            cb.bars[4].col:SetVertexColor(60/255, 150/255, 220/255, .2)
        end

        -- get eclipse status
        local hasEclipse = false
        for i=0,40 do
            local _,_,_,_,_,_,_,_,_,_, spellID = UnitBuff('player', i)

            if spellID == ECLIPSE_BAR_SOLAR_BUFF_ID then
                hasEclipse = { 238/255, 200/255, 77/255, .5 }
                break
            elseif spellID == ECLIPSE_BAR_LUNAR_BUFF_ID then
                hasEclipse = { 60/255, 150/255, 220/255, .5 }
                break
            end
        end

        if hasEclipse then
            cb.bars[4].bg:SetBackdropBorderColor(unpack(hasEclipse))
        else
            cb.bars[4].bg:SetBackdropBorderColor(0,0,0,0)
        end
    end

    -- Mana --------------------------------------------------------------------
    local shown = false
    if UnitPowerType('player') ~= 0 then
        local curr, max =
            UnitPower('player', 0), UnitPowerMax('player', 0)

        if curr ~= max then
            cb.bars[5]:SetMinMaxValues(0, max)
            cb.bars[5]:SetValue(curr)
            ShowBar(self, cb.bars[5])
            shown = true
        end
    end

    if not shown and cb.bars[5].bg:IsShown() then
        HideBar(self, cb.bars[5])
    end
end
---------------------------------------------------- Update druid shroom bars --
local function UpdateDruidShrooms(self, bar)
    if bar.id > 3 then return end
    UpdateShamanBar(self, bar)
end
---------------------------------------------------------- Shadow priest mana --
local function UpdateShadowPriestMana(self,event)
    local cur,max =
        UnitPower('player',SPELL_POWER_MANA),
        UnitPowerMax('player',SPELL_POWER_MANA)

    if cur == max then
        HideBar(self, cb.bars[1])
    else
        ShowBar(self, cb.bars[1])
        cb.bars[1]:SetMinMaxValues(0,max)
        cb.bars[1]:SetValue(cur)
    end
end

------------------------------------------------------- Post-create functions --
------------------------------------------------ Post-create for generic bars --
local function CreateGenericBar(self)
    for k, bar in ipairs(cb.bars) do
        if not bar.col then
            -- create bar background
            bar.col = bar:CreateTexture(nil, 'BACKGROUND')
            bar.col:SetTexture(kui.m.t.sbar)
            bar.col:SetAllPoints(bar)
        end

        local r,g,b = bar:GetStatusBarColor()
        bar.col:SetVertexColor(r, g, b, .2)
    end
end
--------------------------------------------------------------------- Eclipse --
local function CreateEclipseBar(self)
    local bar = cb.bars[4]
    local bg  = bar.bg

    bg:SetBackdrop({
        bgFile = kui.m.t.solid,
        edgeFile = kui.m.t.shadow, edgeSize = 2,
        insets = { top = 2, right = 2, bottom = 2, left = 2 }
    })

    bar.hasBorder = 2

    bg:SetBackdropColor(0,0,0,1)
    bg:SetBackdropBorderColor(1,1,1,0)

    bg:SetWidth(bg:GetWidth()+4)
    bg:SetHeight(bg:GetHeight()+4)

    bar:SetPoint('TOPLEFT', bg, 'TOPLEFT', 3, -3)
    bar:SetPoint('BOTTOMRIGHT', bg, 'BOTTOMRIGHT', -3, 3)

    CreateGenericBar(self)
end

--[[--------------------------------------------------------- Update function --
    Calls cb.o.update.f(self)
    Calls cb.o.update.b(self, bar) for each bar created by Create()
]]
local function Update(self, event, ...)
    if event == 'UNIT_POWER' or
       event == 'UNIT_POWER_FREQUENT' or
       event == 'UNIT_AURA' or
       event == 'UNIT_COMBO_POINTS'
    then
        local unit = ...
        if unit ~= self.unit then return end
    end

    cb = cb or self.ClassBars
    if not cb.o then return end

    if cb.o.update.f then
        cb.o.update.f(self, event, ...)
    end

    if cb.o.update.b then
        for k, b in pairs(cb.bars) do
            cb.o.update.b(self, b)
        end
    end
end
--[[------------------------------------------------------------- Create bars --
    Creates bars from cb.o object
    Calls cb.o.create(self) upon completion
    Also forces Update with nil event
]]
local function CreateBars(self)
    cb.bars = cb.bars or {}

    --print('CreateBars')

    local space   = 1
    local groups  = cb.o.groups

    -- parse groups
    if groups then
        groups[0] = { bars = {} }
    else
        groups = { [0] = { bars = {} } }
    end

    cb.container.groups = groups
    cb.container.space = space

    -- create/update bars
    for k,group in pairs(groups) do
        if not group.bars then
            group.bars = {}
        end
    end

    -- create/update bars, default method
    for k, v in ipairs(cb.o.bars) do
        local b, bg
        local group = groups[v.group or 0]

        if cb.bars[k] then
            -- update bar size, position...
            b = cb.bars[k]
            bg = b.bg

            bg:ClearAllPoints()
        else
            -- create a bar
            bg = CreateFrame("Frame", nil, cb.container)
            b = CreateFrame("StatusBar", nil, bg)

            bg:SetBackdrop({ bgFile = kui.m.t.sbar })
            bg:SetBackdropColor(.05, .05, .05)

            b:SetPoint('TOPLEFT', bg, 'TOPLEFT', 1, -1)
            b:SetPoint('BOTTOMRIGHT', bg, 'BOTTOMRIGHT', -1, 1)
            b:SetStatusBarTexture(kui.m.t.sbar)

            if cb.o.tooltip then
                -- enable tooltip
                b:EnableMouse(true)

                b:SetScript('OnEnter', function(self)
                    lines = cb.o.tooltip(self)

                    if lines and #lines > 0 then
                        GameTooltip:SetOwner(self.bg, 'ANCHOR_CURSOR')

                        for _, line in pairs(lines) do
                            if line.t and line.c then
                                GameTooltip:AddLine(line.t, line.c.r, line.c.g, line.c.b)
                            else
                                GameTooltip:AddLine(line)
                            end
                        end

                        GameTooltip:Show()
                    end
                end)

                b:SetScript('OnLeave', function()
                    GameTooltip:Hide()
                end)
            end

            b.bg        = bg
            b.id        = v.id or k
            b.group     = v.group or 0
            b.hasBorder = 0
            cb.bars[k]  = b
        end

        tinsert(group.bars, b)

        b:SetStatusBarColor(unpack(v.colour or cb.o.colour or {1,1,1}))
        b:SetMinMaxValues(unpack(v.minmax or cb.o.minmax or {0,1}))

        if not v.minmax and not cb.o.minmax then
            b:SetValue(1)
        end

        bg:SetHeight(cb.height)
    end

    -- register container events
    for k, e in pairs(cb.o.events) do
        cb.container:RegisterEvent(e)
    end

    -- call post create
    if cb.o.create then
        cb.o.create(self)
    end

    Update(self)

    -- size/position bars
    ArrangeBars()
end
--------------------------------------------------------------- Update object --
-- updates the bar object when power type or max power changes
local function UpdateObject(self, event, unit, resource)
    --print('UpdateObject')
    cb = cb or self.ClassBars

    if cb.level and UnitLevel('player') < cb.level then
        return
    end

    if event == 'UNIT_MAXPOWER' then
        if unit ~= 'player' then return end
        resource = _G['SPELL_POWER_'..resource]

        if resource ~= cb.type then
            return
        end
    else
        -- power type has changed, or set up for initial display
        --print('Power type update (or initial call)')
        if cb.types then
            cb.type = cb.PowerTypes[GetSpecialization()]
        end

        if cb.types then
            cb.o = cb.types[cb.type]
        end

        if not cb.o then
            -- this specialization has no object attached to it
            cb.container:Hide()
            cb.container:UnregisterAllEvents()
            return
        else
            cb.container:Show()
        end

        if not cb.o.bars then
            cb.o.dynamic = true
            cb.o.bars = {}
        end

        resource = cb.o.resource or cb.type
    end

    local powerMax = UnitPowerMax('player', resource)

    if cb.bars then
        -- cycle existing bars to destroy (in case powerMax has decreased)
        for k, bar in ipairs(cb.bars) do
            if (cb.o.dynamic and k > powerMax) or
               (not cb.o.dynamic and k > #cb.o.bars)
            then
                -- destroy bars which are no longer needed
                bar:UnregisterAllEvents()
                HideBar(self, bar)

                -- they'll be garbage collected... right?
                cb.bars[k] = nil
                cb.o.bars[k] = nil
            end
        end
    end

    if cb.o.dynamic then
        --print('Dynamic bars')
        -- determine bars to add to object (in case powerMax has increased)
        for k=1,powerMax do
            if not cb.o.bars[k] then
                --print('Will create bar '..k)
                cb.o.bars[k] = {}
            end
        end
    end

    if #cb.o.bars > 0 then
        -- create/update bars
        CreateBars(self)
    end
end
-------------------------------------------------------- Enable ClassBars --
local function Enable(self, unit)
    cb = self.ClassBars or nil
    if not cb then return end

    if cb.class ~= "SHAMAN" and cb.class ~= "DEATHKNIGHT" and
       cb.class ~= "DRUID" and cb.class ~= "PALADIN" and
       cb.class ~= "WARLOCK" and cb.class ~= "MONK" and cb.class ~= 'PRIEST' and
       cb.class ~= 'ROGUE'
    then
        cb = nil
        return
    end

    if cb.class == 'PRIEST' then
        cb.PowerTypes = {
            [3] = 'mana'
        }
    end

    -- create container
    cb.container = CreateFrame("Frame", nil, self)
    cb.container:SetWidth(cb.width)
    cb.container:SetHeight(cb.height)

    if not cb.point then
        cb.point = { 'BOTTOMLEFT', self, 'TOPLEFT', 0, 1 }
    end

    -- TODO do this?
    --if cb.horizcenter == nil or cb.horizcenter == true then
        cb.container:SetPoint(unpack(cb.point))
    --end

    cb.container:SetScript('OnEvent', function(_, event, ...)
        Update(self, event, ...)
    end)

    cb.o = {}

------------------------------------------------------- Create Totem Bars --
    if cb.class == 'SHAMAN' then
        cb.o.bars = {
            [1] = { colour = {255/255, 109/255, 22/255} },  -- fire
            [2] = { colour = {120/255, 255/255, 60/255} },  -- earth
            [3] = { colour = {112/255, 65/255, 255/255} },  -- air
            [4] = { colour = {112/255, 255/255, 255/255} }, -- water
        }

        cb.o.events  = { 'PLAYER_TOTEM_UPDATE' }
        cb.o.update  = { ['b'] = UpdateShamanBar }
        cb.o.create  = CreateGenericBar
        cb.o.tooltip = ShamanTooltip
------------------------------------------------------------ Create Runes --
    elseif cb.class == 'DEATHKNIGHT' then
        cb.o.bars = {
            [1] = {}, [2] = {},
            [3] = { id = 5 }, [4] = { id = 6 },
            [5] = { id = 3 }, [6] = { id = 4 },
        }
        cb.o.events = { 'RUNE_POWER_UPDATE', 'RUNE_TYPE_UPDATE' }

        cb.colours = {
            [1] = { .7, 0, 0 },     -- blood
            [2] = { .3, .7, 0 },    -- unholy
            [3] = { .2, .2, .8 },   -- frost
            [4] = { 1, .5, 0 }      -- death
        }

        cb.o.create = function(self)
            RuneFrame:Hide()
            RuneFrame.Show = function() return end
            RuneFrame:UnregisterAllEvents()
        end

        cb.o.update = { ['b'] = UpdateDeathKnightBar }
---------------------------------------------------------- Create Eclipse --
    elseif cb.class == 'DRUID' then
        cb.o.rows = 1
        cb.o.groups = { [1] = { rows = 1 }, [2] = { rows = 3 } }
        cb.o.bars = {
            [1] = { group = 2, colour = { 0, 1, .6 } },
            [2] = { group = 2, colour = { 0, 1, .6 } },
            [3] = { group = 2, colour = { 0, 1, .6 } },
            [4] = { group = 1, colour = { 111/255, 186/255, 245/255 }, minmax = { 0, 100 } }, -- lunar
            [5] = { group = 1, colour = { 78/255, 95/255, 190/255 } }, -- mana
        }
        cb.o.events = {
            'PLAYER_TOTEM_UPDATE',
            'UPDATE_SHAPESHIFT_FORM',
            'ECLIPSE_DIRECTION_CHANGE',
            'UNIT_POWER', 'UNIT_MAXPOWER', 'UNIT_AURA'
        }

        cb.o.create = CreateEclipseBar
        cb.o.update = { ['f'] = UpdateDruid, ['b'] = UpdateDruidShrooms }
        cb.o.tooltip = ShamanTooltip
----------------------------------------------------------- Create holy power --
    elseif cb.class == 'PALADIN' then
        cb.type = SPELL_POWER_HOLY_POWER
        cb.o.colour = { 1, 1, 0 }

        cb.o.events = { 'UNIT_POWER' }
        cb.o.update = { ['f'] = UpdateGeneric }
------------------------------------------------------- Create warlock powers --
    elseif cb.class == 'WARLOCK' then
        cb.level = 10
        cb.type = SPELL_POWER_SOUL_SHARDS
        cb.o.colour = { .5, 0, 1 }

        cb.o.events = { 'UNIT_POWER' }
        cb.o.update = { ['f'] = UpdateGeneric }
------------------------------------------------------------ Shadow orbs (13) --
    elseif cb.class == 'PRIEST' then
        cb.types = {
            ['mana'] = {
                bars = {{ colour = { 78/255, 95/255, 190/255 } }},
                update = { ['f'] = UpdateShadowPriestMana },
                events = { 'UNIT_POWER', 'UNIT_POWER_FREQUENT', 'UNIT_MAXPOWER' }
            }
        }
-------------------------------------------------------------------- Chi (12) --
    elseif cb.class == 'MONK' then
        cb.type = SPELL_POWER_CHI

        cb.o.colour = { .5, 1, 1 }

        cb.o.events = { 'UNIT_POWER' }
        cb.o.update = { ['f'] = UpdateGeneric }
---------------------------------------------------------------- combo points --
    elseif cb.class == 'ROGUE' then
        cb.type = SPELL_POWER_COMBO_POINTS
        cb.o.bars =   { {},{},{},{},{} }
        cb.o.colour = { 1,1,.1 }
        cb.o.events = { 'UNIT_POWER', 'UNIT_MAXPOWER', 'PLAYER_TALENT_UPDATE' }
        cb.o.update = { ['f'] = UpdateComboPoints }
    end

    self:RegisterEvent('PLAYER_ENTERING_WORLD', Update)

    if cb.type or cb.types then
        self:RegisterEvent('UNIT_MAXPOWER', UpdateObject)
        self:RegisterEvent('PLAYER_TALENT_UPDATE', UpdateObject)
    end

    if cb.type or cb.types then
        UpdateObject(self) -- parse object
    else
        CreateBars(self)
    end
end

oUF:AddElement("ClassBars", nil, Enable, nil)
