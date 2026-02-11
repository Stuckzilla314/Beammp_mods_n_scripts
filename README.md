# BeamMP Server Scripts & Mods

This repository contains scripts and mods for a BeamMP server. BeamMP is a multiplayer mod for BeamNG.drive that allows players to connect and play together.

## 📁 Directory Structure

```
.
├── Resources/
│   ├── Server/          # Server-side Lua scripts (plugins)
│   │   └── [PluginName]/
│   │       └── main.lua # Entry point for each plugin
│   └── Client/          # Client-side mods (vehicles, maps, etc.)
│       └── [ModName]/
├── docs/                # Documentation for scripts and mods
└── README.md
```

## 🚀 Getting Started

### Server Scripts (Lua Plugins)

Server scripts are located in `Resources/Server/`. Each plugin should have its own folder with a `main.lua` file as the entry point.

**Example Plugin Structure:**
```
Resources/Server/
└── MyPlugin/
    └── main.lua
```

**Basic Plugin Example:**
```lua
-- main.lua
function onInit()
    print("MyPlugin loaded successfully!")
end

MP.RegisterEvent("onInit", "onInit")
```

### Client Mods

Client mods (vehicles, maps, UI mods) go in `Resources/Client/`. These are sent to connected clients automatically.

## 📚 Common Events

BeamMP provides several events you can hook into:

- `onInit` - Called when the server starts
- `onPlayerConnect` - When a player connects
- `onPlayerJoin` - When a player fully joins
- `onPlayerDisconnect` - When a player disconnects
- `onChatMessage` - When a chat message is sent
- `onVehicleSpawn` - When a vehicle is spawned
- `onVehicleDeleted` - When a vehicle is deleted

## 🎮 Available Plugins

### DriftEvent
Professional drift competition system with real-time scoring and leaderboards.

**Features:**
- Timed drift events with admin-configurable duration
- Professional scoring based on Formula Drift criteria (angle, speed, proximity, time)
- Real-time leaderboard tracking
- Automatic event management with timer
- Player statistics and final results display

**Commands:**
- `/driftstart [seconds]` - Start event (admin only)
- `/driftstop` - End event (admin only)
- `/driftstatus` - Check event status and your score
- `/driftleaderboard` - View current rankings
- `/drifthelp` - Show help

**Documentation:** See [DriftEvent README](Resources/Server/DriftEvent/README.md)

### AdminTools
Basic admin commands for server management (kick, announce).

### WelcomeMessage
Sends welcome messages to players when they join.

## 🔧 Installation

1. Copy the desired plugin folder from `Resources/Server/` to your BeamMP server's `Resources/Server/` directory
2. Copy any client mods from `Resources/Client/` to your server's `Resources/Client/` directory
3. Restart your BeamMP server

## 📖 Resources

- [BeamMP Official Documentation](https://docs.beammp.com/)
- [BeamMP Wiki - Scripting](https://wiki.beammp.com/en/Scripting)
- [BeamMP Discord](https://discord.gg/beammp)
- [BeamMP GitHub](https://github.com/BeamMP)

## 🤝 Contributing

Feel free to submit pull requests with new scripts or improvements to existing ones!

## 📝 License

This repository contains scripts and mods for BeamMP servers. Please respect the licensing of individual mods and scripts.

---

**Note:** Make sure to test all scripts in a development environment before deploying to a production server.