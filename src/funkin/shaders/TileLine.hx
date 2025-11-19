package funkin.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class TileLine extends FlxGraphicsShader {
    @:glFragmentSource("#pragma header
    
    uniform vec4 color1;
    uniform vec4 color2;
    uniform float time;
    uniform float yScale;
    uniform float density;

    void main() {
        // c  o  m  p  r  e  s  s  i  o  n
        float tilePos = ((openfl_TextureCoordv.x + openfl_TextureCoordv.y * (openfl_TextureSize.y / openfl_TextureSize.x) * yScale) + time) * density;
        vec4 lineCol = mix(color1, color2, smoothstep(0.95, 1.05, mod(tilePos, 2.0)));
        gl_FragColor = texture2D(bitmap, openfl_TextureCoordv) * openfl_Alphav * lineCol;
        gl_FragColor.rgb *= lineCol.a; // flixel i hate you
    }")

    public function new() {
        super();
        color1.value = [1.0, 1.0, 1.0, 1.0];
        color2.value = [0.0, 0.0, 0.0, 1.0];
        yScale.value = [0.7];
        time.value = [0.0];
        density.value = [80.0];
    }
}