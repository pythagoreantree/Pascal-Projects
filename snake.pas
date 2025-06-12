program SnakeGame;

uses crt;

const
	star = '*';
	at = '@';
	empty = ' ';
	finalMessage = 'GAME OVER';
	initLength = 25;
	minVelocity = 25;
	initVelocity = 300;
	showInterval = 3000;
	velocityDelta = 25;
	leftArrow = -75;
	rightArrow = -77;
	upArrow = -72;
	downArrow = -80;
	enter = 13;

type
	Coords = record
		x, y: longint;
	end;
	Element = record
		symbol: char;
		coords: Coords;
	end;
	ListItemPtr = ^ListItem;
	ListItem = record
		elem: Element;
		next: ListItemPtr;
	end;
	Direction = record
		dx, dy: longint;
	end;
	SnakeEntity = record
		head, tail: ListItemPtr;
		direction: Direction;
		velocity: integer;
	end;
	FoodEntity = record
		symbol: char;
		coords: Coords;
	end;

procedure GetKey(var code: integer);
var
	c: char;
begin
	c := ReadKey;
	if c = #0 then
	begin
		c := ReadKey;
		code := -ord(c)
	end
	else
	begin
		code := ord(c)
	end
end;

procedure AddToHead(elem: Element; var snake: SnakeEntity);
var
	tmp: ListItemPtr;
begin
	new(tmp);
	tmp^.elem := elem;
	tmp^.next := snake.head;
	snake.head := tmp;
	if snake.tail = nil then
		snake.tail := snake.head
end;

procedure AddToTail(elem: Element; var snake: SnakeEntity);
var
	tmp: ListItemPtr;
begin
	new(tmp);
	tmp^.elem := elem;
	tmp^.next := nil;
	if snake.tail <> nil then
		snake.tail^.next := tmp;
	snake.tail := tmp;
	if snake.head = nil then
		snake.head := snake.tail
end;

procedure RemoveTail(var snake: SnakeEntity);
var
	current, tmp: ListItemPtr;
begin
	current := snake.head;
	tmp := snake.tail;
	while current^.next <> tmp do
		current := current^.next;
	snake.tail := current;
	snake.tail^.next := nil;
	dispose(tmp)
end;

procedure InitSnake(var snake: SnakeEntity);
var
	i: integer;
	startX, startY: longint;
	elem: Element;
begin
	snake.head := nil;
	snake.tail := nil;

	startX := (ScreenWidth - initLength) div 2;
	startY := ScreenHeight div 2;
	for i := 0 to (initLength - 1) do
	begin
		if i = 0 then
			elem.symbol := at
		else
			elem.symbol := star;
		elem.coords.x := startX + i;
		elem.coords.y := startY;
		AddToTail(elem, snake);
	end;

	snake.direction.dx := -1;
	snake.direction.dy := 0;

	snake.velocity := initVelocity
end;

procedure ShowSymbol(coords: Coords; symbol: char);
begin
	GotoXY(coords.x, coords.y);
	write(symbol);
	GotoXY(1, 1)
end;

procedure ShowElement(elem: Element);
begin
	ShowSymbol(elem.coords, elem.symbol)
end;

procedure ShowSnake(var snake: SnakeEntity);
var
	current: ListItemPtr;
begin
	current := snake.head;
	while current <> nil do
	begin
		ShowElement(current^.elem);
		current := current^.next
	end
end;

procedure SetSymbolInHead(symbol: char; var snake: SnakeEntity);
begin
	if snake.head = nil then
	begin
		clrscr;
		writeln('ERROR: SetHeadSymbol: Snake has no head!');
		delay(showInterval);
		halt(2)
	end;
	snake.head^.elem.symbol := symbol
end;

function SameCoords(coords1, coords2: Coords): boolean;
begin
	SameCoords := (coords1.x = coords2.x) and (coords1.y = coords2.y)
end;

function CoordsInSnake(coords: Coords; var snake: SnakeEntity): boolean;
var
	current: ListItemPtr;
begin
	current := snake.head;
	while current <> nil do
	begin
		if SameCoords(current^.elem.coords, coords) then
		begin
			CoordsInSnake := true;
			exit
		end;
		current := current^.next
	end;
	CoordsInSnake := false
end;

function GetNewHeadCoords(var snake: SnakeEntity): Coords;
var
	elemCoords: Coords;
begin
	if snake.head = nil then
	begin
		clrscr;
		writeln('ERROR: GetHeadCoords: Snake has no head!');
		delay(showInterval);
		halt(2)
	end;
	
	elemCoords.x := snake.head^.elem.coords.x + snake.direction.dx;
	if elemCoords.x < 1 then
		elemCoords.x := ScreenWidth - 1;
	if elemCoords.x > (ScreenWidth - 1) then
		elemCoords.x := 1;

	elemCoords.y := snake.head^.elem.coords.y + snake.direction.dy;
	if elemCoords.y < 1 then
		elemCoords.y := (ScreenHeight - 1);
	if elemCoords.y > (ScreenHeight - 1) then
		elemCoords.y := 1;

	GetNewHeadCoords := elemCoords
end;

function GetNewTailCoords(var snake: SnakeEntity): Coords;
var
	elemCoords: Coords;
begin
	if snake.tail = nil then
	begin
		clrscr;
		writeln('ERROR: GetTailCoords: Snake has no tail!');
		delay(showInterval);
		halt(2)
	end;
	elemCoords.x := snake.tail^.elem.coords.x;
	elemCoords.y := snake.tail^.elem.coords.y;

	if (snake.direction.dx <> 0) and (snake.direction.dy = 0) then
		elemCoords.x := elemCoords.x - snake.direction.dx;
	if elemCoords.x < 1 then
		elemCoords.x := ScreenWidth - 1;
	if elemCoords.x > (ScreenWidth - 1) then
		elemCoords.x := 1;

	if (snake.direction.dx = 0) and (snake.direction.dy <> 0) then
		elemCoords.y := elemCoords.y - snake.direction.dy;
	if elemCoords.y < 1 then
		elemCoords.y := ScreenHeight - 1;
	if elemCoords.y > (ScreenHeight - 1) then
		elemCoords.y := 1;

	GetNewTailCoords := elemCoords
end;

procedure GameOver;
var
	x, y: longint;
begin
	clrscr;

	x := (ScreenWidth - length(finalMessage)) div 2;
	y := ScreenHeight div 2;

	GotoXY(x, y);
	writeln(finalMessage);
	GotoXY(1, 1);

	while not KeyPressed do
		delay(showInterval);
	clrscr;

	halt(3)
end;

procedure Move(var snake: SnakeEntity);
var
	tailCoords: Coords;
	headElem: Element;
begin
	if snake.tail = nil then
	begin
		clrscr;
		writeln('ERROR: Move: Snake has no tail!');
		delay(showInterval);
		halt(2)
	end;
	tailCoords := snake.tail^.elem.coords;
	ShowSymbol(tailCoords, empty);
	RemoveTail(snake);

	headElem.symbol := at;
	headElem.coords := GetNewHeadCoords(snake);
	if CoordsInSnake(headElem.coords, snake) then
		GameOver;
	SetSymbolInHead(star, snake);
	AddToHead(headElem, snake);

	if snake.head = nil then
	begin
		clrscr;
		writeln('ERROR: Move: Snake has no head!');
		delay(showInterval);
		halt(2)
	end;
	ShowElement(snake.head^.elem);

	if snake.head^.next = nil then
	begin
		clrscr;
		writeln('ERROR: Move: Snake is too short!');
		delay(showInterval);
		halt(2)
	end;
	ShowElement(snake.head^.next^.elem);

	delay(snake.velocity)
end;

function SameDirection(var s: SnakeEntity; dx, dy: longint): boolean;
begin
	SameDirection := (s.direction.dx = dx) and (s.direction.dy = dy)
end;

function OppositeByXorY(var s: SnakeEntity; dx, dy: longint): boolean;
var
	oppositeByX, oppositeByY: boolean;
begin
	oppositeByX := (s.direction.dx = -dx) and (s.direction.dy = 0);
	oppositeByY := (s.direction.dx = 0) and (s.direction.dy = -dy);
	oppositeByXorY := oppositeByX or oppositeByY
end;

procedure ChangeDirection(var s: SnakeEntity; dx, dy: longint);
begin
	if SameDirection(s, dx, dy) then
		exit;
	if OppositeByXorY(s, dx, dy) then
		exit;
	s.direction.dx := dx;
	s.direction.dy := dy
end;

procedure InitFood(var food: FoodEntity);
begin
	food.symbol := star;
	food.coords.x := 1;
	food.coords.y := 1
end;

function GetRandomCoords: Coords;
var
	randCoords: Coords;
begin
	randCoords.x := random(ScreenWidth - 1) + 1;
	randCoords.y := random(ScreenHeight - 1) + 1;
	GetRandomCoords := randCoords
end;

procedure ShowFood(var food: FoodEntity; var snake: SnakeEntity);
var
	newFoodCoords: Coords;
begin
	repeat
		newFoodCoords := GetRandomCoords
	until not CoordsInSnake(newFoodCoords, snake);
	food.coords := newFoodCoords;
	ShowSymbol(food.coords, food.symbol)
end;

procedure Fasten(var snake: SnakeEntity);
begin
	snake.velocity := snake.velocity - velocityDelta;
	if snake.velocity < 25 then
		snake.velocity := minVelocity
end;

procedure Update(var snake: SnakeEntity);
var
	elem: Element;
begin
	elem.symbol := star;
	elem.coords := GetNewTailCoords(snake);
	AddToTail(elem, snake);
	Fasten(snake)
end;

var
	snake: SnakeEntity;
	food: FoodEntity;
	c: integer;
begin
	randomize;
	clrscr;

	InitSnake(snake);
	InitFood(food);
	
	ShowSnake(snake);
	ShowFood(food, snake);
	delay(snake.velocity);

	while true do
	begin
		if KeyPressed then
		begin
			GetKey(c);
			case c of
				leftArrow:
					ChangeDirection(snake, -1, 0);
				rightArrow:
					ChangeDirection(snake, 1, 0);
				upArrow:
					ChangeDirection(snake, 0, -1);
				downArrow:
					ChangeDirection(snake, 0, 1);
				enter:
					break
			end
		end;
		Move(snake);
		if CoordsInSnake(food.coords, snake) then
		begin
			Update(snake);
			ShowFood(food, snake)
		end
	end;

	clrscr
end.
