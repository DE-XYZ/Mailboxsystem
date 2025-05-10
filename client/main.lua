AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    -- ESX laden
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

-- Server-Callbacks

-- Spieler-Konto abrufen
ESX.RegisterServerCallback('postal_system:getPlayerAccount', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local account = DatabaseHandler.GetAccount(xPlayer.identifier)
    cb(account)
end)

-- Spieler-Mails abrufen
ESX.RegisterServerCallback('postal_system:getPlayerMails', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local account = DatabaseHandler.GetAccount(xPlayer.identifier)
    
    if not account then
        cb({})
        return
    end
    
    local mails = DatabaseHandler.GetMails(account.id)
    cb(mails)
end)

-- Spieler-Inventar abrufen
ESX.RegisterServerCallback('postal_system:getPlayerInventory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local items = xPlayer.getInventory()
    
    local filteredItems = {}
    for _, item in pairs(items) do
        if item.count > 0 then
            table.insert(filteredItems, {
                name = item.name,
                label = item.label,
                count = item.count,
                weight = item.weight or 0
            })
        end
    end
    
    cb(filteredItems)
end)