package funkin.objects;

import flixel.graphics.FlxGraphic;
import lime.app.Future;
import openfl.system.System;

/**
 * Helper Sprite that fades to a next sprite once it's fully loaded in another thread
 * @author BoloVEVO
 * ripped from fnvx
 */
class FadingSprite extends FlxSpriteGroup
{
    public var curSprite:FlxSprite;
    public var nextSprite:FlxSprite;
    var canSwitch:Bool = true;
    var pending:Bool = false;
    var _pendingGraphic:String;
    var _pendingFinishCallback:Void->Void;
    var _pendingFadeCallback:Void->Void;
    var scaleX:Float = 1;
    var scaleY:Float = 1;
    var graphicSizeX:Int;
    var graphicSizeY:Int;

    public function new(x:Float,y:Float)
    {
        super(x,y);
        curSprite = new FlxSprite();
        curSprite.alpha = 0;
        nextSprite = new FlxSprite();
        nextSprite.alpha = 0;
        add(nextSprite);
        add(curSprite);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (!pending || _pendingGraphic == null)
            return;

        changeTo(_pendingGraphic, _pendingFinishCallback, _pendingFadeCallback);
    }

    public function changeTo(graphicPath:String, instant:Bool = false, ?onComplete:Void->Void, ?onFadeComplete:Void->Void)
    {
        if (instant)
        {
            curSprite.alpha = 1;
            nextSprite.alpha = 1;
            curSprite.loadGraphic(Paths.image(graphicPath));
            nextSprite.loadGraphic(Paths.image(graphicPath));

            if (onComplete != null)
                onComplete();

            if (onFadeComplete != null)
                onFadeComplete();

            nextSprite.graphic.persist = false;
            nextSprite.graphic.destroyOnNoUse = true;

            return;
        }

        if (!canSwitch)
        {
            _pendingGraphic = graphicPath;
            _pendingFinishCallback = onComplete;
            _pendingFadeCallback = onFadeComplete;
            pending = true;
            return;
        }

        _pendingGraphic = null;
        _pendingFinishCallback = null;
        _pendingFadeCallback = null;
           
        pending = false;
        canSwitch = false;

        Paths.imageAsync(graphicPath).onComplete((graph:FlxGraphic)->{
            new Future(()->System.gc(),true);
            fadeSprites(graph, onComplete, onFadeComplete);     
        });
    }

    private function fadeSprites(graph:FlxGraphic, ?onComplete:Void->Void, ?onFadeComplete:Void->Void)
    {
        if (graph == null)
            trace("GRAPHIC NULL???");
        nextSprite.loadGraphic(graph);
        
       
        FlxTween.tween(curSprite,{alpha:0},0.25,{ease:FlxEase.smoothStepOut, onComplete:(twn)->{
            canSwitch = true;
            curSprite.alpha = 1.0;
            var oldGraphic:String = curSprite.graphic.key;
            if (curSprite.graphic != graph)
                Paths.destroyAsset(oldGraphic);
            curSprite.loadGraphic(graph);

            new Future(()->System.gc(),true);
            if (onFadeComplete != null)
                onFadeComplete();
        }});
        if (onComplete != null)
            onComplete();

        graph.persist = false;
        graph.destroyOnNoUse = true;
    }

    public function setScale(x:Float, y:Float)
    {
        scaleX = x;
        scaleY = y;
        for (member in members)
        {
            member.scale.set(x,y);
        }
    }

    override function setGraphicSize(width:Float = 0, height:Float = 0)
    {
        curSprite.setGraphicSize(width,height);
        nextSprite.setGraphicSize(width,height);
    }

    override function updateHitbox()
    {
        for (member in this)
        {
            member.updateHitbox();
        }
    }

    override function destroy()
    {
        var curGraphic:FlxGraphic = curSprite.graphic;
        var nextGraphic:FlxGraphic = nextSprite.graphic;

        if (curGraphic != null)
            Paths.destroyAsset(curGraphic.key);

        if (nextGraphic != null)
            Paths.destroyAsset(nextGraphic.key);
        super.destroy();
    }
}