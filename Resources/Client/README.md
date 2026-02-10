# Client Mods

This directory contains client-side mods that will be sent to players when they connect to the server.

## What are Client Mods?

Client mods can include:
- Custom vehicles
- Maps
- UI modifications
- Sound packs
- Any other BeamNG.drive mod content

## How to Add Mods

1. Place your mod zip files or folders in this directory
2. The BeamMP server will automatically send them to clients when they connect
3. Clients must have enough download bandwidth and storage space

## Mod Structure

Mods should follow the standard BeamNG.drive mod structure:

```
ModName/
├── info.json          # Mod metadata
├── vehicles/          # Vehicle files (if applicable)
├── levels/            # Map files (if applicable)
└── lua/               # Lua scripts (if applicable)
```

## Notes

- Large mods may take time to download for clients
- Ensure all mods are compatible with the current BeamNG.drive version
- Test mods in single-player before deploying to the server
- Some mods may conflict with each other - test thoroughly

## Finding Mods

Popular sources for BeamNG.drive mods:
- [BeamNG.drive Official Repository](https://www.beamng.com/resources/)
- [BeamNG.drive Forums](https://www.beamng.com/forums/)
- Community mod creators

**Important:** Always respect mod creators' licenses and terms of use. Only distribute mods you have permission to share.
