Config = {}

-- Allgemeine Einstellungen
Config.Locale = 'de'                     -- Sprache (de/en)
Config.UseTarget = true                  -- ox_target/qtarget Unterstützung (wenn false, wird ein 3D-Text verwendet)
Config.InteractionDistance = 2.0         -- Maximale Distanz für Interaktionen
Config.CommandPermission = 'admin'       -- Benötigte Berechtigung für Admin-Befehle
Config.MailboxModel = 'prop_postbox_01a' -- Standardmodell für Mailboxen
Config.MaxPackageWeight = 10.0           -- Maximales Gewicht für Pakete in kg
Config.MaxItemsPerPackage = 5            -- Maximale Anzahl verschiedener Items pro Paket
Config.MailboxBlip = {
    Sprite = 478,                        -- Sprite für Mailbox-Blip
    Color = 4,                           -- Farbe für Mailbox-Blip
    Scale = 0.8,                         -- Größe des Blips
    Display = 4,                         -- Anzeigetyp (4 = nur auf Minimap)
    ShortRange = true                    -- Nur in kurzer Distanz anzeigen
}

-- Benachrichtigungen
Config.Notifications = {
    UseESX = true,                       -- ESX-Benachrichtigungen verwenden (wenn false, wird natives FiveM verwendet)
    Duration = 5000                      -- Dauer der Benachrichtigung in ms
}

-- Kosten
Config.Costs = {
    LetterDelivery = 50,                 -- Kosten für einen Briefversand
    PackageBaseCost = 100,               -- Basiskosten für ein Paket
    WeightMultiplier = 10                -- Zusätzliche Kosten pro kg Gewicht
}

-- Zeiteinstellungen
Config.DeliveryTime = {
    Letters = 5,                         -- Lieferzeit für Briefe in Minuten
    Packages = 10                        -- Lieferzeit für Pakete in Minuten
}

-- Item-Definitionen für Briefe (müssen in items.lua des Servers existieren oder erstellt werden)
Config.Items = {
    Letter = 'letter',                   -- Item für Briefe
    Package = 'package'                  -- Item für Pakete
}

-- Account-Einstellungen
Config.Account = {
    AddressFormat = 'PS-%d',             -- Format für Post-Adressen (PS-1234)
    PrefixLength = 4                     -- Länge des numerischen Teils der Adresse
}