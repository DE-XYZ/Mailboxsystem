-- UI schließen
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- Konto erstellen
RegisterNUICallback('createAccount', function(data, cb)
    TriggerServerEvent('postal_system:createAccount')
    cb({})
end)

-- Mails laden
RegisterNUICallback('loadMails', function(data, cb)
    ESX.TriggerServerCallback('postal_system:getPlayerMails', function(mails)
        cb({
            mails = mails
        })
    end)
end)

-- Brief senden
RegisterNUICallback('sendLetter', function(data, cb)
    TriggerServerEvent('postal_system:sendLetter', data)
    cb({})
end)

-- Paket senden
RegisterNUICallback('sendPackage', function(data, cb)
    TriggerServerEvent('postal_system:sendPackage', data)
    cb({})
end)

-- Inventar für Paketversand laden
RegisterNUICallback('getInventory', function(data, cb)
    ESX.TriggerServerCallback('postal_system:getPlayerInventory', function(inventory)
        cb({
            inventory = inventory
        })
    end)
end)

-- Mail sammeln/abholen
RegisterNUICallback('collectMail', function(data, cb)
    TriggerServerEvent('postal_system:collectMail', data.id)
    cb({})
end)

-- Wenn eine Mail abgeholt wurde
RegisterNetEvent('postal_system:mailCollected')
AddEventHandler('postal_system:mailCollected', function(mailId)
    SendNUIMessage({
        action = 'mailCollected',
        id = mailId
    })
end)

-- Wenn eine neue Mail empfangen wurde
RegisterNetEvent('postal_system:mailReceived')
AddEventHandler('postal_system:mailReceived', function()
    SendNUIMessage({
        action = 'mailReceived'
    })
end)

-- Konto erstellt
RegisterNetEvent('postal_system:accountCreated')
AddEventHandler('postal_system:accountCreated', function(accountData)
    SendNUIMessage({
        action = 'accountCreated',
        account = accountData
    })
end)