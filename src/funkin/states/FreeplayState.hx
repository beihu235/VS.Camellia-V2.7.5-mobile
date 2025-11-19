package funkin.states;

import flixel.math.FlxRect;
import funkin.backend.Meta;
import funkin.backend.WeekData;
import funkin.backend.Scores;
import funkin.objects.ui.Border;
import funkin.objects.ui.SwirlBG;
import funkin.objects.CharIcon;
import funkin.objects.FunkinSprite;
import funkin.objects.ui.FreeplaySongSlot;
import funkin.shaders.TileLine;
import funkin.shaders.SongSlotShader;
import funkin.states.OptionsState.OptionType;
import funkin.objects.FadingSprite;
import flixel.graphics.FlxGraphic;

import flixel.addons.display.FlxBackdrop;

typedef FreeplaySongData = {
	var id:String;
	var weekDiffs:Array<DiffData>;
	var colours:Array<FlxColor>;
	var pauseMusic:String;
	var meta:MetaFile;
	var icons:Array<String>;
	var folder:String;

	var slot:FreeplaySongSlot;
}

typedef FreeplaySortMethod = {
	var name:String;
	var method:(a:FreeplaySongData, b:FreeplaySongData) -> Int;
	var sensitive:Bool;
}

class FreeplayState extends FunkinState {
	public static var fromPlayState:Bool = false;
	public static var self:FreeplayState; // just to fucking access curDiffSelected like bro

	var borderTop:Border;
	var borderBot:Border;

	var bg:SwirlBG;
	var lineShader:TileLine;

	var slotShader:SongSlotShader;

	var songList:Array<FreeplaySongData> = [];
	var echoSlot:FunkinSprite;
	var songSlots:FlxTypedGroup<FreeplaySongSlot>;
	var songTexts:FlxTypedGroup<FlxText>;
	var songSubtitles:FlxTypedGroup<FlxText>;
	var selectTriangle:FlxSprite;
	var scoreCount:FlxText;
	var scoreTitle:FlxText;
	var ranking:FlxText;
	// var clearType:FlxText; doesnt fit AGAIN bro kill me

	var metadataBG:FunkinSprite;
	var topMetadata:FlxText;
	var botMetadata:FlxText;
	var topMetaVal:FlxText;
	var botMetaVal:FlxText;
	var jacket:FadingSprite;
	var jacketBorder:FunkinSprite;

	var vsSprite:FunkinSprite;
	var iconP1:CharIcon;
	var iconP2:CharIcon;

	static var curSort:Int = 0;
	var sortTxt:FlxText;
	var sorts:Array<FreeplaySortMethod> = [
		{name: "Week", method: (a, b) -> {return 1;}, sensitive: false},
		{name: "A-Z", method: (a, b) -> {return (a.meta.songName.toLowerCase() < b.meta.songName.toLowerCase()) ? -1 : 1;}, sensitive: false},
		{name: "Diff", method: function(a, b) {
			final diff = (Settings.data.gameplayModifiers["playingSide"] == "Dancer") ? "Camellia" : Difficulty.list[self.curDiffSelected];
			final diffIdx = (Settings.data.gameplayModifiers["playingSide"] == "Opponent") ? 1 : 0;
			final aDiffs = a.meta.rating.get(diff);
			final aBlank = (aDiffs == null || aDiffs.length < (diffIdx + 1));
			final bDiffs = b.meta.rating.get(diff);
			final bBlank = (bDiffs == null || bDiffs.length < (diffIdx + 1));

			if (aBlank && bBlank)
				return 1;
			if (aBlank != bBlank)
				return aBlank ? 1 : -1;
			return (aDiffs[diffIdx] < bDiffs[diffIdx]) ? 1 : -1;
		}, sensitive: true}
	];
	var draggedOnce:Bool = false;
	var dragging:Bool = false;
	var dragY:Float = -1;

	public static final modList:Array<GameModifier> = [
		new GameModifier("Playback Rate", "How fast the game will go.", "playbackRate", FloatOption(0.35, 5.0, 0.05)),
		new GameModifier('Playing Side', 'Which side you\'re playing on for the song.', 'playingSide', ListOption(['Default', 'Opponent']), true),
		new GameModifier("No Fail", "If you'll live even when out of health.", "noFail", BoolOption),
		new GameModifier("FC Only", "If you'll fail the moment you combo break.", "instakill", BoolOption),
		new GameModifier("Sicks Only", "If you'll fail the moment you don't hit a sick.", "onlySicks", BoolOption),
		new GameModifier("Mirrored Notes", "If the chart will flip its notes around.", "mirroredNotes", BoolOption),
		new GameModifier("Randomized Notes", "If the game will swap the lanes around.", "randomizedNotes", BoolOption),
		new GameModifier("Modcharts", "If the game will do some wacky stuff with the notes to make it\nlook cooler.", "modcharts", BoolOption),
		new GameModifier("Sustains", "If the game will add holds or not.", "sustains", BoolOption),
		new GameModifier("Botplay", "If the game will play the chart for you.", "botplay", BoolOption),
		new GameModifier('Blind', 'How much of the chart do you remember?', 'blind', BoolOption),
	];
	var inMods:Bool = false;
	var curMod:Int = 0;
	var modSin:Float = 0.0;
	var modBG:FunkinSprite;
	var modDarken:FunkinSprite;
	var simpleModBG:FunkinSprite;
	var modTxt:FlxText;
	var modTriangles:Array<FunkinSprite> = [];
	var modSlots:FlxTypedGroup<FreeplaySongSlot>;
	var modTexts:FlxTypedGroup<FlxText>;
	var modSubtitles:FlxTypedGroup<FlxText>;
	var modVal:FlxText;

	var lerpScore:Float = 0;
	var curPlay:PlayData;
	var exiting:Bool = false;
	static var curSelected:Int = 0;
	var curDiffSelected:Int = 0;
	var centerDiff:Float = 1;
	var noChartTwn:FlxTween;
	var noChart:FunkinSprite;
	var diffSquares:FlxTypedGroup<FunkinSprite>;
	var diffTitles:FlxTypedGroup<FlxText>;
	var diffRatings:FlxTypedGroup<FlxText>;

	var curSong(get, never):FreeplaySongData;
	var initJacket:Bool = true;

	function get_curSong():FreeplaySongData return songList[songSlots.members[curSelected].ID];

	// var debugClear:Int = -1;

	override function create():Void {
		super.create();
		self = this;
		curDiffSelected = Difficulty.list.indexOf(Difficulty.current);

		// only one shader to keep batching.
		slotShader = new SongSlotShader();

		add(bg = new SwirlBG(0xFF808080, 0xFF505050));
		final lastSpeed = bg.speed;

		var freeplayTile:FlxBackdrop = new FlxBackdrop(Paths.image('menus/Freeplay/bigText'), Y);
		freeplayTile.velocity.y = 25;
		add(freeplayTile);

		if (!Settings.data.reducedQuality) {
			var lineBG = new FunkinSprite();
			lineBG.makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
			lineShader = new TileLine();
			lineShader.color1.value = [0, 0, 0, 0.375];
			lineShader.color2.value = [0, 0, 0, 0.5];
			lineShader.density.value = [200.0];
			lineShader.time.value = [SwirlBG.time / 64];
			lineBG.shader = lineShader;
			add(lineBG);
		}
		
		add(songSlots = new FlxTypedGroup<FreeplaySongSlot>());
		add(ranking = new FlxText(-50, -50, 0, "?"));
		// add(clearType = new FlxText(-50, -50, 0, "?"));
		add(songTexts = new FlxTypedGroup<FlxText>());
		add(songSubtitles = new FlxTypedGroup<FlxText>());

		add(diffSquares = new FlxTypedGroup<FunkinSprite>());
		add(diffTitles = new FlxTypedGroup<FlxText>());
		add(diffRatings = new FlxTypedGroup<FlxText>());

		add(noChart = new FunkinSprite(0, 0, Paths.image("menus/Freeplay/noChart")));
		noChart.scale.set();

		loadMods();
		loadSongs();
		curSelected = Std.int(FlxMath.bound(curSelected, 0, songSlots.length - 1));
		final selSlot = songSlots.members[curSelected];
		
		ranking.alpha = 0.5;
		ranking.setFormat(Paths.font("menus/bozonBI.otf"), 116, 0xFFFFFFFF, RIGHT);
		ranking.setPosition(selSlot.x - selSlot.offset.x + 605 * selSlot.scale.x - ranking.width, selSlot.y + selSlot.frameHeight * 0.5 - ranking.height * 0.75);
		ranking.clipRect = FlxRect.get(0, 0, ranking.frameWidth * 3, ranking.frameHeight * 0.75); // times 3 just in case
		/*
		clearType.alpha = 0.5;
		clearType.setFormat(Paths.font("menus/bozonBI.otf"), 60, 0xFFFFFFFF, RIGHT);
		clearType.setPosition(ranking.x - 5 - clearType.width, selSlot.y + selSlot.frameHeight * 0.5 - clearType.height * 0.75);
		clearType.clipRect = FlxRect.get(0, 0, clearType.frameWidth * 7, clearType.frameHeight * 0.75); // times 7 just in case
		*/
		add(selectTriangle = new FunkinSprite(selSlot.x + 55, selSlot.y - selSlot.frameHeight * 0.35, Paths.image("menus/triangle")));
		selectTriangle.color = 0xFF000000;
		selectTriangle.flipX = true;
		selectTriangle.origin.x += 3; // UUUUUGGGGGGGGHHHHHHHHH
		
		add(scoreCount = new FlxText(selectTriangle.x - 15, selSlot.y + selSlot.frameHeight * 0.5 + 10, 0, "0", 48));
		scoreCount.setFormat(Paths.font("Rockford-NTLG Light Italic.ttf"), 48, 0xFFB0B0B0, RIGHT);
		scoreCount.x -= scoreCount.width;
		scoreCount.y -= scoreCount.height;
		
		add(scoreTitle = new FlxText(scoreCount.x - 5, scoreCount.y, 0, "SCORE:", 16));
		scoreTitle.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 16, 0xFF000000, RIGHT);
		scoreTitle.x -= scoreTitle.width;
		scoreTitle.y += scoreTitle.height * 0.35;

		echoSlot = new FunkinSprite(selSlot.x, selSlot.y, Paths.image("menus/Freeplay/songBar"));
		//echoSlot.clipGraphic(0, 0, selSlot.frameWidth, selSlot.frameHeight);
		//echoSlot.scale.copyFrom(selSlot.scale);
		echoSlot.offset.copyFrom(selSlot.offset);
		echoSlot.origin.copyFrom(selSlot.origin);
		echoSlot.colorTransform.redOffset = 255;
		echoSlot.visible = false;
		add(echoSlot);

		add(jacket = new FadingSprite(88, 174));
		add(jacketBorder = new FunkinSprite(jacket.x - 2, jacket.y - 2, Paths.image('menus/Freeplay/albumBorder')));

		metadataBG = new FunkinSprite(jacket.x, jacket.y - 44, Paths.image('menus/Freeplay/metadata'));
		metadataBG.scale.set(0.5, 0.5);
		metadataBG.updateHitbox();
		add(metadataBG);

		add(iconP1 = new CharIcon('', true));
		iconP1.setPosition(metadataBG.x + 231, metadataBG.y - 50);
		iconP1.clipRect = FlxRect.get(32, 25, iconP1.frameWidth - 32, 79);
		iconP1.scale.set(0.5, 0.5);
		iconP1.alpha = 0.8;

		add(iconP2 = new CharIcon(''));
		iconP2.setPosition(metadataBG.x + 115, metadataBG.y - 50);
		iconP2.clipRect = FlxRect.get(32, 25, iconP2.frameWidth - 32, 79);
		iconP2.scale.set(0.5, 0.5);
		iconP2.alpha = 0.8;

		// ??????????????????????
/*		var iconCliprect = FlxRect.get(metadataBG.x + 168, metadataBG.y, 160, 40);
		iconP1.clipRect = iconCliprect;
		iconP2.clipRect = iconCliprect;*/

		noChart.x = metadataBG.x + (metadataBG.width - noChart.width) * 0.5;
		noChart.y = metadataBG.y + metadataBG.height;

		add(topMetadata = new FlxText(metadataBG.x + 1, metadataBG.y + 2, 160, 'BPM\nGENRE\nALBUM', 12));
		topMetadata.font = Paths.font('menus/ITC Avant Garde Gothic CE Book.otf');
		add(topMetaVal = new FlxText(topMetadata.x, topMetadata.y, topMetadata.fieldWidth, '?\n?\n?', 12));
		topMetaVal.font = Paths.font('menus/ITC Avant Garde Gothic CE Book.otf');
		topMetaVal.alignment = RIGHT;

		add(botMetadata = new FlxText(metadataBG.x + 1, (metadataBG.y + metadataBG.height) - 40, metadataBG.width, 'VOCAL\nJACKET ART\nCHART', 12));
		botMetadata.font = Paths.font('menus/ITC Avant Garde Gothic CE Book.otf');
		add(botMetaVal = new FlxText(botMetadata.x, botMetadata.y, botMetadata.fieldWidth, '?\n?\n?', 12));
		botMetaVal.font = Paths.font('menus/ITC Avant Garde Gothic CE Book.otf');
		botMetaVal.alignment = RIGHT;

		vsSprite = new FunkinSprite(metadataBG.x + 235, metadataBG.y + 14, Paths.image('menus/Freeplay/vs'));
		vsSprite.scale.set(0.5, 0.5);
		vsSprite.updateHitbox();
		add(vsSprite);
		
		add(modDarken);
		add(simpleModBG);
		add(modSlots);
		add(modTexts);
		add(modSubtitles);
		add(modVal);

		add(modBG);
		add(modTxt);
		for (tri in modTriangles)
			add(tri);
		
		add(borderTop = new Border(true, "SELECT A SONG • ", "Freeplay"));
		add(borderBot = new Border(false));

		// TODO: make a shortcut for these buttons for cleanup.
		final buttonY = borderBot.border.y + 58; // unfortunately 58 is the only number that centers it.
		var upButton = new FunkinSprite(borderBot.x + 40, buttonY, Paths.image('menus/keyIndicator'));
		upButton.scrollFactor.set(0, 1);
		borderBot.add(upButton);

		var downButton = new FunkinSprite(upButton.x + upButton.width + 3, buttonY, Paths.image('menus/keyIndicator'));
		downButton.angle = 180;
		downButton.scrollFactor.set(0, 1);
		borderBot.add(downButton);

		var changeSongTxt = new FlxText((downButton.x + downButton.width) + 5, downButton.y, 0, _t("freeplay_scroll"), 16);
		changeSongTxt.font = Paths.font('LineSeed.ttf');
		changeSongTxt.scrollFactor.set(0, 1);
		borderBot.add(changeSongTxt);
		
		var leftButton = new FunkinSprite(changeSongTxt.x + changeSongTxt.width + 50, buttonY, Paths.image('menus/keyIndicator'));
		leftButton.angle = 270;
		leftButton.scrollFactor.set(0, 1);
		borderBot.add(leftButton);

		var rightButton = new FunkinSprite(leftButton.x + leftButton.width + 3, buttonY, Paths.image('menus/keyIndicator'));
		rightButton.angle = 90;
		rightButton.scrollFactor.set(0, 1);
		borderBot.add(rightButton);

		var changeDiffTxt = new FlxText((rightButton.x + rightButton.width) + 5, rightButton.y, 0, _t("diff_scroll"), 16);
		changeDiffTxt.font = Paths.font('LineSeed.ttf');
		changeDiffTxt.scrollFactor.set(0, 1);
		borderBot.add(changeDiffTxt);

		var mButton = new FunkinSprite(changeDiffTxt.x + changeDiffTxt.width + 50, buttonY, Paths.image('menus/M button'));
		mButton.scale.set(0.5, 0.5);
		mButton.updateHitbox();
		mButton.scrollFactor.set(0, 1);
		borderBot.add(mButton);

		var modifiersTxt = new FlxText((mButton.x + mButton.width) + 5, mButton.y, 0, _t("modifiers"), 16);
		modifiersTxt.font = Paths.font('LineSeed.ttf');
		modifiersTxt.scrollFactor.set(0, 1);
		borderBot.add(modifiersTxt);

		var eButton = new FunkinSprite(modifiersTxt.x + modifiersTxt.width + 50, buttonY, Paths.image('menus/E button'));
		eButton.scale.set(0.5, 0.5);
		eButton.updateHitbox();
		eButton.scrollFactor.set(0, 1);
		borderBot.add(eButton);
	
		borderBot.add(sortTxt = new FlxText((eButton.x + eButton.width) + 5, eButton.y, 0, '', 16));
		sortTxt.font = Paths.font('LineSeed.ttf');
		sortTxt.scrollFactor.set(0, 1);
		
		sortSongs(sorts[curSort].method);

		changeSelection();
		changeDifficulty();
		bg.speed = lastSpeed;

		if (fromPlayState) {
			fromPlayState = false;

			borderTop.y += FlxG.height;
			borderBot.y -= FlxG.height;

			var ogOffsets = [];
			for (thing in borderBot.members) {
				ogOffsets.push(thing.offset.y);
				thing.visible = thing == borderBot.border;
			}
			FlxTween.num(0, 1, 0.75, {ease: FlxEase.cubeOut}, function(num) {
				final height = FlxG.height * (1 - num);
				borderTop.y = height;
				borderBot.y = -height;
				borderTop.fill = -Math.min(FlxG.camera.scroll.y, 0) + borderTop.y;
				borderBot.fill = Math.min(FlxG.camera.scroll.y, 0) - borderBot.y;

				for (i => thing in borderBot.members) {
					if (thing == borderBot.border || borderTop.border.frameHeight - 40 >= thing.y + thing.height - 5) continue;

					thing.visible = true;
					final y = Math.max((borderTop.border.frameHeight - 40) - thing.y, 0);
					thing.clipGraphic(0, y, thing.graphic.width, thing.graphic.height - y);
					thing.offset.y = ogOffsets[i] - y;
				}
			});
		} else
			borderTop.transitionTween(true);
	}
	
	override function update(delta:Float):Void {
		super.update(delta);

		if (FlxG.mouse.justPressed) {
			dragging = true;
			dragY = FlxG.mouse.screenY;
		} else if (dragging && !exiting) {
			final dist = Math.round((FlxG.mouse.screenY - dragY) / 75);

			if (dist != 0) {
				draggedOnce = true;
				dragY += 75 * dist;
				(inMods ? changeModSel : changeSelection)(-dist);
				FlxG.sound.play(Paths.audio("menu_move", "sfx"));
			}

			if (FlxG.mouse.justReleased) {
				dragging = false;
				draggedOnce = false;
				dragY = -1;
			}
		}

		if (!Settings.data.reducedQuality) {
			selectTriangle.angle += delta * 160;
			lineShader.time.value[0] = SwirlBG.time / 64;
			
			lerpScore = FlxMath.lerp(lerpScore, curPlay.score, delta * 12.5);
			scoreCount.text = Std.string(Math.round(lerpScore));
		}

		bg.speed = FlxMath.lerp(bg.speed, 1.0, delta * 15.0);

		for (i => square in diffSquares) {
			final txt = diffTitles.members[i];
			final rat = diffRatings.members[i];

			var fromCenter = (i - centerDiff);
			var targetScale = (i == curDiffSelected) ? 1.0 : 0.85;
			var targetAlpha = 1.0;
			if (Math.abs(fromCenter) > 2) {
				targetScale = 0.0;
				targetAlpha = 0.0;
			} else if (Difficulty.list.length > 5) {
				final centerSquare = (i == 0 || i == Difficulty.list.length - 1 || Math.abs(fromCenter) < 2);
				targetScale = centerSquare ? targetScale : 0.5;
				targetAlpha = centerSquare ? 1 : 0.5;
				fromCenter *= centerSquare ? 1 : 0.875;
			}
			square.x = FlxMath.lerp(square.x, metadataBG.x + metadataBG.width * 0.5 + 95 * fromCenter, delta * 15);
			square.scale.x = square.scale.y = FlxMath.lerp(square.scale.x, targetScale, delta * 15);
			Util.lerpColorTransform(square.colorTransform, (i == curDiffSelected ? Difficulty.colors[i] : 0xFF1A1A1A), delta * 15, targetAlpha);
			txt.alpha = rat.alpha = square.alpha;

			txt.scale.copyFrom(square.scale);
			txt.origin.set();
			txt.x = square.x - square.frameWidth * square.scale.x * 0.5 + square.scale.x * 15;
			txt.y = square.y + (square.frameHeight - square.frameHeight * square.scale.y) * 0.5 + square.scale.y * 5;

			rat.scale.copyFrom(square.scale);
			rat.origin.set();
			rat.x = square.x - square.frameWidth * square.scale.x * 0.5;
			rat.y = square.y + square.frameHeight * 0.5 - 10 * square.scale.y;

			final top = square.y + (square.frameHeight - square.frameHeight * square.scale.y) * 0.5;
			final skewAmt = 26 * (1.0 - (FlxG.mouse.y - top) / (square.frameHeight * square.scale.y));
			final left = square.x - square.frameWidth * 0.5 + skewAmt + (square.frameWidth - square.frameWidth * square.scale.x) * 0.5;

			if ((!exiting && !inMods && FlxG.mouse.justReleased && !draggedOnce) && FlxG.mouse.x >= left && FlxG.mouse.x <= left + (square.frameWidth - 26) * square.scale.x && FlxG.mouse.y >= top && FlxG.mouse.y <= top + square.frameHeight * square.scale.y) {
				if (curDiffSelected == i)
					selectSong();
				else {
					changeDifficulty(i - curDiffSelected);
					FlxG.sound.play(Paths.audio("menu_setting_tick", "sfx"));
				}
			}
		}

		modSin += delta * 0.5 * Math.PI;
		for (tri in modTriangles)
			tri.x = modTxt.x + modTxt.height * 1.75 + 3 * Math.abs(Math.sin(modSin));

		final selSlot = songSlots.members[curSelected];
		selectTriangle.scale.copyFrom(selSlot.scale);
		selectTriangle.x = selSlot.x - selSlot.offset.x + 55;
		selectTriangle.y = selSlot.y - selSlot.frameHeight * selSlot.scale.y * 0.35;
		scoreCount.y = selSlot.y + selSlot.frameHeight * selSlot.scale.y * 0.5 + 10 - scoreCount.height;
		scoreTitle.setPosition(selSlot.txt.x, scoreCount.y + scoreTitle.height * 0.35);
		scoreCount.x = scoreTitle.x + scoreTitle.width + 5;
		ranking.setPosition(selSlot.x - selSlot.offset.x + 605 * selSlot.scale.x - ranking.width, selSlot.y + selSlot.frameHeight * 0.5 - ranking.height * 0.75);
		// clearType.setPosition(ranking.x - 5 - clearType.width, selSlot.y + selSlot.frameHeight * 0.5 - clearType.height * 0.75);

		jacketBorder.color = simpleModBG.color = modBG.color = FlxColor.interpolate(modBG.color, songList[songSlots.members[curSelected].ID].colours[1], delta * 15);
		@:privateAccess modVal.regenGraphic();
		modVal.origin.set();
		modVal.scale.x = modVal.scale.y = FlxMath.lerp(modVal.scale.x, 1.0, delta * 15);
		modVal.x = modTexts.members[curMod].x;
		modVal.y = modSlots.members[curMod].y + modSlots.members[curMod].frameHeight * modSlots.members[curMod].scale.y * 0.5 + 10 - modVal.frameHeight * modVal.scale.y;
		@:privateAccess var modValUvX = modTexts.members[curMod]._frame.frame.x / modVal.scale.x;
		modVal.clipGraphic(modValUvX, 0, modVal.graphic.width - modValUvX, modVal.graphic.height);
		modVal.x += modValUvX * modVal.scale.x;

		if (echoSlot != null && echoSlot.visible) {
			echoSlot.clipGraphic(0, 0, selSlot.frameWidth, selSlot.frameHeight);
			echoSlot.offset.copyFrom(selSlot.offset);
			echoSlot.origin.copyFrom(selSlot.origin);
			echoSlot.setPosition(selSlot.x - (echoSlot.frameWidth * echoSlot.scale.x - selSlot.frameWidth - echoSlot.scale.y), selSlot.y);
		}
		for (i => slot in songSlots.members)
			slot.offset.x = FlxMath.lerp(slot.offset.x, (i == curSelected || !exiting) ? modBG.width - 2 : -720, delta * 6);

		final hitboxOffset = -0.5 * (modBG.width - modBG.frameWidth);
		modDarken.alpha = FlxMath.lerp(modDarken.alpha, inMods ? 1 : 0, delta * 7.5);
		modBG.offset.x = FlxMath.lerp(modBG.offset.x - hitboxOffset, inMods ? FlxG.width * 0.575 : 0, delta * 12.5);
		simpleModBG.offset.x = -0.5 * (simpleModBG.width - simpleModBG.frameWidth) + modBG.offset.x;
		modTxt.offset.x = modBG.offset.x;
		for (tri in modTriangles) {
			tri.offset.x = -0.5 * (tri.width - tri.frameWidth) + modBG.offset.x;
			tri.angle = FlxMath.lerp(tri.angle, inMods ? 180 : 0, delta * 20);
		}
		for (slot in modSlots)
			slot.offset.x = modBG.offset.x;
		modBG.offset.x += hitboxOffset;

		//FlxG.camera.scroll.x = FlxMath.lerp(FlxG.camera.scroll.x, inMods ? FlxG.width * 0.575 : 0, delta * 15);

		if (exiting) return;

		if (FlxG.keys.justPressed.M || (FlxG.mouse.justPressed && (inMods ? FlxG.mouse.x < modBG.x - modBG.offset.x + hitboxOffset : FlxG.mouse.x >= modBG.x - modBG.offset.x + hitboxOffset))) {
			inMods = !inMods;
			dragging = false;
			draggedOnce = false;
			dragY = -1;
			if (!inMods)
				updateMeta();
			FlxG.sound.play(Paths.audio(inMods ? "popup_appear" : "popup_select", "sfx"));
		} else if (FlxG.keys.justPressed.E) {
			curSort = FlxMath.wrap(curSort + 1, 0, sorts.length - 1);
			sortSongs(sorts[curSort].method);
		}

		(inMods ? modInputs : songInputs)(delta, Controls.justPressed('ui_down'), Controls.justPressed('ui_left'));
	}

	override function destroy() {
		self = null;
		super.destroy();
	}

	function songInputs(delta:Float, downJustPressed:Bool, leftJustPressed:Bool) {
		/*if (FlxG.keys.justPressed.P) {
			debugClear = (debugClear + 1) % Ranking.clearTypeList.length;
			clearType.visible = true;
			clearType.color = Ranking.clearTypeColours[debugClear];
			clearType.text = Ranking.clearTypeList[debugClear];
		}*/

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			Addons.current = '';
			exiting = true;
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
			borderTop.transitionTween(false, 0, 0.25, function() {
				FlxG.switchState(new funkin.states.MainMenuState());
			});
		} else if (FlxG.mouse.wheel != 0 || downJustPressed || Controls.justPressed('ui_up')) {
			changeSelection(FlxG.mouse.wheel != 0 ? -FlxG.mouse.wheel : (downJustPressed ? 1 : -1));
			FlxG.sound.play(Paths.audio("menu_move", "sfx"));
		} else if (leftJustPressed || Controls.justPressed('ui_right')) {
			changeDifficulty(leftJustPressed ? -1 : 1);
			FlxG.sound.play(Paths.audio("menu_setting_tick", "sfx"));
		} else if (Controls.justPressed('accept')) {
			selectSong();
		}
	}

	function updateDiffMeta() {
		curPlay = Scores.get(curSong.id, Difficulty.list[curDiffSelected], curSong.meta.hasModchart);
		if (Settings.data.reducedQuality)
			scoreCount.text = Std.string(curPlay.score);

		if (curPlay.accuracy < 0){
			ranking.visible = false;
			//clearType.visible = false;
		} else {
			final rank = Ranking.getFromAccuracy(curPlay.accuracy);
			//final clearIdx = Ranking.clearTypeList.indexOf(curPlay.clearType);

			ranking.visible = true;
			ranking.color = rank.color;
			ranking.text = rank.name;

			/*clearType.visible = true;
			clearType.color = Ranking.clearTypeColours[clearIdx];
			clearType.text = curPlay.clearType;*/
		}

		final diff = (Settings.data.gameplayModifiers["playingSide"] == "Dancer") ? "Camellia" : Difficulty.list[curDiffSelected];
		botMetaVal.text = '${curSong.meta.vocalComposer}\n${curSong.meta.jacket}\n${curSong.meta.charter.get(diff)}'.toUpperCase();
	}

	function updateMeta() {
		updateDiffMeta();

		topMetaVal.text = '${curSong.meta.timingPoints[0]?.bpm ?? 1}\n${curSong.meta.genre}\n${curSong.meta.album}'.toUpperCase();
		
		final isDancer = (Settings.data.gameplayModifiers["playingSide"] == "Dancer");
		final diffIdx = (Settings.data.gameplayModifiers["playingSide"] == "Opponent") ? 1 : 0;
		for (i in 0...Difficulty.list.length) {
			final diffs = curSong.meta.rating.get(isDancer ? "Camellia" : Difficulty.list[i]);
			if (diffs == null || diffs.length < (diffIdx + 1))
				diffRatings.members[i].text = "?";
			else
				diffRatings.members[i].text = Std.string(Math.floor(diffs[diffIdx])) + (diffs[diffIdx] % 1 != 0 ? "+" : ""); // im not making a mini plus.
		}
	}

	function songClick(slot:FreeplaySongSlot, released:Bool) {
		if (exiting || inMods || !released || draggedOnce) return;

		if (slot.curTarget != 0)
			changeSelection(slot.curTarget);
		else
			selectSong();
	}

	function selectSong() {
		final songID:String = curSong.id;
		final diff:String = Difficulty.list[curDiffSelected];
		if (!Song.exists(songID, diff)) {
			trace('Chart does not exist: $songID - $diff');
			FlxG.sound.play(Paths.audio("menu_deletedata", "sfx"));

			if (noChartTwn != null)
				noChartTwn.cancel();

			noChartTwn = FlxTween.num(0, 1.25, 1.25, null, function(num) {
				if (num < 0.2) {
					var scale = num * 5.0;
					var sin = Math.sin(scale * Math.PI);
					noChart.scale.x = 1.5 - 0.5 * (scale - sin);
					noChart.scale.y = 1 / (2 - (scale - sin));
				} else {
					noChart.scale.x = 1.0;
					noChart.scale.y = 1.0 - FlxEase.cubeOut(Math.max((num - 1.0) * 4.0, 0.0));
				}
			});

			return;
		}

		Dialogue.fromMenu = true;
		Addons.current = curSong.folder;
		PlayState.songID = songID;
		Difficulty.current = diff;
		PauseMenu.musicPath = curSong.pauseMusic;
		exiting = true;

		FlxG.mouse.visible = false;
		FlxG.sound.play(Paths.audio("menu_finish", "sfx"));
		FlxTween.num(1, 0, 1, {ease: FlxEase.quadOut}, function(num) {
			Conductor.inst.volume = num;
		});

		final selSlot = songSlots.members[curSelected];
		echoSlot.visible = true;
		echoSlot.clipGraphic(0, 0, selSlot.frameWidth, selSlot.frameHeight);
		echoSlot.scale.copyFrom(selSlot.scale);

		FlxTween.tween(echoSlot, {"scale.x": 1.5, "scale.y": 1.5, "alpha": 0}, 1, {ease: FlxEase.cubeOut});
		//FlxTween.tween(bg, {"alpha": 0.35}, 0.15, {ease: FlxEase.cubeOut});
		FlxTween.num(1, 0, 0.5, {ease: FlxEase.cubeOut}, function(num) {
			for (item in [metadataBG, topMetadata, topMetaVal, botMetadata, botMetaVal, jacketBorder, jacket, iconP1, iconP2, vsSprite])
				item.alpha = num;

			for (i => square in diffSquares) {
				if (i == curDiffSelected) continue;
				square.alpha = num;
				diffTitles.members[i].alpha = num;
				diffRatings.members[i].alpha = num;
			}
		});

		var ogOffsets = [for (thing in borderBot.members) thing.offset.y];
		FlxTween.num(1, 0, 1, {ease: FlxEase.cubeIn, startDelay: 0.25, onComplete: function(twn) {
			PlayState.inTransition = true;
			openSubState(new FreeplayTransition(curSong.meta, function() {
				for (mem in members) {
					if (mem == null || !mem.exists || !mem.alive) continue;
					mem.visible = mem == borderTop || mem == borderBot;
				}

				var jacketPath:String = 'jackets/${curSong.id}';
				if (!Paths.exists('images/$jacketPath.png')) jacketPath = 'jackets/default';

				final jacketGraph:FlxGraphic = Paths.image(jacketPath);
				jacketGraph.persist = true;
				jacketGraph.destroyOnNoUse = false;

				Paths.clearExcept([
					Paths.getCacheKey('menus/border.png', 'IMG', 'images'),
					Paths.getCacheKey('menus/borderTop.png', 'IMG', 'images'),
					Paths.getCacheKey('menus/Freeplay/albumBorder.png', 'IMG', 'images'),
					Paths.getCacheKey(jacketPath+".png", 'IMG', 'images')
				]);
				FlxG.switchState(new PlayState());
				return false;
			}, true));
		}}, function(num) {
			final height = FlxG.height * (1 - num);
			borderTop.y = height;
			borderBot.y = -height;
			borderTop.fill = -Math.min(FlxG.camera.scroll.y, 0) + borderTop.y;
			borderBot.fill = Math.min(FlxG.camera.scroll.y, 0) - borderBot.y;

			for (i => thing in borderBot.members) {
				if (thing == borderBot.border || borderTop.border.frameHeight - 40 >= thing.y + thing.height - 5) {
					thing.visible = thing == borderBot.border;
					continue;
				}

				final y = Math.max((borderTop.border.frameHeight - 40) - thing.y, 0);
				thing.clipGraphic(0, y, thing.graphic.width, thing.graphic.height - y);
				thing.offset.y = ogOffsets[i] - y;
			}
		});
	}

	function changeSelection(?dir:Int = 0):Void {
		songSlots.members[curSelected].txtOffset = 0.0;
		curSelected = FlxMath.wrap(curSelected + dir, 0, songSlots.length - 1);
		songSlots.members[curSelected].txtOffset = 45.0;
		
		for (i => slot in songSlots.members)
			slot.retarget(i - curSelected);

		bg.speed = 10;

		var jacketPath:String = 'jackets/${curSong.id}';
		if (!Paths.exists('images/$jacketPath.png')) jacketPath = 'jackets/default';

		jacket.changeTo(jacketPath, initJacket, ()->{
			jacket.nextSprite.setGraphicSize(jacketBorder.width - 3, jacketBorder.height - 3);
			jacket.nextSprite.updateHitbox();
		},()->{
			jacket.curSprite.setGraphicSize(jacketBorder.width - 3, jacketBorder.height - 3);
			jacket.curSprite.updateHitbox();
		});

		initJacket = false;
		
		loadDiffs((curSong.meta.diffs != null && curSong.meta.diffs.length > 0) ? curSong.meta.diffs : curSong.weekDiffs);
		updateMeta();

		iconP1.change(curSong.icons[0]);
		iconP2.change(curSong.icons[1]);

		bg.targetColor1 = curSong.colours[0];
		bg.targetColor2 = curSong.colours[1];
	}

	function changeDifficulty(?dir:Int = 0):Void {
		final diffColor = Difficulty.colors[curDiffSelected];
		
		diffRatings.members[curDiffSelected].color = diffColor;
		diffTitles.members[curDiffSelected].color = diffColor;
		diffTitles.members[curDiffSelected].font = Paths.font("menus/GOTHIC.TTF");

		curDiffSelected = FlxMath.wrap(curDiffSelected + dir, 0, Difficulty.list.length - 1);
		if (Difficulty.list.length > 5)
			centerDiff = FlxMath.bound(curDiffSelected, 2, Difficulty.list.length - 3);

		diffRatings.members[curDiffSelected].color = 0xFFFFFFFF;
		diffTitles.members[curDiffSelected].color = 0xFFFFFFFF;
		diffTitles.members[curDiffSelected].font = Paths.font("menus/GOTHICB.TTF");

		final slotColor = Difficulty.colors[curDiffSelected];
		slotShader.color.value = [slotColor.redFloat, slotColor.greenFloat, slotColor.blueFloat, 1.0];
		//diffText.text = 'Difficulty: ${Difficulty.list[curDiffSelected]}';

		updateDiffMeta();

		if (sorts[curSort].sensitive)
			sortSongs(sorts[curSort].method);
	}

	function sortSongs(method:(a:FreeplaySongData, b:FreeplaySongData) -> Int) {
		var sortedSongs = songList.copy();
		sortedSongs.sort(method);
		curSelected = sortedSongs.indexOf(curSong);

		selectTriangle.x = FlxG.width;
		scoreCount.x = FlxG.width;
		scoreTitle.x = FlxG.width;

		// make the array full of null instead of emptying
		// just reduces allocation
		for (i in 0...songSlots.length) {
			songSlots.members[i] = null;
			songTexts.members[i] = null;
			songSubtitles.members[i] = null;
		}

		for (i => song in sortedSongs) {
			final slot = song.slot;

			slot.retarget(i - curSelected);
			slot.setPosition(
				FlxG.width,
				slot.targetY
			);
			slot.postReposition();

			songSlots.insert(i, slot);
			songTexts.insert(i, slot.txt);
			songSubtitles.insert(i, slot.sub);
		}
	
		sortTxt.text = 'SORT (${sorts[curSort].name.toUpperCase()})';
	}

	function loadDiffs(diffs:Array<DiffData>) {
		if (diffSquares.length == Difficulty.list.length) {
			var allTheSame = true;
			for (i in 0...diffs.length) {
				if (diffs[i].name != Difficulty.list[i]) {
					allTheSame = false;
					break;
				}
			}

			if (allTheSame)
				return;
		}

		final center = (diffs.length - 1) * 0.5;
		var diffIdx = -1;
		for (i in 0...diffs.length) {
			if (diffs[i].name == Difficulty.list[curDiffSelected]) {
				diffIdx = i;
				break;
			}
		}
		curDiffSelected = diffIdx < 0 ? Math.floor(diffs.length * 0.5) : diffIdx;
		centerDiff = diffs.length > 5 ? FlxMath.bound(curDiffSelected, 2, diffs.length - 3) : center;

		final slotColor = diffs[curDiffSelected].color;
		slotShader.color.value = [slotColor.redFloat, slotColor.greenFloat, slotColor.blueFloat, 1.0];

		for (i in 0...Std.int(Math.min(diffs.length, diffSquares.length))) {
			final square = diffSquares.members[i];
			square.x = metadataBG.x + metadataBG.width * 0.5;
			square.color = i == curDiffSelected ? diffs[i].color : 0xFF1A1A1A;
			square.alpha = 1;
			square.scale.set();

			final txt = diffTitles.members[i];
			txt.font = i == curDiffSelected ? Paths.font("menus/GOTHICB.TTF") : Paths.font("menus/GOTHIC.TTF");
			txt.color = i == curDiffSelected ? 0xFFFFFFFF : diffs[i].color;
			txt.text = diffs[i].name.toUpperCase();
			txt.x = square.x + 15;
			txt.alpha = 1;
			txt.scale.set();
		
			final rat = diffRatings.members[i];
			rat.color = txt.color;
			rat.x = square.x;
			rat.alpha = 1;
			rat.scale.set();
		}

		while (diffSquares.length > diffs.length) {
			final square = diffSquares.members[diffSquares.length - 1];
			final txt = diffTitles.members[diffTitles.length - 1];
			final rat = diffRatings.members[diffRatings.length - 1];

			diffSquares.remove(square, true);
			diffTitles.remove(txt, true);
			diffRatings.remove(rat, true);
			
			square.destroy();
			txt.destroy();
			rat.destroy();
		}

		while (diffSquares.length < diffs.length) {
			var square = new FunkinSprite(metadataBG.x + metadataBG.width * 0.5, 25 + metadataBG.y + metadataBG.height, Paths.image("menus/Freeplay/diffSqr"));
			square.color = diffSquares.length == curDiffSelected ? diffs[diffSquares.length].color : 0xFF1A1A1A;
			square.offset.x = square.frameWidth * 0.5;
			square.scale.set();
			diffSquares.add(square);

			var txt = new FlxText(square.x + 15, square.y + 5, square.width - 15, diffs[diffTitles.length].name.toUpperCase());
			txt.setFormat(diffTitles.length == curDiffSelected ? Paths.font("menus/GOTHICB.TTF") : Paths.font("menus/GOTHIC.TTF"), 16, 0xFFFFFFFF, CENTER);
			txt.color = diffTitles.length == curDiffSelected ? 0xFFFFFFFF : diffs[diffTitles.length].color;
			txt.scale.copyFrom(square.scale);
			diffTitles.add(txt);

			var rat = new FlxText(square.x, square.y + square.height * 0.5 - 10, square.width - 5, "?");
			rat.setFormat(Paths.font("menus/GOTHICB.TTF"), 32, 0xFFFFFFFF, CENTER);
			rat.scale.copyFrom(txt.scale);
			rat.color = txt.color;
			diffRatings.add(rat);
		}

		Difficulty.list = [for (diff in diffs) diff.name];
		Difficulty.colors = [for (diff in diffs) diff.color];
	}

	function loadSongs() {
		WeekData.reload();

		songList.resize(0);
		for (week in WeekData.list) {
			for (song in week.songs) {
				var pauseMusic:String = week.pauseMusic;
				if (song.pauseMusic.length != 0) pauseMusic = song.pauseMusic;
			
				final song:FreeplaySongData = {
					id: song.id,
					weekDiffs: week.diffs,
					colours: song.colors,
					pauseMusic: pauseMusic,
					meta: Meta.load(song.id),
					icons: song.icons,
					folder: week.folder,

					slot: null
				};
				songList.push(song);
			}	
		}

		for (i => song in songList) {
			var slot = new FreeplaySongSlot(i - curSelected, (FlxG.random.bool(song.meta.rngChance) ? song.meta.randomName : song.meta.songName), song.meta.subtitle);
			slot.offset.x = -720;
			slot.shader = slotShader;
			slot.onClick = songClick;
			slot.ID = i;
			songSlots.add(slot);
			songTexts.add(slot.txt); // for batching, the txt and subtitle stay in their own groups. (that sounds discrimitory oh god)
			songSubtitles.add(slot.sub);
			
			song.slot = slot;
		}
	}

	function modInputs(delta:Float, downJustPressed:Bool, leftJustPressed:Bool) {
		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			inMods = false;
			dragging = false;
			draggedOnce = false;
			dragY = -1;
			updateMeta();
			FlxG.sound.play(Paths.audio("popup_select", "sfx"));
		} else if (FlxG.mouse.wheel != 0 || downJustPressed || Controls.justPressed('ui_up')) {
			changeModSel(FlxG.mouse.wheel != 0 ? -FlxG.mouse.wheel : (downJustPressed ? 1 : -1));
			FlxG.sound.play(Paths.audio("menu_move", "sfx"));
		} else if (leftJustPressed || Controls.justPressed('ui_right')) {
			modList[curMod].change(leftJustPressed);
			modVal.text = ("< " + modList[curMod].formatText(true) + " >").toUpperCase();

			FlxG.sound.play(Paths.audio(modList[curMod].sound, 'sfx'));

			if (modList[curMod].updateMeta) {
				updateMeta();
				if (sorts[curSort].sensitive)
					sortSongs(sorts[curSort].method);
			}
		} else if (Controls.justPressed('accept')) {
			modList[curMod].change(false);
			modVal.text = ("< " + modList[curMod].formatText(true) + " >").toUpperCase();
			FlxG.sound.play(Paths.audio(modList[curMod].sound, 'sfx'));
			
			if (modList[curMod].updateMeta) {
				updateMeta();
				if (sorts[curSort].sensitive)
					sortSongs(sorts[curSort].method);
			}
		}

		if (Settings.data.reducedQuality) scoreCount.text = Std.string(curPlay.score);
	}

	function modClick(slot:FreeplaySongSlot, released:Bool) {
		if (!inMods) return;

		if (slot.curTarget != 0 && released && !draggedOnce) {
			curMod = curMod + slot.curTarget;
			modVal.text = ("< " + modList[curMod].formatText(true) + " >").toUpperCase();
			
			modVal.scale.set();
			for (i => slot in modSlots.members)
				slot.retarget(i - curMod);

			FlxG.sound.play(Paths.audio("menu_move", "sfx"));
		} else if (slot.curTarget == 0 && !released) {
			modList[curMod].change(FlxG.mouse.x < modVal.x + modVal.textField.getCharBoundaries(modVal.text.length - 1).x);
			modVal.text = ("< " + modList[curMod].formatText(true) + " >").toUpperCase();
			FlxG.sound.play(Paths.audio(modList[curMod].sound, 'sfx'));
			
			if (modList[curMod].updateMeta)
				updateMeta();
		}
	}

	function changeModSel(dir:Int) {
		curMod = FlxMath.wrap(curMod + dir, 0, modSlots.length - 1);
		modVal.text = ("< " + modList[curMod].formatText(true) + " >").toUpperCase();
		
		modVal.scale.set();
		for (i => slot in modSlots.members)
			slot.retarget(i - curMod);
	}

	function loadMods() {
		modDarken = new FunkinSprite(0, 0).makeGraphic(1, 1, 0x80000000);
		modDarken.scale.set(FlxG.width, FlxG.height);
		modDarken.updateHitbox();

		simpleModBG = new FunkinSprite(FlxG.width, 0).makeGraphic(1, 1, 0xFF808080);
		simpleModBG.scale.set(FlxG.width, FlxG.height);
		simpleModBG.updateHitbox();

		// weird + 2
		modBG = new FunkinSprite(FlxG.width + 2, 0).makeGraphic(1, 1, 0xFFE7E7E7);
		modBG.scale.set(25, FlxG.height);
		modBG.updateHitbox();
		modBG.x -= modBG.width;

		modTxt = new FlxText(modBG.x + modBG.width * 0.5, modBG.y + modBG.height * 0.5, 0, _t("modifiers"));
		modTxt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 14, 0xFFFFFFFF, CENTER);
		modTxt.x -= modTxt.height * 2.25; // WHY DO THESE NUMBERS WORK. WHY THE RECIPROCAL + HALF AND HALF. WHY NOT JUST 0.5
		modTxt.y -= modTxt.width * 0.25;
		modTxt.angle = 270;

		var modTri1 = new FunkinSprite(modTxt.x + modTxt.height * 1.75, modTxt.y - modTxt.width * 0.375 - 3, Paths.image("menus/triangle"));
		modTri1.scale.scale(0.35);
		modTri1.updateHitbox();
		modTri1.y -= modTri1.height;
		modTriangles.push(modTri1);
		
		var modTri2 = new FunkinSprite(modTxt.x + modTxt.height * 1.75, modTxt.y + modTxt.width * 0.625 + 3, Paths.image("menus/triangle"));
		modTri2.scale.scale(0.35);
		modTri2.updateHitbox();
		modTriangles.push(modTri2);
		
		modSlots = new FlxTypedGroup<FreeplaySongSlot>();
		modTexts = new FlxTypedGroup<FlxText>();
		modSubtitles = new FlxTypedGroup<FlxText>();

		for (i => mod in modList) {
			var slot = new FreeplaySongSlot(i - curMod, mod.name, mod.desc, true);
			slot.shader = slotShader;
			slot.onClick = modClick;
			modSlots.add(slot);
			modTexts.add(slot.txt);
			modSubtitles.add(slot.sub);
		}

		modVal = new FlxText(modTexts.members[curMod].x, modSlots.members[curMod].y + modSlots.members[curMod].frameHeight * 0.5 + 10, 0, ("< " + modList[curMod].formatText(true) + " >").toUpperCase(), 48);
		modVal.setFormat(Paths.font("Rockford-NTLG Light Italic.ttf"), 48, 0xFFB0B0B0, RIGHT);
		modVal.y -= modVal.height;
	}

	public static function preloadAlbumCovers():Void {
		for (albumCover in Paths.readDirectory("images/jackets"))
        	if (albumCover.endsWith(".png"))//this is just in case someone wants to add more file types
            	Paths.image('jackets/${haxe.io.Path.withoutExtension(albumCover)}');
	}
}

class GameModifier {
	public var name:String;
	public var desc:String;
	public var sound:String = "menu_setting_tick";
	public var updateMeta:Bool = false;

	public var id:String;
	public var type:OptionType;
	@:isVar public var value(get, set):Dynamic;

	//type specific
	public var powMult:Float = 1;
	
	public dynamic function onChange(v:Dynamic) {}

	public dynamic function formatText(selected:Bool):String {
		return '$value';
	}

	public function new(name:String, desc:String, settingsVar:String, type:OptionType, ?updateMeta:Bool = false) {
		this.name = name;
		this.desc = desc;
		this.updateMeta = updateMeta;
		this.id = settingsVar;
		this.type = type;

		switch (type) {
			case BoolOption:
				sound = "menu_toggle";
				formatText = function(_) {
					return value ? "ON" : "OFF";
				};
			case FloatOption(min, max, inc, wrap):
				// add some increment specific rounding to prevent .599999999999999999999
				inc ??= 0.05;
				// my desmos graph idea of 10 ^ floor(log(x)) did not work so now i need this
				while (inc < 1) {
					inc *= 10;
					powMult *= 10;
				}
				while (inc > 9) {
					inc *= 0.1;
					powMult *= 0.1;
				}
			default: // nothin
		}
	}

	public function change(left:Bool) {
		switch (type) {
			case IntOption(min, max, inc, wrap):
				inc ??= 1;
				inc *= left ? -1 : 1;
				wrap ??= false;

				final range = (max - min);
				var curVal:Float = value;
				curVal = wrap ? (((curVal - min) + inc + range) % range) + min : FlxMath.bound(curVal + inc, min, max);
				value = Std.int(curVal);
			case FloatOption(min, max, inc, wrap):
				inc ??= 0.05;
				inc *= left ? -1 : 1;
				wrap ??= false;

				final range = (max - min);
				var curVal:Float = value;
				curVal = wrap ? (((curVal - min) + inc + range) % range) + min : FlxMath.bound(curVal + inc, min, max);
				value = Math.round(curVal * powMult) / powMult;
			case BoolOption:
				value = !value;
			case ListOption(list):
				final inc = left ? -1 : 1;
				value = list[FlxMath.wrap(list.indexOf(value) + inc, 0, list.length - 1)];
			default: // nothin
		}
	}

	function get_value():Dynamic {
		return Settings.data.gameplayModifiers.get(id);
	}

	function set_value(v:Dynamic):Dynamic {
		Settings.data.gameplayModifiers.set(id, v);

		onChange(v);
		return v;
	}
}