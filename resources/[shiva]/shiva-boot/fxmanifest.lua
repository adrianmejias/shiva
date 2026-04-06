fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'shiva-boot'
description 'Shiva Boot — triggers the shiva-core boot pipeline'
author      'Shiva Framework'
version     '1.0.0'

-- Must be the LAST resource ensured in server.cfg.
-- By the time this starts, all [shiva-modules] and
-- [shiva-overrides] resources are already running.
dependencies {
    'shiva-core',
}

server_scripts {
    'sv_trigger.lua',
}
