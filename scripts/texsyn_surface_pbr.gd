extends MeshInstance

export var tex_albedo: Texture
export var tex_normal: Texture
export var tex_height: Texture
export var tex_roughness: Texture
export var tex_metallic: Texture
export var tex_ao: Texture
export var enableIsotropy = true
export var enableSymmetry = true
export var isotropyStartAngle = 0.0
export var isotropyEndAngle = 360.0
export var debug_showTiling = false
export var tilingScale = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	var exemplarAlbedo = tex_albedo.get_data()
	exemplarAlbedo.convert(Image.FORMAT_RGBF)

	var exemplarNormal = tex_normal.get_data()
	exemplarNormal.convert(Image.FORMAT_RGBF)
	
	var exemplarHeight = tex_height.get_data()
	exemplarHeight.convert(Image.FORMAT_RF)
	
	var exemplarRoughness = tex_roughness.get_data()
	exemplarRoughness.convert(Image.FORMAT_RF)
	
	var exemplarMetallic = tex_metallic.get_data()
	exemplarMetallic.convert(Image.FORMAT_RF)
	
	var exemplarAO = tex_ao.get_data()
	exemplarAO.convert(Image.FORMAT_RF)
	
	var imtex_exemplar = TextureArray.new()
	imtex_exemplar.create(exemplarAlbedo.get_width(), exemplarAlbedo.get_height(), 2, Image.FORMAT_RGBF)
	imtex_exemplar.set_layer_data(exemplarAlbedo, 0)
	imtex_exemplar.set_layer_data(exemplarNormal, 1)

	var imtex_exemplar_1DFormat = TextureArray.new()
	imtex_exemplar_1DFormat.create(exemplarAlbedo.get_width(), exemplarAlbedo.get_height(), 4, Image.FORMAT_RF)
	imtex_exemplar_1DFormat.set_layer_data(exemplarHeight, 0)
	imtex_exemplar_1DFormat.set_layer_data(exemplarRoughness, 1)
	imtex_exemplar_1DFormat.set_layer_data(exemplarMetallic, 2)
	imtex_exemplar_1DFormat.set_layer_data(exemplarAO, 3)

	self.get_active_material(0).set_shader_param("samplerExemplar", imtex_exemplar)
	self.get_active_material(0).set_shader_param("samplerExemplar1DFormat", imtex_exemplar_1DFormat)
	self.get_active_material(0).set_shader_param("enableIsotropy", enableIsotropy)
	self.get_active_material(0).set_shader_param("enableSymmetry", enableSymmetry)
	self.get_active_material(0).set_shader_param("isotropyStartAngle", isotropyStartAngle*3.14159265359/180)
	self.get_active_material(0).set_shader_param("isotropyEndAngle", isotropyEndAngle*3.14159265359/180)
	self.get_active_material(0).set_shader_param("tilingScale", tilingScale)
	self.get_active_material(0).set_shader_param("debug_showTiling", debug_showTiling)
	pass # Replace with function body.
 

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
