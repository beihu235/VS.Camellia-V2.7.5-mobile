package funkin.states;
import flixel.math.FlxPoint;

class BlueBalledState extends flixel.FlxSubState {
    var char:funkin.objects.Character;
    var song:String;

    var bg:FlxSprite;

    var camPos:FlxPoint;
	var camPointer:FlxObject;

    var confirm:Bool = false;
    var followCam:Bool = true;

    var charID:ByteInt;

    public function new(cam:FlxCamera, charID:ByteInt = 0) {
        this.charID = charID;
        this.camera = cam;
        super();
        add(bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK));
        bg.scrollFactor.set(0, 0);
        bg.moves = false;
        bg.active = false;

        final ps = funkin.states.PlayState.self;
        final strums = ps.playfield.strumlines;
        char = (charID < strums.length && strums.members[charID].character() != null) ? strums.members[charID].character() : ps.bf;
        char.dead = true;
        char.screenCenter();
        add(char);

        camPos = new FlxPoint(char.getGraphicMidpoint().x, char.getGraphicMidpoint().y);
        camera.target = null;
		add(camPointer = new FlxObject(0, 0, 1, 1));
        //camPos.set(char.getGraphicMidpoint().x, char.getGraphicMidpoint().y);
        camPointer.setPosition(camera.scroll.x + (FlxG.camera.width / 2), camera.scroll.y + (FlxG.camera.height / 2));
        camera.follow(camPointer, LOCKON, 1);

        char.playAnim('firstDeath');

		FlxG.timeScale = 1;
        FlxG.sound.play(Paths.audio("menu_deletedata", "sfx"));
        new FlxTimer().start(1.2, _ -> {
            Conductor.inst = FlxAudioHandler.loadAudio(Paths.audioPath("zenith", "music"), true, 0.5, true);
            Conductor.inst.pitch = 1;
			Conductor.inst.play();
            followCam = false;
            char.playAnim('death-loop');
        });
    }

    override function update(t:Float){
        super.update(t);
        if(confirm) return;
        //trace("pointer pos: X:"+camPointer.x + " Y:"+camPointer.y);
        if (followCam) {
            camPos.x = char.x + char.origin.x - char.offset.x - (char.frameOffset.x * char.scale.x);
            camPos.y = char.y + char.origin.y - char.offset.y - (char.frameOffset.y * char.scale.y);
            camPointer.setPosition(FlxMath.lerp(camPointer.x, camPos.x, t * 60 * 0.85), 
                                   FlxMath.lerp(camPointer.y, camPos.y, t * 60 * 0.85));
        }

        if (Controls.justPressed('accept')){
            Conductor.stop();
            FlxG.sound.play(Paths.audio("menu_confirm", "sfx"));
            char.playAnim('confirm');
            ending();
        } else if (Controls.justPressed('back')) {
            Conductor.stop();
            FlxG.sound.play(Paths.audio("byebye", "sfx"));
            char.playAnim('missUP');
            backToMenu();
        }
    }

    function ending():Void{
        confirm = true;
        new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				camera.fade(FlxColor.BLACK, 2, false, function()
				{
					funkin.states.PlayState.resetState();
				});
			});
    }

    function backToMenu():Void {
        confirm = true;
        new FlxTimer().start(0.7, function(tmr:FlxTimer){
            camera.fade(FlxColor.BLACK, 2, false, function()
            {
                if(funkin.states.PlayState.storyMode) {
					PlayState.songList.resize(0);
					PlayState.storyMode = false;
                    FlxG.switchState(new funkin.states.StoryMenuState());
				} else
                    FlxG.switchState(new funkin.states.FreeplayState());
            });
        });
    }
}