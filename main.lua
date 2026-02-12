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
local CURRENT_VERSION = "0.2"
local mainHandler = Handler(Looper.getMainLooper())
local GEMINI_PREFS = "GEMINI_CONFIG"
local PREFS_NAME = "VOICE_CONFIG"
local GENERATION_STATE_PREFS = "GENERATION_STATE"
local API_PROVIDERS = {
 "Google Generative Language (Gemini)"
}
local API_ENDPOINTS = {
 ["Google Generative Language (Gemini)"] = function(apiKey)
 return string.format(
 "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=%s",
 apiKey)
 end
}
local DEFAULT_API_KEY = ""
local SELECTED_API_PROVIDER = "Google Generative Language (Gemini)"
local API_KEY = DEFAULT_API_KEY
local configNames = {"Host", "Guest 1", "Guest 2", "Guest 3", "Guest 4", "Guest 5"}
local configVoices = {"Puck", "Kore", "Charon", "Zephyr", "Fenrir", "Leda"}
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
local isAudioAutoPlayEnabled = false
local textEmotionModes = {
 "Default (Keep as is)",
 "Default Voice Emotion"
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
local lastGeneratedAudioPath = nil
local lastGeneratedAudioType = nil
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
 SELECTED_API_PROVIDER = prefs.getString("API_PROVIDER", "Google Generative Language (Gemini)")
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
 0x52, 0x49, 0x46, 0x46,
 totalSizeB[1], totalSizeB[2], totalSizeB[3], totalSizeB[4],
 0x57, 0x41, 0x56, 0x45,
 0x66, 0x6d, 0x74, 0x20,
 0x10, 0x00, 0x00, 0x00,
 0x01, 0x00,
 channels & 0xff, (channels >> 8) & 0xff,
 sampleRateB[1], sampleRateB[2], sampleRateB[3], sampleRateB[4],
 byteRateB[1], byteRateB[2], byteRateB[3], byteRateB[4],
 blockAlign & 0xff, (blockAlign >> 8) & 0xff,
 bitsPerSample & 0xff, (bitsPerSample >> 8) & 0xff,
 0x64, 0x61, 0x74, 0x61,
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
 Thread.sleep(100)
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
 collectgarbage("collect")
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
 processNextChunk(chunks, voiceName, emotion, speed, pitch, isSaving, 1, #chunks)
end

function processNextChunk(chunks, voiceName, emotion, speed, pitch, isSaving, index, totalChunks)
 if index > totalChunks then
 mergeAndSavePodcast()
 return
 end
 currentGenerationChunkIndex = index
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
 local systemPrompt = getSystemPrompt(emotion, nil, speed, pitch)
 local inputText = currentChunk
 local speechConfig = {
 voiceConfig = { prebuiltVoiceConfig = { voiceName = voiceName } }
 }
 local requestBody
 local apiUrl = string.format(
 "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=%s",
 API_KEY)
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
 local systemPrompt = getSystemPrompt(currentEmotion, nil, currentSpeed, currentPitch)
 local inputText = cleanedText
 local voiceToUse = voiceName
 local isValidVoice = false
 for _, v in pairs(voiceMapGemini) do
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
 temperature = 0.1,
 maxOutputTokens = 8000
 },
 safetySettings = {
 { category = "HARM_CATEGORY_HARASSMENT", threshold = "BLOCK_ONLY_HIGH" },
 { category = "HARM_CATEGORY_HATE_SPEECH", threshold = "BLOCK_ONLY_HIGH" },
 { category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = "BLOCK_ONLY_HIGH" },
 { category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = "BLOCK_ONLY_HIGH" }
 }
 }
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 headers.put("x-goog-api-client", "gl-kotlin/2.1.0-ai fire/16.5.0")
 local apiUrl = string.format(
 "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=%s",
 API_KEY)
 Http.post(apiUrl, cjson.encode(requestBody), headers, function(code, content)
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

function processMultiVoicePodcast()
 local rawText = scriptInput.text
 if #rawText == 0 then
 showErrorDialog("Empty script.")
 return
 end
 local processedText = rawText
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
 audioParts = {}
 finalPodcastPath = nil
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
 processMultiVoiceLine(lines, 1, #lines)
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
 return
 end
 currentGenerationProgress = index - 1
 local currentLine = dialogueList[index]
 local speakerName = currentLine.speaker
 local rawText = currentLine.text
 local selectedVoice = "Puck"
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
 local isValidVoice = false
 for _, v in pairs(voiceMapGemini) do
 if v == selectedVoice then
 isValidVoice = true
 break
 end
 end
 if not isValidVoice then selectedVoice = "Puck" end
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
 local speechConfig = { voiceConfig = { prebuiltVoiceConfig = { voiceName = selectedVoice } } }
 local requestBody = {
 contents = { { parts = { { text = textToSpeak } } } },
 generationConfig = {
 responseModalities = {"AUDIO"},
 speechConfig = speechConfig,
 temperature = 0.1,
 maxOutputTokens = 5000
 },
 safetySettings = {
 { category = "HARM_CATEGORY_HARASSMENT", threshold = "BLOCK_ONLY_HIGH" },
 { category = "HARM_CATEGORY_HATE_SPEECH", threshold = "BLOCK_ONLY_HIGH" },
 { category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = "BLOCK_ONLY_HIGH" },
 { category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = "BLOCK_ONLY_HIGH" }
 }
 }
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 local powerManager = activity.getSystemService(Context.POWER_SERVICE)
 local wakeLockHttp = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "PodcastGen:HTTPLock")
 wakeLockHttp.acquire(2*60*1000)
 local apiUrl = string.format(
 "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=%s",
 API_KEY)
 Http.post(apiUrl, cjson.encode(requestBody), headers, function(code, content)
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
 for k, v in pairs(voiceMapGemini) do
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
 for k, _ in pairs(voiceMapGemini) do
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
 tempVoiceID = voiceMapGemini[tempVoiceDisplay]
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

function showGeminiConfigDialog()
 local tempApiKey = API_KEY
 local tempApiProvider = SELECTED_API_PROVIDER
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 local titleLabel = TextView(activity)
 titleLabel.text = "API Configuration"
 titleLabel.textSize = 14
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
 providerLabel.textSize = 12
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
keyLabel.textSize = 12
keyLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
local keyLabelParams = keyLabel.getLayoutParams()
if keyLabelParams then
 keyLabelParams.topMargin = dip2px(10)
end
mainLayout.addView(keyLabel)
local keyInput = EditText(activity)
keyInput.text = tempApiKey
keyInput.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
keyInput.hint = "Enter API Key..."
mainLayout.addView(keyInput)
local noteLabel = TextView(activity)
noteLabel.text = "Note: Gemini is recommended for better performance."
noteLabel.textSize = 10
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
 testButtonParams.topMargin = dip2px(10)
end
mainLayout.addView(testButton)
local resultText = TextView(activity)
resultText.text = "Test status: Not tested"
resultText.textSize = 10
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
 saveGeminiConfig()
 runOnUi(function()
 showInfoDialog("Success", "Configuration saved!")
 end)
 dlg.show()
end)
d.setNegativeButton("Cancel", function()
 if API_KEY == "" or API_KEY == DEFAULT_API_KEY then
 activity.finish()
 else
 dlg.show()
 end
end)
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
 if #key == 0 then
 resultText.text = "Error: Please enter API key"
 return
 end
 testButton.text = "Testing..."
 testButton.setEnabled(false)
 resultText.text = "Test status: Connecting..."
 local testModel = "gemini-2.5-flash"
 local apiUrl = string.format(
 "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
 testModel, key
 )
 local requestBody = {
 contents = {{ role = "user", parts = {{ text = "Hello, reply with one word Success." }}}},
 generationConfig = { temperature = 0.5, maxOutputTokens = 10 }
 }
 local headers = HashMap()
 headers.put("Content-Type", "application/json")
 Http.post(apiUrl, cjson.encode(requestBody), headers, function(code, content)
 runOnUi(function()
 testButton.text = "Test API Connection"
 testButton.setEnabled(true)
 if code == 200 then
 local status, data = pcall(cjson.decode, content)
 if status and data and data.candidates and #data.candidates > 0 then
 local candidate = data.candidates[1]
 if candidate.content and candidate.content.parts and #candidate.content.parts > 0 then
 local responseText = candidate.content.parts[1].text
 resultText.text = "Google API working! Response: " .. tostring(responseText)
 else
 resultText.text = "API Error: Response blocked or empty."
 end
 else
 resultText.text = "JSON parsing error"
 end
 elseif code == 400 then
 resultText.text = "Error 400: Invalid API Key"
 elseif code == 403 then
 resultText.text = "Error 403: Permission denied"
 elseif code == 429 then
 resultText.text = "Error 429: Rate limit exceeded"
 else
 resultText.text = "HTTP Error: " .. code
 end
 end)
 end)
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
 mainLayout.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 local titleLabel = TextView(activity)
 titleLabel.text = file.name
 titleLabel.textSize = 16
 titleLabel.gravity = Gravity.CENTER
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setTextColor(0xFF333333)
 local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 titleParams.bottomMargin = dip2px(8)
 titleLabel.setLayoutParams(titleParams)
 mainLayout.addView(titleLabel)
 local fileInfoText = TextView(activity)
 fileInfoText.text = string.format("Track %d of %d", currentFileIndex, #audioFiles)
 fileInfoText.textSize = 10
 fileInfoText.gravity = Gravity.CENTER
 fileInfoText.setTextColor(0xFF666666)
 local fileInfoParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 fileInfoParams.bottomMargin = dip2px(10)
 fileInfoText.setLayoutParams(fileInfoParams)
 mainLayout.addView(fileInfoText)
 local seekBar = SeekBar(activity)
 local seekParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 seekParams.bottomMargin = dip2px(8)
 seekBar.setLayoutParams(seekParams)
 mainLayout.addView(seekBar)
 local timeLayout = LinearLayout(activity)
 timeLayout.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 timeLayout.setPadding(0, 0, 0, dip2px(10))
 
 local currentTime = TextView(activity)
 currentTime.text = "00:00"
 currentTime.textSize = 10
 currentTime.setTextColor(0xFF2196F3)
 currentTime.setTypeface(Typeface.DEFAULT_BOLD)
 currentTime.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 timeLayout.addView(currentTime)
 local totalTime = TextView(activity)
 totalTime.text = "00:00"
 totalTime.textSize = 10
 totalTime.setTextColor(0xFF666666)
 totalTime.gravity = Gravity.RIGHT
 totalTime.setLayoutParams(LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
 timeLayout.addView(totalTime)
 mainLayout.addView(timeLayout)
 local speedLabel = TextView(activity)
 speedLabel.text = "Playback Speed"
 speedLabel.textSize = 12
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
 speedValueText.textSize = 10
 speedValueText.gravity = Gravity.CENTER
 speedValueText.setTextColor(0xFF666666)
 local speedValueParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
 speedValueParams.topMargin = dip2px(5)
 speedValueParams.bottomMargin = dip2px(20)
 speedValueText.setLayoutParams(speedValueParams)
 mainLayout.addView(speedValueText)
 local controlSpacer = View(activity)
 controlSpacer.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1))
 mainLayout.addView(controlSpacer)
 local controlRow1 = LinearLayout(activity)
 controlRow1.setOrientation(LinearLayout.HORIZONTAL)
 controlRow1.gravity = Gravity.CENTER
 controlRow1.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 controlRow1.setPadding(0, 0, 0, dip2px(10))
 local prevTrackButton = Button(activity)
 prevTrackButton.text = "PREV"
 prevTrackButton.setTextSize(14)
 prevTrackButton.setBackgroundResource(android.R.drawable.btn_default)
 local prevTrackParams = LinearLayout.LayoutParams(dip2px(60), dip2px(45))
 prevTrackParams.rightMargin = dip2px(5)
 prevTrackButton.setLayoutParams(prevTrackParams)
 if currentFileIndex == 1 then
 prevTrackButton.setEnabled(false)
 prevTrackButton.setTextColor(0xFFAAAAAA)
 end
 controlRow1.addView(prevTrackButton)
 local rewindButton = Button(activity)
 rewindButton.text = "REW-5s"
 rewindButton.setTextSize(12)
 rewindButton.setBackgroundResource(android.R.drawable.btn_default)
 local rewindParams = LinearLayout.LayoutParams(dip2px(70), dip2px(45))
 rewindParams.rightMargin = dip2px(5)
 rewindButton.setLayoutParams(rewindParams)
 controlRow1.addView(rewindButton)
 local playPauseButton = Button(activity)
 playPauseButton.text = "PLAY"
 playPauseButton.setTextSize(14)
 playPauseButton.setTypeface(Typeface.DEFAULT_BOLD)
 playPauseButton.setBackgroundResource(android.R.drawable.btn_default)
 local playPauseParams = LinearLayout.LayoutParams(dip2px(80), dip2px(55))
 playPauseButton.setLayoutParams(playPauseParams)
 controlRow1.addView(playPauseButton)
 local forwardButton = Button(activity)
 forwardButton.text = "FWD-5s"
 forwardButton.setTextSize(12)
 forwardButton.setBackgroundResource(android.R.drawable.btn_default)
 local forwardParams = LinearLayout.LayoutParams(dip2px(70), dip2px(45))
 forwardParams.leftMargin = dip2px(5)
 forwardButton.setLayoutParams(forwardParams)
 controlRow1.addView(forwardButton)
 local nextTrackButton = Button(activity)
 nextTrackButton.text = "NEXT"
 nextTrackButton.setTextSize(14)
 nextTrackButton.setBackgroundResource(android.R.drawable.btn_default)
 local nextTrackParams = LinearLayout.LayoutParams(dip2px(60), dip2px(45))
 nextTrackParams.leftMargin = dip2px(5)
 nextTrackButton.setLayoutParams(nextTrackParams)
 if currentFileIndex == #audioFiles then
 nextTrackButton.setEnabled(false)
 nextTrackButton.setTextColor(0xFFAAAAAA)
 end
 controlRow1.addView(nextTrackButton)
 mainLayout.addView(controlRow1)
 local bottomSpacer = View(activity)
 bottomSpacer.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(20), 0))
 mainLayout.addView(bottomSpacer)
 local closeButton = Button(activity)
 closeButton.text = "CLOSE PLAYER"
 closeButton.setTextSize(12)
 closeButton.setTypeface(Typeface.DEFAULT_BOLD)
 closeButton.setTextColor(0xFFFFFFFF)
 closeButton.setBackgroundColor(0xFFF44336)
 local closeParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(45))
 closeButton.setLayoutParams(closeParams)
 mainLayout.addView(closeButton)
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
 if player.isPlaying() then
 player.stop()
 end
 player.release()
 player = nil
 end
 end)
 end

 local function updatePlayerState()
 if playerState == "playing" then
 playPauseButton.text = "PAUSE"
 elseif playerState == "paused" then
 playPauseButton.text = "PLAY"
 else
 playPauseButton.text = "PLAY"
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
 onStopTrackingTouch = function(seekBar)
 pcall(function()
 if player then
 player.seekTo(seekBar.getProgress())
 end
 end)
 end
 })

 local function update()
 if playerState == "playing" and player then
 local success, playing = pcall(function() return player.isPlaying() end)
 if success and playing then
 local currentPos = player.getCurrentPosition()
 seekBar.setProgress(currentPos)
 currentTime.text = string.format("%02d:%02d", math.floor(currentPos/60000), math.floor((currentPos/1000)%60))
 updateTask = task(1000, update)
 end
 end
 end
 playPauseButton.onClick = function()
 vibrate()
 pcall(function()
 if playerState == "playing" then
 player.pause()
 playerState = "paused"
 else
 player.start()
 playerState = "playing"
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
 if newPos > duration then newPos = duration end
 player.seekTo(newPos)
 seekBar.setProgress(newPos)
 end
 end)
 end
 rewindButton.onClick = function()
 vibrate()
 pcall(function()
 if player then
 local newPos = player.getCurrentPosition() - 5000
 if newPos < 0 then newPos = 0 end
 player.seekTo(newPos)
 seekBar.setProgress(newPos)
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
 mainLayout.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 local titleLabel = TextView(activity)
 titleLabel.text = "Audio Files Manager"
 titleLabel.textSize = 16
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.gravity = Gravity.CENTER
 titleLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 mainLayout.addView(titleLabel)
 local countLabel = TextView(activity)
 countLabel.text = "Total Files: " .. #audioFiles
 countLabel.textSize = 10
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
 emptyText.setPadding(dip2px(20), dip2px(20), dip2px(20), dip2px(20))
 fileContainer.addView(emptyText)
 return
 end
 for i, file in ipairs(audioFiles) do
 local fileItem = LinearLayout(activity)
 fileItem.setOrientation(LinearLayout.VERTICAL)
 fileItem.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 fileItem.setPadding(dip2px(10), dip2px(10), dip2px(10), dip2px(10))
 fileItem.setBackgroundColor(0xFFF5F5F5)
 local nameText = TextView(activity)
 nameText.text = file.name
 nameText.textSize = 12
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
 sizeText.textSize = 8
 sizeText.setTextColor(0xFF666666)
 sizeText.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 infoLayout.addView(sizeText)
 local spacer = View(activity)
 spacer.setLayoutParams(LinearLayout.LayoutParams(dip2px(10), dip2px(1)))
 infoLayout.addView(spacer)
 local dateText = TextView(activity)
 dateText.text = os.date("%Y-%m-%d %H:%M", math.floor(file.lastModified/1000))
 dateText.textSize = 8
 dateText.setTextColor(0xFF666666)
 dateText.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 infoLayout.addView(dateText)
 fileItem.addView(infoLayout)
 fileContainer.addView(fileItem)
 local divider = View(activity)
 divider.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(5)))
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
 local padding = dip2px(10)
 dlgLayout.setPadding(padding, padding, padding, padding)
 local scrollView = ScrollView(activity)
 scrollView.addView(dlgLayout)
 for i, option in ipairs(options) do
 local btn = Button(activity)
 btn.text = option
 btn.setTextSize(14)
 btn.setContentDescription(option)
 local btnParams = LinearLayout.LayoutParams(
 LinearLayout.LayoutParams.MATCH_PARENT,
 dip2px(40)
 )
 if i < #options then
 btnParams.bottomMargin = dip2px(5)
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
 end
 elseif option == "Share" then
 shareAudioFile(file)
 elseif option == "Rename" then
 showRenameDialog(file, parentDialog)
 elseif option == "Delete" then
 local confirmDlg = LuaDialog(activity)
 confirmDlg.setTitle("Delete File")
 confirmDlg.setMessage("Are you sure you want to delete this file: " .. file.name .. "?")
 confirmDlg.setPositiveButton("Delete", function()
 local filePath = file.absolutePath or ("/storage/emulated/0/Audio/Podcast Generator/" .. file.name)
 local targetFile = File(filePath)
 if targetFile.exists() and targetFile.delete() then
 showInfoDialog("Success", "File deleted successfully!")
 audioFiles = getAudioFilesList()
 if countLabel then countLabel.text = "Total Files: " .. #audioFiles end
 displayFiles()
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
 cancelBtn.setTextSize(14)
 cancelBtn.setTextColor(0xFFF44336)
 local cancelParams = LinearLayout.LayoutParams(
 LinearLayout.LayoutParams.MATCH_PARENT,
 dip2px(40)
 )
 cancelParams.topMargin = dip2px(10)
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
 showErrorDialog("File not found: " .. file.name)
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
 shareIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 local chooser = Intent.createChooser(shareIntent, "Share Audio: " .. file.name)
 chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
 activity.startActivity(chooser)
 vibrate()
 end)
 if not status then
 pcall(function()
 local tempDir = activity.getExternalCacheDir()
 if tempDir then
 local tempFile = FileClass(tempDir, "share_" .. file.name)
 local input = FileInputStream(audioFile)
 local output = FileOutputStream(tempFile)
 local buffer = byte[4096]
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
 container.setPadding(dip2px(20), dip2px(10), dip2px(20), dip2px(10))
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

function showAboutDialog()
 local scrollView = ScrollView(activity)
 local mainLayout = LinearLayout(activity)
 mainLayout.setOrientation(LinearLayout.VERTICAL)
 mainLayout.setPadding(dip2px(8), dip2px(8), dip2px(8), dip2px(8))
 local titleLabel = TextView(activity)
 titleLabel.text = "Podcast Voice Generator"
 titleLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 titleLabel.textSize = 14
 titleLabel.setTypeface(Typeface.DEFAULT_BOLD)
 titleLabel.setGravity(Gravity.CENTER)
 mainLayout.addView(titleLabel)
 local providerLabel = TextView(activity)
 providerLabel.text = "Using " .. tostring(SELECTED_API_PROVIDER)
 providerLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 providerLabel.setGravity(Gravity.CENTER)
 providerLabel.textSize = 10
 mainLayout.addView(providerLabel)
 local versionLabel = TextView(activity)
 versionLabel.text = "Version " .. CURRENT_VERSION
 versionLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 versionLabel.setGravity(Gravity.CENTER)
 versionLabel.textSize = 10
 mainLayout.addView(versionLabel)
 local divider1 = View(activity)
 divider1.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(1)))
 divider1.setBackgroundColor(0xFFCCCCCC)
 local divider1Params = divider1.getLayoutParams()
 if divider1Params then
 divider1Params.topMargin = dip2px(8)
 divider1Params.bottomMargin = dip2px(8)
 end
 mainLayout.addView(divider1)
 local updateButton = Button(activity)
 updateButton.text = "Check for Updates"
 updateButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local updateButtonParams = updateButton.getLayoutParams()
 if updateButtonParams then
 updateButtonParams.topMargin = dip2px(5)
 end
 mainLayout.addView(updateButton)
 local divider2 = View(activity)
 divider2.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dip2px(1)))
 divider2.setBackgroundColor(0xFFCCCCCC)
 local divider2Params = divider2.getLayoutParams()
 if divider2Params then
 divider2Params.topMargin = dip2px(8)
 divider2Params.bottomMargin = dip2px(8)
 end
 mainLayout.addView(divider2)
 local configLabel = TextView(activity)
 configLabel.text = "Current configuration:"
 configLabel.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 configLabel.textSize = 10
 mainLayout.addView(configLabel)
 local providerInfo = TextView(activity)
 providerInfo.text = "Provider: " .. tostring(SELECTED_API_PROVIDER)
 providerInfo.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 providerInfo.textSize = 10
 mainLayout.addView(providerInfo)
 local voicesInfo = TextView(activity)
 voicesInfo.text = "Available Voices: 31"
 voicesInfo.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 voicesInfo.textSize = 10
 mainLayout.addView(voicesInfo)
 if API_KEY and #API_KEY > 5 then
 local apiInfo = TextView(activity)
 apiInfo.text = "API Key: Configured"
 apiInfo.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 apiInfo.textSize = 10
 mainLayout.addView(apiInfo)
 else
 local apiInfo = TextView(activity)
 apiInfo.text = "API Key: Not configured"
 apiInfo.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 apiInfo.textSize = 10
 apiInfo.setTextColor(0xFFFF0000)
 mainLayout.addView(apiInfo)
 end
 local configButton = Button(activity)
 configButton.text = "Configure API Settings"
 configButton.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
 local configButtonParams = configButton.getLayoutParams()
 if configButtonParams then
 configButtonParams.topMargin = dip2px(8)
 end
 mainLayout.addView(configButton)
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
 updateButton.onClick = function()
 aboutDialog.dismiss()
 vibrate()
 checkForUpdate(true)
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
 padding = "10dp",
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginBottom = "8dp",
 { TextView, text = "Mode:", textSize = "12sp", gravity = "center_vertical", layout_width = "wrap_content", layout_height = "wrap_content", layout_marginRight = "8dp" },
 { Spinner, id = "modeSpinner", layout_width = "fill", layout_weight = 1, layout_height = "wrap_content" }
 },
 { View, layout_height="1dp", backgroundColor=0xFF888888, layout_width="fill", layout_marginTop="5dp", layout_marginBottom="10dp" },
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 { Button, id = "btnConfigVoice1", text = "Configure Voice", layout_width = "0dp", layout_weight = 1, layout_height = "wrap_content", textSize = "10sp", layout_marginRight = "4dp", visibility = View.VISIBLE },
 { Button, id = "btnConfigVoice2", text = "Configure Voice 2", layout_width = "0dp", layout_weight = 1, layout_height = "wrap_content", textSize = "10sp", layout_marginLeft = "4dp", visibility = View.GONE },
 },
 { View, layout_height="1dp", backgroundColor=0xFF888888, layout_width="fill", layout_marginTop="10dp", layout_marginBottom="10dp" },
 { TextView, id = "chatLabel", text = "Enter text:", textSize = "12sp" },
 {
 EditText,
 id = "chatInput",
 hint = "Type text for single voice...",
 layout_width = "fill",
 layout_height = "wrap_content",
 lines = 2,
 },
 { TextView, id = "charCounter", text = "Characters: 0/50000 | Tokens: 0/12500", textSize = "8sp", layout_width = "fill", gravity = "right" },
 {
 LinearLayout,
 id = "voiceSelectorLayout",
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "4dp",
 visibility = View.GONE,
 { TextView, text = "Select Voice:", textSize = "10sp", gravity = "center_vertical", layout_width = "wrap_content", layout_marginRight = "8dp" },
 { Spinner, id = "voiceSelectorSpinner", layout_width = "0dp", layout_weight = 1 },
 { Button, id = "btnAddToScript", text = "Add to Script", layout_width = "wrap_content", layout_marginLeft = "8dp" }
 },
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "4dp",
 { TextView, id = "dialogueEmotionLabel", text = "Apply Default Emotion to input:", textSize = "10sp", gravity = "center_vertical", layout_width = "wrap_content", layout_height = "wrap_content", layout_marginRight = "4dp", visibility = View.GONE },
 { Button, id = "btnDialogueEmotionApply", text = "Apply Tag", layout_width = "wrap_content", layout_height = "wrap_content", textSize = "10sp", layout_marginLeft = "4dp", visibility = View.GONE }
 },
 { TextView, id="podcastEmotionNote", text="*Default intonation will be used if no emotion tag.", textSize="8sp", textColor=0xFF555555, layout_marginTop="4dp", visibility=View.GONE },
 {
 LinearLayout,
 id = "addButtonsLayout",
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "4dp",
 { Button, id = "btnTestSpeak", text = "Test Listen", layout_width = "fill", layout_height = "wrap_content", textSize = "10sp" }
 },
 {
 LinearLayout,
 id = "textEmotionSpinnerLayout",
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "8dp",
 visibility = View.GONE,
 { TextView, text = "Text Emotion:", textSize = "12sp", gravity = "center_vertical", layout_width = "wrap_content", layout_height = "wrap_content", layout_marginRight = "8dp" },
 { Spinner, id = "textEmotionSpinner", layout_width = "fill", layout_weight = 1, layout_height = "wrap_content" }
 },
 { TextView, id = "scriptLabel", text = "Final Script:", textSize = "12sp", layout_marginTop = "8dp", visibility = View.GONE },
 {
 EditText,
 id = "scriptInput",
 hint = "Script will appear here...",
 layout_width = "fill",
 layout_height = "80dp",
 padding = "8dp",
 backgroundColor = 0xFFF0F0F0,
 textColor = 0xFF000000,
 lines = 8,
 inputType = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE,
 gravity = "top",
 layout_marginBottom = "8dp",
 visibility = View.GONE
 },
 {
 Button,
 id = "generateButton",
 text = "Generate Audio",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "4dp"
 },
 {
 ProgressBar,
 id = "podcastProgressBar",
 layout_width = "fill",
 layout_height = "wrap_content",
 style = "?android:attr/progressBarStyleHorizontal",
 layout_marginTop = "4dp",
 visibility = View.GONE,
 max = 100
 },
 {
 TextView,
 id = "resultText",
 text = "Status...",
 layout_width = "fill",
 layout_height = "wrap_content",
 padding = "4dp",
 textIsSelectable = true,
 },
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "4dp",
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
 layout_marginLeft = "4dp",
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
 layout_marginTop = "8dp"
 },
 {
 LinearLayout,
 orientation = "horizontal",
 layout_width = "fill",
 layout_height = "wrap_content",
 layout_marginTop = "8dp",
 {
 Button,
 id = "btnAbout",
 text = "Configuration & About",
 layout_width = "fill",
 layout_height = "wrap_content",
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
if API_KEY == "" or API_KEY == DEFAULT_API_KEY then
 showGeminiConfigDialog()
else
 dlg.show()
end
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