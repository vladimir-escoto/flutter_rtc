extension ToCallFormat on Duration {
  String toCallFormat() {
    final hours = inHours.remainder(24);
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:$seconds";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:$seconds";
    }
  }
}
