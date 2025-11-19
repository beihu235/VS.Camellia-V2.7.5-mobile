package funkin.states;

import lime.ui.KeyCode;
import lime.app.Application;

import funkin.objects.PlayField;
import funkin.objects.Strumline;
import funkin.objects.Note;

class CalibrateOffsetState extends FunkinState {
	var playfield:PlayField;
	var strumline:Strumline;

	var extraTime:Float = 1500; // 1.5 seconds

	var introText:FlxText;
	var introBG:FlxSprite;
	var finished:Bool = false;
	var skipIntro:Bool = false;

	var totalNoteDifference:Float = 0;
	var notesHit:Int = 0;
	var finalOffset:Float = 0;

	public function new(?skipIntro:Bool = false):Void {
		super();
		this.skipIntro = skipIntro;
	}

	override function create():Void {
		super.create();
		Conductor.stop();
		
		strumline = new Strumline(0, 0, true);
		strumline.screenCenter(X);

		add(playfield = new PlayField([strumline]));
		playfield.downscroll = Settings.data.downscroll;
		playfield.playerID = 0;
		strumline.y = playfield.downscroll ? FlxG.height - 150 : 50;
		playfield.noteHit = noteHit;
		playfield.visible = skipIntro;
		playfield.active = skipIntro;

		load();
		
		// don't need to worry about offset for this one
		Conductor._time = -extraTime;
		if (skipIntro) start();

		add(introBG = new FlxSprite().makeGraphic(1, 1, FlxColour.BLACK));
		introBG.scale.set(FlxG.width, FlxG.height);
		introBG.updateHitbox();
		introBG.visible = !skipIntro;
		introBG.alpha = skipIntro ? 0 : 1;

		add(introText = new FlxText(0, 0, FlxG.width, '
			Welcome to the calibration offset menu!\n\nIt\'s designed to make your taps more synced to the music.\nRemember to relax as much as possible, and focus on how close the notes are to the music, not the strums.\n\nKeep in mind that human error is always a thing,\nso the offset given might not exactly work.\nDon\'t stress it!\n\nPress Accept to start
		', 20));
		introText.font = Paths.font('vcr.ttf');
		introText.alignment = 'center';
		introText.screenCenter();
		introText.visible = !skipIntro;
		introText.alpha = skipIntro ? 0 : 1;
	}

	var songID:String = 'Sync Test';
	function load():Void {
		var song:Chart = Song.createDummyFile();

		Conductor.timingPoints = [
			{
				time: 0,
				bpm: 128
			}
		];

		Conductor.bpm = Conductor.timingPoints[0].bpm;
		var beat: Float = 4;
		while(beat < 96){		
			song.notes.push({
				time: Math.max(0, Conductor.crotchet * beat),
				lane: (beat % 4) <= 1 ? 0 : 3,
				length: 0,
				player: 0,
				speed: 1,
				type: ''
			});

			beat += 2;
		}

		Conductor.inst = FlxAudioHandler.loadAudio(Paths.audioPath('songs/$songID/Inst'));
		Conductor.inst.onComplete = finish;

		playfield.load(song.notes);
		playfield.scrollSpeed = Settings.data.scrollSpeed;
	}

	function finish():Void {
		finalOffset = Math.floor(totalNoteDifference / notesHit);
		introText.text = 'Your offset is: $finalOffset millisecond${Math.abs(finalOffset) != 1 ? 's' : ''} (${finalOffset > 0 ? 'later' : 'earlier'})\n\nPress Accept to confirm\nPress Back to retry';
		introText.screenCenter();

		finished = true;
		Conductor.playing = false;

		FlxTween.tween(introBG, {alpha: 1}, 0.5, {onComplete: function(_) playfield.visible = false});
		FlxTween.tween(introText, {alpha: 1}, 0.5);
		introBG.visible = true;
		introText.visible = true;
	}

	function start():Void {
		Conductor.playing = true;
		new FlxTimer().start(extraTime / 1000, function(_) Conductor.play());
		playfield.active = true;

		if (skipIntro) return;

		playfield.visible = true;
		playfield.active = true;
		
		FlxTween.tween(introBG, {alpha: 0}, 0.5);
		FlxTween.tween(introText, {alpha: 0}, 0.5);
	}

	override function update(delta:Float):Void {
		super.update(delta);

		if (finished && Controls.justPressed('accept')) {
			Settings.data.noteOffset = finalOffset;
			FlxG.switchState(new OptionsState());
		}

		if (Controls.justPressed('back')) {
			if (finished) FlxG.switchState(new CalibrateOffsetState(true));
			else FlxG.switchState(new OptionsState());
		} else if (!Conductor.playing && !finished && Controls.justPressed('accept')) start();
	}

	function noteHit(_, note:Note):Void {
		totalNoteDifference += note.hitTime;
		notesHit++;
	}
}