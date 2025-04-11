use std::path::PathBuf;
use serde::{Serialize, Deserialize};
use tokio::fs;
use std::process::Command;
use std::io::{BufReader, BufRead};
use std::sync::{Arc, Mutex};
use tokio::sync::mpsc;

#[derive(Debug, Serialize, Deserialize)]
pub struct JavaInfo {
    pub version: String,
    pub path: PathBuf,
    pub vendor: String,
    pub is_64bit: bool,
    pub heap_size: u64,
}

pub struct SystemUtils {
    java_versions: Arc<Mutex<Vec<JavaInfo>>>,
}

impl SystemUtils {
    pub fn new() -> Self {
        SystemUtils {
            java_versions: Arc::new(Mutex::new(Vec::new())),
        }
    }

    pub async fn find_java_installations(&self) -> Result<Vec<JavaInfo>, String> {
        let mut java_versions = Vec::new();

        // Check common Java installation paths
        let paths = vec![
            PathBuf::from("C:\\Program Files\\Java"),
            PathBuf::from("C:\\Program Files (x86)\\Java"),
            PathBuf::from("/usr/lib/jvm"),
            PathBuf::from("/Library/Java/JavaVirtualMachines"),
        ];

        for base_path in paths {
            if base_path.exists() {
                let mut dir = fs::read_dir(&base_path)
                    .await
                    .map_err(|e| e.to_string())?;

                while let Some(entry) = dir.next_entry().await.map_err(|e| e.to_string())? {
                    let path = entry.path();
                    if path.is_dir() {
                        if let Some(java_info) = Self::check_java_installation(&path).await {
                            java_versions.push(java_info);
                        }
                    }
                }
            }
        }

        // Check PATH
        if let Ok(output) = Command::new("java")
            .arg("-version")
            .output()
        {
            if let Some(java_info) = Self::parse_java_version(&output.stderr).await {
                java_versions.push(java_info);
            }
        }

        let mut versions = self.java_versions.lock().unwrap();
        *versions = java_versions.clone();

        Ok(java_versions)
    }

    async fn check_java_installation(path: &PathBuf) -> Option<JavaInfo> {
        let java_path = path.join("bin").join("java");
        if !java_path.exists() {
            return None;
        }

        if let Ok(output) = Command::new(&java_path)
            .arg("-version")
            .output()
        {
            Self::parse_java_version(&output.stderr).await
        } else {
            None
        }
    }

    async fn parse_java_version(output: &[u8]) -> Option<JavaInfo> {
        let output = String::from_utf8_lossy(output);
        let mut version = None;
        let mut vendor = None;
        let mut is_64bit = false;

        for line in output.lines() {
            if line.contains("version") {
                version = line.split('"').nth(1).map(|s| s.to_string());
            }
            if line.contains("Java(TM)") {
                vendor = Some("Oracle".to_string());
            } else if line.contains("OpenJDK") {
                vendor = Some("OpenJDK".to_string());
            }
            if line.contains("64-Bit") {
                is_64bit = true;
            }
        }

        if let (Some(version), Some(vendor)) = (version, vendor) {
            Some(JavaInfo {
                version,
                path: PathBuf::from("java"), // This will be updated with actual path
                vendor,
                is_64bit,
                heap_size: 0, // This will be calculated
            })
        } else {
            None
        }
    }

    pub async fn get_system_info() -> Result<SystemInfo, String> {
        let mut info = SystemInfo::new();

        // Get CPU info
        if let Ok(output) = Command::new("wmic")
            .args(&["cpu", "get", "name"])
            .output()
        {
            let output = String::from_utf8_lossy(&output.stdout);
            info.cpu = output.lines()
                .nth(1)
                .map(|s| s.trim().to_string())
                .unwrap_or_default();
        }

        // Get memory info
        if let Ok(output) = Command::new("wmic")
            .args(&["memorychip", "get", "capacity"])
            .output()
        {
            let output = String::from_utf8_lossy(&output.stdout);
            let total_memory: u64 = output.lines()
                .skip(1)
                .filter_map(|s| s.trim().parse::<u64>().ok())
                .sum();
            info.total_memory = total_memory / (1024 * 1024 * 1024); // Convert to GB
        }

        // Get OS info
        if let Ok(output) = Command::new("systeminfo")
            .output()
        {
            let output = String::from_utf8_lossy(&output.stdout);
            for line in output.lines() {
                if line.contains("OS Name") {
                    info.os = line.split(":").nth(1)
                        .map(|s| s.trim().to_string())
                        .unwrap_or_default();
                }
            }
        }

        Ok(info)
    }

    pub async fn check_port_availability(port: u16) -> bool {
        use std::net::TcpListener;
        TcpListener::bind(("127.0.0.1", port)).is_ok()
    }

    pub async fn find_available_port(start_port: u16) -> Option<u16> {
        for port in start_port..65535 {
            if Self::check_port_availability(port).await {
                return Some(port);
            }
        }
        None
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SystemInfo {
    pub cpu: String,
    pub total_memory: u64,
    pub os: String,
}

impl SystemInfo {
    pub fn new() -> Self {
        SystemInfo {
            cpu: String::new(),
            total_memory: 0,
            os: String::new(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_system_utils() {
        let utils = SystemUtils::new();
        assert!(utils.find_java_installations().await.is_ok());
        
        let system_info = SystemUtils::get_system_info().await.unwrap();
        assert!(!system_info.cpu.is_empty());
        assert!(system_info.total_memory > 0);
        assert!(!system_info.os.is_empty());
        
        assert!(SystemUtils::check_port_availability(25565).await);
    }
} 