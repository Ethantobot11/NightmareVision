#if !macro
import haxe.io.Path;

// flixel
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxBasic;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;

#if sys
import sys.*;

import sys.io.*;
#end

import funkin.api.DiscordClient;

#if VIDEOS_ALLOWED
import hxvlc.flixel.*;
#end

// Spesificly Extended Mobile-Controls Library Objects For FNF
import mobile.objects.FunkinMobilePad;
import mobile.objects.FunkinHitbox;
import mobile.objects.FunkinJoyStick;
import mobile.Util;
// Others
import mobile.ScreenUtil;
import mobile.MobileConfig;
import mobile.MobileConfig.ButtonModes;
import mobile.MobileButton;
import mobile.backend.StorageUtil;
import mobile.substates.MobileExtraControl;
import mobile.MobileControlManager;
//Android
#if android
import android.callback.CallBack as AndroidCallBack;
import android.content.Context as AndroidContext;
import android.widget.Toast as AndroidToast;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
import android.Tools as AndroidTools;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
#end

import Init;

import funkin.Paths;
import funkin.data.ClientPrefs;
import funkin.backend.Conductor;
import funkin.utils.CoolUtil;
import funkin.data.Highscore;
import funkin.states.*;
import funkin.objects.BGSprite;
import funkin.backend.MusicBeatState;

using flixel.util.FlxArrayUtil;

using StringTools;
#end
