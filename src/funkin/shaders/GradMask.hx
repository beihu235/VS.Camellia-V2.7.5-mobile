package funkin.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class GradMask extends FlxGraphicsShader {
    @:glFragmentSource("#pragma header

    uniform vec4 fromCol;
    uniform vec4 toCol;

    uniform float from;
    uniform float to;

    void main() {
        vec4 mixCol = mix(fromCol, toCol, smoothstep(from, to, openfl_TextureCoordv.x));
        float alpha = mixCol.a * openfl_Alphav;
        mixCol.a = 1.0;
        gl_FragColor = texture2D(bitmap, openfl_TextureCoordv) * mixCol * alpha;
    }")

    public function new() {
        super();

        from.value = [0];
        to.value = [1];
        fromCol.value = [1, 1, 1, 0];
        toCol.value = [1, 1, 1, 1];
    }
}