local mailboxes = {}
local currentMailbox = nil

-- Mailboxen laden
RegisterNetEvent('postal_system:loadMailboxes')
AddEventHandler('postal_system:loadMailboxes', function(data)
    mailboxes = data
    
    -- Bestehende Blips entfernen
    for _, mailbox in pairs(mailboxes) do
        if mailbox.blip then
            RemoveBlip(mailbox.blip)
        end
    end
    
    -- Neue Blips erstellen
    for i, mailbox in ipairs(mailboxes) do
        CreateMailboxBlip(mailbox)
        CreateMailboxEntity(mailbox)
    end
end)

-- Neue Mailbox erstellen
RegisterNetEvent('postal_system:createMailbox')
AddEventHandler('postal_system:createMailbox', function(data)
    table.insert(mailboxes, data)
    CreateMailboxBlip(data)
    CreateMailboxEntity(data)
end)

-- Mailbox entfernen
RegisterNetEvent('postal_system:removeMailbox')
AddEventHandler('postal_system:removeMailbox', function(id)
    for i, mailbox in ipairs(mailboxes) do
        if mailbox.id == id then
            if mailbox.blip then
                RemoveBlip(mailbox.blip)
            end
            
            if mailbox.entity and DoesEntityExist(mailbox.entity) then
                DeleteEntity(mailbox.entity)
            end
            
            table.remove(mailboxes, i)
            break
        end
    end
end)

-- Blip für Mailbox erstellen
function CreateMailboxBlip(mailbox)
    local blip = AddBlipForCoord(mailbox.x, mailbox.y, mailbox.z)
    SetBlipSprite(blip, Config.MailboxBlip.Sprite)
    SetBlipColour(blip, Config.MailboxBlip.Color)
    SetBlipScale(blip, Config.MailboxBlip.Scale)
    SetBlipAsShortRange(blip, Config.MailboxBlip.ShortRange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(_U('mail_blip'))
    EndTextCommandSetBlipName(blip)
    
    mailbox.blip = blip
end

-- Mailbox-Entity erstellen
function CreateMailboxEntity(mailbox)
    -- Model laden
    local model = GetHashKey(mailbox.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    -- Entity erstellen
    local entity = CreateObject(model, mailbox.x, mailbox.y, mailbox.z - 1.0, false, false, false)
    SetEntityHeading(entity, mailbox.heading)
    FreezeEntityPosition(entity, true)
    SetEntityAsMissionEntity(entity, true, true)
    
    mailbox.entity = entity
    
    -- Model freigeben
    SetModelAsNoLongerNeeded(model)
end

-- Mailbox-Interaktionsschleife
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local nearestMailbox = nil
        local minDist = Config.InteractionDistance + 1.0
        
        for _, mailbox in pairs(mailboxes) do
            local dist = #(coords - vector3(mailbox.x, mailbox.y, mailbox.z))
            if dist < minDist then
                nearestMailbox = mailbox
                minDist = dist
            end
        end
        
        if nearestMailbox and minDist <= Config.InteractionDistance then
            currentMailbox = nearestMailbox
            
            -- Wenn kein Target-System verwendet wird
            if not Config.UseTarget then
                ESX.ShowHelpNotification(_U('press_to_open'))
                
                if IsControlJustReleased(0, 38) then -- E Taste
                    OpenMailboxMenu()
                end
            end
        else
            currentMailbox = nil
            Citizen.Wait(500)
        end
    end
end)

-- Target-System Unterstützung
if Config.UseTarget then
    Citizen.CreateThread(function()
        Wait(1000) -- Warten, bis Entities geladen sind
        
        for _, mailbox in pairs(mailboxes) do
            if mailbox.entity and DoesEntityExist(mailbox.entity) then
                exports.qtarget:AddTargetEntity(mailbox.entity, {
                    options = {
                        {
                            icon = "fas fa-envelope",
                            label = _U('mail_blip'),
                            action = function()
                                OpenMailboxMenu()
                            end
                        }
                    },
                    distance = Config.InteractionDistance
                })
            end
        end
    end)
end

-- Mailbox-Menü öffnen
function OpenMailboxMenu()
    ESX.TriggerServerCallback('postal_system:getPlayerAccount', function(account)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            account = account
        })
    end)
end