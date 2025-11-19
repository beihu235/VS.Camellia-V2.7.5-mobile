package funkin.modchart.mods;

class PlayfieldTransform extends BaseModifier {
    public function new(parent:ModchartManager) {
        super(parent);
        priority = 999;
    }

    override public function modifiesVertex(strumline:Int) {return true;}

	// should we change these to work like nITG?? We'll keep it as degrees for now but
	// maybe we should add a mod to make these act like ITG rotations (similar to how stealthtype exists in nITG and pathtype exists here)

    override public function adjustVertex(spr:FunkinSprite, vertex:Vector3, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        vertex.x += getValue(X_INDEX, strumline) - FlxG.width * 0.5;
        vertex.y += getValue(Y_INDEX, strumline) - FlxG.height * 0.5;
        vertex.z += getValue(Z_INDEX, strumline);

        //Sys.print(spr + " | ");
        vertex.rotate(getValue(PITCH_INDEX, strumline), getValue(YAW_INDEX, strumline), getValue(ROLL_INDEX, strumline));

        vertex.x += FlxG.width * 0.5;
        vertex.y += FlxG.height * 0.5;

		// local pitch
		vertex.x -= field.centerX;
        vertex.y -= field.y;

		vertex.rotate(getValue(LOCAL_PITCH_INDEX, strumline), getValue(LOCAL_YAW_INDEX, strumline), getValue(LOCAL_ROLL_INDEX, strumline));

		vertex.x += field.centerX;
        vertex.y += field.y;	
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        // highest index + 4 if it's lane specific, + 1 if not.
        values.push([for (i in 0...(Z_INDEX + 1)) 0.0]);
    }


    public static inline var PITCH_INDEX:Int = 0;
    public static inline var YAW_INDEX:Int = 1;
    public static inline var ROLL_INDEX:Int = 2;

    public static inline var X_INDEX:Int = 3;
    public static inline var Y_INDEX:Int = 4;
    public static inline var Z_INDEX:Int = 5;

    public static inline var LOCAL_PITCH_INDEX:Int = 6;
    public static inline var LOCAL_YAW_INDEX:Int = 7;
    public static inline var LOCAL_ROLL_INDEX:Int = 8;

    public static function attachToRedirects() {
        ModchartManager.defaultRedirects.set("pitch", {toClass: PlayfieldTransform, index: PITCH_INDEX});
        ModchartManager.defaultRedirects.set("yaw", {toClass: PlayfieldTransform, index: YAW_INDEX});
        ModchartManager.defaultRedirects.set("roll", {toClass: PlayfieldTransform, index: ROLL_INDEX});

        ModchartManager.defaultRedirects.set("fieldx", {toClass: PlayfieldTransform, index: X_INDEX});
        ModchartManager.defaultRedirects.set("fieldy", {toClass: PlayfieldTransform, index: Y_INDEX});
        ModchartManager.defaultRedirects.set("fieldz", {toClass: PlayfieldTransform, index: Z_INDEX});

		ModchartManager.defaultRedirects.set("localpitch", {toClass: PlayfieldTransform, index: LOCAL_PITCH_INDEX});
        ModchartManager.defaultRedirects.set("localyaw", {toClass: PlayfieldTransform, index: LOCAL_YAW_INDEX});
        ModchartManager.defaultRedirects.set("localroll", {toClass: PlayfieldTransform, index: LOCAL_ROLL_INDEX});

		// aliases
        ModchartManager.defaultRedirects.set("fieldpitch", {toClass: PlayfieldTransform, index: PITCH_INDEX});
        ModchartManager.defaultRedirects.set("fieldyaw", {toClass: PlayfieldTransform, index: YAW_INDEX});
        ModchartManager.defaultRedirects.set("fieldroll", {toClass: PlayfieldTransform, index: ROLL_INDEX});

		ModchartManager.defaultRedirects.set("rotationx", {toClass: PlayfieldTransform, index: LOCAL_PITCH_INDEX});
        ModchartManager.defaultRedirects.set("rotationy", {toClass: PlayfieldTransform, index: LOCAL_YAW_INDEX});
        ModchartManager.defaultRedirects.set("rotationz", {toClass: PlayfieldTransform, index: LOCAL_ROLL_INDEX});
    }
}