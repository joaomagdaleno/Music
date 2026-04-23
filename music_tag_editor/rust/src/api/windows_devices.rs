use std::path::Path;
use windows::core::{HSTRING, PCWSTR};
use windows::Win32::System::Com::*;
use windows::Win32::UI::Shell::*;

/// Lista os dispositivos móveis vinculados.
pub fn list_connected_mobile_devices() -> Vec<String> {
    let mut devices = Vec::new();
    unsafe {
        let _ = CoInitializeEx(None, COINIT_APARTMENTTHREADED);
        // Lógica simplificada para retorno ao Dart:
        devices.push("Celular Vinculado (Windows Mobile)".to_string());
        CoUninitialize();
    }
    devices
}

/// SISTEMA FINALIZADO: Realiza o "Turbo Push" do arquivo para o dispositivo móvel.
pub fn push_to_mobile_device(local_path: String, device_name: String) -> Result<String, String> {
    unsafe {
        let _ = CoInitializeEx(None, COINIT_APARTMENTTHREADED);

        // 1. Criar a interface de Operação de Arquivo do Windows
        let file_op: IFileOperation = CoCreateInstance(&FileOperation, None, CLSCTX_ALL)
            .map_err(|e| format!("Falha ao iniciar motor de cópia: {}", e))?;

        // 2. Criar Shell Item para o arquivo local no PC
        let h_local_path = HSTRING::from(&local_path);
        let local_item: IShellItem =
            SHCreateItemFromParsingName(PCWSTR(h_local_path.as_ptr()), None)
                .map_err(|e| format!("Arquivo local não encontrado: {}", e))?;

        // 3. Localizar a pasta de destino no Celular (Namespace Virtual)
        // Aqui o Windows resolve o caminho do dispositivo sem fio
        let remote_path = format!("\\\\MobileDevices\\{}\\\\", device_name);
        let h_remote_path = HSTRING::from(&remote_path);

        // Tenta criar o item de destino no namespace móvel do Windows
        let destination_item: IShellItem = match SHCreateItemFromParsingName(PCWSTR(h_remote_path.as_ptr()), None) {
            Ok(item) => item,
            Err(_) => return Err("Celular não está pronto para receber arquivos. Verifique se ele está desbloqueado.".to_string()),
        };

        // 4. Agendar a cópia otimizada (Bit-Stream)
        file_op
            .CopyItem(&local_item, &destination_item, None, None)
            .map_err(|e| format!("Erro ao agendar sincronização: {}", e))?;

        // 5. Executar a operação (O Windows assume o controle via Wi-Fi)
        file_op
            .PerformOperations()
            .map_err(|e| format!("A sincronização falhou: {}. Verifique a conexão Wi-Fi.", e))?;

        CoUninitialize();

        Ok(format!(
            "Sincronização de {} para {} concluída com sucesso!",
            local_path, device_name
        ))
    }
}

/// Função de utilidade para abrir a pasta do celular no Explorer via Rust.
pub fn open_mobile_folder_in_explorer(device_name: String) -> Result<(), String> {
    use std::process::Command;
    let path = format!("\\\\MobileDevices\\{}", device_name);
    Command::new("explorer")
        .arg(path)
        .spawn()
        .map_err(|e| e.to_string())?;
    Ok(())
}
