package funkin.states;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import funkin.backend.Song.Chart;
import funkin.objects.*;
import funkin.backend.EventHandler;
import funkin.objects.Strumline.StrumNote;
import funkin.Dialogue;

@:structInit class NoteHit {
	public var time:Float;
	public var diff:Float;
	public var color:FlxColor;
}

class PlayState extends FunkinState {
	public static var songID:String = 'tremendous';
	public var songName:String = '';
	public static var song:Chart;
	public static var self:PlayState;
	//static var weekData:WeekFile;
	public static var deaths:Int = 0;

	public static var inTransition:Bool = false;
	public static var songList:Array<String> = [];
	public static var storyMode:Bool = false;
	public static var currentLevel:Int = 0;
	public var paused:Bool = false;
	var extraTime:Float = 2500; 

	var noteSkin:String;

	public var noteHitList:Array<NoteHit> = [];
	public var score:Int = 0;
	var maxScore:Int = 1000000;
	public var comboBreaks:Int = 0;
	var combo:Int = 0;
	public var accuracy:Float = 0.0;
	var health(default, set):Float = 50;
	function set_health(value:Float):Float {
		if ((playfield.playerID == 1 && value <= 0) || (playfield.playerID == 0 && value >= 100))
			death();
		value = FlxMath.bound(value, 0, 100);

		// update health bar
		health = value;
		healthBar.percent = FlxMath.remapToRange(FlxMath.bound(health, healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);

		iconP1.animation.curAnim.curFrame = healthBar.percent < 20 ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = healthBar.percent > 80 ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)

		return health = value;
	}

	@:unreflective var disqualified:Bool = false;

	@:isVar public var botplay(get, set):Bool = false;

	var metronome:Bool = false;
	function set_botplay(value:Bool):Bool {
		// prevents players from just having botplay on the entire time
		// and then turning it off at the last note
		// and saving the play
		if (value) disqualified = true;

		playfield.botplay = value;
		botplayTxt.visible = value;
		return botplay = value;
	}

	function get_botplay():Bool {
		if (playfield == null) return false;
		// preventing someone doing `game.playfield.botplay = true;`
		// to get around disqualifying
		if (playfield.botplay) disqualified = true;
		return playfield.botplay;
	}

	var clearType:String;

	public var totalNotes:Int;
	public var notesHit:Int = 0;
	public var notesPlayed:Float = 0.0;

	var gfSpeed:Int = 1;

	public var playfield:PlayField;
	public var playerStrums:Strumline;
	public var opponentStrums:Strumline;
	var characterCache:Map<String, Character> = [];

	var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;

	var eventHandler:EventHandler;

	var judgeSpr:JudgementSpr;
	var comboNumbers:ComboNums;

	var ranking:FlxText;
	var judgeCounter:FlxText;
	var timingIndicator:FlxText;

	var hud:FlxSpriteGroup;

	var noteCamOffset:Array<FlxPoint> = [
		FlxPoint.get(-10, 0),
		FlxPoint.get(0, 10),
		FlxPoint.get(0, -10),
		FlxPoint.get(10, 0)
	];
	var noteCamDelay:Float = 0;

	var scoreTxt:FlxText;
	var healthBar:Bar;

	var iconP1:CharIcon;
	var iconP2:CharIcon;

	var downscroll:Bool = false;

	var botplayTxt:FunkinSprite;
	var stageName:String;

	var characters:FlxTypedSpriteGroup<Character>;

	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;

	var hitErrorBar:HitErrorBar;

	var camFollow:FlxObject;

	public var bf:Character;
	public var dad:Character;
	public var gf:Character;

	public var stage:Stage;

	final iconSpacing:Float = 30;
	public var defaultCamZoom:Float = 1;
	public var defaultHudZoom:Float = 1;
	public var isZooming:Bool = false;

	override function create():Void {
		skipMusicCheck = true;
		super.create();
		Conductor.stop();
		FlxG.timeScale = Settings.data.gameplayModifiers["playbackRate"];

		self = this;
		if (storyMode) {
			songID = songList[currentLevel];
			StoryMenuState.fromPlayState = true;
		} else
			FreeplayState.fromPlayState = true;
		OptionsState.inPlayState = false;

		//Paths.clearStoredMemory();

		clearType = updateClearType();
		FlxG.mouse.visible = false;
		downscroll = Settings.data.downscroll;
		metronome = Settings.data.metronome;
		noteSkin = Settings.data.noteSkin;
		var strumlineYPos:Float = downscroll ? FlxG.height - 150 : 50;

		FlxG.cameras.reset(camGame = new FlxCamera());

		add(camFollow = new FlxObject());
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		camGame.follow(camFollow, LOCKON, 0.5);

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alphaFloat = 1 - (Settings.data.gameVisibility / 100);

		// to prevent more lag when you can't even see the game camera
		if (Settings.data.gameVisibility <= 0) {
			camGame.visible = false;
			camGame.active = false;
			camHUD.bgColor = FlxColor.TRANSPARENT;
		}

		camOther = FlxG.cameras.add(new FlxCamera(), false);
		camOther.bgColor.alpha = 0;

		ScriptHandler.loadFromDir('scripts');

		Conductor._time = -(extraTime * FlxG.timeScale);
		Conductor.rawTime = Conductor.visualTime = Conductor._time + Conductor.offset;

		add(characters = new FlxTypedSpriteGroup<Character>());

		playerStrums = new Strumline(960, strumlineYPos - 10, true, noteSkin);
		opponentStrums = new Strumline(320, strumlineYPos - 10, false, noteSkin);
		playerStrums.alpha = 0;
		opponentStrums.alpha = 0;

		var extraStrumline:Strumline = new Strumline(0, strumlineYPos - 10, false, Settings.data.noteSkin);
		extraStrumline.screenCenter(X);
		extraStrumline.alpha = 0;
		extraStrumline.visible = false;

		var strumlines = [opponentStrums, playerStrums, extraStrumline];
		var playerID = switch (Settings.data.gameplayModifiers['playingSide']) {
			case 'Default': // BF/RIGHT SIDE/PLAYER/ETC
				1;

			case 'Opponent': // UUFO/CAMELLIA/BOTAN/LEFT SIDE/ETC
				0;

			case 'Dancer': // GF/MIDDLE CAMELLIA/WHATEVER THE FUCK
				// if dancer doesn't have a chart for the song just default to the player side
				if (!Song.exists(songID, 'gf')) {
					Settings.data.gameplayModifiers['playingSide'] = 'Default';
					1;
				} else 2;

			case _: // defaults to 'Default' (no shit
				1;
		}
		var popupX:Float = (!Settings.data.centeredNotes && Settings.data.popupCenter == "Field") ? strumlines[playerID].centerX : FlxG.width * 0.5;

		add(judgeSpr = new JudgementSpr(popupX, downscroll ? FlxG.height - 155 : 40));
		judgeSpr.cameras = [camHUD];
		judgeSpr.x -= judgeSpr.width * 0.5;

		add(comboNumbers = new ComboNums(popupX, downscroll ? FlxG.height - 170 : 135));
		comboNumbers.cameras = [camHUD];
		comboNumbers.x -= comboNumbers.width * 0.5;

		if (Settings.data.centeredNotes || Settings.data.popupCenter != "Top") {
			judgeSpr.screenCenter(Y);
			comboNumbers.y = judgeSpr.y + 95;
			comboNumbers.originalPos.y = comboNumbers.y;
		}

		add(playfield = new PlayField(strumlines));
		playfield.cameras = [camHUD]; // so you can still `game.hud.visible = false;` without hiding the strumlines too
		playfield.scrollSpeed = Settings.data.scrollSpeed;
		playfield.downscroll = downscroll;
		playfield.playerID = playerID;

		playfield.noteHit = noteHit;
		playfield.sustainHit = sustainHit;
		playfield.noteMiss = noteMiss;
		playfield.ghostTap = ghostTap;
		playfield.noteSpawned = noteSpawned;

		playfield.add(noteSplashes = new FlxTypedSpriteGroup<NoteSplash>());
		playfield.noteSplashes = noteSplashes;
		for (i in 0...Strumline.keyCount) noteSplashes.add(new NoteSplash(i));
		noteSplashes.cameras = [camHUD];

		add(hud = new FlxSpriteGroup());
		hud.visible = !Settings.data.hideHUD;
		hud.cameras = [camHUD];

		if (Settings.data.centeredNotes) {
			for (i => line in playfield.strumlines.members) {
				if (i == playfield.playerID) {
					line.screenCenter(X);
					continue;
				}

				line.visible = false;
				line.alpha = 0;
			}
		} else if (!Settings.data.opponentNotes) {
			for (i => line in playfield.strumlines.members)
				line.visible = i == playfield.playerID;
		}

		if (Settings.data.gameplayModifiers['blind']) {
			playerStrums.visible = false;
			opponentStrums.visible = false;
		}

		loadSong();

		eventHandler = new EventHandler();
		eventHandler.triggered = eventTriggered;
		eventHandler.pushed = eventPushed;
		eventHandler.load(songID);

		stage = new Stage(stageName);
		ScriptHandler.loadFile(Paths.get('stages/$stageName.hx'));
		camGame.zoom = defaultCamZoom = stage.zoom;
		camFollow.setPosition(stage.camera.x, stage.camera.y);
		camGame.snapToTarget();

		characters.add(gf = new Character(stage.spectator.x, stage.spectator.y, song.meta.spectator));
		gf.visible = stage.isSpectatorVisible;
		ScriptHandler.loadFile(Paths.get('characters/${gf.name}.hx'));
		extraStrumline.character = function() return gf;

		//to-do add to the json the character positions and position of it's reflections
		characters.add(dad = new Character(stage.opponent.x, stage.opponent.y, song.meta.enemy));
		ScriptHandler.loadFile(Paths.get('characters/${dad.name}.hx'));
		characters.add(bf = new Character(stage.player.x, stage.player.y, song.meta.player));
		ScriptHandler.loadFile(Paths.get('characters/${bf.name}.hx'));

		playerStrums.character = function() return bf;
		opponentStrums.character = function() return dad;
		opponentStrums.healthMult = -1.0;

		loadHUD();

		Conductor.syncBeats();
		ScriptHandler.call('create');

		var dontStart = (Dialogue.fileExists(songID) && storyMode);
		if (dontStart) {
			var dialogue:Dialogue = new Dialogue(songID);
			dialogue.cameras = [camOther];
			openSubState(dialogue);
			dialogue.onClose = start;
		}

		var strumFadeTime:Float = 0.5;

		for (strumline in playfield.strumlines) {
			for (i => strum in strumline.members) {
				Main.tweenManager.tween(strum, {y: strum.y + 10, alpha: 1}, strumFadeTime, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
		}

		/*new FlxTimer().start(5, function(_) { //i'll leave this here for future debugging -blear
			funkin.backend.ModchartManager.playerStrums('a', 0, -320, 0, 0.4, 'quadinout', 1);
		});*/

		botplay = Settings.data.gameplayModifiers["botplay"];
		disqualified = disqualified || (Settings.data.gameplayModifiers["randomizedNotes"] || !Settings.data.gameplayModifiers["sustains"]);

		//at the very end the credits will be rolled
		if (inTransition) {
			inTransition = false;
			var substate = new funkin.states.FreeplayTransition(song.meta, function() {
				start();
				return true;
			}, false);
			substate.cameras = [camOther];
			openSubState(substate);
		} else if (!dontStart) {
			start();
			funkin.backend.CreditsStuff.CreditsOverlay.rolldaCredits(this, camOther, playfield.playerID == 0);
		}

		#if DISCORD_ALLOWED DiscordClient.changePresence('Playing: $songName', '', '', true); #end

		if (!_requestSubStateReset) {
			var substate = new BasicBorderTransition(Dialogue.fromMenu ? BOTH : BOTTOM, true, 0.5, 0);
			substate.cameras = [camOther];
			openSubState(substate);
		}
		Dialogue.fromMenu = false;
	}

	function start() {
		Conductor.playing = true;
		new FlxTimer().start((extraTime * FlxG.timeScale) / 1000, _ -> {
			playerStrums.alpha = 1;
			opponentStrums.alpha = 1;
			Conductor.play();
			ScriptHandler.call('songStarted');
		});
	}

	function eventTriggered(event:Event):Void {
		ScriptHandler.call('eventTriggered', [event.name, event.args]);

		switch event.name {
			case 'Change Character':
				var type:Int = event.args[0];
				var character:Character = switch type {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}

				var name:String = event.args[1];
				if (character == null || character.name == name) return;
				var newCharacter:Character = characterCache[name];
				if (newCharacter == null) return;

				newCharacter.alpha = character.alpha;
				newCharacter.visible = character.visible;
				newCharacter.active = character.active;
				newCharacter.setPosition(character.x, character.y);
				character.visible = false;
				character.active = false;

				if (type == 0) {
					dad = newCharacter;
					iconP2.change(name);
				} else if (type == 1) gf = newCharacter;
				else if (type == 2) {
					bf = newCharacter;
					iconP1.change(name);
				}

				healthBar.setColors(dad.healthColor, bf.healthColor);

			case 'Hey!':
				var character:Character = switch event.args[0] {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}

				if (character == null || !character.animation.exists('cheer')) return;
				character.playAnim('cheer', true);
				character.specialAnim = true;
		}
	}

	var eventList:Array<String> = [];
	function eventPushed(event:Event):Void {
		eventPushedUnique(event);
		if (eventList.contains(event.name)) return;

		ScriptHandler.call('eventPushed', [event]);
		eventList.push(event.name);
	}

	function eventPushedUnique(event:Event):Void {
		ScriptHandler.call('eventPushedUnique', [event]);

		switch event.name {
			case 'Change Character':
				cacheCharacter(event.args[1]);
		}
	}

	function cacheCharacter(name:String):Character {
		var character:Character = new Character(0, 0, name);
		character.alpha = 0.0001;
		character.draw();
		character.visible = false;
		character.active = false;
		characters.add(character);
		characterCache.set(name, character);
		return character;
	}

	function noteSpawned(note:Note):Void {
		ScriptHandler.call('noteSpawned', [note]);
	}

	// for stages
	function addBehindObject(obj:FlxBasic, target:FlxBasic) {
		return insert(members.indexOf(target), obj);
	}

	var botplayTxtSine:Float = 0;
	override function update(delta:Float):Void {
		super.update(delta);

		updateCameraScale(delta);
		updateIconScales(delta);
		updateIconPositions();

		if (Settings.data.notesMoveCamera) {
			if (noteCamDelay > 0) noteCamDelay -= delta;
			else camGame.targetOffset.set();
		}

		if (Conductor.rawTime >= 0) eventHandler.update();

		if (FlxG.keys.justPressed.F8) botplay = !botplay;

		if (botplayTxt.visible) {
			botplayTxtSine += 180 * delta;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplayTxtSine) / 180);
		}

		if (Controls.justPressed('reset') && Settings.data.canReset && !alreadyDying) {
			death();
		}

		if (Controls.justPressed('pause')) {
			final substate:PauseMenu = new PauseMenu();
			substate.cameras = [camOther];
			paused = true;

			openSubState(substate);
		}
		ScriptHandler.call('update', [delta]);

		camGame.followLerp = !paused ? (0.1 * FlxG.timeScale) : 0;
	}

	inline function singCharacter(strumline:Strumline, note:Note) {
		var curCharacter:Character = strumline.character();
		if (note.type == 'GF Sing') curCharacter = gf;
		var dontAnimate:Bool = note.noAnimation && note.type != 'GF Sing';
		if (curCharacter == null) return;

		if (note.type == 'Cheer') {
			curCharacter.playAnim('cheer');
			curCharacter.specialAnim = true;
		}

		if (dontAnimate) return;

		curCharacter.playAnim('sing${Note.directions[note.data.lane].toUpperCase()}', true, note.animSuffix);
	}

	function noteHit(strumline:Strumline, note:Note) {
		note.wasHit = true;

		if(ScriptHandler.call('noteHit', [strumline, note]) == -1)return;
		
		if (note.data.player != playfield.playerID) {
			singCharacter(strumline, note);
			note.hitJudgement = Judgement.list[1];
			if (note.sustain != null)
				note.sustain.hitJudgement = note.hitJudgement;
			return;
		} else if (botplay) {
			singCharacter(strumline, note);

			if (Settings.data.notesMoveCamera) {
				noteCamDelay = 0.5;
				var offsetToUse:FlxPoint = noteCamOffset[note.data.lane];
				camGame.targetOffset.set(offsetToUse.x, offsetToUse.y);
			}

			final judge:Judgement = Judgement.list[1];
			note.hitJudgement = judge;
			if(note.sustain != null)
				note.sustain.hitJudgement = judge;
			//health += judge.health * strumline.healthMult;
			judgeSpr.display(judge.timing);
			//comboNumbers.display(++combo);

			noteHitList.push({
				time: note.rawTime,
				diff: judge.timing,
				color: judge.color
			});

			return;
		}

		if (note.sound.length > 0) FlxG.sound.play(Paths.audio(note.sound));

		judgeHit(strumline, note);
		singCharacter(strumline, note);

		if (Settings.data.notesMoveCamera) {
			noteCamDelay = 0.5;
			var offsetToUse:FlxPoint = noteCamOffset[note.data.lane];
			camGame.targetOffset.set(offsetToUse.x, offsetToUse.y);
		}
	}

	dynamic function sustainHit(strumline:Strumline, note:Sustain, mostRecent:Bool) {
		ScriptHandler.call('sustainHit', [strumline, note, mostRecent]);
		noteCamDelay = 0.5;

		// if we have more stuff regarding sustain hitting, only go below this if it's animation based
		if (!mostRecent) return;

		singCharacter(strumline, note);
	}

	function judgeHit(field:Strumline, note:Note) {
		var judge:Judgement = Judgement.getFromTiming(note.hitTime);
		final divHitTime = note.hitTime / FlxG.timeScale * -1;

		if (!note.breakOnHit) {
			noteHitList.push({
				time: note.rawTime,
				diff: divHitTime,
				color: judge.color
			});
		}

		judge = ScriptHandler.call("judgeHit", [field, note, judge], true) ?? judge; // So that scripts can override judgements if required i.e for mines

		note.hitJudgement = judge;
		if(note.sustain != null)
			note.sustain.hitJudgement = judge;

		if (note.breakOnHit) {
			health -= note.missHealth * field.healthMult;
			combo = 0;
			comboBreaks++;
		} else {
			notesPlayed += judge.accuracy;
			notesHit++;
			judge.hits++;
			combo++;
			health += judge.health * field.healthMult;
		}

		accuracy = updateAccuracy();
		clearType = updateClearType();
		score = updateScore();
		timingIndicator.text = '${Util.truncateFloat(divHitTime, 2)} ms';
		Main.tweenManager.cancelTweensOf(timingIndicator);
		timingIndicator.alpha = 1;
		Main.tweenManager.tween(timingIndicator, {alpha: 0}, 0.35, {ease: FlxEase.cubeIn, startDelay: 0.75});

		if (Settings.data.hitErrorBar)
			hitErrorBar.registerHit(note.hitTime * -1);

		if (judge.breakCombo) {
			if (combo >= 50 && gf.animation.exists('sad')) {
				gf.playAnim('sad');
				gf.specialAnim = true;
			}

			combo = 0;
			comboBreaks++;
			if (Settings.data.gameplayModifiers["instakill"])
				death();
		}

		if (!judge.splashes && Settings.data.gameplayModifiers["onlySicks"])
			death();

		updateScoreTxt();
		updateJudgeCounter();
		judgeSpr.display(note.hitTime);
		switch (Settings.data.comboTinting){
			case 'Clear Flag':
				var colour:FlxColor = FlxColor.WHITE;
				if(comboBreaks == 0){
					for(i in 0...Judgement.list.length){
						if(Judgement.list[i].hits > 0)
							colour = Judgement.list[i].color;
					}
				}
				comboNumbers.color = colour;
			case 'Per-Note':
				comboNumbers.color = judge.color;
		}

		if (!judge.breakCombo) 
			comboNumbers.display(combo);
		else
			comboNumbers.clearNums();

		if (Settings.data.noteSplashSkin != 'none' && judge.splashes) {
			final splash = noteSplashes.members[note.data.lane];
			if(Settings.data.strumGlow == 'Judgement'){
				splash.luminColors = true;
				splash.color = judge.color;
			} else {
				splash.luminColors = note.luminColors;
				splash.color = note.color;
			}
			splash.hit(field.members[note.data.lane]);
		}

		ScriptHandler.call("postJudgeHit", [field, note, judge]); // i KNOW post functions are lame i KNOW but i NEED THIs so im not DOING SHIT EVERY FRAME FOR NO REASON FOR MY JUDGE SKIN SCRIPT -neb

		judge = null;
	}

	var scoreBg:FunkinSprite;
	var judgeBg:FunkinSprite;
	var clearTypeTxt:FlxText;

	function loadHUD():Void {
		hud.clear();

		hud.add(hitErrorBar = new HitErrorBar(0, downscroll ? FlxG.height - 50 : 45));
		hitErrorBar.screenCenter(X);
		hitErrorBar.visible = Settings.data.hitErrorBar;

		hud.add(timingIndicator = new FlxText(0, downscroll ? FlxG.height - 30 : 25, 500, '0 ms', 16));
		timingIndicator.alignment = 'center';
		timingIndicator.screenCenter(X);
		timingIndicator.alpha = 0;
		timingIndicator.font = Paths.font('Rockford-NTLG Light Italic.ttf');
		timingIndicator.borderSize = 1.25;
		timingIndicator.borderStyle = OUTLINE;
		timingIndicator.borderColor = 0xFF000000;

		hud.add(healthBar = new Bar(0, downscroll ? 55 : 640, function() return health, 0, 100));
		healthBar.setColors(dad.healthColor, bf.healthColor);
		healthBar.screenCenter(X);
		healthBar.alpha = Settings.data.healthBarAlpha;
		healthBar.leftToRight = false;

		hud.add(iconP1 = new CharIcon(bf.icon, true));
		iconP1.y = healthBar.y - (iconP1.height * 0.5);
		iconP1.scale.set(0.8, 0.8);
		iconP1.updateHitbox();
		iconP1.alpha = Settings.data.healthBarAlpha;

		hud.add(iconP2 = new CharIcon(dad.icon));
		iconP2.y = healthBar.y - (iconP2.height * 0.5);
		iconP2.scale.set(0.8, 0.8);
		iconP2.updateHitbox();
		iconP2.alpha = Settings.data.healthBarAlpha;

		updateIconPositions();

		hud.add(scoreBg = new FunkinSprite(0, downscroll ? 21 : FlxG.height - 39));
		scoreBg.loadGraphic(Paths.image('ui/scoreBack'));
		scoreBg.screenCenter(X);

		hud.add(scoreTxt = new FlxText(0, scoreBg.y, FlxG.width, '', 20));
		scoreTxt.font = Paths.font('Rockford-NTLG Light Italic.ttf');
		scoreTxt.alignment = CENTER;
		scoreTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		scoreTxt.borderColor = FlxColor.BLACK;
		scoreTxt.borderSize = 1.25;
		scoreTxt.screenCenter(X);

		hud.add(judgeBg = new FunkinSprite(0, 0));
		judgeBg.loadGraphic(Paths.image('ui/judgementCt'));
		judgeBg.x = Settings.data.gameplayModifiers['playingSide'] == 'Opponent' ? (FlxG.width - judgeBg.width) - 5 : 5;
		judgeBg.screenCenter(Y);
		judgeBg.visible = Settings.data.judgementCounter;

		hud.add(ranking = new FlxText(judgeBg.x, 0, judgeBg.width, '?'));
		ranking.setFormat(Paths.font('Rockford-NTLG Light Italic.ttf'), 20, 0xFFFFFFFF, (Settings.data.gameplayModifiers['opponentMode'] ? RIGHT : LEFT), OUTLINE, 0xFF000000);
		ranking.borderSize = 1.25;
		ranking.y = (judgeBg.visible ? judgeBg.y : FlxG.height) - 3 - ranking.height;

		hud.add(judgeCounter = new FlxText(judgeBg.x + 5, judgeBg.y + 5, 500, '', 20));
		judgeCounter.font = Paths.font('menus/GOTHICI.TTF');
		judgeCounter.visible = Settings.data.judgementCounter;
		
		add(botplayTxt = new FunkinSprite().loadGraphic(Paths.image('ui/botplay')));
		botplayTxt.visible = false;
		botplayTxt.screenCenter();
		botplayTxt.camera = camHUD;

		updateScoreTxt();
		updateJudgeCounter();
	}

	dynamic function ghostTap(strumline:Strumline, dir:Int, shouldMiss:Bool)
	{
		if (shouldMiss)
		{
			if (ScriptHandler.call('ghostTapMiss', [strumline, dir]) == -1)return;

			onMiss(strumline, Note.defaultMissHealth, true, dir, '');
		}
	}

	dynamic function noteMiss(strumline:Strumline, note:Note) {
		if (ScriptHandler.call('noteMiss', [strumline, note]) == -1)return;
		if (note.ignore || note.data.player != playfield.playerID)return;

		onMiss(strumline, note.missHealth, !note.noAnimation, note.data.lane, note.animSuffix);
	}

	function onMiss(strumline:Strumline, missHealth:Float, animation:Bool, dir:Int, animSuffix:String)
	{
		if (combo >= 50 && gf.animation.exists('sad')) {
			gf.playAnim('sad');
			gf.specialAnim = true;
		}

		comboBreaks++;
		combo = 0;

		health -= missHealth * strumline.healthMult;

		if (Settings.data.hitErrorBar)
			hitErrorBar.registerMiss();

		/* if (Settings.data.accuracyType.toLowerCase() == 'complex') {
			if (!note.isSustain) {
				notesPlayed += Wife3.missWeight;
				notesHit += 2;
			} else notesPlayed += Wife3.holdDropWeight;
		} */

		if (Settings.data.gameplayModifiers["instakill"] || Settings.data.gameplayModifiers["onlySicks"])
			death();

		score = updateScore();
		accuracy = updateAccuracy();
		clearType = updateClearType();
		updateScoreTxt();
		updateJudgeCounter();

		var curCharacter:Character = strumline.character();

		if (curCharacter != null && animation)
			curCharacter.playAnim('miss${Note.directions[dir].toUpperCase()}', true, animSuffix);
	}

	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.RED);
	function updateJudgeCounter() {
		if (!Settings.data.judgementCounter) return;
		
		var marvs:Int = Judgement.list[0].hits;
		var sicks:Int = Judgement.list[1].hits;
		var goods:Int = Judgement.list[2].hits;
		var bads:Int = Judgement.list[3].hits;
		var shits:Int = Judgement.list[4].hits;

		var intendText:String = 'Marv: $marvs\nSick: $sicks\nGood: $goods\nBad: $bads';
		var n:Int = intendText.length;
		intendText += '\nShit: $shits\nMiss: ${Math.max(0, comboBreaks - shits)}';
		judgeCounter.removeFormat(selectedFormat);
		judgeCounter.addFormat(selectedFormat, n, intendText.length);
		judgeCounter.text = intendText;
	}

	function updateClearType():String {
		var marvs:Int = Judgement.list[0].hits;
		var sicks:Int = Judgement.list[1].hits;
		var goods:Int = Judgement.list[2].hits;
		var bads:Int = Judgement.list[3].hits;
		var shits:Int = Judgement.list[4].hits;

		var type:String = 'N/A';

		if (comboBreaks == 0) {
			if (bads > 0) type = 'FC';
			else if (goods > 0) {
				if (goods == 1) type = 'BF';
				else if (goods <= 9) type = 'SDG';
				else if (goods >= 10) type = 'GFC';
			} else if (sicks > 0) {
				if (sicks == 1) type = 'WF';
				else if (sicks <= 9) type = 'SDP';
				else if (sicks >= 10) type = 'PFC';
			} else if (marvs > 0) type = 'MFC';
		} else {
			if (comboBreaks == 1) type = 'MF';
			else if (comboBreaks <= 9) type = 'SDCB';
			else type = 'Clear';
		}

		return type;
	}

	// pretty much just osu simplified
	function updateScore():Int {
		var marvs:Int = Judgement.list[0].hits;
		var sicks:Int = Judgement.list[1].hits;
		var goods:Int = Judgement.list[2].hits;
		var bads:Int = Judgement.list[3].hits;
		var shits:Int = Judgement.list[4].hits;
		return Math.floor(((marvs * 1.01 + sicks + goods * 0.7 + bads * 0.35 + shits * 0.1) / totalNotes) * maxScore) - ((comboBreaks - shits) * 200);
	}

	inline function updateAccuracy():Float {
		return notesPlayed / (notesHit + comboBreaks);
	}

	function updateScoreTxt():Void {
		final rank:Ranking = (notesHit == 0) ? {} : Ranking.getFromAccuracy(accuracy);

		ranking.text = '${rank.name} | $clearType';
		ranking.color = rank.color;
		if(Settings.data.hideAcc)
			scoreTxt.text = _formatT("score_no_acc", ['$score']);//'Score: $score | Accuracy: ${Util.truncateFloat(accuracy, 2)}%';
		else
			scoreTxt.text = _formatT("score", ['$score', '${Util.truncateFloat(accuracy, 2)}']);//'Score: $score | Accuracy: ${Util.truncateFloat(accuracy, 2)}%';
		
		ScriptHandler.call("updateScoreTxt", []);
	}

	function loadSong():Void {
		song = Song.load(songID, Difficulty.current);

		if (Conductor.inst != null){ 
			Conductor.inst.stop();
			Conductor.inst = null;
		}

		if (Song.exists(songID, 'gf')) {

			var middleNotes:Chart = Song.load(songID, 'gf');
			for (note in middleNotes.notes) {
				note.player = 2;
				song.notes.push(note);
			}
		}

		Conductor.offset = song.meta.offset;
		Conductor.timingPoints = song.meta.timingPoints;
		Conductor.bpm = Conductor.timingPoints[0].bpm;

		stageName = song.meta.stage;
		songName = song.meta.songName;

		// load inst
		try {
		
			Conductor.inst = FlxAudioHandler.loadAudio(Paths.audioPath('songs/$songID/Inst'));//FlxG.sound.load(Paths.audio('songs/$songID/Inst'));
			Conductor.inst.pitch = FlxG.timeScale;
			Conductor.inst.onComplete = function() {
				ResultsScreenState.lastPlay = Scores.get(songID, Difficulty.current, song.meta.hasModchart).copy(false);
				if (!disqualified) {
					Scores.set({
						songID: songID,
						difficulty: Difficulty.current,

						score: score,
						accuracy: accuracy,
						accType: Settings.data.accuracyType,
						clearType: clearType,

						modifiers: Settings.data.gameplayModifiers.copy()
					}, song.meta.hasModchart);
				}
				checkAwards();
				endSong();
				Scores.save();
			}

		} catch (e:Dynamic) {
			Sys.println('Instrumental failed to load: $e');
		}

		// load vocals
		try {
			if (song.meta.hasVocals) {
				Conductor.vocals = FlxAudioHandler.loadAudio(Paths.audioPath('songs/$songID/Vocals'));//FlxG.sound.load(Paths.audio('songs/$songID/Voices'));
				Conductor.vocals.pitch = FlxG.timeScale;
				Conductor.vocals.volume = Settings.data.disableVocals ? 0 : 1;
			}
		} catch (e:Dynamic) {
			Sys.println('Vocals failed to load: $e');
		}

		ScriptHandler.loadFromDir('songs/$songID');
		ScriptHandler.call('loadSong', [song]);

		playfield.load(song.notes);
		playfield.scrollSpeed /= FlxG.timeScale;

		for (noteData in playfield.unspawnedNotes) {
			if (noteData.player != playfield.playerID || noteData.type == 'Mine') continue;
			totalNotes++;
		}

		trace('total amount of hittable notes: $totalNotes');
	}

	// forceLeave:Bool - forces you to leave to the main menu
	public function endSong(?forceLeave:Bool = false) {
		if (!forceLeave && ScriptHandler.call('onEndSong', [songID], true) == -1) return;
		//trace('bro'); //bro, remember to disable ur traces :bartcoal:

		FlxG.timeScale = 1;
		Conductor.stop();
		if (Conductor.vocals != null) {
			Conductor.vocals.destroy();
			Conductor.vocals = null;
		}
		deaths = 0;

		Util.cancelAllTimers();
		Util.cancelAllTweens();

		if (!forceLeave) {
			final substate:funkin.states.ResultsScreenState = new funkin.states.ResultsScreenState();
			substate.camera = camOther;
			openSubState(substate);
			#if DISCORD_ALLOWED DiscordClient.changePresence('In Results'); #end
		} else {
			#if DISCORD_ALLOWED DiscordClient.changePresence('In the Menus', '', '', true); #end
			Conductor.inst = FlxAudioHandler.loadAudio(Paths.audioPath(funkin.backend.CreditsStuff.MenuMusic.gimmeMusicName()));
			Conductor.play();
			var wasStory = storyMode;
			var substate = new BasicBorderTransition(BOTH, false, 0.75, 0.5, function() {
				for (mem in members) {
					if (mem == null || !mem.exists || !mem.alive) continue;
					mem.visible = false;
				}

				Paths.clearExcept([
					Paths.getCacheKey('menus/border.png', 'IMG', 'images'),
					Paths.getCacheKey('menus/borderTop.png', 'IMG', 'images')
				]);

				FlxG.switchState(wasStory ? new StoryMenuState() : new FreeplayState());
			});
			substate.cameras = [camOther];
			openSubState(substate);
			songList.resize(0);
			storyMode = false;
			currentLevel = 0;
		}
	}

	public function proceed() {
		if (storyMode && ++currentLevel < songList.length) {
			Dialogue.fromMenu = true; // ehhhh dont feel like renaming.
			FlxG.resetState();
			return false;
		}

		songList.resize(0);
		currentLevel = 0;

		Conductor.inst = FlxAudioHandler.loadAudio(Paths.audioPath(funkin.backend.CreditsStuff.MenuMusic.gimmeMusicName()));
		Conductor.play();
		
		FlxG.switchState(storyMode ? new StoryMenuState() : new FreeplayState());
		#if DISCORD_ALLOWED DiscordClient.changePresence('In the Menus', '', '', true); #end
		storyMode = false;
		return true;
	}

	override function destroy():Void {
		ScriptHandler.call('destroy');
		Judgement.resetHits();
		ScriptHandler.clear();
		FlxG.mouse.visible = true;
		self = null;
		Conductor.vocals = null;
		super.destroy();
	}

	function updateCameraScale(delta:Float):Void {
		if (Settings.data.cameraZooms.toLowerCase() == 'off' || isZooming) return;

		final scalingMult:Float = Math.exp(-delta * 6);
		camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, scalingMult);
		camHUD.zoom = FlxMath.lerp(defaultHudZoom, camHUD.zoom, scalingMult);
	}

	function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	function updateIconScales(delta:Float):Void {
		var mult:Float = FlxMath.lerp(0.8, iconP1.scale.x, Math.exp(-delta * 9));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(0.8, iconP2.scale.x, Math.exp(-delta * 9));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
	}

	override function stepHit(step:Int) {
		ScriptHandler.call('stepHit', [step]);
	}

	override function beatHit(beat:Int) {
		iconP1.scale.set(1, 1);
		iconP1.updateHitbox();

		iconP2.scale.set(1, 1);
		iconP2.updateHitbox();

		characterBopper(beat);

		ScriptHandler.call('beatHit', [beat]);

		if (metronome && Conductor.rawTime >= 0) {
			FlxG.sound.play(Paths.audio('metronome', 'sfx'));
		}
	}

	// i added this check to prevent that ugly ahh jittering
	override function measureHit(measure:Int) {
		if (Settings.data.cameraZooms.toLowerCase() != 'off' && !isZooming) {
			camGame.zoom += 0.015;
			camHUD.zoom += 0.0075;
		}

		ScriptHandler.call('measureHit', [measure]);
	}

	function characterBopper(beat:Int):Void {
		for (char in characters) {
			final interval = char == gf ? (gfSpeed * char.danceInterval) : char.danceInterval;
			if (char.specialAnim || beat % interval != 0 || !char.active)
				continue;
			char.dance();
		}
	}

	// have to make it a function instead because dce lol
	function loadVideo(path:String):FunkinVideo {
		return new FunkinVideo(Paths.video(path), true);
	}

	// i'd much rather use a switch case for this
	// but it won't check off multiple awards at once if we don't so lol
	function checkAwards() {
		if (disqualified || songID == 'tutorial') return;

		var curDiff:String = Difficulty.current.toLowerCase();

		// First Roots! / Budding Sprout! / Full Bloom!
		if (comboBreaks == 0) {
			// i feel like we should use default_list here
			if (Difficulty.list.contains(Difficulty.current)) { // for custom diffs
				for (i in 0...Difficulty.list.indexOf(Difficulty.current) + 1) {
					Awards.unlock('fc_' + Difficulty.list[i].toLowerCase());
				}
			}
		// So close...
		} else if (comboBreaks == 1) Awards.unlock('choke');

		if (storyMode) {
			// NOTICE: WHEN THE WEEK LIST IS FINALIZED FOR 2.75, ARRAYS MAY NEED TO BE ADJUSTED!
			var weekNames = ['Rehearsal Session', 'The Grand Show', 'Holofunk', 'Fingerbreaker'];
			var weekAwards = ['beat_week1', 'beat_week2', 'beat_holofunk', 'beat_fingerbreak'];

			var curWeek = weekNames.indexOf(WeekData.list[WeekData.current].name);
			if (curWeek >= 0) {
				Awards.setScore(weekAwards[curWeek], Math.max(Awards.getScore(weekAwards[curWeek]), currentLevel + 1));

				// Paranormal Activity!
				if (weekNames[curWeek] == 'Fingerbreaker' && Difficulty.current == 'Maniac')
					Awards.setScore('beat_fingerbreak_maniac', Math.max(Awards.getScore('beat_fingerbreak_maniac'), currentLevel + 1));
			}

		}
		
		// How's THAT for a change?
		if (playfield.playerID == 0) Awards.unlock('clear_opponent');

		// MARVELOUS!!
		if (accuracy >= 100) {
			Awards.unlock('marvelous');
		}

		if (curDiff == 'maniac') {
			// Speed Demon!
			if (accuracy >= 95 && Settings.data.gameplayModifiers['playbackRate'] >= 1.5) {
				Awards.unlock('clear_speed');
			}

			switch songID {
				// A REAL Tiebreaker!
				case 'tremendous': Awards.unlock('beat_tremendous');

				// Blast Processing!
				case 'compute it': Awards.unlock('beat_compute');
			}

/*			// Paranormal Activity!
			var ghostTrilogy:Array<String> = cast Awards.saveFile.data.ghostTrilogy ?? [];
			if (!ghostTrilogy.contains(songID)) {
				ghostTrilogy.push(songID);
			}
			Awards.saveFile.data.ghostTrilogy = ghostTrilogy;
			if (ghostTrilogy == ['ghost', 'ghoul', 'ghost-vip']) Awards.unlock('beat_fingerbreak_maniac');*/
		}

		// difficulty specific awards
		var curRatings:Array<Float> = (Addons.current.length == 0 ? funkin.backend.DifficultyRating.list.get(songID)?.get(Difficulty.current) : song.meta.rating?.get(Difficulty.current)) ?? [];

		var curDiffRating:Float = playfield.playerID == 0 ? curRatings[1] : curRatings[0];
		trace(curDiffRating);
		// Slow and Steady!
		if (curDiffRating >= 5) Awards.unlock('clear_5');

		// Picking up the pace!
		if (curDiffRating >= 10) Awards.unlock('clear_10');

		// Above and Beyond!
		if (curDiffRating >= 15) {
			Awards.unlock('clear_15');

			// Safety Measures...
			if (Settings.data.gameplayModifiers['noFail']) Awards.unlock('clear_nofail');
		}

		// On top of the world!
		if (curDiffRating == 20) Awards.unlock('clear_20');

		// register any in progress awards
		Awards.save();
	}

	var alreadyDying:Bool = false;
	function death():Void {
		if (alreadyDying) return;

		if (Settings.data.gameplayModifiers["noFail"]) {
			if (!disqualified) disqualified = true;
			return;
		}

		disqualified = true;
		alreadyDying = true;
		deaths++;

		Util.cancelAllTimers();
		Util.cancelAllTweens();

		for (strumline in playfield.strumlines) {
			for (strum in strumline.members) {
				Main.tweenManager.tween(strum, {
					x: strum.x + FlxG.random.int(-50, 50), 
					y: strum.y + FlxG.random.int(-100, 100), 
					angle: FlxG.random.int(-40, 40)
				}, FlxG.random.int(2, 4), {ease: FlxEase.quadInOut});
			}
		}

		camHUD.fade(0x42FF0000, 5);

		function updateTimeScale(v:Float)
			FlxG.timeScale = v;
		Main.tweenManager.num(FlxG.timeScale, 0.1, 5, {ease:FlxEase.linear}, updateTimeScale.bind());
		Main.tweenManager.tween(camGame, {zoom: camGame.zoom + 0.5, angle: (FlxG.random.bool() ? -10 : 10)}, 5, {ease: FlxEase.linear});
		if (Conductor.vocals != null)
			Main.tweenManager.tween(Conductor.vocals, {pitch: 0.1}, 5, {ease: FlxEase.linear});
		Main.tweenManager.tween(Conductor.inst, {pitch: 0.1}, 5, {ease: FlxEase.linear, 
			onComplete: t -> {
				Conductor.stop();
				Util.cancelAllTimers();
				Util.cancelAllTweens();
				//endSong(true);
				final substate:funkin.states.BlueBalledState = new funkin.states.BlueBalledState(camOther, playfield.playerID);
				/*substate.charID = playfield.playerID;
				substate.camera = camOther;*/
				openSubState(substate);
			}});
	}

	//in testing i ran into some issues, so this function will be here
	public static function resetState():Void{
		FlxG.resetState();
	}
}
