import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class _AnonConfigState {
  bool _isViewOnly = false;

  get isViewOnly => _isViewOnly;

  setWalletViewState(bool isViewOnly) => _isViewOnly = isViewOnly;
}

final anonConfigState = _AnonConfigState();
