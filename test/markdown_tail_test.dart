import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/util/markdown_tail.dart';

void main() {
  test('short text is returned as is', () {
    expect(markdownTail('hello\nworld', maxChars: 100), 'hello\nworld');
  });

  test('long text keeps the end, cut at a line start', () {
    final text = List.generate(100, (i) => 'line $i').join('\n');
    final tail = markdownTail(text, maxChars: 40);
    expect(text.endsWith(tail), isTrue);
    expect(tail.startsWith('line '), isTrue); // not mid-line
    expect(tail.length, lessThanOrEqualTo(40));
  });

  test('a cut inside a code fence re-opens it', () {
    final text = 'intro\n```dart\n${List.filled(50, 'x = 1;').join('\n')}\n';
    final tail = markdownTail(text, maxChars: 60);
    expect(tail.startsWith('```\n'), isTrue);
  });

  test('a cut after a closed fence does not', () {
    final text = '```\ncode\n```\n${List.filled(50, 'prose').join('\n')}';
    expect(markdownTail(text, maxChars: 60).startsWith('```'), isFalse);
  });

  test('one huge line is cut by length', () {
    final text = 'a' * 5000;
    expect(markdownTail(text, maxChars: 100), 'a' * 100);
  });
}
