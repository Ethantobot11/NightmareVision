import flixel.text.FlxText;
import flixel.addons.text.FlxTypeText;

import funkin.game.shaders.RGBPalette;

import haxe.Json;

import sys.io.File;

using StringTools;

typedef DialogueCharacter =
{
	var name:String;
	var asset:String;
	var sound:String;
	var icon:String;
	var boxColor:FlxColor;
	var boxShadeColor:FlxColor;
	var animations:Array<AnimData>;
}

typedef AnimData =
{
	var anim:String;
	var name:String;
	var loop:Bool;
	var offsets:Array<Int>;
}

// Dialogue softcode!
public var hasDialogue:Bool = false;
public var hasDialogueAudio = true;

/**
 * Debug cutscene testing.
**/
public var repeatedCutscenes:Bool = false;

public var skipText:FlxText; // skip video text
var bgFade:FlxSprite;
var box:FlxSprite;
var boxRGB:RGBPalette;
var bubble:FlxSprite;
var bubble_old:FlxSprite;
var icon:HealthIcon;
var icon_old:HealthIcon;
var boxGroup:FlxSpriteGroup;
var swagDialogue:FlxTypeText;
var rtlDisplayText:FlxText;
var rtlWrapMeasure:FlxText;
var dropText:FlxText;
var dropText_old:FlxText;
var text_old:FlxText;
var dialogueList:Array<Dynamic>;
var curEmote:String = 'happy';
var curCharacter:String = 'bf';
var dialogueEnded:Bool = false;
var curIcon:String = 'bf';
var curSide:Int = 0;
var charMap:Map<String, Dynamic> = ["DLOW" => "D'LOW"];
var blackYnot:FlxSprite;
var vidPlaying:Bool = false;
var dialogueAfter:Bool = false;
var video:FunkinVideoSprite;
var rtlMode:Bool = false;
var rtlFullText:String = "";

// dialogue portraits
var portrait:Array<FlxSprite> = [];

// bro
var portraitOffs:Array<Map<String, Array<Int>>> = [
	["DLOW" => "D'LOW"],
	["DLOW" => "D'LOW"],
	["DLOW" => "D'LOW"
	]
];

function onCreatePost()
{
	final PADDING = 15;
	skipText = new FlxText(PADDING, 0, FlxG.width - PADDING * 2, Lang.str('video_skip'));
	skipText.setFormat(Paths.font("liberbold.ttf"), 25, FlxColor.WHITE, Lang.hasSpecial('rightToLeft') ? 'right' : 'left', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	skipText.borderSize = 2;
	skipText.y = FlxG.height - skipText.height - (PADDING * (3 / 4));
	skipText.camera = camOther;
	skipText.zIndex = 12;
}

function onVidEnd()
{
	vidPlaying = false;
	camGame.visible = true;
	skipText.visible = false;
	// ^ for windowed fullscreen
	if (dialogueAfter) readDialogue();
	else
	{
		startCountdown();
		if (blackYnot != null) FlxTween.tween(blackYnot, {alpha: 0}, 0.5,
			{
				onComplete: function() {
					blackYnot.destroy();
				}
			});
	}
}

/**
	* Loads a video cutscene basically.
	`vid` > what video
	`hold on a second`
**/
public function videoCutscene(?vid:String = 'sussus-moogus', ?dAfter:Bool = true)
{
	if (!isStoryMode || PlayState.seenCutscene) return;
	songStartCallback = () -> {
		return Function_Stop;
	}
	
	dialogueAfter = dAfter ?? true;
	
	if (!dialogueAfter) PlayState.seenCutscene = true;
	
	blackYnot = new FlxSprite().makeGraphic(FlxG.width + 3, FlxG.height, FlxColor.BLACK);
	blackYnot.camera = camOther;
	add(blackYnot);
	
	video = new FunkinVideoSprite();
	add(video);
	video.onFormat(() -> {
		vidPlaying = true;
		video.camera = camOther;
		video.setGraphicSize(0, FlxG.height);
		video.antialiasing = ClientPrefs.globalAntialiasing;
		video.updateHitbox();
		video.screenCenter();
		camGame.visible = false;
		// ^ for windowed fullscreen
		textFade();
	});
	video.onEnd(onVidEnd);
	if (video.load(Paths.video(Paths.sanitize(vid)))) video.delayAndStart();

	add(skipText);
}

public function textFade()
{
	skipText.visible = true;
	skipText.alpha = 0.5;
	FlxTween.tween(skipText, {alpha: 0}, 3, {startDelay: 3});
}

/**
 * The most disgusting code of all time. Okay so like. Imagine this: We grab the character from data/dialogue/ and load it but ONLY if it already exists.
 * This code is really bad but nothing in this mod uses more than 3 characters for dialogue total so I don't care.
 * I have not tested if more than 3 work. Please don't do that.
**/
function speakerAnims(char:String = 'bf')
{
	// oh my fucking god dude
	var loadUp:Bool = false;
	var blah:DialogueCharacter;
	if (charMap.exists(char))
	{
		blah = charMap.get(char);
	}
	else
	{
		var path:String = Paths.modFolders('data/dialogue/' + char + '.json');
		blah = Json.parse(File.getContent(path));
		charMap[char] = blah;
		loadUp = true;
	}
	curSide = blah.side;
	curSound = blah.sound;
	curIcon = blah.icon;
	boxRGB.setColors([FlxColor.fromString(blah.boxColor), 0xFF666666, FlxColor.fromString(blah.boxShadeColor)]);
	var who:FlxSprite = portrait[curSide];
	if (loadUp)
	{
		who.frames = Paths.getSparrowAtlas('ui/dialogue/characters/' + blah.asset);
		
		for (b in blah.animations)
		{
			if (b.loop) who.animation.addByPrefix(b.anim + '-loop', b.name, 24, true);
			who.animation.addByPrefix(b.anim, b.name, 24, b.reset ?? true);
			
			portraitOffs[curSide].set(b.anim, b.offsets);
		}
		
		who.animation.onFinish.add(function(anim:String) {
			if (who.animation.exists(anim + '-loop')) who.animation.play(anim + '-loop', true);
		});
	}
	boxChar = Lang.str(blah.name, blah.name);
	return who;
}

function animPlay(why, ?emote = 'happy')
{
	var who = portrait[why];
	if (portraitOffs[why].exists(emote))
	{
		who.animation.play(emote);
		who.offset.set(portraitOffs[why].get(emote)[0], portraitOffs[why].get(emote)[1]);
	}
	else trace('I am sorry. I cannot complete this request.');
}

/**
	* Hm.
	`oldToo` > Refresh old?
**/
function refreshDialogue(?oldToo = false)
{
	if (oldToo)
	{
		if (bubble_old.alpha != 1)
		{
			for (i in [dropText_old, text_old, icon_old, bubble_old])
			{
				i.alpha = 1;
			}
		}
		dropText_old.text = dropText.text;
		text_old.text = rtlMode ? formatArabicDialogueText(rtlFullText) : swagDialogue.text;
		if (rtlMode) Lang.arabicTextFix(text_old);
		icon_old.changeIcon(curIcon);
		moveTextUp(text_old, dropText_old);
		FlxG.sound.play(Paths.sound('clickText'), 0.8);
	}
	
	dialogueEnded = false;
	var splitName:Array<String> = dialogueList[0].split(":");
	curCharacter = splitName[1]; // idk
	
	v4SpeakerShit();
	curEmote = splitName[2]; // emote
	dialogueList[0] = dialogueList[0].substr(splitName[1].length + 3 + splitName[2].length).trim();
	var line = StringTools.contains(dialogueList[0], 'dialogue_') ? Lang.str(dialogueList[0]) : dialogueList[0];
	if (rtlMode)
	{
		rtlFullText = line;
		rtlDisplayText.text = line;
	}
	swagDialogue.text = line;
	moveTextUp(swagDialogue, dropText);
	if (rtlMode)
	{
		rtlDisplayText.scale.y = swagDialogue.scale.y;
		rtlDisplayText.text = '';
	}
	swagDialogue.resetText(line);
	swagDialogue.start(0.05, true);
	
	var who = portrait[curSide];
	
	who.animation.onLoop.removeAll();
	animPlay(curSide, curEmote);
	
	swagDialogue.completeCallback = function() {
		dialogueEnded = true;
		if (rtlMode)
		{
			rtlDisplayText.text = formatArabicDialogueText(rtlFullText);
			Lang.arabicTextFix(rtlDisplayText);
		}
		
		who.animation.onLoop.addOnce(function(anim:String) {
			if (who.animation.exists(anim + '-loop'))
			{
				who.animation.play(anim + '-loop', true);
			}
			else
			{
				who.animation.pause();
			}
		});
	};
	
	dialogueList.remove(dialogueList[0]);
}

/**
 * Let us grab this shit at once!
**/
function v4SpeakerShit()
{
	var speaker:FlxSprite = speakerAnims(curCharacter);
	swagDialogue.sounds = [FlxG.sound.load(Paths.sound('dialogue/' + curSound), 0.6)];
	dropText.text = boxChar;
	icon.changeIcon(curIcon);
	if (!speaker.visible)
	{
		speaker.visible = true;
		switch (speaker)
		{
			case portrait[2]:
				FlxTween.tween(speaker, {alpha: 1, x: 864.75}, 0.5, {ease: FlxEase.quadInOut});
			case portrait[0]:
				FlxTween.tween(speaker, {alpha: 1, x: 246.85}, 0.5, {ease: FlxEase.quadInOut});
			case portrait[1]:
				FlxTween.tween(speaker, {alpha: 1, y: 148.15}, 0.5, {ease: FlxEase.quadInOut});
		}
	}
}

/** 
 * Run this function to read the songs/SONG_NAME/dialogue.txt file
**/
public function readDialogue()
{
	if (!isStoryMode || PlayState.seenCutscene) return;
	songStartCallback = () -> {
		return Function_Stop;
	}
	if (!repeatedCutscenes) PlayState.seenCutscene = true;
	var naughty:Bool = true;
	hasDialogue = true;
	
	// For some stuff like Arabic
	var rightLeft = Lang.hasSpecial('rightToLeft');
	var gLtR:FlxTextAlign = (rightLeft ? FlxTextAlign.RIGHT : FlxTextAlign.LEFT);
	rtlMode = rightLeft;
	
	var textX:Float = rightLeft ? 300 : 350; // 325.85
	var txt = Paths.modFolders('songs/' + Paths.sanitize(songName) + '/dialogue.txt');
	dialogueList = CoolUtil.coolTextFile(txt);
	
	if (blackYnot != null) FlxTween.tween(blackYnot, {alpha: 0}, 0.5);
	
	// trace('Loading dialogue at ' + txt);
	if (hasDialogueAudio)
	{
		FlxG.sound.playMusic(Paths.music('dialogue/' + Paths.sanitize(songName)));
		FlxG.sound.music.volume = 0;
		FlxG.sound.music.fadeIn(1, 0, 0.8);
	}
	
	bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFFFFFFF);
	bgFade.camera = camHUD;
	bgFade.alpha = 0;
	add(bgFade);
	
	FlxTween.tween(bgFade, {alpha: 0.35}, 0.8, {ease: FlxEase.circIn});
	
	// Create the box group.
	boxGroup = new FlxSpriteGroup();
	boxGroup.camera = camHUD;
	add(boxGroup);
	
	// Dialgoue box
	box = new FlxSprite(260.1, 431.45).loadGraphic(Paths.image('ui/dialogue/dialogueBox'));
	box.screenCenter(FlxAxes.X);
	boxRGB = new RGBPalette();
	boxRGB.setColors([0xFFFF1515, 0xFF666666, 0xFF7D0058]);
	box.shader = boxRGB.shader;
	
	var port0:FlxSprite = new FlxSprite(246.85 - 50, 251.35);
	port0.updateHitbox();
	port0.visible = false;
	port0.alpha = 0;
	
	portrait.push(port0);
	
	var port1:FlxSprite = new FlxSprite(206.85, 148.15 + 50);
	port1.frames = Paths.getSparrowAtlas('ui/dialogue/characters/gf');
	port1.updateHitbox();
	port1.screenCenter(FlxAxes.X);
	port1.visible = false;
	port1.alpha = 0;
	
	boxGroup.add(port1);
	boxGroup.add(port0);
	
	portrait.push(port1);
	
	// portrait right
	port2 = new FlxSprite(864.75 + 50, 216.3);
	port2.updateHitbox();
	port2.visible = false;
	port2.alpha = 0;
	boxGroup.add(port2);
	portrait.push(port2);
	
	boxGroup.add(box);
	
	bubble = new FlxSprite(355.85, 495.55).loadGraphic(Paths.image('ui/dialogue/bubble'));
	bubble_old = new FlxSprite(355.85, 616.35).loadGraphic(Paths.image('ui/dialogue/bubble'));
	for (i in [bubble, bubble_old])
	{
		i.screenCenter(FlxAxes.X);
		i.x += 18.5; // fuck it
		boxGroup.add(i);
	}
	
	icon = new HealthIcon('red', false);
	icon.setPosition(rightLeft ? 920 : 220, (bubble.getMidpoint().y - 75));
	icon.setGraphicSize(Std.int(icon.width * 0.7));
	icon.updateHitbox();
	boxGroup.add(icon);
	
	swagDialogue = new FlxTypeText(textX, 0, Std.int(FlxG.width * 0.5), "", 28);
	swagDialogue.setFormat(Paths.font("liber.ttf"), 26, FlxColor.BLACK, gLtR);
	swagDialogue.visible = !rightLeft;
	
	dropText = new FlxText(textX, 495, Std.int(FlxG.width * 0.5), "", 28);
	dropText.setFormat(Paths.font("liberbold.ttf"), Lang.hasSpecial('smallerDialogue') ? 20 : 30, FlxColor.WHITE, gLtR, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	dropText.borderSize = 2;
	boxGroup.add(dropText);
	swagDialogue.y = dropText.y + 30;
	
	boxGroup.add(swagDialogue);
	rtlDisplayText = new FlxText(textX, swagDialogue.y, Std.int(FlxG.width * 0.5), "", 28);
	rtlDisplayText.setFormat(Paths.font("liber.ttf"), 26, FlxColor.BLACK, gLtR);
	rtlDisplayText.textField.wordWrap = true;
	rtlDisplayText.textField.multiline = true;
	rtlDisplayText.visible = rightLeft;
	boxGroup.add(rtlDisplayText);
	rtlWrapMeasure = new FlxText(textX, swagDialogue.y, Std.int(FlxG.width * 0.5), "", 28);
	rtlWrapMeasure.setFormat(Paths.font("liber.ttf"), 26, FlxColor.BLACK, gLtR);
	rtlWrapMeasure.textField.wordWrap = true;
	rtlWrapMeasure.textField.multiline = true;
	
	// old version of everything
	icon_old = new HealthIcon('red', false);
	icon_old.setPosition(icon.x, (bubble.getMidpoint().y - 75) + 120.8);
	icon_old.setGraphicSize(icon.width);
	icon_old.updateHitbox();
	icon_old.flipX = icon.flipX = rightLeft;
	boxGroup.add(icon_old);
	
	dropText_old = new FlxText(textX, 622.65 - 9, Std.int(FlxG.width * 0.5), "", 28);
	dropText_old.setFormat(Paths.font("liberbold.ttf"), dropText.size, FlxColor.WHITE, gLtR, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	dropText_old.borderSize = 2;
	boxGroup.add(dropText_old);
	
	text_old = new FlxText(textX, 671.05 - 21, Std.int(FlxG.width * 0.5), "", 28);
	text_old.setFormat(Paths.font("liber.ttf"), 26, FlxColor.BLACK, gLtR);
	boxGroup.add(text_old);
	
	for (i in [dropText_old, text_old, icon_old, bubble_old, box, icon, bubble])
	{
		i.alpha = 0.001;
	}
	// boxGroup.visible = false;
	
	FlxTimer.wait(0.5, function() {
		box.alpha = 1;
		bubble.alpha = 1;
		icon.alpha = 1;
		refreshDialogue();
	});
}

function getAtt(ac:String)
{
	return (Lang.current?.special != null ? Lang.current?.special.contains(ac) : false);
}

function formatArabicDialogueText(source:String):String
{
	if (!rtlMode || source == null || source.length < 1 || rtlWrapMeasure == null) return source;
	
	var wrappedLines:Array<String> = [];
	for (paragraph in source.split("\n"))
	{
		if (paragraph.trim().length < 1)
		{
			wrappedLines.push("");
			continue;
		}
		
		var words = paragraph.split(" ");
		var currentLine:String = "";
		for (i in 0...words.length)
		{
			var word = words[words.length - 1 - i];
			var candidate = (currentLine.length > 0) ? (word + " " + currentLine) : word;
			rtlWrapMeasure.text = candidate;
			if (currentLine.length > 0 && rtlWrapMeasure.textField.numLines > 1)
			{
				wrappedLines.unshift(currentLine);
				currentLine = word;
			}
			else currentLine = candidate;
		}
		wrappedLines.unshift(currentLine);
	}
	rtlWrapMeasure.text = "";
	return wrappedLines.join("\n");
}

/** 
 * Weird dialogue thing just in case it breaks with other languages.
 * Not too much stress-testing done beside from the Korean language.
**/
function moveTextUp(a, b)
{
	var rt = 65;
	// trace(Lang.current?.name); //idk if this was meant to be left here
	// trace('MOVE');
	// a.y = (b.y + 30);
	a.scale.y = (a.height > 64 ? (rt / a.height) : 1);
}

/** 
 * Ran only when the song has dialogue and in the dialogue cutscene.
**/
function dialogueUpdate(elapsed:Float)
{
	if (controls.BACK)
	{
		swagDialogue.skip();
		goodBialogue();
	}
	if (controls.ACCEPT)
	{
		if (dialogueEnded)
		{
			if (dialogueList.length > 0) refreshDialogue(true);
			else
			{
				goodBialogue();
			}
		}
		else
		{
			swagDialogue.skip();
		}
	}
}

function goodBialogue()
{
	hasDialogue = false;
	FlxG.sound.music.stop(); // fadeOut(1.5, 0);
	FlxG.sound.play(Paths.sound('panelDisappear'), 0.5);
	FlxTween.tween(bgFade, {alpha: 0}, 0.25,
		{
			ease: FlxEase.circIn
		});
	FlxTween.tween(boxGroup, {y: boxGroup.y + 700}, 0.25,
		{
			ease: FlxEase.circIn,
			onComplete: function() {
				boxGroup.kill();
				charMap.clear();
				bgFade.kill();
			}
		});
		
	startCountdown();
}

function onUpdate(elapsed)
{
	if (hasDialogue) dialogueUpdate(elapsed);
	if (vidPlaying)
	{
		if (controls.BACK)
		{
			video.kill();
			onVidEnd();
		}
	}
}

function onUpdatePost()
{
	if (swagDialogue != null)
	{
		if (rtlMode && rtlFullText.length > 0)
		{
			var ftLen = swagDialogue.text.length;
			if (ftLen > 0)
			{
				if (ftLen > rtlFullText.length) ftLen = rtlFullText.length;
				var startIndex = rtlFullText.length - ftLen;
				if (startIndex < 0) startIndex = 0;
				rtlDisplayText.text = formatArabicDialogueText(rtlFullText.substring(startIndex));
				Lang.arabicTextFix(rtlDisplayText);
			}
			else rtlDisplayText.text = '';
			rtlDisplayText.updateHitbox();
		}
		else swagDialogue.updateHitbox();
	}
}
