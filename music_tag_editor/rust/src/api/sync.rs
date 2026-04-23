use crate::api::duplicates::generate_acoustic_fingerprint;
use crate::api::metadata::{read_metadata, write_metadata, AudioMetadata};

/// Sincroniza as tags de um arquivo "Mestre" para todos os outros arquivos que possuem o mesmo som.
pub fn sync_tags_across_formats(
    master_path: String,
    other_paths: Vec<String>,
) -> Result<String, String> {
    let master_metadata = read_metadata(master_path.clone()).map_err(|e| e.to_string())?;
    let master_fingerprint =
        generate_acoustic_fingerprint(master_path).map_err(|e| e.to_string())?;

    let mut synced_count = 0;

    for path in other_paths {
        if let Ok(fp) = generate_acoustic_fingerprint(path.clone()) {
            if fp == master_fingerprint {
                // É a mesma música! Sincronizar tags.
                let mut target_meta = master_metadata.clone();
                target_meta.file_path = path.clone();
                write_metadata(path, target_meta).ok();
                synced_count += 1;
            }
        }
    }

    Ok(format!(
        "Sincronização concluída: {} arquivos atualizados.",
        synced_count
    ))
}
