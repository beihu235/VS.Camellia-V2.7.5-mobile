package funkin.modchart.mods;

class CenterZoom extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 16;
    }

    override public function modifiesPosition(strumline:Int) {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        pos.x -= FlxG.width * 0.5;
        pos.y -= FlxG.height * 0.5;

        final centerZoom = getValue(CENTER_ZOOM_INDEX, strumline) - getValue(CENTER_MINI_INDEX, strumline) * 0.5;
        pos.x *= centerZoom * getValue(CENTER_ZOOM_X_INDEX, strumline);
        pos.y *= centerZoom * getValue(CENTER_ZOOM_Y_INDEX, strumline);

        pos.x += FlxG.width * 0.5;
        pos.y += FlxG.height * 0.5;
    }

    override public function modifiesScale(strumline:Int) {return true;}
    override public function adjustScale(spr:FunkinSprite, scale:FlxPoint, distance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        final centerZoom = getValue(CENTER_ZOOM_INDEX, strumline) - getValue(CENTER_MINI_INDEX, strumline) * 0.5;
        scale.x *= centerZoom * getValue(CENTER_ZOOM_X_INDEX, strumline);
        scale.y *= centerZoom * getValue(CENTER_ZOOM_Y_INDEX, strumline);
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        final newValSet = [for (i in 0...(CENTER_MINI_INDEX + 1)) 1.0];
        newValSet[CENTER_MINI_INDEX] = 0.0;
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

    public static inline var CENTER_ZOOM_INDEX:Int = 0;
    public static inline var CENTER_ZOOM_X_INDEX:Int = 1;
    public static inline var CENTER_ZOOM_Y_INDEX:Int = 2;
    public static inline var CENTER_MINI_INDEX:Int = 3;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("centerzoom", {toClass: CenterZoom, index: CENTER_ZOOM_INDEX});
        ModchartManager.defaultRedirects.set("centerzoomx", {toClass: CenterZoom, index: CENTER_ZOOM_X_INDEX});
        ModchartManager.defaultRedirects.set("centerzoomy", {toClass: CenterZoom, index: CENTER_ZOOM_Y_INDEX});
        ModchartManager.defaultRedirects.set("centermini", {toClass: CenterZoom, index: CENTER_MINI_INDEX});
    }
}