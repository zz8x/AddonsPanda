-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье", "Призрачный волк"}
local teammate = nil
function Idle()
    if IsReadySpell("Тотем трепета") and TimerLess("AntiFear", 1) then
        if HasTotem(1) ~= "Тотем трепета" and DoSpell("Тотем трепета") then return end
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
        CheckTarget()
        Rotation()
        return
    end
end

-- Актуально при игре в 2 хила, для уменьшения оверхила
local healCastSpells = {"Великая волна исцеления", "Волна исцеления", "Цепное исцеление"}
function CheckHealCast(u, h)
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo("player")
    if not spell or not endTime then return end
    if not tContains(healCastSpells, spell) then return end
    if not InCombatLockdown() or IsControlKeyDown() then return end
    
    local lastHealCastTarget = GetLastSpellTarget(spell)
    if not lastHealCastTarget then return end
    if UnitThreat(lastHealCastTarget) == 3 then return end

    local last = endTime/1000 - GetTime()
    if last > 0.4 and not(h < 45 and not IsOneUnit(u, lastHealCastTarget)) then return end
    local incomingheals = UnitGetIncomingHeals(u)
    local hp = UnitHealth(u) + incomingheals
    local maxhp = UnitHealthMax(u)
    local spellHeal = GetSpellAmount(spell, 0)
    local lost = maxhp - (hp - spellHeal)
    if (lost < (spellHeal * 0.5)) then -- 80% оверхила допустимо
        oexecute("SpellStopCasting()")
        print("Для игрока ", UnitName(lastHealCastTarget), " хилка ", spell, " особо не нужна." )
    end
end

local attackCasts = {"Молния", "Цепная молния", "Выброс лавы"}
local rUnit, rCount, rDist = nil, 0, {}
function HealRotation()
    local members = GetHealingMembers(UNITS)
    if #members < 1 then return false end
    local u = members[1]
    local h = UnitHealth100(u)
    local l = UnitLostHP(u)
    if TryInterrupt(TARGETS, h > 40) then return end

    local unitWithShield, threatLowHPUnit, threatLowHP, lowhpmembers, notfullhpmembers = nil, nil, 1000, 0, 0
    local myHP, myMana =  UnitHealth100("player"), UnitMana100("player")
    for i=1,#members do 
        local u = members[i]
        local h = UnitHealth100(u)
        if HasMyBuff("Щит земли", 1, u) then unitWithShield = u end
        if (UnitThreatAlert(u) == 3) and (h < threatLowHP) and (not IsOneUnit(u, "player")) then
           threatLowHPUnit = u  
           threatLowHP = h 
        end
        if h < 40 then lowhpmembers = lowhpmembers + 1 end
        if h < 100 then notfullhpmembers = notfullhpmembers + 1 end
    end 

    if (myMana > 50 and myHP < 40) then
       threatLowHPUnit = "player"
       threatLowHP = myHP  
    end

    if h > 30 and IsReadySpell("Очищение духа") and UnitMana100("player") > 10  then
        for i = 1, #members do
            if (IsAlt() or InControl(members[i])) and TryDispel(members[i]) then return end
        end
    end

    CheckHealCast(u, h)
    local overheal =  0.3
    if FastUpdate then
        if not CanHeal(rUnit) then
            rUnit, rCount = nil, 0    
        end
    else
        rUnit, rCount = nil, 0
        wipe(rDist)
        local amount = GetSpellAmount("Цепное исцеление", 6000) * 0.1 * overheal
        for i=1,#members do 
            local u, c = members[i], 0
            for j=1,#members do
                local u2 = members[j]
                if UnitLostHP(u2) > amount then
                    local d = rDist[u..u2] or rDist[u2..u] 
                    if not d then
                        d = CheckDistance(u, u2) or 100
                        rDist[u..u2] = d
                        rDist[u2..u] = d
                    end
                    if d < 10  then c = c + 1 end 
                end
            end
            if rUnit == nil or rCount < c then 
                rUnit = u
                rCount = c
            end
        end 
    end


    if HasBuff("Стремительность предков") then
        if rUnit and rCount > 2 then
            if DoSpell("Цепное исцеление", rUnit) then return end 
        else
            if DoSpell("Великая волна исцеления", u) then return end
        end
        return 
    end

    if IsArena() and not InCombatLockdown() and not HasBuff("Водный щит") and not unitWithShield and DoSpell("Щит земли", "player") then return end

    if GetInventoryItemID("player", 16) and not sContains(GetTemporaryEnchant(16), "Жизнь Земли") and DoSpell("Оружие жизни земли") then return end

    if not (HasBuff("Водный щит") or HasBuff("Щит земли")) and DoSpell("Водный щит") then return end

    if threatLowHPUnit and InCombatLockdown() then
        if unitWithShield and UnitThreatAlert(unitWithShield) < 3 and threatLowHPUnit and (threatLowHP < 70) then
            TimerReset("Shield")
            unitWithShield = nil
        end
        
        if not unitWithShield and not TimerLess("Shield", 3) and DoSpell("Щит земли", threatLowHPUnit) then 
            TimerStart("Shield")
            return 
        end
        
        if unitWithShield and not IsOneUnit(unitWithShield, threatLowHPUnit) and threatLowHP < 65 and not TimerLess("Shield", 6) and DoSpell("Щит земли", threatLowHPUnit) then 
            TimerStart("Shield")
            return
        end
    end

    if HasSpell("Быстрина") and IsReadySpell("Быстрина") then
        local amount = GetSpellAmount("Быстрина", 6000) * overheal
        for i=1,#members do
            local u = members[i]
            if not HasMyBuff("Быстрина", 1 , u) and (UnitLostHP(u) > amount or UnitHealth100(u) < 65) and DoSpell("Быстрина", u) then return end
        end
    end

    if h < 95 and DoSpell("Высвободить чары стихий", u) then return end

    if InCombatLockdown() then
        if (h < 45 or lowhpmembers > 2) and HasSpell("Стремительность предков") and DoSpell("Стремительность предков") then chat("Мгновенка!") return end
        if (lowhpmembers > 1 or l > GetSpellAmount("Великая волна исцеления", 12000)) and UseEquippedItem("Талисман стрел разума") then return end
        if (lowhpmembers > 1 or l > GetSpellAmount("Великая волна исцеления", 12000)) and UseEquippedItem("Знак отличия Властелина Земли") then return end
    end

    if h < 38 and DoSpell("Исцеляющий всплеск", u) then return end

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

    local ChainHeal = GetSpellAmount("Цепное исцеление", 7000) * overheal
    local HealingWaveHeal = GetSpellAmount("Великая волна исцеления", 12000) * overheal
    local LesserHealingWaveHeal = GetSpellAmount("Волна исцеления", 8000) * overheal
    
    if PlayerInPlace() then
    
        if h < 25 and (l > HealingWaveHeal) and HasMyBuff("Приливные волны", 1, "player") and DoSpell("Великая волна исцеления", u) then return end
        if h < 10 and DoSpell("Волна исцеления", u) then return end
        
        if h > 40 and rCount > 1 and not IsPvP() and (l > ChainHeal or h < 80) and DoSpell("Цепное исцеление", rUnit) then return end 
        if h > 70 and rCount > 1 and IsBattleground() and (UnitThreatAlert("player") < 3) and DoSpell("Цепное исцеление", rUnit) then return end 
        
        -- мана сейв
        if h > 50 and myMana < 50 and (l > LesserHealingWaveHeal * 1.2) and HasMyBuff("Приливные волны", 1.5, "player") and DoSpell("Волна исцеления", u) then return end
        
        if IsPvP() and (l > HealingWaveHeal) and HasMyBuff("Приливные волны", 1.5, "player") and DoSpell("Великая волна исцеления", u) then return end
        if IsPvP() and (l > LesserHealingWaveHeal) and (l < HealingWaveHeal) and DoSpell("Волна исцеления", u) then return end 
        
        if (l > HealingWaveHeal) and DoSpell("Великая волна исцеления", u) then return end
        
        if (h < 40 or l > LesserHealingWaveHeal) and UnitMana100("player") > 50 and DoSpell("Волна исцеления", u) then return end
        
        
        if h < 100 and IsControlKeyDown() then
            if rUnit and rCount > 1 then
                if DoSpell("Цепное исцеление", rUnit) then return end 
            else
                if DoSpell("Волна исцеления", u) then return end
            end
        end
        
    end
    
    if (h > 60 and myMana > 50) and (CanInterrupt or IsPvP()) then
        if IsSpellNotUsed("Очищение духа", 5) and TryDispel(IUNITS) then return  end
        if IsSpellNotUsed("Развеивание магии", 5) and TrySteal(ITARGETS) then return  end
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
        --if UnitLostHP("player") > 500 and UseEquippedItem("Особое оборудование Чурбана") then return true end
        if hp < 60 and DoSpell("Наставления предков") then return true end
        if hp < 50 and DoSpell("Каменная форма") then return true end
    end
    if  PlayerInPlace() then
        if hp < 40 and IsPlayerCasting() and not IsSpellInUse("Исцеляющий всплеск") then oexecute("SpellStopCasting()") end
        if hp < (IsCtr() and 99 or 60) then DoSpell("Исцеляющий всплеск", "player")  return true end
        if hp < 40 then return true end        
        if teammate then
            local t = UnitHealth100(teammate)
            if t < 40 and IsPlayerCasting() and not IsSpellInUse("Исцеляющий всплеск") then oexecute("SpellStopCasting()") end
            if CanHeal(teammate) and t < (IsCtr() and 99 or 55) and  DoSpell("Исцеляющий всплеск", teammate) then return true end
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
    
    if IsNotAttack("target") then return end

    if not CanAttack() then return end

    if IsSpellNotUsed("Развеивание магии", 2) and TrySteal("target") then return end

    --[[if IsShift() and IsReadySpell("Землетрясение") then
        DoSpell("Землетрясение", "target")
        return
    end]]

    

    if HasMyDebuff("Огненный шок", 5,"target") and (select(4, HasBuff("Щит молний")) or 0) > 6 and DoSpell("Земной шок") then return end
    
    if HasBuff("Волна лавы") then
        if IsPlayerCasting(0.5) then oexecute("SpellStopCasting()") end
        if DoSpell("Выброс лавы") then return end
    end
    if not HasMyDebuff("Огненный шок", 1,"target") then
          if DoSpell("Огненный шок") then return end
          if IsReadySpell("Огненный шок") then return end
    end

    if InCombatLockdown() then
        if UseEquippedItem("Талисман стрел разума") then return end
        if UseEquippedItem("Знак отличия Властелина Земли") then return end
        if DoSpell("Покорение стихий") then return end
    end
    if PlayerInPlace() and HasMyDebuff("Огненный шок", 1.5,"target") and  DoSpell("Выброс лавы") then return end
    if DoSpell("Высвободить чары стихий") then return end
    if IsAOE() and PlayerInPlace() then
        if DoSpell("Цепная молния") then return end
    else
        if DoSpell("Молния") then return end    
    end 
    
end
