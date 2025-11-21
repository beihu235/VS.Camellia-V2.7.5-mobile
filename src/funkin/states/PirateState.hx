package funkin.states;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import openfl.Lib;

class PirateState extends FunkinState
{
	var warnText:FlxText;

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		var guh:String = "
		This is pirate version
		You are banned from entering the game
		please use the legitimate version\n
        ";
		warnText = new FlxText(0, 0, FlxG.width, guh, 32);
		warnText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.RED, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

		addVirtualPad(NONE, A);
	}

	override function update(elapsed:Float)
	{
		if (Controls.pressed('accept'))
			Util.openURL('https://github.com/beihu235/VS.Camellia-V2.7.5-mobile');

		super.update(elapsed);
	}
}
