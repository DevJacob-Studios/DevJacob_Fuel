TrackedVehicle = {}

function TrackedVehicle.new(entityHandle)
    local self = {}

    self.entityHandle = entityHandle
    self.distanceTravelledKm = 0.0
    self.fuelConsumed = 0.0
    self.lastCoords = vector3(0.0, 0.0, 0.0)

    return self
end

function TrackedVehicle.Reset(trackedVehicle, coords)
    trackedVehicle.distanceTravelledKm = 0.0
    trackedVehicle.fuelConsumed = 0.0
    trackedVehicle.lastCoords = coords
end

function TrackedVehicle.TryGrabNozzleAsync(fuelPump, pedHandle)
    local _promise = promise.new()

    local runFunc = function()
        fuelPump.nozzle = Nozzle.new(fuelPump)
        local result = Citizen.Await(Nozzle.TryGrabFromPumpAsync(fuelPump.nozzle, pedHandle))
        _promise:resolve(result)
    end

    runFunc()
    return _promise
end
