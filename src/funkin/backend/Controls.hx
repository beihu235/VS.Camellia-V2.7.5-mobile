package funkin.backend;

import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import haxe.ds.Vector;
import lime.ui.KeyCode;

//for the gamepad support
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.FlxG;

class Controls {
	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx
	public static final default_binds:Map<String, Array<FlxKey>> = [
		'note_left'		=> [D, LEFT],
		'note_down'		=> [F, DOWN],
		'note_up'		=> [J, UP],
		'note_right'	=> [K, RIGHT],

		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],

		// undertale lol
		'next_dialogue' => [ENTER, Z],
		'skip_dialogue' => [SHIFT, X],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],

		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],

		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];

	public static var binds:Map<String, Array<Int>> = [for (bind in default_binds.keys()) bind => default_binds[bind].copy()];

	//hehe, controller support incoming, btw those A, B, X and Y binds are for xbox controllers
	public static final default_gamepad_binds:Map<String, Array<FlxGamepadInputID>> = [
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_up'		=> [DPAD_UP, Y],
		'note_right'	=> [DPAD_RIGHT, B],

		'accept'		=> [A, START],
		'back'			=> [B, BACK],
		'pause'			=> [START, BACK],
		'reset'			=> [Y]
	];
	public static var gamepad_binds:Map<String, Array<FlxGamepadInputID>> = default_gamepad_binds;

	static var _save:FlxSave;

	public static function justPressed(name:String):Bool {
		var k = _getKeyStatus(name, JUST_PRESSED);
		return k;
	}

	public static function pressed(name:String):Bool {
		var k = _getKeyStatus(name, PRESSED);
		return k;
	}

	public static function released(name:String):Bool {
		var k = _getKeyStatus(name, JUST_RELEASED);
		return k;
	}

	// backend functions to reduce repetitive code
	static function _getKeyStatus(name:String, state:FlxInputState):Bool {
		if (!Main.keyboardInputs) return false;

		var binds:Array<FlxKey> = binds[name];
		if (binds == null) {
			trace('Keybind "$name" doesn\'t exist.');
			return false;
		}

		var keyHasState:Bool = false;

		for (key in binds) {
			@:privateAccess
			if (FlxG.keys.getKey(key).hasState(state)) {
				keyHasState = true;
				break;
			}
		}

		return keyHasState;
	}

	//more gamepad stuff --it will be fully implemented in other commit rn i feel lazzzy
	public static function gamepadJustPressed(name:String, ?gamepad:FlxGamepad):Bool return _getGamepadKeyStatus(name, PRESSED, gamepad);
	public static function gamepadPressed(name:String, ?gamepad:FlxGamepad):Bool return _getGamepadKeyStatus(name, PRESSED, gamepad);
	public static function gamepadReleased(name:String, ?gamepad:FlxGamepad):Bool return _getGamepadKeyStatus(name, JUST_RELEASED, gamepad);

	static function _getGamepadKeyStatus(name:String, state:FlxInputState, ?gamepad:FlxGamepad):Bool {
		var binds = gamepad_binds[name];
		if (binds == null) return false;
		if (gamepad == null) gamepad = FlxG.gamepads.lastActive;
		if (gamepad == null) return false;

		for (btn in binds) {
			if (gamepad.checkStatus(btn, state)) return true;
		}
		return false;
	}

	//RUMBLE SUPPORT BABY!!! pd:i have some plans in mind for this - blear
	public static function setGamepadVibration(intensity:Float, duration:Float = 0.2, ?gamepad:FlxGamepad):Void {
		if (gamepad == null) gamepad = FlxG.gamepads.lastActive;
		/*if (gamepad != null && gamepad.supportsVibration) {
			gamepad.rumble(intensity, intensity, duration);
		}*/
		#if FLX_GAMEPAD
    if (gamepad != null && Reflect.hasField(gamepad, "rumble")) {
        Reflect.callMethod(gamepad, Reflect.field(gamepad, "rumble"), [intensity, intensity, duration]);
    }
    #end
	}

	public static function save() {
		_save.data.binds = binds;
		_save.flush();
	}

	public static function load() {
		if (_save == null) {
			_save = new FlxSave();
			_save.bind('controls', Util.getSavePath());
		}

		if (_save.data.binds != null) {
			var loadedKeys:Map<String, Array<FlxKey>> = _save.data.binds;
			for (control => keys in loadedKeys) {
				if (!binds.exists(control)) continue;
				binds.set(control, keys);
			}
		}
	}

	@:noDebug @:pure public static function convertStrumKey(arr:Array<String>, key:FlxKey):Int {
		if (key == NONE) return -1;
		for (i in 0...arr.length) {
			for (possibleKey in binds[arr[i]]) {
				if (key == possibleKey) return i;
			}
		}

		return -1;
	}

	// because openfl inlines it for some reason
	// @:noDebug to reduce overhead from calling it
    @:noDebug @:pure public static function convertLimeKeyCode(code:KeyCode):Int {
        @:privateAccess
        return inline openfl.ui.Keyboard.__convertKeyCode(code);
    }


	public static function reset(?saveToDisk:Bool = false) {
		for (key in binds.keys()) {
			if (!default_binds.exists(key)) continue;
			binds.set(key, default_binds.get(key).copy());
		}

		if (saveToDisk) save();
	}
}