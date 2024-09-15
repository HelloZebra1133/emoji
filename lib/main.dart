import 'package:flutter/material.dart';
import 'dart:convert'; // Import for JSON parsing
import 'package:flutter/services.dart' show rootBundle;

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
        // If search text is not empty, filter the emojis
        _filteredEmojis = emojiMap.values
            .where((emoji) {
          String emojiChar = emoji['emoji'];
          String mainName = emoji['main_name'].toLowerCase();
          String meaning = emoji['meaning'].toLowerCase();
          List<String> associatedNames = List<String>.from(emoji['associated_names']);

          // Check if emoji matches the search text
          if (emojiChar.contains(_searchText)) {
            return true;
          }
          if (mainName.contains(_searchText) || meaning.contains(_searchText)) {
            return true;
          }
          return associatedNames.any(
                  (String associatedName) => associatedName.toLowerCase().contains(_searchText));
        })
            .map((emoji) {
          // Find the best match for the search text in associated names
          String bestMatch = List<String>.from(emoji['associated_names'])
              .firstWhere((String name) => name.toLowerCase().contains(_searchText), orElse: () => emoji['main_name']);

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
          title: Text('Associated Names $emojiCode'), // Dynamic title with emoji code
          content: SingleChildScrollView( // Make the content scrollable
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: associatedNames
                  .map((name) => ListTile(
                title: Text(name),
              ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

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
                        style: const TextStyle(fontSize: 40), // Increased emoji size
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
