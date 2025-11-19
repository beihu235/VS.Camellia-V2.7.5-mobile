package funkin.states;

import flixel.math.FlxMath;
import funkin.backend.Meta.MetaFile;

class FreeplayTransition extends flixel.FlxSubState {
	public function new(meta:MetaFile, onClose:Void->Bool, toPlayState:Bool) {
		super();

		var borderTop:FunkinSprite = null;
		var borderBot:FunkinSprite = null;
		if (!toPlayState) {
			borderTop = new FunkinSprite(0, 0, Paths.image("menus/borderTop"));
			borderTop.clipGraphic(0, -FlxG.height, borderTop.graphic.width, borderTop.graphic.height + FlxG.height);
			borderTop.scrollFactor.set();
			add(borderTop);

			borderBot = new FunkinSprite(0, 0, Paths.image("menus/border"));
			borderBot.y -= borderBot.height;
			borderBot.clipGraphic(0, 0, borderBot.graphic.width, borderBot.graphic.height + FlxG.height);
			borderBot.scrollFactor.set();
			add(borderBot);
		}

		var jacketBorder = new FunkinSprite(190, 180, Paths.image('menus/Freeplay/albumBorder'));
		jacketBorder.setGraphicSize(370);
		jacketBorder.updateHitbox();
		jacketBorder.scrollFactor.set();

		var jacketPath:String = 'jackets/${PlayState.songID}';
		if (!Paths.exists('images/$jacketPath.png')) jacketPath = 'jackets/default';

		var jacket = new FunkinSprite(jacketBorder.x + 2 * jacketBorder.scale.x, jacketBorder.y + 2 * jacketBorder.scale.y, Paths.image(jacketPath));
		jacket.setGraphicSize(jacketBorder.width - 4 * jacketBorder.scale.x, jacketBorder.height - 4 * jacketBorder.scale.y);
		jacket.updateHitbox();
		jacket.scrollFactor.set();
		add(jacket);
		add(jacketBorder);
		
		var nameBG = new FunkinSprite(jacket.x + jacket.width + 20, jacket.y);
		nameBG.makeGraphic(1, 1, 0xFFFFFFFF);
		nameBG.scrollFactor.set();
		nameBG.origin.set();
		add(nameBG);

		var nameTxt = new FlxText(nameBG.x + 5, nameBG.y + 3, 520, meta.songName.toUpperCase());
		nameTxt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 64, 0xFF101010, LEFT);
		nameBG.scale.set(0, nameTxt.height + 3);
		nameTxt.scrollFactor.set();
		add(nameTxt);

		var diffBG = new FunkinSprite(nameBG.x, nameBG.y + nameBG.scale.y);
		diffBG.makeGraphic(1, 1, Difficulty.colors[Difficulty.list.indexOf(Difficulty.current)]);
		diffBG.scrollFactor.set();
		diffBG.origin.set();
		add(diffBG);

		final diffs = meta.rating.get((Settings.data.gameplayModifiers["playingSide"] == "Dancer") ? "Camellia" : Difficulty.current);
		final diffIdx = (Settings.data.gameplayModifiers["playingSide"] == "Opponent") ? 1 : 0;
		var diffTxt = new FlxText(
			diffBG.x + 5,
			diffBG.y + 3,
			0,
			Difficulty.current.toUpperCase() + "          " + ((diffs == null || diffs.length < (diffIdx + 1)) ? "?" : (Std.string(Math.floor(diffs[diffIdx])) + (diffs[diffIdx] % 1 != 0 ? "+" : "")))
		);
		diffTxt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 32, 0xFFFFFFFF, LEFT);
		diffBG.scale.set(0, diffTxt.height + 3);
		diffTxt.scrollFactor.set();
		add(diffTxt);

		var gradMask = new funkin.shaders.GradMask();
		gradMask.fromCol.value[3] = 1;
		gradMask.toCol.value[3] = 0;
		gradMask.from.value = [-0.15];
		gradMask.to.value = [-0.05];
		nameTxt.shader = diffTxt.shader = gradMask;

		var chartTitle = new FlxText(nameBG.x, diffBG.y + diffBG.scale.y + 30, 0, "CHART DESIGN");
		chartTitle.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 32, 0xFFFFFFFF, LEFT);
		chartTitle.scrollFactor.set();
		add(chartTitle);
		var chartValue = new FlxText(nameBG.x, chartTitle.y + chartTitle.height, 0, meta.charter.get((Settings.data.gameplayModifiers["playingSide"] == "Dancer") ? "Camellia" : Difficulty.current));
		chartValue.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 32, 0xFFFFFFFF, LEFT);
		chartValue.scrollFactor.set();
		add(chartValue);

		var jacketArtTitle = new FlxText(nameBG.x, chartValue.y + chartValue.height + 10, 0, "JACKET ARTIST");
		jacketArtTitle.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 32, 0xFFFFFFFF, LEFT);
		jacketArtTitle.scrollFactor.set();
		add(jacketArtTitle);
		var jacketArtValue = new FlxText(nameBG.x, jacketArtTitle.y + jacketArtTitle.height, 0, meta.jacket);
		jacketArtValue.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 32, 0xFFFFFFFF, LEFT);
		jacketArtValue.scrollFactor.set();
		add(jacketArtValue);

		if (toPlayState) {
			jacketBorder.x -= 30;
			jacket.x -= 30;
			jacketBorder.alpha = 0;
			jacket.alpha = 0;

			chartTitle.y += 30;
			chartValue.y += 30;
			chartTitle.alpha = 0;
			chartValue.alpha = 0;

			jacketArtTitle.y += 30;
			jacketArtValue.y += 30;
			jacketArtTitle.alpha = 0;
			jacketArtValue.alpha = 0;

			var jacketTwn = Main.tweenManager.tween(jacket, {x: jacket.x + 30, alpha: 1}, 0.5, {ease: FlxEase.quartOut});
			Main.tweenManager.tween(jacketBorder, {x: jacketBorder.x + 30, alpha: 1}, 0.5, {ease: FlxEase.quartOut});

			var nameTwn = Main.tweenManager.num(0, 1, 0.5, {ease: FlxEase.cubeOut, startDelay: jacketTwn.duration * 0.75}, function(num) {
				nameBG.scale.x = (nameTxt.width + 10) * num;
				diffBG.scale.x = (diffTxt.width + 10) * num;
				gradMask.to.value[0] = num * 1.15 - 0.05;
				gradMask.from.value[0] = gradMask.to.value[0] - 0.1;
			});

			var chartTwn = Main.tweenManager.tween(chartTitle, {y: chartTitle.y - 30, alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: nameTwn.startDelay + nameTwn.duration * 0.5});
			Main.tweenManager.tween(chartValue, {y: chartValue.y - 30, alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: chartTwn.startDelay});
			var artTwn = Main.tweenManager.tween(jacketArtTitle, {y: jacketArtTitle.y - 30, alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: chartTwn.startDelay + 0.25});
			Main.tweenManager.tween(jacketArtValue, {y: jacketArtValue.y - 30, alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: artTwn.startDelay});

			new FlxTimer().start(3, function(_) {
				if (onClose())
					close();
			});
		} else {
			var nameTwn = Main.tweenManager.num(1, 0, 0.35, {ease: FlxEase.cubeOut}, function(num) {
				nameBG.scale.x = (nameTxt.width + 10) * num;
				diffBG.scale.x = (diffTxt.width + 10) * num;
				gradMask.to.value[0] = num * 1.15 - 0.05;
				gradMask.from.value[0] = gradMask.to.value[0] - 0.1;
			});

			var jacketTwn = Main.tweenManager.tween(jacket, {x: jacket.x - 30, alpha: 0}, 0.35, {ease: FlxEase.quartOut, startDelay: nameTwn.duration * 0.75});
			Main.tweenManager.tween(jacketBorder, {x: jacketBorder.x - 30, alpha: 0}, 0.35, {ease: FlxEase.quartOut, startDelay: jacketTwn.startDelay});

			var chartTwn = Main.tweenManager.tween(chartTitle, {y: chartTitle.y + 30, alpha: 0}, 0.35, {ease: FlxEase.quartOut, startDelay: jacketTwn.startDelay});
			Main.tweenManager.tween(chartValue, {y: chartValue.y + 30, alpha: 0}, 0.35, {ease: FlxEase.quartOut, startDelay: chartTwn.startDelay});
			var artTwn = Main.tweenManager.tween(jacketArtTitle, {y: jacketArtTitle.y + 30, alpha: 0}, 0.35, {ease: FlxEase.quartOut, startDelay: chartTwn.startDelay + 0.25});
			Main.tweenManager.tween(jacketArtValue, {y: jacketArtValue.y + 30, alpha: 0}, 0.35, {ease: FlxEase.quartOut, startDelay: artTwn.startDelay});

			Main.tweenManager.num(1, 0, 0.35, {ease: FlxEase.cubeOut, startDelay: artTwn.startDelay, onComplete: function(twn) {
				if (onClose())
					close();
			}}, function(num) {
				final height = FlxG.height * num;
				borderTop.y = borderTop.height * (num - 1);
				borderTop.clipGraphic(0, -height, borderTop.graphic.width, borderTop.graphic.height + height);
				borderBot.y = FlxMath.lerp(FlxG.height, -borderBot.height, num);
				borderBot.clipGraphic(0, 0, borderBot.graphic.width, borderBot.graphic.height + height);
			});
		}
	}
}