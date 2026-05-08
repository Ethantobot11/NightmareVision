package mobile.hscript;

import lime.ui.Haptic;
import flixel.FlxG;
import funkin.scripts.FunkinScript; // Adjust this based on Nightmare's actual HScript class name

class MobileHScript 
{
    public static function implement(script:FunkinScript)
    {
        // JoyStick Functions
        script.set('addJoyStick', function(?managerName:String, x:Float = 0, y:Float = 0, ?graphic:String, size:Float = 1) {
            var manager = PlayState.checkManager(managerName);
            manager.addJoyStick(x, y, graphic, null, size);
        });

        script.set('joyStickPressed', function(?managerName:String, ?pos:String):Bool {
            return PlayState.checkManager(managerName).joyStick.pressed(pos);
        });

        // Hitbox Functions
        script.set('addHitbox', function(?managerName:String, ?mode:String, ?hints:Bool) {
            var manager = PlayState.checkManager(managerName);
            manager.addHitbox(mode, hints);
        });

        // MobilePad Functions
        script.set('addMobilePad', function(?managerName:String, dpad:String, action:String) {
            var manager = PlayState.checkManager(managerName);
            manager.addMobilePad(dpad, action);
        });

        // Haptics & Touch
        #if mobile
        script.set('vibrate', function(duration:Int, ?period:Int = 0) {
            Haptic.vibrate(period, duration);
        });

        script.set('touchPressedObject', function(objName:String):Bool {
            var obj = PlayState.instance.variables.get(objName); // Nightmare uses a variables map
            if (obj != null) return ScreenUtil.touch.overlaps(obj) && ScreenUtil.touch.pressed;
            return false;
        });
        #end
        
        // Android Specifics
        #if android
        script.set('backJustPressed', function() return FlxG.android.justPressed.BACK);
        #end
    }
}