use lofty::{Accessor, AudioFile, Probe, Tag, TagExt, TaggedFileExt};
use std::path::Path;
use sha2::{Sha256, Digest};
use std::fs::File;
use std::io::{self, Read};
use walkdir::WalkDir;
use std::collections::HashMap;

pub struct AudioMetadata {
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub year: Option<u32>,
    pub genre: Option<String>,
    pub track_number: Option<u16>,
    pub duration_ms: u64,
}

/// Lê metadados de um arquivo usando a biblioteca Lofty.
pub fn read_metadata(path: String) -> Result<AudioMetadata, String> {
    let tagged_file = Probe::open(&path)
        .map_err(|e| e.to_string())?
        .read()
        .map_err(|e| e.to_string())?;

    let tag = tagged_file.primary_tag()
        .or_else(|| tagged_file.first_tag())
        .ok_or("Nenhuma tag encontrada no arquivo")?;

    let properties = tagged_file.properties();

    Ok(AudioMetadata {
        title: tag.title().map(|s| s.to_string()),
        artist: tag.artist().map(|s| s.to_string()),
        album: tag.album().map(|s| s.to_string()),
        year: tag.year(),
        genre: tag.genre().map(|s| s.to_string()),
        track_number: tag.track().map(|t| t as u16),
        duration_ms: properties.duration().as_millis() as u64,
    })
}

/// Grava metadados em um arquivo.
pub fn write_metadata(path: String, metadata: AudioMetadata) -> Result<(), String> {
    let mut tagged_file = Probe::open(&path)
        .map_err(|e| e.to_string())?
        .read()
        .map_err(|e| e.to_string())?;

    let tag = tagged_file.primary_tag_mut()
        .ok_or("Não foi possível acessar as tags para escrita")?;

    if let Some(title) = metadata.title { tag.set_title(title); }
    if let Some(artist) = metadata.artist { tag.set_artist(artist); }
    if let Some(album) = metadata.album { tag.set_album(album); }
    if let Some(year) = metadata.year { tag.set_year(year); }
    if let Some(genre) = metadata.genre { tag.set_genre(genre); }
    if let Some(track) = metadata.track_number { tag.set_track(track as u32); }

    tag.save_to_path(&path).map_err(|e| e.to_string())?;
    Ok(())
}

/// Calcula o hash SHA256 de um arquivo para detecção de duplicados.
pub fn calculate_file_hash(path: String) -> Result<String, String> {
    let mut file = File::open(path).map_err(|e| e.to_string())?;
    let mut hasher = Sha256::new();
    let mut buffer = [0; 8192];

    loop {
        let count = file.read(&mut buffer).map_err(|e| e.to_string())?;
        if count == 0 { break; }
        hasher.update(&buffer[..count]);
    }

    Ok(format!("{:x}", hasher.finalize()))
}

/// Encontra arquivos duplicados em uma pasta comparando hashes.
pub fn find_duplicates_in_folder(folder_path: String) -> Result<Vec<Vec<String>>, String> {
    let mut hashes: HashMap<String, Vec<String>> = HashMap::new();

    for entry in WalkDir::new(folder_path).into_iter().filter_map(|e| e.ok()) {
        if entry.file_type().is_file() {
            if let Ok(hash) = calculate_file_hash(entry.path().to_string_lossy().to_string()) {
                hashes.entry(hash).or_insert_with(Vec::new).push(entry.path().to_string_lossy().to_string());
            }
        }
    }

    // Retorna apenas os grupos que têm mais de um arquivo (duplicados)
    Ok(hashes.into_values().filter(|v| v.len() > 1).collect())
}
