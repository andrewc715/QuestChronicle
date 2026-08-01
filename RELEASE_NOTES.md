# Quest Chronicle v0.5.2: Wardrobe Scanner Recovery

Version 0.5.2 fixes the live-client regression where v0.5.1 reported zero collected and zero compatible appearances in every equipment category.

## What happened

The v0.5.1 scanner changed several pieces at once:

- it established a temporary collected-only filter context;
- it cleared the Wardrobe search;
- it changed the current class filter;
- it immediately queried every category;
- it supplied only one representation of the slot's transmog location.

Retail's transmog search database and filter rebuild can be asynchronous. During that short rebuilding period, filtered counts and category queries can legitimately return empty results. The generated API documentation also describes `GetCategoryAppearances` and `GetAppearanceSources` as accepting a `TransmogLocationMixin`, while Blizzard's current Wardrobe implementation passes the object's `GetData()` representation in one of those paths.

The result was an exquisitely organized wardrobe containing absolutely nothing.

## Fixes

- Waits until `IsSearchDBLoading()` and `IsSearchInProgress()` both report ready.
- Uses `GetCategoryCollectedCount()` as the diagnostic baseline instead of the transient filtered count.
- Requests a broad collection view and filters collected appearances locally.
- Queries category appearances with:
  1. the documented `TransmogLocationMixin`;
  2. Blizzard's `transmogLocation:GetData()` representation;
  3. a category-only fallback.
- Keeps whichever valid query returns the richest collected result.
- Resolves appearance sources using both transmog-location forms.
- Removes `SetSearchAndFilterCategory()` from the tight scan loop.
- Retries a slot twice when WoW reports collected appearances but briefly returns no rows.
- Builds the new collection in a staging cache.
- Refuses to replace an existing healthy cache with an impossible all-zero result.
- Adds explicit Preparing and Failed scanner states with clearer status text.
- Advances the wardrobe cache format to version 3, forcing a clean rescan.

## Preserved

- Quest Chronicle SavedVariables schema 2.
- Courier export format 1.
- All Chronicle events, quest snapshots, RP notes, drafts, and settings.
- Manual preview-only behavior.
- No transmog is applied and no Blizzard outfit slot is modified.

## Installation

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with the folder from this archive.
3. Log in and allow the character and collection data to settle for a few seconds.
4. Close Blizzard's Transmogrify and Collections Wardrobe windows.
5. Open `/qc`, select **Outfits**, and click **Scan Collection**.

If the native search database is still initializing, Quest Chronicle will display **Preparing** and wait up to twelve seconds rather than caching an empty response.
