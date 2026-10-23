/// The end of [text], for previews that only ever show their last few lines
/// (the benchmark grid cards). Parsing and laying out a whole long reply every
/// frame just to show its tail is what made big or long batches lag.
///
/// Cuts at a line start where possible, and re-opens a fenced code block when
/// the cut lands inside one, so the kept part still renders as it would have.
String markdownTail(String text, {int maxChars = 1500}) {
  if (text.length <= maxChars) return text;
  var cut = text.length - maxChars;
  final lineStart = text.indexOf('\n', cut);
  // Only snap forward when that leaves a reasonable amount of text.
  if (lineStart != -1 && lineStart < text.length - maxChars ~/ 2) {
    cut = lineStart + 1;
  }
  var fences = 0;
  for (var i = text.indexOf('```'); i != -1 && i < cut;) {
    fences++;
    i = text.indexOf('```', i + 3);
  }
  final tail = text.substring(cut);
  return fences.isOdd ? '```\n$tail' : tail;
}
