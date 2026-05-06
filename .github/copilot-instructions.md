# ComputerCraft RedNet Chat System - AI Coding Instructions

## Project Overview
A multi-server chat system using ComputerCraft's RedNet networking. Multiple server implementations handle client registration and message broadcasting with different design maturity levels.

## Architecture & Components

### File Structure
- **rednetClient.lua**: Client-side chat interface (currently empty - placeholder)
- **rednetServer.lua**: Initial server implementation with bugs and incomplete handlers
- **rednetServerLive.lua**: Production-ready server implementation using versioned protocol

### Data Model Pattern
Maintain dual mappings for client tracking:
```lua
clients = {}     -- username → computer_id mapping
ids = {}         -- computer_id → username reverse mapping
```
This enables O(1) lookup in both directions for broadcast operations.

### Protocol Design
Use versioned protocol constants to prevent cross-version conflicts:
```lua
local PROTOCOL = "geekChat_v1"  -- Always use versioned names
rednet.receive(PROTOCOL)        -- Filter messages by protocol
```

## Message Flow & Handler Pattern
All handlers follow a signature: `handleX(id, message)` where:
- `id`: Computer ID sending the message
- `message`: Table containing `type` field (e.g., `"register"`, `"broadcast"`, `"whisper"`) and type-specific fields

**Key validation pattern** (from rednetServerLive.lua):
```lua
if message.type ~= "register" then return end
```
Always check message type at handler entry to enable stacking multiple handlers in main loop.

### Whisper/Direct Messaging Feature
Whisper messages enable direct private communication between users. Implementation details:
- **Server**: `handleWhisper` looks up recipient username and sends to their computer ID only
- **Client**: Prefix messages with `/w <username> <message>` to send direct messages
- **Message format**: `{ type = "whisper", recipient = "username", content = "..." }`

## Critical Bugs to Fix in rednetServer.lua
1. **Syntax error**: `!clients[username]` should be `not clients[username]` (Lua uses `not`, not `!`)
2. **Variable mismatch**: `id[id]` is undefined - should be `ids[id]` (reverse lookup table)
3. **Incomplete handleWhisper**: Function body is empty - needs to look up recipient username and send message to their computer ID only
4. **Registration typo**: `client[username]` exists but uses inconsistent naming with `clients`
5. **Missing modem initialization check**: rednetServerLive handles it correctly

## Known Patterns
- **Modem setup**: `peripheral.find("modem", rednet.open)` - idiomatic ComputerCraft startup
- **Main loop**: Infinite `while true` with `rednet.receive()` blocking on messages
- **Broadcast**: Loop over `ids` table to send to all connected clients
- **Error handling**: Return early from handlers if preconditions fail; send error packets to clients

## Client-Side Expectations (for rednetClient.lua)
- Expect `{ type = "register_ok" }` or `{ type = "error", msg = "..." }` responses from register
- Expect `{ type = "system", msg = "..." }` for server notifications (joins, leaves, etc.)
- Expect `{ type = "broadcast", from = username, msg = "..." }` for public messages
- Expect `{ type = "whisper", from = username, msg = "..." }` for private messages
- Send messages as tables: `{ type = "broadcast", content = "..." }` for public or `{ type = "whisper", recipient = "...", content = "..." }` for direct messaging
- Parse input starting with `/w` as whisper prefix: `/w <username> <message>` syntax

## Development Notes
- ComputerCraft Lua uses Lua 5.1 (not 5.3+) - no `~=` alternative operator
- Rednet is simulated networking; range limited in single-player worlds
- Test locally with multiple ComputerCraft emulator instances or FiveM-style environments
