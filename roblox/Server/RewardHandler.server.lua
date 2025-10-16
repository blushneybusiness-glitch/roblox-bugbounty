-- RewardHandler.server.lua
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Module.Config)

local function deliverRewardToPlayer(player, reward)
    local stats = player:FindFirstChild("leaderstats")
    if stats and stats:FindFirstChild("Credits") then
        stats.Credits.Value = stats.Credits.Value + reward.amount
    end
    local ok, res = pcall(function()
        local payload = HttpService:JSONEncode({ caseId = reward.caseId, delivered = true, deliveredTo = player.UserId, amount = reward.amount })
        HttpService:PostAsync((Config.DISCORD_PUSH_ENDPOINT:gsub("/report$","") .. "/reward/delivered"), payload, Enum.HttpContentType.ApplicationJson)
    end)
end

Players.PlayerAdded:Connect(function(player)
    spawn(function()
        local ok, res = pcall(function()
            local url = (Config.DISCORD_PUSH_ENDPOINT:gsub("/report$","") .. "/rewards/pending?userId=" .. player.UserId)
            return HttpService:GetAsync(url)
        end)
        if ok and res then
            local parsed = nil
            pcall(function() parsed = HttpService:JSONDecode(res) end)
            if parsed and type(parsed) == "table" and #parsed > 0 then
                for _, r in ipairs(parsed) do
                    deliverRewardToPlayer(player, r)
                end
            end
        end
    end)
end)
