import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:music_hub/features/library/services/metadata_aggregator_service.dart';
import 'package:music_hub/core/services/database_service.dart';

class TagEditorScreen extends StatefulWidget {
  final SearchResult track;

  const TagEditorScreen({super.key, required this.track});

  @override
  State<TagEditorScreen> createState() => _TagEditorScreenState();
}

class _TagEditorScreenState extends State<TagEditorScreen> {
  final MetadataAggregatorService _metadataService = MetadataAggregatorService.instance;
  final DatabaseService _dbService = DatabaseService.instance;

  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;
  late TextEditingController _yearController;
  
  bool _isAutoFilling = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.title);
    _artistController = TextEditingController(text: widget.track.artist);
    _albumController = TextEditingController(text: widget.track.album ?? '');
    _genreController = TextEditingController(text: widget.track.genre ?? '');
    _yearController = TextEditingController(text: ''); 
    
    // Add listener to rebuild when title changes (for Save button state)
    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _autoFill() async {
    setState(() => _isAutoFilling = true);
    try {
      final result = await _metadataService.aggregateMetadata(
        _titleController.text,
        _artistController.text,
      );
      
      setState(() {
        _titleController.text = result.title ?? _titleController.text;
        _artistController.text = result.artist ?? _artistController.text;
        _albumController.text = result.album ?? _albumController.text;
        if (result.allGenres.isNotEmpty) {
          _genreController.text = result.allGenres.join(', ');
        }
        if (result.year != null) {
          _yearController.text = result.year.toString();
        }
      });
    } catch (e) {
      debugPrint('Auto-fill error: $e');
    } finally {
      setState(() => _isAutoFilling = false);
    }
  }

  Future<void> _save() async {
     final updatedTrack = SearchResult(
      id: widget.track.id,
      title: _titleController.text,
      artist: _artistController.text,
      album: _albumController.text,
      url: widget.track.url,
      platform: widget.track.platform,
      thumbnail: widget.track.thumbnail,
      localPath: widget.track.localPath,
      genre: _genreController.text,
      isVault: widget.track.isVault,
      isDownloaded: widget.track.isDownloaded,
      isOfficial: widget.track.isOfficial,
    );

    await _dbService.updateTrackMetadata(
      updatedTrack.id,
      updatedTrack.title,
      updatedTrack.artist,
      updatedTrack.album ?? '',
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    if (isWindows) {
      return _buildFluent(context);
    }
    return _buildMaterial(context);
  }

  Widget _buildFluent(BuildContext context) => fluent.NavigationView(
        appBar: fluent.NavigationAppBar(
          title: const Text('Editor de Tags'),
          leading: fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        content: fluent.ScaffoldPage.scrollable(
          header: fluent.PageHeader(
            title: Text(widget.track.title),
            commandBar: fluent.CommandBar(
              primaryItems: [
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.search),
                  label: const Text('Auto-Preencher'),
                  onPressed: _isAutoFilling ? null : _autoFill,
                ),
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.save),
                  label: const Text('Salvar Alterações'),
                  onPressed: _titleController.text.trim().isEmpty ? null : _save,
                ),
              ],
            ),
          ),
          children: [
            if (_isAutoFilling) const fluent.ProgressBar(),
            const SizedBox(height: 16),
            fluent.InfoLabel(
              label: 'Título',
              child: fluent.TextBox(controller: _titleController),
            ),
            const SizedBox(height: 12),
            fluent.InfoLabel(
              label: 'Artista',
              child: fluent.TextBox(controller: _artistController),
            ),
            const SizedBox(height: 12),
            fluent.InfoLabel(
              label: 'Álbum',
              child: fluent.TextBox(controller: _albumController),
            ),
            const SizedBox(height: 12),
            fluent.InfoLabel(
              label: 'Gênero',
              child: fluent.TextBox(controller: _genreController),
            ),
            const SizedBox(height: 12),
            fluent.InfoLabel(
              label: 'Ano',
              child: fluent.TextBox(controller: _yearController),
            ),
          ],
        ),
      );

  Widget _buildMaterial(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Tag Editor'),
          actions: [
             if (_isAutoFilling)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _isAutoFilling ? null : _autoFill,
              tooltip: 'Auto-fill',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _titleController.text.trim().isEmpty ? null : _save,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _artistController,
                decoration: const InputDecoration(labelText: 'Artist'),
              ),
              TextField(
                controller: _albumController,
                decoration: const InputDecoration(labelText: 'Album'),
              ),
              TextField(
                controller: _genreController,
                decoration: const InputDecoration(labelText: 'Genre'),
              ),
              TextField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
            ],
          ),
        ),
      );
}
