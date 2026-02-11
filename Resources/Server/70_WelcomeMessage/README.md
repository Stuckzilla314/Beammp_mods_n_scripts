# WelcomeMessage Plugin

A simple BeamMP server plugin that welcomes players when they join and announces when they leave.

## Features

- Sends a personalized welcome message to joining players
- Announces to all players when someone joins
- Announces to all players when someone leaves
- Logs all join/leave events to the server console

## Installation

1. Copy the `70_WelcomeMessage` folder to your BeamMP server's `Resources/Server/` directory
2. Restart your BeamMP server

## Configuration

This plugin works out of the box with no configuration needed. You can customize the welcome messages by editing `main.lua`.

## Example Output

When a player joins:
```
[WelcomeMessage] John (ID: 0) joined the server
```

Chat messages:
- To joining player: "Welcome to the server, John!"
- To all players: "John has joined the server!"

When a player leaves:
- To all players: "John has left the server!"
