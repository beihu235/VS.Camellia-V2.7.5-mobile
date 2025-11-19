package funkin.backend;

import haxe.io.Path;
import funkin.objects.NoteSplash;

// works similar to psych's modding system
// although you can't replace assets
// since it's just meant to add songs to freeplay and run scripts
// also all mods are global
class Addons {


	public static var list:Array<Addon> = [];
	public static var current:String = '';

	@:unreflective
	public static final folder:String = 'addons';

	public static function load() {
		#if ADDONS_ALLOWED
		for (i => id in FileSystem.readDirectory(folder)) {
			if (!FileSystem.isDirectory('$folder/$id')) continue;
			var addon:Addon = getFile(id);
			list.push(addon);

			Sys.println('Loaded addon: ${addon.name} ($id)');
		}
		#end

		//reloadNotesplashes();
	}

/* 	public static function reloadNotesplashes() {
		NoteSplash.possibleNotesplashes = ['none'];
					
		for (splashPath in Paths.readDirectory("data/noteSplashes"))
        	if (splashPath.endsWith(".json5")){
				var splashName:String = Path.withoutDirectory(Path.withoutExtension(splashPath));
				if(NoteSplash.possibleNotesplashes.contains(splashName))continue;
				var data = NoteSplashData.get(splashName);
				NoteSplash.possibleNotesplashes.push(splashName);
				NoteSplash.notesplashNames.set(splashName, data.name);
			}
	} */

	public static function reload() {
		list.resize(0);
		load();
	}

	public static function getFile(name:String):Addon {
		var file:Addon = {};
		file.id = name;
		file.disabled = Settings.data.addonsOff.contains(name);
		var path:String = '$folder/$name/meta.json';

		#if ADDONS_ALLOWED
		if (!FileSystem.exists(path)) {
			file.name = 'Unknown ($name)';
			return file;
		}

		var rawFile = Json5.parse(sys.io.File.getContent(path));
		for (property in Reflect.fields(rawFile)) {
			// ??????? ok i guess no `Reflect.hasField()` for you
			if (!Reflect.fields(file).contains(property)) continue;

			Reflect.setField(file, property, Reflect.field(rawFile, property));
		}
		#end

		return file;
	}
}

@:structInit
class Addon {
	public var disabled:Bool = false;

	public var name:String = 'Unknown';
	public var id:String = '';
	public var description:String = 'No description given.';
	public var contributors:Array<String> = [];
	public var licensed:Bool = false;

	public function toString():String {
		return 'Addon: $name | Contributors: $contributors';
	}
}