import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import funkin.objects.Character;
import funkin.Dialogue;
import funkin.states.PlayState;

if (!PlayState.storyMode) {
	closeFile();
	return;
}

function create() {
	game.subStateOpened.add(openSubstate);
	FlxG.sound.play(Paths.audio('cheer1', 'sfx/dialogue'));
}

function openSubstate(substate) {
	
	substate.onNewMessage = function(index, message) {
		if (!Std.isOfType(substate, Dialogue)) return;
	game.subStateOpened.remove(openSubstate);
		switch (index) {
			case 10: FlxG.sound.play(Paths.audio('cheer4', 'sfx/dialogue'));
		}
		}
}
