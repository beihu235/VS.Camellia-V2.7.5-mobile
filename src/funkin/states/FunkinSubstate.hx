package funkin.states;

import funkin.backend.FlxAudioHandler;
import flixel.FlxSubState;
import openfl.Lib;

//仅仅添加移动端控件
class FunkinSubstate extends FlxSubState {
	public static var instance:FunkinSubstate;
		
	override function create() {
		instance = this;	
		super.create();

		Controls.isInSubstate = true;
	}

	public var virtualPad:FlxVirtualPad;
	public var mobileControls:MobileControls;
	public var camControls:FlxCamera;
	public var vpadCam:FlxCamera;

	public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
	{
		virtualPad = new FlxVirtualPad(DPad, Action);
		virtualPad.alpha = Settings.data.controlsAlpha + 0.000001;
		add(virtualPad);
		#if desktop
		if (!Settings.data.needMobileControl)
		{
			virtualPad.alpha = 0;
			virtualPad.active = virtualPad.visible = false;
		}
		#end
	}

	public function removeVirtualPad()
	{
		if (virtualPad != null)
			remove(virtualPad);
	}

	public function addMobileControls(DefaultDrawTarget:Bool = true):Void
	{
		mobileControls = new MobileControls();

		var stage = Lib.current.stage;
		var scale:Float = Math.min((stage.stageWidth / FlxG.width), (stage.stageHeight / FlxG.height));
		var newWidth:Int = Std.int(stage.stageWidth / scale);
		var newHeight:Int = Std.int(stage.stageHeight / scale);

		camControls = new FlxCamera(0, 0, newWidth, newHeight);

		camControls.x = (FlxG.width - newWidth) / 2;
		camControls.y = (FlxG.height - newHeight) / 2;
		camControls.bgColor.alpha = 0;
		FlxG.cameras.add(camControls, DefaultDrawTarget);

		mobileControls.cameras = [camControls];
		mobileControls.alpha = Settings.data.playControlsAlpha + 0.000001;
		add(mobileControls);
		#if desktop
		if (!Settings.data.needMobileControl)
		{
			mobileControls.alpha = 0;
			mobileControls.active = mobileControls.visible = false;
		}
		#end
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
	}

	public function androidBack():Bool {
		#if android if (FlxG.android.justReleased.BACK) return true; #end
		 return false;
	}

	public function addVirtualPadCamera(DefaultDrawTarget:Bool = true):Void
	{
		if (virtualPad != null)
		{
			vpadCam = new FlxCamera();
			vpadCam.bgColor.alpha = 0;
			FlxG.cameras.add(vpadCam, DefaultDrawTarget);
			virtualPad.cameras = [vpadCam];
		}
	}

	override function destroy()
	{
		super.destroy();

		if (virtualPad != null)
		{
			virtualPad = FlxDestroyUtil.destroy(virtualPad);
			virtualPad = null;
		}

		if (mobileControls != null)
		{
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
			mobileControls = null;
		}
	}

	override function close() {
		super.close();
		Controls.isInSubstate = false;
	}
}
