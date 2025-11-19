package funkin.states;

enum abstract BorderTransitionType(ByteUInt) from ByteUInt to ByteUInt {
    var BOTH = 0;
    var TOP = 1;
    var BOTTOM = 2;
}

class BasicBorderTransition extends FlxSubState {
    var borderTop:FunkinSprite;
    var borderBot:FunkinSprite;

    var time:Float = 0;
    var fromScene:Bool = false;
    var duration:Float = 0.35;
    var endDelay:Float = 1;
    var onEnd:Void->Void;

    public function new(type:BorderTransitionType, ?fromScene:Bool = false, ?duration:Float = 0.35, ?endDelay:Float = 1, ?onEnd:Void->Void) {
        super();

        if (type != BOTTOM) {
            borderTop = new FunkinSprite(0, 0, Paths.image("menus/borderTop"));
            if (fromScene)
                borderTop.clipGraphic(0, -FlxG.height, borderTop.graphic.width, borderTop.graphic.height + FlxG.height);
            else
                borderTop.visible = false;
            add(borderTop);
        }

        if (type != TOP) {
            borderBot = new FunkinSprite(0, FlxG.height, Paths.image("menus/border"));
            if (fromScene) {
                borderBot.clipGraphic(0, 0, borderBot.graphic.width, borderBot.graphic.height + FlxG.height);
                borderBot.y -= borderBot.frameHeight;
            } else
                borderBot.visible = false;
            add(borderBot);
        }

        this.fromScene = fromScene;
        this.duration = duration;
        this.endDelay = endDelay;
        this.onEnd = onEnd;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        final nextTime = time + (elapsed / FlxG.timeScale);
        if (time > duration) {
            time = nextTime;
            if (time >= duration + endDelay && onEnd != null) {
                onEnd();
                onEnd = null;
            } else if (time >= duration + endDelay && fromScene)
                (parent == null ? destroy : close)();
            return;
        }
        
        time = nextTime;
        final scale = FlxEase.quartOut(Math.min(time / duration, 1));
        
        if (borderTop != null) {
            final height = (FlxG.height + borderTop.graphic.height) * (fromScene ? 1 - scale : scale);
            borderTop.clipGraphic(0, borderTop.graphic.height - height, borderTop.graphic.width, height);
            borderTop.visible = borderTop.frameHeight > 3;
        }
        if (borderBot != null) {
            final height = (FlxG.height + borderBot.graphic.height) * (fromScene ? 1 - scale : scale);
            borderBot.clipGraphic(0, 0, borderBot.graphic.width, height);
            borderBot.visible = borderBot.frameHeight > 3;
            borderBot.y = FlxG.height - borderBot.frameHeight;
        }
    }
}