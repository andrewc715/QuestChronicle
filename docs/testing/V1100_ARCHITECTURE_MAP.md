# Quest Chronicle v1.10.0 Architecture Map

## Runtime routing

```text
Outfits UI
   |
   v
QuestChronicle.Generation API
   |
   v
Mode Registry
   |
   +-- TRAVELER -------- SHARED_FRAMEWORK
   |      |
   |      +-- GenerationLifecycle
   |      +-- GenerationJob phase state machine
   |      +-- SchedulerEngine
   |      +-- ContextProvider
   |      +-- AnchorEngine
   |      +-- CandidateEngine
   |      +-- SupportEngine
   |      +-- ValidationEngine
   |      +-- RepairEngine
   |      +-- WeaponEngine
   |      +-- CommitEngine
   |      +-- RerollEngine
   |      +-- DiagnosticsEngine
   |      +-- VisualLanguage
   |              |
   |              v
   |         Traveler policy callbacks
   |              |
   |              v
   |         Live-validated v1.9.0.15 selection,
   |         scoring, repair, route, and report providers
   |
   +-- ZONE_NATIVE ----- LEGACY adapter ---- Existing worker path
   +-- CLASS_FANTASY --- LEGACY adapter ---- Existing worker path
   +-- CHRONICLE_ECHO -- LEGACY adapter ---- Existing worker path
```

## Responsibility boundary

### Shared framework owns

- registered mode identity and capability discovery;
- action IDs and lifecycle state;
- Generate Outfit and Reroll Unlocked dispatch;
- contextual support-reroll lifecycle;
- cooperative phase-state routing;
- context setup dispatch;
- anchor-phase dispatch;
- candidate and weapon-phase orchestration;
- completed-outfit validation routing;
- alternate-skeleton routing;
- atomic commit routing;
- cancellation routing;
- implementation identity in immutable diagnostics.

### Traveler policy owns

- mode context and Chronicle context consumption;
- visual descriptor provider;
- anchor candidate and pair scoring callbacks;
- novelty interpretation;
- support profile, role, and scoring callbacks;
- mismatch budgets and final validation rules;
- repair-target ranking and alternate-skeleton callback;
- naming, warning, comparison, and tuning-audit policy.

The underlying v1.9.0.15 implementations are retained and wrapped where relocation would add parity risk. Shared modules contain no Traveler mode constants or Traveler-specific scoring rules.

## Compatibility boundary

Zone Native, Class Fantasy, and Chronicle Echo are explicit legacy adapters. They use the same user-facing controls and results as v1.9.0.15, but do not claim shared-framework capability.

Legacy individual anchor and weapon-slot rerolls remain outside the extracted modern action lifecycle. Contextual support-slot rerolls use the shared lifecycle.
