package funkin.objects.ui;

import funkin.backend.Meta.MetaFile;

class FreeplaySongSlot extends FunkinSprite {
	public var txt:FlxText;
	public var sub:FlxText;

	public var invert:Bool = false;
	public var txtOffset:Float = 0.0;

	public var curTarget:Int = -1;
	public var targetX:Float = 0.0;
	public var targetY:Float = 0.0;
	public var targetScale:Float = 1.0;
	public var targetAlpha:Float = 1.0;
	public var targetSlotCol:Float = 0.0;

	public var onClick:FreeplaySongSlot->Bool->Void;

	var wasTargeted:Bool = false;

	public function new(target:Int, title:String, subtitle:String, ?invert:Bool = false) {
		super(0, 0, Paths.image("menus/Freeplay/songBar"));
		active = true;
		
		offset.y = frameHeight * 0.5;
		origin.x = 0.0;
		
		if (invert) {
			this.invert = true;
			angle = 180;
		}

		txt = new FlxText(0, 0, 0, title, 24);
		txt.setFormat(Paths.font("Rockford-NTLG Extralight.ttf"), 24, 0xFF000000, invert ? LEFT : RIGHT);

		sub = new FlxText(0, 0, 0, subtitle, 12);
		sub.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 12, 0xFF000000, invert ? LEFT : RIGHT);

		retarget(target);
		setPosition(FlxG.width, targetY);
		scale.set(targetScale, targetScale);
		alpha = 0.0;

		postReposition();
	}

	override function update(delta:Float) {
		scale.x = scale.y = FlxMath.lerp(scale.x, targetScale, delta * 15);
		x = FlxMath.lerp(x, targetX, delta * 15);
		y = FlxMath.lerp(y, targetY, delta * 15);
		alpha = FlxMath.lerp(alpha, targetAlpha, delta * 15);
		colorTransform.alphaOffset = FlxMath.lerp(colorTransform.alphaOffset, targetSlotCol, delta * 7.5);

		postReposition();

		final left = x - offset.x - camera.scroll.x * scrollFactor.x;
		final right = left + frameWidth * scale.x * _cosAngle;
		final top = y - frameHeight * scale.y * 0.5 - camera.scroll.y * scrollFactor.y;
		final bottom = top + frameHeight * scale.y;
		if ((FlxG.mouse.justPressed || FlxG.mouse.justReleased) && FlxG.mouse.x >= Math.min(left, right) && FlxG.mouse.x <= Math.max(left, right) && FlxG.mouse.y >= top && FlxG.mouse.y <= bottom && onClick != null)
			onClick(this, FlxG.mouse.justReleased);
	}

	public inline function postReposition() {
		clipGraphic(0, 0, Math.abs(x - FlxG.width) / scale.x, frameHeight);

		final invertOffset = invert ? 620 * scale.x : 0;
		txt.setPosition(
			x - invertOffset - offset.x + 45 + txtOffset,
			y - frameHeight * scale.y * 0.425
		);
		sub.setPosition(
			txt.x,
			txt.y + txt.height - 5
		);
		
		if (invert) {
			final txtFrameX = Math.max(FlxG.width - offset.x - txt.x, 0.0);
			txt._frame.frame.x = txtFrameX;
			txt._frame.frame.width = txt.frameWidth - txtFrameX;
			txt.offset.x = -txtFrameX;
			
			final subFrameX = Math.max(FlxG.width - offset.x - sub.x, 0.0);
			sub._frame.frame.x = subFrameX;
			sub._frame.frame.width = sub.frameWidth - subFrameX;
			sub.offset.x = -subFrameX;

			txt.visible = txt._frame.frame.width >= 5;
			sub.visible = sub._frame.frame.width >= 5;
		} else {
			txt._frame.frame.width = FlxG.width - offset.x - txt.x;
			sub._frame.frame.width = FlxG.width - offset.x - sub.x;
		}
	}

	public function retarget(target:Int) {
		if ((curTarget == 0) != (target == 0)) {
			txt.font = Paths.font((target == 0) ? "Rockford-NTLG Medium.ttf" : "Rockford-NTLG Extralight.ttf");
			txt.size = (target == 0) ? 38 : 24;
			sub.size = (target == 0) ? 16 : 12;
		}

		final diffSign = (target == 0) ? 0 : FlxMath.signOf(target);
		final xScale = invert ? -1 : 1;

		// MAGIC. NUMBERS. EVERYWHERE.
		targetScale = (target == 0 ? 1.0 : 0.675);
		targetX = FlxG.width - (target == 0 ? 610 : 410 + 30 * target * xScale) * xScale;
		targetY = (FlxG.height * 0.5 + 100 * diffSign + 82 * (target - diffSign));
		targetAlpha = Math.pow(0.675, 1.65 * Math.abs(target));
		targetSlotCol = (target == 0 ? 0 : 254);
		curTarget = target;
	}
}