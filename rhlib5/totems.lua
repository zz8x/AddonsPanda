-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function IsTotemPushedNow(i)
    local _, totemName, startTime, duration = GetTotemInfo(i)
    if totemName and startTime and (GetTime() - startTime < 5) then return true end
    return false
end
  
------------------------------------------------------------------------------------------------------------------
function HasTotem(name, last)
    --Где (1) Это Огненный, (2) = Земляной, (3) = Водный, (4) = Воздух
    if not last then last = 0.01 end
    
    local n = tonumber(name)
    if n ~= nil then
        local _, totemName, startTime, duration = GetTotemInfo(n)
        if totemName and startTime and (startTime+duration-GetTime() > last) then 
            return totemName 
        end
        return false
    end
    
    for index=1,4 do
        local _, totemName, startTime, duration = GetTotemInfo(index)
        if totemName 
            and strlower(totemName):match(strlower(name)) 
            and startTime 
            and (startTime+duration-GetTime() > last) then 
            return true 
        end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function TotemCount()
    local n = 0
    for index=1,4 do
        local _, totemName, startTime, duration = GetTotemInfo(index)
        if totemName and startTime and (startTime+duration-GetTime() > 0.01) then n = n + 1 end
    end
    return n
end