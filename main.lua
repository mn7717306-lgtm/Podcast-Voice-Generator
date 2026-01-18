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
local CURRENT_VERSION = "1.0"
local GITHUB_REPO_URL = "https://github.com/mn7717306-lgtm/Podcast-Voice-Generator"
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/mn7717306-lgtm/Podcast-Voice-Generator/main/"
local VERSION_URL = GITHUB_RAW_URL .. "version.txt"
local UPDATE_URL = GITHUB_RAW_URL .. "update.txt"
local MESSAGE_URL = GITHUB_RAW_URL .. "Message.txt"
local LINK_URL = GITHUB_RAW_URL .. "Link.txt"
local LICENSE_URL = GITHUB_RAW_URL .. "LICENSE"
local PLUGIN_PATH = "/storage/emulated/0/瑙ｈ/Plugins/Podcast Voice Generator/main.lua"
local PLUGIN_DIR = "/storage/emulated/0/瑙ｈ/Plugins/Podcast Voice Generator/"
local UPDATE_PREFS = "UPDATE_CONFIG"
local MESSAGE_PREFS = "MESSAGE_CONFIG"
local LINK_PREFS = "LINK_CONFIG"
local updateInProgress = false
local lastUpdateCheckTime = 0
local UPDATE_CHECK_INTERVAL = 24 * 60 * 60 * 1000
local mainHandler = Handler(Looper.getMainLooper())
local GEMINI_PREFS = "GEMINI_CONFIG"
local PREFS_NAME = "VOICE_CONFIG"
local GENERATION_STATE_PREFS = "GENERATION_STATE"
local BACKGROUND_SERVICE_PREFS = "BACKGROUND_SERVICE"
local FEEDBACK_API_URL = "https://text-psi-ashen.vercel.app/api/send"
local USERNAME_PREFS = "USERNAME_CONFIG"
local FEEDBACK_PREFS = "FEEDBACK_CONFIG"
local currentUsername = ""
local isFeedbackEnabled = true
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

function getUsernamePrefs()
 return activity.getSharedPreferences(USERNAME_PREFS, Context.MODE_PRIVATE)
end

function getFeedbackPrefs()
 return activity.getSharedPreferences(FEEDBACK_PREFS, Context.MODE_PRIVATE)
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

function getUsernamePrefs()
 return activity.getSharedPreferences("PodcastGeneratorPrefs", Context.MODE_PRIVATE)
end
function validateUsername(input)
 if not input or type(input) ~= "string" then return false end
 local len = utf8.len(input) or #input
 if len < 6 or len > 30 then return false end
 if not input:match("^[A-Za-z .]+$") then return false end
 if input:match("%s%s") then return false end
 if input:match("^%s") or input:match("%s$") then return false end
 return true
end
function saveUsername(username)
 if not validateUsername(username) then return false end
 local prefs = getUsernamePrefs()
 local editor = prefs.edit()
 editor.putString("username", username)
 editor.putBoolean("username_set", true)
 local success = editor.commit()
 if success then
 currentUsername = username
 end
 return success
end
function loadUsername()
 local prefs = getUsernamePrefs()
 currentUsername = prefs.getString("username", "")
 return currentUsername
end
function isUsernameSet()
 local prefs = getUsernamePrefs()
 return prefs.getBoolean("username_set", false)
end
function setupUsernameSystem()
 if isUsernameSet() then return end
 
 local usernameDialog = LuaDialog(activity)
 usernameDialog.setTitle("Welcome to Podcast Voice Generator")
 usernameDialog.setMessage("Please enter your username to continue.\n(Requirements: 6-30 letters, spaces or dots only)")
 
 local usernameInput = EditText(activity)
 usernameInput.setHint("Type your username here...")
 usernameInput.setContentDescription("Enter username, 6 to 30 characters")
 
 usernameDialog.setView(usernameInput)
 
 usernameDialog.setPositiveButton("Save & Start", function(dialog, which)
 local username = tostring(usernameInput.text)
 if validateUsername(username) then
 if saveUsername(username) then
 showInfoDialog("Success", "Welcome " .. username .. "! You can now use the extension.")
 if type(reopenDialogWithCurrentState) == "function" then
 reopenDialogWithCurrentState()
 end
 end
 else
 showErrorDialog("Invalid Name! Please use 6-30 letters, spaces, or dots only.")
 setupUsernameSystem()
 end
 end)
 
 usernameDialog.setNegativeButton("Exit Plugin", function(dialog, which)
 dialog.dismiss()
 if service then
 service.stopSelf() -- یہ پلگ ان سروس کو بند کرنے کا درست طریقہ ہے
 end
 end)
 
 usernameDialog.setCancelable(false) 
 usernameDialog.show()
end

function sanitizeFeedbackText(text)
 if not text or type(text) ~= "string" then return "" end
 local replacements = {
 {"\n", "[NL]"},
 {"\"", "[QUOTE]"},
 {"'", "[SQUOTE]"},
 {"\t", "[TAB]"},
 {"|", "[PIPE]"},
 {",", "[COMMA]"},
 {";", "[SEMICOLON]"},
 {":", "[COLON]"},
 {"_", "[UNDERSCORE]"},
 {"\\", "[BACKSLASH]"},
 {"/", "[SLASH]"},
 {"%*", "[ASTERISK]"},
 {"%?", "[QMARK]"},
 {"!", "[EMARK]"},
 {"%%", "[PERCENT]"},
 {"&", "[AMPERSAND]"},
 {"<", "[LT]"},
 {">", "[GT]"},
 {"%[", "[BRACKET]"},
 {"%]", "[BRACKET]"},
 {"{", "[BRACE]"},
 {"}", "[BRACE]"}
 }
 local sanitized = text
 for _, rep in ipairs(replacements) do
 sanitized = sanitized:gsub(rep[1], rep[2])
 end
 return sanitized
end

function sendFeedbackToServer(feedbackText, feedbackType)
 if not isFeedbackEnabled then return end
 local sanitizedText = sanitizeFeedbackText(feedbackText)
 local data = {
 message = sanitizedText,
 userName = currentUsername ~= "" and currentUsername or "Anonymous",
 type = feedbackType or "manual",
 timestamp = os.date("%Y-%m-%d %H:%M:%S"),
 appVersion = CURRENT_VERSION
 }
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 headers.put("Accept", "application/json")
 Thread(Runnable{
 run = function()
 Http.post(FEEDBACK_API_URL, cjson.encode(data), headers, function(code, content)
 end)
 end
 }).start()
end

function showFeedbackDialog()
 local feedbackDialog = LuaDialog(activity)
 feedbackDialog.setTitle("Send Feedback to Developer")
 local feedbackInput = EditText(activity)
 feedbackInput.setHint("Type your feedback, suggestions, or report issues...")
 feedbackInput.setLines(5)
 feedbackDialog.setView(feedbackInput)
 feedbackDialog.setPositiveButton("Send", function(dialog, which)
 local feedbackText = tostring(feedbackInput.text)
 if #feedbackText > 0 then
 sendFeedbackToServer(feedbackText, "manual")
 showInfoDialog("Thank You", "Feedback sent successfully!")
 else
 showErrorDialog("Please enter feedback text.")
 end
 end)
 feedbackDialog.setNegativeButton("Cancel", nil)
 feedbackDialog.show()
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
 
 if manualCheck then
 service.speak("Checking for updates, please wait...")
 end
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
 mainLayout.setPadding(dip2px(15), dip2px(15), dip2px(15), dip2px(15))
 
 local titleLabel = TextView(activity)
 titleLabel.text = "New Update Available!"
 titleLabel.textSize = 18
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFF2196F3)
 titleLabel.setFocusable(true) -- For screen reader focus
 titleLabel.setGravity(Gravity.CENTER)
 mainLayout.addView(titleLabel)
 local versionLabel = TextView(activity)
 versionLabel.text = "Version: " .. newVersion
 versionLabel.textSize = 14
 versionLabel.setFocusable(true)
 versionLabel.setGravity(Gravity.CENTER)
 mainLayout.addView(versionLabel)
 local whatsNewLabel = TextView(activity)
 whatsNewLabel.text = "What's New in this update:"
 whatsNewLabel.textSize = 14
 whatsNewLabel.setFocusable(true)
 whatsNewLabel.setTypeface(Typeface.DEFAULT_BOLD)
 mainLayout.addView(whatsNewLabel)
 local updateTextView = TextView(activity)
 updateTextView.text = updateDetails
 updateTextView.textSize = 13
 updateTextView.setFocusable(true)
 updateTextView.setLineSpacing(dip2px(2), 1.2)
 mainLayout.addView(updateTextView)
 scrollView.addView(mainLayout)
 local updateDialog = LuaDialog(activity)
 updateDialog.setTitle("Update Notification")
 updateDialog.setView(scrollView)
 
 updateDialog.setPositiveButton("Update Now", function()
 vibrate()
 updateDialog.dismiss()
 performUpdate(newVersion)
 end)
 if manualCheck then
 updateDialog.setNegativeButton("Close", function()
 vibrate()
 updateDialog.dismiss()
 end)
 else
 updateDialog.setNegativeButton("Later", function()
 vibrate()
 updateDialog.dismiss()
 end)
 end
 updateDialog.show()
end
function performUpdate(newVersion)
 updateInProgress = true
 service.speak("Downloading update, please don't close the app...")
 
 local function downloadAndReplace()
 downloadFile(GITHUB_RAW_URL .. "main.lua", function(newContent, errorMsg)
 if newContent then
 local backupPath = PLUGIN_PATH .. ".backup"
 local status, err = pcall(function()
 local currentFile = io.open(PLUGIN_PATH, "r")
 if currentFile then
 local currentContent = currentFile:read("*a")
 currentFile:close()
 local backupFile = io.open(backupPath, "w")
 backupFile:write(currentContent)
 backupFile:close()
 end
 
 local newFile = io.open(PLUGIN_PATH, "w")
 newFile:write(newContent)
 newFile:close()
 end)
 if status then
 if File(backupPath).exists() then os.remove(backupPath) end
 runOnUi(function()
 showInfoDialog("Update Successful", "Version " .. newVersion .. " has been installed. Please restart the plugin.")
 end)
 else
 runOnUi(function()
 showErrorDialog("Write Error: " .. tostring(err))
 end)
 end
 else
 runOnUi(function()
 showErrorDialog("Download failed: " .. (errorMsg or "Unknown error"))
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
 mainLayout.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 local titleLabel = TextView(activity)
 titleLabel.text = "Server Message"
 titleLabel.textSize = 16
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFF2196F3)
 titleLabel.gravity = Gravity.CENTER
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(10)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 local messageTextView = TextView(activity)
 messageTextView.text = messageContent
 messageTextView.textSize = 12
 messageTextView.setTextColor(0xFF333333)
 messageTextView.setLineSpacing(dip2px(1), 1.1)
 messageTextView.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(messageTextView)
 local spacer = View(activity)
 local spacerParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(15))
 spacer.setLayoutParams(spacerParams)
 mainLayout.addView(spacer)
 local checkLayout = LinearLayout(activity)
 checkLayout.setOrientation(LinearLayout.HORIZONTAL)
 checkLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local checkBox = CheckBox(activity)
 checkBox.text = "Don't show again"
 checkBox.textSize = 10
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
 mainLayout.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 local titleLabel = TextView(activity)
 titleLabel.text = "New Video Uploaded!"
 titleLabel.textSize = 16
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFFFF9800)
 titleLabel.gravity = Gravity.CENTER
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(10)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 local messageTextView = TextView(activity)
 messageTextView.text = messageText or "A new video has been uploaded to our channel!"
 messageTextView.textSize = 12
 messageTextView.setTextColor(0xFF333333)
 messageTextView.setLineSpacing(dip2px(1), 1.1)
 messageTextView.setGravity(Gravity.CENTER)
 messageTextView.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(messageTextView)
 local spacer = View(activity)
 local spacerParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(20))
 spacer.setLayoutParams(spacerParams)
 mainLayout.addView(spacer)
 scrollView.addView(mainLayout)
 local videoDialog = LuaDialog(activity)
 videoDialog.setTitle("Video Notification")
 videoDialog.setView(scrollView)
 videoDialog.setPositiveButton("Watch Now", function()
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
 mainLayout.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 local titleLabel = TextView(activity)
 titleLabel.text = "License Agreement"
 titleLabel.textSize = 16
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFF333333)
 titleLabel.gravity = Gravity.CENTER
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(10)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 local licenseTextView = TextView(activity)
 if licenseContent then
 licenseTextView.text = licenseContent
 else
 licenseTextView.text = "Unable to load license. Please check your internet connection.\n\nError: " .. (errorMsg or "Unknown")
 end
 licenseTextView.textSize = 10
 licenseTextView.setTextColor(0xFF555555)
 licenseTextView.setLineSpacing(dip2px(1), 1.0)
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
 sendFeedbackToServer(tostring(msg), "error")
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
 local function getBytes(val)
 return {
 val & 0xff,
 (val >> 8) & 0xff,
 (val >> 16) & 0xff,
 (val >> 24) & 0xff
 }
 end
 local totalSizeB = getBytes(totalSize)
 local sampleRateB = getBytes(longSampleRate)
 local byteRateB = getBytes(calculatedByteRate)
 local dataLenB = getBytes(totalDataLen)
 local header = {
 0x52, 0x49, 0x46, 0x46, -- RIFF
 totalSizeB[1], totalSizeB[2], totalSizeB[3], totalSizeB[4],
 0x57, 0x41, 0x56, 0x45, -- WAVE
 0x66, 0x6d, 0x74, 0x20, -- fmt 
 0x10, 0x00, 0x00, 0x00, -- Subchunk1Size (16 for PCM)
 0x01, 0x00, -- AudioFormat (1 for PCM)
 channels & 0xff, (channels >> 8) & 0xff,
 sampleRateB[1], sampleRateB[2], sampleRateB[3], sampleRateB[4],
 byteRateB[1], byteRateB[2], byteRateB[3], byteRateB[4],
 blockAlign & 0xff, (blockAlign >> 8) & 0xff,
 bitsPerSample & 0xff, (bitsPerSample >> 8) & 0xff,
 0x64, 0x61, 0x74, 0x61, -- data
 dataLenB[1], dataLenB[2], dataLenB[3], dataLenB[4]
 }
 for i = 1, #header do
 outStream.write(header[i])
 end
end

function mergeAndSavePodcast()
 local status, err = pcall(function()
 if not audioParts or #audioParts == 0 then
 error("No audio parts to merge.")
 end
 import "java.io.FileOutputStream"
 import "java.io.File"
 
 local path = activity.getCacheDir().toString() .. "/gemini_podcast_final.wav"
 local file = File(path)
 
 if file.exists() then
 file.delete()
 Thread.sleep(100) -- سسٹم کو فائل ہینڈل آزاد کرنے کا وقت دیں
 end
 local os = FileOutputStream(file)
 local totalAudioLen = 0
 
 for i = 1, #audioParts do
 if audioParts[i] then
 totalAudioLen = totalAudioLen + #audioParts[i]
 end
 end
 writeWavHeader(os, totalAudioLen, 24000, 1, 48000)
 for i = 1, #audioParts do
 if audioParts[i] then
 os.write(audioParts[i])
 if i % 5 == 0 then os.flush() end 
 end
 end
 os.flush()
 os.getFD().sync()
 os.close()
 
 audioParts = {} 
 collectgarbage("collect") -- زبردستی ریم صاف کرنا
 
 return path
 end)
 if status then
 finalPodcastPath = err
 lastGeneratedAudioPath = finalPodcastPath
 lastGeneratedAudioType = "podcast"
 
 runOnUi(function()
 resultText.text = "Success! Podcast merge complete."
 
 if playButton then
 playButton.setVisibility(View.VISIBLE)
 playButton.text = "Listen"
 playButton.setEnabled(true)
 end
 
 if downloadButton then downloadButton.setVisibility(View.VISIBLE) end
 if formatSpinner then formatSpinner.setVisibility(View.VISIBLE) end
 if generateButton then
 generateButton.text = "Generate Audio"
 generateButton.setEnabled(true)
 end
 if podcastProgressBar then podcastProgressBar.setVisibility(View.GONE) end
 if audioPlayer then
 if audioPlayer.isPlaying() then audioPlayer.stop() end
 audioPlayer.reset()
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
 if podcastProgressBar then podcastProgressBar.setVisibility(View.GONE) end
 showErrorDialog("Merge Error: " .. tostring(err))
 end)
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
 local lastPunct = chunk:match("^.*()[%.,;!?蹟貙貨責]")
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
 sendFeedbackToServer("Long text generation started: " .. text:sub(1, 100), "auto")
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
 sendFeedbackToServer("Long text generation completed successfully", "auto")
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
 sendFeedbackToServer("Chunk error: " .. errorMsg, "error")
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
 sendFeedbackToServer("Test speak started: " .. text:sub(1, 50), "auto")
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
 backgroundWakeLock.setReferenceCounted(false)
 end
 if backgroundWakeLock and not backgroundWakeLock.isHeld() then
 backgroundWakeLock.acquire(30*60*1000)
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
 sendFeedbackToServer("Multi-voice podcast started: " .. rawText:sub(1, 100), "auto")
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
 voiceToUse = "Puck"
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
 voiceToUse = "alloy"
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
 sendFeedbackToServer("Multi-voice podcast completed successfully", "auto")
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
 sendFeedbackToServer("Line error: " .. errMsg, "error")
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
 temperature = 0.5,
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
 mainLayout.setPadding(dip2px(8), dip2px(8), dip2px(8), dip2px(8))
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
 mainLayout.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 local nameLabel = TextView(activity)
 nameLabel.text = "1. Voice Name:"
 nameLabel.textSize = 12
 mainLayout.addView(nameLabel)
 local nameInput = EditText(activity)
 nameInput.text = tempName
 nameInput.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 nameInput.hint = "Example: Host, Guest..."
 mainLayout.addView(nameInput)
 local voiceLabel = TextView(activity)
 voiceLabel.text = "2. Select Voice:"
 voiceLabel.textSize = 12
 voiceLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local voiceLabelParams = voiceLabel.getLayoutParams()
 if voiceLabelParams then
 voiceLabelParams.topMargin = dip2px(10)
 end
 mainLayout.addView(voiceLabel)
 local voiceSpinner = Spinner(activity)
 voiceSpinner.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(voiceSpinner)
 local emotionLabel = TextView(activity)
 emotionLabel.text = "3. Default Emotion:"
 emotionLabel.textSize = 12
 emotionLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local emotionLabelParams = emotionLabel.getLayoutParams()
 if emotionLabelParams then
 emotionLabelParams.topMargin = dip2px(10)
 end
 mainLayout.addView(emotionLabel)
 local emotionSpinner = Spinner(activity)
 emotionSpinner.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(emotionSpinner)
 local speedLabel = TextView(activity)
 speedLabel.text = "4. Voice Speed:"
 speedLabel.textSize = 12
 speedLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local speedLabelParams = speedLabel.getLayoutParams()
 if speedLabelParams then
 speedLabelParams.topMargin = dip2px(10)
 end
 mainLayout.addView(speedLabel)
 local speedText = TextView(activity)
 speedText.text = string.format("Speed: %.1fx", currentSpeed)
 speedText.textSize = 10
 mainLayout.addView(speedText)
 local speedSeekBar = SeekBar(activity)
 speedSeekBar.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(speedSeekBar)
 local pitchLabel = TextView(activity)
 pitchLabel.text = "5. Voice Pitch (Tone):"
 pitchLabel.textSize = 12
 pitchLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local pitchLabelParams = pitchLabel.getLayoutParams()
 if pitchLabelParams then
 pitchLabelParams.topMargin = dip2px(10)
 end
 mainLayout.addView(pitchLabel)
 local pitchText = TextView(activity)
 pitchText.text = string.format("Pitch: %.1f", currentPitch)
 pitchText.textSize = 10
 mainLayout.addView(pitchText)
 local pitchSeekBar = SeekBar(activity)
 pitchSeekBar.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(pitchSeekBar)
 local divider = View(activity)
 divider.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(1)))
 divider.setBackgroundColor(0xFF888888)
 local dividerParams = divider.getLayoutParams()
 if dividerParams then
 dividerParams.topMargin = dip2px(15)
 dividerParams.bottomMargin = dip2px(10)
 end
 mainLayout.addView(divider)
 local testLabel = TextView(activity)
 testLabel.text = "Test Text:"
 testLabel.textSize = 12
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
 container.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 for i = 1, voiceLimit do
 local voiceRow = LinearLayout(activity)
 voiceRow.setOrientation(LinearLayout.HORIZONTAL)
 voiceRow.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 voiceRow.setPadding(dip2px(8), dip2px(8), dip2px(8), dip2px(8))
 voiceRow.setFocusable(true)
 local nameText = TextView(activity)
 local displayName = configNames[i] or ("Voice " .. i)
 local displayID = configVoices[i] or "None"
 nameText.text = i .. ". " .. displayName .. " (" .. displayID .. ")"
 nameText.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 nameText.gravity = Gravity.CENTER_VERTICAL
 nameText.textSize = 12
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
 podcastProgressBar.setProgress(0)
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
 local responseTex