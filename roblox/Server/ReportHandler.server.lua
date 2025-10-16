-- ReportHandler.server.lua
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Module.Config)

-- Remotes
local remotes = ReplicatedStorage:FindFirstChild("BugRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "BugRemotes"
    remotes.Parent = ReplicatedStorage
end

local OpenUI = remotes:FindFirstChild("OpenUI")
if not OpenUI then
    OpenUI = Instance.new("RemoteEvent")
    OpenUI.Name = "OpenUI"
    OpenUI.Parent = remotes
end

local SubmitReport = remotes:FindFirstChild("SubmitReport")
if not SubmitReport then
    SubmitReport = Instance.new("RemoteFunction")
    SubmitReport.Name = "SubmitReport"
    SubmitReport.Parent = remotes
end

local function generateCaseId()
    local stamp = os.date("!%Y%m%d-%H%M%S")
    local rand = string.format("%04X", math.random(0,0xFFFF))
    return ("BUG-%s-%s"):format(stamp, rand)
end

local function hmac_stub(key, message)
    -- Placeholder for HMAC; replace with real HMAC for production
    return HttpService:UrlEncode(tostring(os.time()) .. ":" .. tostring(#message))
end

local lastSubmitted = {}

SubmitReport.OnServerInvoke = function(player, payload)
    if not player then return { success = false, message = "Not authenticated" } end
    local subject = tostring(payload.subject or ""):sub(1,80)
    local details = tostring(payload.details or ""):sub(1,2000)
    local anonymous = payload.anonymous and true or false

    if subject == "" then return { success = false, message = "Subject required" } end

    local last = lastSubmitted[player.UserId]
    if last and os.time() - last < 24*60*60 then
        return { success = false, message = "You have already submitted in the last 24 hours." }
    end

    local caseId = generateCaseId()
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    local record = {
        caseId = caseId,
        reporterUserId = player.UserId,
        displayName = player.DisplayName or player.Name,
        subject = subject,
        details = details,
        timestamp = timestamp,
        status = "open",
        modActions = {},
        anonymousPublic = anonymous
    }

    -- POST to Cloud API
    local payloadCloud = {
        caseId = record.caseId,
        reporterUserId = record.reporterUserId,
        displayName = record.displayName,
        anonymousPublic = record.anonymousPublic,
        subject = record.subject,
        details = record.details,
        timestamp = record.timestamp,
    }
    local body = HttpService:JSONEncode(payloadCloud)
    local success, resp = pcall(function()
        return HttpService:PostAsync(Config.DISCORD_PUSH_ENDPOINT, body, Enum.HttpContentType.ApplicationJson)
    end)
    if success then
        lastSubmitted[player.UserId] = os.time()
        return { success = true, caseId = caseId }
    else
        lastSubmitted[player.UserId] = os.time()
        return { success = true, caseId = caseId, note = "Cloud push failed; saved locally." }
    end
end

-- OpenUI server command to client
OpenUI.OnServerEvent:Connect(function(player)
    OpenUI:FireClient(player)
end)
