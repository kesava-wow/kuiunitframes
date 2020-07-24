--[[
-- Cutaway bar animation for oUF.
-- By Kesava @ curse.com.
-- All rights reserved.
--
-- (also handles inverting because why not)
--]]
local ouf = oUF or oUFKuiEmbed or ns.oUF
local kui = LibStub('Kui-1.0')
if not ouf then return end

local function Cutaway_SetValue(bar,value)
    if not bar:IsVisible() then
        bar:orig_SetValue_Cutaway(value)
        return
    end

    local width = bar:GetWidth()
    local c_val = bar:GetValue()
    local c_max = select(2,bar:GetMinMaxValues())

    if (bar.inverted and (c_max-value) > c_val) or
       (not bar.inverted and value < c_val)
    then
        if not kui.frameIsFading(bar.Cutaway_Fader) then
            if bar.inverted then
                -- (right of bar)
                bar.Cutaway_Fader:SetPoint('RIGHT',bar:GetStatusBarTexture())
                -- (right of bar minus value difference)
                bar.Cutaway_Fader:SetPoint('LEFT',bar,(c_val/c_max)*width,0)
            elseif bar:GetReverseFill() then
                bar.Cutaway_Fader:SetPoint('RIGHT',bar:GetStatusBarTexture(),'LEFT')
                bar.Cutaway_Fader:SetPoint('LEFT',bar,'RIGHT',-(c_val / c_max) * width,0)
            else
                -- (right of bar)
                bar.Cutaway_Fader:SetPoint('LEFT',bar:GetStatusBarTexture(),'RIGHT')
                -- (right of bar plus value difference)
                bar.Cutaway_Fader:SetPoint('RIGHT',bar,'LEFT',(c_val / c_max) * width,0)
            end

            bar.Cutaway_Fader.right = c_val

            kui.frameFade(bar.Cutaway_Fader, {
                mode = 'OUT',
                timeToFade = .2
            })
        end
    end

    if bar.Cutaway_Fader.right and
       ((bar.inverted and (c_max-value) < bar.Cutaway_Fader.right) or
       (not bar.inverted and value > bar.Cutaway_Fader.right))
    then
        -- stop immediately if the value moves beyond our start point
        kui.frameFadeRemoveFrame(bar.Cutaway_Fader)
        bar.Cutaway_Fader:SetAlpha(0)
    end

    if bar.inverted then
        bar:orig_SetValue_Cutaway(c_max-value)
    else
        bar:orig_SetValue_Cutaway(value)
    end
end
local function Cutaway_SetStatusBarColor(bar,...)
    bar:orig_SetStatusBarColor_Cutaway(...)
    bar.Cutaway_Fader:SetVertexColor(...)
end

local function CutawayBar(frame,bar)
    local fader = bar:CreateTexture(nil,'ARTWORK')
    fader:SetTexture('interface/buttons/white8x8')
    fader:SetVertexColor(bar:GetStatusBarColor())
    fader:SetAlpha(0)

    fader:SetPoint('TOP')
    fader:SetPoint('BOTTOM')

    bar.orig_SetValue_Cutaway = bar.SetValue
    bar.SetValue = Cutaway_SetValue

    bar.orig_SetStatusBarColor_Cutaway = bar.SetStatusBarColor
    bar.SetStatusBarColor = Cutaway_SetStatusBarColor

    bar.Cutaway_Fader = fader
end

local function hook(frame)
    frame.CutawayBar = CutawayBar

    for k,v in pairs({'Health','Power'}) do
        if frame[v] and frame[v].Cutaway then
            frame:CutawayBar(frame[v])
        end
    end
end

for i,f in ipairs(ouf.objects) do hook(f) end
ouf:RegisterInitCallback(hook)
