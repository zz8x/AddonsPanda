-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------

function IsReadySlot(slot, checkGCD)
    if not HasAction(slot) then return false end 
    local itemID = GetInventoryItemID("player",slot)
    if not itemID or (IsItemInRange(itemID, "target") == 0) then return false end
    if not IsReadyItem(itemID, checkGCD) then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------

function UseSlot(slot)
    if IsPlayerCasting() then return false end
    if not IsReadySlot(slot) then return false end
    if not IsReadySlot(slot, true) then return true end
    omacro("/use " .. slot) 
    if SpellIsTargeting() then 
        oclick("target")
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
function GetItemCooldownLeft(name)
    local itemName, itemLink =  GetItemInfo(name)
    if not itemName then
        if Debug then error("Итем [".. name .. "] не найден!") end
        return false;
    end
    local itemID =  itemLink:match("item:(%d+):")
    local start, duration, enabled = GetItemCooldown(itemID);
    if enabled ~= 1 then return 1 end
    if not start then return 0 end
    if start == 0 then return 0 end
    local left = start + duration - GetTime()
    return left
end

------------------------------------------------------------------------------------------------------------------
function ItemExists(item)
    return GetItemInfo(item) and true or false
end

------------------------------------------------------------------------------------------------------------------
function ItemInRange(item, unit)
    if ItemExists(item) then
        return (IsItemInRange(item, unit) == 1)
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function IsReadyItem(name, checkGCD)
   local usable = IsUsableItem(name) 
   if not usable then return true end
   local left = GetItemCooldownLeft(name)
   return IsReady(left, checkGCD)
end

------------------------------------------------------------------------------------------------------------------
function EquipItem(itemName)
    if IsEquippedItem(itemName) then return false end
    if Debug then
        print(itemName)
    end
    omacro("/equip  " .. itemName) 
    return IsEquippedItem(itemName)
end
------------------------------------------------------------------------------------------------------------------

function UseItem(itemName, count)
    if IsPlayerCasting() then return false end
    if not ItemExists(itemName) then return false end
    if not IsEquippedItem(itemName) and not IsUsableItem(itemName) then return false end
    if IsCurrentItem(itemName) then return false end
    if not IsReadyItem(itemName) then return false end
    if not IsReadyItem(itemName, true) then return true end
    local itemSpell = GetItemSpell(itemName)
    if itemSpell and IsSpellInUse(itemSpell) then return false end
    if not count then count = 1 end
    for i = 1, count do
        omacro("/use " .. itemName)
        if SpellIsTargeting() then 
            oclick("target")
        end
    end
    return true
end
------------------------------------------------------------------------------------------------------------------
function UseEquippedItem(item)
    if IsEquippedItem(item) and UseItem(item) then return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
local potions = { 
    "Камень здоровья",
	"Легендарное лечебное зелье",
	"Рунический флакон с лечебным зельем"--[[,
	"Бездонный флакон с лечебным зельем",
    "Гигантский флакон с лечебным зельем"]]
}
function UseHealPotion()
    for i = 1, #potions do 
		if UseItem(potions[i], 5) then return true end
	end
    return false
end