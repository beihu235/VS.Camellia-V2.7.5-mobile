package funkin.modchart.mods;

class SchmovinDrunk extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 0;
    }

	inline function sin(rads:Float, clip:Float){
		var value = FlxMath.fastSin(rads);
		var sign = value / Math.abs(value);
		if(Math.abs(value) > Math.abs(clip))return Math.abs(clip) * sign;
		return value;
	}

    function getDrunkVal(idx:Int, strumline:Int, distance:Float, lane:Int, beat:Float, clipVal: Float) {
        final val = getValue(idx, strumline);
        if (val == 0.0) return 0.0;

        final offset = getValue(idx + 2, strumline);
        final speed = 1 + getValue(idx + 1, strumline);
        final period = 1 + getValue(idx + 3, strumline);

		var phaseShift = (lane * 0.5) + offset + (distance * period) / 222 * Math.PI;
        return sin((beat * speed) / 4 * Math.PI + phaseShift, clipVal) * (Strumline.swagWidth * 0.5) * val;
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        final clipVal:Float = Math.abs(1 - parent.get("sinclip", strumline));
		
		pos.x += getDrunkVal(X_INDEX, strumline, distance, lane, beat, clipVal);
        pos.y += getDrunkVal(Y_INDEX, strumline, distance, lane, beat, clipVal);
        pos.z += getDrunkVal(Z_INDEX, strumline, distance, lane, beat, clipVal);
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(Z_PERIOD_INDEX + 1)) 0.0]);
    }

    // override function isActive(vals:Array<Float>) {
    //     return vals[X_INDEX] != 0.0 || vals[Y_INDEX] != 0.0 || vals[Z_INDEX] != 0.0;
    // }

    public static inline var X_INDEX:Int = 0;
    public static inline var X_SPEED_INDEX:Int = 1;
    public static inline var X_OFFSET_INDEX:Int = 2;
    public static inline var X_PERIOD_INDEX:Int = 3;

    public static inline var Y_INDEX:Int = 4;
    public static inline var Y_SPEED_INDEX:Int = 5;
    public static inline var Y_OFFSET_INDEX:Int = 6;
    public static inline var Y_PERIOD_INDEX:Int = 7;

    public static inline var Z_INDEX:Int = 8;
    public static inline var Z_SPEED_INDEX:Int = 9;
    public static inline var Z_OFFSET_INDEX:Int = 10;
    public static inline var Z_PERIOD_INDEX:Int = 11;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("schmovindrunk", {toClass: SchmovinDrunk, index: X_INDEX});
        ModchartManager.defaultRedirects.set("schmovindrunkspeed", {toClass: SchmovinDrunk, index: X_SPEED_INDEX});
        ModchartManager.defaultRedirects.set("schmovindrunkoffset", {toClass: SchmovinDrunk, index: X_OFFSET_INDEX});
        ModchartManager.defaultRedirects.set("schmovindrunkperiod", {toClass: SchmovinDrunk, index: X_PERIOD_INDEX});

        ModchartManager.defaultRedirects.set("schmovindrunky", {toClass: SchmovinDrunk, index: Y_INDEX});
        ModchartManager.defaultRedirects.set("schmovindrunkyspeed", {toClass: SchmovinDrunk, index: Y_SPEED_INDEX});
        ModchartManager.defaultRedirects.set("schmovindrunkyoffset", {toClass: SchmovinDrunk, index: Y_OFFSET_INDEX});
        ModchartManager.defaultRedirects.set("schmovindrunkyperiod", {toClass: SchmovinDrunk, index: Y_PERIOD_INDEX});

        ModchartManager.defaultRedirects.set("schmovindrunkz", {toClass: SchmovinDrunk, index: Z_INDEX});
        ModchartManager.defaultRedirects.set("schmovindrunkzspeed", {toClass: SchmovinDrunk, index: Z_SPEED_INDEX});
        ModchartManager.defaultRedirects.set("schmovindrunkzoffset", {toClass: SchmovinDrunk, index: Z_OFFSET_INDEX});
        ModchartManager.defaultRedirects.set("schmovindrunkzperiod", {toClass: SchmovinDrunk, index: Z_PERIOD_INDEX});
    }
}