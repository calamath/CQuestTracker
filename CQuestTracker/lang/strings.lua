local L = GetString
local strings = {
	SI_CQT_QUEST_LIST_NORMAL_FORMATTER =			"|t75%:75%:EsoUI/Art/Icons/heraldrycrests_misc_blank_01|t <<1>>", 
	SI_CQT_QUEST_LIST_CHECKED_FORMATTER =			"|c00FF00|t75%:75%:EsoUI/Art/Miscellaneous/check_icon_32.dds:inheritcolor|t|r <<1>>", 
	SI_CQT_QUEST_LIST_PINNED_FORMATTER =			"|cFFD040|t75%:75%:EsoUI/Art/Miscellaneous/status_locked.dds:inheritcolor|t|r <<1>>", 
	SI_CQT_QUEST_LIST_IGNORED_FORMATTER =			"|cFF0000|t75%:75%:Esoui/Art/Castbar/forbiddenaction.dds:inheritcolor|t|r <<1>>", 
	SI_CQT_QUEST_REPEATABLE_TEXT =					L(SI_QUEST_JOURNAL_REPEATABLE_TEXT).."|t16:16:EsoUI/Art/Journal/journal_Quest_Repeat.dds|t", 

--	Localization Strings
	SI_CQT_WELCOME_TEXT1 =							"Welcome to CQuestTracker add-on !", 
	SI_CQT_WELCOME_TEXT2 =							" This quest tracker will automatically update the displayed list and show recent ongoing quests with higher priority.", 
	SI_CQT_WELCOME_TEXT3 =							" Initially, only the tracked quest is displayed. If you want to display additional quests immediately, do the following.", 
	SI_CQT_WELCOME_TEXT4 =							" Opening the quest list menu from the upper left corner of the tracker window and pick out your favorite quest by left-clicking on the quest name. You can also pin a specific quest to show all the time, or ignore to hide.", 
	SI_CQT_TITLEBAR_QUEST_LIST_BUTTON_TIPS =		"Quest List", 
	SI_CQT_TITLEBAR_OPEN_SETTINGS_BUTTON_TIPS =		"Open settings", 
	
	SI_CQT_QUESTLIST_MENU_HEADER =					"Quest List: (<<1>>/<<2>>)", 
	SI_CQT_ENABLE_PINNING_QUEST =					"Pin the quest", 
	SI_CQT_DISABLE_PINNING_QUEST =					"Unpin the quest", 
	SI_CQT_ENABLE_IGNORING_QUEST =					"Ignoring the quest", 
	SI_CQT_DISABLE_IGNORING_QUEST =					"Disable ignoring the quest", 
	SI_CQT_PICK_OUT_QUEST =							"Pick out the quest", 
	SI_CQT_RULE_OUT_QUEST =							"Rule out the quest", 
	SI_CQT_MOST_LOWER_QUEST =						"Most lower the quest", 

	SI_CQT_QUESTTYPE_ZONE_STORY_QUEST =				"Zone Story", 
	SI_CQT_QUESTTYPE_SIDE_QUEST =					"Side Quest", 
	SI_CQT_QUEST_BACKGROUND_HEADER =				"Background:", 
	SI_CQT_QUEST_OR_DESCRIPTION =					L(SI_QUEST_OR_DESCRIPTION), -- "Complete one:"	[No translation necessary]
	SI_CQT_QUEST_OPTIONAL_STEPS_DESCRIPTION =		L(SI_QUEST_OPTIONAL_STEPS_DESCRIPTION), -- "Optional Steps:"	[No translation necessary]
	SI_CQT_QUEST_OPTIONAL_STEPS_OR_DESCRIPTION =	"Optional steps - complete one:", 
	SI_CQT_QUEST_OBJECTIVES_HEADER =				"<<C:1[no objectives/objective/objectives]>>:", 
	SI_CQT_QUEST_OBJECTIVES_OR_HEADER =				"<<C:1[no objectives/objective/objectives - complete one]>>:", 
	SI_CQT_QUEST_HINT_STEPS_HEADER =				"<<C:1[no hints/hint/hints]>>:", 

	SI_CQT_UI_PANEL_HEADER1_TEXT =					"This add-on provides a multiple quest tracker that automatically focuses on your most recent quest-related activities.", 
	SI_CQT_UI_ACCOUNT_WIDE_OP_NAME =				"Use Account Wide Settings", 
	SI_CQT_UI_ACCOUNT_WIDE_OP_TIPS =				"When the account wide setting is OFF, then each character can have different configuration options set below.", 
	SI_CQT_UI_BEHAVIOR_HEADER1_TEXT =				"Behavior Options", 
	SI_CQT_UI_HIDE_DEFAULT_TRACKER_OP_NAME =		"Hide Default Quest Tracker", 
	SI_CQT_UI_HIDE_DEFAULT_TRACKER_OP_TIPS =		"Hide Default Quest Tracker", 
	SI_CQT_UI_HIDE_QUEST_TRACKER_OP_NAME =			"Hide This Quest Tracker", 
	SI_CQT_UI_HIDE_QUEST_TRACKER_OP_TIPS =			"Hide This Quest Tracker", 
	SI_CQT_UI_SHOW_IN_COMBAT_OP_NAME =				"Show in Combat Mode", 
	SI_CQT_UI_SHOW_IN_COMBAT_OP_TIPS =				"Show CQuestTracker while in combat mode.", 
	SI_CQT_UI_SHOW_IN_GAMEMENU_SCENE_OP_NAME =		"Show in Game Menu Scene", 
	SI_CQT_UI_SHOW_IN_GAMEMENU_SCENE_OP_TIPS =		"Show CQuestTracker while in Game Settings menu.", 
	SI_CQT_UI_HIDE_IN_BATTLEGROUNDS_OP_NAME =		"Hide in Battlegrounds", 
	SI_CQT_UI_HIDE_IN_BATTLEGROUNDS_OP_TIPS =		"Hide CQuestTracker while in Battlegrounds.", 
	SI_CQT_UI_TRACKER_VISUAL_HEADER1_TEXT =			"Tracker Visual Options", 
	SI_CQT_UI_QUEST_NAME_FONT_SUBHEADER_TEXT =		"Quest Name Font:", 
	SI_CQT_UI_QUEST_CONDITION_FONT_SUBHEADER_TEXT =	"Quest Condition Font:", 
	SI_CQT_UI_COMMON_FONTTYPE_MENU_NAME = 			"|u25:0::|uFont Type", 
	SI_CQT_UI_COMMON_FONTSIZE_MENU_NAME = 			"|u25:0::|uFont Size", 
	SI_CQT_UI_COMMON_FONTWEIGHT_MENU_NAME = 		"|u25:0::|uFont Weight", 
	SI_CQT_UI_QUEST_NAME_FONTTYPE_MENU_TIPS = 		"Specify your preferred font type.", 
	SI_CQT_UI_QUEST_NAME_FONTSIZE_MENU_TIPS = 		"Specify your preferred font size.", 
	SI_CQT_UI_QUEST_NAME_FONTWEIGHT_MENU_TIPS = 	"Specify your preferred font weight.", 
	SI_CQT_UI_QUEST_CONDITION_FONTTYPE_MENU_TIPS = 	"Specify your preferred font type.", 
	SI_CQT_UI_QUEST_CONDITION_FONTSIZE_MENU_TIPS = 	"Specify your preferred font size.", 
	SI_CQT_UI_QUEST_CONDITION_FONTWEIGHT_MENU_TIPS = "Specify your preferred font weight.", 
	SI_CQT_UI_BACKGROUND_SUBHEADER_TEXT =			"Background:", 
	SI_CQT_UI_COMMON_BACKGROUND_COLOR_MENU_NAME =	"|u25:0::|uBackground Color", 
	SI_CQT_UI_COMMON_OPACITY_MENU_NAME =			"|u25:0::|u" .. L(SI_COLOR_PICKER_ALPHA), 	-- "|u25:0::|uOpacity"	[No translation necessary]
	SI_CQT_UI_BACKGROUND_COLOR_MENU_TIPS =			"Specify your preferred background color of the tracker panel.", 
	SI_CQT_UI_BACKGROUND_OPACITY_MENU_TIPS =		"Specify your preferred opacity of the background color.", 
}

for stringId, stringToAdd in pairs(strings) do
   ZO_CreateStringId(stringId, stringToAdd)
   SafeAddVersion(stringId, 1)
end
