import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController(); //O campo Edit do texto...

  List _toDoList = []; //Lista que irei armazenar as tarefas...

  Map<String, dynamic> _lastRemoved; //Criando um mapa para guardar o último removido
  int _lastRemovedPos; //inteiro do indice da posição do item removido.

  @override
  void initState() {
    super.initState();

    _readData().then((data) { //Vai chamar a função _readData e o return dela vai entregar o data.
      setState(() { //Atualiza a tela.
        _toDoList = json.decode(data); //Insere o Json na List.
      });
    });
  }

  void _addToDo() {
    setState(() { //Atualiza a tela...
      Map<String, dynamic> newToDo = Map(); //Quando trabalhamos com JSON usamos este...
      newToDo["title"] = _toDoController.text;  //Peguei o texto do textField e coloquei na variavel que tem JSON com titulo title.
      _toDoController.text = ""; //Zerar o textField.
      newToDo["ok"] = false; //Colocar o campo do Json como false.
      _toDoList.add(newToDo); //Adicionando o elemento para a _toDoList.
      _saveData(); //Chama a função que Pega os arquivos e converte pra json e salva no arquivo compras.json...
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1)); //Demore um pouco pra correr, uso o async e um delauy de segundo. Não é bom se usar o serv online
    setState(() { //Atualiza tela
      _toDoList.sort((a, b){ //Ordenacao do Dart. Sempre tem que ter dois argumentos.
        if(a["ok"] && !b["ok"]) return 1; // Ordenacao primeiro pelos OK.
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData(); //Chama a função que Pega os arquivos e converte pra json e salva no arquivo compras.json...
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Compras"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container( //Container será usado para inserir espaçamento... e o restante
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row( // Dentro da linha vou por o texto e o botão de ADD
              children: <Widget>[
                Expanded( //Devo inserir pois aparece erro, porque eu devo informar o quanto de tamanho será ocupado pelo Textfield... Ai coloque o o Expanded
                    child: TextField(
                      controller: _toDoController,
                      decoration: InputDecoration(
                          labelText: "Novo item",
                          labelStyle: TextStyle(color: Colors.blueAccent)
                      ),
                    )
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo, //Chamadno a função la em cima quando clica no botão...
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh, //Atualizar a lista na tela quando segurar o mouse pra baixo...
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0), //Inserir o espaçamento apenas no topo.
                  itemCount: _toDoList.length, //Tamanho da lista...
                  itemBuilder: buildItem),), //Chamando a função buildItem para diminuir o tamanho do codigo
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index){ //funcao pra reduzir o tamanho do codigo.
    return Dismissible( //Widget que permite arrastar para poder remover o item da lista.
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()), //Deve escolher qual o indice, normalmente usamos o tempo em milisegundo.
      background: Container(
        color: Colors.red, //Barra de cor vermelha
        child: Align(
          alignment: Alignment(-0.9, 0.0), //Alinhamento da lixeira
          child: Icon(Icons.delete, color: Colors.white,), //Desenhando uma lixeira qdo desliza
        ),
      ),
      direction: DismissDirection.startToEnd, //Deslizando da esquerda pra direita
      child: CheckboxListTile( //O que irei excluir? meu CheckboxListTile.
        title: Text(_toDoList[index]["title"]), // Recebe o texto...
        value: _toDoList[index]["ok"], // Recebe o true/false ...
        secondary: CircleAvatar( // Muda o icone do avatar da lista caso esteja ok ou com erro.
          child: Icon(_toDoList[index]["ok"] ?
          Icons.check : Icons.error),),
        onChanged: (c){ //Quando houver mudancas, o c é o parametro que va mudar
          setState(() { //Atualiza a lista com o novo estado...
            _toDoList[index]["ok"] = c; //Irá salvar na _toDoList o que eu selecionei true ou false.
            _saveData(); //Chama a função que Pega os arquivos e converte pra json e salva no arquivo compras.json...
          });
        },
      ),
      onDismissed: (direction){ //Função que faz quando eu arrasto pra excluir. No caso como eu só selecionei a direção start to end então ele irá fazer a mesma.
        setState(() { //Atualiza a tela.
          _lastRemoved = Map.from(_toDoList[index]); //Ao deletar, primeiro duplicamos o item
          _lastRemovedPos = index; //Salvamos a posicao que excluimos
          _toDoList.removeAt(index); //Removemos da lista
          _saveData(); //Chama a função que Pega os arquivos e converte pra json e salva no arquivo compras.json...

          final snack = SnackBar( //SnackBar usamos pra mostrar informacao ao usuario.
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"), //O conteudo exibido.
            action: SnackBarAction(label: "Desfazer", //Ação para a SnackBar.
                onPressed: () { //Quando clicar no botão da snackbar
                  setState(() { //Atualiza a tela
                    _toDoList.insert(_lastRemovedPos, _lastRemoved); //Inserimos o item que foi excluido na posicao que tinhamos gravado
                    _saveData(); //Chama a função que Pega os arquivos e converte pra json e salva no arquivo compras.json...
                  });
                }),
            duration: Duration(seconds: 2), //Duração da mensagem...
          );

          Scaffold.of(context).removeCurrentSnackBar(); //Remove a snackbar e abaixo poe uma nova.
          Scaffold.of(context).showSnackBar(snack); //Mostrar a snackbar

        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/compras.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

}

