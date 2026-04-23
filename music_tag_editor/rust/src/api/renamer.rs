use crate::api::ast::evaluate_rule;
use crate::api::metadata::read_metadata;
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RenamePreview {
    pub original_path: String,
    pub new_name: String,
}

/// Gera um preview da renomeação e retorna como uma string JSON para o Dart.
pub fn get_rename_preview(paths: Vec<String>, rule: String) -> String {
    let previews: Vec<RenamePreview> = paths
        .into_par_iter()
        .map(|path| {
            let metadata = match read_metadata(path.clone()) {
                Ok(m) => m,
                Err(_) => {
                    return RenamePreview {
                        original_path: path,
                        new_name: "Erro ao ler metadados".to_string(),
                    }
                }
            };

            let new_name_raw = evaluate_rule(rule.clone(), metadata);
            let clean_name = new_name_raw.replace(
                |c: char| ['<', '>', ':', '\"', '/', '\\', '|', '?', '*'].contains(&c),
                "",
            );

            RenamePreview {
                original_path: path,
                new_name: format!("{}.mp3", clean_name),
            }
        })
        .collect();

    serde_json::to_string(&previews).unwrap_or_else(|_| "[]".to_string())
}

/// Executa a renomeação real a partir de uma lista de previews em JSON.
pub fn execute_rename_batch(json_previews: String) -> Result<String, String> {
    let previews: Vec<RenamePreview> =
        serde_json::from_str(&json_previews).map_err(|e| e.to_string())?;

    for preview in previews {
        let old_path = Path::new(&preview.original_path);
        if let Some(parent) = old_path.parent() {
            let new_path = parent.join(&preview.new_name);
            fs::rename(old_path, new_path).ok();
        }
    }
    Ok("Renomeação concluída!".to_string())
}
