import 'package:flutter/material.dart';

class SearchResultsDialog extends StatelessWidget {
  final List<dynamic> recordings;

  const SearchResultsDialog({super.key, required this.recordings});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select the correct track'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: recordings.length,
          itemBuilder: (context, index) {
            final recording = recordings[index];
            final title = recording['title'] ?? 'No title';
            // The artist information is a bit nested.
            final artist = recording['artist-credit']?[0]?['name'] ?? 'No artist';

            return ListTile(
              title: Text(title),
              subtitle: Text(artist),
              onTap: () {
                // Return the selected recording to the previous screen.
                Navigator.of(context).pop(recording);
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
