# Godot Texsyn Scripts

## Description

<img src="https://user-images.githubusercontent.com/15910330/230186509-e4bb2d6f-668a-4404-8250-5f76c92ddfd1.png"  width="567" height="426">

This project is a script repository to test our texture synthesis scripts and image processing classes using [our fork of Godot 4.0](https://github.com/DrLutzi/godot), in the [texsyn4 branch](https://github.com/DrLutzi/godot/tree/texsyn4).
It is used by researchers at the BISOUS of the University of Sherbrooke to work on real-time texture synthesis. 

## Installation

- Compile [our fork of Godot 4.0](https://github.com/DrLutzi/godot), which has the same requirements as Godot 4.0.
- Download the resources and texsyn files of [this drive](https://drive.google.com/drive/folders/1i5tzNFtTbG-DTTWhwVybwerXT3g1NZnn?usp=sharing) and paste them into the repository.
If you do not do that, you will need to re-create a new scene file (refer to section [Custom scene](#custom-scene))
- Execute the godot editor using this repository as working folder, or with the project selection screen.

## Custom scene

Texsyn is made to represent textured surfaces with texture synthesis processes, especially tiling and blending (see [HN18](https://hal.inria.fr/hal-01824773/)) rather than periodic tilings.

### Creating the surface.

To create a surface with a stationary tiling and blending using 2 square tilings (see [LSD23](https://hal.science/hal-03964175/)):

- Create any MeshInstance3D with its geometry (for instance, a plane)
- In its Material, attach [shaders/texsyn_stationary_pbr.gdshader](shaders/texsyn_stationary_pbr.gdshader)
- Add any texture component you want in the shader parameters.

To create a surface with a cyclostationary tiling and blending (for textures whose elements have a periodic global organisation, see [LSD21](https://hal.science/hal-03181139/)) using 2 square tilings: 
- Create any node
- Attach the script [scripts/texsyn_cyclostationary_computer.gd](scripts/texsyn_cyclostationary_computer.gd) to the node
- Set the textures you want for your surface in the script parameters.
- Set the First Period Vector and Second Period Vector values in the script parameters. See [Cyclostationarity: Period vectors](cyclostationarity-choosing-period-vectors). 
- Execute the scene once. The script will take several minutes to compute the cyclostationary mean textures, required for cyclostationary texture synthesis, as well as a realization of the cyclostationary sampler.
- Create any MeshInstance3D with its geometry (for instance, a plane)
- In its Material, attach [shaders/texsyn_cyclostationary_pbr.gdshader](shaders/texsyn_cyclostationary_pbr.gdshader).
- Add your texture components, their respective mean, and the realization of the sampler in the appropriate shader parameters.

### Setting the shader parameters.
Each shader was written by first generating the code of a StandardMaterial3D. As such, some parameters are not correct by default.
Assuming every texture component is set, in order to get the classic default parameters, from top to bottom, you need to:
- Set **Albedo** to a white color
- Set **Roughness** to 1
- Set **Metallic Texture Channel** to (1, 0, 0, 0) assuming the metallic map is on the red component
- Set **Specular** to 0.5
- Set **Metallic** to 1
- Set **Normal Scale** to 1
- Set **AO Texture Channel** to (1, 0, 0, 0) assuming the AO map is on the red component
- Set **Heightmap Scale** to 1
- Set **Heightmap Min Layers** to 8
- Set **Heightmap Max Layers** to 32
- Set **UV1 Scale** to (1, 1, 1) (although you probably want to test out a large scale since you're here)
- If not already done, set each texture, and, for cyclostationarity, the realization of the sampler, and each spatially-varying mean.

3. Optionnal: Camera

We borrowed a [simple script for the camera](https://godotengine.org/asset-library/asset/1561), you can attach that to a Camera3D to move in your scene when you execute it.

NOTE: Only seamless textures are compatible.

## Cyclostationarity: choosing period vectors.

When wanting to display a surface with a cyclostationary texture synthesis, you need to tell the sampler how it should blend the elements of the texture.
To do this, you need to set First Period Vector and Second Period Vector, with values between 0 and 1 for each component. 
These represents the different translation vectors needed to get from one element of the pattern to another. 
For ease of use, you can also instead give the inverse vector values. 
Here are the two most typical cases: 
- The elements of your texture are organised in a `NxM` grid. Set the periods to `(N, 0)` and `(0, M)`. 
- The texture is a brick wall-like texture (alternating pattern) with `N` bricks on `x` and `M` bricks on `y`. Set the period vectors to `(N, 0)` and `(2N, M)`. This is because getting to the next closest element on y requires to draw a diagonal vector.
