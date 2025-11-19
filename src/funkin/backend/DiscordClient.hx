package funkin.backend;

import sys.thread.Thread;
import lime.app.Application;
import flixel.util.FlxStringUtil;

#if (cpp && DISCORD_ALLOWED)
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

class DiscordClient {
	public static var started:Bool = false;
	inline static final default_gameID:String = "1340757629622026270";
	public static var gameID(default, set):String = default_gameID;
	static var _app:DiscordApp = new DiscordApp();
	// hides this field from scripts and reflection in general
	@:unreflective static var _thread:Thread;

	#if IS_TESTBUILD
	public static final testers:Array<String> = [
		'rudyrue',
		'srtpro278',
		'blearchipmunk',
		'literallynoone',
		'foxeru'
	];
	public static var username:String = '';
	#end

	public static function check() {
		#if IS_TESTBUILD
		start();
		#else
		if (Settings.data.discordRPC) start();
		else if (started) stop();
		#end
	}

	public dynamic static function stop() {
		started = false;
		Discord.Shutdown();
	}
	
	static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		#if IS_TESTBUILD
		username = request[0].username;
		#end
		Sys.println('(Discord) Connected to user "${request[0].username}"');
		changePresence();
	}

	static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		Sys.println('(Discord): Error ($errorCode: $message)');
	}

	static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		Sys.println('(Discord): Disconnected ($errorCode: $message)');
	}

	public static function start() {
		//trace('hello im starting');
		#if IS_TESTBUILD
		if (started) return;
		#else
		if (started || !Settings.data.discordRPC) return;
		#end
		//trace('i did it');

		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(gameID, cpp.RawPointer.addressOf(discordHandlers), 1, null);

		if (!started) Sys.println("(Discord): Client connected.");

		if (_thread == null) {
			_thread = Thread.create(() -> {
				while (true) {
					if (started) {
						#if DISCORD_DISABLE_IO_THREAD
						Discord.UpdateConnection();
						#end
						Discord.RunCallbacks();
					}

					// Wait 2 seconds until the next loop...
					Sys.sleep(2.0);
				}
			});
		}
		started = true;

		Application.current.window.onClose.add(function() {
			if (!started) return;
			stop();
		});
	}

	//this will be changed on a newer commit to prevent leaks from testing -blear
	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float, largeImageKey:String = 'icon') {
		if (!started) return;

		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		_app.state = state;
		_app.details = details;
		_app.smallImageKey = smallImageKey;
		_app.largeImageKey = largeImageKey;
		_app.largeImageText = '';
		// obtained times are in milliseconds
		// we convert them into seconds so that discord can show them properly
		_app.startTimestamp = Std.int(startTimestamp * 0.001);
		_app.endTimestamp = Std.int(endTimestamp * 0.001);
		updatePresence();
	}

	public static function updatePresence() {
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(_app._presence));
	}
	
	inline public static function resetGameID() {
		gameID = default_gameID;
	}

	static function set_gameID(newID:String):String {
		var changed:Bool = gameID != newID;
		gameID = newID;

		if (changed && started) {
			stop();
			start();
			updatePresence();
		}
		return newID;
	}
}

@:allow(funkin.backend.DiscordClient)
private final class DiscordApp {
	public var state(get, set):String;
	public var details(get, set):String;
	public var smallImageKey(get, set):String;
	public var largeImageKey(get, set):String;
	public var largeImageText(get, set):String;
	public var startTimestamp(get, set):Int;
	public var endTimestamp(get, set):Int;

	@:noCompletion private var _presence:DiscordRichPresence;

	function new() {
		_presence = DiscordRichPresence.create();
	}

	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("state", state),
			LabelValuePair.weak("details", details),
			LabelValuePair.weak("smallImageKey", smallImageKey),
			LabelValuePair.weak("largeImageKey", largeImageKey),
			LabelValuePair.weak("largeImageText", largeImageText),
			LabelValuePair.weak("startTimestamp", startTimestamp),
			LabelValuePair.weak("endTimestamp", endTimestamp)
		]);
	}

	@:noCompletion inline function get_state():String return _presence.state;
	@:noCompletion inline function set_state(value:String):String return _presence.state = value;

	@:noCompletion inline function get_details():String return _presence.details;
	@:noCompletion inline function set_details(value:String):String return _presence.details = value;

	@:noCompletion inline function get_smallImageKey():String return _presence.smallImageKey;
	@:noCompletion inline function set_smallImageKey(value:String):String return _presence.smallImageKey = value;

	@:noCompletion inline function get_largeImageKey():String return _presence.largeImageKey;
	@:noCompletion inline function set_largeImageKey(value:String):String return _presence.largeImageKey = value;

	@:noCompletion inline function get_largeImageText():String return _presence.largeImageText;
	@:noCompletion inline function set_largeImageText(value:String):String return _presence.largeImageText = value;

	@:noCompletion inline function get_startTimestamp():Int return _presence.startTimestamp;
	@:noCompletion inline function set_startTimestamp(value:Int):Int return _presence.startTimestamp = value;

	@:noCompletion inline function get_endTimestamp():Int return _presence.endTimestamp;
	@:noCompletion inline function set_endTimestamp(value:Int):Int return _presence.endTimestamp = value;
}
#else
class DiscordClient {
	public static var started:Bool = false;
	inline static final default_gameID:String = "";
	public static var gameID(default, set):String = default_gameID;
	static var _app:DiscordApp = new DiscordApp();
	@:unreflective static var _thread:Thread;

	public static function check() {}
	public dynamic static function stop() {}
	
	static function onReady(_):Void {}
	static function onError(_, _):Void {}
	static function onDisconnected(_, _):Void {}

	public static function start() {}
	public static function changePresence(_, _g, _, _, _, _) {}
	public static function updatePresence() {}
	inline public static function resetGameID() gameID = default_gameID;
	static function set_gameID(newID:String):String return gameID = newID;
}

@:allow(funkin.backend.DiscordClient)
private final class DiscordApp {
	public var state:String = '';
	public var details:String = '';
	public var smallImageKey:String = '';
	public var largeImageKey:String = '';
	public var largeImageText:String = '';
	public var startTimestamp:Int;
	public var endTimestamp:Int;

	@:noCompletion private var _presence:Dynamic;

	function new() {}
}
#end