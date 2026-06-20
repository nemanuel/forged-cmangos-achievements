# Achievements Module for CMaNGOS Classic

[![Build & Validate](https://github.com/nemanuel/forged-cmangos-achievements/actions/workflows/build.yml/badge.svg)](https://github.com/nemanuel/forged-cmangos-achievements/actions/workflows/build.yml)

Backports WotLK achievements to CMaNGOS Classic.

This module was ported from https://github.com/tsaah/core/tree/hb-achievements and has been
updated to work with the latest CMaNGOS Classic core and classic-db.

The upstream core no longer ships the historical generic `ModuleMgr`/`ModuleConfig`
framework, so the current compatibility work focuses on a thin, achievement-specific
hook surface and a much smaller core patch.

<!-- ![Achievements UI](https://github.com/davidonete/cmangos-achievements/assets/11618807/caa813e9-0053-4405-8d00-cf04fe5c205f) -->

## Supported Cores

| Core | Status |
|------|--------|
| CMaNGOS Classic | Supported |
| CMaNGOS TBC | Untested |
| CMaNGOS WoTLK | Unsupported |

## Latest CMaNGOS Compatibility

The modernization work in this repository is aimed at keeping achievements working on
current CMaNGOS cores without reviving the old module framework.

- The legacy `ModuleMgr` and `ModuleConfig` dependency is being replaced with a small
   achievements-only integration surface.
- Unused hook call sites are removed instead of being carried forward for compatibility.
- The remaining core changes are kept as narrow and auditable as possible so the patch
   stays maintainable against upstream changes.


## Installation

1. **Prepare a current CMaNGOS Classic or TBC checkout** and apply
   `patches/classic.patch` to the core tree before building. The old generic module
   framework is no longer required in upstream cores.
   ```bash
   cd mangos-classic
   git apply --whitespace=fix /path/to/cmangos-achievements/patches/classic.patch
   ```

2. **Copy this repository into** `src/modules/achievements` inside the CMaNGOS source
   tree:
   ```bash
   git clone https://github.com/nemanuel/cmangos-achievements \
       mangos-classic/src/modules/achievements
   ```

3. **Configure CMake and build** the core with achievements enabled:
  
   ```bash
   # Windows
   cmake -S .\mangos-classic -B .\mangos-classic\build -G "Visual Studio 17 2022" -A x64 -DBUILD_MODULES=ON -DBUILD_PLAYERBOTS=ON -DBUILD_MODULE_ACHIEVEMENTS=ON -DBoost_DIR="C:\local\boost_1_85_0\lib64-msvc-14.3\cmake\Boost-1.85.0"
   ```

4. **Install the configuration file** — copy
   `src/modules/achievements/src/achievements.conf.dist.in` to the directory that
   contains your `mangosd` executable and rename it to `achievements.conf`. Edit the
   options as needed (see [Configuration](#configuration)).

5. **Install the database schemas** (first time only) - run PowerShell commands:
   ```bash
   # World database
   Get-ChildItem -Path ".\mangos-classic\src\modules\Achievements\sql\install\world\*.sql" | ForEach-Object {
      Get-Content $_.FullName | mysql -u root -p --database=classicmangos
   }

   # Characters database
   Get-ChildItem -Path ".\mangos-classic\src\modules\Achievements\sql\install\characters\*.sql" | ForEach-Object {
      Get-Content $_.FullName | mysql -u root -p --database=classiccharacters
   }
   ```

6. **Upgrading an existing installation** — run the migration scripts instead:
   ```bash
   mysql -u<user> -p<pass> <world_db>   < sql/migrate/world_migrate.sql
   mysql -u<user> -p<pass> <chars_db>   < sql/migrate/characters_migrate.sql
   ```
   The migration scripts are idempotent and safe to re-run.

7. **Install the client addon** — download and install
   https://github.com/celguar/Achiever

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `Achievements.Enable` | `0` | Enable the achievements system |
| `Achievements.SendMessage` | `1` | Announce achievements in chat/guild |
| `Achievements.SendAddon` | `1` | Send Achiever addon data packets |
| `Achievements.SendVisual` | `1` | Play visual effect on achievement earn |
| `Achievements.RandomBots` | `0` | Enable achievements for random bots |
| `Achievements.RandomBotsRealmFirst` | `0` | Allow bots to earn Realm First achievements |
| `Achievements.AccountAchievenemts` | `0` | Sync achievements across all characters on an account (note: key name has a typo preserved for backward compatibility) |
| `Achievements.EffectId` | `146` | Spell visual effect ID played on achievement earn |

## Uninstallation

**Option A — Disable only:**
Set `Achievements.Enable = 0` in `achievements.conf` and restart the server.

**Option B — Full removal:**
1. Recompile without `-DBUILD_MODULE_ACHIEVEMENTS=ON`
2. Remove database tables:
   ```bash
   mysql -u<user> -p<pass> <chars_db>   < sql/uninstall/characters/characters.sql
   mysql -u<user> -p<pass> <world_db>   < sql/uninstall/world/world.sql
   ```

## Architecture & Documentation

| Document | Description |
|----------|-------------|
| [docs/architecture-analysis.md](docs/architecture-analysis.md) | Current architecture, event flow, data structures, technical debt |
| [docs/hook-audit.md](docs/hook-audit.md) | Audit of all core hooks — required, replaceable, and obsolete |
| [docs/migration/01-build-audit.md](docs/migration/01-build-audit.md) | Build audit showing why the historical module framework no longer links against current upstream cores |
| [docs/migration/02-achievement-hook-audit.md](docs/migration/02-achievement-hook-audit.md) | Full hook inventory for the achievement consumers |
| [docs/migration/03-scriptmgr-migration-audit.md](docs/migration/03-scriptmgr-migration-audit.md) | Analysis of what ScriptMgr can and cannot replace |
| [docs/migration/04-minimal-hook-set.md](docs/migration/04-minimal-hook-set.md) | Minimal residual hook set needed for current CMaNGOS |
| [docs/event-architecture.md](docs/event-architecture.md) | Target modern event architecture and migration strategy |
| [docs/classic-patch-modernization-report.md](docs/classic-patch-modernization-report.md) | Compile errors, failing patch hunks, ModuleMgr dependencies, and patch-footprint replacement recommendations |

### Required Core Changes

A reduced patch to CMaNGOS Classic is required to keep the achievements module
working on current upstream. The migration docs split the work into audited hook
classes, a minimal residual hook set, and the follow-up step of replacing the
legacy framework with a thinner achievement-specific surface.

## CI

The GitHub Actions workflow (`.github/workflows/build.yml`) automatically:

1. Checks out the latest `mangos-classic` master
2. Builds the core + achievements module
3. Validates all SQL scripts against a live MySQL 8.0 instance
4. Verifies idempotency of the migration scripts

## Credits

* Original port: https://github.com/tsaah/core/tree/hb-achievements
* Module packaging: https://github.com/davidonete/cmangos-achievements
* Client addon: https://github.com/celguar/Achiever
