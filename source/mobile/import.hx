#if !macro
import mobile.objects.FunkinHitbox;
import mobile.objects.FunkinJoyStick;
import mobile.objects.FunkinMobilePad;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if android
import android.content.Context as AndroidContext;
import android.widget.Toast as AndroidToast;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
import android.Tools as AndroidTools;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
#end

#end