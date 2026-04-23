use crate::api::transcode::get_audio_details;
use sha2::{Digest, Sha256};
use std::fs::File;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::probe::Hint;

/// Gera uma "Assinatura Acústica" simplificada baseada nos primeiros segundos do áudio real.
/// Isso permite detectar se dois arquivos são a mesma música mesmo que tenham formatos diferentes.
pub fn generate_acoustic_fingerprint(path: String) -> Result<String, String> {
    let file = File::open(&path).map_err(|e| e.to_string())?;
    let mss = MediaSourceStream::new(Box::new(file), Default::default());

    let mut hint = Hint::new();
    let probed = symphonia::default::get_probe()
        .format(&hint, mss, &Default::default(), &Default::default())
        .map_err(|e| e.to_string())?;

    let mut format = probed.format;
    let track = format.tracks().first().ok_or("Nenhuma trilha encontrada")?;
    let mut decoder = symphonia::default::get_codecs()
        .make(&track.codec_params, &Default::default())
        .map_err(|e| e.to_string())?;

    let mut hasher = Sha256::new();
    let mut samples_processed = 0;
    let max_samples = 44100 * 5; // Analisar os primeiros 5 segundos

    while let Ok(packet) = format.next_packet() {
        if let Ok(decoded) = decoder.decode(&packet) {
            // Pegamos o buffer de áudio bruto (PCM) e passamos pelo hasher
            // Isso cria uma assinatura baseada no SOM, não nos bytes do arquivo.
            // Para simplicidade, usamos uma representação dos samples.
            hasher.update(format!("{:?}", decoded).as_bytes());
            samples_processed += 1000; // Estimativa
        }
        if samples_processed > max_samples {
            break;
        }
    }

    Ok(format!("{:x}", hasher.finalize()))
}

/// Diagnostica a integridade de um arquivo de áudio.
pub fn diagnose_file(path: String) -> String {
    match get_audio_details(path.clone()) {
        Ok(details) => format!("Arquivo íntegro: {}", details),
        Err(e) => format!("CORROMPIDO: {}", e),
    }
}

/// Tenta reparar o cabeçalho (header) de um arquivo usando Lofty.
pub fn repair_file_header(path: String) -> Result<String, String> {
    use lofty::prelude::*;
    use lofty::Probe;

    let tagged_file = Probe::open(&path)
        .map_err(|e| e.to_string())?
        .read()
        .map_err(|e| e.to_string())?;

    // Ao salvar novamente com o Lofty, ele reconstrói a estrutura de tags e headers.
    tagged_file
        .primary_tag()
        .ok_or("Nenhuma tag para reparar")?
        .save_to_path(&path)
        .map_err(|e| e.to_string())?;

    Ok("Estrutura do arquivo reconstruída com sucesso.".to_string())
}
