--
-- Calamath's Quest Tracker [CQT]
--
-- Copyright (c) 2022 Calamath
--
-- This software is released under the Artistic License 2.0
-- https://opensource.org/licenses/Artistic-2.0
--
-- Note :
-- This addon works that uses the library LibAddonMenu-2.0 by sirinsidiator, Seerah, released under the Artistic License 2.0
-- This addon works that uses the library LibCustomMenu by votan.
-- This addon works that uses the library LibMediaProvider-1.0 by Seerah, released under the LGPL-2.1 license.
-- This addon works that uses the library LibCInteraction by Calamath, released under the Artistic License 2.0
-- You will need to obtain the above libraries separately.
--

if CQuestTracker then return end
-- ---------------------------------------------------------------------------------------
-- Library
-- ---------------------------------------------------------------------------------------
local LMP = LibMediaProvider
if not LMP then d("[CQuestTracker] Error : 'LibMediaProvider' not found.") return end
local LAM = LibAddonMenu2
if not LAM then d("[CQuestTracker] Error : 'LibAddonMenu' not found.") return end
local LibCInteraction = LibCInteraction
if not LibCInteraction then d("[CQuestTracker] Error : 'LibCInteraction' not found.") return end

-- ---------------------------------------------------------------------------------------
-- Name Space
-- ---------------------------------------------------------------------------------------
local CQT = {
	name = "CQuestTracker", 
	version = "1.4.2", 
	author = "Calamath", 
	savedVarsSV = "CQuestTrackerSV", 
	savedVarsVersion = 1, 
	authority = {2973583419,210970542}, 
	isInitialized = false, 
	external = {}
}
CQuestTracker = CQT.external
CQuestTracker.name = CQT.name
CQuestTracker.version = CQT.version
CQuestTracker.author = CQT.author


-- ---------------------------------------------------------------------------------------
-- Helper Functions
-- ---------------------------------------------------------------------------------------
local L = GetString

local function Decolorize(str)
	if type(str) == "string" then
		return str:gsub("|[cC]%x%x%x%x%x%x", ""):gsub("|[rR]", "")
	else
		return str
	end
end

local function Colorize(colorDef, str, option)
--	colorDef : ZO_ColorDef object or hexadecimal RGB notation (usually 6 characters, ignoring alpha)
--	str      : string
--	option   : string for specifying feature options [optional]
--				  nil      --> same as ZO_ColorDef:Colorize(), regardless of whether it is colored text or not.
--				 "FILL"    --> fills the entire text with the specified color, including colored text
--				 "DEFAULT" --> passes colored text unchanged and fills only standard color text with specified color
	local rgbHex
	local tbl
	if type(colorDef) == "string" then
		rgbHex = colorDef:match("(%x%x%x%x%x%x)")	-- checking hexadecimal RGB notation
	elseif type(colorDef) == "table" then
		if colorDef.ToHex and colorDef.Colorize then	-- checking ZO_ColorDef
			rgbHex = colorDef:ToHex()
		end
	end
	if rgbHex and type(str) == "string" then
		if option == "FILL" then
			tbl = { "|c", rgbHex, Decolorize(str), "|r" }
		elseif option == "DEFAULT" then
			tbl = { "|c", rgbHex, str:gsub("(|[cC]%x%x%x%x%x%x.-|[rR])", "|r%1|c"..rgbHex), "|r" }
		else
			tbl = { "|c", rgbHex, str, "|r" }
		end
		return tconcat(tbl)
	else
		return str
	end
end

local function RemoveTexture(str)
	if type(str) == "string" then
		return str:gsub("|t[^|]+|t", "")
	else
		return str
	end
end

local cprint, cprintf
local NORMAL_COLOR = "dcdcdc"
if CHAT_ROUTER then
	cprint = function(text)
		pcall(function(text) CHAT_ROUTER:AddSystemMessage(Colorize(NORMAL_COLOR, tostring(text), "DEFAULT")) end, text)
	end
	cprintf = function(text, ...)
		pcall(function(text, ...) CHAT_ROUTER:AddSystemMessage(Colorize(NORMAL_COLOR, text:format(...), "DEFAULT")) end, text, ...)
	end
else
	cprint = d
	cprintf = df
end


-- ---------------------------------------------------------------------------------------
-- Quest Cache Manager Class
-- ---------------------------------------------------------------------------------------
local UPPER_LIMIT_OF_ASSUMED_QUEST_ID = 50000
local CQT_QuestCache_Singleton = ZO_InitializingObject:Subclass()

function CQT_QuestCache_Singleton:Initialize()
	self.name = "CQT-QuestCacheSingleton"
	self.journalQuestCache = {}
	self.questIdCache = {}
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ADD_ON_LOADED, function(_, addonName)
		if addonName ~= CQT.name then return end
		EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
		if LibDebugLogger then
			self.LDL = LibDebugLogger(self.name)
		else
			self.LDL = {
				Verbose = function() end, 
				Debug = function() end, 
				Info = function() end, 
				Warn = function() end, 
				Error = function() end, 
			}
		end
		self:RebuildJournalQuestCache()
		self:RebuildQuestIdCache()
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_QUEST_ADDED, function(_, journalIndex, questName)
		self:UpdateJournalQuestCache(journalIndex, questName)
--		self.LDL:Debug("EVENT_QUEST_ADDED :")
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_QUEST_LIST_UPDATED, function()
		self:RebuildJournalQuestCache()
--		self.LDL:Debug("EVENT_QUEST_LIST_UPDATED :")
	end)
end

function CQT_QuestCache_Singleton:RebuildQuestIdCache()
	local name, zId
	ZO_ClearTable(self.questIdCache)
	for i = 1, UPPER_LIMIT_OF_ASSUMED_QUEST_ID do
		name = GetQuestName(i)
		if name ~= "" then
			zId = GetParentZoneId(GetQuestZoneId(i))
			if not self.questIdCache[zId] then
				self.questIdCache[zId] = {}
			end
			if not self.questIdCache[zId][name] then
				self.questIdCache[zId][name] = { i }
			else
				table.insert(self.questIdCache[zId][name], i)
			end
		end
	end
end

function CQT_QuestCache_Singleton:GetNumQuestIdCache()
	local num = 0
	for z, v in pairs(self.questIdCache) do
		for n, ids in pairs(v) do
			if #ids > 1 then
--				self.LDL:Debug("zoneId=%d, num=%d, name=%s", z, #ids, n)
			end
			num = num + 1
		end
	end
--	self.LDL:Debug("numQuests: ", num)
	return num
end

function CQT_QuestCache_Singleton:GetQuestIds(journalIndex)
	local name, zId = self:GetJournalQuestCache(journalIndex)
	local pzId = GetParentZoneId(zId)
	return self.questIdCache[pzId] and self.questIdCache[pzId][name] or { 0 }
end

function CQT_QuestCache_Singleton:GetQuestId(journalIndex)
	local t = self:GetQuestIds(journalIndex)
	return t and t[1] or 0
end

function CQT_QuestCache_Singleton:HasCompletedQuest(journalIndex)
	local hasCompleted = false
	for _, qId in pairs(self:GetQuestIds(journalIndex)) do
		hasCompleted = hasCompleted or HasCompletedQuest(qId)
	end
	return hasCompleted
end

function CQT_QuestCache_Singleton:RebuildJournalQuestCache()
	ZO_ClearNumericallyIndexedTable(self.journalQuestCache)
	for i = 1, MAX_JOURNAL_QUESTS do
		local name = GetJournalQuestName(i)
		local _, _, z = GetJournalQuestLocationInfo(i)
		table.insert(self.journalQuestCache, {
			index = i, 
			name = name, 
			zoneId = GetZoneId(z), 
		})
	end
end

function CQT_QuestCache_Singleton:UpdateJournalQuestCache(journalIndex, name)
	local _, _, z = GetJournalQuestLocationInfo(journalIndex)
	self.journalQuestCache[journalIndex].index = journalIndex
	self.journalQuestCache[journalIndex].name = name
	self.journalQuestCache[journalIndex].zoneId = GetZoneId(z)
end

function CQT_QuestCache_Singleton:GetJournalQuestCache(journalIndex)
	return self.journalQuestCache[journalIndex].name, self.journalQuestCache[journalIndex].zoneId
end

local CQT_QuestCacheManager = CQT_QuestCache_Singleton:New()	-- Never do this more than once!

-- global API --
local GetQuestCacheManager = function() return CQT_QuestCacheManager end
local GetQuestId = function(journalIndex) return CQT_QuestCacheManager:GetQuestId(journalIndex) end
local HasCompletedQuestByIndex = function(journalIndex) return CQT_QuestCacheManager:HasCompletedQuest(journalIndex) end


-- ---------------------------------------------------------------------------------------
-- Quest Timer Manager Class
-- ---------------------------------------------------------------------------------------
local CQT_QuestTimer_Singleton = ZO_InitializingObject:Subclass()
function CQT_QuestTimer_Singleton:Initialize(template, attrib)
	self.name = "CQT-QuestTimerSingleton"
	self.template = template or "CQT_QuestTimerTemplate"
	self.attrib = {
		timerFont = "$(BOLD_FONT)|$(KB_18)|soft-shadow-thick", 
		timerColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL) }, 
		timerIcon = "Esoui/Art/Miscellaneous/timer_64.dds", 
	}
	self.overriddenAttrib = attrib or {}
	self.timers = {}
	self.control = WINDOW_MANAGER:CreateControl("CQT_UI_QuestTimerRoot", GuiRoot, CT_CONTROL)
	self.timerPool = ZO_ControlPool:New(self.template, self.control)
	self.timerPool:SetCustomFactoryBehavior(function(control)
		control.time = control:GetNamedChild("Time")
		control.icon = control:GetNamedChild("Icon")
		control:SetHandler("OnUpdate", function(control, time)
			self:UpdateTimer(control, time)
		end)
	end)
	self.timerPool:SetCustomAcquireBehavior(function(control, key)
		control.time:SetFont(self:GetAttribute("timerFont"))
		control.time:SetColor(unpack(self:GetAttribute("timerColor")))
		local icon = self:GetAttribute("timerIcon")
		control.icon:SetTexture(icon)
		if icon ~= "" then
			local iconSize = control.time:GetFontHeight()
			control.icon:SetDimensions(iconSize, iconSize)
		else
			control.icon:SetDimensions(0, 0)
		end
	end)
	self.timerPool:SetCustomResetBehavior(function(control)
		control:SetParent(self.control)
		control:ClearAnchors()
		control.time:SetText("")
		control.time:SetHidden(false)
	end)
	self.control:RegisterForEvent(EVENT_QUEST_TIMER_UPDATED, function(event, journalIndex)
		local timerStart, timerEnd, isVisible, isPaused = GetJournalQuestTimerInfo(journalIndex)
		if isVisible then
			self:CreateTimer(journalIndex)
		else
			self:RemoveTimer(journalIndex)
		end
	end)
	self.control:RegisterForEvent(EVENT_QUEST_TIMER_PAUSED, function(event, journalIndex, isPaused)
		if self.timers[journalIndex] then
			local timerStart, timerEnd, isVisible, isPaused = GetJournalQuestTimerInfo(journalIndex)
			self.timers[journalIndex].isPaused = isPaused
			if not isPaused then
				self.timers[journalIndex].timerStart = timerStart
				self.timers[journalIndex].timerEnd = timerEnd
			end
		end
	end)
	self.control:RegisterForEvent(EVENT_QUEST_REMOVED, function(event, _, journalIndex)
		self:RemoveTimer(journalIndex)
	end)

	for i = 1, MAX_JOURNAL_QUESTS do
		if IsValidQuestIndex(i) then
			self:CreateTimer(i)
		end
	end	
end

function CQT_QuestTimer_Singleton:GetAttribute(key)
	if self.overriddenAttrib[key] ~= nil then
		return self.overriddenAttrib[key]
	else
		return self.attrib[key]
	end
end

function CQT_QuestTimer_Singleton:SetAttribute(key, value)
	if self.overriddenAttrib[key] ~= nil then
		self.overriddenAttrib[key] = value
	else
		self.attrib[key] = value
	end
end

function CQT_QuestTimer_Singleton:AcquireTimer(journalIndex)
	if self.timers[journalIndex] then
		return self.timers[journalIndex]
	end
	local timer, key = self.timerPool:AcquireObject()
	timer.key = key
	timer:SetHidden(false)
	self.timers[journalIndex] = timer
	return timer
end

function CQT_QuestTimer_Singleton:RemoveTimer(journalIndex)
	if self.timers[journalIndex] then
		self.timerPool:ReleaseObject(self.timers[journalIndex].key)
		self.timers[journalIndex] = nil
	end
end

function CQT_QuestTimer_Singleton:UpdateTimer(timer, now)
	if not timer.isPaused and timer.nextUpdate <= now then
		local remainingTime = timer.timerEnd - now
		if remainingTime > 0 then
			local timeText, nextUpdateDelta = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
			timer.time:SetText(timeText)
			timer.nextUpdate = now + nextUpdateDelta
		else
			self:RemoveTimer(timer.journalIndex)
		end
	end
end

function CQT_QuestTimer_Singleton:CreateTimer(journalIndex)
	local timerStart, timerEnd, isVisible, isPaused = GetJournalQuestTimerInfo(journalIndex)
	if isVisible then
		local timer = self:AcquireTimer(journalIndex)
		timer.journalIndex = journalIndex
		timer.timerStart = timerStart
		timer.timerEnd = timerEnd
		timer.isVisible = isVisible
		timer.isPaused = isPaused

		local now =  GetFrameTimeSeconds()
		timer.nextUpdate = now

		self:UpdateTimer(timer, now)
	end
end

function CQT_QuestTimer_Singleton:GetTimerAPI(journalIndex)
	return self.timers[journalIndex]
end

function CQT_QuestTimer_Singleton:SetUserAttributeTableAPI(overriddenAttrib)
	if type(overriddenAttrib) == "table" then
		self.overriddenAttrib = overriddenAttrib
	end
end

function CQT_QuestTimer_Singleton:DiscardAllTimerLayoutsAPI()
	for _, timer in pairs(self.timers) do
		timer:SetParent(self.control)
		timer:ClearAnchors()
	end
end

local CQT_QuestTimerManager = {
	internal = CQT_QuestTimer_Singleton:New(), 	-- Never do this more than once!
	api = {}, 
}
--
-- ---- CQT_QuestTimerManager API ----
--
-- * GetQuestTimerManager():GetTimer(*luaindex* _journalQuestIndex_)
-- ** _Returns:_ *object:nilable* _questTimerControl_
 -- It is necessary to tie it to a container with SetParent() and lay it out with SetAnchor(), to display the acquired timer control.
CQT_QuestTimerManager.api.GetTimer = function(self, journalIndex)
	return CQT_QuestTimerManager.internal:GetTimerAPI(journalIndex)
end

-- * GetQuestTimerManager():SetUserAttributeTable(*table* _overriddenAttrib_)
-- Specify if you want to use a user-defined attribute table
CQT_QuestTimerManager.api.SetUserAttributeTable = function(self, overriddenAttrib)
	return CQT_QuestTimerManager.internal:SetUserAttributeTableAPI(overriddenAttrib)
end

-- * GetQuestTimerManager():DiscardAllTimerLayouts()
-- Utility function to release all laid out timer controls at once
CQT_QuestTimerManager.api.DiscardAllTimerLayouts = function(self)
	return CQT_QuestTimerManager.internal:DiscardAllTimerLayoutsAPI()
end
-- global API --
local GetQuestTimerManager = function() return CQT_QuestTimerManager.api end


-- ---------------------------------------------------------------------------------------
-- Template
-- ---------------------------------------------------------------------------------------
-- NOTE : This function is based on ZO_Tooltip_AddDivider by ZOS, with its own size adjustments for the UI design of the CQuestTracker add-on.
local function CQT_QuestTooltip_AddDivider(tooltip)
	if not tooltip.dividerPool then
		tooltip.dividerPool = ZO_ControlPool:New("CQT_QuestTooltipDivider", tooltip, "Divider")
		tooltip.dividerPool:SetCustomResetBehavior(function(divider)
			-- It is not necessary to reset the texture, but we still have a failsafe in case the texture is changed.
			divider:SetTexture("EsoUI/Art/Miscellaneous/horizontalDivider.dds")
		end)
	end

	local divider = tooltip.dividerPool:AcquireObject()
	if divider then
		tooltip:AddControl(divider)
		divider:SetAnchor(CENTER)
	end
end


-- ---------------------------------------------------------------------------------------
-- Tracker Panel Class
-- ---------------------------------------------------------------------------------------
local CQT_TrackerPanel = ZO_Object:Subclass()

function CQT_TrackerPanel:New(...)
	local trackerPanel = ZO_Object.New(self)
	trackerPanel:Initialize(...)
	return trackerPanel
end

function CQT_TrackerPanel:Initialize(control, attrib)
	self.attrib = {
		compactMode = false, 
		clampedToScreen = false, 
		offsetX = 400, 
		offsetY = 300, 
		width = 400, 
		height = 600, 
		defaultIndent = 30, 
		defaultSpacing = 0, 
		headerFont = "$(BOLD_FONT)|$(KB_18)|soft-shadow-thick", 
		headerColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL) }, 
		headerColorSelected = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED) }, 
		headerChildIndent = 30, 
		headerChildSpacing = 0, 
		conditionFont = "$(BOLD_FONT)|$(KB_15)|soft-shadow-thick", 
		conditionColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED) }, 
		conditionChildIndent = 0, 
		conditionChildSpacing = 0, 
		showOptionalStep = true, 
		showHintStep = true, 
		hintFont = "$(BOLD_FONT)|$(KB_15)|soft-shadow-thick", 
		hintColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED) }, 
		titlebarColor = { 0.4, 0.6666667, 1, 0.7 }, 
		bgColor = { ZO_ColorDef:New(0, 0, 0, 0):UnpackRGBA() }, 
	}
	self.overriddenAttrib = attrib or {}
	self.panelControl = control
	self.fragment = ZO_HUDFadeSceneFragment:New(control)
	self.panelBg = self.panelControl:GetNamedChild("Bg")
	self.container = control:GetNamedChild("ContainerScrollChild")
	self.journalIndexToTreeNode = {}
	self.questTimer = GetQuestTimerManager()
	control:SetHandler("OnMouseEnter", function(control)
		if MouseIsInside(self.titlebar) and not self.titlebar:IsHidden() then
			self:ShowPanelFrame()
		end
	end)
	control:SetHandler("OnMoveStart", function(control)
		self:ShowPanelFrame(1)
	end)
	control:SetHandler("OnMoveStop", function(control)
		local x, y = control:GetScreenRect()
		self:SetAttribute("offsetX", x)
		self:SetAttribute("offsetY", y)
		self:ResetAnchorPosition()
	end)
	control:SetHandler("OnResizeStart", function(control)
		self:ShowPanelFrame(1)
	end)
	control:SetHandler("OnResizeStop", function(control)
		local x, y = control:GetScreenRect()
		local width, height = control:GetDimensions()
		self:SetAttribute("offsetX", x)
		self:SetAttribute("offsetY", y)
		self:SetAttribute("width", width)
		self:SetAttribute("height", height)
		self:ResetAnchorPosition()
		self:RefreshTree()
	end)
	self.titlebar = control:GetNamedChild("TitleBar")
	self.titlebarFragment = ZO_SimpleSceneFragment:New(self.titlebar)
	self.titlebarFragment:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_HIDING then
			self:HidePanelFrame()
		end
	end)
	self:SetupPanelVisual()
	self:HidePanelFrame()
	self:InitializeTree()
	self:ResetAnchorPosition()
	CALLBACK_MANAGER:RegisterCallback("CQT-TrackerPanelVisualUpdated", function(key)
		self:SetupPanelVisual()
		self:RefreshTree()
	end)
	CALLBACK_MANAGER:RegisterCallback("CQT-QuestListUpdated", function(questList)
		self.questList = questList
		self:RefreshTree()
	end)
	FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerAssistStateChanged", function(unassistedData, assistedData)
		if assistedData and assistedData.arg1 then
			self:RefreshTree()
		end
	end)
end

function CQT_TrackerPanel:RegisterTitleBarButton(controlName, onClickedCallback, tooltipText)
	if self.titlebar then
		local button = self.titlebar:GetNamedChild(controlName)
		if button then
			if type(onClickedCallback) == "function" then
				button.OnMouseClicked = onClickedCallback
			end
			if type(tooltipText) == "string" and tooltipText ~= "" then
				button.tooltipText = tooltipText
			end
		end
	end
end

function CQT_TrackerPanel:SetupPanelVisual()
	local titlebarColor = self:GetAttribute("titlebarColor")
	if self.titlebar.bg then
		self.titlebar.bg:SetColor(unpack(titlebarColor))
	end
	if self.titlebar.text then
		local r, g, b = self.titlebar.text:GetColor()
		self.titlebar.text:SetColor(r, g, b, titlebarColor[4])
	end
	if self.panelBg then
		self.panelBg:SetCenterColor(unpack(self:GetAttribute("bgColor")))
	end
	self.panelControl:SetClampedToScreen(self:GetAttribute("clampedToScreen"))
end

function CQT_TrackerPanel:ShowPanelFrame(desiredAlpha)
	if self.panelBg then
		local r, g, b, a = unpack(self:GetAttribute("titlebarColor"))
		self.panelBg:SetEdgeColor(r, g, b, desiredAlpha or a)
	end
end

function CQT_TrackerPanel:HidePanelFrame()
	if self.panelBg then
		local r, g, b = unpack(self:GetAttribute("titlebarColor"))
		self.panelBg:SetEdgeColor(r, g, b, 0)
	end
end

function CQT_TrackerPanel:GetControl()
	return self.panelControl
end

function CQT_TrackerPanel:GetFragment()
	return self.fragment
end

function CQT_TrackerPanel:GetTitleBarFragment()
	return self.titlebarFragment
end

function CQT_TrackerPanel:GetAttribute(key)
	if self.overriddenAttrib[key] ~= nil then
		return self.overriddenAttrib[key]
	else
		return self.attrib[key]
	end
end

function CQT_TrackerPanel:SetAttribute(key, value)
	if self.overriddenAttrib[key] ~= nil then
		self.overriddenAttrib[key] = value
	else
		self.attrib[key] = value
	end
end

function CQT_TrackerPanel:SetAttributes(attributeTable)
	if type(attributeTable) ~= "table" then return end
	for k, v in pairs(attributeTable) do
		self:SetAttribute(k, v)
	end
end

function CQT_TrackerPanel:ClearAllTreeNodeOpenStatus()
	ZO_ClearTable(self.trackerTree.treeNodeOpenStatus)
end

function CQT_TrackerPanel:SetTreeNodeOpenStatus(questId, userRequestedOpen)
	self.trackerTree.treeNodeOpenStatus[questId] = userRequestedOpen
end

function CQT_TrackerPanel:ResetAnchorPosition()
	self.panelControl:ClearAnchors()
	self.panelControl:SetAnchor(TOPLEFT, guiRoot, TOPLEFT, self:GetAttribute("offsetX"), self:GetAttribute("offsetY"))
	self.panelControl:SetDimensions(self:GetAttribute("width"), self:GetAttribute("height"))
	self.container:SetWidth(self.container:GetParent():GetWidth())
	self.trackerTree.width = self.container:GetWidth()
end

function CQT_TrackerPanel:InitializeTree()
	self.trackerTree = ZO_Tree:New(self.container, self:GetAttribute("defaultIndent"), self:GetAttribute("defaultSpacing"), self.container:GetParent():GetWidth())
	local function HeaderNodeLabelMaxWidth(control)
		local isValid, _, _, _, textOffsetX, _ = control.text:GetAnchor(0)
		return control.node:GetTree():GetWidth() - (isValid and textOffsetX or 0)
	end
	local function HeaderNodeUpdateSize(control)
		local textWidth, textHeight = control.text:GetTextDimensions()
		local isValid, _, _, _, textOffsetX, textOffsetY = control.text:GetAnchor(0)
		control:SetDimensions(control.node:GetTree():GetWidth(), textHeight + (isValid and textOffsetY or 0))
	end
	local function HeaderNodeGetTextColor(label)
		if label and label.selected then
			return unpack(self:GetAttribute("headerColorSelected"))
		else
			return unpack(self:GetAttribute("headerColor"))
		end
	end
	local function HeaderNodeSetup(node, control, data, open, userRequested, enabled)
		local name, _, _, _, _, completed, tracked, _, _, questType, instanceDisplayType = GetJournalQuestInfo(data.journalIndex)
		local timerWidth = data.timer and data.timer:GetWidth() or 0
		control.journalIndex = data.journalIndex
		control.questId = data.questId
		control.text:SetFont(self:GetAttribute("headerFont"))
		control.text.GetTextColor = HeaderNodeGetTextColor
		control.text:RefreshTextColor()
		control.text:SetDimensionConstraints(0, 0, HeaderNodeLabelMaxWidth(control) - timerWidth, 0)
		control.text:SetText(name)
--		control.icon:SetTexture("/esoui/art/icons/heraldrycrests_misc_blank_01.dds")	-- black icon
		control.icon:SetTexture("EsoUI/Art/Journal/journal_Quest_Selected.dds")
		control.icon:SetHidden(not tracked)
		control.iconHighlight:SetTexture("EsoUI/Art/Journal/journal_Quest_Selected.dds")
        control.iconHighlight:SetHidden(not tracked)
		control.status:SetTexture("EsoUI/Art/Quest/conditioncomplete.dds")
		control.status:SetColor(0, 1, 0, 1)
		control.status:SetHidden(not completed)
		if data.timestamp[3] then
			control.pinned:SetTexture("EsoUI/Art/Miscellaneous/locked_up.dds")
			control.pinned:SetHidden(false)
		else
			control.pinned:SetHidden(true)
		end
		if data.timer then
			local _, headerTextCenterY = control.text:GetCenter()
			data.timer.time:SetFont(self:GetAttribute("headerFont"))
			data.timer.time:SetColor(unpack(self:GetAttribute("headerColor")))
			data.timer:ClearAnchors()
			data.timer:SetParent(control)
			data.timer:SetAnchor(RIGHT, control, TOPRIGHT, 0, headerTextCenterY - control:GetTop())
		end
		ZO_IconHeader_Setup(control, tracked, enabled, true, HeaderNodeUpdateSize)
	end
	local function HeaderNodeEquality(left, right)
		return left.questId == right.questId
	end
	self.trackerTree:AddTemplate("CQT_QuestHeader", HeaderNodeSetup, nil, HeaderNodeEquality, self:GetAttribute("headerChildIndent"), self:GetAttribute("headerChildSpacing"))

	local function EntryNodeUpdateSize(control)
		control:SetDimensions(control.text:GetTextWidth(), control.text:GetTextHeight())
	end
	local function EntryNodeSetup(node, control, data, open, userRequested, enabled)
		if data.visibility == QUEST_STEP_VISIBILITY_HINT then
			control.text:SetFont(self:GetAttribute("hintFont"))
			control.text:SetColor(unpack(self:GetAttribute("hintColor")))
		else
			control.text:SetFont(self:GetAttribute("conditionFont"))
			control.text:SetColor(unpack(self:GetAttribute("conditionColor")))
		end
		control.text:SetText(data.text or "")
		EntryNodeUpdateSize(control)
	end
	self.trackerTree:AddTemplate("CQT_Entry", EntryNodeSetup)

	local function ConditionNodeLabelMaxWidth(control)
		local node = control.node
		local isValid, _, _, _, textOffsetX, _ = control.text:GetAnchor(0)
		return node:GetTree():GetWidth() - node:ComputeTotalIndentFrom(node:GetParent())  - (isValid and textOffsetX or 0)
	end
	local function ConditionNodeUpdateSize(control)
		local textWidth, textHeight = control.text:GetTextDimensions()
		local isValid, _, _, _, textOffsetX, textOffsetY = control.text:GetAnchor(0)
		control:SetDimensions(textWidth + (isValid and textOffsetX or 0), textHeight + (isValid and textOffsetY or 0))
	end
	local function ConditionNodeSetup(node, control, data, open, userRequested, enabled)
		if data.visibility == QUEST_STEP_VISIBILITY_HINT then
			control.text:SetFont(self:GetAttribute("hintFont"))
			control.text:SetColor(unpack(self:GetAttribute("hintColor")))
		else
			control.text:SetFont(self:GetAttribute("conditionFont"))
			control.text:SetColor(unpack(self:GetAttribute("conditionColor")))
		end
		control.text:SetDimensionConstraints(0, 0, ConditionNodeLabelMaxWidth(control), 0)
		control.text:SetText(data.text or "unknown")
		control.status:SetTexture("EsoUI/Art/Miscellaneous/check_icon_32.dds")
		control.status:SetColor(0, 1, 0, 1)
		control.status:SetHidden(not data.isChecked)
		ConditionNodeUpdateSize(control)
	end
	local function ConditionNodeEquality(left, right)
		return left.text == right.text
	end
	self.trackerTree:AddTemplate("CQT_QuestCondition", ConditionNodeSetup, nil, ConditionNodeEquality, self:GetAttribute("conditionChildIndent"), self:GetAttribute("conditionChildSpacing"))
	self.trackerTree:SetExclusive(false)
	self.trackerTree:SetOpenAnimation("ZO_TreeOpenAnimation")
	self.trackerTree.treeNodeOpenStatus = {}
end

function CQT_TrackerPanel:RefreshTree()
	local function ShouldOpenQuestHeader(questInfo)
		local userRequestedOpen = self.trackerTree.treeNodeOpenStatus[questInfo.questId]
		if userRequestedOpen == nil then
			if self:GetAttribute("compactMode") then
				local tracked = select(7, GetJournalQuestInfo(questInfo.journalIndex))
				return tracked or (questInfo.timestamp[3] and questInfo.timestamp[3] > 0)
			else
				return true
			end
		else
			return userRequestedOpen
		end
	end
	local function GetNumVisibleQuestConditions(journalIndex, stepIndex)
		local visibleConditionCount = 0
		for conditionIndex = 1, GetJournalQuestNumConditions(journalIndex, stepIndex) do
			local _, _, _, _, _, isVisible = GetJournalQuestConditionValues(journalIndex, stepIndex, conditionIndex)
			if isVisible then
				visibleConditionCount = visibleConditionCount + 1
			end
		end
		return visibleConditionCount
	end
	local function GetNumVisibleQuestHintSteps(journalIndex)
		local visibleHintCount = 0
		for stepIndex = QUEST_MAIN_STEP_INDEX + 1, GetJournalQuestNumSteps(journalIndex) do
			local _, stepVisibility, stepType = GetJournalQuestStepInfo(journalIndex, stepIndex)
			if stepType ~= QUEST_STEP_TYPE_END and stepVisibility == QUEST_STEP_VISIBILITY_HINT then
				visibleHintCount = visibleHintCount + GetNumVisibleQuestConditions(journalIndex, stepIndex)
			end
		end
		return visibleHintCount
	end
	local function IsOrDescription(journalIndex, stepIndex)
		local _, _, stepType, overrideText = GetJournalQuestStepInfo(journalIndex, stepIndex)
		return (not overrideText or overrideText == "") and stepType == QUEST_STEP_TYPE_OR and GetNumVisibleQuestConditions(journalIndex, stepIndex) > 2
	end
	local function PopulateQuestConditions(journalIndex, stepIndex, tree, parentNode, sound, open)
		local firstNode = nil
		local previousNode = nil
		local _, stepVisibility, stepType, overrideText, conditionCount = GetJournalQuestStepInfo(journalIndex, stepIndex)
		if overrideText and overrideText ~= "" then
			local checked = stepType == QUEST_STEP_TYPE_AND
			if stepType ~= QUEST_STEP_TYPE_END then
				for conditionIndex = 1, conditionCount do
					local _, _, isFailCondition, isComplete = GetJournalQuestConditionValues(journalIndex, stepIndex, conditionIndex)
					if (not isFailCondition) and isComplete then
						if stepType ~= QUEST_STEP_TYPE_AND then
							checked = true
							break
						end
					else
						if stepType == QUEST_STEP_TYPE_AND then
							checked = false
							break
						end
					end
				end
			end
			firstNode = tree:AddNode("CQT_QuestCondition", { text = overrideText, visibility = stepVisibility, isChecked = checked }, parentNode, sound, open)
		else
			for conditionIndex = 1, conditionCount do
				local conditionText, curCount, maxCount, isFailCondition, isComplete, isGroupCreditShared, isVisible, conditionType = GetJournalQuestConditionInfo(journalIndex, stepIndex, conditionIndex)
				if (not isFailCondition) and (conditionText ~= "") and isVisible then
					local taskNode = tree:AddNode("CQT_QuestCondition", { text = conditionText, visibility = stepVisibility, isChecked = isComplete or (curCount == maxCount) }, parentNode, sound, open)
					firstNode = firstNode or taskNode
					if previousNode then
						previousNode.nextNode = taskNode
					end
					previousNode = taskNode
				end
			end
		end
		return firstNode
	end

	local questList = self.questList
	if not questList then return end
	self.journalIndexToTreeNode = {}
	self.trackerTree:Reset()
    self.trackerTree:SetSuspendAnimations(false)
	self.questTimer:DiscardAllTimerLayouts()
	local questNode = {}
	local firstNode = nil
	local previousNode = nil
	for i, questInfo in ipairs(questList) do
		questNode[i] = self.trackerTree:AddNode("CQT_QuestHeader", questInfo, nil, nil, ShouldOpenQuestHeader(questInfo))
		self.journalIndexToTreeNode[questInfo.journalIndex] = questNode[i]
		if IsOrDescription(questInfo.journalIndex, QUEST_MAIN_STEP_INDEX) then
			local subHeaderNode = self.trackerTree:AddNode("CQT_Entry", { text = L(SI_CQT_QUEST_OR_DESCRIPTION) }, questNode[i], nil, true)
		end
		PopulateQuestConditions(questInfo.journalIndex, QUEST_MAIN_STEP_INDEX, self.trackerTree, questNode[i], nil, true)
		if self:GetAttribute("showOptionalStep") then
			for stepIndex = QUEST_MAIN_STEP_INDEX + 1, GetJournalQuestNumSteps(questInfo.journalIndex) do
				local _, stepVisibility, stepType = GetJournalQuestStepInfo(questInfo.journalIndex, stepIndex)
				if stepType ~= QUEST_STEP_TYPE_END and stepVisibility == QUEST_STEP_VISIBILITY_OPTIONAL then
					if IsOrDescription(questInfo.journalIndex, stepIndex) then
						local subHeaderNode = self.trackerTree:AddNode("CQT_Entry", { text = L(SI_CQT_QUEST_OPTIONAL_STEPS_OR_DESCRIPTION) }, questNode[i], nil, true)
					else
						local subHeaderNode = self.trackerTree:AddNode("CQT_Entry", { text = L(SI_CQT_QUEST_OPTIONAL_STEPS_DESCRIPTION) }, questNode[i], nil, true)
					end
					PopulateQuestConditions(questInfo.journalIndex, stepIndex, self.trackerTree, questNode[i], nil, true)
				end
			end
		end
		if self:GetAttribute("showHintStep") then
			local hintSubHeaderDisplayed = false
			local visibleHintCount = GetNumVisibleQuestHintSteps(questInfo.journalIndex)
			if visibleHintCount > 0 then
				for stepIndex = QUEST_MAIN_STEP_INDEX + 1, GetJournalQuestNumSteps(questInfo.journalIndex) do
					local _, stepVisibility, stepType = GetJournalQuestStepInfo(questInfo.journalIndex, stepIndex)
					if stepType ~= QUEST_STEP_TYPE_END and stepVisibility == QUEST_STEP_VISIBILITY_HINT then
						if not hintSubHeaderDisplayed then
							local subHeaderNode = self.trackerTree:AddNode("CQT_Entry", { text = zo_strformat(L(SI_CQT_QUEST_HINT_STEPS_HEADER), visibleHintCount), visibility = stepVisibility }, questNode[i], nil, false)
							hintSubHeaderDisplayed = true
						end
						PopulateQuestConditions(questInfo.journalIndex, stepIndex, self.trackerTree, questNode[i], nil, false)
					end
				end
			end
		end
	end
end


-- ---------------------------------------------------------------------------------------
-- CQuestTracker
-- ---------------------------------------------------------------------------------------

local FONT_TYPE =   1
local FONT_STYLE =  2
local FONT_SIZE =   3
local FONT_WEIGHT = 4
local CQT_SV_DEFAULT = {
	accountWide = true, 
	hideFocusedQuestTracker = false, 
	hideCQuestTracker = false, 
	maxNumDisplay = 5, 
	maxNumPinnedQuest = 5, 
	panelAttributes = {
		compactMode = false, 
		clampedToScreen = false, 
		offsetX = 400, 
		offsetY = 300, 
		width = 400, 
		height = 600, 
		headerFont = "$(BOLD_FONT)|$(KB_18)|soft-shadow-thick", 
		headerColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL) }, 
		headerColorSelected = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED) }, 
		conditionFont = "$(BOLD_FONT)|$(KB_15)|soft-shadow-thick", 
		conditionColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED) }, 
		showHintStep = true, 
		hintFont = "$(BOLD_FONT)|$(KB_15)|soft-shadow-thick", 
		hintColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED) }, 
		titlebarColor = { 0.4, 0.6666667, 1, 0.7 }, 
		bgColor = { ZO_ColorDef:New(0, 0, 0, 0):UnpackRGBA() }, 
	}, 
	qhFont = {
		[FONT_TYPE] = "$(BOLD_FONT)", 
		[FONT_STYLE] = "", 
		[FONT_SIZE] = "$(KB_18)", 
		[FONT_WEIGHT] = "soft-shadow-thick", 
	}, 
	qcFont = {
		[FONT_TYPE] = "$(BOLD_FONT)", 
		[FONT_STYLE] = "", 
		[FONT_SIZE] = "$(KB_15)", 
		[FONT_WEIGHT] = "soft-shadow-thick", 
	}, 
	qkFont = {
		[FONT_TYPE] = "$(BOLD_FONT)", 
		[FONT_STYLE] = "", 
		[FONT_SIZE] = "$(KB_15)", 
		[FONT_WEIGHT] = "soft-shadow-thick", 
	}, 
	panelBehavior = {
		minimizeInHUD = false, 
		showInCombat = true, 
		showInBattleground = false, 
		showInGameMenuScene = true, 
	}, 
	qtooltip = {
		show = true, 
		anchor = LEFT, 
	}, 
	improveKeybinds = true, 
	cycleAllQuests = false, 
	cycleBackwardsMod1 = KEY_SHIFT, 
	cycleBackwardsMod2 = KEY_GAMEPAD_LEFT_TRIGGER, 
	holdToShowQuestTooltip = true, 
	autoTrackToAddedQuest = true, 
	autoTrackToProgressedQuest = false, 
}
function CQT:Initialize()
	self:ConfigDebug()
	CQT.LDL:Debug("EVENT_ADD_ON_LOADED :")
	self.currentApiVersion = GetAPIVersion()
	self.lang = GetCVar("Language.2")
	self.sessionStartTime = { GetTimeStamp(), 0 }
	self.isFirstTimePlayerActivated = true
	self.isSettingPanelInitialized = false
	self.isSettingPanelShown = false
	self.isQuestTooltipShown = false
	self.forceAssistControl = {}

	self.questList = {}
	self.circularJournalIndexList = {}
	self.activityLog = ZO_SavedVars:NewCharacterIdSettings("CQuestTrackerLog", 1, nil, { quest = {}, }, GetWorldName())

	-- CQuestTracker Config
	self.svCurrent = {}
	self.svAccount = ZO_SavedVars:NewAccountWide("CQuestTrackerSV", 1, nil, CQT_SV_DEFAULT, GetWorldName())
	self:ValidateConfigDataSV(self.svAccount)
	if self.svAccount.accountWide then
		self.svCurrent = self.svAccount
	else
		self.svCharacter = ZO_SavedVars:NewCharacterIdSettings("CQuestTrackerSV", 1, nil, CQT_SV_DEFAULT, GetWorldName())
		self:ValidateConfigDataSV(self.svCharacter)
		self.svCurrent = self.svCharacter
	end

	-- quest timer
	self.questTimer = GetQuestTimerManager()

	-- tracker panel
	self.trackerPanel = CQT_TrackerPanel:New(CQT_UI_TrackerPanel, self.svCurrent.panelAttributes)
	self.trackerPanel:RegisterTitleBarButton("SettingBtn", CQT_SettingButton_OnClicked, L(SI_CQT_TITLEBAR_OPEN_SETTINGS_BUTTON_TIPS))
	self.trackerPanel:RegisterTitleBarButton("QuestListBtn", CQT_QuestListButton_OnClicked, L(SI_CQT_TITLEBAR_QUEST_LIST_BUTTON_TIPS))
	HUD_SCENE:AddFragment(self.trackerPanel:GetFragment())
	HUD_UI_SCENE:AddFragment(self.trackerPanel:GetFragment())
	HUD_UI_SCENE:AddFragment(self.trackerPanel:GetTitleBarFragment())
	if self.svCurrent.panelBehavior.showInGameMenuScene then
		self:AddTrackerPanelFragmentToGameMenuScene()
	end
	self.trackerPanel:GetTitleBarFragment():RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_HIDING then
			if self:IsQuestTooltipShown() then
				self:HideQuestTooltip()
			end
		end
	end)
	KEYBINDINGS_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWING or newState == SCENE_FRAGMENT_HIDING then
			self:UpdateTrackerPanelVisibility()
		end
	end)

	-- focused quest management
	self:InitializeFocusedQuestControlTable()

	-- tutorial
	ZO_Dialogs_RegisterCustomDialog(self.name .. "_WELCOME_MESSAGE", {
		canQueue = true, 
		title = {
			text = "Calamath's Quest Tracker", 
		}, 
		mainText = {
			text = function(dialog)
				return ZO_GenerateParagraphSeparatedList({ L(SI_CQT_WELCOME_TEXT1), L(SI_CQT_WELCOME_TEXT2), L(SI_CQT_WELCOME_TEXT3), L(SI_CQT_WELCOME_TEXT4), })
			end, 
		}, 
		buttons = {
			{
				text = SI_DIALOG_CLOSE, 
			}, 
		},
	})

	self:RegisterEvents()

	-- keybinds and interactions
	self:InitializeKeybinds()
	self:RegisterInteractions()
	self.trackerPanel:GetFragment():RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWING then
			if self.svCurrent.improveKeybinds then
				PushActionLayerByName("CQT_InteractionSnatcher")
			end
		elseif newState == SCENE_FRAGMENT_HIDING then
			RemoveActionLayerByName("CQT_InteractionSnatcher")
		end
	end)

	self.isInitialized = true
	self.LDL:Debug("Initialized: ", self.lang)
end

function CQT:ConfigDebug(arg)
	local debugMode = false
	local key = HashString(GetDisplayName())
	local dummy = function() end
	if LibDebugLogger then
		for _, v in pairs(arg or self.authority or {}) do
			if key == v then debugMode = true end
		end
	end
	if debugMode then
		self.LDL = LibDebugLogger(self.name)
	else
		self.LDL = { Verbose = dummy, Debug = dummy, Info = dummy, Warn = dummy, Error = dummy, }
	end
end

function CQT:ValidateConfigDataSV(sv)
	if sv.panelAttributes.compactMode == nil					then sv.panelAttributes.compactMode						= CQT_SV_DEFAULT.panelAttributes.compactMode								end
	if sv.panelAttributes.clampedToScreen == nil				then sv.panelAttributes.clampedToScreen					= CQT_SV_DEFAULT.panelAttributes.clampedToScreen							end
	if sv.panelAttributes.headerColorSelected == nil			then sv.panelAttributes.headerColorSelected				= ZO_ShallowTableCopy(CQT_SV_DEFAULT.panelAttributes.headerColorSelected)	end
	if sv.panelAttributes.hintFont == nil						then sv.panelAttributes.hintFont						= sv.panelAttributes.conditionFont											end		-- Derived from conditionFont and added
	if sv.panelAttributes.hintColor == nil						then sv.panelAttributes.hintColor						= ZO_ShallowTableCopy(CQT_SV_DEFAULT.panelAttributes.hintColor)				end
	if sv.panelAttributes.titlebarColor == nil					then sv.panelAttributes.titlebarColor					= ZO_ShallowTableCopy(CQT_SV_DEFAULT.panelAttributes.titlebarColor)			end
	if sv.qkFont == nil											then sv.qkFont											= ZO_ShallowTableCopy(sv.qcFont)											end		-- Derived from qcFont and added
	if sv.improveKeybinds == nil								then sv.improveKeybinds									= CQT_SV_DEFAULT.improveKeybinds											end
	if sv.cycleAllQuests == nil									then sv.cycleAllQuests									= CQT_SV_DEFAULT.cycleAllQuests												end
	if sv.cycleBackwardsMod1 == nil								then sv.cycleBackwardsMod1								= CQT_SV_DEFAULT.cycleBackwardsMod1											end
	if sv.cycleBackwardsMod2 == nil								then sv.cycleBackwardsMod2								= CQT_SV_DEFAULT.cycleBackwardsMod2											end
	if sv.holdToShowQuestTooltip == nil							then sv.holdToShowQuestTooltip							= CQT_SV_DEFAULT.holdToShowQuestTooltip										end
	if sv.autoTrackToAddedQuest == nil							then sv.autoTrackToAddedQuest							= CQT_SV_DEFAULT.autoTrackToAddedQuest										end
	if sv.autoTrackToProgressedQuest == nil						then sv.autoTrackToProgressedQuest						= CQT_SV_DEFAULT.autoTrackToProgressedQuest									end
end

function CQT:RegisterEvents()
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, function(event, initial)
		self.LDL:Debug("EVENT_PLAYER_ACTIVATED : initial =", initial, ", isFirstTime =", self.isFirstTimePlayerActivated)
		if self.isFirstTimePlayerActivated then
			self.isFirstTimePlayerActivated = false
			self:CreateSettingPanel()
			SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_TRACKER, self.svCurrent.hideFocusedQuestTracker and "false" or "true")	-- Override default quest tracker visibility with our save data settings.
			if ZO_FocusedQuestTrackerPanelTimerAnchor and ZO_FocusedQuestTrackerPanelTimerAnchor.SetHidden then
				ZO_FocusedQuestTrackerPanelTimerAnchor:SetHidden(self.svCurrent.hideFocusedQuestTracker)	-- Override default quest timer panel visibility with our save data settings.
			end
			if initial then	-- --------------------------------- after login
				-- Check if this is the first login for this character after using this addon.
				if not self.activityLog.apiVersion then
					self.activityLog.apiVersion = self.currentApiVersion
					self:ShowWelcomeMessageDialog()
				end
				-- Check if this is the first login after api version update since using this addon.
				if self.activityLog.apiVersion < self.currentApiVersion then
					self.LDL:Debug("detected api version up")
				end
			else	-- ----------------------------------------- after reloadui
				self:RefreshQuestList()
			end
		else
--			if initial then		-- ----------------------------- after fast travel
--			end
		end
		self:UpdateTrackerPanelVisibility()
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_DEACTIVATED, function(event)
		self.activityLog.apiVersion = self.currentApiVersion
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INTERFACE_SETTING_CHANGED, function(event, settingSystemType, settingId)
		if settingSystemType == SETTING_TYPE_UI and settingId == UI_SETTING_SHOW_QUEST_TRACKER then
			local hideDefaultQuestTracker = not GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_TRACKER)
			self.svCurrent.hideFocusedQuestTracker = hideDefaultQuestTracker
			if ZO_FocusedQuestTrackerPanelTimerAnchor and ZO_FocusedQuestTrackerPanelTimerAnchor.SetHidden then
				ZO_FocusedQuestTrackerPanelTimerAnchor:SetHidden(hideDefaultQuestTracker)
			end
		end
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, function(event, inCombat)
		if not self.svCurrent.panelBehavior.showInCombat then
			self:UpdateTrackerPanelVisibility()
		end
	end)
	if FOCUSED_QUEST_TRACKER and FOCUSED_QUEST_TRACKER.OnQuestAdded then
		-- The default quest tracker unconditionally changes the focused quest when accepting a quest, but the add-on takes over its control by CQT:UpdateFocusedQuestByEvent.
		-- Returning true in the Hook function means blocking the execution of the original FOCUSED_QUEST_TRACKER:OnQuestAdd function.
		ZO_PreHook(FOCUSED_QUEST_TRACKER, "OnQuestAdded", function(self, questIndex) return true end)
	end
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_QUEST_ADDED, function(event, journalIndex, questName, objectiveName)
		self:UpdateTimeStampByIndex(journalIndex)
		self:UpdateFocusedQuestByEvent(event, journalIndex)
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_QUEST_ADVANCED, function(event, journalIndex, questName, isPushed, isComplete, mainStepChanged)
		self:UpdateTimeStampByIndex(journalIndex)
		self:UpdateFocusedQuestByEvent(event, journalIndex)
		self:RefreshQuestList()
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(event, journalIndex, questName, conditionText, conditionType, currConditionVal, newConditionVal, conditionMax, isFailCondition, stepOverrideText, isPushed, isComplete, isConditionComplete, isStepHidden, isConditionCompleteStatusChanged, isConditionCompletableBySiblingStatusChanged)
		self:UpdateTimeStampByIndex(journalIndex)
		self:UpdateFocusedQuestByEvent(event, journalIndex)
		self:RefreshQuestList()
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_QUEST_CONDITION_OVERRIDE_TEXT_CHANGED, function(event, journalIndex)
		self:UpdateTimeStampByIndex(journalIndex)
		self:UpdateFocusedQuestByEvent(event, journalIndex)
		self:RefreshQuestList()
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_QUEST_LIST_UPDATED, function(event)
		self:ValidateActivityLog()
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_QUEST_OPTIONAL_STEP_ADVANCED, function(event, text)
		self:RefreshQuestList()
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_QUEST_REMOVED, function(event, isCompleted, journalIndex, questName, zoneIndex, poiIndex, questId)
		self:DeleteTimeStampByIndex(journalIndex)
	end)
	local function QJM_OnQuestsListUpdatedBehindSchedule()
		self:RefreshQuestList()
	end
	QUEST_JOURNAL_MANAGER:RegisterCallback("QuestListUpdated", function()
		zo_callLater(QJM_OnQuestsListUpdatedBehindSchedule, 100)	-- delay 100ms
	end)
end

function CQT:RegisterInteractions()
	self.interactions = self.interactions or {}
	self.interactions["CQT_TOGGLE_TRACKED_QUEST"] = LibCInteraction:RegisterInteraction("CQT_TOGGLE_TRACKED_QUEST", {
		type = "hold", 
		enabled = function()
			return self.trackerPanel:GetFragment():IsShowing()
		end, 
		holdTime = 300, 
		endedCallback = function()
			if self:IsQuestTooltipShown() then
				self:HideQuestTooltip()
			end
		end, 
		performedCallback = function()
			if self.svCurrent.holdToShowQuestTooltip then
				local focusedQuestIndex = QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex()
				if self:IsQuestTooltipShown() then
					self:HideQuestTooltip()
				end
				if focusedQuestIndex then
					InitializeTooltip(CQT_QuestTooltip, GuiRoot, CENTER, 0, 0, CENTER)
					self:LayoutQuestTooltip(CQT_QuestTooltip, focusedQuestIndex)
					self.isQuestTooltipShown = true
				end
			end
		end, 
		canceledCallback = function(interaction)
			local isModifierKeyDown = interaction:IsModifierKeyDown(self.svCurrent.cycleBackwardsMod1) or interaction:IsModifierKeyDown(self.svCurrent.cycleBackwardsMod2)
			if self.svCurrent.cycleAllQuests then
				if isModifierKeyDown then
					self:AssistPrevious()
				else
					FOCUSED_QUEST_TRACKER:AssistNext()
				end
			else
				if isModifierKeyDown then
					self:ToggleFocusedQuestToPreviousInTheDisplayed()
				else
					self:ToggleFocusedQuestToNextInTheDisplayed()
				end
			end
		end, 
	})
end

function CQT:CopyKeybinds(sourceActionName, destActionName)
	local layer, category, action = GetActionIndicesFromName(destActionName)
	if layer and category and action then
		if IsProtectedFunction("UnbindAllKeysFromAction") then
			CallSecureProtected("UnbindAllKeysFromAction", layer, category, action)
		else
			UnbindAllKeysFromAction(layer, category, action)
		end
	else
		return
	end
	layer, category, action = GetActionIndicesFromName(sourceActionName)
	if layer and category and action then
		for i = 1, GetMaxBindingsPerAction() do
			local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layer, category, action, i)
			CreateDefaultActionBind(destActionName, key, mod1, mod2, mod3, mod4)
		end
	else
		return
	end
	if self.keybinds then
		self.keybinds[sourceActionName] = destActionName
	end
	return true
end

function CQT:InitializeKeybinds()
	self.keybinds = self.keybinds or {}
	self:CopyKeybinds("ASSIST_NEXT_TRACKED_QUEST", "CQT_TOGGLE_TRACKED_QUEST")
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_KEYBINDING_CLEARED, function(event, layerIndex, categoryIndex, actionIndex, bindingIndex)
		local actionName = GetActionInfo(layerIndex, categoryIndex, actionIndex)
		if self.keybinds[actionName] then
			self:CopyKeybinds(actionName, self.keybinds[actionName])	-- Rebuild due to setting changes
		end
	end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_KEYBINDING_SET, function(event, layerIndex, categoryIndex, actionIndex, bindingIndex)
		local actionName = GetActionInfo(layerIndex, categoryIndex, actionIndex)
		if self.keybinds[actionName] then
			self:CopyKeybinds(actionName, self.keybinds[actionName])	-- Rebuild due to setting changes
		end
	end)
end


function CQT:InitializeFocusedQuestControlTable()
	ZO_ClearTable(self.forceAssistControl)
	if FOCUSED_QUEST_TRACKER and FOCUSED_QUEST_TRACKER.ForceAssist then
		if EVENT_QUEST_ADDED then
			self.forceAssistControl[EVENT_QUEST_ADDED] = self.svCurrent.autoTrackToAddedQuest
		end
		if EVENT_QUEST_ADVANCED then
			self.forceAssistControl[EVENT_QUEST_ADVANCED] = self.svCurrent.autoTrackToProgressedQuest
		end
		if EVENT_QUEST_CONDITION_COUNTER_CHANGED then
			self.forceAssistControl[EVENT_QUEST_CONDITION_COUNTER_CHANGED] = self.svCurrent.autoTrackToProgressedQuest
		end
	end
end

function CQT:UpdateFocusedQuestByEvent(event, journalIndex)
	if self.forceAssistControl[event] then
		FOCUSED_QUEST_TRACKER:ForceAssist(journalIndex)
		if FOCUSED_QUEST_TRACKER.UpdateAssistedVisibility then
			FOCUSED_QUEST_TRACKER:UpdateAssistedVisibility()
		end
	end
end

function CQT:ToggleFocusedQuestToNextInTheDisplayed()
-- Toggle focused quest to the next quest in the displayed.
	if #self.questList == 0 then return end
	local nextJournalIndex
	local focusedQuestIndex = QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex()
	if self.circularJournalIndexList[focusedQuestIndex] then
		nextJournalIndex = self.circularJournalIndexList[focusedQuestIndex].nextJournalIndex
	else
		nextJournalIndex = self.questList[1].journalIndex
	end
	FOCUSED_QUEST_TRACKER:ForceAssist(nextJournalIndex)
end

function CQT:ToggleFocusedQuestToPreviousInTheDisplayed()
	if #self.questList == 0 then return end
	local previousJournalIndex
	local focusedQuestIndex = QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex()
	if self.circularJournalIndexList[focusedQuestIndex] then
		previousJournalIndex = self.circularJournalIndexList[focusedQuestIndex].prevJournalIndex
	else
		previousJournalIndex = self.questList[1].journalIndex
	end
	FOCUSED_QUEST_TRACKER:ForceAssist(previousJournalIndex)
end

function CQT:AssistPrevious()
-- Toggle focused quest to the previous in the QJM sorted quest list. oppositte of the FOCUSED_QUEST_TRACKER:AssistNext().
	local questList = QUEST_JOURNAL_MANAGER:GetQuestList()
	local numQuestList = #questList
	if numQuestList == 0 then return end
	local focusedQuestIndex = QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex()
	local previousQuest
	for i, quest in ipairs(questList) do
		if quest.questIndex == focusedQuestIndex then
			previousQuest = (i == 1) and numQuestList or (i - 1)
			break
		end
	end
	FOCUSED_QUEST_TRACKER:ForceAssist(questList[previousQuest].questIndex)
end

function CQT:RefreshQuestList()
	local quests = QUEST_JOURNAL_MANAGER:GetQuestList()
	local pinnedQuestList = {}
	local unpinnedQuestList = {}
	local numEntry = 0
	ZO_ClearNumericallyIndexedTable(self.questList)
	for k, v in pairs(quests) do
		local questId = GetQuestId(v.questIndex)
		local t = {
			journalIndex = v.questIndex, 
			qjmQuestIndex = k, 
			questId = questId, 
			timestamp = self:GetTimeStamp(questId) or self.sessionStartTime, 
			timer = self.questTimer:GetTimer(v.questIndex)
		}
		if not self:IsIgnoredQuest(questId) and not self:IsUnrecordedQuest(questId) then
			if self:IsPinnedQuest(questId) then
				table.insert(pinnedQuestList, t)
			else
				table.insert(unpinnedQuestList, t)
			end
		end
	end
	
	table.sort(pinnedQuestList, function(a, b)
		if a.timestamp[3] ~= b.timestamp[3] then
			return a.timestamp[3] < b.timestamp[3]
		else	
			return a.questId < b.questId
		end
	end)
	table.sort(unpinnedQuestList, function(a, b)
		if a.timestamp[1] ~= b.timestamp[1] then
			return a.timestamp[1] > b.timestamp[1]
		elseif a.timestamp[2] ~= b.timestamp[2] then
			return a.timestamp[2] > b.timestamp[2]
		else	
			return a.questId < b.questId
		end
	end)
	
	for _, v in ipairs(pinnedQuestList) do
		if numEntry >= self.svCurrent.maxNumDisplay then break end
		if numEntry >= self.svCurrent.maxNumPinnedQuest then break end
		table.insert(self.questList, v)
		numEntry = numEntry + 1
	end
	for _, v in ipairs(unpinnedQuestList) do
		if numEntry >= self.svCurrent.maxNumDisplay then break end
		table.insert(self.questList, v)
		numEntry = numEntry + 1
	end

	ZO_ClearTable(self.circularJournalIndexList)
	local numQuestListEntry = #self.questList
	if numQuestListEntry > 0 then
		local prevIndex = self.questList[numQuestListEntry].journalIndex
		for k, v in ipairs(self.questList) do
			local t = {
				questListIndex = k, 
				prevJournalIndex = prevIndex, 
			}
			self.circularJournalIndexList[v.journalIndex] = t
			if self.circularJournalIndexList[prevIndex] then
				self.circularJournalIndexList[prevIndex].nextJournalIndex = v.journalIndex
			end
			prevIndex = v.journalIndex
		end
		self.circularJournalIndexList[prevIndex].nextJournalIndex = self.questList[1].journalIndex
	end
	CALLBACK_MANAGER:FireCallbacks("CQT-QuestListUpdated", self.questList)
end


function CQT:PickOutQuestByIndex(journalIndex)
	return self:PickOutQuest(GetQuestId(journalIndex))
end
function CQT:PickOutQuest(questId)
	self:UpdateTimeStamp(questId)
	self:RefreshQuestList()
end

function CQT:PickOutPinnedQuestByIndex(journalIndex)
	return self:PickOutPinnedQuest(GetQuestId(journalIndex))
end
function CQT:PickOutPinnedQuest(questId)
	self:UpdateTimeStamp(questId)
	self:SetPinnedStatusTimeStamp(questId)
	self:RefreshQuestList()
end

function CQT:RuleOutQuestByIndex(journalIndex)
	return self:RuleOutQuest(GetQuestId(journalIndex))
end
function CQT:RuleOutQuest(questId)
	self:UpdateTimeStamp(questId, 0 - GetTimeStamp(), 0 - GetGameTimeMilliseconds())
	if self:IsPinnedQuest(questId) then
		self:ResetPinnedStatusTimeStamp(questId)
	end
	self:RefreshQuestList()
end

function CQT:EnablePinningQuestByIndex(journalIndex)
	return self:EnablePinningQuest(GetQuestId(journalIndex))
end
function CQT:EnablePinningQuest(questId)
	CQT:SetPinnedStatusTimeStamp(questId)
	CQT:RefreshQuestList()
end

function CQT:DisablePinningQuestByIndex(journalIndex)
	return self:DisablePinningQuest(GetQuestId(journalIndex))
end
function CQT:DisablePinningQuest(questId)
	CQT:ResetPinnedStatusTimeStamp(questId)
	CQT:RefreshQuestList()
end

function CQT:IsPinnedQuestByIndex(journalIndex)
	return self:IsPinnedQuest(GetQuestId(journalIndex))
end
function CQT:IsPinnedQuest(questId)
	return self.activityLog.quest[questId] and self.activityLog.quest[questId][3] and self.activityLog.quest[questId][3] > 0
end

function CQT:EnableIgnoringQuestByIndex(journalIndex)
	return self:EnableIgnoringQuest(GetQuestId(journalIndex))
end
function CQT:EnableIgnoringQuest(questId)
	self:SetPinnedStatusTimeStamp(questId, 0 - GetTimeStamp())
	self:RefreshQuestList()
end

function CQT:DisableIgnoringQuestByIndex(journalIndex)
	return self:DisableIgnoringQuest(GetQuestId(journalIndex))
end
function CQT:DisableIgnoringQuest(questId)
	self:ResetPinnedStatusTimeStamp(questId)
	self:RefreshQuestList()
end

function CQT:IsIgnoredQuestByIndex(journalIndex)
	return self:IsIgnoredQuest(GetQuestId(journalIndex))
end
function CQT:IsIgnoredQuest(questId)
	return self.activityLog.quest[questId] and self.activityLog.quest[questId][3] and self.activityLog.quest[questId][3] < 0
end

function CQT:IsUnrecordedQuestByIndex(journalIndex)
	return self:IsUnrecordedQuest(GetQuestId(journalIndex))
end
function CQT:IsUnrecordedQuest(questId)
	return self:IsValidTimeStamp(questId) and self.activityLog.quest[questId][1] == 0 and self.activityLog.quest[questId][2] == 0
end


function CQT:IsValidTimeStamp(questId)
	return self.activityLog.quest[questId] and self.activityLog.quest[questId][1] and self.activityLog.quest[questId][2]
end

function CQT:UpdateTimeStampByIndex(journalIndex, arg1, arg2)
	return self:UpdateTimeStamp(GetQuestId(journalIndex), arg1, arg2)
end
function CQT:UpdateTimeStamp(questId, arg1, arg2)
	self.trackerPanel:SetTreeNodeOpenStatus(questId, nil)	-- clear previous status
	if not self.activityLog.quest[questId] then
		self.activityLog.quest[questId] = {}
	end
	self.activityLog.quest[questId][1] = arg1 or GetTimeStamp()
	self.activityLog.quest[questId][2] = arg2 or GetGameTimeMilliseconds()
end

function CQT:SetPinnedStatusTimeStampByIndex(journalIndex, arg3)
	return self:SetPinnedStatusTimeStamp(GetQuestId(journalIndex), arg3)
end
function CQT:SetPinnedStatusTimeStamp(questId, arg3)
	self.trackerPanel:SetTreeNodeOpenStatus(questId, nil)	-- clear previous status
	if self.activityLog.quest[questId] then
		self.activityLog.quest[questId][3] = arg3 or GetTimeStamp()
	end
end

function CQT:ResetPinnedStatusTimeStampByIndex(journalIndex)
	return self:ResetPinnedStatusTimeStamp(GetQuestId(journalIndex))
end
function CQT:ResetPinnedStatusTimeStamp(questId)
	self.trackerPanel:SetTreeNodeOpenStatus(questId, nil)	-- clear previous status
	if self.activityLog.quest[questId] then
		self.activityLog.quest[questId][3] = nil
	end
end

function CQT:DeleteTimeStampByIndex(journalIndex)
	return self:DeleteTimeStamp(GetQuestId(journalIndex))
end
function CQT:DeleteTimeStamp(questId)
	self.trackerPanel:SetTreeNodeOpenStatus(questId, nil)	-- clear previous status
	if self.activityLog.quest[questId] then
		self.activityLog.quest[questId] = nil
	end
end

function CQT:GetTimeStampByIndex(journalIndex)
	return self.activityLog[GetQuestId(journalIndex)]
end
function CQT:GetTimeStamp(questId)
	return self.activityLog.quest[questId]
end

function CQT:ValidateActivityLog()
	for i = 1, MAX_JOURNAL_QUESTS do
		if IsValidQuestIndex(i) then
			local questId = GetQuestId(i)
			if not self:IsValidTimeStamp(questId) then
				-- If the player had accepted an unrecorded quest in the activity log, 
				if select(7, GetJournalQuestInfo(i)) then
					self:UpdateTimeStamp(questId, nil, i)
				else
					self:UpdateTimeStamp(questId, 0, 0)
				end
			end
		end
	end
end


function CQT:IsQuestTooltipShown()
	return self.isQuestTooltipShown
end

function CQT:LayoutQuestTooltip(tooltip, journalIndex)
	local function GetNumVisibleQuestConditions(journalIndex, stepIndex)
		local visibleConditionCount = 0
		for conditionIndex = 1, GetJournalQuestNumConditions(journalIndex, stepIndex) do
			local _, _, _, _, _, isVisible = GetJournalQuestConditionValues(journalIndex, stepIndex, conditionIndex)
			if isVisible then
				visibleConditionCount = visibleConditionCount + 1
			end
		end
		return visibleConditionCount
	end
	local function GetNumVisibleQuestHintSteps(journalIndex)
		local visibleHintCount = 0
		for stepIndex = QUEST_MAIN_STEP_INDEX + 1, GetJournalQuestNumSteps(journalIndex) do
			local _, stepVisibility, stepType = GetJournalQuestStepInfo(journalIndex, stepIndex)
			if stepType ~= QUEST_STEP_TYPE_END and stepVisibility == QUEST_STEP_VISIBILITY_HINT then
				visibleHintCount = visibleHintCount + GetNumVisibleQuestConditions(journalIndex, stepIndex)
			end
		end
		return visibleHintCount
	end
	local function IsOrDescription(journalIndex, stepIndex)
		local _, _, stepType, overrideText = GetJournalQuestStepInfo(journalIndex, stepIndex)
		return (not overrideText or overrideText == "") and stepType == QUEST_STEP_TYPE_OR and GetNumVisibleQuestConditions(journalIndex, stepIndex) > 2
	end
	local function IsMultipleDescriptions(journalIndex, stepIndex)
		local _, _, stepType, overrideText = GetJournalQuestStepInfo(journalIndex, stepIndex)
		return (not overrideText or overrideText == "") and (stepType == QUEST_STEP_TYPE_OR  or stepType == QUEST_STEP_TYPE_AND) and GetNumVisibleQuestConditions(journalIndex, stepIndex) > 2
	end
	local function AddRepeatableQuestDetails(journalIndex)
		local repeatType = GetJournalQuestRepeatType(journalIndex)
		if repeatType ~= QUEST_REPEAT_NOT_REPEATABLE then
			if HasCompletedQuestByIndex(journalIndex) then
				tooltip:AddLine(L(SI_CQT_QUEST_REPEATABLE_PREVIOUSLY_COMPLETED), "ZoFontGameMedium", 0, 1, 1, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
			else
				tooltip:AddLine(L(SI_CQT_QUEST_REPEATABLE_NEVER_COMPLETED), "ZoFontGameMedium", 0, 1, 0, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
			end
		end
	end
	local function AddQuestConditions(journalIndex, stepIndex)
		local _, stepVisibility, stepType, overrideText, conditionCount = GetJournalQuestStepInfo(journalIndex, stepIndex)
		if overrideText and overrideText ~= "" then
			local checked = stepType == QUEST_STEP_TYPE_AND
			if stepType ~= QUEST_STEP_TYPE_END then
				for conditionIndex = 1, conditionCount do
					local _, _, isFailCondition, isComplete = GetJournalQuestConditionValues(journalIndex, stepIndex, conditionIndex)
					if (not isFailCondition) and isComplete then
						if stepType ~= QUEST_STEP_TYPE_AND then
							checked = true
							break
						end
					else
						if stepType == QUEST_STEP_TYPE_AND then
							checked = false
							break
						end
					end
				end
			end
			if checked then
				tooltip:AddLine(zo_strformat(SI_CQT_QUEST_LIST_CHECKED_FORMATTER, overrideText), "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
			else
				tooltip:AddLine(zo_strformat(SI_CQT_QUEST_LIST_NORMAL_FORMATTER, overrideText), "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
			end
		else
			for conditionIndex = 1, conditionCount do
				local conditionText, curCount, maxCount, isFailCondition, isComplete, isGroupCreditShared, isVisible, conditionType = GetJournalQuestConditionInfo(journalIndex, stepIndex, conditionIndex)
				if (not isFailCondition) and (conditionText ~= "") and isVisible then
					if isComplete or (curCount == maxCount) then
						tooltip:AddLine(zo_strformat(SI_CQT_QUEST_LIST_CHECKED_FORMATTER, conditionText), "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
					else
						tooltip:AddLine(zo_strformat(SI_CQT_QUEST_LIST_NORMAL_FORMATTER, conditionText), "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
					end
				end
			end
		end
	end
	local titleR, titleG, titleB = ZO_SELECTED_TEXT:UnpackRGB()
	local questName, backgroundText, activeStepText, activeStepType, activeStepTrackerOverrideText, completed, tracked, questLevel, pushed, questType, instanceDisplayType = GetJournalQuestInfo(journalIndex)
	local zoneName, _, pz = GetJournalQuestLocationInfo(journalIndex)
	local repeatType = GetJournalQuestRepeatType(journalIndex)
	local questIcon = QUEST_JOURNAL_KEYBOARD:GetIconTexture(questType, instanceDisplayType)
	local bgTexture = GetZoneStoryKeyboardBackground(GetZoneId(pz))
	tooltip:GetNamedChild("Background"):SetTexture(bgTexture)
	tooltip:GetNamedChild("Background"):SetHidden(bgTexture == GetZoneStoryKeyboardBackground(0))
	if questIcon then
		ZO_ItemIconTooltip_OnAddGameData(tooltip, TOOLTIP_GAME_DATA_ITEM_ICON, questIcon)
	end
	local questTypeName
	if questType == QUEST_TYPE_NONE and zoneName ~= "" then
		if instanceDisplayType == INSTANCE_DISPLAY_TYPE_ZONE_STORY then
			questTypeName = L(SI_CQT_QUESTTYPE_ZONE_STORY_QUEST)
		else
			questTypeName = L(SI_CQT_QUESTTYPE_SIDE_QUEST)
		end
	else
		questTypeName = L("SI_QUESTTYPE", questType)
	end
	tooltip:AddHeaderLine(questTypeName, "ZoFontWinH5", 1, TOOLTIP_HEADER_SIDE_LEFT, ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
	tooltip:AddHeaderLine(zo_strformat(SI_QUEST_JOURNAL_ZONE_FORMAT, zoneName), "ZoFontWinH5", 2, TOOLTIP_HEADER_SIDE_LEFT, ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
	if repeatType ~= QUEST_REPEAT_NOT_REPEATABLE then
		tooltip:AddHeaderLine(L(SI_CQT_QUEST_REPEATABLE_TEXT), "ZoFontWinH5", 1, TOOLTIP_HEADER_SIDE_RIGHT, ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
	end
	tooltip:AddLine(zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, questName), "ZoFontWinH2", titleR, titleG, titleB, TOPLEFT, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
	tooltip:AddVerticalPadding(18)
	CQT_QuestTooltip_AddDivider(tooltip)
	if completed then
		local goalCondition, _, _, _, goalBackgroundText, goalStepText = GetJournalQuestEnding(journalIndex)
		tooltip:AddLine(L(SI_CQT_QUEST_BACKGROUND_HEADER), "ZoFontGameMedium", titleR, titleG, titleB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, true)
		tooltip:AddLine(goalBackgroundText, "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
		tooltip:AddLine(zo_strformat(L(SI_CQT_QUEST_OBJECTIVES_HEADER), 1), "ZoFontGameMedium", titleR, titleG, titleB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, true)
		tooltip:AddLine(goalStepText, "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
		CQT_QuestTooltip_AddDivider(tooltip)
		tooltip:AddLine(goalCondition, "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
	else
		local objectivesHeader
		tooltip:AddLine(L(SI_CQT_QUEST_BACKGROUND_HEADER), "ZoFontGameMedium", titleR, titleG, titleB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, true)
		tooltip:AddLine(backgroundText, "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
		if IsOrDescription(journalIndex, QUEST_MAIN_STEP_INDEX) then
			objectivesHeader = L(SI_CQT_QUEST_OBJECTIVES_OR_HEADER)
		else
			objectivesHeader = L(SI_CQT_QUEST_OBJECTIVES_HEADER)
		end
		tooltip:AddLine(zo_strformat(objectivesHeader, IsMultipleDescriptions(journalIndex, MAIN_STEP_INDEX) and 2 or 1), "ZoFontGameMedium", titleR, titleG, titleB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, true)
		tooltip:AddLine(activeStepText, "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
		CQT_QuestTooltip_AddDivider(tooltip)
		AddQuestConditions(journalIndex, QUEST_MAIN_STEP_INDEX)
	end
	for stepIndex = QUEST_MAIN_STEP_INDEX + 1, GetJournalQuestNumSteps(journalIndex) do
		local optionalStepText, stepVisibility, stepType = GetJournalQuestStepInfo(journalIndex, stepIndex)
		if stepType ~= QUEST_STEP_TYPE_END and stepVisibility == QUEST_STEP_VISIBILITY_OPTIONAL then
			if IsOrDescription(journalIndex, stepIndex) then
				tooltip:AddLine(L(SI_CQT_QUEST_OPTIONAL_STEPS_OR_DESCRIPTION), "ZoFontGameMedium", titleR, titleG, titleB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, true)
			else
				tooltip:AddLine(L(SI_CQT_QUEST_OPTIONAL_STEPS_DESCRIPTION), "ZoFontGameMedium", titleR, titleG, titleB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, true)
			end
			if optionalStepText ~= "" then
				tooltip:AddLine(optionalStepText, "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
				CQT_QuestTooltip_AddDivider(tooltip)
			end
			AddQuestConditions(journalIndex, stepIndex)
		end
	end
	local hintHeaderDisplayed = false
	local visibleHintCount = GetNumVisibleQuestHintSteps(journalIndex)
	if visibleHintCount > 0 then
		for stepIndex = QUEST_MAIN_STEP_INDEX + 1, GetJournalQuestNumSteps(journalIndex) do
			local _, stepVisibility, stepType = GetJournalQuestStepInfo(journalIndex, stepIndex)
			if stepType ~= QUEST_STEP_TYPE_END and stepVisibility == QUEST_STEP_VISIBILITY_HINT then
				if not hintHeaderDisplayed then
					CQT_QuestTooltip_AddDivider(tooltip)
					tooltip:AddLine(zo_strformat(L(SI_CQT_QUEST_HINT_STEPS_HEADER), visibleHintCount), "ZoFontGameMedium", titleR, titleG, titleB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, true)
					hintHeaderDisplayed = true
				end
				AddQuestConditions(journalIndex, stepIndex)
			end
		end
	end
	if repeatType ~= QUEST_REPEAT_NOT_REPEATABLE then
		CQT_QuestTooltip_AddDivider(tooltip)
		AddRepeatableQuestDetails(journalIndex, repeatType)
	end
end

function CQT:ShowQuestTooltipNextToOwner(control, journalIndex)
	local PADDING = 10
	jorunalIndex = journalIndex or control.journalIndex
	if journalIndex then
		local owner = control:GetOwningWindow()
		local relativePoint = LEFT	-- or user preference
		if (owner:GetRight() + PADDING + CQT_QuestTooltip:GetWidth()) > GuiRoot:GetRight() then
			relativePoint = LEFT
		elseif (owner:GetLeft() - PADDING - CQT_QuestTooltip:GetWidth()) < GuiRoot:GetLeft() then
			relativePoint = RIGHT
		end
		if relativePoint == LEFT then
			InitializeTooltip(CQT_QuestTooltip, owner, RIGHT, 0 - PADDING, 0, LEFT)
		else
			InitializeTooltip(CQT_QuestTooltip, owner, LEFT, PADDING, 0, RIGHT)
		end
		self:LayoutQuestTooltip(CQT_QuestTooltip, journalIndex)
		self.isQuestTooltipShown = true
	end
end

function CQT:HideQuestTooltip()
	ClearTooltip(CQT_QuestTooltip)
	self.isQuestTooltipShown = false
end

function CQT:ShowQuestListManagementMenu(owner, initialRefCount, menuType)
	local PADDING = 200
	local function QuestListMenuTooltip(control, inside, journalIndex)
		if inside then
			local relativePoint = LEFT	-- or user preference
			local owner = ZO_Menu
			if (owner:GetRight() + PADDING + CQT_QuestTooltip:GetWidth()) > GuiRoot:GetRight() then
				relativePoint = LEFT
			elseif (owner:GetLeft() - PADDING - CQT_QuestTooltip:GetWidth()) < GuiRoot:GetLeft() then
				relativePoint = RIGHT
			end
			if relativePoint == LEFT then
				InitializeTooltip(CQT_QuestTooltip, owner, RIGHT, 0 - PADDING, 0, LEFT)
			else
				InitializeTooltip(CQT_QuestTooltip, owner, LEFT, PADDING, 0, RIGHT)
			end
			self:LayoutQuestTooltip(CQT_QuestTooltip, journalIndex)
			self.isQuestTooltipShown = true
		else
			self:HideQuestTooltip()
		end
	end
	local quests = QUEST_JOURNAL_MANAGER:GetQuestList()
	if quests and #quests > 0 then
		ClearMenu()
		AddCustomMenuItem(zo_strformat(L(SI_CQT_QUESTLIST_MENU_HEADER), GetNumJournalQuests(), MAX_JOURNAL_QUESTS), function() end, MENU_ADD_OPTION_HEADER)
		for k, v in pairs(quests) do
			local format
			local subMenuEntries = {}
--[[
			table.insert(subMenuEntries, {
				label = L(SI_CQT_PICK_OUT_QUEST), 
				callback = function()
					self:PickOutQuestByIndex(v.questIndex)
				end, 
				disabled = function()
					return self:IsIgnoredQuestByIndex(v.questIndex) or self:IsPinnedQuestByIndex(v.questIndex)
				end, 
				tooltip = function(control, inside)
					QuestListMenuTooltip(control, inside, v.questIndex)
				end, 
			})
]]
			if self:IsPinnedQuestByIndex(v.questIndex) then
				format = L(SI_CQT_QUEST_LIST_PINNED_FORMATTER)
				table.insert(subMenuEntries, {
					label = L(SI_CQT_DISABLE_PINNING_QUEST), 
					callback = function()
						self:DisablePinningQuestByIndex(v.questIndex)
					end, 
					tooltip = function(control, inside)
						QuestListMenuTooltip(control, inside, v.questIndex)
					end, 
				})
			else
				table.insert(subMenuEntries, {
					label = L(SI_CQT_ENABLE_PINNING_QUEST), 
					callback = function()
						self:EnablePinningQuestByIndex(v.questIndex)
					end, 
					tooltip = function(control, inside)
						QuestListMenuTooltip(control, inside, v.questIndex)
					end, 
				})
			end
			if self:IsIgnoredQuestByIndex(v.questIndex) then
				format = L(SI_CQT_QUEST_LIST_IGNORED_FORMATTER)
				table.insert(subMenuEntries, {
					label = L(SI_CQT_DISABLE_IGNORING_QUEST), 
					callback = function()
						self:DisableIgnoringQuestByIndex(v.questIndex)
					end, 
					tooltip = function(control, inside)
						QuestListMenuTooltip(control, inside, v.questIndex)
					end, 
				})
			else
				format = format or L(SI_CQT_QUEST_LIST_NORMAL_FORMATTER)
				table.insert(subMenuEntries, {
					label = L(SI_CQT_ENABLE_IGNORING_QUEST), 
					callback = function()
						self:EnableIgnoringQuestByIndex(v.questIndex)
					end, 
					tooltip = function(control, inside)
						QuestListMenuTooltip(control, inside, v.questIndex)
					end, 
				})
			end
			table.insert(subMenuEntries, {
				label = L(SI_CQT_MOST_LOWER_QUEST), 
				callback = function()
					self:RuleOutQuestByIndex(v.questIndex)
				end, 
				tooltip = function(control, inside)
					QuestListMenuTooltip(control, inside, v.questIndex)
				end, 
			})
			if GetJournalQuestType(v.questIndex) ~= QUEST_TYPE_MAIN_STORY then
				table.insert(subMenuEntries, {
					label = L(SI_QUEST_TRACKER_MENU_ABANDON), 
					callback = function()
						AbandonQuest(v.questIndex)
			 		end, 
					disabled = function()
						return GetJournalQuestType(v.questIndex) == QUEST_TYPE_MAIN_STORY
					end, 
					tooltip = function(control, inside)
						QuestListMenuTooltip(control, inside, v.questIndex)
					end, 
				})
			end
			AddCustomSubMenuItem(zo_strformat(format, v.name), subMenuEntries, nil, nil, nil, nil, function()
				self:HideQuestTooltip()
				self:PickOutQuestByIndex(v.questIndex)
			end)
			AddCustomMenuTooltip(function(control, inside)
				QuestListMenuTooltip(control, inside, v.questIndex)
			end)
		end
		ShowMenu(owner, initialRefCount, menuType)
	end
end

function CQT:AddTrackerPanelFragmentToGameMenuScene()
	if self.trackerPanel then
		local trackerPanelFragment= self.trackerPanel:GetFragment()
		local trackerPanelTitleBarFragment = self.trackerPanel:GetTitleBarFragment()
		if not GAME_MENU_SCENE:HasFragment(trackerPanelFragment) then
			GAME_MENU_SCENE:AddFragment(trackerPanelFragment)
		end
		if not GAME_MENU_SCENE:HasFragment(trackerPanelTitleBarFragment) then
			GAME_MENU_SCENE:AddFragment(trackerPanelTitleBarFragment)
		end
		
	end
end

function CQT:RemoveTrackerPanelFragmentFromGameMenuScene()
	if self.trackerPanel then
		local trackerPanelFragment= self.trackerPanel:GetFragment()
		local trackerPanelTitleBarFragment = self.trackerPanel:GetTitleBarFragment()
		if GAME_MENU_SCENE:HasFragment(trackerPanelFragment) then
			GAME_MENU_SCENE:RemoveFragment(trackerPanelFragment)
		end
		if GAME_MENU_SCENE:HasFragment(trackerPanelTitleBarFragment) then
			GAME_MENU_SCENE:RemoveFragment(trackerPanelTitleBarFragment)
		end
	end
end

function CQT:UpdateTrackerPanelAttribute(key, value)
	if self.svCurrent.panelAttributes[key] ~= nil then
		self.svCurrent.panelAttributes[key] = value
		CALLBACK_MANAGER:FireCallbacks("CQT-TrackerPanelVisualUpdated", key)
	end
end

function CQT:UpdateTrackerPanelVisibility()
	if self.trackerPanel then
		local trackerPanelFragment= self.trackerPanel:GetFragment()
		trackerPanelFragment:SetHiddenForReason("DisabledInCombat", (not self.svCurrent.panelBehavior.showInCombat) and IsUnitInCombat("player"), 0, 0)
		trackerPanelFragment:SetHiddenForReason("DisabledInBattlegrounds", (not self.svCurrent.panelBehavior.showInBattleground) and IsActiveWorldBattleground(), 0, 0)
		trackerPanelFragment:SetHiddenForReason("DisabledWhileKeybindingsSettings", KEYBINDINGS_FRAGMENT:IsShowing(), 0, 0)
		trackerPanelFragment:SetHiddenForReason("DisabledBySetting", self:GetTrackerPanelHideSetting(), 0, 0)
	end
end

function CQT:GetTrackerPanelHideSetting()
	return self.svCurrent.hideCQuestTracker
end

function CQT:SetTrackerPanelHideSetting(newValue)
	self.svCurrent.hideCQuestTracker = newValue
	self:UpdateSettingPanel()
	self:UpdateTrackerPanelVisibility()
end

function CQT:ToggleTrackerPanelHideSetting()
	self:SetTrackerPanelHideSetting(not self:GetTrackerPanelHideSetting())
end


function CQT:CreateSettingPanel()
	local panelData = {
		type = "panel", 
		name = "CQuestTracker", 
		displayName = "Calamath's Quest Tracker", 
		author = self.author, 
		version = self.version, 
		website = "https://www.esoui.com/downloads/info3276-CalamathsQuestTracker.html", 
		feedback = "https://www.esoui.com/downloads/info3276-CalamathsQuestTracker.html#comments", 
		donation = "https://www.esoui.com/downloads/info3276-CalamathsQuestTracker.html#donate", 
		slashCommand = "/cqt", 
		registerForRefresh = true, 
		registerForDefaults = true, 
	}
	self.settingPanel = LAM:RegisterAddonPanel("CQuestTracker_Options", panelData)

	local optionsData = {}
	optionsData[#optionsData + 1] = {
		type = "description", 
		title = "", 
		text = L(SI_CQT_UI_PANEL_HEADER1_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_ACCOUNT_WIDE_OP_NAME), 
		getFunc = function() return self.svAccount.accountWide end, 
		setFunc = function(newValue) self.svAccount.accountWide = newValue end, 
		tooltip = L(SI_CQT_UI_ACCOUNT_WIDE_OP_TIPS), 
		width = "full", 
		requiresReload = true, 
		default = CQT_SV_DEFAULT.accountWide, 
	}
	optionsData[#optionsData + 1] = {
		type = "header", 
		name = L(SI_CQT_UI_BEHAVIOR_HEADER1_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_HIDE_DEFAULT_TRACKER_OP_NAME), 
		getFunc = function() return self.svCurrent.hideFocusedQuestTracker end, 
		setFunc = function(newValue)
			self.svCurrent.hideFocusedQuestTracker = newValue
			SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_TRACKER, newValue and "false" or "true")
		end, 
--		tooltip = L(SI_CQT_UI_HIDE_DEFAULT_TRACKER_OP_TIPS), 
		width = "full", 
		default = CQT_SV_DEFAULT.hideFocusedQuestTracker, 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_HIDE_QUEST_TRACKER_OP_NAME), 
		getFunc = function() return self:GetTrackerPanelHideSetting() end, 
		setFunc = function(newValue)
			self:SetTrackerPanelHideSetting(newValue)
		end, 
--		tooltip = L(SI_CQT_UI_HIDE_QUEST_TRACKER_OP_TIPS), 
		width = "full", 
		default = CQT_SV_DEFAULT.hideCQuestTracker, 
		reference = "CQT_UI_OptionsPanel_HideQuestTrackerCheckBox", 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_SHOW_IN_COMBAT_OP_NAME), 
		getFunc = function() return self.svCurrent.panelBehavior.showInCombat end, 
		setFunc = function(newValue)
			self.svCurrent.panelBehavior.showInCombat = newValue
			self:UpdateTrackerPanelVisibility()
		end, 
		tooltip = L(SI_CQT_UI_SHOW_IN_COMBAT_OP_TIPS), 
		width = "full", 
		disabled = function() return self:GetTrackerPanelHideSetting() end, 
		default = CQT_SV_DEFAULT.panelBehavior.showInCombat, 
		reference = "CQT_UI_OptionsPanel_ShowInCombatCheckBox", 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_SHOW_IN_GAMEMENU_SCENE_OP_NAME), 
		getFunc = function() return self.svCurrent.panelBehavior.showInGameMenuScene end, 
		setFunc = function(newValue)
			self.svCurrent.panelBehavior.showInGameMenuScene = newValue
			if newValue then
				self:AddTrackerPanelFragmentToGameMenuScene()
			else
				self:RemoveTrackerPanelFragmentFromGameMenuScene()
			end
		end, 
		tooltip = L(SI_CQT_UI_SHOW_IN_GAMEMENU_SCENE_OP_TIPS), 
		width = "full", 
		disabled = function() return self:GetTrackerPanelHideSetting() end, 
		default = CQT_SV_DEFAULT.panelBehavior.showInGameMenuScene, 
		reference = "CQT_UI_OptionsPanel_ShowInGameMenuSceneCheckBox", 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_HIDE_IN_BATTLEGROUNDS_OP_NAME), 
		getFunc = function() return not self.svCurrent.panelBehavior.showInBattleground end, 
		setFunc = function(newValue)
			self.svCurrent.panelBehavior.showInBattleground = not newValue
			self:UpdateTrackerPanelVisibility()
		end, 
		tooltip = L(SI_CQT_UI_HIDE_IN_BATTLEGROUNDS_OP_TIPS), 
		width = "full", 
		disabled = function() return self:GetTrackerPanelHideSetting() end, 
		default = not CQT_SV_DEFAULT.panelBehavior.showInBattleground, 
		reference = "CQT_UI_OptionsPanel_HideInBattlegroundCheckBox", 
	}
	optionsData[#optionsData + 1] = {
		type = "header", 
		name = L(SI_CQT_UI_PANEL_OPTION_HEADER1_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "slider", 
		name = L(SI_CQT_UI_MAX_NUM_QUEST_DISPLAYED_OP_NAME), 
		tooltip = L(SI_CQT_UI_MAX_NUM_QUEST_DISPLAYED_OP_TIPS), 
		min = 2, 
		max = 10, 
		step = 1, 
		getFunc = function() return self.svCurrent.maxNumDisplay end, 
		setFunc = function(newValue)
			self.svCurrent.maxNumDisplay = newValue
			self.svCurrent.maxNumPinnedQuest = newValue
			self:RefreshQuestList()
		end, 
		clampInput = true, 
		default = CQT_SV_DEFAULT.maxNumDisplay, 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_COMPACT_MODE_OP_NAME), 
		getFunc = function() return self.svCurrent.panelAttributes.compactMode end, 
		setFunc = function(newValue)
			self.trackerPanel:ClearAllTreeNodeOpenStatus()
			self:UpdateTrackerPanelAttribute("compactMode", newValue)
		end, 
		tooltip = L(SI_CQT_UI_COMPACT_MODE_OP_TIPS), 
		width = "full", 
		default = CQT_SV_DEFAULT.panelAttributes.compactMode, 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_CLAMPED_TO_SCREEN_OP_NAME), 
		getFunc = function() return self.svCurrent.panelAttributes.clampedToScreen end, 
		setFunc = function(newValue)
			self:UpdateTrackerPanelAttribute("clampedToScreen", newValue)
		end, 
		tooltip = L(SI_CQT_UI_CLAMPED_TO_SCREEN_OP_TIPS), 
		width = "full", 
		default = CQT_SV_DEFAULT.panelAttributes.clampedToScreen, 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_HIDE_QUEST_HINT_STEP_OP_NAME), 
		getFunc = function() return not self.svCurrent.panelAttributes.showHintStep end, 
		setFunc = function(newValue)
			self:UpdateTrackerPanelAttribute("showHintStep", not newValue)
		end, 
		tooltip = L(SI_CQT_UI_HIDE_QUEST_HINT_STEP_OP_TIPS), 
		width = "full", 
		default = not CQT_SV_DEFAULT.panelAttributes.showHintStep, 
	}
	optionsData[#optionsData + 1] = {
		type = "header", 
		name = L(SI_CQT_UI_TRACKER_VISUAL_HEADER1_TEXT), 
	}
	
	local fontTypeChoices = {
		"Bold Font", 
		"Chat Font", 
		"Custom", 
	}
	local fontTypeChoicesValues = {
		"$(BOLD_FONT)", 
		"$(CHAT_FONT)", 
		"custom", 
	}
	local fontStyleChoices = LMP:List("font")
	local fontSizeChoices = {
		"14", 
		"15", 
		"16", 
		"17", 
		"18", 
		"19", 
		"20", 
		"24", 
	}
	local fontSizeChoicesValues = {
		"$(KB_14)", 
		"$(KB_15)", 
		"$(KB_16)", 
		"$(KB_17)", 
		"$(KB_18)", 
		"$(KB_19)", 
		"$(KB_20)", 
		"$(KB_24)", 
	}
	local fontWeightChoices = {
		"normal", 
		"shadow", 
		"outline", 
		"thick-outline", 
		"soft-shadow-thin", 
		"soft-shadow-thick", 
	}
	local function GetFontDescriptor(font)
		local fontPath = font[FONT_TYPE] == "custom" and LMP:Fetch("font", font[FONT_STYLE]) or font[FONT_TYPE]
		if font[FONT_WEIGHT] and font[FONT_WEIGHT] ~= "normal" then
			return string.format("%s|%s|%s", fontPath, font[FONT_SIZE], font[FONT_WEIGHT])
		else
			return string.format("%s|%s", fontPath, font[FONT_SIZE])
		end
	end
	optionsData[#optionsData + 1] = {
		type = "description", 
		title = "", 
		text = L(SI_CQT_UI_QUEST_NAME_FONT_SUBHEADER_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTTYPE_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_NAME_FONTTYPE_MENU_TIPS), 
		choices = fontTypeChoices, 
		choicesValues = fontTypeChoicesValues, 
		getFunc = function() return self.svCurrent.qhFont[FONT_TYPE] end, 
		setFunc = function(typeStr)
			self.svCurrent.qhFont[FONT_TYPE] = typeStr
			self:UpdateTrackerPanelAttribute("headerFont", GetFontDescriptor(self.svCurrent.qhFont))
		end, 
		scrollable = 15, 
		default = CQT_SV_DEFAULT.qhFont[FONT_TYPE], 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTSTYLE_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_NAME_FONTSTYLE_MENU_TIPS), 
		choices = fontStyleChoices, 
		getFunc = function() return self.svCurrent.qhFont[FONT_STYLE] end, 
		setFunc = function(styleStr)
			self.svCurrent.qhFont[FONT_STYLE] = styleStr
			self:UpdateTrackerPanelAttribute("headerFont", GetFontDescriptor(self.svCurrent.qhFont))
		end, 
		scrollable = 15, 
		disabled = function() return self.svCurrent.qhFont[FONT_TYPE] ~= "custom" end, 
		default = CQT_SV_DEFAULT.qhFont[FONT_STYLE], 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTSIZE_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_NAME_FONTSIZE_MENU_TIPS), 
		choices = fontSizeChoices, 
		choicesValues = fontSizeChoicesValues, 
		getFunc = function() return self.svCurrent.qhFont[FONT_SIZE] end, 
		setFunc = function(sizeStr)
			self.svCurrent.qhFont[FONT_SIZE] = sizeStr
			self:UpdateTrackerPanelAttribute("headerFont", GetFontDescriptor(self.svCurrent.qhFont))
		end, 
		scrollable = 15, 
		default = CQT_SV_DEFAULT.qhFont[FONT_SIZE], 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTWEIGHT_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_NAME_FONTWEIGHT_MENU_TIPS), 
		choices = fontWeightChoices, 
		getFunc = function() return self.svCurrent.qhFont[FONT_WEIGHT] end, 
		setFunc = function(weightStr)
			self.svCurrent.qhFont[FONT_WEIGHT] = weightStr
			self:UpdateTrackerPanelAttribute("headerFont", GetFontDescriptor(self.svCurrent.qhFont))
		end, 
		scrollable = 15, 
		default = CQT_SV_DEFAULT.qhFont[FONT_WEIGHT], 
	}
	optionsData[#optionsData + 1] = {
		type = "colorpicker", 
		name = L(SI_CQT_UI_QUEST_NAME_NORMAL_COLOR_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_NAME_NORMAL_COLOR_MENU_TIPS), 
		getFunc = function()
			local r, g, b = unpack(self.svCurrent.panelAttributes.headerColor)
			return r, g, b
		end, 
		setFunc = function(r, g, b)
			local a = self.svCurrent.panelAttributes.headerColor[4]
			self:UpdateTrackerPanelAttribute("headerColor", { r, g, b, a, })
		end, 
		default = {
			r = CQT_SV_DEFAULT.panelAttributes.headerColor[1], 
			g = CQT_SV_DEFAULT.panelAttributes.headerColor[2], 
			b = CQT_SV_DEFAULT.panelAttributes.headerColor[3], 
		}, 
	}
	optionsData[#optionsData + 1] = {
		type = "colorpicker", 
		name = L(SI_CQT_UI_QUEST_NAME_FOCUSED_COLOR_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_NAME_FOCUSED_COLOR_MENU_TIPS), 
		getFunc = function()
			local r, g, b = unpack(self.svCurrent.panelAttributes.headerColorSelected)
			return r, g, b
		end, 
		setFunc = function(r, g, b)
			local a = self.svCurrent.panelAttributes.headerColorSelected[4]
			self:UpdateTrackerPanelAttribute("headerColorSelected", { r, g, b, a, })
		end, 
		default = {
			r = CQT_SV_DEFAULT.panelAttributes.headerColorSelected[1], 
			g = CQT_SV_DEFAULT.panelAttributes.headerColorSelected[2], 
			b = CQT_SV_DEFAULT.panelAttributes.headerColorSelected[3], 
		}, 
	}
	optionsData[#optionsData + 1] = {
		type = "description", 
		title = "", 
		text = L(SI_CQT_UI_QUEST_CONDITION_FONT_SUBHEADER_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTTYPE_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_CONDITION_FONTTYPE_MENU_TIPS), 
		choices = fontTypeChoices, 
		choicesValues = fontTypeChoicesValues, 
		getFunc = function() return self.svCurrent.qcFont[FONT_TYPE] end, 
		setFunc = function(typeStr)
			self.svCurrent.qcFont[FONT_TYPE] = typeStr
			self:UpdateTrackerPanelAttribute("conditionFont", GetFontDescriptor(self.svCurrent.qcFont))
		end, 
		scrollable = 15, 
		default = CQT_SV_DEFAULT.qcFont[FONT_TYPE], 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTSTYLE_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_CONDITION_FONTSTYLE_MENU_TIPS), 
		choices = fontStyleChoices, 
		getFunc = function() return self.svCurrent.qcFont[FONT_STYLE] end, 
		setFunc = function(styleStr)
			self.svCurrent.qcFont[FONT_STYLE] = styleStr
			self:UpdateTrackerPanelAttribute("conditionFont", GetFontDescriptor(self.svCurrent.qcFont))
		end, 
		scrollable = 15, 
		disabled = function() return self.svCurrent.qcFont[FONT_TYPE] ~= "custom" end, 
		default = CQT_SV_DEFAULT.qcFont[FONT_STYLE], 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTSIZE_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_CONDITION_FONTSIZE_MENU_TIPS), 
		choices = fontSizeChoices, 
		choicesValues = fontSizeChoicesValues, 
		getFunc = function() return self.svCurrent.qcFont[FONT_SIZE] end, 
		setFunc = function(sizeStr)
			self.svCurrent.qcFont[FONT_SIZE] = sizeStr
			self:UpdateTrackerPanelAttribute("conditionFont", GetFontDescriptor(self.svCurrent.qcFont))
		end, 
		scrollable = 15, 
		default = CQT_SV_DEFAULT.qcFont[FONT_SIZE], 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTWEIGHT_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_CONDITION_FONTWEIGHT_MENU_TIPS), 
		choices = fontWeightChoices, 
		getFunc = function() return self.svCurrent.qcFont[FONT_WEIGHT] end, 
		setFunc = function(weightStr)
			self.svCurrent.qcFont[FONT_WEIGHT] = weightStr
			self:UpdateTrackerPanelAttribute("conditionFont", GetFontDescriptor(self.svCurrent.qcFont))
		end, 
		scrollable = 15, 
		default = CQT_SV_DEFAULT.qcFont[FONT_WEIGHT], 
	}
	optionsData[#optionsData + 1] = {
		type = "colorpicker", 
		name = L(SI_CQT_UI_QUEST_CONDITION_COLOR_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_CONDITION_COLOR_MENU_TIPS), 
		getFunc = function()
			local r, g, b = unpack(self.svCurrent.panelAttributes.conditionColor)
			return r, g, b
		end, 
		setFunc = function(r, g, b)
			local a = self.svCurrent.panelAttributes.conditionColor[4]
			self:UpdateTrackerPanelAttribute("conditionColor", { r, g, b, a, })
		end, 
		default = {
			r = CQT_SV_DEFAULT.panelAttributes.conditionColor[1], 
			g = CQT_SV_DEFAULT.panelAttributes.conditionColor[2], 
			b = CQT_SV_DEFAULT.panelAttributes.conditionColor[3], 
		}, 
	}
	optionsData[#optionsData + 1] = {
		type = "description", 
		title = "", 
		text = L(SI_CQT_UI_QUEST_HINT_FONT_SUBHEADER_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTTYPE_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_HINT_FONTTYPE_MENU_TIPS), 
		choices = fontTypeChoices, 
		choicesValues = fontTypeChoicesValues, 
		getFunc = function() return self.svCurrent.qkFont[FONT_TYPE] end, 
		setFunc = function(typeStr)
			self.svCurrent.qkFont[FONT_TYPE] = typeStr
			self:UpdateTrackerPanelAttribute("hintFont", GetFontDescriptor(self.svCurrent.qkFont))
		end, 
		scrollable = 15, 
		default = CQT_SV_DEFAULT.qkFont[FONT_TYPE], 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTSTYLE_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_HINT_FONTSTYLE_MENU_TIPS), 
		choices = fontStyleChoices, 
		getFunc = function() return self.svCurrent.qkFont[FONT_STYLE] end, 
		setFunc = function(styleStr)
			self.svCurrent.qkFont[FONT_STYLE] = styleStr
			self:UpdateTrackerPanelAttribute("hintFont", GetFontDescriptor(self.svCurrent.qkFont))
		end, 
		scrollable = 15, 
		disabled = function() return self.svCurrent.qkFont[FONT_TYPE] ~= "custom" end, 
		default = CQT_SV_DEFAULT.qkFont[FONT_STYLE], 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTSIZE_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_HINT_FONTSIZE_MENU_TIPS), 
		choices = fontSizeChoices, 
		choicesValues = fontSizeChoicesValues, 
		getFunc = function() return self.svCurrent.qkFont[FONT_SIZE] end, 
		setFunc = function(sizeStr)
			self.svCurrent.qkFont[FONT_SIZE] = sizeStr
			self:UpdateTrackerPanelAttribute("hintFont", GetFontDescriptor(self.svCurrent.qkFont))
		end, 
		scrollable = 15, 
		default = CQT_SV_DEFAULT.qkFont[FONT_SIZE], 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_COMMON_FONTWEIGHT_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_HINT_FONTWEIGHT_MENU_TIPS), 
		choices = fontWeightChoices, 
		getFunc = function() return self.svCurrent.qkFont[FONT_WEIGHT] end, 
		setFunc = function(weightStr)
			self.svCurrent.qkFont[FONT_WEIGHT] = weightStr
			self:UpdateTrackerPanelAttribute("hintFont", GetFontDescriptor(self.svCurrent.qkFont))
		end, 
		scrollable = 15, 
		default = CQT_SV_DEFAULT.qkFont[FONT_WEIGHT], 
	}
	optionsData[#optionsData + 1] = {
		type = "colorpicker", 
		name = L(SI_CQT_UI_QUEST_HINT_COLOR_MENU_NAME), 
		tooltip = L(SI_CQT_UI_QUEST_HINT_COLOR_MENU_TIPS), 
		getFunc = function()
			local r, g, b = unpack(self.svCurrent.panelAttributes.hintColor)
			return r, g, b
		end, 
		setFunc = function(r, g, b)
			local a = self.svCurrent.panelAttributes.hintColor[4]
			self:UpdateTrackerPanelAttribute("hintColor", { r, g, b, a, })
		end, 
		default = {
			r = CQT_SV_DEFAULT.panelAttributes.hintColor[1], 
			g = CQT_SV_DEFAULT.panelAttributes.hintColor[2], 
			b = CQT_SV_DEFAULT.panelAttributes.hintColor[3], 
		}, 
	}
	optionsData[#optionsData + 1] = {
		type = "description", 
		title = "", 
		text = L(SI_CQT_UI_TITLEBAR_SUBHEADER_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "colorpicker", 
		name = L(SI_CQT_UI_TITLEBAR_COLOR_MENU_NAME), 
		tooltip = L(SI_CQT_UI_TITLEBAR_COLOR_MENU_TIPS), 
		getFunc = function()
			local r, g, b = unpack(self.svCurrent.panelAttributes.titlebarColor)
			return r, g, b
		end, 
		setFunc = function(r, g, b)
			local a = self.svCurrent.panelAttributes.titlebarColor[4]
			self:UpdateTrackerPanelAttribute("titlebarColor", { r, g, b, a, })
		end, 
		default = {
			r = CQT_SV_DEFAULT.panelAttributes.titlebarColor[1], 
			g = CQT_SV_DEFAULT.panelAttributes.titlebarColor[2], 
			b = CQT_SV_DEFAULT.panelAttributes.titlebarColor[3], 
		}, 
	}
	optionsData[#optionsData + 1] = {
		type = "slider", 
		name = L(SI_CQT_UI_COMMON_OPACITY_MENU_NAME), 
		tooltip = L(SI_CQT_UI_TITLEBAR_OPACITY_MENU_TIPS), 
		getFunc = function() return zo_round(self.svCurrent.panelAttributes.titlebarColor[4] * 100) end, 
		setFunc = function(newValue)
			local r, g, b = unpack(self.svCurrent.panelAttributes.titlebarColor)
			self:UpdateTrackerPanelAttribute("titlebarColor", { r, g, b, newValue / 100, })
		end, 
		min = 0.0, 
		max = 100.0, 
		step = 1, 
		default = zo_round(CQT_SV_DEFAULT.panelAttributes.titlebarColor[4] * 100), 
	}
	optionsData[#optionsData + 1] = {
		type = "description", 
		title = "", 
		text = L(SI_CQT_UI_BACKGROUND_SUBHEADER_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "colorpicker", 
		name = L(SI_CQT_UI_COMMON_BACKGROUND_COLOR_MENU_NAME), 
		tooltip = L(SI_CQT_UI_BACKGROUND_COLOR_MENU_TIPS), 
		getFunc = function()
			local r, g, b = unpack(self.svCurrent.panelAttributes.bgColor)
			return r, g, b
		end, 
		setFunc = function(r, g, b)
			local a = self.svCurrent.panelAttributes.bgColor[4]
			self:UpdateTrackerPanelAttribute("bgColor", { r, g, b, a, })
		end, 
		default = {
			r = CQT_SV_DEFAULT.panelAttributes.bgColor[1], 
			g = CQT_SV_DEFAULT.panelAttributes.bgColor[2], 
			b = CQT_SV_DEFAULT.panelAttributes.bgColor[3], 
		}, 
	}
	optionsData[#optionsData + 1] = {
		type = "slider", 
		name = L(SI_CQT_UI_COMMON_OPACITY_MENU_NAME), 
		tooltip = L(SI_CQT_UI_BACKGROUND_OPACITY_MENU_TIPS), 
		getFunc = function() return zo_round(self.svCurrent.panelAttributes.bgColor[4] * 100) end, 
		setFunc = function(newValue)
			local r, g, b = unpack(self.svCurrent.panelAttributes.bgColor)
			self:UpdateTrackerPanelAttribute("bgColor", { r, g, b, newValue / 100, })
		end, 
		min = 0.0, 
		max = 100.0, 
		step = 1, 
		default = zo_round(CQT_SV_DEFAULT.panelAttributes.bgColor[4] * 100), 
	}
	optionsData[#optionsData + 1] = {
		type = "header", 
		name = L(SI_CQT_UI_ADVANCED_OPTION_HEADER1_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "description", 
		title = "", 
		text = L(SI_CQT_UI_KEYBINDS_INTERACTION_HEADER1_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_KEYBINDS_IMPROVEMENT_MENU_NAME), 
		getFunc = function() return self.svCurrent.improveKeybinds end, 
		setFunc = function(newValue)
			self.svCurrent.improveKeybinds = newValue
			if newValue then
				PushActionLayerByName("CQT_InteractionSnatcher")
			else
				RemoveActionLayerByName("CQT_InteractionSnatcher")
			end
		end, 
		tooltip = L(SI_CQT_UI_KEYBINDS_IMPROVEMENT_MENU_TIPS), 
		width = "full", 
		default = CQT_SV_DEFAULT.improveKeybinds, 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_CYCLE_DISPLAYED_QUESTS_MENU_NAME), 
		getFunc = function() return not self.svCurrent.cycleAllQuests end, 
		setFunc = function(newValue)
			self.svCurrent.cycleAllQuests = not newValue
		end, 
		tooltip = L(SI_CQT_UI_CYCLE_DISPLAYED_QUESTS_MENU_TIPS), 
		width = "full", 
		disabled = function() return not self.svCurrent.improveKeybinds end, 
		default = not CQT_SV_DEFAULT.cycleAllQuests, 
	}

	local modifierKeyChoices = {}
	local modifierKeyChoicesValues = LibCInteraction:GetSupportedModifierKeys()
	for k, v in pairs(modifierKeyChoicesValues) do
		table.insert(modifierKeyChoices, GetKeyName(v) .. " " .. ZO_Keybindings_GenerateIconKeyMarkup(v, 125))
	end
	table.insert(modifierKeyChoices, GetKeyName(KEY_INVALID))
	table.insert(modifierKeyChoicesValues, KEY_INVALID)
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_CYCLE_BACKWARDS_MOD_KEY1_MENU_NAME), 
		tooltip = L(SI_CQT_UI_CYCLE_BACKWARDS_MOD_KEY_MENU_TIPS), 
		choices = modifierKeyChoices, 
		choicesValues = modifierKeyChoicesValues, 
		sort = "value-up", 
		getFunc = function() return self.svCurrent.cycleBackwardsMod1 end, 
		setFunc = function(keyCode)
			self.svCurrent.cycleBackwardsMod1 = keyCode
		end, 
		scrollable = 15, 
		disabled = function() return not self.svCurrent.improveKeybinds end, 
		default = CQT_SV_DEFAULT.cycleBackwardsMod1, 
	}
	optionsData[#optionsData + 1] = {
		type = "dropdown", 
		name = L(SI_CQT_UI_CYCLE_BACKWARDS_MOD_KEY2_MENU_NAME), 
		tooltip = L(SI_CQT_UI_CYCLE_BACKWARDS_MOD_KEY_MENU_TIPS), 
		choices = modifierKeyChoices, 
		choicesValues = modifierKeyChoicesValues, 
		sort = "value-up", 
		getFunc = function() return self.svCurrent.cycleBackwardsMod2 end, 
		setFunc = function(keyCode)
			self.svCurrent.cycleBackwardsMod2 = keyCode
		end, 
		scrollable = 15, 
		disabled = function() return not self.svCurrent.improveKeybinds end, 
		default = CQT_SV_DEFAULT.cycleBackwardsMod2, 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_HOLD_TO_DISPLAY_QUEST_TOOLTIP_NAME), 
		getFunc = function() return self.svCurrent.holdToShowQuestTooltip end, 
		setFunc = function(newValue)
			self.svCurrent.holdToShowQuestTooltip = newValue
		end, 
		tooltip = L(SI_CQT_UI_HOLD_TO_DISPLAY_QUEST_TOOLTIP_TIPS), 
		width = "full", 
		disabled = function() return not self.svCurrent.improveKeybinds end, 
		default = CQT_SV_DEFAULT.holdToShowQuestTooltip, 
	}
	optionsData[#optionsData + 1] = {
		type = "description", 
		title = "", 
		text = L(SI_CQT_UI_FOCUSED_QUEST_CONTROL_HEADER1_TEXT), 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_AUTO_TRACK_ADDED_QUEST_OP_NAME), 
		getFunc = function() return self.svCurrent.autoTrackToAddedQuest end, 
		setFunc = function(newValue)
			self.svCurrent.autoTrackToAddedQuest = newValue
			self:InitializeFocusedQuestControlTable()
		end, 
		tooltip = L(SI_CQT_UI_AUTO_TRACK_ADDED_QUEST_OP_TIPS), 
		width = "full", 
		default = CQT_SV_DEFAULT.autoTrackToAddedQuest, 
	}
	optionsData[#optionsData + 1] = {
		type = "checkbox",
		name = L(SI_CQT_UI_AUTO_TRACK_PROGRESSED_QUEST_OP_NAME), 
		getFunc = function() return self.svCurrent.autoTrackToProgressedQuest end, 
		setFunc = function(newValue)
			self.svCurrent.autoTrackToProgressedQuest = newValue
			self:InitializeFocusedQuestControlTable()
		end, 
		tooltip = L(SI_CQT_UI_AUTO_TRACK_PROGRESSED_QUEST_OP_TIPS), 
		width = "full", 
		default = CQT_SV_DEFAULT.autoTrackToProgressedQuest, 
	}

	LAM:RegisterOptionControls("CQuestTracker_Options", optionsData)

	local function OnLAMPanelControlsCreated(panel)
		if panel ~= self.settingPanel then return end
		CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", OnLAMPanelControlsCreated)
		self.isSettingPanelInitialized = true
	end
	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", OnLAMPanelControlsCreated)
	CALLBACK_MANAGER:RegisterCallback("LAM-PanelOpened", function(panel)
		if panel ~= self.settingPanel then return end
		self.isSettingPanelShown = true
	end)
	CALLBACK_MANAGER:RegisterCallback("LAM-PanelClosed", function(panel)
		if panel ~= self.settingPanel then return end
		self.isSettingPanelShown = false
	end)
end

function CQT:OpenSettingPanel()
	if self.settingPanel then
		LAM:OpenToPanel(self.settingPanel)
	end
end

function CQT:UpdateSettingPanel()
	if self.isSettingPanelShown then
		if CQT_UI_OptionsPanel_HideQuestTrackerCheckBox then
			CQT_UI_OptionsPanel_HideQuestTrackerCheckBox:UpdateValue()		-- Note : When called with no arguments, getFunc will be called, and setFunc will NOT be called.
		end
		if CQT_UI_OptionsPanel_ShowInCombatCheckBox and CQT_UI_OptionsPanel_ShowInCombatCheckBox.UpdateDisabled then
			CQT_UI_OptionsPanel_ShowInCombatCheckBox:UpdateDisabled()
		end
		if CQT_UI_OptionsPanel_ShowInGameMenuSceneCheckBox and CQT_UI_OptionsPanel_ShowInGameMenuSceneCheckBox.UpdateDisabled then
			CQT_UI_OptionsPanel_ShowInGameMenuSceneCheckBox:UpdateDisabled()
		end
		if CQT_UI_OptionsPanel_HideInBattlegroundCheckBox and CQT_UI_OptionsPanel_HideInBattlegroundCheckBox.UpdateDisabled then
			CQT_UI_OptionsPanel_HideInBattlegroundCheckBox:UpdateDisabled()
		end
	end
end

function CQT:ShowWelcomeMessageDialog()
	ZO_Dialogs_ShowDialog(self.name .. "_WELCOME_MESSAGE")
end


EVENT_MANAGER:RegisterForEvent(CQT.name, EVENT_ADD_ON_LOADED, function(event, addonName)
	if addonName ~= CQT.name then return end
	EVENT_MANAGER:UnregisterForEvent(CQT.name, EVENT_ADD_ON_LOADED)
	CQT:Initialize()
end)


-- ---------------------------------------------------------------------------------------
-- XML Handlers
-- ---------------------------------------------------------------------------------------
function CQT_QuestHeaderTemplate_OnInitialized(control)
	ZO_IconHeader_OnInitialized(control)
	control.status = control:GetNamedChild("StatusIcon")
	control.pinned = control:GetNamedChild("PinnedIcon")
	control.OnMouseUp = CQT_QuestHeader_OnMouseUp
	control.OnMouseEnter = CQT_QuestHeader_OnMouseEnter
	control.OnMouseExit = CQT_QuestHeader_OnMouseExit
--	control.OnMouseDoubleClick = CQT_QuestHeader_OnMouseDoubleClick
end

function CQT_EntryTemplate_OnInitialized(control)
	control.text = control:GetNamedChild("Text")
end

function CQT_QuestConditionTemplate_OnInitialized(control)
	CQT_EntryTemplate_OnInitialized(control)
	control.status = control:GetNamedChild("StatusIcon")
end

-- For when you want to propagate to the parent node control without breaking self out of the args
-- CQT_PropagateHandlerToParentNode("OnMouseUp", ...)
function CQT_PropagateHandlerToParentNode(handlerName, control, ...)
	if control and control.node and control.node:GetParent() then
		local parentNodeControl = control.node:GetParent():GetControl()
		if parentNodeControl and parentNodeControl[handlerName] then
			parentNodeControl[handlerName](parentNodeControl, ...)
		end
	end
end

function CQT_QuestHeader_OnMouseUp(control, button, upInside)
	if upInside then
		if button == MOUSE_BUTTON_INDEX_LEFT then
			if control.enabled and control.node:GetTree():IsEnabled() then
				if select(7, GetJournalQuestInfo(control.journalIndex)) then
					control.node:GetTree().treeNodeOpenStatus[control.questId] = not control.node:IsOpen()
				else
					control.node:GetTree().treeNodeOpenStatus[control.questId] = nil
				end
				control.node:GetTree():ToggleNode(control.node)
				FOCUSED_QUEST_TRACKER:ForceAssist(control.journalIndex)
			end
		elseif button == MOUSE_BUTTON_INDEX_RIGHT then
			ClearMenu()
			if CQT:IsPinnedQuestByIndex(control.journalIndex) then
				AddCustomMenuItem(L(SI_CQT_DISABLE_PINNING_QUEST), function()
					CQT:DisablePinningQuestByIndex(control.journalIndex)
				end)
			else
				AddCustomMenuItem(L(SI_CQT_ENABLE_PINNING_QUEST), function()
					CQT:EnablePinningQuestByIndex(control.journalIndex)
				end)
			end
			if not CQT:IsIgnoredQuestByIndex(control.journalIndex) then
				AddCustomMenuItem(L(SI_CQT_ENABLE_IGNORING_QUEST), function()
					CQT:EnableIgnoringQuestByIndex(control.journalIndex)
				end)
			end
			AddCustomMenuItem(L(SI_QUEST_TRACKER_MENU_SHOW_IN_JOURNAL), function()
				SYSTEMS:GetObject("questJournal"):FocusQuestWithIndex(control.journalIndex)
				SCENE_MANAGER:Show(SYSTEMS:GetObject("questJournal"):GetSceneName())
			end)
			if GetIsQuestSharable(control.journalIndex) and IsUnitGrouped("player") then
				AddCustomMenuItem(L(SI_QUEST_TRACKER_MENU_SHARE), function()
					ShareQuest(control.journalIndex)
				end)
			end
			AddCustomMenuItem(L(SI_QUEST_TRACKER_MENU_SHOW_ON_MAP), function()
				ZO_WorldMap_ShowQuestOnMap(control.journalIndex)
			end)
			if GetJournalQuestType(control.journalIndex) ~= QUEST_TYPE_MAIN_STORY then
				AddCustomMenuItem(L(SI_QUEST_TRACKER_MENU_ABANDON), function()
					AbandonQuest(control.journalIndex)
			 	end)
			end
			ShowMenu(control)
		end
	end
end

function CQT_QuestHeader_OnMouseEnter(control)
	ZO_IconHeader_OnMouseEnter(control)
	control.text:SetDesaturation(-1.5)
	CQT:ShowQuestTooltipNextToOwner(control, control.journalIndex)
end

function CQT_QuestHeader_OnMouseExit(control)
	ZO_IconHeader_OnMouseExit(control)
	control.text:SetDesaturation(0)
	CQT:HideQuestTooltip()
end

function CQT_QuestHeader_OnMouseDoubleClick(control, button)
	if button == MOUSE_BUTTON_INDEX_LEFT then
		CQT:ShowQuestListManagementMenu(control)
	end
end

function CQT_QuestListButton_OnClicked(control, button)
	if button == MOUSE_BUTTON_INDEX_LEFT then
		CQT:ShowQuestListManagementMenu(control)
	end
end
function CQT_SettingButton_OnClicked(control, button)
	if button == MOUSE_BUTTON_INDEX_LEFT then
		CQT:OpenSettingPanel()
	end
end
function CQT_ToggleTrackerPanelVisibility_OnKeybindDown()
	CQT:ToggleTrackerPanelHideSetting()
end

-- ---------------------------------------------------------------------------------------
-- Chat commands
-- ---------------------------------------------------------------------------------------
SLASH_COMMANDS["/cqt.debug"] = function(arg) if arg ~= "" then CQT:ConfigDebug({tonumber(arg)}) end end

