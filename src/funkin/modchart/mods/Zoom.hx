package funkin.modchart.mods;

class Zoom extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 6;
    }

    override public function modifiesPosition(strumline:Int) {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        pos.x -= field.centerX;
        pos.y -= FlxG.height * 0.5;

        final zoom = getValue(ZOOM_INDEX, strumline) - getValue(MINI_INDEX, strumline) * 0.5;
        pos.x *= zoom * getValue(ZOOM_X_INDEX, strumline);
        pos.y *= zoom * getValue(ZOOM_Y_INDEX, strumline);

        pos.x += field.centerX;
        pos.y += FlxG.height * 0.5;
    }

    override public function modifiesScale(strumline:Int) {return true;}
    override public function adjustScale(spr:FunkinSprite, scale:FlxPoint, distance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        final zoom = getValue(ZOOM_INDEX, strumline) - getValue(MINI_INDEX, strumline) * 0.5;
        scale.x *= zoom * getValue(ZOOM_X_INDEX, strumline);
        scale.y *= zoom * getValue(ZOOM_Y_INDEX, strumline);
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        final newValSet = [for (i in 0...(MINI_INDEX + 1)) 1.0];
        newValSet[MINI_INDEX] = 0.0;
        values.push(newValSet);
    }

    override function isActive(vals:Array<Float>) {
        for (i => num in vals) {
            final check = (i % 4 == 3) ? 0.0 : 1.0;
            if (num != check)
                return true;
        }
        return false;
    }

    public static inline var ZOOM_INDEX:Int = 0;
    public static inline var ZOOM_X_INDEX:Int = 1;
    public static inline var ZOOM_Y_INDEX:Int = 2;
    public static inline var MINI_INDEX:Int = 3;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("zoom", {toClass: Zoom, index: ZOOM_INDEX});
        ModchartManager.defaultRedirects.set("zoomx", {toClass: Zoom, index: ZOOM_X_INDEX});
        ModchartManager.defaultRedirects.set("zoomy", {toClass: Zoom, index: ZOOM_Y_INDEX});
        ModchartManager.defaultRedirects.set("mini", {toClass: Zoom, index: MINI_INDEX});
    }
}