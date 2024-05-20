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
-- Shared Utilities
-- ---------------------------------------------------------------------------------------
local zoneDisplayTypeIconTexture = {
	[ZONE_DISPLAY_TYPE_NONE]			= nil, 
	[ZONE_DISPLAY_TYPE_SOLO]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_instance.dds", 
	[ZONE_DISPLAY_TYPE_DUNGEON]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_groupDungeon.dds", 
	[ZONE_DISPLAY_TYPE_RAID]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_raid.dds", 
	[ZONE_DISPLAY_TYPE_GROUP_DELVE]		= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_groupDelve.dds", 
	[ZONE_DISPLAY_TYPE_GROUP_AREA]		= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_groupArea.dds", 
	[ZONE_DISPLAY_TYPE_PUBLIC_DUNGEON]	= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_dungeon.dds", 
	[ZONE_DISPLAY_TYPE_DELVE]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_delve.dds", 
	[ZONE_DISPLAY_TYPE_HOUSING]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_housing.dds", 
	[ZONE_DISPLAY_TYPE_BATTLEGROUND]	= "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_tabicon_battlegrounds.dds", 
	[ZONE_DISPLAY_TYPE_ZONE_STORY]		= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_zoneStory.dds", 
	[ZONE_DISPLAY_TYPE_COMPANION]		= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_companion.dds", 
	[ZONE_DISPLAY_TYPE_ENDLESS_DUNGEON]	= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_endlessDungeon.dds", 
}
local function GetZoneDisplayTypeIcon(zoneDisplayType)
	return zoneDisplayTypeIconTexture[zoneDisplayType]
end
CQT:RegisterSharedObject("GetZoneDisplayTypeIcon", GetZoneDisplayTypeIcon)

local questTypeIconTexture = {
	[QUEST_TYPE_NONE]				= nil, 
	[QUEST_TYPE_GROUP]				= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_group.dds", 
	[QUEST_TYPE_MAIN_STORY]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_mainStory.dds", 
	[QUEST_TYPE_GUILD]				= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_guild.dds", 
	[QUEST_TYPE_CRAFTING]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_crafting.dds", 
	[QUEST_TYPE_DUNGEON]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_dungeon.dds", 
	[QUEST_TYPE_RAID]				= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_raid.dds", 
	[QUEST_TYPE_AVA]				= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_ava.dds", 
	[QUEST_TYPE_CLASS]				= nil, 
	[QUEST_TYPE_QA_TEST]			= nil, 
	[QUEST_TYPE_AVA_GROUP]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_avagroup.dds", 
	[QUEST_TYPE_AVA_GRAND]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_avagroup.dds", 
	[QUEST_TYPE_HOLIDAY_EVENT]		= "EsoUI/Art/TreeIcons/Gamepad/achievement_categoryicon_events.dds", 
	[QUEST_TYPE_BATTLEGROUND]		= "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_tabicon_battlegrounds.dds", 
	[QUEST_TYPE_PROLOGUE]			= "EsoUI/Art/TreeIcons/Gamepad/achievement_categoryicon_prologue.dds", 
	[QUEST_TYPE_UNDAUNTED_PLEDGE]	= "EsoUI/Art/Icons/ServiceMapPins/servicepin_undaunted.dds", 
	[QUEST_TYPE_COMPANION]			= "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_companion.dds", 
	[QUEST_TYPE_TRIBUTE]			= "EsoUI/Art/Tribute/Gamepad/gp_tribute_tabicon_tribute.dds", 
	[QUEST_TYPE_SCRIBING]			= "EsoUI/Art/TreeIcons/Gamepad/gp_tutorial_indexicon_scribing.dds", 
}
local function GetQuestTypeIcon(questType)
	return questTypeIconTexture[questType]
end
CQT:RegisterSharedObject("GetQuestTypeIcon", GetQuestTypeIcon)

