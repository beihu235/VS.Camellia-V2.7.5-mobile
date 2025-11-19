package funkin.objects;

import funkin.modchart.ModchartManager;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
class Strumline extends FlxTypedSpriteGroup<StrumNote> {
	public static final keyCount:Int = 4;
	public static var size(default, set):Float = 0.65;
	static function set_size(value:Float) {
		swagWidth = 160.0 * value;
		return size = value;
	}
	public static var swagWidth:Float = 160.0 * size;

	public var overrideScrollSpeed:Float = 0; // When 0, defer to PlayField.scrollSpeed

	public var skin(default, set):String;
	//public static inline var default_skin:String = Settings.default_data.noteSkin;
	function set_skin(value:String):String {
		skin = value;
		regenerate();
		return value;
	}
	public var ai:Bool;

	public var centerX:Float = 0;
	public var curHolds:Array<Sustain> = [];

	public dynamic function character():Character return null;
	public var healthMult:Float = 1.0;

	// for similar properties between Strumline and ProxyField. as said, only for modcharts.
	public var modchartX:Float = 0;
	public var modchartY:Float = 0;
	public var modchartAlpha:Float = 1;

	public function new(?x:Float, ?y:Float, ?player:Bool = false, ?skin:String) {
		this.moves = false;
		this.ai = !player;
		super(x, y);
		this.skin = skin ?? Settings.data.noteSkin;

		// center the strumline on the x position we gave it
		// instead of basing the x position on the left side of the x axis
		this.x = x - (width * 0.5);
		centerX = x;
	}

	public function regenerate() {
		// just in case there's anything stored
		while (members.length != 0) members.pop().destroy();

		var strum:StrumNote = null;
		for (i in 0...keyCount) {
			add(strum = new StrumNote(this, i));
			strum.ID = i;
			strum.scale.set(size, size);
			strum.updateHitbox();
			strum.x += swagWidth * i;
			strum.y += (swagWidth - strum.height) * 0.5;
		}
	}

	public function setModchartOffset(?x:Float = 0, ?y:Float = 0) {
		this.modchartX = x;
		this.modchartY = y;
	}

	override function set_x(Value:Float):Float {
		centerX += Value - x;
		return super.set_x(Value);
	}
}

@:allow(funkin.objects.PlayField)
class StrumNote extends FunkinSprite {
	public var queueStatic:Bool = false;
	public var luminColors:Bool = false;
	public var modchartPos:Vector3 = new Vector3();
	public var stealth:Float = 0;
	public var parent:Strumline;
	public var isHolding:Bool = false;

	public function new(parent:Strumline, lane:Int) {
		super();

		this.parent = parent;

		animation.finishCallback = anim -> {
			active = false;
			
			var waitForAnim = !isHolding || (!parent.ai && Settings.data.unglowOnAnimFinish);

			if (!waitForAnim || anim != 'notePressed') return;
			playAnim('default');
		}

		// modding by length will cause different behaviour here
		// left, down, up, right, if it goes beyond that, it loops back, left down up right, and so on.
		final anim:String = Note.directions[lane % Note.directions.length];

		frames = Note.getSkin(parent.skin);
		animation.addByPrefix('default', 'arrow${anim.toUpperCase()}', 24);
		animation.addByPrefix('pressed', '$anim press', 48, false);
		animation.addByPrefix('notePressed', '$anim confirm', 48, false);

		playAnim('default');
	}

	override function playAnim(name:String, ?forced:Bool = true, ?suffix:String = "") {
		queueStatic = false;
		luminColors = false;
		color = 0xFFFFFFFF;
		super.playAnim(name, forced, suffix);
		centerOffsets();
		centerOrigin();
	}

	override public function drawComplex(camera:FlxCamera) {
		prepareMatrix(camera);
		camera.drawNote(_frame, _matrix, colorTransform, blend, antialiasing, luminColors);
	}

	public function drawCrazy(modchart:ModchartManager, strumline:Int, downscroll:Bool, field:Strumline) {
		if (modchart.arrowPath != null)
			modchart.arrowPath.drawPath(this, strumline, downscroll, field);

		final oldX = x;
		final oldY = y;
		final oldScaleX = scale.x;
		final oldScaleY = scale.y;
		final mult: Float = downscroll ? -1 : 1;
		modchart.stealthColor.set(1.0, 1.0, 1.0);
		modchart.scrollMult = mult;

		final distance: Float = modchart.adjustDistance(this, 0, ID, strumline, field, STRUM);
		modchartPos.set(x + width * 0.5, y + height * 0.5 + (distance * mult), 0);
		modchart.adjustPos(this, modchartPos, distance, 0, ID, strumline, field, STRUM);
		modchart.adjustScale(this, scale, distance, ID, strumline, field, STRUM);
		stealth = modchart.getStealth(this, distance, 0, modchartPos, ID, strumline, field, STRUM);

		x = modchartPos.x - width * 0.5;
		y = modchartPos.y - height * 0.5;
		final layer = modchartPos.z;
		prepareMatrix(cameras[0]);
		_matrix.translate(cameras[0].scroll.x * scrollFactor.x, cameras[0].scroll.y * scrollFactor.y);
		x = oldX;
		y = oldY;
		scale.set(oldScaleX, oldScaleY);

		Note.modchartVertices[0].set(_matrix.transformX(0, 0), _matrix.transformY(0, 0), modchartPos.z);
		Note.modchartVertices[1].set(_matrix.transformX(_frame.frame.width, 0), _matrix.transformY(_frame.frame.width, 0), modchartPos.z);
		Note.modchartVertices[2].set(_matrix.transformX(0, _frame.frame.height), _matrix.transformY(0, _frame.frame.height), modchartPos.z);
		Note.modchartVertices[3].set(_matrix.transformX(_frame.frame.width, _frame.frame.height), _matrix.transformY(_frame.frame.width, _frame.frame.height), modchartPos.z);
		
		final orient:Float = modchart.get("orient", strumline);
		if(orient != 0){
			final orientOffset: Float = modchart.get("orientoffset", strumline);
			final cacheX:Float = modchartPos.x;
			final cacheY:Float = modchartPos.y;
			final cacheZ:Float = modchartPos.z;
			modchartPos.set(x + width * 0.5, y + (height * 0.5) + ((distance + 2) * mult), 0);
			modchart.adjustPos(this, modchartPos, distance + 2, 2, ID, strumline, field, STRUM);

			Note.cachePoint.set(modchartPos.x - cacheX, modchartPos.y - cacheY);
			Note.cachePoint.rotateByDegrees(orientOffset);

			final diffX: Float = Note.cachePoint.x;
			final diffY: Float = Note.cachePoint.y;

			for (i => vert in Note.modchartVertices){	
				vert.x -= modchartPos.x;
				vert.y -= modchartPos.y;
				vert.z -= modchartPos.z;
				vert.rotateRads(0, 0, orient * (Math.atan2(diffY, diffX) - (Math.PI / 2)));
				vert.x += modchartPos.x;
				vert.y += modchartPos.y;
				vert.z += modchartPos.z;
			}
			modchartPos.set(cacheX, cacheY, cacheZ);
		}

		for (vert in Note.modchartVertices) {
			modchart.adjustVertex(this, vert, modchartPos, distance, 0, ID, strumline, field, STRUM);
			vert.project();
		}

		modchart.pushDraw(strumline, field, cameras, scrollFactor, _frame, Note.modchartVertices, colorTransform, blend, antialiasing, luminColors, stealth, layer, true);
	}
}