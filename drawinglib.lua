
--[[
  
    Drawing API lib

    just makes it easier to draw shit in 3d space

]]

local api = {}

--// local funcs
local function constructDrawing(object,properties)
    local Draw = Drawing.new(object)

    for i,v in pairs(properties) do 
        Draw[i] = v
    end 

    return Draw
end

--// main funcs
local drawings = {}

--// custom functions
function api.BulletTracer(origin,hit)
    table.insert(drawings,{
        UserData = {
            Origin = origin,
            Direction = hit,
        },
        Object = constructDrawing("Line",{})
        Update = function(self)
            local obj = self.Object 

            local origin,vis1 = workspace.CurrentCamera:WorldToViewportPoint(self.UserData.Origin)
            local hit,vis2 = workspace.CurrentCamera:WorldToViewportPoint(self.UserData.Direction)

            if true then 
                obj.Visible = true

                obj.From = Vector2.new(origin.X,origin.Y)
                obj.To = Vector2.new(hit.X,hit.Y)
            else 
                obj.Visible = false 
            end 
        end
    })
end 

return api
