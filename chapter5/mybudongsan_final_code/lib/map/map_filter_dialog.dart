import 'package:flutter/material.dart';

import 'map_filter.dart';

class MapFilterDialog extends StatefulWidget {
  final MapFilter mapFilter;

  const MapFilterDialog(this.mapFilter, {super.key});

  @override
  State<MapFilterDialog> createState() => _MapFilterDialogState();
}

class _MapFilterDialogState extends State<MapFilterDialog> {
  late MapFilter _mapFilter;

  static const List<DropdownMenuItem<String>> _buildingDropdownItems = [
    DropdownMenuItem(value: '1', child: Text('1동')),
    DropdownMenuItem(value: '2', child: Text('2동')),
    DropdownMenuItem(value: '3', child: Text('3동 이상')),
  ];

  static const List<DropdownMenuItem<String>> _peopleDropdownItems = [
    DropdownMenuItem(value: '0', child: Text('전부')),
    DropdownMenuItem(value: '100', child: Text('100세대 이상')),
    DropdownMenuItem(value: '300', child: Text('300세대 이상')),
    DropdownMenuItem(value: '500', child: Text('500세대 이상')),
  ];

  static const List<DropdownMenuItem<String>> _carDropdownItems = [
    DropdownMenuItem(value: '1', child: Text('세대별 1대 미만')),
    DropdownMenuItem(value: '2', child: Text('세대별 1대 이상')),
  ];

  @override
  void initState() {
    super.initState();
    _mapFilter = widget.mapFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('My 부동산'),
      content: SizedBox(
        height: 300,
        child: Column(
          children: [
            _buildDropdown(
              items: _buildingDropdownItems,
              value: _mapFilter.buildingString,
              onChanged: (value) {
                setState(() {
                  _mapFilter.buildingString = value!;
                });
              },
              labelText: '건물 동수',
            ),
            _buildDropdown(
              items: _peopleDropdownItems,
              value: _mapFilter.peopleString,
              onChanged: (value) {
                setState(() {
                  _mapFilter.peopleString = value!;
                });
              },
              labelText: '세대수',
            ),
            _buildDropdown(
              items: _carDropdownItems,
              value: _mapFilter.carString,
              onChanged: (value) {
                setState(() {
                  _mapFilter.carString = value!;
                });
              },
              labelText: '주차 대수',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_mapFilter);
                  },
                  child: const Text('확인'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('취소'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required List<DropdownMenuItem<String>> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    required String labelText,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        items: items,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}