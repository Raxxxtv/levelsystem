Config = {}

Config.XP = {
    kill = 50,
    job = 25,
    playtime = 50
}

Config.Rewards = {
    {type = "cash", amount = 2500},
    {type = "item", name = "phone"},
    {type = "item", name = "radio"},
    {type = "item", name = "fixkit"}
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

Config.JobXP = {
    police = 1.5,
    ambulance = 1.3,
    mechanic = 1.2
}

Config.DailyXP = {
    min = 10,
    max = 5000
}