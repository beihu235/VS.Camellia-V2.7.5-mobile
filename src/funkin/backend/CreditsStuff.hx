package funkin.backend;

import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import funkin.objects.ui.SkewyLine;

using StringTools;

/*typedef CreditsShit = {
    var song:String;
    var musician:String;
    var charter:String;
    var modcharter:String;
    var album:String;
}*/

class CreditsOverlay extends FlxSpriteGroup {
    public var backLines:SkewyLine;
    public var back:FunkinSprite;
    public var label:FunkinSprite;
    public var nowPlaying:FlxText;
    public var triangle:FunkinSprite;
    public var title:FlxText;
    public var info:FlxText;

    var wid:Float;

    public function new(y:Float, titleTxt:String, infoTxt:String, rightSide:Bool, scene:FlxGroup) {
        super();
        scene.add(this);
        scrollFactor.set();

        back = new FunkinSprite(0, y).loadGraphic(Paths.image("menus/NowPlaying/card"));
        back.scale.scale(2 / 3);
        back.updateHitbox();
        add(back);

        label = new FunkinSprite(0, back.y).loadGraphic(Paths.image("menus/NowPlaying/label"));
        label.scale.copyFrom(back.scale);
        label.updateHitbox();
        label.y -= label.frameHeight * label.scale.y * 0.5;
        add(label);

        if (!Settings.data.reducedQuality) {
            add(triangle = new FunkinSprite(15, label.y + label.height * 0.5, Paths.image("menus/triangle")));
            triangle.color = 0xFF000000;
            triangle.flipX = true;
            triangle.scale.set(0.35, 0.35);
            triangle.updateHitbox();
            triangle.y -= triangle.height * 0.5;
            triangle.origin.x += 3; // UUUUUGGGGGGGGHHHHHHHHH

            if (rightSide)
                triangle.x = FlxG.width - triangle.x - triangle.width;
        }

        nowPlaying = new FlxText(40, label.y + label.height * 0.5, 0, "NOW PLAYING");
        nowPlaying.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 18, 0xFF101010, LEFT);
        nowPlaying.y -= nowPlaying.height * 0.5;
        add(nowPlaying);

        title = new FlxText(5, back.y + 20, 0, titleTxt, 28);
		title.font = Paths.font('Rockford-NTLG Medium.ttf');
        title.alignment = rightSide ? RIGHT : LEFT;
        add(title);

        info = new FlxText(5, title.y + title.height, 0, infoTxt, 20);
		info.font = Paths.font('Rockford-NTLG Light.ttf');
        info.alignment = title.alignment;
        add(info);

        final width = Math.max(Math.max(title.width + 15, info.width + 15), (595 - back.graphic.width) * back.scale.x) + back.graphic.width * back.scale.x;
        final clipWidth = width / back.scale.x;
        back.frame.frame.set(-clipWidth + back.graphic.width, 0, clipWidth, back.graphic.height);
        back.frame.sourceSize.x = Math.ceil(clipWidth);
        back.resetFrame();
        back.updateHitbox();

        var xMult = -1;
        var points = [-15, back.scale.y, back.width, back.scale.y, back.width - 163 * back.scale.x, back.height - back.scale.y, -15, back.height - back.scale.y];
        if (rightSide) {
            back.flipX = label.flipX = true;
            back.x = FlxG.width - back.width;
            label.x = FlxG.width - label.width;

            points = [0, back.scale.y, back.width + 15, back.scale.y, back.width + 15, back.height - back.scale.y, 163 * back.scale.x, back.height - back.scale.y];

            for (obj in [nowPlaying, title, info])
                obj.x = FlxG.width - obj.x - obj.width;
            
            xMult = 1;
        }

        if (!Settings.data.reducedQuality) {
            backLines = new SkewyLine(points);
            backLines.setPosition(back.x, back.y);
            insert(members.indexOf(back), backLines);
        }
        
        wid = width;
        x += width * xMult;
        var twn = FlxTween.tween(this, {x: 0}, 1, {ease: FlxEase.quintOut});
        twn.then(FlxTween.tween(this, {x: width * xMult}, 1.5, {
            ease: FlxEase.quintOut,
            startDelay: 3,
            onComplete: tween -> {
                scene.remove(this);
                destroy();
            }
        }));
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (backLines != null)
            backLines.alpha = (wid - Math.abs(x)) * 0.02;

        if (triangle != null)
            triangle.angle += elapsed * 160;
    }

    //public static var albumpublic:String;
    /**
     * this function is used to roll the credits of the song in the playstate
     * @param scene the scene where the credits will be displayed
     * @param camera the camera where the credits will be displayed
     */
    public static function rolldaCredits(scene:FlxState, camera:FlxCamera, ?rightSide:Bool = false) {
        var creditData:funkin.backend.Meta.MetaFile = funkin.states.PlayState.song.meta != null ? funkin.states.PlayState.song.meta : {
            songName: "N/A",
            instComposer: "N/A",
            vocalComposer: "N/A",
            charter: [],
            album: "N/A",
            jacket: "N/A",
            timingPoints: [],
            offset: 0.0,
            hasVocals: true,
            player: "bf",
            spectator: "bf",
            enemy: "bf",
            stage: "studio"
        };
        /*var creditData:CreditsShit = (jsonPath == null) ? {
            song: "N/A",//PlayState.instance.formattedSong,
            musician: "N/A",
            charter: "N/A",
            modcharter: "N/A",
            album: "N/A"
        } : Json.parse(jsonPath);*/

        var creds = new CreditsOverlay(160, creditData.songName, formatCreditText(creditData), rightSide, scene);
        creds.camera = camera;
        return creds;
    }

    static function formatCreditText(data:funkin.backend.Meta.MetaFile):String{
        var text = [
            'arrange: ${data.vocalComposer}',
            'chart: ${data.charter[Difficulty.current]}'
        ];
        /*if (data.modcharter != "N/A" && data.modcharter != null) {
            text.push('Modcharter ${data.modcharter}');
        }*/
        /*if (data.album != "N/A" && data.album != null) {
            text.push('From: ${data.album}');
        }*/

        //albumpublic = data.album;

        return text.join("\n");
    }
}

typedef MusicList = {
    var music:Array<String>;
    var bpm:Array<ShortUInt>;
}
class MenuMusic{
    public static var track:ByteUInt = 0;
    //public static var artists:String = 'N/A';
    public static var musicList:Array<String> = [];
    public static var bpmList:Array<ShortUInt> = [];

    //for the first start
    public static var gameInitialized:Bool = false;

    /**
     * this function loads the music list from a JSON file (prob it will change to another format in the future)
     */
    public static function loadMusicList(){
        var jsonPath = null;//Paths.getTextFromFile('music/musiclist.json');
        var json:MusicList = (jsonPath == null) ? {
            music: ['Myths You Forgot', 'Dance with Silence'],
            bpm: [149, 128]
        }: Json.parse(jsonPath);
        //trace("Music Loaded: "+json.music);
        musicList = json.music;
        bpmList = json.bpm;
    }

    /**
     * this function is used to get the song name for the menus, recommended to save in one variable if you are going to use it in more things since
     * it will change every time you call it
     * @return String
     */
     public inline static function gimmeMusicName ():String{
        track = /*(musicList.length == 1 || musicList.length == 0) && */!gameInitialized ? 0 : FlxG.random.int(0, musicList.length-1);
        //trace("Music: "+musicList[track] + " tracknumber: "+track);
        return musicList[track];
    }
    /**
     * this function will give you the bpm of the current track
     * @return ShortUInt//Int
     */
    public inline static function bpm():ShortUInt{
        return bpmList[track];
    }
    /**
     * this function will roll some info of the current track in the menu
     * @param scene 
     */
    public static function menuCredits(scene:FlxState){
        return new CreditsOverlay(85, musicList[track], "", false, scene);
    }
}