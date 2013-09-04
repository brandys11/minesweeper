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
    game.mines = (game.size*game.size)~/10;
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
  bool lost=false;
  
  Timer timer;
  
  DivElement container;
  List<List<Cell>> board;
  MouseEvent specialMouseEvent = new MouseEvent("Show");
  
  Game(DivElement this.container){
    init();  
  }
  
  init(){
    container.children.clear();
        
    lost=false;
    
    toTurnLeft = size*size-mines;
    stopTimer();
    query('#time').text = 0.toString();
    query('#mines').text = mines.toString();
        
    container.style..height = (size*20).toString() + '.px'
                   ..width = (size*20).toString() + '.px';
    
    board = new List.generate(size, (i){
      return new List.generate(size,(j){
        return new Cell(container,i,j);
      }, growable: false);
    }, growable: false);
    
    List<bool> bombs = new List.filled(size*size,false);
    for(int i=0;i<mines;i++)bombs[i]=true;
    bombs = shuffle(bombs);
    
    for(int i=0;i<size*size;i++){
      if(bombs[i]){
        board[i~/size][i%size].bomb();
        for(int j=-1;j<2;j++)
          for(int k=-1;k<2;k++)
            try { board[i~/size+j][i%size+k].bombsAround++; }
            catch(e){;}
      }
    }
  }
  startTimer(){
    if(timer==null)
      timer = new Timer.periodic(new Duration(seconds:1), (t) {
        query('#time').text = (int.parse(query('#time').text)+1).toString();
      });
  }
  stopTimer(){
    if(timer!=null){
      timer.cancel();
      timer=null;
    }
  }
  
  lose(){
    game.lost = true;
    timerSun.cancel();
    query('#sun').attributes['src'] = 'images/sad.jpg';
    window.alert('Prehrali ste!!!');
  }
  
  win(){
    if(lost)return;
    timer.cancel();
    timerSun.cancel();
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
  
  show(MouseEvent e){
    waitingSun(300);
    game.startTimer();
    
    if(( e.button==0 
        && !div.classes.contains("flag") )
        || e.type=='Show'){ 
      if(type){
        div.classes.add("bomb");
        game.lose();
      }
      else {
        if(bombsAround>0) 
          div..text = bombsAround.toString()
             ..classes.add('number');
        else div.classes.add("blank");
        if(!_turned) game.toTurnLeft--;
      }
      
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