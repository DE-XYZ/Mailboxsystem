-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'Claude'
description 'Ein Post- und Paketsystem für ESX FiveM-Server'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'locales/*.lua'
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/mailbox.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/commands.lua',
    'server/main.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/css/style.css',
    'ui/js/script.js',
    'ui/img/*.png'
}

dependencies {
    'es_extended',
    'oxmysql'
}