package funkin.modchart.mods;

class Skew extends BaseModifier {
	public function new(parent:ModchartManager) {
		super(parent);
		priority = 4;
	}

	override public function modifiesVertex(strumline:Int) {return true;}
	override public function adjustVertex(spr:FunkinSprite, vertex:Vector3, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        vertex.x -= field.centerX;
        vertex.y -= FlxG.height * 0.5;

        vertex.x += vertex.y * getValue(X_INDEX, strumline);
        vertex.y += FlxG.height * vertex.x / (Strumline.swagWidth * 4) * getValue(Y_INDEX, strumline);

        vertex.x += field.centerX;
        vertex.y += FlxG.height * 0.5;
	}

	override public function addStrumlineSet() {
		super.addStrumlineSet();
		// highest index + 4 if it's lane specific, + 1 if not.
		values.push([for (i in 0...(Y_INDEX + 1)) 0.0]);
	}

	public static inline var X_INDEX:Int = 0;
	public static inline var Y_INDEX:Int = 1;

	public static function attachToRedirects() {
		ModchartManager.defaultRedirects.set("skewx", {toClass: Skew, index: X_INDEX});
		ModchartManager.defaultRedirects.set("skewy", {toClass: Skew, index: Y_INDEX});
	}
}