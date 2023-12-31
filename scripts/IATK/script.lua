-- checks
if game.GameId ~= 1998835206 then
	return
end
repeat
	task.wait()
until game:IsLoaded()

-- top level stuff
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local locPlr = Players.LocalPlayer
local gui = locPlr:WaitForChild("PlayerGui")
gui:WaitForChild("UI"):WaitForChild("Windows")

local array = function(a: any)
	return {
		push = function(i)
			a[#a + 1] = i
		end,
		clear = function()
			table.clear(a)
		end,
		find = function(k)
			return table.find(a, k)
		end,
		remove = function(i)
			return table.remove(a, i)
		end,
		raw = a,
	}
end

local keys = {
	events = "IATMK_events",
	setting = "IAMTK_isEnabled",
	settingFile = "IAMTK_setting.txt",
}

local getters = {}
local function buttonify(button: ImageButton, pos: GuiMain?)
	getters.events().push(button.MouseButton1Down:Connect(function()
		button.Image = "http://www.roblox.com/asset/?id=11352193500"
		if pos then
			pos.Position = UDim2.new(0.5, 0, 0.1, 0)
		end
	end))
	getters.events().push(button.MouseButton1Up:Connect(function()
		button.Image = "http://www.roblox.com/asset/?id=11352192648"
		if pos then
			pos.Position = UDim2.new(0.5, 0, 0, 0)
		end
	end))
	getters.events().push(button.MouseButton1Click:Connect(function()
		local click = getters.sfx().Click
		click.PlaybackSpeed = math.random(70, 130) / 100
		click:Play()
	end))
end

getters = {
	texts = function(): { string }
		return HttpService:JSONDecode(game:HttpGet("https://cdn.nexpid.xyz/scripts/IATK/list.json"))
	end,
	events = function()
		if not _G[keys.events] then
			_G[keys.events] = {}
		end
		return array(_G[keys.events])
	end,
	sfx = function(): {
		Click: Sound,
	}
		local sfx = gui.UI.SFX

		return {
			Click = sfx.Click,
		}
	end,
	thingityThing = function(): ImageButton
		local ok = gui.UI.Windows.Main.WindowHolder.Settings

		if ok:FindFirstChild("TeammateKills") then
			ok.TeammateKills:Destroy()
		end

		local nya = ok.OldWeaponModels:Clone()
		nya.Name = "TeammateKills"
		nya.Title.Text = "Teammate Kills"
		nya.Desc.Text = "Shows teammate kills in the kill list"
		nya.Parent = ok
		nya.Visible = true

		buttonify(nya.OnOff, nya.OnOff.Icon)

		return nya.OnOff
	end,
}

-- disconnect
for _, e in pairs(getters.events().raw) do
	if typeof(e) == "function" then
		task.spawn(e)
	else
		e:Disconnect()
	end
end
getters.events().clear()

-- runners
do
	local jeepers = getters.thingityThing()

	if isfile(keys.settingFile) then
		_G[keys.setting] = readfile(keys.settingFile) == "y"
	end
	local function update()
		local val = _G[keys.setting]
		jeepers.ImageColor3 = if val then Color3.fromRGB(104, 221, 96) else Color3.fromRGB(218, 75, 75)
		jeepers.Icon.Image = if val then "rbxassetid://12674614011" else "rbxassetid://12674574026"
	end
	update()

	jeepers.MouseButton1Click:Connect(function()
		_G[keys.setting] = not _G[keys.setting]
		writefile(keys.settingFile, if _G[keys.setting] then "y" else "n")

		update()
	end)
end

local texts = getters.texts()

local lastKiller: Player
local function handlePlayer(plr: Player)
	local function handleKills(it: IntValue)
		if not table.find({ "Kills", "Infects" }, it.Name) then
			return
		end

		getters.events().push(it:GetPropertyChangedSignal("Value"):Connect(function()
			if plr.Team == locPlr.Team then
				lastKiller = plr
			end
		end))
	end

	task.spawn(function()
		plr:WaitForChild("leaderstats")
		for _, c in pairs(plr.leaderstats:GetChildren()) do
			task.spawn(handleKills, c)
		end
		getters.events().push(plr.leaderstats.ChildAdded:Connect(function(k)
			task.wait()
			handleKills(k)
		end))
	end)

	local function handleCharacter(char: Model)
		local humanoid: Humanoid = char:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			task.wait(0.45)
			if not _G[keys.setting] then
				return
			end

			if locPlr.Team and locPlr.Team ~= plr.Team then
				local killer = lastKiller
				if not killer or killer == locPlr or killer.Team ~= locPlr.Team then
					return
				end

				local text = texts[Random.new():NextInteger(1, #texts)]

				local string = text:gsub("%%a", killer.DisplayName):gsub("%%b", plr.DisplayName)

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 0.25, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.RobotoMono
				label.TextStrokeTransparency = 0
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextScaled = true
				label.TextStrokeColor3 = Color3.fromRGB(27, 42, 53)
				label.TextColor3 = Color3.fromRGB(190, 255, 255)
				label.Text = string
				label.Parent = locPlr.PlayerGui.UI.Hud.KillHolder

				TweenService:Create(label, TweenInfo.new(6.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
					TextStrokeTransparency = 1,
					TextTransparency = 1,
				}):Play()
				Debris:AddItem(label, 6.5)
			end
		end)
	end

	getters.events().push(plr.CharacterAdded:Connect(handleCharacter))
	if plr.Character then
		task.spawn(handleCharacter, plr.Character)
	end
end

getters.events().push(Players.PlayerAdded:Connect(handlePlayer))
for _, p in pairs(Players:GetPlayers()) do
	task.spawn(handlePlayer, p)
end
