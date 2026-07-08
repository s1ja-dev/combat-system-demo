# Combat System Demo

A server-authoritative combat system for Roblox — melee **and** a raycast blaster — built in Luau with [Rojo](https://rojo.space/). Part of a Roblox scripting portfolio.

## What it demonstrates

- **Server-authoritative hit detection** — the client's `RequestAttack` remote carries **no payload at all**. The server independently finds the nearest valid target within range and inside a forward-facing cone, so there is nothing a modified client can lie about (no client-supplied target, damage, or hit part).
- **A second weapon with a different trust model** — the blaster's `RequestFire` remote *does* carry a payload (aim origin/direction), because a raycast weapon fundamentally needs to know where the client is aiming. `WeaponService` bounds that trust explicitly: it clamps range server-side and rejects any origin that isn't close to the attacker's actual position, rather than pretending a zero-payload design is possible for every weapon type.
- **Headshot detection**, two ways — melee decides it server-side by attacker-Head-to-target-Head proximity (no raycast needed at melee range); the blaster decides it from the exact part the raycast hit.
- **Health / death / respawn** — `Humanoid.Health` mutated only by the server, with a post-respawn invulnerability window centralized behind one `HealthService.ApplyDamage` call.
- **Ragdoll on death** — `RagdollService` swaps Motor6D joints for physically simulated BallSocketConstraints the instant a Humanoid dies (player or dummy), instead of a stiff death pose. Respawn always clones from a pristine, pre-ragdoll snapshot, so the next spawn's rig is never left half-broken.
- **NPC training dummies** — Workspace models tagged `CombatDummy` (via `CollectionService`) are valid targets alongside real players, so combat is testable solo. Dummies respawn by cloning (Roblox refuses to revive a Humanoid already in the Dead state).
- **Kill feed + floating damage numbers** — broadcast `CombatHit` events drive both a scrolling kill feed and per-hit damage text at the impact point, headshots called out distinctly.
- **Hit VFX/SFX/icons/weapon mesh — all live, not placeholders.** Particle packs are wired by reference (their textures are already public Roblox assets, no upload needed); SFX, UI icons, and the blaster's 3D mesh (a real Kenney model, not a block placeholder) were uploaded through the Roblox Open Cloud Assets API and are referenced by `rbxassetid`. `WeaponModel` still keeps a block-built fallback in case that asset is ever missing, so nothing breaks silently.

## Structure

```
src/shared/    Classes (Signal/Trove/Class), Net (Remotes/NetConstants), Config, Assets/VFX (particle packs)
src/server/    HealthService, DummyService, CombatService, WeaponService, WeaponModel, RagdollService
src/client/    CombatController + WeaponController (input), VfxController, HealthBar + KillFeed + DamageNumbers (UI)
```

See [`UI_REQUIREMENTS.md`](UI_REQUIREMENTS.md) for the remote/data contract the UI is built on — the visuals can be reskinned without touching game logic.

## Running

Needs an empty Roblox Studio place with the Rojo plugin connected:

```
rojo serve
```

Click a target within melee range to attack; land it on the head for a headshot (2× damage). Equip the Blaster from your hotbar to fight at range instead.
