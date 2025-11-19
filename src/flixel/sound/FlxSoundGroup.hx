package flixel.sound;

class FlxSoundGroup {
	public var members:Array<FlxSound> = [];

	public var limit:Int = 0;

	public var volume(default, set):Float;
	public var pitch(default, set):Float;
	public var time(default, set):Float;
	public var pan(default, set):Float;

	public function new(?_limit:Int = 0) {
		if (_limit > 0) limit = _limit;
	}

	public function add(sound:FlxSound):FlxSound {
		if (members.contains(sound) || members.length >= limit) return sound;
		if (sound.group != null) sound.group.members.remove(sound);

		@:bypassAccessor sound.group = this;
		members.push(sound);
		@:privateAccess sound.updateTransform();
		FlxG.sound.list.add(sound);

		return sound;
	}

	public function remove(sound:FlxSound):FlxSound {
		if (!members.contains(sound)) return sound;
			
		@:bypassAccessor sound.group = null;
		members.remove(sound);
		@:privateAccess sound.updateTransform();
		FlxG.sound.list.remove(sound);
		
		return sound;
	}

	public function destroy():Void {
		while (members.length > 0) {
			var sound:FlxSound = members[0];

			remove(sound);
			sound.destroy();
			sound = null;
		}
	}

	public function play():Void {
		for (sound in members) sound.play();
	}

	public function stop():Void {
		for (sound in members) sound.stop();
	}

	public function pause():Void {
		for (sound in members) sound.pause();
	}

	public function resume():Void {
		for (sound in members) sound.resume();
	}

	function set_volume(value:Float):Float {
		for (sound in members) sound.volume = value;
		return volume = value;
	}

	function set_pitch(value:Float):Float {
		for (sound in members) sound.pitch = value;
		return pitch = value;
	}

	function set_time(value:Float):Float {
		for (sound in members) sound.time = value;
		return time = value;
	}

	function set_pan(value:Float):Float {
		for (sound in members) sound.pan = value;
		return pan = value;
	}
}