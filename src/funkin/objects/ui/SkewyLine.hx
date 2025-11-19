package funkin.objects.ui;

import flixel.math.FlxAngle;
import flixel.util.FlxDestroyUtil;

class SkewyLine extends FlxTypedSpriteGroup<FunkinSprite> {
    public var intensityX:Float = 3;
    public var intensityY:Float = 3;
    public var speed:Float = 1;
    var time:Float = 0;

    var points:Array<Float> = [];
    var squares:Array<FunkinSprite> = [];
    var lines:Array<FunkinSprite> = [];

    var minX:Float = 0;
    var minY:Float = 0;
    var wid:Float = 0;
    var hei:Float = 0;

    public function new(points:Array<Float>) {
        super();
        this.points = points;
        directAlpha = true;

        for (i in 0...Math.floor(points.length * 0.5)) {
            var sqr = new FunkinSprite(points[i * 2], points[i * 2 + 1]);
            sqr.makeGraphic(1, 1, 0xFFFFFFFF);
            sqr.scale.set(7, 7);
            sqr.offset.set(0.5, 0.5);
            add(sqr);
            squares.push(sqr);

            var line = new FunkinSprite(sqr.x, sqr.y);
            line.makeGraphic(1, 1, 0xFFFFFFFF);
            line.scale.set(0, 1);
            sqr.offset.set(0.0, 0.5);
            line.origin.x = 0;
            add(line);
            lines.push(line);
        }
        updateLines();

        minX = findMinX();
        minY = findMinY();
        wid = width;
        hei = height;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
    
        time += elapsed * speed;
        final skewX = Math.tan(Math.sin(time) * intensityX * FlxAngle.TO_RAD);
        final skewY = Math.tan(Math.cos(time) * intensityY * FlxAngle.TO_RAD);
        
        for (i => sqr in squares) {
            sqr.setPosition(x + points[i * 2], y + points[i * 2 + 1]);
            sqr.x += wid * ((sqr.y - (minY + hei * 0.5)) / hei) * skewX;
            sqr.x = (sqr.x - minX - wid * 0.5) * scale.x + minX + wid * 0.5 - offset.x;
            sqr.y += hei * ((sqr.x - (minX + wid * 0.5)) / wid) * skewY;
            sqr.y = (sqr.y - minY - hei * 0.5) * scale.y + minY + hei * 0.5 - offset.y;
        }
        updateLines();
    }

	override function initVars():Void {
        flixelType = SPRITEGROUP;

        offset = FlxPoint.get();
        origin = FlxPoint.get();
        scale = FlxPoint.get(1, 1);

        scrollFactor = new FlxCallbackPoint(scrollFactorCallback);
        scrollFactor.set(1, 1);

        initMotionVars();
    }

    override function destroy():Void {
        offset = FlxDestroyUtil.put(offset);
        origin = FlxDestroyUtil.put(origin);
        scale = FlxDestroyUtil.put(scale);

        super.destroy();
    }

    function updateLines() {
        for (i => line in lines) {
            final nextI = (i + 1) % lines.length;
            final distX = squares[nextI].x - squares[i].x;
            final distY = squares[nextI].y - squares[i].y;
            line.setPosition(squares[i].x, squares[i].y);
            line.scale.x = Math.sqrt(Math.pow(distX, 2) + Math.pow(distY, 2));
            line.angle = Math.atan2(distY, distX) * FlxAngle.TO_DEG;
        }
    }

    override function set_x(Value:Float):Float {
        minX += Value - x;
        return super.set_x(Value);
    }

    override function set_y(Value:Float):Float {
        minY += Value - y;
        return super.set_y(Value);
    }
}