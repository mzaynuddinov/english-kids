import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pin_service.dart';
import '../theme.dart';

class PinGate extends StatefulWidget {
  final String title;
  final VoidCallback onUnlocked;

  const PinGate({super.key, required this.title, required this.onUnlocked});

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  final pin = TextEditingController();
  final confirm = TextEditingController();
  bool setup = false;
  bool ready = false;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final has = await PinService.instance.hasPin();
    if (!mounted) return;
    setState(() {
      setup = !has;
      ready = true;
    });
  }

  @override
  void dispose() {
    pin.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      error = null;
      busy = true;
    });
    try {
      if (setup) {
        if (!PinService.instance.validFormat(pin.text)) {
          setState(() => error = 'PIN бояд 4 рақам бошад.');
          return;
        }
        if (pin.text != confirm.text) {
          setState(() => error = 'PIN мувофиқат намекунад.');
          return;
        }
        final ok = await PinService.instance.setPin(pin.text);
        if (!ok) {
          setState(() => error = 'PIN захира нашуд.');
          return;
        }
        widget.onUnlocked();
        return;
      }
      final ok = await PinService.instance.verify(pin.text);
      if (!ok) {
        setState(() => error = 'PIN нодуруст аст.');
        return;
      }
      widget.onUnlocked();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: cyan600)));
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const Icon(Icons.lock_rounded, size: 42, color: cyan600),
            const SizedBox(height: 10),
            Text(
              setup ? 'PIN-коди волидонро таъин кунед' : '🔒 Қисмати волидон',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _PinDots(value: pin.text),
            const SizedBox(height: 10),
            TextField(
              controller: pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'PIN',
                hintText: '• • • •',
                border: OutlineInputBorder(),
              ),
            ),
            if (setup) ...[
              const SizedBox(height: 8),
              TextField(
                controller: confirm,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Такрори PIN',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!,
                  style: const TextStyle(
                      color: Color(0xFFDC2626), fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: Text(setup ? 'Захира' : 'Кушодан'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> unlockParent(BuildContext context,
    {String title = 'Қисмати волидон'}) async {
  var ok = false;
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => PinGate(
        title: title,
        onUnlocked: () {
          ok = true;
          Navigator.pop(context);
        },
      ),
    ),
  );
  return ok;
}

class _PinDots extends StatelessWidget {
  final String value;
  const _PinDots({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < value.length ? cyan700 : Colors.transparent,
              border: Border.all(color: cyan700, width: 2),
            ),
          ),
      ],
    );
  }
}
