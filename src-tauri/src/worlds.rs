use std::path::PathBuf;
use serde::{Serialize, Deserialize};
use tokio::fs;
use std::collections::HashMap;
use zip::ZipArchive;
use std::io::Cursor;

#[derive(Debug, Serialize, Deserialize)]
pub struct World {
    pub name: String,
    pub path: PathBuf,
    pub size: u64,
    pub last_modified: String,
    pub seed: Option<i64>,
    pub difficulty: String,
    pub game_mode: String,
    pub spawn_x: i32,
    pub spawn_y: i32,
    pub spawn_z: i32,
    pub time: i64,
    pub weather: String,
    pub version: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct WorldManager {
    worlds: HashMap<String, World>,
    server_path: PathBuf,
}

impl WorldManager {
    pub fn new(server_path: &PathBuf) -> Self {
        WorldManager {
            worlds: HashMap::new(),
            server_path: server_path.clone(),
        }
    }

    pub async fn load_worlds(&mut self) -> Result<(), String> {
        let worlds_path = self.server_path.join("worlds");
        if !worlds_path.exists() {
            fs::create_dir_all(&worlds_path)
                .await
                .map_err(|e| e.to_string())?;
        }

        let mut dir = fs::read_dir(&worlds_path)
            .await
            .map_err(|e| e.to_string())?;

        while let Some(entry) = dir.next_entry().await.map_err(|e| e.to_string())? {
            let path = entry.path();
            if path.is_dir() {
                if let Ok(world) = self.load_world_info(&path).await {
                    self.worlds.insert(world.name.clone(), world);
                }
            }
        }

        Ok(())
    }

    async fn load_world_info(&self, path: &PathBuf) -> Result<World, String> {
        let metadata = fs::metadata(path)
            .await
            .map_err(|e| e.to_string())?;

        let level_dat = path.join("level.dat");
        let mut world = World {
            name: path.file_name().unwrap().to_str().unwrap().to_string(),
            path: path.clone(),
            size: metadata.len(),
            last_modified: chrono::Local::now().to_rfc3339(),
            seed: None,
            difficulty: "normal".to_string(),
            game_mode: "survival".to_string(),
            spawn_x: 0,
            spawn_y: 64,
            spawn_z: 0,
            time: 0,
            weather: "clear".to_string(),
            version: "1.20".to_string(),
        };

        if level_dat.exists() {
            // TODO: Implement NBT parsing for level.dat
        }

        Ok(world)
    }

    pub async fn create_world(&mut self, name: &str, seed: Option<i64>) -> Result<(), String> {
        let world_path = self.server_path.join("worlds").join(name);
        if world_path.exists() {
            return Err("World already exists".to_string());
        }

        fs::create_dir_all(&world_path)
            .await
            .map_err(|e| e.to_string())?;

        let world = World {
            name: name.to_string(),
            path: world_path.clone(),
            size: 0,
            last_modified: chrono::Local::now().to_rfc3339(),
            seed,
            difficulty: "normal".to_string(),
            game_mode: "survival".to_string(),
            spawn_x: 0,
            spawn_y: 64,
            spawn_z: 0,
            time: 0,
            weather: "clear".to_string(),
            version: "1.20".to_string(),
        };

        self.worlds.insert(name.to_string(), world);
        Ok(())
    }

    pub async fn delete_world(&mut self, name: &str) -> Result<(), String> {
        if let Some(world) = self.worlds.get(name) {
            fs::remove_dir_all(&world.path)
                .await
                .map_err(|e| e.to_string())?;
            self.worlds.remove(name);
        }
        Ok(())
    }

    pub async fn backup_world(&self, name: &str, backup_path: &PathBuf) -> Result<(), String> {
        if let Some(world) = self.worlds.get(name) {
            let backup_file = backup_path.join(format!("{}_{}.zip", name, chrono::Local::now().format("%Y%m%d_%H%M%S")));
            
            let mut zip = zip::ZipWriter::new(std::fs::File::create(&backup_file).map_err(|e| e.to_string())?);
            let options = zip::write::FileOptions::default();

            let mut paths = Vec::new();
            paths.push(world.path.clone());

            while let Some(path) = paths.pop() {
                let name = path.strip_prefix(&world.path).unwrap();
                
                if path.is_file() {
                    zip.start_file(name.to_str().unwrap(), options)
                        .map_err(|e| e.to_string())?;
                    let content = fs::read(&path).await.map_err(|e| e.to_string())?;
                    zip.write_all(&content).map_err(|e| e.to_string())?;
                } else if path.is_dir() {
                    zip.add_directory(name.to_str().unwrap(), options)
                        .map_err(|e| e.to_string())?;
                    
                    let mut dir = fs::read_dir(&path)
                        .await
                        .map_err(|e| e.to_string())?;
                    
                    while let Some(entry) = dir.next_entry().await.map_err(|e| e.to_string())? {
                        paths.push(entry.path());
                    }
                }
            }

            zip.finish().map_err(|e| e.to_string())?;
        }
        Ok(())
    }

    pub async fn restore_world(&mut self, backup_file: &PathBuf) -> Result<(), String> {
        let file = std::fs::File::open(backup_file).map_err(|e| e.to_string())?;
        let mut archive = ZipArchive::new(file).map_err(|e| e.to_string())?;

        let world_name = backup_file.file_stem()
            .unwrap()
            .to_str()
            .unwrap()
            .split('_')
            .next()
            .unwrap();

        let world_path = self.server_path.join("worlds").join(world_name);
        if world_path.exists() {
            fs::remove_dir_all(&world_path)
                .await
                .map_err(|e| e.to_string())?;
        }

        fs::create_dir_all(&world_path)
            .await
            .map_err(|e| e.to_string())?;

        for i in 0..archive.len() {
            let mut file = archive.by_index(i).map_err(|e| e.to_string())?;
            let outpath = world_path.join(file.name());

            if file.name().ends_with('/') {
                fs::create_dir_all(&outpath)
                    .await
                    .map_err(|e| e.to_string())?;
            } else {
                if let Some(p) = outpath.parent() {
                    if !p.exists() {
                        fs::create_dir_all(p)
                            .await
                            .map_err(|e| e.to_string())?;
                    }
                }

                let mut outfile = std::fs::File::create(&outpath).map_err(|e| e.to_string())?;
                std::io::copy(&mut file, &mut outfile).map_err(|e| e.to_string())?;
            }
        }

        self.load_worlds().await?;
        Ok(())
    }

    pub fn get_world(&self, name: &str) -> Option<&World> {
        self.worlds.get(name)
    }

    pub fn get_all_worlds(&self) -> Vec<&World> {
        self.worlds.values().collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_world_manager() {
        let server_path = PathBuf::from("test_server");
        let mut manager = WorldManager::new(&server_path);
        
        assert!(manager.load_worlds().await.is_ok());
        assert_eq!(manager.get_all_worlds().len(), 0);
        
        assert!(manager.create_world("test_world", Some(12345)).await.is_ok());
        assert_eq!(manager.get_all_worlds().len(), 1);
    }
} 