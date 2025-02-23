os.pullEvent = os.pullEventRaw

-- Check if running on a pocket computer
local isPocket = pocket and true or false

-- Variables
local msg = ""
local MH = {}
local historyFilePath = "/.chat_history"
local nameFilePath = "/.chat_username"
local modemSide = nil
local name = ""

-- Load chat history from file if available
if fs.exists(historyFilePath) then
    local file = fs.open(historyFilePath, "r")
    local line = file.readLine()
    while line do
        table.insert(MH, line) -- Newest messages at the bottom
        line = file.readLine()
    end
    file.close()
end

-- Load or ask for username
if fs.exists(nameFilePath) then
    local file = fs.open(nameFilePath, "r")
    name = file.readLine()
    file.close()
else
    term.write("Name: ")
    name = read()
    local file = fs.open(nameFilePath, "w")
    file.writeLine(name)
    file.close()
end

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

-- Clear the terminal
local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Display the startup message/logo
local function displayStartupMessage()
    clear()
    term.setTextColor(colors.green)  -- Emerald color
    local screenWidth, screenHeight = term.getSize()
    local message = "Emerald Wireless!"
    
    -- Ensure the message fits on the screen (adjust for Pocket Computer if needed)
    if #message > screenWidth then
        message = message:sub(1, screenWidth)  -- Trim the message if it's too long
    end

    -- Calculate the position to center the message
    local xPos = math.floor((screenWidth - #message) / 2) + 1
    local yPos = math.floor(screenHeight / 2)

    -- Set cursor to the calculated position
    term.setCursorPos(xPos, yPos)
    print(message)
    
    term.setTextColor(colors.white)  -- Default color for subsequent text
    os.sleep(2)  -- Display the logo for 2 seconds
    clear()  -- Clear the screen after the logo
end

-- Save chat history to file
local function saveHistory()
    local file = fs.open(historyFilePath, "w")
    for _, line in ipairs(MH) do
        file.writeLine(line)
    end
    file.close()
end

-- Send message via Rednet
local function send(MSg)
    rednet.broadcast(name .. ": " .. MSg)
end

-- Draw the chat screen
local function drawScreen(Msg)
    clear()
    local screenWidth, screenHeight = term.getSize()
    local linesToShow = isPocket and 5 or 18  -- Adjust the number of lines to show based on screen size
    local startIdx = math.max(1, #MH - linesToShow)  -- Get the last `linesToShow` messages

    -- Print the chat history starting from the last message
    for i = startIdx, #MH do
        term.setCursorPos(1, screenHeight - (linesToShow - (i - startIdx)))  -- Position messages just above the input line
        print(MH[i])
    end

    -- Print the current message input at the bottom
    term.setCursorPos(1, screenHeight)  -- Set the cursor at the bottom of the screen
    print(Msg)
end

-- Clear old messages (older than 2 days)
local function clearOldMessages()
    local currentTime = os.time()
    local maxAge = 2 * 24 * 60 * 60 -- 2 days

    local newMH = {}
    for _, line in ipairs(MH) do
        local timestamp = tonumber(line:match("^%[(%d+)%]"))
        if not timestamp or currentTime - timestamp <= maxAge then
            table.insert(newMH, line)
        end
    end

    MH = newMH
    saveHistory()
end

-- Delete all chat history
local function deleteHistory()
    MH = {}
    saveHistory()
end

-- Main chat loop
local function runTime()
    local historyStart = 1
    local linesToShow = isPocket and 5 or 18
    local screenWidth, screenHeight = term.getSize()

    while true do
        -- Draw the screen before asking for input
        drawScreen("Enter a message: " .. msg)

        local event, a, b, c = os.pullEvent()

        if event == "char" then
            msg = msg .. a
        elseif event == "key" then
            if a == keys.backspace then
                msg = msg:sub(1, #msg - 1)
            elseif a == keys.enter and msg ~= "" then
                -- Send the message
                send(msg)

                -- Add the message to the history immediately after sending it
                table.insert(MH, name .. ": " .. msg)
                saveHistory()

                -- Clear the message input box
                msg = ""

                -- Update the screen immediately to show the new message
                drawScreen("Enter a message: ")
            elseif a == keys.up then
                historyStart = math.max(1, historyStart - 1)
            elseif a == keys.down then
                historyStart = math.min(#MH - linesToShow + 1, historyStart + 1)
            elseif a == keys.d and c == true then
                term.clear()
                term.setCursorPos(1, 1)
                term.setTextColor(colors.red)
                term.write("Delete chat history? (Y/N): ")
                local confirmation = read():lower()
                if confirmation == "y" then
                    deleteHistory()
                end
            end
        elseif event == "rednet_message" then
            -- Add the received message to the history and update the screen
            table.insert(MH, name .. ": " .. b)
            saveHistory()

            -- Immediately draw the updated chat
            drawScreen("Enter a message: " .. msg)
        end

        clearOldMessages() -- Remove old messages
    end
end

-- Show startup message/logo
displayStartupMessage()

-- Start chat application
runTime()
