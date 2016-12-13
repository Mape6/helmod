-------------------------------------------------------------------------------
-- Classe to build recipe dialog
--
-- @module PlannerRecipeSelector
-- @extends #PlannerDialog
--

PlannerRecipeSelector = setclass("HMPlannerRecipeSelector", PlannerDialog)

local recipeGroups = {}
local recipeFilter = nil
local recipeFilterProduct = true
-------------------------------------------------------------------------------
-- On initialization
--
-- @function [parent=#PlannerRecipeSelector] on_init
--
-- @param #PlannerController parent parent controller
--
function PlannerRecipeSelector.methods:on_init(parent)
	self.panelCaption = "Recipe Selector"
	self.player = self.parent.parent
end

-------------------------------------------------------------------------------
-- Get the parent panel
--
-- @function [parent=#PlannerRecipeSelector] getParentPanel
--
-- @param #LuaPlayer player
--
-- @return #LuaGuiElement
--
function PlannerRecipeSelector.methods:getParentPanel(player)
	return self.parent:getDialogPanel(player)
end

-------------------------------------------------------------------------------
-- Get or create filter panel
--
-- @function [parent=#PlannerRecipeSelector] getFilterPanel
--
-- @param #LuaPlayer player
--
function PlannerRecipeSelector.methods:getFilterPanel(player)
	local panel = self:getPanel(player)
	if panel["filter-panel"] ~= nil and panel["filter-panel"].valid then
		return panel["filter-panel"]
	end
	return self:addGuiFrameV(panel, "filter-panel", "helmod_frame_resize_row_width", ({"helmod_common.filter"}))
end

-------------------------------------------------------------------------------
-- Get or create scroll panel
--
-- @function [parent=#PlannerRecipeSelector] getSrollPanel
--
-- @param #LuaPlayer player
--
function PlannerRecipeSelector.methods:getSrollPanel(player)
	local displaySize = self.player:getGlobalSettings(player, "display_size")
	local panel = self:getPanel(player)
	if panel["main-panel"] ~= nil and panel["main-panel"].valid then
		return panel["main-panel"]["scroll-panel"]
	end
	local mainPanel = self:addGuiFrameV(panel, "main-panel", "helmod_frame_resize_row_width")
	return self:addGuiScrollPane(mainPanel, "scroll-panel", "helmod_scroll_recipe_selector_"..displaySize, "auto", "auto")
end

-------------------------------------------------------------------------------
-- Get or create groups panel
--
-- @function [parent=#PlannerRecipeSelector] getGroupsPanel
--
-- @param #LuaPlayer player
--
function PlannerRecipeSelector.methods:getGroupsPanel(player)
	local panel = self:getSrollPanel(player)
	if panel["groups-panel"] ~= nil and panel["groups-panel"].valid then
		return panel["groups-panel"]
	end
	return self:addGuiFlowV(panel, "groups-panel", "helmod_flow_resize_row_width")
end

-------------------------------------------------------------------------------
-- Get or create item list panel
--
-- @function [parent=#PlannerRecipeSelector] getItemListPanel
--
-- @param #LuaPlayer player
--
function PlannerRecipeSelector.methods:getItemListPanel(player)
	local panel = self:getSrollPanel(player)
	if panel["item-list-panel"] ~= nil and panel["item-list-panel"].valid then
		return panel["item-list-panel"]
	end
	return self:addGuiFlowV(panel, "item-list-panel", "helmod_flow_resize_row_width")
end

-------------------------------------------------------------------------------
-- On open
--
-- @function [parent=#PlannerRecipeSelector] on_open
--
-- @param #LuaPlayer player
-- @param #LuaGuiElement element button
-- @param #string action action name
-- @param #string item first item name
-- @param #string item2 second item name
-- @param #string item3 third item name
--
-- @return #boolean if true the next call close dialog
--
function PlannerRecipeSelector.methods:on_open(player, element, action, item, item2, item3)
	Logging:debug("PlannerRecipeSelector:on_open():",player, element, action, item, item2, item3)
	local globalPlayer = self.player:getGlobal(player)
	if item3 ~= nil then
		recipeFilter = item3:lower():gsub("[-]"," ")
	else
		recipeFilter = nil
	end
	recipeFilterProduct = true
	-- close si nouvel appel
	return true
end

-------------------------------------------------------------------------------
-- After open
--
-- @function [parent=#PlannerRecipeSelector] after_open
--
-- @param #LuaPlayer player
-- @param #LuaGuiElement element button
-- @param #string action action name
-- @param #string item first item name
-- @param #string item2 second item name
-- @param #string item3 third item name
--
function PlannerRecipeSelector.methods:after_open(player, element, action, item, item2, item3)
	self.parent:send_event(player, "HMPlannerRecipeEdition", "CLOSE")
	self.parent:send_event(player, "HMPlannerProductEdition", "CLOSE")
	self.parent:send_event(player, "HMPlannerSettings", "CLOSE")
end

-------------------------------------------------------------------------------
-- On event
--
-- @function [parent=#PlannerRecipeSelector] on_event
--
-- @param #LuaPlayer player
-- @param #LuaGuiElement element button
-- @param #string action action name
-- @param #string item first item name
-- @param #string item2 second item name
-- @param #string item3 third item name
--
function PlannerRecipeSelector.methods:on_event(player, element, action, item, item2, item3)
	Logging:debug("PlannerRecipeSelector:on_event():",player, element, action, item, item2, item3)
	local globalPlayer = self.player:getGlobal(player)
	local globalSettings = self.player:getGlobal(player, "settings")
	local defaultSettings = self.player:getDefaultSettings()
	
	if action == "recipe-group" then
		globalPlayer.recipeGroupSelected = item
		self:on_update(player, element, action, item, item2, item3)
	end

	if action == "recipe-select" then
		local productionBlock = self.parent.model:addRecipeIntoProductionBlock(player, item)
		self.parent.model:update(player)
		self.parent:refreshDisplayData(player)
		self:close(player)
	end

	if action == "change-boolean-settings" then
		if globalSettings[item] == nil then globalSettings[item] = defaultSettings[item] end
		globalSettings[item] = not(globalSettings[item])
		self:on_update(player, item, item2, item3)
	end

	if action == "recipe-filter-switch" then
		recipeFilterProduct = not(recipeFilterProduct)
		self:on_update(player, element, action, item, item2, item3)
	end

	if action == "recipe-filter" then
		recipeFilter = element.text
		self:on_update(player, element, action, item, item2, item3)
	end

end

-------------------------------------------------------------------------------
-- On update
--
-- @function [parent=#PlannerRecipeSelector] on_update
--
-- @param #LuaPlayer player
-- @param #LuaGuiElement element button
-- @param #string action action name
-- @param #string item first item name
-- @param #string item2 second item name
-- @param #string item3 third item name
--
function PlannerRecipeSelector.methods:on_update(player, element, action, item, item2, item3)
	Logging:trace("PlannerRecipeSelector:on_update():",player, element, action, item, item2, item3)
	local globalPlayer = self.player:getGlobal(player)
	-- recuperation recipes
	recipeGroups = {}
	local firstGroup = nil
	for key, recipe in pairs(self.player:getRecipes(player)) do
		local find = false
		if recipeFilter ~= nil and recipeFilter ~= "" then
			local elements = recipe.products
			if recipeFilterProduct ~= true then
				elements = recipe.ingredients
			end
			
			for key, element in pairs(elements) do
				local search = element.name:lower():gsub("[-]"," ")
				if string.find(search, recipeFilter) then
					find = true
				end
			end
		else
			find = true
		end

		local filter_show_hidden = self.player:getGlobalSettings(player, "filter_show_hidden")
		if find == true and (recipe.enabled == true or filter_show_hidden == true) then
			if firstGroup == nil then firstGroup = recipe.group.name end
			if recipeGroups[recipe.group.name] == nil then recipeGroups[recipe.group.name] = {} end
			if recipeGroups[recipe.group.name][recipe.subgroup.name] == nil then recipeGroups[recipe.group.name][recipe.subgroup.name] = {} end
			table.insert(recipeGroups[recipe.group.name][recipe.subgroup.name], recipe)
		end
	end

	if recipeGroups[globalPlayer.recipeGroupSelected] == nil then
		globalPlayer.recipeGroupSelected = firstGroup
	end
	self:updateFilter(player, element, action, item, item2, item3)
	self:updateGroupSelector(player, element, action, item, item2, item3)
	self:updateItemList(player, element, action, item, item2, item3)
end

-------------------------------------------------------------------------------
-- Update filter
--
-- @function [parent=#PlannerRecipeSelector] updateFilter
--
-- @param #LuaPlayer player
-- @param #LuaGuiElement element button
-- @param #string action action name
-- @param #string item first item name
-- @param #string item2 second item name
-- @param #string item3 third item name
--
function PlannerRecipeSelector.methods:updateFilter(player, element, action, item, item2, item3)
	Logging:trace("PlannerRecipeSelector:updateFilter():",player, element, action, item, item2, item3)
	local globalPlayer = self.player:getGlobal(player)
	local panel = self:getFilterPanel(player)
	local globalSettings = self.player:getGlobal(player, "settings")

	if panel["filter"] == nil then
		local guiFilter = self:addGuiTable(panel, "filter", 2)
		local filter_show_hidden = self.player:getGlobalSettings(player, "filter_show_hidden")
		self:addGuiCheckbox(guiFilter, self:classname().."=change-boolean-settings=ID=filter_show_hidden", filter_show_hidden)
		self:addGuiLabel(guiFilter, "filter_show_hidden", ({"helmod_recipe-edition-panel.filter-show-hidden"}))
		
		self:addGuiCheckbox(guiFilter, self:classname().."=recipe-filter-switch=ID=filter-product", recipeFilterProduct)
		self:addGuiLabel(guiFilter, "filter-product", ({"helmod_recipe-edition-panel.filter-by-product"}))
		
		self:addGuiCheckbox(guiFilter, self:classname().."=recipe-filter-switch=ID=filter-ingredient", not(recipeFilterProduct))
		self:addGuiLabel(guiFilter, "filter-ingredient", ({"helmod_recipe-edition-panel.filter-by-ingredient"}))
		
		self:addGuiLabel(guiFilter, "filter-value", ({"helmod_common.filter"}))
		self:addGuiText(guiFilter, self:classname().."=recipe-filter=ID=filter-value", recipeFilter)
		
		self:addGuiLabel(panel, "message", ({"helmod_recipe-edition-panel.message"}))
	else
		panel["filter"][self:classname().."=recipe-filter-switch=ID=filter-product"].state = recipeFilterProduct
		panel["filter"][self:classname().."=recipe-filter-switch=ID=filter-ingredient"].state = not(recipeFilterProduct)
	end

end

-------------------------------------------------------------------------------
-- Update item list
--
-- @function [parent=#PlannerRecipeSelector] updateItemList
--
-- @param #LuaPlayer player
-- @param #LuaGuiElement element button
-- @param #string action action name
-- @param #string item first item name
-- @param #string item2 second item name
-- @param #string item3 third item name
--
function PlannerRecipeSelector.methods:updateItemList(player, element, action, item, item2, item3)
	Logging:trace("PlannerRecipeSelector:updateItemList():",player, element, action, item, item2, item3)
	local globalPlayer = self.player:getGlobal(player)
	local panel = self:getItemListPanel(player)
	local globalSettings = self.player:getGlobal(player, "settings")

	if panel["recipe-list"] ~= nil  and panel["recipe-list"].valid then
		panel["recipe-list"].destroy()
	end

	-- recuperation recipes et subgroupes
	local recipeSubgroups = {}
	if recipeGroups[globalPlayer.recipeGroupSelected] ~= nil then
		recipeSubgroups = recipeGroups[globalPlayer.recipeGroupSelected]
	end
	--local guiRecipeSelectorTable = self:addGuiTable(panel, "recipe-table", 10)
	local guiRecipeSelectorList = self:addGuiFlowV(panel, "recipe-list", "helmod_flow_recipe_selector")
	for key, subgroup in pairs(recipeSubgroups) do
		-- boucle subgroup
		local guiRecipeSubgroup = self:addGuiTable(guiRecipeSelectorList, "recipe-table-"..key, 10, "helmod_table_recipe_selector")
		for key, recipe in spairs(subgroup,function(t,a,b) return t[b]["order"] > t[a]["order"] end) do
			local localised_name = recipe.localised_name
			if globalSettings.real_name == true then
				localised_name = recipe.name
			end
			Logging:trace("PlannerRecipeSelector:on_update",recipe.name)
			self:addSelectSpriteIconButton(guiRecipeSubgroup, self:classname().."=recipe-select=ID=", self.player:getRecipeIconType(player, recipe), recipe.name, recipe.name, nil, localised_name)
		end
	end

end

-------------------------------------------------------------------------------
-- Update group selector
--
-- @function [parent=#PlannerRecipeSelector] updateGroupSelector
--
-- @param #LuaPlayer player
-- @param #LuaGuiElement element button
-- @param #string action action name
-- @param #string item first item name
-- @param #string item2 second item name
-- @param #string item3 third item name
--
function PlannerRecipeSelector.methods:updateGroupSelector(player, element, action, item, item2, item3)
	Logging:trace("PlannerRecipeSelector:updateGroupSelector():",player, element, action, item, item2, item3)
	local globalPlayer = self.player:getGlobal(player)
	local panel = self:getGroupsPanel(player)

	if panel["recipe-groups"] ~= nil  and panel["recipe-groups"].valid then
		panel["recipe-groups"].destroy()
	end

	-- ajouter de la table des groupes de recipe
	local guiRecipeSelectorGroups = self:addGuiTable(panel, "recipe-groups", 6, "helmod_table_recipe_selector")
	for group, element in pairs(recipeGroups) do
		-- set le groupe
		if globalPlayer.recipeGroupSelected == nil then globalPlayer.recipeGroupSelected = group end
		local color = nil
		if globalPlayer.recipeGroupSelected == group then
			color = "yellow"
		end
		local tooltip = group
		-- ajoute les icons de groupe
		local action = self:addXxlSelectSpriteIconButton(guiRecipeSelectorGroups, self:classname().."=recipe-group=ID=", "item-group", group, group, color, tooltip)
	end

end
