extends Node3D

#script that computes and saves in EXR files the textures necessary
#for rendering the provided textures with the texsyn module.

@export var texture_albedo: Texture
@export var texture_normal: Texture
@export var texture_height: Texture
@export var texture_roughness: Texture
@export var texture_metallic: Texture
@export var texture_ao: Texture
@export var meanSize = 1024
@export var meanPrecision = 256
@export var realizationSize = 256
@export var firstPeriodVector = Vector2(1.0, 0.0)
@export var secondPeriodVector = Vector2(0.0, 1.0)
@export_dir var texsynDirectoryName = "texsyn"
@export var centerExemplars = false

func checkMeanExistence(tex : Texture):
	var meanTexFilename = "res://{dir}/mean_{id}.png".format({"dir":texsynDirectoryName, "id":tex.get_path().get_basename().get_file()})
	return FileAccess.file_exists(meanTexFilename)

func saveMean(tex: Texture, mean: Image):
	if tex != null:
		var meanTexFilename = "res://{dir}/mean_{id}.png".format({"dir":texsynDirectoryName, "id":tex.get_path().get_basename().get_file()})
		mean.save_png(meanTexFilename)
		
func centerExemplar(proctex: ProceduralSampling, image: Image, mean: Image):
	if image != null :
		if centerExemplars :
			proctex.centerExemplar(image, mean)
		image.generate_mipmaps()
		mean.generate_mipmaps()

func checkExemplarExistence(tex : Texture):
	var meanTexFilename = "res://{dir}/exemplar_{id}.exr".format({"dir":texsynDirectoryName, "id":tex.get_path().get_basename().get_file()})
	return FileAccess.file_exists(meanTexFilename)

func saveExemplar(tex: Texture, mean: Image):
	if tex != null and centerExemplars :
		var meanTexFilename = "res://{dir}/exemplar_{id}.exr".format({"dir":texsynDirectoryName, "id":tex.get_path().get_basename().get_file()})
		mean.save_exr(meanTexFilename)

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open("res://")
	dir.make_dir(texsynDirectoryName)
	
	var firstPeriodCleansed = firstPeriodVector
	var secondPeriodCleansed = secondPeriodVector
	if(firstPeriodCleansed[0]>1.0) :
		firstPeriodCleansed[0] = 1.0/firstPeriodCleansed[0]
	if(firstPeriodCleansed[1]>1.0) :
		firstPeriodCleansed[1] = 1.0/firstPeriodCleansed[1]
	if(secondPeriodCleansed[0]>1.0) :
		secondPeriodCleansed[0] = 1.0/secondPeriodCleansed[0]
	if(secondPeriodCleansed[1]>1.0) :
		secondPeriodCleansed[1] = 1.0/secondPeriodCleansed[1]
	
	
	var proctex = ProceduralSampling.new()
	proctex.set_cyclostationaryPeriods(firstPeriodCleansed, secondPeriodCleansed)
	proctex.set_meanAccuracy(meanPrecision)
	proctex.set_meanSize(meanSize)
	
	var exemplarAlbedo : Image
	var exemplarNormal : Image
	var exemplarHeight : Image
	var exemplarRoughness : Image
	var exemplarMetallic : Image
	var exemplarAO : Image
	var meanAlbedo = Image.new()
	var meanNormal = Image.new()
	var meanHeight = Image.new()
	var meanRoughness = Image.new()
	var meanMetallic = Image.new()
	var meanAO = Image.new()
	
	var width
	var height
	
	var computeAlbedo = texture_albedo != null and !checkMeanExistence(texture_albedo)
	var computeNormal = texture_normal != null and !checkMeanExistence(texture_normal)
	var computeHeight = texture_albedo != null and !checkMeanExistence(texture_height)
	var computeRoughness = texture_albedo != null and !checkMeanExistence(texture_roughness)
	var computeMetallic = texture_albedo != null and !checkMeanExistence(texture_metallic)
	var computeAO = texture_albedo != null and !checkMeanExistence(texture_ao)
	
	if computeAlbedo:
		exemplarAlbedo = Image.new()
		exemplarAlbedo.copy_from(texture_albedo.get_image())
		exemplarAlbedo.convert(Image.FORMAT_RGBF)
		proctex.set_albedo(exemplarAlbedo)
		width = exemplarAlbedo.get_width()
		height = exemplarAlbedo.get_height()

	if computeNormal:
		exemplarNormal = Image.new()
		exemplarNormal.copy_from(texture_normal.get_image())
		exemplarNormal.convert(Image.FORMAT_RGBF)
		proctex.set_normal(exemplarNormal)
		width = exemplarNormal.get_width()
		height = exemplarNormal.get_height()
	
	if computeHeight:
		exemplarHeight = Image.new()
		exemplarHeight.copy_from(texture_height.get_image())
		exemplarHeight.convert(Image.FORMAT_RF)
		proctex.set_height(exemplarHeight)
		width = exemplarHeight.get_width()
		height = exemplarHeight.get_height()
	
	if computeRoughness:
		exemplarRoughness = Image.new()
		exemplarRoughness.copy_from(texture_roughness.get_image())
		exemplarRoughness.convert(Image.FORMAT_RF)
		proctex.set_roughness(exemplarRoughness)
		width = exemplarRoughness.get_width()
		height = exemplarRoughness.get_height()
	
	if computeMetallic:
		exemplarMetallic = Image.new()
		exemplarMetallic.copy_from(texture_metallic.get_image())
		exemplarMetallic.convert(Image.FORMAT_RF)
		proctex.set_metallic(exemplarMetallic)
		width = exemplarMetallic.get_width()
		height = exemplarMetallic.get_height()

	if computeAO:
		exemplarAO = Image.new()
		exemplarAO.copy_from(texture_ao.get_image())
		exemplarAO.convert(Image.FORMAT_RF)
		proctex.set_ao(exemplarAO)
		width = exemplarAO.get_width()
		height = exemplarAO.get_height()
	
	if computeAlbedo :
		meanAlbedo = Image.create(width, height, false, Image.FORMAT_RGBF)
		proctex.spatiallyVaryingMeanToAlbedo(meanAlbedo)
		saveMean(texture_albedo, meanAlbedo)
		centerExemplar(proctex, exemplarAlbedo, meanAlbedo)
		saveExemplar(texture_albedo, exemplarAlbedo)
		
	if computeNormal :
		meanNormal = Image.create(width, height, false, Image.FORMAT_RGBF)
		proctex.spatiallyVaryingMeanToNormal(meanNormal)
		saveMean(texture_normal, meanNormal)
		centerExemplar(proctex, exemplarNormal, meanNormal)
		saveExemplar(texture_normal, exemplarNormal)
		
	if computeHeight :
		meanHeight = Image.create(width, height, false, Image.FORMAT_RF)
		proctex.spatiallyVaryingMeanToHeight(meanHeight)
		saveMean(texture_height, meanHeight)
		centerExemplar(proctex, exemplarHeight, meanHeight)
		saveExemplar(texture_height, exemplarHeight)
		
	if computeRoughness :
		meanRoughness = Image.create(width, height, false, Image.FORMAT_RF)
		proctex.spatiallyVaryingMeanToRoughness(meanRoughness)
		saveMean(texture_roughness, meanRoughness)
		centerExemplar(proctex, exemplarRoughness, meanRoughness)
		saveExemplar(texture_roughness, exemplarRoughness)
		
	if computeMetallic :
		meanMetallic = Image.create(width, height, false, Image.FORMAT_RF)
		proctex.spatiallyVaryingMeanToMetallic(meanMetallic)
		saveMean(texture_metallic, meanMetallic)
		centerExemplar(proctex, exemplarMetallic, meanMetallic)
		saveExemplar(texture_metallic, exemplarMetallic)

	if computeAO :
		meanAO = Image.create(width, height, false, Image.FORMAT_RF)
		proctex.spatiallyVaryingMeanToAO(meanAO)
		saveMean(texture_ao, meanAO)
		centerExemplar(proctex, exemplarAO, meanAO)
		saveExemplar(texture_ao, exemplarAO)

	var srName = "res://{dir}/realization_{t00}_{t01}_{t10}_{t11}.exr"
	srName = srName.format({"dir":texsynDirectoryName, "t00":"%.1f" % firstPeriodVector.x, "t01":"%.1f" % firstPeriodVector.y, "t10":"%.1f" % secondPeriodVector.x, "t11":"%.1f" % secondPeriodVector.y})
	if !FileAccess.file_exists(srName):
		var realization = Image.new()
		realization.save_exr(srName)
