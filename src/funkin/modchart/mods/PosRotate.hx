package funkin.modchart.mods;

class PosRotate extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 5;
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        pos.x -= field.centerX;
        pos.y -= FlxG.height * 0.5;

        final localX = getValue(LOCAL_X_INDEX, strumline) + getValue(LOCAL_X_LANE_INDEX + lane, strumline);
        final localY = getValue(LOCAL_Y_INDEX, strumline) + getValue(LOCAL_Y_LANE_INDEX + lane, strumline);
        final localZ = getValue(LOCAL_Z_INDEX, strumline) + getValue(LOCAL_Z_LANE_INDEX + lane, strumline);
        if (localX != 0.0 || localY != 0.0 || localZ != 0.0)
            pos.rotate(localX, localY, localZ);

        final strumPos = Strumline.swagWidth * (lane - 1.5);
        pos.x -= strumPos; // technically pos.x -= (centerX + strumPos) but we already offset centerX
        // no need to offset height again.

        final normX = getValue(X_INDEX, strumline) + getValue(X_LANE_INDEX + lane, strumline);
        final normY = getValue(Y_INDEX, strumline) + getValue(Y_LANE_INDEX + lane, strumline);
        final normZ = getValue(Z_INDEX, strumline) + getValue(Z_LANE_INDEX + lane, strumline);
        if (normX != 0.0 || normY != 0.0 || normZ != 0.0)
            pos.rotate(normX, normY, normZ);

        pos.x += field.centerX + strumPos;
        pos.y += FlxG.height * 0.5;
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(LOCAL_Z_LANE_INDEX + 4)) 0.0]);
    }

    public static inline var X_INDEX:Int = 0;
    public static inline var Y_INDEX:Int = 1;
    public static inline var Z_INDEX:Int = 2;

    public static inline var LOCAL_X_INDEX:Int = 3;
    public static inline var LOCAL_Y_INDEX:Int = 4;
    public static inline var LOCAL_Z_INDEX:Int = 5;

    public static inline var X_LANE_INDEX:Int = 6;
    public static inline var Y_LANE_INDEX:Int = 10;
    public static inline var Z_LANE_INDEX:Int = 14;

    public static inline var LOCAL_X_LANE_INDEX:Int = 18;
    public static inline var LOCAL_Y_LANE_INDEX:Int = 22;
    public static inline var LOCAL_Z_LANE_INDEX:Int = 26;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("rotatex", {toClass: PosRotate, index: X_INDEX});
        ModchartManager.defaultRedirects.set("rotatey", {toClass: PosRotate, index: Y_INDEX});
        ModchartManager.defaultRedirects.set("rotatez", {toClass: PosRotate, index: Z_INDEX});

        ModchartManager.defaultRedirects.set("localrotatex", {toClass: PosRotate, index: LOCAL_X_INDEX});
        ModchartManager.defaultRedirects.set("localrotatey", {toClass: PosRotate, index: LOCAL_Y_INDEX});
        ModchartManager.defaultRedirects.set("localrotatez", {toClass: PosRotate, index: LOCAL_Z_INDEX});

        for (i in 0...4) {
            ModchartManager.defaultRedirects.set("rotatex" + i, {toClass: PosRotate, index: X_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("rotatey" + i, {toClass: PosRotate, index: Y_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("rotatez" + i, {toClass: PosRotate, index: Z_LANE_INDEX + i});
    
            ModchartManager.defaultRedirects.set("localrotatex" + i, {toClass: PosRotate, index: LOCAL_X_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("localrotatey" + i, {toClass: PosRotate, index: LOCAL_Y_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("localrotatez" + i, {toClass: PosRotate, index: LOCAL_Z_LANE_INDEX + i});
        }
    }
}