local id = math.random()

if not plugin then
	return
end

-->> Services <<--
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Terrain = workspace.Terrain

local PluginEnvironment = script.Parent

-->> Modules <<--
local pathToInstance = require(PluginEnvironment.utils.pathToInstance)

-->> Constants <<--
local KEY_SAVE_LOCATION = "saveLocation"
local OUTPUT_HEADER_TEXT = "[saveRBXTerrian]:"

local DEFAULT_SAVE_LOCATION = game:GetService("ServerStorage")

-->> Plugins <<--
local toolbar = plugin:CreateToolbar("saveRBXTerrain")

local button = toolbar:CreateButton(id, "Click to toggle.", "rbxassetid://78078303951344", "Save RBX Terrain")
local gui = plugin:CreateDockWidgetPluginGui(
	id,
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 400, 150, 400, 150)
)

local textLabel = Instance.new("TextLabel")
local regionMin = Instance.new("TextLabel")
local regionMax = Instance.new("TextLabel")

local saveTerrain = Instance.new("TextButton")
local setSaveLocationBtn = Instance.new("TextButton")

local saveLocation = plugin:GetSetting(KEY_SAVE_LOCATION) :: string
local tempLocate : Instance?

-->> Variables <<--
local activate = false

local selectionBox: BasePart
local renderConnect: RBXScriptConnection

local minPos : Vector3int16
local maxPos : Vector3int16
local size : Vector3

-->> Initialize <<--
gui.Title = "Save RBX Terrain"

gui.Name = "Save_RBX_Terrain"
textLabel.Name = "TellPeopleWhatShouldTheyDo"
regionMin.Name = "Region3MinPos"
regionMax.Name = "Region3MaxPos"
saveTerrain.Name = "SaveTerrain"
setSaveLocationBtn.Name = "SetSaveLocation"

textLabel.Text = "Adjust the part size/position to set the work area, then click save/export."
regionMin.Text = ""
regionMax.Text = ""
saveTerrain.Text = "Save"
setSaveLocationBtn.Text = "Set Save Location"

textLabel.BackgroundTransparency = 1
regionMin.BackgroundTransparency = 0.5
regionMax.BackgroundTransparency = 0.5

regionMin.BackgroundColor3 = Color3.new(0, 0, 0)
regionMax.BackgroundColor3 = Color3.new(0, 0, 0)
saveTerrain.BackgroundColor3 = Color3.fromRGB(125, 125, 125)
setSaveLocationBtn.BackgroundColor3 = Color3.fromRGB(125, 125, 125)

textLabel.TextScaled = true
regionMin.TextScaled = true
regionMax.TextScaled = true
saveTerrain.TextScaled = true
setSaveLocationBtn.TextScaled = true

textLabel.Size = UDim2.new(1, -10, 0.25, -5)
regionMin.Size = UDim2.new(0.5, -10, 0.25, 0)
regionMax.Size = UDim2.new(0.5, -10, 0.25, 0)
saveTerrain.Size = UDim2.new(0.5, -10, 0.25, 0)
setSaveLocationBtn.Size = UDim2.new(0.5, -10, 0.25, 0)

textLabel.Position = UDim2.fromOffset(5, 5)
regionMin.Position = UDim2.new(0, 5, 0.25, 0)
regionMax.Position = UDim2.new(0.5, 5, 0.25, 0)
saveTerrain.Position = UDim2.new(0, 5, 0.75, -5)
setSaveLocationBtn.Position = UDim2.new(0.5, 5, 0.75, -5)

textLabel.BorderSizePixel = 0
regionMin.BorderSizePixel = 0
regionMax.BorderSizePixel = 0
saveTerrain.BorderSizePixel = 0
setSaveLocationBtn.BorderSizePixel = 0

textLabel.TextColor3 = Color3.new(1, 1, 1)
regionMin.TextColor3 = Color3.new(1, 1, 1)
regionMax.TextColor3 = Color3.new(1, 1, 1)
saveTerrain.TextColor3 = Color3.new(1, 1, 1)
setSaveLocationBtn.TextColor3 = Color3.new(1, 1, 1)

textLabel.Parent = gui
regionMin.Parent = gui
regionMax.Parent = gui
saveTerrain.Parent = gui
setSaveLocationBtn.Parent = gui

if saveLocation ~= nil then
	tempLocate = pathToInstance(saveLocation)

	if tempLocate == nil then
		tempLocate = DEFAULT_SAVE_LOCATION
		warn(`{OUTPUT_HEADER_TEXT} Failed to find instance through path ({saveLocation}). The save location has been temporary set to {DEFAULT_SAVE_LOCATION.Name}.`)
	end

end

local function onButtonClick()
	activate = not activate
	gui.Enabled = activate

	if activate then
		selectionBox = Instance.new("Part")
		selectionBox.Name = "TerrainConverterPart"
		selectionBox.Size = Vector3.new(10, 10, 10)
		selectionBox.Anchored = true
		selectionBox.CanCollide = false
		selectionBox.Transparency = 1

		local edge = Instance.new("SelectionBox")
		edge.Adornee = selectionBox

		edge.Parent = selectionBox
		selectionBox.Parent = workspace
		Selection:Set({ selectionBox })

        if minPos then
            selectionBox.Position = (minPos + maxPos) / 2
            selectionBox.Size = size
        end

		renderConnect = RunService.PreRender:Connect(function()
			size = selectionBox.Size
			minPos = selectionBox.Position - size / 2
			maxPos = selectionBox.Position + size / 2

			regionMin.Text = `{math.floor(minPos.X)}, {math.floor(minPos.Y)}, {math.floor(minPos.Z)}`
			regionMax.Text = `{math.floor(maxPos.X)}, {math.floor(maxPos.Y)}, {math.floor(maxPos.Z)}`
		end)
	else
		selectionBox:Destroy()
		selectionBox = nil

		if renderConnect then
			renderConnect:Disconnect()
			renderConnect = nil
		end
	end
end

local function setSaveLocation()
	local location = Selection:Get()[1] :: Instance
	local pathToLocation = location:GetFullName()

	plugin:SetSetting(KEY_SAVE_LOCATION, pathToLocation)
	tempLocate = location

	print(`{OUTPUT_HEADER_TEXT} The save location has been set to: {pathToLocation}`)
end

gui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if gui.Enabled ~= activate then
        onButtonClick()    
    end
end)

button.Click:Connect(onButtonClick)
setSaveLocationBtn.MouseButton1Click:Connect(setSaveLocation)

saveTerrain.MouseButton1Click:Connect(function()
	if not selectionBox then
		return
	end

	local min = Vector3int16.new(minPos.X, minPos.Y, minPos.Z)
	local max = Vector3int16.new(maxPos.X, maxPos.Y, maxPos.Z)

	local newRegion3 = Region3int16.new(min, max)

	local newTerrainRegion = Terrain:CopyRegion(newRegion3) 
	newTerrainRegion.Parent = tempLocate

	Selection:Set({ newTerrainRegion })
end)
