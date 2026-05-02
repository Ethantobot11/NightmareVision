package mobile;

import haxe.Json;
import haxe.io.Path;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import mobile.MobileConfig.ButtonsModes;
import mobile.MobileConfig.MobileButtonsData;
import mobile.MobileConfig.CustomHitboxData;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

class Util {
	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function setupMaps(folder:String, map:Dynamic, mode:ButtonsModes)
    {
    folder = folder.contains(':') ? folder.split(':')[1] : folder;
    
    // DEBUG: See where the game is actually looking
    trace('Checking folder: ' + folder);

    #if mobile_controls_file_support 
    if (FileSystem.exists(folder)) 
    #end
    {
        var files = readDirectory(folder);
        trace('Found ' + files.length + ' files in ' + folder);

        for (file in files)
        {
            if (Path.extension(file) == 'json')
            {
                var fullPath = Path.join([folder, Path.withoutDirectory(file)]);
                var str:String = "";

                #if mobile_controls_file_support
                if (FileSystem.exists(fullPath))
                    str = File.getContent(fullPath);
                else 
                #end
                    str = Assets.getText(fullPath);

                // Safety: Don't parse if the file was empty or missing
                if (str == null || str.trim() == "") {
                    trace('Warning: File ' + fullPath + ' is empty, skipping.');
                    continue;
                }

                var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
                trace('Successfully loading JSON key: ' + mapKey + ' for mode: ' + mode);

                if (mode == HITBOX) {
                    var json:CustomHitboxData = cast Json.parse(str);
                    map.set(mapKey, json);
                }
                else if (mode == ACTION || mode == DPAD) {
                    var json:MobileButtonsData = cast Json.parse(str);
                    map.set(mapKey, json);
                }
            }
        }
    }
    #if mobile_controls_file_support
    else {
        trace('ERROR: Folder ' + folder + ' does not exist on disk.');
    }
    #end
    }

	inline public static function readDirectory(directory:String):Array<String>
	{
		var dirs:Array<String> = [];

		#if mobile_controls_file_support
		return FileSystem.readDirectory(directory);
		#else
		var dirs:Array<String> = [];
		for(dir in Assets.list().filter(folder -> folder.startsWith(directory)))
		{
			@:privateAccess
			for(library in lime.utils.Assets.libraries.keys())
			{
				if(library != 'default' && Assets.exists('$library:$dir') && (!dirs.contains('$library:$dir') || !dirs.contains(dir)))
					dirs.push('$library:$dir');
				else if(Assets.exists(dir) && !dirs.contains(dir))
					dirs.push(dir);
			}
		}
		return dirs;
		#end
	}
}