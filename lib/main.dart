import 'package:emoji_assist/settings_screen.dart';
import 'package:emoji_assist/video_player.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // Import for JSON parsing
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;
import 'package:provider/provider.dart';
import 'font_size_provider.dart'; // Import your provide

void main() {
  runApp(
      ChangeNotifierProvider(
      create: (_) => FontSizeProvider(), // Provide the FontSizeProvider
  child: const EmojiApp())
  );
}

class EmojiApp extends StatelessWidget {
  const EmojiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the FontSizeProvider
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return MaterialApp(
      title: 'EmojiAssist',
      theme: ThemeData(
        primaryColor: const Color(0xffdcf8c6), // Custom primary color
        scaffoldBackgroundColor: const Color(0xffece5dd), // Background color
        appBarTheme: const AppBarTheme(
          color: Color(0xffdcf8c6), // Top bar color
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff504e4e), // Custom color for the active border
              width: 2.0,
            ),
          ),
          labelStyle: TextStyle(
            color: Color(0xff000000), // Custom color for the label when focused
          ),

        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Color(0xffece5dd), // Remove white lines by matching the background color
          selectedTileColor: Color(0xffdcf8c6), // Optional: custom selected tile color
        ),
        dividerColor: Colors.transparent, // Set divider color to transparent to remove dividers
      ),
      home: const EmojiCategoriesScreen(),
    );
  }
}


class EmojiCategoriesScreen extends StatefulWidget {
  const EmojiCategoriesScreen({super.key});

  @override
  _EmojiCategoriesScreenState createState() => _EmojiCategoriesScreenState();
}

class _EmojiCategoriesScreenState extends State<EmojiCategoriesScreen> {
  List<Map<String, dynamic>> _filteredEmojis = [];
  String _searchText = "";
  Map<String, Map<String, dynamic>> emojiMap = {}; // Map to hold unique emojis
  Map<String, int> moodFrequency = {}; // Declare moodFrequency at the class level

  @override
  void initState() {
    super.initState();
    _loadEmojis(); // Load emojis from the JSON file
  }

  Future<void> _loadEmojis() async {
    String data = await rootBundle.loadString('assets/emoji_formatted.json');
    Map<String, dynamic> jsonResult = json.decode(data);

    // Flatten the data into a list of emoji objects
    jsonResult.forEach((definition, emojis) {
      for (var emoji in emojis) {
        if (!emojiMap.containsKey(emoji)) {
          // Add each emoji as a unique entry in the emojiMap
          emojiMap[emoji] = {
            'emoji': emoji,
            'main_name': definition, // Use the definition as the main name
            'associated_names': [definition], // Start with only this definition
            'meaning': definition, // Set the meaning as the definition
            'mood': definition // Assign the mood as the definition
          };
        } else {
          // Add the definition to associated names if it already exists
          emojiMap[emoji]?['associated_names'].add(definition);
        }
      }
    });

    // Split emojis into non-flags and flags for display
    List<Map<String, dynamic>> nonFlagEmojis = [];
    List<Map<String, dynamic>> flagEmojis = [];

    emojiMap.forEach((_, emoji) {
      if (emoji['meaning'] == 'flag') {
        flagEmojis.add(emoji);
      } else {
        nonFlagEmojis.add(emoji);
      }
    });

    // Sort emojis (optional, as needed)
    nonFlagEmojis.sort((a, b) {
      int aNamesCount = (a['associated_names'] as List).length;
      int bNamesCount = (b['associated_names'] as List).length;

      if (aNamesCount != bNamesCount) {
        return bNamesCount.compareTo(aNamesCount);
      }

      int freqA = moodFrequency[a['mood']] ?? 0;
      int freqB = moodFrequency[b['mood']] ?? 0;
      return freqB.compareTo(freqA);
    });

    flagEmojis.sort((a, b) {
      int aNamesCount = (a['associated_names'] as List).length;
      int bNamesCount = (b['associated_names'] as List).length;
      return bNamesCount.compareTo(aNamesCount);
    });

    // Combine non-flags and flags for the final filtered list
    setState(() {
      _filteredEmojis = [...nonFlagEmojis, ...flagEmojis];
    });
  }


  // Filter emojis based on search text
  void _filterEmojis(String searchText) {
    setState(() {
      _searchText = searchText.toLowerCase();

      if (_searchText.isEmpty) {
        // If search text is empty, set name to least shared description
        _filteredEmojis = emojiMap.values.map((emoji) {
          List<String> associatedNames = List<String>.from(emoji['associated_names']);

          // Find the least shared description
          String leastSharedName = associatedNames.reduce((name1, name2) {
            int count1 = emojiMap.values.where((e) => e['associated_names'].contains(name1)).length;
            int count2 = emojiMap.values.where((e) => e['associated_names'].contains(name2)).length;
            return count1 < count2 ? name1 : name2;
          });

          // Find the most shared meaning
          String mostSharedMeaning = associatedNames.reduce((name1, name2) {
            int count1 = emojiMap.values.where((e) => e['associated_names'].contains(name1)).length;
            int count2 = emojiMap.values.where((e) => e['associated_names'].contains(name2)).length;
            return count1 > count2 ? name1 : name2;
          });

          return {
            ...emoji,
            'main_name_temp': leastSharedName,
            'meaning': mostSharedMeaning,
          };
        }).toList();
      } else {
        // If search text is not empty, rank by relevance to search term
        List<String> searchWords = _searchText.split(' ').where((word) => word.isNotEmpty).toList();

        _filteredEmojis = emojiMap.values.map((emoji) {
          List<String> associatedNames = List<String>.from(emoji['associated_names']);

          // Find the most relevant name to the search term
          String bestMatch = associatedNames.reduce((name1, name2) {
            int relevance1 = _calculateRelevance(name1.toLowerCase(), searchWords);
            int relevance2 = _calculateRelevance(name2.toLowerCase(), searchWords);
            return relevance1 >= relevance2 ? name1 : name2;
          });

          // Find the most shared meaning
          String mostSharedMeaning = associatedNames.reduce((name1, name2) {
            int count1 = emojiMap.values.where((e) => e['associated_names'].contains(name1)).length;
            int count2 = emojiMap.values.where((e) => e['associated_names'].contains(name2)).length;
            return count1 > count2 ? name1 : name2;
          });

          return {
            ...emoji,
            'main_name_temp': bestMatch,
            'meaning': mostSharedMeaning,
          };
        }).toList();
      }
    });
  }

// Helper method to calculate relevance
  int _calculateRelevance(String name, List<String> searchWords) {
    return searchWords.fold(0, (score, word) => score + (name.contains(word) ? 1 : 0));
  }




  // Show a dialog with all associated names of the emoji
  void _showAssociatedNames(BuildContext context, String emojiCode, List<String> associatedNames) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xffece5dd),
          title: Text(
            'Names $emojiCode',
            style: _emojiTextStyle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: associatedNames
                  .map((name) => Column(
                children: [
                  ListTile(
                    title: Text(
                      name,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const FractionallySizedBox(
                    widthFactor: 1,
                    child: Divider(thickness: 2),
                  ),
                ],
              ))
                  .toList(),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showCopyInstructions(context, emojiCode);
                  },
                  child: const Text('Copy Emoji'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }


  void _showCopyInstructions(BuildContext context, String emojiCode) {
    // Copy the emoji to the clipboard
    Clipboard.setData(ClipboardData(text: emojiCode));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xffece5dd),
          title: Text(
            'Emoji Copied! $emojiCode',
            style: _emojiTextStyle.copyWith(fontSize: 24),
          ),
          content: const Text(
            'The emoji has been copied to your clipboard. Follow these steps to use it:\n\n'
                '1. Open your messaging app (like WhatsApp).\n'
                '2. Go to the chat where you want to use the emoji.\n'
                '3. Long-press the box where you type your message.\n'
                '4. Select "Paste" to insert the emoji.',
            style: TextStyle(fontSize: 20),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the current dialog
                    _showVideoHelpDialog(context, emojiCode); // Show the video help dialog
                  },
                  child: const Text('Video Help'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }





  void _showVideoHelpDialog(BuildContext context, String emojiCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xffece5dd),
          title: const Text('How to Paste the Emoji'),
          content: const SizedBox(
            height: 200, // Adjust height as needed
            child: LoopingVideoPlayer(videoPath: 'assets/tutorial.mp4'),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the current dialog
                    _showCopyInstructions(context, emojiCode); // Show the copy instructions dialog
                  },
                  child: const Text('Text Help'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }








  // Define a TextStyle with the custom font
  final TextStyle _emojiTextStyle = const TextStyle(
    fontFamily: 'WhatsappEmoji',
    fontSize: 40, // Adjust the size as needed
  );

  @override
  Widget build(BuildContext context) {
    // Access the FontSizeProvider
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text('EmojiAssist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0), // Increased padding for accessibility
            child: TextField(
              onChanged: _filterEmojis,
              decoration: const InputDecoration(
                labelText: 'Search Emoji',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: fontSizeProvider.fontSize-2, fontFamily: 'WhatsappEmoji'), // Increased font size for the input
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredEmojis.length,
              itemBuilder: (context, index) {
                final emoji = _filteredEmojis[index];
                return Column(
                  children: [
                    ListTile(
                      leading: Text(
                        emoji['emoji']!,
                        style: _emojiTextStyle,
                      ),
                      title: Text(
                        emoji['main_name_temp'] ?? emoji['main_name']!,
                        style: TextStyle(fontSize: fontSizeProvider.fontSize), // Larger text for title
                      ),
                      subtitle: Text(
                        emoji['meaning']!,
                        style: TextStyle(fontSize: fontSizeProvider.fontSize-4), // Larger text for subtitle
                      ),
                      onTap: () {
                        _showAssociatedNames(context, emoji['emoji']!, emoji['associated_names']);
                      },
                    ),
                    const FractionallySizedBox(
                      widthFactor: 0.75, // 75% width of the screen
                      child: Divider(thickness: 2), // Add divider between emojis
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
