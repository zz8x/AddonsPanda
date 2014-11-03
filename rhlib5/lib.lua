-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Инициализация скрытого фрейма для обработки событий
local frame=CreateFrame("Frame","RHLIB5FRAME",UIParent)
------------------------------------------------------------------------------------------------------------------
-- Список событие -> обработчики
local EventList = {}
function AttachEvent(event, func) 
    if nil == func then error("Func can't be nil") end  
    local funcList = EventList[event]
    if nil == funcList then 
        funcList = {} 
        -- attach events
        frame:RegisterEvent(event)
    end
    tinsert(funcList, func)
    EventList[event] = funcList
end

------------------------------------------------------------------------------------------------------------------
-- Выполняем обработчики соответсвующего события
local function onEvent(self, event, ...)
    if EventList[event] ~= nil then
        local funcList = EventList[event]

        for i = 1, #funcList do
            funcList[i](event, ...)
        end
    end
end
frame:SetScript("OnEvent", onEvent)

------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
local UpdateList = {}
function AttachUpdate(f, i) 
    if nil == f then error("Func can't be nil") end  
    if i == nil then i = 1 end -- одна секунда по умолчанию
    tinsert(UpdateList, {func = f, interval = i, update = 0})
end

------------------------------------------------------------------------------------------------------------------

local update = 1
local unpdateTick = 1
-- Выполняем обработчики события OnUpdate
local function OnUpdate(frame, elapsed)

    if ((IsAttack() or IsMouse(3)) and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end
    local throttle = 1 / GetFramerate()
    update = update + elapsed
    if update > throttle then
        unpdateTick  = unpdateTick + 1
        if (unpdateTick == 10) then
            FastUpdate = false
            unpdateTick = 0
        else
            FastUpdate = true
        end

        UpdateIdle(update)

        if not FastUpdate then
            for i=1, #UpdateList do
                local u = UpdateList[i]
                u.update = u.update + update
                if u.update > u.interval then
                    u.func(u.update)
                    u.update = 0
                end
            end
        end
        update = 0
    end
end
frame:SetScript("OnUpdate", OnUpdate)
------------------------------------------------------------------------------------------------------------------
function omacro(macro)
    if(IsRightControlKeyDown() == 1) then print('macro', macro) end
    oexecute("RunMacroText('"..macro.."')")
end
------------------------------------------------------------------------------------------------------------------