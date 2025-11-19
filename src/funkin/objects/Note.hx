package funkin.objects;

import flixel.math.FlxAngle;
import funkin.backend.Util;
import funkin.shaders.NoteShader;
import funkin.objects.Strumline.StrumNote;
import funkin.modchart.ModchartManager;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;

// TODO: implement
/* typedef NoteSkinPixelData = {
	image: String,
	holdImage: String,
	noteRows: Int,
	noteColumns: Int,
	holdRows: Int,
	holdColumns: Int,

	staticIndices: Array<Array<Int>>,
	noteIndices: Array<Array<Int>>,
	pressIndices: Array<Array<Int>>,
	glowIndices: Array<Array<Int>>,
	holdIndices: Array<Array<Int>>,
	holdEndIndices: Array<Array<Int>>,

	?staticFramerate: Float,
	?noteFramerate: Float,
	?pressFramerate: Float,
	?glowFramerate: Float,
	?holdFramerate: Float
}

typedef NoteSkinNormalData = {
	image: String,

	staticPrefixes: Array<String>,
	notePrefixes: Array<String>,
	pressPrefixes: Array<String>,
	glowPrefixes: Array<String>,

	?staticFramerate: Float,
	?noteFramerate: Float,
	?pressFramerate: Float,
	?glowFramerate: Float
}

typedef NoteSkinDataFile = {
	displayName: String,
	pixel: NoteSplashPixelData,
	normal: NoteSplashNormalData
}

@:structInit
class NoteSkinData {
	public var displayName: String = 'Fallback';
	public var pixel: NoteSplashPixelData = {
		image: "pixelFunkin",
		holdImage: "pixelFunkinHolds",
		noteRows: 4,
		noteColumns: 5,
		holdRows: 4,
		holdColumns: 2,

		staticIndices: [[0], [1], [2], [3]],
		noteIndices: [[4], [5], [6], [7]],
		pressIndices: [[4, 8], [5, 9], [6, 10], [7, 11]],
		glowIndices: [[12, 16], [13, 17], [14, 18], [15, 19]],
		holdIndices: [[0], [1], [2], [3]],

	}
} */

@:structInit
class NoteData {
	public var time:Float = 0;
	public var beat:Float = 0;
	public var lane:Int = 0;
	public var speed:Single = 1;
	public var player:Int = 0;
	public var type:String;

	public var length:Single = 0;

	public var parent:NoteData = null;
	public var spotInLine:Int = 0;
	public var children:Array<NoteData> = [];
	public var connectedNote:Note = null;

	public var quant:Int = -1;
}

//@:nullSafety(Strict)
class Note extends FunkinSprite {
	public var data:NoteData;

	public static var colourShader:NoteShader = new NoteShader();
	public static var byQuant:Bool = false;
	public static var curPalette:Array<FlxColor> = null;
	public static final quantPalettes:Map<String, Array<FlxColor>> = [ //changed some vars to final since they won't be changing
		"Funkin" => [ // Basically just improved Kade quants, using 9k colours for the yellow/blue and Receptor grey for the misc quants
			// though if it gets killed idc LOL
 			0xFFF9393F, // 4th
			0xFF00FFFF, // 8th
			0xFFC24B99, // 12th
			0xFF12FA05, // 16th
			0xFF87A3AD, // 20th
			0xFFC24B99, // 24th
			0xFFFBFF22, // 32nd
			0xFFC24B99, // 48th
			0xFF41ECAA, // 64th
			0xFF87A3AD, // 96th
			0xFF87A3AD, // 192nd 
		],
		"ITG" => [
			0xFFFE2E2E, // 4th
			0xFF3E4FD4, // 8th
			0xFFBB32FF, // 12th
			0xFF0CF23E, // 16th
			0xFF7474A5, // 20th
			0xFFBB32FF, // 24th
			0xFFFFFF28, // 32nd
			0xFFBB32FF, // 48th
			0xFF38D1D1, // 64th
			0xFF7474A5, // 96th
			0xFF7474A5 // 192nd
		],
		"ArrowVortex" => [
			0xFFFE2E2E, // 4th
			0xFF3E4FD4, // 8th
			0xFFBB32FF, // 12th
			0xFFFFFF28, // 16th
			0xFF5F5F5F, // 20th 
			0xFFFF7CC4, // 24th
			0xFFFF7F00, // 32nd
			0xFF38D1D1, // 48th
			0xFF0CF23E, // 64th
			0xFF5F5F5F, // 96th
			0xFF5F5F5F, // 192nd
		],
		"DivByZero" => [
			0xFFFF0000,
			0xFF0040FF,
			0xFF00FF00,
			0xFFFFFF00,
			0xFFA8A8A8,
			0xFFFF00BF,
			0xFFFFA400,
			0xFF00FFFF,
			0xFFA8A8A8,
			0xFFA8A8A8,
			0xFFA8A8A8,
		],
		"Osu" => [
			0xFFFEFEFE, // ofset by 1, 1, 1 to activate colorTransform
			0xFFED1121,
			0xFF8866EE,
			0xFF66CCFF,
			0xFF4E5552,
			0xFFEEAA00,
			0xFFFFCC22,
			0xFFCC6600,
			0xFF6644CC,
			0xFF4E5552,
			0xFF4E5552
		],
		"Kade" => [ // made slightly more usable LMFAO still not very usable
			0xFFF9393F, // 4th
			0xFF00FFFF, // 8th
			0xFFC24B99, // 12th
			0xFF12FA05, // 16th
			0xFFC24B99, // 20th
			0xFFC24B99, // 24th
			0xFF12FA05, // 32nd
			0xFFC24B99, // 48th
			0xFF00FFFF, // 64th
			0xFFC24B99, // 96th
			0xFFC24B99, // 192nd
		]
	];
	public static final colours:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static final directions:Array<String> = ['left', 'down', 'up', 'right'];

	public static var modchartVertices:Array<Vector3> = [
		new Vector3(),
		new Vector3(),
		new Vector3(),
		new Vector3()
	];
	public static var finalVertices:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];

	public static  final defaultTypes:Array<String> = [
		'', // Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Mine',
		'No Animation'
	];

	public static final defaultMissHealth:Float = 6;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var isSustain:Bool = false;
	public var sustain:Sustain;

	public var multAlpha:Float = 1.0;
	public var luminColors:Bool = false;

	public var distance:Float = 2000;
	public var correctionOffset:FlxPoint = FlxPoint.get(0, 0);
	public var modchartPos:Vector3 = new Vector3();
	public var stealth:Float = 0;

	public var lateHitMult:Float = 1;
	public var earlyHitMult:Float = 1;
	public var breakOnHit:Bool = false;
	public var ignore:Bool = false;
	public var missHealth:Float = 6;

	public var noAnimation:Bool = false;
	public var animSuffix:String = '';
	public var sound:String = '';

	public var time(get, never):Float;
	inline function get_time():Float return data.time - Settings.data.noteOffset;

	public var rawTime(get, never):Float;
	inline function get_rawTime():Float return data.time;

	public var rawHitTime(get, never):Float;
	inline function get_rawHitTime():Float return time - Conductor.rawTime;

	public var hitTime(get, never):Float;
	inline function get_hitTime():Float return time - Conductor.visualTime;

	public var canHit:Bool = true;
	public var inHitRange(get, never):Bool;
	function get_inHitRange():Bool {
		final early:Bool = time < Conductor.rawTime + (Judgement.max.timing * earlyHitMult);
		final late:Bool = time > Conductor.rawTime - (Judgement.max.timing * lateHitMult);

		return early && late;
	}

	public var tooLate(get, never):Bool;
	function get_tooLate():Bool {
		return hitTime < -((Judgement.max.timing + 25 * FlxG.timeScale));
	}

	public var hitJudgement:Judgement = Judgement.list[0];

	public var hittable(get, never):Bool;
	function get_hittable():Bool return exists && inHitRange && canHit && !missed;

	public var wasHit:Bool = false;
	public var missed:Bool = false;

	public var type(default, set):String;
	function set_type(value:String):String {
		var textureToSet:String = '';
		ignore = false;
		breakOnHit = false;
		earlyHitMult = 1.0;
		lateHitMult = 1.0;
		animSuffix = '';
		sound = '';
		missHealth = defaultMissHealth;
		switch (value) {
			case 'Mine':
				textureToSet = 'mine';
				sound = 'sfx/mine';
				data.length = 0;
				luminColors = false;
				ignore = true;
				breakOnHit = true;
				earlyHitMult = 0.4;
				lateHitMult = 0.4;
				missHealth = 20;

				// just some extra visual bs
				copyAngle = false;
				active = true;

			case 'GF Sing':
				noAnimation = true;

			case 'Alt Animation':
				animSuffix = '-alt';

			case 'Cheer':
				noAnimation = true;
		}

		texture = textureToSet;
		return type = value;
	}

	public var noteSuffix:String = "0";
	public var texture(default, set):String;
	function set_texture(value:String):String {
		if (value == null || value.length == 0) value = '';
		
		reload(value);
		return texture = value;
	}

	public function reload(?skin:String) {
		frames = getSkin(skin);

		scale.set(Strumline.size, Strumline.size);
		loadAnims(colours[data.lane % colours.length]);
		updateHitbox();
	}

	public static function getSkin(?name:String):FlxFramesCollection {
		name ??= '';
		if (name.length == 0) name = Settings.data.noteSkin;
		name = Util.format(name);

		function getTextureKey(name:String):String {
			var key:String = name;
			if (Settings.data.quantColouring.toLowerCase() == 'none') return key;

			key = '$name-quant';
			if (!Paths.exists('images/noteSkins/$key.xml')) key = name;
			return key;
		}

		return Paths.sparrowAtlas('noteSkins/${getTextureKey(name)}');
	}

	function loadAnims(colour:String) {
		animation.addByPrefix('default', colour + noteSuffix);
		playAnim('default');
	}

	public function new() {
		super();

		data = {
			time: 0,
			lane: 0,
			speed: 1.0,
			player: 0,
			length: 0,
			type: '',
			connectedNote: this
		}

		active = false;
	}

	public function setup(data:NoteData):Note {
		this.data = data;
		data.connectedNote = this;
		isSustain = false;
		sustain = null;
		noAnimation = false;
		luminColors = curPalette != null;

		missed = false;
		wasHit = false;
		correctionOffset.set(0, 0);
		antialiasing = true;
		multAlpha = 1.0;
		copyAngle = true;
		copyAlpha = true;
		type = data.type;
		
		if (!luminColors) color = 0xFFFFFFFF;
		else color = curPalette[byQuant ? Conductor.quants.indexOf(data.quant) : data.lane];

		return this;
	}

	override function update(delta:Float) {
		super.update(delta);
		if (type == 'Mine') angle += 135 * delta;
	}

	// custom kill handling for allowing sustain heads to stay "existant" when hit
	override public function kill():Void {
		alive = false;
		exists = false;
		data.connectedNote = null;
	}

	override public function revive():Void {
		alive = true;
		exists = true;
	}

	@:noDebug public function followStrum(strum:StrumNote, downscroll:Bool, scrollSpeed:Float) {
		visible = strum.visible && strum.parent.visible;
		distance = hitTime * 0.45 * scrollSpeed;
		distance *= downscroll ? -1 : 1;

		if (copyAngle) angle = strum.angle;
 		if (copyAlpha) alpha = strum.alpha * multAlpha;

		if (copyX)
			x = strum.x;
		if (copyY)
			y = strum.y + correctionOffset.y + distance;
	}

	override public function drawComplex(camera:FlxCamera) {
		prepareMatrix(camera);
		camera.drawNote(_frame, _matrix, colorTransform, blend, antialiasing, luminColors);
	}
	
	@:allow(funkin.objects.Strumline)
	static var cachePoint = FlxPoint.get();

	public function drawCrazy(modchart:ModchartManager, downscroll:Bool, field:Strumline) {
		final strumline = data.player;
		final mult = downscroll ? -1 : 1;
		modchart.stealthColor.set(1.0, 1.0, 1.0);
		modchart.scrollMult = mult;
		
		final oldX = x;
		final oldY = y;
		final oldScaleX = scale.x;
		final oldScaleY = scale.y;

		var newDistance: Float = modchart.adjustDistance(this, distance * mult, data.lane, strumline, field, NOTE);
		
		var rawY:Float = y - distance;
		modchartPos.set(x + width * 0.5, (rawY + (newDistance * mult)) + height * 0.5, 0);

		modchart.adjustPos(this, modchartPos, newDistance, distance * mult, data.lane, strumline, field, NOTE);
		modchart.adjustScale(this, scale, newDistance, data.lane, strumline, field, NOTE); // TODO: add newDistance to the args of this and getStealth
		stealth = modchart.getStealth(this, newDistance, distance * mult, modchartPos, data.lane, strumline, field, NOTE);

		x = modchartPos.x - width * 0.5;
		y = modchartPos.y - height * 0.5;
		final layer = modchartPos.z;
		prepareMatrix(cameras[0]);
		_matrix.translate(cameras[0].scroll.x * scrollFactor.x, cameras[0].scroll.y * scrollFactor.y);
		x = oldX;
		y = oldY;
		scale.set(oldScaleX, oldScaleY);

		modchartVertices[0].set(_matrix.transformX(0, 0), _matrix.transformY(0, 0), modchartPos.z);
		modchartVertices[1].set(_matrix.transformX(_frame.frame.width, 0), _matrix.transformY(_frame.frame.width, 0), modchartPos.z);
		modchartVertices[2].set(_matrix.transformX(0, _frame.frame.height), _matrix.transformY(0, _frame.frame.height), modchartPos.z);
		modchartVertices[3].set(_matrix.transformX(_frame.frame.width, _frame.frame.height), _matrix.transformY(_frame.frame.width, _frame.frame.height), modchartPos.z);

		final orient:Float = modchart.get("orient", strumline);
		if(orient != 0){
			final orientOffset: Float = modchart.get("orientoffset", strumline);
			final cacheX:Float = modchartPos.x;
			final cacheY:Float = modchartPos.y;
			final cacheZ:Float = modchartPos.z;
			modchartPos.set(x + width * 0.5, (rawY + ((newDistance + 2) * mult)) + height * 0.5, 0);
			modchart.adjustPos(this, modchartPos, newDistance + 2, (distance * mult) + 2, data.lane, strumline, field, NOTE);

			cachePoint.set(modchartPos.x - cacheX, modchartPos.y - cacheY);
			cachePoint.rotateByDegrees(orientOffset);

			final diffX: Float = cachePoint.x;
			final diffY: Float = cachePoint.y;

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

		for (i => vert in modchartVertices) {
			modchart.adjustVertex(this, vert, modchartPos, newDistance, distance * mult, data.lane, strumline, field, NOTE);
			vert.project();
		}

		modchart.pushDraw(strumline, field, cameras, scrollFactor, _frame, Note.modchartVertices, colorTransform, blend, antialiasing, luminColors, stealth, layer);
	}

	override public function toString():String {
		return 'Lane ${data.lane} at ${data.time}';
	}
}
