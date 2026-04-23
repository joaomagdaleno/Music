use flutter_rust_bridge::StreamSink;
use notify::{RecursiveMode, Watcher};
use std::path::Path;

/// Inicia o monitoramento de uma pasta. Envia o caminho dos arquivos alterados via Stream.
pub fn start_watcher(folder_path: String, sink: StreamSink<String>) -> Result<(), String> {
    let mut watcher = notify::recommended_watcher(move |res: notify::Result<notify::Event>| {
        match res {
            Ok(event) => {
                // Notifica o Flutter sobre cada caminho alterado
                for path in event.paths {
                    if let Some(path_str) = path.to_str() {
                        sink.add(path_str.to_string()).ok();
                    }
                }
            }
            Err(e) => println!("Erro no monitor: {:?}", e),
        }
    })
    .map_err(|e| e.to_string())?;

    watcher
        .watch(Path::new(&folder_path), RecursiveMode::Recursive)
        .map_err(|e| e.to_string())?;

    // IMPORTANTE: Em uma implementação de produção, o Watcher deve ser guardado
    // em uma variável global ou retornado para não ser dropado.
    // Para este motor, o FRB manterá a função ativa enquanto o StreamSink estiver aberto.
    std::mem::forget(watcher);

    Ok(())
}
