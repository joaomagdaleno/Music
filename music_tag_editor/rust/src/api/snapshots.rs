use rusqlite::{params, Connection};
use serde_json;

/// Cria um snapshot (ponto de restauração) dos metadados de um arquivo.
pub fn create_metadata_snapshot(
    db_path: String,
    file_path: String,
    metadata_json: String,
) -> Result<(), String> {
    let conn = Connection::open(db_path).map_err(|e| e.to_string())?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT NOT NULL,
            metadata_blob TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )",
        [],
    )
    .map_err(|e| e.to_string())?;

    conn.execute(
        "INSERT INTO snapshots (file_path, metadata_blob) VALUES (?1, ?2)",
        params![file_path, metadata_json],
    )
    .map_err(|e| e.to_string())?;

    Ok(())
}

/// Recupera o histórico de versões de um arquivo.
pub fn get_file_history(db_path: String, file_path: String) -> Result<Vec<String>, String> {
    let conn = Connection::open(db_path).map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT metadata_blob FROM snapshots WHERE file_path = ?1 ORDER BY timestamp DESC")
        .map_err(|e| e.to_string())?;

    let rows = stmt
        .query_map([file_path], |row| row.get(0))
        .map_err(|e| e.to_string())?;

    let mut history = Vec::new();
    for row in rows {
        history.push(row.map_err(|e| e.to_string())?);
    }
    Ok(history)
}
