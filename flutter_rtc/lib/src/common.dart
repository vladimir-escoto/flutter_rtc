
extension ToCallFormat on Duration {
  String toCallFormat() {
    final hours = inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }
}