package funkin.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class SongSlotShader extends FlxGraphicsShader {
    @:glFragmentSource("#pragma header

    // only one uniform, the red stepping will come from colorTransform.alphaOffset to allow batching.
    uniform vec4 color;

    const vec4 white = vec4(1.0);

    void main() {
        vec4 texel = texture2D(bitmap, openfl_TextureCoordv);
        gl_FragColor = mix(color, white, smoothstep(0.95, 1.0, texel.r)) * (1.0 - step(texel.r, openfl_ColorOffsetv.a)) * openfl_Alphav * texel.a;
    }")

    public function new() {
        super();
        color.value = [0.5, 0.5, 0.5, 1.0];
    }
}