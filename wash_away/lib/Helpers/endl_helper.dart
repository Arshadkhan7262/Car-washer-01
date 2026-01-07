String splitFirstWord(String text) {
  text = text.trim();

  final index = text.indexOf(' ');

  if (index == -1) return text;

  return '${text.substring(0, index)}\n${text.substring(index + 1).trim()}';
}
