-- Warrior Rotation Helper by Timofeev Alexey
-- Команда на установку флага и чардж к нему
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
    if not IsReadySpell("Охрана")  then 
        chat("!ready def")
        return true 
    end
    if not InRange("Охрана", target) then 
        chat("!range def")
        return true 
    end
    return false 
  end
)

function DefCommand()
    if IsAlt() then
        JumpCommand()
        return
    end
    local target = "target"
    if not IsInteractUnit(target) then
        target = GetTeammate()
        if not target then 
            chat('!teammate def')
            return 
        end
        if not IsInteractUnit(target) then
            chat('!interact def')
            return
        end
    end
    DoCommand("def", target)
end 
------------------------------------------------------------------------------------------------------------------
 SetCommand("jump", 
  function(flag)

    if IsReadySpell(flag) then
        chat("Jump "..flag.."!")
        DoSpell(flag, true)
        return
    end

    local name = UnitName("target")
    if name ~= flag then
        chat("Jump выбор знамени!")
        omacro("/target "..flag)
        return
    end
 
    if IsReadySpell("Охрана") then
        chat("Jump Охрана!")
        DoSpell("Охрана", "target")
        return
    else
        chat("Jump возврат цели!")
        oexecute('TargetLastTarget()') 
        TimerStart('JumpSucces')   
    end

  end, 
  function(flag) 
    if TimerLess('JumpSucces', 1) then 
        chat("JumpSucces!")
        return true 
    end

    if TimerMore('Jump', 3) then
        if IsReadySpell("Охрана") and IsReadySpell(flag) then
            TimerStart('Jump')
            chat("JumpStart "..target.."!")
            return false
        end
        chat("JumpFail!")
        return true
    end

    return false 
  end
)

function JumpCommand()
    local flag = IsReadySpell("Издевательское знамя")  and  "Издевательское знамя" or "Деморализующее знамя"
    DoCommand("jump", flag)
end
------------------------------------------------------------------------------------------------------------------
 SetCommand("unroot", 
  function(flag, target)

    if IsReadySpell(flag) then
        chat("UnRoot "..flag.."!")
        DoSpell(flag, target)
        return
    end

    local name = UnitName("target")
    if name ~= flag then
        chat("UnRoot выбор знамени!")
        omacro("/target "..flag)
        return
    end
 
    if IsReadySpell("Охрана") then
        chat("UnRoot Охрана!")
        DoSpell("Охрана", "target")
        return
    else
        chat("UnRoot возврат цели!")
        oexecute('TargetLastTarget()') 
        TimerStart('UnRootSucces')   
    end

  end, 
  function(flag, target) 
    if TimerLess('UnRootSucces', 1) then 
        chat("UnRootSucces!")
        return true 
    end

    if TimerMore('UnRoot', 3) then
        if IsReadySpell("Охрана") and InRange("Охрана", target) and IsReadySpell(flag) then
            local d = CheckDistance("player", target) or 100
            if d < 22 then
                TimerStart('UnRoot')
                chat("UnRootStart "..target.."!")
                return false
            end
        end
        chat("UnRootFail!")
        return true
    end

    return false 
  end
)

function UnRootCommand()
    local flag = IsReadySpell("Издевательское знамя")  and  "Издевательское знамя" or "Деморализующее знамя"
    local target = "target"
    if IsAlt() then 
        target = "focus" 
    end
    DoCommand("unroot", flag, target)
end
