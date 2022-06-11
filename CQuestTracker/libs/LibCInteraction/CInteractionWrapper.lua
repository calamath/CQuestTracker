--
-- CInteractionWrapper [CIW] : (LibCInteraction)
--
-- Copyright (c) 2022 Calamath
--
-- This software is released under the Artistic License 2.0
-- https://opensource.org/licenses/Artistic-2.0
--

if LibCInteraction then return end

-- ---------------------------------------------------------------------------------------
-- Name Space
-- ---------------------------------------------------------------------------------------
local CInteractionWrapper = {
	name = "LibCInteraction", 
	version = "0.9.0", 
	author = "Calamath", 
	authority = {2973583419,210970542}, 
	external = {}, 
	supportedModifierKeys = {
		[KEY_CTRL] = function() return IsControlKeyDown() end, 
		[KEY_ALT] = function() return IsAltKeyDown() end, 
		[KEY_SHIFT] = function() return IsShiftKeyDown() end, 
		[KEY_COMMAND] = function() return IsCommandKeyDown() end, 
		[KEY_GAMEPAD_LEFT_TRIGGER] = function() return GetGamepadLeftTriggerMagnitude() > 0.2 end, 
		[KEY_GAMEPAD_RIGHT_TRIGGER] = function() return GetGamepadRightTriggerMagnitude() > 0.2 end, 
	}, 
}
local CIW = CInteractionWrapper
LibCInteraction = CIW.external
LibCInteraction.name = CIW.name
LibCInteraction.version = CIW.version
LibCInteraction.author = CIW.author

-- ---------------------------------------------------------------------------------------
-- Interaction Wrapper Base Class
-- ---------------------------------------------------------------------------------------
local CBaseInteractionWrapper = ZO_InitializingObject:Subclass()
function CBaseInteractionWrapper:Initialize(control, actionName, data)
	self.control = control
	if self.control then
		self.control:SetHidden(true)	-- disable timer
	end
	self.interactionType = "base"
	self.actionName = actionName
	self:SetKeyDownCallback(data.keyDownCallback)
	self:SetKeyUpCallback(data.keyUpCallback)
	self:SetStartedCallback(data.startedCallback)
	self:SetPerformedCallback(data.performedCallback)
	self:SetCanceledCallback(data.canceledCallback)
	self:SetEndedCallback(data.endedCallback)
	self:SetEnabled(data.enabled or (data.enabled == nil))
	self.multipleInput = data.multipleInput
	self.duration = 0

	self.currentAction = nil
	self.isStarted = false
	self.isPerformed = false
	self.startTime = nil
	self.endTime = nil
	self.targetTime = nil
end
function CBaseInteractionWrapper:GetValue(value, ...)
	if type(value) == "function" then
		return value(...)
	else
		return value
	end
end
function CBaseInteractionWrapper:GetCurrentActionName()
	return self.currentAction
end
function CBaseInteractionWrapper:GetHoldTime()
	if self.startTime then
		local endTime = self.endTime or GetFrameTimeMilliseconds()
		return endTime - self.startTime
	else
		return 0
	end
end
function CBaseInteractionWrapper:SetKeyDownCallback(callback)
	self.keyDownCallback = callback
end
function CBaseInteractionWrapper:SetKeyUpCallback(callback)
	self.keyUpCallback = callback
end
function CBaseInteractionWrapper:SetStartedCallback(callback)
	self.startedCallback = callback
end
function CBaseInteractionWrapper:SetPerformedCallback(callback)
	self.performedCallback = callback
end
function CBaseInteractionWrapper:SetCanceledCallback(callback)
	self.canceledCallback = callback
end
function CBaseInteractionWrapper:SetEndedCallback(callback)
	self.endedCallback = callback
end
function CBaseInteractionWrapper:SetEnabled(enabled)
	self.enabled = enabled
end
function CBaseInteractionWrapper:EnableTimer()
	if self.control then
		self.control:SetHidden(false)
	end
end
function CBaseInteractionWrapper:DisableTimer()
	if self.control then
		self.control:SetHidden(true)
	end
end
function CBaseInteractionWrapper:IsModifierKeyDown(keyCode)
	return CIW.supportedModifierKeys[keyCode] and CIW.supportedModifierKeys[keyCode]() or false
end
function CBaseInteractionWrapper:Reset()
-- Should be Overridden
	self:DisableTimer()
	self.currentAction = nil
	self.isStarted = false
	self.isPerformed = false
	self.startTime = nil
	self.endTime = nil
	self.targetTime = nil
end
function CBaseInteractionWrapper:OnKeyDown(actionName, ...)
--  Should be Overridden
end
function CBaseInteractionWrapper:PrerequisiteForStarting(actionName, ...)
--  Should be Overridden
end
function CBaseInteractionWrapper:OnStarted(actionName, ...)
--  Should be Overridden
end
function CBaseInteractionWrapper:OnKeyUp(actionName, ...)
--  Should be Overridden
end
function CBaseInteractionWrapper:PrerequisiteForEnding(actionName, ...)
--  Should be Overridden
end
function CBaseInteractionWrapper:OnEnded(actionName, ...)
--  Should be Overridden
end
function CBaseInteractionWrapper:OnUpdate()
--  Should be Overridden
end


-- ---------------------------------------------------------------------------------------
-- Default Interaction Wrapper Class
-- ---------------------------------------------------------------------------------------
local CDefaultInteractionWrapper = CBaseInteractionWrapper:Subclass()
function CDefaultInteractionWrapper:Initialize(control, actionName, data)
	CBaseInteractionWrapper.Initialize(self, control, actionName, data)
	self.interactionType = "default"
end
function CDefaultInteractionWrapper:OnKeyDown(actionName, ...)
	if self.keyDownCallback then
		self.keyDownCallback(self, ...)
	end
	if self:PrerequisiteForStarting(actionName, ...) then
		self.isStarted = true
		self.currentAction = actionName
		self.startTime = GetFrameTimeMilliseconds()
		self:OnStarted(actionName, ...)
	end
end
function CDefaultInteractionWrapper:PrerequisiteForStarting()
	return not self.isStarted and self:GetValue(self.enabled)
end
function CDefaultInteractionWrapper:OnStarted(actionName, ...)
	if self.startedCallback then
		self.startedCallback(self, ...)
	end
end
function CDefaultInteractionWrapper:OnKeyUp(actionName, ...)
	if self.keyUpCallback then
		self.keyUpCallback(self, ...)
	end
	if self:PrerequisiteForEnding(actionName, ...) then
		self.endTime = GetFrameTimeMilliseconds()
		self:OnEnded(actionName, ...)
		self:Reset()
	end
end
function CDefaultInteractionWrapper:PrerequisiteForEnding()
	return self.isStarted
end
function CDefaultInteractionWrapper:OnEnded(actionName, ...)
	if self.endedCallback then
		self.endedCallback(self, ...)
	end
end


-- ---------------------------------------------------------------------------------------
-- Press Interaction Wrapper Class
-- ---------------------------------------------------------------------------------------
local CPressInteractionWrapper = CDefaultInteractionWrapper:Subclass()
function CPressInteractionWrapper:Initialize(control, actionName, data)
	CDefaultInteractionWrapper.Initialize(self, control, actionName, data)
	self.interactionType = "press"
end
function CPressInteractionWrapper:PrerequisiteForEnding(actionName)
	return self.isStarted and not (self.multipleInput and self.currentAction ~= actionName)
end


-- ---------------------------------------------------------------------------------------
-- Hold Interaction Wrapper Class
-- ---------------------------------------------------------------------------------------
local CHoldInteractionWrapper = CDefaultInteractionWrapper:Subclass()
function CHoldInteractionWrapper:Initialize(control, actionName, data)
	CDefaultInteractionWrapper.Initialize(self, control, actionName, data)
	self.interactionType = "hold"
	self.duration = data.holdTime or 200
	self.control:SetHandler("OnUpdate", function(control, time)
		self:OnUpdate(control, time)
	end)
end
function CHoldInteractionWrapper:PrerequisiteForStarting()
	return not self.isPerformed and not self.isStarted and self:GetValue(self.enabled)
end
function CHoldInteractionWrapper:OnStarted(actionName, ...)
	self.targetTime = self.startTime + self:GetValue(self.duration)
	self:EnableTimer()
	CDefaultInteractionWrapper.OnStarted(self, actionName, ...)
end
function CHoldInteractionWrapper:PrerequisiteForEnding(actionName)
	return self.isStarted and not (self.multipleInput and self.currentAction ~= actionName)
end
function CHoldInteractionWrapper:OnEnded(actionName, ...)
	if self.isPerformed then
		CDefaultInteractionWrapper.OnEnded(self, actionName, ...)
	else
		if self.canceledCallback then
			self.canceledCallback(self, ...)
		end
	end
end
function CHoldInteractionWrapper:OnUpdate()
--	d(GetFrameTimeMilliseconds())	-- debug
	if self.targetTime and GetFrameTimeMilliseconds() > self.targetTime then
		self.targetTime = nil
		if not self.isPerformed then
			self.isPerformed = true
			if self.performedCallback then
				self.performedCallback(self)
			end
		end
	end
end


-- ---------------------------------------------------------------------------------------
-- Interaction Wrapper Manager Class
-- ---------------------------------------------------------------------------------------
local CInteractionWrapperManager_Singleton = ZO_InitializingObject:Subclass()

function CInteractionWrapperManager_Singleton:Initialize()
	self.name = "CIWManagerSingleton"
	self.control = WINDOW_MANAGER:CreateControl("CIW_UI_Root", GuiRoot, CT_CONTROL)
	self.supportedModifierKeys = CIW.supportedModifierKeys
	self.timers = {}
	self.interactions = {}
	self.timerPool = ZO_ControlPool:New("CIW_InteractionTimer", self.control)
	self.timerPool:SetCustomResetBehavior(function(control)
		control:SetParent(self.control)
		control:ClearAnchors()
		control:SetHidden(true)
		control:SetHandler("OnUpdate", nil)
	end)
	self.wrapperClass = {}
	self.timerRequired = {}

	self.LDL = {
		Verbose = function() end, 
		Debug = function() end, 
		Info = function() end, 
		Warn = function() end, 
		Error = function() end, 
	}

	self:RegisterWrapperClass("base", CBaseInteractionWrapper, false)
	self:RegisterWrapperClass("default", CDefaultInteractionWrapper, false)
	self:RegisterWrapperClass("press", CPressInteractionWrapper, false)
	self:RegisterWrapperClass("hold", CHoldInteractionWrapper, true)
end

function CInteractionWrapperManager_Singleton:RegisterWrapperClass(interactionType, class, timerRequired)
	if not self.wrapperClass[interactionType] then
		self.wrapperClass[interactionType] = class or CBaseInteractionWrapper
		self.timerRequired[interactionType] = timerRequired or false
	end
end

function CInteractionWrapperManager_Singleton:GetSupportedModifierKeys()
	local t = {}
	for keyCode in pairs(self.supportedModifierKeys) do
		table.insert(t, keyCode)
	end
	return t
end

function CInteractionWrapperManager_Singleton:IsSupportedModifierKey(keyCode)
	return self.supportedModifierKeys[keyCode] ~= nil
end

function CInteractionWrapperManager_Singleton:AcquireTimer()
	local timer, key = self.timerPool:AcquireObject()
	timer.key = key
	self.timers[key] = timer
	return timer
end

function CInteractionWrapperManager_Singleton:RemoveTimer(key)
	if self.timers[key] then
		self.timerPool:ReleaseObject(self.timers[key])
		self.timers[key] = nil
	end
end

function CInteractionWrapperManager_Singleton:RegisterInteraction(actionName, data)
	if not actionName then return end
	if type(data) ~= "table" then return end
	local interactionType = data.type
	if not self.wrapperClass[interactionType] then return end

	local timerControl = self.timerRequired[interactionType] and self:AcquireTimer()
	local interaction = self.wrapperClass[interactionType]:New(timerControl, actionName, data)

	if type(actionName) == "table" then
		for _, action in pairs(actionName) do
			if not self.interactions[action] then
				self.interactions[action] = {}
			end
			table.insert(self.interactions[action], interaction)
		end
	else
		if not self.interactions[actionName] then
			self.interactions[actionName] = {}
		end
		table.insert(self.interactions[actionName], interaction)
	end
	return interaction
end

function CInteractionWrapperManager_Singleton:HandleKeybindDown(actionName, ...)
	if self.interactions[actionName] then
		for _, interaction in ipairs(self.interactions[actionName]) do
			interaction:OnKeyDown(actionName, ...)
		end
	end
end

function CInteractionWrapperManager_Singleton:HandleKeybindUp(actionName, ...)
	if self.interactions[actionName] then
		for _, interaction in ipairs(self.interactions[actionName]) do
			interaction:OnKeyUp(actionName, ...)
		end
	end
end


-- ---------------------------------------------------------------------------------------
-- CInteractionWrapper
-- ---------------------------------------------------------------------------------------
function CIW:Initialize()
	self:ConfigDebug()
	self.internal = CInteractionWrapperManager_Singleton:New()	-- Never do this more than once!
	self.internal.LDL = self.LDL
	self:RegisterAPI()
end

function CIW:ConfigDebug(arg)
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
	if self.shared then
		self.shared.LDL = self.LDL
	end
end

function CIW:RegisterAPI()
--
-- ---- LibCInteraction API
--
-- * LibCInteraction:GetSupportedModifierKeys()
-- ** _Returns:_ *table* _keyCodeList_
	CIW.external.GetSupportedModifierKeys = function(LCI)
		return CIW.internal:GetSupportedModifierKeys()
	end

-- * LibCInteraction:IsSupportedModifierKey(*[KeyCode|#KeyCode]* _keyCode_)
-- ** _Returns:_ *bool* _isSupported_
	CIW.external.IsSupportedModifierKey = function(LCI, keyCode)
		return CIW.internal:IsSupportedModifierKey(keyCode)
	end

-- * LibCInteraction:RegisterInteraction(*string* _actionName_. *table* _interactionDataTable_)
-- ** _Returns:_ *object:nilable* _interactionWrapperObject_
	CIW.external.RegisterInteraction = function(LCI, actionName, data)
		return CIW.internal:RegisterInteraction(actionName, data)
	end

-- * LibCInteraction:HandleKeybindDown(*string* _actionName_)
	CIW.external.HandleKeybindDown = function(LCI, actionName, ...)
		return CIW.internal:HandleKeybindDown(actionName, ...)
	end

-- * LibCInteraction:HandleKeybindUp(*string* _actionName_)
	CIW.external.HandleKeybindUp = function(LCI, actionName, ...)
		return CIW.internal:HandleKeybindUp(actionName, ...)
	end
end

EVENT_MANAGER:RegisterForEvent(CIW.name, EVENT_ADD_ON_LOADED, function(_, addonName)
	if addonName ~= CIW.name then return end
	EVENT_MANAGER:UnregisterForEvent(CIW.name, EVENT_ADD_ON_LOADED)
	CIW:Initialize()
end)
