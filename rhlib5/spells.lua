-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------
-- Время сетевой задержки 
LagTime = 0
local lastUpdate = 0
local function UpdateLagTime()
    if GetTime() - lastUpdate < 30 then return end
    lastUpdate = GetTime() 
    LagTime = tonumber(((select(3,GetNetStats()) + select(4,GetNetStats())) / 1000))

end
AttachUpdate(UpdateLagTime)
local sendTime = 0
local function CastLagTime(event, ...)
    local unit, spell = select(1,...)
    if spell and unit == "player" then
        if event == "UNIT_SPELLCAST_SENT" then
            sendTime = GetTime()
        end
        if event == "UNIT_SPELLCAST_START" then
            if not sendTime then return end
            LagTime = (GetTime() - sendTime) / 2
        end
    end
end
AttachEvent('UNIT_SPELLCAST_START', CastLagTime)
AttachEvent('UNIT_SPELLCAST_SENT', CastLagTime)

------------------------------------------------------------------------------------------------------------------
function GetKickInfo(target) 
    if target == nil then target = "target" end 
    if not CanAttack(target) then return end
    local channel = false
    -- name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("unit")
    local spell, _, _, _, startTime, endTime, _, _, notinterrupt = UnitCastingInfo(target)
    if not spell then 
        --name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("unit")
        spell, _, _, _, startTime, endTime, _, nointerrupt = UnitChannelInfo(target)
        channel = true
    end
    if not spell then return nil end
    if IsPvP() and not tContains(InterruptRedList, spell) then return end
    local s = startTime / 1000 -- время начала каста
    local c = GetTime() -- текущее время
    local e = endTime / 1000 -- время конца каста 
    local t = e - c -- осталось до конца каста
    local l = e - s -- время каста
    local d = 0.2 + 0.3 * random() -- время задержки интерапта, чтоб не палить контору.
    if d > l * 0.8 then d = l - 0.3 end -- если каст меньше задержки, уменьшаем задержку
    if c - s < d then return end -- если пока рано сбивать, выходим (задержка)
    if t < (channel and 0.5 or 0.2) then  return  end -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик
    local name = UnitName(target)
    name = name or target
    local m = " -> " .. spell .. " ("..name..")"
    return spell, t, channel, notinterrupt, m
end

------------------------------------------------------------------------------------------------------------------
--IsPlayerCasting(1)  кастим, но меньше секунды
function IsPlayerCasting(less)
    local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo("player")
    if spell == nil then
        spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo("player")
    end
    if not spell or not endTime then return nil end
    local res = ((endTime/1000 - GetTime()) < LagTime)
    if res then return nil end
    return less and (GetTime() - startTime / 1000 < less) or true
end

------------------------------------------------------------------------------------------------------------------
local spellToIdList = {}
function GetSpellId(name, rank)
    spellGUID = name
    if rank then
        spellGUID = name .. rank
    end
    local result = spellToIdList[spellGUID]
    if nil == result then
        local link = GetSpellLink(name,rank)
        if not link then 
            result = 0 
        else
            result = 0 + link:match("spell:%d+"):match("%d+")
        end
        spellToIdList[spellGUID] = result
    end
    return result
end

------------------------------------------------------------------------------------------------------------------
function HasSpell(spellName)
    if GetSpellInfo(spellName) then return true end
    return false
end
------------------------------------------------------------------------------------------------------------------
local gcd_starttime, gcd_duration
local function updateGCD(_, start, dur, enable) 
    if start > 0 and enable > 0 then 
        if dur and dur > 0 and dur <= 1.5 then
            gcd_starttime = start
            gcd_duration = dur
        end
    end 
end
hooksecurefunc("CooldownFrame_SetTimer", updateGCD)

function GetGCDLeft()
    if not gcd_starttime then return 0 end
    local t = GetTime() - gcd_starttime
    if  t  > gcd_duration then
        return 0
    end
    return gcd_duration - t
end


function InGCD()
    return GetGCDLeft() > LagTime
end

local abs = math.abs
function IsReady(left, checkGCD)
    if checkGCD == nil then checkGCD = false end
    if not checkGCD then
        local gcdLeft = GetGCDLeft()
        if (abs(left - gcdLeft) < 0.01) then return true end    
    end
    if left > LagTime then return false end
    return true
end
------------------------------------------------------------------------------------------------------------------
function InInteractRange(unit)
    -- need test and review
    if (unit == nil) then unit = "target" end
    if not IsInteractUnit(unit) then return false end
    return IsItemInRange(34471, unit) == 1
end
------------------------------------------------------------------------------------------------------------------
function InMelee(target)
    if (target == nil) then target = "target" end
    return IsItemInRange(37727, target) == 1
end

------------------------------------------------------------------------------------------------------------------

function IsReadySpell(name, checkGCD)
    local usable, nomana = IsUsableSpell(name)
    if not usable then return false end
    local left = GetSpellCooldownLeft(name)
    return IsSpellNotUsed(name, 0.5) and IsReady(left, checkGCD)
end

------------------------------------------------------------------------------------------------------------------
function GetSpellCooldownLeft(name)
    local start, duration, enabled = GetSpellCooldown(name);
    if enabled ~= 1 then return 1 end
    if not start then return 0 end
    if start == 0 then return 0 end
    return start + duration - GetTime()
end

------------------------------------------------------------------------------------------------------------------
function UseMount(mountName)
    if IsPlayerCasting() then return false end
    if InGCD() then return false end
    if IsMounted()then return false end
    --[[if Debug then
        print(mountName)
    end]]
    omacro("/use "..mountName)
    return true
end
------------------------------------------------------------------------------------------------------------------
function InRange(spell, target) 
    if target == nil then target = "target" end
    if spell and IsSpellInRange(spell,target) == 0 then return false end 
    return true    
end

------------------------------------------------------------------------------------------------------------------
local InCast = {}
local function getCastInfo(spell)
	if not InCast[spell] then
		InCast[spell] = {}
	end
	return InCast[spell]
end
local function UpdateIsCast(event, ...)
    local unit, spell, rank, target = select(1,...)
    if spell and unit == "player" then
        local castInfo = getCastInfo(spell)
        if event == "UNIT_SPELLCAST_SUCCEEDED"
            and castInfo.StartTime and castInfo.StartTime > 0 then
            castInfo.LastCastTime = castInfo.StartTime 
        end
        if event == "UNIT_SPELLCAST_SENT" then
            castInfo.StartTime = GetTime()
            castInfo.TargetName = target
        else
            castInfo.StartTime = 0
        end
    end
end
AttachEvent('UNIT_SPELLCAST_SENT', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_SUCCEEDED', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_FAILED', UpdateIsCast)

function GetLastSpellTarget(spell)
    local castInfo = getCastInfo(spell)
    return (castInfo.Target and castInfo.TargetGUID and UnitExists(castInfo.Target) and UnitGUID(castInfo.Target) == castInfo.TargetGUID) and castInfo.Target or nil
end

function GetSpellLastTime(spell)
    local castInfo = getCastInfo(spell)
    return castInfo.LastCastTime or 0
end

function IsSpellNotUsed(spell, t)
    local last  = GetSpellLastTime(spell)
    return GetTime() - last >= t
end


function IsSpellInUse(spellName)
    -- нет спела -- Используется сейчас
    if not spellName or IsCurrentSpell(spellName) then return true end
    if not InCast[spellName] or not InCast[spellName].StartTime then return false end
    local start = InCast[spellName].StartTime
    if (GetTime() - start <= LagTime) then return true end
    if IsReadySpell(spellName) then InCast[spellName].StartTime = 0 end
    return false
end
------------------------------------------------------------------------------------------------------------------
local function checkTargetInErrList(target, list)
    if not target then target = "target" end
    if target == "player" then return true end
    if not UnitExists(target) then return false end
    local t = list[UnitGUID(target)]
    if t and GetTime() - t < 1.2 then return false end
    return true;
end

local notVisible = {}
--~ Цель в поле зрения.
function IsVisible(target)
    if olos and olos(target) == 1 then return false end
    return checkTargetInErrList(target, notVisible)
end

local notInView = {}
-- передо мной
function IsInView(target)
    return checkTargetInErrList(target, notInView)
end

local notBehind = {}
-- за спиной цели
function IsBehind(target)
    return checkTargetInErrList(target, notBehind)
end

local lastFailedSpellTime = {}
local lastFailedSpellError = {}

function GetLastSpellError(spellName, t)
    if not spellName then return nil end
    local lastTime = lastFailedSpellTime[spellName]
    if t and lastTime and (GetTime() - lastTime > t) then return nil end
    return lastFailedSpellError[spellName]
end

local function UpdateTargetPosition(event, ...)

    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if sourceGUID == UnitGUID("player") and sContains(type, "SPELL_CAST_FAILED") and spellId and spellName  then
        local err = amount
        if err then
            lastFailedSpellTime[spellName] = GetTime()
            lastFailedSpellError[spellName] = err
        end
        local cast = getCastInfo(spellName)
        local guid = cast.TargetGUID or nil
        if err and guid then
            if err == "Цель вне поля зрения." then
                notVisible[guid] = GetTime()
            end
            if err == "Цель должна быть перед вами." then
                notInView[guid] = GetTime() 
            end
            if err == "Вы должны находиться позади цели." then 
                notBehind[guid] = GetTime() 
            end
        end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateTargetPosition)
------------------------------------------------------------------------------------------------------------------
SpellsAmounts  = SpellsAmounts or {};
SpellsAmount = SpellsAmount or {};
local function UpdateSpellsAmounts(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if amount and sourceGUID == UnitGUID("player") and sContains(type, "SPELL_HEAL") and spellId and spellName  then
        local amounts = SpellsAmounts[spellName]
        if nil == amounts then amounts = {} end
        tinsert(amounts, amount)
        if #amounts > 25 then tremove(amounts, 1) end
        SpellsAmounts[spellName] = amounts
        local average = 0
        for i = 1, #amounts do
            average = average + amounts[i]
        end
        SpellsAmount[spellName] = floor(average / #amounts)
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateSpellsAmounts)

function GetSpellAmount(spellName, expected)
    local amount = SpellsAmount[spellName]
    return nil == amount and expected or amount
end

------------------------------------------------------------------------------------------------------------------
local fix_oclick = false
local badSpellTarget = {}
function UseSpell(spellName, target)
    if not fix_oclick then
        oinfo("player") -- fix oclick
        fix_oclick = true        
    end
    local dump = false --spellName == "Целительный ливень"
    
    -- Не пытаемся что либо прожимать во время каста
    if IsPlayerCasting() then 
        if dump then print("Кастим, не можем прожать", spellName) end
        return false 
    end
    local manual = target == false;
    local auto = target == true;
    if manual or auto then target = nil end
    if target == nil then target = IsHarmfulSpell(spellName) and "target" or "player" end
    if dump then print("Пытаемся прожать", spellName, "на", target) end
    if SpellIsTargeting() then
        -- Не мешаем выбрать область для спела (нажат вручную)
        if dump then print("Ждем выбор цели, не можем прожать", spellName) end
        if TimerStarted('Manual') and TimerMore('Manual', 3) then oexecute('SpellStopTargeting()') end
        return false
    else
        TimerReset('Manual')
    end
    -- Проверяем на наличе спела в спелбуке
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    if not name then
        if Debug then error("Спел [".. spellName .. "] не найден!") end
        return false;
    end
    -- проверяем, что этот спел не используется сейчас
    if IsSpellInUse(spellName) then
        if dump then print("Уже прожали, не можем больше прожать", spellName) end
        return false 
    end

    if UnitExists(target) and badSpellTarget[spellName] then 
        local badTargetTime = badSpellTarget[spellName][UnitGUID(target)]
        if badTargetTime and (GetTime() - badTargetTime < 10) then 
            if dump then 
                print(target, "- Цель не подходящая, не можем прожать", spellName) 
            end
            return false 
        end
    end

    -- проверяем что цель в зоне досягаемости
    if not InRange(spellName, target) then 
        if dump then print(target," - Цель вне зоны досягаемости, не можем прожать", spellName) end
        return false
    end  

    -- Проверяем что все готово
    if not IsReadySpell(spellName) then
        if dump then print("Не готово, не можем прожать", spellName) end
        return false
    end

    if not IsReadySpell(spellName, true) then
        if dump then print("ГКД, не можем прожать", spellName) end
        return true -- дальше не идем
    end
    -- собираем команду
    local cast = "/cast "
    -- с учетом цели
    if target ~= nil then cast = cast .."[@".. target .."] "  end
    -- проверяем, хватает ли нам маны
    if cost and cost > 0 and (UnitPower("player", powerType) or 0) <= cost then 
        if dump then print("Не достаточно маны, не можем прожать", spellName) end
        return false
    end
    if UnitExists(target) then 
        -- данные о кастах
        local castInfo = getCastInfo(spellName)
        castInfo.Target = target
        castInfo.TargetName = UnitName(target)
        castInfo.TargetGUID = UnitGUID(target)
    end
    -- пробуем скастовать
    --if Debug then print("Жмем", cast .. "!" .. spellName) end
    omacro(cast .. "!" .. spellName)
    -- если нужно выбрать область - кидаем на текущий mouseover
    if SpellIsTargeting() then 
        if manual then
            TimerStart('Manual')
        else
            if auto then
                 local look = IsMouselooking()
                if look then
                    oexecute('TurnOrActionStop()')
                end
                oexecute('CameraOrSelectOrMoveStart()')
                oexecute('CameraOrSelectOrMoveStop()')
                if look then
                    oexecute('TurnOrActionStart()')
                end
                oexecute('SpellStopTargeting()')
            else
                oclick(target)
                oexecute('SpellStopTargeting()')    
            end
            
        end
    end

    if dump then print("Спел вроде прожался", spellName) end
    local castInfo = getCastInfo(spellName)
        -- проверка на успешное начало кд
        if castInfo.StartTime and (GetTime() - castInfo.StartTime < 0.01) then
            if UnitExists(target) then
                -- проверяем цель на соответствие реальной
                if castInfo.TargetName and castInfo.TargetName ~= "" and castInfo.TargetName ~= UnitName(target) then 
                    if dump then print("Цели не совпали", spellName) end
                    oexecute("SpellStopCasting()")
                    --chat("bad target", target, spellName)
                    if nil == badSpellTarget[spellName] then
                        badSpellTarget[spellName] = {}
                    end
                    local badTargets = badSpellTarget[spellName]
                    badTargets[UnitGUID(target)] = GetTime()
                    castInfo.Target = nil
                    castInfo.TargetName = nil
                    castInfo.TargetGUID = nil
                end
            end
        end
    if Debug then 
        local name = UnitName(target)
        name = name or target
        chat(spellName .. " -> ".. name, 0.4,0.4,0.4) 
    end
    return true
end