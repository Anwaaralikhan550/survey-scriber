# Phrase Bank Editor — web portal

A small, zero-dependency web tool for searching and safely editing the RICS L2
phrase bank (the sentence templates the report is built from) on a proper
screen instead of the phone.

Edits the real asset files in place:
- `assets/property_inspection/phrase_texts.json`
- `assets/property_valuation/phrase_texts.json`

## Run

```bash
node tool/phrase_portal/server.js
# then open http://localhost:4599   (set PORT=xxxx to change)
```

No `npm install` — it uses Node built-ins only (Node 18+).

## What it does

- **Search** across all ~888 phrase keys and their sentence text.
- **Edit** any sentence in a large editor.
- **Token lock** — every `{TOKEN}` in a sentence is a parameter the report
  fills in. Removing or renaming one breaks the report, so the tool blocks a
  save that changes the set of tokens. Tick **Override token lock** to save a
  deliberate structural change (e.g. a genuinely new parameter the engine
  already substitutes).
- **Saves in the repo's exact JSON format** (`indent=2`, non-ASCII escaped),
  so edits produce clean, minimal diffs.

## Workflow

1. Run the server, edit phrases, save.
2. The asset file is updated on disk.
3. Commit the file and rebuild the app — the new wording ships with the next
   build. (Live over-the-air sync to installed apps is a separate, larger
   piece and is not part of this tool.)

## Notes

- Single-admin tool — it reads and writes the file directly, so run one
  instance at a time.
- After editing, run the phrase audit (`flutter test test/phrase_audit`) to
  confirm the bank still produces 0 placeholder-leak / grammar defects.
