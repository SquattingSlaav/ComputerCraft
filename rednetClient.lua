local PROTOCOL = "geekChat_v1"
local SERVER_ID = 1

peripheral.find("modem", rednet.open)

local username
repeat
    write("Enter username: ")
    username = read()
    rednet.broadcast({ type = "register", username = username }, PROTOCOL)
    local _, response = rednet.receive(PROTOCOL)
    if response and response.type == "error" then
        print(response.msg)
    elseif response and response.type == "register_ok" then
        break
    end
until false

print("Connected as " .. username)
print("Type /w USERNAME MESSAGE for private messages")
print("Type your message and press Enter to broadcast")

local function parseInput(input)
    if input:sub(1, 3) == "/w " then
        local parts = {}
        for part in input:gmatch("%S+") do
            table.insert(parts, part)
        end
        if #parts >= 3 then
            local recipient = parts[2]
            local content = table.concat(parts, " ", 3)
            return { type = "whisper", recipient = recipient, content = content }
        else
            return nil
        end
    else
        return { type = "broadcast", content = input }
    end
end

local function receiveMessages()
    while true do
        local _, message = rednet.receive(PROTOCOL, 0.1)
        if message then
            if type(message) == "table" and message.type then
                if message.type == "broadcast" then
                    if message.from ~= username then
                        print("[" .. (message.from or "Unknown") .. "]: " .. (message.msg or ""))
                    end
                elseif message.type == "whisper" then
                    print("[WHISPER from " .. (message.from or "Unknown") .. "]: " .. (message.msg or ""))
                elseif message.type == "system" then
                    print("[SYSTEM]: " .. (message.msg or ""))
                elseif message.type == "error" then
                    print("[ERROR]: " .. (message.msg or ""))
                end
            end
        end
    end
end

local function handleInput()
    while true do
        write("> ")
        local input = read()
        
        if input ~= "" then
            local message = parseInput(input)
            if message then
                rednet.broadcast(message, PROTOCOL)
            else
                print("[ERROR] Invalid whisper format. Use: /w USERNAME MESSAGE")
            end
        end
    end
end

parallel.waitForAny(receiveMessages, handleInput)