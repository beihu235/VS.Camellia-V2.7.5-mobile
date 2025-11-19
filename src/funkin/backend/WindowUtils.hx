package funkin.backend;

import lime.ui.Window;

#if windows
@:cppFileCode('#
#include <Windows.h>
#include <windowsx.h>
#include <cstdio>
#include <iostream>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <winternl.h>
#include <Shlobj.h>
#include <commctrl.h>
#include <string>

#define UNICODE

#pragma comment(lib, "Dwmapi")
#pragma comment(lib, "ntdll.lib")
#pragma comment(lib, "User32.lib")
#pragma comment(lib, "Shell32.lib")
#pragma comment(lib, "gdi32.lib")
')
#end
class WindowUtils {

	#if windows
	@:functionCode('
	HWND window = GetActiveWindow();

	auto color = RGB(r, g, b);

	if (S_OK != DwmSetWindowAttribute(window, 35, &color, sizeof(COLORREF))) {
		DwmSetWindowAttribute(window, 35, &color, sizeof(COLORREF));
	}

	if (S_OK != DwmSetWindowAttribute(window, 34, &color, sizeof(COLORREF))) {
		DwmSetWindowAttribute(window, 34, &color, sizeof(COLORREF));
	}

	UpdateWindow(window);
	')
	#end
	public static function changeWindowColor(r:Int=0xff, g:Int=0xff, b:Int=0xff){}


	//yeah, fuck it, now it's based on chroma :fire:
	#if windows
	@:functionCode('
	HWND hWnd = GetActiveWindow();
	res = SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) | WS_EX_LAYERED);
	if (res)
	{
		SetLayeredWindowAttributes(hWnd, RGB(r, g, b), active?1:0, LWA_COLORKEY);
	}
	')
	#end
	public static function transparentWindow(active:Bool = true, r:Int=1, g:Int=1, b:Int=1, ?res:Int = 0){}

	/**
	 * set the opacity of the window between 0 and 255
	 */
	 #if windows
	@:functionCode('
	HWND hWnd = GetActiveWindow();

	if (SetLayeredWindowAttributes != nullptr) {
		LONG_PTR style = GetWindowLongPtr(hWnd, GWL_EXSTYLE);
		SetWindowLongPtr(hWnd, GWL_EXSTYLE, style | WS_EX_LAYERED);

		SetLayeredWindowAttributes(hWnd, RGB(0, 0, 0), opacity, LWA_ALPHA);
	}
	')
	#end //the mac opacity thing will delay until i get inspiration to ever code in haxe or someone actually develops it here
	public static function setWindowOpacity(opacity:Int=255){}

	public static function setBorderlessWindow(hide:Bool){
		lime.app.Application.current.window.borderless = hide;
	}

	/*@:functionCode('
	SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
	')
	public static function setWallpaper(path:String){}

	@:functionCode('
	var path = new String(260);
		SystemParametersInfo(SPI_GETDESKWALLPAPER, 260, path, 0);
		return path;
	')
	public static function saveWallpaper(){}*/

		#if windows
	@:functionCode('
	HWND hWnd = GetActiveWindow();
	RECT rect;
	GetWindowRect(hWnd, &rect);
	int x, y;
	int width = rect.right - rect.left;
	int height = rect.bottom - rect.top;
	x = (GetSystemMetrics (SM_CXSCREEN) - width) / 2;
	y = (GetSystemMetrics (SM_CYSCREEN) - height) / 2;
	MoveWindow (hWnd, x, y, width, height, TRUE);
	')
	#end
	public static function centerWindow(){}

	#if windows
	@:functionCode('
	HWND hWnd = GetActiveWindow();
	x = (GetSystemMetrics (SM_CXSCREEN) - 1280) / 2;
	return x;
	')
	#end
	public static function getWindowCenterPosX(x:Int = 0){return x;}

	#if windows
	@:functionCode('
	HWND hWnd = GetActiveWindow();
	y = (GetSystemMetrics (SM_CYSCREEN) - 720) / 2;
	return y;
	')
	#end
	public static function getWindowCenterPosY(y:Int = 0){return y;}


	//this is to make this compile, like... it needs to be properly modified to fit the engine nicely
	static var windowPosX:Int = 0;
    static var windowPosY:Int = 0;
    static var wasFullscreen:Bool = false;
    static var wasMaximized:Bool = false;
    static var windowWidth:Int = 0;
    static var windowHeight:Int = 0;
	static var windowModchart:Bool = false;

	/**
     * this function will prepare the window for the modchart
     */
     public static function prepareWindowModchart(){
        windowModchart = true;
        //get the properties of the window before changing them
        windowPosX = WindowUtils.getWindowCenterPosX();
        windowPosY = WindowUtils.getWindowCenterPosY();
        wasFullscreen = lime.app.Application.current.window.fullscreen;
        wasMaximized = lime.app.Application.current.window.maximized;
        windowWidth = lime.app.Application.current.window.width;
        windowHeight = lime.app.Application.current.window.height;
        //set the new properties
        openfl.Lib.application.window.fullscreen = false;
        openfl.Lib.application.window.maximized = false;
        //openfl.Lib.application.window.resize(1280, 720);
        WindowUtils.centerWindow();
    }

    /**
     * this function will reset the window to the original position/size/fullscreen
     */
    public static function resetWindow(){
        openfl.Lib.application.window.x = windowPosX;
        openfl.Lib.application.window.y = windowPosY;
        openfl.Lib.application.window.resize(windowWidth, windowHeight);

        openfl.Lib.application.window.fullscreen = wasFullscreen;
        openfl.Lib.application.window.maximized = wasMaximized;
    }

    /**
    * WARNING: YOU NEED TO USE prepareWindowModchart() BEFORE USING THIS FUNCTION
    * 
    * this function will tween the window position
    * @param x the x position of the window
    * @param y the y position of the window
    * @param time the time it will take to tween
    * @param easing the easing function pls use a FlxEase like FlxEase.linear
    * 
    * note: for easier use, the function automatically uses the position based on the original window position
    */
    public static function windowPosTween(x:Float, y:Float, time:Float = 1, ?easing:Float->Float){
        FlxTween.cancelTweensOf(lime.app.Application.current.window);
        FlxTween.tween(lime.app.Application.current.window, {x:x + windowPosX, y:y + windowPosY}, time, {ease:easing});
    }

    /**
     * WARNING: YOU NEED TO USE prepareWindowModchart() BEFORE USING THIS FUNCTION
     * 
     * this function will tween the window size
     * @param width the width of the window
     * @param height the height of the window
     * @param time the time it will take to tween
     * @param easing the easing function pls use a FlxEase like FlxEase.linear
     */
    public static function windowSizeTween(width:Float, height:Float, time:Float = 1, ?easing:Float->Float){
        FlxTween.cancelTweensOf(lime.app.Application.current.window);
        FlxTween.tween(lime.app.Application.current.window, {width:width, height:height}, time, {ease:easing});
    }
}