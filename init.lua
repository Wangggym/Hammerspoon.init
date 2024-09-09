-- 保存之前激活的应用程序
local previousApp = nil

-- 定义右 Command 键状态
local rightCmdPressed = false

-- 监听 flagsChanged 事件
local flagsChangedTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    local flags = event:getFlags()
    -- 检查右 Command 键状态
    if flags.cmd then
        if event:getKeyCode() == 0x36 then -- 0x36 是右 Command 键的键码
            rightCmdPressed = event:getType() == hs.eventtap.event.types.flagsChanged
        end
    else
        rightCmdPressed = false
    end
    return false
end)

local function judgeCodeEditorAndOthers(keyCode, alertMessage, keystroke)
    local vscode = hs.application.find("Code")
    local cursor = hs.application.find("Cursor")
    if cursor and cursor:isRunning() then
        codeEditor = cursor
    elseif vscode and vscode:isRunning() then
        codeEditor = vscode
    end

    if codeEditor then
        hs.alert.show(alertMessage, 0.5)
        codeEditor:activate()
        hs.eventtap.keyStroke(table.unpack(keystroke))
    else
        hs.alert.show("Cursor 或 Visual Studio Code 未运行")
    end
    return true
end

-- 监听键盘按键事件
local keyDownTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    if rightCmdPressed then
        if event:getKeyCode() == hs.keycodes.map.j then
            local clipboard = hs.pasteboard.getContents()
            if clipboard then
                local success, result = pcall(function()
                    local jsonObject = hs.json.decode(clipboard)
                    local jsonString = hs.json.encode(jsonObject)
                    hs.pasteboard.setContents(jsonString)
                    return true
                end)

                if success then
                    hs.alert.show("JSON object successfully converted to string and copied to clipboard", 1)
                else
                    hs.alert.show("Conversion failed: Clipboard content is not valid JSON", 2)
                end
            else
                hs.alert.show("Clipboard is empty", 2)
            end
            return true
        end
        if event:getKeyCode() == hs.keycodes.map.t then
            local chrome = hs.application.find("Chrome")
            if chrome then
                hs.alert.show("Command + T", 0.5)
                chrome:activate()
                hs.eventtap.keyStroke({"cmd"}, "T")
            else
                hs.alert.show("Chrome is not running")
            end
            return true
        end
        if event:getKeyCode() == hs.keycodes.map.r then
            local cursor = hs.application.find("Cursor")
            local vscode = hs.application.find("Code")
            local codeEditor = nil
            if cursor and cursor:isRunning() then
                codeEditor = cursor
            elseif vscode and vscode:isRunning() then
                codeEditor = vscode
            end
            if codeEditor then
                hs.alert.show("Command + R", 0.5)
                previousApp = hs.application.frontmostApplication()
                codeEditor:activate()
                hs.eventtap.keyStroke({"shift", "cmd"}, "F5")
                if previousApp and previousApp ~= codeEditor then
                    hs.timer.doAfter(0.3, function()
                        previousApp:activate()
                        previousApp = nil
                    end)
                end
            else
                hs.alert.show("Cursor or Visual Studio Code is not running")
            end
            return true
        end

        if event:getKeyCode() == hs.keycodes.map.n then
            return judgeCodeEditorAndOthers(hs.keycodes.map.n, "Command + N", {{"cmd"}, "N"})
        end

        if event:getKeyCode() == hs.keycodes.map.p then
            return judgeCodeEditorAndOthers(hs.keycodes.map.p, "Command + P", {{"cmd"}, "P"})
        end

        if event:getKeyCode() == hs.keycodes.map.g then
            return judgeCodeEditorAndOthers(hs.keycodes.map.g, "Command + G", {{"option"}, "G"})
        end

    end
    return false
end)

-- 启动事件监听
flagsChangedTap:start()
keyDownTap:start()

-- 定义一个函数来监控并重启事件监听器
local function monitorAndRestart(tap, name)
    if not tap:isEnabled() then
        print(name .. " 监听器已被关闭，正在重启...")
        hs.alert.show(name .. " 监听器已被关闭，正在重启...")
        tap:start()
    end
end

-- 使用 hs.uielement.watcher 监控 Hammerspoon 状态变化
local function hammerspoonWatcher(element, event, watcher, info)
    if event == hs.uielement.watcher.elementDestroyed then
        -- 监听器被禁用，重新启动监听器
        monitorAndRestart(flagsChangedTap, "flagsChangedTap")
        monitorAndRestart(keyDownTap, "keyDownTap")
    end
end

-- 创建并启动 Hammerspoon 状态变化监控
local app = hs.application.get("Hammerspoon")
if app then
    local watcher = app:newWatcher(hammerspoonWatcher)
    watcher:start({hs.uielement.watcher.elementDestroyed})
end
