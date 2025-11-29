class FoxCloudDomainGuard {
  static const Set<String> _allowedHosts = {
    'main.vpnghost.space',
    'sub.vpnghost.space',
  };

  static bool isAllowed(String rawUrl) {
    try {
      final url = rawUrl.trim();
      if (url.isEmpty) return false;

      final uri = Uri.parse(url);
      if (!uri.hasScheme) {
        // пробуем добавить https по умолчанию, если вдруг пользователь вставил без схемы
        final fixed = Uri.parse('https://$url');
        return _allowedHosts.contains(fixed.host);
      }

      return _allowedHosts.contains(uri.host);
    } catch (_) {
      return false;
    }
  }
}
