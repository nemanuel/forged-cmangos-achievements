# Build Audit

## Scope

This audit answers two narrow questions against the current `cmangos/mangos-classic` core and the local achievement module source:

1. Do `ModuleMgr` / `sModuleMgr` definitions still exist?
2. Does a `modules` static library (`libmodules.a`) still build and link into game?

## Findings

| Check | Result | Evidence |
|---|---|---|
| `ModuleMgr` / `sModuleMgr` definitions in current core | **No** | Current upstream `cmangos/mangos-classic` contains no generic `ModuleMgr.h` or `sModuleMgr` framework. The only similarly named type is the unrelated Warden anticheat manager (`src/game/Anticheat/module/Warden/WardenModuleMgr.hpp`). |
| Achievement module still expects module framework headers | **Yes** | `/home/runner/work/cmangos-achievements/cmangos-achievements/src/AchievementsModule.h` inherits `Module` (`class AchievementsModule : public Module`), and `/home/runner/work/cmangos-achievements/cmangos-achievements/CMakeLists.txt` adds `${CMAKE_SOURCE_DIR}/src/modules/modules/src`, defines `ENABLE_MODULES`, and links target `modules`. |
| `libmodules.a` / `modules` target in current core | **No** | Current upstream build files create `shared` and `game` libraries and link `mangosd` against `shared`, `game`, and `gsoap`; there is no `modules` target in the core build. |
| `mangosd` links a module library | **No** | Upstream `src/mangosd/CMakeLists.txt` links `shared`, `game`, `gsoap`, and `cmangos-compile-option-interface` only. |

## Notes

- Local module CMake still assumes the old module framework:
  - `/home/runner/work/cmangos-achievements/cmangos-achievements/CMakeLists.txt:46-67`
- Current upstream core build wiring does not provide that framework anymore:
  - `cmangos/mangos-classic/CMakeLists.txt`
  - `cmangos/mangos-classic/src/CMakeLists.txt`
  - `cmangos/mangos-classic/src/game/CMakeLists.txt`
  - `cmangos/mangos-classic/src/mangosd/CMakeLists.txt`

## Conclusion

The achievement module still depends on the historical module framework, but the current `mangos-classic` core no longer defines `ModuleMgr` / `sModuleMgr` and no longer builds or links a `modules` static library. Any modernization must remove that dependency instead of trying to relink it unchanged.
