TriggerEvent('chat:addSuggestion', '/resetlevel', 'Setzt das Level eines Spielers zurück', {
    { name="Spieler ID", help="Hier musst du die ID des Spielers angeben" }
})
TriggerEvent('chat:addSuggestion', '/setlevel', 'Setzt das Level eines Spielers', {
    { name="Spieler ID", help="Hier musst du die ID des Spielers angeben" },
    { name="Level", help="Hier musst du das Level angeben, welches du dem Spieler geben möchtest" }
})

RegisterCommand('level', function()
    ESX.TriggerServerCallback('levelsystem:getData', function(data)
        if not data then return end

        local needed = data.level * data.level * 100
        ESX.ShowNotification(
            ('Level: ~b~%s\nXP: ~y~%s~s~/~y~%s')
            :format(data.level, data.xp, needed)
        )
    end)
end)

CreateThread(function()
    while true do
        Wait(Config.Playtime * 1000)
        TriggerServerEvent('levelsystem:heartbeat')
    end
end)