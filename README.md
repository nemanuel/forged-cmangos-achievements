# Achievements Module for CMaNGOS Classic

[![Build & Validate](https://github.com/nemanuel/cmangos-achievements/actions/workflows/build.yml/badge.svg)](https://github.com/nemanuel/cmangos-achievements/actions/workflows/build.yml)

Backports WotLK achievements to CMaNGOS Classic (and optionally TBC).

This module was ported from https://github.com/tsaah/core/tree/hb-achievements and has been
updated to work with the latest CMaNGOS Classic core and classic-db.

![Achievements UI](https://github.com/davidonete/cmangos-achievements/assets/11618807/caa813e9-0053-4405-8d00-cf04fe5c205f)

---

## Supported Cores

| Core | Status |
|------|--------|
| CMaNGOS Classic | ✅ Supported |
| CMaNGOS TBC | ✅ Supported |
| CMaNGOS WoTLK | ❌ Not applicable |

---

## Quick Start

### Prerequisites

* CMaNGOS Classic (or TBC) compiled and running
* MySQL / MariaDB 8.0+
* The [Achiever addon](https://github.com/celguar/Achiever) installed on the game client

### Installation

1. **Install the module framework** following the instructions at
   https://github.com/davidonete/cmangos-modules#how-to-install

2. **Place this module** in `src/modules/achievements` inside the CMaNGOS source tree:
   ```bash
   git clone https://github.com/nemanuel/cmangos-achievements \
       mangos-classic/src/modules/achievements
   ```

3. **Enable the module** in CMake and recompile:
   ```bash
   cmake -DBUILD_MODULE_ACHIEVEMENTS=ON ..
   make -j$(nproc)
   ```

4. **Install the configuration file** — copy
   `src/modules/achievements/src/achievements.conf.dist.in` to the directory
   containing your `mangosd` executable and rename it to `achievements.conf`.
   Edit the options as needed (see [Configuration](#configuration)).

5. **Install the database schemas** (first time only):
   ```bash
   # World database
   mysql -u<user> -p<pass> <world_db>   < sql/install/world/01_world_data.sql
   mysql -u<user> -p<pass> <world_db>   < sql/install/world/02_world_update.sql
   mysql -u<user> -p<pass> <world_db>   < sql/install/world/03_world_locales.sql

   # Characters database
   mysql -u<user> -p<pass> <chars_db>   < sql/install/characters/characters.sql
   ```

6. **Upgrading an existing installation** — run the migration scripts instead:
   ```bash
   mysql -u<user> -p<pass> <world_db>   < sql/migrate/world_migrate.sql
   mysql -u<user> -p<pass> <chars_db>   < sql/migrate/characters_migrate.sql
   ```
   The migration scripts are idempotent and safe to re-run.

7. **Install the client addon** — download and install
   https://github.com/celguar/Achiever

---

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `Achievements.Enable` | `0` | Enable the achievements system |
| `Achievements.SendMessage` | `1` | Announce achievements in chat/guild |
| `Achievements.SendAddon` | `1` | Send Achiever addon data packets |
| `Achievements.SendVisual` | `1` | Play visual effect on achievement earn |
| `Achievements.RandomBots` | `0` | Enable achievements for random bots |
| `Achievements.RandomBotsRealmFirst` | `0` | Allow bots to earn Realm First achievements |
| `Achievements.AccountAchievenemts` | `0` | Sync achievements across all characters on an account |
| `Achievements.EffectId` | `146` | Spell visual effect ID played on achievement earn |

---

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

---

## Architecture & Documentation

| Document | Description |
|----------|-------------|
| [docs/architecture-analysis.md](docs/architecture-analysis.md) | Current architecture, event flow, data structures, technical debt |
| [docs/hook-audit.md](docs/hook-audit.md) | Audit of all core hooks — required, replaceable, and obsolete |
| [docs/event-architecture.md](docs/event-architecture.md) | Target modern event architecture and migration strategy |

### Required Core Changes

A reduced patch to CMaNGOS Classic is required for ~23 game events that are
not yet exposed by the CMaNGOS `ScriptMgr`.  See
[docs/hook-audit.md](docs/hook-audit.md) for the complete list (Category A
hooks) and [docs/event-architecture.md](docs/event-architecture.md) for the
target minimal-patch design.

---

## CI

The GitHub Actions workflow (`.github/workflows/build.yml`) automatically:

1. Checks out the latest `mangos-classic` master
2. Builds the core + achievements module
3. Validates all SQL scripts against a live MySQL 8.0 instance
4. Verifies idempotency of the migration scripts

---

## Credits

* Original port: https://github.com/tsaah/core/tree/hb-achievements
* Module packaging: https://github.com/davidonete/cmangos-achievements
* Client addon: https://github.com/celguar/Achiever

