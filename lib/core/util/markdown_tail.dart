/// The end of [text], for previews that only ever show their last few lines
/// (the benchmark grid cards). Parsing and laying out a whole long reply every
/// frame just to show its tail is what made big or long batches lag.
///
/// Cuts at a line start where possible, and re-opens a fenced code block or a
/// display-math block (`$$…$$`, `\[…\]`) when the cut lands inside one — else
/// its closing delimiter would open a new block that swallows the rest.
String markdownTail(String text, {int maxChars = 1500}) {
  if (text.length <= maxChars) return text;
  var cut = text.length - maxChars;
  final lineStart = text.indexOf('\n', cut);
  // Only snap forward when that leaves a reasonable amount of text.
  if (lineStart != -1 && lineStart < text.length - maxChars ~/ 2) {
    cut = lineStart + 1;
  }
  int before(String delimiter) {
    var n = 0;
    for (var i = text.indexOf(delimiter); i != -1 && i < cut;) {
      n++;
      i = text.indexOf(delimiter, i + delimiter.length);
    }
    return n;
  }

  final tail = text.substring(cut);
  if (before('```').isOdd) return '```\n$tail';
  if (before(r'$$').isOdd) return '\$\$\n$tail';
  if (before(r'\[') > before(r'\]')) return '\\[\n$tail';
  return tail;
}
