--// Cache

local select = select
local pcall, getgenv, next, Vector2, mathclamp, type, mousemoverel = select(1, pcall, getgenv, next, Vector2.new, math.clamp, type, mousemoverel or (Input and Input.MouseMove))

--// Preventing Multiple Processes

pcall(function()
	getgenv().Aimbot.Functions:Exit()
end)

--// Environment

getgenv().Aimbot = {}
local Environment = getgenv().Aimbot

--// Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Variables

local RequiredDistance, Typing, Running, Animation, ServiceConnections = 2000, false, false, nil, {}

--// Script Settings

Environment.Settings = {
	Enabled = false,
	TeamCheck = false,
	AliveCheck = true,
	WallCheck = false, -- Laggy
	Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
	ThirdPerson = false, -- Uses mousemoverel instead of CFrame to support locking in third person (could be choppy)
	ThirdPersonSensitivity = 3, -- Boundary: 0.1 - 5
	TriggerKey = "MouseButton2",
	Toggle = false,
	LockPart = "Head" -- Body part to lock on
}

Environment.FOVSettings = {
	Enabled = false,
	Visible = false,
	Amount = 90,
	Color = Color3.fromRGB(255, 255, 255),
	LockedColor = Color3.fromRGB(255, 70, 70),
	Transparency = 0.5,
	Sides = 60,
	Thickness = 1,
	Filled = false
}

Environment.FOVCircle = Drawing.new("Circle")

--// Functions

local function CancelLock()
	Environment.Locked = nil
	if Animation then Animation:Cancel() end
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
end

local function GetClosestPlayer()
	if not Environment.Locked then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000

		-- Поиск игроков
		for _, v in ipairs(workspace:GetChildren()) do
			if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character then
                if v:FindFirstChild(Environment.Settings.LockPart) and v:FindFirstChildOfClass("Humanoid") then
                    local IsPlayer = false
                    local Player
                    if Players:GetPlayerFromCharacter(v) then
                        IsPlayer = true
                        Player = Players:GetPlayerFromCharacter(v)
                    else
                        IsPlayer = false
                    end
                    if IsPlayer and Environment.Settings.TeamCheck and Player.Team == LocalPlayer.Team then 
                        continue
                    end
                    if Environment.Settings.AliveCheck and v:FindFirstChildOfClass("Humanoid").Health <= 0 then 
                        continue
                    end
                    if Environment.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v[Environment.Settings.LockPart].Position}, v:GetChildren())) > 0 then 
                        continue 
                    end

                    local Vector, OnScreen = Camera:WorldToViewportPoint(v[Environment.Settings.LockPart].Position)
                    local Distance = (Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2(Vector.X, Vector.Y)).Magnitude

                    if Distance < RequiredDistance and OnScreen then
                        RequiredDistance = Distance
                        Environment.Locked = v
                    end
				end
			end
        end
        
		for _, aizone in ipairs(workspace:FindFirstChild("AiZones"):GetChildren()) do
			for _, npc in ipairs(aizone:GetChildren()) do
				if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild(Environment.Settings.LockPart) and npc:FindFirstChildOfClass("Humanoid") then
					local Vector, OnScreen = Camera:WorldToViewportPoint(npc[Environment.Settings.LockPart].Position)
					local Distance = (Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2(Vector.X, Vector.Y)).Magnitude

					if Distance < RequiredDistance and OnScreen then
						RequiredDistance = Distance
						Environment.Locked = npc
					end
				end
			end
		end
	else
		if (Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2(Camera:WorldToViewportPoint(Environment.Locked[Environment.Settings.LockPart].Position).X, Camera:WorldToViewportPoint(Environment.Locked[Environment.Settings.LockPart].Position).Y)).Magnitude > RequiredDistance then
			CancelLock()
		end
	end
end

--// Typing Check

ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)

--// Main

local function Load()
	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
			Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
			Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
			Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
			Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
			Environment.FOVCircle.Color = Environment.FOVSettings.Color
			Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
			Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
			Environment.FOVCircle.Position = Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
		else
			Environment.FOVCircle.Visible = false
		end

		if Running and Environment.Settings.Enabled then
			GetClosestPlayer()

			if Environment.Locked then
				if Environment.Settings.ThirdPerson then
					Environment.Settings.ThirdPersonSensitivity = mathclamp(Environment.Settings.ThirdPersonSensitivity, 0.1, 5)

					local Vector = Camera:WorldToViewportPoint(Environment.Locked[Environment.Settings.LockPart].Position)
					mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity)
				else
					if Environment.Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked[Environment.Settings.LockPart].Position)})
						Animation:Play()
					else
						Camera.CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked[Environment.Settings.LockPart].Position)
					end
				end

			Environment.FOVCircle.Color = Environment.FOVSettings.LockedColor

			end
		end
	end)

	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
		if not Typing then
			pcall(function()
				if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							CancelLock()
						end
					else
						Running = true
					end
				end
			end)

			pcall(function()
				if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							CancelLock()
						end
					else
						Running = true
					end
				end
			end)
		end
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if not Typing then
			if not Environment.Settings.Toggle then
				pcall(function()
					if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
						Running = false; CancelLock()
					end
				end)

				pcall(function()
					if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
						Running = false; CancelLock()
					end
				end)
			end
		end
	end)
end

--// Functions

Environment.Functions = {}

function Environment.Functions:Exit()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	if Environment.FOVCircle.Remove then Environment.FOVCircle:Remove() end

	getgenv().Aimbot.Functions = nil
	getgenv().Aimbot = nil
	
	Load = nil; GetClosestPlayer = nil; CancelLock = nil
end

function Environment.Functions:Restart()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	Load()
end

function Environment.Functions:ResetSettings()
	Environment.Settings = {
		Enabled = true,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
		ThirdPerson = false, -- Uses mousemoverel instead of CFrame to support locking in third person (could be choppy)
		ThirdPersonSensitivity = 3, -- Boundary: 0.1 - 5
		TriggerKey = "MouseButton2",
		Toggle = false,
		LockPart = "Head" -- Body part to lock on
	}

	Environment.FOVSettings = {
		Enabled = true,
		Visible = true,
		Amount = 90,
		Color = Color3.fromRGB(255, 255, 255),
		LockedColor = Color3.fromRGB(255, 70, 70),
		Transparency = 0.5,
		Sides = 60,
		Thickness = 1,
		Filled = false
	}
end

--// Load

Load()

local AimbotEnv = getgenv().Aimbot
local AimbotSettings,AimbotFovSettings,AimbotFunctions = AimbotEnv.Settings,AimbotEnv.FOVSettings, AimbotEnv.Functions

getgenv().Config = {
	Invite = "",
	Version = "0.1",
}

getgenv().luaguardvars = {
	DiscordName = "username#0000",
}

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/drillygzzly/Other/main/1"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Okorix/testiruemluarbxpdesp/main/espmod.lua"))()
local RunService = game:GetService("RunService")
local PlayersService = game:GetService("Players")
local LocalPlayer = PlayersService.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Lighting = game.Lighting
local FullbrightEnabled = false
local NoGP5Effect = false
local CToZoomEnabled = false
local ExitEspHighlight = false
local NoVisorEffect = false

Library:init() -- Initalizes Library Do Not Delete This

ESP.NPCLookingFunc = function(NPCName)
    local Text = NPCName.." is looking at you!"
    Library:SendNotification(Text, 5, Color3.new(255, 0, 0))
end

ESP.BoxType = "Corner Box Esp"

local Window = Library.NewWindow({
	title = "TESTIRUEM.LUA",
	size = UDim2.new(0, 525, 0, 650)
})

local Tabs = {
    Visuals = Window:AddTab("Visuals"),
    Aimbot = Window:AddTab("Aimbot"),
	Settings = Library:CreateSettingsTab(Window),
}

local Sections = {
    PlayersSection = Tabs.Visuals:AddSection("Players ESP", 1),
    MiscSection = Tabs.Visuals:AddSection("Misc", 2),
    AimbotSection = Tabs.Aimbot:AddSection("Aimbot", 1),
    FovSection = Tabs.Aimbot:AddSection("FOV", 2)
}


Sections.PlayersSection:AddToggle({
	enabled = true,
	text = "Enabled",
	flag = "EspEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    ESP.Enabled = Valuee
	end
})
Sections.PlayersSection:AddToggle({
	enabled = true,
	text = "Health",
	flag = "HealthEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    ESP.ShowHealth = Valuee
	end
})
Sections.PlayersSection:AddToggle({
	enabled = true,
	text = "Names",
	flag = "NamesEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    ESP.ShowName = Valuee
	end
})
Sections.PlayersSection:AddToggle({
	enabled = true,
	text = "Boxes",
	flag = "BoxEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    ESP.ShowBox = Valuee
	end
})
Sections.PlayersSection:AddToggle({
	enabled = true,
	text = "Tracers",
	flag = "TracersEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    ESP.ShowTracer = Valuee
	end
})
Sections.PlayersSection:AddToggle({
	enabled = true,
	text = "Distance",
	flag = "DistanceEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    ESP.ShowDistance = Valuee
	end
})
Sections.PlayersSection:AddToggle({
	enabled = true,
	text = "Current weapon",
	flag = "CurrentWeaponEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    ESP.ShowWeapon = Valuee
	end
})
Sections.MiscSection:AddToggle({
	enabled = true,
	text = "Fullbright",
	flag = "FullbrightEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    FullbrightEnabled = Valuee
	end
})
function hasProperty(object, propertyName)
    local success, _ = pcall(function() 
        object[propertyName] = object[propertyName]
    end)
    return success
end
Sections.MiscSection:AddToggle({
	enabled = true,
	text = "No visor effect",
	flag = "NoVisorEffectEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
        NoVisorEffect = Valuee
        -- if PlayerGui:FindFirstChild("MainGui") then
        --     local MainGui = PlayerGui.MainGui
        --     local MainFrame = MainGui.MainFrame
        --     local ScreenEffects = MainFrame.ScreenEffects
        --     local VisorFrame = ScreenEffects.Visor
        --     for _,ChildFolders in pairs(VisorFrame:GetChildren()) do
        --         for _,ObjectsInFolder in pairs(ChildFolders:GetChildren()) do
        --             if hasProperty(ObjectsInFolder, "Visible") then
        --                 ObjectsInFolder.Visible = not Valuee
        --             end
        --         end
        --     end
        -- end
	end
})
Sections.MiscSection:AddToggle({
	enabled = true,
	text = "No GP5 effect",
	flag = "NoVisorEffectEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
        NoGP5Effect = Valuee
	end
})
local function AddExitHighlight(Obj)
    Obj.Transparency = 0
    local Highlight = Instance.new("Highlight",Obj)
    Highlight.Name = "ExitLocationHighlight"
    Highlight.FillTransparency = 0
    Highlight.OutlineTransparency = 1
    Highlight.FillColor = Color3.new(0,255,0)
end
local function RemoveExitHighlight(Obj)
    Obj.Transparency = 1
    Obj.ExitLocationHighlight:Destroy()
end
local function CheckForHighlight(Obj)
    if Obj:FindFirstChild("ExitLocationHighlight") then
        return true
    end
    return false
end

Sections.MiscSection:AddToggle({
	enabled = true,
	text = "Exit locations green highlight",
	flag = "ExtractESP",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
        ExitEspHighlight = Valuee
        if Valuee == false then
            for _,Objectt in pairs(workspace.NoCollision.ExitLocations:GetChildren()) do
                local CheckHighlight = CheckForHighlight(Objectt)
                if CheckHighlight == true then
                    RemoveExitHighlight(Objectt)
                end
            end
        end
	end
})
Sections.MiscSection:AddToggle({
	enabled = true,
	text = "C to zoom enabled",
	flag = "CToZoomEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
        CToZoomEnabled = Valuee
	end
})
Sections.MiscSection:AddButton({
	enabled = true,
	text = "Remove fog",
	flag = "RemoveFog",
	tooltip = "",
	risky = false,
	confirm = false, -- shows confirm button
	callback = function(DaNaxuiEto)
		Lighting.FogEnd = 100000
		for i,v in pairs(Lighting:GetDescendants()) do
			if v:IsA("Atmosphere") then
				v:Destroy()
			end
		end
	end
})
Sections.MiscSection:AddSlider({
	text = "Default FOV",
	flag = 'FOVInGameSlider', 
	suffix = "", 
	value = tonumber(PlayerGui.MainGui.MainFrame.Settings.Menu.ScrollingFrame.Gameplay.Frame.DefaultFOV.Slider.TextBox.Text),
	min = 1, 
	max = 120,
	increment = 1,
	tooltip = "Use this slider in settings to work (Apply changes in settings after using the slider)",
	risky = false,
	callback = function(Valuee) 
		PlayerGui.MainGui.MainFrame.Settings.Menu.ScrollingFrame.Gameplay.Frame.DefaultFOV.Slider.TextBox.Text = tostring(Valuee)
	end
})
Sections.AimbotSection:AddToggle({
	enabled = true,
	text = "Enabled",
	flag = "AimbotEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    AimbotSettings.Enabled = Valuee
	end
})
Sections.AimbotSection:AddToggle({
	enabled = true,
	text = "AliveCheck",
	flag = "AliveCheckEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    AimbotSettings.AliveCheck = Valuee
	end
})
Sections.AimbotSection:AddToggle({
	enabled = true,
	text = "WallCheck (Laggy)",
	flag = "WallCheckEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    AimbotSettings.WallCheck = Valuee
	end
})
Sections.AimbotSection:AddSlider({
	text = "Sensitivity (Animation length)", 
	flag = 'Sensitivity', 
	suffix = "", 
	value = 0.000,
	min = 0, 
	max = 5,
	increment = 0.001,
	tooltip = "",
	risky = false,
	callback = function(Valuee) 
		AimbotSettings.Sensitivity = Valuee
	end
})
Sections.AimbotSection:AddBind({
	text = "Trigger keybind",
	flag = "TriggerKeybind",
	nomouse = false,
	noindicator = true,
	tooltip = "",
	mode = "toggle",
	bind = Enum.UserInputType.MouseButton2,
	risky = false,
	keycallback = function(Valuee)
	    AimbotSettings.TriggerKey = Valuee.Name
	end
})
Sections.AimbotSection:AddToggle({
	enabled = true,
	text = "Toggle",
	flag = "ToggleEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    AimbotSettings.Toggle = Valuee
	end
})
Sections.AimbotSection:AddList({
	enabled = true,
	text = "Lock part",
	flag = "Lockpart",
	multi = false,
	tooltip = "",
    risky = false,
    dragging = false,
    focused = false,
	value = "Head",
	values = {
		"Head",
        "UpperTorso",
        "LowerTorso",
		"HumanoidRootPart",
	},
	callback = function(Valuee)
	    AimbotSettings.LockPart = Valuee
	end
})
Sections.FovSection:AddToggle({
	enabled = true,
	text = "Enabled",
	flag = "FovEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    AimbotFovSettings.Enabled = Valuee
	end
})
Sections.FovSection:AddToggle({
	enabled = true,
	text = "Visible",
	flag = "VisibleEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    AimbotFovSettings.Visible = Valuee
	end
})
Sections.FovSection:AddSlider({
	text = "Radius", 
	flag = 'Radius', 
	suffix = "", 
	value = 1.000,
	min = 1.000, 
	max = 1000,
	increment = 0.001,
	tooltip = "",
	risky = false,
	callback = function(Valuee) 
		AimbotFovSettings.Amount = Valuee
	end
})
Sections.FovSection:AddColor({
    enabled = true,
    text = "Color",
    flag = "Color",
    tooltip = "",
    color = Color3.new(255, 255, 255),
    trans = 0,
    open = false,
    callback = function(Valuee)
        AimbotFovSettings.Color = Valuee
    end
})
Sections.FovSection:AddColor({
    enabled = true,
    text = "Locked color",
    flag = "LockedColor",
    tooltip = "",
    color = Color3.new(255, 255, 255),
    trans = 0,
    open = false,
    callback = function(Valuee)
        AimbotFovSettings.LockedColor = Valuee
    end
})
Sections.FovSection:AddSlider({
	text = "Transparency", 
	flag = 'Transparency', 
	suffix = "", 
	value = 0.500,
	min = 0.000, 
	max = 1.000,
	increment = 0.001,
	tooltip = "",
	risky = false,
	callback = function(Valuee) 
		AimbotFovSettings.Transparency = Valuee
	end
})
Sections.FovSection:AddSlider({
	text = "Sides", 
	flag = 'Sides', 
	suffix = "", 
	value = 60,
	min = 30, 
	max = 280,
	increment = 1,
	tooltip = "",
	risky = false,
	callback = function(Valuee) 
		AimbotFovSettings.Sides = Valuee
	end
})
Sections.FovSection:AddSlider({
	text = "Thickness", 
	flag = 'Thickness', 
	suffix = "", 
	value = 0.500,
	min = 0.000, 
	max = 1.000,
	increment = 0.001,
	tooltip = "",
	risky = false,
	callback = function(Valuee) 
		AimbotFovSettings.Thickness = Valuee
	end
})
Sections.FovSection:AddToggle({
	enabled = true,
	text = "Filled",
	flag = "FilledEnabled",
	tooltip = "",
	risky = false, -- turns text to red and sets label to risky
	callback = function(Valuee)
	    AimbotFovSettings.Filled = Valuee
	end
})
RunService.RenderStepped:Connect(function()
    if FullbrightEnabled == true then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
    if PlayerGui:FindFirstChild("MainGui") then
        if NoVisorEffect == true then
            PlayerGui.MainGui.MainFrame.ScreenEffects.Visor.Visible = false
        else
            PlayerGui.MainGui.MainFrame.ScreenEffects.Visor.Visible = true
        end
        if NoGP5Effect == true then
            PlayerGui.MainGui.MainFrame.ScreenEffects.Mask.Visible = false
        else
            PlayerGui.MainGui.MainFrame.ScreenEffects.Mask.Visible = true
        end
    end
    if ExitEspHighlight == true then
        for _,Objectt in pairs(workspace.NoCollision.ExitLocations:GetChildren()) do
            local Check = CheckForHighlight(Objectt)
            if Check == false then
                AddExitHighlight(Objectt)
            end
        end
    end
end)
local OldZoomFOV = game.Workspace.CurrentCamera.FieldOfView

local ZoomSettings = {
    ZoomTime = 0.2,
    ZoomedAmount = 10
}

local function DoZoom(time, amount)
    local Tween_Info = TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut) 
    local Tween = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera, Tween_Info, {FieldOfView = amount})
    return Tween
end

game:GetService("UserInputService").InputBegan:Connect(function(Input,GameProc)
    if Input.KeyCode == Enum.KeyCode.C and CToZoomEnabled == true and not GameProc then
        DoZoom(ZoomSettings.ZoomTime, ZoomSettings.ZoomedAmount):Play()
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(Input)
    if Input.KeyCode == Enum.KeyCode.C and CToZoomEnabled == true and not GameProc then
        DoZoom(ZoomSettings.ZoomTime, OldZoomFOV):Play()
    end
end)

Library:SendNotification("TESTIRUEM LOADED HAVE FUN", 5, Color3.new(255, 0, 0))
