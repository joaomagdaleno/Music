use rustfft::{num_complex::Complex, FftPlanner};
use std::fs::File;
use symphonia::core::audio::SampleBuffer;
use symphonia::core::codecs::DecoderOptions;
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

#[derive(Debug, Clone)]
pub struct SpectralAnalysisResult {
    pub quality_status: String,
    pub is_fake_high_res: bool,
    pub frequency_magnitudes: Vec<f32>,
}

/// Analisa o espectro de frequências para detectar se um arquivo de alta resolução é "Fake" (Upscaled)
/// e retorna as magnitudes das frequências para renderização do espectrograma.
pub fn analyze_spectral_quality(path: String) -> Result<SpectralAnalysisResult, String> {
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

    let mut planner = FftPlanner::new();
    let fft_size = 2048;
    let fft = planner.plan_fft_forward(fft_size);

    let mut high_freq_energy = 0.0;
    let mut total_energy = 0.0;
    let mut aggregated_magnitudes: Vec<f32> = vec![0.0; fft_size / 2];
    let mut frames_processed = 0;

    // Analisar até 50 frames para ter uma boa média sem demorar muito
    for _ in 0..50 {
        match format.next_packet() {
            Ok(packet) => {
                match decoder.decode(&packet) {
                    Ok(decoded) => {
                        let mut sample_buf =
                            SampleBuffer::<f32>::new(decoded.capacity() as u64, *decoded.spec());
                        sample_buf.copy_interleaved_ref(decoded);

                        let samples = sample_buf.samples();
                        if samples.len() < fft_size {
                            continue;
                        }

                        let mut buffer: Vec<Complex<f32>> = samples
                            .iter()
                            .take(fft_size)
                            .map(|&s| Complex { re: s, im: 0.0 })
                            .collect();

                        fft.process(&mut buffer);

                        // Agregar magnitudes (apenas a primeira metade de Nyquist)
                        for (i, val) in buffer.iter().take(fft_size / 2).enumerate() {
                            let mag = val.norm();
                            aggregated_magnitudes[i] += mag;
                            total_energy += mag;

                            // Considerando que a taxa de amostragem costuma ser 44.1kHz, 
                            // a metade é ~22kHz. Índices acima de 80% (aprox 16kHz+) 
                            // são considerados "altas frequências" para detecção de MP3 vs FLAC.
                            if i > (fft_size / 2 * 4) / 5 {
                                high_freq_energy += mag;
                            }
                        }
                        frames_processed += 1;
                    }
                    Err(_) => continue,
                }
            }
            Err(_) => break,
        }
    }

    if frames_processed == 0 {
        return Err("Não foi possível processar frames de áudio suficientes".into());
    }

    // Normalizar as magnitudes para o Flutter (escala de 0.0 a 1.0)
    let max_mag = aggregated_magnitudes
        .iter()
        .cloned()
        .fold(0.0 / 0.0, f32::max); // f32::max com NaN fallback
    
    let normalized_magnitudes: Vec<f32> = aggregated_magnitudes
        .iter()
        .map(|&m| if max_mag > 0.0 { m / max_mag } else { 0.0 })
        .collect();

    let ratio = high_freq_energy / total_energy;
    
    // Limite heurístico: Se menos de 1% da energia está nas frequências > 16kHz,
    // provavelmente é um upsampled mp3 (cutoff do encoder).
    let is_fake_high_res = ratio < 0.01;
    let quality_status = if is_fake_high_res {
        "Qualidade Suspeita (Corte de Frequência / Possível Upscale)".to_string()
    } else {
        "Qualidade Alta (Espectro Completo)".to_string()
    };

    Ok(SpectralAnalysisResult {
        quality_status,
        is_fake_high_res,
        frequency_magnitudes: normalized_magnitudes,
    })
}
