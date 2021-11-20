import 'signature.dart';

/// Class for signature action, saving user action everytime they do the signing.
/// The purpose are to do undo & redo
class SignatureAction {
  /// array of point to save user's latest action
  static final List<List<Point>> _latestActions = <List<Point>>[];

  /// array of point that use to save points when user undo the signature
  static final List<List<Point>> _revertedActions = <List<Point>>[];

  /// save action's points to latest action
  static void addAction(List<Point> points) {
    _latestActions.add(<Point>[...points]);
  }

  /// It will remove last action from [_latestActions].
  /// The last action will be saved to [_revertedActions] 
  /// that will be used to do redo-ing.  
  /// Then, it will modify the real points with the last action.
  static void undo(SignatureController signatureController) {
    if (_latestActions.isNotEmpty) {
      final List<Point> lastAction = _latestActions.removeLast();
      _revertedActions.add(<Point>[...lastAction]);
      if (_latestActions.isNotEmpty) {
        signatureController.points = <Point>[..._latestActions.last];
        return;
      }
      signatureController.points = <Point>[];
    }
  }

  /// It will remove last reverted actions and add it into [_latestActions]
  /// Then, it will modify the real points with the last reverted action.
  static void redo(SignatureController signatureController) {
    if (_revertedActions.isNotEmpty) {
      final List<Point> lastRevertedAction = _revertedActions.removeLast();
      _latestActions.add(<Point>[...lastRevertedAction]);
      signatureController.points = <Point>[...lastRevertedAction];
      return;
    }
  }
}
