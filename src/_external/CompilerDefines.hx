package _external;

// have to make this a seperate class
// otherwise haxe shits itself
// thanks haxe
class CompilerDefines {
	public static var list(get, never):Map<String, Dynamic>;
	static inline function get_list():Map<String, Dynamic> return _get();

	static macro function _get() return macro $v{haxe.macro.Context.getDefines()};
}