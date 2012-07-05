#!/usr/bin/env python
# encoding: utf-8

import objc
from Foundation import *
from AppKit import *

GlyphsReporter = objc.protocolNamed('GlyphsReporter')

class GlyphsExpandPathsPreviewTool (NSObject, GlyphsReporter):
	def init(self):
		self.controller = None
		self.offsetCurvePlugin = None
		return self
	
	def title(self):
		return "Expand Paths Preview"
	
	def interfaceVersion(self):
		return 1
	
 	def keyEquivalent(self):
		'''The key + cmd+opt+shift that is used as a keyboard shortcut'''
		return "x"
		
	def drawBackgroundForLayer_(self, Layer):
		if self.offsetCurvePlugin is None:
			self.offsetCurvePlugin = GlyphsFilterOffsetCurve.alloc().init()
		Font = Layer.parent().parent()
		FontMaster = Font.fontMasterForId_(Layer.associatedMasterId())
		if FontMaster is not None and FontMaster.userData().className() == "__NSCFDictionary" :
			if FontMaster.userData().has_key("GSOffsetHorizontal"):
				OffsetX = FontMaster.userData()["GSOffsetHorizontal"].floatValue()
				OffsetY = FontMaster.userData()["GSOffsetVertical"].floatValue()
				MakeStroke = False
				if FontMaster.userData().has_key("GSOffsetMakeStroke"):
					MakeStroke = FontMaster.userData()["GSOffsetMakeStroke"].boolValue()
				Position = 0.5
				if FontMaster.userData().has_key("GSOffsetPosition"):
					Position = FontMaster.userData()["GSOffsetPosition"].floatValue()
				CopyLayer = Layer.copy()
				CopyLayer.addInflectionPoints()
				self.offsetCurvePlugin.offsetLayer_offsetX_offsetY_makeStroke_position_error_shadow_(CopyLayer, OffsetX, OffsetY, MakeStroke, Position, None, None)
				Path = CopyLayer.bezierPath()
				NSColor.grayColor().set()
				if Path != None:
					Path.fill()
	
	def drawForgroundForLayer_(self, Layer):
		pass

	def setController_(self, Controller):
		self.controller = Controller
	
