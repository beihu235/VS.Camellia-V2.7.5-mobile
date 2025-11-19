package funkin.modchart.mods;

import openfl.geom.ColorTransform;
import flixel.graphics.frames.FlxFrame;
import funkin.objects.Note;

class ArrowPath extends BaseModifier {
	static var pathColor:ColorTransform = new ColorTransform();
	static var modchartPosLow:Vector3 = new Vector3();
	static var curStealthColor:Vector3 = new Vector3();
	static var nextStealthColor:Vector3 = new Vector3();
	public var pathFrame:FlxFrame;

	public function new(parent:ModchartManager) {
		super(parent);
		parent.arrowPath = this;
		pathFrame = FlxG.bitmap.create(1, 1, 0xFFFFFFFF, false, "ARROW_PATH_BITMAP").imageFrame.frame;
		priority = 0;
	}

	public function drawPath(strum:StrumNote, strumline:Int, downscroll:Bool, field:Strumline) {
		if (!active[strumline]) return;

		final spiral = getValue(SPIRAL_INDEX, strumline) == 1;
		final modchartPos = strum.modchartPos;
		final distInc = Math.max(20 * (getValue(GRAIN_INDEX, strumline) + Settings.data.holdGrain), 3);
		final mult = downscroll ? -1 : 1;
		final start = -65 * (getValue(BACK_DRAW_SIZE_INDEX, strumline) + 1) - Strumline.swagWidth * 0.5;
		final end = FlxG.height * (getValue(DRAW_SIZE_INDEX, strumline) + 1);
		final width = (1 + getValue(WIDTH_INDEX, strumline) + getValue(WIDTH_LANE_INDEX + strum.ID, strumline)); // a base width of 2 but we also half it for the vertex offsetting so it cancels out.
		final stealthEffective = getValue(STEALTH_INDEX, strumline);
		var stealth = 0.0;
		var angleUp = 0.0;
		var angleDown = 0.0;

		// the strumline's actually at 50 but extra padding for why not.
		var dist = start;
		final newDist: Float = parent.adjustDistance(strum, dist, strum.ID, strumline, field, SUSTAIN);
		parent.scrollMult = mult;
		modchartPos.set(strum.x + strum.width * 0.5, strum.y + strum.height * 0.5 + (dist * mult), 0);
		parent.adjustPos(strum, modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);

		final perc = getValue(INDEX, strumline) + getValue(LANE_INDEX + strum.ID, strumline);
		var curAlpha = 0.0;
		inline function getNextPos() {
			parent.stealthColor.set(1.0, 1.0, 1.0);
			stealth = parent.getStealth(strum, newDist, dist, modchartPos, strum.ID, strumline, field, SUSTAIN) * stealthEffective;
			nextStealthColor.copyFrom(parent.stealthColor);
			
			var alpha = 
				dist < (start + distInc * 2) ?
				1.0 - (dist - (start + distInc * 2)) / (distInc * 2) :
				(dist >= (end - distInc * 2) ? 1.0 - (dist - (end - distInc * 2)) / (distInc * 2) : 1.0);
			alpha *= perc;

			dist += distInc;

			final newDist: Float = parent.adjustDistance(strum, dist, strum.ID, strumline, field, SUSTAIN);
			parent.scrollMult = mult;
			modchartPosLow.set(strum.x + strum.width * 0.5, strum.y + strum.height * 0.5 + (dist * mult), 0);
			parent.adjustPos(strum, modchartPosLow, newDist, dist, strum.ID, strumline, field, SUSTAIN);
			
			if (spiral)
				angleDown = Math.atan2(modchartPosLow.y - modchartPos.y, modchartPosLow.x - modchartPos.x);

			return alpha;
		}
		curAlpha = getNextPos();
		final offsetX = spiral ? width * Math.sin(angleDown) : width;
		final offsetY = spiral ? width * Math.cos(angleDown) : 0;

		Note.modchartVertices[0].set(
			modchartPos.x - offsetX,
			modchartPos.y + offsetY,
			modchartPos.z
		);
		parent.adjustVertex(strum, Note.modchartVertices[0], modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);
		Note.modchartVertices[0].project();
		Note.modchartVertices[1].set(
			modchartPos.x + offsetX,
			modchartPos.y - offsetY,
			modchartPos.z
		);
		parent.adjustVertex(strum, Note.modchartVertices[1], modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);
		Note.modchartVertices[1].project();

		pathColor.redMultiplier = getValue(RED_INDEX, strumline) * getValue(RED_LANE_INDEX + strum.ID, strumline);
		pathColor.greenMultiplier = getValue(GREEN_INDEX, strumline) * getValue(GREEN_LANE_INDEX + strum.ID, strumline);
		pathColor.blueMultiplier = getValue(BLUE_INDEX, strumline) * getValue(BLUE_LANE_INDEX + strum.ID, strumline);

		angleUp = angleDown;
		modchartPos.copyFrom(modchartPosLow);
		while (dist < end) {
			curStealthColor.copyFrom(parent.stealthColor);
			var alpha = getNextPos();
			final angle = (angleDown + angleUp) * 0.5;
			final offsetX = spiral ? width * Math.sin(angle) : width;
			final offsetY = spiral ? width * Math.cos(angle) : 0;

			Note.modchartVertices[2].set(
				modchartPos.x - offsetX,
				modchartPos.y + offsetY,
				modchartPos.z
			);
			parent.adjustVertex(strum, Note.modchartVertices[2], modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);
			Note.modchartVertices[2].project();
			Note.modchartVertices[3].set(
				modchartPos.x + offsetX,
				modchartPos.y - offsetY,
				modchartPos.z
			);
			parent.adjustVertex(strum, Note.modchartVertices[3], modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);
			Note.modchartVertices[3].project();

			pathColor.alphaMultiplier = alpha;
			parent.stealthColor.copyFrom(curStealthColor);
			parent.pushDraw(strumline, field, strum.cameras, strum.scrollFactor, pathFrame, Note.modchartVertices, pathColor, null, false, false, stealth, -1500);
			parent.stealthColor.copyFrom(nextStealthColor);

			Note.modchartVertices[0].copyFrom(Note.modchartVertices[2]);
			Note.modchartVertices[1].copyFrom(Note.modchartVertices[3]);

			angleUp = angleDown;
			modchartPos.copyFrom(modchartPosLow);
		}
	}

	override function addStrumlineSet() {
		super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        final newValSet = [for (i in 0...(STEALTH_INDEX + 1)) 0.0];
        for (i in RED_INDEX...(BLUE_LANE_INDEX + 4))
            newValSet[i] = 1.0;
		newValSet[STEALTH_INDEX] = 1.0;

        values.push(newValSet);
	}

	override function isActive(vals:Array<Float>) {
		for (i in 0...5) {
			if (vals[i] != 0.0)
				return true;
		}
		return false;
	}

	public static inline var INDEX:Int = 0;
	public static inline var LANE_INDEX:Int = 1;

	public static inline var WIDTH_INDEX:Int = 5;
	public static inline var WIDTH_LANE_INDEX:Int = 6;

	public static inline var RED_INDEX:Int = 10;
	public static inline var GREEN_INDEX:Int = 11;
	public static inline var BLUE_INDEX:Int = 12;
	public static inline var RED_LANE_INDEX:Int = 13;
	public static inline var GREEN_LANE_INDEX:Int = 17;
	public static inline var BLUE_LANE_INDEX:Int = 21;

	public static inline var DRAW_SIZE_INDEX:Int = 25;
	public static inline var BACK_DRAW_SIZE_INDEX:Int = 26;

	public static inline var GRAIN_INDEX:Int = 27;
	public static inline var STEALTH_INDEX:Int = 28;
	public static inline var SPIRAL_INDEX:Int = 28;

	public static function attachToRedirects() {
		ModchartManager.defaultRedirects.set("arrowpath", {toClass: ArrowPath, index: INDEX});
		for (i in 0...4)
			ModchartManager.defaultRedirects.set("arrowpath" + i, {toClass: ArrowPath, index: LANE_INDEX + i});

		ModchartManager.defaultRedirects.set("arrowpathwidth", {toClass: ArrowPath, index: WIDTH_INDEX});
		ModchartManager.defaultRedirects.set("arrowpathgirth", {toClass: ArrowPath, index: WIDTH_INDEX});
		ModchartManager.defaultRedirects.set("arrowpathsize", {toClass: ArrowPath, index: WIDTH_INDEX});
		for (i in 0...4) {
			ModchartManager.defaultRedirects.set("arrowpathwidth" + i, {toClass: ArrowPath, index: WIDTH_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("arrowpathgirth" + i, {toClass: ArrowPath, index: WIDTH_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("arrowpathsize" + i, {toClass: ArrowPath, index: WIDTH_LANE_INDEX + i});
		}

		ModchartManager.defaultRedirects.set("arrowpathred", {toClass: ArrowPath, index: RED_INDEX});
		ModchartManager.defaultRedirects.set("arrowpathgreen", {toClass: ArrowPath, index: GREEN_INDEX});
		ModchartManager.defaultRedirects.set("arrowpathblue", {toClass: ArrowPath, index: BLUE_INDEX});
		for (i in 0...4) {
			ModchartManager.defaultRedirects.set("arrowpathred" + i, {toClass: ArrowPath, index: RED_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("arrowpathgreen" + i, {toClass: ArrowPath, index: GREEN_LANE_INDEX + i});
			ModchartManager.defaultRedirects.set("arrowpathblue" + i, {toClass: ArrowPath, index: BLUE_LANE_INDEX + i});
		}

		ModchartManager.defaultRedirects.set("arrowpathdrawsize", {toClass: ArrowPath, index: DRAW_SIZE_INDEX});
		ModchartManager.defaultRedirects.set("arrowpathdrawsizefront", {toClass: ArrowPath, index: DRAW_SIZE_INDEX});
		ModchartManager.defaultRedirects.set("arrowpathdrawsizeback", {toClass: ArrowPath, index: BACK_DRAW_SIZE_INDEX});

		ModchartManager.defaultRedirects.set("arrowpathgrain", {toClass: ArrowPath, index: GRAIN_INDEX});
		ModchartManager.defaultRedirects.set("arrowpathstealth", {toClass:ArrowPath, index: STEALTH_INDEX});
		ModchartManager.defaultRedirects.set("arrowpathspiral", {toClass: ArrowPath, index: SPIRAL_INDEX});
		ModchartManager.defaultRedirects.set("spiralarrowpath", {toClass: ArrowPath, index: SPIRAL_INDEX});
		ModchartManager.defaultRedirects.set("spiralpaths", {toClass: ArrowPath, index: SPIRAL_INDEX});
	}
}