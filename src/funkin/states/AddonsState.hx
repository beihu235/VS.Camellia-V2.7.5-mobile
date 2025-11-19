package funkin.states;

import flixel.graphics.FlxGraphic;
import funkin.objects.FunkinSprite;
import funkin.objects.ui.SwirlBG;
import funkin.objects.ui.Border;
import funkin.shaders.TileLine;
import funkin.shaders.GradMask;

class AddonsState extends FunkinState {
	var iconGraphics:Array<FlxGraphic> = [];

	var borderTop:Border;
	var borderBot:Border;

	var bg:SwirlBG;
	var lineShader:TileLine;

	var theresNothin:FunkinSprite;
	var tmr:Float = 0.0;

	var icons:FlxTypedGroup<FunkinSprite>;
	var coloUrs:FlxTypedGroup<FunkinSprite>; // dont worry about the capital U
	var titles:FlxTypedGroup<FlxText>;
	var descs:FlxTypedGroup<FlxText>;
	var warnings:FlxTypedGroup<FunkinSprite>;

	static var curSelected:Int = 0;
	var draggedOnce:Bool = false;
	var dragging:Bool = false;
	var dragY:Float = -1;

	final colorON:FlxColor = FlxColor.fromRGB(54, 255, 101);
	final colorOFF:FlxColor = FlxColor.fromRGB(255, 28, 70);

	override function create():Void {
		super.create();

		add(bg = new SwirlBG(0xFF363636, 0xFF98FBAF));
		final lastSpeed = bg.speed;

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

		var addonsTile:flixel.addons.display.FlxBackdrop = new flixel.addons.display.FlxBackdrop(Paths.image('menus/Addons/bigText'), Y);
		addonsTile.velocity.y = 25;
		add(addonsTile);

		add(icons = new FlxTypedGroup<FunkinSprite>());
		add(coloUrs = new FlxTypedGroup<FunkinSprite>());
		add(titles = new FlxTypedGroup<FlxText>());
		add(descs = new FlxTypedGroup<FlxText>());
		add(warnings = new FlxTypedGroup<FunkinSprite>());
		loadAddons();

		add(theresNothin = new FunkinSprite(FlxG.width * 0.5, FlxG.height * 0.5, Paths.image("menus/Addons/noAddons")));
		theresNothin.x -= theresNothin.width * 0.5;
		theresNothin.y -= theresNothin.height * 0.5;
		theresNothin.visible = icons.length <= 0;

		var whatBG = new FunkinSprite(45, 460);
		whatBG.makeGraphic(1, 1, 0x80000000);
		whatBG.scale.set(425, 190);
		whatBG.updateHitbox();
		add(whatBG);

		var whatTitle = new FlxText(whatBG.x + 20, whatBG.y + 10, whatBG.width - 40, _t("addons_what_title"));
		whatTitle.setFormat(Paths.font("HelveticaNowDisplay-Black.ttf"), 28, 0xFFFFFFFF, LEFT);
		add(whatTitle);

		var whatDesc = new FlxText(whatTitle.x, whatTitle.y + whatTitle.height, whatTitle.fieldWidth, _t("addons_what_desc"));
		whatDesc.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 18, 0xFFFFFFFF, LEFT);
		add(whatDesc);

		var warningTxt = new FlxText(whatTitle.x, whatBG.y + whatBG.height - 20, whatTitle.fieldWidth, "          " + _t("license_warning"));
		warningTxt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 14, 0xFFFFFFFF, LEFT);
		warningTxt.y -= warningTxt.height;
		add(warningTxt);

		var miniNo = new FunkinSprite(warningTxt.x, warningTxt.y, Paths.image("menus/Addons/licenseWarning"));
		miniNo.scale.scale(0.25);
		miniNo.updateHitbox();
		add(miniNo);

		add(borderTop = new Border(true, "INSTALL ADDITIONAL ASSETS • ", "Addons"));
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

		var changePackTxt = new FlxText((downButton.x + downButton.width) + 5, downButton.y, 0, _t("addons_scroll"), 16);
		changePackTxt.font = Paths.font('LineSeed.ttf');
		changePackTxt.scrollFactor.set(0, 1);
		add(changePackTxt);

		var rButton = new FunkinSprite(changePackTxt.x + changePackTxt.width + 50, buttonY, Paths.image('menus/keyIndicator'));
		rButton.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
		rButton.scrollFactor.set(0, 1);
		add(rButton);

		var rTxt = new FlxText(rButton.x + rButton.width * 0.5, rButton.y + rButton.height * 0.5, 0, "R");
		rTxt.setFormat(Paths.font('LineSeed.ttf'), 16, 0xFF000000, LEFT);
		rTxt.x -= rTxt.width * 0.5;
		rTxt.y -= rTxt.height * 0.5;
		rTxt.scrollFactor.set(0, 1);
		add(rTxt);

		var reloadTxt = new FlxText((rButton.x + rButton.width) + 5, rButton.y, 0, _t("reload"), 16);
		reloadTxt.font = Paths.font('LineSeed.ttf');
		reloadTxt.scrollFactor.set(0, 1);
		add(reloadTxt);

		if (!theresNothin.visible) {
			curSelected = Std.int(FlxMath.bound(curSelected, 0, icons.length - 1));
			changeSelection();
		}
		borderTop.transitionTween(true);
	}

	override function update(delta:Float):Void {
		super.update(delta);

		if (curSelected < 0) return;

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			Settings.data.addonsOff = [];
			for (addon in Addons.list) {
				if (addon.disabled)
					Settings.data.addonsOff.push(addon.id);
			}
			Settings.save();

			final cacheSel = curSelected;
			curSelected = -1;
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
			borderTop.transitionTween(false, 0, 0.25, function() {
				curSelected = cacheSel;
				FlxG.switchState(new funkin.states.ExtrasState());
			});
			return;
		} else if (FlxG.keys.justPressed.R) {
			while (icons.length > 0) {
				final icon = icons.members[0];
				final color = coloUrs.members[0];
				final title = titles.members[0];
				final desc = descs.members[0];

				icons.remove(icon, true);
				coloUrs.remove(color, true);
				titles.remove(title, true);
				descs.remove(desc, true);

				icon.destroy();
				color.destroy();
				title.destroy();
				desc.destroy();

				final warn = warnings.members[0];
				warnings.remove(warn);
				if (warn != null)
					warn.destroy();
			}

			Addons.reload();
			loadAddons();

			theresNothin.visible = icons.length <= 0;
			if (!theresNothin.visible) {
				curSelected = Std.int(FlxMath.bound(curSelected, 0, icons.length - 1));
				changeSelection();
			}
		}

		tmr += delta;
		if (theresNothin.visible) {
			theresNothin.alpha = 0.85 + 0.15 * Math.sin(tmr);
			return;
		}

		if (FlxG.mouse.justPressed && !theresNothin.visible) {
			dragging = true;
			dragY = FlxG.mouse.screenY;
		} else if (dragging) {
			final dist = Math.round((FlxG.mouse.screenY - dragY) / 120);

			if (dist != 0) {
				draggedOnce = true;
				dragY += 120 * dist;
				changeSelection(-dist);
				FlxG.sound.play(Paths.audio("menu_move", "sfx"));
			}
		}

		var upJustPressed:Bool = Controls.justPressed('ui_up');
		if (FlxG.mouse.wheel != 0 || upJustPressed || Controls.justPressed('ui_down')) {
			changeSelection(FlxG.mouse.wheel != 0 ? -FlxG.mouse.wheel : (upJustPressed ? -1 : 1));
			FlxG.sound.play(Paths.audio("menu_move", "sfx"));
		} else if (Controls.justPressed('accept')) {
			FlxG.sound.play(Paths.audio("menu_setting_tick", "sfx"));

			Addons.list[curSelected].disabled = !Addons.list[curSelected].disabled;
			coloUrs.members[curSelected].color = (Addons.list[curSelected].disabled ? colorOFF : colorON);
		}

		for (i => icon in icons.members) {
			icon.setPosition(
				FlxMath.lerp(icon.x, 675 - 35 * (i - curSelected), delta * 15),
				FlxMath.lerp(icon.y, (FlxG.height - icon.height) * 0.5 + 190 * (i - curSelected), delta * 15),
			);
			coloUrs.members[i].setPosition(
				icon.x - coloUrs.members[i].width,
				icon.y
			);
			final title = titles.members[i];
			title.setPosition(
				icon.x + 15,
				icon.y + 10
			);
			descs.members[i].setPosition(
				title.x,
				title.y + title.height - 5
			);

			if (warnings.members[i] != null)
				warnings.members[i].setPosition(title.x + title.width + 10, title.y + (title.height - warnings.members[i].height) * 0.5);

			if (FlxG.mouse.justReleased && !draggedOnce && FlxG.mouse.x >= coloUrs.members[i].x && FlxG.mouse.x <= icon.x + icon.width && FlxG.mouse.y >= icon.y && FlxG.mouse.y <= icon.y + icon.height) {
				if (i != curSelected) {
					changeSelection(i - curSelected);
					FlxG.sound.play(Paths.audio("menu_move", "sfx"));
				} else {
					FlxG.sound.play(Paths.audio("menu_setting_tick", "sfx"));

					Addons.list[curSelected].disabled = !Addons.list[curSelected].disabled;
					coloUrs.members[curSelected].color = (Addons.list[curSelected].disabled ? colorOFF : colorON);
				}
			}
		}

		if (dragging && FlxG.mouse.justReleased) {
			dragging = false;
			draggedOnce = false;
			dragY = -1;
		}
	}

	function changeSelection(?dir:Int = 0) {
		icons.members[curSelected].alpha = 0.45;
		coloUrs.members[curSelected].alpha = 0.45;
		titles.members[curSelected].color = 0xFFAAAAAA;
		descs.members[curSelected].color = 0xFFAAAAAA;
		if (warnings.members[curSelected] != null)
			warnings.members[curSelected].color = 0xFFAAAAAA;

		curSelected = FlxMath.wrap(curSelected + dir, 0, Addons.list.length - 1);

		icons.members[curSelected].alpha = 0.8;
		coloUrs.members[curSelected].alpha = 0.8;
		titles.members[curSelected].color = 0xFFFFFFFF;
		descs.members[curSelected].color = 0xFFFFFFFF;
		if (warnings.members[curSelected] != null)
			warnings.members[curSelected].color = 0xFFFFFFFF;
	}

	function loadAddons() {
		for (graph in iconGraphics)
			Paths.destroyAsset("MODicon", graph);
		iconGraphics = [];

		var backupIcon = Paths.image("menus/Addons/backupIcon");
		for (i => file in Addons.list) {
			if (FileSystem.exists('addons/${file.id}/icon.png')) {
				final bitmapO = funkin.backend.OptimizedBitmapData.fromFile('addons/${file.id}/icon.png');
				final graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmapO, false, 'addons/${file.id}/icon.png');
				graph.persist = true;
				graph.destroyOnNoUse = false;
				iconGraphics.push(graph);
			} else
				iconGraphics.push(null);

			final graphic = iconGraphics[i] != null ? iconGraphics[i] : backupIcon;
			var icon = new FunkinSprite(FlxG.width, FlxG.height * 0.5 + 190 * (i - curSelected), graphic);
			icon.setGraphicSize(0, 175);
			icon.clipGraphic(0, 0, 585 / icon.scale.x, icon.frameHeight);
			icon.updateHitbox();
			icon.y -= icon.height * 0.5;
			icon.alpha = 0.45;
			var grad = new GradMask();
			grad.fromCol.value[3] = 1.0;
			grad.toCol.value = [17 / 255, 17 / 255, 17 / 255, 1.0];
			grad.from.value[0] = 1.0 - (75 / icon.scale.x / graphic.width);
			icon.shader = grad;
			icons.add(icon);


			var color = new FunkinSprite(icon.x - 10, icon.y);
			color.makeGraphic(1, 1, 0xFFFFFFFF);
			color.scale.set(10, icon.height);
			color.updateHitbox();
			color.color = file.disabled ? colorOFF : colorON;
			coloUrs.add(color);
			color.alpha = 0.45;

			var title = new FlxText(icon.x + 15, icon.y + 10, 0, file.name.toUpperCase());
			title.setFormat(Paths.font('HelveticaNowDisplay-Black.ttf'), 36, 0xFFAAAAAA, LEFT);
			titles.add(title);

			var desc = new FlxText(title.x, title.y + title.height - 5, (icon.width - 30), file.description);
			desc.setFormat(Paths.font('Rockford-NTLG Light.ttf'), 16, 0xFFAAAAAA, LEFT);
			descs.add(desc);

			if (file.licensed) {
				var warning = new FunkinSprite(title.x + title.width + 10, title.y + title.height * 0.5, Paths.image("menus/Addons/licenseWarning"));
				warning.scale.scale(0.5);
				warning.updateHitbox();
				warning.y -= warning.height * 0.5;
				warning.color = 0xFFAAAAAA;
				warnings.insert(warnings.length, warning);
			} else {
				// kinda hacky to make a blank spot butttt
				// oh and this blank making is also why i use insert
				warnings.insert(warnings.length, icon);
				warnings.remove(icon, false);
			}
		}
	}
}
