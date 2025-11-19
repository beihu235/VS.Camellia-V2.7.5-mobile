package funkin.objects;

import flixel.math.FlxRect;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;

class Bar extends FlxSpriteGroup {
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var bg:FlxSprite;
	public var valueFunction:Void -> Float = null;
	public var percent(default, set):Float = 0;
	public var bounds:Dynamic = {min: 0, max: 1};
	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = new FlxPoint(0, 0);

	public function new(x:Float, y:Float, valueFunction:Void -> Float = null, boundX:Float = 0, boundY:Float = 1) {
		super(x, y);
		
		this.valueFunction = valueFunction;
		setBounds(boundX, boundY);
		
		bg = new FlxSprite().loadGraphic(Paths.image('ui/health border'));
		barWidth = Math.floor(bg.width);
		barHeight = Math.floor(bg.height);

		leftBar = new FlxSprite().loadGraphic(Paths.image('ui/healthBar'));
		rightBar = new FlxSprite().loadGraphic(Paths.image('ui/healthBar'));

		add(leftBar);
		add(rightBar);
		add(bg);
		regenerateClips();
	}

	override function update(elapsed:Float) {
		if (valueFunction == null) {
			percent = 0.0;
			super.update(elapsed);
			return;
		}

		percent = FlxMath.remapToRange(FlxMath.bound(valueFunction(), bounds.min, bounds.max), bounds.min, bounds.max, 0, 100);
		super.update(elapsed);
	}
	
	public function setBounds(min:Float, max:Float) {
		bounds.min = min;
		bounds.max = max;
	}

	public function setColors(left:FlxColor = null, right:FlxColor = null) {
		if (left != null) leftBar.color = left;
		if (right != null) rightBar.color = right;
	}

	public function updateBar() {
		if (leftBar == null || rightBar == null) return;

		var leftSize:Float = 0;
		if (leftToRight) leftSize = FlxMath.lerp(0, barWidth, percent / 100);
		else leftSize = FlxMath.lerp(0, barWidth, 1 - percent / 100);

		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight;
		leftBar.clipRect.x = barOffset.x;
		leftBar.clipRect.y = barOffset.y;

		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight;
		rightBar.clipRect.x = barOffset.x + leftSize;
		rightBar.clipRect.y = barOffset.y;

		barCenter = leftBar.x + leftSize + barOffset.x;

		leftBar.clipRect = leftBar.clipRect;
		rightBar.clipRect = rightBar.clipRect;
	}

	public function regenerateClips() {
		final bgWidth:Int = Math.floor(bg.width);
		final bgHeight:Int = Math.floor(bg.height);

		if (leftBar != null) {
			leftBar.setGraphicSize(bgWidth, bgHeight);
			leftBar.updateHitbox();
			leftBar.clipRect = FlxRect.get(0, 0, bgWidth, bgHeight);
		}

		if (rightBar != null) {
			rightBar.setGraphicSize(bgWidth, bgHeight);
			rightBar.updateHitbox();
			rightBar.clipRect = FlxRect.get(0, 0, bgWidth, bgHeight);
		}

		updateBar();
	}

	function set_percent(value:Float):Float {
		final doUpdate:Bool = value != percent;
		percent = value;

		if (doUpdate) updateBar();
		return value;
	}

	function set_leftToRight(value:Bool):Bool {
		leftToRight = value;
		updateBar();
		return value;
	}

	function set_barWidth(value:Int):Int {
		barWidth = value;
		regenerateClips();
		return value;
	}

	function set_barHeight(value:Int):Int {
		barHeight = value;
		regenerateClips();
		return value;
	}
}