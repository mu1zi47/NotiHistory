enum CaptureAppFilter {
  all('Все приложения', 'Фильтр'),
  enabled('Включённые', 'Включённые'),
  disabled('Выключенные', 'Выключенные');

  const CaptureAppFilter(this.title, this.label);
  final String title, label;
  bool matches(bool enabled) => switch (this) {
    CaptureAppFilter.all => true,
    CaptureAppFilter.enabled => enabled,
    CaptureAppFilter.disabled => !enabled,
  };
}
