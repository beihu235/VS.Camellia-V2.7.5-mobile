package funkin.modchart;

import funkin.modchart.ModchartManager;

class AuxModifier extends funkin.modchart.BaseModifier {
    public var defaultValue:Float;

    public function new(parent:ModchartManager, defaultValue:Float) {
        priority = 0;

        this.defaultValue = defaultValue;
        super(parent);
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        values.push([defaultValue]);
    }

    override function isActive(vals:Array<Float>) {
        return vals[0] != defaultValue;
    }
}