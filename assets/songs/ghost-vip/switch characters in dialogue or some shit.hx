import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import funkin.objects.Character;
import funkin.Dialogue;

function create() {
	game.subStateOpened.add(openSubstate);
}

function openSubstate(substate) {
	if (!Std.isOfType(substate, Dialogue)) return;
	
	var fakeGf = new Character(game.gf.x, game.gf.y, 'gf');
	game.add(fakeGf);
	var fakeCamellia = new Character(game.dad.x, game.dad.y, 'camellia');
	game.add(fakeCamellia);
	var fakeBf = new Character(game.bf.x, game.bf.y, 'bf');
	game.add(fakeBf);
	game.dad.visible = false;
	game.bf.visible = false;
	game.gf.visible = false;

	var ogZoom = FlxG.camera.zoom;
	var darkBG = null;
	var darkenTwn = null;

	game.subStateOpened.remove(openSubstate);
	substate.onNewMessage = function(index, message) {

		switch (index) {
			case 1: FlxG.sound.play(Paths.audio('cheer1', 'sfx/dialogue'));
			case 11:
				if (Settings.data.flashingLights) return;

				darkBG = new FunkinSprite();
				darkBG.makeGraphic(1, 1, 0x80000000);
				darkBG.scale.set(FlxG.width / FlxG.camera.zoom, FlxG.height / FlxG.camera.zoom);
				darkBG.updateHitbox();
				darkBG.screenCenter();
				darkBG.scrollFactor.set();
				game.addBehindObject(darkBG, fakeGf);

				darkenTwn = FlxTween.num(1, 0, 0.35, {ease: FlxEase.cubeOut}, function(num) {
					substate.bg.alpha = 0.6 * num;
					substate.characters[0].alpha = substate.characters[3].alpha = num;
					game.camHUD.alpha = num;
					FlxG.camera.zoom = FlxMath.lerp(1.3, ogZoom, num);

					darkBG.alpha = 1 - num;
					var offset = 255 - 255 * num;
					fakeGf.setColorTransform(num, num, num, 1, offset, offset, offset, 0);
					fakeCamellia.setColorTransform(num, num, num, 1, offset, offset, offset, 0);
					fakeBf.setColorTransform(num, num, num, 1, offset, offset, offset, 0);
				});
			case 12:
				substate.bg.alpha = 0.6;
				
				if (darkenTwn != null)
					darkenTwn.cancel();
				
				var ogAlpha = [];
				for (obj in substate.members) {
					if (Std.isOfType(obj, FlxSprite) && obj != substate.charsLayered) {
						ogAlpha.push(obj.alpha);
						obj.alpha = 0;
					} else
						ogAlpha.push(1);
				}
				var charAlphas = [];
				for (i in 0...substate.characters.length) {
					substate.characters[i].alpha = 0;
					charAlphas.push(i == message.side ? 1 : 0.5);
				}

				substate.paused = true;
	
				if (Settings.data.flashingLights)
					game.camOther.flash(0xFFFFFFFF, 2);
				else {
					FlxTween.tween(FlxG.camera, {zoom: ogZoom}, 0.5, {ease: FlxEase.quartOut});
					FlxTween.num(0, 1, 0.75, {ease: FlxEase.cubeOut, onComplete: function(twn) {
						game.remove(darkBG, true);
						darkBG.destroy();
					}}, function(num) {
						darkBG.alpha = 1 - num;
						game.camHUD.alpha = num;

						var offset = 255 - 255 * num;
						game.gf.setColorTransform(num, num, num, 1, offset, offset, offset, 0);
						game.dad.setColorTransform(num, num, num, 1, offset, offset, offset, 0);
						game.bf.setColorTransform(num, num, num, 1, offset, offset, offset, 0);
					});
				}
				FlxG.sound.play(Paths.audio("snap", "sfx/dialogue"));
				game.remove(fakeCamellia);
				game.remove(fakeGf);
				game.remove(fakeBf);
				fakeCamellia.destroy();
				fakeGf.destroy();
				fakeBf.destroy();
	
				game.dad.visible = true;
				game.bf.visible = true;
				game.gf.visible = true;
	
				new FlxTimer().start(2, function(_) {
					for (i in 0...substate.members.length) {
						var obj = substate.members[i];
						if (Std.isOfType(obj, FlxSprite))
							FlxTween.tween(obj, {alpha: ogAlpha[i]}, 1);
					}
					for (i in 0...substate.characters.length)
						FlxTween.tween(substate.characters[i], {alpha: charAlphas[i]}, 1);
					new FlxTimer().start(1, function(_) substate.paused = false);
				});
			case 18: FlxG.sound.play(Paths.audio('cheer', 'sfx/dialogue'));
		};
	}
}