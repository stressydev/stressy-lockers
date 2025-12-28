# Rental Lockers

A **rental locker system** for QBX + ox_inventory with 3D text interaction, unrent option, and recurring billing.

---

## Features

- Rent lockers at multiple locations  
- 15 lockers per location, configurable  
- Persistent storage in MySQL (`stressy_lockers` table)  
- Access locker stash via ox_inventory  
- Unrent locker with refund  
- 3D text `[E] Rental Lockers` interaction  
- Automatic recurring billing via `lib.cron`  
- Police can raid lockers

## Warrants Integration
On client line 81
You may need to update this for your own system of warrants
```
function AttemptRaid(locationName, lockerId, key)
    -- This just triggers the existing stash event
    -- Any warrant checks or custom logic can be handled externally before calling this
    TriggerServerEvent('stressy-lockers:openStash', locationName, lockerId, key)
end
```

---

## Requirements

- QBX Core (`qbx_core`)  
- ox_inventory  
- ox_lib  
- lib.cron  
- MySQL database  

---

## Installation

1. Place in `resources/[qb]/rental-lockers`  
2. Add to `server.cfg`:

```cfg
ensure stressy-lockers
ensure qbx_core
ensure ox_inventory
ensure ox_lib
```

## Configuration
```
LockerConfig.MaxSlots = 20
LockerConfig.MaxWeight = 50000
LockerConfig.BillingCron = '0 0 * * *' -- daily at midnight

LockerConfig.Lockers = {
    {
        name = "Downtown Vinewood Lockers",
        coords = vector3(244.686, 374.662, 105.738),
        blip = { enabled = true, sprite = 763, color = 70, scale = 0.7 },
        lockers = {
            { id = 1, price = 25 },
            { id = 2, price = 25 },
            { id = 3, price = 25 },
            { id = 4, price = 25 },
            { id = 5, price = 25 },
            { id = 6, price = 25 },
            { id = 7, price = 25 },
            { id = 8, price = 25 },
            { id = 9, price = 25 },
            { id = 10, price = 25 },
            { id = 11, price = 50 },
            { id = 12, price = 50 },
            { id = 13, price = 50 },
            { id = 14, price = 50 },
            { id = 15, price = 50 }
        }
    }
}
```

## Usage
- Approach a locker location → see [E] Rental Lockers
- Press E → open locker menu
- Available lockers → rent
- Owned lockers → open stash or unrent

## Callbacks

```
| Callback                    | Description                |
| --------------------------- | -------------------------- |
| `stressy-lockers:getLockers`   | Fetch all rented lockers   |
| `stressy-lockers:rentLocker`   | Rent a locker              |
| `stressy-lockers:unrentLocker` | Unrent a locker and refund |
| `stressy-lockers:openStash`    | Open ox_inventory stash    |
| `stressy-lockers:getLockersByIdentifier`    | Fetch Locker by identifier    |
| `stressy-lockers:getAllLockersForMDT`    | Get All Lockers    |


```
<img src="https://jumardevelopments.sirv.com/scripts/stressy-lockers.png" width="1366" height="778" alt="">


