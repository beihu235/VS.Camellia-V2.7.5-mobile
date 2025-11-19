package funkin.objects;

typedef CharacterFile = {
	var antialiasing:Bool;
	var flipX:Bool;
	var icon:String;
	var scale:Float;
	var singDuration:Float;
	var healthColor:FlxColor;
	var sheets:String;
	var offset:Array<Float>;
	var danceInterval:Int;
	var reflectionOffset:Int;

	var animations:Array<CharacterAnim>;
}

typedef CharacterAnim = {
	var name:String;
	var id:String;
	var indices:Array<Int>;
	var framerate:Int;
	var looped:Bool;
	var offsets:Array<Float>;
}

class Character extends FunkinSprite {
	public static inline var default_name:String = 'bf';
	public var name:String = default_name;
	public var singDuration:Float = 4;
	public var danceInterval:ByteInt = 2;
	public var healthColor:FlxColor = 0xFFA1A1A1;
	public var sheets:Array<String> = [];
	public var icon:String = '';
	public var dancer:Bool = false;
	public var autoIdle:Bool = true;
	//i'll be honest, i want to implement a -player tag to the name of the png/xml
	//to load all the character and the death/miss animations
	//prob in a later commit unless rudy or srt do it before me
	public var dead:Bool = false;
	public var reflective:Bool = true;
	public var specialAnim:Bool = false;

	public var reflectionY:Int = 0; //i'll use a smaller type of number to save some memory
	var _file:CharacterFile;

	public function new(?x:Float, ?y:Float, ?name:String, ?player:Bool = true, ?hasReflection:Bool = true) {
		name ??= default_name;
		super(x, y);

		var path:String = Paths.get('characters/$name.json');
		if (!FileSystem.exists(path)) {
			trace('character path "$path" doesn\'t exist');
			name = default_name;
		}
		path = Paths.get('characters/$name.json');

		_file = getFile(path);

		this.name = name;
		this.reflective = Settings.data.reflections && hasReflection;
		this.singDuration = _file.singDuration;
		this.healthColor = _file.healthColor;
		this.sheets = _file.sheets.split(',');
		this.icon = _file.icon;
		this.danceInterval = _file.danceInterval;
		this.reflectionY = _file.reflectionOffset;
		flipX = _file.flipX;
		antialiasing = _file.antialiasing;

		frames = Paths.multiAtlas(this.sheets);

		for (fnfAnim in _file.animations) {
			if (isAnimate && library != null && library.getSymbol(fnfAnim.id) != null) {
				if (fnfAnim.indices.length == 0) {
					anim.addBySymbol(fnfAnim.name, fnfAnim.id, fnfAnim.framerate, fnfAnim.looped);
				} else {
					anim.addBySymbolIndices(fnfAnim.name, fnfAnim.id, fnfAnim.indices, fnfAnim.framerate, fnfAnim.looped);
				}
			} else {
				if (fnfAnim.indices.length == 0) {
					animation.addByPrefix(fnfAnim.name, fnfAnim.id, fnfAnim.framerate, fnfAnim.looped);
				} else {
					animation.addByIndices(fnfAnim.name, fnfAnim.id, fnfAnim.indices, '', fnfAnim.framerate, fnfAnim.looped);
				}
			}

			offsetMap.set(fnfAnim.name, fnfAnim.offsets);
		}

		scale.set(_file.scale, _file.scale);
		updateHitbox();
		offset.set(_file.offset[0] * scale.x, _file.offset[1] * scale.y);

		if (animation.exists('danceLeft') || animation.exists('danceRight')) {
			danceList = ['danceLeft', 'danceRight'];
			dancer = true;
		} else danceList = ['idle'];

		animation.finishCallback = anim -> {
			specialAnim = false;
			if (!animation.exists('$anim-loop')) return;
			animation.play('$anim-loop');
		}

		dance(true);
	}

	public var dancing(get, never):Bool;
	function get_dancing():Bool {
		return animation.curAnim != null && (danceList.contains(animation.curAnim.name) || loopDanceList.contains(animation.curAnim.name));
	}

	var _singTimer:Float = 0.0;
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (!autoIdle || specialAnim || dancing || dead) return;

		_singTimer -= elapsed * (singDuration * (Conductor.stepCrotchet * 0.25));
		if (_singTimer <= 0.0) dance(true);
	}

	var animIndex:Int = 0;
	var danceList(default, set):Array<String>;
	var loopDanceList:Array<String>;
	// there could be a better way of detecting looped dancing butttttt
	function set_danceList(value:Array<String>):Array<String> {
		loopDanceList = [for (anim in value) '$anim-loop'];
		return danceList = value;
	}
	public function dance(?forced:Bool = false) {
		if (!forced && animation.curAnim == null) return;

		// support for gf/spooky kids characters
		if (dancer && !forced) forced = dancing;

		var finished:Bool = animation.curAnim?.finished ?? true;
		var looped:Bool = animation.curAnim?.looped ?? false;
		if (!forced && ((dancing && (!looped && !finished)) || _singTimer > 0.0)) return;

		playAnim(danceList[animIndex]);
		animIndex = FlxMath.wrap(animIndex + 1, 0, danceList.length - 1);
	}

	override function updateHitbox():Void {
		var oldOffset:FlxPoint = FlxPoint.get();
		oldOffset.copyFrom(offset);
		super.updateHitbox();
		offset.copyFrom(oldOffset);
		oldOffset.put();
	}

	override function playAnim(name:String, ?forced:Bool = true, ?suffix:String = "") {
		super.playAnim(name, forced, suffix);
		if (name.startsWith('sing') || name.startsWith('miss')) {
			_singTimer = singDuration * (Conductor.stepCrotchet * 0.15);
		}
	}

	public static function createDummyFile():CharacterFile {
		return {
			antialiasing: true,
			flipX: false,
			icon: 'face',
			scale: 1,
			singDuration: 4,
			healthColor: 0xFFA1A1A1,
			danceInterval: 2,
			sheets: 'characters/bf',
			reflectionOffset: 0,
			offset: [0, 0],

			animations: [
				{
					name: 'name',
					id: 'id',
					indices: [],
					framerate: 24,
					looped: false,
					offsets: [0, 0]
				}
			],
		}
	}

	static function getFile(path:String):CharacterFile {
		var file:CharacterFile = createDummyFile();
		if (!FileSystem.exists(path)) return file;
		
		var data = Json5.parse(File.getContent(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		return file;
	}

	public var reflectionAlpha:Float = 0.25;
	public var isVisible(get, never):Bool;
	
	inline function get_isVisible() return visible && alpha > 0;
	
	//this function fixes flickering when the character is at the edge of the screen
	//i'll see later if saving the camera where the character is will let us get rid of the for loop
	override function isOnScreen(?camera:FlxCamera):Bool{
		for (c in cameras)
			if (c.visible && c.exists && super.isOnScreen(c))
				return true;
		return false;
			//return cameras.any(c -> c.visible && c.exists /*&& super.isOnScreen(c)*/);
	}
	
	override function draw() {
		if (!reflective) {
			super.draw();
			return;
		}

		// Handle reflection drawing if enabled
		if (isOnScreen() && isVisible && reflectionAlpha > 0 && !dead)
			drawReflection();
	
		// Draw the character again but normally
		super.draw();
	}
	
	// Save original properties
	var originalAlpha:Float;
	var offsetY:Float;
	//also to save some processing (and memory), i'll disable the x offset, since it's not needed
	//unless we want to make use of complex lighting
	//rn i'm still really disgusted and don't have the energy to code a lot...
	private function drawReflection():Void {
		// Save original properties
		originalAlpha = alpha;
		offsetY = frameOffset.y;

		// Apply reflection transformations
		alpha *= reflectionAlpha;
		frameOffset.y = 0;
		//scale.y = -scale.y;
		//let's see if flipY works better
		flipY = !flipY;
		y += height - reflectionY;
	
		// Draw the reflection
		super.draw();
	
		// Restore original properties
		alpha = originalAlpha;
		frameOffset.y = offsetY;
		flipY = !flipY; //yup, it does
		y -= height - reflectionY;
		
	}
}
