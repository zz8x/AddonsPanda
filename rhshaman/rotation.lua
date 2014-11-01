-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
local function actualDistance(target)
    return InRange("Молния", target)
end 
local peaceBuff = {"Пища", "Питье", "Призрачный волк"}
local teammate = nil
function Idle()
    if InControl("player", 5) and IsReadySpell("Тотем трепета") then
        if HasTotem(2) ~= "Тотем трепета" and DoSpell("Тотем трепета") then return end
        return
    end
    if AutoFreedom() then return end
    if IsAttack() or IsMouse(3) then
        if HasBuff("Парашют") then oexecute('CancelUnitBuff("player", "Парашют")') return end
        if HasBuff("Призрачный волк") then  oexecute('CancelUnitBuff("player", "Призрачный волк")') return end
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end



    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    
    --[[if IsFarm() then
        if PlayerInPlace() and not InCombatLockdown() and UnitMana100("player") < 60 and UseItem("Дамайча") then return end
        InCombatMode()
    end]]

    if not FastUpdate then
        teammate = GetTeammate()
    end

    if not FastUpdate and IsReadySpell("Пронизывающий ветер") then
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if CanAttack(t) and UnitAffectingCombat(t) and HasBuff("Отражение заклинания", 1, t) and DoSpell("Пронизывающий ветер", t) then return end
        end
    end

    if HasSpell("Быстрина") then
        HealRotation()
        return
    end

    if IsCtr() or InCombatMode() then
       if TryHeal() then return end
    end

	if InCombatMode() then
        CheckTarget(true, actualDistance)
        Rotation()
        return
    end
end

local attackCasts = {"Молния", "Цепная молния", "Выброс лавы"}
local rUnit, rCount =  nil, 0
function HealRotation()
    local members = GetHealingMembers(UNITS)
    if #members < 1 then return false end
    local u = members[1]
    local h = UnitHealth100(u)
    local l = UnitLostHP(u)


    if HasBuff("Стремительность предков") then
        if DoSpell("Великая волна исцеления", u) then return end
        return 
    end

    if TryInterrupt(TARGETS, h > 40) then return end


    if h > 30 and IsReadySpell("Очищение духа") and UnitMana100("player") > 10  then
        for i = 1, #members do
            local u = members[i]
            if (IsAlt() or InControl(u)) and TryDispel(u) then return end
        end
    end

    if IsArena() and not InCombatLockdown() and not HasBuff("Водный щит") and not unitWithShield and DoSpell("Щит земли", "player") then return end

    if GetInventoryItemID("player", 16) and not sContains(GetTemporaryEnchant(16), "Жизнь Земли") and DoSpell("Оружие жизни земли") then return end

    if not (HasBuff("Водный щит") or HasBuff("Щит земли")) and DoSpell("Водный щит") then return end

    local myHP, myMana =  UnitHealth100("player"), UnitMana100("player")
    local unitWithShield, threatLowHPUnit, threatLowHP = nil, "player", 1000
    if (myMana > 50 and myHP < 40) then
       threatLowHP = myHP  
    else
        for i=1,#members do 
            local u = members[i]
            local h = UnitHealth100(u)
            if HasMyBuff("Щит земли", 5, u) then unitWithShield = u end
            if (UnitThreatAlert(u) == 3) and (h < threatLowHP) and (not IsOneUnit(u, "player")) then
               threatLowHPUnit = u  
               threatLowHP = h 
            end
        end 
    end

    
    if unitWithShield and not IsOneUnit(unitWithShield, threatLowHPUnit) and UnitThreatAlert(unitWithShield) < 3 and (threatLowHP < 70) then
        TimerReset("Shield")
        unitWithShield = nil
    end
    
    if not unitWithShield and TimerMore("Shield", 2) and DoSpell("Щит земли", threatLowHPUnit) then 
        TimerStart("Shield")
        return 
    end
    
    if unitWithShield and not IsOneUnit(unitWithShield, threatLowHPUnit) and threatLowHP < 65 and TimerMore("Shield", 4) and DoSpell("Щит земли", threatLowHPUnit) then 
        TimerStart("Shield")
        return
    end
    

    if HasSpell("Быстрина") and IsReadySpell("Быстрина") then
        for i=1,#members do
            local u = members[i]
            if UnitHealth100(u) < (HasMyBuff("Быстрина", 1 , u) and 50 or 95) and DoSpell("Быстрина", u) then return end
        end
    end

    if h < 95 and DoSpell("Высвободить чары стихий", u) then return end

    local overheal =  0.3
    local GreatHealingWaveHeal = GetSpellAmount("Великая волна исцеления", 12000) * overheal
    local HealingWaveHeal = GetSpellAmount("Волна исцеления", 8000) * overheal

    if InCombatLockdown() then
        if l > GreatHealingWaveHeal and UseEquippedItem("Талисман стрел разума") then return end
        if l > GreatHealingWaveHeal and UseEquippedItem("Знак отличия Властелина Земли") then return end
        if h < 35 and HasSpell("Стремительность предков") and DoSpell("Стремительность предков") then chat("Мгновенка!") return end
    end

    if IsAttack() and h > 60 then
        if not IsInteractUnit("target") then CheckTarget() end

        if not  IsNotAttack("target") and CanAttack("target") then 
            if IsSpellNotUsed("Развеивание магии", 2) and TrySteal("target") then return end

            if not HasMyDebuff("Огненный шок", 1,"target") and  DoSpell("Огненный шок") then return end

            if PlayerInPlace() and HasMyDebuff("Огненный шок", 1.5,"target") and  DoSpell("Выброс лавы") then return end

            if IsAOE() and PlayerInPlace() then
                if DoSpell("Цепная молния") then return end
            else
                if DoSpell("Молния") then return end    
            end 

        end
    end

    if h < 40 then
        local spell = UnitCastingInfo("player")
        if spell and tContains(attackCasts, spell) then oexecute("SpellStopCasting()") end
    end

    
    if PlayerInPlace() or HasBuff("Благосклонность предков", 1) then
                    
        if h < 38 and DoSpell("Исцеляющий всплеск", u) then return end

        if FastUpdate then
            if not CanHeal(rUnit) then
                rUnit, rCount = nil, 0    
            end
        else
            rUnit, rCount = nil, 0
            for i=1,#members do 
                local u1, c = members[i], 0
                if UnitHealth100(u1) < 95 then
                    for j=1,#members do
                        local u2 = members[j]
                        if UnitHealth100(u2) < 95 then
                            local d = CheckDistance(u1, u2) or 100
                            if d < 10  then c = c + 1 end 
                        end
                    end
                    if rCount < c then 
                        rUnit = u1
                        rCount = c
                    end
                end
            end 
        end

        if h > 50 and rCount > 1 and DoSpell("Цепное исцеление", rUnit) then return end

        if (l > GreatHealingWaveHeal) then
            if HasMyBuff("Приливные волны", 1.5, "player") and DoSpell("Великая волна исцеления", u) then return end
        else
            if (l > HealingWaveHeal) and DoSpell("Волна исцеления", u) then return end 
        end

        
        if h < 100 and IsCtr() then
            if rCount > 1 then
                if DoSpell("Цепное исцеление", rUnit) then return end 
            else
                if DoSpell("Волна исцеления", u) then return end
            end
        end
        
    end

    if (h > 60 or not PlayerInPlace()) and myMana > 50 and (CanInterrupt or IsPvP()) then
        if IsSpellNotUsed("Очищение духа", 5) and TryDispel(IUNITS) then return  end
        if IsSpellNotUsed("Развеивание магии", 2) and TrySteal(ITARGETS) then return  end
    end

    if not IsAttack() and h > 50 and IsPvP() then
        for i = 1, #ITARGETS do
            local t = ITARGETS[i]
            if CanControl(t) and UnitIsPlayer(t) and not HasDebuff("Ледяной шок", 0.1, t) and DoSpell("Ледяной шок", t) then return  end
        end
    end
end


function TryHeal()
    local hp = UnitHealth100("player")
    if InCombatLockdown() and IsValidTarget("target") then
        if hp < 70 and not HasTotem(3) and DoSpell("Тотем исцеляющего потока") then return true end
        if hp < 60 and DoSpell("Наставления предков") then return true end
        if hp < 50 and DoSpell("Каменная форма") then return true end
        if hp < 40 and not HasTotem(3) and DoSpell("Тотем целительного прилива") then return true end
    end
    if  PlayerInPlace() or HasBuff("Благосклонность предков", 1) then
        if not (IsArena() or InDuel()) then
            if hp < 35 then UseHealPotion() end
        end
        if hp < 40 and IsPlayerCasting() and not IsSpellInUse("Исцеляющий всплеск") then oexecute("SpellStopCasting()") end
        if hp < (IsCtr() and 99 or 50) then DoSpell("Исцеляющий всплеск", "player")  return true end
        if hp < 40 then return true end        
        if teammate then
            local t = UnitHealth100(teammate)
            if t < 40 and IsPlayerCasting() and not IsSpellInUse("Исцеляющий всплеск") then oexecute("SpellStopCasting()") end
            if CanHeal(teammate) and t < (IsCtr() and 99 or 50) and  DoSpell("Исцеляющий всплеск", teammate) then return true end
            if t < 40 then return true end
        end
        
    end
    if IsSpellInUse("Исцеляющий всплеск") then return true end
    if IsSpellNotUsed("Очищение духа", 2) and TryDispel("player") then return true end
    if teammate and TryDispel(teammate) then return true end

    return false
end

function Rotation()
    
    if TryInterrupt(TARGETS) then return end

    if GetInventoryItemID("player",16) and not sContains(GetTemporaryEnchant(16), "Язык пламени") and DoSpell("Оружие языка пламени") then return end

    if not HasBuff("Щит молний") and DoSpell("Щит молний") then return end
    
    if IsFarm() and InCombatLockdown() then
        if UnitMana100("player") < 60 and DoSpell("Гром и молния") then return end
        if not HasTotem(1) and DoSpell("Тотем магмы") then return end
        --if not HasTotem(2) and DoSpell("Тотем элементаля земли") then return end
    end


    if IsNotAttack("target") then return end

    if not CanAttack() then return end

    if IsSpellNotUsed("Развеивание магии", 2) and TrySteal("target") then return end

    --[[if IsShift() and IsReadySpell("Землетрясение") then
        DoSpell("Землетрясение", "target")
        return
    end]]

    

    if HasMyDebuff("Огненный шок", 5,"target") and (select(4, HasBuff("Щит молний")) or 0) > 6 and DoSpell("Земной шок") then return end
    
    if HasBuff("Волна лавы") then
        if IsPlayerCasting(0.5) and not IsSpellInUse("Выброс лавы") then oexecute("SpellStopCasting()") end
        if DoSpell("Выброс лавы") then return end
    end
    if not HasMyDebuff("Огненный шок", 1,"target") then
          if DoSpell("Огненный шок") then return end
          if IsReadySpell("Огненный шок") then return end
    end

    if InCombatLockdown() then
        --if UseEquippedItem("Талисман стрел разума") then return end
        --if UseEquippedItem("Знак отличия Властелина Земли") then return end
        if DoSpell("Покорение стихий") then return end
        if DoSpell("Удар духов стихии") then return end
        if DoSpell("Высвободить чары стихий") then return end
    end

    --[[if IsReadySpell("Опаляющий тотем") then
            if HasTotem(1) ~= "Тотем магмы" and DoSpell("Опаляющий тотем") then return end
            return
    end]]

    if UnitMana100("player") > 30 and (PlayerInPlace() or HasBuff("Благосклонность предков", 1)) and HasMyDebuff("Огненный шок", 1.5,"target")  then
        if DoSpell("Выброс лавы") then return end
        if IsReadySpell("Выброс лавы") then return end
    end
    
    if IsAOE() and (PlayerInPlace() or HasBuff("Благосклонность предков", 1)) then
        if  DoSpell("Цепная молния") then return end
    else
        if DoSpell("Молния") then return end    
    end 
    
end
