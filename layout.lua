--[[
    Kui Unit Frames
    Kesava-Auchindoun
    All rights reserved

    Unit factory
]]
local addon,ns=...
local oUF = oUF
local kui = LibStub('Kui-1.0')
ns.frames = {}
-------------------------------------------------- Individual unit layout --
local function MainLayout(self, unit)
    ns.CreateMainElements(self)
end
oUF:RegisterStyle("KuitwoMain", MainLayout)
------------------------------------------------------------- Arbitrary stuff --
local function SpawnFrame(unit)
    ns.frames[unit] = oUF:Spawn(unit)
    _G['oUF_Kuitwo_'..unit] = ns.frames[unit]
    ns.InitFrame(ns.frames[unit])
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

    -- add ouf tags
    oUF.Tags.Methods['kui:hp'] = function(u,r)
        local m = UnitHealthMax(u)
        local c = UnitHealth(u)

        if c == m or c == 0 or m == 0 then
            return
        elseif UnitIsFriend('player',u) then
            return '-'..kui.num(m-c)
        else
            local p = c / m * 100
            if p < 1 then
                return string.format('%.1f', p)
            else
                return math.ceil(p)
            end
        end
    end
    oUF.Tags.Events['kui:hp'] = 'UNIT_MAXHEALTH UNIT_HEALTH_FREQUENT UNIT_CONNECTION'
    oUF.Tags.Methods['kui:curhp'] = function(u,r)
        local c = UnitHealth(u or r)
        if c > 0 then
            return kui.num(c)
        end
    end
    oUF.Tags.Events['kui:curhp'] = 'UNIT_HEALTH_FREQUENT'
    oUF.Tags.Methods['kui:pp'] = function(u,r)
        return kui.num(UnitPower(u or r))
    end
    oUF.Tags.Events['kui:pp'] = 'UNIT_POWER_UPDATE UNIT_POWER_FREQUENT'
    oUF.Tags.Methods['kui:status'] = function()
        local final
        if UnitAffectingCombat('player') then
            final = '|cffffaaaacbt|r'
        end

        if IsResting() then
            final = (final and final..' ' or '')..'|cffffffaarst|r'
        end

        if UnitIsPVP('player') and not GetPVPDesired() then
            if IsPVPTimerRunning() then
                local timer = math.floor(GetPVPTimer() / 1000)
                final = (final and final..' ' or '')..
                    '|cffbbffbb'..(timer >= 60 and
                    math.floor(timer / 60)..'m' or
                    timer..'s')..'|r'
            else
                final = (final and final..' ' or '')..'|cffaaffaapvp|r'
            end
        end

        return final
    end
    oUF.Tags.Events['kui:status'] = 'PLAYER_UPDATE_RESTING PLAYER_REGEN_DISABLED PLAYER_REGEN_ENABLED PLAYER_FLAGS_CHANGED UNIT_FACTION'
    oUF.Tags.SharedEvents['PLAYER_REGEN_ENABLED'] = true
    oUF.Tags.SharedEvents['PLAYER_REGEN_DISABLED'] = true
    oUF.Tags.SharedEvents['PLAYER_FLAGS_CHANGED'] = true

    -- Spawn individual units ----------------------------------------------
    self:SetActiveStyle("KuitwoMain")
    SpawnFrame('player')
    SpawnFrame('pet')
    SpawnFrame('pettarget')
    SpawnFrame('target')
    SpawnFrame('targettarget')
    SpawnFrame('focus')
    SpawnFrame('focustarget')
end)
