Config = {}

--[[
	Controls if the script will show the built in hud

	NOTE: This *can* be a bit more resource intensive 
	as it is drawing on the screen every tick so if you
	can it may be better to implement your own UI system
]]
Config["UseHUD"] = true

--[[
	A list of prop / object models that are treated
	as gas pumps
]]
Config["GasPumpModels"] = {
	"prop_gas_pump_1d",
	"prop_vintage_pump",
	"prop_gas_pump_old3",
	"prop_gas_pump_1b",
	"prop_gas_pump_old2",
	"prop_gas_pump_1a",
	"prop_gas_pump_1c",
}

--[[
	A list of vehicle model's which are considered 
	electric vehicles
]]
Config["ElectricVehicleModels"] = {
	"airtug",
	"caddy",
	"caddy2",
	"caddy3",
	"cyclone",
	"dilettan",
	"khamel",
	"neon",
	"raiden",
	"surge",
	"tezeract",
	"voltic"
}

--[[
	The base fuel economy for each vehicle class
	(except cycles, planes, helis and boats) 
	in L / 100km

	Class Numbers
	0 = Compacts
	1 = Sedans
	2 = SUVs
	3 = Coupes
	4 = Muscle
	5 = Sports Classics
	6 = Sports
	7 = Super
	8 = Motorcycles
	9 = Off-road
	10 = Industrial
	11 = Utility
	12 = Vans
	13 = Cycles
	14 = Boats
	15 = Helicopters
	16 = Planes
	17 = Service
	18 = Emergency
	19 = Military
	20 = Commercial
	21 = Trains
]]
Config["BaseFuelEconomy"] = {
	[0] = 7.0, -- Compacts
	[1] = 9.0, -- Sedans
	[2] = 11.0, -- SUVs
	[3] = 10.0, -- Coupes
	[4] = 13.0, -- Muscle
	[5] = 17.0, -- Sports Classics
	[6] = 13.0, -- Sports
	[7] = 19.6, -- Super
	[8] = 3.9, -- Motorcycles
	[9] = 13.0, -- Off-road
	[10] = 36.2, -- Industrial
	[11] = 19.6, -- Utility
	[12] = 15.7, -- Vans
	-- [13] = 0.00, -- Cycles
	-- [14] = 0.05, -- Boats
	-- [15] = 0.5, -- Helicopters
	-- [16] = 0.5, -- Planes
	[17] = 15.68, -- Service
	[18] = 10.0, -- Emergency
	[19] = 23.5, -- Military
	[20] = 19.6, -- Commercial
	-- [21] = 0.05, -- Trains
}

--[[
	Use this config section to specify a fuel economy
	in L/100km to use for a specific vehicle model instead
	of the value for the vehicle class from BaseFuelEconomy
]]
Config["OverrideBaseFuelEconomy"] = {
	["airtug"] = 0,
}

--[[
	The volume of air that the engine consumes in a single revolution is known as 
	displacement. To understand how this affects fuel economy, just picture an 
	engine throttling along. The more air that needs to be pushed while the engine 
	is in movement, the more energy the engine requires.

	TLDR: A factor to detemine the idle fuel consumption

	See BaseFuelEconomy for class numbers
]]
Config["EngineDisplacement"] = {
	[0] = 1.5, -- Compacts
	[1] = 3.0, -- Sedans
	[2] = 3.5, -- SUVs
	[3] = 3.5, -- Coupes
	[4] = 5.0, -- Muscle
	[5] = 3.5, -- Sports Classics
	[6] = 3.9, -- Sports
	[7] = 6.5, -- Super
	[8] = 0.6, -- Motorcycles
	[9] = 1.5, -- Off-road
	[10] = 13.0, -- Industrial
	[11] = 6.0, -- Utility
	[12] = 5.4, -- Vans
	-- [13] = 0.00, -- Cycles
	-- [14] = 0.05, -- Boats
	-- [15] = 0.5, -- Helicopters
	-- [16] = 0.5, -- Planes
	[17] = 5.4, -- Service
	[18] = 3.5, -- Emergency
	[19] = 6.5, -- Military
	[20] = 6.0, -- Commercial
	-- [21] = 0.00, -- Trains
}

--[[
	Override EngineDisplacement for a specified vehicle model
]]
Config["OverrideEngineDisplacement"] = {
	["airtug"] = 0,
}
