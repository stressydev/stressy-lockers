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
        lockers = GenerateLockers() -- 15 lockers
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
| `rentalLocker:getLockers`   | Fetch all rented lockers   |
| `rentalLocker:rentLocker`   | Rent a locker              |
| `rentalLocker:unrentLocker` | Unrent a locker and refund |
| `rentalLocker:openStash`    | Open ox_inventory stash    |

```
<img src="https://jumardevelopments.sirv.com/scripts/stressy-lockers.png" width="1366" height="778" alt="">


