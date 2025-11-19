package funkin.objects.ui;

class Border extends FlxSpriteGroup {
    public var titleSpeed:Float = 25;

    public var top:Bool;
    public var border:FunkinSprite;
    public var scrollTitle:FlxText;
    public var miniText:FunkinSprite;
    public var camelliaLogo:FunkinSprite;

    public var fill(default, set):Float = 0;
    public var scrollText(get, set):String;

    static var curTransTwn:FlxTween;
    public function transitionTween(fromScene:Bool, ?startDelay:Float = 0.25, ?endDelay:Float = 0.25, ?finish:Void->Void) {
        if (curTransTwn != null)
            curTransTwn.cancel();

        var axis = top ? -1 : 1;
        var endScroll = FlxG.height * axis;
        if (fromScene) {
            FlxG.camera.scroll.y = endScroll;
            endScroll = 0;
            fill = FlxG.height;
        }
        
        var startScroll = FlxG.camera.scroll.y;
        curTransTwn = FlxTween.tween(FlxG.camera.scroll, {y: endScroll}, 0.75, {ease: (fromScene ? FlxEase.cubeOut : FlxEase.cubeIn), startDelay: startDelay, onUpdate: function(twn) {
            fill = top ? (-Math.min(FlxMath.lerp(startScroll, endScroll, twn.scale), 0) + y) : (Math.max(FlxMath.lerp(startScroll, endScroll, twn.scale), 0) - y);
        }, onComplete: function(twn) {
            curTransTwn = null;
            fill = (fromScene ? 0 : FlxG.height) - y * axis;

            if (finish == null) return;

            new FlxTimer().start(endDelay, function(tmr) {
                finish();
            });
        }});
    }

    public function new(top:Bool, ?scrollTxt:String, ?miniTextDir:String) {
        super();
        this.top = top;

        add(border = new FunkinSprite(0, 0, Paths.image("menus/border" + (top ? "Top" : ""))));
        border.scrollFactor.set(0, 1);
        if (!top)
            border.y = FlxG.height - border.height;

        if (top) {
            add(scrollTitle = new FlxText(0, 0, 0, scrollTxt));
            scrollTitle.setFormat(Paths.font("LineSeed.ttf"), 32, 0xFFFFFFFF, RIGHT);
            scrollTitle.updateHitbox();
            scrollTitle.clipGraphic(0, 0, FlxG.width, scrollTitle.frameHeight);
            scrollTitle.wrapMode = REPEAT;
            scrollTitle.scrollFactor.set(0, 1);
            scrollTitle.alpha = 0.05;

            add(miniText = new FunkinSprite(border.x + 300, border.y + 55, Paths.image('menus/$miniTextDir/text')));
            miniText.setGraphicSize(0, 26);
            miniText.updateHitbox();
            miniText.x -= miniText.width;
            miniText.scrollFactor.set(0, 1);
        } else {
            add(camelliaLogo = new FunkinSprite(border.x + border.width - 35, border.y + border.height * 0.5, Paths.image('menus/camelliaLogo')));
            camelliaLogo.scale.set(0.5, 0.5);
            camelliaLogo.updateHitbox();
            camelliaLogo.scrollFactor.set(0, 1);
            camelliaLogo.x -= camelliaLogo.width;
            camelliaLogo.y -= camelliaLogo.height * 0.5;
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        if (scrollTitle != null)
            @:privateAccess scrollTitle._frame.frame.x -= elapsed * titleSpeed;
    }

    function set_fill(value:Float) {
        final offsetY = top ? -value : 0;
        border.clipGraphic(0, offsetY, border.graphic.width, border.graphic.height + value);
        border.offset.y = (-0.5 * (border.height - border.graphic.height)) - offsetY;
        return fill = value;
    }

    function get_scrollText() {
        return (scrollTitle != null) ? scrollTitle.text : "";
    }

    function set_scrollText(value:String) {
        @:privateAccess if (scrollTitle != null) {
            final oldX = scrollTitle._frame.frame.x;
            scrollTitle.text = value;
            scrollTitle.updateHitbox();
            scrollTitle.clipGraphic(oldX, 0, FlxG.width, scrollTitle.frameHeight);
        }
        return value;
    }
}