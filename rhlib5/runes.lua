-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function Runes(slot)
    local c = 0
    if slot == 1 then
       if IsRuneReady(1) then c = c + 1 end
       if IsRuneReady(2) then c = c + 1 end
    elseif slot == 2 then
        if IsRuneReady(5) then c = c + 1 end
        if IsRuneReady(6) then c = c + 1 end
    elseif slot == 3 then
        if IsRuneReady(3) then c = c + 1 end
        if IsRuneReady(4) then c = c + 1 end
    end
    return c;
end

------------------------------------------------------------------------------------------------------------------
function NoRunes(t)
    if (t == nil) then t = 1.6 end
    if GetRuneCooldownLeft(1) < t then return false end
    if GetRuneCooldownLeft(2) < t then return false end
    if GetRuneCooldownLeft(3) < t then return false end
    if GetRuneCooldownLeft(4) < t then return false end
    if GetRuneCooldownLeft(5) < t then return false end
    if GetRuneCooldownLeft(6) < t then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------
function IsRuneReady(id, time)
    if nil == time then time = 0 end
    local left = GetRuneCooldownLeft(id)
    if left - time > LagTime then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------
function GetRuneCooldownLeft(id)
    local start, duration = GetRuneCooldown(id);
    if not start then return 0 end
    if start == 0 then return 0 end
    local left = start + duration - GetTime()
    if left < 0 then left = 0 end
    return left
end

