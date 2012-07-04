//
//  GlyphsFilterTraceBackground.m
//  GlyphsFilterTraceBackground
//
//  Created by Georg Seifert on 13.1.08.
//  Copyright 2008 schriftgestaltung.de. All rights reserved.
//

#import "GlyphsFilterTraceBackground.h"
#import <GlyphsCore/GSNode.h>
#import <GlyphsCore/GSGlyph.h>
#import <GlyphsCore/GSLayer.h>
#import <GlyphsCore/GSPath.h>
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSBackgroundImage.h>
#import <GlyphsCore/GSNode.h>
#import <GlyphsCore/GSGeometrieHelper.h>

#import "NSImage+BMP.h"

//#import <GlyphsCore/GSGlyphsViewProtocol.h>
//#import <GlyphsCore/GSDialogController.h>
//#import "GSEditViewController.h"

@implementation GlyphsFilterTraceBackground

- (id)init {
	self = [super init];
	[NSBundle loadNibNamed:@"GSTraceBackgroundDialog" owner:self];
	return self;	
}
- (NSUInteger) interfaceVersion {
	return 1;
}
- (NSString *) title {
	return NSLocalizedStringFromTableInBundle(@"Trace Background", nil, [NSBundle bundleForClass:[self class]], @"Name of the Trace Background Filter");
}
- (NSString*) keyEquivalent {
	return nil;
}
- (NSString*) actionName {
	return NSLocalizedStringFromTableInBundle(@"Trace", nil, [NSBundle bundleForClass:[self class]], @"Name of the Trace Background Filter Action Button");
}
- (BOOL) runFilterWithLayer:(GSLayer*) Layer error: (NSError**) error {
	return [super runFilterWithLayer:Layer error:error];
}

- (IBAction) setThesholdAction:(id) sender {
	_threshold = [sender floatValue];
	[self process:nil];
}
- (IBAction) setMinElementSizeAction:(id) sender {
	_minElementSize = [sender integerValue];
	[self process:nil];
}
- (IBAction) setRoundnessAction:(id) sender {
	_roundness = [sender floatValue];
	[self process:nil];
}
- (IBAction) setOptimizeCurvesAction:(id) sender {
	_optimizeCurves = [sender state];
	[self process:nil];
}
- (IBAction) setOptimizationToleranceAction:(id) sender {
	_optimizationTolerance = [sender floatValue];
	[self process:nil];
}
- (void) final {
	NSUserDefaults * Defaults = [NSUserDefaults standardUserDefaults];
	[Defaults setFloat:_threshold forKey:@"com.schriftgestaltung.Trace.Threshold"];
	[Defaults setInteger:_minElementSize forKey:@"com.schriftgestaltung.Trace.MinElementSize"];
	[Defaults setFloat:_roundness forKey:@"com.schriftgestaltung.Trace.Roundness"];
	[Defaults setBool:_optimizeCurves forKey:@"com.schriftgestaltung.Trace.OptimizeCurves"];
	[Defaults setFloat:_optimizationTolerance forKey:@"com.schriftgestaltung.Trace.OptimizationTolerance"];
	[Defaults setBool:_stroke forKey:@"com.schriftgestaltung.Trace.Stroke"];
	[super final];
}

- (void) process:(id) sender {
	int k;
	for (k = 0; k < [_shadowLayers count]; k++) {
		GSLayer * Layer = [_layers objectAtIndex:k];
		GSBackgroundImage * Image = [Layer backgroundImage];
		if (Image && [Image hasImageToDraw]) {
			
			NSArray *reps=[Image.image representations];
			NSEnumerator *enumerator = [reps objectEnumerator];
			id obj;
			NSBitmapImageRep *bir=nil;
			
			// cycle through _all_ image reps
			while ((obj = [enumerator nextObject])) {
                if([obj isKindOfClass: [NSBitmapImageRep class]]) {
					bir=(NSBitmapImageRep *)obj;
					UKLog(@"bpp: %ld", [bir bitsPerPixel]);
                }
			}
			
			NSBitmapImageRep *bitmap = nil;//[[Image.image representations] objectAtIndex:0];
			//if ([bitmap bitsPerPixel] != 24) {
			bitmap = [Image.image flatImageRep];
			//}
			CGFloat Scale = [bitmap pixelsWide] / [Image.image size].width ;
			
			NSData * BMPData = [bitmap representationUsingType:NSBMPFileType properties:nil];
			
			NSString * TempSaveString = [[_tempDir stringByAppendingPathComponent:_fileName] stringByAppendingString:@".bmp"];
			UKLog(@"TempSaveString: %@", TempSaveString);
			if (BMPData) {
				[BMPData writeToFile:TempSaveString atomically:NO];
				if (!_stroke) {
					NSMutableArray * Arguments = [NSMutableArray arrayWithObjects:
												  @"-bGlyphs",
												  [NSString stringWithFormat: @"-k %.2f", _threshold / 0xff],
												  [NSString stringWithFormat: @"-t %d", _minElementSize],
												  [NSString stringWithFormat: @"-a %.3f", (_roundness * ((4 / 3) + 0.01)) - 0.01],
												  [NSString stringWithFormat: @"-O %.3f", _optimizationTolerance],
												  TempSaveString,
												  nil];
					if (!_optimizeCurves) {
						[Arguments insertObject:@"-n" atIndex:1];
					}
					UKLog(@"__Arguments: %@", Arguments);
					NSString * Result = [self traceFile:Arguments withCommand:@"potrace"];
					[[NSFileManager defaultManager] removeItemAtPath:TempSaveString error:nil]; 
					UKLog(@"__Result: %@", Result);
					if ([Result length] > 10) {
						@try {
							
							NSArray * PathArray = [Result propertyList];
							if ([PathArray count] > 0) {
								NSMutableArray * Paths = [NSMutableArray array];
								NSAffineTransform * Transform = [NSAffineTransform transform];
								[Transform setTransformStruct:[Image transformStruct]];
								[Transform scaleBy:1.0f/Scale];
								for (NSDictionary * PathDict in PathArray) {
									GSPath * Path = [[GSPath alloc] initWithPathDict:PathDict];
									if (Path && [Path.nodes count] > 1) {
										for (GSNode * Node in Path.nodes) {
											Node.position = [Transform transformPoint:Node.position];
										}
										[Paths addObject:Path];
									}
								}
								if ([Paths count] > 0) {
									[Layer setPaths:Paths];
								}	
							}
							
						}
						@catch (NSException *exception) {
							UKLog(@"Something went wrong: %@", Result);
						}
					}
				}
			}
		}
	}
}

- (NSError*) setup {
	NSUserDefaults * Defaults = [NSUserDefaults standardUserDefaults];
	[Defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithFloat:128], @"com.schriftgestaltung.Trace.Threshold", 
								[NSNumber numberWithInt:6], @"com.schriftgestaltung.Trace.MinElementSize",
								[NSNumber numberWithFloat:0.75], @"com.schriftgestaltung.Trace.Roundness",
								[NSNumber numberWithBool:YES], @"com.schriftgestaltung.Trace.OptimizeCurves",
								[NSNumber numberWithFloat:0.2], @"com.schriftgestaltung.Trace.OptimizationTolerance",nil]];
	_threshold = [Defaults floatForKey:@"com.schriftgestaltung.Trace.Threshold"];
	_minElementSize = (NSUInteger)abs([Defaults integerForKey:@"com.schriftgestaltung.Trace.MinElementSize"]);
	_roundness = [Defaults floatForKey:@"com.schriftgestaltung.Trace.Roundness"];
	_optimizeCurves = [Defaults boolForKey:@"com.schriftgestaltung.Trace.OptimizeCurves"];
	_optimizationTolerance = [Defaults floatForKey:@"com.schriftgestaltung.Trace.OptimizationTolerance"];
	_stroke = [Defaults boolForKey:@"com.schriftgestaltung.Trace.Stroke"];
	[thresholdField setFloatValue:_threshold];
	[minElementSizeField setIntegerValue:_minElementSize];
	[roundnessField setFloatValue:_roundness];
	[optimizeCurvesCkeckBox setState:_optimizeCurves];
	[optimizationToleranceField setFloatValue:_optimizeCurves];
	[strokeCheckBox setState:_stroke];
	_tempDir = NSTemporaryDirectory();
	_fileName = [[NSProcessInfo processInfo] globallyUniqueString];
	
	[super setup];
	[self process:nil];
	return nil;
}

#pragma mark -
- (NSString*) traceFile:(NSArray*) arguments withCommand:(NSString*) Command {
	UKLog(@"__argument: %@", arguments);
	NSMutableString *output = [NSMutableString stringWithCapacity:4096];
	NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *helperApplication = [thisBundle pathForResource:Command ofType:nil];
	// Test argument.
	if ([arguments count] == 0) {
		// Return on nil or zero length input.
		return nil;
	}
	
	// Get C strings from helper application path and argument.
	const char *path = [helperApplication cStringUsingEncoding:NSUTF8StringEncoding];
	//
	
	// Create file descriptor pair for interprocess communication.
	int fd[2];
	if (pipe(fd) != 0) {
		// Return on error.
		return nil;
	}
	
	// Create child process. Vfork is faster than fork but it does make the
	// child process use the very same memory as the parent process which 
	// is dangerous unless we call exec.
	// Using fork (not vfork!) without exec is reasonable fast but becomes
	// slower with every iteration. Mac OS X is a strange beast.
	
	pid_t pid = vfork();
	//pid_t pid = fork();
	if (pid < 0) {
		// Return on error.
		return nil;
	}
	
	if (pid == 0) {
		//							  //
		// *** Begin child process. *** //
		//							  //
		
		// Close read end of the pipe.
		if (close(fd[0]) != 0) {
			// Exit on error.
			_exit(EXIT_FAILURE);
		}
		
		// Route stdout to pipe.
		if (dup2(fd[1], STDOUT_FILENO) != STDOUT_FILENO) {
			// Exit on error.
			_exit(EXIT_FAILURE);
		}
		// Execute helper application.
		//const char *input = [argument cStringUsingEncoding:NSASCIIStringEncoding];
		unsigned Count = [arguments count];
		unsigned i = 0;
		char *argv[Count+2];
		argv[0] = (char *)path;
		for (; i < Count; i++) {
			argv[i+1] = (char *)[[arguments objectAtIndex:i] cStringUsingEncoding:NSASCIIStringEncoding];
		}
		argv[i+2] = NULL;
		execv(path, argv);  
		
		// Exit on error.
		_exit(EXIT_FAILURE);
		//								//
		// ***  End child process.  *** //
		//								//
	}
	
	// Close write end of the pipe.
	if (close(fd[1]) == 0) {
		
		// Read data from child process until the pipe is closed.
		while (1) {
			char buf[4096 + 1];
			int count = read(fd[0], buf, 4096);
			if (count == -1 && errno == EINTR) {
				// System call has been interrupted by signal.
				continue;
			} else if (count < 0) {
				// Return on error.
				return nil;
			} else if (count == 0) {
				// End of file.
				break;
			} else {
				// Append data to result string.
				buf[count] = '\0';
				[output appendString:[NSString stringWithCString:buf encoding:NSASCIIStringEncoding]];
			}
		}
	}
	
	// Close read end of the pipe.
	if (close(fd[0]) != 0) {
		// Set output to nil on error but continue execution.
		output = nil;
	}
	
	// Get exit code of child process, so it doesn't become a zombie process.
	int status;
	while (1) {
		pid_t code = waitpid(pid, &status, 0);
		if (code == -1 && errno == EINTR) {
			// System call has been interrupted by signal.
			continue;
		} else if (code != pid) {
			// Return on error.
			return nil;
		} else {
			// Got exit code of child process.
			break;
		}
	}
	
	// Test exit code of child process.
	if (!WIFEXITED(status) || WEXITSTATUS(status) != EXIT_SUCCESS) {
		return nil;
	}
	
	// Success.
	return output;
}

@end
