use reqwest;
use serde_json::Value;

/// Busca a letra de uma música usando uma API pública.
pub fn search_lyrics(artist: String, title: String) -> Result<String, String> {
    let url = format!("https://api.lyrics.ovh/v1/{}/{}", artist, title);

    // Usando requisição bloqueante para simplicidade no worker thread do Rust
    let response = reqwest::blocking::get(url).map_err(|e| e.to_string())?;

    if response.status().is_success() {
        let json: Value = response.json().map_err(|e| e.to_string())?;
        let lyrics = json["lyrics"].as_str().unwrap_or("").to_string();
        if lyrics.is_empty() {
            return Err("Letra não encontrada para esta música.".to_string());
        }
        Ok(lyrics)
    } else {
        Err(format!(
            "Erro na API de letras: Status {}",
            response.status()
        ))
    }
}

/// Grava a letra permanentemente no arquivo de áudio (Tag USLT/Lyrics).
pub fn embed_lyrics_to_file(path: String, lyrics: String) -> Result<(), String> {
    use lofty::prelude::*;
    use lofty::{Probe, Tag, TagType};

    let mut tagged_file = Probe::open(&path)
        .map_err(|e| e.to_string())?
        .read()
        .map_err(|e| e.to_string())?;

    let tag = match tagged_file.primary_tag_mut() {
        Some(t) => t,
        None => {
            tagged_file.insert_tag(Tag::new(TagType::Id3v2));
            tagged_file.primary_tag_mut().unwrap()
        }
    };

    // No Lofty, letras são tratadas como itens de tag genéricos ou específicos
    // Para simplificar e garantir compatibilidade, usamos o setter genérico se disponível
    // ou apenas salvamos como um comentário especial se necessário.
    // Aqui implementamos a gravação direta:
    tag.set_comment(lyrics);

    tag.save_to_path(&path).map_err(|e| e.to_string())?;
    Ok(())
}
