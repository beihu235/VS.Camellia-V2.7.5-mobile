package funkin.states;

import funkin.objects.ui.SwirlBG;
import funkin.objects.ui.Border;
import funkin.shaders.TileLine;
import flixel.graphics.FlxGraphic;
import haxe.io.Path;

using StringTools;

class AwardsState extends FunkinState {
	static var curSelected:Int = 0;
	static var curTopRow:Int = 0;
	var curViewRow:Float = 0;

	var selBorder:FunkinSprite;
	var images:FlxTypedSpriteGroup<FunkinSprite>;
	var locks:FlxTypedSpriteGroup<FunkinSprite>;

	var borderTwn:FlxTween;
	var displayBG:FunkinSprite;
	var awardIcon:FunkinSprite;
	var nameBG:FunkinSprite;
	var nameTxt:FlxText;
	var descTxt:FlxText;

	var progPercent:Float = 0;
	var progFill:FunkinSprite;
	var progEmpty:FunkinSprite;
	var progTxt:FlxText;

	var totalTitleBG:FunkinSprite;
	var totalTitle:FlxText;
	var totalBG:FunkinSprite;
	var totalFill:FunkinSprite;
	var totalEmpty:FunkinSprite;
	var totalTxt:FlxText;

    var bg:SwirlBG;
	var lineShader:TileLine;

	var borderTop:Border;
	//var borderBot:Border;
	
	override function create():Void {
		super.create();
		curViewRow = curTopRow;

		add(bg = new SwirlBG(0xFF935825, 0xFFFFC800));

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

		//var grayscale = new funkin.shaders.Grayscale();
		add(images = new FlxTypedSpriteGroup(720, 160));
		add(locks = new FlxTypedSpriteGroup(720, 160));
		for (i in 0...Awards.list.length) {
			var spr = new FunkinSprite(140 * (i % 4), 140 * Math.floor(i / 4), tryIcon(Awards.list[i].icon));
			var targetWidth = (spr.frameWidth > spr.frameHeight) ? spr.frameWidth * (spr.frameHeight / spr.frameWidth) : spr.frameWidth;
			var targetHeight = (spr.frameHeight > spr.frameWidth) ? spr.frameHeight * (spr.frameWidth / spr.frameHeight) : spr.frameHeight;
			spr.clipGraphic((spr.frameWidth - targetWidth) * 0.5, (spr.frameHeight - targetHeight) * 0.5, targetWidth, targetHeight);
			spr.setGraphicSize(125);
			spr.updateHitbox();
			spr.alpha = i == curSelected ? 1.0 : 0.7;
			//spr.shader = Awards.isUnlocked(Awards.list[i].id) ? null : grayscale;
			
			if (!Awards.isUnlocked(Awards.list[i].id)) {
				var lock = new FunkinSprite(spr.x + spr.width * 0.5, spr.y + spr.height * 0.5, Paths.image("menus/Awards/lock"));
				lock.scale.set(0.75, 0.75);
				lock.updateHitbox();
				lock.x -= lock.width * 0.5;
				lock.y -= lock.height * 0.5;
				locks.add(lock);
			}
			images.add(spr);
		}

		curSelected = Std.int(FlxMath.bound(curSelected, 0, Awards.list.length - 1));
		final curAward = Awards.list[curSelected];

		var curSpr = images.members[curSelected];
		add(selBorder = new FunkinSprite(curSpr.x + curSpr.width * 0.5, curSpr.y + curSpr.height * 0.5, Paths.image("menus/Gallery/selBorder")));
		selBorder.x -= selBorder.width * 0.5;
		selBorder.y -= selBorder.height * 0.5;

		add(displayBG = new FunkinSprite(25, 250));
		displayBG.makeGraphic(1, 1, 0xFF000000);
		displayBG.scale.set(640, 180);
		displayBG.updateHitbox();
		displayBG.offset.set();
		displayBG.origin.set();
		displayBG.alpha = 0.5;

		add(awardIcon = new FunkinSprite(displayBG.x + 25, displayBG.y + 40, tryIcon(curAward.icon)));
		awardIcon.shader = images.members[curSelected].shader;
		awardIcon.setGraphicSize(-1, displayBG.height - 50);
		awardIcon.updateHitbox();

		add(descTxt = new FlxText(awardIcon.x + awardIcon.width + 10, awardIcon.y + 5, 0, curAward.description));
		descTxt.fieldWidth = displayBG.width - (descTxt.x - displayBG.x) - 10;
		descTxt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 24, 0xFFFFFFFF, LEFT);

		add(progEmpty = new FunkinSprite(descTxt.x, displayBG.y + displayBG.height - 35));
		progEmpty.makeGraphic(1, 1, 0xFF808080);
		progEmpty.scale.set(descTxt.fieldWidth, 25);
		progEmpty.origin.set();

		add(progFill = new FunkinSprite(progEmpty.x, progEmpty.y));
		progFill.makeGraphic(1, 1, 0xFFFFFFFF);
		progFill.scale.set(0, 25);
		progFill.origin.set();

		add(progTxt = new FlxText(progFill.x + 5, progFill.y + progFill.scale.y * 0.5, 0, "DONE!"));
		if (!Awards.isUnlocked(curAward.id))
			progTxt.text = curAward.maxScore <= 0 ? "PENDING..." : Awards.getScore(curAward.id) + "/" + curAward.maxScore;
		progTxt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 16, 0xFF000000, LEFT);
		progTxt.y -= progTxt.height * 0.5;
		
		if (Awards.list[curSelected].maxScore <= 0)
			progPercent = Awards.isUnlocked(Awards.list[curSelected].id) ? 1 : 0;
		else
			progPercent = Awards.getScore(Awards.list[curSelected].id) / Awards.list[curSelected].maxScore;
		
		add(nameBG = new FunkinSprite(displayBG.x + 15, displayBG.y - 20));
		nameBG.makeGraphic(1, 1, 0xFFFFFFFF);
		nameBG.scale.set(0, 50);
		nameBG.origin.set();
		
		add(nameTxt = new FlxText(nameBG.x + 20, nameBG.y + nameBG.scale.y * 0.5, 0, Awards.list[curSelected].name.toUpperCase()));
		nameTxt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 24, 0xFF000000, LEFT);
		nameTxt.y -= nameTxt.height * 0.5;

		add(totalBG = new FunkinSprite(displayBG.x, displayBG.y + displayBG.height + 50));
		totalBG.makeGraphic(1, 1, 0x80000000);
		totalBG.scale.set(displayBG.width, 90);
		totalBG.updateHitbox();

		add(totalEmpty = new FunkinSprite(totalBG.x + 10, totalBG.y + totalBG.height - 45));
		totalEmpty.makeGraphic(1, 1, 0xFF808080);
		totalEmpty.scale.set(totalBG.width - 20, 35);
		totalEmpty.origin.set();

		add(totalFill = new FunkinSprite(totalEmpty.x, totalEmpty.y));
		totalFill.makeGraphic(1, 1, 0xFFFFFFFF);
		totalFill.scale.set(0, 35);
		totalFill.origin.set();

		// manual check instead of _unlocked.length incase stragglers remain.
		var awardsUnlocked = 0;
		for (award in Awards.list) {
			if (Awards.isUnlocked(award.id))
				++awardsUnlocked;
		}
		totalFill.scale.x = totalEmpty.scale.x * (awardsUnlocked / Awards.list.length);

		add(totalTxt = new FlxText(totalFill.x + 5, totalFill.y + totalFill.scale.y * 0.5, 0, "100%!"));
		if (awardsUnlocked < Awards.list.length)
			totalTxt.text = '$awardsUnlocked/${Awards.list.length} (${Math.round(awardsUnlocked / Awards.list.length * 100)}%)';
		totalTxt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 20, 0xFF000000, LEFT);
		totalTxt.x = Math.max(totalFill.x + totalFill.scale.x - totalTxt.width - 5, totalFill.x + 5);
		totalTxt.y -= totalTxt.height * 0.5;

		add(totalTitleBG = new FunkinSprite(totalBG.x + 15, totalBG.y - 20));
		totalTitleBG.makeGraphic(1, 1, 0xFFFFFFFF);
		totalTitleBG.scale.set(0, 50);
		totalTitleBG.origin.set();

		add(totalTitle = new FlxText(totalTitleBG.x + 20, totalTitleBG.y + totalTitleBG.scale.y * 0.5, 0, _t("awards_total")));
		totalTitle.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 24, 0xFF000000, LEFT);
		totalTitle.y -= totalTitle.height * 0.5;
		totalTitleBG.scale.x = totalTitle.width + 40;

		add(borderTop = new Border(true, "EMBRACE YOUR ACHIEVEMENTS • ", "Awards"));
		//add(borderBot = new Border(false));

		borderTop.transitionTween(true);
	}

	function tryIcon(icon:String) {
		return Paths.exists('images/menus/Awards/$icon.png') ? Paths.image('menus/Awards/$icon') : Paths.image("menus/Awards/BACKUP_ICON");
	}

	function changeSelection(inc:Int, ?horizontal:Bool = false) {
		images.members[curSelected].alpha = 0.7;
		if (horizontal) {
			final rowStart = Math.floor(curSelected / 4) * 4;
			final rowLen = Std.int(Math.min(Awards.list.length - rowStart, 4));
			curSelected = ((curSelected - rowStart) + inc + rowLen) % rowLen + rowStart;
		} else {
			final rows = Math.ceil(Awards.list.length / 4) * 4;
			curSelected = (curSelected + inc + rows) % rows;
			final row = Math.floor(curSelected / 4);
			final rowStart = row * 4;
			final rowLen = Std.int(Math.min(Awards.list.length - rowStart, 4));
			curSelected = Std.int(FlxMath.bound(curSelected, rowStart, rowStart + (rowLen - 1)));

			if (row < curTopRow)
				curTopRow = row;
			else if (row >= curTopRow + 3)
				curTopRow = Std.int(Math.min(row - 2, Math.floor((Awards.list.length - 1) / 4)));
		}
		curViewRow = curTopRow;
		images.members[curSelected].alpha = 1.0;
		selBorder.alpha = 0.0;
		selBorder.scale.set(1.15, 1.15);

		awardIcon.shader = images.members[curSelected].shader;
		awardIcon.loadGraphic(tryIcon(Awards.list[curSelected].icon));
		awardIcon.setGraphicSize(-1, displayBG.height - 50);
		awardIcon.updateHitbox();

		nameTxt.text = Awards.list[curSelected].name.toUpperCase();
		descTxt.text = Awards.list[curSelected].description;

		if (Awards.list[curSelected].maxScore <= 0)
			progPercent = Awards.isUnlocked(Awards.list[curSelected].id) ? 1 : 0;
		else
			progPercent = Awards.getScore(Awards.list[curSelected].id) / Awards.list[curSelected].maxScore;

		if (!Awards.isUnlocked(Awards.list[curSelected].id))
			progTxt.text = Awards.list[curSelected].maxScore <= 0 ? "PENDING..." : Awards.getScore(Awards.list[curSelected].id) + "/" + Awards.list[curSelected].maxScore;
		else 
			progTxt.text = "DONE!";

		FlxG.sound.play(Paths.audio("menu_move", "sfx"));
	}

	override function update(delta:Float) {
		super.update(delta);

		if (!Settings.data.reducedQuality)
			lineShader.time.value[0] = SwirlBG.time / 64;

		progFill.scale.x = FlxMath.lerp(progFill.scale.x, progEmpty.scale.x * progPercent, delta * 15);
		progTxt.x = FlxMath.lerp(progTxt.x, Math.max(progFill.x + progFill.scale.x - progTxt.width - 5, progFill.x + 5), delta * 20);
		images.y = FlxMath.lerp(images.y, 160 - curViewRow * 140, delta * 20);
		locks.y = images.y;
		nameBG.scale.x = FlxMath.lerp(nameBG.scale.x, nameTxt.width + 40, delta * 20);
		selBorder.alpha = FlxMath.lerp(selBorder.alpha, 1, delta * 10);
		selBorder.scale.x = selBorder.scale.y = 1.15 - 0.15 * selBorder.alpha;
		
		final rowCount = Math.floor((Awards.list.length - 1) / 4) - 2;
		if (FlxG.mouse.wheel != 0)
			curViewRow -= FlxG.mouse.wheel * 0.25;
		if (curViewRow < 0 || curViewRow > rowCount)
			curViewRow = FlxMath.lerp(curViewRow, curViewRow < 0 ? 0 : rowCount, delta * 10);

		if (curSelected < 0) return;
		selBorder.setPosition(images.members[curSelected].x + (images.members[curSelected].width - selBorder.width) * 0.5, images.members[curSelected].y + (images.members[curSelected].height - selBorder.height) * 0.5);

		final leftJustPressed = Controls.justPressed("ui_left");
		final downJustPressed = Controls.justPressed("ui_down");
		if (leftJustPressed || Controls.justPressed("ui_right"))
			changeSelection(leftJustPressed ? -1 : 1, true);
		else if (downJustPressed || Controls.justPressed("ui_up"))
			changeSelection(downJustPressed ? 4 : -4);

		for (i => spr in images.members) {
			if (i == curSelected) continue;

			if (FlxG.mouse.x >= spr.x && FlxG.mouse.x <= spr.x + spr.width && FlxG.mouse.y >= spr.y && FlxG.mouse.y <= spr.y + spr.height) {
				spr.alpha = 1;
				if (FlxG.mouse.justPressed)
					changeSelection(i - curSelected);
			} else
				spr.alpha = 0.7;
		}

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			final cacheSel = curSelected;
			curSelected = -1;
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
			borderTop.transitionTween(false, 0, 0.25, function() {
				curSelected = cacheSel;
				FlxG.switchState(new ExtrasState());
			});
		}
	}
}