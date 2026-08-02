# Quest Chronicle v1.8.5 Live Appearance Metadata Test

1. Install v1.8.5 and `/reload`.
2. Open Outfits while item metadata is still loading.
3. Navigate to a page containing placeholder `Appearance <id>` rows.
4. Do not click those rows.
5. Confirm each visible row changes to its item name as WoW supplies the data.
6. Confirm `Loading era` changes to the final generated/excluded state without clicking.
7. Hover a row while its data loads and confirm the tooltip updates in place.
8. Confirm the selected appearance label updates if the selected source is hydrated.
9. Click an appearance and confirm selection changes once, without a second visible page rebuild.
10. Confirm Generate Outfit, weapon routes, concepts, Custom Sets, and the one-login scan policy still behave as before.
