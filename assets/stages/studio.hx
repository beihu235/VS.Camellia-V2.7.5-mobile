// import flixel.FlxSprite;
// this is to have more control over the stage
var city:FunkinSprite;
var wall:FunkinSprite;
var floor:FunkinSprite;
var camlight:FunkinSprite;
var camlightray:FunkinSprite;
var bflight:FunkinSprite;
var bflightray:FunkinSprite;
var song:String;

function create()
{
	song = songID;
	// trace(song);

	city = new FunkinSprite(250, -250).loadGraphic(Paths.image('stages/studio/city'));
	city.setGraphicSize(Std.int(city.width * 1.1));
	game.addBehindObject(city, game.characters);

	wall = new FunkinSprite(0, -400).loadGraphic(Paths.image('stages/studio/wall'));
	wall.color = 0xFFFE00AF;
	wall.setGraphicSize(Std.int(wall.width * 1.15));
	game.addBehindObject(wall, game.characters);

	floor = new FunkinSprite(0, 400).loadGraphic(Paths.image('stages/studio/floor'));
	floor.color = 0xFFAC35B3;
	floor.setGraphicSize(Std.int(floor.width * 1.15));
	game.addBehindObject(floor, game.characters);

	if (!Settings.data.reducedQuality)
	{
		camlight = new FunkinSprite(200, 410).loadGraphic(Paths.image('stages/studio/camellia glow light'));
		camlight.color = 0xFF4E0E52;
		camlight.setGraphicSize(Std.int(floor.width * 0.35));
		camlight.blend = 0;
		game.addBehindObject(camlight, game.characters);

		camlightray = new FunkinSprite(200, 250).loadGraphic(Paths.image('stages/studio/camellia glow lightray'));
		camlightray.color = 0xFF4B164E;
		camlightray.setGraphicSize(Std.int(floor.width * 0.35));
		camlightray.blend = 0;
		game.add(camlightray, game.characters);

		bflight = new FunkinSprite(1250, 450).loadGraphic(Paths.image('stages/studio/bf glow light'));
		bflight.color = 0xFF3D0B41;
		bflight.setGraphicSize(Std.int(floor.width * 0.17));
		bflight.blend = 0;
		game.addBehindObject(bflight, game.characters);

		bflightray = new FunkinSprite(1250, 345).loadGraphic(Paths.image('stages/studio/bf glow lightray'));
		bflightray.color = 0xFF822686;
		bflightray.setGraphicSize(Std.int(floor.width * 0.20));
		bflightray.blend = 0;
		game.add(bflightray, game.characters);
	}

	// TODO
	// reflections are fucked up on scales other than 1
	// just gonna do this for now because it's more correct
	game.bf.setGraphicSize(Std.int(game.bf.width * 0.75));
	game.bf.updateHitbox();
	game.dad.setGraphicSize(Std.int(game.dad.width * 0.75));
	game.dad.updateHitbox();
	game.gf.setGraphicSize(Std.int(game.gf.width * 0.75));
	game.gf.updateHitbox();

	closeFile();
}
