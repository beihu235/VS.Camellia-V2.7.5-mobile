package funkin;

import lime.ui.KeyCode;
import lime.app.Application;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import funkin.states.PlayState;
import funkin.shaders.TileLine;
import funkin.backend.Meta.MetaFile;
import flixel.addons.display.FlxBackdrop;
import funkin.objects.Countdown;

class PauseMenu extends flixel.FlxSubState {
	public static final optionArr:Array<String> = ['Resume', 'Restart', 'Options', 'Back to Songlist'];

	var extraSpaceForTheTriangleRotatingThingie:Float = 30;
	var cacheAlpha:Float = 1;
	var cacheZoom:Float = 1;

	var leaving:Bool = false;
	var music:FlxAudio;
	var fadeTwn:FlxTween;
	var camBG:FunkinSprite; // pretending that the camera's bgColor is still existant
	var bg:FunkinSprite;
	var tile:FlxBackdrop;
	var piss:FlxTypedSpriteGroup<FlxText>;
	var selectTriangle:FunkinSprite;
	var optionBG:FunkinSprite;
	var longestWidth:Float = 0;
	var curScore:FlxText;
	var curScoreData:FlxText;

	public var curSelected:Int = 0;
	public static var musicPath:String = 'silver';

	var tips:Array<String> = [
		"Try not to pause too much! Most rhythm games punish you for doing so.",
		"Game feels offsync? Try changing your note offset in settings.",
		"Try staying calm in dense sections, to reduce combo brushing.",
		"Remember to take breaks every now and then, too much playing can cause carpal tunnel!",
		"Row keybinds (DFJK, ASKL, ZX,.) tend to help a lot more than WASD/arrow keys!",
		"If your hands feel cold, try running them under hot water. Playing with cold hands usually isn't the best idea!",
		"If it's too hard to read the notes, you can turn down the \"Game Visibility\" option in settings.",
		"Is the chart too overwhelming? Try switching to a lower difficulty - you'll naturally work your way back up with time."
	];
	
	var lineShader:TileLine;
	var songName:FlxText;
	var diffName:FlxText;
	var metaTxt:FlxText;
	var tipTxt:FlxText;
	var ranking:FlxText;

	var countdown:Countdown;

	var keys = ["ui_down", "ui_up", "accept", "back"];
	var held = [false, false, false, false];
	var wasResetingInputs:Bool;
	public function new() {
		super();
		wasResetingInputs = FlxG.inputs.resetOnStateSwitch;
		FlxG.inputs.resetOnStateSwitch = false;
	}

	override function create():Void {
		super.create();
		FlxG.inputs.resetOnStateSwitch = wasResetingInputs;
		Application.current.window.onKeyDown.add(input);
		Application.current.window.onKeyUp.add(release);
		for (i in 0...keys.length)
			held[i] = Controls.pressed(keys[i]);
		Conductor.pause();
		FlxG.timeScale = 1;
		cacheAlpha = PlayState.self.camHUD.alpha;
		cacheZoom = PlayState.self.camHUD.zoom;

		Main.tweenManager.forEach(function(twn:FlxTween) if (twn != null)
			twn.active = false);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (twn != null)
			twn.active = false);
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (tmr != null)
			tmr.active = false);
		
		music = FlxAudioHandler.loadAudio(Paths.audioPath(musicPath, 'music'), true, 0);

		add(camBG = new FunkinSprite());
		camBG.makeGraphic(1, 1, 0xFFFFFFFF);
		camBG.scale.set(FlxG.width, FlxG.height);
		camBG.updateHitbox();
		camBG.color = PlayState.self.camHUD.bgColor;
		camBG.alpha = 0;

		bg = new FunkinSprite();
		if (!Settings.data.reducedQuality) {
			bg.makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
			lineShader = new TileLine();
			lineShader.color1.value = [0, 0, 0, 0.375];
			lineShader.color2.value = [0, 0, 0, 0.5];
			lineShader.density.value = [200.0];
			lineShader.time.value = [0];
			bg.shader = lineShader;
		} else {
			bg.makeGraphic(1, 1, 0x80000000);
			bg.scale.set(FlxG.width, FlxG.height);
			bg.updateHitbox();
		}
		bg.alpha = 0;
		add(bg);

		piss = new FlxTypedSpriteGroup<FlxText>();
		piss.setPosition(100, 150);
		for (i in 0...optionArr.length) {
			final txt:FlxText = new FlxText(0, (i * 45), 0, optionArr[i].toUpperCase(), 40);
			txt.font = Paths.font('Rockford-NTLG Light.ttf');
			if (txt.width > longestWidth) longestWidth = txt.width;
			piss.add(txt);
		}

		tile = new FlxBackdrop(Paths.image('menus/PAUSED'), Y);
		tile.velocity.y = 25;
		tile.scale.set(0.5, 0.5);
		tile.updateHitbox();
		add(tile);

		songName = new FlxText(FlxG.width - 10, -10, 0, PlayState.self.songName.toUpperCase(), 75);
		songName.alignment = 'right';
		songName.font = Paths.font('HelveticaNowDisplay-Black.ttf');
		songName.scale.x = Math.min(FlxG.width - 20, songName.width * 1.15) / songName.width;
		songName.updateHitbox();
		songName.x -= songName.width;
		add(songName);

		diffName = new FlxText(-10, 0, FlxG.width, Difficulty.current.toUpperCase(), 30);
		diffName.alignment = 'right';
		diffName.font = Paths.font('Rockford-NTLG Extralight.ttf');
		diffName.y = (songName.y + songName.height) - 20;
		//diffName.x -= diffName.width;
		add(diffName);

		var meta:MetaFile = PlayState.song.meta;
		metaTxt = new FlxText(-10, 0, FlxG.width, 'from album: ${meta.album}\narrange: ${meta.vocalComposer}\nchart: ${meta.charter[Difficulty.current]}', 20);
		metaTxt.alignment = 'right';
		metaTxt.font = Paths.font('Rockford-NTLG Extralight.ttf');
		metaTxt.y = diffName.y + diffName.height;
		add(metaTxt);

		tipTxt = new FlxText(760, 0, 500, 'TIP: ' + tips[FlxG.random.int(0, tips.length - 1)], 20);
		tipTxt.font = Paths.font('Rockford-NTLG Extralight.ttf');
		tipTxt.alignment = 'right';
		tipTxt.y = (FlxG.height - tipTxt.height) - 20;
		add(tipTxt);

		ranking = new FlxText(75, 0, 0, "?");
		ranking.alpha = 0.5;
		ranking.setFormat(Paths.font("menus/bozonBI.otf"), 200, 0xFFFFFFFF);
		var scoreTxt = 'hit a\nnote\nbum';
		if (PlayState.self.notesHit > 0) {
			final rank = Ranking.getFromAccuracy(PlayState.self.accuracy);
			ranking.color = rank.color;
			ranking.text = rank.name;
			ranking.y = FlxG.height - (ranking.height - 50);
			add(ranking);
			scoreTxt = '${PlayState.self.score}\n${PlayState.self.comboBreaks}\n${Util.truncateFloat(PlayState.self.accuracy, 2)}%';
		}

		add(curScore = new FlxText(piss.x , (piss.y + piss.height) + 20, longestWidth, 'Deaths:\nScore:\nCombo Breaks:\nAccuracy:', 28));
		curScore.font = Paths.font('Rockford-NTLG Light.ttf');
		curScore.color = FlxColour.GRAY;
		add(curScoreData = new FlxText(curScore.x, curScore.y, curScore.fieldWidth, '${PlayState.deaths}\n' + scoreTxt, 28));
		curScoreData.font = Paths.font('Rockford-NTLG Light.ttf');
		curScoreData.alignment = RIGHT;
		curScoreData.color = curScore.color;

		add(optionBG = new FunkinSprite(piss.x - extraSpaceForTheTriangleRotatingThingie, piss.y));
		optionBG.makeGraphic(1, 1, FlxColor.WHITE);
		optionBG.origin.set();

		add(selectTriangle = new FunkinSprite(0, 0, Paths.image("menus/triangle")));
		selectTriangle.color = 0xFF000000;
		selectTriangle.flipX = true;
		selectTriangle.origin.x += 3; // UUUUUGGGGGGGGHHHHHHHHH
		selectTriangle.setGraphicSize(Std.int(selectTriangle.width * 0.6));

		add(piss);

		add(countdown = new Countdown());
		countdown.screenCenter();

		changeSelection();

		music.play();
		fadeTwn = FlxTween.num(0, 1, 0.5, {ease: FlxEase.quadOut}, function(num) {
			if (!exists) return;
			PlayState.self.camHUD.alpha = cacheAlpha * (1 - num);
			PlayState.self.camHUD.zoom = cacheZoom + 0.15 * num;
			music.volume = num;
			
			final daAlpha = PlayState.self.camHUD.bgColor.alphaFloat * PlayState.self.camHUD.alpha;
			camBG.alpha = (daAlpha == 1) ? 0 : (PlayState.self.camHUD.bgColor.alphaFloat - daAlpha) / (1 - daAlpha);
			bg.alpha = num;

			songName.x = FlxG.width - 10 + 45 * (1 - num) - songName.width;
			diffName.offset.x = metaTxt.offset.x = tipTxt.offset.x = -45 * (1 - num);
			songName.alpha = diffName.alpha = metaTxt.alpha = tipTxt.alpha = num;

			curScore.x = curScoreData.x = 55 + 45 * num;
			curScore.alpha = curScoreData.alpha = num;

			ranking.x = 30 + 45 * num;
			ranking.alpha = num * 0.5;

			piss.x = 120 - 20 * num;
			piss.alpha = num;

			tile.alpha = num;
		});
	}

	override function update(delta:Float):Void {
		super.update(delta);

		optionBG.scale.x = FlxMath.lerp(optionBG.scale.x, longestWidth + 20 + extraSpaceForTheTriangleRotatingThingie, delta * 15);
		selectTriangle.x = FlxMath.lerp(selectTriangle.x, optionBG.x + 5, delta * 15);

		if (!Settings.data.reducedQuality) {
			lineShader.time.value[0] = lineShader.time.value[0] + (delta / 64);
			selectTriangle.angle += delta * 160;
		}
	}

	function input(key:KeyCode, _) {
		final id = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (id < 0 || (held[id] && id >= 2)) return;
		held[id] = true;

		switch (id) {
			case 0 | 1: // ui_down | ui_up
				if (countdown.active) return;
				changeSelection(id == 0 ? 1 : -1);
				FlxG.sound.play(Paths.audio("menu_move", "sfx"));
			case 2: // accept
				if (countdown.active) {
					countdown.stop();
					return;
				}

				switch (optionArr[curSelected]) {
					case 'Resume':
						unpause();
					case 'Restart':	
						removeInputs();
						Util.cancelAllTimers();
						Util.cancelAllTweens();
						add(new BasicBorderTransition(TOP, false, 0.5, 0.5, function() {
							FlxG.resetState();
						}));
					case 'Options':
						removeInputs();
						OptionsState.inPlayState = true;

						add(new BasicBorderTransition(BOTTOM, false, 0.5, 0.5, function() {
							FlxG.switchState(new OptionsState());
						}));
					case 'Back to Songlist':
						leaving = true;
						removeInputs();
						close();
						Conductor.stop();
						PlayState.self.endSong(true);
				}
			case 3: // back
				if (countdown.active) {
					countdown.stop();
					return;
				}
				unpause();
		}
	}

	inline function removeInputs() {
		Application.current.window.onKeyDown.remove(input);
		Application.current.window.onKeyUp.remove(release);
	}

	function release(key:KeyCode, _) {
		final id = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (id < 0) return;
		held[id] = false;
	}

	override function destroy() {
		FlxAudioHandler.music.pause();
		music.destroy();

		super.destroy();
		Main.tweenManager.forEach(function(twn:FlxTween) if (twn != null)
			twn.active = !leaving);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (twn != null)
			twn.active = !leaving);
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (tmr != null)
			tmr.active = !leaving);
	}

	function unpause() {
		var percent = fadeTwn.scale;
		fadeTwn.cancel();
		var curScaleX = optionBG.scale.x;
		fadeTwn = FlxTween.num(percent, 0, 0.25, {ease: FlxEase.cubeOut, onComplete: function(twn) {
			countdown.start();
			countdown.onFinish = function() {
				removeInputs();
				close();
				PlayState.self.playfield.refreshInputs();
				FlxG.timeScale = Settings.data.gameplayModifiers["playbackRate"];
				Conductor.resume();
				PlayState.self.paused = false;
			};
			countdown.onTickHandlers.push(function(tick:Int){
				if(tick == 1) PlayState.self.camOther.flash(0x62ffffff);
			});
		}}, function(num) {
			PlayState.self.camHUD.alpha = cacheAlpha * (1 - num);
			PlayState.self.camHUD.zoom = cacheZoom + 0.15 * num;
			music.volume = num;

			final daAlpha = PlayState.self.camHUD.bgColor.alphaFloat * PlayState.self.camHUD.alpha;
			camBG.alpha = (daAlpha == 1) ? 0 : (PlayState.self.camHUD.bgColor.alphaFloat - daAlpha) / (1 - daAlpha);
			bg.alpha = num;

			songName.x = FlxG.width - 10 + 45 * (1 - num) - songName.width;
			diffName.offset.x = metaTxt.offset.x = tipTxt.offset.x = -45 * (1 - num);
			songName.alpha = diffName.alpha = metaTxt.alpha = tipTxt.alpha = num;

			curScore.x = curScoreData.x = 55 + 45 * num;
			curScore.alpha = curScoreData.alpha = num;

			ranking.x = 30 + 45 * num;
			ranking.alpha = num * 0.5;

			piss.x = 120 - 20 * num;
			piss.alpha = num;

			tile.alpha = num;

			optionBG.scale.x = curScaleX * num;

			optionBG.alpha = num;
			selectTriangle.alpha = num;
		});
	}

	function changeSelection(?dir:ByteInt = 0) {
		piss.members[curSelected].color = 0xFFFFFFFF;
		piss.members[curSelected].font = Paths.font('Rockford-NTLG Light.ttf');
		curSelected = FlxMath.wrap(curSelected + dir, 0, piss.length - 1);
		piss.members[curSelected].color = 0xFF000000;
		piss.members[curSelected].font = Paths.font('Rockford-NTLG Medium.ttf');

		var curText:FlxText = piss.members[curSelected];
		optionBG.scale.set(0, curText.height - 5);
		optionBG.y = curText.y;
		selectTriangle.setPosition(curText.x, optionBG.y + (optionBG.scale.y - selectTriangle.height) * 0.5);
	}
}
