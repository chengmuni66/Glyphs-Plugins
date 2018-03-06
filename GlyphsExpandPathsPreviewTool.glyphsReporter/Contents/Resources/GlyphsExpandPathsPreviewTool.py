#!/usr/bin/env python
# encoding: utf-8

import objc
import sys

from GlyphsApp import *
from GlyphsApp.plugins import *

GlyphsReporter = objc.protocolNamed('GlyphsReporter')

class GlyphsExpandPathsPreviewTool (NSObject, GlyphsReporter):
	def init(self):
		self.controller = None
		self.offsetCurvePluginClass = None
		return self
	
	def title(self):
		return "Expand Paths Preview"
	
	def interfaceVersion(self):
		return 1
	
 	def trigger(self):
		'''The key to select the tool with keyboard'''
		return "x"
		
	def drawBackgroundForLayer_(self, Layer):
		if self.offsetCurvePluginClass is None:
			try:
				self.offsetCurvePluginClass = objc.lookUpClass("GlyphsFilterOffsetCurve")
			except:
				print "__ can't find Offset Curve Filter"
				return
		Font = Layer.parent.parent
		FontMaster = Font.fontMasterForId_(Layer.associatedMasterId)
		OffsetX = False
		OffsetY = False
		try:
			OffsetX = FontMaster.userData["GSOffsetHorizontal"].floatValue()
			OffsetY = FontMaster.userData["GSOffsetVertical"].floatValue()
			MakeStroke = False
			if "GSOffsetMakeStroke" in FontMaster.userData:
				MakeStroke = FontMaster.userData["GSOffsetMakeStroke"].boolValue()
			Position = 0.5
			if "GSOffsetPosition" in FontMaster.userData:
				Position = FontMaster.userData["GSOffsetPosition"].floatValue()
			CopyLayer = Layer.copy()
			CopyLayer.addInflectionPoints()
			try:
				self.offsetCurvePluginClass.offsetLayer_offsetX_offsetY_makeStroke_position_error_shadow_(CopyLayer, OffsetX, OffsetY, MakeStroke, Position, None, None)
			except: # new API in 2.5
				self.offsetCurvePluginClass.makeStroke_offsetX_offsetY_capStyle_(CopyLayer, OffsetX, OffsetY, 0)
			Path = CopyLayer.bezierPath
			NSColor.grayColor().set()
			if Path != None:
				Path.fill()
		except Exception as e:
			import traceback
			print traceback.format_exc()

	def drawForgroundForLayer_(self, Layer):
		pass

	def setController_(self, Controller):
		self.controller = Controller
	
