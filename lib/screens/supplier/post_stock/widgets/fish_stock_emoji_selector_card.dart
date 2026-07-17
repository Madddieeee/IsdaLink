import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockEmojiSelectorCard
    extends
        StatelessWidget {
  const FishStockEmojiSelectorCard({
    super.key,
    required this.emojis,
    required this.selectedEmoji,
    required this.onEmojiSelected,
  });

  final List<
    String
  >
  emojis;
  final String selectedEmoji;
  final ValueChanged<
    String
  >
  onEmojiSelected;

  @override
  Widget build(
    BuildContext context,
  ) {
    return PostStockSectionCard(
      title: 'Product Image Icon',
      subtitle: 'Choose a sample icon for the prototype display.',
      icon: Icons.image,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: emojis.map(
            (
              emoji,
            ) {
              final isSelected =
                  selectedEmoji ==
                  emoji;

              return GestureDetector(
                onTap: () => onEmojiSelected(
                  emoji,
                ),
                child: Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(
                    right: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(
                            0xFF146BFF,
                          )
                        : const Color(
                            0xFFEAF7FB,
                          ),
                    borderRadius: BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? const Color(
                              0xFF146BFF,
                            )
                          : const Color(
                              0xFFE1E9F0,
                            ),
                      width: 1.4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}
