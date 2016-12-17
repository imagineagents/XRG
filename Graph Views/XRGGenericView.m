/* 
 * XRG (X Resource Graph):  A system resource grapher for Mac OS X.
 * Copyright (C) 2002-2016 Gaucho Software, LLC.
 * You can view the complete license in the LICENSE file in the root
 * of the source tree.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

//
//  XRGGenericView.m
//

#import "XRGGenericView.h"


@implementation XRGGenericView

- (instancetype) initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) drawGraphWithData:(CGFloat *)samples size:(NSInteger)nSamples currentIndex:(NSInteger)cIndex maxValue:(CGFloat)max inRect:(NSRect)rect flipped:(BOOL)flipped color:(NSColor *)color {
    // call drawRangedGraphWithData to avoid a lot of code duplication.
    [self drawRangedGraphWithData:samples size:nSamples currentIndex:cIndex upperBound:max lowerBound:0 inRect:rect flipped:flipped filled:YES color:color];
}

- (void) drawGraphWithDataFromDataSet:(XRGDataSet *)dataSet maxValue:(CGFloat)max inRect:(NSRect)rect flipped:(BOOL)flipped filled:(BOOL)filled color:(NSColor *)color {
    size_t numVals = [dataSet numValues];
    CGFloat *values = alloca(numVals * sizeof(CGFloat));
    [dataSet valuesInOrder:values];

    // call drawRangedGraphWithData to avoid a lot of code duplication.
    [self drawRangedGraphWithData:values size:numVals currentIndex:numVals - 1 upperBound:max lowerBound:0 inRect:rect flipped:flipped filled:filled color:color];
}


// Adapted from original drawGraphWithData, but added UpperBound and LowerBound in place of Max, and Filled
- (void) drawRangedGraphWithData:(CGFloat *)samples size:(NSInteger)nSamples currentIndex:(NSInteger)cIndex upperBound:(CGFloat)max lowerBound:(CGFloat)min inRect:(NSRect)rect flipped:(BOOL)flipped filled:(BOOL)filled color:(NSColor *)color {
	if (nSamples == 0) return;
	
    NSInteger filledOffset = 0;
    NSInteger currentPointIndex;

    NSPoint origin = rect.origin;
    if (flipped) origin.y += rect.size.height;

    NSPoint *points;
    if (filled) {
        // Allocate points on to the stack, so we don't have to free (also much cheaper than malloc)
        points = (NSPoint *)alloca((nSamples+2)*sizeof(NSPoint));

        points[0] = origin;
        points[nSamples+1] = NSMakePoint(origin.x + rect.size.width, origin.y);
    }
    else {
        // Allocate points on to the stack, so we don't have to free (also much cheaper than malloc)
        points = (NSPoint *)alloca(nSamples * sizeof(NSPoint));
        filledOffset = 1;
    }

    NSInteger i, j;
    CGFloat height;
    CGFloat height_scaled;
    CGFloat dx = rect.size.width / nSamples;
    CGFloat x;
	
	if (fabs(max - min) < 0.001) {
		// Set the difference of max and min to 1 to avoid a divide by 0.
		max += 0.5;
		min -= 0.5;
	}

    CGFloat scale = rect.size.height / (max - min);
    if (flipped) scale *= -1.0f;

    for (i = currentPointIndex = 1 - filledOffset, x= origin.x; i <= nSamples - filledOffset; ++i, x+=dx) {
        j = (i + cIndex + filledOffset) % nSamples;
        
        if (samples[j] != NOVALUE) {
            height = samples[j] - min;
            height_scaled = (height >=  0.0f ? height * scale : 0.0f);

            if (height_scaled + origin.y < rect.origin.y) {
                points[currentPointIndex++] = NSMakePoint(x, rect.origin.y);
            }
            else if (height_scaled + origin.y > rect.origin.y + rect.size.height) {
                points[currentPointIndex++] = NSMakePoint(x, rect.origin.y + rect.size.height);
            }
            else {
                points[currentPointIndex++] = NSMakePoint(x, height_scaled + origin.y);
            }
        }
    }
    // close any gap at the edge of the graph resulting from floating point rounding of dx
    points[currentPointIndex - 1].x = origin.x + rect.size.width;
    
    if (filled) points[currentPointIndex] = NSMakePoint(origin.x + rect.size.width, origin.y);

    [color set];
    NSBezierPath *bp = [NSBezierPath bezierPath];
    [bp setLineWidth:0.0f];
    [bp setFlatness: 0.6f];
    [bp appendBezierPathWithPoints:points count:(currentPointIndex + (1 - filledOffset))];
    if (filled) {
        [bp closePath];
        [bp fill];
    }
    else {
        [bp stroke];
	}
        
    [bp removeAllPoints];
}

- (void) drawRangedGraphWithDataFromDataSet:(XRGDataSet *)dataSet upperBound:(CGFloat)max lowerBound:(CGFloat)min inRect:(NSRect)rect flipped:(BOOL)flipped filled:(BOOL)filled color:(NSColor *)color {
    size_t numVals = [dataSet numValues];
    CGFloat *values = alloca(numVals * sizeof(CGFloat));
    [dataSet valuesInOrder:values];
	
    // call drawRangedGraphWithData to avoid a lot of code duplication.
	[self drawRangedGraphWithData:values size:numVals currentIndex:numVals - 1 upperBound:max lowerBound:min inRect:rect flipped:flipped filled:filled color:color];
}

- (void) drawMiniGraphWithValues:(NSArray<NSNumber *> *)values upperBound:(double)max lowerBound:(double)min leftLabel:(NSString *)leftLabel printValueBytes:(UInt64)printValue printValueIsRate:(BOOL)isRate {
    NSString *rightLabel = nil;
    
    if (printValue >= 1125899906842624)
        rightLabel = [NSString stringWithFormat:@"%3.2fP%@", ((double)printValue / 1125899906842624.), isRate ? @"/s" : @""];
    if (printValue >= 1099511627776)
        rightLabel = [NSString stringWithFormat:@"%3.2fT%@", ((double)printValue / 1099511627776.), isRate ? @"/s" : @""];
    else if (printValue >= 1073741824)
        rightLabel = [NSString stringWithFormat:@"%3.2fG%@", ((double)printValue / 1073741824.), isRate ? @"/s" : @""];
    else if (printValue >= 1048576)
        rightLabel = [NSString stringWithFormat:@"%3.2fM%@", ((double)printValue / 1048576.), isRate ? @"/s" : @""];
    else if (printValue >= 1024)
        rightLabel = [NSString stringWithFormat:@"%4.1fK%@", ((double)printValue / 1024.), isRate ? @"/s" : @""];
    else
        rightLabel = [NSString stringWithFormat:@"%ldB%@", (long)printValue, isRate ? @"/s" : @""];

    [self drawMiniGraphWithValues:values upperBound:max lowerBound:min leftLabel:leftLabel rightLabel:rightLabel];
}

- (void) drawMiniGraphWithValues:(NSArray<NSNumber *> *)values upperBound:(double)max lowerBound:(double)min leftLabel:(NSString *)leftLabel rightLabel:(NSString *)rightLabel {
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    
    [[appSettings graphBGColor] set];
    NSRect bounds = [self bounds];
    CGContextFillRect(gc.CGContext, bounds);

    NSRect barRect = bounds;
    barRect.size.height /= values.count;
    barRect.origin.y = barRect.origin.y + bounds.size.height - barRect.size.height;
    CGFloat spacing = barRect.size.height > 2 ? 1 : 0;

    [gc setShouldAntialias:[appSettings antiAliasing]];

    [[appSettings graphFG1Color] set];
    for (NSInteger i = 0; i < values.count; i++) {
        if ((i == 1) && (values.count == 2)) {
            [[appSettings graphFG2Color] set];
        }
        
        double value = [values[i] doubleValue];
        CGContextFillRect(gc.CGContext, CGRectMake(barRect.origin.x, barRect.origin.y, MAX(1, ((value - min) / (max - min)) * barRect.size.width), floor(barRect.size.height - spacing)));
        barRect.origin.y -= barRect.size.height;
    }

    // draw the text
    [gc setShouldAntialias:[appSettings antialiasText]];

    NSRect textRect = bounds;
    textRect.origin.x += 3;
    textRect.size.width -= 6;
    [leftLabel drawInRect:textRect withAttributes:[appSettings alignLeftAttributes]];
    [rightLabel drawInRect:textRect withAttributes:[appSettings alignRightAttributes]];
    
    [gc setShouldAntialias:YES];
}

- (void) fillRect:(NSRect)rect withColor:(NSColor *)color {
    NSPoint *pointsA;
    NSPoint *pointsB;

    // Allocate points on to the stack, so we don't have to free (also much cheaper than malloc)
    pointsA = (NSPoint *)alloca(2 * sizeof(NSPoint));
    pointsB = (NSPoint *)alloca(2 * sizeof(NSPoint));

    pointsA[0] = rect.origin;
    pointsA[1] = NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height);
    pointsB[0] = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    pointsB[1] = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y);

    [color set];
    NSBezierPath *bp = [NSBezierPath bezierPath];
    [bp setLineWidth:0.0f];
    [bp appendBezierPathWithPoints:pointsA count:2];
    [[NSColor blackColor] set];
    [bp appendBezierPathWithPoints:pointsB count:2];
    [bp fill];
}

// The following methods are to be implemented in subclasses.
- (void) setGraphSize:(NSSize)newSize {
#ifdef XRG_DEBUG
	NSLog(@"Subclass should override setGraphSize.");
#endif
}

- (void) updateMinSize {
#ifdef XRG_DEBUG
	NSLog(@"Subclass should override updateMinSize.");
#endif
}

- (void) graphUpdate:(NSTimer *)aTimer {
#ifdef XRG_DEBUG
	NSLog(@"Subclass should override graphUpdate.");
#endif
}

- (void) fastUpdate:(NSTimer *)aTimer {
#ifdef XRG_DEBUG
	NSLog(@"Subclass should override fastUpdate.");
#endif
}

- (void) min5Update:(NSTimer *)aTimer {
#ifdef XRG_DEBUG
	NSLog(@"Subclass should override min5Update.");
#endif
}

- (void) min30Update:(NSTimer *)aTimer {
#ifdef XRG_DEBUG
	NSLog(@"Subclass should override min30Update.");
#endif
}

@end
