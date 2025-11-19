package funkin.states;

class DisclaimerState extends FunkinState {
	override function create():Void {
		super.create();

		FlxG.save.data.seenDisclaimer = true;
		Settings.save();

		var bg = new FunkinSprite(0, 0, Paths.image('menus/BGopt'));
		add(bg);
		bg.alpha = 0;

		var camelliaLogo = new FunkinSprite(1245, 669.5, Paths.image('menus/camelliaLogo'));
		camelliaLogo.scale.set(0.5, 0.5);
		camelliaLogo.updateHitbox();
		camelliaLogo.scrollFactor.set();
		camelliaLogo.x -= camelliaLogo.width;
		camelliaLogo.y -= camelliaLogo.height * 0.5;
		add(camelliaLogo);
		camelliaLogo.alpha = 0;
		camelliaLogo.x += 30;

		//i KNOW tacto wants to use LineSeed on this but please, its a one time prompt for now and you cant even see it on JP atm
		//lets not break the english one entirely over that we can sort that out in 3.0
		var text = new FlxText(0, 0, FlxG.width, _formatT("disclaimer", [",", _t("accept").toUpperCase()]), 24);
		text.font = Paths.font('Rockford-NTLG Light.ttf'); 
		text.alignment = 'center';
		text.screenCenter();
		add(text);
		text.alpha = 0;
		text.y -= 30;

		FlxTween.tween(bg, {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
		FlxTween.tween(camelliaLogo, {alpha: 1, x: camelliaLogo.x - 30}, 0.75, {startDelay: 0.25, ease: FlxEase.cubeOut});
		FlxTween.tween(text, {alpha: 1, y: text.y + 30}, 0.75, {startDelay: 0.25, ease: FlxEase.cubeOut});
	}

	var pressed:Bool = false;
	override function update(delta:Float) {
		super.update(delta);

		if (pressed) return;

		if (Controls.justPressed('accept') || FlxG.mouse.justPressed) {
			pressed = true;
			FlxG.sound.play(Paths.audio("popup_select", "sfx"));

			var border = new FunkinSprite(0, 0, Paths.image("menus/borderTop"));
			border.clipGraphic(0, -FlxG.height, border.frameWidth, border.frameHeight + FlxG.width);
			border.updateHitbox();
			border.y -= border.height;
			add(border);

			var twn = FlxTween.tween(border, {y: 0}, 0.75, {ease: FlxEase.cubeIn, onComplete: function(twn) {
				new FlxTimer().start(0.25, function(tmr) {
					FlxG.switchState(new MainMenuState());
				});
			}});
		}
	}
}