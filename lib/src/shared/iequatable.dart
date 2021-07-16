///
/// Resumo:
///     Defines a generalized method that a value type or class implements to create
///     a type-specific method for determining equality of instances.
///
/// Parâmetros de Tipo:
///   T:
///     The type of objects to compare.
abstract class IEquatable<T> {
  ///
  /// Resumo:
  ///     Indicates whether the current object is equal to another object of the same type.
  ///
  /// Parâmetros:
  ///   other:
  ///     An object to compare with this object.
  ///
  /// Devoluções:
  ///     true if the current object is equal to the other parameter; otherwise, false.
  bool equals(T other);
}
