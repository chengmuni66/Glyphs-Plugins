//
//  GlyphsFilterTraceBackground.h
//  GlyphsFilterTraceBackground
//
//  Created by Georg Seifert on 13.1.08.
//  Copyright 2008 schriftgestaltung.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GSFilterPlugin.h>

@interface GlyphsFilterTraceBackground : GSFilterPlugin {
	CGFloat _threshold;
	NSUInteger _minElementSize;
	CGFloat _roundness;
	BOOL _optimizeCurves;
	CGFloat _optimizationTolerance;
	BOOL _stroke;
	IBOutlet NSTextField * thresholdField;
	IBOutlet NSTextField * minElementSizeField;
	IBOutlet NSTextField * roundnessField;
	IBOutlet NSButton * optimizeCurvesCkeckBox;
	IBOutlet NSTextField * optimizationToleranceField;
	IBOutlet NSButton * strokeCheckBox;
@private
	NSString * _tempDir;
	NSString * _fileName;
}
- (IBAction) setThesholdAction:(id) sender ;
- (IBAction) setMinElementSizeAction:(id) sender ;
- (IBAction) setRoundnessAction:(id) sender ;
- (IBAction) setOptimizeCurvesAction:(id) sender ;
- (IBAction) setOptimizationToleranceAction:(id) sender ;
- (IBAction) setStrokeAction:(id) sender ;

@end
