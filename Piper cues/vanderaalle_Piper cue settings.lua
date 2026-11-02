-- @noindex
-- Settings for "Piper cue at edit cursor": Piper executable and voices
-- folder.

local EXT = "vanderaalle_piper_cue"
local SEP = package.config:sub(1, 1)

local keys = { "piper", "voices_dir" }
local defaults = {
  piper = "piper",
  voices_dir = reaper.GetResourcePath() .. SEP .. "piper_voices",
}

local current = {}
for i, k in ipairs(keys) do
  local v = reaper.GetExtState(EXT, k)
  current[i] = v ~= "" and v or defaults[k]
end

local ok, input = reaper.GetUserInputs("Piper cue settings", 2,
  "Piper executable (full path):,Voices folder (.onnx files):,separator=\n,extrawidth=350",
  table.concat(current, "\n"))
if not ok then return end

local i = 0
for v in (input .. "\n"):gmatch("(.-)\n") do
  i = i + 1
  if keys[i] then
    v = v:match("^%s*(.-)%s*$")
    reaper.SetExtState(EXT, keys[i], v ~= "" and v or defaults[keys[i]], true)
  end
end
