// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;

use commands::server::*;
use commands::java::*;

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            create_server,
            start_server,
            stop_server,
            get_server_status,
            get_server_list,
            delete_server,
            check_java_installation,
            get_java_version
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
