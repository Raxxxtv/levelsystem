local ESX = exports['es_extended']:getSharedObject()

local AllowedGroups = Config.AllowedGroups
local Debug = {}

local function GetToday()
    local date = os.date('*t')
    return string.format('%04d-%02d-%02d', date.year, date.month, date.day)
end

local function GetLevelData(xPlayer)
    local data = xPlayer.getMeta('levelsystem')

    if not data then
        data = {
            level = 1,
            xp = 0
        }
        xPlayer.setMeta('levelsystem', data)
    end

    return data
end

local function GetPlayerMultiplier(xPlayer)
    return Config.JobXP[xPlayer.job.name] or 1.0
end

local function SaveLevelData(xPlayer, data)
    xPlayer.setMeta('levelsystem', data)
end

local function AddXP(xPlayer, amount)
    local data = GetLevelData(xPlayer)

    data.xp = data.xp + amount

    local needed = Config.RequiredXP(data.level)

    while data.xp >= needed do
        data.xp = data.xp - needed
        data.level = data.level + 1
        needed = Config.RequiredXP(data.level)

        TriggerEvent('levelsystem:LevelUp', xPlayer.source, data.level)
    end

    SaveLevelData(xPlayer, data)
end

AddEventHandler('levelsystem:LevelUp', function(id, newLevel)
    TriggerClientEvent("esx:showNotification", id,("Glückwunsch! Neues Level: ~g~%s"):format(newLevel), "info", 5000, "Levelsystem")
    local reward = Config.Rewards[math.random(#Config.Rewards)]
    local xPlayer = ESX.GetPlayerFromId(id)
    if reward.type == "cash" then
        xPlayer.addMoney(reward.amount)
    elseif reward.type == 'item' then
        xPlayer.addInventoryItem(reward.name, 1)
    end
end)

AddEventHandler('levelsystem:AddXP', function(id, amount)
    local xPlayer = ESX.GetPlayerFromId(id)
    if not xPlayer then return end
    local xp = math.floor(amount * GetPlayerMultiplier(xPlayer))
    AddXP(xPlayer, xp)
end)

ESX.RegisterServerCallback('levelsystem:GetData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    cb(GetLevelData(xPlayer))
end)

RegisterCommand('resetlevel', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    local target = tonumber(args[1]) or source
    if not AllowedGroups[group] then
        TriggerClientEvent("esx:showNotification", source, "Du hast keine Berechtigung um diesen Command auszuführen", "error", 1500, "Levelsystem")
        return
    end
    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then
        TriggerClientEvent("esx:showNotification", source, "Spieler nicht gefunden", "error", 5000, "Levelsystem")
        return
    end
    local data = {
        level = 1,
        xp = 0
    }
    SaveLevelData(xTarget, data)
    TriggerClientEvent("esx:showNotification", source, "Das Level und die XP des Spielers wurden Erfolgreich zurückgesetzt", "success", 5000, "Levelsystem")
    TriggerClientEvent("esx:showNotification", target, "Dein Level und deine XP wurden zurückgesetzt", "info", 5000, "Levelsystem")
end)

local function GiveDailyXP(xPlayer)
    local meta = GetLevelData(xPlayer)
    meta.daily = meta.daily or {}

    local today = GetToday()

    local XP = math.random(Config.DailyXP.min, Config.DailyXP.max)

    if meta.daily.last == today and not Debug[xPlayer.source] then
        return false, "claimed"
    end

    local now = os.time()

    if not meta.JoinTime or (now - meta.JoinTime) < Config.TimeTillDaily then
        local remaining = Config.TimeTillDaily - (now - (meta.JoinTime or now))
        return false, "time", remaining
    end
    
    meta.daily.last = today
    SaveLevelData(xPlayer, meta)
    TriggerEvent('levelsystem:AddXP', xPlayer.source, XP)

    return true, "Success", XP
end

RegisterCommand('daily', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local GiveXP, Reason, Data = GiveDailyXP(xPlayer)

    if GiveXP then
        TriggerClientEvent("esx:showNotification", source, ("Du hast deine DailyXP erhalten ~g~(%s)"):format(Data), "success", 5000, "Levelsystem")
    elseif Reason == "claimed" then
        TriggerClientEvent("esx:showNotification", source, "Du hast deine DailyXP heute schon eingelöst", "error", 5000, "Levelsystem")
    elseif Reason == "time" then
        local minutes = math.ceil(Data / 60)
        TriggerClientEvent("esx:showNotification", source, ("Du kannst deine DailyXP erst in in ~g~%s Minuten~s~ abholen"):format(minutes), "error", 5000, "Levelsystem")
    end
end)


RegisterCommand('setlevel', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    local target = tonumber(args[1]) or source
    local level = tonumber(args[2])
    if not AllowedGroups[group] then
        TriggerClientEvent("esx:showNotification", source, "Du hast keine Berechtigung um diesen Command auszuführen", "error", 1500, "Levelsystem")
        return
    end
    if not level then
        TriggerClientEvent("esx:showNotification", source, "Du musst ein gültiges Level angeben", "error", 1500, "Levelsystem")
        return
    end
    if level < 1 or level > 200 then
        TriggerClientEvent("esx:showNotification", source, "Du musst ein gültiges Level angeben (zwischen 1 und 200)", "error", 1500, "Levelsystem")
        return
    end
    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then
        TriggerClientEvent("esx:showNotification", source, "Spieler nicht gefunden", "error", 5000, "Levelsystem")
        return
    end
    local data = {
        level = level,
        xp = 0
    }
    SaveLevelData(xTarget, data)
    TriggerClientEvent("esx:showNotification", source, "Das Level Spielers wurde Erfolgreich zurückgesetzt", "success", 5000, "Levelsystem")
    TriggerClientEvent("esx:showNotification", target, ("Dein Level wurde von einem Admin geändert. Dein neues Level: ~g~%s"):format(level), "info", 5000, "Levelsystem")
end)

RegisterCommand("levelsystem_debug", function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    if not AllowedGroups[group] then
        TriggerClientEvent("esx:showNotification", source, "Du hast keine Berechtigung um diesen Command auszuführen", "error", 1500, "Levelsystem")
        return
    end
    if Debug[source] then
        Debug[source] = nil
    else
        Debug[source] = true
    end
end)

local StartedTimers = {}

function CreateXPTimer(source)
    StopXPTimer(source)

    StartedTimers[source] = ESX.SetTimeout(Config.Playtime * 1000, function()
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then 
            StopXPTimer(source)
            return 
        end
        TriggerEvent("levelsystem:AddXP", source, Config.XP.playtime)
        CreateXPTimer(source)
    end)
end

function StopXPTimer(source)
    if not StartedTimers[source] then return end
    ESX.ClearTimeout(StartedTimers[source])
    StartedTimers[source] = nil
end

AddEventHandler('esx:playerDropped', function (playerId)
    StopXPTimer(playerId)
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    CreateXPTimer(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end

    local meta = GetLevelData(xPlayer)
    meta.JoinTime = os.time()
    SaveLevelData(xPlayer, meta)
end)
