import 'package:emoji/video_player.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // Import for JSON parsing
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;

void main() {
  runApp(const EmojiApp());
}

class EmojiApp extends StatelessWidget {
  const EmojiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emoji Meaning App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
    String data = await rootBundle.loadString('assets/emojis.json');
    Map<String, dynamic> jsonResult = json.decode(data);

    // Map to track the frequency of each name
    Map<String, int> nameFrequency = {};

    // Map to track all associated names for each emoji code
    Map<String, List<String>> emojiToNames = {};

    // First pass: count frequencies of all names across emojis and build the map of emoji -> names
    jsonResult.forEach((key, value) {
      for (var emojiCode in value) {
        nameFrequency[key] = (nameFrequency[key] ?? 0) + 1;

        // Add key (name) to the list of names associated with this emoji
        if (!emojiToNames.containsKey(emojiCode)) {
          emojiToNames[emojiCode] = [];
        }
        emojiToNames[emojiCode]!.add(key);
      }
    });

    // Second pass: assign both the least common and most common name for each emoji code
    emojiToNames.forEach((emojiCode, names) {
      String leastCommonName = names.reduce((name1, name2) =>
      nameFrequency[name1]! <= nameFrequency[name2]! ? name1 : name2);

      String mostCommonName = names.reduce((name1, name2) =>
      nameFrequency[name1]! >= nameFrequency[name2]! ? name1 : name2);

      String mood = mostCommonName;

      // Track mood frequency at the class level
      moodFrequency[mood] = (moodFrequency[mood] ?? 0) + 1;

      emojiMap[emojiCode] = {
        'emoji': emojiCode,
        'main_name': leastCommonName,
        'associated_names': names,
        'meaning': mostCommonName,
        'mood': mood
      };
    });

    // Split emojis into two lists: flags and non-flags
    List<Map<String, dynamic>> nonFlagEmojis = [];
    List<Map<String, dynamic>> flagEmojis = [];

    for (var emoji in emojiMap.values) {
      if (emoji['meaning'] == 'flag') {
        flagEmojis.add(emoji);
      } else {
        nonFlagEmojis.add(emoji);
      }
    }

    // Sort non-flag emojis by the number of associated names, then by mood frequency
    nonFlagEmojis.sort((a, b) {
      int aNamesCount = (a['associated_names'] as List).length;
      int bNamesCount = (b['associated_names'] as List).length;

      // Sort by the number of associated names in descending order
      if (aNamesCount != bNamesCount) {
        return bNamesCount.compareTo(aNamesCount);
      }

      // If the number of names is the same, sort by mood frequency (in descending order)
      int freqA = moodFrequency[a['mood']] ?? 0;
      int freqB = moodFrequency[b['mood']] ?? 0;

      return freqB.compareTo(freqA); // Sort by mood frequency in descending order
    });

    // Sort flag emojis by the number of associated names (descending order)
    flagEmojis.sort((a, b) {
      int aNamesCount = (a['associated_names'] as List).length;
      int bNamesCount = (b['associated_names'] as List).length;
      return bNamesCount.compareTo(aNamesCount);
    });

    // Combine non-flag emojis and flag emojis, with flags at the bottom
    setState(() {
      _filteredEmojis = [...nonFlagEmojis, ...flagEmojis];
    });
  }

  // Filter emojis based on search text
  void _filterEmojis(String searchText) {
    setState(() {
      _searchText = searchText.toLowerCase();

      if (_searchText.isEmpty) {
        // Reset to the original sorted list
        List<Map<String, dynamic>> nonFlagEmojis = [];
        List<Map<String, dynamic>> flagEmojis = [];

        for (var emoji in emojiMap.values) {
          if (emoji['meaning'] == 'flag') {
            flagEmojis.add(emoji);
          } else {
            nonFlagEmojis.add(emoji);
          }
        }

        // Re-sort non-flag emojis by the number of associated names and mood frequency
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

        // Sort flag emojis by the number of associated names
        flagEmojis.sort((a, b) {
          int aNamesCount = (a['associated_names'] as List).length;
          int bNamesCount = (b['associated_names'] as List).length;
          return bNamesCount.compareTo(aNamesCount);
        });

        // Combine non-flag emojis and flag emojis, with flags at the bottom
        _filteredEmojis = [...nonFlagEmojis, ...flagEmojis];
      } else {
        // Split the search text into individual words
        List<String> searchWords = _searchText.split(' ').where((word) => word.isNotEmpty).toList();

        _filteredEmojis = emojiMap.values
            .where((emoji) {
          String emojiChar = emoji['emoji'];
          String mainName = emoji['main_name'].toLowerCase();
          String meaning = emoji['meaning'].toLowerCase();
          List<String> associatedNames = List<String>.from(emoji['associated_names']);

          // Check if emoji character matches any search word
          if (searchWords.any((word) => emojiChar.contains(word))) {
            return true;
          }

          // Check if main name or meaning contains all search words
          bool matchesMainName = searchWords.every((word) => mainName.contains(word));
          bool matchesMeaning = searchWords.every((word) => meaning.contains(word));
          bool matchesAssociatedNames = searchWords.every(
                  (word) => associatedNames.any((name) => name.toLowerCase().contains(word)));

          return matchesMainName || matchesMeaning || matchesAssociatedNames;
        })
            .map((emoji) {
          // Find the best match for the search text in associated names
          String bestMatch = List<String>.from(emoji['associated_names'])
              .firstWhere((String name) => searchWords.any((word) => name.toLowerCase().contains(word)), orElse: () => emoji['main_name']);

          // Temporarily use the best match as main_name_temp
          emoji['main_name_temp'] = bestMatch;
          return emoji;
        }).toList();
      }
    });
  }



  // Show a dialog with all associated names of the emoji
  void _showAssociatedNames(BuildContext context, String emojiCode, List<String> associatedNames) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                  FractionallySizedBox(
                    widthFactor: 1,
                    child: const Divider(thickness: 2),
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
          title: Text(
            'Emoji Copied! $emojiCode',
            style: _emojiTextStyle.copyWith(fontSize: 24),
          ),
          content: Text(
            'The emoji has been copied to your clipboard. Follow these steps to use it:\n\n'
                '1. Open your messaging app (like WhatsApp).\n'
                '2. Go to the chat where you want to use the emoji.\n'
                '3. Long-press the box where you type your message.\n'
                '4. Select "Paste" to insert the emoji.',
            style: const TextStyle(fontSize: 20),
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
          title: const Text('How to Paste the Emoji'),
          content: SizedBox(
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
  final TextStyle _emojiTextStyle = TextStyle(
    fontFamily: 'WhatsappEmoji',
    fontSize: 40, // Adjust the size as needed
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emoji Meaning App'),
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
              style: const TextStyle(fontSize: 20), // Increased font size for the input
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
                        style: const TextStyle(fontSize: 22), // Larger text for title
                      ),
                      subtitle: Text(
                        emoji['meaning']!,
                        style: const TextStyle(fontSize: 18), // Larger text for subtitle
                      ),
                      onTap: () {
                        _showAssociatedNames(context, emoji['emoji']!, emoji['associated_names']);
                      },
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.75, // 75% width of the screen
                      child: const Divider(thickness: 2), // Add divider between emojis
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
