import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';

class ImageViewer extends StatefulWidget {
  final Client client;
  final Question question;
  final Function(String?) setUrl;
  const ImageViewer({
    super.key,
    required this.client,
    required this.question,
    required this.setUrl,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  @override
  Widget build(BuildContext context) {
    if (widget.question.imageUrl == null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            _onImageTap();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                style: BorderStyle.solid,
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_a_photo,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: Image.network(widget.question.imageUrl!, fit: BoxFit.contain),
      );
    }
  }

  void _onImageTap() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Enter Image URL'),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(hintText: "Image URL"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (Uri.tryParse(
                                    controller.text,
                                  )?.hasAbsolutePath ??
                                  false) {
                                widget.setUrl(controller.text);
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Invalid image URL')),
                                );
                              }
                            },
                            child: Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: Icon(Icons.add_link),
                tooltip: 'Add Image Url',
              ),
              IconButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                        type: FileType.custom,
                        allowedExtensions: [
                          'jpg',
                          'png',
                          'jpeg',
                          'webp',
                          'bmp',
                        ],
                        allowMultiple: false,
                        dialogTitle: 'Select an image',
                      );
                  if (result != null) {
                    try {
                      final File file = await uploadFile(
                        client: widget.client,
                        path: result.files.single.path!,
                      );
                      widget.setUrl(fileToPath(file: file));
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error uploading image: $e')),
                      );
                      return;
                    }
                  }
                },
                icon: Icon(Icons.file_copy),
                tooltip: 'From Computer',
              ),
              IconButton(
                onPressed: () {
                  widget.setUrl(null);
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.delete),
                tooltip: 'Remove Image',
              ),
            ],
          ),
        );
      },
    );
  }
}
