import 'package:flutter/material.dart';
import 'package:music_tag_editor/src/rust/api/windows_devices.dart' as rust_mobile;
import 'package:music_tag_editor/src/rust/api/spectral.dart' as rust_audio;
import 'package:music_tag_editor/services/database_service.dart';

class ManagementHub extends StatefulWidget {
  const ManagementHub({super.key});

  @override
  State<ManagementHub> createState() => _ManagementHubState();
}

class _ManagementHubState extends State<ManagementHub> {
  String _deviceStatus = "Buscando dispositivo...";
  List<String> _connectedDevices = [];
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  Future<void> _refreshDevices() async {
    final devices = await rust_mobile.listConnectedMobileDevices();
    setState(() {
      _connectedDevices = devices;
      _deviceStatus = devices.isNotEmpty 
          ? "${devices.first} conectado" 
          : "Nenhum dispositivo via Phone Link";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Row(
        children: [
          // Sidebar de Navegação
          _buildSidebar(),
          
          // Conteúdo Principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  
                  // Grid de Módulos Inteligentes
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.5,
                      children: [
                        _buildModuleCard(
                          title: "Sincronização Mobile",
                          subtitle: "Enviar tags editadas para o celular",
                          icon: Icons.sync_problem,
                          color: Colors.blueAccent,
                          actionLabel: "Push All",
                          onAction: () async {
                             // Lógica de Push finalizada no Rust
                          },
                        ),
                        _buildModuleCard(
                          title: "Análise de Qualidade",
                          subtitle: "Detectar Fake FLACs e Upscales",
                          icon: Icons.high_quality,
                          color: Colors.purpleAccent,
                          actionLabel: "Iniciar Scan",
                          onAction: () {
                            setState(() => _isAnalyzing = true);
                          },
                        ),
                        _buildModuleCard(
                          title: "Reparo de Biblioteca",
                          subtitle: "Corrigir headers e arquivos corrompidos",
                          icon: Icons.build_circle,
                          color: Colors.orangeAccent,
                          actionLabel: "Reparar",
                          onAction: () {},
                        ),
                        _buildModuleCard(
                          title: "Snapshots & Undo",
                          subtitle: "Restaurar versões anteriores de tags",
                          icon: Icons.history,
                          color: Colors.tealAccent,
                          actionLabel: "Ver Histórico",
                          onAction: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 80,
      color: const Color(0xFF16162A),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _sidebarIcon(Icons.dashboard, true),
          _sidebarIcon(Icons.library_music, false),
          _sidebarIcon(Icons.settings, false),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Icon(icon, color: selected ? Colors.blueAccent : Colors.grey, size: 28),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Management Hub",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              "Controle total do motor nativo Rust",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.phonelink_setup, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(_deviceStatus, style: const TextStyle(color: Colors.blueAccent)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C36),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 40),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  backgroundColor: color.withOpacity(0.1),
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
