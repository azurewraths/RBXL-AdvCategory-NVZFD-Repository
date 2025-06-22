# ARCHITECTURE.md

## 📌 Overview

This repository contains the Luau-based architecture and scripts of the ROBLOX multiplayer game **Noobs V.S. Zombies: Frontier Defense** — a game rich with complex systems, modular logic, and scalable design.

---

## 📦 Conventions

- **Modules**: Reusable Lua systems used by client or server logic, usually encapsulating functionality (e.g. combat, movement, UI).
- `core`, `def`, and `gen` prefixes indicate:
  - `core`: foundational systems (frameworks, startup logic)
  - `def`: default, static systems (standard gameplay, common patterns)
  - `gen`: dynamically generated content (loot tables, procedural systems)

---

## 🔁 Script Communication

Scripts interact via:
- **Modules** (`require`) for code reuse
- **RemoteEvents / RemoteFunctions** for client-server communication
- **BindableEvents / BindableFunctions** for in-context messaging (server-server or client-client)
- **UnreliableRemoteEvent / UnreliableEvent** (...)

For more about ROBLOX events:
- [ROBLOX Events Overview](https://create.roblox.com/docs/scripting/events)
- [Bindable Events](https://create.roblox.com/docs/pt-br/scripting/events/bindable)
- [Remote Events](https://create.roblox.com/docs/pt-br/scripting/events/remote)

---

## 📚 Related Documentation

- [📖 Main Documentation (README)](./README.md) -- If the individual has not been redirected from there to here.
- [🤖 Agent Setup](./AGENTS.md)


