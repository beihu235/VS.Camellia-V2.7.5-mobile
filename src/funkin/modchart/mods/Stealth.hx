package funkin.modchart.mods;

class Stealth extends BaseModifier {
	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	override public function modifiesStealth(strumline:Int):Bool {return true;}
	override public function getStealth(spr:FunkinSprite, stealth:Float, distance:Float, unadjustedDistance:Float, pos:Vector3, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		final hidden = getValue(HIDDEN_INDEX, strumline);
		final hiddenOff = 160 * getValue(HIDDEN_OFFSET_INDEX, strumline); // i went to openitg to get this value what am i doing
		final sudden = getValue(SUDDEN_INDEX, strumline);
		final suddenOff = 160 * getValue(SUDDEN_OFFSET_INDEX, strumline);
		final regionMult = Math.max((hidden + sudden) - 1.0, 0.0);
		final reverseType = Math.floor(getValue(STEALTH_TYPE_INDEX, strumline));

		if (type != STRUM) {
			if(reverseType == 0){
				if(parent.scrollMult > 0){
					stealth += Math.min(Math.max(FlxMath.remapToRange(
						pos.y,
						FlxG.height * (0.45 - 0.25 * regionMult) + hiddenOff,
						FlxG.height * (0.55 - 0.25 * regionMult) + hiddenOff,
						1,
						0
					), 0.0), 1.0) * hidden;
					stealth += Math.min(Math.max(FlxMath.remapToRange(
						pos.y,
						FlxG.height * (0.45 + 0.15 * regionMult) + suddenOff,
						FlxG.height * (0.55 + 0.15 * regionMult) + suddenOff,
						0,
						1
					), 0.0), 1.0) * sudden;
				}else{
					// flipped for reverse
					
					stealth += Math.min(Math.max(FlxMath.remapToRange(
						pos.y,
						FlxG.height * (0.55 - 0.25 * regionMult) + hiddenOff,
						FlxG.height * (0.45 - 0.25 * regionMult) + hiddenOff,
						1,
						0
					), 0.0), 1.0) * hidden;
					stealth += Math.min(Math.max(FlxMath.remapToRange(
						pos.y,
						FlxG.height * (0.55 + 0.15 * regionMult) + suddenOff,
						FlxG.height * (0.45 + 0.15 * regionMult) + suddenOff,
						0,
						1
					), 0.0), 1.0) * sudden;
				}
			}else{
				stealth += Math.min(Math.max(FlxMath.remapToRange(
					reverseType == 2 ? unadjustedDistance : distance,
					FlxG.height * (0.45 - 0.25 * regionMult) + hiddenOff,
					FlxG.height * (0.55 - 0.25 * regionMult) + hiddenOff,
					1,
					0
				), 0.0), 1.0) * hidden;
				stealth += Math.min(Math.max(FlxMath.remapToRange(
					reverseType == 2 ? unadjustedDistance : distance,
					FlxG.height * (0.45 + 0.15 * regionMult) + suddenOff,
					FlxG.height * (0.55 + 0.15 * regionMult) + suddenOff,
					0,
					1
				), 0.0), 1.0) * sudden;
			}
			stealth += getValue(STEALTH_INDEX, strumline) + getValue(STEALTH_LANE_INDEX + lane, strumline);
		} else
			stealth += getValue(DARK_INDEX, strumline) + getValue(DARK_LANE_INDEX + lane, strumline);

		parent.stealthColor.x = getValue(GLOW_RED_INDEX, strumline) * getValue(GLOW_RED_LANE_INDEX + lane, strumline);
		parent.stealthColor.y = getValue(GLOW_GREEN_INDEX, strumline) * getValue(GLOW_GREEN_LANE_INDEX + lane, strumline);
		parent.stealthColor.z = getValue(GLOW_BLUE_INDEX, strumline) * getValue(GLOW_BLUE_LANE_INDEX + lane, strumline);

		return stealth;
	}


	override function isActive(vals:Array<Float>) {
		for (i => num in vals) {
			final check = ((i >= GLOW_RED_INDEX && i < GLOW_BLUE_INDEX + 1) || (i >= GLOW_RED_LANE_INDEX && i < GLOW_BLUE_LANE_INDEX + 4)) ? 1.0 : 0.0;
			if (num != check)
				return true;
		}
		return false;
	}

	override public function addStrumlineSet() {
		super.addStrumlineSet();
		// highest index + 4 if it's lane specific, + 1 if not.
		final newValSet = [for (i in 0...(STEALTH_TYPE_INDEX + 1)) 0.0];
		for (i in GLOW_RED_INDEX...(GLOW_BLUE_INDEX + 1))
			newValSet[i] = 1.0;
		for (i in GLOW_RED_LANE_INDEX...(GLOW_BLUE_LANE_INDEX + 4))
			newValSet[i] = 1.0;
		values.push(newValSet);
	}

	public static inline var STEALTH_INDEX:Int = 0;
	public static inline var DARK_INDEX:Int = 1;
	public static inline var HIDDEN_INDEX:Int = 2;
	public static inline var SUDDEN_INDEX:Int = 3;
	public static inline var HIDDEN_OFFSET_INDEX:Int = 4;
	public static inline var SUDDEN_OFFSET_INDEX:Int = 5;

	public static inline var GLOW_RED_INDEX:Int = 6;
	public static inline var GLOW_GREEN_INDEX:Int = 7;
	public static inline var GLOW_BLUE_INDEX:Int = 8;

	public static inline var STEALTH_LANE_INDEX:Int = 9;
	public static inline var DARK_LANE_INDEX:Int = 13;

	public static inline var GLOW_RED_LANE_INDEX:Int = 17;
	public static inline var GLOW_GREEN_LANE_INDEX:Int = 21;
	public static inline var GLOW_BLUE_LANE_INDEX:Int = 25;

	public static inline var STEALTH_TYPE_INDEX:Int = 29;

	public static function attachToRedirects() {
		ModchartManager.defaultRedirects.set("stealth", {toClass: Stealth, index: STEALTH_INDEX});
		ModchartManager.defaultRedirects.set("dark", {toClass: Stealth, index: DARK_INDEX});
		ModchartManager.defaultRedirects.set("hidden", {toClass: Stealth, index: HIDDEN_INDEX});
		ModchartManager.defaultRedirects.set("sudden", {toClass: Stealth, index: SUDDEN_INDEX});
		ModchartManager.defaultRedirects.set("hiddenoffset", {toClass: Stealth, index: HIDDEN_OFFSET_INDEX});
		ModchartManager.defaultRedirects.set("suddenoffset", {toClass: Stealth, index: SUDDEN_OFFSET_INDEX});
		
		ModchartManager.defaultRedirects.set("stealthglowred", {toClass: Stealth, index: GLOW_RED_INDEX});
		ModchartManager.defaultRedirects.set("stealthglowgreen", {toClass: Stealth, index: GLOW_GREEN_INDEX});
		ModchartManager.defaultRedirects.set("stealthglowblue", {toClass: Stealth, index: GLOW_BLUE_INDEX});
		ModchartManager.defaultRedirects.set("stealthgr", {toClass: Stealth, index: GLOW_RED_INDEX});
		ModchartManager.defaultRedirects.set("stealthgg", {toClass: Stealth, index: GLOW_GREEN_INDEX});
		ModchartManager.defaultRedirects.set("stealthgb", {toClass: Stealth, index: GLOW_BLUE_INDEX});

		for (i in 0...4) {
			ModchartManager.defaultRedirects.set("stealth" + i, {toClass: Stealth, index: STEALTH_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("dark" + i, {toClass: Stealth, index: DARK_LANE_INDEX + i});

			ModchartManager.defaultRedirects.set("stealthglowred" + i, {toClass: Stealth, index: GLOW_RED_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("stealthglowgreen" + i, {toClass: Stealth, index: GLOW_GREEN_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("stealthglowblue" + i, {toClass: Stealth, index: GLOW_BLUE_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("stealthgr" + i, {toClass: Stealth, index: GLOW_RED_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("stealthgg" + i, {toClass: Stealth, index: GLOW_GREEN_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("stealthgb" + i, {toClass: Stealth, index: GLOW_BLUE_LANE_INDEX + i});
		}
		ModchartManager.defaultRedirects.set("stealthtype", {toClass: Stealth, index: STEALTH_TYPE_INDEX});
	}
}