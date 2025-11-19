import funkin.objects.Character;
import funkin.backend.ScriptHandler;
import funkin.backend.Conductor;
import flixel.math.FlxMath;

var fade:FunkinSprite;
var camGlows = [];
var glows;

function create() {

    fade = new FunkinSprite().makeGraphic(1, 1, 0xFF000000);
	fade.scale.set(FlxG.width * 2, FlxG.height * 2);
    fade.cameras = [game.camHUD];
	fade.updateHitbox();
	fade.screenCenter();
    fade.alpha = 0;
	game.insert(0, fade);
    fade.scrollFactor.set();

    game.memberAdded.add(function(spr) {
    if (camGlows.length < 2 && spr.blend == 0) {
        camGlows.push(spr);
    spr.visible = false;
    }

    });

    game.dad.visible = false;

    easedFuncAt(3.6, 0.5, function(percent:Float, beat:Float){
        fade.alpha = FlxMath.lerp(0, 1, percent);
    });

    oneshotFuncAt(4.2, function(spr){
        game.dad.visible = true;
        
        for (glow in camGlows) //those who nose :(
        glow.visible = true;
    });

    easedFuncAt(5, 0.5, function(percent:Float, beat:Float){
        fade.alpha = FlxMath.lerp(1, 0, percent);
    });

}