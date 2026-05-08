package funkin.scripts;

import extensions.hscript.Sharables;
import extensions.hscript.IrisEx;

import crowplexus.iris.Iris;

import extensions.hscript.InterpEx;

import funkin.backend.plugins.DebugTextPlugin;
import funkin.objects.*;
import funkin.objects.note.*;
import mobile.hscript.MobileHScript;
import funkin.scripting.ScriptedSubstate;

@:access(crowplexus.iris.Iris)
@:access(funkin.states.PlayState)
class FunkinScript extends IrisEx implements IFlxDestroyable
{
	/**
	 * List of all accepted hscript extensions
	 */
	public static final H_EXTS:Array<String> = ['hx', 'hxs', 'hscript'];
	
	/**
	 * wrapper for `Paths.getPath` but attempts to append a supported hx extension to its path
	 * @param path 
	 * @return String
	 */
	public static function getPath(path:String):String
	{
		for (extension in H_EXTS)
		{
			final file = '$path.$extension';
			
			final targetPath = Paths.getPath(file, null, true);
			if (FunkinAssets.exists(targetPath)) return targetPath;
			if (FunkinAssets.exists(file)) return file;
		}
		return path;
	}
	
	/**
	 * Helper to check if a path ends with a support hx extension
	 */
	public static function isHxFile(path:String):Bool
	{
		for (extension in H_EXTS)
			if (path.endsWith(extension)) return true;
			
		return false;
	}
	
	/**
	 * Initiates the debugging backend of Iris
	 */
	public static function init()
	{
		inline function formatFileLoc(fileName:String, lineNumber:Int, x:String)
		{
			var tempName = '[$fileName:$lineNumber]';
			
			if (fileName.contains(Mods.currentModDirectory)) tempName = tempName.replace('content/${Mods.currentModDirectory}/', '');
			
			tempName += ' - $x';
			
			return tempName;
		}
		
		Iris.warn = (x, ?pos) -> {
			final output:String = formatFileLoc(pos.fileName, pos.lineNumber, x);
			
			DebugTextPlugin.addText(Std.string(output), Logger.getHexColourFromSeverity(WARN));
			
			Iris.logLevel(ERROR, x, pos);
		}
		
		Iris.error = (x, ?pos) -> {
			final output:String = formatFileLoc(pos.fileName, pos.lineNumber, x);
			
			DebugTextPlugin.addText(Std.string(output), Logger.getHexColourFromSeverity(ERROR));
			
			Iris.logLevel(NONE, x, pos);
		}
		
		Iris.print = (x, ?pos) -> {
			final output:String = formatFileLoc(pos.fileName, pos.lineNumber, x);
			
			DebugTextPlugin.addText(Std.string(output), Logger.getHexColourFromSeverity(PRINT));
			
			Iris.logLevel(NONE, x, pos);
		}
	}
	
	/**
	 * Creates a new `FunkinScript` from a string
	 * @param script 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?shareables:Sharables)
	{
		return new FunkinScript(script, name, additionalVars, shareables);
	}
	
	/**
	 * Creates a new `FunkinScript` from a filepath
	 * 
	 * @param file 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>, ?shareables:Sharables)
	{
		name ??= file;
		
		return new FunkinScript(FunkinAssets.getContent(file), name, additionalVars, shareables);
	}
	
	/**
	 * is true if parsing failed
	 */
	@:noCompletion public var __garbage:Bool = false;
	
	public function new(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?shareables:Sharables)
	{
		super(script, {name: name, autoRun: false, autoPreset: false}, shareables);
		
		(cast interp : InterpEx).parent = FlxG.state;
		// interp = new InterpEx(FlxG.state);
		
		preset();
		
		if (additionalVars != null)
		{
			for (key => obj in additionalVars)
				set(key, additionalVars.get(obj));
		}
		
		tryExecute();
	}
	
	/**
	 * safer parsing
	 */
	inline function tryExecute()
	{
		var ret:Dynamic = null;
		try
		{
			ret = execute();
		}
		catch (e)
		{
			__garbage = true;
			Logger.log('[${name}]: PARSING ERROR: $e', ERROR, true);
		}
		return ret;
	}
	
	// kept for notescript stuff
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		extraVars ??= [];
		
		if (exists(func))
		{
			var daFunc = get(func);
			if (Reflect.isFunction(daFunc))
			{
				var returnVal:Dynamic = null;
				var defaultShit:Map<String, Dynamic> = [];
				
				if (theObject != null) extraVars.set("this", theObject);
				
				for (key in extraVars.keys())
				{
					defaultShit.set(key, get(key));
					set(key, extraVars.get(key));
				}
				
				try
				{
					returnVal = Reflect.callMethod(theObject, daFunc, parameters ?? []);
				}
				catch (e:haxe.Exception)
				{
					#if sys
					Sys.println(e.message);
					#end
				}
				
				for (key in defaultShit.keys())
				{
					set(key, defaultShit.get(key));
				}
				
				return returnVal;
			}
		}
		return null;
	}
	
	@:inheritDoc
	override function preset()
	{
		super.preset();
		#if hl
		set('Math', hl.HLFixes.HLMath);
		set('Std', hl.HLFixes.HLStd);
		set("trace", Reflect.makeVarArgs(function(x:Array<Dynamic>) {
			var pos = this.interp != null ? this.interp.posInfos() : Iris.getDefaultPos(this.name);
			var v = x.shift();
			if (x.length > 0) pos.customParams = x;
			Iris.print(Std.string(v), pos);
		}));
		#end
		
		set("StringTools", StringTools);
		
		set("Type", Type);
		set("script", this);
		set("Dynamic", Dynamic);
		
		set('StringMap', haxe.ds.StringMap);
		set('IntMap', haxe.ds.IntMap);
		set('ObjectMap', haxe.ds.ObjectMap);
		
		set("Main", Main);
		set("Lib", openfl.Lib);
		set("Assets", lime.utils.Assets);
		set("OpenFlAssets", openfl.utils.Assets);
		
		set('curBpm', Conductor.bpm);
		set('crotchet', Conductor.crotchet);
		set('stepCrotchet', Conductor.stepCrotchet);
		set('Function_Halt', funkin.scripting.ScriptConstants.HALT_FUNC);
		set('Function_Stop', funkin.scripting.ScriptConstants.STOP_FUNC);
		set('Function_Continue', funkin.scripting.ScriptConstants.CONTINUE_FUNC);
		set('curBeat', 0);
		set('curStep', 0);
		set('curSection', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);
		set('version', Main.NMV_VERSION.trim());
		set('Defines', funkin.data.Defines);
		
		// set flixel related stuff
		set("FlxG", flixel.FlxG);
		set("FlxSprite", flixel.FlxSprite);
		set("FlxCamera", extensions.flixel.FlxCameraEx);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxSound", flixel.sound.FlxSound);
		set('FlxText', flixel.text.FlxText);
		set("FlxRuntimeShader", funkin.backend.FunkinShader.FunkinRuntimeShader);
		set("FlxFlicker", flixel.effects.FlxFlicker);
		set('FlxSpriteUtil', flixel.util.FlxSpriteUtil);
		set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		set("FlxTiledSprite", flixel.addons.display.FlxTiledSprite);
		set('FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
		
		set("FlxTypedGroup", flixel.group.FlxGroup);
		set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		set("FlxEmitter", flixel.effects.particles.FlxEmitter);
		
		set('FlxCameraFollowStyle', flixel.FlxCamera.FlxCameraFollowStyle);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);
		
		set("FlxAnimate", animate.FlxAnimate);
		set("FlxAnimateFrames", animate.FlxAnimateFrames);
		set("FlxSpriteElement", animate.internal.elements.FlxSpriteElement);
		
		set('Controls', funkin.input.Controls);
        //set('MobileControls', mobile.hscript.MobileHScript.implement);
        set('createNewMobileManager', function(name:String, ?keyDetectionAllowed:Bool):Void
		{
			PlayState.instance.createNewManager(name, keyDetectionAllowed);
		});
		set('getMobileManager', function(name:String)
		{
			return PlayState.instance.customManagers.get(name);
		});

		//JoyStick
		set('addJoyStick', function(?managerName:String, x:Float = 0, y:Float = 0, ?graphic:String, ?onMove:Float->Float->Float->String->Void, size:Float = 1, ?addToCustomSubstate:Bool = false, ?posAtCustomSubstate:Int = -1):Void
		{
			var manager = PlayState.checkManager(managerName);
			if (addToCustomSubstate)
			{
				manager.makeJoyStick(x, y, graphic, onMove, size);
				if (manager.joyStick != null)
					ScriptedSubstate.insertObject(posAtCustomSubstate, manager.joyStick);
			}
			else
				manager.addJoyStick(x, y, graphic, onMove, size);
			if(PlayState.instance.variables.exists(managerName + '_joyStick')) PlayState.instance.variables.set(managerName + '_joyStick', manager.joyStick);
		});

		set('addJoyStickCamera', function(?managerName:String, defaultDrawTarget:Bool = false):Void
		{
			PlayState.checkManager(managerName).addJoyStickCamera(defaultDrawTarget);
		});

		set('removeJoyStick', function(?managerName:String):Void
		{
			PlayState.checkManager(managerName).removeJoyStick();
		});

		set('joyStickPressed', function(?managerName:String, ?position:String):Bool
		{
			return PlayState.checkManager(managerName).joyStick.pressed(position);
		});

		set('joyStickJustPressed', function(?managerName:String, ?position:String):Bool
		{
			return PlayState.checkManager(managerName).joyStick.justPressed(position);
		});

		set('joyStickJustReleased', function(?managerName:String, ?position:String):Bool
		{
			return PlayState.checkManager(managerName).joyStick.justReleased(position);
		});

		//Hitbox
		set("addHitbox", function(?managerName:String, ?mode:String, ?hints:Bool, ?addToCustomSubstate:Bool = false, ?posAtCustomSubstate:Int = -1):Void
		{
			var manager = PlayState.checkManager(managerName);
			if (addToCustomSubstate)
			{
				manager.makeHitbox(mode, hints);
				if (manager.hitbox != null)
					ScriptedSubstate.insertObject(posAtCustomSubstate, manager.hitbox);
			}
			else
				manager.addHitbox(mode, hints);
			if(PlayState.instance.variables.exists(managerName + '_hitbox')) PlayState.instance.variables.set(managerName + '_hitbox', manager.hitbox);
		});

		set("addHitboxCamera", function(?managerName:String, defaultDrawTarget:Bool = false):Void
		{
			PlayState.checkManager(managerName).addHitboxCamera(defaultDrawTarget);
		});

		set("removeHitbox", function(?managerName:String):Void
		{
			PlayState.checkManager(managerName).removeHitbox();
		});

		set('hitboxPressed', function(?managerName:String, ?hint:String):Bool
		{
			return PlayState.checkHBoxPress(hint, 'pressed', managerName);
		});

		set('hitboxJustPressed', function(?managerName:String, ?hint:String):Bool
		{
			return PlayState.checkHBoxPress(hint, 'justPressed', managerName);
		});

		set('hitboxReleased', function(?managerName:String, ?hint:String):Bool
		{
			return PlayState.checkHBoxPress(hint, 'released', managerName);
		});

		set('hitboxJustReleased', function(?managerName:String, ?hint:String):Bool
		{
			return PlayState.checkHBoxPress(hint, 'justReleased', managerName);
		});

		//MobilePad
		set('addMobilePad', function(?managerName:String, DPad:String, Action:String, ?addToCustomSubstate:Bool = false, ?posAtCustomSubstate:Int = -1):Void
		{
			var manager = PlayState.checkManager(managerName);
			if (addToCustomSubstate)
			{
				manager.makeMobilePad(DPad, Action);
				if (manager.mobilePad != null)
					ScriptedSubstate.insertObject(posAtCustomSubstate, manager.mobilePad);
			}
			else
				manager.addMobilePad(DPad, Action);
			if(PlayState.instance.variables.exists(managerName + '_mobilePad')) PlayState.instance.variables.set(managerName + '_mobilePad', manager.mobilePad);
		});

		set('addMobilePadCamera', function(?managerName:String, defaultDrawTarget:Bool = false):Void
		{
			PlayState.checkManager(managerName).addMobilePadCamera(defaultDrawTarget);
		});

		set('removeMobilePad', function(?managerName:String):Void
		{
			PlayState.checkManager(managerName).removeMobilePad();
		});

		set('mobilePadPressed', function(?managerName:String, ?button:String):Bool
		{
			return PlayState.checkMPadPress(button, 'pressed', managerName);
		});

		set('mobilePadJustPressed', function(?managerName:String, ?button:String):Bool
		{
			return PlayState.checkMPadPress(button, 'justPressed', managerName);
		});

		set('mobilePadReleased', function(?managerName:String, ?button:String):Bool
		{
			return PlayState.checkMPadPress(button, 'released', managerName);
		});

		set('mobilePadJustReleased', function(?managerName:String, ?button:String):Bool
		{
			return PlayState.checkMPadPress(button, 'justReleased', managerName);
		});
		
		// abstracts
		set("FlxTextAlign", funkin.utils.MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		set('FlxAxes', funkin.utils.MacroUtil.buildAbstract(flixel.util.FlxAxes));
		set("FlxKey", funkin.utils.MacroUtil.buildAbstract(flixel.input.keyboard.FlxKey));
		set('BlendMode', funkin.utils.MacroUtil.buildAbstract(openfl.display.BlendMode));
		
		set("keyToString", (key:Int) -> {
			return flixel.input.keyboard.FlxKey.toStringMap.get(key);
		});
		set("keyFromString", (str:String) -> {
			return flixel.input.keyboard.FlxKey.fromStringMap.get(str);
		});
		
		// modchart related
		set("ModManager", funkin.game.modchart.ModManager);
		set("SubModifier", funkin.game.modchart.SubModifier);
		set("NoteModifier", funkin.game.modchart.NoteModifier);
		set("ScriptedModifier", funkin.game.modchart.ScriptedModifier);
		set("EventTimeline", funkin.game.modchart.EventTimeline);
		set("Modifier", funkin.game.modchart.Modifier);
		set("StepCallbackEvent", funkin.game.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.game.modchart.events.CallbackEvent);
		set("ModEvent", funkin.game.modchart.events.ModEvent);
		set("EaseEvent", funkin.game.modchart.events.EaseEvent);
		set("SetEvent", funkin.game.modchart.events.SetEvent);
		
		// FNF-specific things
		set("Paths", Paths);
		set("MusicBeatState", funkin.backend.MusicBeatState);
		set("Conductor", funkin.backend.Conductor);
		set("ClientPrefs", funkin.data.ClientPrefs);
		set("CoolUtil", funkin.utils.CoolUtil);
		set('WindowUtil', funkin.utils.WindowUtil);
		
		set("StageData", funkin.data.StageData);
		set("PlayState", PlayState);
		set('FunkinSound', funkin.audio.FunkinSound);
		
		// custom
		set('FlxColor', funkin.scripts.ScriptClasses.ScriptedFlxColor);
		set('Random', funkin.scripts.ScriptClasses.ScriptedFlxRandom);
        set('MainMenuState', funkin.states.MainMenuState);
        // Mobile Controls (So scripts can toggle Hitboxes/Pads)
        //set('MobileConfig', mobile.MobileConfig);
        //set('ButtonsModes', mobile.MobileConfig.ButtonsModes);
		
		// script
		set("FunkinScript", FunkinScript);
		set('ScriptConstants', funkin.scripting.ScriptConstants);
		
		// for compat
		set('HScriptState', funkin.scripting.ScriptedState);
		set('HScriptSubstate', funkin.scripting.ScriptedSubstate);
		
		set('ScriptedState', funkin.scripting.ScriptedState);
		set('ScriptedSubstate', funkin.scripting.ScriptedSubstate);
		
		set("GameOverSubstate", funkin.states.substates.GameOverSubstate);
		
		// objects
		set("Note", funkin.objects.note.Note);
		set("Bar", funkin.objects.Bar);
		#if VIDEOS_ALLOWED
		set("FunkinVideoSprite", funkin.video.FunkinVideoSprite);
		#end
		set("BackgroundDancer", funkin.objects.stageobjects.BackgroundDancer);
		set("BackgroundGirls", funkin.objects.stageobjects.BackgroundGirls);
		set("HealthIcon", HealthIcon);
		set("Character", funkin.objects.Character);
		set("NoteSplash", NoteSplash);
		set("BGSprite", BGSprite);
		set("StrumNote", StrumNote);
		set("Alphabet", Alphabet);
		set("AttachedSprite", AttachedSprite);
		set("AttachedAlphabet", AttachedAlphabet);
		
		set("CutsceneHandler", funkin.objects.CutsceneHandler);
		set('DialogueBox', funkin.objects.DialogueBox);
		
		// modchart related
		set("ModManager", funkin.game.modchart.ModManager);
		set("SubModifier", funkin.game.modchart.SubModifier);
		set("NoteModifier", funkin.game.modchart.NoteModifier);
		set("EventTimeline", funkin.game.modchart.EventTimeline);
		set("Modifier", funkin.game.modchart.Modifier);
		set("StepCallbackEvent", funkin.game.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.game.modchart.events.CallbackEvent);
		set("ModEvent", funkin.game.modchart.events.ModEvent);
		set("EaseEvent", funkin.game.modchart.events.EaseEvent);
		set("SetEvent", funkin.game.modchart.events.SetEvent);
		
		set('inGameOver', false);
		
		set("game", FlxG.state);
		
		if ((FlxG.state is PlayState))
		{
			set("inPlaystate", true);
			set('bpm', PlayState.SONG.bpm);
			set('scrollSpeed', PlayState.SONG.speed);
			set('songName', PlayState.SONG.song);
			set('isStoryMode', PlayState.isStoryMode);
			set('difficulty', PlayState.storyMeta.difficulty);
			set('weekRaw', PlayState.storyMeta.curWeek);
			set('seenCutscene', PlayState.seenCutscene);
			set('week', funkin.data.WeekData.weeksList[PlayState.storyMeta.curWeek]);
			set('difficultyName', funkin.backend.Difficulty.difficulties[PlayState.storyMeta.difficulty]);
			set('songLength', FlxG.sound.music.length);
			set('healthGainMult', PlayState.instance.healthGain);
			set('healthLossMult', PlayState.instance.healthLoss);
			set('instakillOnMiss', PlayState.instance.instakillOnMiss);
			set('botPlay', PlayState.instance.cpuControlled);
			set('practice', PlayState.instance.practiceMode);
			set('startedCountdown', false);
			set('mustHitSection', PlayState.SONG?.notes[0]?.mustHitSection ?? false);
			
			set("global", PlayState.instance.variables);
			set("getInstance", funkin.scripting.ScriptConstants.getInstance);
			
			set('setVar', (varName:String, val:Dynamic) -> PlayState.instance.variables.set(varName, val));
			set('getVar', (varName:String) -> PlayState.instance.variables.get(varName));
			
			set('initScript', (path:String) -> {
				path = FunkinScript.getPath(path);
				if (!PlayState.instance.scripts.exists(path)) PlayState.instance.initFunkinScript(path);
			});
		}
		else
		{
			set("inPlaystate", false);
		}
		
		set("newShader", (?fragFile:String, ?vertFile:String) -> {
			var fragPath = fragFile != null ? Paths.fragment(fragFile) : null;
			var vertPath = vertFile != null ? Paths.vertex(vertFile) : null;
			
			if (fragPath != null)
			{
				if (FunkinAssets.exists(fragPath)) fragPath = FunkinAssets.getContent(fragPath);
			}
			
			if (vertPath != null)
			{
				if (FunkinAssets.exists(vertPath)) vertPath = FunkinAssets.getContent(vertPath);
			}
			
			return new funkin.backend.FunkinShader.FunkinRuntimeShader(fragPath, vertPath);
		});
	}
}
