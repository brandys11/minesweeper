library minesweeper;

import 'dart:html';
import 'dart:async';
import 'package:shuffle/shuffle.dart';

Game game;

void main() {
  game = new Game(query('#board'));
  query('#sun').onClick.listen((e) { game.init(); waitingSun(1000); } );
  
  SelectElement list = query('#list');
  list.onChange.listen((e){
    game.size = int.parse(list.value);
    game.mines = (game.size*game.size)~/7;
  });
  list.children.addAll(
      new List.generate(5, 
          (i) => new Element.html('<option value="${(i*5+5).toString()}">${(i*5+5).toString()}</option>')));
}

Timer timerSun;
waitingSun(int milliseconds){
  query('#sun').attributes['src'] = 'images/waiting.jpg';
  timerSun = new Timer(new Duration(milliseconds:milliseconds) , smilingSun);
}
smilingSun(){
  query('#sun').attributes['src'] = 'images/happy.jpg';
}

class Game {
  int size = 5;
  int mines = 2;
  int minesLeft;
  int toTurnLeft;
  
  bool finished=false;
  bool started;
  
  Timer timer;
  
  DivElement container;
  List<List<Cell>> board;
  MouseEvent specialMouseEvent = new MouseEvent("Show");
  
  Game(DivElement this.container){
    init();  
  }
  
  init(){
    stopGame();
    container.children.clear();
        
    finished=false;
    started=false;
    
    toTurnLeft = size*size-mines;
    query('#time').text = 0.toString();
    query('#mines').text = mines.toString();
        
    container.style..height = (size*20).toString() + '.px'
                   ..width = (size*20).toString() + '.px';
    
    board = new List.generate(size, (i){
      return new List.generate(size,(j){
        return new Cell(container,i,j);
      }, growable: false);
    }, growable: false);
  }
  
  /**
   * Put bombs on the board except the neigboaring cells
   */
  putBombs(int x,int y){
    var list = new List<Cell>();
    for(int i=0;i<size*size;i++){
      if(! ((i ~/ size - x ).abs() < 2 && (i % size - y).abs() < 2))
        list.add(board[i~/size][i%size]);
    }
    list = shuffle(list);
    for(int i =0;i<mines;i++){
      list[i].bomb();
      for(int j=-1;j<2;j++)
        for(int k=-1;k<2;k++)
          try { board[list[i].x+j][list[i].y+k].bombsAround++; }
          catch(e){;}
    }
  }
  startGame(int x,int y){
    if(!started){
      started = true;
      putBombs(x,y);
      
      timer = new Timer.periodic(new Duration(seconds:1), (t) {
        query('#time').text = (int.parse(query('#time').text)+1).toString();
      });
    }
  }
  stopGame(){
    if(timer!=null){
      timer.cancel();
      timer=null;
    }
    if(timerSun!=null)
      timerSun.cancel();
    
    finished = true;
    if(board!=null)
      for(List list in board)
        for(Cell cell in list){
          cell.unHide();
      }
  }
  
  lose(){
    if(finished)return;
    stopGame();
    
    query('#sun').attributes['src'] = 'images/sad.jpg';
    window.alert('Prehrali ste!!!');
  }
  
  win(){
    if(finished)return;
    stopGame();
    
    query('#sun').attributes['src'] = 'images/win.png';
    window.alert('Vyhrali ste!!!');
  }
  
  Turned(int x,int y){
    if(board[x][y].turned)return;
    board[x][y].turn();
    
    for(int j=-1;j<2;j++)
      for(int k=-1;k<2;k++)
        try { 
          board[x+j][y+k].show(specialMouseEvent);
          Turned(x+j,y+k);
        }
        catch(e){;}
  }
  
  check(){
    if(toTurnLeft==0)
      win();
  }
  
}

class Cell {
  /**
   * 0 - nothing
   * 1 - bomb
   */
  bool type=false;
  
  bool _turned=false;
  int bombsAround=0;
  DivElement div;
  
  int x,y;
  
  int size=20;
  
  Cell(Node container,int this.x,int this.y,[int size]){
    div = new DivElement()..classes.add("cell")
        ..style.transform = "translate(${x*this.size}.px,${y*this.size}.px)"
        ..onClick.listen(show)
        ..onContextMenu.listen((MouseEvent e){ e.preventDefault(); show(e); });

    container.append(div);
  }
  
  unHide(){
    if(type){
      div.classes.add("bomb");
      game.lose();
    }
    else {
      if(bombsAround>0) 
        div..text = bombsAround.toString()
        ..classes.add('number');
      else div.classes.add("blank");
    }
  }
  show(MouseEvent e){
    waitingSun(300);
    game.startGame(x,y);
    
    if(( e.button==0 
        && !div.classes.contains("flag") )
        || e.type=='Show' && !_turned){ 
      unHide();
      if(!_turned) game.toTurnLeft--;
      
      if(bombsAround==0) game.Turned(x, y);
      game.check();
      _turned = true;
    }
    else if(e.button!=0 && !_turned){
      if(div.classes.contains("flag")){
        query('#mines').text = (int.parse(query('#mines').text)+1).toString();
      }
      else {
        query('#mines').text = (int.parse(query('#mines').text)-1).toString();
      }
      div.classes.toggle("flag");
    }
  }
  
  bomb() => type=true;
  turn() => _turned=true;
  bool get turned => _turned;

}