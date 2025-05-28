local root = globals.data_model()
local players_root = root:FindChild('Players')
local workspace_root = root:FindChild('Workspace')
local players_names = entity.get_players()
local maps = {"House2", "Hotel", "ResearchFacility", "Mansion2", "Factory", "BioLab", "PoliceStation", "Workplace", "MilBase"}


local fonts =
{
    VerdanaAA = render.create_font("C:\\Windows\\Fonts\\Verdana.ttf", 12, "a")
}



local enable = ui.new_checkbox('Enable Revealer')
local rolesX, rolesY, rolesWidth, rolesHeight = 400, 100, 250, 20
local isDraggingRoles = false
local dragOffsetX, dragOffsetY = 0, 0
local cursor = input.cursor_position()
local VK_LBUTTON = 0x01


local currentMap = nil   
local lastCheckTime = 0 
local checkInterval = 5   
local gunPosition = "Not found"
local gunWorldPos = nil   
local hasSheriff = false  
local screenSize = render.screen_size()
local GeneralGun = nil

local function CheckCurrentMap()
    for _, mapName in ipairs(maps) do
        if workspace_root:FindChild(mapName) then
            return mapName
        end
    end
    return nil
end


local function checkGunDrop()
    if not currentMap then
        return "No map selected", nil
    end

    local mapObject = workspace_root:FindChild(currentMap)
    if not mapObject then
        return "Map not found", nil
    end


  --  print("Children of map " .. currentMap .. ":")
    for _, child in ipairs(mapObject:Children()) do
   --     print("  " .. child:Name())
    end

    local gunDrop = mapObject:FindChild('GunDrop')
    if not gunDrop then
        GeneralGun = nil
        return "Gun not dropped", nil
    else
        GeneralGun = gunDrop
    end


    local positionTable = gunDrop:Primitive():GetPartPosition()

        local position = positionTable
   
        local positionStr = string.format("x: %.2f, y: %.2f, z: %.2f", position.x, position.y, position.z)
        return positionStr, position 
end


local function isOnScreen(x, y)
    return x >= 0 and x <= screenSize.x and y >= 0 and y <= screenSize.y
end


cheat.set_callback("paint", function()
    local currentTime = globals.curtime() 


    local roleLines = {}
    hasSheriff = false 
    local playerInstances = players_root:Children()
    for _, playerInstance in ipairs(playerInstances) do
        if playerInstance and playerInstance:Name() and playerInstance.Name ~= "PointsService" then
            local name = playerInstance:Name()
            local role = "Innocent"
            local hasKnife = false
            local hasGun = false

            -- Check Backpack under Players hierarchy
            local backpack = playerInstance:FindChild("Backpack")
            if backpack then
                for _, item in ipairs(backpack:Children()) do
                    if item and item:Name() then
                        local itemName = item:Name()
                        if itemName == "Knife" then
                            hasKnife = true
                        elseif itemName == "Gun" then
                            hasGun = true
                        end
                    end
                end
            else
              --  print("No Backpack found for " .. name)
            end

            local playerCharacter = workspace_root:FindChild(name)
            if playerCharacter then
                for _, item in ipairs(playerCharacter:Children()) do
                    if item and item:Name() then
                        local itemName = item:Name()
                        if itemName == "Knife" then
                            hasKnife = true
                        elseif itemName == "Gun" then
                            hasGun = true
                        end
                    end
                end
            else
             --   print("No character found in Workspace for " .. name)
            end

   
            if hasKnife then
                role = "Murderer"
            elseif hasGun then
                role = "Sheriff"
                hasSheriff = true 
            end

            table.insert(roleLines, { name = name, role = role })
        else
         --   print("Skipped invalid player instance: " .. (playerInstance and playerInstance:Name() or "nil"))
        end
    end


    if currentTime - lastCheckTime >= checkInterval then
        lastCheckTime = currentTime

        if hasSheriff then

          --  print("Sheriff is alive, skipping map and gun checks.")
            currentMap = nil 
            gunPosition = "Sheriff alive"
            gunWorldPos = nil
        else
         
            if currentMap then

             --   print("Checking if map " .. currentMap .. " still exists...")
                if workspace_root:FindChild(currentMap) then
               --     print("Map " .. currentMap .. " still exists.")
                    gunPosition, gunWorldPos = checkGunDrop()
                else
               --     print("Map " .. currentMap .. " no longer exists. Returning to check all maps.")
                    currentMap = nil
                    gunPosition = "Not found"
                    gunWorldPos = nil
                end
            else
             --   print("Checking all maps...")
                local foundMap = CheckCurrentMap()
                if foundMap then
                 --   print("Found map: " .. foundMap .. ". Starting to monitor it.")
                    currentMap = foundMap
                    gunPosition, gunWorldPos = checkGunDrop() 
                else
                --    print("No maps found.")
                    gunPosition = "Not found"
                    gunWorldPos = nil
                end
            end
        end
    end

   
    if enable:get() == true then
        cursor = input.cursor_position()


        if utils.key_state(VK_LBUTTON) then
            if isMouseOverBox(rolesX, rolesY, rolesWidth, 20, cursor.x, cursor.y) then
                if not isDraggingRoles then
                    isDraggingRoles = true
                    dragOffsetX = cursor.x - rolesX
                    dragOffsetY = cursor.y - rolesY
                end
            end
        else
            isDraggingRoles = false
        end

        if isDraggingRoles then
            rolesX = cursor.x - dragOffsetX
            rolesY = cursor.y - dragOffsetY
        end

        local baseHeight = 20
        local gunLineHeight = 16
        if #roleLines > 0 then
            rolesHeight = baseHeight + (#roleLines * 16) + 10 + gunLineHeight
        else
            rolesHeight = baseHeight + gunLineHeight
        end

        -- Draw outer box for role display
        render.rect(rolesX, rolesY, rolesWidth, rolesHeight, 13, 13, 13, 255, 0)
        render.rect(rolesX + 1, rolesY + 1, rolesWidth - 2, rolesHeight - 2, 28, 28, 29, 255, 0)
        render.gradient(rolesX + 2, rolesY + 2, rolesWidth - 4, 2,
            116, 147, 213, 200,
            255, 255, 255, 200,
            116, 147, 213, 200,
            255, 255, 255, 200
        )


        local textY = rolesY + 8
        for _, info in ipairs(roleLines) do
            local color = { 255, 255, 255 } 
            if info.role == "Murderer" then
                color = { 255, 60, 60 }
            elseif info.role == "Sheriff" then
                color = { 60, 120, 255 }
            end
            render.text(rolesX + 8, textY, string.format("%s - %s", info.name, info.role), color[1], color[2], color[3], 255, "s", 4)
            textY = textY + 16
        end


        render.text(rolesX + 8, textY, "Gun Drop: " .. gunPosition, 255, 255, 0, 255, "s", 4)
    end

    local MurderName = ""
local SheriffName = ""


for _, info in ipairs(roleLines) do
    if info.role == "Murderer" then
        MurderName = info.name
    end

    if info.role == "Sheriff" then
        SheriffName = info.name
    end
end

    local players = entity.get_players()

    for sigma, player in ipairs(players) do
        if player:Name() == MurderName then
            local bbox = player:Bbox()

            render.rect_outline(bbox.x,bbox.y,bbox.width,bbox.height, 255, 0, 0, 255, 0, 1)
        end
        if player:Name() == SheriffName then
            local bbox = player:Bbox()
            render.rect_outline(bbox.x,bbox.y,bbox.width,bbox.height, 0, 0, 255, 255, 0, 1)
        end

    end

    if GeneralGun then
        local position = GeneralGun:Primitive():GetPartPosition()
        local W2S_POS = utils.world_to_screen(Vector3(position.x,position.y,position.z))
    
    
        local GunSize =  Vector3(1,2,1.2)
        

        local minBounds = utils.world_to_screen(Vector3(position.x - GunSize.x/2, position.y - GunSize.y/2, position.z - GunSize.z/2))
        local maxBounds = utils.world_to_screen(Vector3(position.x + GunSize.x/2, position.y + GunSize.y/2, position.z + GunSize.z/2))
        

        local width = math.abs(maxBounds.x - minBounds.x)
        local height = math.abs(maxBounds.y - minBounds.y)
        

        render.text(W2S_POS.x,W2S_POS.y,"GUN DROP",255,0,0,255, "o", fonts.VerdanaAA)
  

        render.rect_outline(W2S_POS.x - width/2, W2S_POS.y - height/2, width, height, 255, 0, 0, 255, 0, 1)
    end
end) 

function isMouseOverBox(x, y, w, h, cx, cy)
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end 
