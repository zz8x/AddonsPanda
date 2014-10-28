-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- список команд
local Commands = {}
------------------------------------------------------------------------------------------------------------------
-- метод для задания команды, которая имеет приоритет на ротацией
-- SetCommand(string 'произвольное имя', function(...) команда, bool function(...) проверка, что все выполнилось, или выполнение невозможно)
function SetCommand(name, applyFunc, checkFunc)
    Commands[name] = {Last = 0, Timer = 0, Apply = applyFunc, Check = checkFunc, Params == null}
end

------------------------------------------------------------------------------------------------------------------
-- Используется в макросах
-- /run DoCommand('my_command', 'focus')
function DoCommand(cmd, ...)
    if not Commands[cmd] then 
        print("DoCommand: Ошибка! Нет такой комманды ".. cmd)
        return
    end 
    local d = 1.85
    local t = GetTime() + d
    local spell, _, _, _, _, endTime  = UnitCastingInfo("player")
    if not spell then spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo("player") end
    if spell and endTime then 
        t = endTime/1000 + d
        if Commands[cmd].Timer and Commands[cmd].Timer == t then 
            oexecute("SpellStopCasting()")
            t = GetTime() + d
        end
    end
    Commands[cmd].Timer = t
    Commands[cmd].Params = { ... }
end

------------------------------------------------------------------------------------------------------------------
-- навешиваем обработчик с максимальным приоритетом на событие OnUpdate, для обработки вызванных комманд
function UpdateCommands()
    if IsPlayerCasting() then return false end
    local ret = false
    for cmd,_ in pairs(Commands) do 
        if not ret then
            if (Commands[cmd].Timer  - GetTime() > 0) then 
                ret = true
                if Commands[cmd].Check(unpack(Commands[cmd].Params)) then 
                   Commands[cmd].Timer = 0
                else
                   if GetTime() - Commands[cmd].Last > 0.2 and Commands[cmd].Apply(unpack(Commands[cmd].Params)) then
                        Commands[cmd].Last = GetTime()
                   end
                end
            else
                Commands[cmd].Timer = 0
            end 
        end
    end
    return ret
end
------------------------------------------------------------------------------------------------------------------
SetCommand("freedom", 
    function() 
        TryFreedom() 
    end, 
    function() 
        if IsPlayerCasting() then return true end
        if not IsReadyFreedom(Spell) then return true end
        return false 
    end
)
------------------------------------------------------------------------------------------------------------------
-- // /run if IsReadySpell("s") and СanMagicAttack("target") then DoCommand("spell", "s", "target") end
SetCommand("spell", 
    function(spell, target) 
        if DoSpell(spell, target) then
            echo(spell.."!",1)
        end
    end, 
    function(spell, target) 
        if not HasSpell(spell) then
            chat(spell .. " - нет спела!")
            return true
        end
        if not InRange(spell, target) then
            chat(spell .. " - неверная дистанция!")
            return true
        end
        if not IsSpellNotUsed(spell, 1)  then
            chat(spell .. " - успешно сработало!")
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
function HelpCommand(cmd, param)
    local target = "player"
    if IsAlt() then 
        target = GetTeammate() 
        if not target then return end
    end
    if not CanHeal(target) then chat('!help ' .. target) return end
    if nil ~= param then
        DoCommand(cmd, param, target)
    else
        DoCommand(cmd, target)
    end
end
------------------------------------------------------------------------------------------------------------------
function AttackCommand(cmd, param)
    local target = "target"
    if IsAlt() then 
        target = "focus" 
    end
    if not CanAttack(target) then chat('!Attack ' .. target) return end
    if nil ~= param then 
        DoCommand(cmd, param, target)
    else
        DoCommand(cmd, target)
    end
end
------------------------------------------------------------------------------------------------------------------
function ControlCommand(cmd, spell)
    local target = "target"
    if IsAlt() then 
        target = "focus" 
    end
    if HasDebuff(spell, 0.1, target) then chat(spell..': OK!') return end
    local aura = InControl(target, 0.1)
    if aura then chat(spell..': уже в котроле '..aura) return end
    if not CanControl(target, spell) then chat(spell..': '..CanControlInfo) return end
    DoSpell("spell", spell, target)
end 
------------------------------------------------------------------------------------------------------------------