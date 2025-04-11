use std::path::PathBuf;
use std::process::{Child, Command};
use std::sync::{Arc, Mutex};
use tokio::fs;
use serde::{Serialize, Deserialize};
use crate::{ServerConfig, ServerType, MemoryConfig};

#[derive(Debug)]
pub struct MinecraftServer {
    config: ServerConfig,
    process: Arc<Mutex<Option<Child>>>,
    status: Arc<Mutex<ServerStatus>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerStatus {
    pub is_running: bool,
    pub players_online: u32,
    pub tps: f32,
    pub memory_usage: f32,
    pub cpu_usage: f32,
}

impl MinecraftServer {
    pub fn new(config: ServerConfig) -> Self {
        MinecraftServer {
            config,
            process: Arc::new(Mutex::new(None)),
            status: Arc::new(Mutex::new(ServerStatus {
                is_running: false,
                players_online: 0,
                tps: 20.0,
                memory_usage: 0.0,
                cpu_usage: 0.0,
            })),
        }
    }

    pub async fn start(&self) -> Result<(), String> {
        let mut process = self.process.lock().unwrap();
        if process.is_some() {
            return Err("Server is already running".to_string());
        }

        let java_path = self.find_java().await?;
        let server_jar = self.config.path.join("server.jar");

        if !server_jar.exists() {
            return Err("Server jar not found".to_string());
        }

        let mut command = Command::new(java_path);
        command
            .arg(format!("-Xms{}M", self.config.memory.min_mb))
            .arg(format!("-Xmx{}M", self.config.memory.max_mb))
            .arg("-jar")
            .arg(server_jar)
            .arg("nogui")
            .current_dir(&self.config.path);

        match command.spawn() {
            Ok(child) => {
                *process = Some(child);
                let mut status = self.status.lock().unwrap();
                status.is_running = true;
                Ok(())
            }
            Err(e) => Err(format!("Failed to start server: {}", e)),
        }
    }

    pub fn stop(&self) -> Result<(), String> {
        let mut process = self.process.lock().unwrap();
        if let Some(mut child) = process.take() {
            if let Err(e) = child.kill() {
                return Err(format!("Failed to stop server: {}", e));
            }
            let mut status = self.status.lock().unwrap();
            status.is_running = false;
            Ok(())
        } else {
            Err("Server is not running".to_string())
        }
    }

    pub fn restart(&self) -> Result<(), String> {
        self.stop()?;
        // TODO: Add delay to ensure server is fully stopped
        self.start()
    }

    async fn find_java(&self) -> Result<PathBuf, String> {
        // TODO: Implement Java detection logic
        Ok(PathBuf::from("java"))
    }

    pub async fn download_server(&self, version: &str, server_type: ServerType) -> Result<(), String> {
        // TODO: Implement server download logic
        Ok(())
    }

    pub fn get_status(&self) -> ServerStatus {
        self.status.lock().unwrap().clone()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_server_creation() {
        let config = ServerConfig {
            name: "Test Server".to_string(),
            version: "1.20.4".to_string(),
            server_type: ServerType::Vanilla,
            path: PathBuf::from("test_server"),
            memory: MemoryConfig {
                min_mb: 1024,
                max_mb: 2048,
            },
            port: 25565,
        };

        let server = MinecraftServer::new(config);
        assert!(!server.get_status().is_running);
    }
} 