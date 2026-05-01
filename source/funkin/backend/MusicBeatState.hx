package funkin.backend;

import funkin.scripting.PluginsManager;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.math.FlxMath;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import funkin.backend.BaseTransitionState;
import funkin.states.transitions.SwipeTransition;
import funkin.data.*;
import funkin.scripts.*;
import funkin.input.Controls;

import mobile.backend.MobileControlManager; 

class MusicBeatState extends FlxUIState
{
    // --- MOBILE PORT OVERRIDES START ---
    public var mobileManager:MobileControlManager;

    public function getMobilePadButton(name:String) {
        return mobileManager?.mobilePad?.getButton(name);
    }
    public function mobilePadJustPressed(buttons:Dynamic):Bool {
        return mobileManager?.mobilePad?.justPressed(buttons);
    }
    public function mobilePadPressed(buttons:Dynamic):Bool {
        return mobileManager?.mobilePad?.pressed(buttons);
    }
    public function mobilePadJustReleased(buttons:Dynamic):Bool {
        return mobileManager?.mobilePad?.justReleased(buttons);
    }
    public function mobilePadReleased(buttons:Dynamic):Bool {
        return mobileManager?.mobilePad?.released(buttons);
    }
    public function addMobilePad(DPad:String, Action:String) {
        mobileManager.addMobilePad(DPad, Action);
    }
    public function removeMobilePad() {
        mobileManager.removeMobilePad();
    }
    public function addHitbox(?mode:String, ?hints:Bool):Void {
        mobileManager.addHitbox(mode, hints);
    }
    public function removeHitbox() {
        mobileManager.removeHitbox();
    }
    public function addHitboxCamera(defaultDrawTarget:Bool = false):Void {
        mobileManager.addHitboxCamera(defaultDrawTarget);
    }
    public function addMobilePadCamera(defaultDrawTarget:Bool = false):Void {
        mobileManager.addMobilePadCamera(defaultDrawTarget);
    }
    // --- MOBILE PORT OVERRIDES END ---

    static final _defaultTransState:Class<BaseTransitionState> = SwipeTransition;
    public static var transitionInState:Null<Class<BaseTransitionState>> = null;
    public static var transitionOutState:Null<Class<BaseTransitionState>> = null;

    private var stepsToDo:Int = 0;
    public var curSection:Int = 0;
    public var curStep:Int = 0;
    public var curBeat:Int = 0;
    private var curDecStep:Float = 0;
    private var curDecBeat:Float = 0;
    private var controls(get, never):Controls;

    public var scripted:Bool = false;
    public var scriptName:String = '';
    public var scriptGroup:ScriptGroup = new ScriptGroup();

    inline function get_controls():Controls return Controls.instance;

    public function new() {
        super();
        // Initialize the mobile manager here
        mobileManager = new MobileControlManager(this);
    }

    override function create() {
        super.create();
        if (!FlxTransitionableState.skipNextTransOut) {
            openSubState(Type.createInstance(transitionOutState ?? _defaultTransState, [TransitionStatus.OUT]));
        }
        FlxTransitionableState.skipNextTransOut = false;
        PluginsManager.callOnScripts('onStateCreate');
    }

    override function update(elapsed:Float) {
        final oldStep:Int = curStep;
        updateCurStep();
        updateBeat();

        if (oldStep != curStep) {
            if (curStep > 0) stepHit();
            // Note: Ensure PlayState exists in your engine's scope
            if (curStep > oldStep) updateSection();
        }

        scriptGroup.call('onUpdate', [elapsed]);
        PluginsManager.callOnScripts('onUpdate', [elapsed]);
        super.update(elapsed);
    }

    private function updateCurStep():Void {
        // Conductor logic varies by engine; ensure Conductor.songPosition exists
        var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
        var stepOffset:Float = (((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrotchet);
        curStep = Math.floor(curDecStep = (lastChange.stepTime + stepOffset));
    }

    private function updateBeat():Void {
        curBeat = Math.floor(curStep / 4);
        curDecBeat = curDecStep / 4;
    }

    private function updateSection():Void {
        // Simple FNF section logic
        if (stepsToDo < 1) stepsToDo = 16; 
        while (curStep >= stepsToDo) {
            curSection++;
            stepsToDo += 16;
            sectionHit();
        }
    }

    public function stepHit():Void {
        if (curStep % 4 == 0) beatHit();
        scriptGroup.call('onStepHit', []);
        PluginsManager.callOnScripts('onStepHit');
    }

    public function beatHit():Void {
        scriptGroup.call('onBeatHit', []);
        PluginsManager.callOnScripts('onBeatHit');
    }

    public function sectionHit():Void {
        scriptGroup.call('onSectionHit', []);
        PluginsManager.callOnScripts('onSectionHit');
    }

    override function destroy() {
        scriptGroup.call('onDestroy');
        scriptGroup = FlxDestroyUtil.destroy(scriptGroup);
        
        // Clean up mobile manager to prevent memory leaks
        if (mobileManager != null) mobileManager.destroy();
        
        super.destroy();
    }

    override function closeSubState() {
        scriptGroup.call('onCloseSubState', []);
        super.closeSubState();
    }
}