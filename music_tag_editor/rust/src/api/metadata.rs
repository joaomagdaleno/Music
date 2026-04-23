use lofty::prelude::*;
use lofty::{Probe, Tag, TagType};
use rayon::prelude::*;
use std::path::Path;

#[derive(Debug, Clone)]
pub struct AudioMetadata {
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub year: Option<u32>,
    pub track_number: Option<u32>,
    pub genre: Option<String>,
    pub duration_ms: u32,
    pub file_path: String,
}

pub fn read_metadata(path: String) -> Result<AudioMetadata, String> {
    let tagged_file = Probe::open(&path)
        .map_err(|e| e.to_string())?
        .read()
        .map_err(|e| e.to_string())?;

    let tag = tagged_file
        .primary_tag()
        .or_else(|| tagged_file.first_tag());
    let properties = tagged_file.properties();

    Ok(AudioMetadata {
        title: tag.and_then(|t| t.title().map(|s| s.to_string())),
        artist: tag.and_then(|t| t.artist().map(|s| s.to_string())),
        album: tag.and_then(|t| t.album().map(|s| s.to_string())),
        year: tag.and_then(|t| t.year()),
        track_number: tag.and_then(|t| t.track()),
        genre: tag.and_then(|t| t.genre().map(|s| s.to_string())),
        duration_ms: properties.duration().as_millis() as u32,
        file_path: path,
    })
}

pub fn read_metadata_batch(paths: Vec<String>) -> Vec<Result<AudioMetadata, String>> {
    paths.into_par_iter().map(read_metadata).collect()
}

pub fn write_metadata(path: String, metadata: AudioMetadata) -> Result<(), String> {
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

    if let Some(t) = metadata.title {
        tag.set_title(t);
    }
    if let Some(a) = metadata.artist {
        tag.set_artist(a);
    }
    if let Some(al) = metadata.album {
        tag.set_album(al);
    }
    if let Some(y) = metadata.year {
        tag.set_year(y);
    }
    if let Some(tr) = metadata.track_number {
        tag.set_track(tr);
    }
    if let Some(g) = metadata.genre {
        tag.set_genre(g);
    }

    tag.save_to_path(&path).map_err(|e| e.to_string())?;
    Ok(())
}

pub fn extract_cover_art(path: String) -> Option<Vec<u8>> {
    let tagged_file = Probe::open(&path).ok()?.read().ok()?;
    let tag = tagged_file
        .primary_tag()
        .or_else(|| tagged_file.first_tag())?;
    tag.pictures().first().map(|p| p.data().to_vec())
}

pub fn extract_and_optimize_cover(path: String, max_size: u32) -> Option<Vec<u8>> {
    let raw_data = extract_cover_art(path)?;
    let img = image::load_from_memory(&raw_data).ok()?;
    let resized = img.thumbnail(max_size, max_size);
    let mut buffer = std::io::Cursor::new(Vec::new());
    resized
        .write_to(&mut buffer, image::ImageFormat::Jpeg)
        .ok()?;
    Some(buffer.into_inner())
}
