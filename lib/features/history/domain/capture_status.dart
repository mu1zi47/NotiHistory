class CaptureStatus {
  const CaptureStatus({
    this.supported = true,
    this.granted = false,
    this.connected = false,
    this.error,
  });
  final bool supported, granted, connected;
  final String? error;
  bool get active => supported && granted && connected && error == null;
}
