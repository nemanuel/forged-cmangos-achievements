# Migration Plan

## Problem Statement

`cmangos-achievements` currently inherits from the historical CMaNGOS module framework
(`class AchievementsModule : public Module`).  The current `cmangos/mangos-classic`
master no longer ships `ModuleMgr`, `sModuleMgr`, `ModuleConfig`, or the `modules`
static library.  Building against a current core therefore fails immediately.

Additionally, `patches/classic.patch` (143 hunks, 35 files) is unmaintainable because:

- Over half its hunks add `sModuleMgr` call sites for hooks that have **no achievement
  consumer** at all (34 unused hooks).
- The three call sites actually needed by the module (`OnMailTakeItem`,
  `OnActionBidWinning`, `OnTradeAccepted`) are **missing** from the patch.
- The entire CMake layer adds infrastructure (`FetchContent`, module registry,
  option blocks) that serves zero purpose once the module framework is gone.

The goal is **not** to restore the module framework.  The goal is a thin,
achievement-only hook layer that requires the smallest possible invasive change to the
CMaNGOS core.

---

## Dependency Map – What Must Be Removed

### In `CMakeLists.txt`

| Symbol / path | Where used | Replacement |
|---------------|-----------|-------------|
| `${CMAKE_SOURCE_DIR}/src/modules/modules/src` (include dir) | `target_include_directories` | Remove; no Module.h needed |
| `ENABLE_MODULES` compile definition | `target_compile_definitions` | Remove |
| `modules` link target | `target_link_libraries` | Remove |

### In `src/AchievementsModuleConfig.h`

| Symbol | Where used | Replacement |
|--------|-----------|-------------|
| `#include "ModuleConfig.h"` | line 2 | Remove; `AchievementsModuleConfig` no longer inherits `ModuleConfig` |
| `class AchievementsModuleConfig : public ModuleConfig` | line 238 | Become a plain struct |

### In `src/AchievementsModule.h`

| Symbol | Where used | Replacement |
|--------|-----------|-------------|
| `#include "Module.h"` | line 4 | Remove |
| `class AchievementsModule : public Module` | line 784 | Become a standalone singleton |
| `override` on every `OnXxx` method | lines 795–873 | Remove; methods become regular members |
| `GetConfig() const override` | line 792 | Returns plain `AchievementsModuleConfig*` |
| `std::vector<ModuleChatCommand>* GetCommandTable() override` | line 875 | Remove or replace with custom command registration |
| `const char* GetChatCommandPrefix() const override` | line 876 | Remove |

### In `src/AchievementsModule.cpp`

| Symbol | Where used | Replacement |
|--------|-----------|-------------|
| `Module::GetConfig()` base call | line 3698 | Return internal config pointer directly |
| `AchievementsModule()` base constructor call | line 3691 | Plain constructor |
| `GetModule()` calls on `PlayerAchievementMgr` | scattered | Keep; `PlayerAchievementMgr` holds an `AchievementsModule*` already |

### In `src/AchievementsModuleConfig.cpp`

| Symbol | Replacement |
|--------|-----------|
| `#include "ModuleConfig.h"` | Remove |
| `ModuleConfig(...)` base constructor | Remove; use `sConfig` directly |

---

## Phases

### Phase 0 – Baseline (analysis only, already done)

- [x] Confirm `ModuleMgr` / `sModuleMgr` are gone from upstream.
- [x] Audit every hook; classify as *lifecycle*, *criteria consumer*, or *unused*.
- [x] Identify the three call sites missing from `classic.patch`.
- [x] Produce `HOOK_USAGE_MATRIX.md` and `MINIMAL_PATCH_PLAN.md`.

### Phase 1 – Strip module framework from module source

*Touches only files inside `src/` and `CMakeLists.txt`; does **not** touch `patches/`.*

1. **`CMakeLists.txt`** – Remove `modules` include dir, `ENABLE_MODULES` define, and
   `modules` link target.  Keep `ENABLE_ACHIEVEMENTS`, expansion flag, and
   `shared` / `RecastNavigation::Detour` links.

2. **`AchievementsModuleConfig.h` + `.cpp`** – Drop `ModuleConfig` inheritance.
   Replace `OnLoad()` virtual with a plain `bool Load()` that reads from `sConfig`
   directly.  All public fields stay.

3. **`AchievementsModule.h`** – Drop `#include "Module.h"`.  Change class declaration
   from `class AchievementsModule : public Module` to a plain class.  Remove all
   `override` specifiers.  Remove `ModuleChatCommand` return type from
   `GetCommandTable`.  Add a `static AchievementsModule& Instance()` singleton accessor.

4. **`AchievementsModule.cpp`** – Fix constructor (no base call).  Fix `GetConfig()`
   (return `&m_config` directly).  Register chat commands via the existing CMaNGOS
   `ChatHandler` table mechanism instead of `ModuleChatCommand`.

5. **`AchievementsModuleConfig.cpp`** – Remove `ModuleConfig` base call; read config
   values from `sConfig.GetStringDefault` / `GetBoolDefault` / `GetIntDefault` directly.

### Phase 2 – Design and implement `AchievementHooks`

Create two new files in `src/`:

**`AchievementHooks.h`** – A lightweight, non-virtual observer class.
The core calls a single global instance.  See `MINIMAL_PATCH_PLAN.md §AchievementHooks
interface` for the full proposed API.

**`AchievementHooks.cpp`** – Implements the singleton accessor and forwards every
call to `AchievementsModule::Instance()` after a null-check.

The existing `AchievementsModule::OnXxx` methods do **not** change signatures;
`AchievementHooks` is a thin forwarding shim, so the core need only know
`AchievementHooks`, not `AchievementsModule`.

### Phase 3 – Replace `classic.patch`

Generate `patches/classic-minimal.patch` that:

1. **Removes** all 34 unused `sModuleMgr` call sites (and the matching `#include`s
   that are only needed by those sites).
2. **Replaces** every surviving `sModuleMgr.OnXxx(...)` call with
   `sAchievementHooks.OnXxx(...)`.
3. **Adds** the three missing call sites:
   - `src/game/Mails/MailHandler.cpp` – `OnMailTakeItem`
   - `src/game/AuctionHouse/AuctionHouseMgr.cpp` – `OnActionBidWinning`
   - `src/game/Entities/TradeHandler.cpp` – `OnTradeAccepted`
4. **Shrinks** the CMake additions to a single `add_subdirectory` block (no
   FetchContent, no module registry, no per-module option loop).

Expected result: ≈ 75 hunks across ≈ 22 files (down from 143 / 35).

### Phase 4 – Integration and validation

1. Build against a fresh clone of `cmangos/mangos-classic` master with only
   `classic-minimal.patch` applied.
2. Run the existing unit-test suite (if any) and the SQL migration scripts.
3. Archive the old `classic.patch` in `patches/legacy/` for reference.
4. Update `README.md` and `docs/` accordingly.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| `AchievementHooks` call site breaks on CMaNGOS API change | Medium | Medium | Use thin forwarding layer; decouple hook signatures from internal types where possible |
| Three missing hooks (`OnMailTakeItem`, `OnActionBidWinning`, `OnTradeAccepted`) diverge from upstream function signatures | Low | Medium | Confirm exact function names in current upstream before writing call sites |
| `LEARN_SKILL_LEVEL` criteria remain untriggered after migration | Low | Low | Criteria evaluated at login via `CheckAllAchievementCriteria`; acceptable |
| Arena / barber / LFD criteria silently do nothing in Classic | Negligible | Low | Already the case; document as known limitation |

---

## Non-Goals

- Restoring the historical `ModuleMgr` / `sModuleMgr` framework.
- Supporting multiple modules through a shared dispatch layer.
- Implementing untriggered criteria types (arena, barber, LFD, stat snapshots).
- Modifying any CMaNGOS logic other than adding the minimal set of call sites.
