-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Возвращает список членов группы отсортированных по приоритету исцеления
local members = {}
local membersHP = {}
local protBuffsList = {"Ледяная глыба", "Божественный щит", "Превращение", "Щит земли", "Частица Света"}
local dangerousType = {"worldboss", "rareelite", "elite"}
local function compareMembers(u1, u2) 
    return membersHP[u1] < membersHP[u2]
end
function GetHealingMembers(units)
    local myHP = UnitHealth100("player")
    if #members > 0 and FastUpdate then
        return members
    end
    wipe(members)
    wipe(membersHP)
    if units == nil then 
        tinsert(members, "player")
        membersHP["player"] = UnitHealth100("player")
        return members, membersHP
    end
    for i = 1, #units do
        local u = units[i]
        if CanHeal(u) then 
            local h =  UnitHealth100(u)
            if IsFriend(u) and UnitAffectingCombat(u) then 
                h = h - (110 - h) / 10
            end
            if UnitIsPet(u) then
                if UnitAffectingCombat("player") then 
                    h = h * 1.5
                end
            else
                if not IsPvP() then
                    local status = 0
                    for j = 1, #TARGETS do
                        local t = TARGETS[j]
                        if tContains(dangerousType, UnitClassification(t)) then 
                            local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", t)
                            if state ~= nil and state > status then status = state end
                        end
                    end
                    h = h - 2 * status
                end
                if not IsOneUnit("player", u) and HasBuff(protBuffsList, 1, u) then h = h + 5 end
                if not IsArena() and myHP < 50 and not IsOneUnit("player", u) and not (UnitThreat(u) == 3) then h = h + 30 end
            end
            tinsert(members, u)
            membersHP[u] = h
        end
    end
    sort(members, compareMembers)  
    return members
end
------------------------------------------------------------------------------------------------------------------
-- friend list
local function friendListUpdate()
    if not FriendList then 
        ShowFriends()
        FriendList = {} 
    end
    wipe(FriendList)
    local numberOfFriends = GetNumFriends()
    for i = 1, numberOfFriends do
        local name = GetFriendInfo(i);
        if name then 
            tinsert(FriendList, name)
        end
    end
end
friendListUpdate()
AttachEvent("FRIENDLIST_UPDATE", friendListUpdate)

function IsFriend(unit)
    if not FriendList then friendListUpdate() end
    if IsOneUnit(unit, "player") then return true end
    if not UnitIsPlayer(unit) or not IsInteractUnit(unit) then return false end
    return tContains(FriendList, UnitName(unit))
end

------------------------------------------------------------------------------------------------------------------
function GetTeammate()
    if not FriendList or #FriendList < 1 then friendListUpdate() end
    for i = 1, #FriendList do
        local name = FriendList[i];
        if IsInteractUnit(name) then 
            return GetSameGroupUnit(name)
        end
    end
    return nil
end
------------------------------------------------------------------------------------------------------------------
-- unit filted start
local IgnoredNames = {}

function Ignore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil then 
        Notify(target .. " not exists")
        return 
    end
    IgnoredNames[n] = true
    Notify("Ignore " .. n)
end

function IsIgnored(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil or not IgnoredNames[n] then return false end
    -- Notify(n .. " in ignore list")
    return true
end

function NotIgnore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n then 
        IgnoredNames[n] = false
        Notify("Not ignore " .. n)
    end
end

function NotIgnoreAll()
    wipe(IgnoredNames)
    Notify("Not ignore all")
end
-- unit filted start end

------------------------------------------------------------------------------------------------------------------
local inDuel = false
local startDuel = StartDuel
function StartDuel()
    inDuel = true
    startDuel()
end

function InDuel()
    return inDuel
end
local function DuelUpdate(event)
   inDuel = (event == 'DUEL_REQUESTED' and true or false)
end
AttachEvent('DUEL_REQUESTED', DuelUpdate)
AttachEvent('DUEL_FINISHED', DuelUpdate)
------------------------------------------------------------------------------------------------------------------
local units = {}
local realUnits = {}
function GetUnits()
	wipe(units)
	tinsert(units, "target")
	tinsert(units, "focus")
	local members = GetGroupUnits()
	for i = 1, #members, 1 do 
		tinsert(units, members[i])
		tinsert(units, members[i] .."pet")
	end
	tinsert(units, "mouseover")
	wipe(realUnits)
    for i = 1, #units do 
        local u = units[i]
        local exists = false
        for j = 1, #realUnits do 
        exists = IsOneUnit(realUnits[j], u)
			if exists then break end 
		end
        if not exists and InInteractRange(u) then 
			tinsert(realUnits, u) 
		end
    end
    return realUnits
end

------------------------------------------------------------------------------------------------------------------
local groupUnits  = {}
function GetGroupUnits()
	wipe(groupUnits)
	tinsert(groupUnits, "player")
    if not IsInGroup() then return groupUnits end
    local name = "party"
    local size = MAX_PARTY_MEMBERS
	if IsInRaid() then
		name = "raid"
		size = MAX_RAID_MEMBERS
    end
    for i = 0, size do 
		tinsert(groupUnits, name..i)
    end
    return groupUnits
end
------------------------------------------------------------------------------------------------------------------
-- /run DоCommand("cl", GetSameGroupUnit("mouseover"))
function GetSameGroupUnit(unit)
    local group = GetGroupUnits()
    for i = 1, #group do
        if IsOneUnit(unit, group[i]) then return group[i] end
    end
    return unit
end

------------------------------------------------------------------------------------------------------------------
local targets = {}
local realTargets = {}
function GetTargets()
	wipe(targets)
	tinsert(targets, "target")
	tinsert(targets, "focus")
	if IsArena() then
		for i = 1, 5 do 
			 tinsert(targets, "arena" .. i)
		end
	end
	for i = 1, 4 do 
		 tinsert(targets, "boss" .. i)
	end
	local members = GetGroupUnits()
	for i = 1, #members do 
		 tinsert(targets, members[i] .."-target")
		 tinsert(targets, members[i] .."pet-target")
	end
	tinsert(targets, "mouseover")
	wipe(realTargets)
    for i = 1, #targets do 
        local u = targets[i]
        
        local exists = false
        for j = 1, #realTargets do 
 			exists = IsOneUnit(realTargets[j], u) 
			if exists then break end 
		end

        if not exists and IsValidTarget(u) and (IsArena() or CheckInteractDistance(u, 1) 
                or IsOneUnit("player", u .. '-target')) then 
            tinsert(realTargets, u) 
        end
        
    end
    return realTargets
end

------------------------------------------------------------------------------------------------------------------
IsValidTargetInfo = ""
function IsValidTarget(target)
    IsValidTargetInfo = ""
    if target == nil then target = "target" end
    if not UnitName(target) then 
        IsValidTargetInfo = "Нет цели"
        return false 
    end
    if IsIgnored(target) then 
        IsValidTargetInfo = "Цель в игнор листе"
        return false 
    end
    if UnitIsDeadOrGhost(target) and not HasBuff("Притвориться мертвым", 1,target) then 
        IsValidTargetInfo = "Цель дохлая"
        return false 
    end

    if not UnitCanAttack("player", target) then
        IsValidTargetInfo = "Невозможно атаковать"
        return false
    end

    return true
end

------------------------------------------------------------------------------------------------------------------
IsInteractUnitInfo = ""
function IsInteractUnit(t)
    if not UnitExists(t) then 
    	IsInteractUnitInfo = "Нет юнита " .. t
    	return false 
    end
    if IsIgnored(t) then 
    	IsInteractUnitInfo = "В игноре " .. t
    	return false 
    end
    if IsValidTarget(t) then 
    	IsInteractUnitInfo = "Валидная цель " .. t
    	return false 
    end
    if UnitIsDeadOrGhost(t) then 
    	IsInteractUnitInfo = "Труп или призрак " .. t
    	return false 
    end
    if UnitIsCharmed(t) then 
    	IsInteractUnitInfo = "Околдован " .. t
    	return false 
    end
    if UnitIsEnemy("player",t) then
    	IsInteractUnitInfo = "Враждебен "  .. t
    	return false 
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
CanHealInfo = ""
function CanHeal(t)
    CanHealInfo = ""
    if not InInteractRange(t) then
        CanHealInfo = "Не в радиусе взаимодействия"
        return false
    end
    if HasDebuff("Смерч", 0.1, t) then
        CanHealInfo = "В Смерче (имунна)"
        return false
    end
    if not IsVisible(t) then
        CanHealInfo = "Вне поля зрения"
        return false
    end
    
    return true
end 
------------------------------------------------------------------------------------------------------------------
function GetClass(target)
    if not target then target = "player" end
    local _, class = UnitClass(target)
    return class
end

------------------------------------------------------------------------------------------------------------------
function HasClass(units, classes)
    local function checkClass(u, classes)
        return  UnitExists(u) and UnitIsPlayer(u) and (type(classes) == 'table' and tContains(classes, GetClass(u)) or classes == GetClass(u)) 
    end
    if type(units) == 'table' then
    	for i = 1, #units do
            local u = units[i]
    		if checkClass(u, classes) then return true end
    	end
    else
        if checkClass(units, classes) then return true end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function GetUnitType(target)
    if not target then target = "target" end
    local unitType = UnitName(target)
    if UnitIsPlayer(target) then
        unitType = GetClass(target)
    end
    if UnitIsPet(target) then
        unitType ='PET'
    end
    return unitType
end

------------------------------------------------------------------------------------------------------------------
function UnitIsNPC(unit)
    return UnitExists(unit) and not (UnitIsPlayer(unit) or UnitPlayerControlled(unit) or UnitCanAttack("player", unit));
end

------------------------------------------------------------------------------------------------------------------
function UnitIsPet(unit)
    return UnitExists(unit) and not UnitIsNPC(unit) and not UnitIsPlayer(unit) and UnitPlayerControlled(unit);
end

------------------------------------------------------------------------------------------------------------------
function IsOneUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return false end
    return unit1 == unit2 or UnitGUID(unit1) == UnitGUID(unit2)
end

------------------------------------------------------------------------------------------------------------------
function UnitThreat(u, t)
    if not UnitIsPlayer(u) then return 0 end
    local threat = UnitThreatSituation(u, t)
    if threat == nil then threat = 0 end
    return threat
end

------------------------------------------------------------------------------------------------------------------
function UnitThreatAlert(u)
    local threat, target = UnitThreat(u), format("%s-target", u)
    if UnitAffectingCombat(target) 
        and UnitIsPlayer(target) 
        and IsValidTarget(target) 
        and IsOneUnit(u, target .. "-target") then threat = 3 end
    return threat
end

------------------------------------------------------------------------------------------------------------------
function UnitHealth100(target)
    if target == nil then target = "player" end
    return UnitHP(target) * 100 / UnitHealthMax(target)
end

------------------------------------------------------------------------------------------------------------------
function UnitMana100(target)
    if target == nil then target = "player" end
    return UnitMana(target) * 100 / UnitManaMax(target)
end

------------------------------------------------------------------------------------------------------------------
function UnitLostHP(unit)
    local hp = UnitHP(unit)
    local maxhp = UnitHealthMax(unit) 
   -- if target == "player" and IsCtr() then return maxhp / 2 end
    local lost = maxhp - hp
    if UnitThreatAlert(unit) == 3 then lost = lost * 1.5 end
    return lost
end

------------------------------------------------------------------------------------------------------------------
function UnitHP(unit)
  --if target == "player" and IsCtr() then return 50 end
  local hp = UnitHealth(unit) + (UnitGetIncomingHeals(unit) or 0)
  if hp > UnitHealthMax(unit) then hp = UnitHealthMax(unit) end
  return hp
end

------------------------------------------------------------------------------------------------------------------
function IsBattleground()
    local inInstance, instanceType = IsInInstance()
    return (inInstance ~= nil and instanceType =="pvp")
end

------------------------------------------------------------------------------------------------------------------
function IsArena()
    local inInstance, instanceType = IsInInstance()
    return (inInstance ~= nil and instanceType =="arena")
end

------------------------------------------------------------------------------------------------------------------
function IsPvP()
    local inInstance, instanceType = IsInInstance()
    return (inInstance ~= nil and (instanceType =="arena" or instanceType =="pvp")) or (IsValidTarget("target") and UnitIsPlayer("target"))
end
------------------------------------------------------------------------------------------------------------------
function PlayerInPlace()
    return (GetUnitSpeed("player") == 0) and not IsFalling()
end

------------------------------------------------------------------------------------------------------------------
local sqrt = sqrt
function CheckDistance(unit1,unit2)
  if not UnitExists(unit1) or not UnitExists(unit2) or IsOneUnit(unit1,unit2) then return 0 end
  local x1,y1,z1,rot1 = oinfo(unit1) 
  local x2,y2,z2,rot2 = oinfo(unit2) 
  return sqrt( (x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2 )
end

------------------------------------------------------------------------------------------------------------------
function InDistance(unit1,unit2, distance)
  local d = CheckDistance(unit1, unit2)
  if unit1 ~= unit2 then print("InDistance", unit1, unit2, d, d < distance) end
  return d < distance
end

------------------------------------------------------------------------------------------------------------------
function InViewEnemyCount() 
    local count = 0 
    local frames = {WorldFrame:GetChildren()} 
    for _, frame in pairs(frames) do 
        if frame:GetName() and frame:IsShown() and frame:GetName():find('NamePlate%d') then 
            count = count + 1
        end 
    end 
    return count 
end
------------------------------------------------------------------------------------------------------------------
function PlayerFacingTarget(unit)
    if not UnitExists(unit) or IsOneUnit("player",unit) then return false end
    local x1,y1,_,facing = oinfo("player")
    local x2,y2 = oinfo(unit)
    local yawAngle = atan2(y1 - y2, x1 - x2) - deg(facing)
    if yawAngle < 0 then yawAngle = yawAngle + 360 end

    return yawAngle > 90 and yawAngle < 270
end
------------------------------------------------------------------------------------------------------------------
function InCombatMode()

    if IsValidTarget("target") then TimerStart('CombatTarget') end
    if InCombatLockdown() then TimerStart('CombatLock') end
    if IsAttack() then return true end
    if TimerLess('CombatLock', 1) and TimerLess('CombatTarget', 3) then return true end
    --[[if IsFarm() then
        local myHP, myMana =  UnitHealth100("player"), UnitMana100("player")
        if myHP > 60 and myMana > 60  then  
            if TimerMore('Attack', 1) then TryAttack() end
            return true  
        end
    end]]
    return false
end
------------------------------------------------------------------------------------------------------------------
function TargetActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 4) == 1)
end
------------------------------------------------------------------------------------------------------------------
local checkHunter = false;
function CheckTarget(useFocus , actualDistance)

    if not IsPvP() and not IsValidTarget("target")  and UnitThreatSituation("player") == 3 then 
        return 
    end

    if not actualDistance then
        actualDistance = TargetActualDistance
    end
    -- проверяем на 
    if IsValidTarget("target") then
       checkHunter = UnitIsPlayer("target") and ("HUNTER" == GetClass("target"))
    else
        if checkHunter then
            oexecute("TargetLastTarget()")
            if not CanAttack("target") then
                checkHunter = false
                if UnitExists("target") then oexecute("ClearTarget()") end   
            else
                chat("Перевыбрали ханта")
                TryAttack() 
            end
        end
    end

    -- помощь в группе
    if not IsValidTarget("target") and IsInGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then oexecute("ClearTarget()") end

        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and actualDistance(t) and (not IsPvP() or UnitIsPlayer(t))  then 
                oexecute('TargetUnit("'.. t .. '")')
                if CanAttack("target") then
                    break
                end
            end
        end
    end
    -- пытаемся выбрать ну хоть что нибудь
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        local tryTarget = true
        if UnitExists("target") then 
            oexecute("ClearTarget()")
        else
            tryTarget = TimerMore('TargetUnit', 0.3)
        end

        if tryTarget then
            TimerStart('TargetUnit')
            if CanAttack("focus") and (not IsPvP() or UnitIsPlayer("focus")) then 
                oexecute('TargetUnit("focus")') 
            elseif IsPvP() then 
                oexecute("TargetNearestEnemyPlayer()") 
            else
                oexecute("TargetNearestEnemy()") 
            end
            if not IsAttack()  -- если в авторежиме
                and UnitExists("target") 
                and (not CanAttack("target")  -- вообще не цель
                    or (not IsArena() and not actualDistance("target"))  -- далековато
                    or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
                    or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
                )  then 
                oexecute("ClearTarget()") 
            end
        end
    end

    if useFocus ~= false then 
        if not IsValidTarget("focus") then
            if UnitExists("focus") then oexecute("ClearFocus()") end
            for i = 1, #TARGETS do
                local t = TARGETS[i]
                if UnitAffectingCombat(t) and actualDistance(t) and not IsOneUnit("target", t) and (not IsPvP() or UnitIsPlayer(t)) then 
                    oexecute('FocusUnit("'.. t .. '")')
                    break
                end
            end
        end
        
        if not IsValidTarget("focus") or IsOneUnit("target", "focus") or (not IsArena() and not actualDistance("focus")) then
            if UnitExists("focus") then oexecute("ClearFocus()") end
        end
    end

    if IsArena() then
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") and IsValidTarget("arena2") then oexecute('FocusUnit("arena2")') end
            if IsOneUnit("target","arena2") and IsValidTarget("arena1") then oexecute('FocusUnit("arena1")') end
        end
    end
end
------------------------------------------------------------------------------------------------------------------
local freedomSlots = {13, 14}
local freedomItem = nil
local freedomSpell = "Каждый за себя"
function IsReadyFreedom()
	if HasSpell(freedomSpell) then
		return IsReadySpell(freedomSpell) 
	else
		if freedomItem == nil then
	    	for i=1,#freedomSlots do
	    		local slot = freedomSlots[i]
	    		local itemID = GetInventoryItemID("player",slot)
	    		if itemID and GetItemSpell(itemID) == "PvP-аксессуар" then
					freedomItem = GetItemInfo(itemID)
					return IsReadyItem(freedomItem) 
	    		end
	    	end
	    else
	    	return IsReadyItem(freedomItem) 
	    end
	end
    return false
end

function TryFreedom() 
    if IsPlayerCasting() or not IsReadyFreedom() then return false end
    return HasSpell(freedomSpell) and DoSpell(freedomSpell) or UseEquippedItem(freedomItem)
end

local ctrList = { "Сон", "Страх", "Дрожь", "Превращение", "Сглаз", "Подчинение", "Ослепление", "Ошеломление"}
function AutoFreedom()
    if not IsReadyFreedom() then return false end
    if not TimerStarted('Control') or TimerMore('Control', 2) then return false end
    -- контроли или сапы (по атаке)
    local debuff
    local auras = InControl("player", 2, true)
    if auras then
        
        print(auras)
        if sContains(auras, "Оглушение") then
            debuff = "Оглушение"
        elseif IsAttack() then
            for i = 1, #ctrList do
                if sContains(auras, ctrList[i]) then 
                    debuff = ctrList[i]
                end
            end
        end
    end
    if debuff then
        if TryFreedom() then
            chat('freedom: ' .. debuff)
            return true
        end
    end 
    return false
end
------------------------------------------------------------------------------------------------------------------
