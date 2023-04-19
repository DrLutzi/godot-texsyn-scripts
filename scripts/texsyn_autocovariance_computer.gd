extends Node3D

#script that computes and saves in PNG/EXR files the textures necessary
#for rendering the provided textures with the texsyn module.

@export var texture_albedo: Texture
@export var texture_normal: Texture
@export var texture_height: Texture
@export var texture_roughness: Texture
@export var texture_metallic: Texture
@export var texture_ao: Texture
@export var pdfSize = 512
@export var meanSize = 1024
@export var meanPrecision = 256
@export var realizationSize = 512
@export var instanceName = "default"
@export_dir var texsynDirectoryName = "texsyn"
@export var exportPdf = false
@export var centerExemplars = false
var proctex = ProceduralSampling.new()

func checkMeanExistence(tex : Texture):
	var rid = tex.get_rid().get_id()
	var meanTexFilename = "res://{dir}/mean_acv_{id}.png".format({"dir":texsynDirectoryName, "id":tex.get_path().get_basename().get_file()})
	return FileAccess.file_exists(meanTexFilename)

func saveMean(tex: Texture, mean: Image):
	if tex != null:
		var rid = tex.get_rid().get_id()
		var meanTexFilename = "res://{dir}/mean_acv_{id}.png".format({"dir":texsynDirectoryName, "id":tex.get_path().get_basename().get_file()})
		mean.save_png(meanTexFilename)
		
func centerExemplar(image: Image, mean: Image):
	if image != null :
		if centerExemplars :
			proctex.centerExemplar(image, mean)
		image.generate_mipmaps()
		mean.generate_mipmaps()

func checkExemplarExistence(tex : Texture):
	var rid = tex.get_rid().get_id()
	var meanTexFilename = "res://{dir}/exemplar_acv_{id}.exr".format({"dir":texsynDirectoryName, "id":tex.get_path().get_basename().get_file()})
	return FileAccess.file_exists(meanTexFilename)

func saveExemplar(tex: Texture, mean: Image):
	if tex != null and centerExemplars :
		var rid = tex.get_rid().get_id()
		var meanTexFilename = "res://{dir}/exemplar_acv_{id}.exr".format({"dir":texsynDirectoryName, "id":tex.get_path().get_basename().get_file()})
		mean.save_exr(meanTexFilename)

func initImageFromParameters(image, texture, format):
	image.copy_from(texture.get_image())
	image.convert(format)
	image.resize(pdfSize, pdfSize)
	
func saveDataFromParameters(mean: Image, image: Image, texture: Texture):
	mean.resize(meanSize, meanSize)
	saveMean(texture, mean)
	centerExemplar(image, mean)
	saveExemplar(texture, image)
	
func meanNeedsComputation(texture: Texture):
	return texture != null and !checkMeanExistence(texture)

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open("res://")
	dir.make_dir(texsynDirectoryName)
	
	proctex.set_meanAccuracy(meanPrecision)
	proctex.set_meanSize(meanSize)
	
	var exemplarAlbedo : Image
	var exemplarNormal : Image
	var exemplarHeight : Image
	var exemplarRoughness : Image
	var exemplarMetallic : Image
	var exemplarAO : Image
	var meanAlbedo : Image
	var meanNormal : Image
	var meanHeight : Image
	var meanRoughness : Image
	var meanMetallic : Image
	var meanAO : Image
	
	var width
	var height
	
	var computeAlbedo = meanNeedsComputation(texture_albedo)
	var computeNormal = meanNeedsComputation(texture_normal)
	var computeHeight = meanNeedsComputation(texture_height)
	var computeRoughness = meanNeedsComputation(texture_roughness)
	var computeMetallic = meanNeedsComputation(texture_metallic)
	var computeAO = meanNeedsComputation(texture_ao)
	
	var meanLoaded = true
	if computeAlbedo:
		exemplarAlbedo = Image.new()
		width = texture_albedo.get_image().get_width()
		height = texture_albedo.get_image().get_height()
		initImageFromParameters(exemplarAlbedo, texture_albedo, Image.FORMAT_RGBF)
		proctex.set_albedo(exemplarAlbedo)

	if computeNormal:
		exemplarNormal = Image.new()
		width = texture_normal.get_image().get_width()
		height = texture_normal.get_image().get_height()
		initImageFromParameters(exemplarNormal, texture_normal, Image.FORMAT_RGBF)
		proctex.set_normal(exemplarNormal)
	
	if computeHeight:
		exemplarHeight = Image.new()
		width = texture_height.get_image().get_width()
		height = texture_height.get_image().get_height()
		initImageFromParameters(exemplarHeight, texture_height, Image.FORMAT_RF)
		proctex.set_height(exemplarHeight)
	
	if computeRoughness:
		exemplarRoughness = Image.new()
		width = texture_roughness.get_image().get_width()
		height = texture_roughness.get_image().get_height()
		initImageFromParameters(exemplarRoughness, texture_roughness, Image.FORMAT_RF)
		proctex.set_roughness(exemplarRoughness)
	
	if computeMetallic:
		exemplarMetallic = Image.new()
		width = texture_metallic.get_image().get_width()
		height = texture_metallic.get_image().get_height()
		initImageFromParameters(exemplarMetallic, texture_metallic, Image.FORMAT_RF)
		proctex.set_metallic(exemplarMetallic)

	if computeAO:
		exemplarAO = Image.new()
		width = texture_ao.get_image().get_width()
		height = texture_ao.get_image().get_height()
		initImageFromParameters(exemplarAO, texture_ao, Image.FORMAT_RF)
		proctex.set_ao(exemplarAlbedo)
		
	if computeAlbedo or computeNormal or computeHeight or computeRoughness or computeMetallic or computeAO:
		proctex.computeAutocovarianceSampler()
		var srName = "res://{dir}/realization_acv_{id}.exr"
		srName = srName.format({"dir":texsynDirectoryName, "id":instanceName})
		if !FileAccess.file_exists(srName):
			var realization = Image.new()
			proctex.samplerRealizationToImage(realization, realizationSize)
			if exportPdf:
				var pdf = Image.new()
				proctex.samplerPdfToImage(pdf)
				var srPdfName = "res://{dir}/pdf_{id}.png"
				srPdfName = srPdfName.format({"dir":texsynDirectoryName, "id":instanceName})
				pdf.save_png(srPdfName)
			realization.save_exr(srName)
	
	if computeAlbedo :
		meanAlbedo = Image.create(width, height, false, Image.FORMAT_RGBF)
		proctex.spatiallyVaryingMeanToAO(meanAlbedo)
		saveDataFromParameters(meanAlbedo, exemplarAlbedo, texture_albedo)
		
	if computeNormal :
		meanNormal = Image.create(width, height, false, Image.FORMAT_RGBF)
		proctex.spatiallyVaryingMeanToAO(meanNormal)
		saveDataFromParameters(meanNormal, exemplarNormal, texture_normal)
		
	if computeHeight :
		meanHeight = Image.create(width, height, false, Image.FORMAT_RF)
		proctex.spatiallyVaryingMeanToAO(meanHeight)
		saveDataFromParameters(meanHeight, exemplarHeight, texture_height)
		
	if computeRoughness :
		meanRoughness = Image.create(width, height, false, Image.FORMAT_RF)
		proctex.spatiallyVaryingMeanToAO(meanRoughness)
		saveDataFromParameters(meanRoughness, exemplarRoughness, texture_roughness)
		
	if computeMetallic :
		meanMetallic = Image.create(width, height, false, Image.FORMAT_RF)
		proctex.spatiallyVaryingMeanToAO(meanMetallic)
		saveDataFromParameters(meanMetallic, exemplarMetallic, texture_metallic)

	if computeAO :
		meanAO = Image.create(width, height, false, Image.FORMAT_RF)
		proctex.spatiallyVaryingMeanToAO(meanAO)
		saveDataFromParameters(meanAO, exemplarAO, texture_ao)
