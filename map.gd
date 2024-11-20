extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	$WorldEnvironment.environment.set("ssr_enabled",Saved.get_settings("WorldEnvironment/SSR/enable"))
	$WorldEnvironment.environment.set("ssao_enabled",Saved.get_settings("WorldEnvironment/SSAO/enable"))
	$WorldEnvironment.environment.set("ssil_enabled",Saved.get_settings("WorldEnvironment/SSIL/enable"))
	$WorldEnvironment.environment.set("sdfgi_enabled",Saved.get_settings("WorldEnvironment/SDFGI/enable"))
	$WorldEnvironment.environment.set("glow_enabled",Saved.get_settings("WorldEnvironment/Glow/enable"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
