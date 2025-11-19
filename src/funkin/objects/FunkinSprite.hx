package funkin.objects;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;

class FunkinSprite extends animate.FlxAnimate {
	public var offsetMap:Map<String, Array<Float>> = [];
	public var frameOffset:FlxPoint = FlxPoint.get();

	public function new(?x:Float, ?y:Float, ?graphic:FlxGraphicAsset) {
		super(x, y, graphic);
		moves = false;
		active = false;
		antialiasing = FlxSprite.defaultAntialiasing;
	}

	// knew this was gonna get to me eventually lol
	override public function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0, unique:Bool = false, ?key:String):FunkinSprite {
		super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
		return this;
	}

	override public function makeGraphic(width:Int, height:Int, color:FlxColor = FlxColor.WHITE, unique:Bool = false, ?key:String):FunkinSprite	{
		super.makeGraphic(width, height, color, unique, key);
		return this;
	}

	override function set_antialiasing(v:Bool):Bool {
		if (!Settings.data.antialiasing) return antialiasing = false;
		return antialiasing = v;
	}

	public function setOffset(name:String, offsets:Array<Float>) offsetMap.set(name, offsets);

	public function playAnim(name:String, ?forced:Bool = true, ?suffix:String = "") {
		var fullName = name + suffix;
		if (!animation.exists(fullName)) fullName = name;
		if (!animation.exists(fullName)) return;

		final offsetsForAnim:Array<Float> = offsetMap[fullName] ?? [0, 0];

		animation.play(fullName, forced);
		active = animation.curAnim != null ? animation.curAnim.frames.length > 1 : false;
		//this shit messes with the real position of the sprite, like it happened with the reflections
		//it messes with getGraphicMidpoint(); too
		frameOffset.set(offsetsForAnim[0], offsetsForAnim[1]);
	}

	// basically the beginning of drawComplex
	function prepareMatrix(camera:FlxCamera) {
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.translate(-frameOffset.x, -frameOffset.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		if (skew.x != 0 || skew.y != 0)
		{
			updateSkew();
			@:privateAccess _matrix.concat(animate.FlxAnimate._skewMatrix);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}
	}

	override function drawAnimate(camera:FlxCamera):Void {
		var mat = _matrix;
		mat.identity();

		@:privateAccess
		var bounds = timeline._bounds;
		mat.translate(-bounds.x, -bounds.y);

		if (checkFlipX()) {
			mat.scale(-1, 1);
			mat.translate(frame.sourceSize.x, 0);
		}

		if (checkFlipY()) {
			mat.scale(1, -1);
			mat.translate(0, frame.sourceSize.y);
		}

		if (applyStageMatrix)
			mat.concat(library.matrix);

		mat.translate(-origin.x, -origin.y);
		mat.translate(-frameOffset.x, -frameOffset.y);
		mat.scale(scale.x, scale.y);

		if (angle != 0) {
			updateTrig();
			mat.rotateWithTrig(_cosAngle, _sinAngle);
		}

		if (skew.x != 0 || skew.y != 0) {
			updateSkew();
			@:privateAccess mat.concat(animate.FlxAnimate._skewMatrix);
		}

		getScreenPosition(_point, camera);
		_point.x += origin.x - offset.x;
		_point.y += origin.y - offset.y;
		mat.translate(_point.x, _point.y);

		if (renderStage)
			drawStage(camera);

		timeline.currentFrame = animation.frameIndex;
		timeline.draw(camera, mat, colorTransform, blend, antialiasing, shader);
	}

	override function drawComplex(camera:FlxCamera) {
		prepareMatrix(camera);
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, wrapMode, shader);
	}
}