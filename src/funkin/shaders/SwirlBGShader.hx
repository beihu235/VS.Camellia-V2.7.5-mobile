package funkin.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class SwirlBGShader extends FlxGraphicsShader {
	@:glFragmentSource("#pragma header

	uniform float iTime;
	uniform vec3 redCol;
	uniform vec3 greenCol;

	const mat2 uvShift = mat2(6.0, -8.0, 8.0, 6.0) / 8.0;

	// https://www.shadertoy.com/view/lXXXzS 'Cheap Turbulence' by @XorDev

	void main() {
		vec2 uv = openfl_TextureCoordv * 6.0;

		//8 wave passes
		for (float i = 0.0; i < 8.0; i++) {
			//Add a simple sine wave with an offset and animation
			uv.x += sin(uv.y + i + iTime * 0.3);
			//Rotate and scale down
			uv *= uvShift;
		}
		
		// no need for flixel_, we're not using .color
		gl_FragColor = texture2D(bitmap, fract(uv * 0.02));

		gl_FragColor.rgb = mix(mix(redCol * pow(gl_FragColor.r, 0.75), greenCol, pow(gl_FragColor.g, 0.75)), vec3(1.0), gl_FragColor.b);
		gl_FragColor *= openfl_Alphav;
	}")

	public function new() {
		super();

		iTime.value = [0.0];
		redCol.value = [0.35, 0.35, 0.35];
		greenCol.value = [0.65, 0.65, 0.65];
	}
}