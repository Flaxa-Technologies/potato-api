use serde::{Deserialize, Serialize};

/// Display slots for objectives on player screens.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum DisplaySlot {
    List,
    Sidebar,
    BelowName,
}

/// Criterion for scoreboard objectives.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ObjectiveCriteria {
    Dummy,
    Trigger,
    DeathCount,
    PlayerKillCount,
    TotalKillCount,
    Health,
    Custom(String),
}

/// Paper/Bukkit-compatible Scoreboard representation.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Scoreboard {
    pub name: String,
    pub title: String,
    pub slot: DisplaySlot,
    pub lines: Vec<(usize, String)>,
}

impl Scoreboard {
    pub fn new(name: impl Into<String>, title: impl Into<String>, slot: DisplaySlot) -> Self {
        Self {
            name: name.into(),
            title: title.into(),
            slot,
            lines: Vec::new(),
        }
    }

    /// Fast helper to create a sidebar scoreboard (like FastBoard).
    pub fn sidebar(title: impl Into<String>) -> Self {
        Self::new("sidebar", title, DisplaySlot::Sidebar)
    }

    pub fn set_title(&mut self, title: impl Into<String>) {
        self.title = title.into();
    }

    pub fn title(&self) -> &str {
        &self.title
    }

    /// Set a specific score line (score is typically 1..15 for sidebars).
    pub fn set_line(&mut self, score: usize, text: impl Into<String>) {
        let text = text.into();
        if let Some(pos) = self.lines.iter().position(|(s, _)| *s == score) {
            self.lines[pos].1 = text;
        } else {
            self.lines.push((score, text));
            self.lines.sort_by(|a, b| b.0.cmp(&a.0)); // Descending order
        }
    }

    /// Helper to set all lines at once from top to bottom (index 0 gets the highest score).
    pub fn set_lines(&mut self, lines: &[impl AsRef<str>]) {
        self.lines.clear();
        let total = lines.len();
        for (i, line) in lines.iter().enumerate() {
            let score = total.saturating_sub(i);
            self.lines.push((score, line.as_ref().to_string()));
        }
    }

    pub fn get_line(&self, score: usize) -> Option<&str> {
        self.lines.iter().find(|(s, _)| *s == score).map(|(_, t)| t.as_str())
    }

    pub fn remove_line(&mut self, score: usize) {
        self.lines.retain(|(s, _)| *s != score);
    }

    pub fn clear_lines(&mut self) {
        self.lines.clear();
    }

    pub fn lines(&self) -> &[(usize, String)] {
        &self.lines
    }
}

/// Team representation for scoreboard colors, prefixes, suffixes, and visibility.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Team {
    pub name: String,
    pub display_name: String,
    pub prefix: Option<String>,
    pub suffix: Option<String>,
    pub color: Option<String>,
    pub friendly_fire: bool,
    pub see_friendly_invisibles: bool,
    pub entries: Vec<String>,
}

impl Team {
    pub fn new(name: impl Into<String>) -> Self {
        let n = name.into();
        Self {
            name: n.clone(),
            display_name: n,
            prefix: None,
            suffix: None,
            color: None,
            friendly_fire: false,
            see_friendly_invisibles: false,
            entries: Vec::new(),
        }
    }

    pub fn prefix(mut self, prefix: impl Into<String>) -> Self {
        self.prefix = Some(prefix.into());
        self
    }

    pub fn suffix(mut self, suffix: impl Into<String>) -> Self {
        self.suffix = Some(suffix.into());
        self
    }

    pub fn color(mut self, color: impl Into<String>) -> Self {
        self.color = Some(color.into());
        self
    }

    pub fn friendly_fire(mut self, allow: bool) -> Self {
        self.friendly_fire = allow;
        self
    }

    pub fn add_entry(mut self, entry: impl Into<String>) -> Self {
        self.entries.push(entry.into());
        self
    }
}
