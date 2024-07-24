fx_version "cerulean"
lua54 "yes"
game "gta5"

author "DevJacob"
description "A simply modern fuel script for FiveM"
version "0.1.0"

ui_page "nui/index.html"

dependencies {
	"DevJacob_AudioManager",
	"DevJacob_CommonLib",
}

files {
	"nui/index.html",
	"nui/sounds/fuel_pump_click.mp3",
	"nui/sounds/fuel_pump_fill.mp3",
}

shared_scripts {
	"config.lua"
}

client_scripts {
	"@DevJacob_CommonLib/lib/client.lua",
	"@DevJacob_AudioManager/lib/client.lua",
	"client/managers/cacheManager.lua",
	"client/managers/storageManager.lua",
	"client/managers/worldManager.lua",
	"client/utils.lua",
	"client/models/fuelPump.lua",
	"client/models/nozzle.lua",
	"client/models/trackedVehicle.lua",
	"client/main.lua",
}