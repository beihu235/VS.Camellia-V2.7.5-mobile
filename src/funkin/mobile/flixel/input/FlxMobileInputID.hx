package funkin.mobile.flixel.input;

import flixel.system.macros.FlxMacroUtil;

/**
 * A high-level list of unique values for mobile input buttons.
 * Maps enum values and strings to unique integer codes
 * @author Karim Akra & Lily(mcagabe19)
 */
@:runtimeValue
enum abstract FlxMobileInputID(Int) from Int to Int
{
	public static var fromStringMap(default, null):Map<String, FlxMobileInputID> = FlxMacroUtil.buildMap("funkin.mobile.flixel.input.FlxMobileInputID");
	public static var toStringMap(default, null):Map<FlxMobileInputID, String> = FlxMacroUtil.buildMap("funkin.mobile.flixel.input.FlxMobileInputID", true);
	// Nothing & Anything
	var ANY = -2;
	var NONE = -1;
	// Buttons
	var A = 1;
	var B = 2;
	var C = 3;
	var D = 4;
	var E = 5;
	var F = 6;
	var G = 7;
	var P = 8;
	var S = 9;
	var V = 10;
	var X = 11;
	var Y = 12;
	var Z = 13;
	// VPAD Buttons
	var UP = 14;
	var UP2 = 15;
	var DOWN = 16;
	var DOWN2 = 17;
	var LEFT = 18;
	var LEFT2 = 19;
	var RIGHT = 20;
	var RIGHT2 = 21;
	// HITBOX
	var hitboxUP = 22;
	var hitboxDOWN = 23;
	var hitboxLEFT = 24;
	var hitboxRIGHT = 25;
	// PlayState Releated
	var noteUP = 26;
	var noteDOWN = 27;
	var noteLEFT = 28;
	var noteRIGHT = 29;

	var EK_0_0 = 100;

	var EK_1_0 = 101;
	var EK_1_1 = 102;

	var EK_2_0 = 103;
	var EK_2_1 = 104;
	var EK_2_2 = 105;

	var EK_3_0 = 106;
	var EK_3_1 = 107;
	var EK_3_2 = 108;
	var EK_3_3 = 109;

	var EK_4_0 = 110;
	var EK_4_1 = 111;
	var EK_4_2 = 112;
	var EK_4_3 = 113;
	var EK_4_4 = 114;

	var EK_5_0 = 115;
	var EK_5_1 = 116;
	var EK_5_2 = 117;
	var EK_5_3 = 118;
	var EK_5_4 = 119;
	var EK_5_5 = 120;

	var EK_6_0 = 121;
	var EK_6_1 = 122;
	var EK_6_2 = 123;
	var EK_6_3 = 124;
	var EK_6_4 = 125;
	var EK_6_5 = 126;
	var EK_6_6 = 127;

	var EK_7_0 = 128;
	var EK_7_1 = 129;
	var EK_7_2 = 130;
	var EK_7_3 = 131;
	var EK_7_4 = 132;
	var EK_7_5 = 133;
	var EK_7_6 = 134;
	var EK_7_7 = 135;

	var EK_8_0 = 136;
	var EK_8_1 = 137;
	var EK_8_2 = 138;
	var EK_8_3 = 139;
	var EK_8_4 = 140;
	var EK_8_5 = 141;
	var EK_8_6 = 142;
	var EK_8_7 = 143;
	var EK_8_8 = 144;

	var EK_9_0 = 145;
	var EK_9_1 = 146;
	var EK_9_2 = 147;
	var EK_9_3 = 148;
	var EK_9_4 = 149;
	var EK_9_5 = 150;
	var EK_9_6 = 151;
	var EK_9_7 = 152;
	var EK_9_8 = 153;
	var EK_9_9 = 154;



	@:from
	public static inline function fromString(s:String)
	{
		s = s.toUpperCase();
		return fromStringMap.exists(s) ? fromStringMap.get(s) : NONE;
	}

	@:to
	public inline function toString():String
	{
		return toStringMap.get(this);
	}
}
