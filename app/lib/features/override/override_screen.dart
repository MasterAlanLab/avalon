import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'override_view.dart';
import 'override_view_model.dart';

class OverrideScreen extends ConsumerStatefulWidget {
  const OverrideScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<OverrideScreen> createState() => _OverrideScreenState();
}

class _OverrideScreenState extends ConsumerState<OverrideScreen> {
  final _text = TextEditingController();

  OverrideViewModel get _model => ref.read(overrideViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    _text.addListener(() => _model.setText(_text.text));
    // Providers may not change while the tree builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _model.load();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (await _model.save() && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // The saved text arrives after the first frame.
    ref.listen(overrideViewModelProvider.select((s) => s.text), (_, text) {
      if (_text.text != text) _text.text = text;
    });
    return OverrideView(
      state: ref.watch(overrideViewModelProvider),
      controller: _text,
      scrollController: widget.scrollController,
      onCancel: () => context.pop(),
      onSave: _save,
    );
  }
}
