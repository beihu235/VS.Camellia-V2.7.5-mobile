package funkin.modchart.mods;

import flixel.math.FlxAngle;
import funkin.objects.Note;

class Confusion extends BaseModifier {
	public function new(parent:ModchartManager) {
		super(parent);
		priority = -1;
	}

	override public function modifiesVertex(strumline:Int) {return true;}
	override public function adjustVertex(spr:FunkinSprite, vertex:Vector3, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		vertex.x -= pos.x;
		vertex.y -= pos.y;
		vertex.z -= pos.z;

		var dizzyX:Float = 0;
		var dizzyY:Float = 0;
		var dizzyZ:Float = 0;
		if(type != STRUM && spr is Note){
			var note: Note = cast spr;
			if(note.data.length == 0 && type == NOTE)
				dizzyX = distance * 0.5 * getValue(X_DIZZY_INDEX, strumline);

			dizzyY = distance * 0.5 * getValue(Y_DIZZY_INDEX, strumline);
			
			if((note.data.length == 0 || getValue(DIZZY_HOLDS_INDEX, strumline) == 1)  && type == NOTE)
				dizzyZ = (note.data.beat - beat) * getValue(Z_DIZZY_INDEX, strumline) * FlxAngle.TO_DEG;
			dizzyX %= 360;
			dizzyY %= 360;
			dizzyZ %= 360;
		}

		if (type == SUSTAIN){
			vertex.rotate(
				dizzyX,
				dizzyY,
				dizzyZ
			);
		}else{
			vertex.rotate(
				(getValue(X_INDEX, strumline) + getValue(X_LANE_INDEX + lane, strumline)) * beat + (getValue(X_OFFSET_INDEX, strumline) + getValue(X_OFFSET_LANE_INDEX + lane, strumline)) + dizzyX,
				(getValue(Y_INDEX, strumline) + getValue(Y_LANE_INDEX + lane, strumline)) * beat + (getValue(Y_OFFSET_INDEX, strumline) + getValue(Y_OFFSET_LANE_INDEX + lane, strumline)) + dizzyY,
				(getValue(Z_INDEX, strumline) + getValue(Z_LANE_INDEX + lane, strumline)) * beat + (getValue(Z_OFFSET_INDEX, strumline) + getValue(Z_OFFSET_LANE_INDEX + lane, strumline)) + dizzyZ
			);
		}

		vertex.x += pos.x;
		vertex.y += pos.y;
		vertex.z += pos.z;
	}

	override public function addStrumlineSet() {
		super.addStrumlineSet();
		// highest index + 4 if it's lane specific, + 1 if not.
		values.push([for (i in 0...(Z_DIZZY_INDEX + 1)) 0.0]);
	}

	public static inline var X_INDEX:Int = 0;
	public static inline var Y_INDEX:Int = 1;
	public static inline var Z_INDEX:Int = 2;

	public static inline var X_OFFSET_INDEX:Int = 3;
	public static inline var Y_OFFSET_INDEX:Int = 4;
	public static inline var Z_OFFSET_INDEX:Int = 5;

	public static inline var X_LANE_INDEX:Int = 6;
	public static inline var Y_LANE_INDEX:Int = 10;
	public static inline var Z_LANE_INDEX:Int = 14;

	public static inline var X_OFFSET_LANE_INDEX:Int = 18;
	public static inline var Y_OFFSET_LANE_INDEX:Int = 22;
	public static inline var Z_OFFSET_LANE_INDEX:Int = 26;

	public static inline var X_DIZZY_INDEX:Int = 30;  // Roll
	public static inline var Y_DIZZY_INDEX:Int = 31; // Twirl
	public static inline var Z_DIZZY_INDEX:Int = 32; // Dizzy

	public static inline var DIZZY_HOLDS_INDEX:Int = 33;

	public static function attachToRedirects() {
		ModchartManager.defaultRedirects.set("confusionx", {toClass: Confusion, index: X_INDEX});
		ModchartManager.defaultRedirects.set("confusiony", {toClass: Confusion, index: Y_INDEX});
		ModchartManager.defaultRedirects.set("confusion",  {toClass: Confusion, index: Z_INDEX});

		ModchartManager.defaultRedirects.set("roll", {toClass: Confusion, index: X_DIZZY_INDEX});
		ModchartManager.defaultRedirects.set("twirl", {toClass: Confusion, index: Y_DIZZY_INDEX});
		ModchartManager.defaultRedirects.set("dizzy",  {toClass: Confusion, index: Z_DIZZY_INDEX});
		ModchartManager.defaultRedirects.set("dizzyholds",  {toClass: Confusion, index: DIZZY_HOLDS_INDEX});


		ModchartManager.defaultRedirects.set("confusionoffsetx", {toClass: Confusion, index: X_OFFSET_INDEX});
		ModchartManager.defaultRedirects.set("confusionoffsety", {toClass: Confusion, index: Y_OFFSET_INDEX});
		ModchartManager.defaultRedirects.set("confusionoffset",  {toClass: Confusion, index: Z_OFFSET_INDEX});

		for (i in 0...4) {
			ModchartManager.defaultRedirects.set("confusionx" + i, {toClass: Confusion, index: X_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("confusiony" + i, {toClass: Confusion, index: Y_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("confusion" + i,  {toClass: Confusion, index: Z_LANE_INDEX + i});

			ModchartManager.defaultRedirects.set("confusionoffsetx" + i, {toClass: Confusion, index: X_OFFSET_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("confusionoffsety" + i, {toClass: Confusion, index: Y_OFFSET_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("confusionoffset" + i,  {toClass: Confusion, index: Z_OFFSET_LANE_INDEX + i});
		}
	}
}