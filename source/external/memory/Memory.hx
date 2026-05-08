package external.memory;

// Only allow this class to exist on platforms where we have the C++ header ready
#if (cpp && (windows || android || ios))

/**
 * Memory class to properly get accurate memory counts
 */
#if windows
@:buildXml('<include name="../../../../source/external/memory/build.xml" />')
#elseif android
@:buildXml('<include name="../../../../source/external/memory/build.xml" />')
#elseif ios
@:buildXml('<include name="../../../source/external/memory/build.xml" />')
#end
@:include("Memory.h")
extern class Memory
{
	/**
	 * Returns the current resident set size (physical memory use) measured
	 * in bytes, or zero if the value cannot be determined on this OS.
	 */
	@:native("getCurrentRSS")
	public static function getCurrentUsage():Float;
}

#else

// Fallback class for Mac, Linux, and others so the code doesn't crash
class Memory 
{
	public static function getCurrentUsage():Float {
		return 0.0;
	}
}
#end
