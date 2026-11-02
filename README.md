# Piper cues for REAPER

Offline text-to-speech cues in REAPER. Place the edit cursor, run the action,
type the text: a natural-sounding voice is synthesized locally with
[Piper](https://github.com/OHF-Voice/piper1-gpl) and placed as an item at the
cursor on a **Cues** track.

Made for spoken cues sent to performers in live electronics ("Section B, in
four", "Tacet", "Fermata"...), but useful for any voice-over placeholder.

- Free and fully offline: no API key, no account, no internet.
- **Any language Piper has a voice for**, currently 40+ (English, German,
  French, Spanish, Italian, Dutch, Polish, Russian, Chinese, Arabic…, see the
  [voice list](https://huggingface.co/rhasspy/piper-voices)). The language
  comes with the voice: choose a German voice and type German text, and the
  cue is spoken in German. Mix languages in the same project just by switching
  voice.
- No REAPER extensions needed (no SWS, no ReaImGui).
- One undo step per cue; voice and speed are remembered.

## Install

1. **Piper** (Python 3.9+):

   ```bash
   python3 -m venv ~/piper && ~/piper/bin/pip install piper-tts
   ```

   The executable is then `~/piper/bin/piper` (Windows:
   `%USERPROFILE%\piper\Scripts\piper.exe`).

2. **Voices**: from [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices)
   download both the `.onnx` and the `.onnx.json` of each voice you want into
   one folder, e.g. `<REAPER resource path>/piper_voices` (the default).
   Listen to samples [here](https://rhasspy.github.io/piper-samples/).

3. **Scripts**: via ReaPack, *Extensions → ReaPack → Import repositories…*,
   paste

   ```
   https://github.com/vanderaalle/reaper-piper-cues/raw/main/index.xml
   ```

   then install *Piper cue at edit cursor*. Or copy the two `.lua` files from
   `Various/` into REAPER's `Scripts` folder and load them via
   *Actions → New action → Load ReaScript…*.

4. Run **Piper cue settings** once: set the full path of the Piper executable,
   the voices folder and (optionally) the cue track name.

## Use

Run **Piper cue at edit cursor** (assign it a shortcut). The dialog asks:

- **Cue text**
- **Voice**: the voice file name or any unique part of it (`amy`,
  `thorsten`, `paola`); empty = first voice in the folder. The voice sets
  the language, so write the text in that language (the script does not
  translate).
- **Speed**: 1.0 = normal, 1.2 = faster, 0.8 = slower

WAVs are saved in the project media folder under `cues/`. The item is named
after the text, so cues are readable in the arrange view.

## Notes

Tested on Linux (REAPER 7, piper-tts 1.8). Windows and macOS should work
(the script only calls the Piper executable) but are untested; reports welcome.

## License

MIT — see [LICENSE](LICENSE). Piper and its voices have their own licenses;
check each voice's model card.
