package funkin.modchart.mods;

class Beat extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 0;
    }

    public var beatTimes:Array<Array<Float>> = [];

    // from troll (https://github.com/riconuts/FNF-Troll-Engine/blob/a720ab67120449dc96d2f14d20aebd0c9260e2b4/source/funkin/modchart/modifiers/BeatModifier.hx#L19)
    // however the math is simplified.
    final accelTime:Float = 0.2;
    final totalTime:Float = 0.5;
    function getBeatTime(inBeat:Float, offset:Float, mult:Float) {
        //Sys.println(mult + 1.0);
        var beat:Float = (inBeat + accelTime + offset) * (mult + 1.0);
        if (beat < 0) return 0.0;

        final endMult:Float = beat % 2 >= 1 ? -1 : 1;
		beat %= 1.0;

        if (beat >= totalTime) return 0.0;

        var amt:Float = 0.0;
        if (beat <= accelTime) {
            amt = beat / accelTime;
            amt *= amt;
        } else {
            amt = (beat - accelTime) / (totalTime - accelTime);
            amt = 1 - amt * amt;
        }

        return 40.0 * amt * endMult;
    }

	inline function cos(rads:Float, clip:Float){
		var value = Math.cos(rads);
		var sign = value / Math.abs(value);
		if(Math.abs(value) > Math.abs(clip))return Math.abs(clip) * sign;
		return value;
	}


    override public function prepare(strumline:Int, beat:Float) {
        beatTimes[strumline][0] = getBeatTime(beat, getValue(X_OFFSET_INDEX, strumline), getValue(X_MULT_INDEX, strumline));
        beatTimes[strumline][1] = getBeatTime(beat, getValue(Y_OFFSET_INDEX, strumline), getValue(Y_MULT_INDEX, strumline));
        beatTimes[strumline][2] = getBeatTime(beat, getValue(Z_OFFSET_INDEX, strumline), getValue(Z_MULT_INDEX, strumline));
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        // use cos so we dont need to offset pi/2
		final clip:Float = Math.abs(1 - parent.get("cosclip", strumline));

        final xPeriod = ((getValue(X_PERIOD_INDEX, strumline) * 30) + 30);
        pos.x += getValue(X_INDEX, strumline) * beatTimes[strumline][0] * cos(distance / xPeriod, clip);

        final yPeriod = ((getValue(Y_PERIOD_INDEX, strumline) * 30) + 30);
        pos.y += getValue(Y_INDEX, strumline) * beatTimes[strumline][1] * cos(distance / yPeriod, clip);

        final zPeriod = ((getValue(Z_PERIOD_INDEX, strumline) * 30) + 30);
        pos.z += getValue(Z_INDEX, strumline) * beatTimes[strumline][2] * cos(distance / zPeriod, clip);
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(Z_MULT_INDEX + 1)) 0.0]);

        // modifier specific array!
        beatTimes.push([0.0, 0.0, 0.0]);
    }

    override function isActive(vals:Array<Float>) {
        return vals[X_INDEX] != 0.0 || vals[Y_INDEX] != 0.0 || vals[Z_INDEX] != 0.0;
    }

    public static inline var X_INDEX:Int = 0;
    public static inline var X_OFFSET_INDEX:Int = 1;
    public static inline var X_PERIOD_INDEX:Int = 2;
    public static inline var X_MULT_INDEX:Int = 3;

    public static inline var Y_INDEX:Int = 4;
    public static inline var Y_OFFSET_INDEX:Int = 6;
    public static inline var Y_PERIOD_INDEX:Int = 7;
    public static inline var Y_MULT_INDEX:Int = 5;

    public static inline var Z_INDEX:Int = 8;
    public static inline var Z_OFFSET_INDEX:Int = 9;
    public static inline var Z_PERIOD_INDEX:Int = 10;
    public static inline var Z_MULT_INDEX:Int = 11;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("beat", {toClass: Beat, index: X_INDEX});
        ModchartManager.defaultRedirects.set("beatoffset", {toClass: Beat, index: X_OFFSET_INDEX});
        ModchartManager.defaultRedirects.set("beatperiod", {toClass: Beat, index: X_PERIOD_INDEX});
        ModchartManager.defaultRedirects.set("beatmult", {toClass: Beat, index: X_MULT_INDEX});

        ModchartManager.defaultRedirects.set("beaty", {toClass: Beat, index: Y_INDEX});
        ModchartManager.defaultRedirects.set("beatyoffset", {toClass: Beat, index: Y_OFFSET_INDEX});
        ModchartManager.defaultRedirects.set("beatyperiod", {toClass: Beat, index: Y_PERIOD_INDEX});
        ModchartManager.defaultRedirects.set("beatymult", {toClass: Beat, index: Y_MULT_INDEX});

        ModchartManager.defaultRedirects.set("beatz", {toClass: Beat, index: Z_INDEX});
        ModchartManager.defaultRedirects.set("beatzoffset", {toClass: Beat, index: Z_OFFSET_INDEX});
        ModchartManager.defaultRedirects.set("beatzperiod", {toClass: Beat, index: Z_PERIOD_INDEX});
        ModchartManager.defaultRedirects.set("beatzmult", {toClass: Beat, index: Z_MULT_INDEX});
    }
}