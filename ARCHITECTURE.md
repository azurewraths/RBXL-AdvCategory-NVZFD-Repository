# ARCHITECTURE.md

## -> Architectural system and format of the repository.

# ->> General: ROBLOX Luau systems and repository for the scripts and codes of the ROBLOX Game Noobs V.S. Zombies: Frontier Defense, a multiplayer game rich of advanced-like
systems or more in general.

# ->> Repository File Structure

/main
├── /files # ROBLOX place & model files
│ ├── *.rbxl # Place files
│ ├── *.rbxlx # XML-based place files
│ ├── *.rbxm # Model files
│ └── *.rbxmx_old # Legacy or backup model files
│
├── /scripts # Core game logic, split by context
│ ├── /server # Scripts that run on the server
│ │ ├── /modules
│ │ │ ├── coremodules # Game engine modules (data, networking, core logic)
│ │ │ ├── defmodules # Default game mechanics (inventory, combat)
│ │ │ └── genmodules # Generated content (procedural systems, loot)
│ │ └── /defaultcodes
│ │ ├── corescripts # Initialization scripts
│ │ ├── defscripts # Server-side behavior scripts
│ │ └── genscripts # Server logic for dynamic generation
│ │
│ └── /local # Scripts that run on the client
│ ├── /modules
│ │ ├── coremodules # UI managers, input handlers, settings
│ │ ├── defmodules # Reusable local components
│ │ └── genmodules # Visual or reactive scripts
│ └── /defaultcodes
│ ├── corescripts # Client bootstrapping logic
│ ├── defscripts # UI logic, effects, HUD
│ └── genscripts # Client-side dynamic behaviors

## Conventions

- Modules = Modular systems set up within the game in an organized place used by their respective scripts, usually in large-scale.
- `core`, `def`, `gen` structure helps separate responsibilities:
  - `core`: foundational systems
  - `def`: default/standard gameplay logic/non-gameplay logic.
  - `gen`: procedural or runtime-generated on general scripts.

##

# ->> Script communication: Script communication can happen between codes through the useage of modules or events such as RemoteEvent, BindableFunction, BindableEvent, etc.
# ->>> For more information on events, please read: [https://create.roblox.com/docs/scripting/events].

## -> Related documents:

[README.md](./README.md) for documentation 1 (if you have not been redirected from there.
[AGENTS.md](./AGENTS.md) for documentation 2
