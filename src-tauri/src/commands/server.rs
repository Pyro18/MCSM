use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::process::{Command, Child};
use std::fs;
use tauri::Runtime;
use std::sync::Mutex;
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerConfig {
    pub name: String,
    pub version: String,
    pub port: u16,
    pub memory: String,
    pub path: PathBuf,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerStatus {
    pub running: bool,
    pub players: u32,
    pub cpu_usage: f32,
    pub memory_usage: u64,
}

// Store running server processes
lazy_static::lazy_static! {
    static ref RUNNING_SERVERS: Mutex<HashMap<PathBuf, Child>> = Mutex::new(HashMap::new());
}

#[tauri::command]
pub async fn create_server<R: Runtime>(
    _app: tauri::AppHandle<R>,
    config: ServerConfig,
) -> Result<String, String> {
    // Create server directory
    fs::create_dir_all(&config.path)
        .map_err(|e| format!("Failed to create server directory: {}", e))?;

    // Create server.properties file
    let server_properties = format!(
        "server-port={}\nmax-players=20\nonline-mode=true\n",
        config.port
    );
    fs::write(config.path.join("server.properties"), server_properties)
        .map_err(|e| format!("Failed to create server.properties: {}", e))?;

    // Create start script
    let start_script = if cfg!(target_os = "windows") {
        format!(
            "@echo off\njava -Xmx{} -jar server.jar nogui",
            config.memory
        )
    } else {
        format!(
            "#!/bin/bash\njava -Xmx{} -jar server.jar nogui",
            config.memory
        )
    };

    let script_path = config.path.join(if cfg!(target_os = "windows") {
        "start.bat"
    } else {
        "start.sh"
    });

    fs::write(&script_path, start_script)
        .map_err(|e| format!("Failed to create start script: {}", e))?;

    if !cfg!(target_os = "windows") {
        // Make the script executable on Unix-like systems
        Command::new("chmod")
            .arg("+x")
            .arg(&script_path)
            .output()
            .map_err(|e| format!("Failed to make script executable: {}", e))?;
    }

    Ok(format!("Server {} created successfully!", config.name))
}

#[tauri::command]
pub async fn start_server<R: Runtime>(
    _app: tauri::AppHandle<R>,
    server_path: PathBuf,
) -> Result<String, String> {
    let mut running_servers = RUNNING_SERVERS.lock()
        .map_err(|e| format!("Failed to lock running servers: {}", e))?;

    if running_servers.contains_key(&server_path) {
        return Err("Server is already running".to_string());
    }

    let start_script = server_path.join(if cfg!(target_os = "windows") {
        "start.bat"
    } else {
        "start.sh"
    });

    let child = Command::new(start_script)
        .current_dir(&server_path)
        .spawn()
        .map_err(|e| format!("Failed to start server: {}", e))?;

    running_servers.insert(server_path, child);
    Ok("Server started successfully!".to_string())
}

#[tauri::command]
pub async fn stop_server<R: Runtime>(
    _app: tauri::AppHandle<R>,
    server_path: PathBuf,
) -> Result<String, String> {
    let mut running_servers = RUNNING_SERVERS.lock()
        .map_err(|e| format!("Failed to lock running servers: {}", e))?;

    if let Some(mut child) = running_servers.remove(&server_path) {
        child.kill()
            .map_err(|e| format!("Failed to stop server: {}", e))?;
        Ok("Server stopped successfully!".to_string())
    } else {
        Err("Server is not running".to_string())
    }
}

#[tauri::command]
pub async fn get_server_status<R: Runtime>(
    _app: tauri::AppHandle<R>,
    server_path: PathBuf,
) -> Result<ServerStatus, String> {
    let running_servers = RUNNING_SERVERS.lock()
        .map_err(|e| format!("Failed to lock running servers: {}", e))?;

    let running = running_servers.contains_key(&server_path);
    
    // TODO: Implement actual CPU and memory usage monitoring
    Ok(ServerStatus {
        running,
        players: 0, // TODO: Implement player count monitoring
        cpu_usage: 0.0,
        memory_usage: 0,
    })
}

#[tauri::command]
pub async fn get_server_list<R: Runtime>(
    _app: tauri::AppHandle<R>,
) -> Result<Vec<ServerConfig>, String> {
    // TODO: Implement server list retrieval from configuration
    Ok(Vec::new())
}

#[tauri::command]
pub async fn delete_server<R: Runtime>(
    _app: tauri::AppHandle<R>,
    server_path: PathBuf,
) -> Result<String, String> {
    // First stop the server if it's running
    let _ = stop_server(_app.clone(), server_path.clone()).await;

    // Then remove the directory
    fs::remove_dir_all(&server_path)
        .map_err(|e| format!("Failed to delete server directory: {}", e))?;

    Ok("Server deleted successfully!".to_string())
} 