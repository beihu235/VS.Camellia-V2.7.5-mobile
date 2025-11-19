//import flixel.FlxSprite;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
//import funkin.backend.Util;

//import funkin.objects.Speakers;

var sky:FunkinSprite;
var buildings:FunkinSprite;
var jumpscare:FunkinSprite;
var crowdL:FunkinSprite;
var crowdR:FunkinSprite;
var crowdFront:FunkinSprite;
var crowdActive:Bool = true;
var stage:FunkinSprite;

//speakers
var speakerLB:Speakers;
var speakerRB:Speakers;

var stageLQ:FunkinSprite;

//lights control
var autolights:Bool = true;
var slowlights:Bool = false;

var song:String;
var stageMade:Bool = false;

final colors:Array<Int> = [0xff00b1ff, 0xffff432c, 0xffff30fa, 0xff00fd86, 0xffffa71f];

function create(){
	if (Settings.reducedQuality) {
		stageLQ = new FunkinSprite(0, 0).loadGraphic(Paths.image('stages/concert/stageLQ'));
		game.addBehindObject(stageLQ, game.characters);
		closeFile();
		return;
	}

	song = songID;
	 
	sky = new FunkinSprite(-230, -80).loadGraphic(Paths.image('stages/concert/sky'));
	sky.setGraphicSize(Std.int(sky.width*1.75));
	game.addBehindObject(sky, game.characters);

	buildings = new FunkinSprite(-220, -80).loadGraphic(Paths.image('stages/concert/light'));
	buildings.setGraphicSize(Std.int(buildings.width*1.75));
	game.addBehindObject(buildings, game.characters);
	concertLights();

	if (FlxG.random.bool(10)){
		jumpscare = new FunkinSprite(250, -50).loadGraphic(Paths.image('stages/concert/camelliaJumpscare'));
		jumpscare.setGraphicSize(Std.int(jumpscare.width*1.5));
		game.addBehindObject(jumpscare, game.characters);
	}

	crowdL = new FunkinSprite(-725, 400).loadGraphic(Paths.image('stages/concert/backcrowdleft'));
	crowdL.setGraphicSize(Std.int(crowdL.width*1.75));
	game.addBehindObject(crowdL, game.characters);

	crowdR = new FunkinSprite(2025, 400).loadGraphic(Paths.image('stages/concert/backcrowdright'));
	crowdR.setGraphicSize(Std.int(crowdR.width*1.75));
	game.addBehindObject(crowdR, game.characters);

	stage = new FunkinSprite(-215, -120).loadGraphic(Paths.image('stages/concert/stage'));
	stage.setGraphicSize(Std.int(stage.width*1.75));
	game.addBehindObject(stage, game.characters);

	speakerLB = new Speakers(-450, -50, false);
	game.addBehindObject(speakerLB, game.characters);

	speakerRB = new Speakers(1050, -50, true);
	game.addBehindObject(speakerRB, game.characters);
	//1500 --690 should show them
	crowdFront = new FunkinSprite(-220, 1500).loadGraphic(Paths.image('stages/concert/frontcrowd'));
	crowdFront.setGraphicSize(Std.int(crowdFront.width*1.75));
	game.add(crowdFront);

	stageMade = true;
}

// hahahahah funy brithiaSHUT THUP SHUT HTE UFKC UP
var colours:Array<Int> = [0xFF00AFFF, 0xFFFF4434, 0xFFFF34F4, 0xFF34FC8C, 0xFFFFA434];
var curColourIndex:Int = 0;
function concertLights() {
	curColourIndex = FlxG.random.int(0, colours.length - 1, [curColourIndex]);
	buildings.color = colours[curColourIndex];
}

function slowLights(){
	curColourIndex = FlxG.random.int(0, colours.length - 1, [curColourIndex]);
    FlxTween.cancelTweensOf(buildings);
    FlxTween.color(buildings, 0.5, buildings.color, colours[curColourIndex]);
}

function beatHit(beat:Int) {
	if (beat % 2 == 0 && stageMade) {

		speakerLB.boop();
		speakerRB.boop();

		if (crowdActive) {
			for (crowd in [crowdL, crowdR, crowdFront]) {
				var first = FlxTween.tween(crowd.scale, {x: 1.8, y: 1.9}, 0.05);
				first.addChainedTween(FlxTween.tween(crowd.scale, {x: 1.75, y: 1.75}, 0.125));
			}
		}
	}
}

function measureHit(measure:Int) {
	if (!stageMade) return;

	if (autolights) {
		if(slowlights)
			slowlights();
		else
			concertLights();
	}
}

function eventTriggered(name:String, args:Array<Dynamic>){
	switch (name){
		case "camelliazoom":
			game.isZooming = true;
			concertZoom(Math.isNaN(args[0]) ? 2 : args[0],  Math.isNaN(args[1]) ? 1 : args[1]);
		case "lightcolorchangemode":
			slowlights = !slowlights;
		default: return;
	}
}

function concertZoom(zoomType:Int = 2, time:Float = 1/*, easing:String*/) {
	var zoomgame:Float;
	//var zoomhud:Float;
	switch(zoomType) {
		case 1:
			zoomgame = 0.41;
			zoomhud = 0.8;
			crowdActive = true;
		case 2:
			zoomgame = 0.59;
			zoomhud = 1;
			crowdActive = false;
		case 3:
			zoomgame = 0.47;
			zoomhud = 0.9;
			crowdActive = true;
		default:
			zoomgame = 0.59;
			zoomhud = 1;
			crowdActive = false;
	}

	FlxTween.tween(game.camGame, {zoom: zoomgame}, time, {ease:FlxEase.quadInOut, 
		onComplete: t -> {
			game.defaultCamZoom = zoomgame;
			game.isZooming = false;
		}
	});

	if (Settings.data.cameraZooms.toLowerCase() == 'legacy') {
		FlxTween.tween(game.camHUD, {zoom: zoomhud}, time, {ease: FlxEase.quadInOut,
			onComplete: _ -> game.defaultHudZoom = zoomhud
		});
	}

	//crowd tween
	if (crowdActive)
		FlxTween.tween(crowdFront, {y: 690}, time, {ease: FlxEase.quadInOut});
	else
		FlxTween.tween(crowdFront, {y: 1500}, time, {ease: FlxEase.quadInOut});
}