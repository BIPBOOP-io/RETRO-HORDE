# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a **Vampire Survivors** inspired game built with **Godot 4.4** using GDScript. The project is configured for mobile rendering and can be exported to web platforms.

## Development Commands

### Running the Game
```bash
# Open project in Godot editor
godot project.godot

# Run directly from command line (if main scene is set)
godot --main-pack project.godot
```

### Exporting
```bash
# Export to web (preset configured)
godot --export-release "Web" "./Vampire Survivors Proto.html"
```

### Project Management
```bash
# Check project settings
godot --check-only project.godot

# Import assets
godot --editor project.godot
```

## Code Architecture

### Core Systems

**Global Singleton (`Scripts/Global.gd`)**
- Manages global game state and score data
- Accessible from any scene via autoload

**Main Game Manager (`Scripts/Managers/Main.gd`)**
- Orchestrates the main game loop
- Manages survival timer and kill counting
- Handles player death transitions
- Connects player events to UI updates

**Save System (`Scripts/Managers/SaveManager.gd`)**
- Persistent score storage using Godot's FileAccess
- Saves game statistics (duration, kills, level, date)
- Save location: `user://scores.save`

### Player System Architecture

**Player Controller (`Scripts/Player/Player.gd`)**
- Main player character with signal-based communication
- Emits `died` signal when health reaches zero
- Manages stats: health, XP, level, combat attributes
- Handles auto-attack system with configurable parameters
- Integrates with UpgradeManager for character progression

**Upgrade System (`Scripts/Upgrades/UpgradeManager.gd`)**
- Weighted random upgrade selection based on rarity
- Tracks upgrade levels with max level constraints
- Directly modifies player properties when upgrades are applied
- Rarity system: common (60%), rare (25%), epic (12%), legendary (3%)

### Entity Architecture

**Enemy System**
- `Enemy.gd`: Base enemy behavior
- `EnemySpawner.gd`: Manages enemy spawning patterns
- `BackgroundEnemy.gd`: Background decorative enemies
- All enemies use group "enemies" for player targeting

**Projectile System**
- `Arrow.gd`: Player projectile with damage, pierce, knockback, and crit
- Supports multi-shot and spread patterns
- Configurable through player upgrade system

**Pickup System**
- XP orbs in three sizes (Small, Medium, Big)
- Each has individual collection logic

### UI Architecture

**HUD System (`Scripts/UI/HUD.gd`)**
- Real-time display of player stats
- Updates via direct method calls from game systems
- Shows: health, XP progress, level, timer, kills

**Menu Systems**
- `MainMenu.gd`: Entry point
- `GameOver.gd`: End game screen with score display
- `LevelUpMenu.gd`: Upgrade selection interface
- `FloatingText.gd`: Damage/healing feedback

### Scene Structure

```
Scenes/
├── Main/Main.tscn          # Main game scene
├── Player/Player.tscn      # Player character
├── Enemies/                # Enemy prefabs
├── Projectiles/            # Projectile prefabs
├── Pickups/                # Collectible prefabs
├── UI/                     # User interface scenes
└── Effects/                # Particle effects
```

### Key Design Patterns

**Signal-Based Communication**
- Player emits `died` signal to Main manager
- UI updates through direct method calls rather than signals
- Upgrade system uses callback connections

**Group-Based Entity Management**
- "player", "enemies", "hud", "levelup_menu" groups
- Used for quick entity lookup and targeting

**Timer-Based Systems**
- Survival timer for game duration
- Attack timer for player auto-attack
- Regeneration timer for health recovery

**Property-Based Upgrades**
- Upgrades directly modify player properties
- No complex component system - simple property mutations
- Level tracking prevents over-upgrading

### Development Notes

**File Naming Conventions**
- Scripts mirror scene structure
- French comments and upgrade names throughout codebase
- Manager classes in `Scripts/Managers/`
- Entity-specific scripts in matching subdirectories

**Godot-Specific Considerations**
- Uses autoload for Global singleton
- Configured for mobile rendering method
- Web export preset with HTML5 output
- Resource files use .tres format for custom resources

**Performance Patterns**
- Groups used for efficient entity queries
- Timer nodes for regular updates instead of _process polling
- Particle effects instantiated on-demand
- Simple property-based stat system without complex calculations