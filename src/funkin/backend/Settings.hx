package funkin.backend;

import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

@:structInit
@:publicFields
class SaveVariables {
	// for readability/backwards compatability
	var downscroll(get, never):Bool;
	function get_downscroll():Bool return scrollDirection.toLowerCase() == 'down';

	// gameplay
	var scrollDirection:String = 'Up';
	var quantColouring:String = "None";
	var strumGlow:String = 'Per-Note';
	var scrollSpeed:Float = 3;
	var centeredNotes:Bool = false;
	var opponentNotes:Bool = true;
	var hideAcc:Bool = false;
	var comboTinting:String = 'Off';
	var ghostTapping:Bool = true;
	var metronome:Bool = false;
	var canReset:Bool = true;
	var noteOffset:Float = 0;
	var assistClaps:Bool = false;
	var accuracyType:String = 'Simple';
	var hitErrorBar:Bool = true;
	var modcharts:Bool = true;

	var customColumns:Array<FlxColor> = [0xFFED34A9, 0xFF9653D6, 0xFF596AF6, 0xFF69E4B5];
	var customQuants:Array<FlxColor> = [
		0xFFED34A9,
		0xFF596AF6,
		0xFF9653D6,
		0xFF69E4B5,
		0xFF9581A8,
		0xFF9653D6,
		0xFFFFFCA3,
		0xFF9653D6,
		0xFF52B6EB,
		0xFF9581A8,
		0xFF9581A8
	];

	// graphics (that affect performance)
	var framerate:ShortUInt = 60;
	var drawFramerate:Int = 60;
	var splitUpdate:Bool = true;
	var holdGrain:ByteUInt = 1;
	var antialiasing:Bool = true;
	var audioStreams:Bool = true;
	var reducedQuality:Bool = false;
	var shaders:Bool = true;
	var gpuCache:Bool = true;
	var fullscreen:Bool = #if mobile true #else false #end;
	var closeAnimation = true;
	var reflections:Bool = true;
	var videos:Bool = true;
	var disableVocals:Bool = false;

	// visuals (that don't affect performance)
	var flashingLights:Bool = true;
	var noteSkin:String = 'camv2';
	var noteSplashSkin:String = 'classic';
	var unglowOnAnimFinish:Bool = true;
	var gameVisibility:ByteUInt = 100;
	var cameraZooms:String = 'Default';
	var popupCenter:String = "Top";
	var judgementAlpha:Float = 1;
	var judgementCounter:Bool = false;
	var hideHighest:Bool = false;
	var comboAlpha:Float = 1;
	var healthBarAlpha:Float = 1;
	var language:String = 'English';
	var fpsCounter:Bool = true;
	var transitions:Bool = true;
	var timeBarType:String = 'Disabled';
	var hideHUD:Bool = false;
	var lyrics:Bool = true;
	var notesMoveCamera:Bool = true;

	// miscellaneous
	var discordRPC:Bool = true;
	var autoPause:Bool = true;

	//mobile 
	public var dynamicColors:Bool = true;
	public var needMobileControl:Bool = true; // work for desktop
	public var controlsAlpha:Float = 0.6;
	public var playControlsAlpha:Float = 0.2;
	public var screensaver:Bool = false;

	var gameplayModifiers:Map<String, Dynamic> = [
		'playbackRate' => 1.0,
		'instakill' => false,
		'onlySicks' => false,
		'noFail' => false,
		'botplay' => false,
		'mirroredNotes' => false,
		'randomizedNotes' => false,
		'modcharts' => false,
		'sustains' => true,
		'blind' => false,
		'playingSide' => 'Default'
	];

	// for addons
	var addonsOff:Array<String> = [];
}

class Settings {
	public static final default_data:SaveVariables = {};
	public static var data:SaveVariables = {};

	public static function save() {
		for (key in Reflect.fields(data)) {
			// ignores variables with getters
			if (Reflect.hasField(data, 'get_$key')) continue;
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		}

		FlxG.save.flush();
	}

	public static function load() {
		FlxG.save.bind('camellia', Util.getSavePath());

		final fields:Array<String> = Type.getInstanceFields(SaveVariables);
		for (i in Reflect.fields(FlxG.save.data)) {
			if (!fields.contains(i)) continue;

			if (Reflect.hasField(data, 'set_$i')) Reflect.setProperty(data, i, Reflect.field(FlxG.save.data, i));
			else Reflect.setField(data, i, Reflect.field(FlxG.save.data, i));
		}

		if (FlxG.save.data.framerate == null) {
			final refreshRate:ShortUInt = FlxG.stage.application.window.displayMode.refreshRate * 2;
			data.framerate = Std.int(FlxMath.bound(refreshRate * 2, 60, 1000));
		}

		if (FlxG.save.data.drawFramerate == null)
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.drawFramerate = Std.int(FlxMath.bound(refreshRate, 60, 360));
		}

		FlxG.stage.application.window.splitUpdate = data.splitUpdate;
		FlxG.stage.application.window.drawFrameRate = data.drawFramerate;
	
		if (FlxG.save.data.gameplayModifiers != null) {
			final map:Map<String, Dynamic> = FlxG.save.data.gameplayModifiers;
			for (name => value in map) data.gameplayModifiers.set(name, value);
		}

		#if DISCORD_ALLOWED DiscordClient.check(); #end
	}

	public static inline function reset(?saveToDisk:Bool = false) {
		data = {};
		if (saveToDisk) save();
	}

	public static function validate() {
		if (!funkin.backend.LanguageHandler.getLanguages().contains(data.language)) {
			data.language = "English";
			Sys.println("Invalid language! Resetting value in settings.");
		}

		if (!["Default", "Legacy", "Off"].contains(Settings.data.cameraZooms)) {
			Settings.data.cameraZooms = (Settings.data.cameraZooms.toLowerCase() == "false") ? "Off" : "Default";
			Sys.println("Recieved bool instead of string in camera zooms! Adjusting value in settings.");
		}

		final possibleNotesplashes: Array<String> = ['none'];
		for (splashPath in Paths.readDirectory("data/noteSplashes"))
			if (splashPath.endsWith(".json5") || splashPath.endsWith(".json")) {
				var splashName:String = haxe.io.Path.withoutDirectory(haxe.io.Path.withoutExtension(splashPath));
				if(possibleNotesplashes.contains(splashName)) continue;
				possibleNotesplashes.insert(0, splashName);
			}

		if (!possibleNotesplashes.contains(Settings.data.noteSplashSkin)) {
			Settings.data.noteSplashSkin = "classic";
			Sys.println("Note splash doesn't exist! Resetting value in settings.");
		}
	}
}
