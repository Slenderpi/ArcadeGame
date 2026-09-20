extends Node
## Manages/contains info from developer_config.cfg


#region CONFIG FILE STRINGS

## The .cfg file where developer config values are stored.
## The file is stored in your "user" folder,[br]
## which you can open via [b]Project > Open User Data Folder[/b].[br]
## [br]
## You can manually find this folder at the following location:[br]
## Windows: %APPDATA%[br]
## Mac: ~/Library/Application Support/[br]
## Linux: ~/.local/share/
const CFG_PATH := "user://developer_config.cfg"

const SECTION_GENERAL := "general"
const CFGKEY_FREEPLAY_MODE = "freeplay_mode"

const SECTION_GRAPHICS := "graphics"

const SECTION_DEV_GUI_CONFIG := "dev_gui_config"
const CFGKEY_PAUSE_ON_DEV_GUI := "pause_on_dev_gui"
const CFGKEY_DEV_GUI_ENABLED := "dev_gui_enabled"

#endregion


#region CONFIG VALUES
## HOW TO USE:
## For a new config value, add a constant CFGKEY_KEYNAME string into the CONFIG FILE region,
## then put it as a key in a dictionary below.
## Initialize its value to an appropriate default value.
## Then add the dictionary to the `configs` dictionary with the appropriate section string.

## Contains all section configs.
## If you add a new configs dictionary, make sure you add it into [configs] by
## adding a line in [method DevConfig._init_configs_dict]
var configs : Dictionary[String, Dictionary]

var general_config : Dictionary[String, Variant] = {
	CFGKEY_FREEPLAY_MODE: false,
}

## Dictionary of cfg keys and their values, specific to graphics.
var graphics_config : Dictionary[String, Variant] = {
	
}

## Dictionary of cfg keys and their values, specific to dev gui config.
var dev_gui_config_config : Dictionary[String, Variant] = {
	CFGKEY_DEV_GUI_ENABLED: false,
	CFGKEY_PAUSE_ON_DEV_GUI: false,
}

#endregion


#region INITIALIZERS

func _ready() -> void:
	_init_configs_dict()
	_init_config_values()


## Initializes [member DevConfigs.configs] with each section-specific sub-configs dictionary.
## Add a line if you create a new sub-config dictionary.
func _init_configs_dict() -> void:
	configs = {
		SECTION_GENERAL: general_config,
		SECTION_GRAPHICS: graphics_config,
		SECTION_DEV_GUI_CONFIG: dev_gui_config_config,
	}


# Initializes the subdictionaries of configs to their values in the config file, if found.
# Defaults to the default value you set in the initialization of your dictionary.
func _init_config_values() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	for section in configs:
		var currConfig : Dictionary[String, Variant] = configs[section]
		for key in currConfig:
			currConfig[key] = cfg.get_value(section, key, currConfig[key])

#endregion


#region GET VALUE

## Shorthand for [method DevConfig.get_value],
## where [code]section[/code] is given [member DevConfig.SECTION_GENERAL].
func get_general_value(cfgKey: String, default: Variant = null) -> Variant:
	return get_value(SECTION_GENERAL, cfgKey, default)


## Shorthand for [method DevConfig.get_value],
## where [code]section[/code] is given [member DevConfig.SECTION_GRAPHICS].
func get_graphics_value(cfgKey: String, default: Variant = null) -> Variant:
	return get_value(SECTION_GRAPHICS, cfgKey, default)


## Shorthand for [method DevConfig.get_value],
## where [code]section[/code] is given [member DevConfig.SECTION_DEV_GUI_CONFIG].
func get_dev_gui_config_value(cfgKey: String, default: Variant = null) -> Variant:
	return get_value(SECTION_DEV_GUI_CONFIG, cfgKey, default)


## Get a value from [member DevConfigs.configs].
## If the value cannot be found, the config file [member DevConfig.CFG_PATH]
## is searched instead.
func get_value(section: String, cfgKey: String, default: Variant = null) -> Variant:
	# Try finding it in configs
	if configs.has(section):
		var currCfg := configs[section]
		if currCfg.has(cfgKey):
			return currCfg[cfgKey]
	
	# Fallback to searching the config file
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	return cfg.get_value(section, cfgKey, default)

#endregion


#region SET VALUE

## Shorthand for [method DevConfig.get_value],
## where [member DevConfig.SECTION_GENERAL] is the section parameter.
func set_general_value(cfgKey: String, value: Variant) -> Error:
	return set_value(SECTION_GENERAL, cfgKey, value)


## Shorthand for [method DevConfig.get_value],
## where [member DevConfig.SECTION_GRAPHICS] is the section parameter.
func set_graphics_value(cfgKey: String, value: Variant) -> Error:
	return set_value(SECTION_GRAPHICS, cfgKey, value)


## Shorthand for [method DevConfig.get_value],
## where [member DevConfig.SECTION_DEV_GUI_CONFIG] is the section parameter.
func set_dev_gui_config_value(cfgKey: String, value: Variant) -> Error:
	return set_value(SECTION_DEV_GUI_CONFIG, cfgKey, value)


## Set a value and save it to [member DevConfig.CFG_PATH].
func set_value(section: String, cfgKey: String, value: Variant) -> Error:
	configs[section][cfgKey] = value
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	cfg.set_value(section, cfgKey, value)
	var err := cfg.save(CFG_PATH)
	if err != OK:
		printerr("[DevConfig] Failed to save config file \"%s\" with error code %d." % [CFG_PATH, err])
	return err

#endregion


#region MISC CONFIG FUNCTIONS


## Deletes the config file [member DevConfig.CFG_PATH].[br]
## [br]
## The cached [member DevConfig.configs] dictionaries are not affected by this method.
func delete_config_file() -> void:
	if does_config_file_exist():
		var err := DirAccess.remove_absolute(CFG_PATH)
		if err == OK:
			print("[DevConfig] Your developer config file has successfully been deleted.")
		else:
			printerr("[DevConfig] Unable to delete config file! Error code: %d" % err)
	else:
		print("[DevConfig] The config file does not exist.")


## Use this to check if the dev config file located at [member DevConfig.CFG_PATH]
## exists.
func does_config_file_exist() -> bool:
	return FileAccess.file_exists(CFG_PATH)
