/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTextView.h"

#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import "NSView+React.h"

@implementation RCTTextView
{
  RCTEventDispatcher *_eventDispatcher;
  BOOL _jsRequestingFirstResponder;
  NSString *_placeholder;
  NSTextView *_placeholderView;
  NSTextView *_textView;
  NSInteger _nativeEventCount;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  RCTAssertParam(eventDispatcher);

  if ((self = [super initWithFrame:CGRectZero])) {
    _contentInset = NSEdgeInsetsZero;
    _eventDispatcher = eventDispatcher;
    _placeholderTextColor = [self defaultPlaceholderTextColor];
    _textView = [[NSTextView alloc] initWithFrame:self.bounds];
    _textView.backgroundColor = [NSColor clearColor];
    //_textView.scrollsToTop = NO;
    _jsRequestingFirstResponder = YES;
    _textView.delegate = self;
    _placeholderView.delegate = self;
    [self addSubview:_textView];
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (void)updateFrames
{
  // Adjust the insets so that they are as close as possible to single-line
  // RCTTextField defaults, using the system defaults of font size 17 and a
  // height of 31 points.
  //
  // We apply the left inset to the frame since a negative left text-container
  // inset mysteriously causes the text to be hidden until the text view is
  // first focused.
  NSEdgeInsets adjustedFrameInset = NSEdgeInsetsZero;
  adjustedFrameInset.left = _contentInset.left - 5;
  
  NSEdgeInsets adjustedTextContainerInset = _contentInset;
  adjustedTextContainerInset.top += 5;
  adjustedTextContainerInset.left = 0;
  
  CGRect frame = self.frame;// TODO: UIEdgeInsetsInsetRect(self.bounds, adjustedFrameInset);
  _textView.frame = frame;
  _placeholderView.frame = frame;

  // TODO:
 // _textView.textContainerInset = adjustedTextContainerInset;
 // _placeholderView.textContainerInset = adjustedTextContainerInset;
}

- (void)updatePlaceholder
{
  [_placeholderView removeFromSuperview];
  _placeholderView = nil;

  if (_placeholder) {
    _placeholderView = [[NSTextView alloc] initWithFrame:self.bounds];
    _placeholderView.backgroundColor = [NSColor clearColor];
    NSAttributedString* attrString =
    [[NSAttributedString alloc] initWithString:_placeholder attributes:@{
      NSFontAttributeName : (_textView.font ? _textView.font : [self defaultPlaceholderFont]),
      NSForegroundColorAttributeName : _placeholderTextColor
    }];

    [[_placeholderView textStorage] setAttributedString:attrString];
    _placeholderView.delegate = self;
    [self addSubview:_placeholderView]; // TODO: check this

    [self _setPlaceholderVisibility];
  }
}
- (void)hidePlaceholder
{
  [_placeholderView removeFromSuperview];
  _placeholderView = nil;
}

- (NSFont *)font
{
  return _textView.font;
}

- (void)setFont:(NSFont *)font
{
  _textView.font = font;
  [self updatePlaceholder];
}

- (NSColor *)textColor
{
  return _textView.textColor;
}

- (void)setTextColor:(NSColor *)textColor
{
  _textView.textColor = textColor;
}

- (void)setPlaceholder:(NSString *)placeholder
{
  _placeholder = placeholder;
  [self updatePlaceholder];
}

- (void)setPlaceholderTextColor:(NSColor *)placeholderTextColor
{
  if (placeholderTextColor) {
    _placeholderTextColor = placeholderTextColor;
  } else {
    _placeholderTextColor = [self defaultPlaceholderTextColor];
  }
  [self updatePlaceholder];
}

- (void)setContentInset:(NSEdgeInsets)contentInset
{
  _contentInset = contentInset;
  [self updateFrames];
}

- (NSString *)text
{
  return [_textView string];
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
  if (_maxLength == nil) {
    return YES;
  }
  return NO;
//  NSUInteger allowedLength = _maxLength.integerValue - textView.text.length + range.length;
//  if (text.length > allowedLength) {
//    if (text.length > 1) {
//      // Truncate the input string so the result is exactly maxLength
//      NSString *limitedString = [text substringToIndex:allowedLength];
//      NSMutableString *newString = [textView string].mutableCopy;
//      [newString replaceCharactersInRange:range withString:limitedString];
//      [textView setString:newString];
//      // Collapse selection at end of insert to match normal paste behavior
////      UITextPosition *insertEnd = [textView positionFromPosition:textView.beginningOfDocument
////                                                          offset:(range.location + allowedLength)];
////      textView.selectedTextRange = [textView textRangeFromPosition:insertEnd toPosition:insertEnd];
//      [self textViewDidChange:textView];
//    }
//    return NO;
//  } else {
//    return YES;
//  }
}

- (void)setText:(NSString *)text
{
  NSInteger eventLag = _nativeEventCount - _mostRecentEventCount;
  if (eventLag == 0 && ![text isEqualToString:[_textView string]]) {
    //UITextRange *selection = _textView.selectedTextRange;
    [_textView setString:text];
    [self _setPlaceholderVisibility];
   // _textView.selectedTextRange = selection; // maintain cursor position/selection - this is robust to out of bounds
  } else if (eventLag > RCTTextUpdateLagWarningThreshold) {
    RCTLogWarn(@"Native TextInput(%@) is %zd events ahead of JS - try to make your JS faster.", self.text, eventLag);
  }
}

- (void)_setPlaceholderVisibility
{
  if ([_textView string].length > 0) {
    [_placeholderView setHidden:YES];
  } else {
    [_placeholderView setHidden:NO];
  }
}

//- (void)setAutoCorrect:(BOOL)autoCorrect
//{
//  //_textView.autocorrectionType = (autoCorrect ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo);
//}

//- (BOOL)autoCorrect
//{
//  return _textView.autocorrectionType == UITextAutocorrectionTypeYes;
//}

- (void)textDidChange:(NSNotification *)aNotification
{
  [self _setPlaceholderVisibility];
  _nativeEventCount++;
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeChange
                                 reactTag:self.reactTag
                                     text:[_textView string]
                               eventCount:_nativeEventCount];
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
  _nativeEventCount++;
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeEnd
                                 reactTag:self.reactTag
                                     text:[_textView string]
                               eventCount:_nativeEventCount];
}


- (void)textDidBeginEditing:(NSNotification *)aNotification
{
  [self hidePlaceholder];
  if (_clearTextOnFocus) {
    [_textView setString:@""];
    [self _setPlaceholderVisibility];
  }
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeFocus
                                 reactTag:self.reactTag
                                     text:[_textView string]
                               eventCount:_nativeEventCount];
}

- (BOOL)becomeFirstResponder
{
  _jsRequestingFirstResponder = YES;
  BOOL result = [_textView becomeFirstResponder];
  _jsRequestingFirstResponder = NO;
  return result;
}

- (BOOL)resignFirstResponder
{
  [super resignFirstResponder];
  BOOL result = [_textView resignFirstResponder];
  if (result) {
    [_eventDispatcher sendTextEventWithType:RCTTextEventTypeBlur
                                   reactTag:self.reactTag
                                       text:[_textView string]
                                 eventCount:_nativeEventCount];
  }
  return result;
}

- (void)layout
{
  [super layout];
  [self updateFrames];
}

- (BOOL)canBecomeFirstResponder
{
  return _jsRequestingFirstResponder;
}

- (NSFont *)defaultPlaceholderFont
{
  return [NSFont systemFontOfSize:17];
}

- (NSColor *)defaultPlaceholderTextColor
{
  return [NSColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.098/255.0 alpha:0.22];
}

@end
