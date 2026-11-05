import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import '../app_scope.dart';
import '../audio/speaker.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import '../widgets/leoni.dart';
import '../widgets/page_frame.dart';
import 'werkstatt_store.dart';

/// Adresse, unter der die App veröffentlicht wird.
const publicBase = 'https://thatlionfish.github.io/LearnwithLeoni/';

/// Die Werkstatt-Ablage, gesetzt in `main()`.
WerkstattStore? werkstattStore;

/// Übersicht: alle Schüler, Sets, Entwürfe und fehlende Aufnahmen.
class WerkstattHome extends StatefulWidget {
  const WerkstattHome({super.key});

  @override
  State<WerkstattHome> createState() => _WerkstattHomeState();
}

class _WerkstattHomeState extends State<WerkstattHome> {
  Future<List<StudentContent>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<StudentContent>> _load() async {
    final store = werkstattStore!;
    final repo = AppScope.of(context).repository;
    final codes = await store.studentCodes();
    final out = <StudentContent>[];
    for (final c in codes) {
      repo.invalidate(c);
      try {
        out.add(await repo.student(c));
      } on Object {
        // Ordner ohne gültige student.json überspringen.
      }
    }
    return out;
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageFrame(
      seed: 4,
      title: Text('Werkstatt', style: serif(22, weight: 440)),
      actions: [
        IconButton(
          tooltip: 'Neu laden',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _reload,
        ),
        const SizedBox(width: 8),
      ],
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const KumaFigure(pose: KumaPose.wave, height: 90),
            const LeoniFigure(pose: LeoniPose.read, height: 150),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  'Hier prüfst du Entwürfe, gibst Sets frei und nimmst '
                  'Bündnerdütsch auf. Alles wird direkt im Projekt gespeichert; '
                  'online ist es nach dem nächsten Veröffentlichen.',
                  style: text.bodyMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<StudentContent>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, s) in snap.data!.indexed) ...[
                  _StudentCard(content: s, seed: 60 + i, onChanged: _reload),
                  const SizedBox(height: 14),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.content,
    required this.seed,
    required this.onChanged,
  });

  final StudentContent content;
  final int seed;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final st = content.student;
    final link = '$publicBase#/s/${st.code}';
    return OrganicCard(
      seed: seed,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(st.name, style: text.titleLarge)),
              Text(
                '${st.level} · ${st.explainLanguage}',
                style: text.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: SelectableText(link, style: text.bodySmall)),
              IconButton(
                tooltip: 'Link kopieren',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link kopiert')));
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final set in content.sets)
            InkWell(
              borderRadius: organicRadius(set.id.hashCode, base: 12),
              onTap: () async {
                await context.push('/werkstatt/${st.code}/${set.id}');
                onChanged();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    _StatusDot(published: set.published),
                    const SizedBox(width: 10),
                    Expanded(child: Text(set.title, style: text.titleMedium)),
                    Text(_audioSummary(set), style: text.labelMedium),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push('/s/${st.code}'),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Als Schüler ansehen'),
          ),
        ],
      ),
    );
  }

  String _audioSummary(VocabSet set) {
    final missing = set.cards.where((c) => c.audio == null).length;
    final unverified = set.cards.where((c) => !c.verified).length;
    final parts = [
      set.published ? 'freigegeben' : 'Entwurf',
      if (set.variety == Variety.gsw && missing > 0) '$missing Audio fehlt',
      if (unverified > 0) '$unverified ungeprüft',
    ];
    return parts.join(' · ');
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.published});
  final bool published;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: published ? LeoColors.lemonGrass : LeoColors.sand,
      border: Border.all(color: LeoColors.chocolate.withValues(alpha: 0.5)),
    ),
  );
}

/// Ein Set bearbeiten: freigeben, Schreibweisen bestätigen, Audio aufnehmen.
class WerkstattSetScreen extends StatefulWidget {
  const WerkstattSetScreen({
    super.key,
    required this.code,
    required this.setId,
  });

  final String code;
  final String setId;

  @override
  State<WerkstattSetScreen> createState() => _WerkstattSetScreenState();
}

class _WerkstattSetScreenState extends State<WerkstattSetScreen> {
  WerkstattStore get _store => werkstattStore!;
  Map<String, dynamic>? _json;
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingCard;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store.readSet(widget.code, widget.setId).then((j) {
      if (mounted) setState(() => _json = j);
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    Speaker.stop();
    super.dispose();
  }

  List<Map<String, dynamic>> get _cards => [
    for (final c in (_json!['cards'] as List)) c as Map<String, dynamic>,
  ];

  Future<void> _save() async {
    await _store.writeSet(widget.code, widget.setId, _json!);
    if (!mounted) return;
    AppScope.of(context).repository.invalidate(widget.code);
    setState(() {});
  }

  Future<void> _toggleRecord(Map<String, dynamic> card) async {
    final id = card['id'] as String;
    if (_recordingCard == id) {
      final path = await _recorder.stop();
      setState(() => _recordingCard = null);
      if (path == null) return;
      final file = path.replaceAll('\\', '/').split('/').last;
      card['audio'] = 'audio/$file';
      await _save();
      await Speaker.playFile(path);
      return;
    }
    if (_recordingCard != null) return;
    if (!await _recorder.hasPermission()) {
      setState(
        () => _error = 'Kein Zugriff auf das Mikrofon. Bitte in den Windows-Einstellungen erlauben.',
      );
      return;
    }
    final aac = await _recorder.isEncoderSupported(AudioEncoder.aacLc);
    final ext = aac ? 'm4a' : 'wav';
    // Alte Aufnahme ersetzen.
    final old = card['audio'] as String?;
    if (old != null) await _store.delete(_store.studentFile(widget.code, old));
    final path = _store.audioFilePath(widget.code, '${widget.setId}-$id.$ext');
    await _recorder.start(
      RecordConfig(
        encoder: aac ? AudioEncoder.aacLc : AudioEncoder.wav,
        numChannels: 1,
      ),
      path: path,
    );
    setState(() {
      _error = null;
      _recordingCard = id;
    });
  }

  Future<void> _deleteAudio(Map<String, dynamic> card) async {
    final old = card['audio'] as String?;
    if (old == null) return;
    await _store.delete(_store.studentFile(widget.code, old));
    card.remove('audio');
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final json = _json;
    if (json == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final published = json['status'] == 'published';
    final gsw = json['variety'] == 'gsw';
    return PageFrame(
      showBack: true,
      seed: 12,
      title: Text('Werkstatt', style: serif(20, weight: 440)),
      children: [
        Text(json['title'] as String, style: text.displaySmall),
        if ((json['titleTranslation'] as String?)?.isNotEmpty ?? false)
          Text(json['titleTranslation'] as String, style: text.bodyLarge),
        const SizedBox(height: 12),
        OrganicCard(
          seed: 3,
          color: LeoColors.vanillaIce,
          padding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              published
                  ? 'Freigegeben – Schüler sieht das Set'
                  : 'Entwurf – nur hier sichtbar',
              style: text.titleMedium,
            ),
            value: published,
            activeThumbColor: LeoColors.chocolate,
            onChanged: (v) {
              json['status'] = v ? 'published' : 'draft';
              _save();
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: text.bodyMedium),
        ],
        const SizedBox(height: 18),
        for (final (i, card) in _cards.indexed) ...[
          _CardRow(
            card: card,
            seed: 70 + i,
            gsw: gsw,
            recording: _recordingCard == card['id'],
            busy: _recordingCard != null && _recordingCard != card['id'],
            onRecord: () => _toggleRecord(card),
            onPlay: () {
              final a = card['audio'] as String?;
              if (a != null) {
                Speaker.playFile(_store.studentFile(widget.code, a));
              }
            },
            onDelete: () => _deleteAudio(card),
            onVerified: (v) {
              card['verified'] = v;
              _save();
            },
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.card,
    required this.seed,
    required this.gsw,
    required this.recording,
    required this.busy,
    required this.onRecord,
    required this.onPlay,
    required this.onDelete,
    required this.onVerified,
  });

  final Map<String, dynamic> card;
  final int seed;
  final bool gsw;
  final bool recording;
  final bool busy;
  final VoidCallback onRecord;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final ValueChanged<bool> onVerified;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasAudio = card['audio'] != null;
    final verified = (card['verified'] as bool?) ?? true;
    return OrganicCard(
      seed: seed,
      color: recording ? LeoColors.sand : LeoColors.brightWhite,
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card['term'] as String, style: text.titleMedium),
                Text(card['translation'] as String, style: text.bodySmall),
                if (card['alt'] != null)
                  Text(card['alt'] as String, style: text.bodySmall),
                if (gsw || !verified)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: verified,
                        onChanged: (v) => onVerified(v ?? false),
                        activeColor: LeoColors.chocolate,
                      ),
                      Text('Schreibweise geprüft', style: text.bodySmall),
                    ],
                  ),
              ],
            ),
          ),
          if (!hasAudio && !recording)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                gsw ? 'Audio fehlt' : 'Computerstimme',
                style: text.labelMedium,
              ),
            ),
          IconButton(
            tooltip: recording ? 'Aufnahme beenden' : 'Aufnehmen',
            onPressed: busy ? null : onRecord,
            icon: Icon(
              recording ? Icons.stop_circle_rounded : Icons.mic_rounded,
            ),
          ),
          if (hasAudio) ...[
            IconButton(
              tooltip: 'Anhören',
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            IconButton(
              tooltip: 'Aufnahme löschen',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ],
      ),
    );
  }
}
