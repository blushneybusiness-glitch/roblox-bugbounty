-- BugUI.lua (LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("BugRemotes")
local OpenUIEvent = Remotes:WaitForChild("OpenUI")
local SubmitEvent = Remotes:WaitForChild("SubmitReport")

local function makeUI()
    local player = Players.LocalPlayer
    local pg = player:WaitForChild("PlayerGui")
    if pg:FindFirstChild("BugReporterUI") then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "BugReporterUI"
    gui.ResetOnSpawn = false
    gui.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 520, 0, 360)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0.5, 0.5, 0)
    frame.BackgroundTransparency = 0.15
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.Size = UDim2.new(1, -20, 0, 34)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Text = "Bug Reporter"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(230,230,230)

    local subjBox = Instance.new("TextBox")
    subjBox.Parent = frame
    subjBox.Position = UDim2.new(0, 10, 0, 56)
    subjBox.Size = UDim2.new(1, -20, 0, 32)
    subjBox.PlaceholderText = "Subject (max 80 chars)"

    local detailsBox = Instance.new("TextBox")
    detailsBox.Parent = frame
    detailsBox.Position = UDim2.new(0, 10, 0, 96)
    detailsBox.Size = UDim2.new(1, -20, 0, 170)
    detailsBox.PlaceholderText = "Details (max 2000 chars)"
    detailsBox.MultiLine = true

    local anonCheckbox = Instance.new("TextButton")
    anonCheckbox.Parent = frame
    anonCheckbox.Position = UDim2.new(0.78, 0, 1, -68)
    anonCheckbox.Size = UDim2.new(0.18, 0, 0, 28)
    anonCheckbox.Text = "OFF"
    anonCheckbox:SetAttribute("On", false)
    anonCheckbox.MouseButton1Click:Connect(function()
        local on = anonCheckbox:GetAttribute("On")
        on = not on
        anonCheckbox:SetAttribute("On", on)
        anonCheckbox.Text = on and "ON" or "OFF"
    end)

    local submitBtn = Instance.new("TextButton")
    submitBtn.Parent = frame
    submitBtn.Position = UDim2.new(0.62, 0, 1, -34)
    submitBtn.Size = UDim2.new(0.18, 0, 0, 28)
    submitBtn.Text = "Submit"

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Parent = frame
    cancelBtn.Position = UDim2.new(0.82, 0, 1, -34)
    cancelBtn.Size = UDim2.new(0.16, 0, 0, 28)
    cancelBtn.Text = "Cancel"

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 280)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""

    local function sanitizeAndValidate(subject, details)
        subject = tostring(subject or ""):sub(1, 80)
        details = tostring(details or ""):sub(1, 2000)
        return subject, details
    end

    submitBtn.MouseButton1Click:Connect(function()
        submitBtn.Active = false
        local subj, det = sanitizeAndValidate(subjBox.Text, detailsBox.Text)
        if subj == "" then
            statusLabel.Text = "Subject is required"
            submitBtn.Active = true
            return
        end
        local anon = anonCheckbox:GetAttribute("On") == true
        statusLabel.Text = "Submitting..."
        local ok, resp = pcall(function()
            return SubmitEvent:InvokeServer({
                subject = subj,
                details = det,
                anonymous = anon
            })
        end)
        if not ok then
            statusLabel.Text = "Submit failed: "..tostring(resp)
            submitBtn.Active = true
            return
        end
        if resp.success then
            statusLabel.Text = "Submitted — Case ID: "..tostring(resp.caseId)
        else
            statusLabel.Text = "Failed: "..tostring(resp.message)
        end
        submitBtn.Active = true
    end)

    cancelBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end

OpenUIEvent.OnClientEvent:Connect(function()
    makeUI()
end)
