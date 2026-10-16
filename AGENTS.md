# AGENTS.md - Mini Shop (Godot 4 2D Top-Down Shop Simulation)

## 1. Project Overview & Rules
- **Game Title:** Mini Shop
- **Engine:** Godot Engine 4.x (GDScript)
- **Target Audience:** High School / SMK PKL Presentation (Clear architecture, educational, well-documented)
- **Core Principle:** Playability > Complexity | Code Quality > Feature Count | Pure Code > External Assets

### Strict Constraints:
1. **100% Pure Code (NO EXTERNAL ASSETS):**
   - No image files (`.png`, `.jpg`, `.svg`).
   - No external fonts (`.ttf`, `.otf`).
   - No external audio packs (`.wav`, `.mp3`).
   - Visuals are rendered procedurally via `_draw()`, `ColorRect`, `Panel`, `Label`, `StyleBoxFlat`, or `Polygon2D`.
   - Cohesive, modern pastel/warm geometric color palette.
2. **Modular Architecture (NO GIANT SCRIPTS):**
   - Distinct, decoupled scenes for each entity and component.
   - Dedicated scripts under `scripts/` and scenes under `scenes/`.
3. **Strict Iteration (Phase by Phase):**
   - Only 1 phase is developed at a time.
   - Hard stop after each phase for user testing in Godot Editor.

---

## 2. Directory Structure
```
res://
├── assets/                  # (Empty / internal engine assets only)
├── scenes/
│   ├── player/              # Player scene & character nodes
│   ├── shop/                # Shop environment & main game scenes
│   ├── entities/            # Shelves, Cashier, Customers (Future Phases)
│   └── ui/                  # HUD & UI overlays
├── scripts/
│   ├── autoload/            # Singletons / global managers
│   └── components/          # Reusable behavior components
├── project.godot            # Godot 4 project configuration
└── AGENTS.md                # Project guidelines & phase tracker
```

---

## 3. Development Roadmap & Tracker

- [x] **Setup & Architecture**
  - [x] Create project structure and `AGENTS.md`
  - [x] Configure `project.godot` (1152x648 resolution, input mappings)

- [x] **FASE 1: PROTOTYPE FOUNDATION**
  - [x] Procedural Shop Environment (`ShopEnvironment.tscn`) with cozy floor, wall trims, and wall collisions (`StaticBody2D`).
  - [x] Procedural Player (`Player.tscn`) with custom `_draw()` rendering (body, apron, directional eyes, walking animation).
  - [x] Smooth 8-directional top-down movement (`player.gd`) supporting WASD and Arrow Keys.
  - [x] Boundary collision validation.
  - [x] Main Scene assembly (`Main.tscn`) with centered viewport camera and clean layout.

- [x] **FASE 2: INTERACTIVE SHELVES & ITEM HOLDING SYSTEM**
  - [x] Shelf scene (`Shelf.tscn`, `shelf.gd`) with procedural wood rendering, stored items display, dynamic stock counter, and interaction zone (`Area2D`).
  - [x] Procedural item catalog & drawing utilities (`item_data.gd`) for Soda, Snack, and Apple.
  - [x] Player item holding system (pick up from shelf, hold with visual aura & raised hands, place back or into matching shelves).
  - [x] Dynamic prompt pill with proximity detection, glow highlight, and mismatch warning.
  - [x] Pop bounce tween feedback when interacting.

- [x] **FASE 3: CUSTOMER SPAWNING & STATE MACHINE**
  - [x] Procedural customer rendering (`Customer.tscn`, `customer.gd`) with randomized shirt/hair/skin tones, walk animation, and thought bubble.
  - [x] Customer AI State Machine (ENTERING -> DECIDING -> WALKING_TO_SHELF -> BROWSING_SHELF -> GOING_TO_CASHIER -> QUEUEING -> LEAVING).
  - [x] Cashier counter furniture & queue system (`CashierCounter.tscn`, `cashier_counter.gd`).
  - [x] Timed customer spawner (`CustomerSpawner.tscn`, `customer_spawner.gd`) managing store capacity.

- [x] **FASE 4: CASHIER, PAYMENT & ECONOMY SYSTEM**
  - [x] Cash register interaction zone (`CashierCounter.tscn`, `cashier_counter.gd`).
  - [x] Checkout transaction and money counter (`scripts/autoload/game_manager.gd`).
  - [x] Product prices catalog ($12 Soda, $15 Snack, $8 Apple) in `item_data.gd`.
  - [x] Procedural feedback: cash drawer pop, register screen flash, floating "+$XX" revenue animation, and real-time HUD counter.

- [x] **FASE 5: RESTOCK & SIMPLE UPGRADE STATION**
  - [x] Delivery box / restock station (`RestockCrate.tscn`, `restock_crate.gd`) with wholesale purchasing ($5 Soda, $6 Snack, $3 Apple).
  - [x] Movement speed upgrade ($40, +35% movement speed).
  - [x] Shop capacity expansion upgrade ($60, increases shelf capacity from 5 to 8).
  - [x] Upgrade workbench station (`UpgradeStation.tscn`, `upgrade_station.gd`) with real-time feedback and dynamic prompt pill.

- [x] **FASE 6: HUD, UI POLISH & GAME LOOP COMPLETION**
  - [x] Clean procedural UI header (Store Clock 08:00-18:00, Day counter, Cash, Reputation rating, Served count).
  - [x] End-of-day summary modal (`DaySummaryModal.tscn`, `day_summary_modal.gd`) displaying sales, wholesale costs, net profit, and customer satisfaction.
  - [x] Complete seamless game loop ("Buka Toko Hari Berikutnya" button advancing days with retained wealth & upgrades).

- [x] **OVERHAUL: MODERN MINIMARKET (HUMANIZED) & SYSTEM ENHANCEMENTS**
  - [x] Ceramic Tile Floor & Brand Walls (`shop_environment.gd`): Bright square ceramic tile grid with grout seams, glossy sheen, modern neutral walls with multi-colored convenience store brand stripes, and commercial entrance welcome mat.
  - [x] Steel Gondola Shelves (`shelf.gd`): Powder-coated white steel frame, perforated metal uprights with punch slots, vibrant blue/red/green price tag rail channels, acrylic product retainers, and modern LED stock indicators.
  - [x] POS Checkout Counter (`cashier_counter.gd`): Sleek laminate counter with touchscreen POS terminal, barcode flatbed laser scanner with red beam, EDC payment card terminal, receipt paper slot, and queue floor markings.
  - [x] Logistics Restock Carton (`restock_crate.gd`): Heavy-duty commercial distribution carton with white manifest label, barcode stripes, and product stamp.
  - [x] Ergonomic Waiting Bench (`bench.gd`): Tubular stainless steel frame with contoured composite teal seats and rubber feet.
  - [x] Management Kiosk (`upgrade_station.gd`): Modern store operations pedestal with interactive tablet dashboard showing analytics bar charts.
  - [x] Minimarket Floor Litter (`trash.gd`): Thermal receipt paper strips, crushed soda cans with pull tabs, and foil snack wrappers.
  - [x] Humanized Store Clerk (`player.gd`): Defined body anatomy, animated leg swing and work shoes, polo shirt uniform, dark apron with corporate orange strip, clipped employee ID badge, visor cap, and expressive eyes.
  - [x] Humanized Customers & Variations (`customer.gd`): Distinct casual/athletic/formal clothing, leg walk cycles, expressive facial emotions, overhead patience meter bar (green/yellow/red), anger reaction upon depletion, and fail-safe exit navigation.
  - [x] Zero Emojis Constraint: Strictly maintained across all code, logs, and docs.

- [x] **GAMEPLAY EXPANSION: PRE-OPEN PHASE, CARRY CAPACITY & CASHIER AUTOMATION**
  - [x] Pre-Open Preparation Phase: Day begins in `PRE_OPEN` with zero customer spawns and frozen clock (08:00); player freely restocks, cleans, and arranges store.
  - [x] Interactive Store Opening: Trigger at entrance doorway (`[E] Buka Toko`) plus HUD button `[Buka Toko [E]]` switches state to `OPEN`, advancing store hours (08:00 to 21:00) and activating customer spawner.
  - [x] Day Closing & Wage Settlement: Day transitions to `CLOSING` at 21:00; summary modal opens once remaining customers exit, deducting cashier daily wages ($15/day).
  - [x] Multi-Item Carry Capacity: Player carries multiple items (Default Level 1: 2 items -> Level 2: 4 items [$50] -> Level 3: 6 items [$80]) with overhead capacity pill indicators and smart shelf/restock interaction.
  - [x] Automated Cashier Helper NPC: Hired at management kiosk ($75 hire cost, $15/day wage); stands behind counter, automatically scans and completes transactions with 3 upgradeable speed tiers (2.5s -> 1.4s -> 0.5s); player manual override retained.

- [x] **DAY CYCLE FIX & STORE MANAGEMENT REFACTOR**
  - [x] Day cycle state machine architecture: Explicit `enum DayState { PRE_OPEN, OPEN, CLOSING, SUMMARY }` in `game_manager.gd`.
  - [x] Reliable day advancement: `next_day()` and `start_next_day()` cleanly increment `current_day += 1` / `day_count += 1`, reset clock to 08:00, clear daily revenue/expenses/wages, and return state to `PRE_OPEN`.
  - [x] Zero-deadlock closing cycle: Active customer counter excludes `is_queued_for_deletion()` nodes, customer nodes registered in `"customers"` group, direct exit waypoint navigation, plus 15-second emergency safety timer.
  - [x] Procedural store status sign: Doorway illuminated neon sign displays `[ BUKA ]` in green or `[ TUTUP ]` in red, synchronized with HUD status badge and context-aware `[Buka Toko [E]]` button.
  - [x] DaySummaryModal integration: Next day button cleanly transitions state, updates HUD, and restores store for preparation phase.
  - [x] Strict zero-emoji compliance across all GDScript files, scenes, logs, and markdown docs.

- [x] **FULL ASSET PACK & AUDIO INTEGRATION (`res://assets/`)**
  - [x] Centralized Asset & Audio Manager (`scripts/autoload/asset_manager.gd`) registered as `AssetManager` autoload in `project.godot`.
  - [x] Application Icon (`assets/icon.svg`, `assets/icon.png`) configured in `project.godot`.
  - [x] Character & NPC Sprites (`assets/sprites/characters/`): `player_clerk`, `cashier_npc`, `customer_regular`, `customer_impatient`, `customer_vip` (SVG + PNG).
  - [x] Entity & Environment Sprites (`assets/sprites/entities/`, `assets/sprites/environment/`): `shelf_soda`, `shelf_snack`, `shelf_apple`, `cashier_counter`, `restock_crate_soda`, `restock_crate_snack`, `restock_crate_apple`, `upgrade_station`, `bench`, `trash_receipt`, `trash_can`, `trash_wrapper`, `floor_tile`, `welcome_mat`, `sign_open`, `sign_closed`, `queue_marker` (SVG + PNG).
  - [x] Item & UI Sprites (`assets/sprites/items/`, `assets/sprites/ui/`): `item_soda`, `item_snack`, `item_apple`, `icon_money`, `icon_clock`, `icon_day`, `icon_customer`, `icon_star`, `icon_check`, `bubble_frame`, `status_angry`, `status_empty` (SVG + PNG).
  - [x] Audio Effects & Looping BGM (`assets/audio/sfx/`, `assets/audio/bgm/`): `sfx_pickup.wav`, `sfx_place.wav`, `sfx_cash_register.wav`, `sfx_upgrade.wav`, `sfx_restock_buy.wav`, `sfx_clean_trash.wav`, `sfx_store_open.wav`, `sfx_store_close.wav`, `sfx_error.wav`, `sfx_customer_angry.wav`, and `bgm_minimarket.wav`.
