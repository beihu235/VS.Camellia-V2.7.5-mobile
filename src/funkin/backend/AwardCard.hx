package funkin.backend;

import funkin.backend.Awards.Award;
import openfl.events.Event;
import funkin.shaders.GradMask;
import openfl.filters.ShaderFilter;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;

class AwardCard extends Sprite {
    var globalMessages:Array<String> = [
        "ACHIEVEMENT UNLOCKED!",
        "YOU GOT AN AWARD!",
        "youre did it",
        "WOW YOU GOT THE\n[4 Lines in a Row]"
    ];
    var iconBasedMessages:Map<String, Array<String>> = [
        "bronze" => [
            "well anyone can do that"
        ],
        "sliver" => [
            "ALRIGHTY!"
        ],
        "gold" => [
            "AIMED BIG!",
            "LOOK AT YOU GO!",
            "1987\nTHATS ALL I'LL SAY"
        ],
        "platinum" => [
            "tryhard."
        ]
    ];

    static final BG_WIDTH:Int = 500;

    var bg:Bitmap;
    var icon:Bitmap;
    var title:TextField;
    var desc:TextField;
    var green:Bitmap;
    var message:TextField;
    var gradMask:GradMask;

    var newAward:Bool = false;
    var queuedAwards:Array<Award> = [];
    var greenTime:Float = 0;
    var awardTime:Float = 0;

    public function new() {
        super();

        addChild(bg = new Bitmap(new BitmapData(1, 1, true, 0x80000000)));
        bg.width = BG_WIDTH;
        bg.height = 130;
        bg.x = Lib.current.stage.stageWidth;

        addChild(icon = new Bitmap(BitmapData.fromFile(Paths.get("menus/Awards/lock.png", "images"))));
        icon.height = bg.height - 20;
        icon.y = 10;
        icon.scaleX = icon.scaleY;
        icon.smoothing = Settings.data.antialiasing;
        icon.x = bg.x + 5;

        addChild(title = new TextField());
        title.x = icon.x + icon.width + 5;
        title.y = icon.y + 3;
        title.width = BG_WIDTH - icon.width - 20;
		title.multiline = true;
		title.wordWrap = true;
		title.selectable = false;
		title.embedFonts = true;

        var titleFormat:TextFormat = new TextFormat(Paths.font("Rockford-NTLG Medium.ttf"), 30, 0xffffff);
		titleFormat.align = TextFormatAlign.LEFT;
		title.defaultTextFormat = titleFormat;
        title.text = "Touching grass was never an option.";

        addChild(desc = new TextField());
        desc.x = title.x;
        desc.y = title.y + title.textHeight + 5;
        desc.width = title.width;
		desc.multiline = true;
		desc.wordWrap = true;
		desc.selectable = false;
		desc.embedFonts = true;

        var descFormat:TextFormat = new TextFormat(Paths.font("Rockford-NTLG Light.ttf"), 18, 0xffffff);
		descFormat.align = TextFormatAlign.LEFT;
		desc.defaultTextFormat = descFormat;
        desc.text = "Full Combo every song in any difficulty!";

        #if flash
        title.antiAliasType = AntiAliasType.NORMAL;
		title.gridFitType = GridFitType.PIXEL;
		desc.antiAliasType = AntiAliasType.NORMAL;
		desc.gridFitType = GridFitType.PIXEL;
		#end

        addChild(green = new Bitmap(new BitmapData(1, 1, true, 0xFFFFBC2D)));
        green.width = BG_WIDTH;
        green.height = 130;
        green.x = Lib.current.stage.stageWidth - green.width;
        green.shader = gradMask = new GradMask();
        gradMask.from.value = [1];
        gradMask.to.value = [1];
        gradMask.alpha.value = [1];

        addChild(message = new TextField());
        message.x = green.x;
        message.y = green.y;
        message.width = green.width;
		message.multiline = true;
		message.wordWrap = true;
		message.selectable = false;
		message.embedFonts = true;
        message.shader = gradMask;

        var msgFormat:TextFormat = new TextFormat(Paths.font("Rockford-NTLG Medium.ttf"), 40, 0xffffff);
		msgFormat.align = TextFormatAlign.CENTER;
		message.defaultTextFormat = msgFormat;
        message.text = "> FCs every song\n> Bronze";
    }

    override function __enterFrame(delta:Float) {
        if (awardTime < 1.75 && newAward && queuedAwards.length > 0) {
            newAward = false;
            icon.bitmapData.dispose();
            icon.bitmapData = BitmapData.fromFile(Paths.get("menus/Awards/" + queuedAwards[0].icon + ".png", "images"));
            icon.height = bg.height - 20;
            icon.scaleX = icon.scaleY;
            title.width = desc.width = BG_WIDTH - icon.width - 20;

            title.text = queuedAwards[0].name;
            desc.text = queuedAwards[0].description;
            desc.y = title.y + title.textHeight + 5;
        }

        /*if (FlxG.keys.justPressed.T) {
            for (award in funkin.backend.Awards.list)
                pushAward(award);
        } else if (FlxG.keys.justPressed.Y)
            pushAward(funkin.backend.Awards.list[20]);*/

        if (bg.x >= Lib.current.stage.stageWidth && greenTime <= 0.0) return;
        
        delta *= 0.001;
        green.x = message.x = Lib.current.stage.stageWidth - BG_WIDTH;
        icon.smoothing = Settings.data.antialiasing;
        if (greenTime > 0) {
            greenTime = Math.max(greenTime - delta, 0.0);
            var scale = FlxEase.quartOut(1.0 - Math.max(Math.abs(greenTime - 1) - 0.5, 0.0) * 2);
            gradMask.from.value[0] = 1.0 - scale * 1.1;
            gradMask.to.value[0] = 1.0 - scale;

            if (greenTime > 1) {
                bg.x = Lib.current.stage.stageWidth - BG_WIDTH * scale;
                icon.x = bg.x + 10;
                title.x = desc.x = icon.x + (icon.bitmapData.width * icon.scaleX) + 5;
            }
        } else {
            awardTime = Math.max(awardTime - delta, 0.0);
            if (awardTime <= 0.0 && queuedAwards.length > 0) {
                queuedAwards.shift();
                newAward = queuedAwards.length > 0;
                awardTime = newAward ? 2 : 0;
            }

            var fadeScale = awardTime < 1.5 ? 0 : ((awardTime > 1.75 ? 2 - awardTime : 1.5 - awardTime) * 4.0);
            icon.y = 10 + 20 * Math.pow(fadeScale, 3.0);
            title.y = icon.y + 3;
            desc.y = title.y + title.textHeight + 5;
            icon.alpha = title.alpha = desc.alpha = 1.0 - Math.abs(fadeScale);

            bg.x = FlxMath.lerp(bg.x, Lib.current.stage.stageWidth - ((queuedAwards.length > 0) ? BG_WIDTH : 0), delta * 7.5);
            icon.x = bg.x + 10;
            title.x = desc.x = icon.x + (icon.bitmapData.width * icon.scaleX) + 5;
        }
    }

    public function pushAward(award:Award) {
        queuedAwards.push(award);

        newAward = true;
        if (greenTime <= 0.0 && bg.x > Lib.current.stage.stageWidth - 3) {
            var msgList = globalMessages;
            if (iconBasedMessages.exists(award.icon))
                msgList = msgList.concat(iconBasedMessages[award.icon]);
            message.text = FlxG.random.getObject(msgList);
            message.y = green.y + (green.height - message.textHeight) * 0.5;

            greenTime = 2;
            awardTime = 1.5;
            FlxG.sound.play(Paths.audio("never2x jingle", "sfx"));
        } else if (queuedAwards.length <= 1)
            awardTime = 2;
    }
}