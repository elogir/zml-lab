/// Hardware vendor of a remote host — labels the machine, nothing more.
enum Vendor {
  nvidia,
  amd;

  String get label => switch (this) {
    Vendor.nvidia => 'NVIDIA',
    Vendor.amd => 'AMD',
  };
}
