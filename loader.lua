local one_time_only = true

cheat.set_callback("paint", function()
    if one_time_only == true then
        local placeId_index = globals.place_id()
        local mappingUrl = "https://raw.githubusercontent.com/iilliliilil/lmk/refs/heads/main/ids.json"
        if placeId_index == nil then
            print('Why tf are u not in a game??.')
        else
            if placeId_index ~= nil then
                http.get(mappingUrl,nil, function(mappingResponse)
                    if mappingResponse then
                        local mapping = json.parse(mappingResponse)
                        if mapping then
                            for k, v in pairs(mapping) do
                            end
                            local placeId_str = tostring(placeId_index)
                            local scriptUrl = mapping[placeId_str]
                            if scriptUrl then
                                http.get(scriptUrl,nil, function(script)
                                    if script then
                                        local func, err = loadstring(script)
                                        if func then
                                            func()
                                            print("Script loaded successfully!")
                                        else
                                        end
                                    else
                                    end
                                end)
                            else
                                print("Game not supported. ")
                            end
                        else
                        end
                    else
                    end
                end)
            else
            end
        end
        one_time_only = false
    end
end)
