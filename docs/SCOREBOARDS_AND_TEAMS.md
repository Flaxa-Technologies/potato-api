# Scoreboard & Teams API

PotatoMC provides a native, high-performance Scoreboard and Team system matching the ergonomics of Paper and popular libraries like FastBoard—with zero allocation overhead.

---

## 1. Fast Sidebar Scoreboards

Set up and dynamically update a player's sidebar scoreboard in just one line:

```rust
// Fast sidebar creation (ordered top to bottom)
player.set_sidebar_lines("§6§lPotatoMC Network", &[
    "§7-----------------",
    "§fRank: §eMVP+",
    "§fCoins: §612,450",
    "§fOnline: §a48/100",
    "§7-----------------",
    "§epotatomc.flaxa.in",
]);

// Clear scoreboard
player.clear_scoreboard();
```

---

## 2. Dynamic Scoreboard Builder (`Scoreboard`)

For full control over explicit score numbers (1..15) and custom slots:

```rust
use potato_api::scoreboard::{Scoreboard, DisplaySlot};

let mut board = Scoreboard::sidebar("§b§lSkyWars Stats");

// Explicit slot lines
board.set_line(15, "§7Map: §fOvergrowth");
board.set_line(14, "§7Players: §a12/12");
board.set_line(13, "");
board.set_line(12, "§7Kills: §e3");
board.set_line(11, "§7Coins: §6500");

// Apply to player
player.set_scoreboard(&board);

// Dynamically update a specific score line later
board.set_line(12, "§7Kills: §e4");
player.set_scoreboard(&board);
```

---

## 3. Teams API (`Team`)

Configure player prefix/suffix colors, friendly fire, and name tags:

```rust
use potato_api::scoreboard::Team;

let red_team = Team::new("red_team")
    .prefix("§c[RED] ")
    .suffix(" §7★")
    .color("red")
    .friendly_fire(false)
    .add_entry("MAGIC_PLAYZZ");
```
