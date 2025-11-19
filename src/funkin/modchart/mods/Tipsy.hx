package funkin.modchart.mods;

class Tipsy extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 0;
    }

	inline function cos(rads:Float, clip:Float){
		var value = Math.cos(rads);
		var sign = value / Math.abs(value);
		if(Math.abs(value) > Math.abs(clip))return Math.abs(clip) * sign;
		return value;
	}


    // https://github.com/riconuts/FNF-Troll-Engine/blob/f6b7062b0fb759a9d08cef4205dcc157889419c3/source/funkin/modchart/modifiers/DrunkModifier.hx#L30
    function getTipsyVal(idx:Int, strumline:Int, lane:Int, time:Float, clip:Float) {
        final val = getValue(idx, strumline);
        if (val == 0.0) return 0.0;

        final speed = getValue(idx + 1, strumline);
        final spacing = getValue(idx + 2, strumline);
		final offset = getValue(idx + 3, strumline);

        final rads = time * ((speed * 1.2) + 1.2) + offset * 1.2 + lane * ((spacing * 1.8) + 1.8);
        return val * cos(rads, clip) * Strumline.swagWidth * 0.4;
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        final time = Conductor.visualTime * 0.001;
		final clipVal:Float = Math.abs(1 - parent.get("cosclip", strumline));

        pos.x += getTipsyVal(X_INDEX, strumline, lane, time, clipVal);
        pos.y += getTipsyVal(Y_INDEX, strumline, lane, time, clipVal);
        pos.z += getTipsyVal(Z_INDEX, strumline, lane, time, clipVal);
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(Z_OFFSET_INDEX + 1)) 0.0]);
    }

    override function isActive(vals:Array<Float>) {
        return vals[X_INDEX] != 0.0 || vals[Y_INDEX] != 0.0 || vals[Z_INDEX] != 0.0;
    }

    public static inline var X_INDEX:Int = 0;
    public static inline var X_SPEED_INDEX:Int = 1;
    public static inline var X_SPACING_INDEX:Int = 2;
	public static inline var X_OFFSET_INDEX:Int = 3;

    public static inline var Y_INDEX:Int = 4;
    public static inline var Y_SPEED_INDEX:Int = 5;
    public static inline var Y_SPACING_INDEX:Int = 6;
	public static inline var Y_OFFSET_INDEX:Int = 7;

    public static inline var Z_INDEX:Int = 8;
    public static inline var Z_SPEED_INDEX:Int = 9;
    public static inline var Z_SPACING_INDEX:Int = 10;
	public static inline var Z_OFFSET_INDEX:Int = 11;



    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("tipsyx", {toClass: Tipsy, index: X_INDEX});
        ModchartManager.defaultRedirects.set("tipsyxspeed", {toClass: Tipsy, index: X_SPEED_INDEX});
        ModchartManager.defaultRedirects.set("tipsyxspacing", {toClass: Tipsy, index: X_SPACING_INDEX});
		ModchartManager.defaultRedirects.set("tipsyxoffset", {toClass: Tipsy, index: X_OFFSET_INDEX});

        ModchartManager.defaultRedirects.set("tipsy", {toClass: Tipsy, index: Y_INDEX});
        ModchartManager.defaultRedirects.set("tipsyspeed", {toClass: Tipsy, index: Y_SPEED_INDEX});
        ModchartManager.defaultRedirects.set("tipsyspacing", {toClass: Tipsy, index: Y_SPACING_INDEX});
		ModchartManager.defaultRedirects.set("tipsyoffset", {toClass: Tipsy, index: Y_OFFSET_INDEX});

        ModchartManager.defaultRedirects.set("tipsyz", {toClass: Tipsy, index: Z_INDEX});
        ModchartManager.defaultRedirects.set("tipsyzspeed", {toClass: Tipsy, index: Z_SPEED_INDEX});
        ModchartManager.defaultRedirects.set("tipsyzspacing", {toClass: Tipsy, index: Z_SPACING_INDEX});
		ModchartManager.defaultRedirects.set("tipsyzoffset", {toClass: Tipsy, index: Z_OFFSET_INDEX});
    }
}