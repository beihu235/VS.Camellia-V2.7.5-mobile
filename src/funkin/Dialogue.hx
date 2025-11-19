package funkin;

import funkin.objects.ui.SkewyLine;
import flixel.addons.text.FlxTypeText;

@:structInit
@:publicFields
class DialogueFile {
	var characters:Array<DialogueCharPos> = [{name: "camellia"}, {name: "bf", ratio: 1}];
	var list:Array<DialogueLine> = [];
}

@:structInit
@:publicFields
class DialogueCharPos {
	var name:String = 'camellia';
	var ratio:Float = 0;
	var offsetX:Float = 0;
	var startingExpression:String = 'idle';
}

@:structInit
@:publicFields
class DialogueLine {
	var text:String = 'balls';
	var font:String;
	var side:Int = 0;
	var speed:Float = 0.035;
	var volume:Float = 1;
	var expression:String = 'default';
	var color:FlxColor = 0xFFFFFFFF;
}

class Dialogue extends FlxSubState {
	public static var fromMenu:Bool = false;
	public var paused:Bool = false;

	var _file:DialogueFile;
	var _index:Int = 0;
	var list:Array<DialogueLine> = [];
	var characters:Array<DialogueCharacter> = [];
	var charsLayered:FlxTypedSpriteGroup<DialogueCharacter>;
	var bg:FunkinSprite;
	var tipText:FlxText;
	var curText:FlxTypeText;
	var textLines:SkewyLine;
	var textBg:FunkinSprite;
	var selectTriangle:FunkinSprite;
	var name:FlxText;
	var curFont:String = '';
	var finished:Bool = false;
	var textFinished:Bool = true;

	public dynamic function onFinish() {}
	public dynamic function onClose() {}
	public dynamic function onNewMessage(id:Int, line:DialogueLine) {}
	public function new(songID:String, ?fileName:String = 'dialogue') {
		super();
		
		_file = getFile(songID, fileName);
		for (line in _file.list) list.push(line);

		add(bg = new FunkinSprite().makeGraphic(1, 1, FlxColour.BLACK));
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0.6;

		if (!Settings.data.reducedQuality) {
			add(textLines = new SkewyLine([62, 1, 1129, 1, 1129 - 62, 232, 0, 232])); // numbers pulled from img corners
			textLines.intensityX = 1;
			textLines.intensityY = 4;
		}

		textBg = new FunkinSprite(0, 450, Paths.image('ui/dialogue box'));
		textBg.screenCenter(X);
		if (textLines != null)
			textLines.setPosition(textBg.x, textBg.y);

		add(charsLayered = new FlxTypedSpriteGroup<DialogueCharacter>());
		for (i => pos in _file.characters) {
			var char = new DialogueCharacter(pos.name);
			char.playAnim(pos.startingExpression);
			characters.push(char);
			char.ratio = pos.ratio;
			char.x = textBg.x + (textBg.width - char.width) * pos.ratio + pos.offsetX;
		}

		add(textBg);
		var nameplate = new FunkinSprite(textBg.x + 140, textBg.y - 15, Paths.image('ui/dialogue nameplate'));
		add(nameplate);

		add(name = new FlxText(nameplate.x, nameplate.y + 5, nameplate.width, 'fuck', 20));
		name.font = Paths.font('HelveticaNowDisplay-Black.ttf');
		name.alignment = 'center';
		name.color = 0xFF000000;

		add(curText = new FlxTypeText(textBg.x + 65, textBg.y + 60, Std.int(textBg.width - 80), '', 25));
		curText.font = Paths.font('Rockford-NTLG Light.ttf');
		curText.active = false;
		curText.completeCallback = function() textFinished = true;

		add(selectTriangle = new FunkinSprite((textBg.x + textBg.width) - 100, (textBg.y + textBg.height) - 40, Paths.image("menus/triangle")));
		selectTriangle.color = 0xFFFFFFFF;
		selectTriangle.flipX = true;
		selectTriangle.scale.set(0.75, 0.75);
		selectTriangle.updateHitbox();
		selectTriangle.origin.x += 3; // UUUUUGGGGGGGGHHHHHHHHH

		add(tipText = new FlxText(0, 0, 0, '(Press Z/ENTER to confirm, X/SHIFT to skip!)', 16));
		tipText.font = Paths.font('Rockford-NTLG Light.ttf');
		tipText.y = FlxG.height - tipText.height;

		updateLine();

		add(new BasicBorderTransition(fromMenu ? BOTH : BOTTOM, true, 0.5, 0));
	}

	override function update(delta:Float) {
		super.update(delta);

		if (textLines != null)
			textLines.speed = FlxMath.lerp(textLines.speed, 1, delta * 15);

		if (!Settings.data.reducedQuality) {
			selectTriangle.angle += delta * 160;
		}
		selectTriangle.visible = textFinished;

		if (finished || paused) return;

		if (Controls.justPressed('skip_dialogue') && !textFinished) curText.skip();

		if (Controls.justPressed('next_dialogue') && textFinished) {
			_index++;
			updateLine();
		}

		curText.update(delta);

		if (_index >= list.length) {
			onFinish();
			finished = true;
			close();
		}
	}

	override function close() {
		var fadeTime:Float = 1;
		for (obj in members) {
			if (obj is FlxSprite)
				FlxTween.tween(obj, {alpha: 0}, fadeTime);
		}
		new FlxTimer().start(fadeTime, fuck);
	}

	// i love haxe
	function fuck(_) {
		onClose();
		super.close();
	}

	function updateLine() {
		if (_index >= list.length) return;

		if (_index == 1) {
			FlxTween.tween(tipText, {alpha: 0}, 1, {onComplete: function(_) {
				remove(tipText);
				tipText = null;
			}});
		}

		var curLine = list[_index];
		var curCharacter = characters[curLine.side];
		if (charsLayered.members.contains(curCharacter)) {
			charsLayered.remove(curCharacter, true);
			curCharacter.y -= 30;
			FlxTween.tween(curCharacter, {y: curCharacter.y + 30}, 0.25, {ease: FlxEase.backIn});
		} else {
			final xInc:Float = curCharacter.ratio >= 0.5 ? 100 : -100;
			curCharacter.x += xInc;
			curCharacter.alpha = 0;
			FlxTween.tween(curCharacter, {x: curCharacter.x - xInc, alpha: 1}, 0.25, {ease: FlxEase.quartOut});
		}
		charsLayered.add(curCharacter);

		curText.resetText(curLine.text);
		curText.sounds = curCharacter.sounds;
		curText.color = curLine.color;
		curText.delay = curLine.speed;
		curText.volume = curLine.volume;
		curText.start();
		if (curFont != curLine.font && curLine.font.length != 0) {
			curFont = curLine.font;
			curText.font = Paths.font('$curFont.ttf');
		}

		textFinished = false;

		name.text = curCharacter.displayName.toUpperCase();

		if (curCharacter.animation.exists(curLine.expression))
			curCharacter.playAnim(curLine.expression);

		for (i => character in characters) {
			character.alpha = 0.5;
			if (i == curLine.side) character.alpha = 1;
		}

		if (textLines != null)
			textLines.speed = 15;
		onNewMessage(_index, curLine);
	}

	public static function fileExists(songID:String, ?fileName:String = 'dialogue'):Bool {
		trace('songs/$songID/$fileName.json');
		if (!Paths.exists('songs/$songID')) return false;

		return Paths.exists('songs/$songID/$fileName.json');
	}

	public static function getFile(songID:String, fileName:String):DialogueFile {
		var file:DialogueFile = {};
		if (!fileExists(songID, fileName)) return file;

		var rawData = Json5.parse(Paths.getFileContent('songs/$songID/$fileName.json'));
		// for (field in Reflect.fields(rawData)) {
		// 	if (!Reflect.fields(file).contains(field) || field == 'list' || field == 'characters') continue;
		// 	Reflect.setField(file, field, Reflect.field(rawData, field));
		// }

		if (rawData.characters != null) {
			file.characters = [];
			for (char in cast (rawData.characters, Array<Dynamic>)) {
				var pos:DialogueCharPos = {};
				pos.name = char.name ?? "camellia";
				pos.ratio = char.ratio ?? 0.0;
				pos.offsetX = char.offsetX ?? 0.0;
				pos.startingExpression = char.startingExpression ?? "idle";
				file.characters.push(pos);
			}
		}

		if (rawData.list != null) {
			var list:Array<{text:String, side:Int, font:String, speed:Float, volume:Float, expression:String, color:FlxColor}> = rawData.list;
			for (line in list) {
				file.list.push({
					text: line.text,
					side: line.side,
					font: line.font ?? '',
					speed: line.speed,
					volume: line.volume,
					expression: line.expression,
					color: line.color
				});
			}
		}
		return file;
	}
}

@:structInit
@:publicFields
class DialogueCharacterFile {
	var sound:String = 'default';
	var expressionOffsets:Array<Array<Float>> = [[0, 0]];
	var expressions:Array<String> = ['default'];
	var sprite:String = 'default';
	var name:String = 'Unknown';
	var width:Int = 250;
	var height:Int = 250;
	var offset:Array<Float> = [0, 0];
	var isSparrow:Bool = true;
}

class DialogueCharacter extends FunkinSprite {
	public var name:String;
	public var ratio:Float;
	public var sounds:Array<FlxSound> = [];
	public var expressions:Array<String>;
	public var displayName:String;
	public var isSparrow:Bool;
	public function new(name:String) {
		super();

		this.name = name;

		var file:DialogueCharacterFile = getFile(name);
		expressions = file.expressions;
		for (i in 0...expressions.length)
			setOffset(expressions[i], file.expressionOffsets[i]);

		if (file.sound != 'none') {
			var path:String = 'sfx/dialogue/${file.sound}';
			if (!Paths.isDirectory(path)) {
				sounds.push(FlxG.sound.load(Paths.audio(file.sound, 'sfx/dialogue')));
			} else {
				for (i in 0...Paths.readDirectory(path).length - 1) {
					sounds.push(FlxG.sound.load(Paths.audio('$path/$i')));
				}
			}
		}

		displayName = file.name;
		isSparrow = file.isSparrow;

		if (isSparrow) {
			frames = Paths.sparrowAtlas(file.sprite);
			for (expr in expressions)
				animation.addByPrefix(expr, expr, 24, true);
		} else {
			loadGraphic(Paths.image(file.sprite), true, file.width, file.height);
			for (i in 0...expressions.length)
				animation.add(expressions[i], [i]);
		}
		playAnim(expressions[0]);

		offset.set(file.offset[0], file.offset[1]);
	}

	public static function getFile(name:String):DialogueCharacterFile {
		var file:DialogueCharacterFile = {};
		if (!Paths.exists('dialogueCharacters/$name.json')) return file;

		var rawData = Json5.parse(Paths.getFileContent('dialogueCharacters/$name.json'));
		for (field in Reflect.fields(rawData)) {
			if (field == "expressions" || !Reflect.fields(file).contains(field)) continue;
			Reflect.setField(file, field, Reflect.field(rawData, field));
		}

		var expressions:Array<Dynamic> = cast Reflect.field(rawData, "expressions");
		for (i in 0...(expressions == null ? 0 : expressions.length)) {
			if (expressions[i] is String) {
				file.expressions.push(expressions[i]);
				file.expressionOffsets.push([0, 0]);
				continue;
			}

			file.expressions.push(expressions[i].name);
			var offsets:Array<Float> = cast expressions[i].offsets;
			file.expressionOffsets.push((offsets != null && offsets.length >= 2) ? offsets : [0, 0]);
		}

		return file;
	}
}