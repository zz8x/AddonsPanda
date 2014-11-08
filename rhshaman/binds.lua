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
    if not notinterrupt and not IsInterruptImmune(target) then

        if (not channel and t < 1.8) and not HasTotem("Тотем заземления") and IsReadySpell("Тотем заземления", true) and IsHarmfulCast(spell) and InRange("Пронизывающий ветер", target) then
            if canStopCasting  then oexecute("SpellStopCasting()") end
             if DoSpell("Тотем заземления") then
                TimerStart('Interrupt')
                echo("Тотем заземления"..m)
                return true 
            end
        end

        if not HasTotem("Тотем заземления") and (channel or t < 0.8) and IsReadySpell("Пронизывающий ветер") and InRange("Пронизывающий ветер", target) then
            if canStopCasting then oexecute("SpellStopCasting()") end
            if DoSpell("Пронизывающий ветер", target) then
                echo("Пронизывающий ветер"..m)
                TimerStart('Interrupt')
                return true 
            end
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


function IsAOE()
    if not IsShift() and UnitMana100("player") < 50 then return false end  
    if AutoAOE and InViewEnemyCount() > 4 then return true end    
   return IsShift()
    or (AutoAOE and IsValidTarget("target") and IsValidTarget("focus") 
        and not IsOneUnit("target", "focus") 
        and UnitAffectingCombat("focus") and UnitAffectingCombat("target"))
        
end
------------------------------------------------------------------------------------------------------------------
local dispelSpell = "Очищение духа"
local dispelTypes = {"Curse"}
local dispelTypesHeal = {"Curse", "Magic"}
local function dispelTarget(unit)
    if not CanHeal(unit) or HasDebuff("Нестабильное колдовство", 0.1, unit) then return false end
    local supportedTypes = HasSpell("Быстрина") and dispelTypesHeal or dispelTypes
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(unit, i,true) 
        if name and isStealable and (expirationTime - GetTime() >= 3 or expirationTime == 0) and tContains(supportedTypes, debuffType) then
            if DoSpell(dispelSpell, unit) then
                print(dispelSpell, name, debuffType, unit)
                return true
            end
            return false
        end
    end
    return false
end

function TryDispel(targets)
    if not CanInterrupt then return false end
    if not HasSpell(dispelSpell) or not IsReadySpell(dispelSpell) then return false end
    if type(targets) == 'table' then
        for i=1, #targets do
            if dispelTarget(targets[i]) then return true end
        end
        return false
    else
        return dispelTarget(targets)
    end
end
------------------------------------------------------------------------------------------------------------------
local stealSpell = "Развеивание магии"
local stealTypes = {"Magic"}
local function stealTarget(unit)
    if not CanMagicAttack(unit) then return false end
    for i = 1, 40 do
        name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitBuff(unit, i,true) 
        if name and isStealable and (expirationTime - GetTime() >= 3 or expirationTime == 0) and tContains(stealTypes, debuffType) then
            if DoSpell(stealSpell, unit) then
                print(stealSpell, name, debuffType, unit)
                return true
            end
            return false
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
