-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
local function actualDistance(target)
    return InRange("Молния", target)
end 
local peaceBuff = {"Пища", "Питье", "Призрачный волк"}
function Idle()
    if TimerLess('Control', 2) and InControl("player", 5) and IsReadySpell("Тотем трепета") then
        if HasTotem(2) ~= "Тотем трепета" and DoSpell("Тотем трепета") then return end
        return
    end
    if InCombatLockdown() and not IsReadySpell("Тотем трепета") and DoSpell("Зов Стихий") then return end
    if AutoFreedom() then return end

    if IsAttack() or IsMouse(3) then
        if HasBuff("Парашют") then oexecute('CancelUnitBuff("player", "Парашют")') return end
        if HasBuff("Призрачный волк") then oexecute('CancelUnitBuff("player", "Призрачный волк")') return end
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end

    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end

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
local function CheckCast()
    local spell = UnitCastingInfo("player")
    if not spell then return end
    local target = GetLastSpellTarget(spell)
    if not target then return end
    if not InRange(spell, target) then 
        chat('Stop '.. spell .. ' ' .. target)
        oexecute("SpellStopCasting()") 
    end
end
function HealRotation()
    CheckCast()
    local members = GetHealingMembers(UNITS)
    if #members < 1 then return false end
    local u = members[1]
    local h = UnitHealth100(u)
    local l = UnitLostHP(u)

    if HasBuff("Стремительность предков") then
        DoSpell("Великая волна исцеления", u)
        chat("Мгновенно Великая волна исцеления " .. UnitName(u))
        return 
    end

    if TryInterrupt(TARGETS, h > 40) then return end

    local myHP, myMana =  UnitHealth100("player"), UnitMana100("player")
    if InCombatLockdown() then
        if PlayerInPlace() and not HasTotem(3) then
            if myMana < 50 and IsReadySpell("Тотем прилива маны") then
                 DoSpell("Тотем прилива маны") 
                 chat("Тотем прилива маны") 
                 return
            end
            if h < 40 and IsReadySpell("Тотем целительного прилива") then
                DoSpell("Тотем целительного прилива")
                chat("Тотем целительного прилива")
                return
            end
            if h < 70 and IsReadySpell("Тотем исцеляющего потока") then
                DoSpell("Тотем исцеляющего потока")
                chat("Тотем исцеляющего потока")
                return
            end
        end
        if h < 60 and DoSpell("Благосклонность предков") then return true end
        if h < 60 and DoSpell("Перерождение") then return true end
        if myHP < 50 and DoSpell("Каменная форма") then return true end
        if myHP < 40 and UseEquippedItem("Эмблема жестокости бездушного гладиатора") then return true end
    end

    if IsArena() and not InCombatLockdown() and not HasBuff("Водный щит") and not unitWithShield and DoSpell("Щит земли", "player") then return end

    if GetInventoryItemID("player", 16) and not sContains(GetTemporaryEnchant(16), "Жизнь Земли") and DoSpell("Оружие жизни земли") then return end

    local unitWithShield, threatLowHPUnit, threatLowHP = nil, nil, 1000
    for i=1,#members do 
        local u = members[i]
        local h = UnitHealth100(u)
        if (select(4, HasMyBuff("Щит земли", 5, u)) or 0) > 1  then unitWithShield = u end
        if (UnitThreatAlert(u) == 3) and (h < threatLowHP) and (not IsOneUnit(u, "player")) then
           threatLowHPUnit = u  
           threatLowHP = h 
        end
    end

    if myHP < 40 then
       threatLowHP = myHP
       threatLowHPUnit = "player"  
    end

    if  threatLowHPUnit then
        local force = false
        if unitWithShield and not IsOneUnit(unitWithShield, threatLowHPUnit) and UnitThreatAlert(unitWithShield) < 3 and (threatLowHP < 70) then
            force = true
            unitWithShield = nil
        end
        
        if not unitWithShield and (force or IsSpellNotUsed("Щит земли", 2)) and DoSpell("Щит земли", threatLowHPUnit) then 
            return 
        end
        
        if unitWithShield and (force or IsSpellNotUsed("Щит земли", 5)) and not IsOneUnit(unitWithShield, threatLowHPUnit) and threatLowHP < 65 and DoSpell("Щит земли", threatLowHPUnit) then 
            return
        end
    end

    if h < (IsCtr() and 100 or 98) and DoSpell("Быстрина", u) then return end
    if h < (IsCtr() and 100 or 98) and DoSpell("Высвободить чары стихий", u) then return end

    local GreatHealingWaveHeal = GetSpellAmount("Великая волна исцеления", 12000) * 1.2
    local HealingWaveHeal = GetSpellAmount("Волна исцеления", 8000) * 1.2

    if UnitAffectingCombat(u) and UnitIsPlayer(u) and (h < 20 or (l > GreatHealingWaveHeal * 1.5)) and HasSpell("Стремительность предков") and DoSpell("Стремительность предков") then chat("Мгновенка!") return end

    if TryDispelControl(members) then return end

    if IsAttack() and h > 60 then
        if not IsInteractUnit("target") then CheckTarget() end
        if not IsNotAttack("target") and CanAttack("target") then 
            if not HasMyDebuff("Огненный шок", 1,"target") and  DoSpell("Огненный шок") then return end
            if (PlayerInPlace() or HasBuff("Благосклонность предков", 1)) and HasMyDebuff("Огненный шок", 1.5,"target") and DoSpell("Выброс лавы") then return end
        end
        if IsSpellNotUsed("Развеивание магии", 2) and TrySteal("target") then return end
    end

    if PlayerInPlace() or HasBuff("Благосклонность предков", 1) then
                        
        if h < 20 and HasMyBuff("Приливные волны", 1.5, "player") then
            DoSpell("Исцеляющий всплеск", u)
            return 
        end

        if h > 40 and h < (IsCtr() and 100 or 90) and myMana > 40 and UnitIsPlayer(u) and (IsCtr() or HasBuff("Быстрина", 2.5, u)) then
            for i = 1, #members do
                local u2 = members[i]
                if UnitHealth100(u2) < (IsCtr() and 100 or 90) and UnitIsPlayer(u2) and not IsOneUnit(u, u2) and InDistance(u, u2, 12.5) then
                    local name = UnitName(u)
                    local name2 = UnitName(u2)
                    --chat("Цепное исцеление -> " .. name .. " -> " .. name2 )
                    DoSpell("Цепное исцеление", u)
                    return
                end
            end
        end

        if myMana > 40 and (l > GreatHealingWaveHeal) and HasMyBuff("Приливные волны", 2.5, "player") then
            DoSpell("Великая волна исцеления", u)
            return
        end 

        if (h < 50 or (l > HealingWaveHeal)) then
            DoSpell("Волна исцеления", u)
            return
        end 
  
    end

    if not (HasBuff("Водный щит") or HasBuff("Щит земли")) and DoSpell("Водный щит") then return end

    if (h > 60 or not PlayerInPlace()) and myMana > 50 and (CanInterrupt or IsPvP()) then
        if IsSpellNotUsed("Очищение духа", 10) and TryDispel(members) then return  end
        if IsSpellNotUsed("Развеивание магии", 2) and TrySteal(ITARGETS) then return  end
    end

    if not IsAttack() and h > 50 and IsPvP() then
        for i = 1, #ITARGETS do
            local t = ITARGETS[i]
            if CanControl(t) and UnitIsPlayer(t) and not HasDebuff("Ледяной шок", 0.1, t) and DoSpell("Ледяной шок", t) then return end
        end
    end
end

function TryHeal()

    if InCombatLockdown() and IsValidTarget("target") then
        local hp = UnitHealth100("player")
       
        if not (IsArena() or InDuel()) then
            if hp < 35 then UseHealPotion() end
        end
        if hp < 40 and UseEquippedItem("Эмблема жестокости бездушного гладиатора") then return true end
        if hp < 50 and DoSpell("Каменная форма") then return true end
    end

    local members = GetHealingMembers(IUNITS)
    if #members < 1 then return false end
    local u = members[1]
    local h = UnitHealth100(u)
    local l = UnitLostHP(u)
    if h < 70 and not HasTotem(3) and DoSpell("Тотем исцеляющего потока") then return true end
    if h < 60 and DoSpell("Наставления предков") then return true end
    if h < 40 and not HasTotem(3) and DoSpell("Тотем целительного прилива") then return true end
    if  PlayerInPlace() or HasBuff("Благосклонность предков", 1) then
        if h < 20 and IsPlayerCasting() and not IsSpellInUse("Исцеляющий всплеск") then oexecute("SpellStopCasting()") end
        if h < (IsCtr() and 99 or 25) then DoSpell("Исцеляющий всплеск", u)  return true end
        if h < 20 then return true end 
        TryDispel(u)
    end
    if IsSpellInUse("Исцеляющий всплеск") then return true end
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

    if IsShift() and IsReadySpell("Землетрясение") then
        DoSpell("Землетрясение", "target")
        return
    end

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
        if DoSpell("Высвободить чары стихий", "target") then return end
    end

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
