package funkin.objects;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import funkin.backend.Judgement;
import funkin.backend.Util;
import flixel.graphics.FlxGraphic;

using StringTools;

/**
 *
 * HitErrorBar like OSU!! 
 * @author BoloVEVO
 *
**/
class HitErrorBar extends FlxSpriteGroup
{
	var trianglePointer:FlxSprite;

	var timingBar:FlxSprite;

	var widthArray:Array<Float> = [];

	var currentMS:Float = 0;

	var lastMS:Float = 0;

	var middleLine:FlxSprite;

	var hitNotesGroup:FlxTypedSpriteGroup<NoteHitBar>;

	var missHitNote:NoteHitBar;

	var triangleRawPosition:Float;

	var alphaTime:Float = 0;

	public var curVisibleBars:Int = 0;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		this.x = x;
		this.y = y;
		this.alpha = 0.4;

		for (i in 0...Judgement.list.length * 2)
		{
			var id = i;
			if (id >= Judgement.list.length)
				id -= Judgement.list.length;
            
			widthArray[i] = i < Judgement.list.length ? Judgement.list[Judgement.list.length-id-1].timing
				- (Judgement.list[Judgement.list.length-id-2] != null ? Judgement.list[Judgement.list.length-id-2].timing : 0) : Judgement.list[id].timing
					- (Judgement.list[id-1] != null ? Judgement.list[id-1].timing: 0);
		}

		var totalWidth = 0.0;
		for (i in widthArray)
			totalWidth += i;

		var judgeLine:BitmapData = new BitmapData(Std.int(totalWidth), 5, true);

		var daOffset = 0.0;

		for (i in 0...Judgement.list.length * 2) 
		{
			var id = i;
			if (id >= Judgement.list.length)
				id -= Judgement.list.length;

			final shitWidth = widthArray[i];
            final curColor:FlxColor = i < Judgement.list.length ? Judgement.list[Judgement.list.length-id-1].color : Judgement.list[id].color;

			judgeLine.fillRect(new openfl.geom.Rectangle(daOffset, 0, shitWidth, 5),
				curColor);
			daOffset += widthArray[i];
		}

		timingBar = new FlxSprite().loadGraphic(FlxGraphic.fromBitmapData(judgeLine, false, "judgeLine"));

		timingBar.setGraphicSize(300, 5); // Set to a determined scale to don't have a large timing bar because of really high timings.

		timingBar.updateHitbox();

		trianglePointer = new FlxSprite((timingBar.x + timingBar.width / 2) - 5, 0).makeGraphic(10, 10, FlxColor.TRANSPARENT);

		FlxSpriteUtil.drawTriangle(trianglePointer, 0, 0, 10, FlxColor.WHITE, {thickness: 0, color: FlxColor.WHITE}, {smoothing: true});

		trianglePointer.scale.set(1, 0.65);
		trianglePointer.updateHitbox();
		trianglePointer.moves = false;
        trianglePointer.visible = true;

		trianglePointer.antialiasing = FlxG.save.data.antialiasing;

		middleLine = new FlxSprite((timingBar.x + timingBar.width / 2) - 1.5, -10.5).makeGraphic(3, 25, FlxColor.WHITE);

		updatePointerFlip();
		trianglePointer.alpha = 0.7;

		add(timingBar);

		hitNotesGroup = new FlxTypedSpriteGroup<NoteHitBar>(0, 0, 0);

		for (i in 0...hitNotesGroup.maxSize + 1)
		{
			final dummyBar = new NoteHitBar(this, (timingBar.x + timingBar.width / 2) - 1.5, -10.5);

			dummyBar.makeGraphic(3, 18, FlxColor.WHITE);

			dummyBar.moves = false;

			hitNotesGroup.insert(0, dummyBar);

			dummyBar.kill();
		}

		missHitNote = new NoteHitBar(this, timingBar.x + timingBar.width - 1.5, -10.5);
		missHitNote.makeGraphic(3, 18, FlxColor.WHITE);
		missHitNote.visible = false;
		missHitNote.moves = false;
		missHitNote.kill();

		curVisibleBars = 0;

		add(middleLine);
		add(trianglePointer);
		add(missHitNote);

		add(hitNotesGroup);
	}

	public function updatePointerFlip()
	{
		if (Settings.data.downscroll)
		{
			trianglePointer.flipY = true;
			trianglePointer.y = -12;
		}
		else
		{
			trianglePointer.flipY = false;
			trianglePointer.y = 12.5;
		}

		trianglePointer.alpha = 0.7;
	}

	var trianglePos:Float = 0;

	override function update(elapsed:Float)
	{
		if (trianglePointer.visible)
		{
			var rawPos = FlxMath.remapToRange((timingBar.x + timingBar.width / 2)
				+ currentMS, (timingBar.x + timingBar.width / 2),
				(timingBar.x + timingBar.width / 2)
				+ Judgement.max.timing, (timingBar.x + timingBar.width / 2), timingBar.x
				+ timingBar.width)
				- 5;

			trianglePos = rawPos;

			trianglePointer.x = Util.expDecay(trianglePointer.x, rawPos, 7.5);
		}

		if (timingBar.visible)
			if (curVisibleBars <= 0)
				if (timingBar.alpha > 0.4)
					timingBar.alpha -= 0.1 * elapsed;
	}

	public function registerHit(noteMS:Float)
	{
		lastMS = currentMS;
		currentMS = noteMS;

		alphaTime = 0;
		timingBar.alpha = 0.7;
		trianglePointer.alpha = 0.7;

		var barPos = FlxMath.remapToRange((timingBar.x + timingBar.width / 2)
			+ currentMS, (timingBar.x + timingBar.width / 2),
			(timingBar.x + timingBar.width / 2)
			+ Judgement.max.timing, (timingBar.x + timingBar.width / 2), timingBar.x
			+ timingBar.width)
			- 1.5;

		final hitBar:NoteHitBar = hitNotesGroup.recycle(NoteHitBar, generateNewHitBar);
        hitBar.loadGraphic(hitNotesGroup.members[0].graphic);
		hitBar.camera = camera;
		hitBar.setPosition(barPos, y - 7);
	}

    private function generateNewHitBar()
    {
        return new NoteHitBar(this, (timingBar.x + timingBar.width / 2) - 1.5, -10.5);
    }

	public function registerMiss()
	{
		alphaTime = 0;
		timingBar.alpha = 0.7;
		trianglePointer.alpha = 0.7;

        lastMS = currentMS;
		currentMS = Judgement.max.timing;

		triangleRawPosition = timingBar.x + timingBar.width - 1.5;
		missHitNote.revive();
        missHitNote.visible = true;
		missHitNote.setPosition(timingBar.x + timingBar.width - 1.5, y - 7);
	}

	override function destroy()
	{
		widthArray.splice(0, widthArray.length);

		super.destroy();
	}
}

class NoteHitBar extends FlxSprite
{
	public var existTime:Float = 0;

	var errorBar:HitErrorBar;

	public function new(errorBar:HitErrorBar, x:Float, y:Float)
	{
		super(x, y);
		this.errorBar = errorBar;
	}

	override function draw()
	{
		super.draw();

		existTime += FlxG.elapsed * 1000;
		if (existTime > 1000)
			alpha -= 0.1 * FlxG.elapsed;

		if (alpha <= 0.001)
			kill();
	}

	override function revive()
	{
		visible = true;
		alpha = 0.7;
		if (!alive)
			errorBar.curVisibleBars++;
		super.revive();
	}

	override function kill()
	{
		visible = false;
		existTime = 0;
		super.kill();

		errorBar.curVisibleBars--;
	}

	override function destroy()
	{
		super.destroy();
		errorBar = null;
	}
}
