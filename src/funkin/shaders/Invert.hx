package funkin.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class Invert extends FlxGraphicsShader {
    @:glFragmentSource("#pragma header

    uniform float percent;

    void main() {
        gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
        gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_FragColor.a - gl_FragColor.rgb, percent);
    }")

    public function new() {
        super();

        percent.value = [1];
    }
}