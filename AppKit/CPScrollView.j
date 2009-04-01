/*
 * CPScrollView.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPView.j"
@import "CPClipView.j"
@import "CPScroller.j"

#include "CoreGraphics/CGGeometry.h"


/*! @class CPScrollView

    Used to display views that are too large for the viewing area. the CPScrollView
    places scroll bars on the side of the view to allow the user to scroll and see the entire
    contents of the view.
*/
@implementation CPScrollView : CPView
{
    CPClipView  _contentClipView;
    CPClipView  _headerClipView ;
    
    BOOL        _hasVerticalScroller;
    BOOL        _hasHorizontalScroller;
    BOOL        _autohidesScrollers;
    
    CPScroller  _verticalScroller;
    CPScroller  _horizontalScroller;
    
    int         _recursionCount;
    
    float       _verticalLineScroll;
    float       _verticalPageScroll;
    float       _horizontalLineScroll;
    float       _horizontalPageScroll;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _verticalLineScroll = 10.0;
        _verticalPageScroll = 10.0;
        
        _horizontalLineScroll = 10.0;
        _horizontalPageScroll = 10.0;

        _contentClipView = [[CPClipView alloc] initWithFrame:[self clipViewFrame]];
        [self addSubview:_contentClipView];
        
        _headerClipView = [[CPClipView alloc] initWithFrame:[self headerClipViewFrame]] ;
        [self addSubview:_headerClipView] ;
        
        [self setHasVerticalScroller:YES];
        [self setHasHorizontalScroller:YES];
    }
    
    return self;
}

// Determining component sizes
/*!
    Returns the size of the scroll view's content view.
*/
- (CGRect)contentSize
{
    return [_contentClipView frame].size;
}

/*!
    Returns the view that is scrolled for the user.
*/
- (id)documentView
{
    return [_contentClipView documentView];
}

/*!
    Sets the content view that clips the document
    @param aContentView the content view
*/
- (void)setContentView:(CPClipView)aContentView
{
    if (!aContentView)
        return;
    
    var documentView = [aContentView documentView];
    
    if (documentView)
        [documentView removeFromSuperview];
    
    [_contentClipView removeFromSuperview];
    
    var size = [self contentSize];
    
    _contentClipView = aContentView;
        
    [_contentClipView setFrame:CGRectMake(0.0, 0.0, size.width, size.height)];
    [_contentClipView setDocumentView:documentView];

    [self addSubview:_contentClipView];
    
}

/*!
    Returns the content view that clips the document.
*/
- (CPClipView)contentView
{
    return _contentClipView;
}

/*!
    Sets the view that is scrolled for the user.
    @param aView the view that will be scrolled
*/
- (void)setDocumentView:(CPView)aView
{
   [_contentClipView setDocumentView:aView];
   
   // display the header
   _headerClipView = [[CPClipView alloc] initWithFrame:[self headerClipViewFrame]];
   [_headerClipView setDocumentView:[self _headerView]];
   [self addSubview:_headerClipView];
   [_headerClipView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
   [_headerClipView setAutoresizesSubviews:YES];
   
   [self reflectScrolledClipView:_contentClipView];
}

/*!
    Resizes the scroll view to contain the specified clip view.
    @param aClipView the clip view to resize to
*/
- (void)reflectScrolledClipView:(CPClipView)aClipView
{
    if(_contentClipView !== aClipView)
        return;

    if (_recursionCount > 5)
        return;
    
    ++_recursionCount;

    var documentView = [self documentView];
    
    if (!documentView)
    {
        if (_autohidesScrollers)
        {
            [_verticalScroller setHidden:YES];
            [_horizontalScroller setHidden:YES];
        }
        else
        {
//            [_verticalScroller setEnabled:NO];
//            [_horizontalScroller setEnabled:NO];
        }
        
        [_contentClipView setFrame:[self bounds]];
        
        --_recursionCount;
        
        return;
    }

    var documentFrame = [documentView frame],   // the size of the whole document
        clipViewFrame = [self clipViewFrame],   // the size of the visible document, within the scrollbars
        scrollPoint = [_contentClipView bounds].origin,
        difference = _CGSizeMake(CPRectGetWidth(documentFrame) - CPRectGetWidth(clipViewFrame), CPRectGetHeight(documentFrame) - CPRectGetHeight(clipViewFrame)),
        shouldShowVerticalScroller = (!_autohidesScrollers || difference.height > 0.0) && _hasVerticalScroller,
        shouldShowHorizontalScroller = (!_autohidesScrollers || difference.width > 0.0) && _hasHorizontalScroller,
        wasShowingVerticalScroller = ![_verticalScroller isHidden],
        wasShowingHorizontalScroller = ![_horizontalScroller isHidden],
        verticalScrollerWidth = _CGRectGetWidth([_verticalScroller frame]);
        horizontalScrollerHeight = _CGRectGetHeight([_horizontalScroller frame]);
        
    if (_autohidesScrollers)
    {
        // Check to see if either affected the other!
        if (shouldShowVerticalScroller)
            shouldShowHorizontalScroller = (!_autohidesScrollers || difference.width > -verticalScrollerWidth) && _hasHorizontalScroller;

        if (shouldShowHorizontalScroller)
            shouldShowVerticalScroller = (!_autohidesScrollers || difference.height > -horizontalScrollerHeight) && _hasVerticalScroller;
    }

    [_verticalScroller setHidden:!shouldShowVerticalScroller];
    [_verticalScroller setEnabled:difference.height > 0.0];

    [_horizontalScroller setHidden:!shouldShowHorizontalScroller];
    [_horizontalScroller setEnabled:difference.width > 0.0];

    if (shouldShowVerticalScroller)
    {
        // var verticalScrollerHeight = CPRectGetHeight(clipViewFrame);
        var verticalScrollerHeight = CPRectGetHeight([self bounds]);
        
        if (shouldShowHorizontalScroller)
            verticalScrollerHeight -= horizontalScrollerHeight;
    
        difference.width += verticalScrollerWidth;
        clipViewFrame.size.width -= verticalScrollerWidth;
    
        [_verticalScroller setFloatValue:(difference.height <= 0.0) ? 0.0 : scrollPoint.y / difference.height
            knobProportion:CPRectGetHeight(clipViewFrame) / CPRectGetHeight(documentFrame)];
        [_verticalScroller setFrame:CPRectMake(CPRectGetMaxX(clipViewFrame), 0.0, verticalScrollerWidth, verticalScrollerHeight)];
    }
    else if (wasShowingVerticalScroller)
        [_verticalScroller setFloatValue:0.0 knobProportion:1.0];
    
    if (shouldShowHorizontalScroller)
    {
        difference.height += horizontalScrollerHeight;
        clipViewFrame.size.height -= horizontalScrollerHeight;
        
        [_horizontalScroller setFloatValue:(difference.width <= 0.0) ? 0.0 : scrollPoint.x / difference.width
            knobProportion:CPRectGetWidth(clipViewFrame) / CPRectGetWidth(documentFrame)];
        [_horizontalScroller setFrame:CPRectMake(0.0, CPRectGetMaxY(clipViewFrame), CPRectGetWidth(clipViewFrame), horizontalScrollerHeight)];
    }
    else if (wasShowingHorizontalScroller)
        [_horizontalScroller setFloatValue:0.0 knobProportion:1.0];
    
    [_contentClipView setFrame:clipViewFrame];
    
    --_recursionCount;
}

// Managing Scrollers
/*!
    Sets the scroll view's horizontal scroller.
    @param aScroller the horizontal scroller for the scroll view
*/
- (void)setHorizontalScroller:(CPScroller)aScroller
{
    if (_horizontalScroller === aScroller)
        return;
    
    [_horizontalScroller removeFromSuperview];
    [_horizontalScroller setTarget:nil];
    [_horizontalScroller setAction:nil];
    
    _horizontalScroller = aScroller;
    
    [_horizontalScroller setTarget:self];
    [_horizontalScroller setAction:@selector(_horizontalScrollerDidScroll:)];

    [self addSubview:_horizontalScroller];

    [self reflectScrolledClipView:_contentClipView];
}

/*!
    Returns the scroll view's horizontal scroller
*/
- (CPScroller)horizontalScroller
{
    return _horizontalScroller;
}

/*!
    Specifies whether the scroll view can have a horizontal scroller.
    @param hasHorizontalScroller <code>YES</code> lets the scroll view
    allocate a horizontal scroller if necessary.
*/
- (void)setHasHorizontalScroller:(BOOL)shouldHaveHorizontalScroller
{
    if (_hasHorizontalScroller === shouldHaveHorizontalScroller)
        return;

    _hasHorizontalScroller = shouldHaveHorizontalScroller;
    
    if (_hasHorizontalScroller && !_horizontalScroller)
        [self setHorizontalScroller:[[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, CPRectGetWidth([self bounds]), [CPScroller scrollerWidth])]];

    else if (!_hasHorizontalScroller && _horizontalScroller)
    {
        [_horizontalScroller setHidden:YES];

        [self reflectScrolledClipView:_contentClipView];
    }
}

/*!
    Returns <code>YES</code> if the scroll view can have a horizontal scroller.
*/
- (BOOL)hasHorizontalScroller
{
    return _hasHorizontalScroller;
}

/*!
    Sets the scroll view's vertical scroller.
    @param aScroller the vertical scroller
*/
- (void)setVerticalScroller:(CPScroller)aScroller
{
    if (_verticalScroller === aScroller)
        return;
    
    [_verticalScroller removeFromSuperview];
    [_verticalScroller setTarget:nil];
    [_verticalScroller setAction:nil];
    
    _verticalScroller = aScroller;
    
    [_verticalScroller setTarget:self];
    [_verticalScroller setAction:@selector(_verticalScrollerDidScroll:)];

    [self addSubview:_verticalScroller];

    [self reflectScrolledClipView:_contentClipView];
}

/*!
    Return's the scroll view's vertical scroller
*/
- (CPScroller)verticalScroller
{
    return _verticalScroller;
}

/*!
    Specifies whether the scroll view has can have
    a vertical scroller. It allocates it if necessary.
    @param hasVerticalScroller <code>YES</code> allows
    the scroll view to display a vertical scroller
*/
- (void)setHasVerticalScroller:(BOOL)shouldHaveVerticalScroller
{
    if (_hasVerticalScroller === shouldHaveVerticalScroller)
        return;

    _hasVerticalScroller = shouldHaveVerticalScroller;

    if (_hasVerticalScroller && !_verticalScroller)
        [self setVerticalScroller:[[CPScroller alloc] initWithFrame:CPRectMake(0.0, 0.0, [CPScroller scrollerWidth], CPRectGetHeight([self bounds]))]];

    else if (!_hasVerticalScroller && _verticalScroller)
    {
        [_verticalScroller setHidden:YES];

        [self reflectScrolledClipView:_contentClipView];
    }
}

/*!
    Returns <code>YES</code> if the scroll view can have a vertical scroller.
*/
- (BOOL)hasHorizontalScroller
{
    return _hasHorizontalScroller;
}

/*!
    Sets whether the scroll view hides its scoll bars when not needed.
    @param autohidesScrollers <code>YES</code> causes the scroll bars
    to be hidden when not needed.
*/
- (void)setAutohidesScrollers:(BOOL)autohidesScrollers
{
    if (_autohidesScrollers == autohidesScrollers)
        return;

    _autohidesScrollers = autohidesScrollers;
    
    [self reflectScrolledClipView:_contentClipView];
}

/*!
    Returns <code>YES</code> if the scroll view hides its scroll
    bars when not necessary.
*/
- (BOOL)autohidesScrollers
{
    return _autohidesScrollers;
}
/*
- (void)setFrameSize:(CPRect)aSize
{
    [super setFrameSize:aSize];
    
    [self reflectScrolledClipView:_contentClipView];
}*/

/* @ignore */
- (void)_verticalScrollerDidScroll:(CPScroller)aScroller
{
   var  value = [aScroller floatValue],
        documentFrame = [[_contentClipView documentView] frame];
        contentBounds = [_contentClipView bounds];

    switch ([_verticalScroller hitPart])
    {
        case CPScrollerDecrementLine:   contentBounds.origin.y -= _verticalLineScroll;
                                        break;
        
        case CPScrollerIncrementLine:   contentBounds.origin.y += _verticalLineScroll;
                                        break;
           
        case CPScrollerDecrementPage:   contentBounds.origin.y -= _CGRectGetHeight(contentBounds) - _verticalPageScroll;
                                        break;
        
        case CPScrollerIncrementPage:   contentBounds.origin.y += _CGRectGetHeight(contentBounds) - _verticalPageScroll;
                                        break;
        
        case CPScrollerKnobSlot:
        case CPScrollerKnob:
        default:                        contentBounds.origin.y = value * (_CGRectGetHeight(documentFrame) - _CGRectGetHeight(contentBounds));
    }
    
    [_contentClipView scrollToPoint:contentBounds.origin];
}

/* @ignore */
- (void)_horizontalScrollerDidScroll:(CPScroller)aScroller
{
   var value = [aScroller floatValue],
       documentFrame = [[self documentView] frame],
       contentBounds = [_contentClipView bounds];
        
    switch ([_horizontalScroller hitPart])
    {
        case CPScrollerDecrementLine:   contentBounds.origin.x -= _horizontalLineScroll;
                                        break;
        
        case CPScrollerIncrementLine:   contentBounds.origin.x += _horizontalLineScroll;
                                        break;
           
        case CPScrollerDecrementPage:   contentBounds.origin.x -= _CGRectGetWidth(contentBounds) - _horizontalPageScroll;
                                        break;
        
        case CPScrollerIncrementPage:   contentBounds.origin.x += _CGRectGetWidth(contentBounds) - _horizontalPageScroll;
                                        break;
        
        case CPScrollerKnobSlot:
        case CPScrollerKnob:
        default:                        contentBounds.origin.x = value * (_CGRectGetWidth(documentFrame) - _CGRectGetWidth(contentBounds));
    }

    [_contentClipView scrollToPoint:contentBounds.origin];
}

/*!
    Lays out the scroll view's components.
*/
- (void)tile
{
    // yuck.
    // RESIZE: tile->setHidden AND refl
    // Outside Change: refl->tile->setHidden AND refl
    // scroll: refl.
}

/*
    @ignore
*/
-(void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    [self reflectScrolledClipView:_contentClipView];
}

// Setting Scrolling Behavior
/*!
    Sets how much the document moves when scrolled. Sets the vertical and horizontal scroll.
    @param aLineScroll the amount to move the document when scrolled
*/
- (void)setLineScroll:(float)aLineScroll
{
    [self setHorizonalLineScroll:aLineScroll];
    [self setVerticalLineScroll:aLineScroll];
}

/*!
    Returns how much the document moves when scrolled
*/
- (float)lineScroll
{
    return [self horizontalLineScroll];
}

/*!
    Sets how much the document moves when scrolled horizontally.
    @param aLineScroll the amount to move horizontally when scrolled.
*/
- (void)setHorizontalLineScroll:(float)aLineScroll
{
    _horizontalLineScroll = aLineScroll;
}

/*!
    Returns how much the document moves horizontally when scrolled.
*/
- (float)horizontalLineScroll
{
    return _horizontalLineScroll;
}

/*!
    Sets how much the document moves when scrolled vertically.
    @param aLineScroll the new amount to move vertically when scrolled.
*/
- (void)setVerticalLineScroll:(float)aLineScroll
{
    _verticalLineScroll = aLineScroll;
}

/*!
    Returns how much the document moves vertically when scrolled.
*/
- (float)verticalLineScroll
{
    return _verticalLineScroll;
}

/*!
    Sets the horizontal and vertical page scroll amount.
    @param aPageScroll the new horizontal and vertical page scroll amount
*/
- (void)setPageScroll:(float)aPageScroll
{
    [self setHorizontalPageScroll:aPageScroll];
    [self setVerticalPageScroll:aPageScroll];
}

/*!
    Returns the vertical and horizontal page scroll amount.
*/
- (float)pageScroll
{
    return [self horizontalPageScroll];
}

/*!
    Sets the horizontal page scroll amount.
    @param aPageScroll the new horizontal page scroll amount
*/
- (void)setHorizontalPageScroll:(float)aPageScroll
{
    _horizontalPageScroll = aPageScroll;
}

/*!
    Returns the horizontal page scroll amount.
*/
- (float)horizontalPageScroll
{
    return _horizontalPageScroll;
}

/*!
    Sets the vertical page scroll amount.
    @param aPageScroll the new vertcal page scroll amount
*/
- (void)setVerticalPageScroll:(float)aPageScroll
{
    _verticalPageScroll = aPageScroll;
}

/*!
    Returns the vertical page scroll amount.
*/
- (float)verticalPageScroll
{
    return _verticalPageScroll;
}

/*!
    Handles a scroll wheel event from the user.
    @param anEvent the scroll wheel event
*/
- (void)scrollWheel:(CPEvent)anEvent
{
   var value = [_verticalScroller floatValue],
       documentFrame = [[self documentView] frame],
       contentBounds = [_contentClipView bounds];

    contentBounds.origin.x += [anEvent deltaX] * _horizontalLineScroll;
    contentBounds.origin.y += [anEvent deltaY] * _verticalLineScroll;

    [_contentClipView scrollToPoint:contentBounds.origin];
}

- (void)keyDown:(CPEvent)anEvent
{
    var keyCode = [anEvent keyCode],
        value = [_verticalScroller floatValue],
        documentFrame = [[self documentView] frame],
        contentBounds = [_contentClipView bounds];
    
    switch (keyCode)
    {
        case 33:    /*pageup*/
                    contentBounds.origin.y -= _CGRectGetHeight(contentBounds) - _verticalPageScroll;
                    break;
                    
        case 34:    /*pagedown*/
                    contentBounds.origin.y += _CGRectGetHeight(contentBounds) - _verticalPageScroll;
                    break;
                    
        case 38:    /*up arrow*/
                    contentBounds.origin.y -= _verticalLineScroll;
                    break;

        case 40:    /*down arrow*/
                    contentBounds.origin.y += _verticalLineScroll;
                    break;
                    
        case 37:    /*left arrow*/
                    contentBounds.origin.x -= _horizontalLineScroll;
                    break;

        case 49:    /*right arrow*/
                    contentBounds.origin.x += _horizontalLineScroll;
                    break;
                    
        default:    return [super keyDown:anEvent];
    }

    [_contentClipView scrollToPoint:contentBounds.origin];
}

- (CGRect)insetBounds
{
    return [self bounds] ;
}

- (CPView)_headerView
{
    var documentView = [self documentView];
    
    if ([documentView respondsToSelector:@selector(headerView)])
        return [documentView performSelector:@selector(headerView)] ;
    
    return nil ;
}

- (CGRect)headerClipViewFrame
{
    var headerView = [self _headerView];
    var result = [self insetBounds];

    if (headerView === nil)
        return CGRectMakeZero();

    result.size.height=[headerView bounds].size.height;
    result.size.width-=_CGRectGetWidth([_verticalScroller frame]);

    return result;
}

- (CGRect)clipViewFrame
{
    var result = [self insetBounds];
        
    if ([self _headerView] !== nil) {
        result.origin.y+=[self headerClipViewFrame].size.height;
        result.size.height-=[self headerClipViewFrame].size.height;
    }

    return result;
}

@end

var CPScrollViewContentViewKey = "CPScrollViewContentView",
    CPScrollViewVLineScrollKey = "CPScrollViewVLineScroll",
    CPScrollViewHLineScrollKey = "CPScrollViewHLineScroll",
    CPScrollViewVPageScrollKey = "CPScrollViewVPageScroll",
    CPScrollViewHPageScrollKey = "CPScrollViewHPageScroll",
    CPScrollViewHasVScrollerKey = "CPScrollViewHasVScroller",
    CPScrollViewHasHScrollerKey = "CPScrollViewHasHScroller",
    CPScrollViewVScrollerKey = "CPScrollViewVScroller",
    CPScrollViewHScrollerKey = "CPScrollViewHScroller",
    CPScrollViewAutohidesScrollerKey = "CPScrollViewAutohidesScroller";

@implementation CPScrollView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _verticalLineScroll     = [aCoder decodeFloatForKey:CPScrollViewVLineScrollKey];
        _verticalPageScroll     = [aCoder decodeFloatForKey:CPScrollViewVPageScrollKey];

        _horizontalLineScroll   = [aCoder decodeFloatForKey:CPScrollViewHLineScrollKey];
        _horizontalPageScroll   = [aCoder decodeFloatForKey:CPScrollViewHPageScrollKey];
        
        _contentClipView        = [aCoder decodeObjectForKey:CPScrollViewContentViewKey];
        
        _verticalScroller       = [aCoder decodeObjectForKey:CPScrollViewVScrollerKey];
        _horizontalScroller     = [aCoder decodeObjectForKey:CPScrollViewHScrollerKey];

        _hasVerticalScroller    = [aCoder decodeBoolForKey:CPScrollViewHasVScrollerKey];
        _hasHorizontalScroller  = [aCoder decodeBoolForKey:CPScrollViewHasHScrollerKey];
        _autohidesScrollers     = [aCoder decodeBoolForKey:CPScrollViewAutohidesScrollerKey];
        
        // Do to the anything goes nature of decoding, our subviews may not exist yet, so layout at the end of the run loop when we're sure everything is in a correct state.
        [[CPRunLoop currentRunLoop] performSelector:@selector(reflectScrolledClipView:) target:self argument:_contentClipView order:0 modes:[CPDefaultRunLoopMode]];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_contentClipView       forKey:CPScrollViewContentViewKey];
    
    [aCoder encodeObject:_verticalScroller      forKey:CPScrollViewVScrollerKey];
    [aCoder encodeObject:_horizontalScroller    forKey:CPScrollViewHScrollerKey];
    
    [aCoder encodeFloat:_verticalLineScroll     forKey:CPScrollViewVLineScrollKey];
    [aCoder encodeFloat:_verticalPageScroll     forKey:CPScrollViewVPageScrollKey];
    [aCoder encodeFloat:_horizontalLineScroll   forKey:CPScrollViewHLineScrollKey];
    [aCoder encodeFloat:_horizontalPageScroll   forKey:CPScrollViewHPageScrollKey];
    
    [aCoder encodeBool:_hasVerticalScroller     forKey:CPScrollViewHasVScrollerKey];
    [aCoder encodeBool:_hasHorizontalScroller   forKey:CPScrollViewHasHScrollerKey];
    [aCoder encodeBool:_autohidesScrollers      forKey:CPScrollViewAutohidesScrollerKey];
}

@end
