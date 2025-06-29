# DFHack Wonders Script

Build magnificent ancient wonders in Dwarf Fortress using the DFHack scripting system.

**File:** `wonders.lua`

## Usage
```bash
wonders <type> <x> <y> [size] [material] [--instant]
```

**Parameters:**
- `type`: Wonder type (see list below)
- `x`/`y`: Map coordinates (must be valid and exposed)
- `size` (optional): `small`, `medium`, `large` (defaults to `medium`)
- `material` (optional): Any valid inorganic material ID (e.g. `GRANITE`, `MARBLE`, `SLATE`)
- `--instant` (optional): Complete construction immediately

═══════════════════════════════════════════════════════════════
                          GIZA PYRAMID
═══════════════════════════════════════════════════════════════

**Type:** `giza`
**Description:** Sloped Egyptian-style pyramid with hollow interior chambers
**Default Size:** 18×18 base, 12 levels tall
**Features:** Central ramp access, hollow interior, ritual chamber
**Customizable:** Size, material

```
    ▲
   ███
  █░░░█
 █░░░░░█
█░░░░░░░█
█████████
```

═══════════════════════════════════════════════════════════════
                      QUETZALCOATL PYRAMID
═══════════════════════════════════════════════════════════════

**Type:** `quetzalcoatl`
**Description:** Stepped Mesoamerican pyramid with temple platform
**Default Size:** 18×18 base, 12 levels tall
**Features:** Terraced steps, temple cap floor
**Customizable:** Size, material

```
   ███
  █████
 ███████
█████████
```

═══════════════════════════════════════════════════════════════
                           LIGHTHOUSE
═══════════════════════════════════════════════════════════════

**Type:** `lighthouse`
**Description:** Tall tower with beacon chamber
**Default Size:** 7×7 base, 15 levels tall
**Features:** Base platform, hollow shaft, beacon chamber
**Customizable:** Height, material

```
 █████
 █░░░█
 █░░░█
 █░░░█
 █░░░█
█████████
```

═══════════════════════════════════════════════════════════════
                           STONEHENGE
═══════════════════════════════════════════════════════════════

**Type:** `stonehenge`
**Description:** Circular arrangement of standing stones with lintels
**Default Size:** Fixed 16-tile diameter circle
**Features:** 12 standing stones, connecting lintels
**Customizable:** Location only

```
  █─█ █─█
 █       █
█    ░    █
 █       █
  █─█ █─█
```

═══════════════════════════════════════════════════════════════
                           GREAT WALL
═══════════════════════════════════════════════════════════════

**Type:** `greatwall`
**Description:** Fortified wall with watchtowers
**Default Size:** 50 tiles long, 8 levels tall
**Features:** Double-thick walls, watchtowers every 10 segments
**Customizable:** Length, height, material

```
███     ███     ███
███████████████████
███████████████████
```

═══════════════════════════════════════════════════════════════
                            COLOSSUS
═══════════════════════════════════════════════════════════════

**Type:** `colossus`
**Description:** Massive warrior statue with spear and shield
**Default Size:** 7×5 base, 28 levels tall
**Features:** Hollow legs, torso chamber, distinct head, left arm with shield, right arm with spear
**Customizable:** Material only

```
     █
     █
██   █
██████
██████
██████
█░█░██
█░█░██
█    █
```

═══════════════════════════════════════════════════════════════
                            ZIGGURAT
═══════════════════════════════════════════════════════════════

**Type:** `ziggurat`
**Description:** Stepped pyramid with flat platforms
**Default Size:** 18×18 base, 12 steps
**Features:** Terraced levels, central altar
**Customizable:** Size, material

```
   ███
  █████
 ███████
█████████
█████████
```

═══════════════════════════════════════════════════════════════
                         ORACLE TEMPLE
═══════════════════════════════════════════════════════════════

**Type:** `oracle`
**Description:** Columned temple with central sanctum
**Default Size:** 20×32 footprint, 5 levels tall
**Features:** Pillar colonnade, inner chamber
**Customizable:** Material only

```
█ █ █ █ █
█  ███  █
█  ███  █
█ █ █ █ █
```

═══════════════════════════════════════════════════════════════
                            OBELISKS
═══════════════════════════════════════════════════════════════

**Type:** `obelisk` or `obelisks`
**Description:** Four tall stone columns in formation
**Default Size:** 10×10 formation, 10 levels tall
**Features:** Four corner obelisks
**Customizable:** Height, material

```
█     █
█     █
█     █
       
█     █
█     █
█     █
```

═══════════════════════════════════════════════════════════════
                         GREAT LIBRARY
═══════════════════════════════════════════════════════════════

**Type:** `library`
**Description:** Multi-story library with shelving
**Default Size:** 20×32 footprint, 6 levels tall
**Features:** Tiered shelves, reading table on top
**Customizable:** Material only

```
███████████
█║█║█║█║█║█
█║█║█║█║█║█
█║█║█║█║█║█
███████████
```

## Example Usage

```bash
wonders giza 100 150 large LIMESTONE
wonders lighthouse 80 80 medium MARBLE --instant
wonders stonehenge 200 120
wonders colossus 50 75 OBSIDIAN
```

## Finding Coordinates

**Using gui/inspect (Recommended):**
1. Press Ctrl+Shift+D to open DFHack terminal
2. Type `gui/inspect` and press Enter
3. Hover cursor over desired tile
4. Use the displayed Tile x/y coordinates

**Pro Tip:** Ensure the target tile is exposed and accessible.

## Technical Notes

- Uses `dfhack.maps.ensureTileBlock` for tile placement
- `--instant` flag completes construction immediately
- Without `--instant`, creates construction jobs for dwarves
- Builds on surface tiles only
- Some wonders have hollow interiors for functionality