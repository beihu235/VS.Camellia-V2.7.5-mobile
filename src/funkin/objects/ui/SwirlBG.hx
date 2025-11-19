package funkin.objects.ui;

import funkin.shaders.SwirlBGShader;
import flixel.util.FlxColor;

class SwirlBG extends FunkinSprite {
    public static var time:Float = 0.0;

    static var lastCol:Array<Array<Float>> = [[0.5, 0.5, 0.5], [0.35, 0.35, 0.35]];
    static var lastSpeed:Float = 1.0;
    
    var internalTargetCol:Array<Array<Float>> = [null, null];
    var bgShader:SwirlBGShader;
    public var speed:Float = 1.0;
    public var targetColor1(default, set):FlxColor;
    public var targetColor2(default, set):FlxColor;

    public function new(?target1:FlxColor, ?target2:FlxColor) {
        super(0, 0, Paths.image("menus/fluid"));
        screenCenter();
        active = true;

        bgShader = new SwirlBGShader();
        bgShader.redCol.value = lastCol[0];
        bgShader.greenCol.value = lastCol[1];
        bgShader.iTime.value = [time];
        shader = bgShader;

        speed = lastSpeed;
        targetColor1 = target1 ?? FlxColor.fromRGBFloat(lastCol[0][0], lastCol[0][1], lastCol[0][2]);
        targetColor2 = target2 ?? FlxColor.fromRGBFloat(lastCol[1][0], lastCol[1][1], lastCol[1][2]);
    }

    override function update(elapsed:Float) {
        time += elapsed * speed;
        bgShader.iTime.value[0] = time;

        for (i in 0...3) {
            bgShader.redCol.value[i] = FlxMath.lerp(bgShader.redCol.value[i], internalTargetCol[0][i], elapsed * 15);
            bgShader.greenCol.value[i] = FlxMath.lerp(bgShader.greenCol.value[i], internalTargetCol[1][i], elapsed * 15);
        }
    }

    override function destroy() {
        lastCol = [bgShader.redCol.value, bgShader.greenCol.value];
        lastSpeed = speed;
        super.destroy();
    }

    function set_targetColor1(to:FlxColor) {
        internalTargetCol[0] = [to.redFloat, to.greenFloat, to.blueFloat];
        return targetColor1 = to;
    }

    function set_targetColor2(to:FlxColor) {
        internalTargetCol[1] = [to.redFloat, to.greenFloat, to.blueFloat];
        return targetColor2 = to;
    }
}