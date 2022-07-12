--// module variables
local module = {}
module.__index = module

--// services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

--// functions
local vector2New = Vector2.new
local CFNew = CFrame.new

--// variables
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local WorldToViewportPoint = camera.WorldToViewportPoint

--// core vars
local espGroups = {}

-- module functions
local funcs = {
GetName = function(char)
    return char.Name
end,
GetChar = function(plr)
    return plr.Character
end,
GetPlayer = function(char)
    return game:GetService("Players"):GetPlayerFromCharacter(char)
end,
GetHealth = function(char)
    return char:FindFirstChildOfClass("Humanoid").Health,char:FindFirstChildOfClass("Humanoid").MaxHealth
end,
GetPrimaryPart = function(char)
    return char.PrimaryPart
end 
}

function module.setFunctions(func)
funcs = func
end     

local function constructDrawing(object,properties)
local Draw = Drawing.new(object)

for i,v in pairs(properties) do 
    Draw[i] = v
end 
return Draw
end

local function createObject(settings,t)
if settings.boxes then 
    if t.MainBox == nil and t.OutlineBox == nil then 
        t.MainBox = constructDrawing("Quad",{
            Visible = true,
            Transparency = 1,
            Thickness = 2,
            Color = settings.color,
            ZIndex = 100,
        })

        t.OutlineBox = constructDrawing("Quad",{
            Visible = true,
            Transparency = 1,
            Thickness = 4,
            Color = Color3.fromRGB(0,0,0),
            ZIndex = 20
        })
    end 
end     

if settings.healthbar then 
    if t.HealthBar == nil then 
        t.HealthBar = constructDrawing("Line",{
            Visible = true,
            Transparency = 1,
            Thickness = 2,
            Color = settings.healthbarcolor,
            ZIndex = 100,
        })

        t.HealthOutline = constructDrawing("Line",{
            Visible = true,
            Transparency = 1,
            Thickness = 4,
            Color = Color3.fromRGB(0,0,0),
            ZIndex = 20
        })
    end 
end 

if settings.tracer then 
    if t.Tracer == nil then 
        t.Tracer = constructDrawing("Line", {
            Thickness = 2,
            Color = settings.color,
            Transparency = 1,
            ZIndex = 3,
            Visible = true,
        })

    end 
end 

if settings.text then 
    if settings.text.Top then 
        if t.TopText == nil then 
            t.TopText = constructDrawing("Text",{
                Visible = true,
                Transparency = 1,
                Text = settings.text.Top,
                Font = settings.text.font,
                Size = settings.text.size,
                Color = settings.color,
                ZIndex = 100,
                Outline = settings.text.outline,
                Center = true 
            })
        end 
    end

    if settings.text.Bottom then 
        if t.BottomText == nil then 
            t.BottomText = constructDrawing("Text",{
                Visible = true,
                Transparency = 1,
                Text = settings.text.Bottom,
                Font = settings.text.font,
                Size = settings.text.size,
                Color = settings.color,
                ZIndex = 100,
                Outline = settings.text.outline,
                Center = true 
            })
        end 
    end

    if settings.text.Side then 
        if t.SideText == nil then 
            t.SideText = constructDrawing("Text",{
                Visible = true,
                Transparency = 1,
                Text = settings.text.Side,
                Font = settings.text.font,
                Size = settings.text.size,
                Color = settings.color,
                ZIndex = 100,
                Outline = settings.text.outline,
            })
        end 
    end
end 

return t
end 

function module.new(settings)
settings = settings or {}

local default = {
    name = HttpService:GenerateGUID(),
    boxes = false,
    tracer = false,
    visible = false,
    facecam = false,
    distance = 2500,
    color = Color3.fromRGB(255,255,255),
    offset = CFNew(0,-.25,0),
    healthbar = true,
    healthbarcolor = Color3.fromRGB(0, 255, 68),
    text = {}
}

--// override functions: customColor, customVisible, customText, customFilter
for i,v in pairs(default) do 
    if settings[i] == nil then 
        settings[i] = v
    end 
end 

return settings 
end 

function module.createGroup(settings)
settings.groupEnabled = false 
settings.espObjects = {}
settings.lastCache = 0
settings.cache = {}

local functions = {}
functions.__index = functions

function functions.addObject(props,model) 
    if settings.espObjects[model] then return nil end 

    self = props

    --// setup some more settings
    local objectFuncs = {}
    objectFuncs.__index = objectFuncs

    local removed = false 

    function objectFuncs.Remove(box)
        settings.espObjects[model] = nil
        settings.cache[model] = nil

        for i,v in pairs(box.DrawingObjects) do
            v.Visible = false
            v.Transparency = 0
            v:Remove()
        end 
    end

    local object = setmetatable({
        Objects = {},
        Properties = props,
        Group = settings,
        Type = "Normal",
        primarypart = settings.primarypart
    }, objectFuncs)

    -- setup all objects
    object.DrawingObjects = createObject(props,{})

    settings.espObjects[model] = object
end

function functions.addLine(props)
    local objectFuncs = {}
    objectFuncs.__index = objectFuncs

    local removed = false 
    local idx = os.clock()

    function objectFuncs.Remove(box)
        settings.espObjects[idx] = nil
        settings.cache[idx] = nil

        for i,v in pairs(box.DrawingObjects) do
            v.Visible = false
            v.Transparency = 0
            v:Remove()
        end 
    end

    local object = setmetatable({
        Objects = {},
        Properties = props,
        Group = settings,
        Type = "Tracer",
    }, objectFuncs)

    -- setup all objects
    local DrawingObjects = {
        Line = constructDrawing("Line",{
            Thickness = 1,
            Color = props.Color,
            Visible = true,
            Transparency = 1,
        })
    }

    object.DrawingObjects = DrawingObjects

    settings.espObjects[idx] = object
end 

function functions.editSetting(setting,value,applyToAll)
    if setting == "visible" then 
        settings.visible = value 

        if value == false then 
            for i,v in pairs(settings.espObjects) do 
                for _,esp in pairs(v.DrawingObjects) do 
                    esp.Visible = false
                end 
            end 
        end 
    elseif applyToAll ~= true then  
        settings[setting] = value
    else 
        settings[setting] = value

        for i,v in pairs(settings.espObjects) do 
            v[setting] = value
        end 
    end 

    for i,v in pairs(settings.espObjects) do 
        v.DrawingObjects = createObject(settings,v.DrawingObjects)
    end 

    settings.lastCache = 0
end 

function functions.remove()
    for i,v in pairs(settings.espObjects) do 
        v:Remove()
    end

    espGroups[settings.name] = nil
end 

local meta = setmetatable(settings,functions)
espGroups[settings.name] = meta

return meta
end 

function module.SetupListener(settings, listenObject)
local Group = module.createGroup(module.new(settings))

local function addItem(object)
    if settings.customFilter == nil or (settings.customFilter and settings.customFilter(object,Group.espObjects) == true) then 
        local newSettings = settings
        settings.primarypart = object

        if settings.customSettings then 
            newSettings = settings.customSettings(object,settings)
        end 

        Group.addObject(newSettings,object)

        if newSettings.callback then
            newSettings.callback(object)
        end 
    end 
end 

if settings.recursive then 
    listenObject.DescendantAdded:Connect(addItem)

    for i,v in pairs(listenObject:GetDescendants()) do
        coroutine.wrap(addItem)(v)
    end
else 
    listenObject.ChildAdded:Connect(addItem)

    for i,v in pairs(listenObject:GetChildren()) do
        coroutine.wrap(addItem)(v)
    end
end 

return Group
end

-- update
local function updateBoxes(obj,group,positions,xDiff)
local MainBox = obj.DrawingObjects.MainBox
local OutlineBox = obj.DrawingObjects.OutlineBox

if not group.boxes then 
    if MainBox and OutlineBox then
        MainBox.Visible = false 
        OutlineBox.Visible = false
    end

    return 
end 

local TopLeft,TopRight,BottomLeft,BottomRight = positions.TopLeft,positions.TopRight,positions.BottomLeft,positions.BottomRight

if TopLeft[2] and TopRight[2] and BottomRight[2] and BottomLeft[2] then 
    MainBox.Color = obj.Properties.color

    MainBox.PointB = TopLeft[1]
    MainBox.PointA = TopRight[1]
    MainBox.PointC = BottomLeft[1]
    MainBox.PointD = BottomRight[1]

    OutlineBox.PointB = TopLeft[1]
    OutlineBox.PointA = TopRight[1]
    OutlineBox.PointC = BottomLeft[1]
    OutlineBox.PointD = BottomRight[1]

    -- Thickness
    local size = math.abs(xDiff)

    MainBox.Thickness = math.clamp(size/50,1,2)
    OutlineBox.Thickness =  math.clamp(size/50,1,2) * 2

    MainBox.Visible = true 
    OutlineBox.Visible = true 
else 
    MainBox.Visible = false 
    OutlineBox.Visible = false
end 
end 

local function updateHealthBar(obj,group,positions,xDiff)
local MainBox = obj.DrawingObjects.HealthBar
local OutlineBox = obj.DrawingObjects.HealthOutline

if not group.healthbar then 
    if MainBox and OutlineBox then
        MainBox.Visible = false 
        OutlineBox.Visible = false
    end

    return 
end 

local TopLeft,TopRight,BottomLeft,BottomRight = positions.TopLeft,positions.TopRight,positions.BottomLeft,positions.BottomRight

if TopLeft[2] and TopRight[2] and BottomRight[2] and BottomLeft[2] then 
    local From,To = BottomLeft[1].X,TopLeft[1].X
    local BottomY = BottomLeft[1].Y 
    local TopY = TopLeft[1].Y
    local add = -math.clamp(math.abs(xDiff) * .05,4,10)

    if xDiff < 0 then 
        --add = -add
        From = BottomRight[1].X
        To = TopRight[1].X
        BottomY = BottomRight[1].Y
        TopY = TopRight[1].Y
    end 

    local otherAdd = MainBox.Thickness == 2 and 0 or 1
    local health,maxhealth = group.customHealth and group.customHealth(obj) or 100,100
    local perc = health / maxhealth
    local lerped = vector2New(To + add,TopY - otherAdd):Lerp(vector2New(From + add,BottomY + otherAdd),perc)

    MainBox.From = vector2New(From + add,BottomY + otherAdd)
    MainBox.To = lerped

    OutlineBox.From = vector2New(From + add,BottomY + 2)
    OutlineBox.To = vector2New(To + add,TopY - 2)

    -- Thickness
    local size = math.abs(xDiff)

    MainBox.Thickness = math.clamp(size/50,1,2)
    OutlineBox.Thickness =  math.clamp(size/50,1,2) * 2

    MainBox.Visible = true 
    OutlineBox.Visible = true 
else 
    MainBox.Visible = false 
    OutlineBox.Visible = false
end 
end 

local function updateTopText(obj,group, positions, magnitude,xDiff)
local Text = obj.DrawingObjects.TopText

if not group.text.Top then 
    if Text then
        Text.Visible = false 
    end

    return  
end 

if positions.TopText[2] then             
    local sizeDecrease = 0

    if magnitude > 50 and group.text.scaleTop then 
        sizeDecrease = math.clamp((magnitude - 50) / 15,0,group.text.size / 3)
    end 

    Text.Size = group.text.size - sizeDecrease
    Text.Text = group.customTextTop and group.customTextTop(obj) or group.text.Top
    Text.Position = vector2New(positions.TopText[1].X, positions.TopText[1].Y + (xDiff / 40) - Text.TextBounds.Y - 5)
    Text.Color = obj.Properties.color
    Text.Font = group.text.font

    Text.Visible = true 
else 
    Text.Visible = false 
end 
end 

local function updateBottomText(obj,group, positions,magnitude,xDiff)
local Text = obj.DrawingObjects.BottomText

if not group.text.Bottom then 
    if Text then
        Text.Visible = false 
    end

    return  
end 

if positions.BottomText[2] then             
    local sizeDecrease = 0

    if magnitude > 50 and group.text.scaleBottom then 
        sizeDecrease = math.clamp((magnitude - 50) / 15,0,group.text.size / 3)
    end 

    Text.Size = group.text.size - sizeDecrease
    Text.Text = group.customTextBottom and group.customTextBottom(obj) or group.text.Bottom
    Text.Position = vector2New(positions.BottomText[1].X, positions.BottomText[1].Y - (xDiff / 40) + 7)
    Text.Color = obj.Properties.color
    Text.Font = group.text.font

    Text.Visible = true 
else 
    Text.Visible = false 
end 
end 

local function updateSideText(obj, group, positions,magnitude,xDiff)
local Text = obj.DrawingObjects.SideText

if not group.text.Side then 
    if Text then
        Text.Visible = false
    end 

    return  
end 

if positions.TopRight[2] then             
    local sizeDecrease = 0

    if magnitude > 50 and group.text.scaleSide then 
        sizeDecrease = math.clamp((magnitude - 50) / 15,0,group.text.size / 3)
    end 

    local From = positions.TopLeft[1]

    if xDiff > 0 then 
        From = positions.TopRight[1]
    end 

    Text.Size = group.text.size - sizeDecrease
    Text.Text = group.customTextSide and group.customTextSide(obj) or group.text.Side
    Text.Position = vector2New(From.X + 8 + (math.abs(xDiff) / 60), From.Y - sizeDecrease)
    Text.Color = obj.Properties.color
    Text.Font = group.text.font

    Text.Visible = true 
else 
    Text.Visible = false 
end 
end 

local function updateTracer(obj, group, positions) 
local Tracer = obj.DrawingObjects.Tracer 

if not group.tracer then 
    if Tracer then 
        Tracer.Visible = false 
    end 

    return 
end 

if positions.Center[2] then 
    local To = positions.Center[1] 

    Tracer.From = group.tracerorigin == "Mouse" and UserInputService:GetMouseLocation() or
    group.tracerorigin == "Top" and vector2New(camera.ViewportSize.X * 0.5, 0) or
    group.tracerorigin == "Bottom" and vector2New(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y) 

    Tracer.To = To
    Tracer.Color = obj.Properties.color

    Tracer.Visible = true
end 
end 

local function runGroup(group)
local lastCache = group.lastCache

if tick() - lastCache > 1 then 
    -- recache
    group.cache = {}
    group.lastCache = tick()

    for i,v in pairs(group.espObjects) do
        local s = pcall(function() local a = v.primarypart.Position.X end)

        if v.Type == "Normal" and (not s or typeof(v.primarypart) ~= "Instance" or v.primarypart == nil or v.primarypart.Parent == nil or v.primarypart.Parent.Parent == nil) then 
            group.espObjects[i]:Remove()
            group.espObjects[i] = nil 
            continue
        end

        if v.Type ~= "Normal" or (v.primarypart.Position - funcs.GetPrimaryPart(funcs.GetChar(LocalPlayer)).Position).magnitude < group.distance then 
            group.cache[i] = v 
        elseif v.Type == "Normal" then 
            for _,v in pairs(v.DrawingObjects) do
                v.Visible = false
            end
        end 
    end 
end 

local function V3toV2(v3)
    return vector2New(v3.X,v3.Y)
end 

for i,v in pairs(group.cache) do 
    -- determine whether object is safe to draw
    if v.Type == "Normal" then 
        local canDraw = true 

        if funcs.GetChar(LocalPlayer) == nil then canDraw = false end 
        if v.primarypart == nil then v:Remove() canDraw = false continue end 
        if v.primarypart.Parent == nil then v:Remove() canDraw = false continue end 
        if group.customVisible and not group.customVisible(v.primarypart,v) then canDraw = false end 
        if not group.visible then canDraw = false end 

        if not canDraw then 
            for i,v in pairs(v.DrawingObjects) do 
                v.Visible = false 
            end 

            continue
        end 

        local centerCF = v.primarypart.CFrame 

        if group.facecam then
            local cfAngle = CFNew(centerCF.p, camera.CFrame.p)

            local x, y, z = cfAngle:ToEulerAnglesYXZ()
            local newCF = CFrame.Angles(0, y, z) 

            centerCF = CFNew(cfAngle.p) * newCF
        end

        local size = group.customSize and group.customSize(v) or v.size or Vector3.new(4,6,0)

        local points = {
            TopLeft = centerCF * group.offset * CFNew(size.X/2,size.Y/2,0),
            TopRight = centerCF * group.offset * CFNew(-size.X/2,size.Y/2,0),
            BottomLeft = centerCF * group.offset * CFNew(size.X/2,-size.Y/2,0),
            BottomRight = centerCF * group.offset * CFNew(-size.X/2,-size.Y/2,0),
            Center = centerCF * group.offset,
            TopText = centerCF * group.offset * CFNew(0,size.Y/2,0),
            BottomText = centerCF * group.offset * CFNew(0,-size.Y/2,0),
        }

        for i,v in pairs(points) do 
            local result,inScreen = WorldToViewportPoint(camera,v.p)
            points[i] = {vector2New(result.X,result.Y),inScreen}
        end 

        -- i know this is shit code, but need to make sure inlining occurs
        local magnitude = (camera.CFrame.p - v.primarypart.Position).Magnitude 
        local xDiff = points.Center[1].X - points.BottomLeft[1].X


        if group.customColor then 
            v.Properties.color = group.customColor(v)
        end 

        local s,e = pcall(function()
            updateBoxes(v,group,points,xDiff)
            updateHealthBar(v,group,points,xDiff)
            updateTopText(v,group,points,magnitude,xDiff)
            updateBottomText(v,group,points,magnitude,xDiff)
            updateSideText(v,group,points,magnitude,xDiff)
            updateTracer(v,group,points,xDiff)
        end)

        if not s then  
            v.DrawingObjects = createObject(group,v.DrawingObjects)
            warn("Error occured: " .. e)
        end 
    else 
        local From = v.Properties.Origin
        local To = v.Properties.Target

        local points = {
            From = {WorldToViewportPoint(camera,From)},
            To = {WorldToViewportPoint(camera,To)}
        }

        if v.Properties.Effect == "Shrink" then 
            local timeElapsed = os.clock() - i 
            local maxTime = v.Properties.Time
            local perc = 0

            if timeElapsed > v.Properties.EffectStart then 
                perc = (timeElapsed - v.Properties.EffectStart) / maxTime
            end

            if perc >  1 then 
                v.Remove(v)
                continue
            end 

            local lerped = V3toV2(points.From[1]):Lerp(V3toV2(points.To[1]),perc)

            v.DrawingObjects.Line.From = lerped 
            v.DrawingObjects.Line.To = V3toV2(points.To[1])
        elseif v.Properties.Effect == "Fade" then 
            local timeElapsed = os.clock() - i 
            local maxTime = v.Properties.Time
            local perc = 0

            if timeElapsed > v.Properties.EffectStart then 
                perc = (timeElapsed - v.Properties.EffectStart) / maxTime
            end

            if perc > 1 then 
                v.Remove(v)
                continue
            end 


            v.DrawingObjects.Line.From = V3toV2(points.From[1]) 
            v.DrawingObjects.Line.To = V3toV2(points.To[1])

            v.DrawingObjects.Line.Transparency = 1 - perc
        else 
            local totalTime = v.Properties.Time + v.Properties.EffectStart
            local timeElapsed = os.clock() - i  

            if timeElapsed > totalTime then 
                v.Remove(v)
                continue
            end 

            v.DrawingObjects.Line.From = V3toV2(points.From[1]) 
            v.DrawingObjects.Line.To = V3toV2(points.To[1])
        end 
    end 
end 
end 

RunService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value + 1, function()
for i,v in pairs(espGroups) do 
    runGroup(v)
end 
end)

return module

