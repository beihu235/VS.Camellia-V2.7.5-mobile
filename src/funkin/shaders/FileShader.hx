package funkin.shaders;
// blame rudy for using an older flixel-addons
// https://github.com/HaxeFlixel/flixel-addons/blob/dev/flixel/addons/display/FlxRuntimeShader.hx used as reference obv

import flixel.graphics.tile.FlxGraphicsShader;
import openfl.display.ShaderParameterType;
import openfl.display.ShaderParameter;
import openfl.display.ShaderInput;
import openfl.display.BitmapData;
import lime.utils.Float32Array;

using StringTools;

// for replacement since the replacement typically goes in the macro.
inline var FRAG_HEADER:String = "varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;
uniform sampler2D bitmap;
uniform bool hasTransform;
uniform bool hasColorTransform;

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
{
	vec4 color = texture2D(bitmap, coord);
	if (!hasTransform)
	{
		return color;
	}

	if (color.a == 0.0)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	}

	if (!hasColorTransform)
	{
		return color * openfl_Alphav;
	}

	color = vec4(color.rgb / color.a, color.a);

	// not accurate yes but i still dont get why we were matrix multiplying in the first place.
	color = clamp(openfl_ColorOffsetv + (color * openfl_ColorMultiplierv), 0.0, 1.0);

	if (color.a > 0.0)
	{
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}";
inline var FRAG_BODY:String = "gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);";
inline var FRAG_DEFAULT:String = "#pragma header
		
void main(void)
{
	gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
}";

inline var VERT_HEADER:String = "attribute float openfl_Alpha;
attribute vec4 openfl_ColorMultiplier;
attribute vec4 openfl_ColorOffset;
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;

varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;";
inline var VERT_BODY:String = "openfl_Alphav = openfl_Alpha;
	openfl_TextureCoordv = openfl_TextureCoord;

	if (openfl_HasColorTransform) {

		openfl_ColorMultiplierv = openfl_ColorMultiplier;
		openfl_ColorOffsetv = openfl_ColorOffset / 255.0;

	}

	gl_Position = openfl_Matrix * openfl_Position;";
inline var VERT_DEFAULT:String = "#pragma header
		
attribute float alpha;
attribute vec4 colorMultiplier;
attribute vec4 colorOffset;
uniform bool hasColorTransform;

void main(void)
{
	#pragma body
	
	openfl_Alphav = openfl_Alpha * alpha;
	
	if (hasColorTransform)
	{
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = colorMultiplier;
	}
}";

class FileShader extends FlxGraphicsShader {
	public function new(frag:String, vert:String) {
		glFragmentSource = Paths.exists("shaders/" + frag + ".frag") ? Paths.getFileContent("shaders/" + frag + ".frag") : FRAG_DEFAULT;
		glFragmentSource = glFragmentSource.replace("#pragma header", FRAG_HEADER).replace("#pragma body", FRAG_BODY);

		glVertexSource = Paths.exists("shaders/" + vert + ".vert") ? Paths.getFileContent("shaders/" + vert + ".vert") : VERT_DEFAULT;
		glVertexSource = glVertexSource.replace("#pragma header", VERT_HEADER).replace("#pragma body", VERT_BODY);
		super();
	}

	// may one day make var accessing easier. but hopefully yall know about shader.data.var.value = [val];

	@:noCompletion override private function __processGLData(source:String, storageType:String):Void {
		var lastMatch = 0, position, regex, name, type;

		if (storageType == "uniform")
			regex = ~/uniform ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		else
			regex = ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;

		var fields = Reflect.fields(this);
		while (regex.matchSub(source, lastMatch)) {
			type = regex.matched(1);
			name = regex.matched(2);

			if (StringTools.startsWith(name, "gl_"))
				continue;

			var isUniform = (storageType == "uniform");

			if (StringTools.startsWith(type, "sampler")) {
				var input = new ShaderInput<BitmapData>();
				input.name = name;
				@:privateAccess input.__isUniform = isUniform;
				__inputBitmapData.push(input);

				switch (name) {
					case "openfl_Texture":
						__texture = input;
					case "bitmap":
						__bitmap = input;
					default:
				}

				Reflect.setField(__data, name, input);
				if (__isGenerated && fields.contains(name))
					Reflect.setField(this, name, input);
			} else if (!Reflect.hasField(__data, name) || Reflect.field(__data, name) == null) {
				var parameterType:ShaderParameterType = switch (type) {
					case "bool": BOOL;
					case "double", "float": FLOAT;
					case "int", "uint": INT;
					case "bvec2": BOOL2;
					case "bvec3": BOOL3;
					case "bvec4": BOOL4;
					case "ivec2", "uvec2": INT2;
					case "ivec3", "uvec3": INT3;
					case "ivec4", "uvec4": INT4;
					case "vec2", "dvec2": FLOAT2;
					case "vec3", "dvec3": FLOAT3;
					case "vec4", "dvec4": FLOAT4;
					case "mat2", "mat2x2": MATRIX2X2;
					case "mat2x3": MATRIX2X3;
					case "mat2x4": MATRIX2X4;
					case "mat3x2": MATRIX3X2;
					case "mat3", "mat3x3": MATRIX3X3;
					case "mat3x4": MATRIX3X4;
					case "mat4x2": MATRIX4X2;
					case "mat4x3": MATRIX4X3;
					case "mat4", "mat4x4": MATRIX4X4;
					default: null;
				}

				var length = switch (parameterType) {
					case BOOL2, INT2, FLOAT2: 2;
					case BOOL3, INT3, FLOAT3: 3;
					case BOOL4, INT4, FLOAT4, MATRIX2X2: 4;
					case MATRIX3X3: 9;
					case MATRIX4X4: 16;
					default: 1;
				}

				var arrayLength = switch (parameterType) {
					case MATRIX2X2: 2;
					case MATRIX3X3: 3;
					case MATRIX4X4: 4;
					default: 1;
				}

				@:privateAccess switch (parameterType) {
					case BOOL, BOOL2, BOOL3, BOOL4:
						var parameter = new ShaderParameter<Bool>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isBool = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramBool.push(parameter);

						if (name == "openfl_HasColorTransform")
							__hasColorTransform = parameter;

						Reflect.setField(__data, name, parameter);
						if (__isGenerated && fields.contains(name))
							Reflect.setField(this, name, parameter);

					case INT, INT2, INT3, INT4:
						var parameter = new ShaderParameter<Int>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isInt = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramInt.push(parameter);
						Reflect.setField(__data, name, parameter);
						if (__isGenerated && fields.contains(name))
							Reflect.setField(this, name, parameter);

					default:
						var parameter = new ShaderParameter<Float>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						#if lime
						if (arrayLength > 0) parameter.__uniformMatrix = new Float32Array(arrayLength * arrayLength);
						#end
						parameter.__isFloat = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramFloat.push(parameter);

						if (StringTools.startsWith(name, "openfl_")) {
							switch (name) {
								case "openfl_Alpha": __alpha = parameter;
								case "openfl_ColorMultiplier": __colorMultiplier = parameter;
								case "openfl_ColorOffset": __colorOffset = parameter;
								case "openfl_Matrix": __matrix = parameter;
								case "openfl_Position": __position = parameter;
								case "openfl_TextureCoord": __textureCoord = parameter;
								case "openfl_TextureSize": __textureSize = parameter;
								default:
							}
						}

						Reflect.setField(__data, name, parameter);
						if (__isGenerated && fields.contains(name))
							Reflect.setField(this, name, parameter);
				}
			}

			position = regex.matchedPos();
			lastMatch = position.pos + position.len;
		}
	}
}