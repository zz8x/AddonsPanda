-- Shaman Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_SRH = "Shaman Rotation Helper"
BINDING_NAME_SRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_SRH_AUTOAOE = "Вкл/Выкл авто AOE"

print("|cff0055ffRotation Helper|r|cffffe00a > |r|cff0000ffShaman|r loaded")
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON",true)
    else
        echo("Interrupt: OFF",true)
    end 
end
------------------------------------------------------------------------------------------------------------------
local function interruptTarget(target, canStopCasting)
    if target == nil then target = "target" end
    if canStopCasting == nil then canStopCasting = IsPlayerCasting(0.5)  end
    local spell, t, channel, notinterrupt, m = GetKickInfo(target)
    if not spell then return false end

    if (not channel and t < 1.8) and not HasTotem("Тотем заземления") and IsReadySpell("Тотем заземления", true) and IsHarmfulCast(spell) and InRange("Пронизывающий ветер", target) then
        if canStopCasting  then 
            StopCast("Interrupt")
        end
         if DoSpell("Тотем заземления") then
            TimerStart('Interrupt')
            echo("Тотем заземления"..m)
            return true 
        end
    end

    if not notinterrupt and not IsInterruptImmune(target)  and not HasTotem("Тотем заземления") and (channel or t < 0.8) and IsReadySpell("Пронизывающий ветер", true) and InRange("Пронизывающий ветер", target) then
        if canStopCasting then 
            StopCast("Interrupt") 
        end
        if DoSpell("Пронизывающий ветер", target) then
            echo("Пронизывающий ветер"..m)
            TimerStart('Interrupt')
            return true 
        end
    end

    return false 
end
function TryInterrupt(targets, canStopCasting)
    if not CanInterrupt then return false end
    if TimerLess('Interrupt', 0.5)  then return false end

    if type(targets) == 'table' then
        for i=1, #targets do
            if interruptTarget(targets[i], canStopCasting) then return true end
        end
        return false
    else
        return interruptTarget(targets, canStopCasting)
    end
end
------------------------------------------------------------------------------------------------------------------
if AutoAOE == nil then AutoAOE = true end

function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON",true)
    else
        echo("Авто АОЕ: OFF",true)
    end 
end

local cnt = 0
function IsAOE(n)
    if IsShift() then return true end
    if not AutoAOE then return false end
    if not n then n = 1 end
    if cnt < 1 or TimerMore('IsAOE', 2) then
        TimerStart('IsAOE')
        cnt = InViewEnemyCount(true)
        local t = IsValidTarget("target") and UnitAffectingCombat("target")
        local f =  IsValidTarget("focus") and UnitAffectingCombat("focus") and (not t or not IsOneUnit("target", "focus"))
        if t and f and cnt < 2 then 
            cnt = 2 
        else
            if (t or f) and cnt < 1 then 
                cnt = 1 
            end
        end
    end
    return cnt > n
end

------------------------------------------------------------------------------------------------------------------
local dispelSpell = "Очищение духа"
local dispelTypes = {"Curse"}
local dispelTypesHeal = {"Curse", "Magic"}
local function getDispelDebuffCount(unit)
    local supportedTypes = HasSpell("Быстрина") and dispelTypesHeal or dispelTypes
    local count = 0
    if CanHeal(unit) and not HasDebuff("Нестабильное колдовство", 0.1, unit) then 
        for i = 1, 40 do
            local name, _, _, _, debuffType, _, expirationTime  = UnitDebuff(unit, i, true) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) and tContains(supportedTypes, debuffType) then
                count = count + 1
            end
        end
    end
    return count
end

function TryDispel(targets)
    if not CanInterrupt then return false end
    if not HasSpell(dispelSpell) or not IsReadySpell(dispelSpell) then return false end
    local unit = nil
    if type(targets) == 'table' then
        local count = 0       
        for i=1, #targets do
            local u = targets[i]
            local c = getDispelDebuffCount(u)
            if c > count then
                unit = u
                count = c
            end
        end
    else
        if getDispelDebuffCount(targets) > 0 then unit = targets end
    end
    return unit and DoSpell(dispelSpell, unit)
end

function TryDispelControl(members)
    if IsReadySpell("Очищение духа") then
        for i = 1, #members do
            local u = members[i]
            local aura = InControl(u, 2)
            if aura then
                local debuffType = select(5, UnitDebuff(u, aura, true)) 
                if debuffType and tContains(dispelTypesHeal, debuffType) then 
                    chat('Диспелим контроль '..aura..' с ' .. UnitName(u))
                    return DoSpell(dispelSpell, u)
                end
            end
        end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
local stealSpell = "Развеивание магии"
local stealTypes = {"Magic"}
local function stealTarget(unit)
    if not CanMagicAttack(unit) then return false end
    for i = 1, 40 do
        name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitBuff(unit, i,true) 
        if name and isStealable and (expirationTime - GetTime() >= 3 or expirationTime == 0) and tContains(stealTypes, debuffType) then
            return DoSpell(stealSpell, unit)
        end
    end
    return false
end

function TrySteal(targets)
    if not CanInterrupt then return false end
    if not HasSpell(stealSpell) or not IsReadySpell(stealSpell) then return false end
    if type(targets) == 'table' then
        for i=1, #targets do
            if stealTarget(targets[i]) then return true end
        end
        return false
    else
        return stealTarget(targets)
    end
end

------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target, mana)
    return UseSpell(spell, target, mana)
end
