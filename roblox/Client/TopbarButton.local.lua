-- TopbarButton.local.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LOCAL_CONFIG = {
    ButtonName = "ReportBug",
    Tooltip = "Open Bug Reporter",
}

local Remotes = ReplicatedStorage:WaitForChild("BugRemotes")
local OpenUIEvent = Remotes:WaitForChild("OpenUI")

-- fallback simple GUI button if TopbarPlus not present
local function createLocalButton()
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "BugReporterGui"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local button = Instance.new("TextButton")
    button.Name = "OpenBugReporter"
    button.Size = UDim2.new(0, 36, 0, 36)
    button.Position = UDim2.new(0, 10, 0, 10)
    button.BackgroundTransparency = 0.45
    button.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
    button.Text = "🐞"
    button.Parent = gui

    button.MouseButton1Click:Connect(function()
        Remotes.OpenUI:FireServer()
    end)
end

createLocalButton()
