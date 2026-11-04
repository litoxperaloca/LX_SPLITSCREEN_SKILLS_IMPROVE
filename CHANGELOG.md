# Changelog

All notable changes to **LX Split-Screen Skills Boost**.

## v2.2.0

Update to an already published mod. Earlier versions are on the Workshop page.

### Changed in this version

- The skill floor no longer waits a fixed 2500 ms after the character is created. It waits for the character to actually be ready, behind a short 400 ms floor, with a 6000 ms ceiling as a backstop.
- That fixed wait was why the skills were always the very last thing to appear on spawn - 2500 ms against the Starter Kit's 2000 - and much worse on a session's first load, where the check could only run once a frame did.
- Nothing else changed: the same floors, the same per-character state, the same options.
- Skill floors are now configurable in Options -> MODS (combat and crafting, 0-10 each).
- All text moved to translation files (EN/ES/RU).
- The applied floor is stored per character, so raising it later tops up existing characters.
- Characters from v2.0.0 are recognised and not re-processed.

### Included

- A floor, not a handout
- Two groups, both adjustable
- Every local character
- Recipes come with the levels
- Top up later
