# Admin Commands Quick Reference

A quick reference card for BeamMP server administrators.

## Essential Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/help` | Show available commands | `/help` |
| `/kick [id]` | Kick a player | `/kick 2` |
| `/announce [msg]` | Server announcement | `/announce Welcome!` |

## Teleportation

| Command | Description | Example |
|---------|-------------|---------|
| `/tp [id]` | Teleport to player | `/tp 1` |
| `/tphere [id]` | Teleport player to you | `/tphere 2` |
| `/tpall` | Teleport all to you | `/tpall` |

## Vehicle Control

| Command | Description | Example |
|---------|-------------|---------|
| `/freeze [id]` | Freeze vehicle | `/freeze 3` |
| `/unfreeze [id]` | Unfreeze vehicle | `/unfreeze 3` |
| `/explode [id]` | Explode vehicle | `/explode 1` |
| `/resetvehicle [id]` | Reset vehicle | `/resetvehicle 2` |

## Events

| Command | Description | Example |
|---------|-------------|---------|
| `/events` | List all events | `/events` |
| `/startevent [name]` | Start an event | `/startevent race` |
| `/stopevent` | Stop current event | `/stopevent` |

## Available Events

### Built-in (EventManager)
- `race` - Standard race event
- `derby` - Demolition derby
- `freeroam` - Free exploration

### Custom (CustomEvents plugin)
- `timetrial` - Time trial race
- `tag` - Tag game
- `convoy` - Follow the leader
- `policechase` - Cops vs robbers
- `carshow` - Vehicle showcase

## Common Workflows

### Starting an Event
```
/announce Race in 2 minutes!
/tpall
/startevent race
```

### Organizing Players
```
/tpall
/freeze [each player ID]
(give instructions)
/unfreeze [each player ID]
```

### Handling Rule Violations
```
/announce [Player ID] please follow rules
/freeze [id]
(warning)
/unfreeze [id]
```
If problem continues:
```
/kick [id]
```

## Tips
- Always announce before major actions
- Give warnings before kicks
- Use `/tpall` to gather players for events
- Freeze players for screenshots/organization
- Use `/announce` to keep players informed

## Player ID Reference
Player IDs are shown when players connect. Check the server console to see current player IDs.

---
For detailed information, see [ADMIN_GUIDE.md](ADMIN_GUIDE.md)
