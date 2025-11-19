package funkin.backend;

#if SCRIPTS_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import funkin.states.PlayState;

class ScriptHandler {
	public static var list:Array<Script> = [];

	public static function loadFromDir(path:String, ?subFolders:Bool = false):Void {
		
		var directories:Array<String> = ['assets'];

		#if ADDONS_ALLOWED
		for (addon in Addons.list) {
			if (!addon.disabled)
				directories.push('addons/${addon.id}');
		}
		#end

		for (directory in directories) {
			if (!FileSystem.exists('$directory/$path')) continue;

			for (file in FileSystem.readDirectory('$directory/$path')) {
				final absPath:String = '$directory/$path/$file';

				if (FileSystem.isDirectory(absPath)) continue;
				if (!file.endsWith('.hx')) continue;

				loadFile(absPath);
			}
		}
	}

	public static function loadFile(dir:String):Script {
		if (!FileSystem.exists(dir)) return null;
		
		var script:Script = new Script(dir);
		script.set('game', PlayState.self);

		list.push(script);
		try{
			script.execute();
		}catch(e: haxe.Exception){
			trace('$dir failed to load: ${e.message}');
			#if desktop
			lime.app.Application.current.window.alert('Script at $dir failed to load:\n${e.message}', "Error on haxe script!");
			#end
			
		}
		return script;
	}

	public static function call(func:String, ?args:Array<Dynamic>, ?interruptOnFuncReturn:Bool = false):Dynamic {
		//args ??= [];

		if (args == null) {
			args = [];
		}
		var daReturn = null;

		for (i in 0...list.length) {
			final script:Script = list[i];
			if (script == null || script.disposed) continue;
			var ret:IrisCall = script.call(func, args);
			if (ret != null && ret.returnValue != null)
				daReturn = ret.returnValue;
			
			if (daReturn != null && interruptOnFuncReturn)
				return daReturn;
		}

		return daReturn;
	}

	public static function set(variable:String, value:Dynamic):Dynamic {
		for (i in 0...list.length) {
			final script:Script = list[i];
			if (script == null || script.disposed) continue;
			script.set(variable, value);
		}

		return [];
	}

	public static function clear() {
		while (list.length > 0) list.pop().destroy();
	}
}

class Script extends Iris {
	public var disposed:Bool;
	override function destroy():Void {
		super.destroy();
		disposed = true;
	}

	override function call(func:String, ?args:Array<Dynamic>):IrisCall {
		if (!interp.variables.exists(func)) return {funName: func, signature: null, returnValue: null};
		//return super.call(func, args ?? []);
		return super.call(func, args != null ? args : []);
	}

	public static function range(start:Float, end:Float, inc:Float):Iterator<Float> {
		var num = start;
		return {
			hasNext: function() {
				return num <= end;
			},
			next: function() {
				num += inc;
				return num - inc;
			}
		}
	}

	public function new(dir:String) {
		disposed = false;
		super(File.getContent(dir), {name: dir, autoRun: false, autoPreset: true});

		set('closeFile', function() {
			destroy();
			if (!ScriptHandler.list.contains(this)) return;
		});

		set('lerpColor', function(from:FlxColor, to:FlxColor, ratio:Float){
			return FlxColor.fromRGBFloat(FlxMath.lerp(from.redFloat, to.redFloat, ratio), FlxMath.lerp(from.greenFloat, to.greenFloat, ratio),
				FlxMath.lerp(from.blueFloat, to.blueFloat, ratio), FlxMath.lerp(from.alphaFloat, to.alphaFloat, ratio));
		});

		set('Settings', Settings);
		set('FlxG', FlxG);
		set('Controls', Controls);
		set('Util', Util);
		set('handler', ScriptHandler);
		set('Paths', Paths);
		set('FunkinSprite', funkin.objects.FunkinSprite);

		//needed to get the song name inside the script
		set('songID', PlayState.songID);

		//modifier system
		set('range', range);
		set('getModchartManager', getModchartManager);
		set('get', function(name:String, ?strumline:Int = 0) {
			return getModchartManager().get(name, strumline);
		});
		set('setNow', function(name:String, value:Float, ?strumline:Int = -1) {
			getModchartManager().setNow(name, value, strumline);
		});
		set('setAt', function(beat:Float, name:String, value:Float, ?strumline:Int = -1) {
			getModchartManager().setAt(beat, name, value, strumline);
		});
		set('setMultiAt', function(beat:Float, values:Dynamic, ?strumline:Int = -1) {
			getModchartManager().setMultiAt(beat, values, strumline);
		});
		set('easeNow', function(length:Float, name:String, value:Float, ?ease:Float->Float, ?strumline:Int = -1) {
			getModchartManager().easeNow(length, name, value, ease, strumline);
		});
		set('easeAt', function(beat:Float, length:Float, name:String, value:Float, ?ease:Float->Float, ?strumline:Int = -1, ?startVal:Float) {
			getModchartManager().easeAt(beat, length, name, value, ease, strumline, startVal);
		});
		set('easeMultiAt', function(beat:Float, length:Float, values:Dynamic, ?ease:Float->Float, ?strumline:Int = -1, ?startVals:Dynamic) {
			getModchartManager().easeMultiAt(beat, length, values, ease, strumline, startVals);
		});
		set('oneshotFuncAt', function(beat:Float, func:Float->Float->Void) {
			getModchartManager().oneshotFuncAt(beat, func);
		});
		set('continuousFuncAt', function(beat:Float, length:Float, func:Float->Float->Void) {
			getModchartManager().continuousFuncAt(beat, length, func);
		});
		set('easedFuncAt', function(beat:Float, length:Float, func:Float->Float->Void, ?ease:Float->Float, ?startVal:Float, ?endVal:Float) {
			getModchartManager().easedFuncAt(beat, length, func, ease, startVal, endVal);
		});
		set('makeAux', function(name:String, ?defaultValue:Int = 0) {
			getModchartManager().makeAux(name, defaultValue);
		});
		set('makeNode', function(inputs:Array<String>, func:funkin.modchart.ModchartManager.NodeFunc, ?outputs:Array<String>) {
			getModchartManager().makeNode(inputs, func, outputs);
		});
		set('ProxyField', funkin.modchart.drawing.ProxyField);
		set('FlxEase', flixel.tweens.FlxEase);

		//for the concert stage
		set('Speakers', funkin.objects.Speakers);
		//set('FlxSprite', FlxSprite);

		//okay, shaders are coming in
		set('FileShader', funkin.shaders.FileShader);
		set('ShaderFilter', openfl.filters.ShaderFilter);
		//setting this shader for test purposes
		set('RadialBlur', funkin.shaders.RadialBlur);
	}

	static function getModchartManager() {
		if (PlayState.self.playfield.modchart == null)
			PlayState.self.playfield.modchart = new funkin.modchart.ModchartManager();
		return PlayState.self.playfield.modchart;
	}
}
#else
class ScriptHandler {
	public static var list:Array<Script> = [];

	public static function loadFromDir(_, ?subFolders:Bool):Void {}
	public static function loadFile(_):Script return null;

	                               // ????????? thanks haxe
	public static function call(_, ?args:Array<Dynamic>):Array<Dynamic> return [];
	public static function set(_, v:Dynamic):Dynamic return null;
	public static function clear():Void {}
}

class Script {
	public function destroy():Void {}
	public function call(_, ?args:Array<Dynamic>):Dynamic return null;
	public function new(_) {}
}
#end
