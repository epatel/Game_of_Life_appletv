#import "LifeView.h"

#define CELL_SIZE 40

@implementation LifeView {
    NSInteger _width;
    NSInteger _height;
    CGFloat _cursorX;
    CGFloat _cursorY;
    CGPoint _panStart;
    NSInteger *_cells;
    NSTimer *_timer;
}

#define INDEX(_x, _y) ((NSInteger)(_x) + (NSInteger)(_y)*_width)
#define SAFEINDEX(_x, _y) ((NSInteger)((_x+_width)%_width) + (NSInteger)((_y+_height)%_height)*_width)

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    _width = self.frame.size.width/CELL_SIZE;
    _height = self.frame.size.height/CELL_SIZE;
    
    _cells = (NSInteger*)malloc(sizeof(NSInteger)*_width*_height);
    memset(_cells, 0, sizeof(NSInteger)*_width*_height);
    
    _cursorX = _width / 2;
    _cursorY = _height / 2;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:panGesture];
    
    [self loadSavedDesign];
    
    return self;
}

- (void)loadSavedDesign
{
    NSData *design = [[NSUserDefaults standardUserDefaults] objectForKey:@"design"];
    if (design.length == sizeof(NSInteger)*_width*_height) {
        memcpy(_cells, design.bytes, design.length);
    } else {
        [self loadRandomDesign];
    }
}

- (void)saveDesign
{
    NSData *design = [NSData dataWithBytes:_cells length:sizeof(NSInteger)*_width*_height];
    [[NSUserDefaults standardUserDefaults] setObject:design forKey:@"design"];
}

- (void)drawSimpleStringGfx:(NSArray*)rows atX:(NSInteger)x Y:(NSInteger)y
{
    NSInteger rowIndex = 0;
    for (NSString *row in rows) {
        for (NSInteger pos=0; pos<row.length; pos++) {
            if ([row characterAtIndex:pos] == 'O') {
                _cells[SAFEINDEX(x+pos, y+rowIndex)] = 1;
            }
        }
        rowIndex++;
    }
}

- (void)loadRandomDesign
{
    NSArray *things = @[
                        // http://www.argentum.freeserve.co.uk/lex_g.htm#glider
                        
                        @[
                             @".O.",
                             @"..O",
                             @"OOO"
                             
                             ],
                         
                         @[
                             @"OO.",
                             @"O.O",
                             @"O.."
                             
                             ],
                         
                         @[
                             @".OO",
                             @"O.O",
                             @"..O"
                             
                             ],
                         
                         @[
                             @".O.",
                             @"O..",
                             @"OOO"
                             
                             ],
                        
                        // http://www.argentum.freeserve.co.uk/lex_c.htm#clock
                        
                         @[
                             @"..O.",
                             @"O.O.",
                             @".O.O",
                             @".O.."
                             
                             ],
                        
                        // http://www.argentum.freeserve.co.uk/lex_g.htm#glidersbythedozen
                        
                         @[
                             @"OO..O",
                             @"O...O",
                             @"O..OO"
                             
                             ]
                         
                         ];
    
    for (NSInteger i=0; i<5; i++) {
        NSArray *randomThing = things[arc4random() % things.count];
        [self drawSimpleStringGfx:randomThing
                              atX:arc4random()%(_width-[randomThing[0] length])
                                Y:arc4random()%(_height-randomThing.count)];
    }
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    for (UIPress *press in presses) {
        
        if (press.type == UIPressTypeSelect) {
            NSInteger cell = _cells[INDEX(_cursorX, _cursorY)];
            cell = 1 - cell;
            _cells[INDEX(_cursorX, _cursorY)] = cell;
            return;
        }

        if (press.type == UIPressTypeMenu) {
            if (_timer) {
                [_timer invalidate];
                _timer = nil;
                [self loadSavedDesign];
                [self setNeedsDisplay];
                return;
            }
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Conway's Game of Life"
                                                                           message:@"The Game of Life, also known simply as Life, is a cellular automaton devised by the British mathematician John Horton Conway in 1970"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *runAction = [UIAlertAction actionWithTitle:@"Run" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  [self saveDesign];
                                                                  if (!_timer) {
                                                                      _timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                                                                                target:self
                                                                                                              selector:@selector(runTick:)
                                                                                                              userInfo:nil
                                                                                                               repeats:YES];
                                                                  }
                                                              }];
            
            UIAlertAction *randomAction = [UIAlertAction actionWithTitle:@"Random" style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                     memset(_cells, 0, sizeof(NSInteger)*_width*_height);
                                                                     [self loadRandomDesign];
                                                                     [self setNeedsDisplay];
                                                                 }];
            
            UIAlertAction *clearAction = [UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    memset(_cells, 0, sizeof(NSInteger)*_width*_height);
                                                                    [self saveDesign];
                                                                    [self setNeedsDisplay];
                                                                }];
            
            [alert addAction:runAction];
            [alert addAction:randomAction];
            [alert addAction:clearAction];
            
            [_mainViewController presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)runTick:(NSTimer*)timer
{
    NSInteger *neighbors = (NSInteger*)malloc(sizeof(NSInteger)*_width*_height);
    memset(neighbors, 0, sizeof(NSInteger)*_width*_height);
    for (NSInteger y=0; y<_height; y++) {
        for (NSInteger x=0; x<_width; x++) {
            neighbors[INDEX(x, y)] =
            _cells[SAFEINDEX(x+1, y+1)] +
            _cells[SAFEINDEX(x+1, y)] +
            _cells[SAFEINDEX(x+1, y-1)] +
            _cells[SAFEINDEX(x, y+1)] +
            _cells[SAFEINDEX(x, y-1)] +
            _cells[SAFEINDEX(x-1, y+1)] +
            _cells[SAFEINDEX(x-1, y)] +
            _cells[SAFEINDEX(x-1, y-1)];
        }
    }
    for (NSInteger y=0; y<_height; y++) {
        for (NSInteger x=0; x<_width; x++) {
            NSInteger index = INDEX(x, y);
            if (_cells[index]) {
                if (neighbors[index] < 2 ||
                    neighbors[index] > 3) {
                    _cells[index] = 0;
                }
            } else {
                if (neighbors[index] == 3) {
                    _cells[index] = 1;
                }
            }
        }
    }
    free(neighbors);
    [self setNeedsDisplay];
}

- (void)panGesture:(UIPanGestureRecognizer*)gesture
{
    if (_timer) {
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _panStart = [gesture locationInView:self];
    }
    
    CGPoint p = [gesture locationInView:self];
    
    CGFloat dx = p.x - _panStart.x;
    CGFloat dy = p.y - _panStart.y;

    _panStart = p;

    _cursorX += dx / (CELL_SIZE*3.0);
    _cursorY += dy / (CELL_SIZE*3.0);

    while (_cursorX > _width) {
        _cursorX -= _width;
    }
    while (_cursorY > _height) {
        _cursorY -= _height;
    }
    while (_cursorX < 0) {
        _cursorX += _width;
    }
    while (_cursorY < 0) {
        _cursorY += _height;
    }
    
    [self setNeedsDisplay];
}

- (UIBezierPath*)pathForCellatX:(NSInteger)x Y:(NSInteger)y
{
    CGRect cursorRect;
    cursorRect.origin.x = x * CELL_SIZE;
    cursorRect.origin.y = y * CELL_SIZE;
    cursorRect.size = CGSizeMake(CELL_SIZE, CELL_SIZE);
    cursorRect.size.width -= 1;
    cursorRect.size.height -= 1;
    return [UIBezierPath bezierPathWithRoundedRect:cursorRect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(4, 4)];
}

- (void)drawRect:(CGRect)rect
{
    [[UIColor colorWithWhite:0.2 alpha:1.0] set];
    [[UIBezierPath bezierPathWithRect:rect] fill];
    
    CGSize size = self.frame.size;
    
    UIBezierPath *paths = [UIBezierPath bezierPath];
    
    for (NSInteger x=0; x<_width; x++) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(x * CELL_SIZE, 0)];
        [path addLineToPoint:CGPointMake(x * CELL_SIZE, size.height)];
        [paths appendPath:path];
    }

    for (NSInteger y=0; y<_height; y++) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(0, y * CELL_SIZE)];
        [path addLineToPoint:CGPointMake(size.width, y * CELL_SIZE)];
        [paths appendPath:path];
    }
    
    [[UIColor blackColor] setStroke];
    [paths stroke];

    UIBezierPath *cellPaths = [UIBezierPath bezierPath];
    for (NSInteger y=0; y<_height; y++) {
        for (NSInteger x=0; x<_width; x++) {
            if (_cells[INDEX(x, y)]) {
                UIBezierPath *path = [self pathForCellatX:x Y:y];
                [cellPaths appendPath:path];
            }
        }
    }

    [[UIColor greenColor] setFill];
    [cellPaths fill];
    
    if (!_timer) {
        [[UIColor colorWithRed:1 green:1 blue:0 alpha:0.5] set];
        [[self pathForCellatX:_cursorX Y:_cursorY] fill];
    }
}

@end
