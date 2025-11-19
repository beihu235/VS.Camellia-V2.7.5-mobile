package funkin.backend;

@:structInit
class MetaFile {
	public var songName:String = 'Unknown';
	public var subtitle:String = '';
	public var instComposer:String = 'N/A';
	public var vocalComposer:String = 'N/A';
	public var charter:Map<String, String> = [];
	public var rating:Map<String, Array<Float>> = [];
	public var genre:String = "N/A";
	public var album:String = "N/A";
	public var jacket:String = "Unknown";
	public var timingPoints:Array<Conductor.TimingPoint> = [];
	public var offset:Float = 0.0;
	public var hasVocals:Bool = true;
	public var hasModchart:Bool = false;

	public var player:String = 'bf';
	public var spectator:String = 'bf';
	public var enemy:String = 'bf';
	public var stage:String = 'studio';

	@:optional public var randomName:Null<String>;
	@:optional public var rngChance:Float = 0;

	@:optional public var diffs:Array<funkin.backend.WeekData.DiffData>;
}

typedef MetaTimingPoint = {
	var time:Float;
	var ?bpm:Float;
	var ?beatsPerMeasure:ByteUInt;
}

class Meta {
	static var _cache:Map<String, MetaFile> = [];
	public static function cacheFiles(?force:Bool = false):Void {
		if (force) _cache.clear();

		var directories:Array<String> = ['assets'];

		#if ADDONS_ALLOWED
		for (addon in Addons.list) {
			if (!addon.disabled)
				directories.push('addons/${addon.id}');
		}
		#end

		for (i => path in directories) {
			if (!FileSystem.exists('$path/songs')) continue;

			for (song in FileSystem.readDirectory('$path/songs')) {
				_cache.set(song, load(song));
			}
		}
	}

	public static function load(song:String):MetaFile {
		if (_cache.exists(song)) return _cache[song];
		
		var path:String = 'songs/$song/meta.json';
		var file:MetaFile = {};
		file.songName = song;
		for (diff in Difficulty.default_list) file.charter.set(diff, 'Unknown');

		// still keeping this check here
		// in case the file isn't in the cache
		// but the user wants to parse it anyways
		if (!Paths.exists(path)) return file;
		var data:Dynamic = Json5.parse(Paths.getFileContent(path));

		for (property in Reflect.fields(data)) {
			// ??????? ok i guess no `Reflect.hasField()` for you
			if (!Reflect.fields(file).contains(property)) continue;
			if (property == 'charter' || property == 'rating' || property == 'timingPoints') continue;
			
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		for (diff in Reflect.fields(data.charter)) file.charter.set(diff, Reflect.field(data.charter, diff));
		for (diff in Reflect.fields(data.rating)) file.rating.set(diff, Reflect.field(data.rating, diff));

		// have to do it this way
		// otherwise haxe shits itself and starts printing insane numbers
		// and that's no good /ref
		var timingPoints:Array<MetaTimingPoint> = data.timingPoints;
		if (timingPoints != null)  {
			for (point in timingPoints) {
				file.timingPoints.push({
					time: point.time,
					bpm: point.bpm,
					beatsPerMeasure: point.beatsPerMeasure
				});
			}
		}

		_cache.set(song, file);
		return file;
	}
}