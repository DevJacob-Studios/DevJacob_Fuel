FuelPump = {}

function FuelPump.new(modelName, entityHandle)
    local self = {}

    self.modelName = modelName
    self.entityHandle = entityHandle
    self.position = GetEntityCoords(entityHandle, false)
    self.nozzle = nil

    local ropeOffset = StorageManager.PumpRopeOffsets[modelName] or vector3(0.0, 0.0, 1.5)
    self.ropePosition = vector3(self.position.x + ropeOffset.x, self.position.y + ropeOffset.y, self.position.z + ropeOffset.z)

    return self
end

function FuelPump.TryGrabNozzleAsync(fuelPump, pedHandle)
    local _promise = promise.new()

    local runFunc = function()
        fuelPump.nozzle = Nozzle.new(fuelPump)
        local result = Citizen.Await(Nozzle.TryGrabFromPumpAsync(fuelPump.nozzle, pedHandle))
        _promise:resolve(result)
    end

    runFunc()
    return _promise
end

function FuelPump.TryReturnNozzleAsync(fuelPump)
    local _promise = promise.new()

    local runFunc = function()
        local result = Citizen.Await(Nozzle.TryReturnToPumpAsync(fuelPump.nozzle))
        fuelPump.nozzle = nil
        _promise:resolve(result)
    end

    runFunc()
    return _promise
end
