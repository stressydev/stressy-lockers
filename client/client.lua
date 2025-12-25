local LockerConfig = require 'config.shared'
local activeLockers = {}

-- Blips
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

local LOCKER_TEXT_STYLE = {
    scale = vec2(0.35, 0.35),
    font = 4,
    color = vec4(255, 255, 255, 220),
    enableOutline = true,
    enableDropShadow = true,
}


CreateThread(function()
    while true do
        local sleep = 1500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for i, location in ipairs(LockerConfig.Lockers) do
            local dist = #(coords - location.coords)

            if dist < 6.0 then
                sleep = 0

                -- Draw 3D Text
                qbx.drawText3d({
                    text = '[E] Rental Lockers',
                    coords = location.coords + vec3(0.0, 0.0, 1.1),
                    scale = LOCKER_TEXT_STYLE.scale,
                    font = LOCKER_TEXT_STYLE.font,
                    color = LOCKER_TEXT_STYLE.color,
                    enableOutline = LOCKER_TEXT_STYLE.enableOutline,
                    enableDropShadow = LOCKER_TEXT_STYLE.enableDropShadow,
                })

                -- Interaction
                if dist < 1.5 and IsControlJustReleased(0, 38) then
                    OpenLockerMenu(i)
                end
            end
        end

        Wait(sleep)
    end
end)

function OpenLockerMenu(locationIndex)
    local location = LockerConfig.Lockers[locationIndex]

    lib.callback('stressy-lockers:getLockers', false, function(lockers)
        activeLockers = lockers or {}

        local options = {}

        for _, locker in ipairs(location.lockers) do
            local key = locationIndex .. '_' .. locker.id
            local data = activeLockers[key]
            local isMine = data and data.owner == QBX.PlayerData.citizenid

            -- Build sub-menu for owned locker
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
                                OpenLockerMenu(locationIndex) -- Refresh menu
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

            -- Main locker entry
            options[#options + 1] = {
                title = 'Locker #' .. locker.id,
                description = data
                    and (isMine and '🟢 Rented by you' or '🔴 Occupied')
                    or '⚪ Available - $' .. locker.price,
                disabled = data and not isMine,
                onSelect = function()
                    if isMine then
                        -- Open sub-menu for this locker
                        lib.registerContext({
                            id = 'locker_actions_' .. key,
                            title = 'Locker #' .. locker.id,
                            options = lockerActions
                        })
                        lib.showContext('locker_actions_' .. key)
                    else
                        RentLocker(locationIndex, locker.id, locker.price)
                    end
                end
            }
        end

        -- Show main menu
        lib.registerContext({
            id = 'locker_menu',
            title = location.name,
            options = options
        })

        lib.showContext('locker_menu')
    end)
end


-- RENT
function RentLocker(locationIndex, lockerId, price)
    local confirm = lib.alertDialog({
        header = 'Rent Locker',
        content = 'Rent this locker for $' .. price .. '?',
        centered = true,
        cancel = true
    })

    if confirm == 'confirm' then
        local success = lib.callback.await(
            'stressy-lockers:rentLocker',
            false,
            locationIndex,
            lockerId,
            price
        )

        lib.notify({
            title = 'Rental Lockers',
            description = success
                and ('You have rented Locker #' .. lockerId)
                or 'Unable to rent locker',
            type = success and 'success' or 'error'
        })
    end
end
