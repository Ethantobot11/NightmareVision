package funkin;

#if !macro
import flixel.util.FlxDestroyUtil;

import extensions.flixel.FlxCameraEx;
import extensions.flixel.FlxSoundEx;

import funkin.backend.MusicBeatState;
import funkin.backend.MusicBeatSubstate;
import funkin.scripting.ScriptConstants;
import funkin.audio.FunkinSound;
import funkin.backend.Logger;
import funkin.utils.*;

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
#if mobile
import mobile.backend.StorageUtil;
#end
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

using haxe.io.Path;
#end
