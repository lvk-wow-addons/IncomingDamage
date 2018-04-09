function IncomingDamage_ChatPrint(str)
	DEFAULT_CHAT_FRAME:AddMessage("[MyMount] "..str, 0.25, 1.0, 0.25)
end

function IncomingDamage_ErrorPrint(str)
	DEFAULT_CHAT_FRAME:AddMessage("[MyMount] "..str, 1.0, 0.5, 0.5)
end

function IncomingDamage_DebugPrint(str)
	DEFAULT_CHAT_FRAME:AddMessage("[MyMount] "..str, 0.75, 1.0, 0.25)
end

local stats = {
    totalMagicalDamage = 0,
    totalPhysicalDamage = 0,
    totalChaosDamage = 0,
    totalDamage = 0
}
local queue = {}
local frame = CreateFrame("FRAME", "IncomingDamageAddonFrame");
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
local function eventHandler(self, e, timestamp, subEvent, ...)
    function getDmgTypeId(schoolId)
        if schoolId == 1 then
            return 1   -- Physical
        elseif schoolId % 2 >= 1 then
            return 2 -- Chaos
        else
            return 3 -- Magic
        end
        return -schoolId
    end

    if select(6, ...) ~= UnitGUID("player") or not subEvent:find("_DAMAGE") or subEvent:find("ENVIRONMENTAL") then
        return false
    end

    local amountIndex = 10
    if subEvent:find("SPELL_") or subEvent:find("RANGE_") then
        amountIndex = amountIndex + 3
    end

    local dmgTime = GetTime()
    local dmgTypeId = getDmgTypeId(select(12, ...))
    local amount = select(amountIndex, ...)
    if not amount or type(amount) ~= "number" then
        return
    end

    IncomingDamage_AdjustDamage(dmgTypeId, amount)

    table.insert(queue, {dmgTime, dmgTypeId, amount})

    return false
end
frame:SetScript("OnEvent", eventHandler);

function IncomingDamage_TotalMagicalDamage()
    IncomingDamage_CleanupQueue()
    return stats.totalMagicalDamage
end

function IncomingDamage_TotalPhysicalDamage()
    IncomingDamage_CleanupQueue()
    return stats.totalPhysicalDamage
end

function IncomingDamage_TotalChaosDamage()
    IncomingDamage_CleanupQueue()
    return stats.totalChaosDamage
end

function IncomingDamage_TotalDamage()
    IncomingDamage_CleanupQueue()
    return stats.totalDamage
end

function IncomingDamage_CleanupQueue()
    local cutoff = GetTime() - 5
    while queue[1] do
        if queue[1][1] < cutoff then
            local removed = table.remove(queue, 1)
            IncomingDamage_AdjustDamage(removed[2], -removed[3])
        else
            break
        end
    end
end

function IncomingDamage_AdjustDamage(dmgTypeId, amount)
    if dmgTypeId == 1 then
        stats.totalPhysicalDamage = stats.totalPhysicalDamage + amount
    elseif dmgTypeId == 2 then
        stats.totalChaosDamage = stats.totalChaosDamage + amount
    elseif dmgTypeId == 3 then
        stats.totalMagicalDamage = stats.totalMagicalDamage + amount
    end

    stats.totalDamage = stats.totalDamage + amount
end