bool matchesListSearch(String query, List<String?> haystacks) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  for (final h in haystacks) {
    if (h != null && h.toLowerCase().contains(q)) return true;
  }
  return false;
}
