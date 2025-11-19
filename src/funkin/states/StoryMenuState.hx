package funkin.states;

import openfl.text.Font;
import funkin.objects.ui.Border;
import flixel.math.FlxRect;
import flixel.math.FlxAngle;
import flixel.graphics.FlxGraphic;
import flixel.addons.effects.FlxSkewedSprite;
import funkin.objects.FunkinSprite;
import funkin.objects.ui.SwirlBG;
import funkin.shaders.TileLine;
import funkin.shaders.GraphGradient;
import funkin.backend.WeekData;

using StringTools;

class StoryMenuState extends FunkinState {
	public static var fromPlayState:Bool = false;
	static var curHover:Int = 0;
	var curDiffSelected:Int = 0;
	var curSelected:Int = -1;
	var exiting:Bool = false;
	var draggedOnce:Bool = false;
	var dragging:Bool = false;
	var dragY:Float = -1;
	var diffPoints:Array<Float>;
	var curScore:Int = 0;
	var lerpScore:Float = 0;
	var weekList:Array<WeekFile>;
	
	var banners:FlxTypedGroup<FunkinSprite>;
	var infoGroup:FlxSpriteGroup;
	var selectOutline:FunkinSprite;
	var selectBG:FunkinSprite;
	var selectNum:FlxText;
	var selectTitle:FlxText;
	var selectSubtitle:FlxText;
	var selectTri:FunkinSprite;

	// variables to create a mouse deadzone
	final MOUSE_DEADZONE = 5; // technically 10, but goes in both directions.
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;
	var mouseMoved:Bool = false;

	static var curMod:Int = 0;
	static var modKeyRow:Int = 0;
	var inMods:Bool = false;
	var curModRow:Float = 0;
	var hoverMod:Int = 0;
	var modBGs:FlxTypedSpriteGroup<FunkinSprite>;
	var modNames:FlxTypedSpriteGroup<FlxText>;
	var modVals:FlxTypedSpriteGroup<FlxText>;
	var modDescBG:FunkinSprite;
	var modDesc:FlxText;
	var MOD_BG_WIDTH:Float = 450;
	var MOD_BG_HEIGHT:Float = 50;

	var graphTwn:FlxTween;
	var graphShader:GraphGradient;
	var scoreBG:FunkinSprite;
	var graph:FunkinSprite;
	var graphLines:FlxSpriteGroup;
	var graphDots:FlxSpriteGroup;
	var bestTitle:FlxText;
	var bestScore:FlxText;
	var rankTitle:FlxText;
	var bestRank:FlxText;
	var songBGs:FlxTypedSpriteGroup<FunkinSprite>;
	var songNames:FlxTypedSpriteGroup<FlxText>;
	var songDiffs:FlxTypedSpriteGroup<FlxText>;
	var diffBGs:FlxTypedGroup<FunkinSprite>;
	var diffNames:FlxTypedGroup<FlxText>;
	var diffSel:FunkinSprite;

	var borderTop:Border;
	var borderBot:Border;

	var scrollMinusButton:FunkinSprite;
	var scrollPlusButton:FunkinSprite;
	var scrollTxt:FlxText;
	var mButton:FunkinSprite;
	var modifiersTxt:FlxText;

	var bg:SwirlBG;
	var lineShader:TileLine;

	var inTween:Bool = false;

	// i hate this i hate this i hate this i hate this i hate this
	function finickyTextRelining() {
		@:privateAccess {
			if (Font.__fontByName.exists("storyFont")) return;
	
			var font = Font.fromFile(Paths.font("LineSeed.ttf"));
			if (font != null) {
				font.fontName = "storyFont";
				Font.__registeredFonts.push(font);
				Font.__fontByName["storyFont"] = font;
				font.descender = Math.floor(font.descender * 0.35);
				font.ascender = Math.floor(font.ascender * 0.75);
			}
		}
	}

	override function create():Void {
		finickyTextRelining();
		super.create();
		curDiffSelected = Difficulty.list.indexOf(Difficulty.current);
		hoverMod = curMod;
		curModRow = FreeplayState.modList.length + 1;

		// temporary colors (or colours cuz yunno, rudy rudy)
		add(bg = new SwirlBG(0xFF3D3473, 0xFFF344D3));

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

		add(selectOutline = new FunkinSprite(FlxG.width * 0.5, FlxG.height * 0.5, Paths.image("menus/Story/outline")));
		selectOutline.offset.set(selectOutline.frameWidth * 0.5, selectOutline.frameHeight * 0.5);
		selectOutline.alpha = 0.0;

		WeekData.reload();
		weekList = [for (week in WeekData.list) if (!week.hideStory) week];
		curHover = Std.int(FlxMath.bound(curHover, 0, weekList.length - 1));
		loadWeeks();

		add(infoGroup = new FlxSpriteGroup());
		infoGroup.setPosition(FlxG.width * 0.5 - 345, FlxG.height * 0.5);
		
		infoGroup.add(selectBG = new FunkinSprite());
		selectBG.makeGraphic(635, 120, 0x80000000);
		
		infoGroup.add(selectNum = new FlxText(50, 15, selectBG.width - 40, 'Week ${weekList[curHover].weekNum}:', 18));
		selectNum.systemFont = "storyFont";
		
		infoGroup.add(selectTitle = new FlxText(50, 25, selectNum.fieldWidth, weekList[curHover].name));
		selectTitle.setFormat(Paths.font("LineSeedB.ttf"), 32, 0xFFFFFFFF, LEFT);
		
		infoGroup.add(selectSubtitle = new FlxText(50, 72, selectTitle.fieldWidth, weekList[curHover].subtitle, 18));
		selectSubtitle.systemFont = "storyFont";
		
		infoGroup.add(selectTri = new FunkinSprite(15, 40, Paths.image("menus/triangle")));
		selectTri.flipX = true;
		selectTri.origin.x += 3; // UUUUUGGGGGGGGHHHHHHHHH
		
		infoGroup.add(scoreBG = new FunkinSprite(0, 125).makeGraphic(1, 1, 0x80000000));
		scoreBG.origin.set();
		scoreBG.scale.set(375, 0);

		infoGroup.add(graph = new FunkinSprite(170, 200).makeGraphic(175, 155, 0x00000000));
		if (Settings.data.shaders)
			graphShader = new GraphGradient();

		graph.shader = (Settings.data.shaders) ? graphShader : null;
		graph.alpha = 0;

		infoGroup.add(graphDots = new FlxSpriteGroup());
		graphDots.setPosition(graph.x, graph.y);
		graphDots.directAlpha = true;

		infoGroup.add(graphLines = new FlxSpriteGroup());
		graphLines.setPosition(graph.x, graph.y);
		graphLines.directAlpha = true;

		infoGroup.add(bestRank = new FlxText(-55, 95, 0, "S+")); // longest text
		bestRank.setFormat(Paths.font("menus/bozonBI.otf"), 256, 0xFFFFFFFF, LEFT);
		bestRank.updateHitbox();
		bestRank.clipRect = FlxRect.get(55, 0, bestRank.frameWidth - 55, bestRank.frameHeight);
		bestRank.alpha = 0;
		bestRank.text = "";

		infoGroup.add(rankTitle = new FlxText(15, 315, 0, 'BEST GRADE:', 14));
		rankTitle.systemFont = "storyFont";
		rankTitle.alpha = 0;

		infoGroup.add(bestTitle = new FlxText(15, 140, 0, 'BEST SCORE:', 14));
		bestTitle.systemFont = "storyFont";
		bestTitle.alpha = 0;

		infoGroup.add(bestScore = new FlxText(15 + bestTitle.width, 125, 0, '0'));
		bestScore.setFormat(Paths.font("Rockford-NTLG Light Italic.ttf"), 52, 0xFFC8B4D6, LEFT);
		bestScore.alpha = 0;

		infoGroup.add(songBGs = new FlxTypedSpriteGroup<FunkinSprite>());
		infoGroup.add(songNames = new FlxTypedSpriteGroup<FlxText>());
		infoGroup.add(songDiffs = new FlxTypedSpriteGroup<FlxText>());

		loadMods();

		add(diffBGs = new FlxTypedGroup<FunkinSprite>());
		add(diffNames = new FlxTypedGroup<FlxText>());
		add(diffSel = new FunkinSprite(-999, -999, Paths.image("menus/Story/diffGrad")));
		diffSel.colorTransform.alphaOffset = -117; // the first man to use alphaOffset

		var storyTile = new flixel.addons.display.FlxBackdrop(Paths.image('menus/Story/bigText'), Y);
		storyTile.velocity.y = 25;
		add(storyTile);
		
		add(borderTop = new Border(true, "SELECT A WEEK • ", "Story"));
		add(borderBot = new Border(false));

		// TODO: make a shortcut for these buttons for cleanup.
		final buttonY = borderBot.border.y + 58; // unfortunately 58 is the only number that centers it.
		scrollMinusButton = new FunkinSprite(borderBot.x + 40, buttonY, Paths.image('menus/keyIndicator'));
		scrollMinusButton.scrollFactor.set(0, 1);
		borderBot.add(scrollMinusButton);

		scrollPlusButton = new FunkinSprite(scrollMinusButton.x + scrollMinusButton.width + 3, buttonY, Paths.image('menus/keyIndicator'));
		scrollPlusButton.angle = 180;
		scrollPlusButton.scrollFactor.set(0, 1);
		borderBot.add(scrollPlusButton);

		scrollTxt = new FlxText((scrollPlusButton.x + scrollPlusButton.width) + 5, scrollPlusButton.y, 0, _t("diff_scroll"), 16); // use 'diff_scroll' for aligning with mButton. it'll be normal soon.
		scrollTxt.font = Paths.font('LineSeed.ttf');
		scrollTxt.scrollFactor.set(0, 1);
		borderBot.add(scrollTxt);

		mButton = new FunkinSprite(scrollTxt.x + scrollTxt.width + 50, buttonY, Paths.image('menus/M button'));
		mButton.scale.set(0.5, 0.5);
		mButton.updateHitbox();
		mButton.scrollFactor.set(0, 1);
		borderBot.add(mButton);

		modifiersTxt = new FlxText((mButton.x + mButton.width) + 5, mButton.y, 0, _t("modifiers"), 16);
		modifiersTxt.font = Paths.font('LineSeed.ttf');
		modifiersTxt.scrollFactor.set(0, 1);
		borderBot.add(modifiersTxt);
		scrollTxt.text = _t("story_scroll");

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
		
		if (!Settings.data.reducedQuality) {
			selectTri.angle += delta * 160;
			lineShader.time.value[0] = SwirlBG.time / 64;

			lerpScore = FlxMath.lerp(lerpScore, curScore, delta * 12.5);
			bestScore.text = Std.string(Math.round(lerpScore));
		}
		bg.speed = FlxMath.lerp(bg.speed, 1.0, delta * 15.0);
		
		mouseMoved = false;
		if (Math.abs(FlxG.mouse.screenX - lastMouseX) >= MOUSE_DEADZONE || Math.abs(FlxG.mouse.screenY - lastMouseY) >= MOUSE_DEADZONE) {
			lastMouseX = FlxG.mouse.screenX;
			lastMouseY = FlxG.mouse.screenY;
			mouseMoved = true;
		}

		final listHeight = (MOD_BG_HEIGHT + 5) * 5 - 5;
		for (i => bg in modBGs.members) {
			var name = modNames.members[i];
			var val = modVals.members[i];

			bg.y = FlxMath.lerp(bg.y, modBGs.y + (bg.height + 5) * (i - curModRow), delta * 15);
			name.y = bg.y + (bg.height - name.height) * 0.5;
			val.y = bg.y + bg.height - val.frameHeight * 0.75;

			var alpha = Math.min(1 - (Math.abs(bg.y + bg.height * 0.5 - (modBGs.y + listHeight * 0.5)) - listHeight * 0.5) * 0.0425, 1);
			var scale = 1 - (1 - alpha) * 0.3;
			
			bg.colorTransform.redMultiplier = bg.colorTransform.greenMultiplier = bg.colorTransform.blueMultiplier = FlxMath.lerp(bg.colorTransform.redMultiplier, (i == hoverMod) ? 1 : 0, delta * 20);
			name.colorTransform.redMultiplier = name.colorTransform.greenMultiplier = name.colorTransform.blueMultiplier = 1 - bg.colorTransform.redMultiplier;
			val.colorTransform.redMultiplier = val.colorTransform.greenMultiplier = val.colorTransform.blueMultiplier = 1 - bg.colorTransform.redMultiplier * 0.6;
			
			bg.colorTransform.alphaMultiplier = Math.min(Math.max(alpha * (0.5 + 0.25 * bg.colorTransform.redMultiplier), 0), 1);
			name.colorTransform.alphaMultiplier = val.colorTransform.alphaMultiplier = Math.min(Math.max(alpha, 0), 1);

			bg.scale.set(bg.width * scale, bg.height * scale);
			name.scale.set(scale, scale);
			val.scale.set(scale, scale);
		}
		modDescBG.alpha = modDesc.alpha = FlxMath.lerp(modDescBG.alpha, inMods ? 1 : 0, delta * 15);
		modDescBG.y = modBGs.y + listHeight + 5 + 30 * (1 - modDescBG.alpha);
		modDesc.y = modDescBG.y + 5;

		for (i => bg in diffBGs.members) {
			bg.y = borderBot.border.y;
			Util.lerpColorTransform(bg.colorTransform, (i == curDiffSelected ? Difficulty.colors[i] : 0xFF1A1A1A), delta * 15);
			diffNames.members[i].y = bg.y + (bg.height - diffNames.members[i].height) * 0.5;
		}
		if (curSelected > -1) {
			diffSel.y = diffBGs.members[curDiffSelected].y + diffBGs.members[curDiffSelected].height - diffSel.height;
			diffSel.colorTransform.alphaOffset = FlxMath.lerp(diffSel.colorTransform.alphaOffset, -35, delta * 15 * diffBGs.members[curDiffSelected].alpha);

			scrollMinusButton.angle = FlxMath.lerp(scrollMinusButton.angle, -90, delta * 15);
			scrollPlusButton.angle = FlxMath.lerp(scrollPlusButton.angle, 90, delta * 15);
			mButton.alpha = modifiersTxt.alpha = FlxMath.lerp(mButton.alpha, 1, delta * 15);
			mButton.y = modifiersTxt.y = scrollMinusButton.y + 15 * (1 - mButton.alpha);
		} else {
			diffSel.colorTransform.alphaOffset = FlxMath.lerp(diffSel.colorTransform.alphaOffset, -117, delta * 15);

			scrollMinusButton.angle = FlxMath.lerp(scrollMinusButton.angle, 0, delta * 15);
			scrollPlusButton.angle = FlxMath.lerp(scrollPlusButton.angle, 180, delta * 15);
			mButton.alpha = modifiersTxt.alpha = FlxMath.lerp(mButton.alpha, 0, delta * 15);
			mButton.y = modifiersTxt.y = scrollMinusButton.y + 15 * (1 - mButton.alpha);
		}
		scrollTxt.y = FlxMath.lerp(scrollTxt.y, scrollMinusButton.y, delta * 15);

		selectOutline.alpha = FlxMath.lerp(selectOutline.alpha, -Math.min(curSelected, 0), delta * 10);
		selectOutline.scale.x = selectOutline.scale.y = 1.15 - 0.15 * selectOutline.alpha;

		if (exiting) return;

		for (i => banner in banners.members) {
			banner.setPosition(
				FlxMath.lerp(banner.x, FlxG.width * 0.5 + 55 * (i - curHover), delta * 15),
				FlxMath.lerp(banner.y, FlxG.height * 0.5 + 225 * (i - curHover), delta * 15)
			);

			banner.alpha = FlxMath.lerp(banner.alpha, (curSelected == -1 || i == curSelected) ? 0.9 : 0.0, delta * 10);
		}

		final curBanner = banners.members[curHover];
		selectOutline.setPosition(curBanner.x, curBanner.y);
		infoGroup.setPosition(
			FlxMath.lerp(infoGroup.x, (curSelected == -1) ? curBanner.x - 345 : 80, delta * 15),
			FlxMath.lerp(infoGroup.y, (curSelected == -1) ? curBanner.y : 155, delta * 15)
		);

		if (!inTween)
			(curSelected == -1 ? scrollInputs : (inMods ? modInputs : weekInputs))();
	}

	function selectWeek() {
		curSelected = curHover;
		inTween = true;
		final week = weekList[curSelected];

		FlxG.sound.play(Paths.audio("popup_select", 'sfx'));
		scrollTxt.text = _t("diff_scroll");
		scrollTxt.y -= 10;

		var diffIdx = -1;
		for (i in 0...week.diffs.length) {
			if (week.diffs[i].name == Difficulty.list[curDiffSelected]) {
				diffIdx = i;
				break;
			}
		}
		curDiffSelected = diffIdx < 0 ? Math.floor(week.diffs.length * 0.5) : diffIdx;
		Difficulty.list = [for (diff in week.diffs) diff.name];
		Difficulty.colors = [for (diff in week.diffs) diff.color];

		for (i => diff in Difficulty.list) {
			// 942 will be the only number to keep consistent spacing so TIME TO BREAK TABLES
			var sqr = new FunkinSprite(borderBot.border.x + 942, borderBot.border.y, Paths.image("menus/Story/diffSqr"));
			sqr.x -= sqr.width * 0.75 * (Difficulty.list.length - 1 - i);
			sqr.setColorTransform(0.1, 0.1, 0.1, 0, 0, 0, 0, 0);
			diffBGs.add(sqr);

			var txt = new FlxText(sqr.x, sqr.y + sqr.height * 0.5, sqr.width, diff.toUpperCase());
			if (i == curDiffSelected)
				txt.setFormat(Paths.font("menus/GOTHICB.TTF"), 16, 0xFFFFFFFF, CENTER);
			else
				txt.setFormat(Paths.font("menus/GOTHIC.TTF"), 16, Difficulty.colors[i], CENTER);
			txt.y -= txt.height * 0.5;
			txt.alpha = 0.0;
			diffNames.add(txt);
		}
		diffSel.setPosition(diffBGs.members[curDiffSelected].x, diffBGs.members[curDiffSelected].y + diffBGs.members[curDiffSelected].height - diffSel.height);

		final curDiff = (Settings.data.gameplayModifiers["playingSide"] == "Dancer") ? "Camellia" : Difficulty.list[curDiffSelected];
		final diffIdx = (Settings.data.gameplayModifiers["playingSide"] == "Opponent") ? 1 : 0;
		final songs = weekList[curSelected].songs;
		final splitWidth = (songs.length < 2) ? graph.width : graph.width / (songs.length - 1);
		final songHeight = (250 - 5 * (songs.length - 1)) / songs.length;
		curScore = 0;
		var allSongs = true;
		var acc = 1.0;
		diffPoints = [];
		for (i => song in songs) {
			final meta = Meta.load(song.id);
			final diffs = meta.rating.get(curDiff);

			// TODO: use the actual number when we got more ratings in the meta
			diffPoints.push((diffs == null || diffs.length < (diffIdx + 1)) ? 0 : Math.floor(diffs[diffIdx]) * 0.05);

			final score = Scores.get(song.id, Difficulty.list[curDiffSelected], meta.hasModchart);
			curScore += score.score;
			acc *= score.accuracy * 0.01;
			allSongs = allSongs && (score.accuracy >= 0);

			final div = (songs.length < 2) ? 1 : i / (songs.length - 1);
			var dot = new FunkinSprite(FlxMath.lerp(0, graph.width, div), graph.height, Paths.image("menus/Story/graphDot"));
			dot.clipGraphic(0, 0, dot.frameWidth, 4.5);
			dot.updateHitbox();
			dot.x -= dot.width * 0.5;
			dot.y -= dot.height * 0.5;
			graphDots.add(dot);

			var bg = new FunkinSprite((scoreBG.x - infoGroup.x) + scoreBG.scale.x + 5, (scoreBG.y - infoGroup.y) + (5 + songHeight) * i).makeGraphic(1, 1, 0x80000000);
			bg.scale.set(selectBG.width - bg.x, songHeight);
			bg.updateHitbox();
			bg.origin.set();
			bg.offset.set();
			bg.alpha = 0;
			
			final nameTxt = (FlxG.random.bool(meta.rngChance) ? meta.randomName : meta.songName);
			var name:FlxText = new FlxText(bg.x + 5, bg.y + bg.height * 0.5, bg.width - 5, nameTxt.toUpperCase());
			name.setFormat(Paths.font("menus/GOTHIC.TTF"), 14, 0xFFFFFFFF, LEFT);
			name.y -= name.height * 0.5;
			name.alpha = 0;

			final diffTxt = (diffs == null || diffs.length < (diffIdx + 1)) ? "?" : Std.string(Math.floor(diffs[diffIdx])) + (diffs[diffIdx] % 1 != 0 ? "+" : "");
			var diff:FlxText = new FlxText(bg.x + bg.width - 5, bg.y + bg.height, 0, diffTxt);
			diff.setFormat(Paths.font("menus/GOTHICB.TTF"), 50, 0xFFA0A0A0, RIGHT);
			diff.updateHitbox();
			diff.clipGraphic(0, 0, diff.frameWidth, diff.frameHeight * 0.75);
			diff.x -= diff.frameWidth;
			diff.y -= diff.frameHeight;
			diff.alpha = 0;
			
			songBGs.add(bg);
			songNames.add(name);
			songDiffs.add(diff);
			
			if (songs.length > 1 && i == songs.length - 1) continue;

			var line = new FunkinSprite(splitWidth * i, graph.height).makeGraphic(1, 1, 0xFFFFFFFF);
			line.scale.set(splitWidth, 2);
			line.updateHitbox();
			line.y -= line.height * 0.5;
			graphLines.add(line);
		}

		if (Settings.data.reducedQuality)
			bestScore.text = Std.string(curScore);
		final rank:Ranking = allSongs ? Ranking.getFromAccuracy(acc * 100) : {};
		bestRank.text = rank.name;
		bestRank.color = rank.color;

		if (Settings.data.shaders){
			graphShader.setPoints(diffPoints);
			graphShader.progress.value[0] = 0;
		}

		graphDots.alpha = 0.0;
		graphLines.alpha = 0.0;
		final halfDiv = 0.5 / songs.length;
		final diffDiv = 0.5 / Difficulty.list.length;
		FlxTween.num(0, 0.5, 0.375, null, function(num) {
			for (i => bg in songBGs.members) {
				final name = songNames.members[i];
				final diff = songDiffs.members[i];

				if (num < halfDiv * i || bg.alpha >= 1.0) continue;

				bg.alpha = name.alpha = diff.alpha = FlxEase.cubeIn((num - halfDiv * i) / halfDiv);
				bg.offset.x = name.offset.x = diff.offset.x = -30 * (1.0 - bg.alpha);
			}
			for (j in 0...diffBGs.members.length) {
				final i = Difficulty.list.length - 1 - j;
				final bg = diffBGs.members[i];
				final name = diffNames.members[i];

				if (num < diffDiv * i || bg.alpha >= 1.0) continue;

				bg.alpha = name.alpha = FlxEase.quadOut(Math.min((num - diffDiv * i) / diffDiv, 1.0));
				bg.offset.y = name.offset.y = 15 * (1.0 - bg.alpha);
			}
		});

		final curBanner = banners.members[curHover];
		final imgScale = curBanner.graphic.width / 640;
		final startScale = 640 / curBanner.graphic.width;
		final scale = FlxG.height / Math.min(360 * imgScale, curBanner.graphic.height - week.selectedClipY);
		
		FlxTween.num(0, 1, 0.75, {ease: FlxEase.quintInOut, onComplete: function(twn) {
			inTween = false;
		}}, function(num) {
			curBanner.scale.x = curBanner.scale.y = FlxMath.lerp(startScale, scale, num);
			final clipY = FlxMath.lerp(week.unselectedClipY, week.selectedClipY, num);
			curBanner.clipGraphic(0, clipY, curBanner.graphic.width, Math.min(FlxMath.lerp(190, 360, num) * imgScale, curBanner.graphic.height - clipY));
			curBanner.origin.set(curBanner.frameWidth * 0.5, curBanner.frameHeight * 0.5);
			curBanner.offset.copyFrom(curBanner.origin);

			graphDots.alpha = num;
			for (i => dot in graphDots.members) {
				final height = graph.frameHeight * diffPoints[i] * num + 4.5;
				dot.clipGraphic(0, 0, dot.frameWidth, height + 1);
				dot.y = graph.y + graph.height - height;
			}
			graphLines.alpha = num;
			for (i => line in graphLines.members) {
				if (graphLines.length == 1) {
					line.y = graph.y + graph.height * (1.0 - diffPoints[i] * num) - line.height * 0.5;
					continue;
				}

				final height1 = graph.height * diffPoints[i] * num;
				final height2 = graph.height * diffPoints[i + 1] * num;
				line.y = graph.y + graph.height - FlxMath.lerp(height1, height2, 0.5) - line.height * 0.5;
				line.angle = Math.atan((height1 - height2) / splitWidth) * FlxAngle.TO_DEG;
				line.scale.x = Math.sqrt(splitWidth * splitWidth + Math.pow(height2 - height1, 2));
			}
			if (Settings.data.shaders)
				graphShader.progress.value[0] = num;
		});

		FlxTween.tween(graph, {alpha: 1.0}, 0.25, {ease: FlxEase.cubeOut});
		var scoreTwn = FlxTween.tween(scoreBG.scale, {y: 250}, 0.25, {ease: FlxEase.cubeOut});
		scoreTwn.then(FlxTween.num(0, 1, 0.25, {ease: FlxEase.cubeOut}, function(num) {
			for (obj in [bestRank, rankTitle, bestTitle, bestScore]) {
				obj.alpha = num;
				obj.offset.y = 30 * (1 - num);
			}
		}));
	}
	
	function retarget(?dir:Int = 0) {
		banners.members[curHover].color = 0xFF808080;
		curHover = FlxMath.wrap(curHover + dir, 0, weekList.length - 1);
		banners.members[curHover].color = 0xFFFFFFFF;

		bg.speed = 10;
		selectNum.text = 'Week ${weekList[curHover].weekNum}:';
		selectTitle.text = weekList[curHover].name;
		selectSubtitle.text = weekList[curHover].subtitle;
		
		selectOutline.alpha = 0.0;
	}

	function scrollInputs() {
		final downJustPressed:Bool = Controls.justPressed('ui_down');

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			exiting = true;
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
			borderTop.transitionTween(false, 0, 0.25, function() {
				FlxG.switchState(new funkin.states.MainMenuState());
			});
		} else if (FlxG.mouse.wheel != 0 || downJustPressed || Controls.justPressed('ui_up')) {
			retarget(FlxG.mouse.wheel != 0 ? -FlxG.mouse.wheel : (downJustPressed ? 1 : -1));
			FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
		} else if (Controls.justPressed('accept'))
			selectWeek();

		for (i => banner in banners.members) {
			if (FlxG.mouse.justReleased && !draggedOnce && FlxG.mouse.x >= banner.x - banner.width * 0.5 && FlxG.mouse.x <= banner.x + banner.width * 0.5 && FlxG.mouse.y >= banner.y - banner.height * 0.5 && FlxG.mouse.y <= banner.y + banner.height * 0.5) {
				if (i != curHover) {
					retarget(i - curHover);
					FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				} else
					selectWeek();
			}
		}

		if (FlxG.mouse.justPressed) {
			dragging = true;
			dragY = FlxG.mouse.screenY;
		} else if (dragging) {
			final dist = Math.round((FlxG.mouse.screenY - dragY) / 150);

			if (dist != 0) {
				draggedOnce = true;
				dragY += 150 * dist;
				retarget(-dist);
				FlxG.sound.play(Paths.audio("menu_move", "sfx"));
			}

			if (FlxG.mouse.justReleased) {
				dragging = false;
				draggedOnce = false;
				dragY = -1;
			}
		}
	}

	function confirmWeek() {
		Addons.current = weekList[curSelected].folder;
		
		Dialogue.fromMenu = true;
		PlayState.songList = [for (song in weekList[curSelected].songs) song.id];
		WeekData.current = WeekData.list.indexOf(weekList[curSelected]); // certain weeks can be hidden from story mode
		Difficulty.current = Difficulty.list[curDiffSelected];
		PlayState.storyMode = true;
		PauseMenu.musicPath = weekList[curSelected].pauseMusic;

		FlxG.mouse.visible = false;
		FlxG.sound.play(Paths.audio("menu_finish", "sfx"));
		FlxTween.num(1, 0, 1, {ease: FlxEase.quadOut}, function(num) {
			Conductor.inst.volume = num;
		});

		var rouxls = new FunkinSprite(FlxG.width * 0.5 - 1, 0);
		rouxls.makeGraphic(1, 1, 0xFFFFFFFF);
		rouxls.scale.set(2, FlxG.height);
		rouxls.updateHitbox();
		insert(members.indexOf(borderTop), rouxls);

		FlxTween.tween(rouxls.scale, {x: FlxG.width}, 0.25, {ease: FlxEase.quartOut});
		FlxTween.color(rouxls, 1, Settings.data.flashingLights ? 0xFFFFFFFF : 0xFF282828, 0xFF000000, {ease: FlxEase.cubeOut});

		exiting = true;
		var ogOffsets = [for (thing in borderBot.members) thing.offset.y];
		FlxTween.num(1, 0, 1, {ease: FlxEase.cubeIn, startDelay: 0.25, onComplete: function(twn) {
			new FlxTimer().start(1, function(tmr) {
				for (mem in members) {
					if (mem == null || !mem.exists || !mem.alive) continue;
					mem.visible = mem == borderTop || mem == borderBot;
				}

				Paths.clearExcept([
					Paths.getCacheKey('menus/border.png', 'IMG', 'images'),
					Paths.getCacheKey('menus/borderTop.png', 'IMG', 'images')
				]);

				FlxG.switchState(new PlayState());
			});
			// PlayState.inTransition = true;
			// openSubState(new FreeplayTransition(curSong.meta, function() {
			// 	FlxG.switchState(new PlayState());
			// 	return false;
			// }, true));
		}}, function(num) {
			final height = FlxG.height * (1 - num) - FlxG.camera.scroll.y;
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

	function changeDifficulty(dir:Int = 0) {
		if (dir != 0) {
			diffNames.members[curDiffSelected].color = Difficulty.colors[curDiffSelected];
			diffNames.members[curDiffSelected].font = Paths.font("menus/GOTHIC.TTF");
	
			curDiffSelected = FlxMath.wrap(curDiffSelected + dir, 0, Difficulty.list.length - 1);
			diffSel.setPosition(diffBGs.members[curDiffSelected].x, diffBGs.members[curDiffSelected].y + diffBGs.members[curDiffSelected].height - diffSel.height);
			diffSel.colorTransform.alphaOffset = -117;
	
			diffNames.members[curDiffSelected].color = 0xFFFFFFFF;
			diffNames.members[curDiffSelected].font = Paths.font("menus/GOTHICB.TTF");
		}

		var oldPoints:Array<Float> = [for (i in 0...diffPoints.length) diffPoints[i]];
		var finalPoints:Array<Float> = [];
		final songs = weekList[curSelected].songs;
		final diffIdx = (Settings.data.gameplayModifiers["playingSide"] == "Opponent") ? 1 : 0;
		final curDiff = (Settings.data.gameplayModifiers["playingSide"] == "Dancer") ? "Camellia" : Difficulty.list[curDiffSelected];
		curScore = 0;
		var allSongs = true;
		var acc = 1.0;
		for (i => song in songs) {
			final meta = Meta.load(song.id);
			final diffs = meta.rating.get(curDiff);
			final diffTxt = songDiffs.members[i];
			
			final score = Scores.get(song.id, Difficulty.list[curDiffSelected], meta.hasModchart);
			curScore += score.score;
			acc *= score.accuracy * 0.01;
			allSongs = allSongs && (score.accuracy >= 0);
			
			finalPoints.push((diffs == null || diffs.length < (diffIdx + 1)) ? 0 : Math.floor(diffs[diffIdx]) * 0.05);
			diffTxt.text = (diffs == null || diffs.length < (diffIdx + 1)) ? "?" : Std.string(Math.floor(diffs[diffIdx])) + (diffs[diffIdx] % 1 != 0 ? "+" : "");
			diffTxt.updateHitbox();
			diffTxt.clipGraphic(0, 0, diffTxt.graphic.width, diffTxt.graphic.height * 0.75);
			diffTxt.x = songBGs.members[i].x + songBGs.members[i].width - 5 - diffTxt.frameWidth;
		}

		if (Settings.data.reducedQuality)
			bestScore.text = Std.string(curScore);
		final rank:Ranking = allSongs ? Ranking.getFromAccuracy(acc * 100) : {};
		bestRank.text = rank.name;
		bestRank.color = rank.color;

		final splitWidth = (songs.length < 2) ? graph.width : graph.width / (songs.length - 1);
		if (graphTwn != null)
			graphTwn.cancel();

		graphTwn = FlxTween.num(0, 1, 0.35, {ease: FlxEase.quintOut, onComplete: function(twn) {
			graphTwn = null;
		}}, function(num) {
			for (i in 0...diffPoints.length)
				diffPoints[i] = FlxMath.lerp(oldPoints[i], finalPoints[i], num);

			if (Settings.data.shaders)
				graphShader.setPoints(diffPoints);

			for (i => dot in graphDots.members) {
				final height = graph.frameHeight * diffPoints[i] + 4.5;
				dot.clipGraphic(0, 0, dot.frameWidth, height + 1);
				dot.y = graph.y + graph.height - height;
			}
			for (i => line in graphLines.members) {
				if (graphLines.length == 1) {
					line.y = graph.y + graph.height * (1.0 - diffPoints[i]) - line.height * 0.5;
					continue;
				}
	
				final height1 = graph.height * diffPoints[i];
				final height2 = graph.height * diffPoints[i + 1];
				line.y = graph.y + graph.height - FlxMath.lerp(height1, height2, 0.5) - line.height * 0.5;
				line.angle = Math.atan((height1 - height2) / splitWidth) * FlxAngle.TO_DEG;
				line.scale.x = Math.sqrt(splitWidth * splitWidth + Math.pow(height2 - height1, 2));
			}
		});
	}

	function weekInputs() {
		final leftJustPressed:Bool = Controls.justPressed('ui_left');

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			if (graphTwn != null) {
				graphTwn.cancel();
				graphTwn = null;
			}

			final week = weekList[curSelected];
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
			scrollTxt.text = _t("story_scroll");
			scrollTxt.y -= 10;
			curSelected = -1;
			inTween = true;

			final halfDiv = 0.5 / songBGs.length;
			final diffDiv = 0.5 / diffBGs.length;
			final curAOffset = diffSel.colorTransform.alphaOffset;
			FlxTween.num(0.5, 0, 0.375, null, function(num) {
				diffSel.colorTransform.alphaOffset = FlxMath.lerp(-117, curAOffset, num * 2);
				for (i => bg in songBGs.members) {
					final name = songNames.members[i];
					final diff = songDiffs.members[i];

					bg.alpha = name.alpha = diff.alpha = FlxEase.cubeOut((num - halfDiv * i) / halfDiv);
					bg.offset.x = name.offset.x = diff.offset.x = -30 * (1.0 - bg.alpha);
				}
				for (j in 0...diffBGs.members.length) {
					final i = Difficulty.list.length - 1 - j;
					final bg = diffBGs.members[i];
					final name = diffNames.members[i];

					bg.alpha = name.alpha = FlxEase.quadIn(Math.min(Math.max((num - diffDiv * i) / diffDiv, 0.0), 1.0));
					bg.offset.y = name.offset.y = 15 * (1.0 - bg.alpha);
				}
			});

			final splitWidth = (diffPoints.length < 2) ? graph.width : graph.width / (diffPoints.length - 1);
			final curBanner = banners.members[curHover];
			final imgScale = curBanner.graphic.width / 640;
			final startScale = 640 / curBanner.graphic.width;
			final scale = FlxG.height / Math.min(360 * imgScale, curBanner.graphic.height - week.selectedClipY);

			FlxTween.num(0, 1, 0.75, {ease: FlxEase.quintInOut, type: BACKWARD, onComplete: function(twn) {
				while (graphDots.length > 0) {
					final dot = graphDots.members[0];
					graphDots.remove(dot, true);
					dot.destroy();
				}
				while (graphLines.length > 0) {
					final line = graphLines.members[0];
					graphLines.remove(line, true);
					line.destroy();
				}
				while (songBGs.length > 0) {
					final bg = songBGs.members[0];
					final name = songNames.members[0];
					final diff = songDiffs.members[0];

					songBGs.remove(bg, true);
					songNames.remove(name, true);
					songDiffs.remove(diff, true);
					bg.destroy();
					name.destroy();
					diff.destroy();
				}
				while (diffBGs.length > 0) {
					final bg = diffBGs.members[0];
					final name = diffNames.members[0];

					diffBGs.remove(bg, true);
					diffNames.remove(name, true);
					bg.destroy();
					name.destroy();
				}

				inTween = false;
			}}, function(num) {
				curBanner.scale.x = curBanner.scale.y = FlxMath.lerp(startScale, scale, num);
				final clipY = FlxMath.lerp(week.unselectedClipY, week.selectedClipY, num);
				curBanner.clipGraphic(0, clipY, curBanner.graphic.width, Math.min(FlxMath.lerp(190, 360, num) * imgScale, curBanner.graphic.height - clipY));
				curBanner.origin.set(curBanner.frameWidth * 0.5, curBanner.frameHeight * 0.5);
				curBanner.offset.copyFrom(curBanner.origin);

				for (i => dot in graphDots.members) {
					final height = graph.frameHeight * diffPoints[i] * num + 4.5;
					dot.clipGraphic(0, 0, dot.frameWidth, height + 1);
					dot.y = graph.y + graph.height - height;
				}
				for (i => line in graphLines.members) {
					if (graphLines.length == 1) {
						line.y = graph.y + graph.height * (1.0 - diffPoints[i] * num) - line.height * 0.5;
						continue;
					}
	
					final height1 = graph.height * diffPoints[i] * num;
					final height2 = graph.height * diffPoints[i + 1] * num;
					line.y = graph.y + graph.height - FlxMath.lerp(height1, height2, 0.5) - line.height * 0.5;
					line.angle = Math.atan((height1 - height2) / splitWidth) * FlxAngle.TO_DEG;
					line.scale.x = Math.sqrt(splitWidth * splitWidth + Math.pow(height2 - height1, 2));
				}
				if (Settings.data.shaders)
					graphShader.progress.value[0] = num;
			});

			FlxTween.tween(scoreBG.scale, {y: 0}, 0.25, {ease: FlxEase.cubeOut});
			FlxTween.num(1, 0, 0.25, {ease: FlxEase.cubeOut}, function(num) {
				graph.alpha = num;
				graphDots.alpha = num;
				graphLines.alpha = num;
				for (obj in [bestRank, rankTitle, bestTitle, bestScore]) {
					obj.alpha = num;
					obj.offset.y = 30 * (1 - num);
				}
			});
		} else if (leftJustPressed || Controls.justPressed('ui_right')) {
			changeDifficulty(leftJustPressed ? -1 : 1);
			FlxG.sound.play(Paths.audio("menu_setting_tick", 'sfx'));
		} else if (FlxG.keys.justPressed.M) {
			FlxG.sound.play(Paths.audio("popup_appear", "sfx"));
			curModRow = modKeyRow;
			inMods = true;
		} else if (Controls.justPressed('accept'))
			confirmWeek();

		if (FlxG.mouse.y < diffBGs.members[0].y || FlxG.mouse.y > diffBGs.members[0].y + diffBGs.members[0].height) return;
		final xOffset = 42 * (1.0 - (FlxG.mouse.y - diffBGs.members[0].y) / diffBGs.members[0].height);

		for (i => bg in diffBGs.members) {
			if (FlxG.mouse.justReleased && !draggedOnce && FlxG.mouse.x >= bg.x + xOffset && FlxG.mouse.x <= bg.x + xOffset + (bg.width - 42)) {
				if (i != curDiffSelected) {
					changeDifficulty(i - curDiffSelected);
					FlxG.sound.play(Paths.audio("menu_setting_tick", 'sfx'));
				} else
					confirmWeek();
			}
		}
	}

	function loadWeeks() {
		add(banners = new FlxTypedGroup<FunkinSprite>());
		for (i => week in weekList) {
			final path = Paths.exists('images/menus/Story/weeks/${week.background}.png') ? week.background : 'BACKUP';
			var banner = new FunkinSprite(FlxG.width * 0.5 + 55 * (i - curHover), FlxG.height + 225 * (i - curHover), Paths.image('menus/Story/weeks/$path'));
			banner.clipGraphic(0, week.unselectedClipY, banner.graphic.width, Math.min((banner.graphic.width / 640) * 190, banner.graphic.height - week.unselectedClipY));
			banner.setGraphicSize(640);
			banner.updateHitbox();
			banner.offset.set(banner.frameWidth * 0.5, banner.frameHeight * 0.5);
			banner.alpha = 0.0;
			banner.color = (i == curHover) ? 0xFFFFFFFF : 0xFF808080;
			banners.add(banner);
		}
	}

	function updateScore() {
		curScore = 0;
		var allSongs = true;
		var acc = 1.0;
		for (i => song in weekList[curSelected].songs) {
			final meta = Meta.load(song.id);

			final score = Scores.get(song.id, Difficulty.list[curDiffSelected], meta.hasModchart);
			curScore += score.score;
			acc *= score.accuracy * 0.01;
			allSongs = allSongs && (score.accuracy >= 0);
		}

		if (Settings.data.reducedQuality)
			bestScore.text = Std.string(curScore);
		final rank:Ranking = allSongs ? Ranking.getFromAccuracy(acc * 100) : {};
		bestRank.text = rank.name;
		bestRank.color = rank.color;
	}

	function modInputs() {
		final leftJustPressed:Bool = Controls.justPressed('ui_left');
		final upJustPressed:Bool = Controls.justPressed('ui_up');

		inline function setHover(to) {
			modVals.members[hoverMod].text = FreeplayState.modList[hoverMod].formatText(false).toUpperCase();
			hoverMod = to;
			modDesc.text = FreeplayState.modList[hoverMod].desc;
			modVals.members[hoverMod].text = ("< " + FreeplayState.modList[hoverMod].formatText(true) + " >").toUpperCase();
		}

		if (FlxG.mouse.x >= modBGs.x && FlxG.mouse.x <= modBGs.x + MOD_BG_WIDTH && FlxG.mouse.y >= modBGs.y && FlxG.mouse.y <= modBGs.y + (MOD_BG_HEIGHT + 5) * 5 - 5) {
			if (FlxG.mouse.wheel != 0)
				curModRow -= FlxG.mouse.wheel * 0.25;
			if (curModRow < 0 || curModRow > FreeplayState.modList.length - 5)
				curModRow = FlxMath.lerp(curModRow, curModRow < 0 ? 0 : FreeplayState.modList.length - 5, FlxG.elapsed * 10);

			for (i => bg in modBGs.members) {
				if (FlxG.mouse.y < bg.y || FlxG.mouse.y > bg.y + bg.height) continue;
				
				if (mouseMoved && hoverMod != i)
					setHover(i);

				if (hoverMod == i && FlxG.mouse.justPressed) {
					final modVal = modVals.members[i];
					FreeplayState.modList[hoverMod].change(FlxG.mouse.x < modVal.x + modVal.textField.getCharBoundaries(2).x);
					modVal.text = ("< " + FreeplayState.modList[hoverMod].formatText(true) + " >").toUpperCase();
					FlxG.sound.play(Paths.audio(FreeplayState.modList[hoverMod].sound, 'sfx'));

					curMod = hoverMod;
					if (curMod <= modKeyRow + 1)
						modKeyRow = Std.int(Math.max(curMod - 1, 0));
					else if (curMod >= modKeyRow + 3)
						modKeyRow = Std.int(Math.min(curMod - 3, FreeplayState.modList.length - 5));

					if (FreeplayState.modList[hoverMod].updateMeta)
						changeDifficulty();
					else
						updateScore();
				}
			}
		} else {
			setHover(curMod);
			curModRow = modKeyRow;
		}

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight || FlxG.keys.justPressed.M) {
			FlxG.sound.play(Paths.audio("menu_cancel", "sfx"));
			curModRow = FreeplayState.modList.length + 1;
			inMods = false;
		} else if (leftJustPressed || Controls.justPressed('ui_right')) {
			FreeplayState.modList[hoverMod].change(leftJustPressed);
			modVals.members[hoverMod].text = ("< " + FreeplayState.modList[hoverMod].formatText(true) + " >").toUpperCase();
			FlxG.sound.play(Paths.audio(FreeplayState.modList[hoverMod].sound, 'sfx'));

			curMod = hoverMod;
			if (curMod <= modKeyRow + 1)
				modKeyRow = Std.int(Math.max(curMod - 1, 0));
			else if (curMod >= modKeyRow + 3)
				modKeyRow = Std.int(Math.min(curMod - 3, FreeplayState.modList.length - 5));

			if (FreeplayState.modList[hoverMod].updateMeta)
				changeDifficulty();
			else
				updateScore();
		} else if (upJustPressed || Controls.justPressed('ui_down')) {
			setHover((hoverMod + (upJustPressed ? -1 : 1) + modBGs.length) % modBGs.length);
			curMod = hoverMod;
			curModRow = Math.min(curMod, FreeplayState.modList.length - 5);

			FlxG.sound.play(Paths.audio("menu_move", "sfx"));

			if (curMod <= modKeyRow + 1)
				modKeyRow = Std.int(Math.max(curMod - 1, 0));
			else if (curMod >= modKeyRow + 3)
				modKeyRow = Std.int(Math.min(curMod - 3, FreeplayState.modList.length - 5));
			curModRow = modKeyRow;
		} else if (Controls.justPressed('accept')) {
			FreeplayState.modList[hoverMod].change(false);
			modVals.members[hoverMod].text = ("< " + FreeplayState.modList[hoverMod].formatText(true) + " >").toUpperCase();
			FlxG.sound.play(Paths.audio(FreeplayState.modList[hoverMod].sound, 'sfx'));

			curMod = hoverMod;
			if (curMod <= modKeyRow + 1)
				modKeyRow = Std.int(Math.max(curMod - 1, 0));
			else if (curMod >= modKeyRow + 3)
				modKeyRow = Std.int(Math.min(curMod - 3, FreeplayState.modList.length - 5));

			if (FreeplayState.modList[hoverMod].updateMeta)
				changeDifficulty();
			else
				updateScore();
		}
	}

	function loadMods() {
		add(modBGs = new FlxTypedSpriteGroup<FunkinSprite>(745, 155));
		add(modNames = new FlxTypedSpriteGroup<FlxText>(modBGs.x, modBGs.y));
		add(modVals = new FlxTypedSpriteGroup<FlxText>(modBGs.x, modBGs.y));

		for (i => mod in FreeplayState.modList) {
			var bg = new FunkinSprite(0, (MOD_BG_HEIGHT + 5) * i).makeGraphic(1, 1, 0xFFFFFFFF);
			bg.scale.set(MOD_BG_WIDTH, MOD_BG_HEIGHT);
			bg.updateHitbox();
			
			var name:FlxText = new FlxText(bg.x + 5, bg.y + bg.height * 0.5, bg.width - 5, mod.name.toUpperCase());
			name.setFormat(Paths.font("menus/GOTHIC.TTF"), 14, 0xFFFFFFFF, LEFT);
			name.y -= name.height * 0.5;

			var val:FlxText = new FlxText(bg.x + 5, bg.y + bg.height, bg.width - 5, ((i == curMod) ? "< " + mod.formatText(true) + " >" : mod.formatText(false)).toUpperCase());
			val.setFormat(Paths.font("menus/GOTHICB.TTF"), 50, 0xFFA0A0A0, RIGHT);
			val.updateHitbox();
			val.clipRect = FlxRect.get(0, 0, val.frameWidth, val.frameHeight * 0.75);
			val.origin.y = 0;
			val.y -= val.frameHeight * 0.75;

			modBGs.add(bg);
			modNames.add(name);
			modVals.add(val);
		}

		add(modDescBG = new FunkinSprite(modBGs.x, modBGs.y + (MOD_BG_HEIGHT + 5) * 5));
		modDescBG.makeGraphic(1, 1, 0x80000000);
		modDescBG.scale.set(450, 375 - 55 * 5);
		modDescBG.updateHitbox();

		add(modDesc = new FlxText(modDescBG.x + 5, modDescBG.y + 5, modDescBG.width - 5, FreeplayState.modList[curMod].desc));
		modDesc.setFormat(Paths.font("menus/GOTHIC.TTF"), 18, 0xFFFFFFFF, LEFT);
	}
}