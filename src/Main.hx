package;

import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import funkin.backend.LanguageHandler;
import funkin.backend.FPSCounter;
import funkin.backend.AwardCard;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;

import lime.app.Application;

#if android
import funkin.backend.AppData;
import sys.io.File;
#end

#if mobile
import funkin.mobile.states.CopyState;
#end

#if (linux && !debug)
@:cppInclude('../../../../src/_external/gamemode_client.h') // i don't care enough to properly point back to the src folder whatever it works fuck you
@:cppFileCode('#define GAMEMODE_AUTO')
#end
class Main extends Sprite {
	public static var fpsCounter:FPSCounter;
	public static var awardsCard:AwardCard;
	public static var keyboardInputs:Bool = true;
	public static var isClosing:Bool = false;
	public static var windowTween:FlxTween = null;
	/**
	 * Tween Manager that works regardless FlxG.timeScale
	 */
	public static var tweenManager:FlxTweenManager = null;

	public function new() {
		super();

		#if android
		SUtil.doPermissionsShit();
		#end

		funkin.mobile.backend.CrashHandler.init();

		#if mobile
		#if android
		if (!FileSystem.exists(AndroidEnvironment.getExternalStorageDirectory() + '/.' + Application.current.meta.get('file')))
			FileSystem.createDirectory(AndroidEnvironment.getExternalStorageDirectory() + '/.' + Application.current.meta.get('file'));
		#end
		Sys.setCwd(SUtil.getStorageDirectory());
		#end

		//Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		addChild(new FlxGame(InitState, 1280, 720, 60, true, true));
		
		addChild(fpsCounter = new FPSCounter(10, 10, 16));
		fpsCounter.visible = Settings.data.fpsCounter;
		addChild(awardsCard = new AwardCard());

		@:privateAccess FlxG.keys._nativeCorrection.set("0_43", FlxKey.PLUS);
	}

	override function __enterFrame(delta:Int) {
		super.__enterFrame(delta);

		if (isClosing) return;

		@:privateAccess
		FlxG.mouse.enabled = !FlxG.game._lostFocus;
	}

	public static function clearExceptWindow() {
		@:privateAccess if (FlxTween.globalManager == null || FlxTween.globalManager._tweens == null) return;

		@:privateAccess final twns = FlxTween.globalManager._tweens;

		for (tween in twns){
			if (tween == null || tween == windowTween) continue;

			tween.active = false;
			tween.destroy();
		}

		twns.splice(0, twns.length);

		if (windowTween != null)
			twns.push(windowTween);
	}

	#if windows
	// Get rid of hit test function because mouse memory ramp up during first move (-Bolo)
	@:noCompletion override function __hitTest(_, _, _, _, _, _):Bool return false;
	@:noCompletion override function __hitTestHitArea(_, _, _, _, _, _):Bool return false;
	@:noCompletion override function __hitTestMask(_, _):Bool return false;
	#end

	function onCrash(e:UncaughtErrorEvent):Void {
		e.preventDefault();
		e.stopImmediatePropagation();

		var errMsg:String = '${e.error}\n\n';
		var date:String = '${Date.now()}'.replace(":", "'");

		for (stackItem in CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(_, file, line, _): errMsg += 'Called from $file:$line\n';
				default: Sys.println(stackItem);
			}
		}

		errMsg += '\nExtra Info:\n';
		errMsg += 'Operating System: ${Util.getOperatingSystem()}\nTarget: ${Util.getTarget()}\n\n';

		final defines:Map<String, Dynamic> = _external.CompilerDefines.list;
		errMsg += 'Haxe: ${defines['haxe']}\nFlixel: ${defines['flixel']}\nOpenFL: ${defines['openfl']}\nLime: ${defines['lime']}';

		if (!FileSystem.exists('./crash/')) FileSystem.createDirectory('./crash/');

		File.saveContent('./crash/$date.txt', '$errMsg\n');
		Sys.println('\n$errMsg');
		lime.app.Application.current.window.alert(errMsg, "Error!");
		Sys.exit(1);
	}
}

class InitState extends flixel.FlxState {

	public static var ignoreCopy = false; //用于copystate，别删

	override function create():Void {

		cpp.vm.Gc.enable(true);
		cpp.vm.Gc.run(true);  

		#if mobile
		FlxG.mouse.visible = false;
		FlxG.fullscreen = true;
		#end
		
		#if mobile
		if (!CopyState.checkExistingFiles())
		{
			flixel.FlxG.switchState(new CopyState());
			return;
		}
		#end

		setDefines();

		#if android FlxG.android.preventDefaultKeys = [BACK]; #end

		#if android
			if (AppData.getVersionName() != Application.current.meta.get('version')
				|| AppData.getAppName() != Application.current.meta.get('file')                                                                                                                                                                  
				|| (AppData.getPackageName() != Application.current.meta.get('packageName')
					&& AppData.getPackageName() != Application.current.meta.get('packageName') + 'Backup1' // 共存
					&& AppData.getPackageName() != Application.current.meta.get('packageName') + 'Backup2' // 共存
					&& AppData.getPackageName() != 'com.antutu.ABenchMark' // 超频测试 安兔兔
					&& AppData.getPackageName() != 'com.ludashi.benchmark' // 超频测试 鲁大师
				)) {
					FlxG.switchState(new PirateState());
					return;
				}
		#end

		flixel.FlxG.switchState(new TitleState());
	}

	private function setDefines() {
		Main.tweenManager = new FlxTweenManager();
		Controls.load();
		Settings.load();
		Scores.load();
		DiscordClient.start();
		Addons.load();
		Awards.load();
		Meta.cacheFiles();
		funkin.modchart.ModchartManager.setupRedirects();
		LanguageHandler.loadTranslations();

		Settings.validate();
		LanguageHandler.setLanguage(Settings.data.language);

		FlxG.mouse.load(openfl.display.BitmapData.fromFile('assets/images/cursor.png'));

		FlxG.fullscreen = #if mobile true #else Settings.data.fullscreen #end;
		FlxG.fixedTimestep = false;
		FlxG.drawFramerate = FlxG.updateFramerate = Settings.data.framerate;
		FlxG.game.focusLostFramerate = Math.floor(Settings.data.framerate / 4);
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.cameras.useBufferLocking = true;
		FlxG.autoPause = Settings.data.autoPause;
		FlxAudioHandler.init();

		FlxG.signals.focusGained.add(()->{
			FlxAudioHandler.onFocus();
		});

		FlxG.signals.focusLost.add(()->{
			if (!FlxG.autoPause)
				return;
			FlxAudioHandler.onFocusLost();
		});

		FlxG.sound.volumeHandler = (v:Float) -> {
			FlxG.save.data.volume = v;
			FlxAudioHandler.volume = v;

			@:privateAccess
			FlxAudioHandler.music._audioBackend.updateVolume();

			for (al in FlxAudioHandler.audioList) {
				if (!al.exists) continue;
				@:privateAccess
				al._audioBackend.updateVolume();
			}
		}
		FlxG.sound.volumeUpKeys = Controls.binds["volume_up"];
		FlxG.sound.volumeDownKeys = Controls.binds["volume_down"];
		FlxG.sound.muteKeys = Controls.binds["volume_mute"];

		FlxG.signals.preUpdate.add(()->{
			Main.tweenManager.update(FlxG.elapsed/FlxG.timeScale);
		});

		FlxG.signals.preStateSwitch.add(()->{
			Conductor.reset();
			FlxAudioHandler.checkStoredSounds();
		});

		/*FlxG.stage.application.onExit.add(function(exitCode:Int)
		{
			FlxG.save.close();
		});*/ //yeah uhh... that should be with the code of the window close event

		FlxG.sound.volume = FlxG.save.data.volume ?? 1.0;
		FlxG.sound.muted = FlxG.save.data.muted ?? false;
		FlxG.sound.volumeHandler(FlxG.sound.muted ? 0 : FlxG.sound.volume);
		#if !mobile
		FlxG.game.soundTray.updateWithSettings();
		#end

		#if !debug
			cpp.NativeGc.enterGCFreeZone();
		#end

		openfl.Lib.application.window.onClose.add(function () {
			Main.isClosing = true;
			Main.keyboardInputs = false;
			FlxG.mouse.enabled = false;

			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.data.muted = FlxG.sound.muted;
			FlxG.save.flush();
			FlxG.save.close();

			if (FlxG.state is funkin.states.OptionsState) {
				Controls.save();
				Settings.save();
			}

			if(Settings.data.closeAnimation){
				openfl.Lib.application.window.onClose.cancel();
				FlxG.autoPause = false;
				//i'm killimg my ahh!!!! -blear
				// me too - rudy
				// why is this CAUSING MY GAME TO STOP RESPONDING!!! -neb
				// i don't have anything to add to this i just wanna participate -fox
				// ooh! me next! me next! i wanna add a comment too! -srt
				// hi guys i'm also here -tictacto
				// she strogan on my beef til i'm off -lno
				
				Conductor.stop();
				FlxG.sound.play(Paths.audio("byebye", 'sfx'));
				Main.windowTween = FlxTween.num(255, 0, 2, {ease: FlxEase.quadInOut, 
					onUpdate: tween -> {
						var curVal = Std.int(255 + (0 - 255) * tween.scale);
						funkin.backend.WindowUtils.setWindowOpacity(Std.int(curVal));}, 
					onComplete: tween -> Sys.exit(1)});
			}
        }, true);

		FlxG.signals.preStateSwitch.remove(FlxTween.globalManager.clear);
		FlxG.signals.preStateSwitch.add(Main.clearExceptWindow);

		FlxG.plugins.add(new funkin.backend.Conductor());
	}
}
