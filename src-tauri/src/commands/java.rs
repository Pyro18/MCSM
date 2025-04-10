use std::process::Command;
use serde::{Deserialize, Serialize};
use tauri::Runtime;

#[derive(Debug, Serialize, Deserialize)]
pub struct JavaInfo {
    pub version: String,
    pub path: String,
    pub is_valid: bool,
}

#[tauri::command]
pub async fn check_java_installation<R: Runtime>(
    _app: tauri::AppHandle<R>,
) -> Result<Vec<JavaInfo>, String> {
    let mut java_installations = Vec::new();

    // Check JAVA_HOME environment variable
    if let Ok(java_home) = std::env::var("JAVA_HOME") {
        if let Some(info) = check_java_path(&java_home) {
            java_installations.push(info);
        }
    }

    // Check common Java installation paths
    let common_paths = if cfg!(target_os = "windows") {
        vec![
            "C:\\Program Files\\Java",
            "C:\\Program Files (x86)\\Java",
        ]
    } else {
        vec![
            "/usr/lib/jvm",
            "/usr/java",
            "/opt/java",
        ]
    };

    for path in common_paths {
        if let Ok(entries) = std::fs::read_dir(path) {
            for entry in entries.flatten() {
                if let Some(info) = check_java_path(entry.path().to_str().unwrap_or("")) {
                    java_installations.push(info);
                }
            }
        }
    }

    // Check PATH for java executable
    if let Ok(path) = std::env::var("PATH") {
        for dir in path.split(if cfg!(target_os = "windows") { ";" } else { ":" }) {
            let java_path = format!("{}/java", dir);
            if let Some(info) = check_java_path(&java_path) {
                java_installations.push(info);
            }
        }
    }

    Ok(java_installations)
}

fn check_java_path(path: &str) -> Option<JavaInfo> {
    let java_executable = if cfg!(target_os = "windows") {
        format!("{}/bin/java.exe", path)
    } else {
        format!("{}/bin/java", path)
    };

    if !std::path::Path::new(&java_executable).exists() {
        return None;
    }

    let output = Command::new(&java_executable)
        .arg("-version")
        .output();

    match output {
        Ok(output) => {
            let version_output = String::from_utf8_lossy(&output.stderr);
            let version = version_output
                .lines()
                .next()
                .unwrap_or("")
                .split('"')
                .nth(1)
                .unwrap_or("Unknown")
                .to_string();

            Some(JavaInfo {
                version,
                path: java_executable,
                is_valid: true,
            })
        }
        Err(_) => None,
    }
}

#[tauri::command]
pub async fn get_java_version<R: Runtime>(
    _app: tauri::AppHandle<R>,
    java_path: String,
) -> Result<String, String> {
    let output = Command::new(java_path)
        .arg("-version")
        .output()
        .map_err(|e| e.to_string())?;

    let version_output = String::from_utf8_lossy(&output.stderr);
    let version = version_output
        .lines()
        .next()
        .ok_or_else(|| "No version output".to_string())?
        .split('"')
        .nth(1)
        .ok_or_else(|| "Invalid version format".to_string())?
        .to_string();

    Ok(version)
} 