package funkin.modchart.mods;

class CenteredPath extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = -1;
    }

	override public function modifiesDistance(strumline:Int):Bool {return true;}
	override function adjustDistance(spr:FunkinSprite, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType):Float {
		final pathType:Float = getValue(CENTERED_PATH_TYPE, strumline);
		final noteSpeed:Float = field.overrideScrollSpeed <= 0 ? grandparent.scrollSpeed : field.overrideScrollSpeed;

		final newDistance:Float = distance + (FlxMath.lerp(Strumline.swagWidth, Conductor.crotchet * noteSpeed * 0.45, pathType) * getValue(INDEX, strumline)) + getValue(TROLL_INDEX, strumline);
		return newDistance;
	}

	override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(CENTERED_PATH_TYPE + 1)) 0.0]);
    }

    public static inline final INDEX:Int = 0;
	public static inline final LANE_INDEX:Int = 1;

	public static inline final TROLL_INDEX:Int = 5;
	public static inline final TROLL_LANE_INDEX:Int = 6;

	public static inline final CENTERED_PATH_TYPE:Int = 10;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("centeredpath", {toClass: CenteredPath, index: INDEX});
		ModchartManager.defaultRedirects.set("transformpath", {toClass: CenteredPath, index: TROLL_INDEX});
		ModchartManager.defaultRedirects.set("centeredpathtype", {toClass: CenteredPath, index: CENTERED_PATH_TYPE});
		for(i in 0...4){
			ModchartManager.defaultRedirects.set('centeredpath$i', {toClass: CenteredPath, index: LANE_INDEX + i});
			ModchartManager.defaultRedirects.set('transformpath$i', {toClass: CenteredPath, index: TROLL_LANE_INDEX + i});
		}
		// aliases
		ModchartManager.defaultRedirects.set("movepath", {toClass: CenteredPath, index: INDEX});
		ModchartManager.defaultRedirects.set("centered2", {toClass: CenteredPath, index: INDEX});

    }
}