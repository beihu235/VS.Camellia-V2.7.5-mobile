package funkin.backend.audio;

import funkin.backend.audio._backends.FlxAudioSource;
#if sys
import funkin.backend.audio._backends.FlxOpenALSource;
#end

/**
 * Replacement of FlxSound that gets rid of openfl Sound to expose cut features such as streaming (only in native) and see streamed bytes in real time.
 * 
 * In Native: Streaming and smart caching support
 * 
 * In HTML5: No differences with FlxSound, this is because the game needs to load the entire library and caching it to the ram including sounds, so streaming and caching doesn't make sense here.
 * 
 * @author BoloVEVO
 */
@:allow(backend.FlxAudioHandler)
class FlxAudio extends FlxBasic
{
	private var _audioBackend:FlxAudioSource;

	public var time(get, set):Float;
	public var length(get, never):Float;
	public var pitch(get, set):Float;
	public var volume(get, set):Float;
	public var paused(get, never):Bool;
	public var stopped(get, never):Bool;
	public var playing(get, never):Bool;
	public var looped(get, set):Bool;
	public var loopTime(get, set):Float;
	public var endTime(get, set):Null<Float>;

	public var onComplete:Void->Void;

	public var path:String;

	public var fadeTween:FlxTween;

	var _resumeOnFocus:Bool = false;

	public function new()
	{
		super();
		_audioBackend = new FlxOpenALSource(this);
	}

	/**
	 * Uploads a sound buffer loaded from the desired path to this FlxAudio
	 *
	 * @param	audioPath	Path of the sound to load the buffer.
	 * @param	looped			Wether if the sound should loop or not.
	 * @param	stream			If the buffer needs to be streamed or entirely loaded into the memory. (Stream may take more cpu)
	 */
	public function load(audioPath:Null<String>, looped:Bool = false, stream:Bool = false):FlxAudio
	{
		path = audioPath;

		stream = stream && funkin.backend.Settings.data.audioStreams;
		#if sys
		if (FlxAudioHandler.audioCache.exists(path) && _audioBackend is FlxOpenALSource) {
			var openALBackend:FlxOpenALSource = cast _audioBackend;
			var bufferData = FlxAudioHandler.audioCache.get(path);
			bufferData.onUse = true;

			openALBackend.loadFromBuffer(bufferData.bufferArray, bufferData.channels, bufferData.sampleRate, bufferData.bitsPerSample, looped);
		}
		else
		#end {
			_audioBackend.load(looped, stream);
		}

		return this;
	}

	/**
	 * Helper function that tweens this sound's volume.
	 *
	 * @param	Duration	The amount of time the fade-out operation should take.
	 * @param	To			The volume to tween to, 0 by default.
	 */
	public inline function fadeOut(Duration:Float = 1, ?To:Float = 0, ?onComplete:FlxTween->Void):FlxAudio
	{
		if (fadeTween != null)
			fadeTween.cancel();
		fadeTween = FlxTween.num(volume, To, Duration, {onComplete: onComplete}, volumeTween);
		
		return this;
	}
	
	/**
	 * Helper function that tweens this sound's volume.
	 *
	 * @param	Duration	The amount of time the fade-in operation should take.
	 * @param	From		The volume to tween from, 0 by default.
	 * @param	To			The volume to tween to, 1 by default.
	 */
	public inline function fadeIn(Duration:Float = 1, From:Float = 0, To:Float = 1, ?onComplete:FlxTween->Void):FlxAudio
	{
		if (!playing)
			play();
			
		if (fadeTween != null)
			fadeTween.cancel();
			
		fadeTween = FlxTween.num(From, To, Duration, {onComplete: onComplete}, volumeTween);
		return this;
	}
	
	function volumeTween(f:Float):Void
	{
		volume = f;
	}

	@:allow(funkin.backend.FlxAudioHandler)
	function onFocus():Void
	{
		if (_resumeOnFocus)
		{
			_resumeOnFocus = false;
			play();
		}
	}
	
	@:allow(funkin.backend.FlxAudioHandler)
	function onFocusLost():Void
	{
		_resumeOnFocus = playing;
		pause();
	}
	
	public function get_looped()
		return _audioBackend.looped;

	public function set_looped(t:Bool)
	{
		_audioBackend.looped = t;
		return t;
	}

	public function get_loopTime()
		return _audioBackend.loopTime;

	public function set_loopTime(t:Float)
	{
		_audioBackend.loopTime = t;
		return t;
	}

	public function get_endTime()
		return _audioBackend.endTime;

	public function set_endTime(t:Float)
	{
		_audioBackend.endTime = t;
		return t;
	}

	public function get_time()
		return _audioBackend.time;

	public function set_time(t:Float)
	{
		_audioBackend.time = t;
		return t;
	}

	public function get_length()
		return _audioBackend.length;

	public function get_pitch()
		return _audioBackend.pitch;

	public function set_pitch(p:Float)
	{
		_audioBackend.pitch = p;
		return p;
	}

	public function get_volume()
		return _audioBackend.volume;

	public function set_volume(v:Float)
	{
		_audioBackend.volume = v;
		return v;
	}

	public function get_paused()
		return _audioBackend.paused;

	public function get_stopped()
		return _audioBackend.stopped;

	public function play()
		_audioBackend.play();

	public function pause()
		_audioBackend.pause();

	public function stop()
		_audioBackend.stop();

	public function get_playing()
		return _audioBackend.playing;

	override function destroy()
	{
		onComplete = null;
		super.destroy();
		_audioBackend.dispose();
		_audioBackend.connectedAudio = null;
	}
}
