-- Warrior Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
SetCommand("stun", 
    function(target) 
        if DoSpell("Удар громовержца", target) then
            echo("Удар громовержца!", 1)
        end
    end, 
    function(target) 
        return not CanControl(target) or HasDebuff("Удар громовержца", 0,1, target) or not IsSpellNotUsed("Удар громовержца", 1) 
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("blink", 
    function() 
        if DoSpell("Героический прыжок", false) then
            echo("Героический прыжок!", 1)
        end
    end, 
    function() 
        return not IsReadySpell("Героический прыжок") or SpellIsTargeting() or IsSpellInUse("Героический прыжок")
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("disarm", 
    function(target) 
        if DoSpell("Обезоруживание", target) then
            echo("Обезоруживание!", 1)
        end
    end, 
    function(target) 
        return HasDebuff("Обезоруживание", 0,1, target) or not IsSpellNotUsed("Обезоруживание", 1) 
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("fear", 
    function(target) 
        if DoSpell("Устрашающий крик", target) then
            echo("Устрашающий крик!", 1)
        end
    end, 
    function(target) 
        return not CanControl(target) or HasDebuff("Устрашающий крик", 0,1, target) or not IsSpellNotUsed("Устрашающий крик", 1) 
    end
)
------------------------------------------------------------------------------------------------------------------
 SetCommand("def", 
  function(target) 
    DoSpell("Охрана", target)
  end, 
  function(target) 
    --if target == nil then target = "target" end
    if (not InGCD() and not IsSpellNotUsed("Охрана",1)) then return true end
    return false 
  end
)
------------------------------------------------------------------------------------------------------------------
 SetCommand("unroot", 
  function()
    if IsReadySpell("Издевательское знамя") and InRange("Охрана", target) and DoSpell("Издевательское знамя", target) then
        echo("Портал установлен", 1)
    end

    if RunMacroText("/target Издевательское знамя") then
        echo("Портал выбран", 1)
    end

    if DoSpell("Охрана") then
        echo("Телепортация прошла успешно", 1)
        RunMacroText("/targetlastenemy")
    end
  end, 
  function() 
    if target == nil then target = "target" end
    if (not InGCD() and not IsSpellNotUsed("Охрана",1)) then return true end
    return false 
  end
)