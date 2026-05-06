local PROTOCOL = "geekChat_v1"
local clients = {}
local ids = {}

local function broadcast(packet, excludeId)
    if not packet or not packet.type then return end
    for clientId, username in pairs(ids) do
        if clientId and type(clientId) == "number" and clientId ~= excludeId then
            rednet.send(clientId, packet, PROTOCOL)
        end
    end
end

local function handleRegister(id, message)
    if not (message.type == "register") then return end

    local username = message.username
    
    -- If username already exists, remove the old connection first
    if clients[username] ~= nil then
        local oldId = clients[username]
        ids[oldId] = nil
        broadcast({ type = "system", msg = username .. " reconnected" })
    end

    clients[username] = id
    ids[id] = username
    print("[SERVER] " .. username .. " registered from computer " .. id)
    rednet.send(id, { type = "register_ok" }, PROTOCOL)
    broadcast({ type = "system", msg = username .. " has joined the chat!"})
end

local function handleBroadcast(id, message)
    if not (message.type == "broadcast") then return end

    local username = ids[id]
    if username == nil then
        rednet.send(id, { type = "error", msg = "Not registered" }, PROTOCOL)
        return
    end

    local content = message.content or ""
    print("[SERVER] Broadcast from " .. username .. ": " .. content)
    broadcast({ type = "broadcast", from = username, msg = content }, id)
end

local function handleWhisper(id, message)
    if not (message.type == "whisper") then return end

    local username = ids[id]
    if username == nil then
        rednet.send(id, { type = "error", msg = "Not registered" }, PROTOCOL)
        return
    end

    local recipientId = clients[message.recipient]
    if recipientId == nil then
        rednet.send(id, { type = "error", msg = "User not found" }, PROTOCOL)
        return
    end

    local content = message.content or ""
    print("[SERVER] Whisper from " .. username .. " to " .. message.recipient .. ": " .. content)
    rednet.send(recipientId, { type = "whisper", from = username, msg = content }, PROTOCOL)
end

peripheral.find("modem", rednet.open)

while true do
    local id, message = rednet.receive(PROTOCOL)
    handleRegister(id, message)
    handleBroadcast(id, message)
    handleWhisper(id, message)
end