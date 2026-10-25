/// The `meta.json` fields a person types for a run, by path ('server.commit'
/// is `meta['server']['commit']`). ZML-Lab's Export run and Edit details and
/// the website's run page edit exactly these, under the same rules (see
/// [withRunMetaFields]); the rest of meta.json describes how the run was
/// measured and stays as recorded. `tags` is a list, edited comma-separated.
const runMetaFields = [
  'label',
  'model.name',
  'hardware.description',
  'server.version',
  'server.commit',
  'tags',
  'notes',
];

/// [meta]'s value at [path] as a form shows it.
String runMetaField(Map<String, Object?> meta, String path) {
  Object? v = meta;
  for (final key in path.split('.')) {
    v = v is Map ? v[key] : null;
  }
  return switch (v) {
    String s => s,
    List l => l.join(', '),
    _ => '',
  };
}

/// [meta] with [fields] (path → text) in: trimmed, tags split on commas,
/// and a blank field removes its key (never null or ""). Sections ('model',
/// 'server'…) are copied, never edited in place; every other key is kept.
Map<String, Object?> withRunMetaFields(
  Map<String, Object?> meta,
  Map<String, String> fields,
) {
  final out = Map<String, Object?>.of(meta);
  for (final MapEntry(key: path, value: text) in fields.entries) {
    final keys = path.split('.');
    final Object value = path == 'tags'
        ? [
            for (final t in text.split(','))
              if (t.trim().isNotEmpty) t.trim(),
          ]
        : text.trim();
    final blank =
        value is String && value.isEmpty || value is List && value.isEmpty;
    Map<String, Object?>? into = out;
    for (final key in keys.take(keys.length - 1)) {
      final had = into![key] as Map?;
      // A blank field doesn't create the section it would go in.
      if (had == null && blank) {
        into = null;
        break;
      }
      final section = Map<String, Object?>.of(
        had?.cast<String, Object?>() ?? const {},
      );
      into[key] = section;
      into = section;
    }
    if (into == null) continue;
    if (blank) {
      into.remove(keys.last);
    } else {
      into[keys.last] = value;
    }
  }
  return out;
}

/// The entries of [fields] whose trimmed text differs from [meta]'s: the
/// only ones an edit writes.
Map<String, String> changedRunMetaFields(
  Map<String, Object?> meta,
  Map<String, String> fields,
) => {
  for (final MapEntry(key: path, value: text) in fields.entries)
    if (text.trim() != runMetaField(meta, path)) path: text,
};

/// A run's [runMetaFields], as saved runs keep them. Empty = none.
class RunDetails {
  const RunDetails({
    required this.label,
    this.model = '',
    this.hardware = '',
    this.serverVersion = '',
    this.serverCommit = '',
    this.tags = const [],
    this.notes = '',
  });

  factory RunDetails.fromMeta(Map<String, Object?> meta) => RunDetails(
    label: runMetaField(meta, 'label'),
    model: runMetaField(meta, 'model.name'),
    hardware: runMetaField(meta, 'hardware.description'),
    serverVersion: runMetaField(meta, 'server.version'),
    serverCommit: runMetaField(meta, 'server.commit'),
    tags: [
      for (final t in (meta['tags'] as List? ?? const []))
        if (t is String) t,
    ],
    notes: runMetaField(meta, 'notes'),
  );

  final String label;
  final String model;
  final String hardware;
  final String serverVersion;
  final String serverCommit;
  final List<String> tags;
  final String notes;

  /// A meta.json holding just these fields.
  Map<String, Object?> toMeta() => withRunMetaFields(const {}, {
    'label': label,
    'model.name': model,
    'hardware.description': hardware,
    'server.version': serverVersion,
    'server.commit': serverCommit,
    'tags': tags.join(', '),
    'notes': notes,
  });

  /// What search looks through, beside the name and model.
  List<String> get searchFields => [
    hardware,
    serverVersion,
    serverCommit,
    ...tags,
    notes,
  ];
}
