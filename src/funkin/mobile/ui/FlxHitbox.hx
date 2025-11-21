package funkin.mobile.ui;

import funkin.mobile.ui.input.FlxMobileInputManager;
import openfl.display.BitmapData;
import funkin.mobile.ui.FlxButton;
import openfl.display.Shape;
import funkin.mobile.ui.input.FlxMobileInputID;
import funkin.states.PlayState;
import flixel.util.FlxColor;

import openfl.Lib;

/**
 * A zone with dynamic hint's based on mania.
 * 
 * @author: Mihai Alexandru
 * @modification's author: Karim Akra & Lily (mcagabe19)
 */
class FlxHitbox extends FlxMobileInputManager
{
	public var buttonNotes:Array<FlxButton> = [];
	public var buttonExtra1:FlxButton = new FlxButton(0, 0);
	public var buttonExtra2:FlxButton = new FlxButton(0, 0);
	public var buttonExtra3:FlxButton = new FlxButton(0, 0);
	public var buttonExtra4:FlxButton = new FlxButton(0, 0);

	var storedButtonsIDs:Map<String, Array<FlxMobileInputID>> = new Map<String, Array<FlxMobileInputID>>();

	/**
	 * Create the zone.
	 */
	public function new()
	{
		super();

		var stage = Lib.current.stage;

		for (button in Reflect.fields(this))
		{
			if (Std.isOfType(Reflect.field(this, button), FlxButton))
			{
				storedButtonsIDs.set(button, Reflect.getProperty(Reflect.field(this, button), 'IDs'));
			}
		}

		for (i in 0...4)
		{
			var button = createHint(FlxG.width * i / 4, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height), getColor(i));
			buttonNotes.push(button);
			add(button);
		}

		// Assign input IDs to main keys
		for (i in 0...buttonNotes.length)
		{
			buttonNotes[i].IDs = [getInputID(i)];
		}

		// Assign input IDs to extra buttons
		for (button in Reflect.fields(this))
		{
			if (Std.isOfType(Reflect.field(this, button), FlxButton))
			{
				Reflect.setProperty(Reflect.getProperty(this, button), 'IDs', storedButtonsIDs.get(button));
			}
		}

		scrollFactor.set();
		updateTrackedButtons();
	}

	/**
	 * Get input ID based on index
	 */
	private function getInputID(index:Int):FlxMobileInputID
	{
		return switch (index) {
			case 0: FlxMobileInputID.noteLEFT;
			case 1: FlxMobileInputID.noteDOWN; 
			case 2: FlxMobileInputID.noteUP;
			case _: FlxMobileInputID.noteRIGHT;
		}
	}

	/**
	 * Get color for key based on index and mania
	 */
	private function getColor(index:Int):Int
	{
		// 动态颜色设置优先
		if (Settings.data.dynamicColors)
		{		
			return Settings.data.customColumns[index];
		} else {
			return Settings.default_data.customColumns[index];
		}
	}

	/**
	 * Clean up memory.
	 */
	override function destroy()
	{
		super.destroy();

		for (button in buttonNotes)
		{
			button = FlxDestroyUtil.destroy(button);
		}
	}

	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):FlxButton
	{
		var hint = new FlxButton(X, Y);
		hint.loadGraphic(createHintGraphic(Width, Height));
		hint.color = Color;
		hint.solid = false;
		hint.immovable = true;
		hint.multiTouch = true;
		hint.moves = false;
		hint.scrollFactor.set();
		hint.alpha = 0.5;
		hint.antialiasing = Settings.data.antialiasing;
		
		if (Settings.data.playControlsAlpha >= 0)
		{
			hint.onDown.callback = function()
			{
				hint.alpha = Settings.data.playControlsAlpha;
			}
			hint.onUp.callback = function()
			{
				hint.alpha = 0.00001;
			}
			hint.onOut.callback = function()
			{
				hint.alpha = 0.00001;
			}
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	function createHintGraphic(Width:Int, Height:Int):BitmapData
	{
		var shape:Shape = new Shape();

		var guh = Settings.data.playControlsAlpha;
		if (guh >= 0.9)
			guh = Settings.data.playControlsAlpha - 0.07;

		shape.graphics.beginFill(0xFFFFFF);
		shape.graphics.lineStyle(3, 0xFFFFFF, 1);
		shape.graphics.drawRect(0, 0, Width, Height);
		shape.graphics.lineStyle(0, 0, 0);
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}
}
