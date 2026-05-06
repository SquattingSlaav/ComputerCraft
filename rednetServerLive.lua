local PROTOCOL = "geekChat_v1"
local clients = {}
local ids = {}

local function broadcast(packet)
    for _, clientId in pairs(clients) do
        rednet.send(clientId, packet, PROTOCOL)
    end
end

local function handleRegister(id, message)
    if message.type ~= "register" then return end

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
    if message.type ~= "broadcast" then return end

    local username = ids[id]
    if username == nil then
        rednet.send(id, { type = "error", msg = "Not registered" }, PROTOCOL)
        return
    end

    print("[SERVER] Broadcast from " .. username .. ": " .. message.content)
    broadcast({ type = "broadcast", from = username, msg = message.content })
end

local function handleWhisper(id, message)
    if message.type ~= "whisper" then return end

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

    print("[SERVER] Whisper from " .. username .. " to " .. message.recipient .. ": " .. message.content)
    rednet.send(recipientId, { type = "whisper", from = username, msg = message.content }, PROTOCOL)
end

peripheral.find("modem", rednet.open)

while true do
    local id, message = rednet.receive(PROTOCOL)
    handleRegister(id, message)
    handleBroadcast(id, message)
    handleWhisper(id, message)
end