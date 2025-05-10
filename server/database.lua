DatabaseHandler = {}

-- Tabellen beim Serverstart erstellen
DatabaseHandler.Init = function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `postal_mailboxes` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `x` FLOAT NOT NULL,
            `y` FLOAT NOT NULL,
            `z` FLOAT NOT NULL,
            `heading` FLOAT NOT NULL,
            `model` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `postal_accounts` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(50) NOT NULL,
            `address` VARCHAR(20) NOT NULL UNIQUE,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `identifier_idx` (`identifier`)
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `postal_mails` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `sender_id` INT NOT NULL,
            `recipient_id` INT NOT NULL,
            `type` ENUM('letter', 'package') NOT NULL,
            `subject` VARCHAR(100) NOT NULL,
            `content` TEXT,
            `items` LONGTEXT,
            `sent_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `delivered` BOOLEAN DEFAULT FALSE,
            `collected` BOOLEAN DEFAULT FALSE,
            INDEX `sender_idx` (`sender_id`),
            INDEX `recipient_idx` (`recipient_id`),
            FOREIGN KEY (`sender_id`) REFERENCES `postal_accounts`(`id`) ON DELETE CASCADE,
            FOREIGN KEY (`recipient_id`) REFERENCES `postal_accounts`(`id`) ON DELETE CASCADE
        )
    ]])

    print('[^2INFO^7] Postal System: Datenbanktabellen wurden initialisiert')
end

-- Mailbox-Funktionen
DatabaseHandler.GetAllMailboxes = function()
    local result = MySQL.query.await('SELECT * FROM postal_mailboxes')
    return result
end

DatabaseHandler.CreateMailbox = function(x, y, z, heading, model)
    return MySQL.insert.await('INSERT INTO postal_mailboxes (x, y, z, heading, model) VALUES (?, ?, ?, ?, ?)', {
        x, y, z, heading, model
    })
end

DatabaseHandler.DeleteMailbox = function(id)
    return MySQL.query.await('DELETE FROM postal_mailboxes WHERE id = ?', {id})
end

DatabaseHandler.GetNearbyMailbox = function(x, y, z, distance)
    local result = MySQL.query.await([[
        SELECT *, SQRT(POW(x - ?, 2) + POW(y - ?, 2) + POW(z - ?, 2)) AS distance 
        FROM postal_mailboxes 
        HAVING distance < ? 
        ORDER BY distance 
        LIMIT 1
    ]], {x, y, z, distance})
    
    if result and #result > 0 then
        return result[1]
    end
    return nil
end

-- Account-Funktionen
DatabaseHandler.CreateAccount = function(identifier)
    local address
    local unique = false
    
    -- Eindeutige Adresse generieren
    while not unique do
        local number = math.random(10^(Config.Account.PrefixLength-1), 10^Config.Account.PrefixLength-1)
        address = string.format(Config.Account.AddressFormat, number)
        
        local exists = MySQL.scalar.await('SELECT COUNT(*) FROM postal_accounts WHERE address = ?', {address})
        if exists == 0 then
            unique = true
        end
    end
    
    local id = MySQL.insert.await('INSERT INTO postal_accounts (identifier, address) VALUES (?, ?)', {
        identifier, address
    })
    
    return id, address
end

DatabaseHandler.GetAccount = function(identifier)
    local result = MySQL.query.await('SELECT * FROM postal_accounts WHERE identifier = ? LIMIT 1', {identifier})
    if result and #result > 0 then
        return result[1]
    end
    return nil
end

DatabaseHandler.GetAccountByAddress = function(address)
    local result = MySQL.query.await('SELECT * FROM postal_accounts WHERE address = ? LIMIT 1', {address})
    if result and #result > 0 then
        return result[1]
    end
    return nil
end

-- Mail-Funktionen
DatabaseHandler.CreateMail = function(data)
    return MySQL.insert.await([[
        INSERT INTO postal_mails 
        (sender_id, recipient_id, type, subject, content, items) 
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        data.sender_id,
        data.recipient_id,
        data.type,
        data.subject,
        data.content,
        data.items
    })
end

DatabaseHandler.GetMails = function(accountId)
    return MySQL.query.await([[
        SELECT m.*, 
               s.address AS sender_address, 
               r.address AS recipient_address,
               r.identifier AS recipient_identifier
        FROM postal_mails m
        JOIN postal_accounts s ON m.sender_id = s.id
        JOIN postal_accounts r ON m.recipient_id = r.id
        WHERE m.recipient_id = ? AND m.collected = 0
        ORDER BY m.sent_at DESC
    ]], {accountId})
end

DatabaseHandler.MarkAsDelivered = function(mailId)
    return MySQL.query.await('UPDATE postal_mails SET delivered = 1 WHERE id = ?', {mailId})
end

DatabaseHandler.MarkAsCollected = function(mailId)
    return MySQL.query.await('UPDATE postal_mails SET collected = 1 WHERE id = ?', {mailId})
end

DatabaseHandler.GetMailById = function(mailId)
    local result = MySQL.query.await([[
        SELECT m.*, 
               s.address AS sender_address, 
               r.address AS recipient_address,
               r.identifier AS recipient_identifier
        FROM postal_mails m
        JOIN postal_accounts s ON m.sender_id = s.id
        JOIN postal_accounts r ON m.recipient_id = r.id
        WHERE m.id = ?
        LIMIT 1
    ]], {mailId})
    
    if result and #result > 0 then
        return result[1]
    end
    return nil
end