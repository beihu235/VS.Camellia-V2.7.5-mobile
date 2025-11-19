package funkin.states;

import haxe.io.Path;
import funkin.objects.FunkinSprite;
import funkin.objects.ui.SwirlBG;
import funkin.objects.ui.Border;
import funkin.shaders.SwirlBGShader;
import funkin.shaders.GradMask;
import funkin.shaders.TileLine;
import flixel.addons.display.FlxBackdrop;

class MainMenuState extends FunkinState {
	var bg:SwirlBG;
	var lineShader:TileLine;
	var borderBot:Border;
	var textFade:FunkinSprite;
	var mainMenuTile:FlxBackdrop;
	
	// ill make this bump later
	var logo:FunkinSprite;
	
	var artTwn:FlxTween;
	var sideArt:FunkinSprite;
	var gradMask:GradMask;

	var list:Array<String> = ['story', 'freeplay', 'options', 'extras', 'credits'];
	var funnyScroll:Bool = FlxG.random.bool(1);
	var objs:FlxTypedSpriteGroup<MainMenuOption>;
	var curSelected:Int = -1;

	// variables to create a mouse deadzone
	final MOUSE_DEADZONE = 5; // technically 10, but goes in both directions.
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;
	
	override function create():Void {
		super.create();

		add(bg = new SwirlBG(0xFFFF427E, 0xFF6F1831));

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

		var possible = [for (file in FileSystem.readDirectory("assets/images/menus/MainMenu/sideArt")) Path.withoutExtension(file)];
		sideArt = new FunkinSprite(FlxG.width, 0, Paths.image("menus/MainMenu/sideArt/" + possible[FlxG.random.int(0, possible.length - 1)]));
		sideArt.scale.scale(FlxG.height / sideArt.frameHeight);
		sideArt.updateHitbox();
		gradMask = new GradMask();
		sideArt.shader = gradMask;
		gradMask.from.value = [1];
		gradMask.to.value = [1];
		add(sideArt);
		sideArt.x -= sideArt.width * 0.2;
		artTwn = FlxTween.num(0, 1, 1, {startDelay: 0.2}, function(num) {
			sideArt.x = FlxG.width - sideArt.width * (0.2 + 0.6 * FlxEase.quintOut(num));
			gradMask.to.value[0] = 1.0 - 0.7 * FlxEase.quintOut(num);
			gradMask.from.value[0] = 1.0 - FlxEase.quintOut(num);
		});
		//FlxTween.tween(sideArt, {x: FlxG.width - sideArt.width, alpha: 1}, 1, {ease: FlxEase.quintOut, startDelay: 0.2});

		mainMenuTile = new FlxBackdrop(Paths.image('menus/MainMenu/text'), Y);
		mainMenuTile.velocity.y = 25;
		mainMenuTile.scale.set(0.5, 0.5);
		mainMenuTile.updateHitbox();
		add(mainMenuTile);

		add(logo = new FunkinSprite(40, 40, Paths.image("menus/MainMenu/twotone_camlogo")));
		logo.scale.set(0.5, 0.5);
		logo.updateHitbox();

		add(objs = new FlxTypedSpriteGroup<MainMenuOption>());
		for (i => option in list) {
			var select:Void->Void = () -> {};
			var position:FlxPoint = FlxPoint.get(0, 0);
			var art:String = option;

			switch option {
				case 'story':
					select = () -> {FlxG.switchState(new StoryMenuState());};
					position.set(50, 300);

				case 'freeplay':
					select = () -> {FlxG.switchState(new FreeplayState());};
					position.set(325, 300);

				case 'options':
					select = () -> {FlxG.switchState(new OptionsState());};
					position.set(50, 505);

				case 'extras':
					select = () -> {
						ExtrasState.fromMainMenu = true;
						FlxG.switchState(new ExtrasState());
					};
					position.set(230, 505);

				case 'credits':
					select = () -> {FlxG.switchState(new CreditsState());};
					position.set(410, 505);
			}

			var obj = new MainMenuOption(option, select, art);
			obj.setPosition(position.x, position.y);
			objs.add(obj);
			obj.ID = i;
			position.put();
		}

		borderBot = new Border(false);
		add(borderBot);

		var logoIdx = borderBot.members.indexOf(borderBot.camelliaLogo);
		var scrollTitle = new FlxText(0, FlxG.height, 0, funnyScroll ? "ough.... im gonna be sick.     ouuuuuugh. OUUUUUUUUUUUUUUUUUUUUUUGH " : "VS. CAMELLIA VERSION 2.75 • ");
		scrollTitle.setFormat(Paths.font("LineSeed.ttf"), 32, 0xFFFFFFFF, RIGHT);
		scrollTitle.updateHitbox();
		scrollTitle.clipGraphic(0, 0, FlxG.width, scrollTitle.frameHeight);
		scrollTitle.wrapMode = REPEAT;
		scrollTitle.scrollFactor.set(0, 1);
		scrollTitle.y -= scrollTitle.height;
		scrollTitle.alpha = 0.05;
		borderBot.insert(logoIdx, borderBot.scrollTitle = scrollTitle);

		borderBot.insert(logoIdx + 1, textFade = new FunkinSprite(FlxG.width, FlxG.height, Paths.image("menus/MainMenu/textFade")));
		textFade.x -= textFade.width;
		textFade.y -= textFade.height;

		#if (IS_TESTBUILD && DISCORD_ALLOWED)
		//after giving them some hope, we end up crushing it xd
		var okayyoucanpass:Bool = false;
		for (tester in funkin.backend.DiscordClient.testers) {
			//trace('current tester: $tester, current user: ${funkin.backend.DiscordClient.username}');
			if (tester == funkin.backend.DiscordClient.username)
				okayyoucanpass = true;
		}
		if (!okayyoucanpass) {
			Conductor.stop();
			FlxG.switchState(new UserNotApproved());
			return;
		}
		#end

		borderBot.transitionTween(true, 0);
	}

	override function update(delta:Float):Void {
		super.update(delta);

		bg.speed = FlxMath.lerp(bg.speed, 1.0, delta * 15.0);
		if (!Settings.data.reducedQuality)
			lineShader.time.value[0] = SwirlBG.time / 64;
		if (funnyScroll)
			borderBot.titleSpeed = 175 * (Math.sin(SwirlBG.time * 18) + 1.5);

		if (curSelected < -1) return;
		
		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			FlxG.sound.play(Paths.audio("menu_cancel", "sfx"));
			borderBot.transitionTween(false, 0.25, 0.25, () -> {FlxG.switchState(new TitleState());});
			curSelected = -2;
			return;
		} 

		if (Math.abs(FlxG.mouse.screenX - lastMouseX) >= MOUSE_DEADZONE || Math.abs(FlxG.mouse.screenY - lastMouseY) >= MOUSE_DEADZONE) {
			lastMouseX = FlxG.mouse.screenX;
			lastMouseY = FlxG.mouse.screenY;

			for (option in objs) {
				if (!option.visible) continue;

				if (FlxG.mouse.overlaps(option) && (curSelected != option.ID)) {
					changeSelection(option.ID);
					break;
				}
			}
		}

/*		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight)
			FlxG.switchState(new TitleState());*/

		final leftJustPressed:Bool = Controls.justPressed('ui_left');
		final downJustPressed:Bool = Controls.justPressed('ui_down');

		if (leftJustPressed || Controls.justPressed('ui_right')) {
			if (curSelected < 2)
				changeSelection(FlxMath.wrap(curSelected + (leftJustPressed ? -1 : 1), 0, 1));
			else
				changeSelection(FlxMath.wrap(curSelected + (leftJustPressed ? -1 : 1), 2, list.length - 1));
		} else if (downJustPressed || Controls.justPressed('ui_up')) {
			if (curSelected < 2)
				changeSelection((curSelected == 1) ? list.length - 1 : 2);
			else
				changeSelection((curSelected == list.length - 1) ? 1 : 0);
		}
		
		if (curSelected < 0) return;

		if (FlxG.mouse.justPressed) {
            for (option in objs) {
                if (FlxG.mouse.overlaps(option)) {
					if (option.ID != curSelected)
                    	changeSelection(option.ID);
                    selectItem();
                    break;
                }
            }
		} else if (Controls.justPressed('accept'))
			selectItem();
	}

	function selectItem() {
		FlxG.sound.play(Paths.audio("menu_confirm", "sfx"));

		FlxTween.tween(borderBot.scrollTitle, {y: borderBot.scrollTitle.y + borderBot.scrollTitle.height, alpha: 0}, 0.5, {ease: FlxEase.quintOut});
		FlxTween.tween(mainMenuTile, {x: mainMenuTile.x - mainMenuTile.width}, 0.75, {ease: FlxEase.cubeIn});

		artTwn.cancel();
		FlxTween.num(artTwn.scale, 0, 1, null, function(num) {
			sideArt.x = FlxG.width - sideArt.width * (0.2 + 0.6 * FlxEase.quintOut(num));
			gradMask.to.value[0] = 1.0 - 0.7 * FlxEase.quintOut(num);
			gradMask.from.value[0] = 1.0 - FlxEase.quintOut(num);
		});

		for (i => obj in objs.members) {
			if (i == curSelected) {
				final clone = obj.bg.clone();
				add(clone);
				clone.setPosition(obj.bg.x, obj.bg.y);

				FlxTween.tween(clone, {"scale.x": 1.5, "scale.y": 1.4, alpha: 0}, 1, {ease: FlxEase.cubeOut});
				borderBot.transitionTween(false, 0.25, 0.25, obj.select);
			} else {
				FlxTween.tween(obj, {"x": obj.x - 50, alpha: 0}, 0.35, {ease: FlxEase.quintOut});
			}
		}

		curSelected = -2;
	}

	function changeSelection(index:Int = 0) {
		bg.speed = 10;

		// set old
		if (curSelected >= 0) {
			var lastObj:MainMenuOption = objs.members[curSelected];
			lastObj.bg.color = 0xFF000000;
			lastObj.bg.alpha = 0.6;

			lastObj.text.font = Paths.font('Rockford-NTLG Light.ttf');
			@:privateAccess lastObj.text.regenGraphic();
			lastObj.text.origin.set(0, lastObj.text.frameHeight);

			FlxTween.cancelTweensOf(lastObj.text);
			FlxTween.tween(lastObj.text.scale, {x: 10 / 11, y: 10 / 11}, 0.1, {ease: FlxEase.cubeOut});
			lastObj.text.color = 0xFFFFFFFF;
		}

		// set new
		var curObj:MainMenuOption = objs.members[index];
		curObj.bg.color = 0xFFFFFFFF;
		curObj.bg.alpha = 1;

		if (!funnyScroll)
			borderBot.scrollText = _formatT(list[index] + "_desc", [","]) + " • ";
		
		curObj.text.font = Paths.font('Rockford-NTLG Medium.ttf');
		@:privateAccess curObj.text.regenGraphic();
		curObj.text.origin.set(0, curObj.text.frameHeight);
		FlxTween.cancelTweensOf(curObj.text);
		FlxTween.tween(curObj.text.scale, {x: 1, y: 1}, 0.1, {ease: FlxEase.cubeOut});
		curObj.text.color = 0xFF000000;

		// set curSelected
		curSelected = index;

		FlxG.sound.play(Paths.audio("menu_move", "sfx"));
	}
}

private class MainMenuOption extends FlxSpriteGroup {
	public var bg:FunkinSprite;
	public var text:FlxText;
	public var select:Void->Void;

	public function new(name:String, select:Void->Void, ?art:String) {
		super();
		this.select = select;

		add(bg = new FunkinSprite(Paths.image("menus/MainMenu/" + art)));
		bg.color = 0xFF000000;
		bg.alpha = 0.6;

		add(text = new FlxText(5, 0, 0, _t(name + "_button"), 33));
		text.font = Paths.font('Rockford-NTLG Light.ttf');
		text.y = (bg.height - text.height) - 3;
		text.origin.set(0, text.frameHeight);
		text.scale.scale(10 / 11);
	}
}