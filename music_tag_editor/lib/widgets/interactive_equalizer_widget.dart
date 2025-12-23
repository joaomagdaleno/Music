import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';

class InteractiveEqualizerWidget extends StatefulWidget {
  const InteractiveEqualizerWidget({super.key});

  @override
  State<InteractiveEqualizerWidget> createState() =>
      _InteractiveEqualizerWidgetState();
}

class _InteractiveEqualizerWidgetState
    extends State<InteractiveEqualizerWidget> {
  final EqualizerService _service = EqualizerService.instance;
  List<double> _gains = [];
  List<int> _frequencies = [];
  double _minGain = -12.0;
  double _maxGain = 12.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParameters();
  }

  Future<void> _loadParameters() async {
    try {
      final params = await _service.equalizer.parameters;
      _minGain = params.minDecibels;
      _maxGain = params.maxDecibels;

      _frequencies =
          params.bands.map((b) => b.centerFrequency.toInt()).toList();
      _gains = List.filled(params.bands.length, 0.0);

      // Get current gains
      for (int i = 0; i < params.bands.length; i++) {
        _gains[i] = params.bands[i].gain;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      // Equalizer not available (probably not Android)
      setState(() {
        _isLoading = false;
        _frequencies = [60, 230, 910, 3600, 14000];
        _gains = [0, 0, 0, 0, 0];
      });
    }
  }

  String _formatFrequency(int hz) {
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(1)}k';
    }
    return '$hz';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Equalizador',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  Text(_service.isAutoMode ? 'Auto' : 'Manual'),
                  Switch(
                    value: !_service.isAutoMode,
                    onChanged: (val) {
                      setState(() {
                        _service.setAutoMode(!val);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_frequencies.length, (i) {
                return _EqualizerBand(
                  frequency: _formatFrequency(_frequencies[i]),
                  gain: _gains[i],
                  minGain: _minGain,
                  maxGain: _maxGain,
                  enabled: !_service.isAutoMode,
                  onChanged: (newGain) {
                    setState(() => _gains[i] = newGain);
                    _service.setCustomBand(i, newGain);
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PresetButton(
                  label: 'Flat', onTap: () => _applyPreset([0, 0, 0, 0, 0])),
              _PresetButton(
                  label: 'Bass', onTap: () => _applyPreset([5, 3, 0, 0, 0])),
              _PresetButton(
                  label: 'Rock', onTap: () => _applyPreset([3, 1, -1, 1, 3])),
              _PresetButton(
                  label: 'Pop', onTap: () => _applyPreset([2, 0, -1, 0, 2])),
              _PresetButton(
                  label: 'Jazz', onTap: () => _applyPreset([0, 0, 2, 1, 0])),
            ],
          ),
        ],
      ),
    );
  }

  void _applyPreset(List<double> preset) {
    _service.setAutoMode(false);
    for (int i = 0; i < preset.length && i < _gains.length; i++) {
      _gains[i] = preset[i];
      _service.setCustomBand(i, preset[i]);
    }
    setState(() {});
  }
}

class _EqualizerBand extends StatelessWidget {
  final String frequency;
  final double gain;
  final double minGain;
  final double maxGain;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _EqualizerBand({
    required this.frequency,
    required this.gain,
    required this.minGain,
    required this.maxGain,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedGain = (gain - minGain) / (maxGain - minGain);
    final barHeight = 150 * normalizedGain;

    return GestureDetector(
      onVerticalDragUpdate: enabled
          ? (details) {
              final delta = -details.delta.dy / 150 * (maxGain - minGain);
              final newGain = (gain + delta).clamp(minGain, maxGain);
              onChanged(newGain);
            }
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${gain.toStringAsFixed(0)}dB',
            style: TextStyle(
              fontSize: 10,
              color:
                  enabled ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 32,
                height: barHeight.clamp(8.0, 150.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: enabled
                        ? [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.tertiary
                          ]
                        : [Colors.grey, Colors.grey.shade400],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            frequency,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

