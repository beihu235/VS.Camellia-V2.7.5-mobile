import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

if (!Settings.data.lyrics) {
	closeFile();
	return;
}

function eventTriggered(name:String, args:Array<Dynamic>):Void {
	if (name != 'Lyric') return;
	makeLyric(args[0], args[1].length != 0 ? Std.parseFloat(args[1]) : null);
}

var members:Array<FlxText> = [];
function makeLyric(text:String, ?duration:Float) {
	duration ??= 2;

	var txt:FlxText = new FlxText(0, Settings.data.downscroll ? 100 : 600, 750, text, 30);
	txt.active = false;
	txt.alignment = 'center';
	txt.screenCenter(0x01);
	txt.font = Paths.font('rockfordntlg.ttf');
	txt.borderStyle = FlxTextBorderStyle.OUTLINE;
	txt.borderSize = 2;
	txt.camera = game.camOther;

	game.add(txt);
	members.push(txt);

	if (members.length > 1) {
		for (obj in members) {
			if (obj == txt) continue;

			var height:Float = (10 + obj.height);
			var yPos:Float = Settings.data.downscroll ? (obj.y + height) : (obj.y - height);
			FlxTween.tween(obj, {y: yPos}, 0.25, {ease: FlxEase.cubeOut});
		}

		final lastLyric:FlxText = members[members.indexOf(txt) - 1];

		if (lastLyric != null && lastLyric.alpha >= 1) {
			FlxTween.tween(lastLyric, {alpha: 0.5}, 0.25, {ease: FlxEase.cubeOut});
		}
	}
	
	new FlxTimer().start(duration, function() {
		FlxTween.cancelTweensOf(txt);

		FlxTween.tween(txt, {alpha: 0}, 0.25, {ease: FlxEase.cubeOut, onComplete: function() {
			members.remove(txt);
			txt.destroy();
			game.remove(txt);
			txt = null;
		}});
	});
}