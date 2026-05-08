package funkin.scripting;

import funkin.backend.FallbackState;
import flixel.FlxObject;

@:nullSafety
class ScriptedSubstate extends funkin.backend.MusicBeatSubstate
{
    public static var instance:Null<ScriptedSubstate> = null;

	public function new(scriptName:String)
	{
		super();
		
		initStateScript(scriptName, false);
		scriptGroup.parent = this;
		scriptGroup.call('onLoad');
	}
	
	override function create()
	{
		super.create();
		
		if (!scripted)
		{
			FlxG.switchState(() -> new FallbackState('failed to load ($scriptName)!\nDoes it exist?', () -> FlxG.switchState(MainMenuState.new)));
			return;
		}
		
		scriptGroup.call('onCreate');
	}
    public static function insertObject(?pos:Int = -1, tagObject:FlxObject)
    {
    if (instance != null && tagObject != null)
    {
        // Null Safety fix: ensure pos is treated as a non-nullable Int
        var position:Int = (pos == null) ? -1 : pos;

        if (position < 0) 
            instance.add(tagObject);
        else 
            instance.insert(position, tagObject);
            
        return true;
    }
    return false;
    }
}
