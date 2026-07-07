/// Incremental parser for the benchmarker's CSV event stream.
///
/// The tool (Go `encoding/csv`) writes RFC 4180: fields containing commas,
/// quotes or newlines are double-quoted with `""` escapes — model tokens
/// routinely contain all three, so records can span physical lines and a
/// naive line-split would corrupt them. This parser is fed decoded string
/// chunks as they arrive and emits complete records; state survives chunk
/// boundaries.
library;

/// One row of the benchmarker's CSV output.
/// Header: timestamp,request_id,seq,token,request_timestamp,inputs_tokens,
///         outputs_tokens,concurrency,server,session_id,error
class PerfEvent {
  const PerfEvent({
    required this.timestampNs,
    required this.requestId,
    required this.seq,
    required this.requestTimestampNs,
    required this.inputTokens,
    required this.outputTokens,
    required this.concurrency,
    required this.server,
    required this.error,
  });

  final int timestampNs;
  final String requestId;
  final int seq;
  final int requestTimestampNs;
  final int inputTokens;
  final int outputTokens;
  final int concurrency;
  final String server;
  final String error;

  bool get isError => error.isNotEmpty;
}

/// Streaming CSV → [PerfEvent]. Feed with [add], drain returned records.
class PerfCsvParser {
  final List<String> _fields = [];
  final StringBuffer _field = StringBuffer();
  bool _inQuotes = false;

  /// True right after a closing quote — the next char decides whether it was
  /// an escaped `""` or the end of the field.
  bool _afterQuote = false;
  bool _fieldWasQuoted = false;
  bool _sawHeader = false;

  /// Parses [chunk] and returns the events completed by it. Rows that don't
  /// look like event rows (the header, or malformed lines) are skipped.
  List<PerfEvent> add(String chunk) {
    final out = <PerfEvent>[];
    for (var i = 0; i < chunk.length; i++) {
      final ch = chunk[i];
      if (_afterQuote) {
        _afterQuote = false;
        if (ch == '"') {
          _field.write('"'); // escaped quote, still inside the field
          _inQuotes = true;
          continue;
        }
        _inQuotes = false;
        // fall through: ch is a delimiter (or stray text, treated literally)
      }
      if (_inQuotes) {
        if (ch == '"') {
          _afterQuote = true;
        } else {
          _field.write(ch);
        }
        continue;
      }
      switch (ch) {
        case '"' when _field.isEmpty && !_fieldWasQuoted:
          _inQuotes = true;
          _fieldWasQuoted = true;
        case ',':
          _endField();
        case '\n':
          _endField();
          final event = _endRecord();
          if (event != null) out.add(event);
        case '\r':
          break; // swallowed; the \n that follows ends the record
        default:
          _field.write(ch);
      }
    }
    return out;
  }

  void _endField() {
    _fields.add(_field.toString());
    _field.clear();
    _fieldWasQuoted = false;
  }

  PerfEvent? _endRecord() {
    final f = List<String>.of(_fields);
    _fields.clear();
    if (f.length < 11) return null;
    if (!_sawHeader && f[0] == 'timestamp') {
      _sawHeader = true;
      return null;
    }
    final ts = int.tryParse(f[0]);
    final reqTs = int.tryParse(f[4]);
    if (ts == null || reqTs == null) return null;
    return PerfEvent(
      timestampNs: ts,
      requestId: f[1],
      seq: int.tryParse(f[2]) ?? 0,
      // f[3] is the token text — not needed for stats.
      requestTimestampNs: reqTs,
      inputTokens: int.tryParse(f[5]) ?? 0,
      outputTokens: int.tryParse(f[6]) ?? 0,
      concurrency: int.tryParse(f[7]) ?? 0,
      server: f[8],
      error: f[10],
    );
  }
}
