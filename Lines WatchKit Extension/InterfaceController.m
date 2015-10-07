//
//  InterfaceController.m
//  Lines WatchKit Extension
//
//  Created by Carl on 6/30/15.
//  Copyright © 2015 Carl Gorringe. All rights reserved.
//
//  This work is licensed under the the terms of the GNU General Public License version 3 (GPLv3)
//  http://www.gnu.org/licenses/gpl-3.0.html
//

#import "InterfaceController.h"
#import <math.h>

const int kNumLines  = 30;
const int kSkipMin   = 3;
const int kSkipMax   = 10;
const int k38mmWidth = 136;  // 38mm watch is 136 x 170 pts

typedef struct LLine_t {
  CGPoint start;
  CGPoint end;
} LLine;


@interface InterfaceController ()

@property (assign, nonatomic) CGSize mainSize;
@property (strong, nonatomic) UIImage *linesImg;
@property (strong, nonatomic) NSTimer *linesTimer;

@end


@implementation InterfaceController

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Watch Lifecycle

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  // Configure interface objects here.
}

- (void)willActivate {
  // This method is called when watch view controller is about to be visible to user
  [super willActivate];
  
  // start the lines
  if (!self.linesTimer) {
    [self startLinesTimer];
  }
}

- (void)didDeactivate {
  // This method is called when watch view controller is no longer visible
  [self stopLinesTimer];
  [super didDeactivate];
}

- (CGSize)mainSize {
  return CGSizeEqualToSize(_mainSize, CGSizeZero) ? mainImageSize() : _mainSize;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Helper functions

int randomInt(int min, int max) {
  // Random int in range min to max inclusive
  return (arc4random_uniform(max - min + 1) + min);
}

CGSize mainImageSize() {
  // Returns an image size that fills the available space under the status bar (in points)

  // Since we're unable to query the WKInterfaceImage for it's size, we need to
  // calculate it ourselves based on the watch's size.
  int width, height;
  CGRect rect = [[WKInterfaceDevice currentDevice] screenBounds];
  width = rect.size.width;

  // status bar differs slightly in height depending on size of watch
  // and we want to subtract this from the screen's height.
  if (width <= k38mmWidth) {
    // 38mm watch is 136 x 170 pts, status bar 19 pts high.
    height = rect.size.height - 19;
  }
  else {
    // 42mm watch is 156 x 195 pts, status bar 21 pts high.
    height = rect.size.height - 21;
  }

  return CGSizeMake(width, height);
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Timers

- (void)startLinesTimer {
  // Setup recurring timer for lines animation

  [self nextLine:YES];  // reset first line
  self.linesTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05f
                                                 target: self
                                               selector: @selector(drawTimer:)
                                               userInfo: nil
                                                repeats: YES ];
}

- (void)stopLinesTimer {

  if (self.linesTimer) {
    [self.linesTimer invalidate];
    self.linesTimer = nil;
  }
}

- (void)drawTimer:(NSTimer *)timer {

  UIGraphicsBeginImageContext(self.mainSize);
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  if (ctx) {
    if (self.linesImg) {
      [self.linesImg drawInRect:CGRectMake(0, 0, self.mainSize.width, self.mainSize.height) blendMode:kCGBlendModeNormal alpha:0.95];
    }
    [self drawNextLine:ctx];
    self.linesImg = UIGraphicsGetImageFromCurrentImageContext();
    [self.mainImg setImage:self.linesImg];
  }
  UIGraphicsEndImageContext();
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Lines

- (CGColorRef)nextColor:(BOOL)reset {

  static int count = 0;
  static int oldR = 0, oldG = 0, oldB = 0;
  static int newR = 0, newG = 0, newB = 0;
  static int skpR = 0, skpG = 0, skpB = 0;
  static int curR = 0, curG = 0, curB = 0;

  if (reset) { count = 0; }
  
  count--;
  if (count < 0) {
    count = 15;
    oldR = newR; newR = randomInt(0, 1) * 255;
    oldG = newG; newG = randomInt(0, 1) * 255;
    oldB = newB; newB = randomInt(0, 1) * 255;
    skpR = (newR == oldR) ? 0 : ((newR > oldR) ? 16 : -16);
    skpG = (newG == oldG) ? 0 : ((newG > oldG) ? 16 : -16);
    skpB = (newB == oldB) ? 0 : ((newB > oldB) ? 16 : -16);
    curR = oldR;
    curG = oldG;
    curB = oldB;
  }
  curR += skpR;
  curG += skpG;
  curB += skpB;

  return [[UIColor colorWithRed:(curR / 256.0f) green:(curG / 256.0f) blue:(curB / 256.0f) alpha:1] CGColor];
}

- (LLine)nextLine:(BOOL)reset {

  static LLine line;
  static LLine skip;

  if (reset) {
    // randomly position a new line
    line.start.x = randomInt(0, self.mainSize.width);
    line.start.y = randomInt(0, self.mainSize.height);
    line.end.x   = randomInt(0, self.mainSize.width);
    line.end.y   = randomInt(0, self.mainSize.height);

    // random skip values
    skip.start.x = (randomInt(0, 1)) ? randomInt(kSkipMin, kSkipMax) : -randomInt(kSkipMin, kSkipMax);
    skip.start.y = (randomInt(0, 1)) ? randomInt(kSkipMin, kSkipMax) : -randomInt(kSkipMin, kSkipMax);
    skip.end.x   = (randomInt(0, 1)) ? randomInt(kSkipMin, kSkipMax) : -randomInt(kSkipMin, kSkipMax);
    skip.end.y   = (randomInt(0, 1)) ? randomInt(kSkipMin, kSkipMax) : -randomInt(kSkipMin, kSkipMax);
  }
  else {
    // move the line
    line.start.x += skip.start.x;
    line.start.y += skip.start.y;
    line.end.x   += skip.end.x;
    line.end.y   += skip.end.y;

    // reverse direction of step values of points that hit border
    if (line.start.x < 0)                     { skip.start.x = randomInt(kSkipMin, kSkipMax);      }
    if (line.start.x >= self.mainSize.width)  { skip.start.x = randomInt(kSkipMin, kSkipMax) * -1; }
    if (line.start.y < 0)                     { skip.start.y = randomInt(kSkipMin, kSkipMax);      }
    if (line.start.y >= self.mainSize.height) { skip.start.y = randomInt(kSkipMin, kSkipMax) * -1; }
    if (line.end.x   < 0)                     { skip.end.x   = randomInt(kSkipMin, kSkipMax);      }
    if (line.end.x   >= self.mainSize.width)  { skip.end.x   = randomInt(kSkipMin, kSkipMax) * -1; }
    if (line.end.y   < 0)                     { skip.end.y   = randomInt(kSkipMin, kSkipMax);      }
    if (line.end.y   >= self.mainSize.height) { skip.end.y   = randomInt(kSkipMin, kSkipMax) * -1; }
  }

  return line;
}

- (void)drawFourLinesUsing:(LLine)line inContext:(CGContextRef)ctx {

  CGContextSetLineWidth(ctx, 1);
  CGContextSetShouldAntialias(ctx, YES);

  // line 1
  CGContextMoveToPoint(ctx, line.start.x, line.start.y);
  CGContextAddLineToPoint(ctx, line.end.x, line.end.y);
  // line 2
  CGContextMoveToPoint(ctx, self.mainSize.width - line.start.x, line.start.y);
  CGContextAddLineToPoint(ctx, self.mainSize.width - line.end.x, line.end.y);
  // line 3
  CGContextMoveToPoint(ctx, line.start.x, self.mainSize.height - line.start.y);
  CGContextAddLineToPoint(ctx, line.end.x, self.mainSize.height - line.end.y);
  // line 4
  CGContextMoveToPoint(ctx, self.mainSize.width - line.start.x, self.mainSize.height - line.start.y);
  CGContextAddLineToPoint(ctx, self.mainSize.width - line.end.x, self.mainSize.height - line.end.y);

  CGContextStrokePath(ctx);
}

- (void)drawNextLine:(CGContextRef)ctx {

  CGContextSetStrokeColorWithColor(ctx, [self nextColor:NO]);
  [self drawFourLinesUsing:[self nextLine:NO] inContext:ctx];
}


////////////////////////////////////////////////////////////////////////////////
@end
