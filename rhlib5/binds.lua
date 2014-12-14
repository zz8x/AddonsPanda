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

function IsPaused() 
    if Paused then return true end
    for i = 1, 72 do
        local btn = _G["BT4Button"..i]
        if btn ~= nil then
            if btn:GetButtonState() == 'PUSHED' then 
                TimerStart('Paused')
                return true
            end
        else
            break
        end
    end
    local t = 0.3
    local spell, _, _, _, _, endTime  = UnitCastingInfo("player")
    if not spell then spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo("player") end
    if spell and endTime then 
        t = t + endTime/1000 - GetTime()
    end
    return TimerLess('Paused', t)
end
        

------------------------------------------------------------------------------------------------------------------
function FaceToTarget(force)
    if not force and (IsMouselooking() or not PlayerInPlace()) then return end
    if not force then force = not PlayerFacingTarget("target") end
    if force and TimerMore("FaceToTarget", 2) and IsValidTarget("target") then
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
        and (amount == "Цель должна быть перед вами." or amount == "Цель вне поля зрения.") then
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
    local speed = GetUnitSpeed("player") / 7 * 100
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
        chat("Автолут ON")
        omacro("/console autoLootDefault 1")
    else
        echo("Режим фарма: OFF",true)
        chat("Автолут OFF")
        omacro("/console autoLootDefault 0")
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
local waterWalkingBuffs = {"Хождение по воде", "Льдистый путь"}
FastUpdate = false
------------------------------------------------------------------------------------------------------------------
local AntiFarmCDTime = 10 * 60
local recedCD = true
local looted = 0
local farmPrefix = "A - Farm "
local farmVendorName = "Франк"
local farmVendor = farmPrefix .. "Vendor"
local farmEnter = farmPrefix .. "Enter"
local farmExit = farmPrefix .. "Exit"
farmCurrentIdx = nil
FarmPointMaxTime = 60
FarmAuto = false
local farmRotate = false
local needMana = false
local money = nil
local farmPriorityMobs = {"Разрыватель"}--,  "Опустошитель"}
local farmLastGuid = nil
------------------------------------------------------------------------------------------------------------------
function UpdateIdle(elapsed)
    
    if nil == oexecute then 
        echo("Требуется магичеcкое действие!!!", true) 
        return 
    end

    if StaticPopup1Button2:IsVisible() == 1 and StaticPopup1Button2:IsEnabled() == 1 and StaticPopup1Button2:GetText() == "Пропустить" then
       chat(StaticPopup1.text:GetText())
       StaticPopup1Button2:Click()
    end
   
    if Farm and UnitIsDeadOrGhost("player") then
        oexecute('AcceptResurrect()')
        farmCurrentIdx = 1
    end

    if UnitIsDead("player") and not UnitIsGhost("player") and (Farm or IsBattleground()) and CheckMapPoint(oinfo("player")) then 
        AddMapPoint('LastDeath')
        oexecute("RepopMe()")  
        TimerStart('Death')
        return             
    end

    if Farm and TimerMore('Death', 10) and UnitIsGhost("player") and CheckMapPoint(oinfo("player")) then 
        local p = GetMapPoint('LastDeath')
        if p then
            c = GetCurrentMapContinent()
            if c and c ~= -1 and p.c == c then
                if not CheckMapPoint(p.x, p.y, p.z) then 
                    chat('teleport to LastDeath')
                    TimerStart('Death')
                    TeleportTo(p) 
                end
                return
            end
            if FarmAuto then 
                chat('teleport to farmEnter')
                TimerStart('Death')
                TeleportToPoint(farmEnter) 
                return
            end
            chat('teleport to Corpse')
            TimerStart('Death')
            TeleportToCorpse()
        end
    end

    if UpdateCommands() then return end
    
    if UnitIsDeadOrGhost("player") or InExecQueue() or IsPaused() then return end

    if Farm then
        if GetFalingTime() > 5 then
            if farmLastGuid then
                omacro('/cleartarget')
                TimerReset('FarmToTarget')
                farmLastGuid = nil
            end
            TeleportToLastPos()
        end

        -- ждем LootFrame
        if TimerLess("Loot", 1.2) then 
            return 
        else
            if TimerStarted("Loot") then
                TimerReset("Loot")
                omacro('/cleartarget')
            end
        end 

        if LootFrame:IsVisible() then CloseLoot() end

        if farmLastGuid and TimerLess('FarmToTarget', 5) then
            if not InMapPoint('LastTarget') then
                --chat('телепорт к трупу')
                TeleportToPoint('LastTarget')
                return                    
            end
            if ResetMapPoint('LastTarget') or IsFalling() then 
                --chat('ResetMapPoint у трупа')
                return 
            end
            if not UnitExists("target") or UnitGUID("target") ~= farmLastGuid then
                --chat('Выбираем последний труп')
                oexecute('TargetLastTarget()')
            end
        else
            if not UnitExists("target") and TimerLess('CombatTarget', 2) and LastTarget then
                --chat('Выбираем труп')
                oexecute('TargetLastTarget()')
            end
        end
        if UnitExists("target") and not UnitIsPlayer("target") and UnitIsDead("target") then
            if FarmAuto and not InMelee("target") and IsVisible("target") then
                if TimerLess('FarmToTarget', 5) then 
                    --chat('farmLastGuid not InMelee')
                    return 
                end
                farmLastGuid = UnitGUID("target")
                TimerStart('FarmToTarget')
                --chat('start FarmToTarget')
                --print("Надо бы к трупу поближе")
                TeleportToTarget('target')
                return
            end
            TimerReset('FarmToTarget')
            farmLastGuid = nil
            --chat('Лутаем')
            oexecute('InteractUnit("target")')
            TimerStart("Loot")
            TimerReset("FarmPoint")
            return
        end

        if TimerStarted('FarmToTarget') then
            if TimerLess('FarmToTarget', 5) then return end
            --chat('end FarmToTarget')
            TimerReset('FarmToTarget')
            farmLastGuid = nil
            omacro('/cleartarget')
        end

    end

    if LootFrame:IsVisible() then
        if IsAttack() then  CloseLoot() end 
        return
    end

    if IsFarm() and TimerMore('AFK', 60 * 5) and not HasBuff("Пища") and not HasBuff("Питье") and not IsPlayerCasting() then
        TimerStart('AFK')
        AntiAFK()
    end

    ------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------
    if TimerStarted('AntiFarmCD') then
        if InMapPoint(farmVendor) then
            ResetMapPoint(farmVendor)
        else
            TeleportToPoint(farmVendor)
        end

        echo('AntiFarmCD ' ..  SecondsToTime(AntiFarmCDTime - TimerElapsed('AntiFarmCD')),1)
        if TimerMore('AntiFarmCD', AntiFarmCDTime) then
            TimerReset('AntiFarmCD')
            farmTryCount = 0
        end
    end
    ------------------------------------------------------------------------------------------------------------------
    if Farm and FarmAuto and not TimerStarted('AntiFarmCD') then

        if  farmPoint ~= farmExit and not money then
            money = GetMoney()
            TimerStart('Money')
        end

        if HasBuff("Питье") and UnitMana100("player") < 100 then
            needMana = false
            return 
        end

        if UnitMana100("player") > 99 then
            needMana = false
        end

        if TimerStarted('Enter') and TimerMore('Enter', 3) then
            TimerStart('AntiFarmCD')
            TimerReset('Enter')
            return
        end

        if InMapPoint(farmEnter) then
            if not TimerStarted('Enter') then TimerStart('Enter') end
        else
            TimerReset('Enter')
        end

        local inInstance, instanceType = IsInInstance()
        if inInstance ~= nil and instanceType ~= "raid" then
            inInstance = nil
        end

        if inInstance ~= nil then

            if TimerMore('View', 10) then
                oexecute('SetView(1)')
                TimerStart('View')
            end

            if farmCurrentIdx == nil then
                farmCurrentIdx = 1
                local i = 1
                while i < 100 do
                    local p = GetMapPoint(farmPrefix .. i)
                    if not p then break end
                    if CheckMapPoint(p.x, p.y, p.z) then
                        farmCurrentIdx = i
                        break
                    end
                    i = i + 1
                end
            end

            if farmRotate then 
                oexecute("TurnRightStop()")
                farmRotate = false
            end

            if needMana then
                 UseItem("Газированная оазисная вода") 
                 return
            end


            if IsAOE() and TimerMore('farmPriorityMobs', 1) and IsValidTarget("target") then
                TimerStart('farmPriorityMobs')
                local name = UnitName("target")
                local guid = UnitGUID("target")
                local try = true
                for i = 1, #farmPriorityMobs do
                    local mob = farmPriorityMobs[i]
                    if sContains(name, mob) then
                        try = false
                        break
                    end
                end

                if try then
                    for i = 1, #farmPriorityMobs do
                        local mob = farmPriorityMobs[i]
                        omacro("/tar " .. mob)
                        if IsValidTarget("target") and InMelee("target") then  
                            break
                        else
                           if guid ~= UnitGUID("target") then omacro('/targetlasttarget') end
                        end
                    end
                end
            end

            if CheckTarget() then return end

            farmPoint = farmPrefix .. farmCurrentIdx
            if not GetMapPoint(farmPoint) then 
                if money then
                    money = GetMoney() - money
                    chat(("Итого: %s, за %s"):format(GetCoinText(money) , SecondsToTime(TimerElapsed('Money'))), 1, 0 , 0.5);
                    money = nil
                    TimerReset('Money')
                end
                farmPoint = farmExit 
            end
            
            if not farmRotate and PlayerInPlace() and not IsPlayerCasting()
                and TimerStarted("NoTarget") and TimerMore("NoTarget",1) then 
                oexecute("TurnRightStart()")
                farmRotate = true
            end

            if not InMapPoint(farmPoint) then
                TimerReset("NoTarget")
                TeleportToPoint(farmPoint) 
                TimerReset("FarmPoint")
                return
            else
                if ResetMapPoint(farmPoint) or IsPlayerCasting() then
                    TimerReset("NoTarget")
                    if not InCombatLockdown() then return end
                end
                if not TimerStarted("FarmPoint") then TimerStart("FarmPoint") end
            end

            if not InCombatMode() then TryAttack() end

            if not UnitExists("target") or (oinfo('target') and InDistance("player", "target", 40.1)) then
                if TimerStarted('FarTarget') then TimerReset('FarTarget') end
            else
                if not TimerStarted('FarTarget') then TimerStart('FarTarget') end
            end
            if TimerStarted('FarTarget')  and TimerMore('FarTarget', 5)  then
                omacro('/cleartarget') 
            end

            if UnitExists("target") then
                FaceToTarget()
            end

            if CanAttack("target") then 
                
                TimerReset("NoTarget")
                recedCD = true
            else
                if UnitExists('target') then chat(CanAttackInfo) end
                if not TimerStarted("NoTarget") then TimerStart("NoTarget") end
                oexecute('ClearTarget()') 
            end

            if TimerStarted("FarmPoint") and TimerLess("FarmPoint", FarmPointMaxTime) then
                echo('<' .. farmPoint .. '> ' ..  SecondsToTime(TimerElapsed('FarmPoint')),1)
            end
            
            if farmPoint ~= farmExit and InMapPoint(farmPoint) then
                local needNext = false
                if TimerStarted("NoTarget") and TimerMore("NoTarget", 2.5) then
                    --chat(farmPoint .. " - Долго без цели")
                    needNext = true
                end
                if TimerStarted("FarmPoint") and TimerMore("FarmPoint",FarmPointMaxTime) then
                    --chat(farmPoint .. " - Долго на точке")
                    needNext = true
                end
                if needNext then
                    if not InCombatLockdown() and UnitMana100("player") < 51 and not HasBuff("Питье") and GetItemCount("Газированная оазисная вода") > 0 then 
                        --print('Пополним ману')
                        needMana = true
                        return
                    end
                    farmCurrentIdx = farmCurrentIdx + 1
                    TimerReset("NoTarget")
                    TimerReset("FarmPoint")

                end
            end
        else
            farmCurrentIdx = 1
            if GetFreeBagSlotCount() < 15 then
                if InMapPoint(farmVendor) then
                    ResetMapPoint(farmVendor)
                    if UnitExists("target") then
                        local unitName = UnitName("target")
                        if sContains(unitName, farmVendorName) then
                            oexecute('InteractUnit("target")')
                        else
                            oexecute('ClearTarget()')
                        end
                    else
                        OpenContainers()
                        if InExecQueue() then return end
                        omacro('/tar '..farmVendorName)
                    end
                else    
                    TeleportToPoint(farmVendor)
                end
            else
                if recedCD then
                    recedCD = false
                    SetRaidDifficultyID(5)
                    SetRaidDifficultyID(3)
                    TimerStart("RaidCD")
                end
                if TimerStarted("RaidCD") and TimerLess("RaidCD", 3) then return end
                TimerStart("Wait")
                TeleportToPoint(farmEnter)
            end
        end

    end
    ------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------


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
local function updateAutoFreedom(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if sourceGUID == UnitGUID("player") and amount and sContains(amount, "Действие невозможно")  then
        TimerStart('Control')
        chat(amount, 1, 0, 0)
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", updateAutoFreedom)
------------------------------------------------------------------------------------------------------------------