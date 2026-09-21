extends Node
## Provides a gui for us to do dev actions, using [ImGui].


## Determines if the main DevGui window is showing or not.
var dev_gui_enabled := false

# Fps text is yellow if fps > this value, else red.
const MODERATE_FPS_LOWER_LIMIT := 30.0
# Fps text is green if fps > this value, else yellow.
const GOOD_FPS_LOWER_LIMIT := 50.0

var sceneNameList : Array[String] = [ # Make sure to keep sceneUids up to date too
	"Booting",
	"Attract Mode",
	"Gameplay",
]
var sceneUids : Array[String] = [ # Make sure to keep sceneNameList up to date too
	SceneManager.SCENE_BOOTING,
	SceneManager.SCENE_ATTRACT_MODE,
	SceneManager.SCENE_GAMEPLAY,
]
var changeSceneChoice : int = 1
var longestSceneName : int = 0
var transitionNameList : Array[String] = [ # Make sure to keep this synced with the TransitionManager
	"None",
	"Black fade",
	"Fancy doors",
]
var longestTransitionName : int = 0


var _mouse_visibility_before_show := Input.MOUSE_MODE_VISIBLE
var _was_resumed_before_dev_gui := false

var _pause_on_dev_gui := true
var _is_deleting_cfg_file := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dev_gui_enabled = DevConfig.get_dev_gui_config_value(DevConfig.CFGKEY_DEV_GUI_ENABLED)
	_pause_on_dev_gui = DevConfig.get_dev_gui_config_value(DevConfig.CFGKEY_PAUSE_ON_DEV_GUI, _pause_on_dev_gui)
	for sn in sceneNameList:
		if sn.length() > longestSceneName:
			longestSceneName = sn.length()
	for tn in transitionNameList:
		if tn.length() > longestTransitionName:
			longestTransitionName = tn.length()


func _process(delta: float) -> void:
	if not dev_gui_enabled:
		return
	ImGui.Begin("ARCADE GAME DevGui") # Can add a version number
	_imgui_consistent_info(delta)
	ImGui.BeginDisabled(SceneManager.is_changing_scene)
	if ImGui.BeginTabBar("Categories"):
		if ImGui.BeginTabItem("General"):
			_imgui_tab_general()
			ImGui.EndTabItem()
		if ImGui.BeginTabItem("Graphics"):
			_imgui_tab_graphics()
			ImGui.EndTabItem()
		if ImGui.BeginTabItem("DevGui Config"):
			_imgui_tab_devgui_config()
			ImGui.EndTabItem()
		ImGui.EndTabBar()
	ImGui.EndDisabled()
	ImGui.End()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_gui"):
		dev_gui_enabled = !dev_gui_enabled
		DevConfig.set_dev_gui_config_value(DevConfig.CFGKEY_DEV_GUI_ENABLED, dev_gui_enabled)
		if dev_gui_enabled:
			_mouse_visibility_before_show = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_was_resumed_before_dev_gui = not get_tree().paused
			if _pause_on_dev_gui:
				get_tree().paused = true
		else:
			Input.mouse_mode = _mouse_visibility_before_show
			if _pause_on_dev_gui and _was_resumed_before_dev_gui:
				get_tree().paused = false


#region OUTSIDE TABS

func _imgui_consistent_info(delta: float) -> void:
	ImGui.Text("FPS:")
	ImGui.SameLine()
	
	var liveFps := 1.0 / delta
	var fpsColor := Color.GREEN if liveFps > GOOD_FPS_LOWER_LIMIT else (Color.YELLOW if liveFps > MODERATE_FPS_LOWER_LIMIT else Color.RED)
	ImGui.TextColored(fpsColor, "%3d" % roundi(Engine.get_frames_per_second()))
	ImGui.SameLine()
	ImGui.Text('=')
	ImGui.SameLine()
	ImGui.TextColored(fpsColor, "%5.1f ms" % (round(delta * 10000.0) / 10.0))
	ImGui.SameLine()
	
	ImGui.Text("|")
	ImGui.SameLine()
	
	ImGui.Text("<other persistent info>")

#endregion


#region TAB GENERAL

func _imgui_tab_general() -> void:
	ImGui.TextWrapped("This will become a general tab with often-used information and capabilities.")
	
	_imgui_general_credits()
	_imgui_general_scene_changing()


func _imgui_general_credits() -> void:
	var tempArr := []
	ImGui.SeparatorText("Credits and Freeplay")
	
	tempArr = [DevConfig.get_general_value(DevConfig.CFGKEY_FREEPLAY_MODE)]
	if ImGui.Checkbox("Freeplay mode", tempArr):
		var fpMode : bool = tempArr[0]
		CreditManager.set_freeplay_mode(fpMode)
		DevConfig.set_general_value(DevConfig.CFGKEY_FREEPLAY_MODE, fpMode)


func _imgui_general_scene_changing() -> void:
	var tempArr := []
	ImGui.SeparatorText("Scene Management")
	
	if ImGui.Button("Change scene to:"):
		SceneManager.change_scene(sceneUids[changeSceneChoice])
	ImGui.SameLine()
	tempArr = [changeSceneChoice]
	ImGui.SetNextItemWidth(ImGui.GetFontSize() * longestSceneName)
	if ImGui.Combo("Scene name", tempArr, sceneNameList):
		changeSceneChoice = tempArr[0]
	
	tempArr = [TransitionManager.curr_transition_id]
	ImGui.SetNextItemWidth(ImGui.GetFontSize() * longestTransitionName)
	if ImGui.Combo("Transition type", tempArr, transitionNameList):
		TransitionManager.set_queued_transition(tempArr[0])

#endregion


#region TAB GRAPHICS

func _imgui_tab_graphics() -> void:
	#if ImGui.CollapsingHeader("Shaders"):
	ImGui.SeparatorText("Screen Settings")
	_imgui_screen_settings()
	#ImGui.SeparatorText("Shaders")
	#_imgui_graphics_shaders()


func _imgui_screen_settings() -> void:
	var tempArr: Array = []
	
	tempArr = [DisplayServer.window_get_vsync_mode()]
	if ImGui.Checkbox("VSync", tempArr):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if tempArr[0] else DisplayServer.VSYNC_DISABLED)
	if ImGui.IsItemHovered(ImGui.HoveredFlags_DelayNone):
		ImGui.SetTooltip(
			"VSync is %s. Click to change it to %s." %
			[Debug.bool_to_str_enabled(tempArr[0]), Debug.bool_to_str_enabled(!tempArr[0])]
		)


#func _imgui_graphics_shaders() -> void:
	#var tempArr: Array = []
	#
	#tempArr = [DevConfig.get_graphics_value(DevConfig.CFGKEY_OUTLINE)]
	#if ImGui.Checkbox("Outline visibility", tempArr):
		#Debug.graphics_set_outline_shader(tempArr[0])
	#if ImGui.IsItemHovered(ImGui.HoveredFlags_DelayNone):
		#ImGui.SetTooltip("Toggles the outline shader.")

#endregion


#region TAB DEVGUI CONFIG

func _imgui_tab_devgui_config() -> void:
	var tempArr: Array = []
	ImGui.TextWrapped("This will contain settings for DevGui itself.")
	# Examples: pause on DevGui show, free mouse on DevGui show
	
	tempArr = [_pause_on_dev_gui]# [DevConfig.get_dev_gui_config_value(DevConfig.CFGKEY_PAUSE_ON_DEV_GUI)]
	if ImGui.Checkbox("Pause on DevGui", tempArr):
		_pause_on_dev_gui = tempArr[0]
		DevConfig.set_dev_gui_config_value(DevConfig.CFGKEY_PAUSE_ON_DEV_GUI, _pause_on_dev_gui)
		if _pause_on_dev_gui:
			get_tree().paused = true
		elif _was_resumed_before_dev_gui:
			get_tree().paused = false
	if ImGui.IsItemHovered(ImGui.HoveredFlags_DelayNone):
		ImGui.SetTooltip("Determines if the game will get paused when DevGui is opened.")
	
	ImGui.SeparatorText("Verbosity")
	tempArr = [DevConfig.get_dev_gui_config_value(DevConfig.CFGKEY_VERBOSE_CREDIT_MANAGER)]
	if ImGui.Checkbox("CreditManager", tempArr):
		CreditManager.verbose = tempArr[0]
		DevConfig.set_dev_gui_config_value(DevConfig.CFGKEY_VERBOSE_CREDIT_MANAGER, tempArr[0])
	
	ImGui.SeparatorText("Dev config file")
	ImGui.BeginDisabled(not DevConfig.does_config_file_exist())
	ImGui.PushStyleColor(ImGui.Col_Button, Color(0.6, 0.0, 0.0, 1.0))
	ImGui.PushStyleColor(ImGui.Col_ButtonHovered, Color(0.85, 0.136, 0.148, 1.0))
	ImGui.PushStyleColor(ImGui.Col_ButtonActive, Color(0.85, 0.391, 0.399, 1.0))
	if ImGui.Button("Clear config file"):
		_is_deleting_cfg_file = true
	ImGui.PopStyleColorEx(3)
	if _is_deleting_cfg_file:
		ImGui.OpenPopup("Confirm Deletion")
		ImGui.SetNextWindowPos(get_viewport().get_mouse_position(), ImGui.Cond_Appearing)
		# Might be worth putting the below popup code in a dedicated confirmation-popup-creating function
		if ImGui.BeginPopupModal("Confirm Deletion", [], ImGui.WindowFlags_AlwaysAutoResize):
			ImGui.Text("Delete developer config file?")
			ImGui.Text("Currently cached config values will not be affected.")
			ImGui.Separator()
			if ImGui.Button("Confirm"):
				DevConfig.delete_config_file()
				_is_deleting_cfg_file = false
				ImGui.CloseCurrentPopup()
			ImGui.SameLine()
			if ImGui.Button("CANCEL"):
				_is_deleting_cfg_file = false
				ImGui.CloseCurrentPopup()
		ImGui.EndPopup()
	if ImGui.IsItemHovered(ImGui.HoveredFlags_DelayNone):
		ImGui.SetTooltip("Deletes your developer config file.\nPath: %s" % DevConfig.CFG_PATH)
	ImGui.EndDisabled()

#endregion
