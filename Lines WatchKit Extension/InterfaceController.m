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

const int kNumLines = 30;
const int kSkipMin  = 3;
const int kSkipMax  = 10;

@interface InterfaceController () {

  // line vars (might not need all these here)
  CGPoint pt1[kNumLines], pt2[kNumLines];
  int skipX1, skipY1, skipX2, skipY2;
  int ct, oldct, bt, colr_ct;
  int colRed, colGreen, colBlue;
  int oldRed, oldGreen, oldBlue;
  int newRed, newGreen, newBlue;
  int skipRed, skipGreen, skipBlue;
  //int ptRed[kNumLines], ptGreen[kNumLines], ptBlue[kNumLines];
}

@property (assign, nonatomic) CGSize mainSize;
@property (strong, nonatomic) UIImage *linesImg;
@property (strong, nonatomic) NSTimer *linesTimer;

@end


@implementation InterfaceController

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Watch Lifecycle

- (void)awakeWithContext:(id)context {

  NSLog(@"awakeWithContext");
  [super awakeWithContext:context];
  // Configure interface objects here.
}

- (void)willActivate {
  // This method is called when watch view controller is about to be visible to user

  NSLog(@"willActivate");
  [super willActivate];
  
  self.mainSize = mainImageSize();
  NSLog(@"mainSize: %.0f x %.0f", self.mainSize.width, self.mainSize.height);

  // TEST mainImg
  if (self.mainImg != nil) {
    
  }

  // start the lines
  if (!self.linesTimer) {
    [self setupLinesVars];
    [self resetLines];
    [self startLinesTimer];
  }
}

- (void)didDeactivate {
  // This method is called when watch view controller is no longer visible

  NSLog(@"didDeactivate");
  [self stopLinesTimer];
  [super didDeactivate];
}

/*
- (CGSize)mainSize {
  return ( _mainSize == CGSizeZero ) ? mainImageSize() : _mainSize;
}
//*/

////////////////////////////////////////////////////////////////////////////////
#pragma mark - General functions

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
  if (width < 140) {
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

  NSLog(@"timer started");
  self.linesTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05f
                                                 target: self
                                               selector: @selector(drawTimer:)
                                               userInfo: nil
                                                repeats: YES ];
}

- (void)stopLinesTimer {
  
  NSLog(@"timer stopped");
  if (self.linesTimer) {
    [self.linesTimer invalidate];
    self.linesTimer = nil;
  }
}

- (void)drawTimer:(NSTimer *)timer {

  UIGraphicsBeginImageContext(self.mainSize);  // required or ctx will be nil
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  if (ctx) {
    if (self.linesImg) {
      //[self.linesImg drawInRect:CGRectMake(0, 0, self.mainSize.width, self.mainSize.height)];
      // try this instead for a fade-out effect
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

- (void)setupLinesVars {
  
  // set some const vars
  oldct = 0;
  ct = 1;
  bt = 0;
  skipRed = 0; skipGreen = 0; skipBlue = 0;
  colRed = 0; colGreen = 0; colBlue = 0;
  //for (int i=0; i < kNumLines; i++) {
  //  ptRed[i] = 0; ptGreen[i] = 0; ptBlue[i] = 0;
  //}
}

- (void)resetLines {
  
  // calculate initial skip values
  skipX1 = (randomInt(0, 1)) ? randomInt(kSkipMin, kSkipMax) : -randomInt(kSkipMin, kSkipMax);
  skipY1 = (randomInt(0, 1)) ? randomInt(kSkipMin, kSkipMax) : -randomInt(kSkipMin, kSkipMax);
  skipX2 = (randomInt(0, 1)) ? randomInt(kSkipMin, kSkipMax) : -randomInt(kSkipMin, kSkipMax);
  skipY2 = (randomInt(0, 1)) ? randomInt(kSkipMin, kSkipMax) : -randomInt(kSkipMin, kSkipMax);

  pt1[ct].x = randomInt(0, self.mainSize.width);
  pt1[ct].y = randomInt(0, self.mainSize.height);
  pt2[ct].x = randomInt(0, self.mainSize.width);
  pt2[ct].y = randomInt(0, self.mainSize.height);
  
  newRed   = randomInt(0, 1) * 255;
  newGreen = randomInt(0, 1) * 255;
  newBlue  = randomInt(0, 1) * 255;
  colr_ct = 16;
}

- (void)drawFourLinesFrom:(CGPoint)from To:(CGPoint)to Context:(CGContextRef)ctx {
  
  CGContextSetLineWidth(ctx, 1);
  CGContextSetShouldAntialias(ctx, NO);
  
  // line 1
  CGContextMoveToPoint(ctx, from.x, from.y);
  CGContextAddLineToPoint(ctx, to.x, to.y);
  
  // line 2
  CGContextMoveToPoint(ctx, self.mainSize.width - from.x, from.y);
  CGContextAddLineToPoint(ctx, self.mainSize.width - to.x, to.y);
  
  // line 3
  CGContextMoveToPoint(ctx, from.x, self.mainSize.height - from.y);
  CGContextAddLineToPoint(ctx, to.x, self.mainSize.height - to.y);
  
  // line 4
  CGContextMoveToPoint(ctx, self.mainSize.width - from.x, self.mainSize.height - from.y);
  CGContextAddLineToPoint(ctx, self.mainSize.width - to.x, self.mainSize.height - to.y);
  
  CGContextStrokePath(ctx);
}

- (void)drawNextLine:(CGContextRef)ctx {
  
  // set color
  colr_ct++;
  if (colr_ct >= 15) {
    colr_ct = 0;
    oldRed    = newRed;   newRed   = randomInt(0, 1) * 255;
    oldGreen  = newGreen; newGreen = randomInt(0, 1) * 255;
    oldBlue   = newBlue;  newBlue  = randomInt(0, 1) * 255;
    
    skipRed   = (newRed == oldRed) ? 0 : ((newRed > oldRed) ? 16 : -16);
    skipGreen = (newGreen == oldGreen) ? 0 : ((newGreen > oldGreen) ? 16 : -16);
    skipBlue  = (newBlue == oldBlue) ? 0 : ((newBlue > oldBlue) ? 16 : -16);
    
    colRed   = oldRed;
    colGreen = oldGreen;
    colBlue  = oldBlue;
  }
  colRed   += skipRed;
  colGreen += skipGreen;
  colBlue  += skipBlue;
  
  // erase line
  bt = ct + 1;
  if (bt >= kNumLines) { bt = 0; }
//  CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);  // erase with black
//  [self drawFourLinesFrom:pt1[bt] To:pt2[bt] Context:ctx];
  
  // increment array index
  oldct = ct;
  ct++;
  if (ct >= kNumLines) { ct = 0; }
  
  // draw new line
  pt1[ct].x = pt1[oldct].x + skipX1;
  pt1[ct].y = pt1[oldct].y + skipY1;
  pt2[ct].x = pt2[oldct].x + skipX2;
  pt2[ct].y = pt2[oldct].y + skipY2;
  //ptRed[ct]   = colRed;
  //ptGreen[ct] = colGreen;
  //ptBlue[ct]  = colBlue;
  
  CGContextSetRGBStrokeColor(ctx, (colRed / 256.0f), (colGreen / 256.0f), (colBlue / 256.0f), 1);
  // void CGContextSetStrokeColorWithColor ( CGContextRef c, CGColorRef color );
  
  [self drawFourLinesFrom:pt1[ct] To:pt2[ct] Context:ctx];
  
  // reverse direction of step values of points that hit border
  if (pt1[ct].x < 0)                     { skipX1 = randomInt(kSkipMin, kSkipMax);      }
  if (pt1[ct].x >= self.mainSize.width)  { skipX1 = randomInt(kSkipMin, kSkipMax) * -1; }
  if (pt1[ct].y < 0)                     { skipY1 = randomInt(kSkipMin, kSkipMax);      }
  if (pt1[ct].y >= self.mainSize.height) { skipY1 = randomInt(kSkipMin, kSkipMax) * -1; }
  if (pt2[ct].x < 0)                     { skipX2 = randomInt(kSkipMin, kSkipMax);      }
  if (pt2[ct].x >= self.mainSize.width)  { skipX2 = randomInt(kSkipMin, kSkipMax) * -1; }
  if (pt2[ct].y < 0)                     { skipY2 = randomInt(kSkipMin, kSkipMax);      }
  if (pt2[ct].y >= self.mainSize.height) { skipY2 = randomInt(kSkipMin, kSkipMax) * -1; }
}

////////////////////////////////////////////////////////////////////////////////
@end



