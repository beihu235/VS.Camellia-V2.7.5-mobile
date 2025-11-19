package funkin.objects;

import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;

using flixel.util.FlxColorTransformUtil;

class ComboNums extends FlxTypedSpriteGroup<Number> {
	public static inline final default_precacheDigits:Int = 4;
	public static inline final default_startingDigits:Int = 3;

	public var size:Float = 0.6;
	public var spacing:Float = 6;

	public var originalPos:FlxPoint = FlxPoint.get();
	public function new(?x:Float, ?y:Float) {
		super(x, y);
		for (i in 0...default_precacheDigits) add(new Number());
		scale.set(size, size);

		originalPos.set(x, y);
	}

	public function clearNums(?until:Int = 0) {
		while (length > until) {
			final num = members[0];
			remove(num, true);
			num.destroy();
		}
	}

	public function display(comboNum:Int) {
		if (Settings.data.comboAlpha <= 0) return;

		final comboStr:String = '$comboNum'.lpad('0', default_startingDigits);
		// remove any excess numbers
		clearNums(comboStr.length);

		// then add any new ones
		for (_ in 0...comboStr.length - length) insert(0, new Number());

		for (i in 0...comboStr.length) {
			final num:Number = members[i];
			if (num == null) continue;

			final convertedNum:Int = comboStr.fastCodeAt(i) - '0'.code;//Std.parseInt(comboStr.charAt(i));

			final centerI = i - length * 0.5;
			if (num.animation.frameIndex != convertedNum) num.animation.frameIndex = convertedNum;
			num.scale.set(scale.x, scale.y);
			num.updateHitbox();
			num.setPosition((originalPos.x + ((num.width * centerI) * scale.x)) + spacing * centerI, originalPos.y - 5);
			num.color = color;
			num.visibility = Settings.data.comboAlpha;

			Main.tweenManager.cancelTweensOf(num);
			Main.tweenManager.tween(num, {visibility: 0}, 0.35, {startDelay: 0.75});

			Main.tweenManager.tween(num, {y: originalPos.y}, 0.1, {
				onComplete: function(_) num.y = originalPos.y,
				ease: FlxEase.cubeIn
			});
		}

		//this.x = originalPos.x - ((width * 0.5) * scale.x);
		// fuck this im just gonna
		// screenCenter(X);
	}
}

private class Number extends FunkinSprite {
	// using this instead of `alpha`
	// so you can set the `alpha` variable without fucking up anything
	public var visibility(default, set):Float = 1;
	function set_visibility(v:Float):Float {
		if (visibility == v) return v;

		visibility = FlxMath.bound(v, 0, 1);
		updateColorTransform();
		return visibility;
	}

	public function new() {
		super();

		loadGraphic(Paths.image('ui/comboNums'), true, 70, 48);
		visibility = 0;

		active = true;
		moves = true;
	}

	override function destroy() {
		Main.tweenManager.cancelTweensOf(this);
		super.destroy();
	}

	override function draw():Void {
		if (visibility <= 0) return;

		super.draw();
	}

	override function updateColorTransform():Void {
		if (colorTransform == null) return;

		useColorTransform = alpha != 1 || visibility != 1 || color != 0xffffff;
		if (useColorTransform) this.colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, visibility * alpha);
		else this.colorTransform.setMultipliers(1, 1, 1, 1);

		dirty = true;
	}
}