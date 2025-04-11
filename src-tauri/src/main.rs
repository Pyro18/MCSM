// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::Manager;
use std::sync::Arc;
use tokio::sync::Mutex;

mod server;
mod console;
mod players;
mod config;
mod plugins;
mod worlds;
mod monitoring;
mod security;
mod advanced;
mod utils;

use server::MinecraftServer;
use config::ServerConfig;
use monitoring::PerformanceMonitor;
use security::SecurityManager;
use advanced::AdvancedManager;

struct AppState {
    server: Arc<Mutex<Option<MinecraftServer>>>,
    monitor: Arc<Mutex<Option<PerformanceMonitor>>>,
    security: Arc<Mutex<Option<SecurityManager>>>,
    advanced: Arc<Mutex<Option<AdvancedManager>>>,
}

#[tauri::command]
async fn start_server(state: tauri::State<'_, AppState>, config: ServerConfig) -> Result<(), String> {
    let server = MinecraftServer::new(config);
    let mut state_server = state.server.lock().await;
    *state_server = Some(server);
    Ok(())
}

#[tauri::command]
async fn stop_server(state: tauri::State<'_, AppState>) -> Result<(), String> {
    let mut state_server = state.server.lock().await;
    if let Some(server) = state_server.as_ref() {
        server.stop()?;
    }
    *state_server = None;
    Ok(())
}

#[tauri::command]
async fn get_server_status(state: tauri::State<'_, AppState>) -> Result<server::ServerStatus, String> {
    let state_server = state.server.lock().await;
    if let Some(server) = state_server.as_ref() {
        Ok(server.get_status())
    } else {
        Ok(server::ServerStatus {
            is_running: false,
            players_online: 0,
            tps: 0.0,
            memory_usage: 0.0,
            cpu_usage: 0.0,
        })
    }
}

fn main() {
    tauri::Builder::default()
        .manage(AppState {
            server: Arc::new(Mutex::new(None)),
            monitor: Arc::new(Mutex::new(None)),
            security: Arc::new(Mutex::new(None)),
            advanced: Arc::new(Mutex::new(None)),
        })
        .invoke_handler(tauri::generate_handler![
            start_server,
            stop_server,
            get_server_status,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
