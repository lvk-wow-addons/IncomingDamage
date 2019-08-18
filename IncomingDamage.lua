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
local function eventHandler(self)
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

    local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, extraArg1, extraArg2, extraArg3, extraArg4, extraArg5, extraArg6, extraArg7, extraArg8, extraArg9, extraArg10 = CombatLogGetCurrentEventInfo()

    if destGUID ~= UnitGUID("player") or not subEvent:find("_DAMAGE") or subEvent:find("ENVIRONMENTAL") then
        return false
    end

    local amountIndex = 10

    local dmgTime = GetTime()
    local dmgTypeId = getDmgTypeId(extraArg3)
    local amount = 0
    if subEvent:find("SPELL_") or subEvent:find("RANGE_") then
        amount = extraArg1
    else
        amount = extraArg4
    end
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