package funkin.states;

import funkin.objects.ui.SwirlBG;
import funkin.objects.ui.Border;
import funkin.shaders.TileLine;
import flixel.graphics.FlxGraphic;
import haxe.io.Path;
import funkin.objects.FadingSprite;

using StringTools;

class GalleryItem {
	public var imgSlot:FlxGraphic;
	public var img:String;
	public var artist:String;
	public var link:String;
	public var desc:String;

	public function new(path:String) {
		img = 'menus/Gallery/${path}';
		imgSlot = Paths.image('menus/Gallery/${path}-slot');

		var txt = Paths.getFileContent('images/menus/Gallery/${path}INFO.txt').replace("\r", "");
		var artistEnd = txt.indexOf("\n");
		var linkEnd = txt.indexOf("\n", artistEnd + 1);
		artist = txt.substring(0, artistEnd);
		link = txt.substring(artistEnd + 1, linkEnd);
		desc = txt.substring(linkEnd + 1, txt.length);
	}
}

class GalleryState extends FunkinState {
	static var curSelected:Int = 0;
	static var curTopRow:Int = 0;
	var curViewRow:Float = 0;
	var list:Array<GalleryItem> = [];

	var selBorder:FunkinSprite;
	var images:FlxTypedSpriteGroup<FunkinSprite>;

	var fullscreen:Bool = false;
	var fullscreenPercent(default, set):Float = 0;
	var fullscreenTwn:FlxTween;
	var borderPercent:Float = 0;
	var borderTwn:FlxTween;
	var displayBG:FunkinSprite;
	var bigDisplay:FadingSprite;
	var smallScale:Float = 1.0;
	var bigScale:Float = 1.0;
	var refRatio:Float = 625 / 330;
	var refBigRatio:Float = FlxG.width / FlxG.height;
	var hoveringSocial:Bool = false;
	var ogArtistWidth:Float = 0;
	var artistBG:FunkinSprite;
	var artistTxt:FlxText;

	var descBG:FunkinSprite;
	var descTxt:FlxText;

    var bg:SwirlBG;
	var lineShader:TileLine;

	var borderTop:Border;
	var borderBot:Border;
	
	override function create():Void {
		super.create();
		curViewRow = curTopRow;

		add(bg = new SwirlBG(0xFF7D1E57, 0xFFC53C9C));

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

		for (file in Paths.readDirectory("images/menus/Gallery")) {
			var firstChar = file.charCodeAt(0);
			var lastChar = file.charCodeAt(file.length-5);
			if (firstChar < '0'.code || firstChar > '9'.code || Path.extension(file) != "png" || lastChar == 116) continue;
			list.push(new GalleryItem(Path.withoutExtension(file)));
		}

		add(images = new FlxTypedSpriteGroup(720, 160));
		for (i in 0...list.length) {
			var spr = new FunkinSprite(135 * (i % 4), 135 * Math.floor(i / 4), list[i].imgSlot);
			if (spr.graphic == null)
				spr.visible = false; // Avoid crash for missing graphic iku iku iku >w<
			var targetWidth = (spr.frameWidth > spr.frameHeight) ? spr.frameWidth * (spr.frameHeight / spr.frameWidth) : spr.frameWidth;
			var targetHeight = (spr.frameHeight > spr.frameWidth) ? spr.frameHeight * (spr.frameWidth / spr.frameHeight) : spr.frameHeight;
			//spr.clipGraphic((spr.frameWidth - targetWidth) * 0.5, (spr.frameHeight - targetHeight) * 0.5, targetWidth, targetHeight);
			spr.setGraphicSize(125,125);
			spr.updateHitbox();
			spr.alpha = i == curSelected ? 1.0 : 0.7;
			images.add(spr);
		}

		curSelected = Std.int(FlxMath.bound(curSelected, 0, list.length - 1));

		var curSpr = images.members[curSelected];
		add(selBorder = new FunkinSprite(curSpr.x + curSpr.width * 0.5, curSpr.y + curSpr.height * 0.5, Paths.image("menus/Gallery/selBorder")));
		selBorder.x -= selBorder.width * 0.5;
		selBorder.y -= selBorder.height * 0.5;

		add(displayBG = new FunkinSprite(23, 128));
		displayBG.makeGraphic(1, 1, 0xFF000000);
		displayBG.scale.set(639, 344);
		displayBG.updateHitbox();
		displayBG.offset.set();
		displayBG.origin.set();
		displayBG.alpha = 0.5;

		add(bigDisplay = new FadingSprite(displayBG.x + displayBG.width * 0.5, displayBG.y + displayBG.height * 0.5));
		bigDisplay.changeTo(list[curSelected].img, true, ()->{
			bigDisplay.nextSprite.offset.set(bigDisplay.nextSprite.frameWidth * 0.5, bigDisplay.nextSprite.frameHeight * 0.5);
			smallScale = (bigDisplay.nextSprite.frameWidth / bigDisplay.nextSprite.frameHeight > refRatio) ? 625 / bigDisplay.nextSprite.frameWidth : 330 / bigDisplay.nextSprite.frameHeight;
			bigScale = (bigDisplay.nextSprite.frameWidth / bigDisplay.nextSprite.frameHeight > refBigRatio) ? FlxG.width / bigDisplay.nextSprite.frameWidth : FlxG.height / bigDisplay.nextSprite.frameHeight;
			bigDisplay.nextSprite.scale.set(smallScale, smallScale);
		},()->{
			bigDisplay.curSprite.offset.set(bigDisplay.nextSprite.frameWidth * 0.5, bigDisplay.nextSprite.frameHeight * 0.5);
			bigDisplay.curSprite.scale.set(smallScale, smallScale);
		});

		add(artistBG = new FunkinSprite(displayBG.x + 15, displayBG.y - 20));
		artistBG.makeGraphic(1, 1, 0xFFFFFFFF);
		artistBG.scale.set(0, 50);
		artistBG.origin.set();

		add(artistTxt = new FlxText(artistBG.x + 20, artistBG.y + artistBG.scale.y * 0.5, 0, list[curSelected].artist.toUpperCase()));
		artistTxt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 24, 0xFF000000, LEFT);
		artistTxt.y -= artistTxt.height * 0.5;
		ogArtistWidth = artistTxt.width;

		add(descBG = new FunkinSprite(displayBG.x, displayBG.y + displayBG.height + 10));
		descBG.makeGraphic(1, 1, 0x80000000);
		descBG.scale.set(displayBG.width, 175);
		descBG.updateHitbox();

		add(descTxt = new FlxText(descBG.x + 20, descBG.y + 20, descBG.width - 40, list[curSelected].desc));
		descTxt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 24, 0xFFFFFFFF, LEFT);

		add(borderTop = new Border(true, "BROWSE THE IMAGES • ", "Gallery"));
		add(borderBot = new Border(false));

		final buttonY = borderBot.border.y + 58; // unfortunately 58 is the only number that centers it.
		var spaceButton = new FunkinSprite(borderBot.x + 40, buttonY, Paths.image('menus/spaceKey'));
		spaceButton.scrollFactor.set(0, 1);
		borderBot.add(spaceButton);

		var spaceTxt = new FlxText(spaceButton.x + spaceButton.width * 0.5, spaceButton.y + spaceButton.height * 0.5, 0, "SPACE");
		spaceTxt.setFormat(Paths.font('LineSeed.ttf'), 16, 0xFF000000, LEFT);
		spaceTxt.x -= spaceTxt.width * 0.5;
		spaceTxt.y -= spaceTxt.height * 0.5;
		spaceTxt.scrollFactor.set(0, 1);
		borderBot.add(spaceTxt);

		var socialTxt = new FlxText((spaceButton.x + spaceButton.width) + 5, spaceButton.y, 0, 'OPEN SOCIAL', 16);
		socialTxt.font = Paths.font('LineSeed.ttf');
		socialTxt.scrollFactor.set(0, 1);
		borderBot.add(socialTxt);

		var enterButton = new FunkinSprite(socialTxt.x + socialTxt.width + 30, buttonY, Paths.image('menus/enterKey'));
		enterButton.scrollFactor.set(0, 1);
		borderBot.add(enterButton);

		var fullscreenTxt = new FlxText((enterButton.x + enterButton.width) + 5, enterButton.y, 0, 'FULL SCREEN', 16);
		fullscreenTxt.font = Paths.font('LineSeed.ttf');
		fullscreenTxt.scrollFactor.set(0, 1);
		borderBot.add(fullscreenTxt);

		borderTop.transitionTween(true);
	}

	function changeSelection(inc:Int, ?horizontal:Bool = false) {
		images.members[curSelected].alpha = 0.7;
		if (horizontal) {
			final rowStart = Math.floor(curSelected / 4) * 4;
			final rowLen = Std.int(Math.min(list.length - rowStart, 4));
			curSelected = ((curSelected - rowStart) + inc + rowLen) % rowLen + rowStart;
		} else {
			final rows = Math.ceil(list.length / 4) * 4;
			curSelected = (curSelected + inc + rows) % rows;
			final row = Math.floor(curSelected / 4);
			final rowStart = row * 4;
			final rowLen = Std.int(Math.min(list.length - rowStart, 4));
			curSelected = Std.int(FlxMath.bound(curSelected, rowStart, rowStart + (rowLen - 1)));

			if (row < curTopRow)
				curTopRow = row;
			else if (row >= curTopRow + 3)
				curTopRow = Std.int(Math.min(row - 2, Math.floor((list.length - 1) / 4)));
		}
		curViewRow = curTopRow;
		images.members[curSelected].alpha = 1.0;
		selBorder.alpha = 0.0;
		selBorder.scale.set(1.15, 1.15);

		bigDisplay.changeTo(list[curSelected].img, false, ()->{
			bigDisplay.nextSprite.offset.set(bigDisplay.nextSprite.frameWidth * 0.5, bigDisplay.nextSprite.frameHeight * 0.5);
			smallScale = (bigDisplay.nextSprite.frameWidth / bigDisplay.nextSprite.frameHeight > refRatio) ? 625 / bigDisplay.nextSprite.frameWidth : 330 / bigDisplay.nextSprite.frameHeight;
			bigScale = (bigDisplay.nextSprite.frameWidth / bigDisplay.nextSprite.frameHeight > refBigRatio) ? FlxG.width / bigDisplay.nextSprite.frameWidth : FlxG.height / bigDisplay.nextSprite.frameHeight;
			bigDisplay.nextSprite.scale.set(smallScale, smallScale);
		},()->{
			bigDisplay.curSprite.offset.set(bigDisplay.nextSprite.frameWidth * 0.5, bigDisplay.nextSprite.frameHeight * 0.5);
			bigDisplay.curSprite.scale.set(smallScale, smallScale);
		});

		artistTxt.text = list[curSelected].artist.toUpperCase();
		descTxt.text = list[curSelected].desc;
		ogArtistWidth = artistTxt.width;

		FlxG.sound.play(Paths.audio("menu_move", "sfx"));
	}

	override function update(delta:Float) {
		super.update(delta);

		if (!Settings.data.reducedQuality)
			lineShader.time.value[0] = SwirlBG.time / 64;

		images.y = FlxMath.lerp(images.y, 160 - curViewRow * 140, delta * 20);
		artistBG.scale.x = FlxMath.lerp(artistBG.scale.x, Math.max(artistTxt.width, ogArtistWidth) + 40, delta * 20);
		selBorder.alpha = FlxMath.lerp(selBorder.alpha, 1, delta * 10);
		selBorder.scale.x = selBorder.scale.y = 1.15 - 0.15 * selBorder.alpha;
		
		final rowCount = Math.floor((list.length - 1) / 4) - 2;
		if (FlxG.mouse.wheel != 0)
			curViewRow -= FlxG.mouse.wheel * 0.25;
		if (curViewRow < 0 || curViewRow > rowCount)
			curViewRow = FlxMath.lerp(curViewRow, curViewRow < 0 ? 0 : rowCount, delta * 10);

		if (curSelected < 0) return;
		selBorder.setPosition(images.members[curSelected].x + (images.members[curSelected].width - selBorder.width) * 0.5, images.members[curSelected].y + (images.members[curSelected].height - selBorder.height) * 0.5);

		final leftJustPressed = Controls.justPressed("ui_left");
		final downJustPressed = Controls.justPressed("ui_down");
		if (!fullscreen && (leftJustPressed || Controls.justPressed("ui_right")))
			changeSelection(leftJustPressed ? -1 : 1, true);
		else if (!fullscreen && (downJustPressed || Controls.justPressed("ui_up")))
			changeSelection(downJustPressed ? 4 : -4);

		for (i => spr in images.members) {
			if (fullscreen || i == curSelected) continue;

			if (FlxG.mouse.x >= spr.x && FlxG.mouse.x <= spr.x + spr.width && FlxG.mouse.y >= spr.y && FlxG.mouse.y <= spr.y + spr.height) {
				spr.alpha = 1;
				if (FlxG.mouse.justPressed)
					changeSelection(i - curSelected);
			} else
				spr.alpha = 0.7;
		}

		if (!fullscreen && (Controls.justPressed('back') || FlxG.mouse.justPressedRight)) {
			final cacheSel = curSelected;
			curSelected = -1;
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
			borderTop.transitionTween(false, 0, 0.25, function() {
				curSelected = cacheSel;
				FlxG.switchState(new ExtrasState());
			});
		}

		var hitFullscreen = FlxG.keys.justPressed.ENTER || (fullscreen && (Controls.justPressed('back') || FlxG.mouse.justReleased || FlxG.mouse.justPressedRight));
		if (!fullscreen && !hitFullscreen && FlxG.mouse.justReleased) {
			final halfWidth = bigDisplay.frameWidth * bigDisplay.scale.x * 0.5;
			final halfHeight = bigDisplay.frameHeight * bigDisplay.scale.y * 0.5;
			hitFullscreen = (FlxG.mouse.x >= bigDisplay.x - halfWidth && FlxG.mouse.x <= bigDisplay.x + halfWidth && FlxG.mouse.y >= bigDisplay.y - halfHeight && FlxG.mouse.y <= bigDisplay.y + halfHeight);
		}
		
		var nowHoveringSocial = (FlxG.mouse.x >= artistBG.x && FlxG.mouse.x <= artistBG.x + artistBG.scale.x && FlxG.mouse.y >= artistBG.y && FlxG.mouse.y <= artistBG.y + artistBG.scale.y);
		if (hoveringSocial != nowHoveringSocial) {
			hoveringSocial = nowHoveringSocial;
			artistTxt.text = nowHoveringSocial ? "OPEN SOCIAL" : list[curSelected].artist.toUpperCase();
		}

		if ((FlxG.keys.justPressed.SPACE || (FlxG.mouse.justReleased && hoveringSocial)) && list[curSelected].link.trim() != "")
			Util.openURL(list[curSelected].link);
		else if (hitFullscreen) {
			fullscreen = !fullscreen;
			if (fullscreenTwn != null) {
				fullscreenTwn.cancel();
				borderTwn.cancel();
			}
			fullscreenTwn = FlxTween.tween(this, {fullscreenPercent: fullscreen ? 1 : 0}, 0.5, {ease: FlxEase.quartOut});
			borderTwn = FlxTween.num(borderPercent, fullscreen ? 1 : 0, 0.75, {startDelay: 0.15, ease: FlxEase.cubeOut}, function(num) {
				borderPercent = num;
				borderTop.y = -borderTop.border.height * borderPercent;
				borderBot.y = borderBot.border.height * borderPercent;
			});
			FlxG.sound.play(Paths.audio(fullscreen ? "popup_appear" : "menu_cancel", 'sfx'));
		}
	}
	
	function set_fullscreenPercent(ratio:Float) {
		displayBG.alpha = 0.5 + 0.5 * ratio;
		artistBG.alpha = artistTxt.alpha = 1.0 - ratio;
		descBG.alpha = descTxt.alpha = 1.0 - ratio;
		displayBG.scale.set(
			FlxMath.lerp(displayBG.width, FlxG.width, ratio),
			FlxMath.lerp(displayBG.height, FlxG.height, ratio)
			);
		displayBG.offset.set(
			FlxMath.lerp(0, displayBG.x, ratio),
			FlxMath.lerp(0, displayBG.y, ratio)
		);
		bigDisplay.setPosition(displayBG.x - displayBG.offset.x + displayBG.scale.x * 0.5, displayBG.y - displayBG.offset.y + displayBG.scale.y * 0.5);
		bigDisplay.scale.x = bigDisplay.scale.y = FlxMath.lerp(smallScale, bigScale, ratio);
		return fullscreenPercent = ratio;
	}
}