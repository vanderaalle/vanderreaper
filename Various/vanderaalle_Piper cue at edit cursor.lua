-- @description Piper cue at edit cursor (offline text-to-speech)
-- @author Andrea Valle (vanderaalle)
-- @version 1.0.0
-- @license MIT
-- @provides [main] vanderaalle_Piper cue settings.lua
-- @link https://github.com/vanderaalle/reaper-piper-cues
-- @about
--   # Piper cue at edit cursor
--
--   Type a text, get it spoken by a local Piper neural voice and placed as an
--   item at the edit cursor on a "Cues" track (created if missing). Meant for
--   spoken cues sent to performers live ("Section B, in four", "Tacet"...),
--   but works for any voice-over placeholder.
--
--   Fully offline and free: no API key, no internet. Works in any language
--   Piper has a voice for (40+): the voice sets the language, so pick e.g. a
--   German voice and type German text. Voice and speed are remembered
--   between runs.
--
--   Requires Piper (`pip install piper-tts`) and at least one voice
--   (.onnx + .onnx.json) from https://huggingface.co/rhasspy/piper-voices.
--   Run "Piper cue settings" once to point the script to Piper and the
--   voices folder.

local EXT = "vanderaalle_piper_cue"
local SEP = package.config:sub(1, 1)

local function setting(key, default)
  local v = reaper.GetExtState(EXT, key)
  return v ~= "" and v or default
end

local function voices_in(dir)
  local list, i = {}, 0
  while true do
    local f = reaper.EnumerateFiles(dir, i)
    if not f then break end
    if f:match("%.onnx$") then list[#list + 1] = f:gsub("%.onnx$", "") end
    i = i + 1
  end
  table.sort(list)
  return list
end

-- Empty = first voice; else exact name, then a unique case-insensitive
-- substring ("paola").
local function find_voice(voices, want)
  if want == "" then return voices[1] end
  local hits = {}
  for _, v in ipairs(voices) do
    if v:lower() == want:lower() then return v end
    if v:lower():find(want:lower(), 1, true) then hits[#hits + 1] = v end
  end
  if #hits == 1 then return hits[1] end
end

local function slug(s)
  local t = s:lower():gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
  return t:sub(1, 30) ~= "" and t:sub(1, 30) or "cue"
end

local function cue_track(name)
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, n = reaper.GetTrackName(tr)
    if n == name then return tr end
  end
  local n = reaper.CountTracks(0)
  reaper.InsertTrackAtIndex(n, true)
  local tr = reaper.GetTrack(0, n)
  reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

-- Returns an error message, or nil on success.
function place_cue(text, voice, speed)
  local piper = setting("piper", "piper")
  local dir = setting("voices_dir", reaper.GetResourcePath() .. SEP .. "piper_voices")
  local voices = voices_in(dir)
  if #voices == 0 then
    return "No Piper voices (.onnx) found in\n" .. dir .. "\n\nRun 'Piper cue settings' to set the folder."
  end
  local model = find_voice(voices, voice)
  if not model then
    return "Voice '" .. voice .. "' not found or ambiguous. Available:\n\n" .. table.concat(voices, "\n")
  end
  speed = tonumber(speed)
  if not speed or speed <= 0 then return "Speed must be a positive number, e.g. 1.0" end

  local out_dir = reaper.GetProjectPath() .. SEP .. "cues"
  reaper.RecursiveCreateDirectory(out_dir, 0)
  local stem = string.format("%s%s%s_%s_x%.2f_%d", out_dir, SEP, slug(text), model, speed, os.time())
  local wav, n = stem .. ".wav", 1
  while reaper.file_exists(wav) do
    n = n + 1
    wav = stem .. "_" .. n .. ".wav"
  end

  -- Text goes through a UTF-8 file: no shell quoting of the cue text.
  local txt = wav:gsub("%.wav$", ".txt")
  local f = io.open(txt, "w")
  f:write(text)
  f:close()
  local cmd = string.format('"%s" -m "%s" --length-scale %.4f -i "%s" -f "%s"',
    piper, dir .. SEP .. model .. ".onnx", 1 / speed, txt, wav)
  local result = reaper.ExecProcess(cmd, 60000) or "failed to start"
  os.remove(txt)

  local src = reaper.file_exists(wav) and reaper.PCM_Source_CreateFromFile(wav)
  if not src or reaper.GetMediaSourceLength(src) == 0 then
    return "Piper produced no audio.\n\n" .. cmd .. "\n\n" .. result ..
      "\n\nIs Piper installed? Run 'Piper cue settings' to set its path."
  end

  local pos = reaper.GetCursorPosition()
  reaper.Undo_BeginBlock()
  local item = reaper.AddMediaItemToTrack(cue_track(setting("track", "Cues")))
  local take = reaper.AddTakeToMediaItem(item)
  reaper.SetMediaItemTake_Source(take, src)
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", text, true)
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", (reaper.GetMediaSourceLength(src)))
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Piper cue: " .. text, -1)
end

-- Test hook: a caller can set PIPER_CUE_NO_UI and call place_cue() itself.
if PIPER_CUE_NO_UI then return end

local ok, input = reaper.GetUserInputs("Piper cue at edit cursor", 3,
  "Cue text:,Voice (name or part of it):,Speed (1.0 = normal):,separator=\n,extrawidth=250",
  "\n" .. setting("voice", "") .. "\n" .. setting("speed", "1.0"))
if not ok then return end
local text, voice, speed = input:match("^(.-)\n(.-)\n(.*)$")
local function trim(s) return s:match("^%s*(.-)%s*$") end
text, voice, speed = trim(text):gsub("%s+", " "), trim(voice), trim(speed):gsub(",", ".")
if text == "" then return end

local err = place_cue(text, voice, speed)
if err then
  reaper.ShowMessageBox(err, "Piper cue", 0)
else
  reaper.SetExtState(EXT, "voice", voice, true)
  reaper.SetExtState(EXT, "speed", speed, true)
end
