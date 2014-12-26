-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--UIParentLoadAddOn("Blizzard_DebugTools");
--DevTools_Dump(n)

--[[
  /run UIParentLoadAddOn("Blizzard_DebugTools");
  /fstack true
  /etrace 
]]

------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------
function echo(msg)
    UIErrorsFrame:Clear()
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2);
end
------------------------------------------------------------------------------------------------------------------
local lastMsg = {}
function chat(msg, r, g, b, key)
    r = r or 1.0
    b = b or 0.5
    g = g or 0.5
    local key  =  r * 100 + g * 10 + b
    if lastMsg[key] == msg and TimerLess('EchoMsg'..key, 2) then return end

    DEFAULT_CHAT_FRAME:AddMessage(msg, r, b, g);
    TimerStart('EchoMsg'..key)
    lastMsg[key] = msg
end
------------------------------------------------------------------------------------------------------------------
function tContainsKey(table, key)
    for name,value in pairs(table) do 
        if key == name then return true end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
function sContains(str, sub)
    if (not str or not sub) then
      return false
    end
    return (strlower(str):find(strlower(sub), 1, true) ~= nil)
end

------------------------------------------------------------------------------------------------------------------
function IsMouse(n)
    return  IsMouseButtonDown(n) == 1
end

------------------------------------------------------------------------------------------------------------------
function IsCtr()
    return  (IsControlKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsAlt()
    return  (IsAltKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsShift()
    return  (IsShiftKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end
------------------------------------------------------------------------------------------------------------------
local timers = {}
function TimerReset(name)
  timers[name] = 0
end
function TimerStarted(name)
  return (timers[name] or 0) > 0
end
function TimerStart(name, offset)
  timers[name] = GetTime() + (offset or 0)
end
function TimerElapsed(name)
  return  GetTime() - (timers[name] or 0)
end
function TimerLess(name, less)
  return TimerElapsed(name) < (less or 0)
end

function TimerMore(name, less)
  return TimerElapsed(name) > (less or 0)
end
------------------------------------------------------------------------------------------------------------------
if ExcludeItemsList == nil then ExcludeItemsList = {} end
------------------------------------------------------------------------------------------------------------------

function GetMinEquippedItemLevel()
local minItemLevel = nil
  if Farm then
    for i = 1, 18 do
      local itemID = GetInventoryItemID("player",i)
      if itemID then
        local name, _, _, itemLevel, _, itemType = GetItemInfo(itemID) 
        if itemType == "Доспехи" and (not minItemLevel or itemLevel < minItemLevel) then 
          minItemLevel = itemLevel 
        end
      end
    end
  end
  return minItemLevel
end
------------------------------------------------------------------------------------------------------------------
local function IsTrash(n, minItemLevel)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(n)
    local excuded = ExcludeItemsList[itemName]
    if excuded ~= nil then return excuded end
    if string.find(n, "ff9d9d9d") then return true end
    if Farm then
      if sContains(itemName, "Эскиз:") or sContains(itemName, "ларец") or sContains(itemName, "сейф") then 
        --print(n, " - Выкидываем эскизы, ларецы и сейфы в режиме фарма") 
        return true 
      end
    end
    if minItemLevel and itemSellPrice > 0 and #itemEquipLoc > 0 and itemLevel and itemLevel < minItemLevel and not (itemType == "Оружие" and itemSubType == "Разное") then 
      --print(n, " - низкий уровень предмета ", itemLevel, " min: " .. minItemLevel)
      return true 
    end
    return false
end

function TrashInfo(itemName, ItemLink)
    if nil == itemName then return end
    local status = ExcludeItemsList[itemName]
    local info = (status == nil and "Авто" or ("Список"))
    chat(itemName .. " - это " .. (IsTrash(ItemLink, GetMinEquippedItemLevel()) and "хлам! " or "полезный предмет! ") .. "(" .. info .. ")" )
end

function TrashToggle()
    local itemName, ItemLink = GameTooltip:GetItem()
    if nil == itemName then return end
    local status = ExcludeItemsList[itemName]
    if status == nil then
      status = true
    elseif status then
      status = false
    else
      status = nil
    end
    ExcludeItemsList[itemName] = status
    TrashInfo(itemName, ItemLink)
end

function TrashTest()
    local itemName, ItemLink = GameTooltip:GetItem()
    print(GetItemInfo(ItemLink))
    TrashInfo(itemName, ItemLink)
end
------------------------------------------------------------------------------------------------------------------
execQueueList = {}
execQueueDelay = 0.5
local function updateMacroFromList()
    if TimerLess('execQueue', execQueueDelay) then return end
    TimerStart('execQueue')
    if #execQueueList < 1 then return end
    local cmd = tremove(execQueueList, 1)
    if type(cmd) == 'function' then
      cmd()
    else
      oexecute(cmd)
    end
    
end
AttachUpdate(updateMacroFromList, 0.1)

function InExecQueue()
  return #execQueueList > 0
end
------------------------------------------------------------------------------------------------------------------
local function eachBagItems(func)
   for bag=0,NUM_BAG_SLOTS do
        for slot=1,GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag,slot)
            if link then func(bag, slot, link) end
        end
    end
end
------------------------------------------------------------------------------------------------------------------
function SellGray()
  ClearCursor()
  wipe(execQueueList)
  execQueueDelay = 0.5
  local minItemLevel = GetMinEquippedItemLevel()
  eachBagItems(function(bag, slot, link)
    if IsTrash(link, minItemLevel) then
      local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(link)                                 
      if itemSellPrice > 0 then 
        tinsert(execQueueList, format("RunMacroText('/use %s %s')", bag, slot))
      else
        PickupContainerItem(bag, slot)
        DeleteCursorItem() 
      end                  
    end
  end)                                        
end
-------------------------------------------------------------------------------------------------------------------
-- Автоматическая продажа хлама и починка
local money = 0
local function SellGrayAndRepair()
    money = GetMoney()
    TimerStart('Sell')
    RepairAllItems(1) -- сперва пробуем за счет ги банка
    RepairAllItems()
    SellGray()
end
AttachEvent('MERCHANT_SHOW', SellGrayAndRepair)
local function StopSell()
  wipe(execQueueList)
  local m = GetMoney() - money
  if not (math.abs(m) < 1) then
    m =  (m > 0 and "" or '-') .. GetCoinText(math.abs(m))  
    chat(("Итого: %s, за %s"):format(m , SecondsToTime(TimerElapsed('Sell'))), 1, 0 , 0.5);
  end
end
AttachEvent('MERCHANT_CLOSED', StopSell)
------------------------------------------------------------------------------------------------------------------
function SellItem(name) 
    wipe(execQueueList)
    execQueueDelay = 0.5
    if not name then name = "" end
    eachBagItems(function (bag, slot, link)
      if string.find(link, name) then                                 
        tinsert(execQueueList, format("RunMacroText('/use %s %s')", bag, slot))                   
      end
    end)                                        
end
------------------------------------------------------------------------------------------------------------------
function OpenContainers()
  wipe(execQueueList)
  execQueueDelay = 0.5
  local minItemLevel = GetMinEquippedItemLevel()
  eachBagItems(function (bag, slot, link)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(link)
    if not IsTrash(link, minItemLevel) and (sContains(itemName, "сунд") or sContains(itemName, "ларец") or sContains(itemName, "сейф")) then
        tinsert(execQueueList, format("RunMacroText('/use %s %s')", bag, slot))
    end 
  end) 
end
------------------------------------------------------------------------------------------------------------------
function DelGray()
  ClearCursor()
  eachBagItems(function (bag, slot, link)
    if IsTrash(link) then                                 
      PickupContainerItem(bag, slot)
      DeleteCursorItem() 
    end
  end) 
end
------------------------------------------------------------------------------------------------------------------
function GetFreeBagSlotCount() 
  local free = 0
  -- считаем сободное место
    for bag=0, NUM_BAG_SLOTS do 
        local n = GetContainerNumFreeSlots(bag);
        if n then free = free + n end
    end
    return free
end
------------------------------------------------------------------------------------------------------------------
-- Автоматическая покупка предметов
function BuyItem(name, count) 
    wipe(execQueueList)
    execQueueDelay = 1.1
    if count == nil then count = 1 end
    local idx, maxStack
    for i=1,100 do 
        if name == GetMerchantItemInfo(i) then
          idx = i
          maxStack = GetMerchantItemMaxStack(i) 
        break
      end 
    end
    if not idx then return end
    TimerStart('BuyItem')
    -- необходимо докупить
    local q = count - GetItemCount(name)
    if q < 1 then return end
    -- нет места
    local x = 1
    local max = GetFreeBagSlotCount() * maxStack
    if max < q then q = max end
    if q < 1 then return end
    while q > 0 do
      local c = (q > 255 and 255 or q)
      q = q - c
      tinsert(execQueueList, format("BuyMerchantItem(%s, %s)", idx, c))
    end
end
------------------------------------------------------------------------------------------------------------------
function NumberToHexColor(n)
    local c =  strsub(format("%X", format("%i", n*100)), -6)
    return string.rep("0", 6 - #c) .. c
end
------------------------------------------------------------------------------------------------------------------
function HexToRGB(hex)
    if not hex then return 0, 0, 0 end
    local rhex, ghex, bhex = string.sub(hex, 1, 2) or 0, string.sub(hex, 3, 4) or 0, string.sub(hex, 5, 6) or 0
    return  tonumber(rhex, 16) / 255, tonumber(ghex, 16) / 255, tonumber(bhex, 16) / 255
end
------------------------------------------------------------------------------------------------------------------
local flagFrames = {}
for i = 1, 4 do
    local flagFrame = CreateFrame("Frame", nil ,UIParent)
    flagFrame:SetFrameStrata("High")
    flagFrame:SetPoint("TOPLEFT",  (i-1) * 5 + 2, -15)
    flagFrame:SetWidth(5)
    flagFrame:SetHeight(5)
    flagFrame:SetScale(1, 1)
    flagFrame:SetAlpha(1)
    flagFrame.texture = flagFrame:CreateTexture("Texture", "Background")
    flagFrame.texture:SetBlendMode("Disable")
    flagFrame.texture:SetTexture(0.1, 0.1, 0.1)
    flagFrame.texture:SetAllPoints(flagFrame)
    flagFrame:Show()
    flagFrames[i] = flagFrame
end

local function updateFlagFrame()
    if TimerStarted('flagFrames') and TimerMore('flagFrames', 0.5) then 
      TimerReset('flagFrames') 
      for i = 1, 4 do
        local flagFrame = flagFrames[i]
        flagFrame.texture:SetTexture(0.1, 0.1, 0.1)
      end
    end
end
AttachUpdate(updateFlagFrame) 
------------------------------------------------------------------------------------------------------------------
function ShowFlag(...)
    if TimerStarted('flagFrames') then return end
    TimerStart('flagFrames')
    local params = {...}
    for i = 1, 4 do
        local flagFrame = flagFrames[i]
        local flag = params[i]
        if flag then
          flagFrame.texture:SetTexture(HexToRGB(flag))
        end
    end
end
------------------------------------------------------------------------------------------------------------------
function TeleportToPoint(name)
  local p = GetMapPoint(name)
  if not p then
    echo("Неизвестная точка " .. name,1)
    return
  end
  if p.c ~= GetCurrentMapContinent() then
    echo("Другой континент",1)
    return
  end
  echo(format("TeleportToPoint( '%s' )", name),1)
  TeleportTo(p.x, p.y, p.z)
end
------------------------------------------------------------------------------------------------------------------
               
function TeleportToTarget(target)
    if not UnitExists(target) then return end
    local x , y, z = oinfo(target)
    if not x or not y or not z then
      echo("Нет данных по координатам",1)
      return
    end
    AddMapPoint('LastTarget', x, y, z)
    TeleportToPoint('LastTarget')
end
------------------------------------------------------------------------------------------------------------------
function TeleportTo(x, y, z)
    if not CheckMapPoint(oinfo("player")) then
        echo('UNKNOWN POS',1)
        return
    end
    if CheckMapPoint(x, y, z) then
       echo("Уже на точке",1)
       return
    end
    TimerStart('LastTeleport')
    AddMapPoint("LastPos")
    ShowFlag("FF0000", NumberToHexColor(x), NumberToHexColor(y), NumberToHexColor(z + 0.5))
end
------------------------------------------------------------------------------------------------------------------
function TeleportToCorpse()
    ShowFlag("0000FF")
end
------------------------------------------------------------------------------------------------------------------
function TeleportToLastPos()
    TeleportToPoint("LastPos")
end
------------------------------------------------------------------------------------------------------------------
function AntiAFK()
  if not (IsPlayerCasting() or IsFalling()) then ShowFlag("00FF00") end
end
------------------------------------------------------------------------------------------------------------------
MapPoints = MapPoints or {}

function AddMapPoint(name, x, y, z)
  if not x or not y or not z then
    x, y, z = oinfo("player") 
  end
  if not x or not y or not z then
    echo("Нет данных по координатам",1)
    return
  end
  x = 0 + format("%.2f", x) 
  y = 0 + format("%.2f", y) 
  z = 0 + format("%.2f", z) 
  local c = GetCurrentMapContinent()
  MapPoints[name] = {x = x, y = y, z = z, c = c }
  if name ~= 'LastPos' and name ~= 'LastDeath' and name ~= 'LastTarget' then
    echo(format("Точка %s добавлена (X: %i Y: %i Z: %i континент: %s)", name, x, y, z, c),1)
  end
end

function GetMapPoint(name)
  local point = MapPoints[name]
  if not point then
    echo(format("Точка %s отсутствует", name),1)
    return nil
  end
  return point
end

function RemoveMapPoint(name)
  if not MapPoints[name] then
    echo(format("Точка %s отсутствует", name),1)
    return
  end
  MapPoints[name] = nil
  echo(format("Точка %s удалена", name),1)  
end
------------------------------------------------------------------------------------------------------------------
function InMapPoint(name)
    --chat("Check InPoint ".. name)
    local p = GetMapPoint(name)
    if not p then
        echo("Неизвестная точка " .. name,1)
        return
    end
    return CheckMapPoint(p.x,p.y, p.z)
end
------------------------------------------------------------------------------------------------------------------
function CheckMapPoint(XPos,YPos, ZPos)
    if not XPos or not YPos or not ZPos then
        return false
    end
    local x,y,z = oinfo("player") 
    return (sqrt( (x-XPos)^2 + (y-YPos)^2 + (z-ZPos)^2 ) < 3)
end
------------------------------------------------------------------------------------------------------------------
function ResetMapPoint(name)
    if not TimerStarted('LastTeleport') or not InMapPoint(name) then return false end
    if TimerMore('LastTeleport', 5) then
      TimerReset('LastTeleport')
      return false 
    end
    TimerReset('LastTeleport')
    oexecute('JumpOrAscendStart()')
    wipe(execQueueList)
    execQueueDelay = 0.3
    tinsert(execQueueList, 'AscendStop()')
    return true
end
------------------------------------------------------------------------------------------------------------------
--[[
/run AddMapPoint('A - Farm 1')
]]
