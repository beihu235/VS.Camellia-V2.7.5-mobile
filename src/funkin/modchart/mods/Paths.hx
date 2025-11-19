package funkin.modchart.mods;

class Paths extends BaseModifier {

	inline function sin(rads:Float, clip:Float){
		var value = FlxMath.fastSin(rads);
		var sign = value / Math.abs(value);
		if(Math.abs(value) > Math.abs(clip))return Math.abs(clip) * sign;
		return value;
	}

	inline function cos(rads:Float, clip:Float)
		return sin(rads + Math.PI * 0.5, clip);

	inline function square(angle:Float) {
		var fAngle = angle % (Math.PI * 2);

		return fAngle >= Math.PI ? -1.0 : 1.0;
	}

	inline function triangle(angle:Float) {
		var fAngle:Float = angle % (Math.PI * 2.0);
		if (fAngle < 0.0)
			fAngle += Math.PI * 2.0;
		
		var result:Float = fAngle / Math.PI;
		
		if (result < 0.5) {
			return 2.0 * result;
		}
		else if (result < 1.5) {
			return -2.0 * result + 2.0;
		}
		else {
			return 2.0 * result - 4.0;
		}
	}

	inline function bounce(index:Int, val:Float, diff:Float, strumline:Int, sinClip:Float) {
		final period = getValue(index + 2, strumline);
		if (period == -1) return 0.0;

		return val * Strumline.swagWidth * 0.5 * Math.abs(sin((diff + getValue(index + 1, strumline)) / (90.0 + 90.0 * period), sinClip));
	}

	inline function getDigitalAngle(yOffset:Float, offset:Float, period:Float) {
		return Math.PI * (yOffset + (1 * offset)) / (Strumline.swagWidth + (period * Strumline.swagWidth));
	}

    public function new(parent:ModchartManager) {
        super(parent);
        priority = 20;
    }

	// TODO: dont hardcode this shit
	inline function getXOffset(lane:Int){
		return switch(lane){
			case 0: -Strumline.swagWidth * 1.5;
			case 1: -Strumline.swagWidth * 0.5;
			case 2: Strumline.swagWidth * 0.5;
			case 3: Strumline.swagWidth * 1.5;
			default: 0;
		};
	}

	override public function modifiesDistance(strumline:Int) {return true;}
	override function adjustDistance(spr:FunkinSprite, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {

		final cubicY: Float = getValue(CUBIC_Y_INDEX, strumline);
		if(cubicY != 0)
			distance += cubicY * Math.pow((getValue(CUBIC_Y_OFFSET_INDEX, strumline) + distance) / Strumline.swagWidth, 3);
		
		final parabolaY: Float = getValue(PARABOLA_Y_INDEX, strumline);
		if(parabolaY != 0){
			final factor: Float = (getValue(PARABOLA_Y_OFFSET_INDEX, strumline) + distance) / Strumline.swagWidth;
			distance += parabolaY * factor * factor;
		}

		
		return distance;
	}

    override public function modifiesPosition(strumline:Int) {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		// Gets the distance value based on if PATHS_USE_PATH_Y is enabled or not
		// When enabled, then paths will use pos.y to determine where in the path it is
		// When disabled, paths use distance.
		// Doing it in a function so paths that modify the Y are also taken into account here
		
		final sinClip:Float = Math.abs(1 - parent.get("sinclip", strumline));
		final cosClip:Float = Math.abs(1 - parent.get("cosclip", strumline));

		var usedDistance:Float = getValue(PATHS_USE_PATH_Y, strumline) == 1 ? distance : unadjustedDistance;

		pos.x += getValue(XMODE_INDEX, strumline) * usedDistance * (strumline % 2 == 0 ? 1 : -1);
		final zigzag:Float = getValue(ZIGZAG_INDEX, strumline);
		if (zigzag != 0) {
			final offset: Float = getValue(ZIGZAG_OFFSET_INDEX, strumline);
			final period: Float = getValue(ZIGZAG_PERIOD_INDEX, strumline);
			final result: Float = triangle((Math.PI * (1 / (period + 1)) * ((usedDistance + 100 * offset) / Strumline.swagWidth)));

			pos.x += (zigzag * (Strumline.swagWidth * 0.5)) * result;
		}

		final digital = getValue(DIGITAL_INDEX, strumline);
		if(digital != 0){
			final steps: Float = getValue(DIGITAL_STEPS_INDEX, strumline) + 1;
			final period: Float = getValue(DIGITAL_PERIOD_INDEX, strumline);
			final offset: Float = getValue(DIGITAL_OFFSET_INDEX, strumline);

			pos.x += (digital * (Strumline.swagWidth * 0.5)) * Math.round(steps * sin(getDigitalAngle(usedDistance, offset, period), sinClip)) / steps;
		}

		final squareVal = getValue(SQUARE_INDEX, strumline);
		if (squareVal != 0) {
			final rads: Float = (Math.PI * (usedDistance + getValue(SQUARE_OFFSET_INDEX, strumline)) / (Strumline.swagWidth * (1 + getValue(SQUARE_PERIOD_INDEX, strumline))));
			pos.x += squareVal * Strumline.swagWidth * 0.5 * square(rads);
		}

		final bounceX = getValue(BOUNCE_INDEX, strumline);
		if (bounceX != 0)
			pos.x += bounce(BOUNCE_INDEX, bounceX, usedDistance, strumline, sinClip);

		final bounceZ = getValue(BOUNCE_Z_INDEX, strumline);
		if (bounceZ != 0)
			pos.x += bounce(BOUNCE_Z_INDEX, bounceZ, usedDistance, strumline, sinClip);

		final cubic: Float = getValue(CUBIC_X_INDEX, strumline);
		if(cubic != 0)
			pos.x += cubic * Math.pow((getValue(CUBIC_X_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth, 3);

		final cubicZ: Float = getValue(CUBIC_Z_INDEX, strumline);
		if(cubicZ != 0)
			pos.z += cubicZ * Math.pow((getValue(CUBIC_Z_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth, 3);

		final parabola: Float = getValue(PARABOLA_X_INDEX, strumline);
		if(parabola != 0){
			final factor: Float = (getValue(PARABOLA_X_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.x += parabola * factor * factor;
		}

		final parabolaZ: Float = getValue(PARABOLA_Z_INDEX, strumline);
		if(parabolaZ != 0){
			final factor: Float = (getValue(PARABOLA_Z_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.z += parabolaZ * factor * factor;
		}
		
		var xOffset: Float = getXOffset(lane);

		final attenuateX: Float = getValue(ATTENUATE_INDEX, strumline);
		if(attenuateX != 0){
			final attenuateFactor: Float = (getValue(ATTENUATE_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.x += attenuateX * attenuateFactor * attenuateFactor * (xOffset / Strumline.swagWidth);
		}

		final attenuateY: Float = getValue(ATTENUATE_Y_INDEX, strumline);
		if(attenuateY != 0){

			final attenuateFactor: Float = (getValue(ATTENUATE_Y_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.y += attenuateY * attenuateFactor * attenuateFactor * (xOffset / Strumline.swagWidth);
		}

		final attenuateZ: Float = getValue(ATTENUATE_Z_INDEX, strumline);
		if(attenuateZ != 0){
			final attenuateFactor: Float = (getValue(ATTENUATE_Z_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.z += attenuateZ * attenuateFactor * attenuateFactor * (xOffset / Strumline.swagWidth);
		}

		final tornado: Float = getValue(TORNADO_INDEX, strumline);
		if (tornado != 0) {
			// from schmovin!! (well i copy pasted this from troll)
			var columnPhaseShift = (lane * Math.PI / 3) + getValue(TORNADO_OFFSET_INDEX, strumline);
			var phaseShift = (usedDistance / 135) * (1 + getValue(TORNADO_PERIOD_INDEX, strumline));
			// originally Note.halfWidth * (keyCount - 1)
			var returnReceptorToZeroOffsetX = (-cos(-columnPhaseShift, cosClip) + 1) * Strumline.swagWidth * 1.5;
			var offsetX = (-cos(phaseShift - columnPhaseShift, cosClip) + 1) * Strumline.swagWidth * 1.5 - returnReceptorToZeroOffsetX;
			pos.x += offsetX * tornado;
		}
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        values.push([for(i in 0...PATHS_USE_PATH_Y + 1) 0.0]);
    }


    public static inline var XMODE_INDEX:Int = 0;
    public static inline var ZIGZAG_INDEX:Int = 1;
	public static inline var ZIGZAG_OFFSET_INDEX:Int = 2;
	public static inline var ZIGZAG_PERIOD_INDEX:Int = 3;

	public static inline var DIGITAL_INDEX:Int = 4;
	public static inline var DIGITAL_OFFSET_INDEX:Int = 5;
	public static inline var DIGITAL_PERIOD_INDEX:Int = 6;
	public static inline var DIGITAL_STEPS_INDEX:Int = 7;
	public static inline var CUBIC_X_INDEX:Int = 8;
	public static inline var CUBIC_X_OFFSET_INDEX:Int = 9;
	public static inline var CUBIC_Y_INDEX:Int = 10;
	public static inline var CUBIC_Y_OFFSET_INDEX:Int = 11;
	public static inline var CUBIC_Z_INDEX:Int = 12;
	public static inline var CUBIC_Z_OFFSET_INDEX:Int = 13;
	
	public static inline var PARABOLA_X_INDEX:Int = 14;
	public static inline var PARABOLA_X_OFFSET_INDEX:Int = 15;
	public static inline var PARABOLA_Y_INDEX:Int = 16;
	public static inline var PARABOLA_Y_OFFSET_INDEX:Int = 17;
	public static inline var PARABOLA_Z_INDEX:Int = 18;
	public static inline var PARABOLA_Z_OFFSET_INDEX:Int = 19;

	public static inline var ATTENUATE_INDEX:Int = 20;
	public static inline var ATTENUATE_OFFSET_INDEX:Int = 21;

	public static inline var ATTENUATE_Y_INDEX:Int = 22;
	public static inline var ATTENUATE_Y_OFFSET_INDEX:Int = 23;

	public static inline var ATTENUATE_Z_INDEX:Int = 24;
	public static inline var ATTENUATE_Z_OFFSET_INDEX:Int = 25;

	public static inline var BOUNCE_INDEX = 26;
	public static inline var BOUNCE_OFFSET_INDEX = 27;
	public static inline var BOUNCE_PERIOD_INDEX = 28;
	public static inline var BOUNCE_Z_INDEX = 29;
	public static inline var BOUNCE_Z_OFFSET_INDEX = 30;
	public static inline var BOUNCE_Z_PERIOD_INDEX = 31;

	public static inline var SQUARE_INDEX = 32;
	public static inline var SQUARE_OFFSET_INDEX = 33;
	public static inline var SQUARE_PERIOD_INDEX = 34;

	public static inline var TORNADO_INDEX = 35;
	public static inline var TORNADO_OFFSET_INDEX = 36;
	public static inline var TORNADO_PERIOD_INDEX = 37;

	public static inline var PATHS_USE_PATH_Y = 38;

    public static function attachToRedirects() {
		var modifiers: Array<String> = [
			"xmode", 
			"zigzag", 
			"zigzagoffset", 
			"zigzagperiod", 
			"digital", 
			"digitaloffset", 
			"digitalperiod", 
			"digitalsteps", 
			"cubicx", 
			"cubicxoffset", 
			"cubicy",
			"cubicyoffset",
			"cubicz",
			"cubiczoffset",
			"parabolax", 
			"parabolaxoffset", 
			"parabolay",
			"parabolayoffset",
			"parabolaz",
			"parabolazoffset",
			"attenuate",
			"attenuateoffset",
			"attenuatey",
			"attenuateyoffset",
			"attenuatez",
			"attenuatezoffset",
			"bounce",
			"bounceoffset",
			"bounceperiod",
			"bouncez",
			"bouncezoffset",
			"bouncezperiod",
			"square",
			"squareoffset",
			"squareperiod",
			"tornado",
			"tornadooffset",
			"tornadoperiod",
			"pathtype" // TODO: maybe figure out a new name, but TL;DR similar to stealthtype where if its 1 then paths will use pos.y instead of distance
			// maybe this should be an aux mod in modmanager that every path mod that requires note's y pos follows? we should also add stealthtype lol
		];

		for(idx in 0...modifiers.length)
			ModchartManager.defaultRedirects.set(modifiers[idx], {toClass: Paths, index: idx});

		// Aliases
		ModchartManager.defaultRedirects.set("attenuatex", {toClass: Paths, index: ATTENUATE_INDEX});
		ModchartManager.defaultRedirects.set("attenuatexoffset", {toClass: Paths, index: ATTENUATE_OFFSET_INDEX});

		

    }
}