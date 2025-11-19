package flixel.graphics.tile;

#if FLX_DRAW_QUADS
import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.system.FlxAssets.FlxShader;
import flixel.math.FlxMatrix;
import openfl.geom.ColorTransform;
import openfl.display.ShaderParameter;
import openfl.Vector;

class FlxDrawQuadsItem extends FlxDrawBaseItem<FlxDrawQuadsItem> {
	static inline var VERTICES_PER_QUAD = #if (openfl >= "8.5.0") 4 #else 6 #end;

	public var shader:FlxShader;

	var rects:Vector<Float>;
	var transforms:Vector<Float>;
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public function new() {
		super();
		type = FlxDrawItemType.TILES;
		rects = new Vector<Float>();
		transforms = new Vector<Float>();
		alphas = [];
	}

	override public function reset():Void {
		super.reset();
		rects.length = 0;
		transforms.length = 0;
		alphas.resize(0);
		if (colorMultipliers != null)
			colorMultipliers.resize(0);
		if (colorOffsets != null)
			colorOffsets.resize(0);
	}

	override public function dispose():Void {
		super.dispose();
		rects = null;
		transforms = null;
		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
	}

	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void {
		var rect = frame.frame;
		rects.push(rect.x);
		rects.push(rect.y);
		rects.push(rect.width);
		rects.push(rect.height);

		transforms.push(matrix.a);
		transforms.push(matrix.b);
		transforms.push(matrix.c);
		transforms.push(matrix.d);
		transforms.push(matrix.tx);
		transforms.push(matrix.ty);

		var alphaMultiplier = transform != null ? transform.alphaMultiplier : 1.0;
		for (i in 0...VERTICES_PER_QUAD)
			alphas.push(alphaMultiplier);

		if (colored || hasColorOffsets) {
			if (colorMultipliers == null)
				colorMultipliers = [];

			if (colorOffsets == null)
				colorOffsets = [];

			if (transform != null) {
				for (_ in 0...VERTICES_PER_QUAD) {
					colorMultipliers.push(transform.redMultiplier);
					colorMultipliers.push(transform.greenMultiplier);
					colorMultipliers.push(transform.blueMultiplier);
					colorMultipliers.push(1);

					colorOffsets.push(transform.redOffset);
					colorOffsets.push(transform.greenOffset);
					colorOffsets.push(transform.blueOffset);
					colorOffsets.push(transform.alphaOffset);
				}
			} else {
				for (i in 0...VERTICES_PER_QUAD) {
					if (i != 0) colorMultipliers.push(1);
					colorOffsets.push(0);
				}
			}
		}
	}

	#if !flash
	override public function render(camera:FlxCamera):Void {
		if (rects.length == 0)
			return;

		var shader = shader != null ? shader : graphics.shader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.wrap = wrapMode;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? ANISOTROPIC16X : NEAREST;
		shader.alpha.value = alphas;

		if (colored || hasColorOffsets) {
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;
		} else {
			shader.colorMultiplier.value = null;
			shader.colorOffset.value = null;
		}

		setParameterValue(shader.hasTransform, true);
		setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

		#if (openfl > "8.7.0")
		camera.canvas.graphics.overrideBlendMode(blend);
		#end
		camera.canvas.graphics.beginShaderFill(shader);
		camera.canvas.graphics.drawQuads(rects, null, transforms);
		camera.canvas.graphics.endFill();
		super.render(camera);
	}

	inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool):Void {
		if (parameter.value == null)
			parameter.value = [];
		parameter.value[0] = value;
	}
	#end
}
#end
