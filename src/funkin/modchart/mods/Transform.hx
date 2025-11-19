package funkin.modchart.mods;

class Transform extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 0;
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        pos.x += (getValue(MOVE_X_INDEX, strumline) + getValue(MOVE_X_LANE_INDEX + lane, strumline)) * Strumline.swagWidth;
        pos.y += (getValue(MOVE_Y_INDEX, strumline) + getValue(MOVE_Y_LANE_INDEX + lane, strumline)) * Strumline.swagWidth * FlxMath.lerp(1, parent.scrollMult, getValue(MOVE_Y_TYPE_INDEX, strumline));
        pos.z += (getValue(MOVE_Z_INDEX, strumline) + getValue(MOVE_Z_LANE_INDEX + lane, strumline)) * Strumline.swagWidth;
		if(type == STRUM){
			pos.x += (getValue(MOVE_RECEPTOR_X_INDEX, strumline) + getValue(MOVE_RECEPTOR_X_LANE_INDEX + lane, strumline)) * Strumline.swagWidth;
			pos.y += (getValue(MOVE_RECEPTOR_Y_INDEX, strumline) + getValue(MOVE_RECEPTOR_Y_LANE_INDEX + lane, strumline)) * Strumline.swagWidth;
			pos.z += (getValue(MOVE_RECEPTOR_Z_INDEX, strumline) + getValue(MOVE_RECEPTOR_Z_LANE_INDEX + lane, strumline)) * Strumline.swagWidth;
		}
	}

    override public function modifiesScale(strumline:Int) {return true;}
    override public function adjustScale(spr:FunkinSprite, scale:FlxPoint, distance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        var mainScale = getValue(SCALE_INDEX, strumline) * getValue(SCALE_LANE_INDEX + lane, strumline);
        mainScale *= Math.pow(0.5, getValue(TINY_INDEX, strumline) + getValue(TINY_LANE_INDEX + lane, strumline));

        final stretch = getValue(STRETCH_INDEX, strumline) + getValue(STRETCH_LANE_INDEX + lane, strumline);
        final squish = getValue(SQUISH_INDEX, strumline) + getValue(SQUISH_LANE_INDEX + lane, strumline);

        var scaleX = mainScale * getValue(SCALE_X_INDEX, strumline) * getValue(SCALE_X_LANE_INDEX + lane, strumline);
        scaleX *= Math.pow(0.5, getValue(TINY_X_INDEX, strumline) + getValue(TINY_X_LANE_INDEX + lane, strumline));
        scaleX *= FlxMath.lerp(1, 0.5, stretch);
        scaleX *= FlxMath.lerp(1, 2, squish);

        var scaleY = mainScale * getValue(SCALE_Y_INDEX, strumline) * getValue(SCALE_Y_LANE_INDEX + lane, strumline);
        scaleY *= Math.pow(0.5, getValue(TINY_Y_INDEX, strumline) + getValue(TINY_Y_LANE_INDEX + lane, strumline));
        scaleY *= FlxMath.lerp(1, 2, stretch);
        scaleY *= FlxMath.lerp(1, 0.5, squish);

        scale.x *= scaleX;
        scale.y *= scaleY;
    }


    override function isActive(vals:Array<Float>) {
        for (i => num in vals) {
            final check = ((i >= SCALE_INDEX && i < SCALE_Y_INDEX + 1) || (i >= SCALE_LANE_INDEX && i < SCALE_Y_LANE_INDEX + 4)) ? 1.0 : 0.0;
            if (num != check)
                return true;
        }
        return false;
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        final newValSet = [for (i in 0...(MOVE_Y_TYPE_INDEX + 1)) 0.0];
        for (i in SCALE_INDEX...(SCALE_Y_INDEX + 1))
            newValSet[i] = 1.0;
        for (i in SCALE_LANE_INDEX...(SCALE_Y_LANE_INDEX + 4))
            newValSet[i] = 1.0;
        values.push(newValSet);
    }

    public static inline var MOVE_X_INDEX:Int = 0;
    public static inline var MOVE_Y_INDEX:Int = 1;
    public static inline var MOVE_Z_INDEX:Int = 2;

    public static inline var SCALE_INDEX:Int = 3;
    public static inline var SCALE_X_INDEX:Int = 4;
    public static inline var SCALE_Y_INDEX:Int = 5;

    public static inline var SQUISH_INDEX:Int = 6;
    public static inline var STRETCH_INDEX:Int = 7;

    public static inline var TINY_INDEX:Int = 8;
    public static inline var TINY_X_INDEX:Int = 9;
    public static inline var TINY_Y_INDEX:Int = 10;

    public static inline var MOVE_X_LANE_INDEX:Int = 11;
    public static inline var MOVE_Y_LANE_INDEX:Int = 15;
    public static inline var MOVE_Z_LANE_INDEX:Int = 19;

    public static inline var SCALE_LANE_INDEX:Int = 23;
    public static inline var SCALE_X_LANE_INDEX:Int = 27;
    public static inline var SCALE_Y_LANE_INDEX:Int = 31;

    public static inline var SQUISH_LANE_INDEX:Int = 35;
    public static inline var STRETCH_LANE_INDEX:Int = 39;

    public static inline var TINY_LANE_INDEX:Int = 43;
    public static inline var TINY_X_LANE_INDEX:Int = 47;
    public static inline var TINY_Y_LANE_INDEX:Int = 51;

    public static inline var MOVE_Y_TYPE_INDEX:Int = 55;

    public static inline var MOVE_RECEPTOR_X_INDEX:Int = 56;
    public static inline var MOVE_RECEPTOR_Y_INDEX:Int = 57;
    public static inline var MOVE_RECEPTOR_Z_INDEX:Int = 58;

    public static inline var MOVE_RECEPTOR_X_LANE_INDEX:Int = 59;
    public static inline var MOVE_RECEPTOR_Y_LANE_INDEX:Int = 63;
    public static inline var MOVE_RECEPTOR_Z_LANE_INDEX:Int = 67;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("movex", {toClass: Transform, index: MOVE_X_INDEX});
        ModchartManager.defaultRedirects.set("movey", {toClass: Transform, index: MOVE_Y_INDEX});
        ModchartManager.defaultRedirects.set("movez", {toClass: Transform, index: MOVE_Z_INDEX});

        ModchartManager.defaultRedirects.set("scale", {toClass: Transform, index: SCALE_INDEX});
        ModchartManager.defaultRedirects.set("scalex", {toClass: Transform, index: SCALE_X_INDEX});
        ModchartManager.defaultRedirects.set("scaley", {toClass: Transform, index: SCALE_Y_INDEX});

        ModchartManager.defaultRedirects.set("squish", {toClass: Transform, index: SQUISH_INDEX});
        ModchartManager.defaultRedirects.set("stretch", {toClass: Transform, index: STRETCH_INDEX});

        ModchartManager.defaultRedirects.set("tiny", {toClass: Transform, index: TINY_INDEX});
        ModchartManager.defaultRedirects.set("tinyx", {toClass: Transform, index: TINY_X_INDEX});
        ModchartManager.defaultRedirects.set("tinyy", {toClass: Transform, index: TINY_Y_INDEX});

        for (i in 0...4) {
            ModchartManager.defaultRedirects.set("movex" + i, {toClass: Transform, index: MOVE_X_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("movey" + i, {toClass: Transform, index: MOVE_Y_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("movez" + i, {toClass: Transform, index: MOVE_Z_LANE_INDEX + i});
    
            ModchartManager.defaultRedirects.set("scale" + i, {toClass: Transform, index: SCALE_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("scalex" + i, {toClass: Transform, index: SCALE_X_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("scaley" + i, {toClass: Transform, index: SCALE_Y_LANE_INDEX + i});
    
            ModchartManager.defaultRedirects.set("squish" + i, {toClass: Transform, index: SQUISH_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("stretch" + i, {toClass: Transform, index: STRETCH_LANE_INDEX + i});

            ModchartManager.defaultRedirects.set("tiny" + i, {toClass: Transform, index: TINY_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("tinyx" + i, {toClass: Transform, index: TINY_X_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("tinyy" + i, {toClass: Transform, index: TINY_Y_LANE_INDEX + i});

			
			ModchartManager.defaultRedirects.set("movereceptorx" + i, {toClass: Transform, index: MOVE_RECEPTOR_X_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("movereceptory" + i, {toClass: Transform, index: MOVE_RECEPTOR_Y_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("movereceptorz" + i, {toClass: Transform, index: MOVE_RECEPTOR_Z_LANE_INDEX + i});

			ModchartManager.defaultRedirects.set("moverx" + i, {toClass: Transform, index: MOVE_RECEPTOR_X_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("movery" + i, {toClass: Transform, index: MOVE_RECEPTOR_Y_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("moverz" + i, {toClass: Transform, index: MOVE_RECEPTOR_Z_LANE_INDEX + i});
        }

        ModchartManager.defaultRedirects.set("moveytype", {toClass: Transform, index: MOVE_Y_TYPE_INDEX});
		
        ModchartManager.defaultRedirects.set("movereceptorx", {toClass: Transform, index: MOVE_RECEPTOR_X_INDEX});
        ModchartManager.defaultRedirects.set("movereceptory", {toClass: Transform, index: MOVE_RECEPTOR_Y_INDEX});
        ModchartManager.defaultRedirects.set("movereceptorz", {toClass: Transform, index: MOVE_RECEPTOR_Z_INDEX});

        ModchartManager.defaultRedirects.set("moverx", {toClass: Transform, index: MOVE_RECEPTOR_X_INDEX});
        ModchartManager.defaultRedirects.set("movery", {toClass: Transform, index: MOVE_RECEPTOR_Y_INDEX});
        ModchartManager.defaultRedirects.set("moverz", {toClass: Transform, index: MOVE_RECEPTOR_Z_INDEX});
		
    }
}