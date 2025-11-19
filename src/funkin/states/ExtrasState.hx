package funkin.states;

import funkin.shaders.Invert;
import funkin.shaders.TileLine;
import funkin.objects.ui.SwirlBG;
import funkin.objects.ui.Border;

class ExtrasState extends FunkinState {
	public static var fromMainMenu:Bool = false;

	var bg:SwirlBG;
	var lineShader:TileLine;
	var borderTop:Border;
	var borderBot:Border;

	var curSelected:Int = -1;
	var exiting:Bool = false;
	var selectOutline:FunkinSprite;
	var banners:FlxTypedGroup<FunkinSprite>;
	var echoBanners:FlxTypedGroup<FunkinSprite>; // incase we have a similar issue to echoSlot
	var echoInvert:Invert;
	var infoGroup:FlxSpriteGroup;

	var extras:Array<String> = ["awards", "addons", "gallery"];
	var colorSets:Array<Array<FlxColor>> = [
		[0xFF935825, 0xFFFFC800],
		[0xFF379680, 0xFF98FBAF],
		[0xFF7D1E57, 0xFFC53C9C]
	];

	// variables to create a mouse deadzone
	final MOUSE_DEADZONE = 5; // technically 10, but goes in both directions.
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;

	override function create():Void {
		super.create();

		add(bg = new SwirlBG(0xFF808080, 0xFF505050));

		if (!Settings.data.reducedQuality) {
			var lineBG = new FunkinSprite();
			lineBG.makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
			lineShader = new TileLine();
			lineShader.color1.value = [0, 0, 0, 0.375];
			lineShader.color2.value = [0, 0, 0, 0.5];
			lineShader.density.value = [200.0];
			lineShader.time.value = [SwirlBG.time / 64];
			lineBG.shader = lineShader;
			add(lineBG);
		}

		add(selectOutline = new FunkinSprite(FlxG.width * 0.5, FlxG.height * 0.5, Paths.image("menus/Story/outline")));
		selectOutline.x -= selectOutline.width * 0.5;
		selectOutline.y -= selectOutline.height * 0.5;
		selectOutline.alpha = 0.0;

		add(banners = new FlxTypedGroup<FunkinSprite>());
		add(echoBanners = new FlxTypedGroup<FunkinSprite>());
		echoInvert = new Invert();
		echoInvert.percent.value = [0];
		for (i => extra in extras) {
			var banner = new FunkinSprite(FlxG.width * 0.5 + 55 * (i - (extras.length - 1) * 0.5), FlxG.height + 225 * (i - (extras.length - 1) * 0.5), Paths.image('menus/Extras/$extra'));
			banner.color = (i == curSelected) ? 0xFFFFFFFF : 0xFF808080;
			banner.x -= banner.width * 0.5;
			banner.y -= banner.height * 0.5;
			banner.alpha = 0.9;

			var echo = new FunkinSprite(banner.x, banner.y, Paths.image('menus/Extras/$extra'));
			echo.visible = false;
			banners.add(banner);
			echoBanners.add(echo);
		}

		var extrasTile = new flixel.addons.display.FlxBackdrop(Paths.image('menus/Extras/bigText'), Y);
		extrasTile.velocity.y = 25;
		add(extrasTile);

		add(borderTop = new Border(true, "SELECT AN EXTRA • ", "Extras"));
		add(borderBot = new Border(false));

		// TODO: make a shortcut for these buttons for cleanup.
		final buttonY = borderBot.border.y + 58; // unfortunately 58 is the only number that centers it.
		var upButton = new FunkinSprite(borderBot.x + 40, buttonY, Paths.image('menus/keyIndicator'));
		upButton.scrollFactor.set(0, 1);
		add(upButton);

		var downButton = new FunkinSprite(upButton.x + upButton.width + 3, buttonY, Paths.image('menus/keyIndicator'));
		downButton.angle = 180;
		downButton.scrollFactor.set(0, 1);
		add(downButton);

		var changeSongTxt = new FlxText((downButton.x + downButton.width) + 5, downButton.y, 0, _t("extras_scroll"), 16);
		changeSongTxt.font = Paths.font('LineSeed.ttf');
		changeSongTxt.scrollFactor.set(0, 1);
		add(changeSongTxt);

		(fromMainMenu ? borderTop : borderBot).transitionTween(true);
		fromMainMenu = false;
	}

	function selectExtra() {
		if (curSelected < 0) return;

		var cls:Class<FunkinState> = switch (extras[curSelected]) {
			case "awards": funkin.states.AwardsState;
			case "addons": funkin.states.AddonsState;
			case "gallery": funkin.states.GalleryState;
			default: null;
		};

		if (cls == null) return;

		exiting = true;
		FlxG.sound.play(Paths.audio("menu_confirm", "sfx"));
		echoBanners.members[curSelected].visible = true;
		if (Settings.data.flashingLights)
			echoBanners.members[curSelected].shader = echoInvert;
		echoBanners.members[curSelected].setPosition(banners.members[curSelected].x, banners.members[curSelected].y);
		FlxTween.num(0, 1, 0.15, {ease: FlxEase.cubeOut}, function(num) {
			echoInvert.percent.value[0] = num;
		});
		FlxTween.tween(echoBanners.members[curSelected], {"scale.x": 1.5, "scale.y": 1.4, "alpha": 0}, 1, {ease: FlxEase.cubeOut});
		borderBot.transitionTween(false, 0.25, 0.25, function() {
			FlxG.switchState(Type.createInstance(cls, []));
		});
	}

	function changeSelection(to:Int) {
		if (curSelected >= 0)
			banners.members[curSelected].color = 0xFF808080;
		curSelected = to;
		banners.members[curSelected].color = 0xFFFFFFFF;

		bg.speed = 10;
		selectOutline.alpha = 0.0;

		bg.targetColor1 = colorSets[curSelected][0];
		bg.targetColor2 = colorSets[curSelected][1];
	}

	override function update(delta:Float) {
		super.update(delta);

		bg.speed = FlxMath.lerp(bg.speed, 1.0, delta * 15.0);
		if (!Settings.data.reducedQuality)
			lineShader.time.value[0] = SwirlBG.time / 64;

		selectOutline.alpha = FlxMath.lerp(selectOutline.alpha, 1 + Math.min(curSelected, 0), delta * 10);
		selectOutline.scale.x = selectOutline.scale.y = 1.15 - 0.15 * selectOutline.alpha;

		final halfLen = (extras.length - 1) * 0.5;
		final xOffset = (curSelected < 0 ? 0 : 15 * (halfLen - curSelected));
		final yOffset = (curSelected < 0 ? 0 : 55 * (halfLen - curSelected));
		for (i => banner in banners.members) {
			banner.setPosition(
				FlxMath.lerp(banner.x, (FlxG.width - banner.width) * 0.5 + 35 * (i - halfLen) + xOffset, delta * 10),
				FlxMath.lerp(banner.y, (FlxG.height - banner.height) * 0.5 + 215 * (i - halfLen) + yOffset, delta * 10)
			);
		}

		if (curSelected >= 0) {
			final selBanner = banners.members[curSelected];
			selectOutline.setPosition(selBanner.x + (selBanner.width - selectOutline.width) * 0.5, selBanner.y + (selBanner.height - selectOutline.height) * 0.5);
		}

		if (exiting) return;

		if (Math.abs(FlxG.mouse.screenX - lastMouseX) >= MOUSE_DEADZONE || Math.abs(FlxG.mouse.screenY - lastMouseY) >= MOUSE_DEADZONE) {
			lastMouseX = FlxG.mouse.screenX;
			lastMouseY = FlxG.mouse.screenY;

			for (i => banner in banners.members) {    
				if (FlxG.mouse.overlaps(banner) && (curSelected != i)) {
					FlxG.sound.play(Paths.audio("menu_move", "sfx"));
					changeSelection(i);
					break;
				}
			}
		}

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			exiting = true;
			FlxG.sound.play(Paths.audio("menu_cancel", "sfx"));
			borderTop.transitionTween(false, 0, 0.25, function() {
				FlxG.switchState(new funkin.states.MainMenuState());
			});
		}

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) {
			changeSelection(FlxMath.wrap(curSelected + (downJustPressed ? 1 : -1), 0, extras.length - 1));
			FlxG.sound.play(Paths.audio("menu_move", "sfx"));
		}

		if (FlxG.mouse.justPressed) {
			for (i => banner in banners.members) {    
				if (FlxG.mouse.overlaps(banner)) {
					if (i != curSelected)
						changeSelection(i);
					selectExtra();
					break;
				}
			}
		} else if (Controls.justPressed("accept"))
			selectExtra();
	}
}