package funkin.modchart.mods;

// Maybe we can do Reverse seperate from a modifier??
// Reason being, for us to be accurate to ITG some modifiers need to have access to the y distance with reverse already factored in
// So it might be good for us to do reverse seperately so we can have access to how that affects the position and pass that into functions
// :shrug: who cares rn lmao we dont need to be 1000% accurate we just need to *look* accurate enough


class Reverse extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = -5;
    }

    public function getReverse(lane:Int, strumline:Int) {
        var reverse = getValue(REVERSE_INDEX, strumline) + getValue(REVERSE_LANE_INDEX + lane, strumline);

        if (lane >= 2)
			reverse += getValue(SPLIT_INDEX, strumline);
		if (lane % 2 == 1)
			reverse += getValue(ALTERNATE_INDEX, strumline);
        if (lane >= 1 && lane <= 2)
            reverse += getValue(CROSS_INDEX, strumline);

        return reverse;
    }

    override public function modifiesPosition(strumline:Int):Bool {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        final reverseMult = 1 - getReverse(lane, strumline) * 2;
        final centeredMult = getValue(CENTERED_INDEX, strumline);
        var curY = pos.y - FlxG.height * 0.5;

        curY *= reverseMult;
        curY *= 1 - centeredMult;

        parent.scrollMult *= reverseMult;
        curY += (distance * parent.scrollMult) * centeredMult;

        pos.y = curY + FlxG.height * 0.5;
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(REVERSE_LANE_INDEX + 4)) 0.0]);
    }

    public static inline var REVERSE_INDEX:Int = 0;
    public static inline var CROSS_INDEX:Int = 1;
    public static inline var SPLIT_INDEX:Int = 2;
    public static inline var ALTERNATE_INDEX:Int = 3;
    public static inline var CENTERED_INDEX:Int = 4;
    public static inline var REVERSE_LANE_INDEX:Int = 5;
    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("reverse", {toClass: Reverse, index: REVERSE_INDEX});
        ModchartManager.defaultRedirects.set("cross", {toClass: Reverse, index: CROSS_INDEX});
        ModchartManager.defaultRedirects.set("split", {toClass: Reverse, index: SPLIT_INDEX});
        ModchartManager.defaultRedirects.set("alternate", {toClass: Reverse, index: ALTERNATE_INDEX});
        ModchartManager.defaultRedirects.set("centered", {toClass: Reverse, index: CENTERED_INDEX});
        for (i in 0...4)
            ModchartManager.defaultRedirects.set("reverse" + i, {toClass: Reverse, index: REVERSE_LANE_INDEX + i});
    }
}