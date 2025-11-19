package funkin.states;

import funkin.states.OptionsState.Option;
import funkin.objects.ui.SkewyLine;
import funkin.shaders.GradMask;
import funkin.shaders.TileLine;
import funkin.shaders.HueGrad;
import funkin.objects.Strumline;
import funkin.objects.Note;

import lime.system.Clipboard;
import haxe.io.Path;

using StringTools;

class CustomColorsSubstate extends flixel.FlxSubState {
	var lineShader:TileLine;
	var bg:FunkinSprite;
	var mainRect:FunkinSprite;
	
	var curRow:Int = 0; // 0 - Notes, 1 - Opts, 2 - Sliders, 3 - Actions
	var curItem:Int = 0;
	var noteOpts:Array<Option> = [
		{
			var opt = new Option("note_skin", "note_skin_desc", "noteSkin", ListOption(['camv2', 'camv1', 'funkin', 'circle','voltexArrow', 'voltexCircle', 'voltexBar', 'holofunk']));
			opt.formatText = function(_) {
				return switch (opt.value) {
					case 'camv2': "Cam. V2";
					case 'camv1': "Cam. V1";
					case 'funkin': "Funkin";
					case 'circle': "Circles";
					case 'voltexArrow': "FNVX (Arrow)";
					case 'voltexCircle': "FNVX (Circle)";
					case 'voltexBar': "FNVX (Bar)";
					case 'holofunk': "Holofunk";
					default: "how'd you get out the list";
				}
			};
			opt.onChange = function(v) {
				final self = cast(FlxG.state.subState, CustomColorsSubstate);
				final lumin = Settings.data.quantColouring != "None";
				for (note in self.notes) {
					note.texture = '';
					note.scale.set(0.55, 0.55);
					note.updateHitbox();
					note.y = self.mainRect.y + 10 + ((160 * 0.55) - note.height) * 0.5;

					if (!lumin && note.luminColors) {
						note.luminColors = false;
						note.color = 0xFFFFFFFF;
					}
				}
				self.bigNote.texture = '';
				self.bigNote.scale.set(1.5, 1.5);
				self.bigNote.updateHitbox();
				self.bigNote.y = 370 + ((160 * 1.5) - self.bigNote.height) * 0.5;
				if (!lumin && self.bigNote.luminColors) {
					self.bigNote.luminColors = false;
					self.bigNote.color = 0xFFFFFFFF;
				}

				if (!lumin) {
					Note.curPalette = getDefaultColumns();
					self.changeNote(0);
				}
			}
			opt;
		},
		{
			final possibleNotesplashes: Array<String> = ['none'];
			final notesplashNames: Map<String, String> = ['none' => 'None'];
			for (splashPath in Paths.readDirectory("data/noteSplashes"))
				if (splashPath.endsWith(".json5") || splashPath.endsWith(".json")) {
					var splashName:String = Path.withoutDirectory(Path.withoutExtension(splashPath));
					if(possibleNotesplashes.contains(splashName)) continue;
					var data = funkin.objects.NoteSplash.NoteSplashData.get(splashName);
					possibleNotesplashes.insert(0, splashName);
					notesplashNames.set(splashName, data.name);
				}

			var opt = new Option("splash_skin", "splash_skin_desc", "noteSplashSkin", ListOption(possibleNotesplashes));
			opt.formatText = function(_) {
				return notesplashNames.get(opt.value) ?? 'Fallback (${opt.value})'; // Display the name so you can figure out what the splash WAS
			};
			opt;
		},
		{ // this can be reverted if the order of the quants matter
			var quantPalettes: Array<String> = [];
			for(name in funkin.objects.Note.quantPalettes.keys())
				quantPalettes.push(name);

			quantPalettes.unshift('Custom (Columns)');
			quantPalettes.unshift('Custom');
			quantPalettes.unshift('None');

			var opt = new Option('quant_col', 'quant_col_desc', "quantColouring", ListOption(quantPalettes));
			opt.onChange = function(v) {
				final lumin = v != "None";
				if (v.startsWith("Custom")) {
					Note.byQuant = v == "Custom";
					Note.curPalette = Note.byQuant ? Settings.data.customQuants : Settings.data.customColumns;
				} else {
					Note.byQuant = lumin;
					Note.curPalette = Note.byQuant && Note.quantPalettes.exists(v) ? Note.quantPalettes[v].copy() : getDefaultColumns();
				}
				
				final self = cast(FlxG.state.subState, CustomColorsSubstate);
				for (i => note in self.notes) {
					if (!lumin || i < Note.curPalette.length)
						note.color = lumin ? Note.curPalette[i] : 0xFFFFFFFF;
					if (note.luminColors != lumin) {
						note.luminColors = lumin;
						note.texture = '';
						note.scale.set(0.55, 0.55);
						note.updateHitbox();
					}
				}
				
				self.bigNote.color = self.notes[self.curNote].color;
				if (self.bigNote.luminColors != lumin) {
					self.bigNote.luminColors = lumin;
					self.bigNote.texture = '';
					self.bigNote.scale.set(1.5, 1.5);
					self.bigNote.updateHitbox();
				}
				
				self.actions[0] = v.startsWith("Custom") ? "reset" : "apply_custom";
				self.actionTxt.members[0].text = _t(self.actions[0]).toUpperCase();
				self.actionTxt.members[0].offset.x = self.actionTxt.members[0].width * 0.5;
				self.changeNote(0);
			}
			opt;
		}
	];
	var rowItemCounts:Array<Int> = [];
	var rowHoris:Array<Int->Void>;
	var rowVerts:Array<Int->Void>;
	var preRowSwitches:Array<Void->Void>;
	var postRowSwitches:Array<Void->Void>;

	// variables to create a mouse deadzone
	final MOUSE_DEADZONE = 5; // technically 10, but goes in both directions.
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;
	public var mouseMoved:Bool = false;

	var hoverNote:Int = -1;
	var curNote:Int = 0;
	var bigNote:Note;
	var noteHover:SkewyLine;
	var noteHover2:SkewyLine;
	var notes:Array<Note> = [];

	var selOptScale:Float = 0;
	var optSel:FunkinSprite;
	var optArrLeft:FunkinSprite;
	var optArrRight:FunkinSprite;
	var optTxt:FlxTypedGroup<FlxText>;
	var optValTxt:FlxTypedGroup<FlxText>;

	// from experience, setting a color to pitch black can screw up these values.
	var curCol:Array<Int> = [0, 0, 0];
	var rgb:Bool = false;
	var holdingCol:Bool = false;
	var colTxts:FlxTypedGroup<FlxText>;
	var colVals:FlxTypedGroup<FlxText>;
	var colHover:FunkinSprite;
	var wheels:FlxTypedGroup<FunkinSprite>;
	var shaders:Array<GradMask> = [];
	var hueShader:HueGrad;
	var colWarning:FlxText;

	var curAction:Int = 1;
	var actions:Array<String> = ["apply_custom", "copy", "paste", "rgb"];
	var actionHover:FunkinSprite;
	var actionTxt:FlxTypedGroup<FlxText>;

	override function create() {
		super.create();

		bg = new FunkinSprite();
		if (!Settings.data.reducedQuality) {
			bg.makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
			lineShader = new TileLine();
			lineShader.color1.value = [0, 0, 0, 0.75 * 0.75];
			lineShader.color2.value = [0, 0, 0, 0.75];
			lineShader.density.value = [200.0];
			lineShader.time.value = [0];
			bg.shader = lineShader;
		} else {
			bg.makeGraphic(1, 1, 0xA0000000);
			bg.scale.set(FlxG.width, FlxG.height);
			bg.updateHitbox();
		}
		add(bg);

		add(mainRect = new FunkinSprite());
		mainRect.makeGraphic(1, 1, 0x80000000);
		mainRect.scale.set(1090, 620);
		mainRect.updateHitbox();
		mainRect.screenCenter();

		final lumin = Settings.data.quantColouring != "None";
		if (Settings.data.quantColouring.startsWith("Custom")) {
			Note.byQuant = Settings.data.quantColouring == "Custom";
			Note.curPalette = Note.byQuant ? Settings.data.customQuants : Settings.data.customColumns;
		} else {
			Note.byQuant = lumin;
			Note.curPalette = Note.byQuant && Note.quantPalettes.exists(Settings.data.quantColouring) ? Note.quantPalettes[Settings.data.quantColouring].copy() : getDefaultColumns();
		}
		final centerIdx:Float = Note.byQuant ? 5.5 : 2;
		for (i in 0...Settings.data.customQuants.length) {
			var note = new Note();
			note.data.lane = i % 4;
			note.luminColors = lumin;
			note.texture = '';
			note.setPosition(FlxG.width * 0.5 + 160 * 0.55 * (i - centerIdx), mainRect.y + 10);
			note.scale.set(0.55, 0.55);
			note.updateHitbox();
			note.y += ((160 * 0.55) - note.height) * 0.5;
			note.color = lumin ? Note.curPalette[Std.int(Math.min(i, Note.curPalette.length - 1))] : 0xFFFFFFFF;
			note.alpha = (Note.byQuant || i < 4) ? 1 : 0;
			add(note);
			notes.push(note);
		}

		if (Note.curPalette[curNote].rgb == 0x000000) {
			curCol[0] = 0;
			curCol[1] = 100;
			curCol[2] = 0;
		} else {
			curCol[0] = Math.floor(Note.curPalette[curNote].hue);
			curCol[1] = Math.floor(Note.curPalette[curNote].saturation * 100);
			curCol[2] = Math.floor(Note.curPalette[curNote].brightness * 100);
		}

		add(noteHover = new SkewyLine([0, 0, 160 * 0.55, 0, 160 * 0.55, 160 * 0.55, 0, 160 * 0.55]));
		noteHover.setPosition(notes[curNote].x, mainRect.y + 10);

		if (!Settings.data.reducedQuality) {
			insert(members.length - 1, noteHover2 = new SkewyLine([0, 0, 160 * 0.55, 0, 160 * 0.55, 160 * 0.55, 0, 160 * 0.55]));
			noteHover2.intensityX = -5;
			noteHover2.intensityY = -5;
			noteHover2.color = 0xFF808080;
			noteHover2.setPosition(noteHover.x, noteHover.y);
		}

		add(optSel = new FunkinSprite(mainRect.x - 4, mainRect.y).makeGraphic(1, 1, 0xFFFFFFFF));
		optSel.scale.set(mainRect.width + 8, 55);
		optSel.updateHitbox();
		optSel.scale.y = 0;

		add(optArrLeft = new FunkinSprite(optSel.x, optSel.y, Paths.image("menus/Options/arrow")));
		optArrLeft.scale.y = 0;

		add(optArrRight = new FunkinSprite(optSel.x + optSel.width, optSel.y, Paths.image("menus/Options/arrow")));
		optArrRight.flipX = true;
		optArrRight.scale.y = 0;
		optArrRight.x -= optArrRight.width;

		add(optValTxt = new FlxTypedGroup<FlxText>());
		add(optTxt = new FlxTypedGroup<FlxText>());
		var y = mainRect.y + 10 + 160 * 0.55 + 25;
		for (i => opt in noteOpts) {
			var txt = new FlxText(mainRect.x + 20, y, mainRect.width - 40, (opt.name.startsWith("<NO-LANG>") ? opt.name.substring(9, opt.name.length) : _t(opt.name)).toUpperCase());
			var val = new FlxText(txt.x, txt.y, 0, opt.formatText(false));

			txt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 30, 0xFFFFFFFF, LEFT);
			txt.updateHitbox();
			//txt.scale.x = 0.85;
			txt.origin.x = 0;

			val.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 30, 0xFFFFFFFF, RIGHT);
			val.updateHitbox();
			// val.scale.x = 0.85;
			val.origin.x = val.frameWidth;
			//y += 35;

			txt.scale.set();
			val.scale.set();
			txt.antialiasing = Settings.data.antialiasing;
			val.antialiasing = Settings.data.antialiasing;
			optTxt.add(txt);
			optValTxt.add(val);
		}

		add(bigNote = new Note());
		bigNote.data.lane = notes[curNote].data.lane;
		bigNote.luminColors = notes[curNote].luminColors;
		bigNote.texture = '';
		bigNote.scale.set(1.5, 1.5);
		bigNote.updateHitbox();
		bigNote.setPosition(250, 370 + ((160 * 1.5) - bigNote.height) * 0.5);
		bigNote.color = notes[curNote].color;

		add(colHover = new FunkinSprite());
		colHover.makeGraphic(1, 1, 0xFFFFFFFF);

		var names = ["hue", "sat", "val"];
		add(wheels = new FlxTypedGroup<FunkinSprite>());
		add(colVals = new FlxTypedGroup<FlxText>());
		add(colTxts = new FlxTypedGroup<FlxText>());
		for (i in 0...3) {
			var wheel = new FunkinSprite(750, (i == 0) ? 370 : wheels.members[i - 1].y + wheels.members[i - 1].height + 60);
			wheel.makeGraphic(1, 1, 0xFFFFFFFF);
			wheel.scale.set(390, 35);
			wheel.updateHitbox();
			shaders.push(new GradMask());
			wheel.shader = shaders[shaders.length - 1];
			wheels.add(wheel);

			var txt = new FlxText(wheel.x, wheel.y - 5, wheel.width, _t(names[i]));
			txt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 20, 0xFFFFFFFF, LEFT);
			txt.y -= txt.height;
			colTxts.add(txt);

			var val = new FlxText(txt.x, txt.y, txt.fieldWidth, Std.string(curCol[i]));
			val.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 20, 0xFFFFFFFF, RIGHT);
			colVals.add(val);
		}

		wheels.members[0].shader = hueShader = new HueGrad();
		updateColor();

		colHover.setPosition(colTxts.members[0].x - 4, colTxts.members[0].y - 4);
		colHover.scale.set(0, colTxts.members[0].height + 8);
		colHover.origin.set();

		add(colWarning = new FlxText(10, mainRect.y + mainRect.height + 3, FlxG.width - 20, _t("color_warning")));
		colWarning.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 20, 0xFFFF2C79, CENTER, OUTLINE, 0xFF000000);
		colWarning.borderSize = 2;
		colWarning.visible = false;

		add(actionHover = new FunkinSprite());
		actionHover.makeGraphic(1, 1, 0xFFFFFFFF);

		actions[0] = Settings.data.quantColouring.startsWith("Custom") ? "reset" : "apply_custom";
		add(actionTxt = new FlxTypedGroup<FlxText>());
		for (i in 0...actions.length) {
			var txt = new FlxText(mainRect.x + mainRect.width / actions.length * (i + 0.5), mainRect.y + mainRect.height - 10, 0, _t(actions[i]).toUpperCase());
			txt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 20, 0xFFFFFFFF, CENTER);
			txt.offset.x = txt.width * 0.5;
			txt.y -= txt.height;
			actionTxt.add(txt);
		}
		checkCanApply();

		actionHover.setPosition(actionTxt.members[curAction].x - 4, actionTxt.members[curAction].y - 4);
		actionHover.scale.set(actionTxt.members[curAction].width + 8, actionTxt.members[curAction].height + 8);
		actionHover.origin.set();

		rowItemCounts = [1, noteOpts.length, 3, 1];
		rowHoris = [
			function(inc) {
				changeNote(inc);
				FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
			},
			function(inc) {
				noteOpts[curItem].change(inc < 0);
				FlxG.sound.play(Paths.audio(noteOpts[curItem].sound, 'sfx'));
				optValTxt.members[curItem].text = noteOpts[curItem].formatText(true);
				optValTxt.members[curItem].x = mainRect.x + mainRect.width - 20 - optValTxt.members[curItem].width;
			},
			function(inc) {
				FlxG.sound.play(Paths.audio("menu_setting_tick", 'sfx'));

				final max = rgb ? 255 : (curItem == 0 ? 360 : 100);
				editColor(Std.int(FlxMath.bound(curCol[curItem] + inc * (FlxG.keys.pressed.SHIFT ? 1 : 5), 0, max)));
			},
			function(inc) {
				actionTxt.members[curAction].color = 0xFFFFFFFF;
				actionTxt.members[curAction].font = Paths.font('Rockford-NTLG Light.ttf');

				FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				curAction = FlxMath.wrap(curAction + inc, actionTxt.members[0].visible ? 0 : 1, actions.length - 1);

				actionTxt.members[curAction].color = 0xFF000000;
				actionTxt.members[curAction].font = Paths.font('Rockford-NTLG Medium.ttf');
			}
		];
		rowVerts = [
			null,
			function(inc) {
				deselectOpt();
		
				curItem = curItem + inc;
				optSel.scale.y = optArrLeft.scale.y = optArrRight.scale.y = 0;
				selOptScale = 0;
		
				selectOpt();
			},
			function(inc) {
				colTxts.members[curItem].color = colVals.members[curItem].color = 0xFFFFFFFF;
				colTxts.members[curItem].font = colVals.members[curItem].font = Paths.font('Rockford-NTLG Light.ttf');

				curItem = curItem + inc;
				colHover.scale.x = 0;
				colHover.y = colTxts.members[curItem].y - 4;

				colTxts.members[curItem].color = colVals.members[curItem].color = 0xFF000000;
				colTxts.members[curItem].font = colVals.members[curItem].font = Paths.font('Rockford-NTLG Medium.ttf');
			},
			null
		];
		preRowSwitches = [
			null,
			deselectOpt,
			function() {
				if (Settings.data.quantColouring.startsWith("Custom")) {
					if (Note.byQuant)
						Settings.data.customQuants = Note.curPalette;
					else
						Settings.data.customColumns = Note.curPalette;
				}

				colTxts.members[curItem].color = colVals.members[curItem].color = 0xFFFFFFFF;
				colTxts.members[curItem].font = colVals.members[curItem].font = Paths.font('Rockford-NTLG Light.ttf');
			},
			function() {
				actionTxt.members[curAction].color = 0xFFFFFFFF;
				actionTxt.members[curAction].font = Paths.font('Rockford-NTLG Light.ttf');
			}
		];
		postRowSwitches = [
			null,
			selectOpt,
			function() {
				colTxts.members[curItem].color = colVals.members[curItem].color = 0xFF000000;
				colTxts.members[curItem].font = colVals.members[curItem].font = Paths.font('Rockford-NTLG Medium.ttf');

				if (colHover.y != colTxts.members[curItem].y - 4) {
					colHover.scale.x = 0;
					colHover.y = colTxts.members[curItem].y - 4;
				}
			},
			function() {
				actionTxt.members[curAction].color = 0xFF000000;
				actionTxt.members[curAction].font = Paths.font('Rockford-NTLG Medium.ttf');
			}
		];
	}

	static function getDefaultColumns():Array<FlxColor> {
		return switch (Settings.data.noteSkin) {
			case 'camv2': [0xFFE5307F, 0xFF1BC8F1, 0xFF32D844, 0xFFF32931];
			case 'circle': [0xFFDB41B8, 0xFF24D4F7, 0xFF31EB40, 0xFFF32931];
			case 'voltexArrow' | 'voltexCircle' | 'voltexBar': [0xFF00FAFF, 0xFF00FAFF, 0xFFFC71EB, 0xFFFC71EB];
			case 'holofunk': [0xFFF04E9A, 0xFF00CCFF, 0xFF0CDF00, 0xFFF94B39];
			default: [0xFFC24C99, 0xFF02FFFF, 0xFF13FA06, 0xFFF93A40]; // camv1, funkin. theyre only a 1 channel val difference
		}
	}

	function swapColorMode() {
		FlxG.sound.play(Paths.audio("menu_toggle", 'sfx'));

		rgb = !rgb;
		wheels.members[0].shader = rgb ? shaders[0] : hueShader;
		updateColor();

		var names = rgb ? ["red", "green", "blue"] : ["hue", "sat", "val"];
		for (i in 0...colTxts.length)
			colTxts.members[i].text = _t(names[i]);

		actionTxt.members[3].text = _t(rgb ? "hsv" : "rgb");
		actionTxt.members[3].offset.x = actionTxt.members[3].width * 0.5;
	}

	function updateColor() {
		if (rgb) {
			curCol[0] = Note.curPalette[curNote].red;
			curCol[1] = Note.curPalette[curNote].green;
			curCol[2] = Note.curPalette[curNote].blue;

			for (i in 0...shaders.length) {
				shaders[i].fromCol.value = [(i == 0 ? 0 : curCol[0] / 255), (i == 1 ? 0 : curCol[1] / 255), (i == 2 ? 0 : curCol[2] / 255), 1];
				shaders[i].toCol.value = [(i == 0 ? 1 : curCol[0] / 255), (i == 1 ? 1 : curCol[1] / 255), (i == 2 ? 1 : curCol[2] / 255), 1];
			}

			for (i => val in colVals)
				val.text = Std.string(curCol[i]);

			return;
		}

		if (Note.curPalette[curNote].rgb == 0x000000) {
			curCol[0] = 0;
			curCol[1] = 100;
			curCol[2] = 0;
		} else {
			curCol[0] = Math.floor(Note.curPalette[curNote].hue);
			curCol[1] = Math.floor(Note.curPalette[curNote].saturation * 100);
			curCol[2] = Math.floor(Note.curPalette[curNote].brightness * 100);
		}

		hueShader.sat.value = [curCol[1] * 0.01];
		hueShader.brt.value = [curCol[2] * 0.01];

		var satCol = FlxColor.fromHSB(curCol[0], 0, curCol[2] * 0.01);
		shaders[1].fromCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
		satCol.setHSB(curCol[0], 1, curCol[2] * 0.01, 1);
		shaders[1].toCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];

		var brtCol = FlxColor.fromHSB(curCol[0], curCol[1] * 0.01, 0);
		shaders[2].fromCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
		brtCol.setHSB(curCol[0], curCol[1] * 0.01, 1, 1);
		shaders[2].toCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];

		for (i => val in colVals)
			val.text = Std.string(curCol[i]);
	}

	function changeNote(inc:Int) {
		curNote = FlxMath.wrap(curNote + inc, 0, Note.byQuant ? notes.length - 1 : 3);
		noteHover.scale.set(1.2, 1.2);

		bigNote.luminColors = notes[curNote].luminColors;
		bigNote.color = notes[curNote].color;
		bigNote.data.lane = notes[curNote].data.lane;
		@:privateAccess bigNote.loadAnims(Note.colours[bigNote.data.lane]);
		bigNote.y = 370 + ((160 * 1.5) - bigNote.height) * 0.5;
		updateColor();

		checkCanApply();
		if (!actionTxt.members[0].visible && curAction == 0) {
			curAction = 1;

			actionTxt.members[0].color = 0xFFFFFFFF;
			actionTxt.members[0].font = Paths.font('Rockford-NTLG Light.ttf');
			if (curRow == 3) { // most likely not but just in case
				actionTxt.members[curAction].color = 0xFF000000;
				actionTxt.members[curAction].font = Paths.font('Rockford-NTLG Medium.ttf');
			}
		}
	}

	function deselectOpt() {
		optTxt.members[curItem].color = 0xFFFFFFFF;
		optTxt.members[curItem].font = Paths.font("Rockford-NTLG Light.ttf");
		optValTxt.members[curItem].text = noteOpts[curItem].formatText(false);
		optValTxt.members[curItem].size = 30;
		optValTxt.members[curItem].color = 0xFFFFFFFF;
		optValTxt.members[curItem].font = Paths.font("Rockford-NTLG Light.ttf");
		optValTxt.members[curItem].x = mainRect.x + mainRect.width - 20 - optValTxt.members[curItem].width;
	}
	function selectOpt() {
		optTxt.members[curItem].color = 0xFF101010;
		optTxt.members[curItem].font = Paths.font("Rockford-NTLG Medium.ttf");	
		optValTxt.members[curItem].text = noteOpts[curItem].formatText(true);
		optValTxt.members[curItem].size = 80;
		optValTxt.members[curItem].color = 0xFFC7C7C7;
		optValTxt.members[curItem].font = Paths.font("Rockford-NTLG Medium.ttf");
		optValTxt.members[curItem].x = mainRect.x + mainRect.width - 20 - optValTxt.members[curItem].width;
	}

	function editColor(to:Int) {
		curCol[curItem] = to;
		colVals.members[curItem].text = Std.string(curCol[curItem]);

		notes[curNote].luminColors = bigNote.luminColors = true;
		if (rgb) {
			notes[curNote].color = bigNote.color = Note.curPalette[curNote] = FlxColor.fromRGB(curCol[0], curCol[1], curCol[2]);
			checkCanApply();

			for (i in 0...shaders.length) {
				if (i == curItem) continue;
				shaders[i].fromCol.value = [(i == 0 ? 0 : curCol[0] / 255), (i == 1 ? 0 : curCol[1] / 255), (i == 2 ? 0 : curCol[2] / 255), 1];
				shaders[i].toCol.value = [(i == 0 ? 1 : curCol[0] / 255), (i == 1 ? 1 : curCol[1] / 255), (i == 2 ? 1 : curCol[2] / 255), 1];
			}

			return;
		}

		notes[curNote].color = bigNote.color = Note.curPalette[curNote] = FlxColor.fromHSB(curCol[0], curCol[1] * 0.01, curCol[2] * 0.01);
		checkCanApply();
		switch (curItem) {
			case 0:
				var satCol = FlxColor.fromHSB(curCol[0], 0, curCol[2] * 0.01);
				shaders[1].fromCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
				satCol.setHSB(curCol[0], 1, curCol[2] * 0.01, 1);
				shaders[1].toCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
		
				var brtCol = FlxColor.fromHSB(curCol[0], curCol[1] * 0.01, 0);
				shaders[2].fromCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
				brtCol.setHSB(curCol[0], curCol[1] * 0.01, 1, 1);
				shaders[2].toCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
			case 1:
				hueShader.sat.value = [curCol[1] * 0.01];

				var brtCol = FlxColor.fromHSB(curCol[0], curCol[1] * 0.01, 0);
				shaders[2].fromCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
				brtCol.setHSB(curCol[0], curCol[1] * 0.01, 1, 1);
				shaders[2].toCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
			case 2:
				hueShader.brt.value = [curCol[2] * 0.01];

				var satCol = FlxColor.fromHSB(curCol[0], 0, curCol[2] * 0.01);
				shaders[1].fromCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
				satCol.setHSB(curCol[0], 1, curCol[2] * 0.01, 1);
				shaders[1].toCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
		}
	}

	function checkCanApply() {
		final isCustom = Settings.data.quantColouring.startsWith("Custom");
		final data = isCustom ? Settings.default_data : Settings.data;
		actionTxt.members[0].visible = Note.curPalette[curNote] != (Note.byQuant ? data.customQuants : data.customColumns)[curNote];

		colWarning.visible = !isCustom && Note.curPalette[curNote] != (Note.byQuant ? Note.quantPalettes[Settings.data.quantColouring] : getDefaultColumns())[curNote];
	}
	function runAction() {
		switch (actions[curAction]) {
			case "apply_custom" | "reset":
				FlxG.sound.play(Paths.audio("popup_select", 'sfx'));

				final target = Note.byQuant ? Settings.data.customQuants : Settings.data.customColumns;
				final ref = actions[curAction] == "reset" ? (Note.byQuant ? Settings.default_data.customQuants : Settings.default_data.customColumns) : Note.curPalette;

				target[curNote] = ref[curNote];

				if (actions[curAction] == "reset") {
					notes[curNote].color = bigNote.color = Note.curPalette[curNote] = ref[curNote];
					updateColor();
				}

				actionTxt.members[0].visible = false;
				actionTxt.members[0].color = 0xFFFFFFFF;
				actionTxt.members[0].font = Paths.font('Rockford-NTLG Light.ttf');
				if (curAction == 0) { // these ifs are just in case.
					curAction = 1;
		
					if (curRow == 3) {
						actionTxt.members[curAction].color = 0xFF000000;
						actionTxt.members[curAction].font = Paths.font('Rockford-NTLG Medium.ttf');
					}
				}
			case "copy":
				FlxG.sound.play(Paths.audio("popup_appear", 'sfx'));
				Clipboard.text = Note.curPalette[curNote].toWebString();
			case "paste":
				var str = Clipboard.text.replace("#", "0x");
				if (str.length == 6 && !str.startsWith("0x"))
					str = "0x" + str;

				if (str.length == 8) {
					FlxG.sound.play(Paths.audio("popup_select", 'sfx'));
					notes[curNote].color = bigNote.color = Note.curPalette[curNote] = Std.parseInt(str);
					updateColor();
					checkCanApply();
				} else {
					trace("Invalid clipboard item!");
					FlxG.sound.play(Paths.audio("menu_deletedata", 'sfx'));

					FlxTween.cancelTweensOf(actionHover);
					FlxTween.shake(actionHover, 5, 0.35, X, {ease: FlxEase.quadOut});
					FlxTween.color(actionHover, 0.35, 0xFFFF5F5F, 0xFFFFFFFF, {ease: FlxEase.quadOut});
				}
			case "rgb" | "hsv":
				swapColorMode();
		}
	}
	
	function switchRow(row:Int, item:Int) {
		if (preRowSwitches[curRow] != null)
			preRowSwitches[curRow]();

		curRow = row;
		curItem = item;

		if (postRowSwitches[curRow] != null)
			postRowSwitches[curRow]();
	}

	override function update(delta:Float) {
		super.update(delta);

		mouseMoved = false;
		if (Math.abs(FlxG.mouse.screenX - lastMouseX) >= MOUSE_DEADZONE || Math.abs(FlxG.mouse.screenY - lastMouseY) >= MOUSE_DEADZONE) {
			lastMouseX = FlxG.mouse.screenX;
			lastMouseY = FlxG.mouse.screenY;
			mouseMoved = true;
		}

		if (!Settings.data.reducedQuality)
			lineShader.time.value[0] = lineShader.time.value[0] + (delta / 64);

		final centerIdx:Float = Note.byQuant ? 5.5 : 2;
		for (i in 0...notes.length) {
			notes[i].x = FlxMath.lerp(notes[i].x, FlxG.width * 0.5 + 160 * 0.55 * (i - centerIdx), delta * 15);
			notes[i].scale.x = notes[i].scale.y = FlxMath.lerp(notes[i].scale.x, (hoverNote == i) ? 0.65 : 0.55, delta * 15);
			if (curRow == 0)
				notes[i].alpha = FlxMath.lerp(notes[i].alpha, (Note.byQuant || i < 4) ? 1 : 0, delta * (7.5 + 7.5 * ((i - 4) / 7)));
			else
				notes[i].alpha = FlxMath.lerp(notes[i].alpha, (Note.byQuant || i < 4) ? 0.5 : 0, delta * 10);
		}
		noteHover.x = FlxMath.lerp(noteHover.x, notes[curNote].x, delta * 15);
		noteHover.scale.x = noteHover.scale.y = FlxMath.lerp(noteHover.scale.x, 1, delta * 10);
		if (noteHover2 != null) {
			noteHover2.x = noteHover.x;
			noteHover2.scale.copyFrom(noteHover.scale);
		}

		final curOpt = curRow == 1 ? curItem : -1;
		var curOptY = mainRect.y + 10 + 160 * 0.55 + 25;
		for (i in 0...optTxt.members.length) {
			final txt = optTxt.members[i];
			final val = optValTxt.members[i];
			@:privateAccess {
				txt.regenGraphic();
				val.regenGraphic();
			}

			txt.origin.x = 0;
			val.origin.x = val.frameWidth;
			txt.scale.x = txt.scale.y = FlxMath.lerp(txt.scale.x, (i == curOpt ? 1.0 : 0.85), delta * 15);
			val.scale.copyFrom(txt.scale);
			final scale = ((txt.scale.y - 0.85) / 0.15);

			curOptY += 10 * scale;
			txt.y = curOptY;
			val.x = mainRect.x + mainRect.width - 20 - val.width;
			val.y = txt.y + (txt.height - val.height) * 0.5 + ((i == curOpt) ? 3 * scale : 0);
			curOptY += 35 + 10 * scale;

			val.visible = true;
			val.offset.y = 0;
			if (i != curOpt) continue;

			val.visible = false;
			final valTop = val.y + (val.graphic.height - val.graphic.height * val.scale.y) * 0.5;
			final valBot = (valTop + val.graphic.height * val.scale.y);
			final valTopMargin = optSel.y + (optSel.height - optSel.scale.y) * 0.5;
			final valBotMargin = optSel.y + (optSel.height + optSel.scale.y) * 0.5;
			final valTopClip = Math.max(valTopMargin - valTop, 0);
			if (valBot > valTopMargin + 5 && valTop < valBotMargin - 5) {
				final leftClip = Math.max(optSel.x - val.x, 0) / val.scale.x;
				val.clipGraphic(leftClip, valTopClip / val.scale.y, val.graphic.width - leftClip, val.graphic.height - (Math.max(valBot - valBotMargin, 0) + valTopClip) / val.scale.y);
				val.offset.x = -leftClip;
				val.offset.y = -valTopClip;
				val.visible = val.frameHeight > 0;
			}
		}
		if (curOpt >= 0)
			optArrLeft.y = optArrRight.y = optSel.y = optTxt.members[curOpt].y + (optTxt.members[curOpt].height - optSel.height) * 0.5;

		selOptScale = Math.min(Math.max(selOptScale + delta * (curOpt < 0 ? -8 : 4), 0.0), 1.0);
		final easedScale = FlxEase.backOut(selOptScale);
		optSel.scale.y = optSel.height * easedScale;
		optArrLeft.scale.y = optArrRight.scale.y = easedScale;

		colHover.scale.x = FlxMath.lerp(colHover.scale.x, colTxts.members[0].fieldWidth + 8, delta * 15);
		colHover.alpha = FlxMath.lerp(colHover.alpha, (curRow == 2 ? 1 : 0.5), delta * 10);
		actionHover.x = FlxMath.lerp(actionHover.x, actionTxt.members[curAction].x - actionTxt.members[curAction].offset.x - 4, delta * 15);
		actionHover.scale.x = FlxMath.lerp(actionHover.scale.x, actionTxt.members[curAction].width + 8, delta * 15);
		actionHover.alpha = FlxMath.lerp(actionHover.alpha, (curRow == 3 ? 1 : 0.5), delta * 10);

		if (holdingCol) {
			if (FlxG.mouse.justReleased) {
				holdingCol = false;
				FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
			}

			final max = rgb ? 255 : (curItem == 0 ? 360 : 100);
			editColor(Std.int(FlxMath.bound((FlxG.mouse.x - wheels.members[curItem].x) / wheels.members[curItem].width, 0, 1) * max));
			return;
		}

		final leftJustPressed:Bool = Controls.justPressed("ui_left");
		final upJustPressed:Bool = Controls.justPressed("ui_up");
		final upJustPressed:Bool = Controls.justPressed("ui_up");

		if (leftJustPressed || Controls.justPressed("ui_right") && rowHoris[curRow] != null) {
			rowHoris[curRow](leftJustPressed ? -1 : 1);
		} else if (upJustPressed || Controls.justPressed("ui_down")) {
			if ((upJustPressed && curItem <= 0) || (!upJustPressed && curItem >= rowItemCounts[curRow] - 1)) {
				final nextRow = FlxMath.wrap(curRow + (upJustPressed ? -1 : 1), 0, rowItemCounts.length - 1);
				switchRow(nextRow, (upJustPressed ? rowItemCounts[nextRow] - 1 : 0));
			} else if (rowVerts[curRow] != null)
				rowVerts[curRow](upJustPressed ? -1 : 1);

			FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
		} else if (Controls.justPressed("accept") && curRow == 3) {
			runAction();
		} else if (Controls.justPressed("back") || FlxG.mouse.justPressedRight) {
			if (Settings.data.quantColouring.startsWith("Custom")) {
				if (Note.byQuant)
					Settings.data.customQuants = Note.curPalette;
				else
					Settings.data.customColumns = Note.curPalette;
			}

			close();
		}

		if (FlxG.mouse.y >= mainRect.y + 5 && FlxG.mouse.y <= mainRect.y + 15 + 160 * 0.55) {
			if (mouseMoved && curRow != 0) {
				switchRow(0, 0);
				FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
			}

			var queueHover = -1;
			for (i => note in notes) {
				if ((Note.byQuant || i < 4) && FlxG.mouse.x >= note.x && FlxG.mouse.x <= note.x + note.width) {
					queueHover = i;

					if (FlxG.mouse.justReleased && curNote != i) {
						changeNote(i - curNote);
						FlxG.sound.play(Paths.audio("popup_appear", 'sfx'));
					}
				}
			}

			if (queueHover >= 0 && queueHover != hoverNote)
				FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
			hoverNote = queueHover;
		} else
			hoverNote = -1;

		for (i => txt in optTxt.members) {
			var height = 35 + 20 * ((txt.scale.y - 0.85) / 0.15);
			
			var top = txt.y + (txt.height - height) * 0.5;
			if (FlxG.mouse.y >= top && FlxG.mouse.y <= top + height) {
				if (mouseMoved && curRow != 1) {
					switchRow(1, i);
					FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				} else if (mouseMoved && curItem != i && rowVerts[curRow] != null) {
					rowVerts[curRow](i - curItem);
					FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				}

				if (FlxG.mouse.justPressed) {
					if (noteOpts[curItem].type == BoolOption) {
						noteOpts[curItem].change(false);
						FlxG.sound.play(Paths.audio(noteOpts[curItem].sound, 'sfx'));
						optValTxt.members[curItem].text = noteOpts[curItem].formatText(true);
					} else if (Math.abs(FlxG.mouse.x - (optSel.x + optSel.width * 0.5)) >= optSel.width * 0.5 - 25) {
						final isLeft = FlxG.mouse.x <= optSel.x + 25;

						noteOpts[curItem].change(isLeft);
						FlxG.sound.play(Paths.audio(noteOpts[curItem].sound, 'sfx'));
						optValTxt.members[curItem].text = noteOpts[curItem].formatText(true);
					}
				}
				break;
			}
		}

		for (i => wheel in wheels.members) {
			if (FlxG.mouse.x >= wheel.x - 4 && FlxG.mouse.x <= wheel.x + wheel.width + 4 && FlxG.mouse.y >= colTxts.members[i].y && FlxG.mouse.y <= wheel.y + wheel.height) {
				if (mouseMoved && curRow != 2) {
					switchRow(2, i);
					FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				} else if (mouseMoved && curItem != i && rowVerts[curRow] != null) {
					rowVerts[curRow](i - curItem);
					FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				}

				if (FlxG.mouse.justPressed) {
					holdingCol = true;
					FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				}
			}
		}

		final div = mainRect.width / actions.length;
		for (i => action in actionTxt.members) {
			if (action.visible && FlxG.mouse.x >= mainRect.x + div * i && FlxG.mouse.x <= mainRect.x + div * (i + 1) && FlxG.mouse.y >= action.y - 4 && FlxG.mouse.y <= action.y + action.height + 4) {
				if (mouseMoved && curRow != 3) {
					switchRow(3, i);
					FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				} else if (mouseMoved && curAction != i) {
					rowHoris[curRow](i - curAction);
					FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				}

				if (FlxG.mouse.justReleased)
					runAction();
			}
		}
	}
}