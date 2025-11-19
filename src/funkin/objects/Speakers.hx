package funkin.objects;

class Speakers extends FlxSprite {
	private var rY:Float = 580;

    public function new(x:Float, y:Float, onTheRight:Bool, ?hasGF:Bool = false) {
        super(x, y);

        frames = Paths.sparrowAtlas('stages/concert/${hasGF ? 'gf-sidespeaker' : "speaker"}');
        animation.addByPrefix("boop", "speaker", 24);
        setGraphicSize(Std.int(this.width * 0.75));

        this.flipX = !onTheRight;

        this.reflectionAlpha = Settings.data.reflections ? 0.25 : 0;
    }

    public var reflectionAlpha:Float = 0.0;
	//public var isVisible(get, never):Bool;
	
	//inline function get_isVisible() return visible && alpha > 0;
	
	//this function fixes flickering when the character is at the edge of the screen
	/*override function isOnScreen(?camera:FlxCamera){
		for (c in cameras)
			if (c.visible && c.exists && super.isOnScreen(c)) return true;
		return false;
			//return cameras.any(c -> c.visible && c.exists /*&& super.isOnScreen(c));
	}*/ //if we won't make any camera movement like crazy, this check isn't needed
	
	//var visibleOnScreen:Bool = false;
	
	override function draw() {
		// Update visibility status for all cameras
		//visibleOnScreen = isOnScreen();
	
		// Handle reflection drawing if enabled
		if (reflectionAlpha > 0 /*&& isVisible*/)
			drawReflection();
	
		// Draw the character again but normally
		super.draw();
	}
	
	// Save original properties
	var originalAlpha:Float;
	//var originalScaleY:Float;
	private function drawReflection() {
		// Save original properties
		originalAlpha = alpha;
		//originalScaleY = scale.y;	
		// Apply reflection transformations
		alpha *= reflectionAlpha;
		//scale.y = -scale.y;
		//let's see if flipY works better
		flipY = !flipY;
	
		//x += reflectionPosArray[0];
		y += rY;
	
		// Draw the reflection
		super.draw();
	
		// Restore original properties
		//x -= reflectionPosArray[0];
		y -= rY;
		//scale.y = originalScaleY;
		flipY = !flipY; //yup it does, we keep it
		alpha = originalAlpha;
	}

    public function boop(){
        animation.play("boop"); //at the moment it will stay like this until we figure out a solution
    }
}