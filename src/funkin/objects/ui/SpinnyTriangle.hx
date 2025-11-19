package funkin.objects.ui;

import flixel.math.FlxRect;

class SpinnyTriangle extends FunkinSprite {
	var verts:Array<Vector3> = [for (i in 0...3) new Vector3()];
	var finalVerts:Array<Float> = [for (i in 0...8) 0.0];

	var region:FlxRect;
	var xSin:Float = Math.sin(-85 * 180 / Math.PI);
	var xCos:Float = Math.cos(-85 * 180 / Math.PI);

	override function initVars() {
		super.initVars();
		_angleChanged = true;
		region = FlxRect.get();

		makeGraphic(1, 1, 0xFFFFFFFF);
	}

	override function draw() {
		if (alpha <= 0)
			return;

		if (_angleChanged) {
			verts[0].set(0, -146.41, 0); // (sin(60) * 400) - 200, getting the height of an equallateral triangle.
			verts[1].set(-200, 200, 0);
			verts[2].set(200, 200, 0); 
			for (i in 0...3) {
				verts[i].y -= 70; /// UUUUUUUUUUGGGGGGGGHHHHHHHHH
				verts[i].rotate(-85, 0, angle);

				verts[i].x += FlxG.width * 0.5;
				verts[i].y += FlxG.height * 0.5;
				verts[i].project();
				verts[i].x -= FlxG.width * 0.5;
				verts[i].y -= FlxG.height * 0.5;
			}

			region.setPosition(Math.min(Math.min(verts[0].x, verts[1].x), verts[2].x), Math.min(Math.min(verts[0].y, verts[1].y), verts[2].y));
			region.right = Math.max(Math.max(verts[0].x, verts[1].x), verts[2].x);
			region.bottom = Math.max(Math.max(verts[0].y, verts[1].y), verts[2].y);
		}

		for (camera in cameras) {
			final camX = x - camera.scroll.x * scrollFactor.x - offset.x;
			final camY = y - camera.scroll.y * scrollFactor.y - offset.y;

			region.x += camX;
			region.y += camY;

			if (!camera.visible || !camera.exists || !camera.containsRect(region)) {
				region.x -= camX;
				region.y -= camY;
				continue;
			}

			finalVerts[0] = finalVerts[2] = verts[0].x + camX;
			finalVerts[1] = finalVerts[3] = verts[0].y + camY;
			finalVerts[4] = verts[1].x + camX;
			finalVerts[5] = verts[1].y + camY;
			finalVerts[6] = verts[2].x + camX;
			finalVerts[7] = verts[2].y + camY;

			camera.drawNoteVertices(_frame, finalVerts, colorTransform, blend, antialiasing, false, 0, colorTransform.alphaMultiplier);

			region.x -= camX;
			region.y -= camY;

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
}