-- ＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿@
-- LUAスクリプト テンプレ(メニュー式じゃない) by TAPI
-- 
-- バグなどがあるかもしれないので修正できたらしときます
-- 
-- 質問などがあればDiscordにお願いします
-- DiscordURL⬇
-- https://discord.gg/6FQPgbBWGR
-- 
-- 範囲はXa
-- offsetの取得方法は自分で調べて( 'ω')b
--
--  _______                                    
-- |__   __|                   (_)                
--   | |      __ _     _ __    _ 
--   | |    / _`  |   | '_ \ \  | |
--   | |   | (_|  |   |  |_)  |  | | 
--   |_|    \__,_ \  |  __ /   |_|
--                 | |                      
--                |_|
-- ＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿@

local libName = "libSGF.so"--〘Main lib〙
local password = "1" --〘PassWord〙
local base = 0
local backupFile = "/sdcard/TAPIModBuckUp.lua"

function auth()
    local input = gg.prompt({"パスワードを入力してください"}, nil, {"text"})
    if input == nil or input[1] ~= password then
        gg.alert("パスワードが違います\nスクリプトを終了します。")
        os.exit()
    end
end

function getLibBase(lib)
    for _,v in ipairs(gg.getRangesList(lib)) do
        if v.state == "Xa" and v.type:sub(1,1) == "r" then
            return v.start
        end
    end
    gg.alert("ライブラリが見つかりません: " .. lib)
    os.exit()
end

function hexToBytes(hex)
    local bytes = {}
    for byte in hex:gmatch("%S+") do
        table.insert(bytes, tonumber(byte, 16))
    end
    return bytes
end

function readOriginal(offset, length)
    local addr = base + offset
    local values = {}
    for i = 0, length - 1 do
        table.insert(values, {address = addr + i, flags = gg.TYPE_BYTE})
    end
    return gg.getValues(values)
end

function patch(offset, hex, enable, backup)
    local addr = base + offset
    local bytes = hexToBytes(hex)
    if enable then
        local original = readOriginal(offset, #bytes)
        local values = {}
        for i, b in ipairs(bytes) do
            table.insert(values, {address = addr + i - 1, flags = gg.TYPE_BYTE, value = b})
        end
        gg.setValues(values)
        return original
    else
        if backup then
            gg.setValues(backup)
        end
    end
end

local features = {

    {name = "ワンパン", 
    offset = 0x325F76C, 
    hex = "80 00 00 54"
    },
    
    {name = "無敵", 
    offset = 0x345CD78, 
    hex = "00 08 21 1E"
    },
    
    {name = "スコアカンスト", 
    offset = 0x3458FD4, 
    hex = "01 C8 14 8B"
    }     --最後の } には , を付けない
    
}

local states = {}
local backups = {}

function restoreAll()
    for i, v in ipairs(features) do
        if states[i] and backups[i] then
            patch(v.offset, v.hex, false, backups[i])
            states[i] = false
        end
    end
end

function saveBackup()
    local file = io.open(backupFile, "w")
    if not file then return end
    for i, v in ipairs(states) do
        if v then file:write(i .. "\n") end
    end
    file:close()
    gg.toast("現在の状態をバックアップしました")
end

function loadBackup()
    local file = io.open(backupFile, "r")
    if not file then
        gg.alert("⚠️バックアップが見つかりません")
        return
    end
    for line in file:lines() do
        local i = tonumber(line)
        if i and features[i] then
            backups[i] = patch(features[i].offset, features[i].hex, true)
            states[i] = true
            gg.toast(features[i].name .. "〘使用状況｜ON〙")
        end
    end
    file:close()
end

function menu()
    local buttons = {}
    for i, v in ipairs(features) do
        local stateText = states[i] and "〘使用状況｜ON〙" or "〘使用状況｜OFF〙"
        buttons[i] = v.name .. " " .. stateText
    end
    local offset = #features
    buttons[offset + 1] = "機能バックアップ"
    buttons[offset + 2] = "機能バックアップ復元"
    buttons[offset + 3] = "スクリプト終了"

    local sel = gg.choice(buttons, nil, "🙂スクリプトテンプレ by TAPI\nTEST")
    if sel == nil then return end

    if sel == offset + 1 then
        saveBackup()
        return
    elseif sel == offset + 2 then
        loadBackup()
        return
    elseif sel == offset + 3 then
        restoreAll()
        os.remove(backupFile)
        gg.alert("スクリプトを終了しました。\nご利用ありがとうございました🙇‍♀️")
        os.exit()
    end

    if not states[sel] then
        backups[sel] = patch(features[sel].offset, features[sel].hex, true)
        states[sel] = true
        gg.toast(features[sel].name .. "〘使用状況｜ON〙")
    else
        patch(features[sel].offset, features[sel].hex, false, backups[sel])
        states[sel] = false
        gg.toast(features[sel].name .. "〘使用状況｜OFF〙")
    end
end

-- 起動処理
auth()
base = getLibBase(libName)
gg.alert("✅ パスワード認証成功\nスクリプトを開始します。")

while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        menu()
    end
    gg.sleep(200)
end
