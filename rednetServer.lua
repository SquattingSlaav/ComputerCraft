peripheral.find("modem", rednet.open)
 
function handleRegister(id, message)
    local username = message

    if not clients[username] then
        clients[username] = id
        rednet.send(id, "Registered successfully", "register")
    else
        rednet.send(id, "Username already taken", "register")
    end
end
 
function handleBroadcast(id, message)
    local username = id[id]
    rednet.broadcast(username .. ": " .. message, "broadcast")
end
 
function handleWhisper(id, message)
    local username = id[id]

end
 
clients = {}
id = {}
 
while true do
    local id, message, protocol = rednet.receive()
    
    if protocol == "register" then
        handleRegister(id, message)
    end

    if protocol == "broadcast" then
        handleBroadcast(id, message)
    end

    if protocol == "whisper" then
        handleWhisper(id, message)
    end
end