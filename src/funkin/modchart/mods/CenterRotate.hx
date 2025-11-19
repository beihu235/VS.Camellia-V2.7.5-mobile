package funkin.modchart.mods;

class CenterRotate extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 15;
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        pos.x -= FlxG.width * 0.5;
        pos.y -= FlxG.height * 0.5;

        final centerX = getValue(CENTER_X_INDEX, strumline) + getValue(CENTER_X_LANE_INDEX + lane, strumline);
        final centerY = getValue(CENTER_Y_INDEX, strumline) + getValue(CENTER_Y_LANE_INDEX + lane, strumline);
        final centerZ = getValue(CENTER_Z_INDEX, strumline) + getValue(CENTER_Z_LANE_INDEX + lane, strumline);

        pos.rotate(centerX, centerY, centerZ);

        pos.x += FlxG.width * 0.5;
        pos.y += FlxG.height * 0.5;
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(CENTER_Z_LANE_INDEX + 4)) 0.0]);
    }

    public static inline var CENTER_X_INDEX:Int = 0;
    public static inline var CENTER_Y_INDEX:Int = 1;
    public static inline var CENTER_Z_INDEX:Int = 2;

    public static inline var CENTER_X_LANE_INDEX:Int = 3;
    public static inline var CENTER_Y_LANE_INDEX:Int = 7;
    public static inline var CENTER_Z_LANE_INDEX:Int = 11;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("centerrotatex", {toClass: CenterRotate, index: CENTER_X_INDEX});
        ModchartManager.defaultRedirects.set("centerrotatey", {toClass: CenterRotate, index: CENTER_Y_INDEX});
        ModchartManager.defaultRedirects.set("centerrotatez", {toClass: CenterRotate, index: CENTER_Z_INDEX});

        for (i in 0...4) {
            ModchartManager.defaultRedirects.set("centerrotatex" + i, {toClass: CenterRotate, index: CENTER_X_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("centerrotatey" + i, {toClass: CenterRotate, index: CENTER_Y_LANE_INDEX + i});
            ModchartManager.defaultRedirects.set("centerrotatez" + i, {toClass: CenterRotate, index: CENTER_Z_LANE_INDEX + i});
        }
    }
}