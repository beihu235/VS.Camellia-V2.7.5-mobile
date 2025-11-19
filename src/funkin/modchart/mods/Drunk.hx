package funkin.modchart.mods;

class Drunk extends BaseModifier {
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

    // https://github.com/riconuts/FNF-Troll-Engine/blob/f6b7062b0fb759a9d08cef4205dcc157889419c3/source/funkin/modchart/modifiers/DrunkModifier.hx#L15
    function getDrunkVal(idx:Int, strumline:Int, distance:Float, lane:Int, time:Float, clipVal:Float) {
        final val = getValue(idx, strumline);
        if (val == 0.0) return 0.0;

        final speed = getValue(idx + 1, strumline);
        final spacing = getValue(idx + 2, strumline);
        final period = getValue(idx + 3, strumline);
		final offset = getValue(idx + 4, strumline);


        final rads = time * (1.0 + speed) + offset + lane * ((spacing * 0.2) + 0.2) + distance * ((period * 10.0) + 10.0) / FlxG.height;
		return val * sin(rads, clipVal) * Strumline.swagWidth * 0.5;
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        final time = Conductor.visualTime * 0.001;
		final clipVal:Float = Math.abs(1 - parent.get("sinclip", strumline));

        pos.x += getDrunkVal(X_INDEX, strumline, distance, lane, time, clipVal);
        pos.y += getDrunkVal(Y_INDEX, strumline, distance, lane, time, clipVal);
        pos.z += getDrunkVal(Z_INDEX, strumline, distance, lane, time, clipVal);
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
    public static inline var X_SPACING_INDEX:Int = 2;
    public static inline var X_PERIOD_INDEX:Int = 3;
	public static inline var X_OFFSET_INDEX:Int = 4;

    public static inline var Y_INDEX:Int = 5;
    public static inline var Y_SPEED_INDEX:Int = 6;
    public static inline var Y_SPACING_INDEX:Int = 7;
    public static inline var Y_PERIOD_INDEX:Int = 8;
	public static inline var Y_OFFSET_INDEX:Int = 9;

    public static inline var Z_INDEX:Int = 10;
    public static inline var Z_SPEED_INDEX:Int = 11;
    public static inline var Z_SPACING_INDEX:Int = 12;
    public static inline var Z_PERIOD_INDEX:Int = 13;
	public static inline var Z_OFFSET_INDEX:Int = 14;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("drunk", {toClass: Drunk, index: X_INDEX});
        ModchartManager.defaultRedirects.set("drunkspeed", {toClass: Drunk, index: X_SPEED_INDEX});
        ModchartManager.defaultRedirects.set("drunkspacing", {toClass: Drunk, index: X_SPACING_INDEX});
        ModchartManager.defaultRedirects.set("drunkperiod", {toClass: Drunk, index: X_PERIOD_INDEX});
		ModchartManager.defaultRedirects.set("drunkoffset", {toClass: Drunk, index: X_OFFSET_INDEX});

        ModchartManager.defaultRedirects.set("drunky", {toClass: Drunk, index: Y_INDEX});
        ModchartManager.defaultRedirects.set("drunkyspeed", {toClass: Drunk, index: Y_SPEED_INDEX});
        ModchartManager.defaultRedirects.set("drunkyspacing", {toClass: Drunk, index: Y_SPACING_INDEX});
        ModchartManager.defaultRedirects.set("drunkyperiod", {toClass: Drunk, index: Y_PERIOD_INDEX});
		ModchartManager.defaultRedirects.set("drunkyoffset", {toClass: Drunk, index: Y_OFFSET_INDEX});

        ModchartManager.defaultRedirects.set("drunkz", {toClass: Drunk, index: Z_INDEX});
        ModchartManager.defaultRedirects.set("drunkzspeed", {toClass: Drunk, index: Z_SPEED_INDEX});
        ModchartManager.defaultRedirects.set("drunkzspacing", {toClass: Drunk, index: Z_SPACING_INDEX});
        ModchartManager.defaultRedirects.set("drunkzperiod", {toClass: Drunk, index: Z_PERIOD_INDEX});
		ModchartManager.defaultRedirects.set("drunkzoffset", {toClass: Drunk, index: Z_OFFSET_INDEX});
    }
}