-- Warrior Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}

function Idle()
    if IsAttack() or IsMouse(3) then
        if HasBuff("Парашют") then oexecute('CancelUnitBuff("player", "Парашют")') return end
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end

    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    
    --[[if IsCtr() or InCombatMode() then
       if TryHeal() then return end
    end]]

	if InCombatMode() then
        CheckTarget()
        TryProtect()
        Rotation()
        return
    end
end

function TryProtect()
    local hp = UnitHealth100("player")
    if IsPvP() and hp < 60 and DoSpell("Оборонительная стойка") then return end
    if hp < 50 and DoSpell("Бой насмерть") then return end
    if hp < 30 and DoSpell("Глухая оборона") then return end
    if HasBuff("Глухая оборона") and DoSpell("Ободряющий клич") then return end
    return false
end

function TryHeal()
    local hp = UnitHealth100("player")
    if not (IsArena() or InDuel()) then
        if hp < 35 then UseHealPotion() end
    end
    return false
end

function Rotation()
    
    if TryInterrupt(TARGETS) then return end
 
    if IsNotAttack("target") then return end
    if IsPvP() and UnitHealth100("player") > 60 and DoSpell("Боевая стойка") then return end
    if InRange("Рывок") and DoSpell("Рывок") then return end
    if IsShift() and DoSpell("Удар грома") then return end
    if IsCtr() then
        if DoSpell("Безрассудство") then return end
        if HasSpell("Вихрь клинков") and UnitMana100(player) > 30 and DoSpell("Размашистые удары") then return end
        if DoSpell("Знамя с черепом") then return end
        if UseItem("Жетон победы бездушного гладиатора") then return end
        if HasSpell("Вихрь клинков") and DoSpell("Вихрь клинков") then return end
        if HasSpell("Ударная волна") and DoSpell("Ударная волна") then return end
        return
    end
    --if not IsReadySpell("Рывок") and InRange("Рывок") and DoSpell("Героический прыжок", "target") then return end
    if IsReadySpell("Победный раж") and UnitHealth100(player) < 70 and DoSpell("Победный раж")  then return end
    --if IsValidTarget() and UnitMana100(player) < 45 and DoSpell("Ярость берсерка") then return end
    if IsPvP() and not HasMyDebuff("Пронзительный вой", 1, target) and CheckInteractDistance("target", 2) and IsSpellNotUsed("Пронзительный вой", 3) and DoSpell("Пронзительный вой") then return end
    if InMelee(target) and DoSpell("Удар колосса") then return end
    if InMelee(target) and DoSpell("Смертельный удар") then return end
    if not IsPvP() and IsValidTarget() and DoSpell("Удар громовержца") then return end

    if IsShift() and UnitMana100(player) > 30 and DoSpell("Вихрь") then return end

    if InMelee(target) and UnitMana100(player) > 45 and DoSpell("Казнь") then return end
    if InMelee(target) and UnitMana100(player) > 45 and DoSpell("Мощный удар") then return end
    if InMelee(target) and DoSpell("Превосходство") then return end
    if IsValidTarget() and DoSpell("Героический бросок") then return end 
    if not HasBuff("крик") and DoSpell("Боевой крик") then return end
    if HasBuff("крик") and not HasMyBuff("крик") then
        if HasBuff("Боевой крик") and DoSpell("Командирский крик") then return end
        if HasBuff("Командирский крик") and DoSpell("Боевой крик") then return end
        return
    end 
    if DoSpell("Боевой крик") then return end

    --if DoSpell("Молния") then return end    
end
