local id = math.random()

-->> Services <<--
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Terrain = workspace.Terrain

-->> Plugins <<--
local toolbar = plugin:CreateToolbar("Terrain Converter")

local button = toolbar:CreateButton(id, "Click to toggle.", "rbxassetid://78078303951344", "Terrain Converter")
local gui = plugin:CreateDockWidgetPluginGui(
	id,
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 400, 150, 400, 150)
)

local textLabel = Instance.new("TextLabel")
local regionMin = Instance.new("TextLabel")
local regionMax = Instance.new("TextLabel")

local saveTerrain = Instance.new("TextButton")

-->> Variables <<--
local activate = false

local selectionBox: BasePart
local renderConnect: RBXScriptConnection

local minPos : Vector3
local maxPos : Vector3
local size : Vector3

-->> Initialize <<--
gui.Title = "Terrain Converter"

gui.Name = "Terrain_Converter"
textLabel.Name = "TellPeopleWhatShouldTheyDo"
regionMin.Name = "Region3MinPos"
regionMax.Name = "Region3MaxPos"
saveTerrain.Name = "SaveTerrain"

textLabel.Text = "Adjust the part size/position to set the work area, then click save/export."
regionMin.Text = ""
regionMax.Text = ""
saveTerrain.Text = "Save"

textLabel.BackgroundTransparency = 1
regionMin.BackgroundTransparency = 0.5
regionMax.BackgroundTransparency = 0.5

regionMin.BackgroundColor3 = Color3.new(0, 0, 0)
regionMax.BackgroundColor3 = Color3.new(0, 0, 0)
saveTerrain.BackgroundColor3 = Color3.fromRGB(125, 125, 125)

textLabel.TextScaled = true
regionMin.TextScaled = true
regionMax.TextScaled = true
saveTerrain.TextScaled = true

textLabel.Size = UDim2.new(1, -10, 0.25, -5)
regionMin.Size = UDim2.new(0.5, -10, 0.25, 0)
regionMax.Size = UDim2.new(0.5, -10, 0.25, 0)
saveTerrain.Size = UDim2.new(0.5, -10, 0.25, 0)

textLabel.Position = UDim2.fromOffset(5, 5)
regionMin.Position = UDim2.new(0, 5, 0.25, 0)
regionMax.Position = UDim2.new(0.5, 5, 0.25, 0)
saveTerrain.Position = UDim2.new(0, 5, 0.75, -5)

textLabel.BorderSizePixel = 0
regionMin.BorderSizePixel = 0
regionMax.BorderSizePixel = 0
saveTerrain.BorderSizePixel = 0

textLabel.TextColor3 = Color3.new(1, 1, 1)
regionMin.TextColor3 = Color3.new(1, 1, 1)
regionMax.TextColor3 = Color3.new(1, 1, 1)
saveTerrain.TextColor3 = Color3.new(1, 1, 1)

textLabel.Parent = gui
regionMin.Parent = gui
regionMax.Parent = gui
saveTerrain.Parent = gui

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

local function convertEnum(t: {[any]: { [any]: any} | EnumItem | number | Vector3})
    local converted = {}

    for i, v in t do
        if typeof(v) == "table" then
            converted[i] = convertEnum(v)
        elseif typeof(v) == "EnumItem" then
			converted[i] = v.Value
        else
            converted[i] = v
        end
    end

    return converted
end

gui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if gui.Enabled ~= activate then
        onButtonClick()    
    end
end)

button.Click:Connect(onButtonClick)

saveTerrain.MouseButton1Click:Connect(function()
	if not selectionBox then
		return
	end

	local min = selectionBox.Position - selectionBox.Size / 2
	local max = selectionBox.Position + selectionBox.Size / 2

	local newRegion3 = Region3.new(min, max):ExpandToGrid(4)

	local file = Instance.new("ModuleScript")
    file.Name = "ConvertedTerrain"
	file.Parent = workspace

	local materials, occupancies = Terrain:ReadVoxels(newRegion3, 4)

    local encode = HttpService:JSONEncode({
			["materials"] = convertEnum(materials),
			["occupancies"] = occupancies,
		})

	file.Source = (
    "-- This terrain voxel table has been converted into JSON table, use HttpService:JSONDecode() to get a lua table. \n" ..
    "-- EnumItems will be convert into the value. \n\n"
     .. `return "{string.gsub(encode, '"', '\\"')}"`
    )

	Selection:Set({ file })
end)
