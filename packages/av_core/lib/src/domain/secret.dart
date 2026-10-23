/// A credential: password, UUID, private key, subscription URL or header.
///
/// The value never appears in `toString` (and so in logs). In model JSON it
/// is written as `{"$secret": value}`; `SecretCodec` lifts every such value
/// out before storage so it can be encrypted on its own (DATA_MODEL §3).
final class Secret {
  const Secret(this.value);

  factory Secret.fromJson(Map<String, dynamic> json) =>
      Secret(json[key]! as String);

  /// Marker key for secret values in model JSON.
  static const key = r'$secret';

  final String value;

  bool get isEmpty => value.isEmpty;

  Map<String, dynamic> toJson() => {key: value};

  @override
  bool operator ==(Object other) => other is Secret && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Secret(***)';
}
