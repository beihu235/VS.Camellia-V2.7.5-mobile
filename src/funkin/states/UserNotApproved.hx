package funkin.states;

class UserNotApproved extends flixel.FlxState{
    public function new(){
        super();
    }
    
    override function create():Void{
        super.create();
        Conductor.inst = FlxAudioHandler.loadAudio(Paths.audioPath("dontplayme", "sfx"), true);
        Conductor.inst.play();
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image("stages/concert/camelliaJumpscare"));
        bg.screenCenter();
        bg.alpha = 0.1;
        add(bg);
        var text:FlxText = new FlxText(0, 0, FlxG.width, "THIS IS A VS CAMELLIA TEST BUILD\n\nwe detected you aren't a tester, the game is blocked\n\n if this is an error, please send a message to rudy in discord\n\nand no, disabling your internet won't work pal :p");
        text.setFormat(null, 32, FlxColor.WHITE, "center");
        text.screenCenter();
        add(text);
    }
}