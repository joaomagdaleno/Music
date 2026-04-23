use rusqlite::{params, Connection};

pub struct DbTrack {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: Option<String>,
    pub local_path: String,
}

pub struct LearningRule {
    pub artist: Option<String>,
    pub field: String,
    pub original_value: String,
    pub corrected_value: String,
}

/// Inicializa o banco de dados com todas as tabelas necessárias e FTS5.
pub fn init_db(db_path: String) -> Result<(), String> {
    let conn = Connection::open(db_path).map_err(|e| e.to_string())?;

    // Tabela de Trilhas
    conn.execute(
        "CREATE TABLE IF NOT EXISTS tracks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            album TEXT,
            local_path TEXT NOT NULL
        )",
        [],
    )
    .map_err(|e| e.to_string())?;

    // Tabela Virtual de Busca (FTS5)
    conn.execute(
        "CREATE VIRTUAL TABLE IF NOT EXISTS tracks_fts USING fts5(
            title, artist, album, content='tracks', content_rowid='id'
        )",
        [],
    )
    .map_err(|e| e.to_string())?;

    // Gatilhos para manter o FTS sincronizado
    conn.execute_batch("
        CREATE TRIGGER IF NOT EXISTS tracks_ai AFTER INSERT ON tracks BEGIN
          INSERT INTO tracks_fts(rowid, title, artist, album) VALUES (new.rowid, new.title, new.artist, new.album);
        END;
        CREATE TRIGGER IF NOT EXISTS tracks_ad AFTER DELETE ON tracks BEGIN
          INSERT INTO tracks_fts(tracks_fts, rowid, title, artist, album) VALUES('delete', old.rowid, old.title, old.artist, old.album);
        END;
        CREATE TRIGGER IF NOT EXISTS tracks_au AFTER UPDATE ON tracks BEGIN
          INSERT INTO tracks_fts(tracks_fts, rowid, title, artist, album) VALUES('delete', old.rowid, old.title, old.artist, old.album);
          INSERT INTO tracks_fts(rowid, title, artist, album) VALUES (new.rowid, new.title, new.artist, new.album);
        END;
    ").ok();

    // Tabela de Regras de Aprendizado
    conn.execute(
        "CREATE TABLE IF NOT EXISTS learning_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            artist TEXT,
            field TEXT NOT NULL,
            original_value TEXT NOT NULL,
            corrected_value TEXT NOT NULL
        )",
        [],
    )
    .map_err(|e| e.to_string())?;

    Ok(())
}

pub fn search_tracks(db_path: String, query: String) -> Result<Vec<DbTrack>, String> {
    let conn = Connection::open(db_path).map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare(
            "SELECT id, title, artist, album, local_path FROM tracks 
         WHERE id IN (SELECT rowid FROM tracks_fts WHERE tracks_fts MATCH ?1)",
        )
        .map_err(|e| e.to_string())?;

    let track_iter = stmt
        .query_map([query], |row| {
            Ok(DbTrack {
                id: row.get(0)?,
                title: row.get(1)?,
                artist: row.get(2)?,
                album: row.get(3)?,
                local_path: row.get(4)?,
            })
        })
        .map_err(|e| e.to_string())?;

    let mut tracks = Vec::new();
    for track in track_iter {
        tracks.push(track.map_err(|e| e.to_string())?);
    }
    Ok(tracks)
}

pub fn save_track(db_path: String, track: DbTrack) -> Result<(), String> {
    let conn = Connection::open(db_path).map_err(|e| e.to_string())?;
    conn.execute(
        "INSERT OR REPLACE INTO tracks (id, title, artist, album, local_path)
         VALUES (?1, ?2, ?3, ?4, ?5)",
        params![
            track.id,
            track.title,
            track.artist,
            track.album,
            track.local_path
        ],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn get_all_tracks(db_path: String) -> Result<Vec<DbTrack>, String> {
    let conn = Connection::open(db_path).map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT id, title, artist, album, local_path FROM tracks")
        .map_err(|e| e.to_string())?;

    let track_iter = stmt
        .query_map([], |row| {
            Ok(DbTrack {
                id: row.get(0)?,
                title: row.get(1)?,
                artist: row.get(2)?,
                album: row.get(3)?,
                local_path: row.get(4)?,
            })
        })
        .map_err(|e| e.to_string())?;

    let mut tracks = Vec::new();
    for track in track_iter {
        tracks.push(track.map_err(|e| e.to_string())?);
    }
    Ok(tracks)
}

pub fn save_learning_rule(db_path: String, rule: LearningRule) -> Result<(), String> {
    let conn = Connection::open(db_path).map_err(|e| e.to_string())?;
    conn.execute(
        "INSERT INTO learning_rules (artist, field, original_value, corrected_value)
         VALUES (?1, ?2, ?3, ?4)",
        params![
            rule.artist,
            rule.field,
            rule.original_value,
            rule.corrected_value
        ],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn get_learning_rules(db_path: String) -> Result<Vec<LearningRule>, String> {
    let conn = Connection::open(db_path).map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT artist, field, original_value, corrected_value FROM learning_rules")
        .map_err(|e| e.to_string())?;

    let rule_iter = stmt
        .query_map([], |row| {
            Ok(LearningRule {
                artist: row.get(0)?,
                field: row.get(1)?,
                original_value: row.get(2)?,
                corrected_value: row.get(3)?,
            })
        })
        .map_err(|e| e.to_string())?;

    let mut rules = Vec::new();
    for rule in rule_iter {
        rules.push(rule.map_err(|e| e.to_string())?);
    }
    Ok(rules)
}
