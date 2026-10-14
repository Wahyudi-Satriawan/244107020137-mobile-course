String routeFromMessage(Map<String, dynamic> data) {
  final rawRoute = data['route'] as String?;
  if (rawRoute == null || rawRoute.trim().isEmpty) {
    return '/';
  }
  final route = rawRoute.trim();
  return route.startsWith('/') ? route : '/$route';
}