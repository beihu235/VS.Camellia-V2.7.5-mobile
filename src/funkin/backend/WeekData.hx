package funkin.backend;

@:structInit
class WeekFile {
	public var songs:Array<SongData> = [];
	public var weekNum:String = '';
	public var name:String = '';
	public var subtitle:String = '';
	public var background:String = '';
	public var pauseMusic:String = '';
	public var folder:String = '';

	public var diffs:Array<DiffData> = [for (i => diff in Difficulty.default_list) {name: diff, color: Difficulty.default_colors[i]}];

	public var unselectedClipY:Float = 0;
	public var selectedClipY:Float = 0;
	public var hideStory:Bool = false;
}

@:structInit
class SongData {
	public var id:String = '';
	public var colors:Array<FlxColor> = [0xFF000000, 0xFFFFFFFF];
	public var icons:Array<String> = ['face', 'face'];
	public var pauseMusic:String = ''; 
}

// typedef so reflection goes through it easier
typedef DiffData = {
	var name:String;
	var color:FlxColor;
}

class WeekData {
	public static var list:Array<WeekFile> = [];
	public static var current:Int = 0;

	public static function createDummyFile():WeekFile {
		return {
			songs: [],
			
			name: 'Week',
			background: 'default',
			pauseMusic: 'silver'
		}
	}

	public static function reload() {
		list.resize(0);

		var directories:Array<String> = ['assets'];
		var originalLength:Int = directories.length;
		
		#if ADDONS_ALLOWED
		for (addon in Addons.list) {
			if (!addon.disabled)
				directories.push('addons/${addon.id}');
		}
		#end

		for (i => path in directories) {
			if (!FileSystem.exists('$path/weeks')) continue;

			for (week in FileSystem.readDirectory('$path/weeks')) {
				var file:WeekFile = getFile('$path/weeks/$week');
				if (i >= originalLength) file.folder = path;
				
				list.push(file);
				if (file.weekNum == "") file.weekNum = Std.string(list.length);
			}
		}
	}

	public static function getFile(path:String):WeekFile {
		var file:WeekFile = createDummyFile();
		if (!FileSystem.exists(path)) return file;
		
		var data = Json5.parse(File.getContent(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.fields(file).contains(property)) continue;
			if (property == 'songs') continue;

			Reflect.setField(file, property, Reflect.field(data, property));
		}

		// god i hate haxe sometimes
		var songs:Array<{id:String, colors:Array<FlxColor>, icons:Array<String>, pauseMusic:String}> = data.songs;
		for (song in songs) {
			file.songs.push({
				id: song.id,
				colors: song.colors,
				icons: song.icons,
				pauseMusic: song.pauseMusic
			});
		}

		return file;
	}
}