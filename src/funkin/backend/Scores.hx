package funkin.backend;

import flixel.util.FlxSave;

@:structInit
class PlayData {
	// song data
	public var songID:String;
	public var difficulty:String;

	// play data
	public var score:Int;
	public var accuracy:Float = -1;
	public var accType:Null<String>;
	public var clearType:String;

	public var modifiers:Map<String, Dynamic>;

	public function copy(?copyMods:Bool = true):PlayData {
		return {
			songID: songID,
			difficulty: difficulty,

			score: score,
			accuracy: accuracy,
			accType: accType,
			clearType: clearType,
			
			modifiers: copyMods ? modifiers.copy() : modifiers
		};
	}
}

class Scores {
	public static var list:Array<PlayData> = [];

	static var _save:FlxSave;

	public static function load():Void {
		_save = new FlxSave();
		_save.bind('scores', Util.getSavePath());

		list.resize(0);
		if (_save.data.list != null) list = _save.data.list;
	}

	public static function save():Void {
		_save.data.list = list;
		_save.flush();
	}

	public static function reset(?saveToDisk:Bool = false):Void {
		list.resize(0);
		if (saveToDisk) save();
	}

	public static function get(songID:String, ?difficulty:String, ?hasModchart:Bool = false):PlayData {
		difficulty ??= Difficulty.current;

		var plays:Array<PlayData> = filter(list, songID, difficulty, hasModchart);
		if (plays.length == 0) {
			return {
				songID: songID,
				difficulty: difficulty,
				score: 0,
				clearType: 'N/A',

				accType: "Simple",

				modifiers: []
			}
		}

		return plays[0];
	}

	public static function set(data:PlayData, ?hasModchart:Bool = false):Void {
		var filteredList:Array<PlayData> = filter(list, data.songID, data.difficulty, hasModchart);

		Sys.println('current modifiers for "${data.songID} - ${data.difficulty}":');
		for (key => value in data.modifiers) {
			Sys.println('$key: $value');
		}
		Sys.println('');

		if (filteredList.length == 0) {
			list.push(data);
			return;
		}

		var oldPlay:PlayData = list[list.indexOf(filteredList[0])];

		if (oldPlay.score < data.score)
			oldPlay.score = data.score;

		if (oldPlay.accuracy < data.accuracy)
			oldPlay.accuracy = data.accuracy;

		var oldIdx = Ranking.clearTypeList.indexOf(oldPlay.clearType);
		var newIdx = Ranking.clearTypeList.indexOf(data.clearType);
		if (oldIdx < newIdx)
			oldPlay.clearType = data.clearType;

		// TODO: figure out how to rank clear types properly
		// since they're strings we can't check them like scores and/or accuracy
	}

	public static function filter(plays:Array<PlayData>, songID:String, difficulty:String, ?hasModchart:Bool = false):Array<PlayData> {
		var modifiers:Map<String, Dynamic> = Settings.data.gameplayModifiers;

		return plays.filter(function(play:PlayData) {
			if (play.modifiers == null || play.accType == null || play.accType != Settings.data.accuracyType) return false; // OLD YA OOOOOOOOLD (or accType doesnt match)

			if (hasModchart && (!play.modifiers.exists("modcharts") || play.modifiers["modcharts"] != modifiers["modcharts"])) return false;

			for (m in ['playbackRate', 'onlySicks', 'mirroredNotes', 'blind', 'playingSide']) {
				if (!play.modifiers.exists(m) || play.modifiers[m] != modifiers[m]) return false;
			}

			return play.songID == songID && play.difficulty == difficulty;
		});
	}
}