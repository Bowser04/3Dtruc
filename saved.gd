extends Node
const SAVE_FILE_NAME:String = "user://settings.save"
var _settings = {
	"WorldEnvironment":{
		"SSR":{
			"enable":true
		},
		"SSAO":{
			"enable":true
		},
		"SSIL":{
			"enable":true
		},
		"SDFGI":{
			"enable":true
		},
		"Glow":{
			"enable":true
		},
	},
	"Preset":"Ultra",
	"Window_type":0
}
func save_save():
	var file = FileAccess.open(SAVE_FILE_NAME, FileAccess.WRITE)
	file.store_string(JSON.stringify(_settings))
	file.close()

func load_save():
	if FileAccess.file_exists(SAVE_FILE_NAME):
		var file = FileAccess.open(SAVE_FILE_NAME, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			_settings = data
			apply()
		else:
			printerr("Corrupted data!")
	else:
		printerr("No saved data!")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_save()

func set_setting(setting:String,value):
	var current_path = _settings
	for i in range(len(setting.split("/"))-1):
		current_path = current_path[setting.split("/")[i]]
	current_path[setting.split("/")[-1]] = value
	print(setting.split("/")[-1]," = ",current_path[setting.split("/")[-1]])
	apply()
func get_settings(setting:String):
	var current_path = _settings
	for i in range(len(setting.split("/"))-1):
		current_path = current_path[setting.split("/")[i]]
	return current_path[setting.split("/")[-1]]
func set_preset(preset:String):
	if preset == "Ultra":
		set_setting("WorldEnvironment/SSR/enable",true)
		set_setting("WorldEnvironment/SSAO/enable",true)
		set_setting("WorldEnvironment/SSIL/enable",true)
		set_setting("WorldEnvironment/SDFGI/enable",true)
		set_setting("WorldEnvironment/Glow/enable",true)
		set_setting("Preset",preset)
	if preset == "High":
		set_setting("WorldEnvironment/SSR/enable",false)
		set_setting("WorldEnvironment/SSAO/enable",true)
		set_setting("WorldEnvironment/SSIL/enable",true)
		set_setting("WorldEnvironment/SDFGI/enable",false)
		set_setting("WorldEnvironment/Glow/enable",true)
		set_setting("Preset",preset)
	if preset == "Medium":
		set_setting("WorldEnvironment/SSR/enable",false)
		set_setting("WorldEnvironment/SSAO/enable",true)
		set_setting("WorldEnvironment/SSIL/enable",false)
		set_setting("WorldEnvironment/SDFGI/enable",false)
		set_setting("WorldEnvironment/Glow/enable",true)
		set_setting("Preset",preset)
	if preset == "Low":
		set_setting("WorldEnvironment/SSR/enable",false)
		set_setting("WorldEnvironment/SSAO/enable",false)
		set_setting("WorldEnvironment/SSIL/enable",false)
		set_setting("WorldEnvironment/SDFGI/enable",false)
		set_setting("WorldEnvironment/Glow/enable",false)
		set_setting("Preset",preset)

func apply():
	if _settings["Window_type"] == 0:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if _settings["Window_type"] == 1:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	save_save()
	print("settings applied")
