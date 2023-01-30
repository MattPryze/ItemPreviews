ItemPreviews = {
    styler = {
        type = EXTENSION_TYPE.NBT_EDITOR_STYLE,
        recursive = true
    }
}

function BedrockStatesNBTToString(states)
    local statesStr = ""

    for i=0, states.childCount-1 do
        local state = states:child(i)

        if(state.type == TYPE.BYTE) then
            statesStr = statesStr .. "1_" .. state.name .. "=" .. tostring(state.value) .. ","
        elseif(state.type == TYPE.INT) then
            statesStr = statesStr .. "3_" .. state.name .. "=" .. tostring(state.value) .. ","
        elseif(state.type == TYPE.STRING) then
            statesStr = statesStr .. "8_" .. state.name .. "=" .. state.value .. ","
        end
    end

    statesStr = statesStr:sub(1, -2)

    return statesStr
end

function ItemPreviews.styler:main(root, context)


    --TODO
    --better version checking

    ItemPreviews.styler.version = -1

    if(context.edition == EDITION.JAVA) then -- DataVersion
        if(root:contains("DataVersion", TYPE.INT)) then
            ItemPreviews.styler.version = root.lastFound.value
        end
    end

end

function ItemPreviews.styler:recursion(root, target, context)

    if(target.name ~= "Count" or target.type ~= TYPE.BYTE or target.parentTag.type ~= TYPE.COMPOUND) then return end

    local item = target.parentTag

    if(context.edition == EDITION.JAVA) then

        if(item:contains("id", TYPE.STRING)) then
            item.id = item.lastFound.value
            item.blockFormat = BLOCK_FORMAT.NAME_STATES
        elseif(item:contains("id", TYPE.SHORT)) then
            item.id = tostring(item.lastFound.value)
            item.blockFormat = BLOCK_FORMAT.ID_DATA
        else return end

        item.meta = ""
        if(item:contains("Damage", TYPE.SHORT)) then
            item.meta = tostring(item.lastFound.value)
            if(item.blockFormat == BLOCK_FORMAT.NAME_STATES) then item.blockFormat = BLOCK_FORMAT.NAME_DATA end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(item:contains("Name", TYPE.STRING)) then
            item.id = item.lastFound.value
            item.blockFormat = BLOCK_FORMAT.NAME_DATA
        elseif(item:contains("id", TYPE.SHORT)) then
            item.id = tostring(item.lastFound.value)
            item.blockFormat = BLOCK_FORMAT.ID_DATA
        else return end
    
        item.meta = ""
        if(item:contains("Damage", TYPE.SHORT)) then
            item.meta = tostring(item.lastFound.value)
        else return end


        local block = nil
        if(item:contains("Block", TYPE.COMPOUND)) then

            block = item.lastFound

            if(block:contains("name", TYPE.STRING)) then block.id = block.lastFound.value end
            if(block:contains("states", TYPE.COMPOUND)) then
                local blockStates = block.lastFound
                if(blockStates:contains("mapped_type", TYPE.INT)) then
                    block.meta = tostring(blockStates.lastFound.value)
                else
                    block.meta = BedrockStatesNBTToString(blockStates)
                end

                block.blockFormat = BLOCK_FORMAT.NAME_STATES
            end
            if(block:contains("val", TYPE.SHORT)) then
                block.meta = tostring(block.lastFound.value)
                block.blockFormat = BLOCK_FORMAT.NAME_DATA
            end
        end

        item.block = block

    elseif(context.edition == EDITION.CONSOLE) then

        if(item:contains("id", TYPE.STRING)) then
            item.id = item.lastFound.value
            item.blockFormat = BLOCK_FORMAT.NAME_DATA
        elseif(item:contains("id", TYPE.SHORT)) then
            item.id = tostring(item.lastFound.value)
            item.blockFormat = BLOCK_FORMAT.ID_DATA
        else return end

        item.meta = ""
        if(item:contains("Damage", TYPE.SHORT)) then
            item.meta = tostring(item.lastFound.value)
        end

    end

    self:ProcessItem(item, context)

end

function ItemPreviews.styler:ProcessItem(item, context)

    --load entries from database
    item.itemEntry = Database:find(context.edition, "items", item.id, item.meta, ItemPreviews.styler.version)
    if(not item.itemEntry.valid) then return end

    if(context.edition == EDITION.BEDROCK) then
        if(item.block ~= nil and item.block.id ~= nil and item.block.meta ~= nil) then
            item.blockEntry = Database:find(context.edition, "blocks", item.block.id, item.block.meta, ItemPreviews.styler.version)
            if(item.blockEntry == nil or not item.blockEntry.valid or item.blockEntry.name:len() == 0) then
                item.blockEntry = nil
            end
        end
    end

    local itemPreviewInfo = {}
    itemPreviewInfo.textColor = "#bfbfbf"

    itemPreviewInfo.icon = item.itemEntry.icon
    if(item.blockEntry ~= nil) then itemPreviewInfo.icon = item.blockEntry.icon end

    self:BaseName(item, itemPreviewInfo, context)
    self:Count(item, itemPreviewInfo, context)
    self:DisplayName(item, itemPreviewInfo, context)
    self:Enchantments(item, itemPreviewInfo, context)

    self:ShowPreview(item, itemPreviewInfo, context)
end

function ItemPreviews.styler:BaseName(item, itemPreviewInfo, context)
    itemPreviewInfo.baseName = item.itemEntry.name
    if(item.blockEntry ~= nil) then itemPreviewInfo.baseName = item.blockEntry.name end
end

function ItemPreviews.styler:Count(item, itemPreviewInfo, context)
    if(item:contains("Count", TYPE.BYTE)) then
        itemPreviewInfo.count = item.lastFound.value
    end
end

function ItemPreviews.styler:DisplayName(item, itemPreviewInfo, context)

    if(context.edition == EDITION.JAVA) then
    
        if(item:contains("tag", TYPE.COMPOUND)) then
            item.tag = item.lastFound
    
            if(item.tag:contains("display", TYPE.COMPOUND)) then
                item.tag.display = item.tag.lastFound
    
                if(item.tag.display:contains("Name", TYPE.STRING)) then
    
                    local text = item.tag.display.lastFound.value
                    local textOut = ""
                    local jsonRoot = JSONValue.new()
    
                    local jsonParseResult = jsonRoot:parse(text).type
    
                    if(jsonParseResult == JSON_TYPE.OBJECT) then
                        if(jsonRoot:contains("text", JSON_TYPE.STRING)) then
                            textOut = jsonRoot.lastFound:getString()
                        end
                    elseif(jsonParseResult == JSON_TYPE.STRING) then
                        textOut = jsonRoot:getString()
                    else
                        if(text == "null") then text = "" end
    
                        textOut = text
                    end
    
                    if(textOut ~= "") then
                        itemPreviewInfo.displayName = textOut
                    end
                end
    
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then
        
        if(item:contains("tag", TYPE.COMPOUND)) then
            item.tag = item.lastFound
    
            if(item.tag:contains("display", TYPE.COMPOUND)) then
                item.tag.display = item.tag.lastFound
    
                if(item.tag.display:contains("Name", TYPE.STRING)) then
                    local text = item.tag.display.lastFound.value
    
                    if(text ~= "") then
                        itemPreviewInfo.displayName = text
                    end
                end
    
            end
        end

    elseif(context.edition == EDITION.CONSOLE) then
        
        if(item:contains("tag", TYPE.COMPOUND)) then
            item.tag = item.lastFound
    
            if(item.tag:contains("display", TYPE.COMPOUND)) then
                item.tag.display = item.tag.lastFound
    
                if(item.tag.display:contains("Name", TYPE.STRING)) then
                    local text = item.tag.display.lastFound.value
    
                    if(text ~= "") then
                        itemPreviewInfo.displayName = text
                    end
                end
    
            end
        end

    end

end

function ItemPreviews.styler:Enchantments(item, itemPreviewInfo, context)

    if(item:contains("tag", TYPE.COMPOUND)) then
        local tag = item.lastFound

        for i=0, tag.childCount-1 do
            local child = tag:child(i)
            if(child.name ~= "Enchantments" and child.name ~= "ench" and child.name ~= "StoredEnchantments") then goto loopContinue end
            if(child.type ~= TYPE.LIST or child.listType ~= TYPE.COMPOUND) then goto loopContinue end
            if(child.childCount == 0) then goto loopContinue end

            local enchList = child
            itemPreviewInfo.textColor = "magenta"

            for i=0, enchList.childCount-1 do
                local ench = enchList:child(i)

                if(ench:contains("id", TYPE.STRING)) then
                    ench.id = ench.lastFound.value
                elseif(ench:contains("id", TYPE.SHORT)) then
                    ench.id = tostring(ench.lastFound.value)
                else
                    goto loopContinue1
                end

                local dbEntry = Database:find(context.edition, "enchantments", ench.id)

                if(dbEntry.valid) then
                    ench.prettyName = dbEntry.name

                    if(ench:contains("lvl", TYPE.SHORT)) then
                        local lvl = ench.lastFound.value

                        if(lvl > 0) then
                            ench.prettyName = ench.prettyName .. " " .. lvl
                        end
                    end

                    Style:setLabel(ench, ench.prettyName)
                    Style:setLabelColor(ench, "#bfbfbf")
                end

                ::loopContinue1::
            end

            ::loopContinue::
        end
    end
end

function ItemPreviews.styler:ShowPreview(item, itemPreviewInfo, context)

    local text = itemPreviewInfo.baseName
    if(itemPreviewInfo.count > 1) then
        text = text .. " x" .. tostring(itemPreviewInfo.count)
    end

    if(itemPreviewInfo.displayName ~= nil and itemPreviewInfo.displayName:len() > 0) then
        text = text .. " \"" .. itemPreviewInfo.displayName .. "\""
    end

    Style:setLabel(item, text)
    Style:setLabelColor(item, itemPreviewInfo.textColor)

    if(itemPreviewInfo.icon > 0) then
        Style:setIcon(item, ":DB/" .. tostring(itemPreviewInfo.icon))
    end
    

end

return ItemPreviews
