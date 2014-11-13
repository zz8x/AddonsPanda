-- Warrior Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_WRH = "Warrior Rotation Helper"
BINDING_NAME_WRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_WRH_AUTOAOE = "Вкл/Выкл авто AOE"

print("|cff0055ffRotation Helper|r|cffffe00a > |r|cff804000Warrior|r loaded")
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

        if InMelee(target) and (channel or t < 0.8) and IsReadySpell("Зуботычина") then
            if canStopCasting then oexecute("SpellStopCasting()") end
            if DoSpell("Зуботычина", target) then
                echo("Зуботычина"..m)
                TimerStart('Interrupt')
                return true 
            end
        end

        if not channel and IsReadySpell("Отражение заклинания") and IsHarmfulCast(spell) and IsOneUnit("player", target .. "-target") then
            if canStopCasting  then oexecute("SpellStopCasting()") end
            if DoSpell("Отражение заклинания") then
                TimerStart('Interrupt')
                echo("Отражение"..m)
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
   return IsShift()
    or (AutoAOE and IsValidTarget("target") and IsValidTarget("focus") 
        and not IsOneUnit("target", "focus") 
        and UnitAffectingCombat("focus") and UnitAffectingCombat("target"))
        and InDistance("target", "focus", 8)
end

------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target, mana)
    return UseSpell(spell, target, mana)
end
