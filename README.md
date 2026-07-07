# Combat System Demo

A server-authoritative melee combat system for Roblox, built in Luau with [Rojo](https://rojo.space/). Part of a Roblox scripting portfolio.

## What it demonstrates

- **Server-authoritative hit detection** — the client's `RequestAttack` remote carries **no payload at all**. The server independently finds the nearest valid target within range and inside a forward-facing cone, so there is nothing a modified client can lie about (no client-supplied target, damage, or hit part).
- **Headshot detection** — decided server-side by comparing the attacker's Head to the target's Head, no client trust and no raycasting needed for melee range.
- **Health / death / respawn** — `Humanoid.Health` mutated only by the server, with a post-respawn invulnerability window centralized behind one `HealthService.ApplyDamage` call.
- **NPC training dummies** — Workspace models tagged `CombatDummy` (via `CollectionService`) are valid targets alongside real players, so combat is testable solo. Dummies respawn by cloning (Roblox refuses to revive a Humanoid already in the Dead state).
- **Kill feed** — broadcast `CombatHit` events, headshots called out distinctly.

## Structure

```
src/shared/    Classes (Signal/Trove/Class), Net (Remotes/NetConstants), Config
src/server/    HealthService, DummyService, CombatService
src/client/    CombatController (input), HealthBar + KillFeed (UI)
```

See [`UI_REQUIREMENTS.md`](UI_REQUIREMENTS.md) for the remote/data contract the UI is built on — the visuals can be reskinned without touching game logic.

## Running

Needs an empty Roblox Studio place with the Rojo plugin connected:

```
rojo serve
```

Click a target within melee range to attack; land it on the head for a headshot (2× damage).
