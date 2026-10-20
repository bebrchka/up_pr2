import 'dart:async';

import 'package:flutter/material.dart';

class DebouncedTextField extends StatefulWidget {
  const DebouncedTextField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.delay = const Duration(milliseconds: 400),
    this.keyboardType = TextInputType.text,
    this.prefixIcon = Icons.search,
    this.width = 240,
  });

  final String value;
  final String label;
  final ValueChanged<String> onChanged;
  final Duration delay;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final double width;

  @override
  State<DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<DebouncedTextField> {
  late final TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant DebouncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final timerActive = _timer?.isActive ?? false;
    if (!timerActive && widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.delay, () => widget.onChanged(value));
  }

  void _submit(String value) {
    _timer?.cancel();
    widget.onChanged(value);
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.prefixIcon, size: 20),
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Очистить',
                icon: const Icon(Icons.clear, size: 18),
                onPressed: _clear,
              );
            },
          ),
        ),
        onChanged: _onChanged,
        onSubmitted: _submit,
      ),
    );
  }
}
