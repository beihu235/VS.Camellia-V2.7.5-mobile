package funkin.objects;

typedef StageFile = {
	var ?zoom:Float;
	var ?isSpectatorVisible:Bool;

	var ?playerPos:Array<Float>;
	var ?spectatorPos:Array<Float>;
	var ?opponentPos:Array<Float>;

	var ?cameraPos:Array<Float>;
}

class Stage {
	var _file:StageFile;

	public var player:FlxPoint = FlxPoint.get(0, 0);
	public var spectator:FlxPoint = FlxPoint.get(0, 0);
	public var opponent:FlxPoint = FlxPoint.get(0, 0);
	public var camera:FlxPoint = FlxPoint.get(0, 0);

	public var zoom:Float = 1;
	public var isSpectatorVisible:Bool = true;

	public function new(name:String) {
		_file = getFile('stages/$name.json');

		player.set(_file.playerPos[0], _file.playerPos[1]);
		spectator.set(_file.spectatorPos[0], _file.spectatorPos[1]);
		opponent.set(_file.opponentPos[0], _file.opponentPos[1]);
		camera.set(_file.cameraPos[0], _file.cameraPos[1]);

		zoom = _file.zoom;
		isSpectatorVisible = _file.isSpectatorVisible;
	}

	public static function getFile(path:String):StageFile {
		var file:StageFile = createDummyFile();
		path = Paths.get(path);
		if (!FileSystem.exists(path)) return file;
		
		var data = Json5.parse(File.getContent(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		return file;
	}

	public static function createDummyFile():StageFile {
		return {
			zoom: 1,
			isSpectatorVisible: true,

			playerPos: [750, 225],
			spectatorPos: [350, 0],
			opponentPos: [100, 225],

			cameraPos: [0, 0]
		}
	}
}