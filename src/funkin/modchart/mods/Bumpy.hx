package funkin.modchart.mods;

class Bumpy extends BaseModifier {
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


    // https://github.com/riconuts/FNF-Troll-Engine/blob/f6b7062b0fb759a9d08cef4205dcc157889419c3/source/funkin/modchart/modifiers/DrunkModifier.hx#L45
    function getBumpyVal(idx:Int, strumline:Int, distance:Float, lane:Int, clip:Float) {
        final val = getValue(idx, strumline);
        if (val == 0.0) return 0.0;

        final offset = getValue(idx + 1, strumline);
        final period = getValue(idx + 2, strumline);

        final rads = (distance + (100.0 * offset)) / ((period * 24.0) + 24.0);
        return val * sin(rads, clip) * 40.0;
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        final clipVal:Float = Math.abs(1 - parent.get("sinclip", strumline));

		pos.x += getBumpyVal(X_INDEX, strumline, distance, lane, clipVal);
        pos.y += getBumpyVal(Y_INDEX, strumline, distance, lane, clipVal);
        pos.z += getBumpyVal(Z_INDEX, strumline, distance, lane, clipVal);
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(Z_PERIOD_INDEX + 1)) 0.0]);
    }

    override function isActive(vals:Array<Float>) {
        return vals[X_INDEX] != 0.0 || vals[Y_INDEX] != 0.0 || vals[Z_INDEX] != 0.0;
    }

    public static inline var X_INDEX:Int = 0;
    public static inline var X_OFFSET_INDEX:Int = 1;
    public static inline var X_PERIOD_INDEX:Int = 2;

    public static inline var Y_INDEX:Int = 3;
    public static inline var Y_OFFSET_INDEX:Int = 4;
    public static inline var Y_PERIOD_INDEX:Int = 5;

    public static inline var Z_INDEX:Int = 6;
    public static inline var Z_OFFSET_INDEX:Int = 7;
    public static inline var Z_PERIOD_INDEX:Int = 8;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("bumpyx", {toClass: Bumpy, index: X_INDEX});
        ModchartManager.defaultRedirects.set("bumpyxoffset", {toClass: Bumpy, index: X_OFFSET_INDEX});
        ModchartManager.defaultRedirects.set("bumpyxperiod", {toClass: Bumpy, index: X_PERIOD_INDEX});

        ModchartManager.defaultRedirects.set("bumpyy", {toClass: Bumpy, index: Y_INDEX});
        ModchartManager.defaultRedirects.set("bumpyyoffset", {toClass: Bumpy, index: Y_OFFSET_INDEX});
        ModchartManager.defaultRedirects.set("bumpyyperiod", {toClass: Bumpy, index: Y_PERIOD_INDEX});

        ModchartManager.defaultRedirects.set("bumpy", {toClass: Bumpy, index: Z_INDEX});
        ModchartManager.defaultRedirects.set("bumpyoffset", {toClass: Bumpy, index: Z_OFFSET_INDEX});
        ModchartManager.defaultRedirects.set("bumpyperiod", {toClass: Bumpy, index: Z_PERIOD_INDEX});
    }
}