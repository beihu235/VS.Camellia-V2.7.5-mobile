package funkin.objects.ui;

class CategoryList extends FunkinSprite {
	// variables to create a mouse deadzone
	final MOUSE_DEADZONE = 5; // technically 10, but goes in both directions.
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;
	public var mouseMoved:Bool = false;

	public var translate:Bool = true;
	public var options(default, set):Array<String>;
	function set_options(value:Array<String>) {
		final lastScale = scale.y;
		scale.y = value.length * 45 + 50 * Math.min(value.length, 1);
		updateHitbox();
		scale.y = lastScale;
		offset.set();
		origin.set();

		while (texts.length > 0) {
			final txt = texts.members[0];
			texts.remove(txt, true);
			txt.destroy();
		}

		var txtY = y + 25;
		hover = Std.int(FlxMath.bound(hover, 0, value.length - 1));
		selected = hover;
		triangle.scale.set();
		hoverSpr.scale.y = 0;
		selScale = 0;
		for (i in 0...value.length) {
			var cata = new FlxText(x + 20, txtY, width - 40, (translate ? _t(value[i]) : value[i]).toUpperCase());
			if (i == hover) {
				cata.y += 5;
				cata.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 30, 0xFF101010, LEFT);
				txtY += 55;
			} else {
				cata.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 30, 0xFFFFFFFF, LEFT);
				cata.updateHitbox();
				cata.scale.set(0.85, 0.85);
				cata.origin.x = 0;
				txtY += 45;
			}
			cata.antialiasing = Settings.data.antialiasing;
			texts.add(cata);
		}

		if (value.length > 0)
			hoverSpr.y = texts.members[hover].y + (texts.members[hover].height - hoverSpr.height) * 0.5;
		return options = value;
	}

	public var enterHit:Bool = false;
	public var useInputs:Bool = true;
	public var useMouse:Bool = true;
	public var selected:Int = 0;
	public var hover:Int = 0;
	public var targetScale:Float = 1;

	public var triangle:FunkinSprite;
	public var hoverSpr:FunkinSprite;
	public var texts:FlxTypedGroup<FlxText>;
	public var selScale:Float = 0;

	public var onRetarget:Int->Void;
	public var open:Int->Void;

	public function new(x:Float, y:Float, options:Array<String>, ?translate:Bool = true) {
		super(x, y);
		active = true;
		makeGraphic(1, 1, 0x80000000);
		scale.set(355, 0);

		hoverSpr = new FunkinSprite(x - 4, y);
		hoverSpr.makeGraphic(1, 1, 0xFFFFFFFF);
		hoverSpr.scale.set(scale.x + 8, 55);
		hoverSpr.updateHitbox();

		texts = new FlxTypedGroup<FlxText>();

		triangle = new FunkinSprite(hoverSpr.x + 20, 0, Paths.image("menus/triangle"));
		triangle.color = 0xFF000000;
		triangle.flipX = true;
		triangle.scale.set(0.7, 0.7);
		triangle.updateHitbox();
		triangle.origin.x += 3; // UUUUUGGGGGGGGHHHHHHHHH

		this.translate = translate;
		this.options = options;
	}
	
	public function retarget(target:Int) {
		if (target == hover) return;

		if (hover >= 0 && hover < texts.length) {
			texts.members[hover].color = 0xFFFFFFFF;
			texts.members[hover].font = Paths.font("Rockford-NTLG Light.ttf");
		}

		hover = Std.int(FlxMath.bound(target, 0, options.length - 1));
		triangle.scale.set();
		hoverSpr.scale.y = 0;
		selScale = 0;

		if (hover >= 0 && hover < texts.length) {
			texts.members[hover].color = 0xFF101010;
			texts.members[hover].font = Paths.font("Rockford-NTLG Medium.ttf");
		}

		if (onRetarget != null)
			onRetarget(target);
		FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
	}

	override function update(delta:Float) {
		enterHit = false;
		super.update(delta);
		if (!Settings.data.reducedQuality)
			triangle.angle += delta * 160;

		mouseMoved = false;
		if (Math.abs(FlxG.mouse.screenX - lastMouseX) >= MOUSE_DEADZONE || Math.abs(FlxG.mouse.screenY - lastMouseY) >= MOUSE_DEADZONE) {
			lastMouseX = FlxG.mouse.screenX;
			lastMouseY = FlxG.mouse.screenY;
			mouseMoved = true;
		}

		final hasObjects = hover >= 0 && hover < options.length;
		if (hasObjects && useMouse && FlxG.mouse.screenX >= x && FlxG.mouse.screenX <= x + width && FlxG.mouse.y >= y && FlxG.mouse.y <= y + height) {
			for (i => cata in texts.members) {
				var height = 45 + 10 * ((cata.scale.y - 0.85) / 0.15);
				
				var top = cata.y + (cata.height - height) * 0.5;
				if (FlxG.mouse.y >= top && FlxG.mouse.y <= top + height) {
					if (FlxG.mouse.justReleased) {
						retarget(i);
						open(i);
					} else if (mouseMoved)
						retarget(i);
					break;
				}
			}
		} else if (hasObjects)
			retarget(selected);

		if (hasObjects && useInputs) {
			final downJustPressed:Bool = Controls.justPressed('ui_down');
	
			if (downJustPressed || Controls.justPressed('ui_up')) {
				selected = FlxMath.wrap(hover + (downJustPressed ? 1 : -1), 0, options.length - 1);
				retarget(selected);
			}
	
			if (Controls.justPressed('accept')) {
				enterHit = true;
				open(hover);
			}
		}

		scale.y = FlxMath.lerp(scale.y, targetScale * height, delta * 15);
		final cataMargin = (y + scale.y);
		var curY = y + 25;
		for (i in 0...texts.length) {
			var cata = texts.members[i];
			cata.origin.x = 0;
			cata.scale.x = cata.scale.y = FlxMath.lerp(cata.scale.x, (i == hover ? 1.0 : 0.85), delta * 15);
			var scale = ((cata.scale.y - 0.85) / 0.15);
			cata.offset.x = -30 * scale;

			curY += 5 * scale;
			cata.x = x + 20;
			cata.y = curY;
			curY += 45 + 5 * scale;

			// clip it to the list.
			final bot = cata.y + (cata.graphic.height - cata.graphic.height * cata.scale.y) * 0.5 + cata.graphic.height * cata.scale.y;
			if (bot < cataMargin - 5) {
				cata.clipGraphic(0, 0, cata.graphic.width, cata.graphic.height - Math.max(bot - cataMargin, 0) / cata.scale.y);
				cata.visible = true;
			} else
				cata.visible = false;
		}
		selScale = Math.min(Math.max(selScale + delta * (-8 + 12 * targetScale) * Math.min(options.length, 1), 0.0), 1.0);
		hoverSpr.scale.y = 55 * FlxEase.backOut(selScale);
		hoverSpr.x = x - 4;

		if (!hasObjects) return;
		hoverSpr.y = texts.members[hover].y + (texts.members[hover].height - hoverSpr.height) * 0.5;
		triangle.scale.x = triangle.scale.y =  0.7 * FlxEase.cubeOut(selScale);
		triangle.setPosition(
			hoverSpr.x + 20 + (30 + texts.members[hover].offset.x),
			hoverSpr.y + (hoverSpr.height - triangle.height) * 0.5
		);
	}

	override function draw() {
		super.draw();
		hoverSpr.draw();
		texts.draw();
		triangle.draw();
	}

	override function set_alpha(value:Float) {
		super.set_alpha(value);

		hoverSpr.alpha = triangle.alpha = alpha;
		for (txt in texts)
			txt.alpha = alpha;

		return alpha;
	}
}