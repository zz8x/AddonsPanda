-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local UnitAura = UnitAura
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetTime = GetTime
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
                local find = false
                for i = 1, #aura do 
                    local a = aura[i]
                    if (sContains(name, a) or (debuffType and sContains(debuffType, a))) then find = true break end 
                end
                if find then break end
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

------------------------------------------------------------------------------------------------------------------
function GetUtilityTooltips()
    if ( not utility_Tooltip1 ) then
        for idxTip = 1,2 do
            local ttname = "utility_Tooltip"..idxTip
            local tt = CreateFrame("GameTooltip", ttname)
            tt:SetOwner(UIParent, "ANCHOR_NONE")
            tt.left = {}
            tt.right = {}
            -- Most of the tooltip lines share the same text widget,
            -- But we need to query the third one for cooldown info
            for i = 1, 30 do
                tt.left[i] = tt:CreateFontString()
                tt.left[i]:SetFontObject(GameFontNormal)
                if i < 5 then
                    tt.right[i] = tt:CreateFontString()
                    tt.right[i]:SetFontObject(GameFontNormal)
                    tt:AddFontStrings(tt.left[i], tt.right[i])
                else
                    tt:AddFontStrings(tt.left[i], tt.right[4])
                end
            end 
         end
    end
    local tt1,tt2 = utility_Tooltip1, utility_Tooltip2
    tt1:ClearLines()
    tt2:ClearLines()
    return tt1,tt2
end

function GetTemporaryEnchant(i_invID)
    local tt1,tt2 = GetUtilityTooltips()
    
    tt1:SetInventoryItem("player", i_invID)
    local n,h = tt1:GetItem()

    tt2:SetHyperlink(h)
    
    -- Look for green lines present in tt1 that are missing from tt2
    local nLines1, nLines2 = tt1:NumLines(), tt2:NumLines()
    local i1, i2 = 1,1
    while ( i1 <= nLines1 ) do
        local txt1 = tt1.left[i1]
        if ( txt1:GetTextColor() ~= 0 ) then
            i1 = i1 + 1
        elseif ( i2 <= nLines2 ) then
            local txt2 = tt2.left[i2]
            if ( txt2:GetTextColor() ~= 0 ) then
                i2 = i2 + 1
            elseif (txt1:GetText() == txt2:GetText()) then
                i1 = i1 + 1
                i2 = i2 + 1
            else
                break
            end
        else
            break
        end
    end
    if ( i1 <= nLines1 ) then
        local line = tt1.left[i1]:GetText()
        local paren = line:find("[(]")
        if ( paren ) then
            line = line:sub(1,paren-2)
        end
        return line
    end    
end