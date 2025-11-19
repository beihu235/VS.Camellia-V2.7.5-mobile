package funkin.backend;

import flixel.util.FlxSignal;
import funkin.backend.Meta;
import funkin.backend.Song;

@:structInit
class TimingPoint {
	public var offsettedTime(get, never):Float;
	function get_offsettedTime():Float return time + Conductor.offset;

	public var time:Float = 0;
	public var bpm:Float = 120;
	public var beatsPerMeasure:ByteUInt = 4;

	public function toString():String {
		return 'Time: $time | Tempo: $bpm | Beats per measure: $beatsPerMeasure';
	}
}

class Conductor extends flixel.FlxBasic {
	public static var quants:Array<Int> = [
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];
	
	public static var playing:Bool = false;
	public static var length:Float = 0.0;

	public static var bpm(default, set):Float = 120.0;
	public static var crotchet:Float = (60 / bpm) * 1000;
	public static var stepCrotchet:Float = crotchet * 0.25;

	public static var beatsPerMeasure(default, set):ByteUInt = 4;
	
	public static var offset:Float = 0.0;

	static var _songPlaying:Bool = false;

	public static var volume(default, set):Float = 1.0;

	public static var visualTime:Float = 0.0;
    public static var rawTime:Float = 0.0;

	static var _lastTime:Float = 0.0;
	static var _resyncTimer:Float = 0.0;

    public static var timingPoints(default, set):Array<TimingPoint> = [];
    static function set_timingPoints(value:Array<TimingPoint>):Array<TimingPoint> {
		if (value == null || value.length == 0) {
			timingPoints.resize(1);
			timingPoints[0] = {};
			return timingPoints;
		}

        var lastPoint:TimingPoint = {
			bpm: 0,
			beatsPerMeasure: 0
		};

        // so that the end-user doesn't have to specify a bpm/numerator every time they add a new point for smth else
        for (point in value) {
            if (point.bpm <= 0) point.bpm = lastPoint.bpm;
            if (point.beatsPerMeasure <= 0) point.beatsPerMeasure = lastPoint.beatsPerMeasure;
            lastPoint = point;
        }
        timingPoints.resize(0);
        timingPoints = value.copy();

        timingPoints.sort((a, b) -> return Std.int(a.time - b.time));

        return value;
    }

	//@:isVar public static var inst(get, set):FlxSound;
	public static var inst:FlxAudio;
	public static var vocals/*:FlxSound*/:FlxAudio;

	public static final vocalResyncDiff:Float = 10.0;

	public static var step:Int = 0;
	public static var beat:Int = 0;
	public static var measure:Int = 0;
	public static var floatStep:Float;
	public static var floatBeat:Float;
	public static var visualBeat:Float;
	public static var floatMeasure:Float;

	static var _prevStep:Int = -1;
	static var _prevBeat:Int = -1;
	static var _prevMeasure:Int = -1;

	public static var onStep:FlxTypedSignal<Int -> Void>;
	public static var onBeat:FlxTypedSignal<Int -> Void>;
	public static var onMeasure:FlxTypedSignal<Int -> Void>;

	public function new() {
		super();
		visible = false;
		onStep = new FlxTypedSignal<Int -> Void>();
		onBeat = new FlxTypedSignal<Int -> Void>();
		onMeasure = new FlxTypedSignal<Int -> Void>();
		reset();
	}

	public static function reset() {
        playing = false;
		@:bypassAccessor
		rawTime = 0.0;
		visualTime = 0.0;
        _time = 0.0;

        floatStep = step = 0;
        floatBeat = beat = 0;
        floatMeasure = measure = 0;

		timingPoints = null;
		if (vocals != null) {
			vocals.destroy();
			vocals = null;
		}
		beatsPerMeasure = 4;
		bpm = 120;

		_songPlaying = false;

        offset = 0.0;

		onStep.removeAll();
		onBeat.removeAll();
		onMeasure.removeAll();
	}

	override function update(elapsed:Float) {
		if (!playing) return;

		_prevStep = step;
		_prevBeat = beat;
		_prevMeasure = measure;

		syncTime(elapsed);
		syncVocals();
		syncBeats();
	}

	public static var _time:Float = 0.0;
	public static dynamic function syncTime(deltaTime:Float):Void {
		if (!playing) return;
		
		deltaTime *= 1000;
		if (inst == null || !inst.playing) {
			_time += deltaTime;
			rawTime = _time + offset;
			visualTime = rawTime;
			return;
		}

		rawTime = inst.time + offset;
		
		if (inst.time == _lastTime)
		{
			visualTime += deltaTime;
		}
		else
		{
			if (Math.abs(rawTime - visualTime) >= deltaTime)
				visualTime = rawTime;
			else
				visualTime += deltaTime;

			_lastTime = inst.time;
		}

		//visualTime = FlxMath.lerp(inst.time + offset, rawTime, Math.exp(-deltaTime * 5));	
	}

	public static dynamic function syncVocals() {
		if (!playing || inst == null || !inst.playing) return;
		if (vocals == null || !vocals.playing) return;

		final instTime:Float = inst.time;
		if (vocals.length < instTime) return;

		if (Math.abs(vocals.time - instTime) > vocalResyncDiff)
			vocals.time = instTime;
	}

    public static dynamic function syncBeats() {
        var point:TimingPoint = getPointFromTime(rawTime);
		var visPoint:TimingPoint = getPointFromTime(visualTime);
        if (point.bpm != bpm) bpm = point.bpm;

		// beatsPerMeasure
		if (point.beatsPerMeasure != beatsPerMeasure) beatsPerMeasure = point.beatsPerMeasure;

        floatBeat = getBeatFromTime(rawTime) + ((rawTime - point.time) / crotchet);
		visualBeat = getBeatFromTime(visualTime) + ((visualTime - visPoint.time) / crotchet);
        floatMeasure = floatBeat / beatsPerMeasure;
		floatStep = floatBeat * 4;

        var nextStep:Int = Math.floor(floatStep);
        var nextBeat:Int = Math.floor(floatBeat);
        var nextMeasure:Int = Math.floor(floatMeasure);

        if (step != nextStep) onStep.dispatch(step = nextStep);
        if (beat != nextBeat) onBeat.dispatch(beat = nextBeat);
        if (measure != nextMeasure) onMeasure.dispatch(measure = nextMeasure);
    }

	public static function stop() {
		playing = false;
		_songPlaying = false;
		
		if (inst != null) inst.stop();
		if (vocals != null) vocals.stop();
	}

	public static function play() {
		playing = true;
		_songPlaying = true;

		if (inst != null) inst.play();
		if (vocals != null) {
			vocals.play();
			syncVocals();
		}
	}

	public static function pause() {
		playing = false;
		if (inst != null) inst.pause();
		if (vocals != null) vocals.pause();
	}

	public static function resume() {
		playing = true;
		if (!_songPlaying) return;

		if (inst != null) inst.play();//.resume();
		if (vocals != null) {
			vocals.play();//.resume();
			syncVocals();
		}
	}

    static function set_bpm(value:Float):Float {
        crotchet = calculateCrotchet(value);
        stepCrotchet = crotchet * 0.25;

		if (timingPoints.length == 1) {
			timingPoints[0].bpm = value;
		}

        return bpm = value;
    }

	static function set_beatsPerMeasure(value:Int):Int {
		if (timingPoints.length == 1) {
			timingPoints[0].beatsPerMeasure = value;
		}

		return beatsPerMeasure = value;
	}

	static function set_volume(value:Float):Float {
		inst.volume = value;
		if (vocals != null) vocals.volume = value;

		return volume = value;
	}

	// helper functions that im just gonna
	// throw at the bottom of here lmao
	inline public static function calculateCrotchet(bpm:Float) {
		return (60 / bpm) * 1000;
	}

    public static function getBeatFromTime(timeAt:Float, ?useOffset:Bool = true):Float {
		var beatFromTime:Float = 0;
		var lastPointTime:Float = useOffset ? offset : 0;
		if (timingPoints.length <= 1) return beatFromTime;

        var curBPM:Float = timingPoints[0].bpm;

        for (point in timingPoints) {
			var pointTime:Float = (useOffset ? point.offsettedTime : point.time);
			if (timeAt >= pointTime) {
				beatFromTime += (pointTime - lastPointTime) / calculateCrotchet(curBPM);
				lastPointTime = pointTime;

				curBPM = point.bpm;
			} else break;
        }

        return beatFromTime;
    }

    public static function getPointFromTime(timeAt:Float, ?useOffset:Bool = true):TimingPoint {
        var lastPoint:TimingPoint = {};
        if (timingPoints.length == 0) return lastPoint;
		lastPoint = timingPoints[0];

		// to prevent running a for loop just for one object
		if (timingPoints.length == 1) return timingPoints[0];

        for (i => point in timingPoints) {
            if (timeAt >= (useOffset ? point.offsettedTime : point.time)) lastPoint = point;
            else break;
        }

        return lastPoint;
    }

	// got this method from troll engine, apperently it's stepmania's quantization method.
	public static function getQuantFromTime(timeAt:Float):Int {
		final point:TimingPoint = getPointFromTime(timeAt, false);
		var beat:Float = getBeatFromTime(timeAt, false);
		beat += (timeAt - point.time) / calculateCrotchet(point.bpm);

		final row:Int = Math.round(beat * 48); // 48 rows per beat
		for (quant in quants) {
			if (row % (192 / quant) == 0) // 192 rows per measure (48 * 4)
				return quant;
		}
		return quants[quants.length - 1];
	}
}
