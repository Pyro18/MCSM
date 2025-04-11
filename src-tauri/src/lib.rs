// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![greet])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

pub mod server;
pub mod console;
pub mod players;
pub mod config;
pub mod plugins;
pub mod worlds;
pub mod monitoring;
pub mod security;
pub mod advanced;
pub mod utils;

use serde::{Serialize, Deserialize};
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerConfig {
    pub name: String,
    pub version: String,
    pub server_type: ServerType,
    pub path: PathBuf,
    pub memory: MemoryConfig,
    pub port: u16,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum ServerType {
    Vanilla,
    Spigot,
    Paper,
    Forge,
    Fabric,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MemoryConfig {
    pub min_mb: u32,
    pub max_mb: u32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Player {
    pub uuid: String,
    pub name: String,
    pub is_online: bool,
    pub is_op: bool,
    pub last_seen: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerStatus {
    pub is_running: bool,
    pub players_online: u32,
    pub tps: f32,
    pub memory_usage: f32,
    pub cpu_usage: f32,
}

// Re-export dei moduli principali
pub use server::*;
pub use console::*;
pub use players::*;
pub use config::*;
pub use plugins::*;
pub use worlds::*;
pub use monitoring::*;
pub use security::*;
pub use advanced::*;
pub use utils::*;
