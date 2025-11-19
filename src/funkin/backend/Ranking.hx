package funkin.backend;

@:structInit
class Ranking {
	public static final clearTypeList:Array<String> = 		["N/A", 		"Clear", 		"SDCB", 	 "MF", 			"FC", 			"GFC", 			"SDG", 		"BF", 			"PFC", 			"SDP", 			"WF", 			"MFC"];
	public static final clearTypeColours:Array<FlxColor> = 	[0xFF808080, 0xFF000000,	 0xFF000000, 0xFF000000, 0xFF0090FF,	  0xFF3EC53E,  0xFF3EC53E,0xFF3EC53E,  0xFFDCAB24,	 0xFFDDFF00,	0xFFDDFF00,  0xFFDDFF00];

	public static var list:Array<Ranking> = [
		{name: 'X', accuracy: 100, color: 0xFF8BE4FF},
		{name: 'S+', accuracy: 99, color: 0xFFFFED49},
		{name: 'S', accuracy: 95, color: 0xFFFFC549},
		{name: 'A', accuracy: 90, color: 0xFF52FF52},
		{name: 'B', accuracy: 80, color: 0xFF6898FF},
		{name: 'C', accuracy: 70, color: 0xFFB373BB},
		{name: 'D', accuracy: 60, color: 0xFFFF3A3A},
		{name: 'F', accuracy: 0, color: 0xFF27060D},
	];

	public static var highest(get, never):Ranking;
	static function get_highest():Ranking return list[0];

	public static var lowest(get, never):Ranking;
	static function get_lowest():Ranking return list[list.length - 1];

	public var name:String = "?";
	public var accuracy:Float = 0;
	public var color:FlxColor = FlxColor.GRAY;

	public static function getFromAccuracy(acc:Float):Ranking {
		for (rank in list) {
			if (acc >= rank.accuracy)
				return rank;
		}

		return lowest;
	}

	public function toString():String {
		return '$name: | Min-Accuracy: $accuracy';
	}
}