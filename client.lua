TriggerEvent('chat:addSuggestion', '/resetlevel', 'Setzt das Level eines Spielers zurück', {
    { name="Spieler ID", help="Hier musst du die ID des Spielers angeben" }
})
TriggerEvent('chat:addSuggestion', '/setlevel', 'Setzt das Level eines Spielers', {
    { name="Spieler ID", help="Hier musst du die ID des Spielers angeben" },
    { name="Level", help="Hier musst du das Level angeben, welches du dem Spieler geben möchtest" }
})

RegisterCommand('level', function()
    ESX.TriggerServerCallback('levelsystem:GetData', function(data)
        if not data then return end

        local needed = Config.RequiredXP(data.level)
        ESX.ShowNotification(('Level: ~b~%s\nXP: ~y~%s~s~/~y~%s'):format(data.level, data.xp, needed), 'info', 5000, "Levelsystem")
    end)
end)