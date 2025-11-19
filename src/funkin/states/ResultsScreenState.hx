package funkin.states;

import flixel.graphics.FlxGraphic;
import funkin.backend.Scores.PlayData;
import funkin.objects.ui.Border;
import funkin.backend.Judgement;
import funkin.states.PlayState;
import funkin.shaders.TileLine;

@:structInit class PotentialModIcon {
	public var condition:Void->Bool;
	public var make:Float->FlxSpriteGroup->Float;
}

class ResultsScreenState extends flixel.FlxSubState {
	public static var lastPlay:PlayData;
	
	var accepted:Bool = false;
	var scrollStart:Float = 0;
	var modIcons:FlxSpriteGroup;
	var modFade:FunkinSprite;
	var modifiers:Array<PotentialModIcon> = [
		{
			condition: () -> Settings.data.gameplayModifiers["botplay"],
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/botplay"));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);
		
				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, 'BOTPLAY', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> Settings.data.gameplayModifiers["playingSide"] != "Default",
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/" + Settings.data.gameplayModifiers["playingSide"].toLowerCase()));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);
		
				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, Settings.data.gameplayModifiers["playingSide"].toUpperCase(), 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> PlayState.song.meta.hasModchart && Settings.data.gameplayModifiers["modcharts"],
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/modcharts"));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);
		
				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, 'MODCHARTED', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> Settings.data.gameplayModifiers["playbackRate"] != 1.0,
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/playbackRate"));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);

				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, '${Settings.data.gameplayModifiers["playbackRate"]}x SPEED', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> Settings.data.gameplayModifiers["instakill"] && !Settings.data.gameplayModifiers["onlySicks"],
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/fcOnly"));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);

				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, 'FC ONLY', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> Settings.data.gameplayModifiers["onlySicks"],
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/sicksOnly"));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);

				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, 'SICKS ONLY', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> Settings.data.gameplayModifiers["noFail"],
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/noFail"));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);

				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, 'NO FAIL', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> Settings.data.gameplayModifiers["mirroredNotes"] && !Settings.data.gameplayModifiers["randomizedNotes"],
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/mirror"));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);
		
				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, 'MIRRORED NOTES', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> Settings.data.gameplayModifiers["randomizedNotes"],
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/random"));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);
		
				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, 'RANDOMIZED NOTES', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> !Settings.data.gameplayModifiers["sustains"],
			make: (x, group) -> {
				var icon = new FunkinSprite(x, 0, Paths.image("menus/Results/mods/noHolds"));
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);
		
				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, 'NO HOLDS', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		},
		{
			condition: () -> Settings.data.gameplayModifiers["blind"],
			make: (x, group) -> {
				var img = FlxG.random.bool(10) ? Paths.image("menus/Results/mods/blindAlt") : Paths.image("menus/Results/mods/blind");
				var icon = new FunkinSprite(x, 0, img);
				icon.scale.scale(0.5);
				icon.updateHitbox();
				group.add(icon);
		
				var text = new FlxText((icon.x + icon.width) + 5, 0, 0, 'BLIND', 16);
				text.font = Paths.font('LineSeed.ttf');
				group.add(text);

				return text.x + text.width + 50;
			}
		}
	];

	var continueBG:FunkinSprite;
	var borderTop:Border;
	var borderBot:Border;
	var lineShader:TileLine;

	var jacket:FunkinSprite;
	var jacketOutline:FunkinSprite;
	var nameBG:FunkinSprite;
	var nameTxt:FlxText;
	var diffBG:FunkinSprite;
	var diffTxt:FlxText;

	var lerpJudges:Array<Float> = [];
	var lerpScore:Float = 0;
	var roundScore:Int = 0;
	var scoreBox:FunkinSprite;
	var scoreTxt:FlxText;
	var scoreInc:FlxText;
	var judgeNames:FlxTypedGroup<FlxText>;
	var judgeCounts:FlxTypedGroup<FlxText>;

	var rankBox:FunkinSprite;
	var ranking:FlxText;
	var accTxt:FlxText;
	// var clearTxt:FlxText; for clearType. may or may not throw this in. S+ makes it hard to fit.

	var timeDot:FlxGraphic;
	var timeBox:FunkinSprite;
	var timeSpr:FunkinSprite;
	var earlyTxt:FlxText;
	var lateTxt:FlxText;
	var msTxt:FlxText;
	var animatedTimeDots:FlxTypedGroup<FunkinSprite>;
	var timeTween:FlxTween;

	public function new(){
		super();
		Conductor.onStep.remove(PlayState.self.stepHit);
		Conductor.onBeat.remove(PlayState.self.beatHit);
		Conductor.onMeasure.remove(PlayState.self.measureHit);

		FlxG.timeScale = 1;
		var songLength = Conductor.inst.length;

		var totalMs:Float = 0;
		for (note in PlayState.self.noteHitList) totalMs += note.diff;
		var avgMs:Float = Util.truncateFloat(totalMs / PlayState.self.notesHit);

		var has727 = false;
		for (judge in Judgement.list)
			has727 = has727 || Std.string(judge.hits).contains("727");
		has727 = has727 || Std.string(PlayState.self.comboBreaks - Judgement.max.hits).contains("727");
		has727 = has727 || Std.string(PlayState.self.score).contains("727");
		has727 = has727 || Std.string(Util.truncateFloat(PlayState.self.accuracy, 2)).replace(".", "").contains("727");
		has727 = has727 || Std.string(avgMs).replace(".", "").contains("727");

		@:privateAccess if (has727 && !PlayState.self.disqualified && PlayState.songID != 'tutorial')
			Awards.unlock('727');

		var camBG = new FunkinSprite();
		camBG.makeGraphic(1, 1, 0xFFFFFFFF);
		camBG.scale.set(FlxG.width, FlxG.height);
		camBG.updateHitbox();
		camBG.color = PlayState.self.camHUD.bgColor;
		camBG.alpha = 0;
		add(camBG);

		var bg = new FunkinSprite();
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

		final cacheAlpha = PlayState.self.camHUD.alpha;
		final cacheZoom = PlayState.self.camHUD.zoom;
		var fadeTwn = FlxTween.num(0, 1, 0.5, {ease: FlxEase.quadOut}, function(num) {
			PlayState.self.camHUD.alpha = cacheAlpha * (1 - num);
			PlayState.self.camHUD.zoom = cacheZoom + 0.15 * num;
			
			final daAlpha = PlayState.self.camHUD.bgColor.alphaFloat * PlayState.self.camHUD.alpha;
			camBG.alpha = (daAlpha == 1) ? 0 : (PlayState.self.camHUD.bgColor.alphaFloat - daAlpha) / (1 - daAlpha);
			bg.alpha = num;
		});

		var jacketPath:String = 'jackets/${PlayState.songID}';
		if (!Paths.exists('images/$jacketPath.png')) jacketPath = 'jackets/default';

		jacketOutline = new FunkinSprite(90, 130, Paths.image("menus/Results/jacketOutline"));
		jacketOutline.scale.scale(0.5);
		jacketOutline.updateHitbox();

		add(jacket = new FunkinSprite(jacketOutline.x + 2, jacketOutline.y + 2, Paths.image(jacketPath)));
		jacket.setGraphicSize(jacketOutline.width - 4, jacketOutline.height - 4);
		jacket.updateHitbox();
		add(jacketOutline);

		add(nameBG = new FunkinSprite(jacket.x - 25, jacket.y + jacket.height));
		nameBG.makeGraphic(1, 1, 0xFFFFFFFF);
		nameBG.scale.x = 340;
		nameBG.origin.set();

		jacketOutline.x -= 30;
		jacketOutline.alpha = 0;
		jacket.x -= 30;
		jacket.alpha = 0;

		add(nameTxt = new FlxText(nameBG.x + 5, 0, nameBG.scale.x - 10, PlayState.song.meta.songName.toUpperCase()));
		nameTxt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 36, 0xFF101010, LEFT);
		nameBG.scale.set(0, nameTxt.height + 3);
		nameBG.y -= nameBG.scale.y * 0.55;
		nameTxt.y = nameBG.y + 3;

		add(diffBG = new FunkinSprite(nameBG.x, nameBG.y + nameBG.scale.y));
		diffBG.makeGraphic(1, 1, Difficulty.colors[Difficulty.list.indexOf(Difficulty.current)]);
		diffBG.origin.set();

		final diffs = PlayState.song.meta.rating.get((Settings.data.gameplayModifiers["playingSide"] == "Dancer") ? "Camellia" : Difficulty.current);
		final diffIdx = (Settings.data.gameplayModifiers["playingSide"] == "Opponent") ? 1 : 0;
		add(diffTxt = new FlxText(
			diffBG.x + 5,
			diffBG.y + 3,
			0,
			Difficulty.current.toUpperCase() + "          " + ((diffs == null || diffs.length < (diffIdx + 1)) ? "?" : (Std.string(Math.floor(diffs[diffIdx])) + (diffs[diffIdx] % 1 != 0 ? "+" : "")))
		));
		diffTxt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 24, 0xFFFFFFFF, LEFT);
		diffBG.scale.set(0, diffTxt.height + 3);

		var gradMask = new funkin.shaders.GradMask();
		gradMask.fromCol.value[3] = 1;
		gradMask.toCol.value[3] = 0;
		gradMask.from.value = [-0.15];
		gradMask.to.value = [-0.05];
		nameTxt.shader = diffTxt.shader = gradMask;

		var jacketTwn = FlxTween.num(0, 1, 0.75, {ease: FlxEase.cubeOut, startDelay: fadeTwn.duration * 0.75}, function(num) {
			jacketOutline.x = 45 + 30 * num;
			jacket.x = jacketOutline.x + 2;
			jacketOutline.alpha = jacket.alpha = num;

			nameBG.scale.x = (nameTxt.width + 10) * num;
			diffBG.scale.x = (diffTxt.width + 10) * num;
			gradMask.to.value[0] = num * 1.15 - 0.05;
			gradMask.from.value[0] = gradMask.to.value[0] - 0.1;
		});

		if (PlayState.self.notesHit > 0) {
			add(rankBox = new FunkinSprite(jacket.x + jacket.width - 1.5, 105, Paths.image("menus/Results/rankBox")));
			rankBox.scale.scale(0.5);
			rankBox.updateHitbox();
			rankBox.alpha = 0;

			add(accTxt = new FlxText(rankBox.x + 50, rankBox.y + 35, 0, '${Util.truncateFloat(PlayState.self.accuracy, 2)}%'));
			accTxt.setFormat(Paths.font("Rockford-NTLG Medium Italic.ttf"), 42, 0xFFFFFFFF, RIGHT);
			accTxt.offset.y = 30;
			accTxt.alpha = 0;

			final rank = Ranking.getFromAccuracy(PlayState.self.accuracy);
			add(ranking = new FlxText(rankBox.x + rankBox.width * 0.835, rankBox.y + rankBox.height - 1, 0, rank.name));
			ranking.setFormat(Paths.font("menus/bozonBI.otf"), 224, rank.color, RIGHT);
			ranking.clipGraphic(0, 0, ranking.width, ranking.height * 0.75);
			ranking.updateHitbox();
			ranking.offset.x = -30;
			ranking.x -= ranking.width;
			ranking.y -= ranking.height;
			ranking.alpha = 0;

			add(scoreBox = new FunkinSprite(rankBox.x + (rankBox.width - 36) + 14.5, rankBox.y, Paths.image("menus/Results/scoreBox")));
			scoreBox.scale.scale(0.5);
			scoreBox.updateHitbox();
			scoreBox.alpha = 0;

			add(judgeNames = new FlxTypedGroup<FlxText>());
			add(judgeCounts = new FlxTypedGroup<FlxText>());

			var curJudgeY:Array<Float> = [];
			var judgeX = scoreBox.x + 190;
			var judgeY = scoreBox.y + 25;
			inline function makeJudgeCount(name, color) {
				lerpJudges.push(0);
				curJudgeY.push(judgeY);
				
				var name = new FlxText(judgeX, judgeY, 0, _t(name));
				name.setFormat(Paths.font("Rockford-NTLG Light Italic.ttf"), 16, color, LEFT);
				name.offset.y = 30;
				name.alpha = 0;
				judgeNames.add(name);

				var count = new FlxText(judgeX, judgeY, 170, "0");
				count.setFormat(Paths.font("Rockford-NTLG Light Italic.ttf"), 16, color, RIGHT);
				count.offset.y = 30;
				count.alpha = 0;
				judgeCounts.add(count);
			}

			for (judge in Judgement.list) {
				makeJudgeCount(judge.name, judge.color);

				judgeX -= 36 * (20 / (scoreBox.height - 14));
				judgeY += 20;
			}
			makeJudgeCount("miss", 0xFF800000);

			add(scoreTxt = new FlxText(scoreBox.x + 40 + 290, scoreBox.y + scoreBox.height - 15, 0, Util.moneyString(0)));
			scoreTxt.setFormat(Paths.font("Rockford-NTLG Medium Italic.ttf"), 60, 0xFFFFFFFF, RIGHT);
			scoreTxt.x -= scoreTxt.width;
			scoreTxt.y -= scoreTxt.height * 0.75;
			scoreTxt.offset.y = 30;
			scoreTxt.alpha = 0;

			add(scoreInc = new FlxText(scoreTxt.x + scoreTxt.width, scoreTxt.y, 0, Util.moneyString(Math.abs(PlayState.self.score - lastPlay.score))));
			scoreInc.setFormat(Paths.font("Rockford-NTLG Medium Italic.ttf"), 24, 0xFFFFFFFF, RIGHT);
			scoreInc.y -= scoreInc.height * 0.75;
			scoreInc.visible = false;
			scoreInc.offset.x = -30;
			scoreInc.alpha = 0;

			if (lastPlay.score < PlayState.self.score) {
				var bestTxt = _t("new_best");
				scoreInc.text = bestTxt + "     +" + scoreInc.text;
				var bestFormat = new FlxTextFormat(0xFFFFC547);
				var numFormat = new FlxTextFormat(0xFF0CB81B);
				scoreInc.addFormat(bestFormat, 0, bestTxt.length + 1);
				scoreInc.addFormat(numFormat, bestTxt.length + 1, scoreInc.text.length);
			} else {
				scoreInc.text = "-" + scoreInc.text;
				scoreInc.color = 0xFFB70C0C;
			}
			scoreInc.x -= scoreInc.width;

			final timeY = rankBox.y + rankBox.height + 6;
			add(timeBox = new FunkinSprite(jacket.x + jacket.width - 45, timeY, Paths.image("menus/Results/timingBox")));
			timeBox.scale.scale(0.5);
			timeBox.updateHitbox();

			final cacheGPU = Settings.data.gpuCache;
			Settings.data.gpuCache = false; // need this off cuz imma be fucking with bitmaps a bit
			timeDot = Paths.image("menus/Results/dot");
			Settings.data.gpuCache = cacheGPU;

			add(timeSpr = new FunkinSprite(timeBox.x + 45, timeBox.y + 35));
			timeSpr.makeGraphic(Std.int(timeBox.width - 90) + timeDot.width, Std.int(timeBox.height - 65) + timeDot.height, 0x00000000);
			timeSpr.offset.set(timeDot.width * 0.5, timeDot.height * 0.5);

			add(animatedTimeDots = new FlxTypedGroup<FunkinSprite>());

			var idx = 0;
			var skewAmt = (36 - 17.5); // idk why half the y padding but ok.
			var highestTiming = Judgement.max.timing;

			add(earlyTxt = new FlxText(timeSpr.x + (timeSpr.width - skewAmt), timeSpr.y + (timeSpr.height - timeDot.height) + 3, 0, _t("early").toUpperCase()));
			earlyTxt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 16, 0xFFFFFFFF, RIGHT);
			earlyTxt.x -= earlyTxt.width * 0.75;
			
			add(lateTxt = new FlxText(timeSpr.x + timeSpr.width, timeSpr.y + 5, 0, _t("late").toUpperCase()));
			lateTxt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 16, 0xFFFFFFFF, RIGHT);
			lateTxt.x -= lateTxt.width * 0.45;
			lateTxt.y -= lateTxt.height;

			add(msTxt = new FlxText(timeSpr.x, timeSpr.y + (timeSpr.height - timeDot.height) + 3, 0, 'AVG: ${avgMs}ms'));
			msTxt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 16, 0xFFFFFFFF, LEFT);

			var bgFadeTwn = FlxTween.num(0, 1, 0.75, {startDelay: jacketTwn.startDelay, ease: FlxEase.cubeOut}, function(num) {
				rankBox.y = scoreBox.y = 75 + 30 * num;
				rankBox.alpha = scoreBox.alpha = num;

				timeBox.y = timeY + 30 * (1 - num);
				msTxt.y = earlyTxt.y = timeBox.y + (timeSpr.y - timeY) + (timeSpr.height - timeDot.height) + 3;
				lateTxt.y = timeBox.y + (timeSpr.y - timeY) + 5 - lateTxt.height;
				timeBox.alpha = earlyTxt.alpha = lateTxt.alpha = num;

				for (i in 0...curJudgeY.length)
					judgeNames.members[i].y = judgeCounts.members[i].y = scoreBox.y + (curJudgeY[i] - scoreBox.y);
				scoreTxt.y = scoreBox.y + scoreBox.height - 15 - scoreTxt.height * 0.75;
				scoreInc.y = scoreTxt.y - scoreInc.height * 0.75;
			});

			var rankTwn = FlxTween.tween(accTxt, {"offset.y": 0, "alpha": 1}, 0.5, {startDelay: bgFadeTwn.startDelay + bgFadeTwn.duration * 0.75, ease: FlxEase.cubeOut});
			FlxTween.tween(ranking, {"offset.x": 0, "alpha": 1}, 0.5, {startDelay: rankTwn.startDelay + 0.15, ease: FlxEase.cubeOut});

			final halfDiv = 0.5 / judgeNames.length;
			var judgeTwn = FlxTween.num(0, 0.5, 0.5, {startDelay: bgFadeTwn.startDelay + bgFadeTwn.duration * 0.75}, function(num) {
				for (i in 0...judgeNames.length) {
					final name = judgeNames.members[i];
					final count = judgeCounts.members[i];

					if (num < halfDiv * i || name.alpha >= 1.0) continue;

					name.alpha = count.alpha = FlxEase.cubeOut((num - halfDiv * i) / halfDiv);
					name.offset.y = count.offset.y = 30 * (1.0 - name.alpha);
				}
			});
			FlxTween.tween(scoreTxt, {"offset.y": 0, "alpha": 1}, 0.5, {startDelay: judgeTwn.startDelay + 0.3, ease: FlxEase.cubeOut});

			timeTween = FlxTween.num(0, songLength, 1.5, {startDelay: bgFadeTwn.startDelay + bgFadeTwn.duration * 0.75, ease: FlxEase.cubeOut}, function(num) {
				while (idx < PlayState.self.noteHitList.length && num >= PlayState.self.noteHitList[idx].time) {
					final hit = PlayState.self.noteHitList[idx];
					final xPercent = hit.time / songLength;
					final yPercent = 1 - (hit.diff + highestTiming) / (highestTiming * 2);
					final dot = animatedTimeDots.recycle(FunkinSprite, function() {
						return new FunkinSprite(0, 0, timeDot);
					});
					dot.setPosition(timeSpr.x + (timeSpr.width - timeDot.width - skewAmt) * xPercent + skewAmt * (1.0 - yPercent), timeSpr.y + (timeSpr.height - timeDot.height) * yPercent);
					dot.offset.x = 20;
					dot.alpha = 0;
					dot.color = hit.color;
					++idx;
				}
			});
		} else {
			var notelessBox = new FunkinSprite(635 + 30, 155, Paths.image("menus/Results/notelessBox"));
			notelessBox.scale.scale(0.5, 0.5);
			notelessBox.updateHitbox();
			add(notelessBox);
			notelessBox.alpha = 0;

			FlxTween.tween(notelessBox, {x: notelessBox.x - 30, alpha: 1}, 0.75, {startDelay: jacketTwn.startDelay, ease: FlxEase.cubeOut});
		}

		borderTop = new Border(true, "", "Results");
		borderBot = new Border(false);
		
		var logoIdx = borderBot.members.indexOf(borderBot.camelliaLogo);
		borderBot.insert(logoIdx, modIcons = new FlxSpriteGroup(0, borderBot.border.y + 58));
		var x = borderBot.border.x + 40;
		for (i=>mod in modifiers) {
			if (!mod.condition()) continue;
			x = mod.make(x, modIcons);
		}
		scrollStart = x > FlxG.width - 300 ? Math.max(FlxG.width, x + 150) : 0;
		modIcons.y += 15;
		modIcons.alpha = 0;

		borderBot.insert(logoIdx + 1, modFade = new FunkinSprite(FlxG.width, FlxG.height, Paths.image("menus/MainMenu/textFade")));
		modFade.x -= modFade.width;
		modFade.y -= modFade.height;
		
		FlxTween.tween(modIcons, {y: modIcons.y - 15, alpha: 1}, 0.5, {ease: FlxEase.quintOut});

		continueBG = new FunkinSprite(0, FlxG.height + borderBot.border.height);
		continueBG.makeGraphic(1, 1, 0xFFFFFFFF);
		continueBG.origin.set(0, 1);
		continueBG.scale.set(FlxG.width, borderBot.border.height);
		add(continueBG);

		// adoption
		borderTop.remove(borderTop.scrollTitle, true);
		add(borderTop.scrollTitle);
		borderTop.scrollTitle.color = 0xFF000000;
		borderTop.scrollTitle.alpha = 0.15;
		borderTop.scrollText = "PRESS ENTER TO CONTINUE • ";
		borderTop.scrollTitle.y = continueBG.y - continueBG.scale.y;

		add(borderTop);
		add(borderBot);

		borderTop.y -= borderTop.border.height;
		borderBot.y += borderBot.border.height;
		FlxTween.tween(borderTop, {y: borderTop.y + borderTop.border.height}, 0.75, {ease: FlxEase.cubeOut});
		FlxTween.tween(borderBot, {y: borderBot.y - borderBot.border.height}, 0.75, {ease: FlxEase.cubeOut});
		FlxTween.tween(continueBG, {y: continueBG.y - borderBot.border.height}, 0.75, {ease: FlxEase.cubeOut});
		FlxTween.tween(borderTop.scrollTitle, {y: borderTop.scrollTitle.y - borderBot.border.height}, 0.75, {ease: FlxEase.cubeOut});

		funkin.states.PlayState.self.paused = true;
		
		Conductor.inst = FlxAudioHandler.loadAudio(Paths.audioPath("results", "music"), true, 0.5, true);
		Conductor.inst.loopTime = 1540;
		Conductor.inst.pitch = 1; //just in case
		Conductor.inst.play();
		//also another feature i'll add later is to play a special music + show something special if your acc
		//is above 90% or maybe if you a new record, we will see...
		//and prob add an emblem for each modifier that is enabled in the song
	}

	override function update(delta:Float){
		super.update(delta);

		if (scrollStart > 0) {
			for (icon in modIcons.members) {
				icon.x -= delta * 30;
				if (icon.x + icon.width < 0)
					icon.x += scrollStart;
			}
		}

		if (!Settings.data.reducedQuality)
			lineShader.time.value[0] = lineShader.time.value[0] + (delta / 64);

		if (!accepted && (Controls.justPressed('accept') || FlxG.mouse.justPressed)) {
			accepted = true;
			Conductor.stop();
			FlxG.sound.play(Paths.audio("menu_confirm", "sfx"));

			FlxTween.tween(modIcons, {y: modIcons.y + 15, alpha: 0}, 0.25, {ease: FlxEase.quintOut});
			if (Settings.data.flashingLights) {
				FlxTween.tween(continueBG.scale, {y: FlxG.height + borderBot.border.height}, 0.25, {ease: FlxEase.quartOut}); // add border height incase the twn didnt finish
				FlxTween.color(continueBG, 1, 0xFFFFFFFF, 0xFF000000, {ease: FlxEase.cubeOut});
			} else {
				var rouxls = new FunkinSprite(FlxG.width * 0.5 - 1, 0);
				rouxls.makeGraphic(1, 1, 0xFFFFFFFF);
				rouxls.scale.set(2, FlxG.height);
				rouxls.updateHitbox();
				insert(members.indexOf(borderTop), rouxls);
		
				FlxTween.tween(rouxls.scale, {x: FlxG.width}, 0.25, {ease: FlxEase.quartOut});
				FlxTween.color(rouxls, 1, Settings.data.flashingLights ? 0xFFFFFFFF : 0xFF282828, 0xFF000000, {ease: FlxEase.cubeOut});
			}

			var ogMiniY = borderTop.miniText.y;
			var ogOffsetY = borderBot.camelliaLogo.offset.y;
			FlxTween.tween(borderBot, {y: -FlxG.height}, 0.75, {ease: FlxEase.cubeIn, startDelay: 0.25, onUpdate: function(twn) {
				final height = FlxG.height * twn.scale;
				borderBot.border.clipGraphic(0, 0, borderBot.border.graphic.width, borderBot.border.graphic.height + height);
				borderTop.border.clipGraphic(0, -height, borderTop.border.graphic.width, borderTop.border.graphic.height + height);
				borderTop.miniText.y = ogMiniY + height;

				if (borderTop.border.frameHeight - 40 < borderBot.camelliaLogo.y + borderBot.camelliaLogo.height - 5) {
					final y = Math.max((borderTop.border.frameHeight - 40) - borderBot.camelliaLogo.y, 0);
					borderBot.camelliaLogo.clipGraphic(0, y, borderBot.camelliaLogo.graphic.width, borderBot.camelliaLogo.graphic.height - y);
					borderBot.camelliaLogo.offset.y = ogOffsetY - y;
				} else 
					borderBot.camelliaLogo.visible = false;
			}, onComplete: function(twn) {
				if (timeTween != null)
					timeTween.cancel();

				new FlxTimer().start(0.25, function(tmr) {
					if (!PlayState.self.proceed()) return; // next song! we may still need some assets!

					for (mem in members) {
						if (mem == null || !mem.exists || !mem.alive) continue;
						mem.visible = mem == borderTop || mem == borderBot;
					}
					for (mem in borderTop.members) {
						if (mem == null || !mem.exists || !mem.alive) continue;
						mem.visible = mem == borderTop.border;
					}
					for (mem in borderBot.members) {
						if (mem == null || !mem.exists || !mem.alive) continue;
						mem.visible = mem == borderBot.border;
					}
					for (mem in PlayState.self.members) {
						if (mem == null || !mem.exists || !mem.alive) continue;
						mem.visible = false;
					}

					var jacketPath:String = 'jackets/${PlayState.songID}.png';
					if (!Paths.exists('images/$jacketPath')) jacketPath = 'jackets/default.png';

					Paths.clearExcept([
						Paths.getCacheKey('menus/border.png', 'IMG', 'images'),
						Paths.getCacheKey('menus/borderTop.png', 'IMG', 'images'),
						Paths.getCacheKey(jacketPath, 'IMG', 'images')
					]);
				});
			}});
		}

		if (PlayState.self.notesPlayed <= 0) return;

		lerpScore = FlxMath.lerp(lerpScore, PlayState.self.score, delta * 12.5 * scoreTxt.alpha);
		var queueScore = Math.round(lerpScore);
		if (roundScore != queueScore) {
			roundScore = queueScore;
			scoreTxt.text = Util.moneyString(Math.round(roundScore));
			scoreTxt.x = scoreBox.x + 40 + 290 - scoreTxt.width;

			if (roundScore >= PlayState.self.score - 10 && !scoreInc.visible) {
				scoreInc.visible = true;
				FlxTween.tween(scoreInc, {"offset.x": 0, "alpha": 1}, 0.75, {ease: FlxEase.cubeOut});
			}
		}

		for (i in 0...lerpJudges.length) {
			lerpJudges[i] = FlxMath.lerp(lerpJudges[i], (i == lerpJudges.length - 1) ? (PlayState.self.comboBreaks - Judgement.max.hits) : Judgement.list[i].hits, delta * 7.5 * judgeCounts.members[i].alpha);
			judgeCounts.members[i].text = Std.string(Math.round(lerpJudges[i]));
		}

		for (dot in animatedTimeDots.members) {
			if (!dot.alive) continue;
			
			dot.alpha = FlxMath.lerp(dot.alpha, 1, delta * 5 * timeBox.alpha);
			dot.offset.x = 20 * (1.0 - dot.alpha);
			if (dot.alpha > 0.99) {
				timeSpr.stamp(dot, Math.round(dot.x - (timeSpr.x - timeSpr.offset.x)), Math.round(dot.y - (timeSpr.y - timeSpr.offset.y)));
				dot.kill();
			}
		}
	}
}