fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'shiva-db'
description 'Shiva DB — first-party MySQL/MariaDB runtime for Shiva'
author      'Shiva Framework'
version     '0.1.0'
repository  'https://github.com/adrianmejias/shiva-core'

server_only 'yes'

dependencies {
    '/server:7290',
}

server_script 'server.js'
