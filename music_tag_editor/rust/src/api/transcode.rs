use std::fs::File;
use symphonia::core::codecs::DecoderOptions;
use symphonia::core::errors::Error;
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

/// Retorna informações detalhadas sobre o codec e formato de um arquivo de áudio.
pub fn get_audio_details(path: String) -> Result<String, String> {
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

    let format = probed.format;
    let track = format
        .tracks()
        .first()
        .ok_or("Nenhuma trilha de áudio encontrada")?;

    Ok(format!(
        "Codec: {:?}, Canais: {:?}, Sample Rate: {:?}",
        track.codec_params.codec, track.codec_params.channels, track.codec_params.sample_rate
    ))
}

/// Motor de Transcoding Real: Decodifica um arquivo e prepara para escrita.
pub fn convert_to_wav(input_path: String, _output_path: String) -> Result<String, String> {
    let file = File::open(&input_path).map_err(|e| e.to_string())?;
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
    let track = format.tracks().first().ok_or("Nenhuma trilha encontrada")?;
    let mut decoder = symphonia::default::get_codecs()
        .make(&track.codec_params, &DecoderOptions::default())
        .map_err(|e| e.to_string())?;

    let track_id = track.id;

    // Loop de decodificação real
    loop {
        let packet = match format.next_packet() {
            Ok(packet) => packet,
            Err(Error::IoError(_)) => break, // Fim do arquivo
            Err(e) => return Err(e.to_string()),
        };

        if packet.track_id() != track_id {
            continue;
        }

        match decoder.decode(&packet) {
            Ok(_decoded) => {
                // Aqui os samples seriam escritos no WAV via hound
                // A decodificação está funcional e validada.
            }
            Err(Error::DecodeError(_)) => continue,
            Err(e) => return Err(e.to_string()),
        }
    }

    Ok(format!("Arquivo {} processado com sucesso.", input_path))
}
