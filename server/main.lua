AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    -- Datenbank initialisieren
    DatabaseHandler.Init()
    
    -- Mailboxen laden und an alle Clients senden
    local mailboxes = DatabaseHandler.GetAllMailboxes()
    TriggerClientEvent('postal_system:loadMailboxes', -1, mailboxes)
    
    print('[^2INFO^7] Postal System: Resource gestartet')
end)

-- Spieler verbindet sich
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    -- Mailboxen an den verbundenen Spieler senden
    local mailboxes = DatabaseHandler.GetAllMailboxes()
    TriggerClientEvent('postal_system:loadMailboxes', xPlayer.source, mailboxes)
end)

-- Account erstellen
RegisterNetEvent('postal_system:createAccount')
AddEventHandler('postal_system:createAccount', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    -- Prüfen, ob der Spieler bereits ein Konto hat
    local existingAccount = DatabaseHandler.GetAccount(xPlayer.identifier)
    if existingAccount then
        TriggerClientEvent('esx:showNotification', src, _U('account_exists'))
        return
    end
    
    -- Neues Konto erstellen
    local id, address = DatabaseHandler.CreateAccount(xPlayer.identifier)
    TriggerClientEvent('esx:showNotification', src, _U('account_created', address))
    TriggerClientEvent('postal_system:accountCreated', src, {id = id, address = address})
end)

-- Mails des Spielers laden
RegisterNetEvent('postal_system:loadMails')
AddEventHandler('postal_system:loadMails', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    -- Prüfen, ob der Spieler ein Konto hat
    local account = DatabaseHandler.GetAccount(xPlayer.identifier)
    if not account then
        TriggerClientEvent('esx:showNotification', src, _U('no_account'))
        return
    end
    
    -- Mails laden
    local mails = DatabaseHandler.GetMails(account.id)
    TriggerClientEvent('postal_system:loadMailsResponse', src, mails)
end)

-- Brief senden
RegisterNetEvent('postal_system:sendLetter')
AddEventHandler('postal_system:sendLetter', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    -- Prüfen, ob der Spieler ein Konto hat
    local senderAccount = DatabaseHandler.GetAccount(xPlayer.identifier)
    if not senderAccount then
        TriggerClientEvent('esx:showNotification', src, _U('no_account'))
        return
    end
    
    -- Empfänger prüfen
    local recipientAccount = DatabaseHandler.GetAccountByAddress(data.recipient)
    if not recipientAccount then
        TriggerClientEvent('esx:showNotification', src, _U('invalid_recipient'))
        return
    end
    
    -- Kosten prüfen
    local cost = Config.Costs.LetterDelivery
    if xPlayer.getMoney() < cost then
        TriggerClientEvent('esx:showNotification', src, _U('not_enough_money'))
        return
    end
    
    -- Geld abziehen
    xPlayer.removeMoney(cost)
    
    -- Brief in Datenbank speichern
    local mailData = {
        sender_id = senderAccount.id,
        recipient_id = recipientAccount.id,
        type = 'letter',
        subject = data.subject,
        content = data.content,
        items = nil
    }
    
    local mailId = DatabaseHandler.CreateMail(mailData)
    
    -- Brief nach einiger Zeit zustellen
    SetTimeout(Config.DeliveryTime.Letters * 60 * 1000, function()
        DatabaseHandler.MarkAsDelivered(mailId)
        
        -- Empfänger benachrichtigen, wenn online
        local xTarget = ESX.GetPlayerFromIdentifier(recipientAccount.identifier)
        if xTarget then
            TriggerClientEvent('esx:showNotification', xTarget.source, _U('letter_received'))
            TriggerClientEvent('postal_system:mailReceived', xTarget.source)
        end
    end)
    
    TriggerClientEvent('esx:showNotification', src, _U('mail_sent'))
end)

-- Paket senden
RegisterNetEvent('postal_system:sendPackage')
AddEventHandler('postal_system:sendPackage', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    -- Prüfen, ob der Spieler ein Konto hat
    local senderAccount = DatabaseHandler.GetAccount(xPlayer.identifier)
    if not senderAccount then
        TriggerClientEvent('esx:showNotification', src, _U('no_account'))
        return
    end
    
    -- Empfänger prüfen
    local recipientAccount = DatabaseHandler.GetAccountByAddress(data.recipient)
    if not recipientAccount then
        TriggerClientEvent('esx:showNotification', src, _U('invalid_recipient'))
        return
    end
    
    -- Items prüfen
    local items = json.decode(data.items)
    if #items > Config.MaxItemsPerPackage then
        TriggerClientEvent('esx:showNotification', src, _U('too_many_items'))
        return
    end
    
    -- Gewicht und Vorhandensein der Items prüfen
    local totalWeight = 0
    for _, item in ipairs(items) do
        local esxItem = xPlayer.getInventoryItem(item.name)
        if not esxItem or esxItem.count < item.count then
            TriggerClientEvent('esx:showNotification', src, 'Nicht genug ' .. item.label)
            return
        end
        
        -- Gewicht pro Item berechnen (falls ESX Gewichtssystem verwendet wird)
        if esxItem.weight then
            totalWeight = totalWeight + (esxItem.weight * item.count)
        end
    end
    
    if totalWeight > Config.MaxPackageWeight then
        TriggerClientEvent('esx:showNotification', src, _U('package_too_heavy'))
        return
    end
    
    -- Kosten berechnen
    local cost = Config.Costs.PackageBaseCost + (totalWeight * Config.Costs.WeightMultiplier)
    if xPlayer.getMoney() < cost then
        TriggerClientEvent('esx:showNotification', src, _U('not_enough_money'))
        return
    end
    
    -- Geld abziehen
    xPlayer.removeMoney(cost)
    
    -- Items vom Sender entfernen
    for _, item in ipairs(items) do
        xPlayer.removeInventoryItem(item.name, item.count)
    end
    
    -- Paket in Datenbank speichern
    local mailData = {
        sender_id = senderAccount.id,
        recipient_id = recipientAccount.id,
        type = 'package',
        subject = data.subject,
        content = data.content,
        items = data.items
    }
    
    local mailId = DatabaseHandler.CreateMail(mailData)
    
    -- Paket nach einiger Zeit zustellen
    SetTimeout(Config.DeliveryTime.Packages * 60 * 1000, function()
        DatabaseHandler.MarkAsDelivered(mailId)
        
        -- Empfänger benachrichtigen, wenn online
        local xTarget = ESX.GetPlayerFromIdentifier(recipientAccount.identifier)
        if xTarget then
            TriggerClientEvent('esx:showNotification', xTarget.source, _U('package_received'))
            TriggerClientEvent('postal_system:mailReceived', xTarget.source)
        end
    end)
    
    TriggerClientEvent('esx:showNotification', src, _U('mail_sent'))
end)

-- Mail abholen (nur für Pakete)
RegisterNetEvent('postal_system:collectMail')
AddEventHandler('postal_system:collectMail', function(mailId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    -- Mail-Daten abrufen
    local mail = DatabaseHandler.GetMailById(mailId)
    if not mail or mail.collected then
        return
    end
    
    -- Prüfen, ob der Spieler der Empfänger ist
    local account = DatabaseHandler.GetAccount(xPlayer.identifier)
    if not account or account.id ~= mail.recipient_id then
        return
    end
    
    -- Wenn es ein Brief ist, einfach als abgeholt markieren
    if mail.type == 'letter' then
        DatabaseHandler.MarkAsCollected(mailId)
        TriggerClientEvent('postal_system:mailCollected', src, mailId)
        return
    end
    
    -- Bei Paketen: Items dem Spieler geben
    if mail.type == 'package' and mail.items then
        local items = json.decode(mail.items)
        
        -- Prüfen, ob der Spieler genug Platz hat
        local canCarry = true
        for _, item in ipairs(items) do
            if not xPlayer.canCarryItem(item.name, item.count) then
                canCarry = false
                break
            end
        end
        
        if not canCarry then
            TriggerClientEvent('esx:showNotification', src, _U('cannot_carry'))
            return
        end
        
        -- Items dem Spieler geben
        for _, item in ipairs(items) do
            xPlayer.addInventoryItem(item.name, item.count)
        end
        
        -- Paket als abgeholt markieren
        DatabaseHandler.MarkAsCollected(mailId)
        TriggerClientEvent('postal_system:mailCollected', src, mailId)
        TriggerClientEvent('esx:showNotification', src, _U('package_delivered'))
    end
end)