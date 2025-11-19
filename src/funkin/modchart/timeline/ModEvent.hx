package funkin.modchart.timeline;

import funkin.modchart.BaseModifier;
import funkin.modchart.ModchartManager.ModRedirect;
import funkin.modchart.timeline.BaseEvent;

class ModEvent extends BaseEvent {
	public var length:Float;
	public var ease:Float->Float;

	public var mod:BaseModifier;
	public var index:Int = 0;
	public var startValue:Float = Math.NaN;
	public var endValue:Float;
	public var strumline:Int = -1;

	public function new(beat:Float, length:Float, redirect:ModRedirect, value:Float, ?ease:Float->Float, ?strumline:Int = -1, ?startVal: Float) {
		this.instant = false;

		this.beat = beat;
		this.length = length;
		this.ease = ease != null ? ease : FlxEase.linear;
		
		this.mod = redirect.toInstance;
		this.endValue = value;
		this.index = redirect.index;
		this.strumline = strumline;
		this.startValue = startVal ?? Math.NaN;
	}

	override function start() {
		if(Math.isNaN(startValue))
			this.startValue = mod.getValue(index, strumline < 0 ? 0 : strumline);
		
		if (length <= 0)
			mod.setValue(index, endValue, strumline);
	}

	override function tick(curBeat:Float) {
		if (length <= 0){
			mod.setValue(index, endValue, strumline);
		}else{
			var percent: Float = Math.min((curBeat - beat) / length, 1);
			percent = ease(percent);

			mod.setValue(index, FlxMath.lerp(startValue, endValue, percent), strumline);
		}
	}

	override function canFinish(curBeat:Float) {
		return length <= 0 || curBeat - beat >= length;
	}
}