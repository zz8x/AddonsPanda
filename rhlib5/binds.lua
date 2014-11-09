-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- l18n
BINDING_HEADER_RHLIB = "Rotation Helper Library"
BINDING_NAME_RHLIB_FACE = "Лицом к Цели"
BINDING_NAME_RHLIB_OFF = "Выкл ротацию"
BINDING_NAME_RHLIB_DEBUG = "Вкл/Выкл режим отладки"
BINDING_NAME_RHLIB_RELOAD = "Перезагрузить интерфейс"
BINDING_NAME_RHLIB_FARM = "Вкл/Выкл режим фарма"
------------------------------------------------------------------------------------------------------------------
-- Условие для включения ротации
function TryAttack()
    if Paused then return end
    TimerStart('Attack')
end
function IsAttack()
    if IsMouse(4) then
        TimerStart('Attack')
    end

    return TimerLess('Attack', 0.5)
end

------------------------------------------------------------------------------------------------------------------
if Paused == nil then Paused = false end
-- Отключаем авторотацию, при повторном нажатии останавливаем каст (если есть)
function AutoRotationOff()
    if IsPlayerCasting() and Paused then oexecute("SpellStopCasting()") end
    Paused = true
    TimerReset('Attack')
    oexecute("StopAttack()")
    oexecute("PetFollow()")
    echo("Авто ротация: OFF",true)
end

------------------------------------------------------------------------------------------------------------------
function FaceToTarget(force)
    if not force and (IsMouselooking() or not PlayerInPlace()) then return end
    if TimerMore("FaceToTarget", 0.2) and IsValidTarget("target") and (force or not PlayerFacingTarget("target")) then
        TimerStart("FaceToTarget")
        oface("target")
    end
end

local function updateFaceTotTarget(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
      
    if type:match("SPELL_CAST_FAILED") and sourceGUID == UnitGUID("player") 
        and (amount == "Цель должна быть перед вами." or amount == "Цель должна быть перед вами.") then
        FaceToTarget()
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateFaceTotTarget)

------------------------------------------------------------------------------------------------------------------
if Debug == nil then Debug = false end

local debugFrame = CreateFrame('Frame')
debugFrame:ClearAllPoints()
debugFrame:SetHeight(15)
debugFrame:SetWidth(800)
debugFrame.text = debugFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
debugFrame.text:SetAllPoints()
debugFrame:SetPoint('TOPLEFT', 2, 0)
debugFrame:SetScale(0.8);
debugFrame:SetAlpha(1)
local updateDebugStatsTime = 0
local function updateDebugStats()
    if not Debug then 
        if debugFrame:IsVisible() then debugFrame:Hide() end
        return 
    end
    if TimerLess('DebugFrame', 0.5) then return end
    TimerStart('DebugFrame')
    UpdateAddOnMemoryUsage()
    UpdateAddOnCPUUsage()
    local mem  = GetAddOnMemoryUsage("rhlib3")
    local fps = GetFramerate();
    local speed = GetUnitSpeed("Player") / 7 * 100
    debugFrame.text:SetText(format('MEM: %.1fKB, LAG: %ims, FPS: %i, SPD: %d%%', mem, LagTime * 1000, fps, speed))
    if not debugFrame:IsVisible() then debugFrame:Show() end
end

AttachUpdate(updateDebugStats) 

function DebugToggle()
    Debug = not Debug
    if Debug then
        debugFrame:Show()
        SetCVar("scriptErrors", 1)
        --UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE");
        SetCVar("Sound_EnableErrorSpeech", "1");
        echo("Режим отладки: ON",true)
    else
        debugFrame:Hide()
        SetCVar("scriptErrors", 0)
        --UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE");
        SetCVar("Sound_EnableErrorSpeech", "0");
        echo("Режим отладки: OFF",true)
    end 
end
------------------------------------------------------------------------------------------------------------------
if Farm == nil then Farm = false end
function FarmToggle()
    Farm = not Farm
    if Farm then
        echo("Режим фарма: ON",true)
    else
        echo("Режим фарма: OFF",true)
    end 
end


function IsFarm()
    return Farm  and not (IsMouselooking() or not PlayerInPlace())
end

------------------------------------------------------------------------------------------------------------------
-- Вызывает функцию Idle если таковая имеется, с заданным рекомендованным интервалом UpdateInterval, 
-- при включенной Авто-ротации
local iTargets = {"target", "focus", "mouseover"}
TARGETS = iTargets
ITARGETS = iTargets
UNITS = {"player"}
IUNITS = UNITS -- Important Units
local function getUnitWeight(u)
    local w = 0
    if IsFriend(u) then w = 2 end
    if IsOneUnit(u, "player") then w = 3 end
    return w
end
local unitWeights = {}
local friendTargets = {}
local function compareUnits(u1,u2) return unitWeights[u1] < unitWeights[u2] end
local function getTargetWeight(t)
    local w = friendTargets[UnitGUID(t)] or 0
    if InMelee(t) then w = 3 end
    if IsOneUnit("focus", t) then w = 3.1 end
    if IsOneUnit("target", t) then w = 3.2 end
    if IsOneUnit("mouseover", t) then w = 3.3 end
    w = w + 3 * (1 - UnitHealth100(t) / 100) 
    return w
end
local targetWeights = {}
local function compareTargets(t1,t2) return targetWeights[t1] < targetWeights[t2] end

FastUpdate = false
local looted = false
local waterWalkingBuffs = {"Хождение по воде", "Льдистый путь"}
function UpdateIdle(elapsed)
    
    if nil == oexecute then 
        echo("Требуется магичеcкое действие!!!", true) 
        return 
    end
    if IsBattleground() and UnitIsDead("player") and not UnitIsGhost("player") then oexecute("RepopMe()") end

    if UpdateCommands() then return end
    
    if Paused or UnitIsDeadOrGhost("player") then return end

    if IsFarm() then
        if CanAttack("target") then looted = false end
        
        if not looted then
            if not UnitExists("target") and TimerLess('CombatTarget', 2) then
                oexecute('TargetLastTarget()')
            end 

            if UnitExists("target") and not UnitIsPlayer("target") and UnitIsDead("target") then
                TemporaryAutoLoot(2)
                oexecute('InteractUnit("target")')
                looted = true
            end    
        end

        if LootFrame:IsVisible() then CloseLoot()  end
    else
        if not IsAttack() and LootFrame:IsVisible() then return end
    end

    if IsMouse(3) and UnitExists("mouseover") and not IsOneUnit("target", "mouseover") then 
        oexecute('FocusUnit("mouseover")')
    end

    if GetFalingTime() > 1 then
        local buff =  HasBuff(waterWalkingBuffs)
        if buff then oexecute('CancelUnitBuff("player", "'..buff..'")') end
    end

    if not FastUpdate then    
        if IsPlayerCasting() then 
            FaceToTarget()
        end
        -- Update units
        UNITS = GetUnits()
        wipe(unitWeights)
        wipe(friendTargets)
        for i=1,#UNITS do
            local u = UNITS[i]
            unitWeights[u] = getUnitWeight(u)

            local guid = UnitGUID(u .. "-target")
            if guid then
                local w = friendTargets[guid] or 1
                if w < 2 and IsFriend(u) then w = 2 end
                friendTargets[guid] = w
            end
        end
        sort(UNITS, compareUnits)
        
        -- Update targets
        TARGETS = GetTargets()
        wipe(targetWeights)
        for i=1,#TARGETS do
            local t = TARGETS[i]
            targetWeights[t] = getTargetWeight(t)
        end
        sort(TARGETS, compareTargets)
        wipe(IUNITS)
        for i = 0, #UNITS do
            local u = UNITS[i]
        	if IsArena() or IsFriend(u) then 
    			tinsert(IUNITS, u)
    		end
    	end
        ITARGETS = IsArena() and iTargets or TARGETS
    end

    if Idle then Idle() end
end
------------------------------------------------------------------------------------------------------------------
local function UpdateMacroAlertHider()
    if StaticPopup1Button2:IsVisible() == 1 and StaticPopup1Button2:IsEnabled() == 1 and StaticPopup1Button2:GetText() == "Пропустить" then
       chat(StaticPopup1.text:GetText())
       StaticPopup1Button2:Click()
    end
end
AttachUpdate(UpdateMacroAlertHider)
------------------------------------------------------------------------------------------------------------------
function GetFalingTime()
    if IsFalling() then
        if not TimerStarted("Falling") then TimerStart("Falling") end
    else
        if TimerStarted("Falling") then TimerReset("Falling") end
    end
    return TimerStarted("Falling") and TimerElapsed("Falling") or 0
end
------------------------------------------------------------------------------------------------------------------
-- Запоминаем вредоносные спелы которые нужно кастить (нужно для сбивания кастов, например тотемом заземления)
if HarmfulCastingSpell == nil then HarmfulCastingSpell = {} end
function IsHarmfulCast(spellName)
    return HarmfulCastingSpell[spellName]
end

local function UpdateHarmfulSpell(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if type:match("SPELL_DAMAGE") and spellName and amount > 0 then
        local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellId) 
        if castTime and castTime > 0 then HarmfulCastingSpell[name] = true end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateHarmfulSpell)
-------------------------------------------------------------------------------------------------------------
function UpdateAutoFreedom(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if sourceGUID == UnitGUID("player") and amount and sContains(amount, "Действие невозможно")  then
        chat(amount)
        TimerStart('Control')
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateAutoFreedom)
------------------------------------------------------------------------------------------------------------------