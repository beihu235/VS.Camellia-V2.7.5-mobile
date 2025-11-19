package funkin.modchart.mods;

class OpponentSwap extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 10;
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        pos.x += ((FlxG.width - field.centerX) - field.centerX) * getValue(0, strumline);
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        values.push([0.0]);
    }

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("opponentswap", {toClass: OpponentSwap, index: 0});
    }
}