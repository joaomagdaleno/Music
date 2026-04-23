use regex::Regex;

/// Limpa uma string de tag ou nome de arquivo usando regras pré-definidas.
pub fn clean_tag(text: String) -> String {
    let mut cleaned = text;

    // 1. Remover padrões de download comuns
    let patterns = [
        r"(?i)\[.*?\]",         // [HQ], [1080p], etc.
        r"(?i)\(official.*?\)", // (Official Video), (Official Audio)
        r"(?i)\(lyric.*?\)",    // (Lyric Video)
        r"(?i)\(audio.*?\)",    // (Audio Only)
        r"(?i)ft\..*?(\s|$)",   // ft. Artist
        r"(?i)feat\..*?(\s|$)", // feat. Artist
        r"(?i)video clipe",     // Video Clipe
        r"\.mp3$",              // .mp3 acidental
        r"\.flac$",             // .flac acidental
    ];

    for pattern in patterns {
        if let Ok(re) = Regex::new(pattern) {
            cleaned = re.replace_all(&cleaned, "").to_string();
        }
    }

    // 2. Normalização de caracteres e espaços
    cleaned = cleaned.replace("_", " ");
    cleaned = cleaned.replace("-", " ");

    if let Ok(re) = Regex::new(r"\s+") {
        cleaned = re.replace_all(&cleaned, " ").to_string();
    }

    cleaned.trim().to_string()
}
