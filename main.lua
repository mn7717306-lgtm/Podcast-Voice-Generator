require "import"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.net.Uri"
import "android.text.*"
import "cjson"
import "android.media.MediaPlayer"
import "java.util.*"
import "android.os.*"
import "java.io.*"
import "android.media.MediaRecorder"
import "android.util.TypedValue"
import "android.util.Base64"
import "java.lang.Byte"
import "java.lang.Integer"
import "java.lang.System"
import "java.text.SimpleDateFormat"
import "java.text.DateFormat"
import "android.graphics.Typeface"
import "android.graphics.Color"
if Build.VERSION.SDK_INT >= 23 then
import "android.media.PlaybackParams"
end
activity = this
local UPDATE_SYSTEM_ENABLED = true
local CURRENT_VERSION = "1.0.0"
local GITHUB_REPO_URL = "https://github.com/mn7717306-lgtm/Podcast-Voice-Generator"
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/mn7717306-lgtm/Podcast-Voice-Generator/main/"
local VERSION_URL = GITHUB_RAW_URL .. "version.txt"
local UPDATE_URL = GITHUB_RAW_URL .. "update.txt"
local MESSAGE_URL = GITHUB_RAW_URL .. "Message.txt"
local LINK_URL = GITHUB_RAW_URL .. "Link.txt"
local LICENSE_URL = GITHUB_RAW_URL .. "LICENSE"
local PLUGIN_PATH = "/storage/emulated/0/解说/Plugins/Podcast Voice Generator/main.lua"
local PLUGIN_DIR = "/storage/emulated/0/解说/Plugins/Podcast Voice Generator/"
local UPDATE_PREFS = "UPDATE_CONFIG"
local MESSAGE_PREFS = "MESSAGE_CONFIG"
local LINK_PREFS = "LINK_CONFIG"
local updateInProgress = false
local lastUpdateCheckTime = 0
local UPDATE_CHECK_INTERVAL = 24 * 60 * 60 * 1000 -- 24 hours
local mainHandler = Handler(Looper.getMainLooper())
local GEMINI_PREFS = "GEMINI_CONFIG"
local PREFS_NAME = "VOICE_CONFIG"
local GENERATION_STATE_PREFS = "GENERATION_STATE"
local BACKGROUND_SERVICE_PREFS = "BACKGROUND_SERVICE"
local API_PROVIDERS = {
 "Google Generative Language (Gemini)",
 "OpenAI Official (GPT-4o mini TTS)"
}
local API_ENDPOINTS = {
 ["Google Generative Language (Gemini)"] = function(apiKey)
 return string.format(
 "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=%s",
 apiKey)
 end,
 ["OpenAI Official (GPT-4o mini TTS)"] = function(apiKey)
 return "https://api.openai.com/v1/audio/speech"
 end
}
local OPENAI_TTS_MODEL = "tts-1"
local DEFAULT_API_KEY = ""
local SELECTED_API_PROVIDER = "OpenAI Official (GPT-4o mini TTS)"
local API_KEY = DEFAULT_API_KEY
local configNames = {"Host", "Guest 1", "Guest 2", "Guest 3", "Guest 4", "Guest 5"}
local configVoices = {"alloy", "echo", "fable", "onyx", "nova", "shimmer"}
local configSpeeds = {1.0, 1.0, 1.0, 1.0, 1.0, 1.0}
local configPitches = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
local configEmotions = {"Default", "Default", "Default", "Default", "Default", "Default"}
local currentMode = 0
local selectedEmotionSingle = "Default"
local customEmotionPrompt = "Please read this sentence with a deep, warm voice."
local textEmotionMode = "Default (Keep as is)"
local MAX_CHARS = 50000
local MAX_TOKENS = 12500
local CHUNK_SIZE = 4000
local audioPlayer = nil
local finalPodcastPath = nil
local audioParts = {}
local testAudioPlayer = nil
local configTestAudioPlayer = nil
local activePlayers = {}
local activeStreams = {}
local activeFiles = {}
local tutorialPlayer = nil
local tutorialTimer = nil
local isAudioAutoPlayEnabled = false
local textEmotionModes = {
 "Default (Keep as is)",
 "Default Voice Emotion",
 "Random Emotion"
}
local emotionsFull = {
 "Default", "Happy", "Energetic", "Sad", "Crying", "Angry",
 "Furious", "Whisper", "Mysterious", "Spooky", "Ghostly",
 "Flat", "Robot", "News", "Radio", "Singing", "Poetic",
 "Storytelling", "Sarcastic", "Confused", "Shocked", "Scared",
 "Panicked", "Disgusted", "Hopeful", "Nostalgic", "Sympathetic",
 "Firm", "Military", "Fast", "Slow", "Nervous", "Sleepy",
 "Drunk", "Pleading", "Secretive", "Philosophical",
 "Custom", "Rap", "Pop", "Rock", "Jazz", "Blues", "Opera",
 "Country", "HipHop", "Electronic", "Reggae", "Classical",
 "Lullaby", "Fairy Tale", "Superhero", "Villain", "Alien",
 "Monster", "Cartoon", "Anime", "Gothic", "Romantic",
 "Comedic", "Horror", "SciFi", "Fantasy", "Adventure"
}
local voiceMapGemini = {
 ["Zephyr (Male, Bright)"]="Zephyr",
 ["Puck (Male, Fresh)"]="Puck",
 ["Charon (Male, Emotional)"]="Charon",
 ["Kore (Female, Firm)"]="Kore",
 ["Fenrir (Male, Excited)"]="Fenrir",
 ["Leda (Female, Youthful)"]="Leda",
 ["Orus (Male, Determined)"]="Orus",
 ["Aoede (Female, Comfortable)"]="Aoede",
 ["Callirrhoe (Female, Easygoing)"]="Callirrhoe",
 ["Autonoe (Female, Bright)"]="Autonoe",
 ["Enceladus (Male, Slightly Hoarse)"]="Enceladus",
 ["Iapetus (Male, Clear)"]="Iapetus",
 ["Umbriel (Female, Easygoing)"]="Umbriel",
 ["Algieba (Male, Smooth)"]="Algieba",
 ["Despina (Female, Smooth)"]="Despina",
 ["Erinome (Female, Clear)"]="Erinome",
 ["Algenib (Male, Hoarse Voice)"]="Algenib",
 ["Rasalgethi (Male, Emotional)"]="Rasalgethi",
 ["Laomedeia (Female, Fresh)"]="Laomedeia",
 ["Achernar (Male, Soft)"]="Achernar",
 ["Alnilam (Male, Firm)"]="Alnilam",
 ["Schedar (Female, Even)"]="Schedar",
 ["Gacrux (Male, Mature)"]="Gacrux",
 ["Pulcherrima (Female, Confident)"]="Pulcherrima",
 ["Achird (Male, Friendly)"]="Achird",
 ["Zubenelgenubi (Male, Simple)"]="Zubenelgenubi",
 ["Vindemiatrix (Female, Gentle)"]="Vindemiatrix",
 ["Sadachbia (Male, Lively)"]="Sadachbia",
 ["Sadaltager (Male, Knowledgeable)"]="Sadaltager",
 ["Sulafat (Female, Warm)"]="Sulafat"
}
local voiceMapOpenAI = {
 ["Alloy (Male)"]="alloy",
 ["Echo (Male)"]="echo",
 ["Fable (Female)"]="fable",
 ["Onyx (Male)"]="onyx",
 ["Nova (Female)"]="nova",
 ["Shimmer (Female)"]="shimmer"
}
local voiceMap = voiceMapOpenAI
local emotionMap = {
 ["Default"] = "[READ THIS TEXT EXACTLY AS WRITTEN]",
 ["Happy"] = "[READ WITH A JOYFUL TONE]",
 ["Energetic"] = "[READ WITH HIGH ENERGY]",
 ["Sad"] = "[READ WITH A SAD TONE]",
 ["Crying"] = "[READ WITH CRYING EMOTION]",
 ["Angry"] = "[READ WITH ANGRY TONE]",
 ["Furious"] = "[READ WITH EXTREME ANGER]",
 ["Whisper"] = "[READ IN WHISPER TONE]",
 ["Mysterious"] = "[READ WITH MYSTERIOUS TONE]",
 ["Spooky"] = "[READ WITH SPOOKY TONE]",
 ["Ghostly"] = "[READ WITH GHOSTLY TONE]",
 ["Flat"] = "[READ WITH FLAT MONOTONE]",
 ["Robot"] = "[READ WITH ROBOTIC VOICE]",
 ["News"] = "[READ WITH NEWS ANCHOR TONE]",
 ["Radio"] = "[READ WITH RADIO ANNOUNCER STYLE]",
 ["Singing"] = "[READ AS IF SINGING]",
 ["Poetic"] = "[READ WITH POETIC TONE]",
 ["Storytelling"] = "[READ WITH STORYTELLING TONE]",
 ["Sarcastic"] = "[READ WITH SARCASTIC TONE]",
 ["Confused"] = "[READ WITH CONFUSED TONE]",
 ["Shocked"] = "[READ WITH SHOCKED TONE]",
 ["Scared"] = "[READ WITH SCARED TONE]",
 ["Panicked"] = "[READ WITH PANICKED TONE]",
 ["Disgusted"] = "[READ WITH DISGUSTED TONE]",
 ["Hopeful"] = "[READ WITH HOPEFUL TONE]",
 ["Nostalgic"] = "[READ WITH NOSTALGIC TONE]",
 ["Sympathetic"] = "[READ WITH SYMPATHETIC TONE]",
 ["Firm"] = "[READ WITH FIRM TONE]",
 ["Military"] = "[READ WITH MILITARY TONE]",
 ["Fast"] = "[READ AT FAST PACE]",
 ["Slow"] = "[READ AT SLOW PACE]",
 ["Nervous"] = "[READ WITH NERVOUS TONE]",
 ["Sleepy"] = "[READ WITH SLEEPY TONE]",
 ["Drunk"] = "[READ WITH DRUNK TONE]",
 ["Pleading"] = "[READ WITH PLEADING TONE]",
 ["Secretive"] = "[READ WITH SECRETIVE TONE]",
 ["Philosophical"] = "[READ WITH PHILOSOPHICAL TONE]",
 ["Rap"] = "[READ WITH RAP STYLE]",
 ["Pop"] = "[READ WITH POP MUSIC STYLE]",
 ["Rock"] = "[READ WITH ROCK STYLE]",
 ["Jazz"] = "[READ WITH JAZZ STYLE]",
 ["Blues"] = "[READ WITH BLUES STYLE]",
 ["Opera"] = "[READ WITH OPERA STYLE]",
 ["Country"] = "[READ WITH COUNTRY STYLE]",
 ["HipHop"] = "[READ WITH HIPHOP STYLE]",
 ["Electronic"] = "[READ WITH ELECTRONIC STYLE]",
 ["Reggae"] = "[READ WITH REGGAE STYLE]",
 ["Classical"] = "[READ WITH CLASSICAL STYLE]",
 ["Lullaby"] = "[READ WITH LULLABY STYLE]",
 ["Fairy Tale"] = "[READ WITH FAIRY TALE STYLE]",
 ["Superhero"] = "[READ WITH SUPERHERO STYLE]",
 ["Villain"] = "[READ WITH VILLAIN STYLE]",
 ["Alien"] = "[READ WITH ALIEN STYLE]",
 ["Monster"] = "[READ WITH MONSTER STYLE]",
 ["Cartoon"] = "[READ WITH CARTOON STYLE]",
 ["Anime"] = "[READ WITH ANIME STYLE]",
 ["Gothic"] = "[READ WITH GOTHIC STYLE]",
 ["Romantic"] = "[READ WITH ROMANTIC STYLE]",
 ["Comedic"] = "[READ WITH COMEDIC STYLE]",
 ["Horror"] = "[READ WITH HORROR STYLE]",
 ["SciFi"] = "[READ WITH SCI-FI STYLE]",
 ["Fantasy"] = "[READ WITH FANTASY STYLE]",
 ["Adventure"] = "[READ WITH ADVENTURE STYLE]",
 ["Custom"] = "[CUSTOM EMOTION - USE PROMPT PROVIDED]"
}
local emotionExampleMap = {
 ["Default"] = "This is a sample text for testing voice generation.",
 ["Happy"] = "I'm so excited to share this wonderful news with everyone today!",
 ["Rap"] = "Check the mic, one two, this is how we do, dropping beats that are fresh and new.",
 ["Pop"] = "This melody will make your heart sing, it's the sound of everything.",
 ["Rock"] = "Turn up the volume, feel the beat, this rock and roll can't be beat!",
 ["Custom"] = "Enter your example sentence here..."
}
local formatOptions = {"wav", "mp3", "wma", "ogg", "aac"}
local USER_AUDIO_DIR = "/storage/emulated/0/Audio/Podcast Generator"
local TUTORIAL_AUDIO_PATH = "/storage/emulated/0/Download/How to use.mp3"
local lastGeneratedAudioPath = nil
local lastGeneratedAudioType = nil
local isDialogHidden = false
local modes = {
 "Single Voice",
 "Two Voices (Dialogue)",
 "Four Voices Podcast",
 "Six Voices Podcast"
}
local isGenerationActive = false
local currentGenerationMode = nil
local currentGenerationText = nil
local currentGenerationProgress = 0
local currentGenerationTotal = 0
local currentGenerationLines = {}
local currentGenerationChunks = {}
local currentGenerationChunkIndex = 0
local currentGenerationTotalChunks = 0
local backgroundWakeLock = nil
local isBackgroundServiceActive = false
local backgroundServiceIntent = nil
function getUpdatePrefs()
 return activity.getSharedPreferences(UPDATE_PREFS, Context.MODE_PRIVATE)
end
function getMessagePrefs()
 return activity.getSharedPreferences(MESSAGE_PREFS, Context.MODE_PRIVATE)
end
function getLinkPrefs()
 return activity.getSharedPreferences(LINK_PREFS, Context.MODE_PRIVATE)
end
function saveLastUpdateCheckTime()
 local prefs = getUpdatePrefs()
 local editor = prefs.edit()
 editor.putLong("lastUpdateCheck", System.currentTimeMillis())
 editor.apply()
end
function getLastUpdateCheckTime()
 local prefs = getUpdatePrefs()
 return prefs.getLong("lastUpdateCheck", 0)
end
function saveLastVideoLink(link)
 local prefs = getLinkPrefs()
 local editor = prefs.edit()
 editor.putString("lastVideoLink", link)
 editor.apply()
end
function getLastVideoLink()
 local prefs = getLinkPrefs()
 return prefs.getString("lastVideoLink", "")
end
function saveMessageShownState(shown)
 local prefs = getMessagePrefs()
 local editor = prefs.edit()
 editor.putBoolean("messageShown", shown)
 editor.apply()
end
function getMessageShownState()
 local prefs = getMessagePrefs()
 return prefs.getBoolean("messageShown", false)
end
function saveMessageDontShowAgain(dontShow)
 local prefs = getMessagePrefs()
 local editor = prefs.edit()
 editor.putBoolean("dontShowAgain", dontShow)
 editor.apply()
end
function getMessageDontShowAgain()
 local prefs = getMessagePrefs()
 return prefs.getBoolean("dontShowAgain", false)
end
function saveVideoLinkShownState(shown)
 local prefs = getLinkPrefs()
 local editor = prefs.edit()
 editor.putBoolean("videoLinkShown", shown)
 editor.apply()
end
function getVideoLinkShownState()
 local prefs = getLinkPrefs()
 return prefs.getBoolean("videoLinkShown", false)
end
function downloadFile(url, callback)
 if not UPDATE_SYSTEM_ENABLED then
 callback(nil, "Update system disabled")
 return
 end
 
 Http.get(url, function(code, content)
 if code == 200 then
 callback(content, nil)
 else
 callback(nil, "HTTP Error: " .. code)
 end
 end)
end
function checkForUpdate(manualCheck, onCompleteCallback)
 if not UPDATE_SYSTEM_ENABLED then
 if onCompleteCallback then onCompleteCallback(false, "Update system disabled") end
 return
 end
 
 if updateInProgress then
 if onCompleteCallback then onCompleteCallback(false, "Update already in progress") end
 return
 end
 
 updateInProgress = true
 
 downloadFile(VERSION_URL, function(onlineVersion, errorMsg)
 if onlineVersion then
 onlineVersion = tostring(onlineVersion):match("^%s*(.-)%s*$")
 
 if onlineVersion and onlineVersion ~= CURRENT_VERSION then
 downloadFile(UPDATE_URL, function(updateDetails, updateError)
 updateInProgress = false
 
 if updateDetails then
 showUpdateDialog(onlineVersion, updateDetails, manualCheck)
 if onCompleteCallback then onCompleteCallback(true, "Update available: " .. onlineVersion) end
 else
 if manualCheck then
 showErrorDialog("Update details not available: " .. (updateError or "Unknown error"))
 end
 if onCompleteCallback then onCompleteCallback(false, "No update details") end
 end
 end)
 else
 updateInProgress = false
 if manualCheck then
 showInfoDialog("Update Check", "You have the latest version!\nCurrent: " .. CURRENT_VERSION)
 end
 if onCompleteCallback then onCompleteCallback(false, "Already up to date") end
 end
 else
 updateInProgress = false
 if manualCheck then
 showErrorDialog("Failed to check update: " .. (errorMsg or "Unknown error"))
 end
 if onCompleteCallback then onCompleteCallback(false, "Check failed: " .. (errorMsg or "Unknown")) end
 end
 end)
 
 if not manualCheck then
 saveLastUpdateCheckTime()
 end
end
function showUpdateDialog(newVersion, updateDetails, manualCheck)
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(20), dip2px(20), dip2px(20), dip2px(20))
 
 local titleLabel = TextView(activity)
 titleLabel.text = "🎉 New Update Available!"
 titleLabel.textSize = 18
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFF2196F3)
 titleLabel.gravity = Gravity.CENTER
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(10)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 
 local versionLabel = TextView(activity)
 versionLabel.text = "Version " .. newVersion
 versionLabel.textSize = 14
 versionLabel.setTextColor(0xFF666666)
 versionLabel.gravity = Gravity.CENTER
 local versionParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 versionParams.bottomMargin = dip2px(20)
 versionLabel.setLayoutParams(versionParams)
 mainLayout.addView(versionLabel)
 
 local whatsNewLabel = TextView(activity)
 whatsNewLabel.text = "What's New:"
 whatsNewLabel.textSize = 16
 whatsNewLabel.setTypeface(Typeface.DEFAULT_BOLD)
 whatsNewLabel.setTextColor(0xFF333333)
 local whatsNewParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 whatsNewParams.bottomMargin = dip2px(10)
 whatsNewLabel.setLayoutParams(whatsNewParams)
 mainLayout.addView(whatsNewLabel)
 
 local updateTextView = TextView(activity)
 updateTextView.text = updateDetails
 updateTextView.textSize = 14
 updateTextView.setTextColor(0xFF555555)
 updateTextView.setLineSpacing(dip2px(2), 1.2)
 updateTextView.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(updateTextView)
 
 local spacer = View(activity)
 local spacerParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1)
 spacer.setLayoutParams(spacerParams)
 mainLayout.addView(spacer)
 
 scrollView.addView(mainLayout)
 
 local updateDialog = LuaDialog(activity)
 updateDialog.setTitle("Update Available")
 updateDialog.setView(scrollView)
 
 updateDialog.setPositiveButton("Update Now", function()
 updateDialog.dismiss()
 performUpdate(newVersion)
 end)
 
 if manualCheck then
 updateDialog.setNegativeButton("Close", function()
 updateDialog.dismiss()
 end)
 else
 updateDialog.setNegativeButton("Later", function()
 updateDialog.dismiss()
 end)
 end
 
 updateDialog.show()
end
function performUpdate(newVersion)
 updateInProgress = true
 
 local function downloadAndReplace()
 downloadFile(GITHUB_RAW_URL .. "main.lua", function(newContent, errorMsg)
 if newContent then
 local backupPath = PLUGIN_PATH .. ".backup"
 local backupFile = io.open(backupPath, "w")
 if backupFile then
 local currentFile = io.open(PLUGIN_PATH, "r")
 if currentFile then
 local currentContent = currentFile:read("*a")
 currentFile:close()
 backupFile:write(currentContent)
 backupFile:close()
 
 local newFile = io.open(PLUGIN_PATH, "w")
 if newFile then
 newFile:write(newContent)
 newFile:close()
 
 os.remove(backupPath)
 
 runOnUi(function()
 showInfoDialog("Update Successful", 
 "Update to version " .. newVersion .. " completed successfully!\n\n" ..
 "Please restart the plugin for changes to take effect.")
 end)
 
 updateInProgress = false
 return
 else
 if File(backupPath).exists() then
 os.rename(backupPath, PLUGIN_PATH)
 end
 end
 else
 backupFile:close()
 os.remove(backupPath)
 end
 end
 
 runOnUi(function()
 showErrorDialog("Update failed: Could not write file")
 end)
 else
 runOnUi(function()
 showErrorDialog("Update failed: " .. (errorMsg or "Unknown error"))
 end)
 end
 updateInProgress = false
 end)
 end
 
 Thread(Runnable{
 run = downloadAndReplace
 }).start()
end
function checkServerMessage()
 if not UPDATE_SYSTEM_ENABLED then return end
 
 if getMessageDontShowAgain() then
 return
 end
 
 downloadFile(MESSAGE_URL, function(messageContent, errorMsg)
 if messageContent and #messageContent > 0 then
 runOnUi(function()
 showServerMessageDialog(messageContent)
 end)
 end
 end)
end
function showServerMessageDialog(messageContent)
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(20), dip2px(20), dip2px(20), dip2px(20))
 
 local titleLabel = TextView(activity)
 titleLabel.text = "📢 Server Message"
 titleLabel.textSize = 18
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFF2196F3)
 titleLabel.gravity = Gravity.CENTER
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(15)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 
 local messageTextView = TextView(activity)
 messageTextView.text = messageContent
 messageTextView.textSize = 14
 messageTextView.setTextColor(0xFF333333)
 messageTextView.setLineSpacing(dip2px(2), 1.2)
 messageTextView.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(messageTextView)
 
 local spacer = View(activity)
 local spacerParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(20))
 spacer.setLayoutParams(spacerParams)
 mainLayout.addView(spacer)
 
 local checkLayout = LinearLayout(activity)
 checkLayout.setOrientation(LinearLayout.HORIZONTAL)
 checkLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 
 local checkBox = CheckBox(activity)
 checkBox.text = "Don't show again"
 checkBox.textSize = 12
 checkBox.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 checkLayout.addView(checkBox)
 
 local filler = View(activity)
 filler.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 checkLayout.addView(filler)
 
 mainLayout.addView(checkLayout)
 
 scrollView.addView(mainLayout)
 
 local messageDialog = LuaDialog(activity)
 messageDialog.setTitle("Important Message")
 messageDialog.setView(scrollView)
 messageDialog.setPositiveButton("OK", function()
 saveMessageDontShowAgain(checkBox.isChecked())
 messageDialog.dismiss()
 end)
 
 messageDialog.show()
 saveMessageShownState(true)
end
function checkVideoLinkNotification()
 if not UPDATE_SYSTEM_ENABLED then return end
 
 if getVideoLinkShownState() then
 return
 end
 
 downloadFile(LINK_URL, function(linkContent, errorMsg)
 if linkContent then
 local link, text = linkContent:match("^(.-)|(.+)$")
 if not link then
 link = linkContent:match("^(.-)%s*$")
 text = "New video available!"
 end
 
 local lastLink = getLastVideoLink()
 
 if link and link ~= lastLink then
 runOnUi(function()
 showVideoLinkDialog(link, text)
 end)
 saveLastVideoLink(link)
 saveVideoLinkShownState(true)
 end
 end
 end)
end
function showVideoLinkDialog(videoLink, messageText)
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(20), dip2px(20), dip2px(20), dip2px(20))
 
 local titleLabel = TextView(activity)
 titleLabel.text = "🎬 New Video Uploaded!"
 titleLabel.textSize = 18
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFFFF9800)
 titleLabel.gravity = Gravity.CENTER
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(15)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 
 local messageTextView = TextView(activity)
 messageTextView.text = messageText or "A new video has been uploaded to our channel!"
 messageTextView.textSize = 14
 messageTextView.setTextColor(0xFF333333)
 messageTextView.setLineSpacing(dip2px(2), 1.2)
 messageTextView.setGravity(Gravity.CENTER)
 messageTextView.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(messageTextView)
 
 local spacer = View(activity)
 local spacerParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(30))
 spacer.setLayoutParams(spacerParams)
 mainLayout.addView(spacer)
 
 scrollView.addView(mainLayout)
 
 local videoDialog = LuaDialog(activity)
 videoDialog.setTitle("Video Notification")
 videoDialog.setView(scrollView)
 
 videoDialog.setPositiveButton("🎥 Watch Now", function()
 videoDialog.dismiss()
 if dlg and dlg.isShowing() then
 dlg.dismiss()
 end
 local intent = Intent(Intent.ACTION_VIEW, Uri.parse(videoLink))
 intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 activity.startActivity(intent)
 end)
 
 videoDialog.setNegativeButton("Close", function()
 videoDialog.dismiss()
 end)
 
 videoDialog.show()
end
function showLicenseDialog()
 downloadFile(LICENSE_URL, function(licenseContent, errorMsg)
 runOnUi(function()
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(20), dip2px(20), dip2px(20), dip2px(20))
 
 local titleLabel = TextView(activity)
 titleLabel.text = "📄 License Agreement"
 titleLabel.textSize = 18
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFF333333)
 titleLabel.gravity = Gravity.CENTER
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(15)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 
 local licenseTextView = TextView(activity)
 if licenseContent then
 licenseTextView.text = licenseContent
 else
 licenseTextView.text = "Unable to load license. Please check your internet connection.\n\nError: " .. (errorMsg or "Unknown")
 end
 licenseTextView.textSize = 12
 licenseTextView.setTextColor(0xFF555555)
 licenseTextView.setLineSpacing(dip2px(1), 1.1)
 licenseTextView.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(licenseTextView)
 
 scrollView.addView(mainLayout)
 
 local licenseDialog = LuaDialog(activity)
 licenseDialog.setTitle("Licenses and Agreements")
 licenseDialog.setView(scrollView)
 licenseDialog.setPositiveButton("Close", nil)
 licenseDialog.show()
 end)
 end)
end
function performAutoChecks()
 if not UPDATE_SYSTEM_ENABLED then return end
 
 local currentTime = System.currentTimeMillis()
 local lastCheck = getLastUpdateCheckTime()
 
 if currentTime - lastCheck > UPDATE_CHECK_INTERVAL then
 checkForUpdate(false, function(updateAvailable, message)
 if updateAvailable then
 end
 end)
 end
 
 checkServerMessage()
 
 checkVideoLinkNotification()
end
function updateApiUrl()
 if API_ENDPOINTS[SELECTED_API_PROVIDER] then
 return API_ENDPOINTS[SELECTED_API_PROVIDER](API_KEY)
 else
 return API_ENDPOINTS["OpenAI Official (GPT-4o mini TTS)"](API_KEY)
 end
end
function runOnUi(callback)
 mainHandler.post(Runnable{ run = callback })
end
function vibrate()
 local vibrator = activity.getSystemService(Context.VIBRATOR_SERVICE)
 if vibrator and vibrator.hasVibrator() then
 pcall(function() vibrator.vibrate(35) end)
 end
end
function estimateTokens(text)
 if not text then return 0 end
 return math.ceil(string.len(text) / 4)
end
function cleanupAllResources()
 for name, player in pairs(activePlayers) do
 if player then
 pcall(function()
 local isPlaying = false
 pcall(function() 
 isPlaying = player.isPlaying() 
 end)
 if isPlaying then
 player.stop()
 end
 player.release()
 activePlayers[name] = nil
 end)
 end
 end
 
 for name, stream in pairs(activeStreams) do
 pcall(function()
 if stream.close then
 stream.close()
 end
 activeStreams[name] = nil
 end)
 end
 
 for name, file in pairs(activeFiles) do
 pcall(function()
 if file.close then
 file.close()
 end
 activeFiles[name] = nil
 end)
 end
 
 audioParts = {}
 audioPlayer = nil
 testAudioPlayer = nil
 configTestAudioPlayer = nil
 finalPodcastPath = nil
 lastGeneratedAudioPath = nil
 isAudioAutoPlayEnabled = false
 
 if tutorialPlayer then
 pcall(function()
 if tutorialPlayer.isPlaying() then
 tutorialPlayer.stop()
 end
 tutorialPlayer.release()
 end)
 tutorialPlayer = nil
 end
 
 if tutorialTimer then
 pcall(function()
 tutorialTimer.cancel()
 end)
 tutorialTimer = nil
 end
 
 local cacheDir = activity.getCacheDir()
 if cacheDir then
 Thread(Runnable{
 run = function()
 local fileList = cacheDir.listFiles()
 if fileList then
 for i=0, #fileList-1 do
 local file = fileList[i]
 if file and file.getName then
 local fileName = file.getName()
 if fileName:match(".*_tts_.*%.mp3$") or fileName:match(".*podcast.*%.mp3$") then
 pcall(function() file.delete() end)
 end
 end
 end
 end
 end
 }).start()
 end
 
 System.gc()
 System.runFinalization()
end
function stopAudio()
 if audioPlayer then
 pcall(function()
 if audioPlayer.isPlaying() then
 audioPlayer.stop()
 end
 audioPlayer.release()
 end)
 audioPlayer = nil
 activePlayers["main"] = nil
 end
 
 if playButton then
 playButton.text = "Listen to Podcast"
 playButton.setEnabled(true)
 end
end
function stopTestAudio()
 if testAudioPlayer then
 pcall(function()
 if testAudioPlayer.isPlaying() then
 testAudioPlayer.stop()
 end
 testAudioPlayer.release()
 end)
 testAudioPlayer = nil
 activePlayers["test"] = nil
 end
end
function stopConfigTestAudio()
 if configTestAudioPlayer then
 pcall(function()
 if configTestAudioPlayer.isPlaying() then
 configTestAudioPlayer.stop()
 end
 configTestAudioPlayer.release()
 end)
 configTestAudioPlayer = nil
 activePlayers["config"] = nil
 end
end
function stopTutorialAudio()
 if tutorialPlayer then
 pcall(function()
 if tutorialPlayer.isPlaying() then
 tutorialPlayer.stop()
 end
 tutorialPlayer.release()
 end)
 tutorialPlayer = nil
 end
 
 if tutorialTimer then
 pcall(function()
 tutorialTimer.cancel()
 end)
 tutorialTimer = nil
 end
end
function showErrorDialog(msg)
 runOnUi(function()
 LuaDialog(activity)
 .setTitle("Error")
 .setMessage(tostring(msg))
 .setPositiveButton("OK", nil)
 .show()
 if generateButton then
 generateButton.text = "Generate Audio"
 generateButton.setEnabled(true)
 audioParts = {}
 finalPodcastPath = nil
 end
 if btnTestSpeak then btnTestSpeak.text = "Test Listen" end
 if podcastProgressBar then podcastProgressBar.setVisibility(View.GONE) end
 end)
end
function showInfoDialog(title, msg)
 runOnUi(function()
 LuaDialog(activity)
 .setTitle(title)
 .setMessage(tostring(msg))
 .setPositiveButton("OK", nil)
 .show()
 end)
end
function updateCharCounter()
 runOnUi(function()
 local text = chatInput.text or ""
 local charCount = string.len(text)
 local tokenEstimate = estimateTokens(text)
 local color = 0xFF000000
 local tokenColor = 0xFF0000FF
 
 if charCount > MAX_CHARS then
 color = 0xFFFF0000
 tokenColor = 0xFFFF0000
 chatInput.text = text:sub(1, MAX_CHARS)
 charCount = MAX_CHARS
 tokenEstimate = estimateTokens(chatInput.text)
 elseif tokenEstimate > MAX_TOKENS then
 tokenColor = 0xFFFFA500
 end
 
 charCounter.text = string.format("Characters: %d/%d | Tokens: %d/%d",
 charCount, MAX_CHARS, tokenEstimate, MAX_TOKENS)
 charCounter.setTextColor(color)
 end)
end
function getPrefs()
 return activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
end
function getGeminiPrefs()
 return activity.getSharedPreferences(GEMINI_PREFS, Context.MODE_PRIVATE)
end
function getGenerationStatePrefs()
 return activity.getSharedPreferences(GENERATION_STATE_PREFS, Context.MODE_PRIVATE)
end
function getBackgroundServicePrefs()
 return activity.getSharedPreferences(BACKGROUND_SERVICE_PREFS, Context.MODE_PRIVATE)
end
function saveBackgroundServiceState(state)
 local prefs = getBackgroundServicePrefs()
 local editor = prefs.edit()
 editor.putBoolean("isRunning", state.isRunning or false)
 editor.putString("mode", state.mode or "")
 editor.putString("text", state.text or "")
 editor.putInt("totalChunks", state.totalChunks or 0)
 editor.putInt("currentChunk", state.currentChunk or 0)
 editor.putString("voiceName", state.voiceName or "")
 editor.putString("emotion", state.emotion or "")
 editor.putFloat("speed", state.speed or 1.0)
 editor.putFloat("pitch", state.pitch or 0.0)
 editor.putLong("startTime", state.startTime or 0)
 editor.apply()
end
function loadBackgroundServiceState()
 local prefs = getBackgroundServicePrefs()
 local state = {}
 state.isRunning = prefs.getBoolean("isRunning", false)
 state.mode = prefs.getString("mode", "")
 state.text = prefs.getString("text", "")
 state.totalChunks = prefs.getInt("totalChunks", 0)
 state.currentChunk = prefs.getInt("currentChunk", 0)
 state.voiceName = prefs.getString("voiceName", "")
 state.emotion = prefs.getString("emotion", "")
 state.speed = prefs.getFloat("speed", 1.0)
 state.pitch = prefs.getFloat("pitch", 0.0)
 state.startTime = prefs.getLong("startTime", 0)
 return state
end
function clearBackgroundServiceState()
 local prefs = getBackgroundServicePrefs()
 local editor = prefs.edit()
 editor.clear()
 editor.apply()
end
function saveGenerationState()
 local prefs = getGenerationStatePrefs()
 local editor = prefs.edit()
 editor.putBoolean("isActive", isGenerationActive)
 editor.putInt("mode", currentGenerationMode or -1)
 editor.putString("text", currentGenerationText or "")
 editor.putInt("progress", currentGenerationProgress)
 editor.putInt("total", currentGenerationTotal)
 local linesJson = cjson.encode(currentGenerationLines)
 editor.putString("lines", linesJson)
 editor.putInt("chunkIndex", currentGenerationChunkIndex)
 editor.putInt("totalChunks", currentGenerationTotalChunks)
 local chunksJson = cjson.encode(currentGenerationChunks)
 editor.putString("chunks", chunksJson)
 editor.apply()
end
function loadGenerationState()
 local prefs = getGenerationStatePrefs()
 isGenerationActive = prefs.getBoolean("isActive", false)
 currentGenerationMode = prefs.getInt("mode", -1)
 currentGenerationText = prefs.getString("text", "")
 currentGenerationProgress = prefs.getInt("progress", 0)
 currentGenerationTotal = prefs.getInt("total", 0)
 currentGenerationChunkIndex = prefs.getInt("chunkIndex", 0)
 currentGenerationTotalChunks = prefs.getInt("totalChunks", 0)
 
 local linesJson = prefs.getString("lines", "[]")
 local status, lines = pcall(cjson.decode, linesJson)
 if status then
 currentGenerationLines = lines
 else
 currentGenerationLines = {}
 end
 
 local chunksJson = prefs.getString("chunks", "[]")
 local status2, chunks = pcall(cjson.decode, chunksJson)
 if status2 then
 currentGenerationChunks = chunks
 else
 currentGenerationChunks = {}
 end
end
function clearGenerationState()
 local prefs = getGenerationStatePrefs()
 local editor = prefs.edit()
 editor.clear()
 editor.apply()
 
 isGenerationActive = false
 currentGenerationMode = nil
 currentGenerationText = nil
 currentGenerationProgress = 0
 currentGenerationTotal = 0
 currentGenerationLines = {}
 currentGenerationChunks = {}
 currentGenerationChunkIndex = 0
 currentGenerationTotalChunks = 0
end
function saveGeminiConfig()
 local prefs = getGeminiPrefs()
 local editor = prefs.edit()
 editor.putString("API_KEY", API_KEY)
 editor.putString("API_PROVIDER", SELECTED_API_PROVIDER)
 editor.apply()
end
function loadGeminiConfig()
 local prefs = getGeminiPrefs()
 API_KEY = prefs.getString("API_KEY", DEFAULT_API_KEY)
 SELECTED_API_PROVIDER = prefs.getString("API_PROVIDER", "OpenAI Official (GPT-4o mini TTS)")
end
function saveConfig()
 local prefs = getPrefs()
 local editor = prefs.edit()
 editor.putInt("mode", currentMode)
 for i = 1, 6 do
 editor.putString("name" .. i, configNames[i])
 editor.putString("voice" .. i, configVoices[i])
 editor.putFloat("speed" .. i, configSpeeds[i])
 editor.putFloat("pitch" .. i, configPitches[i])
 editor.putString("emotion" .. i, configEmotions[i])
 end
 editor.putString("emotionSingle", selectedEmotionSingle)
 editor.putString("textEmotionMode", textEmotionMode)
 editor.putString("customEmotion", customEmotionPrompt)
 if formatSpinner then
 editor.putString("fileFormat", formatSpinner.getSelectedItem() or "mp3")
 end
 editor.apply()
end
function loadConfig()
 loadGeminiConfig()
 local prefs = getPrefs()
 currentMode = prefs.getInt("mode", 0)
 textEmotionMode = prefs.getString("textEmotionMode", "Default (Keep as is)")
 customEmotionPrompt = prefs.getString("customEmotion", "Please read this sentence with a deep, warm voice.")
 selectedEmotionSingle = prefs.getString("emotionSingle", "Default")
 local fileFormat = prefs.getString("fileFormat", "mp3")
 
 for i = 1, 6 do
 configNames[i] = prefs.getString("name" .. i, configNames[i])
 configVoices[i] = prefs.getString("voice" .. i, configVoices[i])
 configSpeeds[i] = prefs.getFloat("speed" .. i, 1.0)
 configPitches[i] = prefs.getFloat("pitch" .. i, 0.0)
 configEmotions[i] = prefs.getString("emotion" .. i, "Default")
 end
 
 runOnUi(function()
 modeSpinner.setSelection(currentMode)
 local function setSpinner(spinner, name, list)
 if not spinner then return end
 for i=1, #list do
 if list[i] == name then
 spinner.setSelection(i - 1)
 return
 end
 end
 end
 if formatSpinner then
 setSpinner(formatSpinner, fileFormat, formatOptions)
 end
 if textEmotionSpinner then
 setSpinner(textEmotionSpinner, textEmotionMode, textEmotionModes)
 end
 updateUIMode(currentMode)
 updateCharCounter()
 end)
end
function writeWavHeader(outStream, totalAudioLen, longSampleRate, channels, byteRate)
 local totalDataLen = totalAudioLen
 local totalSize = totalDataLen + 36
 local bitsPerSample = 16
 local blockAlign = (channels * bitsPerSample) / 8
 
 local calculatedByteRate = longSampleRate * channels * (bitsPerSample / 8)
 local header = {
 82, 73, 70, 70, 
 totalSize % 256, 
 math.floor(totalSize / 256) % 256, 
 math.floor(totalSize / 65536) % 256, 
 math.floor(totalSize / 16777216) % 256,
 87, 65, 86, 69, 
 102, 109, 116, 32, 
 16, 0, 0, 0, 
 1, 0, 
 channels % 256, math.floor(channels / 256) % 256,
 longSampleRate % 256, 
 math.floor(longSampleRate / 256) % 256,
 math.floor(longSampleRate / 65536) % 256, 
 math.floor(longSampleRate / 16777216) % 256,
 calculatedByteRate % 256, 
 math.floor(calculatedByteRate / 256) % 256,
 math.floor(calculatedByteRate / 65536) % 256, 
 math.floor(calculatedByteRate / 16777216) % 256,
 blockAlign % 256, math.floor(blockAlign / 256) % 256,
 bitsPerSample % 256, math.floor(bitsPerSample / 256) % 256,
 100, 97, 116, 97, 
 totalDataLen % 256, 
 math.floor(totalDataLen / 256) % 256,
 math.floor(totalDataLen / 65536) % 256, 
 math.floor(totalDataLen / 16777216) % 256
 }
 for i = 1, #header do
 outStream.write(header[i])
 end
end
function mergeAndSavePodcast()
 local status, err = pcall(function()
 if #audioParts == 0 then
 error("No audio parts to merge.")
 end
 
 import "android.util.Base64"
 import "java.io.FileOutputStream"
 import "java.io.File"
 import "java.io.FileInputStream"
 
 local path = activity.getCacheDir().toString() .. "/gemini_podcast_final.wav"
 local file = File(path)
 if file.exists() then
 file.delete()
 end
 
 local os = FileOutputStream(file)
 local totalAudioLen = 0
 for i, part in ipairs(audioParts) do
 if part then
 totalAudioLen = totalAudioLen + #part
 end
 end
 
 writeWavHeader(os, totalAudioLen, 24000, 1, 48000)
 
 for i, part in ipairs(audioParts) do
 if part then
 os.write(part)
 end
 end
 
 os.flush()
 os.getFD().sync()
 os.close()
 return path
 end)
 
 if status then
 finalPodcastPath = err
 lastGeneratedAudioPath = finalPodcastPath
 lastGeneratedAudioType = "podcast"
 
 runOnUi(function()
 resultText.text = "Success! Podcast merge complete and ready to play."
 if playButton then
 playButton.setVisibility(View.VISIBLE)
 playButton.text = "Listen to Podcast"
 playButton.setEnabled(true)
 end
 if downloadButton then
 downloadButton.setVisibility(View.VISIBLE)
 end
 if formatSpinner then
 formatSpinner.setVisibility(View.VISIBLE)
 end
 if generateButton then
 generateButton.text = "Generate Audio"
 generateButton.setEnabled(true)
 end
 if podcastProgressBar then
 podcastProgressBar.setVisibility(View.GONE)
 end
 
 if audioPlayer then 
 audioPlayer.release() 
 audioPlayer = nil
 end
 audioPlayer = MediaPlayer()
 activePlayers["main"] = audioPlayer
 audioPlayer.setDataSource(finalPodcastPath)
 audioPlayer.prepare()
 end)
 else
 runOnUi(function()
 if generateButton then
 generateButton.text = "Generate Audio"
 generateButton.setEnabled(true)
 end
 if podcastProgressBar then
 podcastProgressBar.setVisibility(View.GONE)
 end
 end)
 showErrorDialog("Merge Error: " .. tostring(err))
 end
end
function getSystemPrompt(emotionName, customPrompt, currentSpeed, currentPitch)
 local emotionText = ""
 if emotionName == "Custom" then
 local p = customPrompt or customEmotionPrompt
 emotionText = #p > 0 and string.format("[%s]", p) or "[READ THIS TEXT]"
 else
 emotionText = emotionMap[emotionName] or "[READ THIS TEXT]"
 end
 
 local speedPrompt = ""
 if currentSpeed and currentSpeed ~= 1.0 then
 if currentSpeed < 0.5 then
 speedPrompt = string.format(" [READ AT EXTREMELY SLOW PACE (%.1fx).]", currentSpeed)
 elseif currentSpeed < 0.8 then
 speedPrompt = string.format(" [READ AT SLOW PACE (%.1fx).]", currentSpeed)
 elseif currentSpeed < 1.0 then
 speedPrompt = string.format(" [READ AT SLIGHTLY SLOWER PACE (%.1fx).]", currentSpeed)
 elseif currentSpeed > 2.0 then
 speedPrompt = string.format(" [READ AT EXTREMELY FAST PACE (%.1fx).]", currentSpeed)
 elseif currentSpeed > 1.5 then
 speedPrompt = string.format(" [READ AT FAST PACE (%.1fx).]", currentSpeed)
 elseif currentSpeed > 1.0 then
 speedPrompt = string.format(" [READ AT SLIGHTLY FASTER PACE (%.1fx).]", currentSpeed)
 end
 end
 
 local pitchPrompt = ""
 if currentPitch and currentPitch ~= 0.0 then
 if currentPitch < -1.5 then
 pitchPrompt = string.format(" [USE EXTREMELY DEEP VOICE (%.1f).]", currentPitch)
 elseif currentPitch < -0.8 then
 pitchPrompt = string.format(" [USE VERY DEEP VOICE (%.1f).]", currentPitch)
 elseif currentPitch < 0.0 then
 pitchPrompt = string.format(" [USE DEEPER VOICE (%.1f).]", currentPitch)
 elseif currentPitch > 1.5 then
 pitchPrompt = string.format(" [USE EXTREMELY HIGH VOICE (%.1f).]", currentPitch)
 elseif currentPitch > 0.8 then
 pitchPrompt = string.format(" [USE VERY HIGH VOICE (%.1f).]", currentPitch)
 else
 pitchPrompt = string.format(" [USE HIGHER VOICE (%.1f).]", currentPitch)
 end
 end
 
 local combinedPrompt = emotionText .. pitchPrompt .. speedPrompt
 return combinedPrompt
end
function splitTextIntoChunks(text, chunkSize)
 if not text or #text == 0 then return {} end
 text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
 if #text <= chunkSize then return {text} end
 
 local chunks = {}
 local lines = {}
 for line in text:gmatch("[^\n]+") do
 table.insert(lines, line)
 end
 
 local currentChunk = ""
 local currentLength = 0
 
 for _, line in ipairs(lines) do
 local lineLength = #line
 if currentLength + lineLength + 1 <= chunkSize then
 if currentLength > 0 then
 currentChunk = currentChunk .. "\n" .. line
 currentLength = currentLength + lineLength + 1
 else
 currentChunk = line
 currentLength = lineLength
 end
 else
 if #currentChunk > 0 then
 table.insert(chunks, currentChunk)
 end
 if lineLength <= chunkSize then
 currentChunk = line
 currentLength = lineLength
 else
 local longLineChunks = {}
 local tempLine = line
 while #tempLine > 0 do
 local chunk = tempLine:sub(1, chunkSize)
 
 local lastBoundary = nil
 local lastSpace = chunk:match("^.*() ")
 local lastPunct = chunk:match("^.*()[%.,;!?۔،؛؟]")
 if lastSpace or lastPunct then
 if lastSpace and lastPunct then
 lastBoundary = math.max(lastSpace, lastPunct)
 elseif lastSpace then
 lastBoundary = lastSpace
 else
 lastBoundary = lastPunct
 end
 end
 
 if lastBoundary and #chunk == chunkSize then
 chunk = chunk:sub(1, lastBoundary - 1)
 end
 table.insert(longLineChunks, chunk)
 tempLine = tempLine:sub(#chunk + 1):gsub("^ +", "")
 end
 for i = 1, #longLineChunks do
 if i == 1 and currentLength == 0 then
 currentChunk = longLineChunks[i]
 currentLength = #longLineChunks[i]
 else
 if currentLength > 0 then
 table.insert(chunks, currentChunk)
 end
 currentChunk = longLineChunks[i]
 currentLength = #longLineChunks[i]
 end
 end
 end
 end
 end
 
 if #currentChunk > 0 then
 table.insert(chunks, currentChunk)
 end
 
 if #chunks == 0 and #text > 0 then
 table.insert(chunks, text:sub(1, chunkSize))
 end
 
 return chunks
end
function getCurrentVoiceMap()
 if SELECTED_API_PROVIDER == "OpenAI Official (GPT-4o mini TTS)" then
 return voiceMapOpenAI
 else
 return voiceMapGemini
 end
end
function updateVoicesBasedOnProvider()
 local currentVoiceMap = getCurrentVoiceMap()
 local voiceNames = {}
 
 for name, _ in pairs(currentVoiceMap) do
 table.insert(voiceNames, name)
 end
 table.sort(voiceNames)
 
 local defaultVoiceID = "Puck"
 if SELECTED_API_PROVIDER == "OpenAI Official (GPT-4o mini TTS)" then
 defaultVoiceID = "alloy"
 end
 for i = 1, 6 do
 if i <= #voiceNames then
 local displayName = voiceNames[i]
 local voiceID = currentVoiceMap[displayName]
 
 configNames[i] = displayName
 configVoices[i] = voiceID
 else
 configNames[i] = (SELECTED_API_PROVIDER == "OpenAI Official (GPT-4o mini TTS)") and "alloy" or "Puck"
 configVoices[i] = defaultVoiceID
 end
 end
 
 saveConfig()
 
 if type(updateVoiceSelector) == "function" then
 updateVoiceSelector()
 end
end
function stringToBytes(str)
 local bytes = {}
 for i = 1, #str do
 bytes[i] = string.byte(str:sub(i, i))
 end
 return bytes
end
function cleanTextForAudio(text)
 if not text then return "" end
 local cleaned = text
 
 cleaned = cleaned:gsub("https?://[%w-_%.%?%:%%%#%=%/]+", "")
 cleaned = cleaned:gsub("www%.[%w-_%.%?%:%%%#%=%/]+", "")
 
 cleaned = cleaned:gsub("%b<>", "")
 
 cleaned = cleaned:gsub("\\", "\\\\")
 cleaned = cleaned:gsub('"', '\\"')
 
 cleaned = cleaned:gsub("[\r\n%c]+", " ")
 
 cleaned = cleaned:gsub("%s%s+", " ")
 cleaned = cleaned:gsub("^%s+", "")
 cleaned = cleaned:gsub("%s+$", "")
 
 if #cleaned == 0 then
 cleaned = "Audio content"
 end
 
 return cleaned
end
function processOpenAIRequest(text, voiceName, emotion, speed, pitch, callback)
 if SELECTED_API_PROVIDER ~= "OpenAI Official (GPT-4o mini TTS)" then
 callback(nil, "Error: Selected provider is not OpenAI. Please check your settings.")
 return 
 end
 local payload = cleanTextForAudio(text)
 
 if emotion and emotion ~= "Default" and emotion ~= "None" then
 if emotion == "Custom" then
 payload = (customEmotionPrompt or "") .. ". " .. payload
 elseif emotionMap and emotionMap[emotion] then
 local emotionText = emotionMap[emotion]
 emotionText = emotionText:gsub("%[", ""):gsub("%]", "")
 if #emotionText > 5 then
 payload = emotionText .. ". " .. payload
 end
 end
 end
 
 local requestBody = {
 model = OPENAI_TTS_MODEL or "tts-1",
 input = payload,
 voice = voiceName or "alloy",
 speed = speed or 1.0,
 response_format = "mp3"
 }
 
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 headers.put("Authorization", "Bearer " .. (API_KEY or ""))
 
 local apiUrl = ""
 if type(API_ENDPOINTS) == "table" and type(API_ENDPOINTS["OpenAI Official (GPT-4o mini TTS)"]) == "function" then
 apiUrl = API_ENDPOINTS["OpenAI Official (GPT-4o mini TTS)"](API_KEY)
 else
 apiUrl = "https://api.openai.com/v1/audio/speech"
 end
 
 Http.post(apiUrl, cjson.encode(requestBody), headers, function(code, content)
 if not activity then return end
 
 if code == 200 and content then
 callback(content, nil)
 else
 local errorMsg = "OpenAI API Error " .. tostring(code)
 
 if content and #content > 0 then
 local status, errData = pcall(cjson.decode, content)
 if status and errData and errData.error then
 errorMsg = errorMsg .. ": " .. tostring(errData.error.message)
 else
 errorMsg = errorMsg .. ": " .. tostring(content):sub(1, 100)
 end
 else
 errorMsg = errorMsg .. " (Check Internet or API Key)"
 end
 
 callback(nil, errorMsg)
 end
 end)
end
function processLongTextInChunks(text, voiceName, emotion, speed, pitch, isSaving)
 stopTestAudio()
 stopAudio()
 
 if not text or #text == 0 then
 showErrorDialog("Text is empty.")
 return
 end
 
 local cleanedText = cleanTextForAudio(text)
 cleanedText = cleanedText:gsub("\r\n", " ")
 cleanedText = cleanedText:gsub("\n", " ")
 cleanedText = cleanedText:gsub("\r", " ")
 cleanedText = cleanedText:gsub("%s+", " ")
 cleanedText = cleanedText:gsub("^%s+", "")
 cleanedText = cleanedText:gsub("%s+$", "")
 
 local chunks = splitTextIntoChunks(cleanedText, CHUNK_SIZE)
 if #chunks == 0 then
 showErrorDialog("Could not split text into chunks.")
 runOnUi(function()
 if generateButton then
 generateButton.text = "Generate Audio"
 generateButton.setEnabled(true)
 end
 if resultText then resultText.text = "Error: Split failed" end
 end)
 return
 end
 
 isGenerationActive = true
 currentGenerationMode = 0
 currentGenerationText = text
 currentGenerationChunks = chunks
 currentGenerationChunkIndex = 0
 currentGenerationTotalChunks = #chunks
 audioParts = {}
 finalPodcastPath = nil
 saveGenerationState()
 
 local bgState = {
 isRunning = true,
 mode = "single_long",
 text = text,
 totalChunks = #chunks,
 currentChunk = 0,
 voiceName = voiceName,
 emotion = emotion,
 speed = speed,
 pitch = pitch,
 startTime = System.currentTimeMillis()
 }
 saveBackgroundServiceState(bgState)
 
 runOnUi(function()
 generateButton.text = string.format("Processing (0/%d)", #chunks)
 generateButton.setEnabled(false)
 if podcastProgressBar then
 podcastProgressBar.setVisibility(View.VISIBLE)
 podcastProgressBar.setProgress(0)
 podcastProgressBar.setMax(#chunks)
 end
 if playButton then playButton.setVisibility(View.GONE) end
 if downloadButton then downloadButton.setVisibility(View.GONE) end
 if formatSpinner then formatSpinner.setVisibility(View.GONE) end
 if resultText then
 resultText.text = string.format("Starting processing... (0/%d)", #chunks)
 end
 end)
 
 acquireWakeLock()
 processNextChunk(chunks, voiceName, emotion, speed, pitch, isSaving, 1, #chunks)
end
function processNextChunk(chunks, voiceName, emotion, speed, pitch, isSaving, index, totalChunks)
 if index > totalChunks then
 mergeAndSavePodcast()
 releaseWakeLock()
 clearBackgroundServiceState()
 return
 end
 
 currentGenerationChunkIndex = index
 saveGenerationState()
 
 local bgState = loadBackgroundServiceState()
 if bgState then
 bgState.currentChunk = index
 saveBackgroundServiceState(bgState)
 end
 
 local currentChunk = chunks[index]
 runOnUi(function()
 if generateButton then
 generateButton.text = string.format("Processing (%d/%d)", index, totalChunks)
 end
 if resultText then
 resultText.text = string.format("Processing chunk %d/%d\nCharacters: %d", 
 index, totalChunks, #currentChunk)
 end
 if podcastProgressBar then
 podcastProgressBar.setProgress(math.floor(index / totalChunks * 100))
 end
 end)
 
 local function handleChunkError(errorMsg)
 isGenerationActive = false
 clearGenerationState()
 clearBackgroundServiceState()
 releaseWakeLock()
 runOnUi(function()
 if generateButton then
 generateButton.text = "Generate Audio"
 generateButton.setEnabled(true)
 end
 if resultText then
 resultText.text = "Failed: " .. errorMsg
 end
 if podcastProgressBar then
 podcastProgressBar.setVisibility(View.GONE)
 end
 end)
 showErrorDialog(errorMsg)
 end
 
 if SELECTED_API_PROVIDER == "OpenAI Official (GPT-4o mini TTS)" then
 processOpenAIRequest(currentChunk, voiceName, emotion, speed, pitch, function(audioData, err)
 if audioData then
 table.insert(audioParts, stringToBytes(audioData))
 processNextChunk(chunks, voiceName, emotion, speed, pitch, isSaving, index + 1, totalChunks)
 else
 handleChunkError("OpenAI error at chunk " .. index .. ": " .. tostring(err))
 end
 end)
 else
 local systemPrompt = getSystemPrompt(emotion, nil, speed, pitch)
 local inputText = currentChunk
 local speechConfig = {
 voiceConfig = { prebuiltVoiceConfig = { voiceName = voiceName } }
 }
 
 local requestBody
 local apiUrl = updateApiUrl()
 requestBody = {
 contents = {
 { parts = {{ text = inputText }} }
 },
 generationConfig = {
 responseModalities = {"AUDIO"},
 speechConfig = speechConfig,
 temperature = 0.1,
 maxOutputTokens = 5000
 }
 }
 
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 headers.put("x-goog-api-client", "gl-kotlin/2.1.0-ai fire/16.5.0")
 
 local powerManager = activity.getSystemService(Context.POWER_SERVICE)
 local chunkWakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "PodcastGen:ChunkLock")
 chunkWakeLock.acquire(2*60*1000)
 
 Http.post(apiUrl, cjson.encode(requestBody), headers, function(code, content)
 if chunkWakeLock then chunkWakeLock.release() end
 if code == 200 then
 local status, data = pcall(cjson.decode, content)
 if status and data and data.candidates and #data.candidates > 0 and data.candidates[1] and data.candidates[1].content and data.candidates[1].content.parts then
 local base64Audio = nil
 for i=1, #data.candidates[1].content.parts do
 if data.candidates[1].content.parts[i].inlineData then
 base64Audio = data.candidates[1].content.parts[i].inlineData.data
 break
 end
 end
 if base64Audio then
 local audioBytes = Base64.decode(base64Audio, Base64.NO_WRAP)
 table.insert(audioParts, audioBytes)
 processNextChunk(chunks, voiceName, emotion, speed, pitch, isSaving, index + 1, totalChunks)
 else
 handleChunkError("Audio error at chunk " .. index .. ": No audio data")
 end
 else
 handleChunkError("JSON error at chunk " .. index)
 end
 else
 handleChunkError("HTTP error at chunk " .. index .. ": " .. code)
 end
 end)
 end
end
function testSpeak(text, voiceName, currentEmotion, currentSpeed, currentPitch, isSaving, isConfigTest)
 if isConfigTest then
 stopConfigTestAudio()
 else
 stopTestAudio()
 end
 
 if not text or #text == 0 then
 showErrorDialog("Text is empty.")
 return
 end
 
 if #text > CHUNK_SIZE then
 processLongTextInChunks(text, voiceName, currentEmotion, currentSpeed, currentPitch, isSaving)
 return
 end
 
 local cleanedText = cleanTextForAudio(text)
 
 if SELECTED_API_PROVIDER == "OpenAI Official (GPT-4o mini TTS)" then
 processOpenAIRequest(cleanedText, voiceName, currentEmotion, currentSpeed, currentPitch, function(audioData, err)
 runOnUi(function()
 if not isConfigTest then
 if generateButton then
 generateButton.text = "Generate Audio"
 generateButton.setEnabled(true)
 end
 if resultText then resultText.text = "Ready" end
 if btnTestSpeak then 
 btnTestSpeak.text = "Test Listen" 
 end
 else
 if btnConfigTestSpeak then
 btnConfigTestSpeak.text = "Test Listen"
 end
 end
 end)
 
 if audioData then
 local tempPath = activity.getCacheDir().toString() .. (isConfigTest and "/config_tts_audio.mp3" or "/single_tts_audio.mp3")
 local file = File(tempPath)
 local os = FileOutputStream(file)
 activeFiles["temp_audio"] = os
 
 import "android.util.Base64"
 local bytes = Base64.decode(audioData, Base64.NO_WRAP)
 os.write(bytes)
 os.flush()
 os.close()
 activeFiles["temp_audio"] = nil
 
 runOnUi(function()
 if isConfigTest then
 stopConfigTestAudio()
 configTestAudioPlayer = MediaPlayer()
 activePlayers["config"] = configTestAudioPlayer
 local success, errorMsg = pcall(function()
 configTestAudioPlayer.setDataSource(tempPath)
 configTestAudioPlayer.prepare()
 configTestAudioPlayer.start()
 end)
 if success then
 if btnConfigTestSpeak then
 btnConfigTestSpeak.text = "Stop"
 end
 else
 if btnConfigTestSpeak then
 btnConfigTestSpeak.text = "Test Listen"
 end
 showErrorDialog("Config test error: " .. errorMsg)
 end
 else
 stopTestAudio()
 finalPodcastPath = tempPath
 lastGeneratedAudioPath = tempPath
 lastGeneratedAudioType = "single"
 
 if resultText then
 resultText.text = isSaving and "Complete! Single audio has been created." or "Playing test audio."
 end
 
 if playButton then
 playButton.setVisibility(View.VISIBLE)
 playButton.text = "Listen"
 playButton.setEnabled(true)
 end
 
 if downloadButton then
 downloadButton.setVisibility(View.VISIBLE)
 end
 
 if formatSpinner then
 formatSpinner.setVisibility(View.VISIBLE)
 end
 
 testAudioPlayer = MediaPlayer()
 activePlayers["test"] = testAudioPlayer
 local success, errorMsg = pcall(function()
 testAudioPlayer.setDataSource(tempPath)
 testAudioPlayer.prepare()
 if not isSaving then
 testAudioPlayer.start()
 if playButton then
 playButton.text = "Stop"
 end
 isAudioAutoPlayEnabled = true
 else
 isAudioAutoPlayEnabled = false
 end
 end)
 if not success then
 if playButton then
 playButton.setEnabled(false)
 end
 showErrorDialog("Audio error: " .. errorMsg)
 end
 
 testAudioPlayer.setOnCompletionListener(MediaPlayer.OnCompletionListener{
 onCompletion = function(mp)
 runOnUi(function()
 if btnTestSpeak then 
 btnTestSpeak.text = "Test Listen" 
 end
 if playButton then
 playButton.text = "Listen"
 playButton.setEnabled(true)
 end
 isAudioAutoPlayEnabled = false
 end)
 end
 })
 
 if isSaving and isDialogHidden then reopenDialogWithCurrentState() end
 end
 end)
 else
 runOnUi(function() if resultText then resultText.text = "Error" end end)
 showErrorDialog("OpenAI TTS error: " .. tostring(err))
 end
 end)
 return
 end
 
 local systemPrompt = getSystemPrompt(currentEmotion, nil, currentSpeed, currentPitch)
 local inputText = cleanedText
 
 local voiceToUse = voiceName
 local currentVoiceMap = getCurrentVoiceMap()
 local isValidVoice = false
 
 for _, v in pairs(currentVoiceMap) do
 if v == voiceName then
 isValidVoice = true
 break
 end
 end
 
 if not isValidVoice then
 voiceToUse = "Puck" 
 end
 
 local speechConfig = { voiceConfig = { prebuiltVoiceConfig = { voiceName = voiceToUse } } }
 
 local requestBody = {
 contents = { { parts = { { text = inputText } } } },
 generationConfig = {
 responseModalities = { "AUDIO" },
 speechConfig = speechConfig,
 temperature = 0.5,
 maxOutputTokens = 8000
 },
 safetySettings = {
 { category = "HARM_CATEGORY_HARASSMENT", threshold = "BLOCK_NONE" },
 { category = "HARM_CATEGORY_HATE_SPEECH", threshold = "BLOCK_NONE" },
 { category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = "BLOCK_NONE" },
 { category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = "BLOCK_NONE" }
 }
 }
 
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 headers.put("x-goog-api-client", "gl-kotlin/2.1.0-ai fire/16.5.0")
 
 Http.post(updateApiUrl(), cjson.encode(requestBody), headers, function(code, content)
 runOnUi(function()
 if not isConfigTest then
 if generateButton then
 generateButton.text = "Generate Audio"
 generateButton.setEnabled(true)
 end
 if resultText then resultText.text = "Ready" end
 if btnTestSpeak then
 btnTestSpeak.text = "Test Listen"
 end
 else
 if btnConfigTestSpeak then
 btnConfigTestSpeak.text = "Test Listen"
 end
 end
 end)
 
 if code == 200 then
 local status, data = pcall(cjson.decode, content)
 if status and data and data.candidates and #data.candidates > 0 and data.candidates[1].content and data.candidates[1].content.parts then
 local base64Audio = nil
 for i = 1, #data.candidates[1].content.parts do
 if data.candidates[1].content.parts[i].inlineData then
 base64Audio = data.candidates[1].content.parts[i].inlineData.data
 break
 end
 end
 
 if base64Audio then
 import "android.util.Base64"
 local audioBytes = Base64.decode(base64Audio, Base64.NO_WRAP)
 local tempPath = activity.getCacheDir().toString() .. (isConfigTest and "/config_tts_audio.wav" or "/single_tts_audio.wav")
 local file = File(tempPath)
 local os = FileOutputStream(file)
 activeFiles["temp_audio"] = os
 
 writeWavHeader(os, #audioBytes, 24000, 1, 48000)
 os.write(audioBytes)
 os.flush()
 os.close()
 activeFiles["temp_audio"] = nil
 
 runOnUi(function()
 if isConfigTest then
 stopConfigTestAudio()
 configTestAudioPlayer = MediaPlayer()
 activePlayers["config"] = configTestAudioPlayer
 local success, errorMsg = pcall(function()
 configTestAudioPlayer.setDataSource(tempPath)
 configTestAudioPlayer.prepare()
 configTestAudioPlayer.start()
 end)
 if success then
 if btnConfigTestSpeak then
 btnConfigTestSpeak.text = "Stop"
 end
 else
 if btnConfigTestSpeak then
 btnConfigTestSpeak.text = "Test Listen"
 end
 showErrorDialog("Config test error: " .. errorMsg)
 end
 else
 stopTestAudio()
 finalPodcastPath = tempPath
 lastGeneratedAudioPath = tempPath
 lastGeneratedAudioType = "single"
 
 if resultText then
 resultText.text = isSaving and "Complete! Single audio has been created." or "Playing test audio."
 end
 
 if playButton then
 playButton.setVisibility(View.VISIBLE)
 playButton.text = "Listen"
 playButton.setEnabled(true)
 end
 
 if downloadButton then
 downloadButton.setVisibility(View.VISIBLE)
 end
 
 if formatSpinner then
 formatSpinner.setVisibility(View.VISIBLE)
 end
 
 testAudioPlayer = MediaPlayer()
 activePlayers["test"] = testAudioPlayer
 local success, errorMsg = pcall(function()
 testAudioPlayer.setDataSource(tempPath)
 testAudioPlayer.prepare()
 if not isSaving then
 testAudioPlayer.start()
 if playButton then
 playButton.text = "Stop"
 end
 isAudioAutoPlayEnabled = true
 else
 isAudioAutoPlayEnabled = false
 end
 end)
 if not success then
 if playButton then
 playButton.setEnabled(false)
 end
 showErrorDialog("Audio error: " .. errorMsg)
 end
 
 testAudioPlayer.setOnCompletionListener(MediaPlayer.OnCompletionListener{
 onCompletion = function(mp)
 runOnUi(function()
 if btnTestSpeak then 
 btnTestSpeak.text = "Test Listen" 
 end
 if playButton then
 playButton.text = "Listen"
 playButton.setEnabled(true)
 end
 isAudioAutoPlayEnabled = false
 end)
 end
 })
 
 if isSaving and isDialogHidden then reopenDialogWithCurrentState() end
 end
 end)
 else
 showErrorDialog("Audio error: No audio data received.")
 end
 else
 runOnUi(function() if resultText then resultText.text = "JSON Error" end end)
 showErrorDialog("JSON error: Invalid response. Content: " .. content)
 end
 else
 runOnUi(function() if resultText then resultText.text = "HTTP Error " .. code end end)
 showErrorDialog("HTTP error " .. code .. ": " .. (content or "No response"))
 end
 end)
end
function acquireWakeLock()
 if not backgroundWakeLock then
 local powerManager = activity.getSystemService(Context.POWER_SERVICE)
 backgroundWakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "PodcastGen:BackgroundLock")
 end
 if backgroundWakeLock and not backgroundWakeLock.isHeld() then
 backgroundWakeLock.acquire()
 end
end
function releaseWakeLock()
 if backgroundWakeLock then
 pcall(function()
 if backgroundWakeLock.isHeld() then
 backgroundWakeLock.release()
 end
 end)
 backgroundWakeLock = nil
 end
end
function processMultiVoicePodcast()
 local rawText = scriptInput.text
 if #rawText == 0 then
 showErrorDialog("Empty script.")
 return
 end
 
 local processedText = processTextForEmotion(rawText)
 local lines = {}
 local totalCharCount = 0
 
 for line in processedText:gmatch("[^\r\n]+") do
 local speaker, content = line:match("^(.-):%s*(.+)")
 
 if speaker and content then
 speaker = speaker:match("^%s*(.-)%s*$")
 content = content:match("^%s*(.-)%s*$")
 
 if #content > 0 then
 local cleanContent = content:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("[\r\n]+", " ")
 
 table.insert(lines, {speaker = speaker, text = cleanContent})
 totalCharCount = totalCharCount + string.len(cleanContent)
 end
 end
 end
 
 if #lines == 0 then
 showErrorDialog("Empty script or incorrect format. Use 'Name: Message' format.")
 return
 end
 
 isGenerationActive = true
 currentGenerationMode = currentMode
 currentGenerationText = rawText
 currentGenerationProgress = 0
 currentGenerationTotal = #lines
 currentGenerationLines = lines
 saveGenerationState()
 
 audioParts = {}
 finalPodcastPath = nil
 acquireWakeLock()
 
 runOnUi(function()
 if generateButton then
 generateButton.setEnabled(false)
 generateButton.text = "Processing..."
 end
 if resultText then
 resultText.text = "Starting podcast generation for " .. #lines .. " lines. Please wait..."
 end
 if podcastProgressBar then
 podcastProgressBar.setVisibility(View.VISIBLE)
 podcastProgressBar.setMax(#lines)
 podcastProgressBar.setProgress(0)
 end
 end)
 
 if processMultiVoiceLine then
 processMultiVoiceLine(lines, 1, #lines)
 else
 showErrorDialog("Error: processMultiVoiceLine function not found.")
 end
end
function resumeGenerationIfNeeded()
 loadGenerationState()
 local bgState = loadBackgroundServiceState()
 
 if bgState.isRunning then
 local currentTime = System.currentTimeMillis()
 local elapsedTime = currentTime - bgState.startTime
 if elapsedTime > 30 * 60 * 1000 then
 clearBackgroundServiceState()
 clearGenerationState()
 return false
 end
 
 if not isDialogHidden and dlg then
 runOnUi(function()
 resultText.text = "Resuming background generation..."
 audioParts = {}
 finalPodcastPath = nil
 generateButton.text = "Processing " .. bgState.totalChunks .. " chunks..."
 podcastProgressBar.setVisibility(View.VISIBLE)
 podcastProgressBar.setProgress(math.floor(bgState.currentChunk / bgState.totalChunks * 100))
 playButton.setVisibility(View.GONE)
 downloadButton.setVisibility(View.GONE)
 formatSpinner.setVisibility(View.GONE)
 generateButton.setEnabled(false)
 acquireWakeLock()
 
 local chunks = splitTextIntoChunks(bgState.text, CHUNK_SIZE)
 processNextChunk(chunks, bgState.voiceName, bgState.emotion, bgState.speed, bgState.pitch, true, bgState.currentChunk + 1, bgState.totalChunks)
 end)
 else
 reopenDialogWithCurrentState()
 end
 return true
 end
 
 if isGenerationActive and currentGenerationMode and #currentGenerationLines > 0 then
 if not isDialogHidden and dlg then
 runOnUi(function()
 resultText.text = "Resuming audio generation..."
 audioParts = {}
 finalPodcastPath = nil
 generateButton.text = "Processing " .. currentGenerationTotal .. " lines..."
 podcastProgressBar.setVisibility(View.VISIBLE)
 podcastProgressBar.setProgress(currentGenerationProgress)
 playButton.setVisibility(View.GONE)
 downloadButton.setVisibility(View.GONE)
 formatSpinner.setVisibility(View.GONE)
 generateButton.setEnabled(false)
 acquireWakeLock()
 processMultiVoiceLine(currentGenerationLines, currentGenerationProgress + 1, currentGenerationTotal)
 end)
 else
 reopenDialogWithCurrentState()
 end
 return true
 end
 
 if isGenerationActive and currentGenerationMode == 0 and #currentGenerationChunks > 0 then
 if not isDialogHidden and dlg then
 runOnUi(function()
 resultText.text = "Resuming long text processing..."
 audioParts = {}
 finalPodcastPath = nil
 generateButton.text = "Processing " .. currentGenerationTotalChunks .. " chunks..."
 podcastProgressBar.setVisibility(View.VISIBLE)
 podcastProgressBar.setProgress(math.floor(currentGenerationChunkIndex / currentGenerationTotalChunks * 100))
 playButton.setVisibility(View.GONE)
 downloadButton.setVisibility(View.GONE)
 formatSpinner.setVisibility(View.GONE)
 generateButton.setEnabled(false)
 acquireWakeLock()
 processNextChunk(currentGenerationChunks, configVoices[1], selectedEmotionSingle, configSpeeds[1], configPitches[1], true, currentGenerationChunkIndex + 1, currentGenerationTotalChunks)
 end)
 else
 reopenDialogWithCurrentState()
 end
 return true
 end
 
 return false
end
function processOpenAIMultiVoiceLine(speakerName, textToSpeak, selectedVoice, currentEmotion, tempCustomPrompt, currentSpeed, currentPitch, callback)
 if SELECTED_API_PROVIDER ~= "OpenAI Official (GPT-4o mini TTS)" then
 local systemPrompt = getSystemPrompt(currentEmotion, tempCustomPrompt, currentSpeed, currentPitch)
 local inputText = cleanTextForAudio(textToSpeak)
 
 local voiceToUse = selectedVoice
 local currentVoiceMap = getCurrentVoiceMap()
 local isValidVoice = false
 
 for _, v in pairs(currentVoiceMap) do
 if v == selectedVoice then
 isValidVoice = true
 break
 end
 end
 
 if not isValidVoice then
 voiceToUse = "Puck" -- Gemini کا ڈیفالٹ وائس
 end
 
 local speechConfig = {
 voiceConfig = { prebuiltVoiceConfig = { voiceName = voiceToUse } }
 }
 
 local requestBody = {
 contents = { { parts = { { text = inputText } } } },
 generationConfig = {
 responseModalities = {"AUDIO"},
 speechConfig = speechConfig,
 temperature = 0.1,
 maxOutputTokens = 5000
 }
 }
 
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 headers.put("x-goog-api-client", "gl-kotlin/2.1.0-ai fire/16.5.0")
 
 Http.post(updateApiUrl(), cjson.encode(requestBody), headers, function(code, content)
 if code == 200 then
 local status, data = pcall(cjson.decode, content)
 if status and data and data.candidates and #data.candidates > 0 and data.candidates[1] and data.candidates[1].content and data.candidates[1].content.parts then
 local base64Audio = nil
 for i=1, #data.candidates[1].content.parts do
 if data.candidates[1].content.parts[i].inlineData then
 base64Audio = data.candidates[1].content.parts[i].inlineData.data
 break
 end
 end
 if base64Audio then
 local audioBytes = Base64.decode(base64Audio, Base64.NO_WRAP)
 callback(audioBytes, nil)
 else
 callback(nil, "No audio data in Gemini response")
 end
 else
 callback(nil, "Invalid JSON response from Gemini")
 end
 else
 local errorMsg = "Gemini Error: " .. code
 if content then
 local status, errData = pcall(cjson.decode, content)
 if status and errData and errData.error then
 errorMsg = errorMsg .. " - " .. errData.error.message
 end
 end
 callback(nil, errorMsg)
 end
 end)
 return
 end
 
 local payload = cleanTextForAudio(textToSpeak)
 if currentEmotion and currentEmotion ~= "Default" and currentEmotion ~= "None" then
 if currentEmotion == "Custom" and tempCustomPrompt then
 payload = tempCustomPrompt .. ". " .. payload
 elseif emotionMap[currentEmotion] then
 local emotionText = emotionMap[currentEmotion]
 emotionText = emotionText:gsub("%[", ""):gsub("%]", "")
 if #emotionText > 5 then
 payload = emotionText .. ". " .. payload
 end
 end
 end
 
 local voiceToUse = selectedVoice
 local currentVoiceMap = getCurrentVoiceMap()
 local isValidVoice = false
 
 for _, v in pairs(currentVoiceMap) do
 if v == selectedVoice then
 isValidVoice = true
 break
 end
 end
 
 if not isValidVoice then
 voiceToUse = "alloy" -- OpenAI کا ڈیفالٹ وائس
 end
 
 local requestBody = {
 model = OPENAI_TTS_MODEL,
 input = payload,
 voice = voiceToUse,
 speed = currentSpeed,
 response_format = "mp3"
 }
 
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 headers.put("Authorization", "Bearer " .. API_KEY)
 
 Http.post(API_ENDPOINTS["OpenAI Official (GPT-4o mini TTS)"](API_KEY), cjson.encode(requestBody), headers, function(code, content)
 if code == 200 then
 callback(stringToBytes(content), nil)
 else
 local errorMsg = "OpenAI Error: " .. code
 if content then
 local status, errData = pcall(cjson.decode, content)
 if status and errData and errData.error then
 errorMsg = errorMsg .. " - " .. errData.error.message
 end
 end
 callback(nil, errorMsg)
 end
 end)
end
function processMultiVoiceLine(dialogueList, index, totalLines)
 if index > totalLines then
 runOnUi(function()
 if resultText then
 resultText.text = "Status: Joining all voice parts, please wait..."
 end
 if podcastProgressBar then
 podcastProgressBar.setProgress(100)
 end
 end)
 
 mergeAndSavePodcast()
 releaseWakeLock()
 clearBackgroundServiceState()
 return
 end
 
 currentGenerationProgress = index - 1
 saveGenerationState()
 
 local currentLine = dialogueList[index]
 local speakerName = currentLine.speaker
 local rawText = currentLine.text
 
 local selectedVoice = SELECTED_API_PROVIDER == "OpenAI Official (GPT-4o mini TTS)" and "alloy" or "Puck"
 local defaultEmotion = "Default"
 local currentSpeed = 1.0
 local currentPitch = 0.0
 
 for i = 1, #configNames do
 if speakerName == configNames[i] then
 selectedVoice = configVoices[i]
 defaultEmotion = configEmotions[i]
 currentSpeed = configSpeeds[i]
 currentPitch = configPitches[i]
 break
 end
 end
 
 if SELECTED_API_PROVIDER ~= "OpenAI Official (GPT-4o mini TTS)" then
 local currentVoiceMap = getCurrentVoiceMap()
 local isValidVoice = false
 for _, v in pairs(currentVoiceMap) do
 if v == selectedVoice then
 isValidVoice = true
 break
 end
 end
 if not isValidVoice then selectedVoice = "Puck" end
 end
 
 local emotionTag, contentText = rawText:match("^%s*%[(.-)%]%s*(.*)$")
 local currentEmotion = defaultEmotion
 local textToSpeak = rawText
 local tempCustomPrompt = nil
 
 if emotionTag then
 local normalizedEmotion = emotionTag:match("^%s*(.-)%s*$")
 local foundEmotion = false
 for _, v in ipairs(emotionsFull) do
 if v:match("^(.-)%s*%(") == normalizedEmotion or v == normalizedEmotion then
 currentEmotion = v
 textToSpeak = contentText
 foundEmotion = true
 break
 end
 end
 if not foundEmotion then
 currentEmotion = "Custom"
 tempCustomPrompt = normalizedEmotion
 textToSpeak = contentText
 end
 else
 textToSpeak = rawText
 end
 
 textToSpeak = cleanTextForAudio(textToSpeak)
 
 runOnUi(function()
 local displayEmotion = tempCustomPrompt and "Custom: " .. tempCustomPrompt or currentEmotion
 if resultText then
 resultText.text = string.format("Processing (%d/%d)\nSpeaker: %s | Voice: %s\nStatus: Generating audio...",
 index, totalLines, speakerName, selectedVoice)
 end
 if podcastProgressBar then
 podcastProgressBar.setVisibility(View.VISIBLE)
 local progress = math.floor(((index - 1) / totalLines) * 100)
 podcastProgressBar.setProgress(progress)
 end
 end)
 
 local function handleLineError(errMsg)
 isGenerationActive = false
 clearGenerationState()
 clearBackgroundServiceState()
 releaseWakeLock()
 runOnUi(function()
 if generateButton then
 generateButton.text = "Generate Audio"
 generateButton.setEnabled(true)
 end
 if resultText then
 resultText.text = "Error: " .. errMsg
 end
 if podcastProgressBar then
 podcastProgressBar.setVisibility(View.GONE)
 end
 showErrorDialog(errMsg)
 end)
 end
 if SELECTED_API_PROVIDER == "OpenAI Official (GPT-4o mini TTS)" then
 processOpenAIMultiVoiceLine(speakerName, textToSpeak, selectedVoice, currentEmotion, tempCustomPrompt, currentSpeed, currentPitch, function(audioData, err)
 if audioData then
 table.insert(audioParts, audioData)
 processMultiVoiceLine(dialogueList, index + 1, totalLines)
 else
 handleLineError("OpenAI error at line " .. index .. ": " .. tostring(err))
 end
 end)
 else
 local speechConfig = { voiceConfig = { prebuiltVoiceConfig = { voiceName = selectedVoice } } }
 
 local requestBody = {
 contents = { { parts = { { text = textToSpeak } } } },
 generationConfig = {
 responseModalities = {"AUDIO"},
 speechConfig = speechConfig,
 temperature = 0.5, -- تھوڑی سی ٹمپریچر بڑھائی گئی تاکہ ماڈل لچکدار رہے
 maxOutputTokens = 5000
 },
 safetySettings = {
 { category = "HARM_CATEGORY_HARASSMENT", threshold = "BLOCK_NONE" },
 { category = "HARM_CATEGORY_HATE_SPEECH", threshold = "BLOCK_NONE" },
 { category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = "BLOCK_NONE" },
 { category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = "BLOCK_NONE" }
 }
 }
 
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 
 local powerManager = activity.getSystemService(Context.POWER_SERVICE)
 local wakeLockHttp = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "PodcastGen:HTTPLock")
 wakeLockHttp.acquire(2*60*1000)
 
 Http.post(updateApiUrl(), cjson.encode(requestBody), headers, function(code, content)
 if wakeLockHttp.isHeld() then wakeLockHttp.release() end
 
 if code == 200 then
 local status, data = pcall(cjson.decode, content)
 if status and data and data.candidates and #data.candidates > 0 then
 local cand = data.candidates[1]
 
 if cand.finishReason and cand.finishReason ~= "STOP" and cand.finishReason ~= "MAX_TOKENS" then
 handleLineError("Line " .. index .. " (" .. speakerName .. ") blocked. Reason: " .. cand.finishReason .. "\nTry adding more context to the text.")
 return
 end
 
 local base64Audio = nil
 if cand.content and cand.content.parts then
 for i=1, #cand.content.parts do
 if cand.content.parts[i].inlineData then
 base64Audio = cand.content.parts[i].inlineData.data
 break
 end
 end
 end
 
 if base64Audio then
 local audioBytes = Base64.decode(base64Audio, Base64.NO_WRAP)
 table.insert(audioParts, audioBytes)
 processMultiVoiceLine(dialogueList, index + 1, totalLines)
 else
 handleLineError("Audio error at line " .. index .. ": No audio data returned.")
 end
 else
 handleLineError("JSON error at line " .. index .. ": Invalid structure.")
 end
 else
 handleLineError("HTTP error at line " .. index .. ": Code " .. code)
 end
 end)
 end
end
function saveAudioFile(sourcePath, selectedFormat)
 local status, savedPath = pcall(function()
 local sourceFile = File(sourcePath)
 if not sourceFile.exists() then
 error("Source file does not exist: " .. sourcePath)
 end
 
 local destDir = File(USER_AUDIO_DIR)
 if not destDir.exists() then
 destDir.mkdirs()
 end
 
 local timestamp = os.date("%Y%m%d_%H%M%S")
 local baseName = ""
 if currentMode == 0 then
 baseName = "single_"
 elseif currentMode == 1 then
 baseName = "dialogue_"
 elseif currentMode == 2 then
 baseName = "podcast4_"
 else
 baseName = "podcast6_"
 end
 
 local newFileName = baseName .. timestamp .. "." .. selectedFormat
 local destFile = File(destDir, newFileName)
 local savedPath = destFile.getAbsolutePath()
 
 local input = FileInputStream(sourceFile)
 local output = FileOutputStream(destFile)
 local buffer = byte[1024]
 local len
 while true do
 len = input.read(buffer)
 if len == -1 then break end
 output.write(buffer, 0, len)
 end
 output.flush()
 output.close()
 input.close()
 
 local mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
 mediaScanIntent.setData(Uri.fromFile(destFile))
 activity.sendBroadcast(mediaScanIntent)
 
 return savedPath
 end)
 
 if not status then
 return nil, savedPath
 end
 return savedPath
end
function showCustomEmotionDialog(voiceIndex, onSaveCallback)
 local currentPrompt = customEmotionPrompt
 local name = configNames[voiceIndex]
 local title = "Custom Emotion for " .. name
 if voiceIndex == 0 then
 title = "Custom Emotion for Single Voice"
 end
 
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 
 local promptLabel = TextView(activity)
 promptLabel.text = "Enter emotion/intonation description (Prompt format):"
 promptLabel.layout_width = LinearLayout.LayoutParams.MATCH_PARENT
 mainLayout.addView(promptLabel)
 
 local promptInput = EditText(activity)
 promptInput.text = currentPrompt
 promptInput.layout_width = LinearLayout.LayoutParams.MATCH_PARENT
 promptInput.layout_height = LinearLayout.LayoutParams.WRAP_CONTENT
 promptInput.hint = "Example: Read with a deep, warm voice..."
 mainLayout.addView(promptInput)
 
 scrollView.addView(mainLayout)
 
 local d = LuaDialog(activity)
 .setTitle(title)
 .setView(scrollView)
 .setPositiveButton("Apply", function()
 local newPrompt = promptInput.text
 if #newPrompt > 0 then
 customEmotionPrompt = newPrompt
 saveConfig()
 if onSaveCallback then
 onSaveCallback(newPrompt)
 end
 end
 end)
 .setNegativeButton("Cancel", nil)
 d.show()
end
local function setupControlSeekBar(seekBar, textView, isSpeed, currentVal, onValueChange)
 local minVal, maxVal, step = isSpeed and 0.5 or -2.0, isSpeed and 3.0 or 2.0, isSpeed and 0.1 or 0.2
 local range = maxVal - minVal
 seekBar.setMax(100)
 
 local function updateValue(progress)
 local value = minVal + (range * progress / 100)
 local snappedValue = math.floor(value / step + 0.5) * step
 if isSpeed then
 textView.text = string.format("Speed: %.1fx", snappedValue)
 else
 textView.text = string.format("Pitch: %.1f", snappedValue)
 end
 onValueChange(snappedValue)
 end
 
 seekBar.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
 onProgressChanged = function(seekBar, progress, fromUser)
 updateValue(progress)
 end,
 onStartTrackingTouch = function() end,
 onStopTrackingTouch = function(seekBar)
 updateValue(seekBar.getProgress())
 vibrate()
 end
 })
 
 local progress = math.floor(((currentVal - minVal) / range) * 100)
 seekBar.setProgress(progress)
end
function showVoiceConfigDialog(voiceIndex)
 local currentName = configNames[voiceIndex]
 local currentVoiceID = configVoices[voiceIndex]
 local currentEmotion = configEmotions[voiceIndex]
 local currentSpeed = configSpeeds[voiceIndex]
 local currentPitch = configPitches[voiceIndex]
 local currentVoiceDisplay = ""
 
 local currentVoiceMap = getCurrentVoiceMap()
 for k, v in pairs(currentVoiceMap) do
 if v == currentVoiceID then
 currentVoiceDisplay = k
 break
 end
 end
 
 if currentVoiceDisplay == "" then
 for k, v in pairs(voiceMapGemini) do
 if v == currentVoiceID then
 currentVoiceDisplay = k
 break
 end
 end
 end
 if currentVoiceDisplay == "" then
 for k, v in pairs(voiceMapOpenAI) do
 if v == currentVoiceID then
 currentVoiceDisplay = k
 break
 end
 end
 end
 
 local tempName = currentName
 local tempVoiceDisplay = currentVoiceDisplay
 local tempVoiceID = currentVoiceID
 local tempEmotion = currentEmotion
 local tempSpeed = currentSpeed
 local tempPitch = currentPitch
 
 local testButton, stopButton
 
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(15), dip2px(15), dip2px(15), dip2px(15))
 
 local nameLabel = TextView(activity)
 nameLabel.text = "1. Voice Name:"
 nameLabel.textSize = 14
 mainLayout.addView(nameLabel)
 
 local nameInput = EditText(activity)
 nameInput.text = tempName
 nameInput.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 nameInput.hint = "Example: Host, Guest..."
 mainLayout.addView(nameInput)
 
 local voiceLabel = TextView(activity)
 voiceLabel.text = "2. Select Voice:"
 voiceLabel.textSize = 14
 voiceLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local voiceLabelParams = voiceLabel.getLayoutParams()
 if voiceLabelParams then
 voiceLabelParams.topMargin = dip2px(15)
 end
 mainLayout.addView(voiceLabel)
 
 local voiceSpinner = Spinner(activity)
 voiceSpinner.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(voiceSpinner)
 
 local emotionLabel = TextView(activity)
 emotionLabel.text = "3. Default Emotion:"
 emotionLabel.textSize = 14
 emotionLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local emotionLabelParams = emotionLabel.getLayoutParams()
 if emotionLabelParams then
 emotionLabelParams.topMargin = dip2px(15)
 end
 mainLayout.addView(emotionLabel)
 
 local emotionSpinner = Spinner(activity)
 emotionSpinner.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(emotionSpinner)
 
 local speedLabel = TextView(activity)
 speedLabel.text = "4. Voice Speed:"
 speedLabel.textSize = 14
 speedLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local speedLabelParams = speedLabel.getLayoutParams()
 if speedLabelParams then
 speedLabelParams.topMargin = dip2px(15)
 end
 mainLayout.addView(speedLabel)
 
 local speedText = TextView(activity)
 speedText.text = string.format("Speed: %.1fx", currentSpeed)
 speedText.textSize = 12
 mainLayout.addView(speedText)
 
 local speedSeekBar = SeekBar(activity)
 speedSeekBar.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(speedSeekBar)
 
 local pitchLabel = TextView(activity)
 pitchLabel.text = "5. Voice Pitch (Tone):"
 pitchLabel.textSize = 14
 pitchLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local pitchLabelParams = pitchLabel.getLayoutParams()
 if pitchLabelParams then
 pitchLabelParams.topMargin = dip2px(15)
 end
 mainLayout.addView(pitchLabel)
 
 local pitchText = TextView(activity)
 pitchText.text = string.format("Pitch: %.1f", currentPitch)
 pitchText.textSize = 12
 mainLayout.addView(pitchText)
 
 local pitchSeekBar = SeekBar(activity)
 pitchSeekBar.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(pitchSeekBar)
 
 local divider = View(activity)
 divider.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(1)))
 divider.setBackgroundColor(0xFF888888)
 local dividerParams = divider.getLayoutParams()
 if dividerParams then
 dividerParams.topMargin = dip2px(20)
 dividerParams.bottomMargin = dip2px(10)
 end
 mainLayout.addView(divider)
 
 local testLabel = TextView(activity)
 testLabel.text = "Test Text:"
 testLabel.textSize = 14
 testLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local testLabelParams = testLabel.getLayoutParams()
 if testLabelParams then
 testLabelParams.topMargin = dip2px(5)
 end
 mainLayout.addView(testLabel)
 
 local testInput = EditText(activity)
 testInput.text = emotionExampleMap[currentEmotion] or emotionExampleMap["Default"]
 testInput.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 testInput.lines = 3
 testInput.hint = "Enter sample text..."
 mainLayout.addView(testInput)
 
 local buttonLayout = LinearLayout(activity)
 buttonLayout.setOrientation(LinearLayout.HORIZONTAL)
 buttonLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local buttonLayoutParams = buttonLayout.getLayoutParams()
 if buttonLayoutParams then
 buttonLayoutParams.topMargin = dip2px(10)
 end
 
 testButton = Button(activity)
 testButton.text = "Test Listen"
 testButton.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 buttonLayout.addView(testButton)
 
 stopButton = Button(activity)
 stopButton.text = "Stop"
 local stopButtonParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1)
 stopButtonParams.leftMargin = dip2px(10)
 stopButton.setLayoutParams(stopButtonParams)
 buttonLayout.addView(stopButton)
 
 mainLayout.addView(buttonLayout)
 scrollView.addView(mainLayout)
 
 local d = LuaDialog(activity)
 .setTitle("Voice Configuration: " .. currentName)
 .setView(scrollView)
 .setPositiveButton("Save & Apply", function()
 stopConfigTestAudio()
 configNames[voiceIndex] = tempName
 configVoices[voiceIndex] = tempVoiceID
 configSpeeds[voiceIndex] = tempSpeed
 configPitches[voiceIndex] = tempPitch
 configEmotions[voiceIndex] = tempEmotion
 saveConfig()
 runOnUi(function()
 resultText.text = string.format("Configuration updated for %s.", tempName)
 end)
 end)
 .setNegativeButton("Cancel", function()
 stopConfigTestAudio()
 end)
 d.show()
 
 nameInput.addTextChangedListener(TextWatcher{
 onTextChanged = function(s, start, before, count)
 tempName = tostring(s)
 end
 })
 
 local voicesList = {}
 local currentMap = getCurrentVoiceMap()
 for k, _ in pairs(currentMap) do
 table.insert(voicesList, k)
 end
 table.sort(voicesList)
 
 local voiceAdapter = ArrayAdapter(activity, android.R.layout.simple_spinner_item, voicesList)
 voiceAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
 voiceSpinner.setAdapter(voiceAdapter)
 
 local vIndexPos = 0
 for i=1, #voicesList do
 if voicesList[i] == currentVoiceDisplay then
 vIndexPos = i - 1
 break
 end
 end
 voiceSpinner.setSelection(vIndexPos)
 
 voiceSpinner.setOnItemSelectedListener(AdapterView.OnItemSelectedListener{
 onItemSelected = function(parent, view, position, id)
 tempVoiceDisplay = voicesList[position + 1]
 tempVoiceID = currentMap[tempVoiceDisplay]
 end
 })
 
 local emotionAdapter = ArrayAdapter(activity, android.R.layout.simple_spinner_item, emotionsFull)
 emotionAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
 emotionSpinner.setAdapter(emotionAdapter)
 
 local emoIndexPos = 0
 for i=1, #emotionsFull do
 if emotionsFull[i] == currentEmotion then
 emoIndexPos = i - 1
 break
 end
 end
 emotionSpinner.setSelection(emoIndexPos)
 
 emotionSpinner.setOnItemSelectedListener(AdapterView.OnItemSelectedListener{
 onItemSelected = function(parent, view, position, id)
 tempEmotion = emotionsFull[position + 1]
 local exampleText = emotionExampleMap[tempEmotion] or emotionExampleMap["Default"]
 testInput.text = exampleText
 if tempEmotion == "Custom" then
 showCustomEmotionDialog(voiceIndex, function(prompt)
 testInput.text = (emotionExampleMap[tempEmotion] or "") .. " (" .. prompt .. ")"
 end)
 end
 end
 })
 
 setupControlSeekBar(speedSeekBar, speedText, true, currentSpeed, function(value)
 tempSpeed = value
 end)
 
 setupControlSeekBar(pitchSeekBar, pitchText, false, currentPitch, function(value)
 tempPitch = value
 end)
 
 testButton.onClick = function()
 vibrate()
 if configTestAudioPlayer and configTestAudioPlayer.isPlaying() then
 stopConfigTestAudio()
 testButton.text = "Test Listen"
 return
 end
 
 local text = testInput.text
 local vID = tempVoiceID
 if #text == 0 then return end
 
 testButton.text = "Creating..."
 Thread(Runnable{ run = function()
 testSpeak(text, vID, tempEmotion, tempSpeed, tempPitch, false, true)
 end }).start()
 end
 
 stopButton.onClick = function()
 vibrate()
 stopConfigTestAudio()
 runOnUi(function()
 testButton.text = "Test Listen"
 end)
 end
end
function showAllVoicesConfigDialog()
 local voiceLimit = 6
 local dialogTitle = "Configure All Voices (1-6)"
 
 if currentMode == 1 then
 voiceLimit = 2
 dialogTitle = "Configure Dialogue Voices (1-2)"
 elseif currentMode == 2 then
 voiceLimit = 4
 dialogTitle = "Configure Podcast Voices (1-4)"
 elseif currentMode == 3 then
 voiceLimit = 6
 dialogTitle = "Configure All Voices (1-6)"
 end
 
 local scrollView = ScrollView(activity)
 local container = LinearLayout(activity)
 container.setOrientation(LinearLayout.VERTICAL)
 container.setPadding(dip2px(20), dip2px(20), dip2px(20), dip2px(20))
 
 for i = 1, voiceLimit do
 local voiceRow = LinearLayout(activity)
 voiceRow.setOrientation(LinearLayout.HORIZONTAL)
 voiceRow.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 voiceRow.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 voiceRow.setFocusable(true)
 
 local nameText = TextView(activity)
 local displayName = configNames[i] or ("Voice " .. i)
 local displayID = configVoices[i] or "None"
 nameText.text = i .. ". " .. displayName .. " (" .. displayID .. ")"
 nameText.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 nameText.gravity = Gravity.CENTER_VERTICAL
 nameText.textSize = 14
 nameText.setTextColor(0xFF333333)
 voiceRow.addView(nameText)
 
 local configButton = Button(activity)
 configButton.text = "Configure"
 configButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 configButton.setContentDescription("Configure " .. displayName)
 configButton.onClick = function()
 vibrate()
 showVoiceConfigDialog(i)
 end
 voiceRow.addView(configButton)
 
 container.addView(voiceRow)
 
 local line = View(activity)
 line.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(1)))
 line.setBackgroundColor(0xFFCCCCCC)
 container.addView(line)
 end
 
 scrollView.addView(container)
 
 LuaDialog(this)
 .setTitle(dialogTitle)
 .setView(scrollView)
 .setPositiveButton("Close", nil)
 .show()
end
function processTextForEmotion(rawText)
 local mode = textEmotionMode
 if mode == "Default (Keep as is)" or not rawText then
 return rawText
 end
 
 local newText = ""
 local lines = {}
 for line in rawText:gmatch("[^\r\n]+") do
 table.insert(lines, line)
 end
 
 local nonDefaultEmotions = {}
 for _, emo in ipairs(emotionsFull) do
 if emo ~= "Default" and emo ~= "Custom" then
 table.insert(nonDefaultEmotions, emo)
 end
 end
 
 math.randomseed(os.time() * os.clock() * 1000000)
 
 for _, line in ipairs(lines) do
 local speaker, content = line:match("^%s*(.-)%s*:%s*(.+)")
 
 if speaker and content then
 speaker = speaker:match("^%s*(.-)%s*$")
 
 local _, _, existingEmotion, cleanedContent = content:find("^%s*%[(.-)%]%s*(.*)$")
 cleanedContent = cleanedContent or content
 
 if mode == "Default Voice Emotion" then
 local selectedEmotion = "Default"
 for i = 1, #configNames do
 if speaker:lower() == tostring(configNames[i]):lower() then
 selectedEmotion = configEmotions[i]
 break
 end
 end
 
 if selectedEmotion ~= "Default" then
 local emotionName = selectedEmotion:match("^(.-)%s*%(") or selectedEmotion:match("^(.-)%s*$")
 if selectedEmotion == "Custom" then
 emotionName = (customEmotionPrompt and customEmotionPrompt ~= "") and customEmotionPrompt:match("^(.-)%.?%s*$") or "Custom"
 end
 newText = newText .. speaker .. ": [" .. emotionName .. "] " .. cleanedContent .. "\n"
 else
 newText = newText .. speaker .. ": " .. cleanedContent .. "\n"
 end
 elseif mode == "Random Emotion" then
 if #nonDefaultEmotions > 0 then
 local randomIndex = math.random(1, #nonDefaultEmotions)
 local randomEmotion = nonDefaultEmotions[randomIndex]
 local emotionName = randomEmotion:match("^(.-)%s*%(") or randomEmotion:match("^(.-)%s*$")
 newText = newText .. speaker .. ": [" .. emotionName .. "] " .. cleanedContent .. "\n"
 else
 newText = newText .. speaker .. ": " .. cleanedContent .. "\n"
 end
 end
 else
 newText = newText .. line .. "\n"
 end
 end
 
 return newText:gsub("\n$", "")
end
function updateUIMode(mode)
 currentMode = mode
 saveConfig()
 
 runOnUi(function()
 if resultText then resultText.text = "Status: Ready for new " .. modes[mode + 1] end
 if podcastProgressBar then 
 podcastProgressBar.setVisibility(View.GONE) 
 podcastProgressBar.setProgress(0) -- Reset progress bar
 end
 if playButton then playButton.setVisibility(View.GONE) end
 if downloadButton then downloadButton.setVisibility(View.GONE) end
 if formatSpinner then formatSpinner.setVisibility(View.GONE) end
 if generateButton then 
 generateButton.setEnabled(true)
 generateButton.text = "Generate Audio"
 end
 end)
 
 if voiceSelectorLayout then
 voiceSelectorLayout.setVisibility((mode >= 1) and View.VISIBLE or View.GONE)
 end
 
 if textEmotionSpinnerLayout then
 textEmotionSpinnerLayout.setVisibility((mode >= 1) and View.VISIBLE or View.GONE)
 end
 
 if dialogueEmotionLabel then
 dialogueEmotionLabel.setVisibility((mode >= 1) and View.VISIBLE or View.GONE)
 end
 
 if btnDialogueEmotionApply then
 btnDialogueEmotionApply.setVisibility((mode >= 1) and View.VISIBLE or View.GONE)
 end
 
 if podcastEmotionNote then
 podcastEmotionNote.setVisibility((mode >= 1) and View.VISIBLE or View.GONE)
 end
 
 if scriptInput then
 scriptInput.setVisibility((mode >= 1) and View.VISIBLE or View.GONE)
 end
 
 if scriptLabel then
 scriptLabel.setVisibility((mode >= 1) and View.VISIBLE or View.GONE)
 end
 
 if mode == 0 then
 if btnConfigVoice1 then
 btnConfigVoice1.text = "Configure Voice"
 btnConfigVoice1.setVisibility(View.VISIBLE)
 end
 if btnConfigVoice2 then
 btnConfigVoice2.setVisibility(View.GONE)
 end
 if chatLabel then chatLabel.text = "Enter text:" end
 if chatInput then chatInput.hint = "Type text for single voice..." end
 if generateButton then generateButton.text = "Generate Audio" end
 if scriptInput then scriptInput.hint = "Not available in single voice mode" end
 elseif mode == 1 then
 if btnConfigVoice1 then
 btnConfigVoice1.text = "Configure Voice 1"
 btnConfigVoice1.setVisibility(View.VISIBLE)
 end
 if btnConfigVoice2 then
 btnConfigVoice2.text = "Configure Voice 2"
 btnConfigVoice2.setVisibility(View.VISIBLE)
 end
 if chatLabel then chatLabel.text = "Enter dialogue:" end
 if chatInput then chatInput.hint = "Type message..." end
 if generateButton then generateButton.text = "Generate Dialogue" end
 if scriptInput then 
 scriptInput.hint = "Example:\n" .. (configNames[1] or "Host") .. ": Hello!\n" .. (configNames[2] or "Guest") .. ": Hi there!" 
 end
 elseif mode == 2 then
 if btnConfigVoice1 then
 btnConfigVoice1.text = "Configure All Voices (1-4)"
 btnConfigVoice1.setVisibility(View.VISIBLE)
 end
 if btnConfigVoice2 then
 btnConfigVoice2.setVisibility(View.GONE)
 end
 if chatLabel then chatLabel.text = "Enter script:" end
 if chatInput then chatInput.hint = "Type message..." end
 if generateButton then generateButton.text = "Generate Podcast (4 Voices)" end
 if scriptInput then 
 scriptInput.hint = "Example:\n" .. (configNames[1] or "Voice 1") .. ": Welcome!\n" .. (configNames[2] or "Voice 2") .. ": Thank you!" 
 end
 elseif mode == 3 then
 if btnConfigVoice1 then
 btnConfigVoice1.text = "Configure All Voices (1-6)"
 btnConfigVoice1.setVisibility(View.VISIBLE)
 end
 if btnConfigVoice2 then
 btnConfigVoice2.setVisibility(View.GONE)
 end
 if chatLabel then chatLabel.text = "Enter script:" end
 if chatInput then chatInput.hint = "Type message..." end
 if generateButton then generateButton.text = "Generate Podcast (6 Voices)" end
 if scriptInput then 
 scriptInput.hint = "Example:\n" .. (configNames[1] or "Voice 1") .. ": Hello everyone!" 
 end
 end
 
 if updateCharCounter then updateCharCounter() end
 if updateVoiceSelector then updateVoiceSelector() end
end
function testGeminiApi(apiKey, onResult)
 local testModel = "gemini-2.5-flash"
 local apiUrl
 
 if SELECTED_API_PROVIDER == "Google Generative Language (Gemini)" then
 apiUrl = string.format(
 "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
 testModel, apiKey
 )
 else
 onResult(false, "Please select Google Generative Language as provider for testing.")
 return
 end
 
 local requestBody = {
 contents = {{ role = "user", parts = {{ text = "Hello, reply with one word Success." }}}},
 generationConfig = { temperature = 0.5, maxOutputTokens = 10 }
 }
 
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 
 Http.post(apiUrl, cjson.encode(requestBody), headers, function(code, content)
 if code == 200 then
 local status, data = pcall(cjson.decode, content)
 
 if status and data and data.candidates and #data.candidates > 0 then
 local candidate = data.candidates[1]
 if candidate.content and candidate.content.parts and #candidate.content.parts > 0 then
 local responseText = candidate.content.parts[1].text
 runOnUi(function()
 onResult(true, "Google API working! Response: " .. tostring(responseText))
 end)
 else
 runOnUi(function()
 onResult(false, "API Error: Response blocked by safety filters or empty content.")
 end)
 end
 else
 runOnUi(function()
 onResult(false, "JSON parsing error: " .. (content or ""):sub(1, 100))
 end)
 end
 elseif code == 400 then
 runOnUi(function()
 onResult(false, "Error 400: Invalid API Key or malformed request.")
 end)
 elseif code == 403 then
 runOnUi(function()
 onResult(false, "Error 403: Permission denied. Check your API key restrictions.")
 end)
 elseif code == 429 then
 runOnUi(function()
 onResult(false, "Error 429: Rate limit exceeded. Try again in a minute.")
 end)
 else
 runOnUi(function()
 onResult(false, "HTTP Error: " .. code .. " - Check connection.")
 end)
 end
 end)
end
function testOpenAIApi(apiKey, onResult)
 if SELECTED_API_PROVIDER ~= "OpenAI Official (GPT-4o mini TTS)" then
 onResult(false, "Please select OpenAI Official as provider for testing.")
 return
 end
 
 local testText = "This is a short API test."
 local testVoice = "alloy"
 
 local requestBody = {
 model = OPENAI_TTS_MODEL,
 input = testText,
 voice = testVoice,
 speed = 1.0,
 response_format = "mp3"
 }
 
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 headers.put("Authorization", "Bearer " .. apiKey)
 
 Http.post(API_ENDPOINTS["OpenAI Official (GPT-4o mini TTS)"](apiKey), cjson.encode(requestBody), headers, function(code, content)
 if code == 200 then
 runOnUi(function()
 onResult(true, "OpenAI API working! Audio response received successfully.")
 end)
 elseif code == 401 then
 runOnUi(function()
 onResult(false, "OpenAI Error 401: Invalid API key.")
 end)
 else
 runOnUi(function()
 onResult(false, "OpenAI HTTP Error: " .. code .. " - " .. (content or ""):sub(1, math.min(string.len(content or ""), 100)) .. "...")
 end)
 end
 end)
end
function showGeminiConfigDialog()
 local tempApiKey = API_KEY
 local tempApiProvider = SELECTED_API_PROVIDER
 
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(15), dip2px(15), dip2px(15), dip2px(15))
 
 local titleLabel = TextView(activity)
 titleLabel.text = "API Configuration"
 titleLabel.textSize = 16
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local titleLabelParams = titleLabel.getLayoutParams()
 if titleLabelParams then
 titleLabelParams.topMargin = dip2px(5)
 titleLabelParams.bottomMargin = dip2px(10)
 end
 mainLayout.addView(titleLabel)
 
 local providerLabel = TextView(activity)
 providerLabel.text = "1. Select API Provider:"
 providerLabel.textSize = 14
 providerLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local providerLabelParams = providerLabel.getLayoutParams()
if providerLabelParams then
 providerLabelParams.topMargin = dip2px(10)
end
mainLayout.addView(providerLabel)
local providerSpinner = Spinner(activity)
providerSpinner.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
mainLayout.addView(providerSpinner)
local keyLabel = TextView(activity)
keyLabel.text = "2. API Key:"
keyLabel.textSize = 14
keyLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
local keyLabelParams = keyLabel.getLayoutParams()
if keyLabelParams then
 keyLabelParams.topMargin = dip2px(15)
end
mainLayout.addView(keyLabel)
local keyInput = EditText(activity)
keyInput.text = tempApiKey
keyInput.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
keyInput.hint = "Enter API Key..."
mainLayout.addView(keyInput)
local noteLabel = TextView(activity)
noteLabel.text = "Note: Gemini is recommended for better performance. For OpenAI, use official keys."
noteLabel.textSize = 12
noteLabel.setTextColor(0xFF555555)
noteLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
local noteLabelParams = noteLabel.getLayoutParams()
if noteLabelParams then
 noteLabelParams.topMargin = dip2px(5)
end
mainLayout.addView(noteLabel)
local testButton = Button(activity)
testButton.text = "Test API Connection"
testButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
local testButtonParams = testButton.getLayoutParams()
if testButtonParams then
 testButtonParams.topMargin = dip2px(15)
end
mainLayout.addView(testButton)
local resultText = TextView(activity)
resultText.text = "Test status: Not tested"
resultText.textSize = 12
resultText.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
local resultTextParams = resultText.getLayoutParams()
if resultTextParams then
 resultTextParams.topMargin = dip2px(5)
end
mainLayout.addView(resultText)
scrollView.addView(mainLayout)
local d = LuaDialog(activity)
d.setTitle("API Configuration")
d.setView(scrollView)
d.setPositiveButton("Save", function()
 API_KEY = tostring(keyInput.text)
 SELECTED_API_PROVIDER = tempApiProvider
 
 if type(updateVoicesBasedOnProvider) == "function" then
 updateVoicesBasedOnProvider()
 end
 
 if type(saveGeminiConfig) == "function" then
 saveGeminiConfig()
 end
 
 runOnUi(function()
 showInfoDialog("Success", "Configuration saved! Provider set to: " .. SELECTED_API_PROVIDER)
 end)
end)
d.setNegativeButton("Cancel", nil)
d.show()
local providerAdapter = ArrayAdapter(activity, android.R.layout.simple_spinner_item, API_PROVIDERS)
providerAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
providerSpinner.setAdapter(providerAdapter)
local providerIndex = 0
for i=1, #API_PROVIDERS do
 if API_PROVIDERS[i] == tempApiProvider then
 providerIndex = i - 1
 break
 end
end
providerSpinner.setSelection(providerIndex)
providerSpinner.setOnItemSelectedListener(AdapterView.OnItemSelectedListener{
 onItemSelected = function(parent, view, position, id)
 tempApiProvider = API_PROVIDERS[position + 1]
 resultText.text = "Test status: Need to test again"
 end
})
keyInput.addTextChangedListener(TextWatcher{
 onTextChanged = function(s, start, before, count)
 tempApiKey = tostring(s)
 resultText.text = "Test status: Need to test again"
 end
})
testButton.onClick = function()
 vibrate()
 local key = tostring(keyInput.text)
 local provider = API_PROVIDERS[providerSpinner.getSelectedItemPosition() + 1]
 
 if #key == 0 then
 resultText.text = "Error: Please enter API key"
 return
 end
 
 if provider == "OpenAI Official (GPT-4o mini TTS)" and not key:match("^sk%-") then
 resultText.text = "Error: This doesn't look like an OpenAI API key"
 return
 end
 
 testButton.text = "Testing..."
 testButton.setEnabled(false)
 resultText.text = "Test status: Connecting..."
 
 Thread(Runnable{ run = function()
 if provider == "OpenAI Official (GPT-4o mini TTS)" then
 if type(testOpenAIApi) == "function" then
 testOpenAIApi(key, function(success, message)
 runOnUi(function()
 testButton.text = "Test API Connection"
 testButton.setEnabled(true)
 resultText.text = message
 end)
 end)
 else
 runOnUi(function() 
 testButton.setEnabled(true)
 resultText.text = "Error: testOpenAIApi function not found" 
 end)
 end
 else
 if type(testGeminiApi) == "function" then
 testGeminiApi(key, function(success, message)
 runOnUi(function()
 testButton.text = "Test API Connection"
 testButton.setEnabled(true)
 resultText.text = message
 end)
 end)
 else
 runOnUi(function() 
 testButton.setEnabled(true)
 resultText.text = "Error: testGeminiApi function not found" 
 end)
 end
 end
 end }).start()
end
end
function getAudioFilesList()
 local dir = File(USER_AUDIO_DIR)
 local files = {}
 
 if not dir.exists() then
 dir.mkdirs()
 return files
 end
 
 local fileList = dir.listFiles()
 if not fileList then
 return files
 end
 
 for i=0, #fileList-1 do
 local file = fileList[i]
 if file and file.isFile() then
 local name = file.getName()
 local path = file.getAbsolutePath()
 local size = file.length()
 local lastModified = file.lastModified()
 
 if name:match("%.wav$") or name:match("%.mp3$") or name:match("%.ogg$") or 
 name:match("%.aac$") or name:match("%.wma$") then
 table.insert(files, {
 name = name,
 path = path,
 size = size,
 lastModified = lastModified,
 file = file
 })
 end
 end
 end
 
 table.sort(files, function(a, b)
 return a.lastModified > b.lastModified
 end)
 
 return files
end
function showProfessionalPlayer(file)
 local player = MediaPlayer()
 local playerState = "stopped"
 local updateTask = nil
 local audioFiles = getAudioFilesList()
 local currentFileIndex = 1
 
 for i, audioFile in ipairs(audioFiles) do
 if audioFile.path == file.path then
 currentFileIndex = i
 break
 end
 end
 
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT))
 mainLayout.setPadding(dip2px(20), dip2px(20), dip2px(20), dip2px(20))
 
 local titleLabel = TextView(activity)
 titleLabel.text = file.name
 titleLabel.textSize = 18
 titleLabel.gravity = Gravity.CENTER
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFF333333)
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(10)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 
 local fileInfoText = TextView(activity)
 fileInfoText.text = string.format("Track %d of %d", currentFileIndex, #audioFiles)
 fileInfoText.textSize = 12
 fileInfoText.gravity = Gravity.CENTER
 fileInfoText.setTextColor(0xFF666666)
 local fileInfoParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 fileInfoParams.bottomMargin = dip2px(15)
 fileInfoText.setLayoutParams(fileInfoParams)
 mainLayout.addView(fileInfoText)
 
 local seekBar = SeekBar(activity)
 local seekParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 seekParams.bottomMargin = dip2px(10)
 seekBar.setLayoutParams(seekParams)
 mainLayout.addView(seekBar)
 
 local timeLayout = LinearLayout(activity)
 timeLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 timeLayout.setPadding(0, 0, 0, dip2px(20))
 
 local currentTime = TextView(activity)
 currentTime.text = "00:00"
 currentTime.textSize = 12
 currentTime.setTextColor(0xFF2196F3)
 currentTime.setTypeface(Typeface.DEFAULT_BOLD)
 currentTime.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 timeLayout.addView(currentTime)
 
 local totalTime = TextView(activity)
 totalTime.text = "00:00"
 totalTime.textSize = 12
 totalTime.setTextColor(0xFF666666)
 totalTime.gravity = Gravity.RIGHT
 totalTime.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 timeLayout.addView(totalTime)
 
 mainLayout.addView(timeLayout)
 
 local speedLabel = TextView(activity)
 speedLabel.text = "Playback Speed"
 speedLabel.textSize = 14
 speedLabel.setTypeface(Typeface.DEFAULT_BOLD)
 speedLabel.setTextColor(0xFF333333)
 local speedLabelParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 speedLabelParams.bottomMargin = dip2px(5)
 speedLabel.setLayoutParams(speedLabelParams)
 mainLayout.addView(speedLabel)
 
 local speedBar = SeekBar(activity)
 speedBar.max = 200
 speedBar.progress = 100
 speedBar.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(speedBar)
 
 local speedValueText = TextView(activity)
 speedValueText.text = "Speed: 1.0x"
 speedValueText.textSize = 12
 speedValueText.gravity = Gravity.CENTER
 speedValueText.setTextColor(0xFF666666)
 local speedValueParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 speedValueParams.topMargin = dip2px(5)
 speedValueParams.bottomMargin = dip2px(30)
 speedValueText.setLayoutParams(speedValueParams)
 mainLayout.addView(speedValueText)
 
 local spacer = View(activity)
 local spacerParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1)
 spacer.setLayoutParams(spacerParams)
 mainLayout.addView(spacer)
 
 local controlRow1 = LinearLayout(activity)
 controlRow1.setOrientation(LinearLayout.HORIZONTAL)
 controlRow1.gravity = Gravity.CENTER
 controlRow1.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 controlRow1.setPadding(0, 0, 0, dip2px(15))
 
 local prevTrackButton = Button(activity)
 prevTrackButton.text = "⏮"
 prevTrackButton.setTextSize(18)
 prevTrackButton.setBackgroundResource(android.R.drawable.btn_default)
 local prevTrackParams = LinearLayout.LayoutParams(dip2px(60), dip2px(50))
 prevTrackParams.rightMargin = dip2px(10)
 prevTrackButton.setLayoutParams(prevTrackParams)
 if currentFileIndex == 1 then
 prevTrackButton.setEnabled(false)
 prevTrackButton.setTextColor(0xFFAAAAAA)
 end
 controlRow1.addView(prevTrackButton)
 
 local rewindButton = Button(activity)
 rewindButton.text = "⏪"
 rewindButton.setTextSize(18)
 rewindButton.setBackgroundResource(android.R.drawable.btn_default)
 local rewindParams = LinearLayout.LayoutParams(dip2px(60), dip2px(50))
 rewindParams.rightMargin = dip2px(10)
 rewindButton.setLayoutParams(rewindParams)
 controlRow1.addView(rewindButton)
 
 local playPauseButton = Button(activity)
 playPauseButton.text = "▶"
 playPauseButton.setTextSize(22)
 playPauseButton.setTypeface(Typeface.DEFAULT_BOLD)
 playPauseButton.setBackgroundResource(android.R.drawable.btn_default)
 local playPauseParams = LinearLayout.LayoutParams(dip2px(70), dip2px(60))
 playPauseButton.setLayoutParams(playPauseParams)
 controlRow1.addView(playPauseButton)
 
 local forwardButton = Button(activity)
 forwardButton.text = "⏩"
 forwardButton.setTextSize(18)
 forwardButton.setBackgroundResource(android.R.drawable.btn_default)
 local forwardParams = LinearLayout.LayoutParams(dip2px(60), dip2px(50))
 forwardParams.leftMargin = dip2px(10)
 forwardButton.setLayoutParams(forwardParams)
 controlRow1.addView(forwardButton)
 
 local nextTrackButton = Button(activity)
 nextTrackButton.text = "⏭"
 nextTrackButton.setTextSize(18)
 nextTrackButton.setBackgroundResource(android.R.drawable.btn_default)
 local nextTrackParams = LinearLayout.LayoutParams(dip2px(60), dip2px(50))
 nextTrackParams.leftMargin = dip2px(10)
 nextTrackButton.setLayoutParams(nextTrackParams)
 if currentFileIndex == #audioFiles then
 nextTrackButton.setEnabled(false)
 nextTrackButton.setTextColor(0xFFAAAAAA)
 end
 controlRow1.addView(nextTrackButton)
 
 mainLayout.addView(controlRow1)
 
 local controlRow2 = LinearLayout(activity)
 controlRow2.setOrientation(LinearLayout.HORIZONTAL)
 controlRow2.gravity = Gravity.CENTER
 controlRow2.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 
 local closeButton = Button(activity)
 closeButton.text = "CLOSE PLAYER"
 closeButton.setTextSize(14)
 closeButton.setTypeface(Typeface.DEFAULT_BOLD)
 closeButton.setTextColor(0xFFFFFFFF)
 closeButton.setBackgroundColor(0xFFF44336)
 local closeParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(50))
 closeParams.topMargin = dip2px(10)
 closeButton.setLayoutParams(closeParams)
 controlRow2.addView(closeButton)
 
 mainLayout.addView(controlRow2)
 
 scrollView.addView(mainLayout)
 
 local pd = LuaDialog(activity)
 .setTitle("Professional Audio Player")
 .setView(scrollView)
 .show()
 
 local function stopAndCleanup()
 playerState = "stopped"
 
 if updateTask then
 updateTask.cancel()
 updateTask = nil
 end
 
 pcall(function()
 if player then
 local playerReleased = false
 pcall(function()
 player.isPlaying()
 end, function(err)
 playerReleased = true
 end)
 
 if not playerReleased then
 if player.isPlaying() then
 player.stop()
 end
 player.release()
 end
 player = nil
 end
 end)
 end
 
 local function updatePlayerState()
 if playerState == "playing" then
 playPauseButton.text = "⏸"
 elseif playerState == "paused" then
 playPauseButton.text = "▶"
 else
 playPauseButton.text = "▶"
 end
 end
 
 local function loadNewFile(newFile, newIndex)
 stopAndCleanup()
 
 player = MediaPlayer()
 player.setDataSource(newFile.path)
 player.prepare()
 playerState = "stopped"
 
 titleLabel.text = newFile.name
 currentFileIndex = newIndex
 fileInfoText.text = string.format("Track %d of %d", currentFileIndex, #audioFiles)
 
 local duration = player.getDuration()
 totalTime.text = string.format("%02d:%02d", math.floor(duration/60000), math.floor((duration/1000)%60))
 seekBar.setMax(duration)
 seekBar.setProgress(0)
 currentTime.text = "00:00"
 
 prevTrackButton.setEnabled(currentFileIndex > 1)
 nextTrackButton.setEnabled(currentFileIndex < #audioFiles)
 prevTrackButton.setTextColor(currentFileIndex > 1 and 0xFF000000 or 0xFFAAAAAA)
 nextTrackButton.setTextColor(currentFileIndex < #audioFiles and 0xFF000000 or 0xFFAAAAAA)
 
 updatePlayerState()
 
 speedBar.setProgress(100)
 speedValueText.text = "Speed: 1.0x"
 end
 
 player.setDataSource(file.path)
 player.prepare()
 local duration = player.getDuration()
 totalTime.text = string.format("%02d:%02d", math.floor(duration/60000), math.floor((duration/1000)%60))
 seekBar.setMax(duration)
 
 seekBar.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
 onProgressChanged = function(seekBar, progress, fromUser)
 if fromUser then
 currentTime.text = string.format("%02d:%02d", math.floor(progress/60000), math.floor((progress/1000)%60))
 end
 end,
 
 onStartTrackingTouch = function(seekBar)
 end,
 
 onStopTrackingTouch = function(seekBar)
 pcall(function()
 if player and playerState == "playing" then
 player.pause()
 player.seekTo(seekBar.getProgress())
 player.start()
 elseif player then
 player.seekTo(seekBar.getProgress())
 end
 end)
 end
 })
 
 playPauseButton.onClick = function()
 vibrate()
 pcall(function()
 if playerState == "stopped" then
 player.start()
 playerState = "playing"
 
 local function update()
 if playerState == "playing" and player and pcall(function() return player.isPlaying() end) then
 local currentPos = player.getCurrentPosition()
 seekBar.setProgress(currentPos)
 currentTime.text = string.format("%02d:%02d", math.floor(currentPos/60000), math.floor((currentPos/1000)%60))
 updateTask = task(1000, update)
 end
 end
 update()
 
 elseif playerState == "playing" then
 player.pause()
 playerState = "paused"
 if updateTask then
 updateTask.cancel()
 updateTask = nil
 end
 
 elseif playerState == "paused" then
 player.start()
 playerState = "playing"
 
 local function update()
 if playerState == "playing" and player and pcall(function() return player.isPlaying() end) then
 local currentPos = player.getCurrentPosition()
 seekBar.setProgress(currentPos)
 currentTime.text = string.format("%02d:%02d", math.floor(currentPos/60000), math.floor((currentPos/1000)%60))
 updateTask = task(1000, update)
 end
 end
 update()
 end
 
 updatePlayerState()
 end)
 end
 
 forwardButton.onClick = function() 
 vibrate()
 pcall(function()
 if player then
 local newPos = player.getCurrentPosition() + 5000
 if newPos > duration then
 newPos = duration
 end
 player.seekTo(newPos)
 seekBar.setProgress(newPos)
 currentTime.text = string.format("%02d:%02d", math.floor(newPos/60000), math.floor((newPos/1000)%60))
 end
 end)
 end
 
 rewindButton.onClick = function() 
 vibrate()
 pcall(function()
 if player then
 local newPos = player.getCurrentPosition() - 5000
 if newPos < 0 then
 newPos = 0
 end
 player.seekTo(newPos)
 seekBar.setProgress(newPos)
 currentTime.text = string.format("%02d:%02d", math.floor(newPos/60000), math.floor((newPos/1000)%60))
 end
 end)
 end
 
 prevTrackButton.onClick = function()
 vibrate()
 if currentFileIndex > 1 then
 loadNewFile(audioFiles[currentFileIndex - 1], currentFileIndex - 1)
 end
 end
 
 nextTrackButton.onClick = function()
 vibrate()
 if currentFileIndex < #audioFiles then
 loadNewFile(audioFiles[currentFileIndex + 1], currentFileIndex + 1)
 end
 end
 
 speedBar.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
 onProgressChanged = function(v, p)
 pcall(function()
 if player then
 local speed = p / 100
 if speed < 0.5 then speed = 0.5 end
 if speed > 2.0 then speed = 2.0 end
 
 speedValueText.text = string.format("Speed: %.1fx", speed)
 
 if Build.VERSION.SDK_INT >= 23 then
 local params = PlaybackParams()
 params.setSpeed(speed)
 player.setPlaybackParams(params)
 end
 end
 end)
 end,
 
 onStartTrackingTouch = function(v)
 end,
 
 onStopTrackingTouch = function(v)
 end
 })
 
 closeButton.onClick = function()
 vibrate()
 stopAndCleanup()
 pd.dismiss()
 end
 
 pd.setOnDismissListener(DialogInterface.OnDismissListener{
 onDismiss = function()
 stopAndCleanup()
 end
 })
end
function showAudioManagementDialog()
 local audioFiles = getAudioFilesList()
 
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT))
 mainLayout.setPadding(dip2px(16), dip2px(16), dip2px(16), dip2px(16))
 
 local titleLabel = TextView(activity)
 titleLabel.text = "Audio Files Manager"
 titleLabel.textSize = 18
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.gravity = Gravity.CENTER
 titleLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(titleLabel)
 
 local countLabel = TextView(activity)
 countLabel.text = "Total Files: " .. #audioFiles
 countLabel.textSize = 12
 countLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(countLabel)
 
 local fileContainer = LinearLayout(activity)
 fileContainer.setOrientation(LinearLayout.VERTICAL)
 fileContainer.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1))
 mainLayout.addView(fileContainer)
 
 local buttonLayout = LinearLayout(activity)
 buttonLayout.setOrientation(LinearLayout.HORIZONTAL)
 buttonLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 
 local refreshButton = Button(activity)
 refreshButton.text = "Refresh"
 refreshButton.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 buttonLayout.addView(refreshButton)
 
 local closeButton = Button(activity)
 closeButton.text = "Close"
 closeButton.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 buttonLayout.addView(closeButton)
 
 mainLayout.addView(buttonLayout)
 scrollView.addView(mainLayout)
 
 local d = LuaDialog(activity)
 .setTitle("Manage Audio Files")
 .setView(scrollView)
 .show()
 
 local currentOptionsDialog = nil
 
 local function displayFiles()
 fileContainer.removeAllViews()
 if #audioFiles == 0 then
 local emptyText = TextView(activity)
 emptyText.text = "No audio files found."
 emptyText.setGravity(Gravity.CENTER)
 emptyText.setPadding(dip2px(40), dip2px(40), dip2px(40), dip2px(40))
 fileContainer.addView(emptyText)
 return
 end
 
 for i, file in ipairs(audioFiles) do
 local fileItem = LinearLayout(activity)
 fileItem.setOrientation(LinearLayout.VERTICAL)
 fileItem.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 fileItem.setPadding(dip2px(15), dip2px(15), dip2px(15), dip2px(15))
 fileItem.setBackgroundColor(0xFFF5F5F5)
 
 local nameText = TextView(activity)
 nameText.text = file.name
 nameText.textSize = 14
 nameText.setTextColor(0xFF333333)
 nameText.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 nameText.setSingleLine(true)
 nameText.setEllipsize(TextUtils.TruncateAt.END)
 fileItem.addView(nameText)
 
 local infoLayout = LinearLayout(activity)
 infoLayout.setOrientation(LinearLayout.HORIZONTAL)
 infoLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 
 local params = infoLayout.getLayoutParams()
 if params then
 params.topMargin = dip2px(5)
 infoLayout.setLayoutParams(params)
 end
 
 local sizeText = TextView(activity)
 sizeText.text = string.format("%.1f KB", file.size/1024)
 sizeText.textSize = 10
 sizeText.setTextColor(0xFF666666)
 sizeText.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 infoLayout.addView(sizeText)
 
 local spacer = View(activity)
 spacer.setLayoutParams(LinearLayout.LayoutParams(dip2px(10), dip2px(1)))
 infoLayout.addView(spacer)
 
 local dateText = TextView(activity)
 dateText.text = os.date("%Y-%m-%d %H:%M", math.floor(file.lastModified/1000))
 dateText.textSize = 10
 dateText.setTextColor(0xFF666666)
 dateText.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 infoLayout.addView(dateText)
 
 fileItem.addView(infoLayout)
 fileContainer.addView(fileItem)
 
 local divider = View(activity)
 divider.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(8)))
 fileContainer.addView(divider)
 
 fileItem.onClick = function()
 vibrate()
 showProfessionalPlayer(file)
 end
 
 fileItem.onLongClick = function()
 vibrate()
 showFileOptionsDialog(file, d)
 return true
 end
 end
 end
 
 function showFileOptionsDialog(file, parentDialog)
 if currentOptionsDialog then
 currentOptionsDialog.dismiss()
 currentOptionsDialog = nil
 end
 
 local options = {
 "Play with Player",
 "Share", 
 "Rename",
 "Delete"
 }
 
 local dlgLayout = LinearLayout(activity)
 dlgLayout.setOrientation(LinearLayout.VERTICAL)
 local padding = dip2px(20)
 dlgLayout.setPadding(padding, padding, padding, padding)
 
 local scrollView = ScrollView(activity)
 scrollView.addView(dlgLayout)
 
 for i, option in ipairs(options) do
 local btn = Button(activity)
 btn.text = option
 btn.setTextSize(16)
 btn.setContentDescription(option)
 
 local btnParams = LinearLayout.LayoutParams(
 LinearLayout.LayoutParams.MATCH_PARENT,
 dip2px(55) -- اونچائی تھوڑی بڑھائی ہے تاکہ ٹچ کرنے میں آسانی ہو
 )
 if i < #options then
 btnParams.bottomMargin = dip2px(10)
 end
 btn.setLayoutParams(btnParams)
 
 btn.onClick = function()
 vibrate()
 
 if currentOptionsDialog then
 currentOptionsDialog.dismiss()
 currentOptionsDialog = nil
 end
 
 if parentDialog and option ~= "Play with Player" and option ~= "Share" then
 parentDialog.dismiss()
 end
 
 if option == "Play with Player" then
 if showProfessionalPlayer then
 showProfessionalPlayer(file)
 else
 showErrorDialog("Player function not found.")
 end
 elseif option == "Share" then
 if shareAudioFile then
 shareAudioFile(file)
 else
 showErrorDialog("Share function not found.")
 end
 elseif option == "Rename" then
 if showRenameDialog then
 showRenameDialog(file, parentDialog)
 else
 showErrorDialog("Rename function not found.")
 end
 elseif option == "Delete" then
 local confirmDlg = LuaDialog(activity)
 confirmDlg.setTitle("Delete File")
 confirmDlg.setMessage("Are you sure you want to delete this file: " .. file.name .. "?")
 confirmDlg.setPositiveButton("Delete", function()
 local filePath = file.absolutePath or ("/storage/emulated/0/Audio/Podcast Generator/" .. file.name)
 local targetFile = File(filePath)
 if targetFile.exists() and targetFile.delete() then
 showInfoDialog("Success", "File deleted successfully!")
 if getAudioFilesList then
 audioFiles = getAudioFilesList()
 if countLabel then countLabel.text = "Total Files: " .. #audioFiles end
 if displayFiles then displayFiles() end
 end
 else
 showErrorDialog("Failed to delete file. Check permissions.")
 end
 confirmDlg.dismiss()
 end)
 confirmDlg.setNegativeButton("Cancel", function()
 confirmDlg.dismiss()
 end)
 confirmDlg.show()
 end
 end
 
 dlgLayout.addView(btn)
 end
 
 local cancelBtn = Button(activity)
 cancelBtn.text = "Cancel"
 cancelBtn.setTextSize(16)
 cancelBtn.setTextColor(0xFFF44336) -- سرخ رنگ
 local cancelParams = LinearLayout.LayoutParams(
 LinearLayout.LayoutParams.MATCH_PARENT,
 dip2px(55)
 )
 cancelParams.topMargin = dip2px(15)
 cancelBtn.setLayoutParams(cancelParams)
 
 cancelBtn.onClick = function()
 vibrate()
 if currentOptionsDialog then
 currentOptionsDialog.dismiss()
 end
 end
 
 dlgLayout.addView(cancelBtn)
 
 local dlg = LuaDialog(activity)
 dlg.setTitle("File Options: " .. file.name)
 dlg.setView(scrollView)
 dlg.show()
 
 currentOptionsDialog = dlg
 
 dlg.setOnDismissListener({
 onDismiss = function()
 currentOptionsDialog = nil
 end
 })
 end
 
 function shareAudioFile(file)
 if currentOptionsDialog then
 currentOptionsDialog.dismiss()
 currentOptionsDialog = nil
 end
 
 local filePath = "/storage/emulated/0/Audio/Podcast Generator/" .. file.name
 local audioFile = File(filePath)
 
 if not audioFile.exists() then
 showErrorDialog("فائل موجود نہیں ہے: " .. file.name)
 return
 end
 
 local Intent = luajava.bindClass("android.content.Intent")
 local Uri = luajava.bindClass("android.net.Uri")
 local Build = luajava.bindClass("android.os.Build")
 local StrictMode = luajava.bindClass("android.os.StrictMode")
 local FileInputStream = luajava.bindClass("java.io.FileInputStream")
 local FileOutputStream = luajava.bindClass("java.io.FileOutputStream")
 local FileClass = luajava.bindClass("java.io.File")
 
 local status, err = pcall(function()
 if Build.VERSION.SDK_INT >= 24 then
 local builder = StrictMode.VmPolicy.Builder()
 StrictMode.setVmPolicy(builder.build())
 end
 
 local shareIntent = Intent(Intent.ACTION_SEND)
 shareIntent.setType("audio/*")
 
 local contentUri = Uri.fromFile(audioFile)
 shareIntent.putExtra(Intent.EXTRA_STREAM, contentUri)
 
 shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
 shareIntent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
 shareIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 
 local chooser = Intent.createChooser(shareIntent, "Share Audio: " .. file.name)
 chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 activity.startActivity(chooser)
 
 vibrate() -- اسکرین ریڈر صارف کے لیے فیڈ بیک
 end)
 
 if not status then
 pcall(function()
 local tempDir = activity.getExternalCacheDir()
 if tempDir then
 local tempFile = FileClass(tempDir, "share_" .. file.name)
 
 local input = FileInputStream(audioFile)
 local output = FileOutputStream(tempFile)
 local buffer = byte[4096] -- بفر سائز
 local bytesRead = input.read(buffer)
 
 while bytesRead ~= -1 do
 output.write(buffer, 0, bytesRead)
 bytesRead = input.read(buffer)
 end
 
 output.flush()
 output.close()
 input.close()
 
 local simpleIntent = Intent(Intent.ACTION_SEND)
 simpleIntent.setType("audio/*")
 simpleIntent.putExtra(Intent.EXTRA_STREAM, Uri.fromFile(tempFile))
 simpleIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 simpleIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
 
 local finalChooser = Intent.createChooser(simpleIntent, "Share via Cache")
 finalChooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 activity.startActivity(finalChooser)
 else
 showErrorDialog("Sharing failure: " .. tostring(err))
 end
 end)
 end
 end
 
 function showRenameDialog(file, parentDialog)
 local renameInput = EditText(activity)
 renameInput.text = file.name
 local container = LinearLayout(activity)
 container.setOrientation(LinearLayout.VERTICAL)
 container.setPadding(dip2px(60), dip2px(20), dip2px(60), dip2px(20))
 container.addView(renameInput)
 local renameDlg = LuaDialog(activity)
 renameDlg.setTitle("Rename Audio File")
 renameDlg.setView(container)
 renameDlg.setPositiveButton("Rename", function()
 local newName = tostring(renameInput.text)
 if #newName > 0 then
 local oldPath = "/storage/emulated/0/Audio/Podcast Generator/" .. file.name
 local newPath = "/storage/emulated/0/Audio/Podcast Generator/" .. newName
 local oldFile = File(oldPath)
 local newFile = File(newPath)
 if oldFile.renameTo(newFile) then
 showInfoDialog("Success", "File renamed successfully!")
 audioFiles = getAudioFilesList()
 countLabel.text = "Total Files: " .. #audioFiles
 displayFiles()
 else
 showErrorDialog("Failed to rename file.")
 end
 end
 renameDlg.dismiss()
 end)
 renameDlg.setNegativeButton("Cancel", function()
 renameDlg.dismiss()
 end)
 renameDlg.show()
 end
 
 refreshButton.onClick = function()
 vibrate()
 audioFiles = getAudioFilesList()
 countLabel.text = "Total Files: " .. #audioFiles
 displayFiles()
 end
 
 closeButton.onClick = function()
 vibrate()
 d.dismiss()
 end
 
 displayFiles()
end
function formatFileSize(bytes)
 if bytes < 1024 then
 return bytes .. " B"
 elseif bytes < 1024 * 1024 then
 return string.format("%.1f KB", bytes / 1024)
 else
 return string.format("%.1f MB", bytes / (1024 * 1024))
 end
end
function formatDate(timestamp)
 local date = Date(timestamp)
 local format = SimpleDateFormat("dd/MM/yy HH:mm")
 return format.format(date)
end
function showAudioPlayerDialog()
 stopTutorialAudio()
 local TUTORIAL_AUDIO_PATH = "/storage/emulated/0/解说/Plugins/Podcast Voice Generator/How to use.mp3"
 local tutorialFile = File(TUTORIAL_AUDIO_PATH)
 if not tutorialFile.exists() then
 TUTORIAL_AUDIO_PATH = "/sdcard/解说/Plugins/Podcast Voice Generator/How to use.mp3"
 tutorialFile = File(TUTORIAL_AUDIO_PATH)
 end
 if not tutorialFile.exists() then
 TUTORIAL_AUDIO_PATH = activity.getExternalFilesDir(nil).toString() .. "/解说/Plugins/Podcast Voice Generator/How to use.mp3"
 tutorialFile = File(TUTORIAL_AUDIO_PATH)
 end
 if not tutorialFile.exists() then
 showErrorDialog("Tutorial audio file not found!\n\nPlease place 'How to use.mp3' in:\n\nInternal Storage/解说/Plugins/Podcast Voice Generator/\n\nOr\n\n" .. activity.getExternalFilesDir(nil).toString() .. "/解说/Plugins/Podcast Voice Generator/")
 return
 end
 
 local isPlaying = false
 local currentPosition = 0
 local duration = 0
 local playbackSpeed = 1.0
 local speedOptions = {"0.5x", "0.75x", "1.0x", "1.25x", "1.5x", "2.0x"}
 local speedValues = {0.5, 0.75, 1.0, 1.25, 1.5, 2.0}
 local currentSpeedIndex = 3
 local updateHandler = Handler()
 local updateRunnable = nil
 local tutorialPlayer = nil
 
 updateRunnable = Runnable({
 run = function()
 if tutorialPlayer and isPlaying then
 pcall(function()
 local currentPos = tutorialPlayer.getCurrentPosition()
 playerSeekBar.setProgress(currentPos)
 currentTimeText.text = formatTime(currentPos)
 end)
 updateHandler.postDelayed(updateRunnable, 500)
 end
 end
 })
 
 local function startUpdateTimer()
 isPlaying = true
 updateHandler.post(updateRunnable)
 end
 
 local function stopUpdateTimer()
 isPlaying = false
 updateHandler.removeCallbacks(updateRunnable)
 end
 
 local function stopTutorialAudioInternal()
 stopUpdateTimer()
 if tutorialPlayer then
 pcall(function()
 local playerReleased = false
 pcall(function()
 tutorialPlayer.isPlaying()
 end, function(err)
 playerReleased = true
 end)
 if not playerReleased then
 if tutorialPlayer.isPlaying() then
 tutorialPlayer.stop()
 end
 tutorialPlayer.release()
 end
 end)
 tutorialPlayer = nil
 end
 end
 
 local function formatTime(milliseconds)
 local totalSeconds = math.floor(milliseconds / 1000)
 local minutes = math.floor(totalSeconds / 60)
 local seconds = totalSeconds % 60
 return string.format("%02d:%02d", minutes, seconds)
 end
 
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT))
 mainLayout.setPadding(dip2px(20), dip2px(20), dip2px(20), dip2px(20))
 
 local titleLabel = TextView(activity)
 titleLabel.text = "How to Use - Tutorial Guide"
 titleLabel.textSize = 20
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFF2196F3)
 titleLabel.gravity = Gravity.CENTER
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(10)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 
 local fileLabel = TextView(activity)
 fileLabel.text = "File: How to use.mp3"
 fileLabel.textSize = 14
 fileLabel.setTextColor(0xFF666666)
 fileLabel.gravity = Gravity.CENTER
 local fileParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 fileParams.bottomMargin = dip2px(5)
 fileLabel.setLayoutParams(fileParams)
 mainLayout.addView(fileLabel)
 
 local pathLabel = TextView(activity)
 pathLabel.text = "Path: " .. TUTORIAL_AUDIO_PATH
 pathLabel.textSize = 10
 pathLabel.setTextColor(0xFF888888)
 pathLabel.gravity = Gravity.CENTER
 pathLabel.setSingleLine(false)
 pathLabel.setMaxLines(2)
 pathLabel.setEllipsize(TextUtils.TruncateAt.START)
 local pathParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 pathParams.bottomMargin = dip2px(15)
 pathLabel.setLayoutParams(pathParams)
 mainLayout.addView(pathLabel)
 
 local progressLayout = LinearLayout(activity)
 progressLayout.setOrientation(LinearLayout.HORIZONTAL)
 progressLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 
 local currentTimeText = TextView(activity)
 currentTimeText.text = "00:00"
 currentTimeText.textSize = 14
 currentTimeText.setTypeface(Typeface.DEFAULT_BOLD)
 currentTimeText.setTextColor(0xFF2196F3)
 currentTimeText.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 progressLayout.addView(currentTimeText)
 
 local playerSeekBar = SeekBar(activity)
 local seekParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1)
 seekParams.leftMargin = dip2px(10)
 seekParams.rightMargin = dip2px(10)
 playerSeekBar.setLayoutParams(seekParams)
 progressLayout.addView(playerSeekBar)
 
 local durationText = TextView(activity)
 durationText.text = "00:00"
 durationText.textSize = 14
 durationText.setTypeface(Typeface.DEFAULT_BOLD)
 durationText.setTextColor(0xFF666666)
 durationText.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 progressLayout.addView(durationText)
 
 mainLayout.addView(progressLayout)
 
 local speedLayout = LinearLayout(activity)
 speedLayout.setOrientation(LinearLayout.HORIZONTAL)
 local speedParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 speedParams.topMargin = dip2px(25)
 speedParams.bottomMargin = dip2px(25)
 speedLayout.setLayoutParams(speedParams)
 speedLayout.gravity = Gravity.CENTER
 
 local speedLabel = TextView(activity)
 speedLabel.text = "Playback Speed:"
 speedLabel.textSize = 14
 speedLabel.setTypeface(Typeface.DEFAULT_BOLD)
 speedLabel.setTextColor(0xFF333333)
 speedLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 speedLayout.addView(speedLabel)
 
 local speedSpinner = Spinner(activity)
 local spinnerParams = LinearLayout.LayoutParams(dip2px(120), LinearLayout.LayoutParams.WRAP_CONTENT)
 spinnerParams.leftMargin = dip2px(15)
 speedSpinner.setLayoutParams(spinnerParams)
 speedLayout.addView(speedSpinner)
 
 mainLayout.addView(speedLayout)
 
 local instructionLabel = TextView(activity)
 instructionLabel.text = "Listen to this tutorial to learn how to use the Podcast Voice Generator plugin effectively."
 instructionLabel.textSize = 12
 instructionLabel.setTextColor(0xFF555555)
 instructionLabel.setGravity(Gravity.CENTER)
 instructionLabel.setLineSpacing(dip2px(2), 1.2)
 local instructionParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 instructionParams.bottomMargin = dip2px(20)
 instructionLabel.setLayoutParams(instructionParams)
 mainLayout.addView(instructionLabel)
 
 local spacer = View(activity)
 local spacerParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1)
 spacer.setLayoutParams(spacerParams)
 mainLayout.addView(spacer)
 
 local controlLayout = LinearLayout(activity)
 controlLayout.setOrientation(LinearLayout.HORIZONTAL)
 controlLayout.setGravity = Gravity.CENTER
 local controlParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 controlParams.bottomMargin = dip2px(15)
 controlLayout.setLayoutParams(controlParams)
 
 local rewindButton = Button(activity)
 rewindButton.text = "⏪ 10s"
 rewindButton.setTextSize(14)
 local rewindParams = LinearLayout.LayoutParams(dip2px(90), dip2px(45))
 rewindParams.rightMargin = dip2px(15)
 rewindButton.setLayoutParams(rewindParams)
 controlLayout.addView(rewindButton)
 
 local playPauseButton = Button(activity)
 playPauseButton.text = "▶ Play"
 playPauseButton.setTextSize(16)
 playPauseButton.setTypeface(Typeface.DEFAULT_BOLD)
 local playParams = LinearLayout.LayoutParams(dip2px(100), dip2px(50))
 playParams.leftMargin = dip2px(10)
 playParams.rightMargin = dip2px(10)
 playPauseButton.setLayoutParams(playParams)
 controlLayout.addView(playPauseButton)
 
 local forwardButton = Button(activity)
 forwardButton.text = "10s ⏩"
 forwardButton.setTextSize(14)
 local forwardParams = LinearLayout.LayoutParams(dip2px(90), dip2px(45))
 forwardParams.leftMargin = dip2px(15)
 forwardButton.setLayoutParams(forwardParams)
 controlLayout.addView(forwardButton)
 
 mainLayout.addView(controlLayout)
 
 local closeButtonLayout = LinearLayout(activity)
 closeButtonLayout.setOrientation(LinearLayout.HORIZONTAL)
 closeButtonLayout.setGravity = Gravity.CENTER
 closeButtonLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 
 local closeButton = Button(activity)
 closeButton.text = "CLOSE TUTORIAL"
 closeButton.setTextSize(14)
 closeButton.setTypeface(Typeface.DEFAULT_BOLD)
 closeButton.setTextColor(0xFFFFFFFF)
 closeButton.setBackgroundColor(0xFFF44336)
 local closeBtnParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(50))
 closeButton.setLayoutParams(closeBtnParams)
 closeButtonLayout.addView(closeButton)
 
 mainLayout.addView(closeButtonLayout)
 
 scrollView.addView(mainLayout)
 
 local d = LuaDialog(activity)
 .setTitle("Tutorial Audio Player")
 .setView(scrollView)
 .show()
 
 local speedAdapter = ArrayAdapter(activity, android.R.layout.simple_spinner_item, speedOptions)
 speedAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
 speedSpinner.setAdapter(speedAdapter)
 speedSpinner.setSelection(currentSpeedIndex - 1)
 
 local function initializePlayer()
 local success, errorMsg = pcall(function()
 tutorialPlayer = MediaPlayer()
 tutorialPlayer.setDataSource(TUTORIAL_AUDIO_PATH)
 tutorialPlayer.prepare()
 duration = tutorialPlayer.getDuration()
 durationText.text = formatTime(duration)
 playerSeekBar.setMax(duration)
 playerSeekBar.setProgress(0)
 currentTimeText.text = "00:00"
 if Build.VERSION.SDK_INT >= 23 then
 pcall(function()
 local params = tutorialPlayer.getPlaybackParams()
 params = params.setSpeed(playbackSpeed)
 tutorialPlayer.setPlaybackParams(params)
 end)
 end
 tutorialPlayer.start()
 isPlaying = true
 playPauseButton.text = "⏸ Pause"
 startUpdateTimer()
 end)
 if not success then
 showErrorDialog("Failed to play tutorial:\n" .. tostring(errorMsg))
 return false
 end
 return true
 end
 
 if not initializePlayer() then
 d.dismiss()
 return
 end
 
 speedSpinner.setOnItemSelectedListener(AdapterView.OnItemSelectedListener{
 onItemSelected = function(parent, view, position, id)
 playbackSpeed = speedValues[position + 1]
 if tutorialPlayer then
 if Build.VERSION.SDK_INT >= 23 then
 pcall(function()
 local wasPlaying = false
 pcall(function()
 wasPlaying = tutorialPlayer.isPlaying()
 end)
 if wasPlaying then 
 tutorialPlayer.pause() 
 end
 local params = tutorialPlayer.getPlaybackParams()
 params = params.setSpeed(playbackSpeed)
 tutorialPlayer.setPlaybackParams(params)
 if wasPlaying then 
 tutorialPlayer.start() 
 end
 end)
 end
 end
 end,
 onNothingSelected = function(parent)
 end
 })
 
 tutorialPlayer.setOnCompletionListener(MediaPlayer.OnCompletionListener{
 onCompletion = function(mp)
 runOnUi(function()
 isPlaying = false
 playPauseButton.text = "▶ Play"
 stopUpdateTimer()
 playerSeekBar.setProgress(duration)
 currentTimeText.text = formatTime(duration)
 end)
 end
 })
 
 playerSeekBar.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
 onProgressChanged = function(seekBar, progress, fromUser)
 if fromUser then
 currentTimeText.text = formatTime(progress)
 end
 end,
 onStartTrackingTouch = function(seekBar)
 end,
 onStopTrackingTouch = function(seekBar)
 if tutorialPlayer then
 pcall(function()
 local wasPlaying = false
 pcall(function()
 wasPlaying = tutorialPlayer.isPlaying()
 end)
 if wasPlaying then
 tutorialPlayer.pause()
 end
 tutorialPlayer.seekTo(seekBar.getProgress())
 if wasPlaying then
 tutorialPlayer.start()
 end
 end)
 end
 end
 })
 
 playPauseButton.onClick = function()
 vibrate()
 if not tutorialPlayer then return end
 pcall(function()
 if isPlaying then
 tutorialPlayer.pause()
 isPlaying = false
 playPauseButton.text = "▶ Play"
 stopUpdateTimer()
 else
 tutorialPlayer.start()
 isPlaying = true
 playPauseButton.text = "⏸ Pause"
 startUpdateTimer()
 end
 end)
 end
 
 rewindButton.onClick = function()
 vibrate()
 if not tutorialPlayer then return end
 pcall(function()
 local currentPos = tutorialPlayer.getCurrentPosition()
 local newPos = math.max(0, currentPos - 10000)
 tutorialPlayer.seekTo(newPos)
 playerSeekBar.setProgress(newPos)
 currentTimeText.text = formatTime(newPos)
 end)
 end
 
 forwardButton.onClick = function()
 vibrate()
 if not tutorialPlayer then return end
 pcall(function()
 local currentPos = tutorialPlayer.getCurrentPosition()
 local newPos = math.min(duration, currentPos + 10000)
 tutorialPlayer.seekTo(newPos)
 playerSeekBar.setProgress(newPos)
 currentTimeText.text = formatTime(newPos)
 end)
 end
 
 closeButton.onClick = function()
 vibrate()
 stopTutorialAudioInternal()
 d.dismiss()
 end
 
 d.setOnDismissListener(DialogInterface.OnDismissListener{
 onDismiss = function()
 stopTutorialAudioInternal()
 end
 })
end
function showAboutDialog()
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 
 local titleLabel = TextView(activity)
 titleLabel.text = "Podcast Voice Generator"
 titleLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 titleLabel.textSize = 16
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setGravity(Gravity.CENTER)
 mainLayout.addView(titleLabel)
 
 local providerLabel = TextView(activity)
 providerLabel.text = "Using " .. tostring(SELECTED_API_PROVIDER)
 providerLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 providerLabel.setGravity(Gravity.CENTER)
 providerLabel.textSize = 12
 mainLayout.addView(providerLabel)
 
 local versionLabel = TextView(activity)
 versionLabel.text = "Version " .. CURRENT_VERSION
 versionLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 versionLabel.setGravity(Gravity.CENTER)
 versionLabel.textSize = 12
 mainLayout.addView(versionLabel)
 
 local divider1 = View(activity)
 divider1.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(1)))
 divider1.setBackgroundColor(0xFFCCCCCC)
 local divider1Params = divider1.getLayoutParams()
 if divider1Params then
 divider1Params.topMargin = dip2px(10)
 divider1Params.bottomMargin = dip2px(10)
 end
 mainLayout.addView(divider1)
 
 local connectLabel = TextView(activity)
 connectLabel.text = "Connect with Developer:"
 connectLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 connectLabel.textSize = 14
 mainLayout.addView(connectLabel)
 
 local whatsappButton = Button(activity)
 whatsappButton.text = "Contact Developer (WhatsApp)"
 whatsappButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local whatsappButtonParams = whatsappButton.getLayoutParams()
 if whatsappButtonParams then
 whatsappButtonParams.topMargin = dip2px(5)
 end
 mainLayout.addView(whatsappButton)
 
 local telegramButton = Button(activity)
 telegramButton.text = "Join Telegram Channel"
 telegramButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local telegramButtonParams = telegramButton.getLayoutParams()
 if telegramButtonParams then
 telegramButtonParams.topMargin = dip2px(5)
 end
 mainLayout.addView(telegramButton)
 
 local youtubeButton = Button(activity)
 youtubeButton.text = "Watch tutorial playlist by Nafees Khan"
 youtubeButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local youtubeButtonParams = youtubeButton.getLayoutParams()
 if youtubeButtonParams then
 youtubeButtonParams.topMargin = dip2px(5)
 end
 mainLayout.addView(youtubeButton)
 
 local updateButton = Button(activity)
 updateButton.text = "🔍 Check for Updates"
 updateButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local updateButtonParams = updateButton.getLayoutParams()
 if updateButtonParams then
 updateButtonParams.topMargin = dip2px(5)
 end
 mainLayout.addView(updateButton)
 
 local licenseButton = Button(activity)
 licenseButton.text = "📄 Licenses and Agreements"
 licenseButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local licenseButtonParams = licenseButton.getLayoutParams()
 if licenseButtonParams then
 licenseButtonParams.topMargin = dip2px(5)
 end
 mainLayout.addView(licenseButton)
 
 local divider2 = View(activity)
 divider2.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(1)))
 divider2.setBackgroundColor(0xFFCCCCCC)
 local divider2Params = divider2.getLayoutParams()
 if divider2Params then
 divider2Params.topMargin = dip2px(10)
 divider2Params.bottomMargin = dip2px(10)
 end
 mainLayout.addView(divider2)
 
 local configLabel = TextView(activity)
 configLabel.text = "Current configuration:"
 configLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 configLabel.textSize = 12
 mainLayout.addView(configLabel)
 
 local providerInfo = TextView(activity)
 providerInfo.text = "Provider: " .. tostring(SELECTED_API_PROVIDER)
 providerInfo.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 providerInfo.textSize = 12
 mainLayout.addView(providerInfo)
 
 local voicesInfo = TextView(activity)
 voicesInfo.text = "Available Voices: " .. (SELECTED_API_PROVIDER == "OpenAI Official (GPT-4o mini TTS)" and "6" or "31")
 voicesInfo.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 voicesInfo.textSize = 12
 mainLayout.addView(voicesInfo)
 
 if API_KEY and #API_KEY > 5 then
 local apiInfo = TextView(activity)
 apiInfo.text = "API Key: Configured"
 apiInfo.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 apiInfo.textSize = 12
 mainLayout.addView(apiInfo)
 else
 local apiInfo = TextView(activity)
 apiInfo.text = "API Key: Not configured"
 apiInfo.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 apiInfo.textSize = 12
 apiInfo.setTextColor(0xFFFF0000)
 mainLayout.addView(apiInfo)
 end
 
 local configButton = Button(activity)
 configButton.text = "Configure API Settings"
 configButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local configButtonParams = configButton.getLayoutParams()
 if configButtonParams then
 configButtonParams.topMargin = dip2px(10)
 end
 mainLayout.addView(configButton)
 
 local tutorialButton = Button(activity)
 tutorialButton.text = "How to Use Tutorial"
 tutorialButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local tutorialButtonParams = tutorialButton.getLayoutParams()
 if tutorialButtonParams then
 tutorialButtonParams.topMargin = dip2px(5)
 end
 mainLayout.addView(tutorialButton)
 
 scrollView.addView(mainLayout)
 
 local aboutDialog = LuaDialog(activity)
 aboutDialog.setTitle("About & Configuration")
 aboutDialog.setView(scrollView)
 aboutDialog.setPositiveButton("OK", function()
 aboutDialog.dismiss()
 end)
 
 configButton.onClick = function()
 aboutDialog.dismiss()
 vibrate()
 showGeminiConfigDialog()
 end
 
 tutorialButton.onClick = function()
 aboutDialog.dismiss()
 vibrate()
 showAudioPlayerDialog()
 end
 
 updateButton.onClick = function()
 aboutDialog.dismiss()
 vibrate()
 checkForUpdate(true, function(updateAvailable, message)
 if not updateAvailable then
 showInfoDialog("Update Check", "You have the latest version!")
 end
 end)
 end
 
 licenseButton.onClick = function()
 aboutDialog.dismiss()
 vibrate()
 showLicenseDialog()
 end
 
 whatsappButton.onClick = function()
 aboutDialog.dismiss()
 vibrate()
 local whatsappMessage = "Hello! I'm using your Podcast Voice Generator extension. It's amazing!"
 local finalUrl = "https://wa.me/message/W4BX62NMZLS3L1?text=" .. Uri.encode(whatsappMessage)
 local intent = Intent(Intent.ACTION_VIEW, Uri.parse(finalUrl))
 intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 activity.startActivity(intent)
 end
 
 telegramButton.onClick = function()
 aboutDialog.dismiss()
 vibrate()
 local intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/TechForVI"))
 intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 activity.startActivity(intent)
 end
 
 youtubeButton.onClick = function()
 aboutDialog.dismiss()
 vibrate()
 local intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.youtube.com/playlist?list=PLwHsDrP1D5-nJHrr7Q9iyc3g_j3imS2Io"))
 intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 activity.startActivity(intent)
 end
 
 aboutDialog.show()
end
function enhancedDownloadButtonClick()
 vibrate()
 if not finalPodcastPath and not lastGeneratedAudioPath then
 resultText.text = "Error: No audio has been created to save."
 return
 end
 local audioPath = finalPodcastPath or lastGeneratedAudioPath
 local selectedFormat = formatSpinner.getSelectedItem()
 resultText.text = "Saving audio file..."
 downloadButton.setEnabled(false)
 formatSpinner.setEnabled(false)
 Thread(Runnable{ 
 run = function()
 local savedPath, err = saveAudioFile(audioPath, selectedFormat)
 runOnUi(function()
 downloadButton.setEnabled(true)
 formatSpinner.setEnabled(true)
 if savedPath then
 local actualFormat = savedPath:match("%.([a-zA-Z0-9]+)$")
 resultText.text = string.format("Successfully saved .%s file at: %s", actualFormat, savedPath)
 showInfoDialog("Success", "Audio saved successfully!\nLocation: " .. savedPath)
 else
 resultText.text = "Error saving file: " .. tostring(err)
 showErrorDialog("Error saving file: " .. tostring(err))
 end
 end)
 end 
 }).start()
end
function dip2px(dp)
 return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dp, activity.getResources().getDisplayMetrics())
end
function reopenDialogWithCurrentState()
 isDialogHidden = false
 if dlg and not dlg.isShowing() then
 dlg.show()
 end
 if lastGeneratedAudioPath then
 finalPodcastPath = lastGeneratedAudioPath
 if playButton and downloadButton and formatSpinner then
 playButton.setVisibility(View.VISIBLE)
 downloadButton.setVisibility(View.VISIBLE)
 formatSpinner.setVisibility(View.VISIBLE)
 playButton.text = "Listen"
 playButton.setEnabled(true)
 end
 if lastGeneratedAudioType == "podcast" then
 if resultText then
 resultText.text = "Podcast is ready! You can listen or save."
 end
 stopAudio()
 audioPlayer = MediaPlayer()
 activePlayers["main"] = audioPlayer
 pcall(function()
 audioPlayer.setDataSource(lastGeneratedAudioPath)
 audioPlayer.prepare()
 audioPlayer.setOnCompletionListener(MediaPlayer.OnCompletionListener{
 onCompletion = function(mp)
 runOnUi(function()
 if playButton then
 playButton.text = "Listen to Podcast"
 playButton.setEnabled(true)
 end
 end)
 end
 })
 end)
 else
 if resultText then
 resultText.text = "Audio is ready! You can listen or save."
 end
 stopTestAudio()
 testAudioPlayer = MediaPlayer()
 activePlayers["test"] = testAudioPlayer
 pcall(function()
 testAudioPlayer.setDataSource(lastGeneratedAudioPath)
 testAudioPlayer.prepare()
 testAudioPlayer.setOnCompletionListener(MediaPlayer.OnCompletionListener{
 onCompletion = function(mp)
 runOnUi(function()
 if playButton then
 playButton.text = "Listen"
 playButton.setEnabled(true)
 end
 end)
 end
 })
 end)
 end
 end
end
function updateVoiceSelector()
 if not voiceSelectorSpinner then return end
 local visibleVoices = {}
 if currentMode == 0 then
 voiceSelectorLayout.setVisibility(View.GONE)
 return
 elseif currentMode == 1 then
 voiceSelectorLayout.setVisibility(View.VISIBLE)
 for i = 1, 2 do
 table.insert(visibleVoices, configNames[i])
 end
 elseif currentMode == 2 then
 voiceSelectorLayout.setVisibility(View.VISIBLE)
 for i = 1, 4 do
 table.insert(visibleVoices, configNames[i])
 end
 elseif currentMode == 3 then
 voiceSelectorLayout.setVisibility(View.VISIBLE)
 for i = 1, 6 do
 table.insert(visibleVoices, configNames[i])
 end
 end
 local voiceAdapter = ArrayAdapter(activity, android.R.layout.simple_spinner_item, visibleVoices)
 voiceAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
 voiceSelectorSpinner.setAdapter(voiceAdapter)
end
function handlePlayButtonClick()
 vibrate()
 local audioPath = finalPodcastPath or lastGeneratedAudioPath
 if not audioPath then
 resultText.text = "Error: No audio has been created."
 return
 end
 
 local function updatePlayButtonState(btnText)
 runOnUi(function()
 playButton.text = btnText
 playButton.setEnabled(true)
 end)
 end
 if audioPlayer and audioPath == finalPodcastPath then
 if audioPlayer.isPlaying() then
 audioPlayer.pause()
 updatePlayButtonState("Listen to Podcast")
 else
 audioPlayer.start()
 playButton.text = "Stop"
 audioPlayer.setOnCompletionListener(MediaPlayer.OnCompletionListener{
 onCompletion = function(mp) updatePlayButtonState("Listen to Podcast") end
 })
 end
 elseif testAudioPlayer and audioPath ~= finalPodcastPath then
 if testAudioPlayer.isPlaying() then
 testAudioPlayer.pause()
 updatePlayButtonState("Listen")
 else
 testAudioPlayer.start()
 playButton.text = "Stop"
 testAudioPlayer.setOnCompletionListener(MediaPlayer.OnCompletionListener{
 onCompletion = function(mp) updatePlayButtonState("Listen") end
 })
 end
 else
 if audioPath == finalPodcastPath then
 stopAudio()
 audioPlayer = MediaPlayer()
 audioPlayer.setDataSource(audioPath)
 audioPlayer.prepare()
 audioPlayer.start()
 playButton.text = "Stop"
 audioPlayer.setOnCompletionListener(MediaPlayer.OnCompletionListener{
 onCompletion = function(mp) updatePlayButtonState("Listen to Podcast") end
 })
 else
 stopTestAudio()
 testAudioPlayer = MediaPlayer()
 testAudioPlayer.setDataSource(audioPath)
 testAudioPlayer.prepare()
 testAudioPlayer.start()
 playButton.text = "Stop"
 testAudioPlayer.setOnCompletionListener(MediaPlayer.OnCompletionListener{
 onCompletion = function(mp) updatePlayButtonState("Listen") end
 })
 end
 end
end
layout = {
 ScrollView,
 layout_width = "fill",
 layout_height = "fill",
 {
 LinearLayout,
 orientation = "vertical",
 layout_width = "fill",
 layout_height = "wrap_content",
 padding = "16dp",
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginBottom = "10dp",
 { TextView, text = "Mode:", textSize = "14sp", gravity = "center_vertical", layout_width = "wrap_content", layout_height = "wrap_content", layout_marginRight = "10dp" },
 { Spinner, id = "modeSpinner", layout_width = "fill", layout_weight = 1, layout_height = "wrap_content" }
 },
 { View, layout_height="1dp", backgroundColor=0xFF888888, layout_width="fill", layout_marginTop="5dp", layout_marginBottom="15dp" },
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 { Button, id = "btnConfigVoice1", text = "Configure Voice", layout_width = "0dp", layout_weight = 1, layout_height = "wrap_content", textSize = "12sp", layout_marginRight = "5dp", visibility = View.VISIBLE },
 { Button, id = "btnConfigVoice2", text = "Configure Voice 2", layout_width = "0dp", layout_weight = 1, layout_height = "wrap_content", textSize = "12sp", layout_marginLeft = "5dp", visibility = View.GONE },
 },
 { View, layout_height="1dp", backgroundColor=0xFF888888, layout_width="fill", layout_marginTop="15dp", layout_marginBottom="15dp" },
 { TextView, id = "chatLabel", text = "Enter text:", textSize = "14sp" },
 {
 EditText,
 id = "chatInput",
 hint = "Type text for single voice...",
 layout_width = "fill",
 layout_height = "wrap_content",
 lines = 2,
 },
 { TextView, id = "charCounter", text = "Characters: 0/50000 | Tokens: 0/12500", textSize = "10sp", layout_width = "fill", gravity = "right" },
 {
 LinearLayout,
 id = "voiceSelectorLayout",
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "5dp",
 visibility = View.GONE,
 { TextView, text = "Select Voice:", textSize = "12sp", gravity = "center_vertical", layout_width = "wrap_content", layout_marginRight = "10dp" },
 { Spinner, id = "voiceSelectorSpinner", layout_width = "0dp", layout_weight = 1 },
 { Button, id = "btnAddToScript", text = "Add to Script", layout_width = "wrap_content", layout_marginLeft = "10dp" }
 },
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "5dp",
 { TextView, id = "dialogueEmotionLabel", text = "Apply Default Emotion to input:", textSize = "12sp", gravity = "center_vertical", layout_width = "wrap_content", layout_height = "wrap_content", layout_marginRight = "5dp", visibility = View.GONE },
 { Button, id = "btnDialogueEmotionApply", text = "Apply Tag", layout_width = "wrap_content", layout_height = "wrap_content", textSize = "12sp", layout_marginLeft = "5dp", visibility = View.GONE }
 },
 { TextView, id="podcastEmotionNote", text="*Default intonation will be used if no emotion tag.", textSize="10sp", textColor=0xFF555555, layout_marginTop="5dp", visibility=View.GONE },
 {
 LinearLayout,
 id = "addButtonsLayout",
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "5dp",
 { Button, id = "btnTestSpeak", text = "Test Listen", layout_width = "fill", layout_height = "wrap_content", textSize = "12sp" }
 },
 {
 LinearLayout,
 id = "textEmotionSpinnerLayout",
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "10dp",
 visibility = View.GONE,
 { TextView, text = "Text Emotion:", textSize = "14sp", gravity = "center_vertical", layout_width = "wrap_content", layout_height = "wrap_content", layout_marginRight = "10dp" },
 { Spinner, id = "textEmotionSpinner", layout_width = "fill", layout_weight = 1, layout_height = "wrap_content" }
 },
 { TextView, id = "scriptLabel", text = "Final Script:", textSize = "14sp", layout_marginTop = "10dp", visibility = View.GONE },
 {
 EditText,
 id = "scriptInput",
 hint = "Script will appear here...",
 layout_width = "fill",
 layout_height = "100dp",
 padding = "10dp",
 backgroundColor = 0xFFF0F0F0,
 textColor = 0xFF000000,
 lines = 10,
 inputType = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE,
 gravity = "top",
 layout_marginBottom = "10dp",
 visibility = View.GONE
 },
 {
 Button,
 id = "generateButton",
 text = "Generate Audio",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "5dp"
 },
 {
 ProgressBar,
 id = "podcastProgressBar",
 layout_width = "fill",
 layout_height = "wrap_content",
 style = "?android:attr/progressBarStyleHorizontal",
 layout_marginTop = "5dp",
 visibility = View.GONE,
 max = 100
 },
 {
 TextView,
 id = "resultText",
 text = "Status...",
 layout_width = "fill",
 layout_height = "wrap_content",
 padding = "5dp",
 textIsSelectable = true,
 },
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "5dp",
 {
 Button,
 id = "playButton",
 text = "Listen",
 layout_width = "0dp",
 layout_weight = 1,
 layout_height = "wrap_content",
 visibility = View.GONE,
 },
 {
 Spinner,
 id = "formatSpinner",
 layout_width = "0dp",
 layout_weight = 1,
 layout_height = "wrap_content",
 layout_gravity = "center_vertical",
 layout_marginLeft = "5dp",
 visibility = View.GONE
 },
 {
 Button,
 id = "downloadButton",
 text = "Save",
 layout_width = "0dp",
 layout_weight = 1,
 layout_height = "wrap_content",
 visibility = View.GONE,
 }
 },
 {
 Button,
 id = "manageAudioButton",
 text = "Manage Audio Files",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "10dp"
 },
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "10dp",
 {
 Button,
 id = "btnHideDialog",
 text = "Hide Dialog",
 layout_width = "0dp",
 layout_weight = 1,
 layout_height = "wrap_content",
 layout_marginRight = "5dp",
 onClick = function()
 vibrate()
 isDialogHidden = true
 dlg.hide()
 cleanupAllResources()
 if generateButton.text == "Processing" or generateButton.text == "Creating..." then
 showInfoDialog("Information", "Audio generation is running in background. Dialog will reopen when completed.")
 end
 end
 },
 {
 Button,
 id = "btnAbout",
 text = "Configuration & About",
 layout_width = "0dp",
 layout_weight = 1,
 layout_height = "wrap_content",
 layout_marginLeft = "5dp",
 onClick = function()
 vibrate()
 showAboutDialog()
 end
 }
 }
 }
}
dlg = LuaDialog(this)
dlg.setTitle("Podcast Voice Generator")
dlg.setView(loadlayout(layout))
dlg.setNegativeButton("Close", function()
 vibrate()
 cleanupAllResources()
 releaseWakeLock()
 clearBackgroundServiceState()
 isDialogHidden = false
 dlg.dismiss()
end)
local modeAdapter = ArrayAdapter(activity, android.R.layout.simple_spinner_item, modes)
modeAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
modeSpinner.setAdapter(modeAdapter)
modeSpinner.setSelection(0)
local textEmotionAdapter = ArrayAdapter(activity, android.R.layout.simple_spinner_item, textEmotionModes)
textEmotionAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
textEmotionSpinner.setAdapter(textEmotionAdapter)
textEmotionSpinner.setSelection(0)
textEmotionSpinner.setOnItemSelectedListener(AdapterView.OnItemSelectedListener{
 onItemSelected = function(parent, view, position, id)
 textEmotionMode = textEmotionModes[position + 1]
 saveConfig()
 end
})
local formatAdapter = ArrayAdapter(activity, android.R.layout.simple_spinner_item, formatOptions)
formatAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
formatSpinner.setAdapter(formatAdapter)
formatSpinner.setSelection(0)
modeSpinner.setOnItemSelectedListener(AdapterView.OnItemSelectedListener{
 onItemSelected = function(parent, view, position, id)
 runOnUi(function()
 updateUIMode(position)
 saveConfig()
 end)
 end
})
chatInput.addTextChangedListener(TextWatcher{
 onTextChanged = function(s, start, before, count)
 updateCharCounter()
 end
})
btnAddToScript.onClick = function()
 vibrate()
 if not voiceSelectorSpinner then return end
 local selectedVoice = voiceSelectorSpinner.getSelectedItem()
 local message = chatInput.getText().toString()
 if selectedVoice and #message > 0 then
 if scriptInput then
 scriptInput.append(selectedVoice .. ": " .. message .. "\n")
 end
 chatInput.setText("")
 end
end
btnConfigVoice1.onClick = function()
 vibrate()
 if currentMode == 0 then showVoiceConfigDialog(1) else showAllVoicesConfigDialog() end
end
btnConfigVoice2.onClick = function()
 vibrate()
 if currentMode == 1 then showVoiceConfigDialog(2) end
end
btnDialogueEmotionApply.onClick = function()
 vibrate()
 if currentMode < 1 then return end
 local currentText = chatInput.text
 if #currentText == 0 then return end
 local nameToApply = configNames[1]
 local selectedEmotion = configEmotions[1]
 local emotionTag = ""
 if selectedEmotion ~= "Default" then
 local emotionName = selectedEmotion:match("^(.-)%s*%(") or selectedEmotion
 if selectedEmotion == "Custom" then emotionName = "Custom" end
 emotionTag = "[" .. emotionName .. "] "
 end
 local cleanedText = currentText:gsub("^%s*%[.-%]%s*", ""):gsub("^%s*" .. nameToApply .. ":%s*", "")
 chatInput.text = nameToApply .. ": " .. emotionTag .. cleanedText
end
btnTestSpeak.onClick = function()
 vibrate()
 if testAudioPlayer and testAudioPlayer.isPlaying() then
 stopTestAudio()
 btnTestSpeak.text = "Test Listen"
 return
 end
 local text = chatInput.text
 if #text == 0 then return end
 local selectedVoice = configVoices[1]
 local currentEmotion = selectedEmotionSingle
 if currentMode >= 1 then
 local selectedIndex = voiceSelectorSpinner.getSelectedItemPosition()
 if selectedIndex >= 0 then
 selectedVoice = configVoices[selectedIndex + 1]
 currentEmotion = configEmotions[selectedIndex + 1]
 end
 end
 stopAudio()
 btnTestSpeak.text = "Creating..."
 Thread(Runnable{ run = function() testSpeak(text, selectedVoice, currentEmotion, configSpeeds[1], configPitches[1], false, false) end }).start()
end
generateButton.onClick = function()
 vibrate()
 local mode = modeSpinner.getSelectedItemPosition()
 stopAudio()
 stopTestAudio()
 
 local function resetGenerateUI()
 runOnUi(function()
 generateButton.setEnabled(true)
 generateButton.text = (mode == 0) and "Generate Audio" or "Generate Podcast"
 if podcastProgressBar then podcastProgressBar.setVisibility(View.GONE) end
 end)
 end
 if playButton then playButton.setVisibility(View.GONE) end
 if downloadButton then downloadButton.setVisibility(View.GONE) end
 if podcastProgressBar then 
 podcastProgressBar.setVisibility(View.GONE)
 podcastProgressBar.setProgress(0)
 end
 generateButton.setEnabled(false)
 isAudioAutoPlayEnabled = false
 if mode == 0 then
 local text = chatInput.text
 if #text == 0 then
 resetGenerateUI()
 showErrorDialog("Please enter text.")
 return
 end
 
 generateButton.text = "Creating..."
 Thread(Runnable{ 
 run = function()
 testSpeak(text, configVoices[1], selectedEmotionSingle, configSpeeds[1], configPitches[1], true, false)
 end 
 }).start()
 else
 processMultiVoicePodcast()
 end
end
playButton.onClick = handlePlayButtonClick
manageAudioButton.onClick = function() vibrate(); showAudioManagementDialog() end
downloadButton.onClick = enhancedDownloadButtonClick
loadConfig()
loadGenerationState()
if lastGeneratedAudioPath and File(lastGeneratedAudioPath).exists() then
 runOnUi(function()
 resultText.text = "Last generated audio is ready!"
 playButton.setVisibility(View.VISIBLE)
 downloadButton.setVisibility(View.VISIBLE)
 formatSpinner.setVisibility(View.VISIBLE)
 playButton.text = "Listen"
 playButton.setEnabled(true)
 end)
end
function updateUIModeOnLoad()
 updateUIMode(currentMode)
 updateVoiceSelector()
end
updateUIModeOnLoad()
performAutoChecks()
if not resumeGenerationIfNeeded() then
 if not isDialogHidden then
 dlg.show()
 end
end