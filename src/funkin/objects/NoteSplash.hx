package funkin.objects;

import funkin.objects.Strumline;
import funkin.modchart.ModchartManager;

typedef NoteSplashDataFile = {
	name: String,
	image: String,
	?animations: Array<Array<String>>,
	?framerate: Float,
	?scale: Array<Float>,
	?offset: Array<Float>
}

@:structInit 
class NoteSplashData {
	public var name: String = 'Fallback';
	public var image: String = 'classic';
	public var animations: Array<Array<String>> = [];
	public var framerate: Float = 24;
	public var scale: Array<Float> = [0.7, 0.7];
	public var offset: Array<Float> = [10, 10];

	// should we make a cache for this that gets cleared on state switch? just so we aren't holding onto 4 seperate instances
	// (it'd save us like BYTES of memory so probably not worth it tbh :sob:)

	public static function get(name: String): NoteSplashData
	{
		var fileContent:String = Paths.getFileContent('data/noteSplashes/$name.json5');
		if (fileContent == '') fileContent = Paths.getFileContent('data/noteSplashes/$name.json');
		if (fileContent == '') return {};
		
		var dataFile: NoteSplashDataFile = Json5.parse(fileContent);
		
		return {
			name: dataFile.name,  // TODO: allow localization, maybe thru like data.localizationKey or some shit
			image: dataFile.image,
			animations: dataFile.animations ?? [],
			framerate: dataFile.framerate ?? 24.0,
			scale: dataFile.scale ?? [0.7, 0.7],
			offset: dataFile.offset ?? [10, 10]
		}
	}

	public function modifySplash(splash: NoteSplash) {
		splash.frames = Paths.sparrowAtlas('noteSplashes/$image');

		if(animations.length == 0){
			var colour:String = Note.colours[splash.lane];
			splash.animation.addByPrefix('hit1', 'note splash $colour 1', framerate, false);
			splash.animation.addByPrefix('hit2', 'note splash $colour 2', framerate, false);
			splash.animation.play('hit1');
			splash.animationCount = 2;
		}else{
			final animations: Array<String> = animations[splash.lane % animations.length];
			for(idx in 0...animations.length){
				final anim: String = animations[idx];

				splash.animation.addByPrefix('hit$idx', anim, framerate, false);
				splash.animationCount++;
			}
			splash.animation.play('hit1');
		}

		splash.targetFramerate = framerate;
		splash.scale.set(scale[0] ?? 0.7, scale[1] ?? 0.7);
		splash.updateHitbox();
		splash.offset.set(offset[0] ?? 0.0, offset[1] ?? 0.0);
		splash.visible = false;
	}
}

class NoteSplash extends FunkinSprite {
	//public static var possibleNotesplashes: Array<String> = ['none']; // idk maybe we move this some day lmao
	//public static var notesplashNames: Map<String, String> = ['none' => 'None'];

	public var animationCount: Int = 2;
	public var targetFramerate: Float = 24;

	public var skin(default, set):String;
	public var modchartPos:Vector3 = new Vector3();
	public var stealth:Float = 0;
	public var luminColors:Bool = false;
	public var lane:Int = 0;
	function set_skin(value:String):String {
		reload(value);
		return skin = value;
	}

	public function new(lane:Int, ?skin:String) {
		super();
		this.lane = lane;
		reload(skin);
		alpha = 0.6;

		animation.finishCallback = function(_) {
			visible = false;
		}
	}

	public var data: NoteSplashData = {}; // fallback

	public function reload(?name:String) {
		name ??= ''; // thanks hl i guess ??? lmao
		if (name.length == 0)
			name = Util.format(Settings.data.noteSplashSkin);
		else if (Paths.exists('images/$name.png')){ // just incase

			frames = Paths.sparrowAtlas(name);

			var colour:String = Note.colours[lane];
			animation.addByPrefix('hit1', 'note splash $colour 1', 24, false);
			animation.addByPrefix('hit2', 'note splash $colour 2', 24, false);
			animation.play('hit1');
		
			scale.set(0.7, 0.7);
			updateHitbox();
			offset.set(10, 10);

			visible = false;
			
			return;
		}
		

		data = NoteSplashData.get(name);
		data.modifySplash(this);

	}

	public function hit(strum:StrumNote) {
		visible = true;
		playAnim('hit${FlxG.random.int(1, animationCount)}');
		updateHitbox();
		setPosition(strum.x + (strum.width - width) * 0.5, strum.y + (strum.height - height) * 0.5);

		animation.curAnim.frameRate = Math.floor(targetFramerate * FlxG.random.float(0.91, 1.08)); // on 24 fps, this is 22-26
	}

/* 	override function draw() {
		if (PlayState.self != null && PlayState.self.playfield.modchart != null) {
			final play = PlayState.self.playfield;
			drawCrazy(play.modchart, play.playerID, play.currentPlayer);
			return;
		}
		super.draw();
	} */

	override public function drawComplex(camera:FlxCamera) {
		prepareMatrix(camera);
		camera.drawNote(_frame, _matrix, colorTransform, blend, antialiasing, luminColors);
	}

	// ive had to copy this func so many times dear lord i shoulda made a note object
	public function drawCrazy(modchart:ModchartManager, strumline:Int, downscroll:Bool, field:Strumline) {
		final oldX = x;
		final oldY = y;
		final oldScaleX = scale.x;
		final oldScaleY = scale.y;
		final mult: Float = downscroll ? -1 : 1;
		modchart.stealthColor.set(1.0, 1.0, 1.0);
		modchart.scrollMult = mult;

		final distance: Float = modchart.adjustDistance(this, 0, ID, strumline, field, STRUM);
		modchartPos.set(x + width * 0.5, y + height * 0.5 + (distance * mult), 0);
		modchart.adjustPos(this, modchartPos, distance, 0, lane, strumline, field, STRUM);
		modchart.adjustScale(this, scale, distance, lane, strumline, field, STRUM);
		stealth = modchart.getStealth(this, distance, 0, modchartPos, lane, strumline, field, STRUM);

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

		for (vert in Note.modchartVertices) {
			modchart.adjustVertex(this, vert, modchartPos, distance, 0, ID, strumline, field, STRUM);
			vert.project();
		}

		modchart.pushDraw(strumline, field, cameras, scrollFactor, _frame, Note.modchartVertices, colorTransform, blend, antialiasing, luminColors, stealth, layer, true);
	}
}