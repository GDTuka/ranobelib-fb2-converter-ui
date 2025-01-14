import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/cmd_run.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? selectedDirectory;
  String? error;

  bool isLoading = false;

  Future<void> _writeConfig() async {
    setState(() {
      error = null;
    });
    if (_fileNameController.text.isEmpty) {
      setState(() {
        error = 'Введите имя файла';
      });
      return;
    }
    if (selectedDirectory == null) {
      setState(() {
        error = 'Выберите папку';
      });

      return;
    }
    if (_urlController.text.isEmpty) {
      setState(() {
        error = 'Введите url';
      });

      return;
    }
    setState(() {
      isLoading = true;
    });
    final exePath = await getExecutablePath('assets/ranobelib.parser.exe');

    final map = <String, dynamic>{
      "bookName": _fileNameController.text,
      "url": _urlController.text,
      "apiUrl": _urlController.text.replaceAll("https://ranobelib.me/ru", "https://api2.mangalib.me/api/manga"),
      "outputDir": _filePathController.text.replaceAll("\\", "/")
    };

    try {
      final res = await runExecutableArguments(exePath, [jsonEncode(map)]);
      if (res.exitCode != 0) {
        setState(() {
          error = res.stderr;
        });
      }
    } on Object catch (e) {
      error = e.toString();
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<String> getExecutablePath(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/${assetPath.split('/').last}';
    final file = File(tempPath);
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return tempPath;
  }

  Future<void> _getSavingPath() async {
    selectedDirectory = await FilePicker.platform.getDirectoryPath();
    _filePathController.text = selectedDirectory ?? '';
  }

  final TextEditingController _fileNameController = TextEditingController();

  final TextEditingController _filePathController = TextEditingController();

  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (error != null) ...[
              Text(error!, style: const TextStyle(color: Colors.red, fontSize: 20)),
              const SizedBox(height: 20),
            ],
            const Text('Введите url страницы'),
            const Text('Пример: https://ranobelib.me/ru/15630--mushoku-tensei'),
            const SizedBox(height: 8),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'URL',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Введите имя сохраняемого файла'),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextField(
                  controller: _fileNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Имя файла',
                  )),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text('Укажите куда сохранять файл'),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: GestureDetector(
                onTap: _getSavingPath,
                child: TextField(
                    controller: _filePathController,
                    enabled: false,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Путь',
                    )),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: ElevatedButton(
                onPressed: _writeConfig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Сохранить',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
