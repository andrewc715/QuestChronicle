# Quest Chronicle v1.0.6 Wardrobe Refresh Policy Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.0.6.
3. Log into the character and leave Blizzard's Wardrobe/Transmogrify windows closed.

## One login refresh

1. After login, wait for the wardrobe scan to begin and finish once.
2. Confirm the chat notice says the wardrobe was refreshed **for this login** when wardrobe announcements are enabled.
3. Travel through a loading screen or enter another zone/instance.
4. Confirm no second automatic wardrobe scan begins.

## Stale collection behavior

1. After the login scan finishes, learn a new transmog appearance or trigger a genuine collection change.
2. Open Quest Chronicle → Outfits.
3. Confirm **Collection may be stale** appears immediately to the left of **Scan Collection**.
4. Wait at least one minute and continue playing.
5. Confirm no automatic wardrobe scan begins.
6. Hover the stale notice and confirm its tooltip explains the manual-refresh policy.

## Manual refresh

1. Click **Scan Collection**.
2. Confirm one scan runs and the stale notice disappears after success.
3. Trigger another collection change.
4. Confirm the stale notice returns without starting another scan.

## Reload behavior

1. With the stale notice visible, run `/reload`.
2. Confirm exactly one new login wardrobe scan runs after the UI reload.
3. Confirm the stale notice clears after that scan.
4. Trigger a loading screen afterward and confirm no further automatic scan occurs.

## Settings and Status

1. Open Options → AddOns → Quest Chronicle.
2. Confirm the obsolete **Refresh the wardrobe after collection changes** option is gone.
3. Open Status & Maintenance after a collection change.
4. Confirm Wardrobe reports **Collection may be stale**, not Refresh queued.

## Regression

- Manual outfit generation and rerolls still work.
- Saved concepts and linked Custom Sets remain intact.
- Save/Update, Update Custom Set, Save as New, and Replace Existing still work.
- Minimap and AddOn Compartment launchers still work.
- `/qc export` followed by `/reload` still writes Courier SavedVariables and performs one login wardrobe scan.
