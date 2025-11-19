package funkin.states;

import funkin.shaders.TileLine;

class WarningSubstate extends FlxSubState {
	var optionArr:Array<String> = ["danger_confirm1", "danger_cancel"];

	var curSelected:Int = 1;
	var extraSpaceForTheTriangleRotatingThingie:Float = 30;
	var longestWidth:Float = 0;
	var rectTmr:Float = 0;

	var lineShader:TileLine;
	var rects:Array<FunkinSprite> = [];
	var title:FlxText;
	var descTxt:FlxText;
	var piss:FlxTypedSpriteGroup<FlxText>;
	var selectTriangle:FunkinSprite;
	var optionBG:FunkinSprite;

	var desc:String;
	var action:Void->Void;

	public function new(desc:String, action:Void->Void) {
		super();
		this.desc = _formatT(desc, [","]);
		this.action = action;
	}

	override function create() {
		super.create();

		var bg = new FunkinSprite();
		if (!Settings.data.reducedQuality) {
			bg.makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
			lineShader = new TileLine();
			lineShader.color1.value = [0, 0, 0, 0.75 * 0.75];
			lineShader.color2.value = [0, 0, 0, 0.75];
			lineShader.density.value = [200.0];
			lineShader.time.value = [0];
			bg.shader = lineShader;
		} else {
			bg.makeGraphic(1, 1, 0xA0000000);
			bg.scale.set(FlxG.width, FlxG.height);
			bg.updateHitbox();
		}
		add(bg);

		for (i in 0...3) {
			var rect = new FunkinSprite(FlxG.width * 0.5, FlxG.height * 0.5, Paths.image("menus/yesThisIsAnImage"));
			rect.x -= rect.width * 0.5;
			rect.y -= rect.height * 0.5;
			rect.antialiasing = false;
			rect.scale.set();
			rect.alpha -= 0.15 * i;
			add(rect);
			rects.push(rect);
		}

		add(title = new FlxText(FlxG.width * 0.5, rects[0].y + 20, 0, _t("danger_title")));
		title.setFormat(Paths.font('HelveticaNowDisplay-Black.ttf'), 72, 0xFFFFFFFF, CENTER);
		title.x -= title.width * 0.5;
		title.scale.x = 1.15;

		add(descTxt = new FlxText(FlxG.width * 0.5, title.y + title.height + 10, rects[0].width - 20, desc));
		descTxt.setFormat(Paths.font('Rockford-NTLG Extralight.ttf'), 28, 0xFFFFFFFF, CENTER);
		descTxt.x -= descTxt.width * 0.5;

		piss = new FlxTypedSpriteGroup<FlxText>();
		piss.setPosition(100, 150);
		for (i in 0...optionArr.length) {
			final txt:FlxText = new FlxText(0, (i * 45), 0, _t(optionArr[i]));
			txt.setFormat(Paths.font(i == curSelected ? 'Rockford-NTLG Medium.ttf' : 'Rockford-NTLG Light.ttf'), 40, (i == curSelected ? 0xFF000000 : 0xFFFFFFFF), LEFT);
			if (txt.width > longestWidth) longestWidth = txt.width;
			piss.add(txt);
		}
		piss.screenCenter(X);
		piss.y = rects[0].y + rects[0].height - 40 - piss.height;

		add(optionBG = new FunkinSprite(piss.x - extraSpaceForTheTriangleRotatingThingie, piss.members[curSelected].y));
		optionBG.makeGraphic(1, 1, FlxColor.WHITE);
		optionBG.scale.set(0, piss.members[curSelected].height - 5);
		optionBG.origin.set();

		add(selectTriangle = new FunkinSprite(piss.members[curSelected].x, optionBG.y + optionBG.scale.y * 0.5, Paths.image("menus/triangle")));
		selectTriangle.color = 0xFF000000;
		selectTriangle.flipX = true;
		selectTriangle.origin.x += 3; // UUUUUGGGGGGGGHHHHHHHHH
		selectTriangle.scale.set(0.6, 0.6);
		selectTriangle.y -= selectTriangle.height * 0.5;

		add(piss);

		FlxG.sound.play(Paths.audio("menu_deletedata", "sfx"));

		for (item in [cast (bg, FlxSprite), title, descTxt]) {
			item.alpha = 0;
			FlxTween.tween(item, {alpha: 1}, 0.5, {ease: FlxEase.cubeOut});
		}
	}

	override function update(delta:Float) {
		super.update(delta);

		rectTmr += delta;
		for (i in 0...rects.length) {
			final sin = Math.sin(rectTmr + 0.7 * i);
			rects[i].scale.x = rects[i].scale.y = FlxMath.lerp(rects[i].scale.x, 1 + (sin * 0.1 + 0.1), delta * 20);

			if (!Settings.data.reducedQuality) {
				final skewSin = Math.sin(rectTmr * 1.5 + 1.05 * i);
				rects[i].skew.set(skewSin * 1.5, skewSin * 1.5);
			}
		}

		optionBG.scale.x = FlxMath.lerp(optionBG.scale.x, longestWidth + 20 + extraSpaceForTheTriangleRotatingThingie, delta * 15);
		selectTriangle.x = FlxMath.lerp(selectTriangle.x, optionBG.x + 5, delta * 15);

		if (!Settings.data.reducedQuality) {
			lineShader.time.value[0] = lineShader.time.value[0] + (delta / 64);
			selectTriangle.angle += delta * 160;
		}

		final upJustPressed = Controls.justPressed("ui_up");

		if (upJustPressed || Controls.justPressed("ui_down")) {
			piss.members[curSelected].color = optionBG.color;
			piss.members[curSelected].font = Paths.font('Rockford-NTLG Light.ttf');
			curSelected = FlxMath.wrap(curSelected + (upJustPressed ? -1 : 1), 0, piss.length - 1);
			piss.members[curSelected].color = 0xFF000000;
			piss.members[curSelected].font = Paths.font('Rockford-NTLG Medium.ttf');
	
			var curText:FlxText = piss.members[curSelected];
			optionBG.scale.set(0, curText.height - 5);
			optionBG.y = curText.y;
			selectTriangle.setPosition(curText.x, optionBG.y + (optionBG.scale.y - selectTriangle.height) * 0.5);
			FlxG.sound.play(Paths.audio("menu_move", "sfx"));
		} else if (Controls.justPressed("accept")) {
			switch (optionArr[curSelected]) {
				case "danger_confirm1":
					optionBG.scale.x = 0;
					optionBG.color = 0xFFFFAFAF;
					optionArr[0] = "danger_confirm2";

					piss.members[0].text = _t(optionArr[0]);
					piss.members[1].color = optionBG.color;

					longestWidth = Math.max(longestWidth, piss.members[0].width);
					selectTriangle.setPosition(piss.members[0].x, optionBG.y + (optionBG.scale.y - selectTriangle.height) * 0.5);

					FlxG.sound.play(Paths.audio("menu_deletedata", "sfx")).pitch = 1.5;
				case "danger_confirm2":
					action();
					close();
					FlxG.sound.play(Paths.audio("popup_select", "sfx"));
				case "danger_cancel":
					close();
					FlxG.sound.play(Paths.audio("popup_select", "sfx"));
			}
		}
	}
}