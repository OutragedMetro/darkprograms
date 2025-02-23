os.pullEvent = os.pullEventRaw

-- Variables
local serverChannel = 1  -- Channel for receiving messages
local historyFilePath = "/server_chat_history"  -- File to store chat history
local modemSide = nil

-- Find and open the modem (works for both wired and wireless)
local modemDetected = false
local startTime = os.time()
while os.time() - startTime < 10 do
    local modem = peripheral.find("modem") or peripheral.find("wireless_modem")
    if modem then
        modemSide = peripheral.getName(modem)
        rednet.open(modemSide)
        modemDetected = true
        print("Modem detected and Rednet opened on:", modemSide)
        break
    end
    os.sleep(1)  -- Wait 1 second before retrying
end

if not modemDetected then
    term.clear()
    term.setCursorPos(1, 1)
    print("No modems detected after 10 seconds. Please attach or enable a modem.")
    os.sleep(3)  -- Allow time to read the message before attempting to restart
    shell.run("reboot")  -- Option to reboot the system or exit to fix the modem issue
end

-- Ensure Rednet is open
if not rednet.isOpen(modemSide) then
    error("Failed to open Rednet on " .. modemSide)
end

-- Load chat history from file if available
local function loadHistory()
    local history = {}
    if fs.exists(historyFilePath) then
        local file = fs.open(historyFilePath, "r")
        local line = file.readLine()
        while line do
            table.insert(history, line)
            line = file.readLine()
        end
        file.close()
    end
    return history
end

-- Save chat history to file
local function saveHistory(history)
    local file = fs.open(historyFilePath, "w")
    for _, line in ipairs(history) do
        file.writeLine(line)
    end
    file.close()
end

-- Log the incoming message
local function logMessage(sender, message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logLine = string.format("[%s] %s: %s", timestamp, sender, message)
    local history = loadHistory()
    table.insert(history, 1, logLine)  -- Add new message to the beginning
    saveHistory(history)
    print(logLine)  -- Display the message on the server screen
end

-- Clear the screen and display a header
local function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.green)  -- Change to green for header
    print("---- Server Chat Log ----")
    term.setTextColor(colors.white)  -- Reset color to white for messages
end

-- Main server loop
local function serverLoop()
    clearScreen()
    print("Server is listening for messages...")
    
    -- Load chat history and display on screen
    local history = loadHistory()
    for _, line in ipairs(history) do
        print(line)
    end

    -- Listen for incoming messages and display them
    while true do
        local senderID, message = rednet.receive(serverChannel)  -- Wait for message from client
        if message then
            logMessage(senderID, message)  -- Log and display the message
        end
    end
end

-- Start the server
serverLoop()
