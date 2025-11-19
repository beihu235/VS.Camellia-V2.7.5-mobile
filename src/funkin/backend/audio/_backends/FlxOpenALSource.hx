package funkin.backend.audio._backends;

import haxe.Timer;
import haxe.Int64;

import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.media.vorbis.Vorbis;
import lime.media.vorbis.VorbisFile;
import lime.media.vorbis.VorbisInfo;
import lime.media.AudioManager;
import lime.system.Endian;
import lime.system.System;
import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView.TypedArrayType;
import lime.utils.ArrayBufferView;

import funkin.backend.FlxAudioHandler.SoundBufferData;
import funkin.backend.FlxAudioHandler;

/**
 * Audio backend for Native that supports OpenAL
 */
@:access(haxe.Timer)
@:access(lime.utils.ArrayBufferView)
class FlxOpenALSource extends FlxAudioSource {
	// Noted that FlxOpenALSource for now only supports vorbis ogg files.

	static final STREAM_BUFFER_SAMPLES:Int = 0x2000; // how much buffers will be generating every frequency (doesnt have to be pow of 2?).
	static final STREAM_MAX_BUFFERS:Int = 5; // how much buffers limit can be used for streamed audios, below 3 won't work.
	static final STREAM_PROCESS_BUFFERS:Int = 2; // how much buffers can be processed in a frequency tick.
	static final STREAM_TIMER_CHECK_MS:Int = 100; // determines how milliseconds to update the buffers if available.
	static final MAX_POOL_BUFFERS:Int = 20; // how much buffers for the pool to hold.

	private static var bufferDataPool:Array<ArrayBufferView> = [];
	private static var isBigEndian:Bool = System.endianness == Endian.BIG_ENDIAN;
	private static var loopPointsSupported:Null<Bool>;

	public var vorb:VorbisFile;
	var _volume:Float = 1.0;

	var channels:Int;
	var sampleRate:Int;
	var bitsPerSample:Int; // Will always have the same 16 bitsPerSample for vorbis.
	var _length:Float;
	var samples:Float;
	var dataLength:Float;

	var streamTimer:Timer;
	var completeTimer:Timer;
	var source:ALSource;
	var buffer:ALBuffer;
	var format:Int; // AL.FORMAT_...
	var arrayType:TypedArrayType;
	var loopPoints:Array<Int>;

	var bufferLength:Int; // Size in bytes for current streamed audio buffers.
	var requestBuffers:Int;
	var queuedBuffers:Int;
	var toLoop:Int;
	var streamEnded:Bool;

	var buffers:Array<ALBuffer>;
	var unusedBuffers:Array<ALBuffer>;

	// ORDERING IS CURRENT TO NEXT, STARTS FROM THE LENGTH OF THE ARRAYS
	var bufferDatas:Array<ArrayBufferView>;
	var bufferTimes:Array<Float>;
	//var bufferLengths:Array<Int>;

	override function init() {
		if (AudioManager.context == null) AudioManager.init();
		if (loopPointsSupported == null) loopPointsSupported = AL.isExtensionPresent("AL_SOFT_loop_points");

		if (source != null || (source = AL.createSource()) == null) return;

		AL.sourcei(source, AL.LOOPING, AL.FALSE);
		//AL.sourcef(source, AL.MAX_GAIN, 10);

		loopPoints = [0, 0];
	}

	override function dispose() {
		stop();

		if (source != null) {
			AL.sourcei(source, AL.BUFFER, AL.NONE);
			AL.deleteSource(source);
			source = null;
		}

		if (buffer != null) {
			AL.bufferData(buffer, 0, null, 0, 0);
			AL.deleteBuffer(buffer);
			buffer = null;
		}
		loopPoints = null;

		if (buffers != null) {
			for (buffer in buffers) AL.bufferData(buffer, 0, null, 0, 0);
			AL.deleteBuffers(buffers);
			buffers = null;
		}

		if (bufferDatas != null) {
			for (data in bufferDatas) if (bufferDataPool.length < MAX_POOL_BUFFERS) bufferDataPool.push(data);
			bufferDatas = null;
		}

		completeTimer = null;
		streamTimer = null;

		unusedBuffers = null;
		bufferTimes = null;
		//bufferLengths = null;
	}

	public static function readVorbisFileBuffer(vorb:VorbisFile, ?info:VorbisInfo):ArrayBufferView {
		if (info == null) info = vorb.info();

		var buffer = new ArrayBufferView(Std.int(getFloat(vorb.pcmTotal()) * info.channels), TypedArrayType.Uint16), total = 0, result = 0;
		do {
			result = vorb.read(buffer.buffer, total, 0x1000, isBigEndian, 2/*wordSize (bitsPerSample >> 3)*/, true);
			total += result;
		} while (result > 0 || result == Vorbis.HOLE);

		return buffer;
	}

	function updateBufferProperties(?bufferData:ArrayBufferView) {
		bufferLength = STREAM_BUFFER_SAMPLES * channels * (bitsPerSample >> 3);
		dataLength = samples * channels * (bitsPerSample >> 3);
		_length = samples / sampleRate * 1000;

		arrayType = bitsPerSample == 32 ? TypedArrayType.Uint32 : (bitsPerSample == 16 ? TypedArrayType.Uint16 : TypedArrayType.Int8);
		if (channels == 2) format = bitsPerSample == 16 ? AL.FORMAT_STEREO16 : AL.FORMAT_STEREO8;
		else format = bitsPerSample == 16 ? AL.FORMAT_MONO16 : AL.FORMAT_MONO8;

		loopPoints[0] = 0;
		loopPoints[1] = Std.int(samples - 1);

		AL.sourceUnqueueBuffers(source, AL.getSourcei(source, AL.BUFFERS_QUEUED));
		AL.sourcei(source, AL.BUFFER, AL.NONE);

		if (!_stream) {
			if (buffers != null) {
				for (buffer in buffers) AL.bufferData(buffer, 0, null, 0, 0);
				AL.deleteBuffers(buffers);
				buffers = null;

				for (data in bufferDatas) if (bufferDataPool.length < MAX_POOL_BUFFERS) bufferDataPool.push(data);
				bufferDatas.resize(0);
			}

			if (buffer != null || (buffer = AL.createBuffer()) != null) {
				if (bufferData != null || (AL.getBufferi(buffer, AL.SIZE) >> 0) != dataLength) {
					AL.bufferData(buffer, format, bufferData, bufferData.byteLength, sampleRate);
					AL.sourcei(source, AL.BUFFER, buffer);
				}
			}
		}
		else {
			var length = STREAM_BUFFER_SAMPLES * channels;
			if (buffers == null) buffers = AL.genBuffers(STREAM_MAX_BUFFERS);
			if (bufferDatas == null) {
				unusedBuffers = [];
				bufferDatas = [];
				bufferTimes = [];
				//bufferLengths = [];
			}
			else
				unusedBuffers.resize(0);

			for (i in 0...STREAM_MAX_BUFFERS) {
				bufferTimes[i] = 0.0;
				//bufferLengths[i] = 0;

				var data = bufferDataPool.pop();
				if (data == null) data = new ArrayBufferView(length, arrayType);
				else {
					data.type = arrayType;
					data.bytesPerElement = data.bytesForType(arrayType);
					data.length = length;
					if (data.byteLength != bufferLength) {
						#if cpp
						data.buffer.getData().resize(bufferLength);
						data.buffer.fill(data.byteLength, bufferLength - data.byteLength, 0);
						@:privateAccess data.buffer.length = bufferLength;
						#else
						data.buffer = new ArrayBuffer(bufferLength);
						#end
					}
					data.byteLength = bufferLength;
				}
				bufferDatas[i] = data;
			}
		}

		updateLoopPoints();
	}

	function updateLoopPoints() {
		if (!looped) return AL.sourcei(source, AL.LOOPING, AL.FALSE);

		var time = time, fixed = time >= _endTime;
		if (fixed) time = _loopTime;
		if (!_stream) {
			var simpleLoop = getLength() < _length - 1 && _loopTime > 1;
			AL.sourcei(source, AL.LOOPING, loopPointsSupported || simpleLoop ? AL.TRUE : AL.FALSE);

			if (loopPointsSupported && !simpleLoop) {
				AL.sourceStop(source);
				AL.sourcei(source, AL.BUFFER, AL.NONE);
				AL.bufferiv(buffer, 0x2015/*AL.LOOP_POINTS_SOFT*/, loopPoints);
				AL.sourcei(source, AL.BUFFER, buffer);
			}

			if (_playing) this.time = time;
			else updateCompleteTimer();
		}
		else if (_playing && (fixed || toLoop > 0)) {
			AL.sourcei(source, AL.LOOPING, AL.FALSE);

			AL.sourceStop(source);
			snapBuffersToTime(time);
			AL.sourcePlay(source);
		}
	}

	override function load(looped:Bool, stream:Bool) {
		super.load(looped, stream);

		if (vorb != null) {
			vorb.clear();
			vorb = null;
		}

		//var desiredPath:String = '';

		try {
			//desiredPath = OpenFlAssets.getPath(connectedAudio.path);
			vorb = VorbisFile.fromFile(/*desiredPath*/connectedAudio.path); //i had to do this since openfl can't find foreign files
		}
		catch (e) {
			//Debug.logWarn('Audio ${connectedAudio.path} couldnt be loaded because the sound ogg couldnt be found!');
			trace('Audio ${connectedAudio.path} couldnt be loaded because the sound ogg couldnt be found!');
		}
		if (vorb == null) return;

		var info = vorb.info();
		if (info == null) return;

		channels = info.channels;
		sampleRate = info.rate;
		bitsPerSample = 16;
		samples = getFloat(vorb.pcmTotal());

		if (!stream || !vorb.seekable() || vorb.pcmTotal() < (STREAM_BUFFER_SAMPLES << 1)) {
			_stream = false;

			var bufferData = FlxAudioHandler.audioCache.get(connectedAudio.path);
			if (bufferData != null) bufferData.onUse = true;
			else {
				FlxAudioHandler.audioCache.set(connectedAudio.path,
					bufferData = new SoundBufferData(readVorbisFileBuffer(vorb, info), channels, sampleRate, 16));
			}

			updateBufferProperties(bufferData.bufferArray);

			vorb.clear();
			vorb = null;
		}
		else
			updateBufferProperties();
	}

	public function loadFromBuffer(buffer:ArrayBufferView, channels:Int = 2, sampleRate:Int = 44100, bitsPerSample:Int = 16, looped:Bool = false) {
		super.load(looped, false);

		if (vorb != null) {
			vorb.clear();
			vorb = null;
		}

		this.channels = channels;
		this.sampleRate = sampleRate;
		this.bitsPerSample = bitsPerSample;
		samples = Math.ffloor(buffer.byteLength / (bitsPerSample >> 3) / channels);

		updateBufferProperties(buffer);
	}

	function readToBufferData(data:ArrayBufferView):Int {
		var wordSize = bitsPerSample >> 3, length = Math.floor((getLength() * sampleRate / 1000 - getFloat(vorb.pcmTell())) * channels * wordSize);
		var n = length < bufferLength ? length : bufferLength;
		n -= n % (channels * wordSize);

		var total = 0, result = 0, wasEOF = false;
		while (total < bufferLength) {
			result = n > 0 ? vorb.read(data.buffer, total, n, isBigEndian, wordSize, true) : 0;

			if (result == Vorbis.HOLE) continue;
			else if (result <= Vorbis.EREAD) break;
			else if (result == 0 || result == Vorbis.EOF) {
				if (wasEOF || (streamEnded = !_looped)) break;
				else {
					wasEOF = true;
					toLoop++;

					streamTimeSeek(_loopTime / 1000);

					if ((length = Math.floor((getLength() - _loopTime) * sampleRate / 1000) * channels * wordSize) < (n = bufferLength - total)) n = length;
					n -= n % (channels * wordSize);
				}
			}
			else {
				total += result;
				n -= result;
				wasEOF = false;
			}
		}

		//if (total < bufferLength) data.buffer.fill(total, n, 0);

		if (result < 0) {
			trace('FlxOpenALSource readToBufferData Bug! reading result is $result, streamEnded: $streamEnded, total: $total, n: $n');
			return result;
		}
		return total;
	}

	function fillBuffer(buffer:ALBuffer):Int {
		var i = STREAM_MAX_BUFFERS - requestBuffers;
		var data = bufferDatas[i], time = vorb.timeTell();

		var decoded = readToBufferData(data);
		if (decoded > 0) {
			AL.bufferData(buffer, format, data, decoded, sampleRate);

			var n = STREAM_MAX_BUFFERS - 1;
			while (i < n) {
				bufferDatas[i] = bufferDatas[i + 1];
				bufferTimes[i] = bufferTimes[++i];
				//bufferLengths[i] = bufferLengths[++i];
			}
			queuedBuffers = requestBuffers;
			bufferDatas[n] = data;
			bufferTimes[n] = time;
			//bufferLengths[n] = decoded;
		}

		return decoded;
	}

	function bufferStream_task() {
		if (source == null || vorb == null || !_playing) return streamTimer.stop();

		var processed = AL.getSourcei(source, AL.BUFFERS_PROCESSED), n = STREAM_PROCESS_BUFFERS, buffer;
		while (processed-- > 0) {
			buffer = AL.sourceUnqueueBuffer(source);
			if (!streamEnded && --n > 0 && fillBuffer(buffer) > 0) AL.sourceQueueBuffer(source, buffer);
			else {
				queuedBuffers = --requestBuffers;
				unusedBuffers.push(buffer);
			}
		}

		if (!streamEnded) {
			if (unusedBuffers.length != 0) {
				requestBuffers++;
				if (fillBuffer(buffer = unusedBuffers.pop()) > 0) {
					queuedBuffers = requestBuffers;
					AL.sourceQueueBuffer(source, buffer);
				}
				else {
					requestBuffers--;
					unusedBuffers.push(buffer);
				}
			}
			else if (queuedBuffers < STREAM_MAX_BUFFERS) {
				if (fillBuffer(buffer = buffers[requestBuffers++]) > 0) AL.sourceQueueBuffer(source, buffer);
				else requestBuffers--;
			}
		}

		if (AL.getSourcei(source, AL.SOURCE_STATE) == AL.STOPPED) {
			AL.sourcePlay(source);
			updateCompleteTimer();
		}
	}

	override function play() if (source != null) super.play();

	override function pause() {
		if (source != null) AL.sourcePause(source);

		super.pause();
		stopTimers();
	}

	override function stop() {
		if (source != null) {
			AL.sourceStop(source);
			toLoop = 0;
		}

		super.stop();
		stopTimers();
	}

	function complete() {
		stop();

		if (connectedAudio.onComplete != null)
			connectedAudio.onComplete();
	}

	function stopTimers() {
		if (completeTimer != null) completeTimer.stop();
		if (streamTimer != null) streamTimer.stop();
	}

	override function get_length():Float return _length;

	override function get_paused():Bool return AL.getSourcei(source, AL.PAUSED) == AL.TRUE;

	override function get_volume():Float return _volume;

	override function set_volume(value:Float):Float {
		_volume = value;
		updateVolume();
		return value;
	}

	override function updateVolume()
		AL.sourcef(source, AL.GAIN, FlxG.sound.muted ? 0 : _volume * FlxAudioHandler.volume);

	override function get_pitch():Float return AL.getSourcef(source, AL.PITCH);

	override function set_pitch(value:Float):Float {
		if (source == null) return 1.0;
		AL.sourcef(source, AL.PITCH, value);
		updateCompleteTimer();
		return value;
	}

	override function set_looped(value:Bool):Bool {
		_looped = value;
		updateLoopPoints();
		return value;
	}

	override function set_loopTime(t:Float) {
		super.set_loopTime(t);
		loopPoints[0] = Std.int(Math.min(_loopTime * sampleRate / 1000, samples - 1));
		updateLoopPoints();
		return _loopTime;
	}

	override function set_endTime(t:Null<Float>) {
		super.set_endTime(t);
		loopPoints[1] = Std.int(Math.min(getLength() * sampleRate / 1000, samples - 1));
		updateLoopPoints();
		return _endTime;
	}

	override function get_time():Float {
		if (source == null) return 0.0;
		else if (completed) return getLength();

		var time = AL.getSourcef(source, AL.SAMPLE_OFFSET) / sampleRate;
		if (_stream) {
			if (_playing && streamEnded && AL.getSourcei(source, AL.SOURCE_STATE) == AL.STOPPED) {
				complete();
				return getLength();
			}
			else if (bufferTimes != null)
				time += bufferTimes[STREAM_MAX_BUFFERS - queuedBuffers];
		}
		time *= 1000;

		var length = getLength();
		return if (!_looped || time <= length) time;
			else ((time - _loopTime) % (length - _loopTime)) + _loopTime;
	}

	override function set_time(value:Float):Float {
		if (source == null) return 0.0;

		var length = getLength();
		value = Math.isFinite(value) ? Math.max(Math.min(value, length), 0) : 0;

		if (_stream) AL.sourceStop(source);
		else {
			AL.sourceRewind(source);
			AL.sourcei(source, AL.SAMPLE_OFFSET, Int64.fromFloat(Math.max(0, Math.min(value / 1000 * sampleRate, samples))));
		}

		var timeRemaining = (length - value) / pitch;
		if (_playing) {
			if (timeRemaining < 8 && value > 8) complete();
			else {
				completed = streamEnded = false;
				if (_stream && (streamTimer == null || !streamTimer.mRunning || Math.abs((time - value) / pitch) > 8))
					snapBuffersToTime(value);

				AL.sourcePlay(source);
			}
		}
		else
			completed = timeRemaining < 8;

		if (!_playing && _stream && bufferTimes != null) bufferTimes[STREAM_MAX_BUFFERS - (requestBuffers = queuedBuffers = 1)] = value / 1000;
		updateCompleteTimer();

		return value;
	}

	// https://github.com/xiph/vorbis/blob/master/CHANGES#L39 bug in libvorbis <= 1.3.4
	inline function streamTimeSeek(time:Float) if (time <= 1e-4) vorb.rawSeek(0); else vorb.timeSeek(time);

	function snapBuffersToTime(time:Float) {
		if (vorb == null || source == null) return;

		AL.sourceUnqueueBuffers(source, AL.getSourcei(source, AL.BUFFERS_QUEUED));

		unusedBuffers.resize(0);
		streamTimeSeek(time / 1000);

		requestBuffers = queuedBuffers = STREAM_PROCESS_BUFFERS > 3 ? STREAM_PROCESS_BUFFERS : 3;
		for (i in 0...queuedBuffers) {
			if (!streamEnded && fillBuffer(buffers[i]) > 0) AL.sourceQueueBuffer(source, buffers[i]);
			else queuedBuffers = --requestBuffers;
		}

		if (!streamEnded) streamTimer = resetTimer(streamTimer, STREAM_TIMER_CHECK_MS, bufferStream_task);
	}

	function updateCompleteTimer() {
		if (_playing) {
			var timeRemaining = (getLength() - time) / pitch;
			if (timeRemaining > 100) completeTimer = resetTimer(completeTimer, timeRemaining - 100, onEnd);
			else {
				if (completeTimer != null) completeTimer.stop();
				if (_looped) play();
				else complete();
			}
		}
		else if (completeTimer != null) 
			completeTimer.stop();
	}

	static function resetTimer(timer:Timer, time:Float, callback:Void->Void):Timer {
		if (timer == null) (timer = new Timer(time)).run = callback;
		else {
			timer.mTime = time;
			timer.mFireAt = Timer.getMS() + time;
			timer.mRunning = true;
			timer.run = callback;

			if (!Timer.sRunningTimers.contains(timer)) Timer.sRunningTimers.push(timer);
		}
		return timer;
	}

	override function onEnd() {
		var timeRemaining = (getLength() - time) / pitch;
		if (timeRemaining > 100 && AL.getSourcei(source, AL.SOURCE_STATE) == AL.PLAYING && (!_stream || !streamEnded && toLoop <= 0)) {
			completeTimer = resetTimer(completeTimer, timeRemaining, onEnd);
			return;
		}

		completeTimer.stop();

		if (!_looped) return complete();

		if (connectedAudio.onComplete != null)
			connectedAudio.onComplete();

		if (toLoop > 0) {
			toLoop = 0;
			completeTimer = resetTimer(completeTimer, (getLength() - _loopTime) / pitch - 100, onEnd);
		}
		else if (!loopPointsSupported || AL.getSourcei(source, AL.SOURCE_STATE) == AL.STOPPED) {
			_playing = true;
			time = _loopTime;
		}
	}

	inline private static function getFloat(x:Int64):Float return x.high * 4294967296. + (x.low >> 0);
}