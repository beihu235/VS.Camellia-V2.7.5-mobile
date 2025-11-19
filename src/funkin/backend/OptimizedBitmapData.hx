package funkin.backend;

import flixel.FlxG;
import lime.graphics.Image;
import lime.graphics.cairo.CairoImageSurface;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class OptimizedBitmapData extends BitmapData {
	@SuppressWarnings("checkstyle:Dynamic")
	@:noCompletion private override function __fromImage(image:#if lime Image #else Dynamic #end):Void
	{
		#if lime
		if (image != null && image.buffer != null)
		{
			this.image = image;

			width = image.width;
			height = image.height;
			rect = new Rectangle(0, 0, image.width, image.height);

			__textureWidth = width;
			__textureHeight = height;

			#if sys
			image.format = BGRA32;
			image.premultiplied = true;
			#end

			__isValid = true;
			readable = true;

			if (FlxG.stage.context3D != null){
				lock();
				getTexture(FlxG.stage.context3D);
				getSurface();

				readable = true;
				this.image = null;

				// @:privateAccess
				// if (FlxG.bitmap.__doNotDelete)
				// 	MemoryUtil.clearMinor();
			}
		}
		#end
	}

	@SuppressWarnings("checkstyle:Dynamic")
	@:dox(hide) public override function getSurface():#if lime CairoImageSurface #else Dynamic #end
	{
		#if lime
		if (__surface == null)
		{
			__surface = CairoImageSurface.fromImage(image);
		}

		return __surface;
		#else
		return null;
		#end
	}

	/**
		Creates a new BitmapData from a file path synchronously. This means that the
		BitmapData will be returned immediately (if supported).

		HTML5 and Flash do not support creating BitmapData synchronously, so these targets
		always return `null`.

		In order to load files from a remote web address, use the `loadFromFile` method,
		which supports asynchronous loading.

		@param	path	A local file path containing an image
		@returns	A new BitmapData if successful, or `null` if unsuccessful
	**/
	public static function fromFile(path:String, pushToGPU:Bool = true):BitmapData
	{
		#if (js && html5)
		return null;
		#else
		var bitmapData:BitmapData = null;
		if(pushToGPU){ //btw we will need to change this if we ever dare to use flixel ui
			bitmapData = new OptimizedBitmapData(0, 0, true, 0);
		} else {
			bitmapData = new BitmapData(0, 0, true, 0);
		}
		bitmapData.__fromFile(path);
		return bitmapData;
		#end
	}
}