extends Control
@export var Window_type:OptionButton
@export var GraphicPreset:OptionButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Window_type.item_selected.connect(_on_Window_type_changed)
	GraphicPreset.item_selected.connect(_on_Graphic_preset_changed)
	select_item_from_text(GraphicPreset,Saved.get_settings("Preset"))
	Window_type.select(Saved.get_settings("Window_type"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func select_item_from_text(ob: OptionButton, item_text: String) -> void:
	for i in ob.get_item_count():
		if ob.get_item_text(i) == item_text:
			ob.select(i)
			break
func _on_Window_type_changed(idx):
	Saved.set_setting("Window_type",idx)
func _on_Graphic_preset_changed(idx):
	if idx == 0:
		Saved.set_preset("Ultra")
	if idx == 1:
		Saved.set_preset("High")
	if idx == 2:
		Saved.set_preset("Medium")
	if idx == 3:
		Saved.set_preset("Low")


func _on_back_pressed() -> void:
	self.hide()
	get_tree().root.get_node("/root/Menu").show()
	queue_free()
