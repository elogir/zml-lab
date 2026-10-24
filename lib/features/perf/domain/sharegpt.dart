/// The ShareGPT dataset the benchmarker replays: ~94k real ChatGPT
/// conversations people shared on sharegpt.com, as cleaned and split for
/// Vicuna (the file vLLM's benchmark uses too). Downloaded once, from the
/// Perf tab.
abstract final class ShareGpt {
  static final url = Uri.parse(
    'https://huggingface.co/datasets/anon8231489123/'
    'ShareGPT_Vicuna_unfiltered/resolve/main/'
    'ShareGPT_V3_unfiltered_cleaned_split.json',
  );

  static const fileName = 'ShareGPT_V3_unfiltered_cleaned_split.json';

  /// Size and SHA-256 as Hugging Face publishes them (x-linked-size /
  /// x-linked-etag), checked after the download.
  static const bytes = 672837942;
  static const sha256 =
      '35f0e213ce091ed9b9af2a1f0755e9d39f9ccec34ab281cd4ca60d70f6479ba4';
}
