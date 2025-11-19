package funkin.backend;

import flixel.graphics.FlxGraphic;
import openfl.system.System;
import animate.FlxAnimateFrames;

import lime.utils.Assets as LimeAssets;
import openfl.media.Sound;

import openfl.display.BitmapData;
import flixel.util.typeLimit.OneOfTwo;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;

import lime.app.Promise;
import lime.app.Future;

// credits to Chris Speciale (lead openfl maintainer) for giving me this abstract lmao
// was a pain in the ass to deal with Dynamic
abstract CachedAsset(Dynamic) {
    // cast from FlxGraphic to CachedAsset
    @:from static inline function fromFlxGraphic(graphic:FlxGraphic):CachedAsset {
        return cast graphic;
    }
    // cast from Sound to CachedAsset
    @:from static inline function fromSound(sound:Sound):CachedAsset {
        return cast sound;
    }
	// cast from FlxAnimateFrames to CachedAsset
    @:from static inline function fromFlxAnimateFrames(frames:FlxAnimateFrames):CachedAsset {
        return cast frames;
	}
	// cast from FlxFramesCollection to CachedAsset
    @:from static inline function fromFlxFramesCollection(frames:FlxFramesCollection):CachedAsset {
        return cast frames;
    }
    // cast from CachedAsset to FlxGraphic
    @:to inline function toFlxGraphic():FlxGraphic {
        return cast this;
    }

    // cast from CachedAsset to Sound
    @:to inline function toSound():Sound {
        return cast this;
    }

	// cast from CachedAsset to FlxAnimateFrames
    @:to inline function toFlxAnimateFrames():FlxAnimateFrames {
        return cast this;
    }

	// cast from CachedAsset to FlxFramesCollection
    @:to inline function toFlxFramesCollection():FlxFramesCollection {
        return cast this;
    }
}

class Paths {
	public static final SOUND_EXT:String = "ogg";
	public static final VIDEO_EXT:String = "mp4";
	public static final IMAGE_EXT:String = "png";

	public static final dumpExclusions:Array<String> = ['SNDmusic/myths-menuscreen.$SOUND_EXT', 'SNDmusic/pause music.$SOUND_EXT'];

	// the tracked assets for the current state
	// not meant to be iterated through for all assets loaded
	public static var localTrackedAssets:Array<String> = [];

	// the currently cached assets
	// iterate this if you want all assets currently loaded
	public static var cachedAssets:Map<String, CachedAsset> = [];

	inline public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
	}

	public static dynamic function destroyAsset(key:String, ?asset:CachedAsset) {
		if (asset == null) {
			asset = cachedAssets[key];
			if (asset == null) return;
		}

		switch (Type.typeof(asset)) {
			// destroying method for graphics
			case TClass(FlxGraphic):
				var graphic:FlxGraphic = asset;

				@:privateAccess
				if (graphic.bitmap != null && graphic.bitmap.__texture != null)
					graphic.bitmap.__texture.dispose();
				FlxG.bitmap.remove(graphic);

				graphic = null;
			// destroying method for sounds
			case TClass(Sound):
				(asset:Sound).close();
				//LimeAssets.cache.clear(key);
			// destroying method for frames
			case TClass(FlxFramesCollection) | TClass(FlxAtlasFrames) | TClass(FlxAnimateFrames):
				(asset:FlxFramesCollection).destroy();
				
			// if grabbed asset doesn't exist then we stop the function
			default:
				trace('uh oh failed asset !!!!! "$key"');
				return;
		}

		cachedAssets.remove(key);
	}

	// deload unused assets from memory
	public static dynamic function clearUnusedMemory() {
		for (key => asset in cachedAssets) {
			if (localTrackedAssets.contains(key) || dumpExclusions.contains(key)) continue;	
			destroyAsset(key, asset);
		}

		System.gc();
	}

	// clear all except specific assets from memory
	public static dynamic function clearExcept(assets:Array<String>) {
		localTrackedAssets = assets;
		clearUnusedMemory();
	}

	// clear all assets from memory
	public static dynamic function clearStoredMemory() {
		for (key => asset in cachedAssets) {
			if (dumpExclusions.contains(key)) continue;
			destroyAsset(key, asset);
		}

		localTrackedAssets = [];
		System.gc();
	}

	public static function getCacheKey(key:String, type:String, ?subFolder:String) {
		return type + ((subFolder != null && subFolder.length != 0) ? '$subFolder/$key' : key);
	}

	public static function get(path:String, ?subFolder:String, ?overrideAddons:Bool = false):String {
		if (subFolder != null && subFolder.length != 0) path = '$subFolder/$path';

		#if ADDONS_ALLOWED
		// start by checking the current addon
		var mainDirectory:String = Addons.current;
		var finalPath:Void -> String = () -> return '$mainDirectory/$path';
		
		// will ignore addons entirely and just use the path given from assets instead if it exists
		if (overrideAddons) {
			if (FileSystem.exists('assets/$path')) return 'assets/$path';
		}

		// if the file doesn't exist in the current played addon
		if (FileSystem.exists(finalPath())) return finalPath();

		// run through the other addons
		if (Addons.list.length > 0) {
			for (addon in Addons.list) {
				if (addon.disabled) continue;

				mainDirectory = 'addons/${addon.id}';
				if (FileSystem.exists(finalPath())) return finalPath();
			}
		}
		#end

		// if that doesn't exist there OneOfTwo just return assets
		return 'assets/$path';
	}

	// images
	public static dynamic function image(key:String, ?subFolder:String = 'images', ?pushToGPU:Null<Bool>):FlxGraphic {

		if (pushToGPU == null)
			pushToGPU = Settings.data.gpuCache;

		if (key.lastIndexOf('.') < 0) key += '.$IMAGE_EXT';
		
		final cacheKey = getCacheKey(key, "IMG", subFolder);

		if (cachedAssets.exists(cacheKey)) return cachedAssets.get(cacheKey);
		
		key = get(key, subFolder, true);
		
		if (!FileSystem.exists(key)) return null;
		if (!localTrackedAssets.contains(cacheKey)) localTrackedAssets.push(cacheKey);

		return cacheBitmap(key, cacheKey, pushToGPU);
	}

	public static dynamic function imageAsync(key:String, ?subFolder:String = 'images', ?pushToGPU:Null<Bool>):Future<FlxGraphic>
	{
		if (pushToGPU == null)
			pushToGPU = Settings.data.gpuCache;

		final future:Future<FlxGraphic> = new Future<FlxGraphic>(()->{
			// Force gpu cache to be off since uploading textures to gpu isn't thread safe. (-Bolo)
			return image(key, subFolder, false);
		}, true);

		final graphicPromise:Promise<FlxGraphic> = new Promise<FlxGraphic>();

		future.onComplete((graphic:FlxGraphic)->{
				// At this point we are on the main thread context again.
				if (pushToGPU)
				{
					var bitmapData:BitmapData = graphic.bitmap;

					@:privateAccess
					if (bitmapData != null && FlxG.stage.context3D != null)
					{
						bitmapData.lock();
						bitmapData.getTexture(FlxG.stage.context3D);
						bitmapData.getSurface();

						bitmapData.readable = true;
						bitmapData.image = null;
					}
				}

				graphicPromise.complete(graphic);
			}
		);

		return graphicPromise.future;
	}

	public static dynamic function cacheBitmap(key:String, cacheKey:String, ?pushToGPU:Bool = false):FlxGraphic {
		//bitmap.disposeImage();

		final bitmapO:BitmapData = funkin.backend.OptimizedBitmapData.fromFile(key, pushToGPU);
		final graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmapO, false, cacheKey);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		cachedAssets.set(cacheKey, graph);
		
		return graph;
	}

	public static function exists(path:String):Bool {
		return FileSystem.exists(get(path));
	}

	public static function isDirectory(path:String):Bool {
		return FileSystem.isDirectory(get(path));
	}

	public static function readDirectory(path:String):Array<String> {
		var list:Array<String> = [];

		var directories:Array<String> = ['assets'];
		for (addon in Addons.list) {
			if (!addon.disabled)
				directories.push('addons/${addon.id}');
		}

		for (directory in directories) {
			if (!FileSystem.exists('$directory/$path')) continue;
			for (file in FileSystem.readDirectory('$directory/$path')) list.push(file);
		}

		return list;
	}

	// basically sys.io.File.getContent() but a failsafe if the file doesn't exist
	public static function getFileContent(path:String):String {
		path = get(path);
		if (!FileSystem.exists(path)) return '';

		return File.getContent(path);
	}

	// now we will return a string
	public static function audioPath(key:String, ?subFolder:String):String {
		if (key.lastIndexOf('.') < 0) key += '.$SOUND_EXT';
		return get(key, subFolder);
	}

	public static dynamic function audio(key:String, ?subFolder:String, ?beepIfNull:Bool = true):Sound {
		final cacheKey = getCacheKey(key, "SND", subFolder);
		if (cachedAssets.exists(cacheKey)) return cachedAssets.get(cacheKey);

		key = audioPath(key, subFolder);

		var file:Sound = null;

		if (!FileSystem.exists(key)) {
			if (beepIfNull) file = flixel.system.FlxAssets.getSound('flixel/sounds/beep');
			Sys.println('could not find sound file: $key');
		} else {
			if (!localTrackedAssets.contains(cacheKey)) localTrackedAssets.push(cacheKey);

			file = Sound.fromFile(key);
			cachedAssets.set(cacheKey, file);
		}

		return file;
	}

	public static dynamic function font(path:String, ?subFolder:String = 'fonts'):String {
		return get(path, subFolder);
	}

	public static dynamic function text(path:String, ?subFolder:String = 'data'):String {
		return get(path, subFolder);
	}

	public static dynamic function video(path:String, ?subFolder:String = 'videos'):String {
		if (path.lastIndexOf('.') < 0) path += '.$VIDEO_EXT';
		return get(path, subFolder);
	}

	public static dynamic function animateAtlas(path:String, ?subFolder:String = 'images'):FlxAnimateFrames {
		final cacheKey = getCacheKey(path, "ANI", subFolder);
		if (cachedAssets.exists(cacheKey)) return cachedAssets.get(cacheKey);

		final folder:String = get(path, subFolder, true);
		if (!FileSystem.exists(folder)) return null;
		if (!localTrackedAssets.contains(cacheKey)) localTrackedAssets.push(cacheKey);

		final frames = FlxAnimateFrames.fromAnimate(folder);
		frames.parent.persist = true;
		cachedAssets.set(cacheKey, frames);
		return frames;
	}

	// we don't want to overcombine.
	static function combineAtlas(atlasA:FlxAtlasFrames, atlasB:FlxAtlasFrames):FlxAtlasFrames {
		if (atlasA is FlxAnimateFrames) {
			@:privateAccess if (atlasB is FlxAnimateFrames && cast (atlasA, FlxAnimateFrames).addedCollections.contains(cast atlasB))
				return atlasA;
			return atlasA.addAtlas(atlasB, false);
		}

		@:privateAccess if (atlasA is FlxAnimateFrames && cast (atlasB, FlxAnimateFrames).addedCollections.contains(cast atlasA))
			return atlasB;
		return atlasB.addAtlas(atlasA, false);
	}

	public static dynamic function multiAtlas(keys:Array<String>, ?subFolder:String = 'images'):Dynamic {
		function getFrames(key:String, subFolder:String):OneOfTwo<FlxAtlasFrames, FlxAnimateFrames> {
			var frames:OneOfTwo<FlxAtlasFrames, FlxAnimateFrames> = null;
			if (Paths.exists('$subFolder/$key/Animation.json')) frames = cast animateAtlas(key, subFolder);
			else frames = cast sparrowAtlas(key, subFolder);

			return frames;
		}

		var parentFrames = cast getFrames(keys[0], subFolder);
		if (keys.length == 1) return parentFrames;

		if (parentFrames == null) return null;

		for (i in 1...keys.length) {
			var extraFrames = cast getFrames(keys[i], subFolder);
			if (extraFrames == null) continue;
			parentFrames = combineAtlas(parentFrames, extraFrames);
		}
		
		return parentFrames;
	}

	public static dynamic function sparrowAtlas(path:String, ?subFolder:String = 'images'):FlxFramesCollection {
		final cacheKey = getCacheKey(path, "SPR", subFolder);
		if (cachedAssets.exists(cacheKey)) return cachedAssets.get(cacheKey);

		final dataFile:String = get('$path.xml', subFolder, true);
		if (!FileSystem.exists(dataFile)) return null;
		if (!localTrackedAssets.contains(cacheKey)) localTrackedAssets.push(cacheKey);

		cachedAssets.set(cacheKey, FlxAtlasFrames.fromSparrow(image(path, subFolder), File.getContent(dataFile)));
		return cachedAssets.get(cacheKey);
		// return FlxAtlasFrames.fromSparrow(image(path, subFolder), File.getContent(dataFile));
	}

	public static dynamic function packerAtlas(path:String, ?subFolder:String = 'images'):FlxFramesCollection {
		final cacheKey = getCacheKey(path, "PAK", subFolder);
		if (cachedAssets.exists(cacheKey)) return cachedAssets.get(cacheKey);

		final dataFile:String = get('$path.txt', subFolder, true);
		if (!FileSystem.exists(dataFile)) return null;
		if (!localTrackedAssets.contains(cacheKey)) localTrackedAssets.push(cacheKey);

		cachedAssets.set(cacheKey, FlxAtlasFrames.fromSpriteSheetPacker(image(path, subFolder), File.getContent(dataFile)));
		return cachedAssets.get(cacheKey);
		// return FlxAtlasFrames.fromSpriteSheetPacker(image(path, subFolder), File.getContent(dataFile));
	}

	public static dynamic function asepriteAtlas(path:String, ?subFolder:String = 'images'):FlxFramesCollection {
		final cacheKey = getCacheKey(path, "ASE", subFolder);
		if (cachedAssets.exists(cacheKey)) return cachedAssets.get(cacheKey);

		final dataFile:String = get('$path.json', subFolder, true);
		if (!FileSystem.exists(dataFile)) return null;
		if (!localTrackedAssets.contains(cacheKey)) localTrackedAssets.push(cacheKey);

		cachedAssets.set(cacheKey, FlxAtlasFrames.fromTexturePackerJson(image(path, subFolder), File.getContent(dataFile)));
		return cachedAssets.get(cacheKey);
		// return FlxAtlasFrames.fromTexturePackerJson(image(path, subFolder), File.getContent(dataFile));
	}
}