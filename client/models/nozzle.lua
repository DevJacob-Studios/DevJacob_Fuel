NozzleState = {
    None = 0,
    Dropped = 1,
    Held = 2,
    InVehicle = 3
}

Nozzle = {}
Nozzle.__index = Nozzle
Nozzle.GRAB_NOZZLE_ANIM_DICT = "anim@am_hold_up@male"
Nozzle.GRAB_NOZZLE_ANIM_NAME = "shoplift_high"
Nozzle.PLACE_IN_VEH_ANIM_DICT = "timetable@gardener@filling_can"
Nozzle.PLACE_IN_VEH_ANIM_NAME = "gar_ig_5_filling_can"
Nozzle.NOZZLE_PROP_MODEL = "prop_cs_fuel_nozle"

function Nozzle.new(fuelPump)
    local self = setmetatable({}, Nozzle)

    self.fuelPump = fuelPump
    self.state = NozzleState.None
    self.propHandle = nil
    self.ropeHandle = nil
    self.holdingPedHandle = nil
    self.fuelingVehicleHandle = nil
    self.isFuelThreadActive = false

    return self
end

function Nozzle._Reset(nozzle)
    nozzle.holdingPedHandle = nil
    nozzle.fuelingVehicleHandle = nil
    nozzle.state = NozzleState.None

    if not nozzle.propHandle then
        DeleteEntity(nozzle.propHandle)
        nozzle.propHandle = nil
    end

    if not nozzle.ropeHandle then
        DeleteRope(nozzle.ropeHandle)
        nozzle.ropeHandle = nil
    end

    return
end

function Nozzle._CreatePropAsync(nozzle, position)
    position = position or vector3(0.0, 0.0, 0.0)
    local _promise = promise.new()

    local runFunc = function()
        local modelLoaded = Citizen.Await(RequestModelAsync(Nozzle.NOZZLE_PROP_MODEL))
        if modelLoaded == false then
            DevJacobLib.Logger.Error(("Failed to load model \"%s\""):format(Nozzle.NOZZLE_PROP_MODEL))
            _promise:reject()
        end

        local newPropHandle = CreateObjectNoOffset(GetHashForModel(Nozzle.NOZZLE_PROP_MODEL), position.x, position.y, position.z, true, true, false)
        if newPropHandle == 0 then
            SetModelAsNoLongerNeeded(GetHashForModel(Nozzle.NOZZLE_PROP_MODEL))
            DevJacobLib.Logger.Error(("Failed to create object for model \"%s\""):format(Nozzle.NOZZLE_PROP_MODEL))
            _promise:reject()
        end

        SetModelAsNoLongerNeeded(GetHashForModel(Nozzle.NOZZLE_PROP_MODEL))

        _promise:resolve(newPropHandle)
    end

    runFunc()
    return _promise
end

function Nozzle._CreateRopeAsync(nozzle, position)
    position = position or vector3(0.0, 0.0, 0.0)
    local _promise = promise.new()

    local runFunc = function()
        local texturesLoaded = Citizen.Await(LoadRopeTexturesAsync())
        if texturesLoaded == false then
            DevJacobLib.Logger.Error("Failed to load rope textures")
            _promise:reject()
        end

        local newRopeHandle = AddRope(position.x, position.y, position.z, 0.0, 0.0, 0.0, 4.0, 1, 4.0, 1.5, 0.5, false, false, true, 1.0, true)
        if not newRopeHandle then
            DevJacobLib.Logger.Error("Failed to create rope")
            _promise:reject()
        end

        ActivatePhysics(newRopeHandle)

        _promise:resolve(newRopeHandle)
    end

    runFunc()
    return _promise
end

function Nozzle._PlayGrabAnimAsync(nozzle, pedHandle)
    local _promise = promise.new()

    local runFunc = function()
        local animDictLoaded = Citizen.Await(RequestAnimDictAsync(Nozzle.GRAB_NOZZLE_ANIM_DICT))
        if animDictLoaded == false then
            DevJacobLib.Logger.Error(("Failed to load anim dict \"%s\""):format(Nozzle.GRAB_NOZZLE_ANIM_DICT))
            _promise:reject()
        end

        TaskPlayAnim(pedHandle, Nozzle.GRAB_NOZZLE_ANIM_DICT, Nozzle.GRAB_NOZZLE_ANIM_NAME, 2.0, 8.0, -1, 50, 0, false, false, false)

        _promise:resolve()
    end

    runFunc()
    return _promise
end

function Nozzle._PlayPlaceInVehicleAnimAsync(nozzle, pedHandle)
    local _promise = promise.new()

    local runFunc = function()
        local animDictLoaded = Citizen.Await(RequestAnimDictAsync(Nozzle.PLACE_IN_VEH_ANIM_DICT))
        if animDictLoaded == false then
            DevJacobLib.Logger.Error(("Failed to load anim dict \"%s\""):format(Nozzle.PLACE_IN_VEH_ANIM_DICT))
            _promise:reject()
        end

        TaskPlayAnim(pedHandle, Nozzle.PLACE_IN_VEH_ANIM_DICT, Nozzle.PLACE_IN_VEH_ANIM_NAME, 2.0, 8.0, -1, 50, 0, false, false, false)

        _promise:resolve()
    end

    runFunc()
    return _promise
end

function Nozzle._TryAttachToPed(nozzle, pedHandle)
    if not pedHandle or not nozzle.propHandle then
        return false
    end

    local boneIndex = GetPedBoneIndex(pedHandle, 18905) -- SKEL_L_Hand
    AttachEntityToEntity(nozzle.propHandle, pedHandle, boneIndex, 0.11, 0.02, 0.02, -15.0, -90.0, -80.0, false, false, false, false, 2, true)

    return IsEntityAttachedToEntity(nozzle.propHandle, pedHandle)
end

function Nozzle._TryAttachToVehicle(nozzle, vehicleHandle)
    if not vehicleHandle or not nozzle.propHandle then
        return false
    end

    local vehicleValid, targetBoneIndex, tankPosition, nozzleOffset, textOffset = TryGetTankPosition(vehicleHandle)
    if not vehicleValid then
        return false
    end

    local vehicleClass = GetVehicleClass(vehicleHandle)
    if vehicleClass == 8 then
        AttachEntityToEntity(nozzle.propHandle, vehicleHandle, targetBoneIndex, 
            nozzleOffset.x, -0.2 + nozzleOffset.y, 0.2 + nozzleOffset.z,
            -75.0, 0.0, 0.0, 
            false, false, false, false, 2, true)
    else
        -- X: Rotate Vert (backflip / frontflip)
        -- Y: Roll (Lean left / right)
        -- Z: Turn
        AttachEntityToEntity(nozzle.propHandle, vehicleHandle, targetBoneIndex, 
            -0.18 + nozzleOffset.x, nozzleOffset.y, 0.75 + nozzleOffset.z,
            -80.0, 0.0, -90.0, 
            false, false, false, false, 2, true)
    end

    return IsEntityAttachedToEntity(nozzle.propHandle, vehicleHandle)
end

function Nozzle.Destroy(nozzle)
    Nozzle._Reset(nozzle)
    return
end

function Nozzle.FeulThread(nozzle)
    local threadFunc = function()
        if nozzle.isFuelThreadActive == true then return end
        nozzle.isFuelThreadActive = true
    
        local percentPerSecond = 6.0
        local intervalDelay = 100
        local percentPerInterval = percentPerSecond / (1000 / intervalDelay)
        
        local fillTankSoundId = AudioManager.PlaySoundFromEntity("nui/sounds/fuel_pump_fill.mp3", nozzle.propHandle, {
            volume = 1.0,
            loop = true,
            radius = 10.0,
        })
    
        local targetVehicleHandle = nozzle.fuelingVehicleHandle
        while nozzle.state == NozzleState.InVehicle and GetFuelPercentage(targetVehicleHandle) < 100.0 do
            local rawFuelPercent = GetFuelPercentage(targetVehicleHandle)
            local newFuelPercent = rawFuelPercent + percentPerInterval
            local groundedPercent = DevJacobLib.Ternary(newFuelPercent > 100.0, 100.0, newFuelPercent)
            SetFuelPercentage(targetVehicleHandle, groundedPercent)
    
            Citizen.Wait(intervalDelay)
        end
    
        AudioManager.StopSound(fillTankSoundId)
        if GetFuelPercentage(targetVehicleHandle) >= 100.0 then
            local tankFullSoundId = AudioManager.PlaySoundFromEntity("nui/sounds/fuel_pump_click.mp3", nozzle.propHandle, {
                volume = 1.0,
                loop = false,
                radius = 10.0,
            })
        end
    
        nozzle.isFuelThreadActive = false
    end
    
    return threadFunc
end

function Nozzle.TryGrabFromPumpAsync(nozzle, pedHandle)
    local _promise = promise.new()

    local runFunc = function()
        if nozzle.state ~= NozzleState.None then
            _promise:resolve(false)
        end

        -- Play the animation
        Citizen.Await(Nozzle._PlayGrabAnimAsync(nozzle, pedHandle))
        Citizen.Wait(300)
        ClearPedTasks(pedHandle)

        -- Create the prop
        nozzle.propHandle = Citizen.Await(Nozzle._CreatePropAsync(nozzle))

        -- Attach the prop to the entity
        local didAttach = Nozzle._TryAttachToPed(nozzle, pedHandle)
        if not didAttach then
            DevJacobLib.Logger.Error("Failed to attach nozzle prop to ped")
            _promise:resolve(false)
        end

        -- Create the rope
        nozzle.ropeHandle = Citizen.Await(Nozzle._CreateRopeAsync(nozzle))

        -- Attach the rope to the prop
        local nozzlePos = GetOffsetFromEntityInWorldCoords(nozzle.propHandle, 0.0, -0.033, -0.195)
        local pumpPos = nozzle.fuelPump.ropePosition
        AttachEntitiesToRope(nozzle.ropeHandle, nozzle.fuelPump.entityHandle, nozzle.propHandle, 
            pumpPos.x, pumpPos.y, pumpPos.z,
            nozzlePos.x, nozzlePos.y, nozzlePos.z,
            5.0, false, false, nil, nil)

        -- Set the nozzle state
        nozzle.holdingPedHandle = pedHandle
        nozzle.state = NozzleState.Held
        StorageManager.CurrentNozzle = nozzle

        _promise:resolve(true)
    end

    runFunc()
    return _promise
end

function Nozzle.TryReturnToPumpAsync(nozzle)
    local _promise = promise.new()

    local runFunc = function()
        if nozzle.state ~= NozzleState.Held then
            _promise:resolve(false)
        end

        -- Play the animation
        Citizen.Await(Nozzle._PlayGrabAnimAsync(nozzle, nozzle.holdingPedHandle))
        Citizen.Wait(300)
        ClearPedTasks(nozzle.holdingPedHandle)

        -- Delete the prop
        DeleteEntity(nozzle.propHandle)
        nozzle.propHandle = nil

        -- Delete the rope and unload the textures
        RopeUnloadTextures()
        DeleteRope(nozzle.ropeHandle)
        nozzle.ropeHandle = nil

        -- Set the nozzle state
        nozzle.holdingPedHandle = nil
        nozzle.state = NozzleState.None
        StorageManager.CurrentNozzle = nil

        _promise:resolve(true)
    end

    runFunc()
    return _promise
end

function Nozzle.TryPlaceInVehicleAsync(nozzle, vehicleHandle)
    local _promise = promise.new()

    local runFunc = function()
        if nozzle.state ~= NozzleState.Held then
            _promise:resolve(false)
        end

        -- Play the animation
        Citizen.Await(Nozzle._PlayGrabAnimAsync(nozzle, nozzle.holdingPedHandle))

        -- Attach the prop to the vehicle
        local didAttach = Nozzle._TryAttachToVehicle(nozzle, vehicleHandle)
        if not didAttach then
            DevJacobLib.Logger.Error("Failed to attach nozzle prop to vehicle")
            _promise:resolve(false)
        end

        -- Clear tasks
        Citizen.Wait(300)
        ClearPedTasks(nozzle.holdingPedHandle)

        -- Set the nozzle state
        nozzle.holdingPedHandle = nil
        nozzle.fuelingVehicleHandle = vehicleHandle
        nozzle.state = NozzleState.InVehicle
        StorageManager.CurrentNozzle = nozzle

        Citizen.CreateThread(nozzle.FeulThread(nozzle))

        _promise:resolve(true)
    end

    runFunc()
    return _promise
end

function Nozzle.TryGrabFromVehicleAsync(nozzle, pedHandle)
    local _promise = promise.new()

    local runFunc = function()
        if nozzle.state ~= NozzleState.InVehicle then
            _promise:resolve(false)
        end

        -- Play the animation
        Citizen.Await(Nozzle._PlayGrabAnimAsync(nozzle, pedHandle))
        Citizen.Wait(300)
        ClearPedTasks(pedHandle)

        -- Attach the prop to the entity
        local didAttach = Nozzle._TryAttachToPed(nozzle, pedHandle)
        if not didAttach then
            DevJacobLib.Logger.Error("Failed to attach nozzle prop to ped")
            _promise:resolve(false)
        end

        -- Set the nozzle state
        nozzle.holdingPedHandle = pedHandle
        nozzle.fuelingVehicleHandle = nil
        nozzle.state = NozzleState.Held
        StorageManager.CurrentNozzle = nozzle

        _promise:resolve(true)
    end

    runFunc()
    return _promise
end
