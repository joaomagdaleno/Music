use std::process::Command;

/// Registra o aplicativo no menu de contexto do Windows Explorer (Botão Direito).
pub fn register_shell_extension(exe_path: String) -> Result<String, String> {
    // 1. Criar a chave no registro para arquivos de áudio
    // HKEY_CLASSES_ROOT\SystemFileAssociations\.mp3\shell\MusicEditor
    let status = Command::new("reg")
        .args(&["add", "HKEY_CURRENT_USER\\Software\\Classes\\SystemFileAssociations\\.mp3\\shell\\MusicEditor", "/ve", "/d", "Editar com Music Editor", "/f"])
        .status()
        .map_err(|e| e.to_string())?;

    if !status.success() {
        return Err("Falha ao registrar menu de contexto".to_string());
    }

    // 2. Definir o comando de execução
    let cmd = format!("\"{}\" \"%1\"", exe_path);
    Command::new("reg")
        .args(&["add", "HKEY_CURRENT_USER\\Software\\Classes\\SystemFileAssociations\\.mp3\\shell\\MusicEditor\\command", "/ve", "/d", &cmd, "/f"])
        .status()
        .map_err(|e| e.to_string())?;

    Ok("Menu de contexto registrado com sucesso!".to_string())
}

/// Remove a integração com o Shell.
pub fn unregister_shell_extension() -> Result<String, String> {
    Command::new("reg")
        .args(&["delete", "HKEY_CURRENT_USER\\Software\\Classes\\SystemFileAssociations\\.mp3\\shell\\MusicEditor", "/f"])
        .status()
        .map_err(|e| e.to_string())?;

    Ok("Menu de contexto removido.".to_string())
}
