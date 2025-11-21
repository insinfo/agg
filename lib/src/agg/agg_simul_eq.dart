/// Utility to solve small systems of simultaneous equations (4x4 with 2 RHS).
class MatrixPivot {
  static int pivot(List<List<double>> m, int row) {
    int k = row;
    double maxVal = -1.0;
    final int rows = m.length;
    for (int i = row; i < rows; i++) {
      final double tmp = m[i][row].abs();
      if (tmp > maxVal && tmp != 0.0) {
        maxVal = tmp;
        k = i;
      }
    }
    if (m[k][row] == 0.0) {
      return -1;
    }
    if (k != row) {
      final List<double> swap = m[k];
      m[k] = m[row];
      m[row] = swap;
      return k;
    }
    return 0;
  }
}

class SimulEq {
  /// Solve a 4x4 system with 2 right-hand columns.
  /// Returns true if solved; false if the system is singular.
  static bool solve(
    List<List<double>> left,
    List<List<double>> right,
    List<List<double>> result,
  ) {
    if (left.length != 4 ||
        right.length != 4 ||
        result.length != 4 ||
        left.any((r) => r.length != 4) ||
        right.any((r) => r.length != 2) ||
        result.any((r) => r.length != 2)) {
      throw ArgumentError('left/right/result must be 4x4, 4x2, 4x2 matrices.');
    }

    const int size = 4;
    const int rightCols = 2;
    final List<List<double>> tmp =
        List.generate(size, (_) => List.filled(size + rightCols, 0.0));

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        tmp[i][j] = left[i][j];
      }
      for (int j = 0; j < rightCols; j++) {
        tmp[i][size + j] = right[i][j];
      }
    }

    for (int k = 0; k < size; k++) {
      if (MatrixPivot.pivot(tmp, k) < 0) {
        return false; // Singular matrix
      }

      final double pivot = tmp[k][k];
      for (int j = k; j < size + rightCols; j++) {
        tmp[k][j] /= pivot;
      }

      for (int i = k + 1; i < size; i++) {
        final double factor = tmp[i][k];
        for (int j = k; j < size + rightCols; j++) {
          tmp[i][j] -= factor * tmp[k][j];
        }
      }
    }

    for (int k = 0; k < rightCols; k++) {
      for (int m = size - 1; m >= 0; m--) {
        result[m][k] = tmp[m][size + k];
        for (int j = m + 1; j < size; j++) {
          result[m][k] -= tmp[m][j] * result[j][k];
        }
      }
    }

    return true;
  }
}
