package funkin.modchart.mods;

class Accel extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 0;
    }

    // https://github.com/riconuts/FNF-Troll-Engine/blob/0f3f4dd1855066a4e4a7a01e5dcf2e717bbb1174/source/funkin/modchart/modifiers/AccelModifier.hx#L8
    override function modifiesDistance(strumline:Int):Bool {return true;}
    override function adjustDistance(spr:FunkinSprite, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		var effectHeight = 720;

		var yAdjust:Float = 0;

        final brake = getValue(BRAKE_INDEX, strumline);
		if (brake != 0) {
			final scale = distance / FlxG.height;
			final off = distance * scale;
			yAdjust += Math.min(Math.max(brake * (off - distance), -600), 600);
		}

        final boost = getValue(BOOST_INDEX, strumline);
		if (boost != 0) {
			final off = distance * 1.5 / ((distance + effectHeight / 1.2) / FlxG.height);
			yAdjust += Math.min(Math.max(boost * (off - distance), -600), 600);
		}

        final wave = getValue(WAVE_INDEX, strumline);
        final wavePeriod = getValue(WAVE_PERIOD_INDEX, strumline);
		if (wavePeriod != -1 /**< no division by 0**/ && wave != 0) 
			yAdjust += wave * 40 * FlxMath.fastSin(distance / ((114 * wavePeriod) + 114));

		return distance + yAdjust;
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(WAVE_PERIOD_INDEX + 1)) 0.0]);
    }

    public static inline var BOOST_INDEX:Int = 0;
    public static inline var BRAKE_INDEX:Int = 1;
    public static inline var WAVE_INDEX:Int = 2;
    public static inline var WAVE_PERIOD_INDEX:Int = 3;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("boost", {toClass: Accel, index: BOOST_INDEX});
        ModchartManager.defaultRedirects.set("brake", {toClass: Accel, index: BRAKE_INDEX});
        ModchartManager.defaultRedirects.set("wave", {toClass: Accel, index: WAVE_INDEX});
        ModchartManager.defaultRedirects.set("waveperiod", {toClass: Accel, index: WAVE_PERIOD_INDEX});
    }
}