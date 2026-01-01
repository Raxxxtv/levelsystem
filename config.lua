Config = {}

Config.XP = {
    kill = 50,
    job = 25,
    playtime = 50
}

Config.Rewards = {
    {type = "cash", amount = 2500},
    {type = "item", name = "phone"},
    {type = "item", name = "radio"}
}

Config.Playtime = 10

Config.RequiredXP = function(level)
    return level * level * 100
end

Config.AllowedGroups = {
    admin = true,
    owner = true,
    mod = true
}