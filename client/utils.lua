function GetHashForModel(modelName)
    local modelHash = CacheManager.ModelHashes[modelName]
    if not modelHash then
        modelHash = joaat(modelName)
        CacheManager.ModelHashes[modelName] = modelHash
    end
    return modelHash
end

function GetBaseFuelEconomyForVeh(vehicleHandle)
    local vehModelHash = GetEntityModel(vehicleHandle)
    if CacheManager.OverrideBaseFuelEconomy[vehModelHash] ~= nil then
        return CacheManager.OverrideBaseFuelEconomy[vehModelHash]
    end

    local vehClass = GetVehicleClass(vehicleHandle)
    return Config["BaseFuelEconomy"][vehClass]
end

function GetDisplacementForVeh(vehicleHandle)
    local vehModelHash = GetEntityModel(vehicleHandle)
    if CacheManager.OverrideEngineDisplacement[vehModelHash] then
        return CacheManager.OverrideEngineDisplacement[vehModelHash]
    end

    local vehClass = GetVehicleClass(vehicleHandle)
    return Config["EngineDisplacement"][vehClass]
end

function LoadRopeTexturesAsync(timeout)
    timeout = timeout or 1000
    local _promise = promise.new()

    local runFunc = function()
        -- Check if the textures are loaded
        if not RopeAreTexturesLoaded(modelHash) then
            _promise:resolve(true)
        end

        -- Try to load the textures
        local timer = 0
        while not RopeAreTexturesLoaded(modelHash) and timer < timeout do
            RopeLoadTextures(modelHash)
            timer = timer + 1
            Citizen.Wait(1)
        end

        local result = RopeAreTexturesLoaded(modelHash)
        _promise:resolve(result == 1)
    end

    runFunc()
    return _promise
end

function RequestModelAsync(modelName, timeout)
    timeout = timeout or 1000
    local _promise = promise.new()

    local runFunc = function()
        -- Get the hash for the model
        local modelHash = GetHashForModel(modelName)
        
        -- Get the model validity state
        local modelValid = CacheManager.ValidModels[modelHash]
        if modelValid == nil then
            modelValid = IsModelValid(modelHash)
            CacheManager.ValidModels[modelHash] = modelValid
        end

        -- Check if the model is valid
        if not modelValid then
            _promise:resolve(false)
        end

        -- Check if the model is loaded
        if not HasModelLoaded(modelHash) then
            _promise:resolve(true)
        end

        -- Try to requets the model
        local timer = 0
        while not HasModelLoaded(modelHash) and timer < timeout do
            RequestModel(modelHash)
            timer = timer + 1
            Citizen.Wait(1)
        end

        local result = HasModelLoaded(modelHash)
        _promise:resolve(result == 1)
    end

    runFunc()
    return _promise
end

function RequestAnimDictAsync(animDict, timeout)
    timeout = timeout or 1000
    local _promise = promise.new()

    local runFunc = function()
        -- Get the anim dict validity state
        local animDictValid = CacheManager.ValidAnimDict[animDict]
        if animDictValid == nil then
            animDictValid = DoesAnimDictExist(animDict)
            CacheManager.ValidAnimDict[animDict] = animDictValid
        end

        -- Check if the anim dict is valid
        if not animDictValid then
            _promise:resolve(false)
        end

        -- Check if the anim dict is loaded
        if HasAnimDictLoaded(animDict) then
            _promise:resolve(true)
        end

        -- Try to requets the anim dict
        local timer = 0
        while not HasAnimDictLoaded(animDict) and timer < timeout do
            RequestAnimDict(animDict)
            timer = timer + 1
            Citizen.Wait(1)
        end

        local result = HasAnimDictLoaded(animDict)
        _promise:resolve(result == 1)
    end

    runFunc()
    return _promise
end

function IsVehicleElectric(vehicleHandle)
    DevJacobLib.Table.ArrayContainsValue(CacheManager.ElectricVehicleModels, GetEntityModel(vehicleHandle))
end

function DoesEntityHaveBone(entityHandle, boneName)
    return GetEntityBoneIndexByName(entityHandle, boneName) ~= -1
end

function TryGetTankPosition(vehicleHandle)
    local targetBone = nil
    local tankPosition = nil
    local nozzleOffset = vector3(0.0, 0.0, 0.0)
    local textOffset = vector3(0.0, 0.0, 0.0)

    local vehicleClass = GetVehicleClass(vehicleHandle)
    local isVehicleElectric = IsVehicleElectric(vehicleHandle)

    if vehicleClass == 8 and vehicleClass ~= 13 and not isVehicleElectric then
        
        if targetBone == nil then
            local boneIndex = GetEntityBoneIndexByName(vehicleHandle, "petrolcap")
            if boneIndex ~= -1 then
                targetBone = boneIndex
            end
        end
        
        if targetBone == nil then
            local boneIndex = GetEntityBoneIndexByName(vehicleHandle, "petroltank")
            if boneIndex ~= -1 then
                targetBone = boneIndex
            end
        end
        
        if targetBone == nil then
            local boneIndex = GetEntityBoneIndexByName(vehicleHandle, "engine")
            if boneIndex ~= -1 then
                targetBone = boneIndex
            end
        end
    
        if targetBone ~= nil then
            return true, targetBone, GetWorldPositionOfEntityBone(vehicleHandle, targetBone), nozzleOffset, textOffset
        end

    elseif vehicleClass ~= 13 and not isVehicleElectric then

        if targetBone == nil then
            local boneIndex = GetEntityBoneIndexByName(vehicleHandle, "petrolcap")
            if boneIndex ~= -1 then
                targetBone = boneIndex
            end
        end
        
        if targetBone == nil then
            local boneIndex = GetEntityBoneIndexByName(vehicleHandle, "petroltank_1")
            if boneIndex ~= -1 then
                targetBone = boneIndex
            end
        end
        
        if targetBone == nil then
            local boneIndex = GetEntityBoneIndexByName(vehicleHandle, "hub_lr")
            if boneIndex ~= -1 then
                targetBone = boneIndex
            end
        end
        
        if targetBone == nil then
            local boneIndex = GetEntityBoneIndexByName(vehicleHandle, "handle_dside_r")
            if boneIndex ~= -1 then
                targetBone = boneIndex
                nozzleOffset = vector3(0.1, -0.5, -0.6)
                textOffset = vector3(0.55, 0.1, -0.2)
            end
        end
    
        if targetBone ~= nil then
            return true, targetBone, GetWorldPositionOfEntityBone(vehicleHandle, targetBone), nozzleOffset, textOffset
        end

    end

    return false, nil, vector3(0.0, 0.0, 0.0), nozzleOffset, textOffset
end

function GetMaxFuelLiters(vehicleHandle)
    local maxFuel = GetVehicleHandlingFloat(vehicleHandle, "CHandlingData", "fPetrolTankVolume")
    return DevJacobLib.Ternary(maxFuel == 0, 65.0, maxFuel)
end

function SetFuelLiters(vehicleHandle, liters)
    local entity = Entity(vehicleHandle)
    local maxFuel = GetMaxFuelLiters(vehicleHandle)
    local groundedLevel = DevJacobLib.Ternary(liters > maxFuel, maxFuel, liters)
    entity.state["DevJacob:Fuel:VehicleFuelLevel"] = groundedLevel
    SetVehicleFuelLevel(vehicleHandle, groundedLevel)
end

function GetFuelLiters(vehicleHandle)
    local entity = Entity(vehicleHandle)
    local fuelBag = entity.state["DevJacob:Fuel:VehicleFuelLevel"]
    local entityFuelLevel = GetVehicleFuelLevel(vehicleHandle)
    local fuelLevel = DevJacobLib.Ternary(fuelBag ~= nil, fuelBag, entityFuelLevel)
    local maxFuel = GetMaxFuelLiters(vehicleHandle)
    local groundedLevel = DevJacobLib.Ternary(fuelLevel > maxFuel, maxFuel, fuelLevel)
    
    if fuelBag == nil then
        SetFuelLiters(vehicleHandle, groundedLevel)
    end

    if entityFuelLevel ~= groundedLevel then
        SetVehicleFuelLevel(vehicleHandle, groundedLevel)
    end

    return groundedLevel
end

function GetFuelPercentage(vehicleHandle)
    local currentLiters = GetFuelLiters(vehicleHandle)
    local maxLiters = GetMaxFuelLiters(vehicleHandle)

    return DevJacobLib.Math.Round((currentLiters / maxLiters) * 100, 2)
end

function SetFuelPercentage(vehicleHandle, percentage)
    percentage = DevJacobLib.Ternary(percentage > 100.0, 100.0, percentage)
    local newLiters = (percentage / 100) * GetMaxFuelLiters(vehicleHandle)
    SetFuelLiters(vehicleHandle, newLiters)
end

function SafeNum(number, default)
    if number == math.huge or DevJacobLib.Math.IsNaN(number) == true then
        return default
    end

    return number
end

function ConsumeVehicleFuel(vehicleHandle)
    local fuelLevel = GetFuelLiters(vehicleHandle)

    if fuelLevel > 0 and GetIsVehicleEngineRunning(vehicleHandle) then
        local key = vehicleHandle

        if StorageManager.TrackedVehicles[key] == nil then
            StorageManager.TrackedVehicles[key] = TrackedVehicle.new(vehicleHandle)
        end

        if StorageManager.TrackedVehicles[key].lastCoords == vector3(0.0, 0.0, 0.0) then
            StorageManager.TrackedVehicles[key].lastCoords = GetEntityCoords(vehicleHandle)
        end

        local distanceTravelled = #(StorageManager.TrackedVehicles[key].lastCoords - GetEntityCoords(vehicleHandle))
        local kmTravelled = math.abs(distanceTravelled / 1000) * 5.2

        StorageManager.TrackedVehicles[key].distanceTravelledKm = StorageManager.TrackedVehicles[key].distanceTravelledKm + distanceTravelled
        StorageManager.TrackedVehicles[key].lastCoords = GetEntityCoords(vehicleHandle)

        local fuelUsed = GetFuelConsumed(vehicleHandle, kmTravelled)
        print(kmTravelled, fuelUsed)
        StorageManager.TrackedVehicles[key].fuelConsumed = StorageManager.TrackedVehicles[key].fuelConsumed + fuelUsed
        fuelLevel = fuelLevel - fuelUsed

        if fuelLevel < 0.2 and IsVehicleElectric(vehicleHandle) and IsVehicleDriveable(vehicleHandle, false) then
            SetVehicleUndriveable(vehicleHandle, true)
        end

        fuelLevel = DevJacobLib.Ternary(fuelLevel < 0.0, 0.0, fuelLevel)
    end

    SetFuelLiters(vehicleHandle, fuelLevel)
end

function GetFuelConsumed(vehicleHandle, kmTravelled)

    if not DoesEntityExist(vehicleHandle) then
        return 0.0
    end

    local vehModelHash = GetEntityModel(vehicleHandle)
    if IsThisModelABicycle(vehModelHash) or IsThisModelAHeli(vehModelHash) or IsThisModelAPlane(vehModelHash) then
        return 0.0
    end

    if IsThisModelACar(vehModelHash) or IsThisModelABike(vehModelHash) or IsThisModelAQuadbike(vehModelHash) then
        local fuelUsed = 0.0
        local vehSpeed = math.abs(GetEntitySpeed(vehicleHandle))
        local currentRpm = GetVehicleCurrentRpm(vehicleHandle)

        if vehSpeed > 3.0 then
            local baseEconomy = GetBaseFuelEconomyForVeh(vehicleHandle)
            local currentAcceleration = GetVehicleCurrentAcceleration(vehicleHandle)
            local currentGear = DevJacobLib.Ternary(currentAcceleration < 0, 1, GetVehicleCurrentGear(vehicleHandle))
            local econLossFactor = SafeNum(currentRpm / currentGear, 1)
            local accelLossFactor = SafeNum(math.abs(currentAcceleration * 1.5), 1)
            local fuelEconomy = SafeNum(baseEconomy + (baseEconomy * econLossFactor) + accelLossFactor, 1)

            fuelUsed = (fuelEconomy * kmTravelled) / 100
        else
            local idleFactor = 0.6 / 216000
            local displacement = GetDisplacementForVeh(vehicleHandle)

            fuelUsed = idleFactor * displacement

            if GetVehicleDashboardSpeed(vehicleHandle) > 3.0 or currentRpm > 0.3 then
                local rpmFactor = 1 + math.abs(currentRpm * 5.0)
                fuelUsed = fuelUsed * rpmFactor
            end
        end

        return math.abs(SafeNum(fuelUsed, 0))
    end

    return 0.0
end