--
-- Calamath's Quest Tracker [CQT]
--
-- Copyright (c) 2022 Calamath
--
-- This software is released under the Artistic License 2.0
-- https://opensource.org/licenses/Artistic-2.0
--

if not CQuestTracker then return end
local CQT = CQuestTracker:SetSharedEnvironment()
-- ---------------------------------------------------------------------------------------
local L = GetString

-- ---------------------------------------------------------------------------------------
-- Tracker Panel Class
-- ---------------------------------------------------------------------------------------
local CQT_TrackerPanel = CT_AdjustableInitializingObject:Subclass()
function CQT_TrackerPanel:Initialize(control, overriddenAttrib)
	self._attrib = {
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
	CT_AdjustableInitializingObject.Initialize(self, overriddenAttrib)
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
--	self.titlebarFragment = ZO_SimpleSceneFragment:New(self.titlebar)
	self.titlebarFragment = ZO_HUDFadeSceneFragment:New(self.titlebar)
	self.titlebarFragment:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_HIDING then
			self:HidePanelFrame()
		end
	end)
	self:SetupPanelVisual()
	self:HidePanelFrame()
	self:InitializeTree()
	self:ResetAnchorPosition()
	CQT:RegisterCallback("TrackerPanelAttributeSettingsChanged", function(key)
		self:SetupPanelVisual()
		self:RefreshTree()
	end)
	CQT:RegisterCallback("TrackerPanelQuestListUpdated", function(questList)
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

function CQT_TrackerPanel:ClearAllTreeNodeOpenStatus()
	ZO_ClearTable(self.trackerTree.treeNodeOpenStatus)
end

function CQT_TrackerPanel:GetTreeNodeOpenStatus(questId)
	return self.trackerTree.treeNodeOpenStatus[questId]
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
		local userRequestedOpen = self:GetTreeNodeOpenStatus(questInfo.questId)
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

CQuestTracker:RegisterClassObject("CQT_TrackerPanel", CQT_TrackerPanel)
