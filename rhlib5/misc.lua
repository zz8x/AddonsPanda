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
local lastMsg = ""
function chat(msg)
    if msg == lastMsg and TimerLess('EchoMsg', 2) then return end
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.5, 0.5);
    TimerStart('EchoMsg')
    lastMsg = msg
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
if TrashList == nil then TrashList = {} end

------------------------------------------------------------------------------------------------------------------
function IsTrash(n) --n - itemlink
    if string.find(n, "ff9d9d9d") then return true end
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(n)
    if tContains(TrashList, itemName)  then return true end
    return false
end

function TrashToggle()
    local itemName, ItemLink = GameTooltip:GetItem()
    if nil == itemName then return end
    if tContains(TrashList, itemName) then 
        for i=1, #TrashList do
            if TrashList[i] ==  itemName then 
                tremove(TrashList, i)
                chat(itemName .. " - это полезный предмет! ")
            end
        end            
    else
        chat(itemName .. " - это хлам! ")
        tinsert(TrashList, itemName)
    end
end
------------------------------------------------------------------------------------------------------------------
local autoLootTimeout = 2
function TemporaryAutoLoot(t)
    autoLootTimer = t or 2
    if not TimerStarted("AutoLoot") then
        chat("Автолут ON")
        omacro("/console autoLootDefault 1")

    end
    TimerStart("AutoLoot")
end
local function UpdateAutoLootTimer()
    if TimerStarted("AutoLoot") and TimerMore("AutoLoot", autoLootTimer)  then
        chat("Автолут OFF")
        omacro("/console autoLootDefault 0")
        TimerReset("AutoLoot")
    end
end
AttachUpdate(UpdateAutoLootTimer, 0.5) 

------------------------------------------------------------------------------------------------------------------
local useItemList = {}
local function updateUseItemsFromList()
    if #useItemList < 1 then return end
    omacro("/use " .. tremove(useItemList, 1))
end
AttachUpdate(updateUseItemsFromList, 1.2)
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
  eachBagItems(function(bag, slot, link)
    if IsTrash(link) then                                 
      tinsert(useItemList, bag .." " .. slot)                   
    end
  end)                                        
end
-------------------------------------------------------------------------------------------------------------------
-- Автоматическая продажа хлама и починка
local function SellGrayAndRepair()
    RepairAllItems(1) -- сперва пробуем за счет ги банка
    RepairAllItems()
    SellGray()
end
AttachEvent('MERCHANT_SHOW', SellGrayAndRepair)
local function StopSell()
  wipe(useItemList)
end
AttachEvent('MERCHANT_CLOSED', SellGrayAndRepair)
------------------------------------------------------------------------------------------------------------------
function SellItem(name) 
    if not name then name = "" end
    eachBagItems(function (bag, slot, link)
      if string.find(link, name) then                                 
        tinsert(useItemList, bag .." " .. slot)                   
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
function GetItemCount(name)
    local count = 0
    for bag=0,NUM_BAG_SLOTS do
        for slot=1,GetContainerNumSlots(bag) do
            local item = GetContainerItemLink(bag,slot)
            if item and string.find(item,name) then 
                count=count+(select(2,GetContainerItemInfo(bag,slot)))
            end
        end
    end
    return count
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
    while true do
      -- необходимо докупить
      local q = count - GetItemCount(name)
      if q < 1 then return end
      -- нет места
      local c = GetFreeBagSlotCount()
      if c < 1 then return end
      BuyMerchantItem(idx,(q > maxStack and maxStack or q))
    end
end

------------------------------------------------------------------------------------------------------------------