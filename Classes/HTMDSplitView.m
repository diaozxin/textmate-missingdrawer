//
//  HTMDSplitView.m
//  MissingDrawer
//
//	Copyright (c) 2006 hetima computer, 
//                2008, 2009 Jannis Leidel, 
//                2010 Christoph Meißner
//
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
//

#import "HTMDSplitView.h"
#import "HTMDResizer.h"
#import "HTMDSettings.h"

#define MIN_SIDEVIEW_WIDTH 135.0f
#define MAX_SIDEVIEW_WIDTH 350.0f

@implementation HTMDSplitView

@synthesize sideView = _sideView;
@synthesize mainView = _mainView;

#pragma mark -
#pragma mark Original Methods

- (id) initWithFrame:(NSRect)frame andMainView:(NSView*)mainView andSideView:(NSView*)sideView {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self setDelegate:self];
		
		_sideView = [sideView retain];
		_mainView = [mainView retain];
		[self.sideView setAutoresizingMask:NSViewHeightSizable];
        [self setVertical:YES];
		
		HTMDSettings* settings = [HTMDSettings defaultSettings];
		if(settings.showSideViewOnLeft) {
			[self addSubview:self.sideView];
			[self addSubview:self.mainView];
		} else {
			[self addSubview:self.mainView];
			[self addSubview:self.sideView];
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleLayout) name:@"MDSideviewLayoutHasBeenChangedNotification" object:nil];
    }
    return self;
}

- (void) toggleLayout {
	debug("toggling views");
	NSView* leftView = [[[self subviews] objectAtIndex:0] retain];
	[leftView removeFromSuperview];
	[self addSubview:leftView];
	[self adjustSubviews];
}

- (IBAction) adjustSubviews:(id)sender {
    [self adjustSubviews];
}

- (void) dealloc {
	[_sideView release], _sideView = nil;
	[_mainView release], _mainView = nil;
	[super dealloc];
}

//cleanup
- (void) windowWillCloseWillCall {
    debug("windowWillCloseWillCall");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self.sideView frame].size.width<=0) {
		debug("save only when frame not collapsed");
		NSRect sideViewFrame = [self.sideView frame];
        sideViewFrame.size.width = MIN_SIDEVIEW_WIDTH;
        [self.sideView setFrame:sideViewFrame];
        [self adjustSubviews];
    }
    [self saveLayout];
	
    if(self.sideView){
		NSDrawer* drawer = [[[self window] drawers]objectAtIndex:0];
        [self.sideView removeFromSuperview];
        [drawer setContentView:self.sideView];
        [_sideView release], _sideView = nil;
    }
}

#pragma mark -
#pragma mark Overridden from NSSplitView

- (CGFloat) dividerThickness {
    return 1;
}

- (void) drawDividerInRect:(NSRect)aRect {
    [[NSColor colorWithDeviceWhite:.625 alpha:1] setFill];
    [NSBezierPath fillRect:aRect];
}

#pragma mark -
#pragma mark NSSplitView delegate methods

- (BOOL) splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
    return NO;
}

- (CGFloat) splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
	if ([[self subviews] objectAtIndex:offset] == self.sideView) {
		return MIN_SIDEVIEW_WIDTH;
	} else {
		return [self frame].size.width - MAX_SIDEVIEW_WIDTH;
	}
	
}

- (CGFloat) splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
	if ([[self subviews] objectAtIndex:offset] == self.sideView) {
		return MAX_SIDEVIEW_WIDTH;
	} else {
		return [self frame].size.width - MIN_SIDEVIEW_WIDTH;
	}
}

- (void) splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
	debug();
	
	float dividerThickness = [self dividerThickness];
    
	NSRect windowFrame = [[NSApp mainWindow] frame];
	windowFrame.size.width = MAX(3*MIN_SIDEVIEW_WIDTH + dividerThickness, windowFrame.size.width);
	[[NSApp mainWindow] setFrame:windowFrame display:YES];

	NSRect splitViewFrame = [self frame];
	splitViewFrame.size.width = MAX(3*MIN_SIDEVIEW_WIDTH + dividerThickness, splitViewFrame.size.width);
	[splitView setFrame:splitViewFrame];
	
    NSRect sideViewFrame = [self.sideView frame];
    NSRect mainViewFrame = [self.mainView frame];
    
	sideViewFrame.size.height = splitViewFrame.size.height;
	mainViewFrame.size.height = splitViewFrame.size.height;

	mainViewFrame.size.width = splitViewFrame.size.width - sideViewFrame.size.width - dividerThickness;
	
	HTMDSettings* settings = [HTMDSettings defaultSettings];
	
	if (settings.showSideViewOnLeft) {
		mainViewFrame.origin.x = sideViewFrame.size.width + dividerThickness;
		sideViewFrame.origin.x = 0;
	} else {
		mainViewFrame.origin.x = 0;
		sideViewFrame.origin.x = mainViewFrame.size.width + dividerThickness;
	}
	
    [self.sideView setFrame:sideViewFrame];
    [self.mainView setFrame:mainViewFrame];
}

#pragma mark -
#pragma mark Sidebar resize area

- (void) resetCursorRects {
	debug();
    [super resetCursorRects];
	
    NSRect location = [resizeSlider frame];
    location.origin.y = [self frame].size.height - location.size.height;
	
    [self addCursorRect:location cursor:[NSCursor resizeLeftRightCursor]];
}

- (void) mouseDown:(NSEvent *)theEvent {
	debug();
    NSPoint clickLocation = [theEvent locationInWindow];
    NSView *clickReceiver = [self hitTest:clickLocation];
    if ([clickReceiver isKindOfClass:[HTMDResizer class]]) {
        inResizeMode = YES;
    } else {
        inResizeMode = NO;
        [super mouseDown:theEvent];
    }
}

- (void) mouseUp:(NSEvent *)theEvent {
	debug();
    inResizeMode = NO;
}

- (void) mouseDragged:(NSEvent *)theEvent {
	debug();
	
    if (inResizeMode == NO) {
        [super mouseDragged:theEvent];
        return;
    }
	
    [[NSNotificationCenter defaultCenter] postNotificationName:NSSplitViewWillResizeSubviewsNotification object:self];
	
	
    NSPoint clickLocation = [theEvent locationInWindow];
	NSView* leftView = [[self subviews] objectAtIndex:0];
    NSRect newFrame = [leftView frame];
    newFrame.size.width = clickLocation.x;
	
    if(self.delegate && [self.delegate respondsToSelector:@selector(splitView:constrainSplitPosition:ofSubviewAt:)]) {
        float new = [self.delegate splitView:self constrainSplitPosition:newFrame.size.width ofSubviewAt:0];
        newFrame.size.width = new;
    }
	
    if(self.delegate && [self.delegate respondsToSelector:@selector(splitView:constrainMinCoordinate:ofSubviewAt:)]) {
        float min = [self.delegate splitView:self constrainMinCoordinate:0. ofSubviewAt:0];
        newFrame.size.width = MAX(min, newFrame.size.width);
    }
	
    if(self.delegate && [self.delegate respondsToSelector:@selector(splitView:constrainMaxCoordinate:ofSubviewAt:)]) {
        float max = [self.delegate splitView:self constrainMaxCoordinate:0. ofSubviewAt:0];
        newFrame.size.width = MIN(max, newFrame.size.width);
    }
	
    [leftView setFrame:newFrame];
	
    [self setNeedsDisplay:YES];
    [self adjustSubviews];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:NSSplitViewDidResizeSubviewsNotification object:self];
}

#pragma mark -
#pragma mark Position save support

- (void) applyLayout:(NSRect)layout toView:(NSView*)view {
	NSRect newFrame = layout;
	if(NSIsEmptyRect(newFrame)) {
		newFrame = [view frame];
		if([self isVertical]) {
			newFrame.size.width = 0;
		} else {
			newFrame.size.height = 0;
		}
	}
	[view setFrame:newFrame];
}

- (void) saveLayout {
	HTMDSettings* settings = [HTMDSettings defaultSettings];
	settings.sideViewLayout = [self.sideView frame];
	settings.mainViewLayout = [self.mainView frame];
	[settings save];
}

- (void) restoreLayout {
	HTMDSettings* settings = [HTMDSettings defaultSettings];
	[self applyLayout:settings.sideViewLayout toView:self.sideView];
	[self applyLayout:settings.mainViewLayout toView:self.mainView];
}

@end