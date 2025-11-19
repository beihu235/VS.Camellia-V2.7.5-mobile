package flixel.system.ui;

// shadowing so it doesnt do all that default shpizz with super.

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.geom.Rectangle;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
#if flash
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
#end

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps ease the bar.
	 */
	var _scaleTime:Float = 0;

	/**
	 * In tandum with easing. The starting point of the bar.
	 */
	var _scaleStart:Float = 1;

	/**
	 * Creates contrast for easier volume readability.
	 */
	var bg:Bitmap;

	/**
	 * Extra flare for the volume bar.
	 */
	var icon:Bitmap;

	/**
	 * The clipping rect for the icon.
	 */
	var iconRect:Rectangle;

	/**
	 * Helps indicate what percentage of the volume isnt being used.
	 */
	var barEmpty:Bitmap;

	/**
	 * Helps display the current volume on the sound tray.
	 */
	var barFill:Bitmap;

	/**
	 * A text representation of your current volume.
	 */
	var text:TextField;

	/**
	 * How wide the sound tray background is.
	 */
	var _width:Int = 490;

	var _defaultScale:Float = 1.25;

	/**The sound used when increasing the volume.**/
	public var volumeUpSound:String = "assets/sfx/menu_setting_tick";

	/**The sound used when decreasing the volume.**/
	public var volumeDownSound:String = 'assets/sfx/menu_setting_tick';

	/**Whether or not changing the volume should make noise.**/
	public var silent:Bool = false;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		bg = new Bitmap(new BitmapData(_width, 20, true, 0x7F000000));
		screenCenter();
		addChild(bg);
        bg.__transform.c = Math.tan(-30 * flixel.math.FlxAngle.TO_RAD);

		icon = new Bitmap(BitmapData.fromFile("assets/images/volume.png"));
		iconRect = new Rectangle(0, 0, 30, 25);
		icon.scrollRect = iconRect;
		icon.x = 3;
		icon.y = 3;
		icon.scaleX = icon.scaleY = 0.5;
		icon.smoothing = Settings.data.antialiasing;
		addChild(icon);

		barEmpty = new Bitmap(new BitmapData(_width - 100, 10, true, 0x80FFFFFF));
		barEmpty.x = 30;
		barEmpty.y = 5;
		addChild(barEmpty);
        barEmpty.__transform.c = bg.__transform.c;

		barFill = new Bitmap(new BitmapData(_width - 100, 10, true, 0xFFFFFFFF));
		barFill.x = 30;
		barFill.y = 5;
		addChild(barFill);
        barEmpty.__transform.c = bg.__transform.c;

		text = new TextField();
		text.width = bg.width;
		text.height = bg.height;
		text.multiline = true;
		text.wordWrap = true;
		text.selectable = false;
		text.embedFonts = true;

		#if flash
		text.antiAliasType = AntiAliasType.NORMAL;
		text.gridFitType = GridFitType.PIXEL;
		#else
		#end

		var dtf:TextFormat = new TextFormat(Paths.font("Rockford-NTLG Medium.ttf"), 12, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "?%";
		text.x = _width * 0.5 - 45;
		text.y = 2.5;

		y = -height;
		visible = false;
	}

	/**
	 * This function updates the soundtray object.
	 */
	public function update(delta:Float):Void
	{
		delta *= 0.001;

		if (_scaleTime < 1) {
			_scaleTime = Math.min(_scaleTime + delta * 4, 1);
			barFill.scaleX = FlxMath.lerp(_scaleStart, FlxG.sound.volume, FlxEase.quartOut(_scaleTime));
			barFill.__transform.c = bg.__transform.c;
		}
		
		// Animate sound tray thing
		if (_timer > -0.25) {
			_timer = Math.max(_timer - delta, -0.25);

			y = FlxMath.lerp(10, -height, FlxEase.quartOut(Math.max(-_timer * 4, 0)));

			if (_timer <= -0.25) {
				visible = false;
				active = false;
				// Sound saving should be handled through exiting.
			}
		}
	}

	public function updateWithSettings() {
		icon.smoothing = Settings.data.antialiasing;

		barFill.scaleX = FlxG.sound.volume;
		barFill.visible = !FlxG.sound.muted;
		barFill.__transform.c = bg.__transform.c;

		if (FlxG.sound.muted)
			text.text = "MUTE";
		else
			text.text = Math.round(FlxG.sound.volume * 100) + "%";

		iconRect.x = (FlxG.sound.muted || FlxG.sound.volume < 0.025) ? 30 : 0;
		icon.scrollRect = iconRect;
	}

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public function show(up:Bool = false):Void
	{
		if (!silent)
		{
			var sound = openfl.media.Sound.fromFile('${up ? volumeUpSound : volumeDownSound}.ogg');
			if (sound != null) {
				var snd = FlxG.sound.load(sound).play();
				snd.onComplete = sound.close;
			}
		}

		_timer = 1.25;
		y = 10;
		icon.smoothing = Settings.data.antialiasing;
		visible = true;
		active = true;

		_scaleStart = barFill.scaleX;
		_scaleTime = 0;

		barFill.visible = !FlxG.sound.muted;
		if (FlxG.sound.muted)
			text.text = "MUTE";
		else
			text.text = Math.round(FlxG.sound.volume * 100) + "%";

		iconRect.x = (FlxG.sound.muted || FlxG.sound.volume < 0.025) ? 30 : 0;
		icon.scrollRect = iconRect;
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end
