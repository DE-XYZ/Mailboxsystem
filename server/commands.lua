-- Mailbox platzieren
ESX.RegisterCommand('createmailbox', Config.CommandPermission, function(xPlayer, args, showError)
    local playerCoords = xPlayer.getCoords()
    local playerHeading = GetEntityHeading(GetPlayerPed(xPlayer.source))
    
    -- Prüfen, ob in der Nähe bereits eine Mailbox existiert
    local nearby = DatabaseHandler.GetNearbyMailbox(playerCoords.x, playerCoords.y, playerCoords.z, 5.0)
    if nearby then
        TriggerClientEvent('esx:showNotification', xPlayer.source, _U('mailbox_exists'))
        return
    end
    
    -- Mailbox-Modell aus Argumenten oder Standard verwenden
    local model = args.model or Config.MailboxModel
    
    -- Mailbox in Datenbank speichern
    local id = DatabaseHandler.CreateMailbox(playerCoords.x, playerCoords.y, playerCoords.z, playerHeading, model)
    
    -- Allen Spielern mitteilen, dass eine neue Mailbox erstellt wurde
    local mailboxData = {
        id = id,
        x = playerCoords.x,
        y = playerCoords.y,
        z = playerCoords.z,
        heading = playerHeading,
        model = model
    }
    
    TriggerClientEvent('postal_system:createMailbox', -1, mailboxData)
    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('mailbox_placed'))
    
end, false, {help = "Erstellt eine Mailbox an deiner Position", arguments = {
    {name = 'model', help = "Optionales Modell für die Mailbox", type = 'string'}
}})

-- Mailbox entfernen
ESX.RegisterCommand('removemailbox', Config.CommandPermission, function(xPlayer, args, showError)
    local playerCoords = xPlayer.getCoords()
    
    -- Finde die nächste Mailbox
    local nearby = DatabaseHandler.GetNearbyMailbox(playerCoords.x, playerCoords.y, playerCoords.z, 5.0)
    if not nearby then
        TriggerClientEvent('esx:showNotification', xPlayer.source, _U('no_nearby_mailbox'))
        return
    end
    
    -- Mailbox aus Datenbank entfernen
    DatabaseHandler.DeleteMailbox(nearby.id)
    
    -- Allen Spielern mitteilen, dass eine Mailbox entfernt wurde
    TriggerClientEvent('postal_system:removeMailbox', -1, nearby.id)
    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('mailbox_removed'))
    
end, false, {help = "Entfernt die nächste Mailbox"})