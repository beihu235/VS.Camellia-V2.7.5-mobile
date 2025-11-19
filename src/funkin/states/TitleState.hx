package funkin.states;

import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxTimer;
import funkin.shaders.TileLine;
import funkin.shaders.DiagonalAlphaMask;

class TitleState extends FunkinState {
	static var seenIntro:Bool = false;
	var accepted:Bool = false;
	var lineShader:TileLine;
	var outlineShader:DiagonalAlphaMask;

	var hoverTmr:Float = 0;
	var mrCamellia:FunkinSprite;
	var logo:FunkinSprite;
	var pressEnter:FunkinSprite;
	var versions:FlxText;
	var titleGroup:FlxSpriteGroup;
	var fadeSprite:FunkinSprite;
	var flashWarning:FlxText;

	var introText:FlxText;
	var phraseImgs:Array<FunkinSprite> = [];

	var mythsYouForgotChanges:Array<Conductor.TimingPoint> = [
		{
			time: 0,
			bpm: 120
		},
		{
			time: 4000,
			bpm: 123
		},
		{
			time: 7902,
			bpm: 125
		},
		{
			time: 9822,
			bpm: 127
		},
		{
			time: 13601,
			bpm: 130
		},
		{
			time: 14525,
			bpm: 131
		},
		{
			time: 15441,
			bpm: 135
		},
		{
			time: 16329,
			bpm: 145
		},
		{
			time: 17157,
			bpm: 150
		}
		// don't need the other half of the changes because nothing happens
	];

	var randomPhrase:Array<String> = [];

	override function create():Void {
		//FreeplayState.preloadAlbumCovers();

		add(titleGroup = new FlxSpriteGroup());

		var bg = new FunkinSprite(0, 0, Paths.image('menus/Title/bg'));
		bg.scale.set(0.5, 0.5);
		bg.updateHitbox();
		bg.screenCenter();
		titleGroup.add(bg);

		if (!Settings.data.reducedQuality) {
			var bgOutline = new FunkinSprite(0, 0, Paths.image('menus/Title/bg outline'));
			bgOutline.scale.set(0.51, 0.51);
			bgOutline.updateHitbox();
			bgOutline.screenCenter();
			bgOutline.y += 5;
			outlineShader = new DiagonalAlphaMask();
			bgOutline.shader = outlineShader;
			titleGroup.add(bgOutline);

			var lineBG = new FunkinSprite();
			lineBG.makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
			lineShader = new TileLine();
			lineShader.color1.value = [0, 0, 0, 0.375];
			lineShader.color2.value = [0, 0, 0, 0.1];
			lineShader.density.value = [200.0];
			lineShader.time.value = [0];
			lineBG.shader = lineShader;
			titleGroup.add(lineBG);
		}

		var vignette = new FunkinSprite(0, 0, Paths.image('menus/Title/vignette'));
		vignette.scale.set(0.5, 0.5);
		vignette.updateHitbox();
		titleGroup.add(vignette);
		vignette.screenCenter();

		mrCamellia = new FunkinSprite(0, 0, Paths.image('menus/Title/mr camellia'));
		titleGroup.add(mrCamellia);
		mrCamellia.scale.set(0.5, 0.5);
		mrCamellia.updateHitbox();
		mrCamellia.screenCenter(X);

		logo = new FunkinSprite(0, 0, Paths.image('menus/Title/logo'));
		titleGroup.add(logo);
		logo.scale.set(0.5, 0.5);
		logo.updateHitbox();
		logo.screenCenter();

		pressEnter = new FunkinSprite(0, 550, Paths.image('menus/Title/press enter'));
		pressEnter.scale.set(0.5, 0.5);
		pressEnter.updateHitbox();
		pressEnter.screenCenter(X);
		titleGroup.add(pressEnter);

		versions = new FlxText(4, 0, 400, 'Vs. Camellia 2.75\nNever2x 1.0.0', 16);
		versions.alignment = 'right';
		versions.font = Paths.font('Rockford-NTLG Light.ttf');
		versions.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versions.y = FlxG.height - versions.height - 4;
		versions.x = FlxG.width - versions.width - 4;
		titleGroup.add(versions);

		Meta.cacheFiles(true);

		if (seenIntro) {
			openSubState(new BasicBorderTransition(TOP, true, 0.8));
			persistentUpdate = true;
			return;
		}
		skipMusicCheck = true;

		super.create();

		Conductor.timingPoints = mythsYouForgotChanges.copy();
		titleGroup.visible = false;

		add(introText = new FlxText(0, 0, FlxG.width, '', 50));
		introText.font = Paths.font('Rockford-NTLG Light.ttf');
		introText.alignment = 'center';

		engineLogo = new FunkinSprite(FlxG.width * 0.5, 0, Paths.image('menus/Title/engineLogoMinimal'));
		engineLogo.x -= engineLogo.width * 0.5;
		engineLogo.scale.set(0.5, 0.5);
		engineLogo.alpha = 0;
		add(engineLogo);

		add(fadeSprite = new FunkinSprite().makeGraphic(1, 1, Settings.data.flashingLights ? FlxColor.WHITE : 0xFF191919));
		fadeSprite.scale.set(FlxG.width, FlxG.height);
		fadeSprite.updateHitbox();
		fadeSprite.alpha = 0;

		randomPhrase = FlxG.random.getObject(getIntroTexts());
		FlxG.mouse.visible = false;

		add(flashWarning = new FlxText(0, 0, FlxG.width, 'WARNING!\n\nThis mod contains flashing lights!\nPlease take caution if you\'re affected by epilepsy.', 30));
		flashWarning.font = Paths.font('Rockford-NTLG Light.ttf');
		flashWarning.alignment = 'center';
		flashWarning.alpha = 0;
		flashWarning.screenCenter();

		FlxTween.tween(flashWarning, {alpha: 1}, 2);
		FlxTween.tween(flashWarning, {alpha: 0}, 2, {
			startDelay: 5, 
			onComplete: function(_) {
				skipMusicCheck = false;
				musicCheck();

				remove(flashWarning);
				flashWarning.destroy();
				flashWarning = null;
			}
		});
	}

	function getIntroTexts():Array<Array<String>> 
		return [for (i in Paths.getFileContent('data/introTxt.txt').split('\n')) i.split('--')];
	
	override function update(delta:Float):Void {
		super.update(delta);

		hoverTmr += delta;
		mrCamellia.y = 10 * (Math.sin(hoverTmr + Math.PI * 0.125) * 0.5 + 0.5);
		logo.y = (FlxG.height - logo.height) * 0.5 + 10 * Math.sin(hoverTmr);
		pressEnter.y = 550 + 10 * Math.sin(hoverTmr + Math.PI * 0.25);
		if (lineShader != null) {
			lineShader.time.value[0] += (delta / 64);
			outlineShader.time.value[0] += delta * 0.35;
		}

		if (accepted) return;
		pressEnter.alpha = Math.sin(3 * hoverTmr) * 0.25 + 0.75;

		if (Controls.justPressed('accept') || FlxG.mouse.justPressed) {
			if (!seenIntro) {
				skip();
				return;
			}

			accepted = true;
			FlxG.sound.play(Paths.audio("menu_confirm", 'sfx'));
			if (Settings.data.flashingLights) {
				logo.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
				pressEnter.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
			} else {
				logo.scale.x = logo.scale.y = logo.scale.x * 1.35;
				pressEnter.scale.x = pressEnter.scale.y = pressEnter.scale.x * 1.35;
				FlxTween.tween(logo.scale, {x: logo.scale.x / 1.35, y: logo.scale.y / 1.35}, 0.75, {ease: FlxEase.cubeOut});
				FlxTween.tween(pressEnter.scale, {x: pressEnter.scale.x / 1.35, y: pressEnter.scale.y / 1.35}, 0.75, {ease: FlxEase.cubeOut});
			}

			var rouxls = new FunkinSprite(FlxG.width * 0.5 - 1, 0);
			rouxls.makeGraphic(1, 1, 0xFFFFFFFF);
			rouxls.scale.set(2, FlxG.height);
			rouxls.updateHitbox();
			titleGroup.insert(titleGroup.members.indexOf(logo), rouxls);

			FlxTween.tween(rouxls.scale, {x: FlxG.width}, 0.25, {ease: FlxEase.quartOut});
			FlxTween.color(rouxls, 1, (Settings.data.flashingLights) ? 0xFFFFFFFF : 0xFF191919, 0xFF000000, {ease: FlxEase.cubeOut});

			for (fade in [logo, pressEnter, versions])
				FlxTween.tween(fade, {alpha: 0}, 2, {ease: FlxEase.cubeIn});

			if (FlxG.save.data.seenDisclaimer) {
				new FlxTimer().start(1.3, tmr -> {
					openSubState(new BasicBorderTransition(TOP, false, 0.8, 0.3, function() {
						FlxG.switchState(new MainMenuState());
					}));
				});
			} else {
				new FlxTimer().start(2.5, tmr -> {
					FlxG.switchState(new DisclaimerState());
				});
			}
		}
	}

	var engineLogo:FunkinSprite;
	override function stepHit(step:Int) {
		if (seenIntro) return;

		switch step {
			case 16:
				introText.text = 'Vs. Camellia Team\nPresents';
				introText.screenCenter();

			case 20:
				FlxTween.tween(introText, {alpha: 0}, 1.500);

			case 32:
				FlxTween.cancelTweensOf(introText);
				introText.alpha = 1;
				introText.text = 'After years\nin the making';
				introText.screenCenter();

			case 36:
				FlxTween.tween(introText, {alpha: 0}, 1.500);

			case 48:
				FlxTween.cancelTweensOf(introText);
				introText.alpha = 1;
				introText.text = 'Rebuilt\nFrom the ground up';
				introText.screenCenter();

			case 52:
				FlxTween.tween(introText, {alpha: 0}, 1.500);

			case 64:
				FlxTween.cancelTweensOf(introText);
				introText.alpha = 1;
				introText.text = 'Now running on\n ';
				introText.screenCenter();

				engineLogo.y = introText.y + 15;
				engineLogo.alpha = 1;

			case 68:
				FlxTween.tween(introText, {alpha: 0}, 1.500);
				FlxTween.tween(engineLogo, {alpha: 0}, 1.500);

			case 80:
				FlxTween.cancelTweensOf(engineLogo);
				remove(engineLogo);

				FlxTween.cancelTweensOf(introText);
				introText.alpha = 1;
				introText.text = randomPhrase[0];
				introText.screenCenter();

			case 96:
				for (i in 1...randomPhrase.length) {
					if (randomPhrase[i].startsWith("IMG>")) {
						var y =  phraseImgs.length > 0 ? phraseImgs[phraseImgs.length - 1].y + phraseImgs[phraseImgs.length - 1].height : introText.y + introText.height;
						var spr = new FunkinSprite(FlxG.width * 0.5, y + 10, Paths.image('menus/Title/introBull/${randomPhrase[i].substring(4, randomPhrase[i].length).trim()}'));
						spr.x -= spr.width * 0.5;
						add(spr);
						phraseImgs.push(spr);
					} else {
						introText.text += '\n${randomPhrase[i]}';
						introText.screenCenter();
					}
				}

			case 112:
				FlxTween.tween(introText, {alpha: 0}, 0.5); // this doesnt work bc you set the intro text to blank
				for (img in phraseImgs) { //whoopsie daisy
					remove(img, true);
					img.destroy();
				}
				phraseImgs.resize(0);
				introText.text = '';

			case 124:
				introText.alpha = 1;
				introText.text = 'Vs. Camellia';
				introText.screenCenter();

			case 128:
				introText.text += '\n2.75';
				introText.screenCenter();

			case 136:
				introText.text += '\nWe hope you enjoy!';
				introText.screenCenter();

			case 140:
				FlxTween.tween(fadeSprite, {alpha: 1}, 0.414);
				if (!Settings.data.flashingLights)
					FlxTween.tween(FlxG.camera, {zoom: 1.2}, 0.414, {ease: FlxEase.quadOut});

			case 144: skip();
		}
	}

	function skip() {
		for (img in phraseImgs) { //whoopsie daisy
			remove(img, true);
			img.destroy();
		}
		phraseImgs.resize(0);
		remove(engineLogo);

		if (flashWarning != null) {
			FlxTween.cancelTweensOf(flashWarning);
			remove(flashWarning);
			flashWarning.destroy();
			flashWarning = null;

			skipMusicCheck = false;
			musicCheck();
		}

		seenIntro = true;
		titleGroup.visible = true;
		introText.visible = false;
		
		FlxTween.cancelTweensOf(fadeSprite);
		fadeSprite.alpha = 1;
		FlxTween.tween(fadeSprite, {alpha: 0}, 0.15);

		if (!Settings.data.flashingLights) {
			FlxTween.cancelTweensOf(FlxG.camera);
			FlxG.camera.zoom = 1.2;
			FlxTween.tween(FlxG.camera, {zoom: 1}, 0.5, {ease: FlxEase.quadOut});
		}

		FlxG.mouse.visible = true;

		if (Conductor.inst.time < 17160 - 300) Conductor.inst.time = 17160;
	}
}