use std::path::PathBuf;
use serde::{Serialize, Deserialize};
use std::collections::HashMap;
use tokio::fs;

#[derive(Debug, Serialize, Deserialize)]
pub struct Player {
    pub uuid: String,
    pub name: String,
    pub is_online: bool,
    pub is_op: bool,
    pub last_seen: String,
    pub playtime: u64,
    pub deaths: u32,
    pub kills: u32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PlayerList {
    players: HashMap<String, Player>,
    whitelist: Vec<String>,
    blacklist: Vec<String>,
    ops: Vec<String>,
}

impl PlayerList {
    pub fn new() -> Self {
        PlayerList {
            players: HashMap::new(),
            whitelist: Vec::new(),
            blacklist: Vec::new(),
            ops: Vec::new(),
        }
    }

    pub async fn load_from_files(&mut self, server_path: &PathBuf) -> Result<(), String> {
        let whitelist_path = server_path.join("whitelist.json");
        let ops_path = server_path.join("ops.json");
        let banned_players_path = server_path.join("banned-players.json");

        if whitelist_path.exists() {
            let whitelist_data = fs::read_to_string(&whitelist_path)
                .await
                .map_err(|e| e.to_string())?;
            let whitelist: Vec<WhitelistEntry> = serde_json::from_str(&whitelist_data)
                .map_err(|e| e.to_string())?;
            self.whitelist = whitelist.into_iter().map(|p| p.uuid).collect();
        }

        if ops_path.exists() {
            let ops_data = fs::read_to_string(&ops_path)
                .await
                .map_err(|e| e.to_string())?;
            let ops: Vec<OpEntry> = serde_json::from_str(&ops_data)
                .map_err(|e| e.to_string())?;
            self.ops = ops.into_iter().map(|p| p.uuid).collect();
        }

        if banned_players_path.exists() {
            let banned_data = fs::read_to_string(&banned_players_path)
                .await
                .map_err(|e| e.to_string())?;
            let banned: Vec<BannedPlayerEntry> = serde_json::from_str(&banned_data)
                .map_err(|e| e.to_string())?;
            self.blacklist = banned.into_iter().map(|p| p.uuid).collect();
        }

        Ok(())
    }

    pub fn add_player(&mut self, player: Player) {
        self.players.insert(player.uuid.clone(), player);
    }

    pub fn remove_player(&mut self, uuid: &str) {
        self.players.remove(uuid);
    }

    pub fn get_player(&self, uuid: &str) -> Option<&Player> {
        self.players.get(uuid)
    }

    pub fn get_all_players(&self) -> Vec<&Player> {
        self.players.values().collect()
    }

    pub fn get_online_players(&self) -> Vec<&Player> {
        self.players.values().filter(|p| p.is_online).collect()
    }

    pub fn add_to_whitelist(&mut self, uuid: String) {
        if !self.whitelist.contains(&uuid) {
            self.whitelist.push(uuid);
        }
    }

    pub fn remove_from_whitelist(&mut self, uuid: &str) {
        self.whitelist.retain(|u| u != uuid);
    }

    pub fn add_to_blacklist(&mut self, uuid: String) {
        if !self.blacklist.contains(&uuid) {
            self.blacklist.push(uuid);
        }
    }

    pub fn remove_from_blacklist(&mut self, uuid: &str) {
        self.blacklist.retain(|u| u != uuid);
    }

    pub fn add_op(&mut self, uuid: String) {
        if !self.ops.contains(&uuid) {
            self.ops.push(uuid);
        }
    }

    pub fn remove_op(&mut self, uuid: &str) {
        self.ops.retain(|u| u != uuid);
    }

    pub fn is_whitelisted(&self, uuid: &str) -> bool {
        self.whitelist.contains(&uuid.to_string())
    }

    pub fn is_banned(&self, uuid: &str) -> bool {
        self.blacklist.contains(&uuid.to_string())
    }

    pub fn is_op(&self, uuid: &str) -> bool {
        self.ops.contains(&uuid.to_string())
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct WhitelistEntry {
    uuid: String,
    name: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct OpEntry {
    uuid: String,
    name: String,
    level: u32,
    bypassesPlayerLimit: bool,
}

#[derive(Debug, Serialize, Deserialize)]
struct BannedPlayerEntry {
    uuid: String,
    name: String,
    created: String,
    source: String,
    expires: Option<String>,
    reason: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_player_management() {
        let mut player_list = PlayerList::new();
        
        let player = Player {
            uuid: "test-uuid".to_string(),
            name: "TestPlayer".to_string(),
            is_online: true,
            is_op: false,
            last_seen: "2024-01-01T00:00:00Z".to_string(),
            playtime: 3600,
            deaths: 0,
            kills: 0,
        };

        player_list.add_player(player);
        assert_eq!(player_list.get_player("test-uuid").unwrap().name, "TestPlayer");
        
        player_list.add_to_whitelist("test-uuid".to_string());
        assert!(player_list.is_whitelisted("test-uuid"));
        
        player_list.remove_from_whitelist("test-uuid");
        assert!(!player_list.is_whitelisted("test-uuid"));
    }
} 