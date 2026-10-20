local function _okumaGuard()
    local score, why = 0, ""
    local function hit(points, code) score = score + points; why = why .. code end
    local function W(...) return table.concat({ ... }) end
    local genv = (type(getgenv) == "function" and getgenv()) or _G
    local isl = type(islclosure) == "function" and islclosure or nil
    local function isLua(f)
        if type(f) ~= "function" then return false end
        local viaInfo = false
        local okI, src = pcall(debug.info, f, "s")
        if okI and type(src) == "string" and src ~= "[C]" then viaInfo = true end
        local viaIsl = false
        if isl then local okL, r = pcall(isl, f); viaIsl = okL and r == true end
        return viaInfo or viaIsl
    end

    -- 1. the Roblox / Luau base library must still be native: a spy wraps these in Lua closures
    local base = {
        pcall, xpcall, tostring, tonumber, type, typeof, select, rawget, rawset, rawequal, setmetatable, getmetatable,
        next, pairs, ipairs, error, assert, unpack, string.char, string.byte, string.sub, string.gsub, string.format,
        string.find, string.rep, table.concat, table.insert, table.remove, math.floor, bit32.bxor, Instance.new,
        game.GetService, game.FindFirstChild, os.time, os.clock, task.spawn, task.wait, task.delay,
    }
    local hooked = 0
    for i = 1, 40 do
        local f = base[i]
        if f ~= nil and isLua(f) then hooked = hooked + 1 end
    end
    if hooked > 0 then hit(100, "A") end

    -- 2. the executor functions that carry code or traffic: a wrapper around them is a logger
    local exec = {
        { "loadstring", loadstring }, { "request", request }, { "http_request", http_request },
        { "readfile", readfile }, { "writefile", writefile }, { "setclipboard", setclipboard },
        { "getgenv", getgenv }, { "hookfunction", hookfunction }, { "newcclosure", newcclosure },
    }
    local wrapped = 0
    for _, e in ipairs(exec) do
        if e[2] ~= nil and isLua(e[2]) then wrapped = wrapped + 1 end
    end
    if wrapped >= 2 then hit(60, "B") elseif wrapped == 1 then hit(30, "b") end
    if syn and type(syn.request) == "function" and isLua(syn.request) then hit(30, "c") end
    pcall(function()
        if isLua(game.HttpGet) or isLua(game.HttpGetAsync) then hit(60, "C") end
    end)

    -- 3. the namecall / index metamethods of game: spies swap these
    pcall(function()
        if type(getrawmetatable) ~= "function" then return end
        local mt = getrawmetatable(game)
        if mt then
            if isLua(rawget(mt, "__namecall")) then hit(60, "D") end
            if isLua(rawget(mt, "__index")) then hit(40, "d") end
            if isLua(rawget(mt, "__newindex")) then hit(30, "e") end
        end
    end)

    -- 4. a known tool leaves its name in the globals
    local names = { "simplespy", "hydroxide", "remotespy", "cobalt", "httpspy", "dumper", "scriptdumper", "scriptlogger",
        "loadstringlog", "loadstringspy", "unveilspy", "ronin", "turtlespy", "rbxdumper", "executorlogger", "luadumper",
        "envlogger", "hookspy", "networkspy", "requestlogger", "interceptor", "unobfuscat", "deobfuscat", "devirtualiz", "decompiler" }
    local function nameHit(k)
        if type(k) ~= "string" then return false end
        local l = k:lower()
        for _, n in ipairs(names) do if l:find(n, 1, true) then return true end end
        return false
    end
    for _, env in ipairs({ genv, _G, shared }) do
        if type(env) == "table" then
            pcall(function() for k in pairs(env) do if nameHit(k) then hit(100, "E") break end end end)
        end
    end

    -- 5. a known tool leaves a window or a script behind (the places an executor hides them are all searched)
    pcall(function()
        local roots = {}
        pcall(function() roots[#roots + 1] = game:GetService("CoreGui") end)
        pcall(function() if gethui then roots[#roots + 1] = gethui() end end)
        pcall(function() roots[#roots + 1] = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
        pcall(function() roots[#roots + 1] = game:GetService("ReplicatedFirst") end)
        pcall(function() roots[#roots + 1] = game:GetService("Lighting") end)
        local seen = 0
        for _, r in ipairs(roots) do
            for _, d in ipairs(r:GetDescendants()) do
                seen = seen + 1
                if seen % 600 == 0 then task.wait() end
                if nameHit(d.Name) then hit(100, "F") return end
            end
        end
        if type(getnilinstances) == "function" then
            for _, d in ipairs(getnilinstances()) do
                if (d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("ScreenGui")) and nameHit(d.Name) then hit(100, "G") return end
            end
        end
        if type(getloadedmodules) == "function" then
            for _, m in ipairs(getloadedmodules()) do if nameHit(m.Name) then hit(100, "H") return end end
        end
    end)

    -- 6. a logger lives in the garbage collector: a Lua function that touches loadstring AND a place to write it
    pcall(function()
        if type(getgc) ~= "function" or not (debug.getconstants or getconstants) then return end
        local getc = debug.getconstants or getconstants
        local a, b = W("load", "string"), W("Http", "Get")
        local sinks = { W("write", "file"), W("append", "file"), W("set", "clipboard"), W("to", "clipboard"), W("web", "hook"), W("discord", ".com/api") }
        local checked, found = 0, 0
        for _, f in ipairs(getgc(false)) do
            if type(f) == "function" and isLua(f) and f ~= _okumaGuard then
                checked = checked + 1
                if checked > 6000 then break end
                if checked % 400 == 0 then task.wait() end
                local okC, cs = pcall(getc, f)
                if okC and type(cs) == "table" then
                    local hasA, hasSink = false, false
                    for _, c in pairs(cs) do
                        if type(c) == "string" then
                            local l = c:lower()
                            if l == a or l == b then hasA = true end
                            for _, s in ipairs(sinks) do if l:find(s, 1, true) then hasSink = true end end
                        end
                    end
                    if hasA and hasSink then found = found + 1 end
                end
            end
        end
        if found >= 3 then hit(60, "I") elseif found >= 1 then hit(20, "i") end
    end)

    -- 7. a hooked function costs more time than a native one: a native call is far below a microsecond
    pcall(function()
        local clock = os.clock
        local t = clock()
        for _ = 1, 3000 do local _ = tostring(1); local _ = type(1); local _ = string.char(65) end
        if clock() - t > 0.02 then hit(40, "T") end
    end)

    return score >= 100, why
end

-- Okuma loader
-- Use:  loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/okuma_loader.luau"))()
-- Checks the current game; runs the matching Okuma script, otherwise shows a "not supported" notification.
-- Before anything is downloaded the environment is searched for loggers and dumpers; if one is found nothing runs.

local BASE_URL = "https://raw.githubusercontent.com/Ninhoous/Okuma/main/Completed/" -- folder holding the game scripts
local LOCAL_DIR = "Okuma/Completed/" -- fallback inside the executor workspace (used if BASE_URL fails)

-- PlaceId -> { name, file }
local GAMES = {
    [189707]    = { name = "Natural Disaster Survival", file = "okuma_nds.luau" },
    [286090429] = { name = "Arsenal",                   file = "okuma_arsenal.luau" },
}

local StarterGui = game:GetService("StarterGui")

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = duration or 6 })
    end)
end

local function blocked(why)
    notify("Okuma", "Ambiente não permitido (" .. tostring(why) .. ").", 8)
end

local entry = GAMES[game.PlaceId]
if not entry then
    notify("Okuma", "Não temos suporte para este jogo ainda.", 7)
    return
end

-- check 1: before the first request
local bad, why = _okumaGuard()
if bad then blocked(why) return end

local function fetch(file)
    local ok, src = pcall(function() return game:HttpGet(BASE_URL .. file) end)
    if ok and type(src) == "string" and #src > 0 and not src:find("^404") then return src end
    if readfile and isfile then
        local path = LOCAL_DIR .. file
        local okLocal, has = pcall(isfile, path)
        if okLocal and has then
            local okRead, data = pcall(readfile, path)
            if okRead and data and #data > 0 then return data end
        end
    end
    return nil
end

local src = fetch(entry.file)
if not src then
    notify("Okuma", "Não consegui baixar o script de " .. entry.name .. ".", 7)
    return
end

-- check 2: a logger can be started while the download is running, so look again right before the code is compiled
bad, why = _okumaGuard()
if bad then blocked(why) return end

local fn, err = loadstring(src)
if not fn then
    notify("Okuma", "Erro ao carregar " .. entry.name .. ".", 7)
    return
end

local ok, runErr = pcall(fn)
if not ok then
    notify("Okuma", "Erro ao executar " .. entry.name .. ".", 7)
end
