use sha2::{Sha256, Digest};
use std::fs::File;
use symphonia::core::audio::SampleBuffer;
use symphonia::core::codecs::DecoderOptions;
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

#[derive(Debug, Clone)]
pub struct AcousticFingerprint {
    pub hash: String,
    pub duration_seconds: f64,
}

/// Gera uma "impressão digital" (fingerprint) básica extraindo e hasheando 
/// as amostras de áudio brutas dos primeiros 10 segundos da música.
/// Isso permite identificar arquivos idênticos no som, mesmo que tenham metadados ou nomes diferentes.
pub fn generate_fingerprint(path: String) -> Result<AcousticFingerprint, String> {
    let file = File::open(&path).map_err(|e| e.to_string())?;
    let mss = MediaSourceStream::new(Box::new(file), Default::default());

    let mut hint = Hint::new();
    let probed = symphonia::default::get_probe()
        .format(
            &hint,
            mss,
            &FormatOptions::default(),
            &MetadataOptions::default(),
        )
        .map_err(|e| e.to_string())?;

    let mut format = probed.format;
    let track = format
        .tracks()
        .first()
        .ok_or("Trilha de áudio não encontrada")?;
    
    let mut decoder = symphonia::default::get_codecs()
        .make(&track.codec_params, &DecoderOptions::default())
        .map_err(|e| e.to_string())?;

    let mut hasher = Sha256::new();
    let mut total_duration = 0.0;
    
    // Ler aproximadamente 10 segundos de áudio para o fingerprint
    let target_frames = 100; 
    let mut frames_processed = 0;

    while frames_processed < target_frames {
        match format.next_packet() {
            Ok(packet) => {
                match decoder.decode(&packet) {
                    Ok(decoded) => {
                        let mut sample_buf =
                            SampleBuffer::<f32>::new(decoded.capacity() as u64, *decoded.spec());
                        sample_buf.copy_interleaved_ref(decoded);

                        let samples = sample_buf.samples();
                        for &sample in samples {
                            // Converter f32 para bytes e alimentar o hasher
                            hasher.update(sample.to_le_bytes());
                        }
                        
                        frames_processed += 1;
                    }
                    Err(_) => continue,
                }
            }
            Err(_) => break, // Fim do arquivo ou erro
        }
    }

    if frames_processed == 0 {
        return Err("Não foi possível decodificar o áudio para o fingerprint".into());
    }

    // Calcular duração total (para verificação secundária)
    if let Some(tb) = track.codec_params.time_base {
        if let Some(ts) = track.codec_params.n_frames {
            total_duration = tb.calc_time(ts).seconds as f64 + tb.calc_time(ts).frac;
        }
    }

    let hash_result = hasher.finalize();
    let hash_hex = format!("{:x}", hash_result);

    Ok(AcousticFingerprint {
        hash: hash_hex,
        duration_seconds: total_duration,
    })
}
