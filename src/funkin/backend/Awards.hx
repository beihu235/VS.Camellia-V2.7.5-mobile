package funkin.backend;

import flixel.util.FlxSave;

#if AWARDS_ALLOWED
class Awards {
	public static var list:Array<Award> = [
		/*{
			name: 'FUCK', id: 'dbgf', hidden: true,
			description: 'die idk'
		},*/
		{
			name: 'No turning back!', id: 'beat_week1',
			description: 'Beat the Rehearsal Session on any difficulty!',
			icon: 'bronze',
			maxScore: 3
		},
		{
			name: 'Thanks for coming!', id: 'beat_week2',
			description: 'Beat The Grand Show on any difficulty!',
			icon: 'silver',
			maxScore: 3
		},
		{
			name: 'Enjoy your stay!', id: 'beat_holofunk',
			description: 'Beat the Holofunk Collab on any difficulty!',
			icon: 'bronze'
		},
		{
			name: 'Epic Encore!', id: 'beat_fingerbreak',
			description: 'Beat the Fingerbreaker Week on any difficulty!',
			icon: 'silver',
			maxScore: 3
		},
		{
			name: 'Slow and Steady!', id: 'clear_5',
			description: 'Clear a track with a difficulty rating of 5 or above!',
			icon: 'bronze'
		},
		{
			name: 'Picking up the pace!', id: 'clear_10',
			description: 'Clear a track with a difficulty rating of 10 or above!',
			icon: 'silver'
		},
		{
			name: 'Above and Beyond!', id: 'clear_15',
			description: 'Clear a track with a difficulty rating of 15 or above!',
			icon: 'gold'
		},
		{
			name: 'On top of the world!', id: 'clear_20',
			description: 'Clear a track with a difficulty rating of 20!',
			icon: 'platinum'
		},
		{
			name: 'First Roots!', id: 'fc_normal',
			description: 'Full Combo a track in Normal difficulty or above!',
			icon: 'bronze'
		},
		{
			name: 'Budding Sprout!', id: 'fc_hard',
			description: 'Full Combo a track in Hard difficulty or above!',
			icon: 'silver'
		},
		{
			name: 'Full Bloom!', id: 'fc_maniac',
			description: 'Full Combo a track in Maniac difficulty or above!',
			icon: 'gold'
		},
		{
			name: 'MARVELOUS!!', id: 'marvelous',
			description: 'Clear a track with 100% Accuracy!',
			icon: 'platinum'
		},
		{
			name: 'So close...', id: 'choke',
			description: 'Clear a track with a singular miss...',
			icon: 'silver'
		},
		{
			name: 'How\'s THAT for a change?', id: 'clear_opponent',
			description: 'Clear a track while playing as the opponent!',
			icon: 'silver'
		},
		{
			name: 'Speed Demon!', id: 'clear_speed',
			description: 'S-rank a track on Maniac difficulty with the Playback Modifier on 1.5x or above!',
			icon: 'gold'
		},
		{
			name: 'Safety Measures...', id: 'clear_nofail',
			description: 'Clear a track with a difficulty rating of 15 or above with the No-Fail modifier... without dying...',
			icon: 'silver'
		},
		{
			name: 'When you f$@#ing see it...', id: '727',
			description: 'I don\'t think we need to explain this one. :^)',
			icon: 'platinum'
			//hidden_desc: true, :troll:
		},
		{
			name: 'Paranormal Activity!', id: 'beat_fingerbreak_maniac',
			description: 'Clear the GHOST trilogy on Maniac Difficulty!',
			icon: 'gold',
			maxScore: 3
		},
		{
			name: 'A REAL Tiebreaker!', id: 'beat_tremendous',
			description: 'Clear TremENDouS on Maniac Difficulty!',
			icon: 'gold'
		},
		{
			name: 'Blast Processing!', id: 'beat_compute',
			description: 'Clear Compute It on Maniac Difficulty!',
			icon: 'gold'
		},
	];

	@:unreflective
	static var _unlocked:Array<String> = [];
	@:unreflective
	static var _scores:Map<String, Float> = [];

	@:unreflective
	public static var saveFile:FlxSave;

	public static function load() {
		if (saveFile == null) {
			saveFile = new FlxSave();
			saveFile.bind('awards', Util.getSavePath());
		}

		if (saveFile.data.list != null) {
			_unlocked.resize(0);
			_unlocked = saveFile.data.list.copy();
		}

		if (saveFile.data.scores != null) {
			_scores = saveFile.data.scores.copy();
		}
	}

	public static function save() {
		saveFile.data.list = _unlocked;
		saveFile.data.scores = _scores;
		saveFile.flush();
	}

	public static function reset(?saveToDisk:Bool = false) {
		_unlocked.resize(0);
		_scores = [];
		if (saveToDisk) save();
	}

	public static function isUnlocked(id:String):Bool {
		if (!exists(id)) return false;
		return _unlocked.contains(id);
	}

	public static function unlock(id:String, ?autoPopup:Bool = true) {
		if (isUnlocked(id)) return;

		_unlocked.push(id);
		save();

		var award = get(id);
		if (award != null)
			Main.awardsCard.pushAward(award);
	}

	public static function getScore(id:String):Float {
		if (!_scores.exists(id)) return 0;
		return _scores[id];
	}

	public static function addScore(id:String, value:Float) {
		var award:Award = get(id);
		if (award == null || award.maxScore <= 0) return;

		setScore(id, _scores[id] + value);
	}

	public static function setScore(id:String, value:Float) {
		var award:Award = get(id);
		if (award == null) return;
		value = Math.min(Math.max(value, 0), award.maxScore);

		_scores.set(id, value);
		if (value >= award.maxScore) unlock(id);
	}

	public static function exists(id:String):Bool {
		for (award in list) {
			if (award.id == id) return true;
		}

		return false;
	}

	public static function get(id:String):Award {
		for (award in list) {
			if (award.id != id) continue;
			return award;
		}

		return null;
	}
}
#else
class Awards {
	public static var list:Array<Award> = [];

	public static function load() {}
	public static function saveFile() {}
	public static function reset(?_) {}
	public static function isUnlocked(_):Bool return false;
	public static function unlock(_, ?_) {}
	public static function getScore(_):Float return 0;
	public static function addScore(_, _) {}
	public static function setScore(_, _) {}

	public static function exists(_):Bool return false;
	public static function get(_):Award return {};

}
#end

@:structInit
class Award {
	public var name:String = 'Unknown';
	public var description:String = 'No description given.';
	public var id:String = '';
	public var icon:String = 'default';
	public var hidden:Bool = false;

	public var maxScore:Float = 0;
	public var decimals:Int = 0;
}