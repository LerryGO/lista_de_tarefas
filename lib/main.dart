// ignore_for_file: use_key_in_widget_constructors

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic>? _lastRemoved;
  int? _lastRemovedPost;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    _toDoController.text.isEmpty
        ? ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              "O Campo deve ser preenchido",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ))
        : setState(() {
            Map<String, dynamic> newToDo = Map();
            newToDo['title'] = _toDoController.text;
            _toDoController.text = '';
            newToDo['ok'] = false;
            _toDoList.add(newToDo);
            _saveData();
          });
  }

  Future<void> _refresh() async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.rocket_launch),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset("assets/team.png"),
                            Text("Integrantes:",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            const Text("Lerry Augusto"),
                            const Text("Viviane Gabriela"),
                            const Text("Gabriel Castro"),
                          ],
                        ),
                      ),
                    );
                  });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: const InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all(Colors.white), // Cor do texto
                    backgroundColor:
                        MaterialStateProperty.all(Colors.blueAccent),
                  ),
                  onPressed: _addToDo,
                  child: const Text("ADD"),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.orange[200]),
            child: const Text("Para excluir a tarefa, arraste para a direita",
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: const Alignment(-0.9, 0),
          child: Row(
            children: const [
              Icon(
                Icons.delete,
                color: Colors.white,
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Excluir",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              )
            ],
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(
          () {
            _lastRemoved = Map.from(
                _toDoList[index]); //salvando o mapa que está sendo excluido
            _lastRemovedPost = index; // pegando o indice dele
            _toDoList.removeAt(index); //removendo o objeto do mapa

            _saveData();

            final snack = SnackBar(
              content: Text("Tarefa \"${_lastRemoved!["title"]}\" removida!"),
              action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPost!,
                        _lastRemoved); //Reinserindo o ultimo objeto excluido do mapa
                    _saveData();
                  });
                },
              ),
              duration: const Duration(seconds: 2),
            );
            ScaffoldMessenger.of(context)
                .removeCurrentSnackBar(); //Removendo a Snackbar atual
            ScaffoldMessenger.of(context)
                .showSnackBar(snack); // Mostrando a nova snackbar
          },
        );
      },
    );
  }

  Future<File> _getFile() async {
    final directory =
        await getApplicationDocumentsDirectory(); // encontrando o diretorio que é permitido salvar no telefone
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(
        _toDoList); // Transformando a Lista em Json e transferindo para uma string
    final file = await _getFile(); // pegando o arquivo em que será salvo
    return file.writeAsString(
        data); //Salvando os arquivos como texto no diterorio inserido
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (err) {
      // ignore: null_check_always_fails
      return null!;
    }
  }
}
