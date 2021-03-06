﻿-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local flyMounts = {
    "Небесный голем",
    "Драгоценная ониксовая пантера",
    "Ракета на обедненном кипарии",
    "Геосинхронный вращатель мира",
    "Непобедимый",
    "Песчаниковый дракон",
    --"Золотистый грифон",
}
local groundMounts = {
    "Небесный голем",
    --"Золотистый грифон",
    "Драгоценная ониксовая пантера",
    "Ракета на обедненном кипарии",
    "Геосинхронный вращатель мира",
    "Непобедимый",
    "Анжинерский чоппер",
    "Большой як для путешествий"
}
SetCommand("mount", 
    function() 
        --[[if not IsArena() then
            -- ускорение
            if IsAlt() and not PlayerInPlace() and UseSlot(6) then
                chat("Ускорители")
                TimerStart('Mount')
                return true
            end
            -- Парашют
            if GetFalingTime() > 1 and UseSlot(15) then
                chat("Парашют")
                TimerStart('Mount')
                return true
            end
            -- рыбная ловля
            if IsEquippedItemType("Удочка") and DoSpell("Рыбная ловля") then
                TimerStart('Mount')
                return true
            end
        end]]

        if InGCD() or IsPlayerCasting() then return end

        if IsFalling() and GetFalingTime() < 1 and DoSpell("Хождение по воде", "player") then 
            TimerStart('Mount')
            return true
        end

        if IsMounted() or CanExitVehicle()  then
            TimerStart('Mount')
            return true
        end

        if not HasBuff("Призрачный волк") and InCombatLockdown() or IsArena() or not PlayerInPlace() or not IsOutdoors() then
            DoSpell("Призрачный волк") 
            TimerStart('Mount')
            return true
        end

        --local mount = "Ракета на обедненном кипарии"
        --local mount = "Небесный голем" --"Драгоценная ониксовая пантера"
        local mount = (IsShift() or IsBattleground() or not IsFlyableArea()) and groundMounts[random(#groundMounts)] or flyMounts[random(#flyMounts)]
        ----"Непобедимый"--"Золотистый грифон"
        if IsAlt() then mount = "Тундровый мамонт путешественника" end --"Большой як для путешествий"
        if IsSwimming() then
            mount = "Подчиненный морской конек"
        end
        if UseMount(mount) then 
            TimerStart('Mount')
            return true
        end
    end, 
    function() 
        if TimerStarted('Mount') and TimerElapsed('Mount') > 0.01 then
            TimerReset('Mount')    
            return  true
        end

        return false 
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("hero", 
    function() 
        local heroSpell = HasSpell("Героизм") and "Героизм" or "Жажда крови"
        return DoSpell(heroSpell) 
    end, 
    function() 
        local heroSpell = HasSpell("Героизм") and "Героизм" or "Жажда крови"
        return not IsReadySpell(heroSpell) 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("frostshock", 
    function(target) 
        if DoSpell("Ледяной шок", target) then
            echo("Ледяной шок!", 1)
        end
    end, 
    function(target) 
        return not InCombatLockdown() or not CanMagicAttack(target) or HasDebuff("Ледяной шок", 0,1, target) or not IsSpellNotUsed("Ледяной шок", 1) 
    end
)
------------------------------------------------------------------------------------------------------------------
local druidForm = {"облик", "Древо Жизни"}
SetCommand("hex", 
    function(force, target) 
        local spell = "Сглаз"
        if force and HasSpell("Стремительность предков") then 
            DoSpell("Стремительность предков") 
        end
        
        if DoSpell(spell, target) then 
            echo(spell,1)
        end
    end, 
    function(force, target) 
        local spell = "Сглаз"

        if not CanControl(target) then 
            echo("Имунен к контролю!")
            return true 
        end
        if not IsSpellNotUsed(spell, 1)  then 
            echo("Успешно прожали "..spell.."!")
            return true 
        end

       if not UnitIsPlayer(target) then
            local creatureType = UnitCreatureType(target)
            if not (creatureType == "Гуманоид" or creatureType == "Животное") then 
                echo(creatureType .. ' - нельзя кинуть '..spell..'!')
                return true 
            end
        else
            if GetClass(target) == "DRUID" and HasBuff(druidForm, 0.1, target) then 
                echo('Друид в форме, имунен к превращениям')
                return true 
            end 
        end

        if not IsReadySpell(spell) then
            chat(spell .. " - не готово!")
            return true
        end

        local cast = UnitCastingInfo("player")
        if spell == cast then
            chat("Кастуем " .. spell)
            return true
        end

        return false
    end
)

-- [Сковать элементаля]
SetCommand("fix", 
    function(force, target) 
        local spell = "Сковать элементаля"
        if force and HasSpell("Стремительность предков") then 
            DoSpell("Стремительность предков") 
        end
        
        if DoSpell(spell, target) then 
            echo(spell,1)
        end
    end, 
    function(force, target) 
        local spell = "Сковать элементаля"

        if not IsSpellNotUsed(spell, 1)  then 
            echo("Успешно прожали "..spell.."!")
            return true 
        end

        local creatureType = UnitCreatureType(target)
        if creatureType ~= "Элементаль" then 
            echo(creatureType .. ' - нельзя кинуть '..spell..'!')
            return true 
        end

        if not IsReadySpell(spell) then
            chat(spell .. " - не готово!")
            return true
        end

        local cast = UnitCastingInfo("player")
        if spell == cast then
            chat("Кастуем " .. spell)
            return true
        end

        return false
    end
)


------------------------------------------------------------------------------------------------------------------
SetCommand("rain", 
    function() 
        if DoSpell("Целительный ливень", false) then
            echo("Целительный ливень!", 1)
        end
    end, 
    function() 
        return not IsReadySpell("Целительный ливень") or SpellIsTargeting() or IsSpellInUse("Целительный ливень")
    end
)
