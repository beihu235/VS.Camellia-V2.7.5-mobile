package funkin.objects;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxSignal;

class Countdown extends FunkinSprite {
	//just to prevent overlapping if more scripts want to use the callbacks
	public var onStartHandlers:Array<Void->Void> = [];
	public var onTickHandlers:Array<Int->Void> = [];
	public var onFinishHandlers:Array<Void->Void> = [];

	public dynamic function onStart():Void {
		for(handler in onStartHandlers){
			handler();
		}
	}
	public dynamic function onTick(tick:Int):Void {
		switch (tick) {
			case 4: 
				FlxG.sound.play(Paths.audio('metronome', 'sfx'));
				animation.frameIndex = 0;
			case 3: 
				FlxG.sound.play(Paths.audio('metronome', 'sfx'));
				animation.frameIndex = 1;
			case 2: 
				FlxG.sound.play(Paths.audio('metronome', 'sfx'));
				animation.frameIndex = 2;
			case 1: 
				FlxG.sound.play(Paths.audio('menu_confirm', 'sfx'));
				animation.frameIndex = 3;
		}
		for(handler in onTickHandlers){
			handler(tick);
		}
	}
	public dynamic function onFinish():Void {
		for(handler in onFinishHandlers){
			handler();
		}
	}

	public var ticks:Int = 4;
	public var finished:Bool = true;

	public function new(?x:Float, ?y:Float) {
		super(x, y);
		final graphic:FlxGraphic = Paths.image('ui/countdown');
		loadGraphic(graphic, true, graphic.width, Std.int(graphic.height * (1 / ticks)));

		animation.frameIndex = -1; // ????

		alpha = 0;
		active = false;
		_lastTick = ticks + 1;
	}

	public function start():Void {
		finished = false;
		active = true;
		_time = (Conductor.crotchet * -(ticks + 1));
		onStart();
	}

	var _lastTick:Int;
	var _time:Float;
	override function update(elapsed:Float):Void {
		if (finished) return;
		alpha -= elapsed / (Conductor.crotchet * 0.001);

		_time += (elapsed * 1000);

		var nextTick:Int = Math.floor(_time / Conductor.calculateCrotchet(Conductor.bpm)) * -1;
		if (nextTick < _lastTick) {
			beat(nextTick);
			_lastTick = nextTick;
		}
	}

	public function beat(curTick:Int) {
		if (curTick > ticks) return;

		onTick(curTick);
		alpha = 1;

		if (curTick <= 0) stop();
	}

	public function stop():Void {
		finished = true;
		active = false;
		alpha = 0;
		onFinish();
	}
}