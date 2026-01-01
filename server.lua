local ESX = exports['es_extended']:getSharedObject()

local AllowedGroups = Config.AllowedGroups

local function getLevelData(xPlayer)
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

local function saveLevelData(xPlayer, data)
    xPlayer.setMeta('levelsystem', data)
end

local function addXP(xPlayer, amount)
    local data = getLevelData(xPlayer)

    data.xp = data.xp + amount

    local needed = Config.RequiredXP(data.level)

    while data.xp >= needed do
        data.xp = data.xp - needed
        data.level = data.level + 1
        needed = Config.RequiredXP(data.level)

        TriggerEvent('levelsystem:levelUp', xPlayer.source, data.level)
    end

    saveLevelData(xPlayer, data)
end

AddEventHandler('levelsystem:levelUp', function(id, newLevel)
    TriggerClientEvent("esx:showNotification", id,("Glückwunsch! Neues Level: ~g~%s"):format(newLevel), "info", 5000, "Levelsystem")
    local reward = Config.Rewards[math.random(#Config.Rewards)]
    local xPlayer = ESX.GetPlayerFromId(id)
    if reward.type == "cash" then
        xPlayer.addMoney(reward.amount)
    elseif reward.type == 'item' then
        xPlayer.addInventoryItem(reward.name, 1)
    end
end)

AddEventHandler('levelsystem:addXP', function(id, amount)
    local xPlayer = ESX.GetPlayerFromId(id)
    if not xPlayer then return end

    addXP(xPlayer, amount)
end)

ESX.RegisterServerCallback('levelsystem:getData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    cb(getLevelData(xPlayer))
end)

RegisterCommand('resetlevel', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.group
    local target = tonumber(args[1]) or source
    if not AllowedGroups[group] then
        TriggerClientEvent("esx:showNotification", source, "Du hast keine Berechtigung um diesen Command auszuführen", "error", 1500, "Levelsystem")
        return
    end
    local xTarget = ESX.GetPlayerFromId(target)
    local data = {
        level = 1,
        xp = 0
    }
    saveLevelData(xTarget, data)
    TriggerClientEvent("esx:showNotification", source, "Das Level und die XP des Spielers wurden Erfolgreich zurückgesetzt", "success", 5000, "Levelsystem")
    TriggerClientEvent("esx:showNotification", target, "Dein Level und deine XP wurden zurückgesetzt", "info", 5000, "Levelsystem")
end)


RegisterCommand('setlevel', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.group
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
    local xTarget = ESX.GetPlayerFromId(target)
    local data = {
        level = level,
        xp = 0
    }
    saveLevelData(xTarget, data)
    TriggerClientEvent("esx:showNotification", source, "Das Level Spielers wurde Erfolgreich zurückgesetzt", "success", 5000, "Levelsystem")
    TriggerClientEvent("esx:showNotification", target, ("Dein Level wurde von einem Admin geändert. Dein neues Level: ~g~%s"):format(level), "info", 5000, "Levelsystem")
end)

local lastReward = {}
local tries = {}

RegisterNetEvent('levelsystem:heartbeat', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local now = os.time()
    lastReward[src] = lastReward[src] or (now - Config.Playtime)
    tries[src] = tries[src] or 0

    if lastReward[src] and now - lastReward[src] < Config.Playtime then
        tries[src] = tries[src] + 1
        if tries[src] >= 3 then
            DropPlayer(src, "Cheater erkannt")
            return
        end
        return
    end

    lastReward[src] = now
    tries[src] = 0

    TriggerEvent('levelsystem:addXP', src, Config.XP.playtime)
end)