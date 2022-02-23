------------------------------------------------
-- CQuestTracker
-- English localization
------------------------------------------------

-- NOTE :
-- The English localization is in 'strings.lua'.
-- Thus the contents of this file can be used as a template for translation into other languages.

--[[

--	Localization Strings
SafeAddString(SI_CQT_WELCOME_TEXT1, 							"Welcome to CQuestTracker add-on !", 1)
SafeAddString(SI_CQT_WELCOME_TEXT2, 							" This quest tracker will automatically update the displayed list and show recent ongoing quests with higher priority.", 1)
SafeAddString(SI_CQT_WELCOME_TEXT3, 							" Initially, only the tracked quest is displayed. If you want to display additional quests immediately, do the following.", 1)
SafeAddString(SI_CQT_WELCOME_TEXT4, 							" Opening the quest list menu from the upper left corner of the tracker window and pick out your favorite quest by left-clicking on the quest name. You can also pin a specific quest to show all the time, or ignore to hide.", 1)
SafeAddString(SI_CQT_TITLEBAR_QUEST_LIST_BUTTON_TIPS, 			"Quest List", 1)
SafeAddString(SI_CQT_TITLEBAR_OPEN_SETTINGS_BUTTON_TIPS, 		"Open settings", 1)
SafeAddString(SI_CQT_QUESTLIST_MENU_HEADER, 					"Quest List: (<<1>>/<<2>>)", 1)
SafeAddString(SI_CQT_ENABLE_PINNING_QUEST, 						"Pin the quest", 1)
SafeAddString(SI_CQT_DISABLE_PINNING_QUEST, 					"Unpin the quest", 1)
SafeAddString(SI_CQT_ENABLE_IGNORING_QUEST, 					"Ignoring the quest", 1)
SafeAddString(SI_CQT_DISABLE_IGNORING_QUEST, 					"Disable ignoring the quest", 1)
SafeAddString(SI_CQT_PICK_OUT_QUEST, 							"Pick out the quest", 1)
SafeAddString(SI_CQT_RULE_OUT_QUEST, 							"Rule out the quest", 1)
SafeAddString(SI_CQT_MOST_LOWER_QUEST, 							"Most lower the quest", 1)

SafeAddString(SI_CQT_QUESTTYPE_ZONE_STORY_QUEST, 				"Zone Story", 1)
SafeAddString(SI_CQT_QUESTTYPE_SIDE_QUEST, 						"Side Quest", 1)
SafeAddString(SI_CQT_QUEST_BACKGROUND_HEADER, 					"Background:", 1)
SafeAddString(SI_CQT_QUEST_OPTIONAL_STEPS_OR_DESCRIPTION, 		"Optional steps - complete one:", 1)
SafeAddString(SI_CQT_QUEST_OBJECTIVES_HEADER, 					"<<C:1[no objectives/objective/objectives]>>:", 1)
SafeAddString(SI_CQT_QUEST_OBJECTIVES_OR_HEADER, 				"<<C:1[no objectives/objective/objectives - complete one]>>:", 1)
SafeAddString(SI_CQT_QUEST_HINT_STEPS_HEADER, 					"<<C:1[no hints/hint/hints]>>:", 1)

SafeAddString(SI_CQT_UI_PANEL_HEADER1_TEXT, 					"This add-on provides a multiple quest tracker that automatically focuses on your most recent quest-related activities.", 1)
SafeAddString(SI_CQT_UI_ACCOUNT_WIDE_OP_NAME, 					"Use Account Wide Settings", 1)
SafeAddString(SI_CQT_UI_ACCOUNT_WIDE_OP_TIPS, 					"When the account wide setting is OFF, then each character can have different configuration options set below.", 1)
SafeAddString(SI_CQT_UI_BEHAVIOR_HEADER1_TEXT, 					"Behavior Options", 1)
SafeAddString(SI_CQT_UI_HIDE_DEFAULT_TRACKER_OP_NAME, 			"Hide Default Quest Tracker", 1)
SafeAddString(SI_CQT_UI_HIDE_DEFAULT_TRACKER_OP_TIPS, 			"Hide Default Quest Tracker", 1)
SafeAddString(SI_CQT_UI_HIDE_QUEST_TRACKER_OP_NAME, 			"Hide This Quest Tracker", 1)
SafeAddString(SI_CQT_UI_HIDE_QUEST_TRACKER_OP_TIPS, 			"Hide This Quest Tracker", 1)
SafeAddString(SI_CQT_UI_SHOW_IN_COMBAT_OP_NAME, 				"Show in Combat Mode", 1)
SafeAddString(SI_CQT_UI_SHOW_IN_COMBAT_OP_TIPS, 				"Show CQuestTracker while in combat mode.", 1)
SafeAddString(SI_CQT_UI_SHOW_IN_GAMEMENU_SCENE_OP_NAME,			"Show in Game Menu Scene", 1)
SafeAddString(SI_CQT_UI_SHOW_IN_GAMEMENU_SCENE_OP_TIPS,			"Show CQuestTracker while in Game Settings menu.", 1)
SafeAddString(SI_CQT_UI_HIDE_IN_BATTLEGROUNDS_OP_NAME,			"Hide in Battlegrounds", 1)
SafeAddString(SI_CQT_UI_HIDE_IN_BATTLEGROUNDS_OP_TIPS,			"Hide CQuestTracker while in Battlegrounds.", 1)
SafeAddString(SI_CQT_UI_PANEL_OPTION_HEADER1_TEXT,				"Panel Options", 1)
SafeAddString(SI_CQT_UI_MAX_NUM_QUEST_DISPLAYED_OP_NAME,		"Max number of quests displayed", 1)
SafeAddString(SI_CQT_UI_MAX_NUM_QUEST_DISPLAYED_OP_TIPS,		"Adjust the maximum number of quests displayed in the tracker panel as needed. The recommended value is 5.", 1)
SafeAddString(SI_CQT_UI_COMPACT_MODE_OP_NAME,					"Compact Mode", 1)
SafeAddString(SI_CQT_UI_COMPACT_MODE_OP_TIPS,					"Turn on Compact Mode to limit the display of quest conditions. Only focused or pinned quests will be displayed, thus reducing the height of the tracker display area.", 1)
SafeAddString(SI_CQT_UI_CLAMPED_TO_SCREEN_OP_NAME,				"Clamped to Screen", 1)
SafeAddString(SI_CQT_UI_CLAMPED_TO_SCREEN_OP_TIPS,				"Turn on Clamped to Screen to prevent the quest tracker from sticking out of the screen.", 1)
SafeAddString(SI_CQT_UI_HIDE_QUEST_HINT_STEP_OP_NAME,			"Hide Quest Hint Steps", 1)
SafeAddString(SI_CQT_UI_HIDE_QUEST_HINT_STEP_OP_TIPS,			"Turn on this option to suppress the display of quest hints, reducing the height of the tracker display area.", 1)
SafeAddString(SI_CQT_UI_TRACKER_VISUAL_HEADER1_TEXT,			"Tracker Visual Options", 1)
SafeAddString(SI_CQT_UI_QUEST_NAME_FONT_SUBHEADER_TEXT, 		"Quest Name Font:", 1)
SafeAddString(SI_CQT_UI_QUEST_CONDITION_FONT_SUBHEADER_TEXT, 	"Quest Condition Font:", 1)
SafeAddString(SI_CQT_UI_COMMON_FONTTYPE_MENU_NAME,  			"|u25:0::|uFont Type", 1)
SafeAddString(SI_CQT_UI_COMMON_FONTSTYLE_MENU_NAME,  			"|u25:0::|uCustom Font Style", 1)
SafeAddString(SI_CQT_UI_COMMON_FONTSIZE_MENU_NAME,  			"|u25:0::|uFont Size", 1)
SafeAddString(SI_CQT_UI_COMMON_FONTWEIGHT_MENU_NAME,  			"|u25:0::|uFont Weight", 1)
SafeAddString(SI_CQT_UI_QUEST_NAME_FONTTYPE_MENU_TIPS,  		"Specify your preferred font type.", 1)
SafeAddString(SI_CQT_UI_QUEST_NAME_FONTSTYLE_MENU_TIPS,  		"Specify your preferred custom font style.", 1)
SafeAddString(SI_CQT_UI_QUEST_NAME_FONTSIZE_MENU_TIPS,  		"Specify your preferred font size.", 1)
SafeAddString(SI_CQT_UI_QUEST_NAME_FONTWEIGHT_MENU_TIPS,  		"Specify your preferred font weight.", 1)
SafeAddString(SI_CQT_UI_QUEST_NAME_NORMAL_COLOR_MENU_NAME,  	"|u25:0::|uQuest Name Color", 1)
SafeAddString(SI_CQT_UI_QUEST_NAME_NORMAL_COLOR_MENU_TIPS,  	"Specify the font color of quest names.", 1)
SafeAddString(SI_CQT_UI_QUEST_NAME_FOCUSED_COLOR_MENU_NAME, 	"|u25:0::|uFocused Quest Name Color", 1)
SafeAddString(SI_CQT_UI_QUEST_NAME_FOCUSED_COLOR_MENU_TIPS, 	"Specify the font color of the focused quest name.", 1)
SafeAddString(SI_CQT_UI_QUEST_CONDITION_FONTTYPE_MENU_TIPS,  	"Specify your preferred font type.", 1)
SafeAddString(SI_CQT_UI_QUEST_CONDITION_FONTSTYLE_MENU_TIPS, 	"Specify your preferred custom font style.", 1)
SafeAddString(SI_CQT_UI_QUEST_CONDITION_FONTSIZE_MENU_TIPS,  	"Specify your preferred font size.", 1)
SafeAddString(SI_CQT_UI_QUEST_CONDITION_FONTWEIGHT_MENU_TIPS, 	"Specify your preferred font weight.", 1)
SafeAddString(SI_CQT_UI_QUEST_CONDITION_COLOR_MENU_NAME, 		"|u25:0::|uQuest Condition/Objective Color", 1)
SafeAddString(SI_CQT_UI_QUEST_CONDITION_COLOR_MENU_TIPS, 		"Specify the font color of quest conditions/objectives.", 1)
SafeAddString(SI_CQT_UI_QUEST_HINT_COLOR_MENU_NAME, 			"|u25:0::|uQuest Hint Color", 1)
SafeAddString(SI_CQT_UI_QUEST_HINT_COLOR_MENU_TIPS, 			"Specify the font color of quest hints.", 1)
SafeAddString(SI_CQT_UI_TITLEBAR_SUBHEADER_TEXT,  				"Title Bar:", 1)
SafeAddString(SI_CQT_UI_TITLEBAR_COLOR_MENU_NAME,  				"|u25:0::|uTitle Bar Color", 1)
SafeAddString(SI_CQT_UI_TITLEBAR_COLOR_MENU_TIPS,  				"Specify your preferred title bar color.", 1)
SafeAddString(SI_CQT_UI_TITLEBAR_OPACITY_MENU_TIPS,  			"Specify your preferred opacity of the title bar color.", 1)
SafeAddString(SI_CQT_UI_BACKGROUND_SUBHEADER_TEXT,  			"Background:", 1)
SafeAddString(SI_CQT_UI_COMMON_BACKGROUND_COLOR_MENU_NAME,  	"|u25:0::|uBackground Color", 1)
SafeAddString(SI_CQT_UI_BACKGROUND_COLOR_MENU_TIPS,  			"Specify your preferred background color of the tracker panel.", 1)
SafeAddString(SI_CQT_UI_BACKGROUND_OPACITY_MENU_TIPS, 			"Specify your preferred opacity of the background color.", 1)

--]]
