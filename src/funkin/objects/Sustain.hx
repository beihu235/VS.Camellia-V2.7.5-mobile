package funkin.objects;

import funkin.objects.Note.NoteData;
import funkin.modchart.ModchartManager;
import funkin.objects.Strumline;
import flixel.graphics.frames.FlxFrame;
import flixel.animation.FlxAnimation;

class Sustain extends Note {
	public var forceHeightRecalc:Bool = false;
	var lastScaleY:Float = -1;
	var lastSustainScale:Float = -1;

	var sustainDivisions:Int = 0;
	var sustainTopY:Float = 0;
	var holdFrame:FlxFrame;
	var holdAnim:FlxAnimation;
	var holdHeight:Float = 0;
	var tailFrame:FlxFrame;
	var tailAnim:FlxAnimation;
	var tailHeight:Float = 0;

	// set to false by default
	// because it causes some weird overlapping bug if it's set to true
	// might try to workaround this in the future
	public var holdAntialiasing:Bool = false;
	public var holdSuffix:String = " hold piece";
	public var tailSuffix:String = " hold end";

	// public var stealthBottom:Float = 0;

	public var tapHolding:Bool = false;
	public var coyoteAlpha:Float = 0.7;
	public var coyoteHitMult:Float = 1.0;
	public var coyoteTimer:Float = 0.175;
	public var timeOffset:Float = 0;
	public var untilTick:Float = 0;

	var modchartPosLow:Vector3 = new Vector3();
	static var curStealthColor:Vector3 = new Vector3();
	static var nextStealthColor:Vector3 = new Vector3();
	static var nextScale:FlxPoint = new FlxPoint();

	public var parent(get, never):Note;
	function get_parent():Note {
		return data.parent.connectedNote;
	}

	// stupid shit to make texture setting not break this
	override function updateHitbox() {}
	override function resetHelpers():Void {
		resetFrameSize();
		_flashRect2.x = 0;
		_flashRect2.y = 0;

		if (graphic != null) {
			_flashRect2.width = graphic.width;
			_flashRect2.height = graphic.height;
		}

		if (FlxG.renderBlit) {
			dirty = true;
			updateFramePixels();
		}
	}

	override function set_type(value:String):String {
		var textureToSet:String = '';
		coyoteHitMult = 1.0;
		holdSuffix = " hold piece";
		tailSuffix = " hold end";
		animSuffix = '';
		tapHolding = false;
		switch (value) {
			case 'Roll':
				tapHolding = true;
				coyoteHitMult = 1.75;
				holdSuffix = " roll piece";
				tailSuffix = " roll end";

			case 'GF Sing':
				noAnimation = true;

			case 'Alt Animation':
				animSuffix = '-alt';
		}

		texture = textureToSet;
		return type = value;
	}

	override function loadAnims(colour:String) {
		animation.addByPrefix('hold', colour + holdSuffix);
		animation.addByPrefix('holdend', colour + tailSuffix);

		holdAnim = animation.getByName("hold");
		tailAnim = animation.getByName("holdend");
		holdHeight = frames.frames[holdAnim.frames[0]].sourceSize.y;
		tailHeight = frames.frames[tailAnim.frames[0]].sourceSize.y;

		final divisionsFloat:Float = ((height - tailHeight * scale.y) / (holdHeight * scale.y)) / Settings.data.holdGrain;
		sustainDivisions = Math.ceil(divisionsFloat);
		sustainTopY = holdHeight * (sustainDivisions - divisionsFloat);
	}

	override function setup(data:NoteData) {
		super.setup(data);
		coyoteAlpha = 0.7;
		lastScaleY = -1; // basically these two will force it to recalc height.
		lastSustainScale = -1;
		isSustain = true;
		holdAntialiasing = antialiasing;
		flipY = Settings.data.downscroll;
		coyoteTimer = 0.175 * coyoteHitMult * FlxG.timeScale;
		timeOffset = 0;
		untilTick = 0;
		return this;
	}

	@:noDebug override public function followStrum(strum:StrumNote, downscroll:Bool, scrollSpeed:Float) {
		visible = strum.visible && strum.parent.visible;
		distance = (hitTime + timeOffset) * 0.45 * scrollSpeed;
		distance *= downscroll ? -1 : 1;

 		if (copyAlpha) alpha = strum.alpha * multAlpha;

		if (copyX)
			x = strum.x + strum.width * 0.5;
		if (copyY)
			y = strum.y + strum.height * 0.5 + correctionOffset.y + distance;
	}

	public function calcHeight(holdScale:Float) {
		if (forceHeightRecalc || scale.y != lastScaleY || holdScale != lastSustainScale) {
			forceHeightRecalc = false;
			lastScaleY = scale.y;
			lastSustainScale = holdScale;
			height = (data.length - timeOffset) * 0.45 * holdScale;
		}
	}

	override public function draw() {
		if (alpha == 0 || coyoteAlpha <= 0 || height <= 0)
			return;

		holdFrame = frames.frames[holdAnim.frames[Math.floor(Math.abs(Conductor.visualTime * 0.001 * holdAnim.frameRate) % holdAnim.frames.length)]];
		tailFrame = frames.frames[tailAnim.frames[Math.floor(Math.abs(Conductor.visualTime * 0.001 * tailAnim.frameRate) % tailAnim.frames.length)]];
		for (camera in cameras) {
			if (!camera.visible || !camera.exists)
				continue;

			drawComplex(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
	override public function drawComplex(camera:FlxCamera) {
		final camX = camera.scroll.x * scrollFactor.x;
		final yMult = flipY ? -1 : 1;
		var curY = -camera.scroll.y * scrollFactor.y;

		Note.finalVertices[0] = Note.finalVertices[4] = x - camX - (holdFrame.frame.width * scale.x * 0.5);
		Note.finalVertices[2] = Note.finalVertices[6] = x - camX + (holdFrame.frame.width * scale.x * 0.5);

		final backupHoldY = holdFrame.frame.y;
		final backupHoldHeight = holdFrame.frame.height;
		for (i in 0...sustainDivisions) {
			Note.finalVertices[1] = Note.finalVertices[3] = y + curY;
			
			holdFrame.frame.y = (i == 0) ? backupHoldY + sustainTopY : backupHoldY;
			holdFrame.frame.height = backupHoldHeight - (holdFrame.frame.y - backupHoldY);
			curY += holdFrame.frame.height * scale.y * yMult * Settings.data.holdGrain;

			Note.finalVertices[5] = Note.finalVertices[7] = y + curY;

			if (Math.min(Note.finalVertices[1], Note.finalVertices[5]) <= camera.viewMarginBottom && Math.max(Note.finalVertices[1], Note.finalVertices[5]) >= camera.viewMarginTop)
				camera.drawNoteVertices(holdFrame, Note.finalVertices, colorTransform, blend, holdAntialiasing, luminColors, 0, colorTransform.alphaMultiplier * coyoteAlpha);
		}
		holdFrame.frame.y = backupHoldY;
		holdFrame.frame.height = backupHoldHeight;

		final backupTailY = tailFrame.frame.y;
		final backupTailHeight = tailFrame.frame.height;
		tailFrame.frame.height = Math.min(height, backupTailHeight);
		tailFrame.frame.y = backupTailY + (backupTailHeight - tailFrame.frame.height);

		Note.finalVertices[1] = Note.finalVertices[3] = y + curY;
		Note.finalVertices[5] = Note.finalVertices[7] = y + curY + (tailFrame.frame.height * scale.y * yMult);

		if (Math.min(Note.finalVertices[1], Note.finalVertices[5]) <= camera.viewMarginBottom && Math.max(Note.finalVertices[1], Note.finalVertices[5]) >= camera.viewMarginTop)
			camera.drawNoteVertices(tailFrame, Note.finalVertices, colorTransform, blend, antialiasing, luminColors, 0, colorTransform.alphaMultiplier * coyoteAlpha);

		tailFrame.frame.y = backupTailY;
		tailFrame.frame.height = backupTailHeight;
	}

	override public function drawCrazy(modchart:ModchartManager, downscroll:Bool, field:Strumline) {
		if (alpha == 0 || coyoteAlpha  <= 0 || height <= 0)
			return;

		final ogAlpha = colorTransform.alphaMultiplier;
		colorTransform.alphaMultiplier *= coyoteAlpha;
		final strumline = data.player;
		final yMult = downscroll ? -1 : 1;
		final oldScaleX = scale.x;
		final oldScaleY = scale.y;
		final spiral:Bool = modchart.get("spiralholds", strumline) == 1;
		final sexuality:Float = modchart.get("straightholds", strumline) - modchart.get("gayholds", strumline);
		final superstraight:Float = modchart.get("extrastraightholds", strumline);
		var layer:Float = 0;
		var angleUp:Float = 0;
		var angleDown:Float = 0;

		var curDist = distance * yMult;
		var curY = 0.0;

		holdFrame = frames.frames[holdAnim.frames[Math.floor(Math.abs(Conductor.visualTime * 0.001 * holdAnim.frameRate) % holdAnim.frames.length)]];
		tailFrame = frames.frames[tailAnim.frames[Math.floor(Math.abs(Conductor.visualTime * 0.001 * tailAnim.frameRate) % tailAnim.frames.length)]];
		
		var newDist: Float = modchart.adjustDistance(this, curDist, data.lane, strumline, field, SUSTAIN);
		final rawY:Float = (y - distance);
		final newY:Float = rawY + (newDist * yMult);
		modchartPos.set(x, newY, 0);
		modchart.scrollMult = yMult;
		modchart.adjustPos(this, modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		modchart.adjustScale(this, scale, newDist, data.lane, strumline, field, SUSTAIN);

		final baseX:Float = modchartPos.x;
		final baseZ:Float = modchartPos.z;
		modchartPos.set(
			FlxMath.lerp(modchartPos.x, x, superstraight),
			FlxMath.lerp(modchartPos.y, y, superstraight),
			FlxMath.lerp(modchartPos.z, 0, superstraight)
		);

		final backupHoldY = holdFrame.frame.y;
		final backupHoldHeight = holdFrame.frame.height;
		final backupTailY = tailFrame.frame.y;
		final backupTailHeight = tailFrame.frame.height;
		var rects = sustainDivisions + 1;
		inline function getNextPos() {
			--rects;
			modchart.stealthColor.set(1.0, 1.0, 1.0);
			stealth = modchart.getStealth(this, newDist, curDist, modchartPos, data.lane, strumline, field, SUSTAIN);
			nextStealthColor.copyFrom(modchart.stealthColor);

			final height:Float = (rects == 0) ? Math.min(height, backupTailHeight) : ((rects == sustainDivisions) ? backupHoldHeight - sustainTopY : backupHoldHeight) * Settings.data.holdGrain;
			curY += height * oldScaleY * yMult;
			curDist = (distance + curY) * yMult;

			final newDist: Float = modchart.adjustDistance(this, curDist, data.lane, strumline, field, SUSTAIN);
			final newY: Float = rawY + (newDist * yMult);

			modchartPosLow.set(x, newY, 0);
			nextScale.set(oldScaleX, oldScaleY);
			modchart.scrollMult = yMult;
			modchart.adjustPos(this, modchartPosLow, newDist, curDist, data.lane, strumline, field, SUSTAIN);
			modchart.adjustScale(this, nextScale, curDist, data.lane, strumline, field, SUSTAIN);
			
			modchartPosLow.set(
				FlxMath.lerp(modchartPosLow.x, baseX, sexuality),
				FlxMath.lerp(modchartPosLow.y, newY, sexuality),
				FlxMath.lerp(modchartPosLow.z, baseZ, sexuality),
			);

			modchartPosLow.set(
				FlxMath.lerp(modchartPosLow.x, x, superstraight),
				FlxMath.lerp(modchartPosLow.y, rawY + (curDist * yMult), superstraight),
				FlxMath.lerp(modchartPosLow.z, 0, superstraight)
			);
			
			if (spiral)
				angleDown = Math.atan2(modchartPosLow.y - modchartPos.y, modchartPosLow.x - modchartPos.x);

			return modchartPosLow.z;
		}
		layer = getNextPos();
		final halfHoldWidth = holdFrame.frame.width * scale.x * 0.5;
		final offsetX = spiral ? halfHoldWidth * Math.sin(angleDown) : halfHoldWidth;
		final offsetY = spiral ? halfHoldWidth * Math.cos(angleDown) : 0;

		Note.modchartVertices[0].set(
			modchartPos.x - offsetX,
			modchartPos.y + offsetY,
			modchartPos.z
		);
		modchart.adjustVertex(this, Note.modchartVertices[0], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		Note.modchartVertices[0].project();
		Note.modchartVertices[1].set(
			modchartPos.x + offsetX,
			modchartPos.y - offsetY,
			modchartPos.z
		);
		modchart.adjustVertex(this, Note.modchartVertices[1], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		Note.modchartVertices[1].project();

		angleUp = angleDown;
		scale.copyFrom(nextScale);
		modchartPos.copyFrom(modchartPosLow);

		for (i in 0...sustainDivisions) {
			holdFrame.frame.y = (i == 0) ? backupHoldY + sustainTopY : backupHoldY;
			holdFrame.frame.height = backupHoldHeight - (holdFrame.frame.y - backupHoldY);

			curStealthColor.copyFrom(modchart.stealthColor);
			final nextLayer = getNextPos();
			final halfHoldWidth = holdFrame.frame.width * scale.x * 0.5;
			final offsetX = spiral ? halfHoldWidth * Math.sin((angleDown + angleUp) * 0.5) : halfHoldWidth;
			final offsetY = spiral ? halfHoldWidth * Math.cos((angleDown + angleUp) * 0.5) : 0;

			Note.modchartVertices[2].set(
				modchartPos.x - offsetX,
				modchartPos.y + offsetY,
				modchartPos.z
			);
			modchart.adjustVertex(this, Note.modchartVertices[2], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
			Note.modchartVertices[2].project();
			Note.modchartVertices[3].set(
				modchartPos.x + offsetX,
				modchartPos.y - offsetY,
				modchartPos.z
			);
			modchart.adjustVertex(this, Note.modchartVertices[3], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
			Note.modchartVertices[3].project();

			modchart.stealthColor.copyFrom(curStealthColor);
			modchart.pushDraw(strumline, field, cameras, scrollFactor, holdFrame, Note.modchartVertices, colorTransform, blend, holdAntialiasing, luminColors, stealth, layer);
			modchart.stealthColor.copyFrom(nextStealthColor);

			Note.modchartVertices[0].copyFrom(Note.modchartVertices[2]);
			Note.modchartVertices[1].copyFrom(Note.modchartVertices[3]);

			layer = nextLayer;
			angleUp = angleDown;
			scale.copyFrom(nextScale);
			modchartPos.copyFrom(modchartPosLow);
		}
		holdFrame.frame.y = backupHoldY;
		holdFrame.frame.height = backupHoldHeight;

		tailFrame.frame.height = Math.min(height, backupTailHeight);
		tailFrame.frame.y = backupTailY + (backupTailHeight - tailFrame.frame.height);
		final halfTailWidth = tailFrame.frame.width * scale.x * 0.5;
		final offsetX = spiral ? halfTailWidth * Math.sin(angleUp) : halfTailWidth;
		final offsetY = spiral ? halfTailWidth * Math.cos(angleUp) : 0;

		Note.modchartVertices[2].set(
			modchartPos.x - offsetX,
			modchartPos.y + offsetY,
			modchartPos.z
		);
		modchart.adjustVertex(this, Note.modchartVertices[2], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		Note.modchartVertices[2].project();
		Note.modchartVertices[3].set(
			modchartPos.x + offsetX,
			modchartPos.y - offsetY,
			modchartPos.z
		);
		modchart.adjustVertex(this, Note.modchartVertices[3], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		Note.modchartVertices[3].project();

		modchart.pushDraw(strumline, field, cameras, scrollFactor, tailFrame, Note.modchartVertices, colorTransform, blend, antialiasing, luminColors, stealth, layer);

		tailFrame.frame.y = backupTailY;
		tailFrame.frame.height = backupTailHeight;

		scale.set(oldScaleX, oldScaleY);
		colorTransform.alphaMultiplier = ogAlpha;
	}

	override function set_height(value:Float) {
		if (height == value) return height;

		final divisionsFloat:Float = ((value - tailHeight * scale.y) / (holdHeight * scale.y)) / Settings.data.holdGrain;
		sustainDivisions = Math.ceil(divisionsFloat);
		sustainTopY = holdHeight * (sustainDivisions - divisionsFloat);
		return height = value;
	}


	// keeping this in case we want to come back to this
	/*override public function drawCrazy(modchart:ModchartManager, downscroll:Bool, field:Strumline) {
		if (alpha == 0 || height <= 0)
			return;

		final strumline = data.player;
		final yMult = downscroll ? -1 : 1;
		final oldScaleX = scale.x;
		final oldScaleY = scale.y;
		final sexuality:Float = modchart.get("straightholds", strumline) - modchart.get("gayholds", strumline);
		final superstraight:Float = modchart.get("extrastraightholds", strumline);
		var layer:Float = 0;

		var curDist = distance * yMult;
		var curY = 0.0;

		holdFrame = frames.frames[holdAnim.frames[Math.floor(Math.abs(Conductor.visualTime * 0.001 * holdAnim.frameRate) % holdAnim.frames.length)]];
		tailFrame = frames.frames[tailAnim.frames[Math.floor(Math.abs(Conductor.visualTime * 0.001 * tailAnim.frameRate) % tailAnim.frames.length)]];
		
		var newDist: Float = modchart.adjustDistance(this, curDist, data.lane, strumline, field, SUSTAIN);
		final rawY:Float = (y - distance);
		final newY:Float = rawY + (newDist * yMult);
		modchartPos.set(x, newY, 0);
		modchart.scrollMult = yMult;
		modchart.adjustPos(this, modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		modchart.adjustScale(this, scale, newDist, data.lane, strumline, field, SUSTAIN);
		modchart.stealthColor.set(1.0, 1.0, 1.0);
		stealth = modchart.getStealth(this, newDist, curDist, modchartPos, data.lane, strumline, field, SUSTAIN);

		final baseX:Float = modchartPos.x;
		final baseZ:Float = modchartPos.z;
		modchartPos.set(
			FlxMath.lerp(modchartPos.x, x, superstraight),
			FlxMath.lerp(modchartPos.y, y, superstraight),
			FlxMath.lerp(modchartPos.z, 0, superstraight)
		);

		Note.modchartVertices[0].set(
			modchartPos.x - (holdFrame.frame.width * scale.x * 0.5),
			modchartPos.y,
			modchartPos.z
		);
		modchart.adjustVertex(this, Note.modchartVertices[0], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		Note.modchartVertices[0].project();
		Note.modchartVertices[1].set(
			modchartPos.x + (holdFrame.frame.width * scale.x * 0.5),
			modchartPos.y,
			modchartPos.z
		);
		modchart.adjustVertex(this, Note.modchartVertices[1], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		Note.modchartVertices[1].project();

		
		final backupHoldY = holdFrame.frame.y;
		final backupHoldHeight = holdFrame.frame.height;
		for (i in 0...sustainDivisions) {
			holdFrame.frame.y = (i == 0) ? backupHoldY + sustainTopY : backupHoldY;
			holdFrame.frame.height = backupHoldHeight - (holdFrame.frame.y - backupHoldY);
			curY += holdFrame.frame.height * oldScaleY * yMult * Settings.data.holdGrain;
			curDist = (distance + curY) * yMult;
			
			final newDist: Float = modchart.adjustDistance(this, curDist, data.lane, strumline, field, SUSTAIN);
			final newY: Float = rawY + (newDist * yMult);

			modchartPos.set(x, newY, 0);
			scale.set(oldScaleX, oldScaleY);
			modchart.scrollMult = yMult;
			modchart.adjustPos(this, modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
			modchart.adjustScale(this, scale, curDist, data.lane, strumline, field, SUSTAIN);

			
			modchartPos.set(
				FlxMath.lerp(modchartPos.x, baseX, sexuality),
				FlxMath.lerp(modchartPos.y, newY, sexuality),
				FlxMath.lerp(modchartPos.z, baseZ, sexuality),
			);

			modchartPos.set(
				FlxMath.lerp(modchartPos.x, x, superstraight),
				FlxMath.lerp(modchartPos.y, rawY + (curDist * yMult), superstraight),
				FlxMath.lerp(modchartPos.z, 0, superstraight)
			);
			

			layer = modchartPos.z;

			Note.modchartVertices[2].set(
				modchartPos.x - (holdFrame.frame.width * scale.x * 0.5),
				modchartPos.y,
				modchartPos.z
			);
			modchart.adjustVertex(this, Note.modchartVertices[2], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
			Note.modchartVertices[2].project();
			Note.modchartVertices[3].set(
				modchartPos.x + (holdFrame.frame.width * scale.x * 0.5),
				modchartPos.y,
				modchartPos.z
			);
			modchart.adjustVertex(this, Note.modchartVertices[3], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
			Note.modchartVertices[3].project();

			modchart.pushDraw(strumline, field, cameras, scrollFactor, holdFrame, Note.modchartVertices, colorTransform, blend, holdAntialiasing, luminColors, stealth, layer);

			Note.modchartVertices[0].copyFrom(Note.modchartVertices[2]);
			Note.modchartVertices[1].copyFrom(Note.modchartVertices[3]);
			modchart.stealthColor.set(1.0, 1.0, 1.0);
			stealth = modchart.getStealth(this, newDist, curDist, modchartPos, data.lane, strumline, field, SUSTAIN);
		}
		holdFrame.frame.y = backupHoldY;
		holdFrame.frame.height = backupHoldHeight;

		final backupTailY = tailFrame.frame.y;
		final backupTailHeight = tailFrame.frame.height;
		tailFrame.frame.height = Math.min(height, backupTailHeight);
		tailFrame.frame.y = backupTailY + (backupTailHeight - tailFrame.frame.height);
		curY += tailFrame.frame.height * oldScaleY * yMult;
		curDist = (distance + curY) * yMult;
		final newDist: Float = modchart.adjustDistance(this, curDist, data.lane, strumline, field, SUSTAIN);
		final newY: Float = rawY + (newDist * yMult);
		modchartPos.set(x, newY, 0);
		scale.set(oldScaleX, oldScaleY);
		modchart.scrollMult = yMult;
		modchart.adjustPos(this, modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		modchart.adjustScale(this, scale, curDist, data.lane, strumline, field, SUSTAIN);

		modchartPos.set(
			FlxMath.lerp(modchartPos.x, baseX, sexuality),
			FlxMath.lerp(modchartPos.y, newY, sexuality),
			FlxMath.lerp(modchartPos.z, baseZ, sexuality),
		);

		modchartPos.set(
			FlxMath.lerp(modchartPos.x, x, superstraight),
			FlxMath.lerp(modchartPos.y, rawY + (curDist * yMult), superstraight),
			FlxMath.lerp(modchartPos.z, 0, superstraight)
		);

		layer = modchartPos.z;


		Note.modchartVertices[2].set(
			modchartPos.x - (tailFrame.frame.width * scale.x * 0.5),
			modchartPos.y,
			modchartPos.z
		);
		modchart.adjustVertex(this, Note.modchartVertices[2], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		Note.modchartVertices[2].project();
		Note.modchartVertices[3].set(
			modchartPos.x + (tailFrame.frame.width * scale.x * 0.5),
			modchartPos.y,
			modchartPos.z
		);
		modchart.adjustVertex(this, Note.modchartVertices[3], modchartPos, newDist, curDist, data.lane, strumline, field, SUSTAIN);
		Note.modchartVertices[3].project();

		modchart.pushDraw(strumline, field, cameras, scrollFactor, tailFrame, Note.modchartVertices, colorTransform, blend, antialiasing, luminColors, stealth, layer);

		tailFrame.frame.y = backupTailY;
		tailFrame.frame.height = backupTailHeight;

		scale.set(oldScaleX, oldScaleY);
	}
	*/
}