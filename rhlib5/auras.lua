-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local UnitAura = UnitAura
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------
local tooltip
function GetTooltip()
     if tooltip == nil then
        tooltip = CreateFrame("GameTooltip", "hiddenTooltip")
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip.left = {}
        tooltip.right = {}
        -- Most of the tooltip lines share the same text widget,
        -- But we need to query the third one for cooldown info
        for i = 1, 30 do
            tooltip.left[i] = tooltip:CreateFontString()
            tooltip.left[i]:SetFontObject(GameFontNormal)
            if i < 5 then
                tooltip.right[i] = tooltip:CreateFontString()
                tooltip.right[i]:SetFontObject(GameFontNormal)
                tooltip:AddFontStrings(tooltip.left[i], tooltip.right[i])
            else
                tooltip:AddFontStrings(tooltip.left[i], tooltip.right[4])
            end
        end 
    end
    tooltip:ClearLines()
    return tooltip
end
------------------------------------------------------------------------------------------------------------------
-- Универсальный внутренний метод, для работы с бафами и дебафами
-- HasAura('auraName' or {'aura1', ...}, minExpiresTime(s), 'target' or {'target', 'focus', ...}, UnitDebuff or UnitBuff or UnitAura, bool AuraCaster = player)
function HasAura(aura, last, target, method, my)
    if aura == nil then return nil end
    if method == nil then method = UnitAura end
    if target == nil then target = "player" end
    if last == nil then last = 0.1 end
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
    if type(target) == 'table' and #target > 0 then 
        for i = 1, #target do 
			name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = HasAura(aura, last, target[i], method, my)
			if name then break end
		end
		return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
    end
    if not UnitExists(target) then return nil end
    for i = 1, 40 do
        name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = method(target, i)
        if not name then return nil end
        if (expirationTime - GetTime() >= last or expirationTime == 0) and (not my or unitCaster == "player") then
            if (type(aura) == 'table') then
                for i = 1, #aura do 
                    local a = aura[i]
                    if (sContains(name, a) or (debuffType and sContains(debuffType, a))) then break end 
                end
            else
                if (sContains(name, aura) or (debuffType and sContains(debuffType, aura))) then break end 
            end
        end
    end 
    return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
end

------------------------------------------------------------------------------------------------------------------
function HasDebuff(aura, last, target, my)
    if target == nil then target = "target" end
    return HasAura(aura, last, target, UnitDebuff, my)
end

------------------------------------------------------------------------------------------------------------------
function HasBuff(aura, last, target, my)
    if target == nil then target = "player" end
    return HasAura(aura, last, target, UnitBuff, my)
end

------------------------------------------------------------------------------------------------------------------
function HasMyBuff(aura, last, target)
    return HasBuff(aura, last, target, true)
end

------------------------------------------------------------------------------------------------------------------
function HasMyDebuff(aura, last, target)
    return HasDebuff(aura, last, target, true)
end
------------------------------------------------------------------------------------------------------------------
-- using: HasTemporaryEnchant(16 or 17)
--/run print(GetTemporaryEnchant(16))
function GetTemporaryEnchant(slot)
    local enchantTooltip = GetTooltip()
    enchantTooltip:SetInventoryItem("player", slot)
    local nLines = enchantTooltip:NumLines()
    for i = 1, nLines do
        local txt = enchantTooltip.left[i]
        if ( txt:GetTextColor() == 0 ) then
            local line = txt:GetText()  
            local paren = line:find("[(]")
            if ( paren ) then
                line = line:sub(1,paren-2)
                return line
            end
        end
    end
end