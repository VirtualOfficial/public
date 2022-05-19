local module = {}
module.__index = module

-->> Services
local players = game:GetService("Players")

-->> Variables

local plr = players.LocalPlayer
local mouse = plr:GetMouse()

local cam = workspace.CurrentCamera

-->> Setup
local V3new = Vector3.new
local WorldToViewportPoint = cam.WorldToViewportPoint

local function constructDrawing(object,properties)
    local Draw = Drawing.new(object)

    for i,v in pairs(properties) do 
        Draw[i] = v
    end 

    return Draw
end

-- important: redo the way I call my update function. there's probably something wrong with it
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

function module.new(settings)
    settings = settings or {}
    
    local default = {}

    default.refreshRate = 1
    default.boxes = false
    default.text = false 
    default.tracer = false 
    default.canRender = false 
    default.visible = false
    default.facecam = false
    default.distance = 2500
    default.color = Color3.fromRGB(255,255,255)
    default.overrides = {}
    default.offset = CFrame.new(0,-.25,0)
    default.chams = false
    default.outlineTransparency = 0
    default.fillTransparency = 0

    --// override functions: customColor, customVisible, customText, customFilter

    for i,v in pairs(default) do 
        if settings[i] == nil then 
            settings[i] = v
        end 
    end 

    return settings 
end 

local espGroups = {}

function module.newGroup(settings)
    settings.groupEnabled = false 
    settings.espObjects = {}
    settings.lastCache = 0
    settings.cache = {}

    local functions = {}
    functions.__index = functions

    -- create a way to add ESP objects and pass that function through
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

            wait()

            box.Highlight:Destroy()

            for i,v in pairs(box.Objects) do
                v.Visible = false
                v.Transparency = 0
            end 
        end

        local box = setmetatable({
            Name = props ~= nil and props.Name or model.Name,
            Type = "Box",
            primarypart = props.primarypart or model.ClassName == "Model" and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")) or model:IsA("BasePart") and model,
            Objects = {},
        }, objectFuncs)
    
        local highlight = Instance.new("Highlight")
        highlight.Enabled = false
        highlight.Parent = game.CoreGui

        box.Highlight = highlight

        if box.primarypart.Parent then 
            if box.primarypart.Parent:IsA("Model") then 
                box.Highlight.Adornee = box.primarypart.Parent
            else 
                box.Highlight.Adornee = box.primarypart
            end 
        else 
            box.Highlight.Adornee = box.primarypart
        end 

        for i,v in pairs(props) do 
            box[i] = v
        end 
    
        box.Objects.box = constructDrawing("Quad", {
            Thickness = 1,
            Color = box.color,
            Transparency = .7,
            Filled = false,
            ZIndex = 3, 
            Visible = self.visible and self.boxes
        })
    
        box.Objects.text = constructDrawing("Text", {
            Text = "",
            Color = box.color,
            Center = true,
            Outline = true,
            Font = 1,
            Size = 16,
            Visible = self.visible and self.text
        })
        
        box.Objects.tracer = constructDrawing("Line", {
            Thickness = 1,
            Color = box.color,
            Transparency = 1,
            ZIndex = 3,
            Visible = self.visible and self.tracer,
        })

        model:GetPropertyChangedSignal("Parent"):Connect(function()
            if model.Parent == nil and self.deleteOnNil ~= false then
                box:Remove()
            end
        end)

        local hum = model:FindFirstChildOfClass("Humanoid") or (model.Parent and model.Parent:FindFirstChildOfClass("Humanoid"))
    
        if hum then
            hum.Died:Connect(function()
                if self.deleteOnNil ~= false then
                    box:Remove()
                end
            end)
        end
    
        box.index = model
    
        settings.espObjects[model] = box
    
        return box 
    end 

    function functions.editSetting(setting,value,applytoAll)
        print(setting,value)

        if setting == "visible" then 
            settings.groupEnabled = value 

            if value == false then 
                wait()

                for i,v in pairs(settings.espObjects) do 
                    v.Highlight.Enabled = false

                    for _,esp in pairs(v.Objects) do 
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
    end 

    -- add delete function

    local meta = setmetatable(settings,functions)

    table.insert(espGroups,meta)

    return meta,functions
end 

function module.AddListener(preset,object)
    local Group,funcs = module.newGroup(preset)
    -- we can add to this group using the "addObject" function, we just have to pass settings and a part
    local function addItem(obj)
        if preset.customFilter == nil or (preset.customFilter and preset.customFilter(obj,ESPObjects) == true) then 
            local newSettings = preset

            if preset.CustomSettings then 
                newSettings = preset.CustomSettings(obj,preset)
            end 

            Group.addObject(newSettings,obj)

            if newSettings.callback then
                newSettings.callback(obj)
            end 
        end 
    end 

    if preset.recursive then
        object.DescendantAdded:Connect(addItem)

        for i,v in pairs(object:GetDescendants()) do
            coroutine.wrap(addItem)(v)
        end
    else    
        object.ChildAdded:Connect(addItem)

        for i,v in pairs(object:GetChildren()) do
            coroutine.wrap(addItem)(v)
        end
    end    

    local functions = {}
    functions.__index = functions

    for i,v in pairs(funcs) do 
        functions[i] = v
    end 

    return functions
end 

function module.createGroup(preset,parts)
    local Group,funcs = module.newGroup(preset)
    -- we can add to this group using the "addObject" function, we just have to pass settings and a part
    local function addItem(obj)
        if preset.customFilter == nil or (preset.customFilter and preset.customFilter(obj,ESPObjects) == true) then 
            local newSettings = preset

            if preset.CustomSettings then 
                newSettings = preset.CustomSettings(obj,preset)
            end 

            Group.addObject(newSettings,obj)

            if newSettings.callback then
                newSettings.callback(obj)
            end 
        end 
    end 

    for i,v in pairs(parts) do 
        addItem(v)
    end 

    local functions = {}
    functions.__index = functions

    for i,v in pairs(funcs) do 
        functions[i] = v
    end 

    return functions    
end 

--[[

    update will loop through all available GROUPS.
    if a group is set to enabled, it will gather all enabled ESPs and gather the ones that are within the current magnitude. 
    This will refresh EACH second. This means that each magnitude can be delayed up to 2 seconds, but it relieves load.
    
    Calculations are in LPH_JIT in order to optimize speed

]]

local lastDt = 0

local function runGroup(group)
    local lastCache = group.lastCache

    if tick() - lastCache > 1 then 
        -- recache
        group.cache = {}
        group.lastCache = tick()

        for i,v in pairs(group.espObjects) do 
            if v.primarypart == nil or v.primarypart.Parent == nil or v.primarypart.Parent.Parent == nil then 
                group.espObjects[i]:Remove()
                group.espObjects[i] = nil 
                continue
            end

            if (v.primarypart.Position - funcs.GetPrimaryPart(funcs.GetChar(game:GetService("Players").LocalPlayer)).Position).magnitude < group.distance then 
                group.cache[i] = v 
            else 
                v.Highlight.Enabled = false

                for i,v in pairs(v.Objects) do
                    v.Visible = false
                end
            end 
        end 
    end 

    local drawFunctions = {
        ["boxes"] = function(CFPoints,self)
            local TL, Vis1 = WorldToViewportPoint(cam, CFPoints.TL.p)
            local TR, Vis2 = WorldToViewportPoint(cam, CFPoints.TR.p)
            local BL, Vis3 = WorldToViewportPoint(cam, CFPoints.BL.p)
            local BR, Vis4 = WorldToViewportPoint(cam, CFPoints.BR.p)
    
            if Vis1 and Vis2 and Vis3 and Vis4 and self.primarypart then
                self.Objects.box.Visible = true
                self.Objects.box.PointA = Vector2.new(TR.X, TR.Y)
                self.Objects.box.PointB = Vector2.new(TL.X, TL.Y)
                self.Objects.box.PointC = Vector2.new(BL.X, BL.Y)
                self.Objects.box.PointD = Vector2.new(BR.X, BR.Y)
                
                self.Objects.box.Color = self.color
            else
                self.Objects.box.Visible = false
            end
        end,
        ["tracer"] = function(CFPoints,self)
            local TP, visible = WorldToViewportPoint(cam, CFPoints.Torso.p)
                
            if visible then
                self.Objects.tracer.Visible = true
                self.Objects.tracer.From = Vector2.new(TP.X, TP.Y)
                self.Objects.tracer.To = Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/1)
                
                self.Objects.tracer.Color = self.color
            else
                self.Objects.tracer.Visible = false
            end
        end,
        ["text"] = function(CFPoints,self)
            local TagPos, Vis5 = WorldToViewportPoint(cam, CFPoints.TagPos.p)
                        
            if Vis5 then
                local text = self.CustomText and self.CustomText(self.primarypart) or self.primarypart.Name

                if text == "unloaded" then 
                    error("Unloaded.")
                    return
                end 

                self.Objects.text.Visible = true
                
                self.Objects.text.Position = Vector2.new(TagPos.X, TagPos.Y + 12)
                
                self.Objects.text.Text = text
                self.Objects.text.Color = self.color
            else
                self.Objects.text.Visible = false
            end
        end
    }

    -- find functions we need to use 
    local updateFuncs = {}

    for i,v in pairs(drawFunctions) do 
        if group[i] == true then 
            updateFuncs[i] = v                       
        end 
    end 

    local count = 0

    for i,v in pairs(group.cache) do 
        count += 1

        if funcs.GetChar(game:GetService("Players").LocalPlayer) == nil then   
            if v.Objects == nil then return end 
            
            v.Highlight.Enabled = false

            for i,v in pairs(v.Objects) do 
                v.Visible = false   
            end 

            continue
        end 

        local function delete()
            group.espObjects[i]:Remove()
        end 

        if v.primarypart == nil then 
            delete()
            continue
        end 

        local allowDraw = true 

        if self.customVisible and self.customVisible(v.primarypart,self) ~= true then 
            allowDraw = false 
        end 

        if not allowDraw then
            for i,v in pairs(v.Objects) do
                v.Visible = false
            end

            v.Highlight.Enabled = false

            continue
        end

        if group.chams then 
            v.Highlight.Enabled = true
        else 
            v.Highlight.Enabled = false
        end
        
        local cf = v.primarypart.CFrame
                
        if group.facecam then
            local cfAngle = CFrame.new(cf.p, cam.CFrame.p)
    
            local x, y, z = cfAngle:ToEulerAnglesYXZ()
            local newCF = CFrame.Angles(0, y, z) 
    
            cf = CFrame.new(cfAngle.p) * newCF
        end

        local size = v.size or Vector3.new(4,6,0)

        local CFPoints = {
            TL = cf * v.offset * CFrame.new(size.X/2,size.Y/2,0),
            TR = cf * v.offset * CFrame.new(-size.X/2,size.Y/2,0),
            BL = cf * v.offset * CFrame.new(size.X/2,-size.Y/2,0),
            BR = cf * v.offset * CFrame.new(-size.X/2,-size.Y/2,0),
            TagPos = cf * v.offset * CFrame.new(0,-size.Y/2,0),
            Torso = cf * v.offset
        }

        local clr = group.color
    
        if group.CustomColor then
            clr = group.CustomColor(v.primarypart,v)
        end 

        if group.outlineTransparency then 
            if group.outlineTransparency ~= 0 then 
                print("outline transparency: ",group.outlineTransparency)
            end
            
            v.Highlight.OutlineTransparency = group.outlineTransparency
        end 

        if group.fillTransparency then 
            v.Highlight.FillTransparency = group.fillTransparency
        end 

        v.Highlight.FillColor = clr 
        v.Highlight.OutlineColor = clr

        v.color = clr

        for i,FUNC in pairs(drawFunctions) do 
            if group[i] ~= true then 
                local tab = {
                    ["boxes"] = "box",
                    ["tracer"] = "tracer",
                    ["text"] = "text"
                }

                if tab[i] then 
                    v.Objects[tab[i]].Visible = false
                end 
            end 
        end 

        for n,func in pairs(updateFuncs) do 
            local succ,err = pcall(function() func(CFPoints,v) end) 
            
            -- safe to assume that the render object is destroyed. kill the object 
            if err then 
                warn("Killing object due to " .. tostring(err))
                delete()
                break
            end
        end 
    end 

    return count
end

local crnt = tick()

local refresh = 60

module.setRefresh = function(a)
    refresh = a
end 

game:GetService("RunService").RenderStepped:Connect(function(dt)
    -- base refresh rate is 60
    if tick() - crnt > (1/refresh) then 
        crnt = tick()
        local count = 0

        for i,v in pairs(espGroups) do 
            if v.groupEnabled then                                     
                local add = runGroup(v)

                if add ~= nil then
                    count += add
                end
            end 
        end 
    end 
end)

return module
