import 'package:flutter/material.dart';
import '../utils/format.dart';

class DatePickerRow extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const DatePickerRow({super.key, required this.date, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(yMd.format(date),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(width: 12),
      OutlinedButton(
          onPressed: () async {
            final d = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100));
            if (d != null) onChanged(d);
          },
          child: const Text('Chọn ngày'))
    ]);
  }
}
