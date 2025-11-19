package funkin.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class HueGrad extends FlxGraphicsShader {
    @:glFragmentSource("#pragma header

    uniform float sat;
    uniform float brt;

    const vec4 hsvK = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 hsv2rgb(vec3 c)
    {
        vec3 p = abs(fract(c.xxx + hsvK.xyz) * 6.0 - hsvK.www);
        return c.z * mix(hsvK.xxx, clamp(p - hsvK.xxx, 0.0, 1.0), c.y);
    }

    void main() {
        gl_FragColor = vec4(hsv2rgb(vec3(openfl_TextureCoordv.x, sat, brt)), 1.0) * openfl_Alphav;
    }")

    public function new() {
        super();
        sat.value = [1.0];
        brt.value = [1.0];
    }
}