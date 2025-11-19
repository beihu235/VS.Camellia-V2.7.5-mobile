import funkin.Dialogue;
import funkin.states.PlayState;
import funkin.backend.Conductor;
import funkin.backend.FlxAudioHandler;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.text.FlxText;

var finished:Bool = !PlayState.storyMode;

function onEndSong(songID:String) {
	if (!finished) {
		Conductor.playing = false;
		var dialogue:Dialogue = new Dialogue(songID, 'epilogue');
		dialogue.cameras = [game.camOther];
		game.openSubState(dialogue);
		dialogue.onClose = function() {
			finished = true;
			game.endSong();
		}

		var blackSprite = new FunkinSprite().makeGraphic(1, 1, 0xFF000000);
		blackSprite.scale.set(FlxG.width, FlxG.height);
		blackSprite.updateHitbox();
		blackSprite.alpha = 0;
		dialogue.add(blackSprite);
		blackSprite.cameras = [game.camOther];

		var text = new FlxText(0, 0, 1000, 'Somewhere in space...', 40);
		text.font = Paths.font('Rockford-NTLG Light.ttf');
		dialogue.add(text);
		text.alignment = 'center';
		text.screenCenter();
		text.cameras = [game.camOther];
		text.alpha = 0;

		dialogue.onNewMessage = function(index, message) {
			if (index == 15) {
				dialogue.paused = true;
				// this looks like dogshit but whatever :clueless: -rudy
				Conductor.inst = FlxAudioHandler.loadAudio(Paths.audioPath("ambiance", "sfx/dialogue"), true, 0.5, true);
				Conductor.inst.play();
				FlxTween.num(0, 0.6, 5, {ease: FlxEase.quadOut}, function(num) {
				Conductor.inst.volume = num;
				});
				FlxTween.tween(text, {alpha: 1}, 4);
				FlxTween.tween(blackSprite, {alpha: 1}, 3, {onComplete: function(_) {
					game.camGame.visible = false;
					game.camHUD.visible = false;
					dialogue.charsLayered.visible = false;
					new FlxTimer().start(3, function(_) {
						FlxTween.tween(text, {alpha: 0}, 3);
						FlxTween.tween(blackSprite, {alpha: 0}, 3, {onComplete: function(_) {
							dialogue.paused = false;
						}});
					});
				}});
			}
				dialogue.onFinish = function() {
				FlxTween.num(0.6, 0, 1, {ease: FlxEase.quadOut}, function(num) {
				Conductor.inst.volume = num;
				});
			}
		}
		return -1;
	}

	return 1;
}