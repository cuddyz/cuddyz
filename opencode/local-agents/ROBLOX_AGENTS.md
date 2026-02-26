# Roblox Game Development (Luau)

Reference project: `ChromeDomeWebDesigns/Papa-Cud-Game-Engine`
(locally at `~/Documents/Roblox/Rojo/papa-cud-game-engine`)

This section defines the preferred patterns for all Roblox / Luau projects. Weight
these conventions above general Roblox community defaults.

---

### Toolchain & Workflow

- **Rojo** (`rojo 7.4.4`) syncs between VSCode and Roblox Studio. Always run `rojo serve`
  during development; never edit `.lua`/`.luau` files and manually copy into Studio.
- **StyLua** (`0.20.0`) is the formatter. Config in `stylua.toml`: `column_width = 100`,
  tabs for indentation. VSCode `formatOnSave` is enabled — let the formatter run, don't
  fight it. Use `-- stylua: ignore` only for blocks that would wrap awkwardly (e.g., large
  ordered data tables).
- **Selene** (`0.27.1`) is the linter. Config in `selene.toml`: `std = "roblox"`. Use
  `--# selene: allow(...)` suppressions only in third-party library files, not in game code.
- **aftman** manages the toolchain versions. Always add new tools via `aftman add`.

**Reference files:** `aftman.toml`, `stylua.toml`, `selene.toml`, `.vscode/settings.json`

---

### Repository Layout & What Is / Isn't Tracked

```
papa-cud-game-engine/
├── default.project.json       → Rojo project mapping
├── aftman.toml                → Toolchain versions
├── scripts/                   → All tracked Lua source (synced by Rojo)
│   ├── ServerScriptService/   → Server scripts & modules
│   ├── StarterPlayer/         → Client entry point
│   └── ReplicatedStorage/     → Shared & client modules, game data
├── workspace_scripts/         → Studio utility scripts (run manually in Studio)
├── models_backups/            → .rbxm model backups (NOT git-tracked, Studio source of truth)
└── starter_gui_backups/       → .rbxm StarterGui backups (NOT git-tracked, Studio source of truth)
```

**What lives in Studio (not git):** Models, GUIs (StarterGui), Workspace layout, RemoteEvents,
RemoteFunctions, and any `Folder` instances that are `$ignoreUnknownInstances: true` in the
Rojo project. Backups of these are stored as `.rbxm` files in `models_backups/` and
`starter_gui_backups/` for recovery, but they are not git-tracked — Roblox Studio is the
source of truth for these assets.

**What is git-tracked:** All `.lua`/`.luau` scripts under `scripts/` and `workspace_scripts/`.

---

### Rojo Project Structure (`default.project.json`)

The Rojo file maps `scripts/` subdirectories to Roblox services:

| Rojo Source Path | Roblox Location |
|---|---|
| `scripts/ServerScriptService/` | `ServerScriptService` |
| `scripts/StarterPlayer/StarterPlayerScripts/` | `StarterPlayer.StarterPlayerScripts` |
| `scripts/ReplicatedStorage/ClientDataStore/` | `ReplicatedStorage.ClientDataStore` |
| `scripts/ReplicatedStorage/ClientModules/` | `ReplicatedStorage.ClientModules` |
| `scripts/ReplicatedStorage/SharedModules/` | `ReplicatedStorage.SharedModules` |
| `scripts/ReplicatedStorage/GameClient/Data/` | `ReplicatedStorage.GameClient.Data` |

`GameClient` has `$ignoreUnknownInstances: true` — `Models/` and `GlobalEvents/` subfolders
(containing RemoteEvent/RemoteFunction instances and 3D models) live in Studio only.

---

### Script Organization Conventions

```
scripts/
  ServerScriptService/
    ServerInit.server.lua                    ← Server bootstrap (entry point)
    ServerModules/
      Player/                                ← Per-player server controllers
      Events/                                ← Remote event dispatch & RobuxPurchase
      Interactions/                          ← Egg, CoinClicker, PetUpgrade server logic
    Libraries/
      ProfileService.lua                     ← Third-party DataStore library (do not modify)
      PlayerTemplate.lua                     ← Default player data shape
    DataStores/
      GlobalPetCountDS.lua                   ← Global leaderboard data

  StarterPlayer/StarterPlayerScripts/
    PlayerInit.client.lua                    ← Client bootstrap (entry point)

  ReplicatedStorage/
    ClientModules/                           ← Client-only handlers
      Events/                               ← Remote event routing, proximity, notifications
      Player/                               ← Client state: pets, currency, boosts, inventory
      UI/                                   ← UI render handlers + animation
      Interactions/                         ← Button interaction handlers per feature
    SharedModules/
      GeneralUtils.lua                      ← Pure utility functions (shared)
      FormatNumber/                         ← ICU-style number formatting library
    GameClient/
      Data/
        GameConstants.lua                   ← App-wide constants
        PetList.lua                         ← All pet definitions (name, rarity, bonuses, asset ID)
        EggList.lua                         ← Egg definitions with RNG chances
        ItemList.lua                        ← Consumable item definitions
        PetIndexRewards.lua                 ← Pet index milestone rewards
```

**Naming pattern for files:**
- Server modules: `*Controller.lua` (e.g., `PlayerPetsController.lua`)
- Client modules: `*Handler.lua` (e.g., `PlayerPetsHandler.lua`, `EggUIRenderHandler.lua`)
- Init modules with children: `init.lua` inside a folder (e.g., `EggOpenServerController/init.lua`)

---

### Module Pattern

Every module is a **flat table** — no OOP metatables on custom game modules. The pattern
is consistent across all files:

```lua
-- ServerScriptService.ServerModules.Player.PlayerPetsController
-- Handles all server-side pet logic for players.

local PlayerPetsController = {}

-- Private
-----------------------------------------------------------------------

local function generatePet(eggData)
    -- private helper
end

-- Public
-----------------------------------------------------------------------

function PlayerPetsController.GivePlayerPet(player, petName)
    -- public method
end

function PlayerPetsController.Init()
    -- called once from ServerInit.server.lua
end

return PlayerPetsController
```

Rules:
- Each file starts with a two-line comment block: `-- Service.Module.Path` then `-- Description`
- `-- Private` and `-- Public` section headers separated by a `-------` divider line
- Private helpers are `local function camelCase(...)` — never attached to the module table
- Public methods are `function Module.PascalCase(...)` — always on the module table
- `Init()` is the standard setup entry point called from the bootstrap scripts

**Reference:** `scripts/ServerScriptService/ServerModules/Player/PlayerPetsController.lua`,
`scripts/ReplicatedStorage/ClientModules/Player/PlayerPetsHandler.lua`

---

### Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Module variables | PascalCase | `PlayerPetsController`, `EggOpenAnimationHandler` |
| Public module functions | PascalCase | `PlayerPetsController.GivePlayerPet` |
| Private local functions | camelCase | `generatePet`, `addPetToPlayerIndex` |
| Constants (module-level) | SCREAMING_SNAKE_CASE | `MAX_CLICKS_PER_SECOND`, `FLUSH_INTERVAL` |
| Parameters (simple) | camelCase | `player`, `petName`, `amount` |
| Data table keys | PascalCase | `PetName`, `PetType`, `Rarity` |
| Roblox service locals | PascalCase (match service name) | `local Players = game:GetService("Players")` |
| Event string IDs | PascalCase strings | `"SyncClickerCoinsEvent"`, `"GivePlayerPetEvent"` |

---

### Service Requiring

Always use `game:GetService("ServiceName")` — **never** `game.ServiceName`. Declare all
services at the top of each file before any other requires:

```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
```

---

### Module Requiring

Always use `:WaitForChild()` — never index directly with `.`:

```lua
-- Correct
local GameConstants = require(ReplicatedStorage:WaitForChild("GameClient"):WaitForChild("Data"):WaitForChild("GameConstants"))

-- For init.lua modules with children
local EggOpenClientHandler = require(script:WaitForChild("EggOpenClientHandler"))
```

Never use `require(game.ReplicatedStorage.X)` or bare path strings.

---

### Client / Server Boundary Enforcement

Every server module starts with a RunService guard:
```lua
local RunService = game:GetService("RunService")
if not RunService:IsServer() then
    return error("PlayerPetsController is server-only. Do not require it via a Local Script.")
end
```

Every client module starts with:
```lua
if RunService:IsServer() then
    return error("PlayerPetsHandler is client-only. Do not require it via a Server Script.")
end
```

This is mandatory on all modules, not optional.

**Reference:** Any file in `scripts/ServerScriptService/ServerModules/` or
`scripts/ReplicatedStorage/ClientModules/`

---

### Remote Event Architecture

Use a **single RemoteEvent + single RemoteFunction** routed by string `eventId` — not one
Remote per action. Both live in `ReplicatedStorage.GameClient.GlobalEvents` (Studio-managed,
not git-tracked).

**Server → Client** (fire-and-forget):
```lua
-- ClientRemoteEventController.lua
function ClientRemoteEventController.FireClient(player, eventId, ...)
    GlobalEvents.RemoteEvent:FireClient(player, eventId, ...)
end
```

**Client → Server** (request/response):
```lua
-- ServerAPIHandler.lua (client-side)
function ServerAPIHandler.InvokeServer(eventId, ...)
    return GlobalEvents.RemoteFunction:InvokeServer(eventId, ...)
end

function ServerAPIHandler.FireServer(eventId, ...)
    GlobalEvents.RemoteEvent:FireServer(eventId, ...)
end
```

**Server dispatch** (`ServerRemoteEventController.lua`) uses `if/elseif` chains on `eventId`:
```lua
GlobalEvents.RemoteEvent.OnServerEvent:Connect(function(player, eventId, ...)
    if eventId == "SyncClickerCoinsEvent" then
        CoinClickerController.SyncClickerCoins(player, ...)
    elseif eventId == "OpenEggEvent" then
        EggOpenServerController.OpenEgg(player, ...)
    end
end)
```

**Reference:** `scripts/ServerScriptService/ServerModules/Events/ClientRemoteEventController.lua`,
`scripts/ServerScriptService/ServerModules/Events/ServerRemoteEventController.lua`,
`scripts/ReplicatedStorage/ClientModules/Events/ServerAPIHandler.lua`

---

### Async Patterns

Use the modern `task` library — **never** the deprecated `wait()`, `spawn()`, or `delay()`:

```lua
task.wait(0.15)              -- instead of wait(0.15)
task.spawn(fn)               -- fire-and-forget concurrent task
task.defer(fn)               -- deferred execution
task.delay(n, fn)            -- delayed callback
```

Infinite service loops go inside `task.spawn`:
```lua
task.spawn(function()
    while true do
        proximityService.CheckProximity()
        task.wait(PROXIMITY_INTERVAL)
    end
end)
```

For one-shot async sync, use a BindableEvent as a manual signal:
```lua
local done = Instance.new("BindableEvent")
-- ... kick off async work, fire done when complete
done.Event:Wait()
done:Destroy()
```

No Promise library is used — `task.*` + BindableEvents cover all async needs.

---

### Error Handling

**DataStore / network calls:** Wrap in `pcall`:
```lua
local success, result = pcall(function()
    return DataStore:GetAsync(key)
end)
if not success then
    warn("DataStore failed:", result)
end
```

**Client interaction handlers:** Wrap public methods in `xpcall` with `debug.traceback`:
```lua
function EggInteractionsHandler.OpenEgg(eggName)
    local success, err = xpcall(function()
        -- interaction logic
    end, debug.traceback)
    if not success then
        warn("EggInteractionsHandler.OpenEgg failed:", err)
    end
end
```

**Wrong-context protection:** `return error(...)` at the top of modules (see boundary enforcement above).

Never use bare `error()` in normal game flow — prefer `warn()` with a descriptive message and
graceful fallback.

---

### Instance Creation

Set `Parent` last — always:
```lua
local folder = Instance.new("Folder")
folder.Name = "ClientPets"
folder.Parent = Workspace
```

Never use the two-argument form `Instance.new("Folder", parent)` — it's deprecated.

---

### Data & State Patterns

**Data persistence:** Use `ProfileService` (third-party, `scripts/ServerScriptService/Libraries/ProfileService.lua`).
Do not modify this library. Define the default player data shape in `PlayerTemplate.lua`.
ProfileService handles session-locking, auto-reconciliation, and `BindToClose` cleanup.

**Player data access:** All profile reads/writes go through `PlayerDataController`. No other
module accesses the `_profiles` table directly.

**Atomic counters:** Use Firestore-equivalent Roblox pattern — `DataStore:IncrementAsync` for
global counters (e.g., `GlobalPetCountDS`), not read-modify-write.

**Attribute-based client communication:** Prefer `player:SetAttribute()` / `GetAttributeChangedSignal()`
for server → client state that clients need to observe reactively (e.g., equipped pets, pet bonus):
```lua
-- Server sets
player:SetAttribute("EquippedPets", HttpService:JSONEncode(equippedPetNames))

-- Client listens
player:GetAttributeChangedSignal("EquippedPets"):Connect(function()
    local pets = HttpService:JSONDecode(player:GetAttribute("EquippedPets"))
    -- update client state
end)
```

**Reference:** `scripts/ServerScriptService/ServerModules/Player/PlayerPetsController.lua`,
`scripts/ServerScriptService/Libraries/PlayerTemplate.lua`

---

### Anti-Cheat Pattern (Coin Clicker)

Client batches actions locally and sends periodic syncs to the server. Server validates:
```lua
-- Server side
local MAX_CLICKS_PER_SECOND = 100
local FLUSH_INTERVAL = 1

-- Validate sequence number (prevents replay)
-- Validate click rate (amount / elapsed <= MAX_CLICKS_PER_SECOND)
-- Reject and warn on failure, never trust raw client values
```

Apply this pattern to any client-initiated numeric accumulation.

**Reference:** `scripts/ServerScriptService/ServerModules/Interactions/CoinClickerController.lua`,
`scripts/ReplicatedStorage/ClientModules/Interactions/InteractableUIInteractionsHandler/CoinClickerInteractionsHandler.lua`

---

### UI / Interaction Architecture

**Button mounting:** CollectionService tag `"UIButton"` on all interactive GuiButtons.
`InteractableUIInteractionsHandler` mounts handlers from a `ButtonActions` dispatch table
keyed on `Button.Name.Value`. An `__Bound` attribute prevents double-mounting:

```lua
if button:GetAttribute("__Bound") then continue end
button:SetAttribute("__Bound", true)
local handler = ButtonActions[button.Name.Value]
if handler then handler(button) end
```

**UI rendering:** Each feature has a dedicated `*RenderHandler.lua` (render/display) and a
separate `*InteractionsHandler.lua` (input/event handling). These are never merged.

**Proximity detection:** Custom `RunService.Heartbeat` loop at 0.15s interval checks distance
to `CollectionService:GetTagged("InteractableProximityPart")` parts. No `ProximityPrompt`
instances are used.

**Pet following animation:** `RunService.RenderStepped` with exponential smoothing:
```lua
-- Smooth follow: position lerps toward target each frame
petModel:PivotTo(CFrame.new(
    currentPosition + (targetPosition - currentPosition) * (1 - math.exp(-k * dt))
))
```

**Reference:** `scripts/ReplicatedStorage/ClientModules/UI/InteractableUIRenderHandler/`,
`scripts/ReplicatedStorage/ClientModules/Interactions/InteractableUIInteractionsHandler/`

---

### Loops

- `ipairs` for ordered arrays (pet lists, egg RNG tables, item arrays)
- `pairs` for dictionaries (player profiles, boost tables, data maps)
- `for i = 1, n, 1 do` for numeric loops — always include the step argument
- Use `continue` (modern Luau) to skip iterations instead of deeply nested `if` blocks

---

### Type Annotations

Luau types are used **selectively**, not universally:
- Use `type` and `export type` in library/utility modules and data definition files
- Game logic controllers and handlers generally have no type annotations
- When annotating, use `type Data = { [string]: number }` style for dictionaries,
  generic types only in library code

Do not force type annotations onto every file — match the existing convention per file type.

---

### Workspace Scripts

Files in `workspace_scripts/` are **Studio utility scripts** run manually by a developer
inside Studio (e.g., to bulk-update model pivots, move assets, apply visual effects). They
are not part of the game runtime and are not synced by Rojo into a service. Keep them in
`workspace_scripts/` and document what each one does with a comment at the top.

**Reference:** `workspace_scripts/syncModelsPivotToPetList.lua`,
`workspace_scripts/movePetModelsToWorkspace.lua`

---

### Game Data Files

All static game content (pets, eggs, items, rewards) lives in `scripts/ReplicatedStorage/GameClient/Data/`
as plain Lua tables returned by ModuleScripts. Data files are the single source of truth —
no hardcoded values in controller/handler logic.

```lua
-- PetList.lua pattern
return {
    CommonCat = {
        PetName = "Common Cat",
        Rarity = "Common",
        PetType = "Cat",
        AssetId = 12345678,
        CoinBonus = 1.1,
        -- ...
    },
    -- ...
}
```

**Reference:** `scripts/ReplicatedStorage/GameClient/Data/PetList.lua`,
`scripts/ReplicatedStorage/GameClient/Data/EggList.lua`,
`scripts/ReplicatedStorage/GameClient/Data/GameConstants.lua`
