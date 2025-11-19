package funkin.shaders;

import openfl.display.BitmapData;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxColor;

class GraphGradient extends FlxGraphicsShader {
    @:glFragmentSource("#pragma header
    
    uniform sampler2D graphData;
    uniform float uvScale;
    uniform float progress;

    void main() {
        vec2 uv = openfl_TextureCoordv;
        uv.y = 1.0 - uv.y;
        uv.x = (uv.x - 0.5) * uvScale + 0.5;
        
        float belowStep = step(uv.y - texture2D(graphData, uv).b * progress, 0.0);
        gl_FragColor = vec4(0.75 * uv.y * belowStep * openfl_Alphav);
    }")

    var daData:BitmapData;
    
    public function new() {
        super();

        progress.value = [0];
        setPoints([0.25, 0.5, 0.75]);
    }

    public function setPoints(points:Array<Float>) {
        if (daData != null)
            daData.dispose();

        if (daData == null || points.length != daData.width)
            daData = new BitmapData(points.length, 1, false, 0xFF000000);
        for (i in 0...points.length)
            daData.setPixel(i, 0, FlxColor.fromRGBFloat(0.0, 0.0, points[i], 1.0)); // i like blue

        graphData.input = daData;
        graphData.wrap = CLAMP;
        graphData.filter = LINEAR;

        uvScale.value = [1.0 - (1.0 / points.length)];
    }

    public function destroy() {
        if (daData != null)
            daData.dispose();
    }
}