package funkin.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class DiagonalAlphaMask extends FlxGraphicsShader {
	@:glFragmentSource("#pragma header

	uniform float time;

	void main() {
		float lightUV = openfl_TextureCoordv.x + openfl_TextureCoordv.y - time;
		float light = (1.0 - abs(mod(lightUV, 2.0) - 1.0)) * floor(mod(lightUV, 4.0) * 0.5);
		gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv) * (light * 2.0);
	}")

	public function new() {
		super();

		time.value = [0];
	}
}