package funkin.states;

import funkin.shaders.TileLine;
import funkin.objects.ui.SpinnyTriangle;
import funkin.objects.ui.CategoryList;
import funkin.objects.ui.SwirlBG;
import funkin.objects.ui.Border;

@:structInit
class Person {
	public var name:String;
	public var role:String;
	public var links:Map<SocialPage, String> = [];
	public var pronouns:String = "";
	public var portrait:String = "BACKUP_PORTRAIT";

	public var color1:FlxColor = 0xFF606060;
	public var color2:FlxColor = 0xFFA0A0A0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var pixelSize:Float = 300;
	public var pixelSizeMatches:RectAxis = WIDTH;
}

enum abstract RectAxis(Int) from Int to Int {
	var WIDTH;
	var HEIGHT;
}

enum abstract SocialPage(String) from String to String {
	var OSU = 'osu!';
	var TWITTER = 'Twitter';
	var BLUESKY = 'Bluesky';
	var YOUTUBE = 'YouTube';
	var CARRD = 'carrd';
	var OTHER = 'Other';
}

class CreditsState extends FunkinState {
	public static final categoryList:Array<String> = ["Musicians", "Programmers", "Artists", "Charters", "Bugtesters", "Special Thanks"];
	public static final list:Map<String, Array<Person>> = [
		"Musicians" => [
			{
				name: 'LiterallyNoOne',
				portrait: "marc portrait",
				role: 'Lead Director, Vocal Covers, Quality Assurance',
				links: [
					YOUTUBE => 'https://www.youtube.com/c/LiterallyNoOne',
					TWITTER => 'https://x.com/L_No_One1',
					BLUESKY => 'https://bsky.app/profile/literallynoone.bsky.social'
				],
				pronouns: 'he/she/they',

				color1: 0xFF79E6FC,
				color2: 0xFF00267A,

				pixelSize: 500,
				pixelSizeMatches: HEIGHT,
				offsetX: -50
			},
			{
				name: 'tictacto',
				role: 'Co-Director, Lead Composer, Vocal Covers, Menu UI, Sound Design, JP Translation Support',
				links: [
					TWITTER => 'https://x.com/tictactuh_',
					YOUTUBE => 'https://www.youtube.com/@tictacto',
					OTHER => 'https://tictacto.xyz/'
				],
				portrait: "tac_portrait_temp",
				pronouns: 'they/them',

				color1: 0xFF2C8198,
				color2: 0xFF58FEB2,
				offsetY: -20
			},
			{
				name: 'Drazically',
				role: 'Composer, Sound Design, JP Translation Support',
				pronouns: 'he/him',
				links: [
					TWITTER => 'https://x.com/drazicallydtm',
					YOUTUBE => 'https://www.youtube.com/@drazicallydtm',
					OTHER => 'https://linktr.ee/drazically'
				],
				color1: 0xFFF8B7A6,
				color2: 0xFFAC5246
			}
		],


		"Programmers" => [
			{
				name: 'Rudyrue',
				role: 'Lead Programmer, Never2x Team, Charter',
				links: [
					BLUESKY => 'https://bsky.app/profile/rudyrue.bsky.social',
				],
				pronouns: 'she/they',
				portrait: 'rudy',
				pixelSize: 500,
				pixelSizeMatches: HEIGHT,
				offsetX: 7,

				color1: 0xFFFFFFFF,
				color2: 0xFFD03190
			},
			{
				name: 'SrtHero278',
				role: 'Programmer, Never2x Team',
				links: [
					BLUESKY => 'https://bsky.app/profile/srtpro278.bsky.social',
					TWITTER => 'https://x.com/SrtPro278'
				],
				pronouns: 'he/they',

				color1: 0xFF181818,
				color2: 0xFF00FFFF
			},
			{
				name: 'BlearChipmunk',
				role: 'Programmer, ES Translation Support',
				pronouns: 'he/him',
				color1: 0xFF91FFB6,
				color2: 0xFF9727FF,
			},
			{
				name: 'Nebula The Zorua',
				role: 'Programmer, Modcharting Support',
				links: [
					BLUESKY => 'https://bsky.app/profile/nebulazorua.bsky.social',
					TWITTER => 'https://x.com/nebula_zorua'
				],
				portrait: 'nebula',
				pronouns: 'he/she',
				color1: 0xC4CA91FF,
				color2: 0xFFFFFFFF,
				offsetX: -7,
				offsetY: 3
			},
			{
				name: 'BoloVEVO',
				role: '2.5 Lead Programmer, Additional Support',
				pronouns: 'he/him',
				links: [
					TWITTER => 'https://x.com/BoloVEVO'
				],
			},
			{
				name: 'Raltyro',
				role: 'Programmer, Audio Backend Rewrite',
				pronouns: '',
				links: [
					TWITTER => 'https://x.com/raltyro',
					OTHER => 'https://github.com/Raltyro'
				],
			},
			{
				name: 'Myceli',
				role: 'Programmer, MacOS Support',
				pronouns: 'she/her',
				links: [
					TWITTER => 'https://x.com/burgerballs9',

				],
			},
			{
				name: 'swordcube',
				role: 'Programmer, Linux Support',
				pronouns: 'he/him',
				links: [
					TWITTER => 'https://x.com/the_cubical_guy',
					BLUESKY => 'https://bsky.app/profile/swordcube.bsky.social',
				],
			}
		],


		"Artists" => [
			{
				name: 'SugarRatio',
				role: 'Lead Artist, Concept Art, Quality Assurance, Week 1 Assets',
				pronouns: '',
				links: [
					TWITTER => 'https://x.com/SugarRatio',
				],
				color1: 0xFFFFFFFF,
				color2: 0xC491FF97,
			},
			{
				name: 'PhilliaEsaya',
				role: 'Artist, Jacket Art, Storyboarding',
				pronouns: 'she/her',
				portrait: 'phillia',
				pixelSize: 500,
				pixelSizeMatches: HEIGHT,
				offsetY: 10,

				color1: 0xffb8872c,
				color2: 0xffffd659

			},
			{
				name: 'sts_puelle',
				role: 'Artist, Jacket Art, Storyboarding',
				pronouns: 'she/her',
				links: [
					CARRD => 'https://pietime.carrd.co/',
					TWITTER => 'https://x.com/STS_PiaEsaya',
					BLUESKY => 'https://bsky.app/profile/sts-puelle.bsky.social'
				],
			},
			{
				name: 'CocoTheMunchkin',
				role: 'Artist, Halloween Sprites, Concept Art, Credits Portraits',
				pronouns: 'she/her',
				portrait: 'coco',
				pixelSize: 500,
				pixelSizeMatches: HEIGHT,
				offsetX: -20,
				links: [
					YOUTUBE => 'https://www.youtube.com/@CocotheMunchkin',
					TWITTER => 'https://x.com/CocotheMunchkin',
					BLUESKY => 'https://bsky.app/profile/cocothemunchkin.bsky.social',
					CARRD => 'https://cocothemunchkin.carrd.co/'
				],
				color1: 0xFFFFE675,
				color2: 0xFFFF9741,
			},
			{
				name: 'Dyl',
				role: 'Artist, Main Menu Portraits, Dialogue Portraits',
				links: [
					BLUESKY => 'https://bsky.app/profile/dyllpill.bsky.social',
				],
				pronouns: 'she/they',
				portrait: 'dyl',
				pixelSize: 500,
				pixelSizeMatches: HEIGHT,
				offsetY: 10,

				color1: 0xFF1A43BF,
				color2: 0xFF0A2472
			},
			{
				name: 'Uniimations',
				role: 'Artist, Week 2 Speakers, Lioness\' Pride GF',
				pronouns: 'she/her',
				links: [
					TWITTER => 'https://x.com/UniiAnimates',
					YOUTUBE => 'https://youtube.com/uniimations'
				],
				color1: 0xFFED4E71,
				color2: 0xFF6A2275
			},
			{
				name: 'Ruiner',
				role: 'Artist, Story Mode Portraits, Promo Art',
				pronouns: 'it/they/he'
			},
			{
				name: 'lalnerd',
				role: 'Artist, Middle Camellia Sprites',
				pronouns: 'she/he',
				links: [
					BLUESKY => 'https://bsky.app/profile/lalnerd.bsky.social',
				],
			},
			{
				name: 'Katanims',
				role: 'Artist, Camellia Sing Sprites, Bob Reanimation (unused atm)',
				pronouns: 'she/her',
				links: [
					TWITTER => 'https://x.com/KatAnims',
					BLUESKY => 'https://bsky.app/profile/katanims.bsky.social',
				],
			},
			{
				name: 'Keaton Hoshida',
				role: 'Artist, Botan Sprites',
				pronouns: 'she/her'
			},
			{
				name: 'DamiNation',
				role: 'Artist, BF Reanimation',
				pronouns: 'he/him',
				links: [
					TWITTER => 'https://x.com/DamiNation2020'
				],
			},
			{
				name: 'mewt',
				role: 'Artist, Additional UI Support',
				pronouns: 'she/her',
				links: [
				TWITTER => 'https://twitter.com/mewtilation'
				],
			},
			{
				name: 'Grand Hammer 6',
				role: 'Artist, Camellia/Botan Dialogue Portraits',
				pronouns: 'he/him',
				links: [
					TWITTER => 'https://x.com/GrandHammer6',
					BLUESKY => 'https://bsky.app/profile/grandhammer6.bsky.social',
					YOUTUBE => 'https://www.youtube.com/channel/UCEJjX7zSqXwEaACXhn8Pwbw'
				],
			},
			{
				name: 'Exo_bonez',
				role: 'Artist, New Logo, Misc UI Assets, Disclaimer Background',
				pronouns: 'she/they/it',
				links: [
					CARRD => 'https://robotonini.carrd.co/'
				],
			},
			{
				name: 'Offbi',
				role: 'Artist, Week 2 Background',
				pronouns: ''
			},
			{
				name: 'Swizik',
				role: 'Artist, Judgement Ratings',
				pronouns: ''
			},
		],


		"Charters" => [
			{
				name: 'Foxeru',
				role: 'Co-Director, Lead Charter, Misc UI Assets, PT-BR Translation Support, Quality Assurance',
				links: [
					TWITTER => 'https://x.com/FoxeruKun',
					OSU => 'https://osu.ppy.sh/users/7479684'
				],
				pronouns: 'he/they',
				portrait: "foxeru",
				pixelSize: 500,
				pixelSizeMatches: HEIGHT,
				offsetX: -50,
				offsetY: 5,

				color1: 0xFFF7E489,
				color2: 0xFF62427A
			},
			{
				name: 'Lott',
				role: 'Charter, Quality Assurance',
				portrait: 'lott',
				pixelSize: 500,
				pixelSizeMatches: HEIGHT,
				offsetX: -40,
				links: [
					TWITTER => 'https://x.com/lott_on_osu',
					CARRD => 'https://lotthhh.carrd.co'
				],
				pronouns: 'he/him',

				color1: 0xFFb2edc2,
				color2: 0xff5f8aff
			},
			{
				name: 'Kafkell',
				role: 'Charter',
				links: [
					CARRD => 'https://ziemi.carrd.co'
				],
				pronouns: 'he/him'
			},
			{
				name: 'Garacide',
				role: 'Charter',
				pronouns: 'she/they'
			},
			{
				name: 'Lumin',
				role: 'Charter',
				pronouns: 'she/they'
			},
			{
				name: 'Roxas',
				role: 'Charter',
				links: [
					TWITTER => 'https://x.com/RoxasEternal'
				],
				pronouns: 'he/him'
			},
			{
				name: 'Alumence',
				role: 'Charter',
				links: [
					YOUTUBE => 'https://www.youtube.com/@alumence_',
					OSU => 'https://osu.ppy.sh/users/30357961'
				],
				pronouns: 'he/him',

				color1: 0xFFAB52C0,
				color2: 0xFF5B7EF4
			},
			{
				name: 'Flootena',
				role: 'Charter',
				links: [
					TWITTER => 'https://x.com/FlootenaDX'
				],
				pronouns: 'she/they',
				portrait: "flootena",
				pixelSize: 500,
				pixelSizeMatches: HEIGHT,

				color1: 0xFF4B0082,
				color2: 0xFFE0B0FF
			},
			{
				name: 'RalseiMania',
				role: 'Charter',
				links: [
					YOUTUBE => 'https://www.youtube.com/@GOSChara',
					OSU => 'https://osu.ppy.sh/users/27620293'
				],
				pronouns: 'he/him',
			},

			// (These people still have stuff in the mod
			// (but aren't actively part of the team at the moment

			{
				name: 'Roko100789',
				role: 'Charter',
				links: [
					TWITTER => 'https://x.com/roko100789'
				],
				pronouns: 'she/her'
			},
			{
				name: 'Ragnarok VII',
				role: 'Charter',
				links: [
					TWITTER => 'https://twitter.com/ragnarok_vii'
				],
				pronouns: 'they/them'
			},
			{
				name: 'YokiGuise',
				role: 'Charter',
				pronouns: 'he/him'
			},
			{
				name: 'Kodapop',
				role: 'Charter, Additional Holofunk Support',
				pronouns: ''
			},
			{
				name: 'Somf',
				role: 'Charter',
				pronouns: ''
			},
			{
				name: 'Polarin',
				role: 'Charter',
				pronouns: 'he/him'
			},
			{
				name: 'Jian Awesome',
				role: 'Charter',
				pronouns: ''
			},
			{
				name: 'Cloverderus',
				role: 'Charter',
				pronouns: ''
			},
			{
				name: 'Kienoob',
				role: 'Charter',
				pronouns: 'he/him'
			},
			{
				name: 'Tenebryste',
				role: 'Charter, Bugtester',
				pronouns: ''
			},
			{
				name: 'Jaldabo',
				role: 'Charter, Bugtester',
				pronouns: 'he/him'
			},
			
		],

		"Bugtesters" => [
			{
				name: 'CarlosisST',
				role: 'Bugtester',
				pronouns: 'they/them',
				color1: 0xFF00D41C,
				color2: 0xFF0075D4
			},
			{
				name: 'Faid',
				role: 'Bugtester, Permission for FNVoltex Noteskins',
				pronouns: 'he/him',
				color1: 0xFFFFAB57,
				color2: 0xFF2B6DFC,
			},
			{
				name: 'PunkinMike',
				role: 'Bugtester',
				pronouns: 'they/he/she',
				color1: 0xFF8C47BD,
				color2: 0xFFD28EFF
			},
			{
				name: 'turtloid',
				role: 'Bugtester, Additional Sound Support/Audio Mixing',
				pronouns: 'he/him',
				color1: 0xFF00D41C,
				color2: 0xFF28802F
			},
			{
				name: 'factsoars',
				role: 'Bugtester',
				pronouns: 'he/him',
				links: [
					TWITTER => 'https://x.com/FA4TLV'
				],
				color1: 0xFF59B4FF,
				color2: 0xFF0654E7
			}
		],

		"Special Thanks" => [
			{name: "Camellia", role: "Thank you for everything, man!"},
			{name: "Holofunk Team", role: "Holofunk Collab"},
			{name: "Myth Engine Team", role: "2.5 Engine"},
			{name: "Kade Developer", role: "1.0/2.0 Engine, basis for Myth"},
			{name: "tentaRJ", role: "1.0 Programming support, 2.5 Gamejolt integration"},
			{name: "MaybeMaru", role: "Moonchart Support + a lot of Texture Atlas related support"},
			{name: "SKL", role: "Voice Actor"},
			{name: "shiroboom", role: "Additional Jacket Arts"},
			{name: "Kyaretto_", role: "Additional Jacket Arts"},
			{name: "Noodnutz_", role: "Additional Jacket Arts"},
			{name: "Public Discord Bugtesters", role: "Thank you for the insane amount of feedback!"},
			{name: "Kasumii-Sama", role: "Allowing us to use TremENDouS"},
			{name: "POCARI SWEAT", role: "TremENDouS Jacket Art"},
			{name: "wildy", role: "Allowing Bob Takeover to happen when it was in"},
			{name: "Kloogybaboogy", role: "Legacy Bob week dialogue, Award Names"},
			{name: "Applebar", role: "Logo feedback, Additional Support"},
			{name: "ZenusPurity", role: "Legacy Week 1 Modcharts"},
			{name: "Sonance", role: "Additional JP Support"},
			{name: "Plushu", role: "1.0 Additional Support"},
			{name: 'Doggo', role: 'Emotional support'},
			{name: 'Hedhālen', role: 'Emotional support'},
			{name: "Fireable", role: "Original Creator + Week 1/2 Director"}
		]
	];
	var curList(get, never):Array<Person>;
	inline function get_curList()
		return list[categoryList[selCategory]];

	var listGrp:CategoryList;
	var selCategory:Int = -1;
	var curPerson:Int = 0;

	var nameBG:FunkinSprite;
	var nameTxt:FlxText;
	var woke:FlxText;
	var descBG:FunkinSprite;
	var descTxt:FlxText;
	var socials:CategoryList;
	var portrait:FunkinSprite;
	var personTriangle:SpinnyTriangle;

	var curThankScroll:Float = 0;
	var thankScrollInc:Float = 0;
	var selThankScale:Float = 0;
	var thankBG:FunkinSprite;
	var thankSel:FunkinSprite;
	var thankTriangle:FunkinSprite;
	var thankTxt:FlxTypedGroup<FlxText>;

	var lastDescHeight:Float = 0;
	var thankDescBG:FunkinSprite;
	var thankDescTxt:FlxText;

    var bg:SwirlBG;
	var lineShader:TileLine;

	var borderTop:Border;
	var borderBot:Border;
	var buttonGroup:FlxSpriteGroup;

	override function create():Void {
		super.create();

		add(bg = new SwirlBG(0xFF606060, 0xFFA0A0A0));

		if (!Settings.data.reducedQuality) {
			var lineBG = new FunkinSprite();
			lineBG.makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
			lineShader = new TileLine();
			lineShader.color1.value = [0, 0, 0, 0.375];
			lineShader.color2.value = [0, 0, 0, 0.5];
			lineShader.density.value = [200.0];
			lineShader.time.value = [SwirlBG.time / 64];
			lineBG.shader = lineShader;
			add(lineBG);
		}

		add(listGrp = new CategoryList(20, 120, categoryList));
		listGrp.open = openCategory;
		listGrp.onRetarget = (i) -> {bg.speed = 5;};
		
		add(personTriangle = new SpinnyTriangle(FlxG.width * 0.75, FlxG.height * 0.85));
		add(portrait = new FunkinSprite());

		add(nameBG = new FunkinSprite(20, 120).makeGraphic(1, 1, 0x70000000));
		nameBG.scale.set(0, 120);
		nameBG.origin.set();

		add(nameTxt = new FlxText(nameBG.x + 17.5, nameBG.y + 5, 0, ""));
		nameTxt.setFormat(Paths.font("HelveticaNowDisplay-Black.ttf"), 42, 0xFFFFFFFF, LEFT);
		nameTxt.scale.x = 1.15;

		add(woke = new FlxText(nameTxt.x, nameTxt.y + nameTxt.height, 0, ""));
		woke.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 28, 0xFFFFFFFF, LEFT);

		add(descBG = new FunkinSprite(nameBG.x, nameBG.y + nameBG.scale.y + 10).makeGraphic(1, 1, 0x70000000));
		descBG.scale.set(530, 190);
		descBG.updateHitbox();
		descBG.scale.x = 0;
		descBG.offset.set();
		descBG.origin.set();

		add(descTxt = new FlxText(descBG.x + 20, descBG.y + 17.5, descBG.width - 40, ""));
		descTxt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 28, 0xFFFFFFFF, LEFT);

		add(socials = new CategoryList(descBG.x, descBG.y + descBG.height + 10, [], false));
		socials.open = function(id) {
			final key = socials.options[id];
			if (!listGrp.enterHit && curList[curPerson].links.exists(key))
				Util.openURL(curList[curPerson].links[key]);
		};
		socials.onRetarget = (i) -> {bg.speed = 5;};
		socials.useInputs = socials.useMouse = false;
		socials.alpha = 0;

		add(thankBG = new FunkinSprite(listGrp.x + listGrp.width + 25, listGrp.y).makeGraphic(1, 1, 0x70000000));
		thankBG.scale.set(515, 515);
		thankBG.updateHitbox();
		thankBG.scale.y = 0;
		thankBG.offset.set();
		thankBG.origin.set();

		add(thankSel = new FunkinSprite(thankBG.x - 4, thankBG.y).makeGraphic(1, 1, 0xFFFFFFFF));
		thankSel.scale.set(thankBG.width + 8, 55);
		thankSel.updateHitbox();
		thankSel.scale.y = 0;

		add(thankDescBG = new FunkinSprite(thankBG.x + thankBG.width + 25, thankBG.y).makeGraphic(1, 1, 0x70000000));
		thankDescBG.scale.set();
		thankDescBG.origin.set();

		add(thankDescTxt = new FlxText(thankDescBG.x + 15, thankDescBG.y + 25, 255, ""));
		thankDescTxt.setFormat(Paths.font("Rockford-NTLG Extralight.ttf"), 20, 0xFFFFFFFF, LEFT);
		
		add(thankTxt = new FlxTypedGroup<FlxText>());
		var y = thankBG.y + 25;
		for (i => guy in list["Special Thanks"]) {
			var txt = new FlxText(thankBG.x + 20, y, thankBG.width - 40, guy.name);

			if (i == 0) {
				txt.y += 10;
				txt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 30, 0xFF101010, LEFT);
				y += 55;
			} else {
				txt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 30, 0xFFFFFFFF, LEFT);
				txt.updateHitbox();
				txt.scale.set(0.85, 0.85);
				txt.origin.x = 0;
				y += 35;
			}
			txt.antialiasing = Settings.data.antialiasing;
            thankTxt.add(txt);
		}

		add(thankTriangle = new FunkinSprite(thankSel.x + 20, 0, Paths.image("menus/triangle")));
		thankTriangle.color = 0xFF000000;
		thankTriangle.flipX = true;
		thankTriangle.scale.set(0.7, 0.7);
		thankTriangle.updateHitbox();
		thankTriangle.origin.x += 3; // UUUUUGGGGGGGGHHHHHHHHH

		thankScrollInc = Math.max(list["Special Thanks"].length * 35 + 60 - thankBG.height, 0) / list["Special Thanks"].length;

		var credsTile = new flixel.addons.display.FlxBackdrop(Paths.image('menus/Credits/bigText'), Y);
		credsTile.x = FlxG.width - credsTile.width;
		credsTile.velocity.y = 25;
		add(credsTile);

		add(borderTop = new Border(true, "SELECT A CATEGORY • ", "Credits"));
		add(borderBot = new Border(false));

		add(buttonGroup = new FlxSpriteGroup(0, borderBot.border.y + 88)); // unfortunately 58 is the only number that centers it.
		buttonGroup.directAlpha = true;
		buttonGroup.alpha = 0;

		var leftButton = new FunkinSprite(borderBot.x + 40, 0, Paths.image('menus/keyIndicator'));
		leftButton.angle = 270;
		leftButton.scrollFactor.set(0, 1);
		buttonGroup.add(leftButton);

		var rightButton = new FunkinSprite(leftButton.x + leftButton.width + 3, 0, Paths.image('menus/keyIndicator'));
		rightButton.angle = 90;
		rightButton.scrollFactor.set(0, 1);
		buttonGroup.add(rightButton);

		var changePersonTxt = new FlxText((rightButton.x + rightButton.width) + 5, 0, 0, _t("credits_scroll"), 16);
		changePersonTxt.font = Paths.font('LineSeed.ttf');
		changePersonTxt.scrollFactor.set(0, 1);
		buttonGroup.add(changePersonTxt);
		
		var upButton = new FunkinSprite(changePersonTxt.x + changePersonTxt.width + 50, 0, Paths.image('menus/keyIndicator'));
		upButton.scrollFactor.set(0, 1);
		buttonGroup.add(upButton);

		var downButton = new FunkinSprite(upButton.x + upButton.width + 3, 0, Paths.image('menus/keyIndicator'));
		downButton.angle = 180;
		downButton.scrollFactor.set(0, 1);
		buttonGroup.add(downButton);

		var changeSocialTxt = new FlxText((downButton.x + downButton.width) + 5, 0, 0, _t("social_scroll"), 16);
		changeSocialTxt.font = Paths.font('LineSeed.ttf');
		changeSocialTxt.scrollFactor.set(0, 1);
		buttonGroup.add(changeSocialTxt);

		borderTop.transitionTween(true);
	}

	function changeThank(to:Int) {
		if (to == curPerson) return;

		if (curPerson < thankTxt.length) {
			thankTxt.members[curPerson].color = 0xFFFFFFFF;
			thankTxt.members[curPerson].font = Paths.font("Rockford-NTLG Light.ttf");
		}

		curPerson = to;
		thankSel.scale.y = 0;
		selThankScale = 0;

		thankTxt.members[curPerson].color = 0xFF101010;
		thankTxt.members[curPerson].font = Paths.font("Rockford-NTLG Medium.ttf");	

		lastDescHeight = thankDescBG.scale.y;
		thankDescTxt.text = curList[curPerson].role;

		bg.speed = 5;
	}

	function changePerson(dir:Int) {
		curPerson = FlxMath.wrap(curPerson + dir, 0, curList.length - 1);

		bg.targetColor1 = curList[curPerson].color1;
		bg.targetColor2 = curList[curPerson].color2;

		nameTxt.text = curList[curPerson].name.toUpperCase();
		woke.text = curList[curPerson].pronouns;
		descTxt.text = curList[curPerson].role;

		socials.options = [for (key in [TWITTER, BLUESKY, YOUTUBE, CARRD, OSU, OTHER])
			if (curList[curPerson].links.exists(key))
				key
		];

		portrait.loadGraphic(Paths.image('menus/Credits/${curList[curPerson].portrait}') ?? Paths.image('menus/Credits/BACKUP_PORTRAIT'));
		portrait.scale.x = portrait.scale.y = curList[curPerson].pixelSize / (curList[curPerson].pixelSizeMatches == WIDTH ? portrait.frameWidth : portrait.frameHeight);
		portrait.updateHitbox();
		portrait.offset.subtract(curList[curPerson].offsetX, curList[curPerson].offsetY);
		portrait.x = FlxG.width * 0.75 - portrait.width * 0.5 + (dir < 0 ? -200 : 200);
		portrait.y = personTriangle.y + 10 - portrait.height;
		portrait.alpha = 0;
	}

	function openCategory(idx:Int) {
		borderTop.scrollText = listGrp.texts.members[idx].text + " • ";
		socials.useInputs = socials.useMouse = idx < categoryList.length - 1;
		listGrp.useInputs = false;
		listGrp.useMouse = !socials.useMouse;
		listGrp.selected = idx;
		selCategory = idx;

		thankTxt.members[curPerson].color = 0xFFFFFFFF;
		thankTxt.members[curPerson].font = Paths.font("Rockford-NTLG Light.ttf");
		if (idx == categoryList.length - 1) {
			changeThank(0);

			thankTxt.members[curPerson].color = 0xFF000000;
			thankTxt.members[curPerson].font = Paths.font("Rockford-NTLG Medium.ttf");

			lastDescHeight = thankDescBG.scale.y;
			thankDescTxt.text = curList[curPerson].role;
		} else {
			curPerson = 0;
			changePerson(0);
		}

		FlxG.sound.play(Paths.audio("popup_appear", 'sfx')); // combo sounds baybee
		FlxG.sound.play(Paths.audio("menu_toggle", 'sfx'));
	}

	override function update(delta:Float):Void {
		listGrp.x = FlxMath.lerp(listGrp.x, (socials.useInputs ? -60 : 20), delta * 15);
		listGrp.alpha = FlxMath.lerp(listGrp.alpha, (socials.useInputs ? 0 : 1), delta * 20);
		socials.x = FlxMath.lerp(socials.x, (socials.useInputs ? 20 : -60), delta * 15);
		socials.alpha = FlxMath.lerp(socials.alpha, (socials.useInputs ? 1 : 0), delta * 20);

		personTriangle.x = FlxMath.lerp(personTriangle.x, FlxG.width * 0.75 + (socials.useInputs ? 0 : 150), delta * 15);
		personTriangle.alpha = 1.0 - listGrp.alpha;
		personTriangle.angle += delta * 160;

		portrait.x = FlxMath.lerp(portrait.x, FlxG.width * 0.75 - portrait.width * 0.5, delta * 15);
		portrait.alpha = FlxMath.lerp(portrait.alpha, (socials.useInputs ? 1 : 0), delta * 20);

		buttonGroup.alpha = personTriangle.alpha;
		buttonGroup.y = borderBot.border.y + 58 + 30 * (1 - buttonGroup.alpha);
		super.update(delta);

		if (!Settings.data.reducedQuality) {
			lineShader.time.value[0] = SwirlBG.time / 64;
			thankTriangle.angle = listGrp.triangle.angle + 90;
		}
		bg.speed = FlxMath.lerp(bg.speed, 1.0, delta * 15.0);

		if (selCategory == categoryList.length - 1) {
			if (FlxG.mouse.screenX >= thankBG.x && FlxG.mouse.screenX <= thankBG.x + thankBG.width) {
				for (i => txt in thankTxt.members) {
					var height = 35 + 20 * ((txt.scale.y - 0.85) / 0.15);
					
					var top = txt.y + (txt.height - height) * 0.5;
					if (FlxG.mouse.screenY >= top && FlxG.mouse.screenY <= top + height) {
						changeThank(listGrp.mouseMoved ? i : curPerson);
						break;
					}
				}
			}
			
			final downJustPressed = Controls.justPressed("ui_down");

			if (downJustPressed || Controls.justPressed("ui_up")) {
				changeThank(FlxMath.wrap(curPerson + (downJustPressed ? 1 : -1), 0, curList.length - 1));
				FlxG.sound.play(Paths.audio("menu_move", "sfx"));
			}

			if (Controls.justPressed("back") || FlxG.mouse.justPressedRight) {
				FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));

				thankTxt.members[curPerson].color = 0xFFFFFFFF;
				thankTxt.members[curPerson].font = Paths.font("Rockford-NTLG Light.ttf");

				borderTop.scrollText = "SELECT A CATEGORY • ";
				listGrp.useInputs = true;
				selCategory = -1;
			}
		} else if (selCategory >= 0) {
			final leftJustPressed = Controls.justPressed("ui_left");

			if (leftJustPressed || Controls.justPressed("ui_right")) {
				changePerson(leftJustPressed ? -1 : 1);
				FlxG.sound.play(Paths.audio("menu_move", "sfx"));
			}

			if (Controls.justPressed("back") || FlxG.mouse.justPressedRight) {
				FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
				listGrp.useInputs = listGrp.useMouse = true;
				socials.useInputs = socials.useMouse = false;

				borderTop.scrollText = "SELECT A CATEGORY • ";
				bg.targetColor1 = 0xFF606060;
				bg.targetColor2 = 0xFFA0A0A0;
				selCategory = -1;
			}
		} else if (selCategory > -2 && (Controls.justPressed('back') || FlxG.mouse.justPressedRight)) {
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
			listGrp.useInputs = listGrp.useMouse = false;
			selCategory = -2;

			borderTop.transitionTween(false, 0, 0.25, function() {
				FlxG.switchState(new MainMenuState());
			});
		}

		thankBG.scale.y = FlxMath.lerp(thankBG.scale.y, (selCategory == categoryList.length - 1 ? thankBG.height : 0), delta * 20);
		thankDescBG.scale.x = 285 * (thankBG.scale.y / thankBG.height);
		@:privateAccess thankDescTxt.regenGraphic();
		if (thankDescBG.scale.x > 16) {
			thankDescTxt.clipGraphic(0, 0, Math.min(thankDescBG.scale.x - 15, thankDescTxt.graphic.width), thankDescTxt.fieldHeight);
			thankDescTxt.visible = true;
		} else
			thankDescTxt.visible = false;

		nameBG.scale.x = FlxMath.lerp(nameBG.scale.x, (selCategory >= 0 && selCategory < categoryList.length - 1) ? Math.max(nameTxt.width * nameTxt.scale.x, woke.width) + 35 : 0, delta * 20);
		@:privateAccess woke.regenGraphic();
		nameTxt.origin.x = 0;
		if (nameBG.scale.x > 16) {
			nameTxt.clipGraphic(0, 0, Math.min((nameBG.scale.x - 15) / nameTxt.scale.x, nameTxt.graphic.width), nameTxt.fieldHeight);
			woke.clipGraphic(0, 0, Math.min(nameBG.scale.x - 15, woke.graphic.width), woke.fieldHeight);
			nameTxt.visible = true;
			woke.visible = true;
		} else {
			nameTxt.visible = false;
			woke.visible = false;
		}

		descBG.scale.x = FlxMath.lerp(descBG.scale.x, (selCategory >= 0 && selCategory < categoryList.length - 1) ? descBG.width : 0, delta * 20);
		@:privateAccess descTxt.regenGraphic();
		if (descBG.scale.x > 16) {
			descTxt.clipGraphic(0, 0, Math.min(descBG.scale.x - 15, descTxt.graphic.width), descTxt.fieldHeight);
			descTxt.visible = true;
		} else
			descTxt.visible = false;

		curThankScroll = FlxMath.lerp(curThankScroll, thankScrollInc * curPerson, delta * 15);
		final thankMargin = (thankBG.y + thankBG.scale.y);
		var curY = thankBG.y + 25 - curThankScroll;
		for (i => txt in thankTxt.members) {
			txt.origin.x = 0;
			txt.scale.x = txt.scale.y = FlxMath.lerp(txt.scale.x, (i == curPerson ? 1.0 : 0.85), delta * 15);
			var scale = ((txt.scale.y - 0.85) / 0.15);
			txt.offset.x = -30 * scale;

			curY += 10 * scale;
			txt.y = curY;
			curY += 35 + 10 * scale;

			// clip it to the list.
			final top = txt.y + (txt.graphic.height - txt.graphic.height * txt.scale.y) * 0.5;
			final bot = top + txt.graphic.height * txt.scale.y;
			if (bot > thankBG.y + 5 && top < thankMargin - 5) {
				final topClip = Math.max(thankBG.y - top, 0);
				txt.clipGraphic(0, topClip / txt.scale.y, txt.graphic.width, txt.graphic.height - (Math.max(bot - thankMargin, 0) + topClip) / txt.scale.y);
				txt.offset.y = -topClip;
				txt.visible = true;
			} else
				txt.visible = false;
		}
		selThankScale = Math.min(Math.max(selThankScale + delta * (selCategory == categoryList.length - 1 ? 4 : -8), 0.0), 1.0);
		final easedScale = FlxEase.backOut(selThankScale);
		thankSel.scale.y = 55 * easedScale;
		thankTriangle.scale.x = thankTriangle.scale.y = 0.7 * FlxEase.cubeOut(selThankScale);
		thankDescBG.scale.y = FlxMath.lerp(lastDescHeight, thankDescTxt.height + 50, easedScale);

		if (thankTxt.length <= 0 || curPerson >= thankTxt.length) return;
		thankSel.y = thankTxt.members[curPerson].y + (thankTxt.members[curPerson].height - thankSel.height) * 0.5;
		thankTriangle.setPosition(
			thankSel.x + 20 + (30 + thankTxt.members[curPerson].offset.x),
			thankSel.y + (thankSel.height - thankTriangle.height) * 0.5
		);
	}
}
