package funkin.shaders;

import flixel.system.FlxAssets.FlxShader;

class RadialBlur extends FlxShader{
    @glFragmentSource('
#pragma header
//https://github.com/bbpanzu/FNF-Sunday/blob/main/source_sunday/RadialBlur.hx
//https://www.shadertoy.com/view/XsfSDs
uniform float cx; //center x (0.0 - 1.0)
uniform float cy; //center y (0.0 - 1.0)
uniform float blurWidth; // blurAmount

const int nsamples = 30; //samples

void main(){
	vec4 color = texture2D(bitmap, openfl_TextureCoordv);
	vec2 res = openfl_TextureCoordv;
	vec2 pp = vec2(cx, cy);
	vec2 center = pp;
	float blurStart = 1.0;

	vec2 uv = openfl_TextureCoordv.xy;

	uv -= center;
	float precompute = blurWidth * (1.0 / float(nsamples - 1));

	for(int i = 0; i < nsamples; i++)
	{
		float scale = blurStart + (float(i)* precompute);
		color += texture2D(bitmap, uv * scale + center);
	}

	color /= float(nsamples);

	gl_FragColor = color;

}')
    public function new() {
        super();

		this.cx.value = [0.5];
		this.cy.value = [0.5];
		this.blurWidth.value = [0.5];
    }

    //to use it you need to do this
    //var shader = new RadialBlur();
    //shader.cx = [0.5];
    //shader.cy = [0.5];
    //shader.blurWidth = [0.0];
    //to trigger that boom do this
    //shader.blurWidth = [0.5]; //or higher
    //and to get back to normal do this
    /*
    function update(elapsed:Float){
        shader.blurWidth = [CoolUtil.lerp(0, shader.blurWidth, 0.85)];
    }*/
}