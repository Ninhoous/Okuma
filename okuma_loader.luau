-- Okuma loader
-- Use:  loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/okuma_loader.luau"))()
-- Checks the current game; runs the matching Okuma script, otherwise shows a "not supported" notification.

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

local entry = GAMES[game.PlaceId]
if not entry then
    notify("Okuma", "Não temos suporte para este jogo ainda.", 7)
    return
end

local src = fetch(entry.file)
if not src then
    notify("Okuma", "Não consegui baixar o script de " .. entry.name .. ".", 7)
    return
end

local fn, err = loadstring(src)
if not fn then
    notify("Okuma", "Erro ao carregar " .. entry.name .. ".", 7)
    return
end

local ok, runErr = pcall(fn)
if not ok then
    notify("Okuma", "Erro ao executar " .. entry.name .. ".", 7)
end
