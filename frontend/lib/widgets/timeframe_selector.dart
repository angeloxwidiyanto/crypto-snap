import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/crypto_service.dart';

class TimeframeSelector extends StatelessWidget {
  const TimeframeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CryptoService>(
      builder: (context, cryptoService, _) {
        final selectedTimeframe = cryptoService.selectedTimeframe;
        final timeframes = cryptoService.timeframes;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Timeframe',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: timeframes.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final timeframe = timeframes[index];
                  final isSelected = timeframe == selectedTimeframe;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(timeframe.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          cryptoService.setTimeframe(timeframe);
                        }
                      },
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.onPrimary 
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
