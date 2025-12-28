
lua54 'yes'
fx_version 'cerulean'
game 'gta5'

author "stressy"
description 'Locker rental system'
shared_scripts {
  '@ox_lib/init.lua',
  '@qbx_core/modules/lib.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'bridge/sv_bridge.lua',
  'server/**',
}

client_scripts {
  'client/**',
  'bridge/cl_bridge.lua',
  '@qbx_core/modules/playerdata.lua',
}

files {
  'config/*.lua',
}
