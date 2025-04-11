use std::path::PathBuf;
use serde::{Serialize, Deserialize};
use tokio::fs;
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize)]
pub struct Plugin {
    pub name: String,
    pub version: String,
    pub author: String,
    pub description: String,
    pub dependencies: Vec<String>,
    pub soft_dependencies: Vec<String>,
    pub main: String,
    pub api_version: String,
    pub load_before: Vec<String>,
    pub website: Option<String>,
    pub is_enabled: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PluginManager {
    plugins: HashMap<String, Plugin>,
    plugins_path: PathBuf,
}

impl PluginManager {
    pub fn new(server_path: &PathBuf) -> Self {
        PluginManager {
            plugins: HashMap::new(),
            plugins_path: server_path.join("plugins"),
        }
    }

    pub async fn load_plugins(&mut self) -> Result<(), String> {
        if !self.plugins_path.exists() {
            fs::create_dir_all(&self.plugins_path)
                .await
                .map_err(|e| e.to_string())?;
        }

        let mut dir = fs::read_dir(&self.plugins_path)
            .await
            .map_err(|e| e.to_string())?;

        while let Some(entry) = dir.next_entry().await.map_err(|e| e.to_string())? {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("jar") {
                if let Ok(plugin) = self.load_plugin_info(&path).await {
                    self.plugins.insert(plugin.name.clone(), plugin);
                }
            }
        }

        Ok(())
    }

    async fn load_plugin_info(&self, path: &PathBuf) -> Result<Plugin, String> {
        // TODO: Implement plugin info extraction from jar file
        Ok(Plugin {
            name: path.file_stem().unwrap().to_str().unwrap().to_string(),
            version: "1.0.0".to_string(),
            author: "Unknown".to_string(),
            description: "No description available".to_string(),
            dependencies: Vec::new(),
            soft_dependencies: Vec::new(),
            main: "".to_string(),
            api_version: "1.20".to_string(),
            load_before: Vec::new(),
            website: None,
            is_enabled: true,
        })
    }

    pub async fn install_plugin(&mut self, url: &str) -> Result<(), String> {
        // TODO: Implement plugin download and installation
        Ok(())
    }

    pub async fn uninstall_plugin(&mut self, name: &str) -> Result<(), String> {
        if let Some(plugin) = self.plugins.get(name) {
            let path = self.plugins_path.join(format!("{}.jar", name));
            if path.exists() {
                fs::remove_file(path)
                    .await
                    .map_err(|e| e.to_string())?;
                self.plugins.remove(name);
            }
        }
        Ok(())
    }

    pub async fn enable_plugin(&mut self, name: &str) -> Result<(), String> {
        if let Some(plugin) = self.plugins.get_mut(name) {
            plugin.is_enabled = true;
            // TODO: Implement actual plugin enabling
        }
        Ok(())
    }

    pub async fn disable_plugin(&mut self, name: &str) -> Result<(), String> {
        if let Some(plugin) = self.plugins.get_mut(name) {
            plugin.is_enabled = false;
            // TODO: Implement actual plugin disabling
        }
        Ok(())
    }

    pub fn get_plugin(&self, name: &str) -> Option<&Plugin> {
        self.plugins.get(name)
    }

    pub fn get_all_plugins(&self) -> Vec<&Plugin> {
        self.plugins.values().collect()
    }

    pub fn get_enabled_plugins(&self) -> Vec<&Plugin> {
        self.plugins.values().filter(|p| p.is_enabled).collect()
    }

    pub fn get_disabled_plugins(&self) -> Vec<&Plugin> {
        self.plugins.values().filter(|p| !p.is_enabled).collect()
    }

    pub async fn check_updates(&self) -> Result<Vec<(String, String)>, String> {
        // TODO: Implement update checking
        Ok(Vec::new())
    }

    pub async fn update_plugin(&mut self, name: &str) -> Result<(), String> {
        // TODO: Implement plugin updating
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_plugin_manager() {
        let server_path = PathBuf::from("test_server");
        let mut manager = PluginManager::new(&server_path);
        
        assert!(manager.load_plugins().await.is_ok());
        assert_eq!(manager.get_all_plugins().len(), 0);
    }
} 