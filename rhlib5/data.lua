-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local SpellsRedList = SpellsRedList

--{"Оглушение", "Неуязвимость, неспособность", "Неуязвимость. Неспособность"}
------------------------------------------------------------------------------------------------------------------
--Паралич
--Дезориентация
--Сон
--Страх
--Ужас
--Принуждение к бегству
--Дрожь
--Заморозка
--Превращение
--Оковы
--Ослепление
--Ошеломление
--Скованность
--Сглаз
--Подчинение
------------------------------------------------------------------------------------------------------------------
--страх подчинение сон
------------------------------------------------------------------------------------------------------------------
-- Можно законтролить игрока
CanControlInfo = ""
local imperviousList = {"Вихрь клинков", "Зверь внутри", "Оскверненная земля"}
local physicsList = {"Незыблемость льда", "Длань защиты"} --Перерождение
function CanControl(target, magic, physic)
    CanControlInfo = ""
    if nil == target then target = "target" end 
    if not (magic and CanMagicAttack or CanAttack)(target) then
        CanControlInfo = (magic and CanMagicAttackInfo or CanAttackInfo) 
        return false
    end
    local aura =  HasBuff(imperviousList, 0.1, target) or (physic and HasBuff(physicsList, 0.1, target))
    if aura then
        CanControlInfo = aura
        return false
    end 
    return true   
end


local tooltipCollection = {}
local tooltip
function InControl(target, last, collectTooltips) 
    tooltip = GetUtilityTooltips()
    wipe(tooltipCollection)
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
        if not name then break end
        if (expirationTime == 0 or expirationTime - GetTime() >= last) and SpellsRedList[spellId] == "CC" then
            if collectTooltips == nil then 
                return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId 
            end

            tooltip:SetUnitDebuff(target, i);
            local nLines = tooltip:NumLines()
            for i = 1, nLines do
                tooltipCollection[#tooltipCollection + 1] = tooltip.left[i]:GetText()
            end
        end 
    end 
    if #tooltipCollection > 0 then return table.concat( tooltipCollection) end
    return nil
end
------------------------------------------------------------------------------------------------------------------
-- можно использовать магические атаки против игрока
CanMagicAttackInfo = ""
local magicList = {"Антимагический панцирь", "Плащ Теней", "Символ ледяной глыбы"  }
local magicReflectList = {"Отражение заклинания", "Дзен-медитация",  "Эффект тотема заземления"}
function CanMagicAttack(target)
    CanMagicAttackInfo = ""
    if nil == target then target = "target" end 
    if not CanAttack(target) then
        CanMagicAttackInfo = CanAttackInfo
        return false
    end
    local aura = HasBuff(magicList, 0.1, target)
    if not aura and not IsAttack() then
        aura = HasBuff(magicReflectList, 0.1, target)
    end
    if aura then
        CanMagicAttackInfo = aura
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
-- можно атаковать игрока (в противном случае не имеет смысла просаживать кд))
local immuneList = {"Божественный щит", "Ледяная глыба", "Сдерживание", "Закон кармы", "Смерч", "Слияние с Тьмой"}
CanAttackInfo = ""
function CanAttack(target)
    CanAttackInfo = ""
    if nil == target then target = "target" end 
    if not IsValidTarget(target) then
        CanAttackInfo = IsValidTargetInfo
        return false
    end
    if not IsVisible(target) then
        CanAttackInfo = "Цель в лосе."
        return false
    end

    local aura = HasAura(immuneList, 0.01, target)
    if aura then
        CanAttackInfo = "Цель имунна: " .. aura
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
local nointerruptBuffs = {"Аура благочестия", "Твердая решимость"}
function IsInterruptImmune(target, t)
    if target == nil then target = "target" end
    if t == nil then t = 0.1 end
    return HasBuff(nointerruptBuffs, t , target)
end
------------------------------------------------------------------------------------------------------------------
local ctrList = { "Сон", "Страх", "Дрожь", "Превращение", "Сглаз", "Подчинение", "Ослепление", "Ошеломление"}
function IsNotAttack(target)
    if not target then target = "target" end
    -- не бьем в имун
    local stop = false
    local msg = ""
    if not CanAttack(target) then 
        msg = msg .. CanAttackInfo .. " "
        stop = true 
    else
        if not stop then
            -- чтоб контроли не сбивать
            local auras = InControl(target, 0.3, true)
            if auras then
                if not sContains(auras, "Оглушение") then
                    for i = 1, #ctrList do
                        if sContains(auras, ctrList[i]) then 
                            msg = msg .. "На цели " .. ctrList[i] .. " "
                            result = true
                        end
                    end
                end
            end
        end
    end

    if msg ~= "Нет цели" then 
        msg = "" 
    end
    if stop and IsAttack() then
        if msg ~= "" then msg = msg .. "(Force!)" end
        stop = false
    end
    if IsValidTarget("target") then
        if stop then 
            if IsSpellInUse("Автоматическая атака") then oexecute("StopAttack()") end
        else
            if not IsSpellInUse("Автоматическая атака") and not IsStealthed() then oexecute("StartAttack()") end
        end   
    end
    
    if msg ~= "" then chat(target..": " .. msg) end
    return stop
end