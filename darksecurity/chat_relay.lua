-- Relay Tower Code with Server Range Check

-- Variables
local modemSide = nil
local relayID = os.getComputerID()  -- Get the current computer's ID (for identifying the relay tower)
local serverID = 1  -- ID of the final server
local relayAddresses = {}  -- List of relay tower addresses (100 to 200)
local messageHistory = {}  -- Stores the message send history
local targetAddress = nil  -- The next address the message will be sent to
local rangeThreshold = 5  -- Range to check for the server (modify as necessary)

-- Fill the relay addresses from 0 to 200
for i = 0, 200 do
    table.insert(relayAddresses, i)
end

-- Find and open the modem (works for both wired and wireless)
local modemDetected = false
while not modemDetected do
    local modem = peripheral.find("modem") or peripheral.find("wireless_modem")
    if modem then
        modemSide = peripheral.getName(modem)
        rednet.open(modemSide)
        modemDetected = true
        print("Modem connected successfully!")
    else
        os.sleep(1)
        print("Waiting for modem...")
    end
end

-- Ensure Rednet is open
if not rednet.isOpen(modemSide) then
    print("Failed to open Rednet!")
    return
else
    print("Rednet is open.")
end

-- Check if the server is within range (this can be based on proximity, signal strength, or IDs)
local function isServerInRange()
    -- For simulation, we just randomly decide if the server is in range
    -- In real applications, you can check signal strength or directly query the server for acknowledgment
    local serverProximity = math.random(1, 10)  -- Simulate server proximity
    if serverProximity <= rangeThreshold then
        return true
    else
        return false
    end
end

-- Send message to the next tower or the server
local function sendToNext(message, currentID)
    local nextAddress
    if currentID == serverID then
        print("Message reached the server!")
        table.insert(messageHistory, "Message received by server")
        return  -- Stop here if the message reached the server
    else
        -- Check if the server is in range
        if isServerInRange() then
            print("Server is in range. Sending directly to server.")
            rednet.send(serverID, message)  -- Send directly to the server if it's in range
            table.insert(messageHistory, "Sent to server directly")
        else
            -- Find the next relay tower to send the message to
            nextAddress = relayAddresses[math.random(1, #relayAddresses)]  -- Randomly choose the next relay tower
            print("Relaying message from " .. currentID .. " to " .. nextAddress)
            rednet.send(nextAddress, message)  -- Send the message to the next relay tower
            table.insert(messageHistory, "Sent to " .. nextAddress)
        end
    end
end

-- Display the message history on the screen
local function displayHistory()
    term.clear()
    term.setCursorPos(1, 1)
    local historyString = "Message Send History:\n"
    for i, history in ipairs(messageHistory) do
        historyString = historyString .. history .. "\n"
    end
    print(historyString)
    print("Displayed message history.")
end

-- Main loop to listen for incoming messages and handle them
local function listenForMessages()
    while true do
        print("Waiting for messages...")
        local id, message = rednet.receive()  -- Wait for a message
        if id then
            -- Display received message and update history
            print("Received message: " .. message)
            table.insert(messageHistory, "Received from " .. id .. ": " .. message)

            -- Display the message send history
            displayHistory()

            -- Send the message to the next tower or server
            sendToNext(message, relayID)
        end
    end
end

-- Start listening for messages
listenForMessages()
