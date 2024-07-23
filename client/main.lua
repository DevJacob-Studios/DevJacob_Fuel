local function OnTickInit()
    -- Parse and cache some config values
    for index, modelName in ipairs(Config["ElectricVehicleModels"]) do
        local modelHash = GetHashForModel(modelName)
        CacheManager.ElectricVehicleModels[index] = value
    end
    
    for modelName, value in pairs(Config["OverrideBaseFuelEconomy"]) do
        local modelHash = GetHashForModel(modelName)
        CacheManager.OverrideBaseFuelEconomy[modelHash] = value
    end
    
    for modelName, value in pairs(Config["OverrideEngineDisplacement"]) do
        local modelHash = GetHashForModel(modelName)
        CacheManager.OverrideEngineDisplacement[modelHash] = value
    end
end

local function OnTickHalfSecond()
    while true do
        local pedPosition = GetEntityCoords(PlayerPedId())

        StorageManager.ClosestPump = WorldManager.GetClosestFuelPump(pedPosition)
        StorageManager.CurrentVehicle = WorldManager.GetClosestVehicle(pedPosition)
        
        Citizen.Wait(500)
    end
end

local function OnTickDrawText()
    while true do
        local delay = 0
        local isDrawing = false
        local displayInteract = false
        local closestPump = StorageManager.ClosestPump
        local closestVehicle = StorageManager.CurrentVehicle
        local playerPed = PlayerPedId()

        if closestPump ~= nil then
            local currentNozzle = StorageManager.CurrentNozzle
            if closestPump.nozzle == nil and currentNozzle == nil then
                isDrawing = true
                displayInteract = true
                DevJacobLib.DrawText3DThisFrame({
                    coords = vector3(closestPump.position.x, closestPump.position.y, closestPump.position.z + 1.2),
                    text = "Grab Nozzle"
                })

                if IsControlJustPressed(0, 51) then
                    Citizen.Await(FuelPump.TryGrabNozzleAsync(closestPump, playerPed))
                end

            elseif currentNozzle ~= nil and currentNozzle.state == NozzleState.Held and currentNozzle.fuelPump == closestPump then
                isDrawing = true
                displayInteract = true
                DevJacobLib.DrawText3DThisFrame({
                    coords = vector3(closestPump.position.x, closestPump.position.y, closestPump.position.z + 1.2),
                    text = "Return Nozzle"
                })

                if IsControlJustPressed(0, 51) then
                    Citizen.Await(FuelPump.TryReturnNozzleAsync(closestPump))
                end

            end

        elseif closestVehicle ~= nil then
            local vehicleValid, tankBoneIndex, tankPos, nozzleOffset, textOffset = TryGetTankPosition(closestVehicle)
            local pedPosition = GetEntityCoords(playerPed)
            
            if vehicleValid == true and #(tankPos - pedPosition) < 1.2 then
                local currentNozzle = StorageManager.CurrentNozzle
                if currentNozzle ~= nil and currentNozzle.state == NozzleState.Held then
                    local closestVehicleClass = GetVehicleClass(closestVehicle)
                    isDrawing = true
                    displayInteract = true
                    DevJacobLib.DrawText3DThisFrame({
                        coords = vector3(tankPos.x + textOffset.x, tankPos.y + textOffset.y, tankPos.z + StorageManager.NozzleZOffset[closestVehicleClass] + textOffset.z),
                        text = "Insert Nozzle"
                    })

                    if IsControlJustPressed(0, 51) then
                        Citizen.Await(Nozzle.TryPlaceInVehicleAsync(currentNozzle, closestVehicle))
                    end

                elseif currentNozzle ~= nil and currentNozzle.state == NozzleState.InVehicle then
                    local closestVehicleClass = GetVehicleClass(closestVehicle)
                    isDrawing = true
                    displayInteract = true
                    DevJacobLib.DrawText3DThisFrame({
                        coords = vector3(tankPos.x + textOffset.x, tankPos.y + textOffset.y, tankPos.z + StorageManager.NozzleZOffset[closestVehicleClass] + textOffset.z),
                        text = "Grab Nozzle"
                    })

                    if IsControlJustPressed(0, 51) then
                        Citizen.Await(Nozzle.TryGrabFromVehicleAsync(currentNozzle, playerPed))
                    end

                end

            end
        
        end

        local pedVehicle = GetVehiclePedIsIn(playerPed, true)
        if pedVehicle ~= nil and DoesEntityExist(pedVehicle) then
            isDrawing = true
            DevJacobLib.DrawText2DThisFrame({
                coords = vector2(0.02, 0.5),
                text = "Fuel Percent: " .. GetFuelPercentage(pedVehicle) .. "%",
                scale = 0.45,
                colour = {
                    r = 255,
                    g = 255,
                    b = 255,
                    a = 200
                }
            })
            
            -- DevJacobLib.DrawText2DThisFrame({
            --     coords = vector2(0.02, 0.525),
            --     text = "Fuel Liters: " .. GetFuelLiters(pedVehicle) .. "L",
            --     scale = 0.45,
            --     colour = {
            --         r = 255,
            --         g = 255,
            --         b = 255,
            --         a = 200
            --     }
            -- })
            
            -- DevJacobLib.DrawText2DThisFrame({
            --     coords = vector2(0.02, 0.55),
            --     text = "Fuel GTA: " .. GetVehicleFuelLevel(pedVehicle),
            --     scale = 0.45,
            --     colour = {
            --         r = 255,
            --         g = 255,
            --         b = 255,
            --         a = 200
            --     }
            -- })
        end

        if isDrawing == false then
            delay = 1000
        end

        if isDrawing == true and displayInteract == true then
            DevJacobLib.DrawHelpTextThisFrame("Press ~INPUT_CONTEXT~ to interact")
        end

        Citizen.Wait(delay)
    end
end

local function OnTickConsumeFuel()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()

        if StorageManager.CurrentVehicle ~= nil then
            local vehicle = StorageManager.CurrentVehicle
            local vehModelHash = GetEntityModel(vehicelHandle)

            if GetVehicleClass(vehicle) ~= 13 and not IsThisModelABicycle(vehModelHash) then

                if IsThisModelAHeli(vehModelHash) or IsThisModelAPlane(vehModelHash) then

                else

                    -- Leak fuel when tank is damaged
                    local tankHealth = GetVehiclePetrolTankHealth(vehicle)
                    local fuelLiters = GetFuelLiters(vehicle)
                    if IsThisModelACar(vehModelHash) and tankHealth < 700 and fuelLiters > 0 then
                        if tankHealth < 250 and not IsVehicleElectric(vehicle) then
                            fuelLiters = fuelLiters - 0.010
                        end

                        fuelLiters = fuelLiters - 0.003
                        SetFuelLiters(vehicle, fuelLiters)
                    end

                    if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                        ConsumeVehicleFuel(vehicle)
                    end

                end

            end

        end

        if IsPedOnFoot(playerPed) then
            for handle, trackedVeh in pairs(StorageManager.TrackedVehicles) do
                if trackedVeh == nil then
                    goto continue
                end

                if not DoesEntityExist(handle) then
                    StorageManager.TrackedVehicles[handle] = nil
                    goto continue
                end

                if GetIsVehicleEngineRunning(handle) then
                    ConsumeVehicleFuel(handle)
                end

                ::continue::
            end
        end

    end
end

local function OnCommandDevSetFuelP(soruce, args)
    SetFuelPercentage(GetVehiclePedIsIn(PlayerPedId(), true), tonumber(args[1]))
end

local function OnCommandDevSetFuelL(soruce, args)
    SetFuelLiters(GetVehiclePedIsIn(PlayerPedId(), true), tonumber(args[1]))
end

local function OnEventResourceStop(resourceName)
    if resourceName ~= CacheManager.CurrentResourceName then
        return
    end

    if StorageManager.CurrentNozzle ~= nil then
        Nozzle.Destroy(StorageManager.CurrentNozzle)
    end
end



AddEventHandler("onResourceStop", OnEventResourceStop)

RegisterCommand("dev_setfuel_p", OnCommandDevSetFuelP)
RegisterCommand("dev_setfuel_l", OnCommandDevSetFuelL)

Citizen.CreateThread(OnTickInit)
Citizen.CreateThread(OnTickHalfSecond)
Citizen.CreateThread(OnTickDrawText)
Citizen.CreateThread(OnTickConsumeFuel)


RegisterCommand("dev_sound1", function()
    AudioManager.PlaySoundOnClient("nui/sounds/fuel_pump_fill.mp3", GetPlayerServerId(PlayerId()))
end)