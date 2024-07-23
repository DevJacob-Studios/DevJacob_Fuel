WorldManager = {}

function WorldManager.GetClosestVehicle(coords, radius)
    radius = radius or 2.0
    local handle, coords = DevJacobLib.GetClosestVehicle(coords, radius, true)
    return handle
end

function WorldManager.GetClosestFuelPump(coords, radius)
    radius = radius or 0.7

    local entityHandle = 0
    local closestModel = nil

    -- Loop through all of the configured pump models until one is in the search radius
    for i = 1, #Config["GasPumpModels"] do
        local model = Config["GasPumpModels"][i]
        local modelHash = GetHashForModel(model)
        entityHandle = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius, model, true, true, true)
        if entityHandle ~= 0 then
            closestModel = model
            break
        end
    end

    -- Check if we found a pump
    if entityHandle == 0 or closestModel == nil then
        return nil
    end

    -- Check if we have cached the pump at the coords
    local pumpCoords = GetEntityCoords(entityHandle)
    if StorageManager.FuelPumps[pumpCoords] ~= nil then
        return StorageManager.FuelPumps[pumpCoords]
    end

    local newPump = FuelPump.new(closestModel, entityHandle)
    StorageManager.FuelPumps[pumpCoords] = newPump
    return newPump
end