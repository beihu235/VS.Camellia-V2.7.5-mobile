package funkin.backend;

import funkin.backend.Meta;
import funkin.objects.Note;
import funkin.objects.Strumline;
import moonchart.formats.OsuMania;
import moonchart.formats.StepMania;
import moonchart.formats.StepManiaShark;
import moonchart.formats.BasicFormat;

typedef JsonChart = {
	var notes:Array<JsonSection>;
	var speed:Float;
}
typedef JsonSection = {sectionNotes:Array<Dynamic>, mustHitSection:Bool, ?changeBPM:Bool, ?bpm:Float, ?sectionBeats:Float, ?lengthInSteps:Float};

typedef Chart = {
	var notes:Array<NoteData>;
	var speed:Float;
	var ?meta:MetaFile;
}

class Song {
	public static function createDummyFile():Chart {
		return {
			notes: [],
			speed: 1.0
		}
	}

	public static function loadFromPath(path:String, ?meta:MetaFile):Chart {
		var file:Chart = createDummyFile();
		file.meta = meta;

		if (!FileSystem.exists(path)) return file;

		inline function tryBpmChanges(basic:DynamicFormat, offsetMult:Float) {
			if (meta == null) return;
			if (meta.timingPoints != null && meta.timingPoints.length > 0) return;
			meta.timingPoints ??= [];

			final basicMeta = basic.getChartMeta();
			meta.offset = basicMeta.offset * offsetMult;
			for (bpm in basicMeta.bpmChanges) {
				meta.timingPoints.push({
					time: bpm.time,
					bpm: bpm.bpm,
					beatsPerMeasure: Std.int(bpm.beatsPerMeasure)
				});
			}
		}

		var rawChart:JsonChart = switch haxe.io.Path.extension(path) {
			case 'json':
				final json = Json.parse(File.getContent(path)).song;
				if (meta != null && (meta.timingPoints == null || meta.timingPoints.length <= 0)) {
					meta.timingPoints ??= [];
					final sects:Array<JsonSection> = cast json.notes;

					var curTime:Float = 0;
					var curBpm = json.bpm;
					meta.timingPoints.push({
						time: curTime,
						bpm: curBpm,
						beatsPerMeasure: 4
					});
					for (section in sects) {
						if (section.changeBPM == true && (section.bpm ?? 0.0) > 0) { // using == true in case theres a null changeBPM
							curBpm = section.bpm;
							meta.timingPoints.push({
								time: curTime,
								bpm: curBpm,
								beatsPerMeasure: 4
							});
						}

						final len = section.sectionBeats ?? ((section.lengthInSteps ?? 16) * 0.25);
						curTime += Conductor.calculateCrotchet(curBpm) * len;
					}
				}
				cast json;

			case 'sm':
				var fnf:CamelliaChart = new CamelliaChart();
				fnf.bakedOffset = false;
				fnf.offsetHolds = false;
				var sm:StepMania = new StepMania().fromFile(path);
				tryBpmChanges(sm, 1);
				cast fnf.fromFormat(sm).data.song;

			case 'ssc':
				var fnf:CamelliaChart = new CamelliaChart();
				fnf.bakedOffset = false;
				fnf.offsetHolds = false;
				var ssc:StepManiaShark = new StepManiaShark().fromFile(path);
				tryBpmChanges(ssc, 1);
				cast fnf.fromFormat(ssc).data.song;

			case 'osu':
				var fnf:CamelliaChart = new CamelliaChart();
				fnf.bakedOffset = false;
				fnf.offsetHolds = false;
				final osu:CamOsuChart = cast new CamOsuChart().fromFile(path);
				tryBpmChanges(osu, 0); // AudioLeadIn is NOT a song offset.
				cast fnf.fromFormat(osu).data.song;

			default: null;
		}

		for (section in rawChart.notes) {
			for (note in section.sectionNotes) {
				file.notes.push({
					time: Math.max(0, note[0]),
					lane: Std.int(note[1] % 4),
					length: note[2],
					player: note[1] > (Strumline.keyCount - 1) != section.mustHitSection ? 1 : 0,
					speed: rawChart.speed,
					type: (note[3] is String ? note[3] : Note.defaultTypes[note[3]]) ?? '',
				});
			}
		}

		file.notes.sort((a, b) -> Std.int(a.time - b.time));

		return file;
	}

	public static function load(song:String, diff:String):Chart {
		return loadFromPath(Paths.get('songs/$song/${getFile(song, diff)}'), Meta.load(song));
	}

	static var formats:Array<String> = ['json', 'sm', 'ssc', 'osu'];
	public static function getFile(song:String, diff:String) {
		diff = Difficulty.format(diff);
		var path:String = '$diff.${formats[0]}';

		var files:Array<String> = FileSystem.readDirectory(Paths.get('songs/$song'));
		for (format in formats) {
			if (files.contains('$diff.$format')) {
				path = '$diff.$format';
				break;
			}
		}

		return path;
	}

	public static function exists(song:String, difficulty:String):Bool {
		return Paths.exists('songs/$song/${getFile(song, difficulty)}');
	}
}

class CamOsuChart extends OsuMania {
	public static function encodeType(hitsound:ByteInt) {
		return 'OSU__$hitsound';
	}

	override function getNotes(?diff:String):Array<BasicNote> {
		var circleSize:Int = data.Difficulty.CircleSize;
		var hitObjects = data.HitObjects;
		var notes:Array<BasicNote> = moonchart.backend.Util.makeArray(hitObjects.length);

		for (i in 0...hitObjects.length) {
			var note = hitObjects[i]; // x, y, time, type, hitSound, objectParams, length/hitSample
			var time:Int = note[2];
			var lane:Int = Math.floor(note[0] * circleSize / OsuMania.OSU_CIRCLE_SIZE);
			var length:Int = (note[5] > 0) ? (note[5] - time) : 0;

			var foundType = note[3];
			var type = BasicNoteType.DEFAULT;

			if (note[4] != 0)
				type = encodeType(note[4]);

			moonchart.backend.Util.setArray(notes, i, {
				time: time,
				lane: lane,
				length: length,
				type: type
			});
		}

		moonchart.backend.Timing.sortNotes(notes);

		return notes;
	}
}

class CamelliaChart extends moonchart.formats.fnf.legacy.FNFLegacy {
 	public function new() {
    	this.indexedTypes = false;
    	this.bakedOffset = false;
    	this.offsetHolds = false;
    
    	super();
		noteTypeResolver.register("Roll", BasicNoteType.ROLL);
		noteTypeResolver.register("Mine", BasicNoteType.MINE);
		noteTypeResolver.register('Cheer', CamOsuChart.encodeType(4));
		noteTypeResolver.register("Alt Animation", CamOsuChart.encodeType(8));
    	noteTypeResolver.register("this is a duel note", CamOsuChart.encodeType(10));
		noteTypeResolver.register("this is a uufo only note", CamOsuChart.encodeType(2));
  	}
}