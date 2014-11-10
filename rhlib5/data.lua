-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--Оглушение
--Неуязвимость, неспособность действовать.
--Неуязвимость. Неспособность к атакующим действиям

StunList = {
}

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
SappedList  = {
}


--страх подчинение сон
TotemList = {
    "Спячка"
}


------------------------------------------------------------------------------------------------------------------
-- Можно законтролить игрока
local magicControlList = {"Покаяние", "Смерч", "Молот правосудия"} -- TODO: дополнить
local physicControlList = {"Молот правосудия", "Калечение", "Оглушить"} -- TODO: дополнить
local imperviousList = {"Вихрь клинков", "Зверь внутри"}
local physicsList = {"Незыблемость льда"}
CanControlInfo = ""
function CanControl(target, spell)
    CanControlInfo = ""
    if nil == target then target = "target" end 
    local physic = false
    local magic = false
    if spell then
        magic = tContains(magicControlList, spell)
        physic = tContains(physicControlList, spell)
    end 
    if not (magic and CanMagicAttack or CanAttack)(target) then
        CanControlInfo = (magic and CanMagicAttackInfo or CanAttackInfo) 
        return false
    end
    local aura = HasBuff(imperviousList, 0.1, target) or (physic and HasBuff(physicsList, 0.1, target))
    if aura then
        CanControlInfo = aura
        return false
    end 
    return true   
end

function InStun(target, t) 
    return HasDebuff(StunList, t, target)
end

function InSap(target, t) 
    return HasDebuff(SappedList, t, target)
end

function InControl(target, t) 
    return InStun(target, t) or InSap(target, t)
end

------------------------------------------------------------------------------------------------------------------
-- можно использовать магические атаки против игрока
CanMagicAttackInfo = ""
local magicList = {"Отражение заклинания", "Антимагический панцирь", "Эффект тотема заземления"}
function CanMagicAttack(target)
    CanMagicAttackInfo = ""
    if nil == target then target = "target" end 
    if not CanAttack(target) then
        CanMagicAttackInfo = CanAttackInfo
        return false
    end
    local aura = HasBuff(magicList, 0.1, target) 
    if aura then
        CanMagicAttackInfo = aura
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
-- можно атаковать игрока (в противном случае не имеет смысла просаживать кд))
local immuneList = {"Божественный щит", "Ледяная глыба", "Сдерживание"}
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
    local aura = HasBuff(immuneList, 0.01, target) or HasDebuff("Смерч", 0.01, target)
    if aura then
        CanAttackInfo = "Цель имунна: " .. aura
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
-- касты обязательные к сбитию в любом случае
local InterruptRedList = {
    "Великая волна исцеления",
    "Волна исцеления",
    "Выброс лавы",
    "Сглаз",
    "Цепное исцеление",
    "Превращение",
    "Прилив сил",
    "Нестабильное колдовство",
    "Блуждающий дух",
    "Стрела Тьмы",
    "Сокрушительный бросок",
    "Стрела Хаоса",
    "Вой ужаса",
    "Страх",
    "Похищение жизни",
    "Похищение души",
    "Свет небес",
    "Вспышка Света",
    "Быстрое исцеление",
    "Исповедь",
    "Божественный гимн",
    "Связующее исцеление",
    "Массовое рассеивание",
    "Прикосновение вампира",
    "Сожжение маны",
    "Молитва исцеления",
    "Исцеление",
    "Контроль над разумом",
    "Великое исцеление",
    "Покровительство Природы",
    "Звездный огонь",
    "Смерч",
    "Спокойствие потоковое",
    "Восстановление",
    "Целительное прикосновение",
    "Изгнание зла", 
    "Сковывание нежити",
    "Спячка",
    "Исцеляющий всплеск",
    "Божественный свет",
    "Отпугивание зверя",
    "Святое сияние",
    "Божественный свет",
    "Звездный поток",
    "Рука Гул'дана"
}

function InInterruptRedList(spellName)
    return tContains(InterruptRedList, spellName)
end
------------------------------------------------------------------------------------------------------------------
local nointerruptBuffs = {"Мастер аур", "Сила духа"}
function IsInterruptImmune(target, t)
    if target == nil then target = "target" end
    if t == nil then t = 0.1 end
    return HasBuff(nointerruptBuffs, t , target)
end
------------------------------------------------------------------------------------------------------------------
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
            local aura = InSap(target)
            if aura then 
                msg = msg .. "На цели " .. aura .. " "
                result = true
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