--[[
-- Cutaway bar animation for oUF.
-- By Kesava @ curse.com.
-- All rights reserved.
--]]
local ouf = oUF or oUFKuiEmbed or ns.oUF
local kui = LibStub('Kui-1.0')
if not ouf then return end

local function Cutaway_SetValue(bar,value)
    if not bar:IsVisible() then
        bar:orig_SetValue_Cutaway(value)
        return
    end

    if value < bar:GetValue() then
        if not kui.frameIsFading(bar.Cutaway_Fader) then
            if bar:GetReverseFill() then
                bar.Cutaway_Fader:SetPoint('RIGHT',bar:GetStatusBarTexture(),'LEFT')
                bar.Cutaway_Fader:SetPoint('LEFT',bar,'RIGHT',
                    -(bar:GetValue() / select(2,bar:GetMinMaxValues())) * bar:GetWidth(),
                    0
                )
            else
                bar.Cutaway_Fader:SetPoint('LEFT',bar:GetStatusBarTexture(),'RIGHT')
                bar.Cutaway_Fader:SetPoint('RIGHT',bar,'LEFT',
                    (bar:GetValue() / select(2,bar:GetMinMaxValues())) * bar:GetWidth(),
                    0
                )
            end

            bar.Cutaway_Fader.right = bar:GetValue()

            kui.frameFade(bar.Cutaway_Fader, {
                mode = 'OUT',
                timeToFade = .2
            })
        end
    end

    if bar.Cutaway_Fader.right and value > bar.Cutaway_Fader.right then
        kui.frameFadeRemoveFrame(bar.Cutaway_Fader)
        bar.Cutaway_Fader:SetAlpha(0)
    end

    bar:orig_SetValue_Cutaway(value)
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
