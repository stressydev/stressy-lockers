local LockerConfig = require 'config.shared'
local Framework = require 'bridge.cl_bridge' 

local LOCKER_TEXT_STYLE = {
    scale = 0.35,
    color = vec4(255, 255, 255, 220),
}


-- ============================================
-- BLIPS
-- ============================================
CreateThread(function()
    for _, location in ipairs(LockerConfig.Lockers) do
        if location.blip.enabled then
            local blip = AddBlipForCoord(location.coords)
            SetBlipSprite(blip, location.blip.sprite)
            SetBlipScale(blip, location.blip.scale)
            SetBlipColour(blip, location.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(location.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- ============================================
-- 3D Text Helper
-- ============================================
function DrawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)

    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end


-- ============================================
-- MAIN LOOP
-- ============================================
CreateThread(function()
    while true do
        local sleep = 1500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for i, location in ipairs(LockerConfig.Lockers) do
            local dist = #(coords - location.coords)

            if dist < 6.0 then
                sleep = 0
                DrawText3D(location.coords.x , location.coords.y , location.coords.z + 1.1, '[E] Rental Lockers')

                if dist < 1.5 and IsControlJustReleased(0, 38) then
                    OpenLockerMenu(i)
                end
            end
        end

        Wait(sleep)
    end
end)


--- RAID SYSTEM (FOR POLICE JOBS) ---
-- Generic police raid function
function AttemptRaid(locationName, lockerId, key)
    -- This just triggers the existing stash event
    -- Any warrant checks or custom logic can be handled externally before calling this
    TriggerServerEvent('stressy-lockers:openStash', locationName, lockerId, key)
end


---- OPEN LOCKER MENU ----
--------------------------

function OpenLockerMenu(locationIndex)
    local location = LockerConfig.Lockers[locationIndex]

    lib.callback('stressy-lockers:getLockers', false, function(lockers)
        activeLockers = lockers or {}

        -- Check if player is police
        local isPolice = false
        local PlayerJob = Framework.PlayerData().job or Framework.PlayerData().job.name

        for _, jobName in ipairs(LockerConfig.PoliceJob) do
            if PlayerJob == jobName then
                isPolice = true
                break
            end
        end

        local playerId = Framework.PlayerData().citizenid or Framework.PlayerData().identifier

        local options = {}

        for _, locker in ipairs(location.lockers) do
            local key = locationIndex .. '_' .. locker.id
            local data = activeLockers[key]
            local isMine = data and data.owner == playerId

            local lockerActions = {}

            if isMine then
                lockerActions[#lockerActions + 1] = {
                    title = 'Open Locker',
                    description = 'Access your locker stash',
                    icon = 'box',
                    onSelect = function()
                        TriggerServerEvent('stressy-lockers:openStash', location.name, locker.id, key)
                    end
                }

                lockerActions[#lockerActions + 1] = {
                    title = 'Unrent Locker',
                    description = 'Give up this locker and get refunded',
                    icon = 'unlock',
                    onSelect = function()
                        local confirm = lib.alertDialog({
                            header = 'Unrent Locker',
                            content = 'Are you sure you want to unrent this locker?',
                            centered = true,
                            cancel = true
                        })

                        if confirm == 'confirm' then
                            local success = lib.callback.await('stressy-lockers:unrentLocker', false, key)
                            if success then
                                lib.notify({
                                    title = 'Rental Lockers',
                                    description = 'Locker #' .. locker.id .. ' has been unrented and refunded.',
                                    type = 'success'
                                })
                                OpenLockerMenu(locationIndex)
                            else
                                lib.notify({
                                    title = 'Rental Lockers',
                                    description = 'Unable to unrent locker.',
                                    type = 'error'
                                })
                            end
                        end
                    end
                }
            end

            -- Build main locker entry
            local description = '⚪ Available - $' .. locker.price
            local disabled = false

            if data then
                if isMine then
                    description = '🟢 Rented by you'
                elseif isPolice then
                    description = '🔴 Occupied - Police can attempt raid'
                else
                    description = '🔴 Occupied'
                    disabled = true
                end
            end

            options[#options + 1] = {
                title = 'Locker #' .. locker.id,
                description = description,
                disabled = disabled,
                onSelect = function()
                    if isMine then
                        lib.registerContext({
                            id = 'locker_actions_' .. key,
                            title = 'Locker #' .. locker.id,
                            options = lockerActions
                        })
                        lib.showContext('locker_actions_' .. key)
                    elseif isPolice then
                        -- Police attempt raid: just call the stash open event
                        AttemptRaid(location.name, locker.id, key)
                    else
                        RentLocker(locationIndex, locker.id, locker.price)
                    end
                end
            }
        end

        lib.registerContext({
            id = 'locker_menu',
            title = location.name,
            options = options
        })
        lib.showContext('locker_menu')
    end)
end


-- ============================================
-- RENT LOCKER
-- ============================================
function RentLocker(locationIndex, lockerId, price)
    local confirm = lib.alertDialog({
        header = 'Rent Locker',
        content = 'Rent this locker for $' .. price .. '?',
        centered = true,
        cancel = true
    })

    if confirm == 'confirm' then
        local success = lib.callback.await('stressy-lockers:rentLocker', false, locationIndex, lockerId, price)

        lib.notify({
            title = 'Rental Lockers',
            description = success
                and ('You have rented Locker #' .. lockerId)
                or 'Unable to rent locker',
            type = success and 'success' or 'error'
        })
    end
end