using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Activity;
using Toybox.Application;

class VisualGearsField extends WatchUi.DataField {

    // Class variables
    hidden var frontGear = null;
    hidden var rearGear = null;
    
    // Constructor
    function initialize() {
        DataField.initialize();
    }

    // Called when data is updated
    function compute(info) {
        // Access derailleur information
        if (info has :frontDerailleurIndex && info.frontDerailleurIndex != null) {
            frontGear = info.frontDerailleurIndex;
        }
        if (info has :rearDerailleurIndex && info.rearDerailleurIndex != null) {
            rearGear = info.rearDerailleurIndex;
        }
        
        // Return true to indicate data was processed
        return true;
    }
    
    // Update the display
    function onUpdate(dc) {
        // Clear the display
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Draw gear information display
        drawGearInfo(dc);
    }
    
    // Draw gear information display with rectangles
    function drawGearInfo(dc) {
        // Constants for display settings
        var DEBUG = false;                    // Enable/disable debug information
        var RECT_HEIGHT = 20;                // Height of gear rectangles
        var RECT_SPACING = 4;                // Spacing between rectangles
        var RECT_BORDER = 2;                 // Border thickness
        var TEXT_HEIGHT = 15;                // Height for debug text
        
        // Get display dimensions
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Set colors - updated for white background and black rectangles
        var colorBackground = Graphics.COLOR_WHITE;
        var colorBorder = Graphics.COLOR_BLACK;
        var colorSelected = Graphics.COLOR_BLACK;
        var colorUnselected = Graphics.COLOR_WHITE;
        var colorText = Graphics.COLOR_BLACK;
        
        // Fill background with white
        dc.setColor(colorBackground, colorBackground);
        dc.fillRectangle(0, 0, width, height);
        
        // ----- Get gear information -----
        var frontGearMax = 0;
        var frontGearIndex = 0;
        var frontGearSize = 0;  // Number of teeth on front gear
        var rearGearMax = 0;
        var rearGearIndex = 0;
        var rearGearSize = 0;  // Number of teeth on rear gear
        
        // Get the gear information from Activity Info
        var info = Activity.getActivityInfo();
        if (info has :frontDerailleurMax && info.frontDerailleurMax != null) {
            frontGearMax = info.frontDerailleurMax;
        }
        if (info has :frontDerailleurIndex && info.frontDerailleurIndex != null) {
            frontGearIndex = info.frontDerailleurIndex;
        }
        if (info has :frontDerailleurSize && info.frontDerailleurSize != null) {
            frontGearSize = info.frontDerailleurSize;
        }
        if (info has :rearDerailleurMax && info.rearDerailleurMax != null) {
            rearGearMax = info.rearDerailleurMax;
        }
        if (info has :rearDerailleurIndex && info.rearDerailleurIndex != null) {
            rearGearIndex = info.rearDerailleurIndex;
        }
        if (info has :rearDerailleurSize && info.rearDerailleurSize != null) {
            rearGearSize = info.rearDerailleurSize;
        }
        
        // Fallback values if no data available (common setups)
        if (frontGearMax == 0 || frontGearMax == null) {
            frontGearMax = 2;
        }
        if (rearGearMax == 0 || rearGearMax == null) {
            rearGearMax = 11;
        }
        if (frontGearSize == 0 || frontGearSize == null) {
            frontGearSize = 42;  // Common chainring size
        }
        if (rearGearSize == 0 || rearGearSize == null) {
            rearGearSize = 15;  // Common cog size
        }
        
        // Calculate rectangle width based on available space - same for both rows
        var rectWidth = (width - (RECT_SPACING * (rearGearMax + 1))) / rearGearMax;
        
        // ----- Draw Front Gears (top row, right-aligned) -----
        // Calculate starting X position to right-align front gears
        var frontStartX = width - (rectWidth + RECT_SPACING) * frontGearMax + RECT_SPACING;
        
        for (var i = 0; i < frontGearMax; i++) {
            var x = frontStartX + i * (rectWidth + RECT_SPACING);
            var y = 0;
            
            // Selected gear gets filled, others get border only
            if (i + 1 == frontGearIndex) {  // +1 because indexes are 1-based
                // Draw selected gear (filled rectangle)
                dc.setColor(colorSelected, colorBackground);
                dc.fillRectangle(x, y, rectWidth, RECT_HEIGHT);
            } else {
                // Draw unselected gear (border only)
                dc.setColor(colorBorder, colorBackground);
                dc.drawRectangle(x, y, rectWidth, RECT_HEIGHT);
            }
        }
        
        // ----- Draw Rear Gears (bottom row, full width) -----
        
        // Draw rear gear rectangles - full width
        for (var i = 0; i < rearGearMax; i++) {
            var x = RECT_SPACING + i * (rectWidth + RECT_SPACING);
            var y = RECT_HEIGHT + 5;
            
            // Selected gear gets filled, others get border only
            if (i + 1 == rearGearIndex) {  // +1 because indexes are 1-based
                // Draw selected gear (filled rectangle)
                dc.setColor(colorSelected, colorBackground);
                dc.fillRectangle(x, y, rectWidth, RECT_HEIGHT);
            } else {
                // Draw unselected gear (border only)
                dc.setColor(colorBorder, colorBackground);
                dc.drawRectangle(x, y, rectWidth, RECT_HEIGHT);
            }
        }
        
        // ----- Draw Gear Ratio Text -----
        // Position for gear ratio text (below the rectangles)
        var ratioY = 2 * (RECT_HEIGHT + 5) + 5;
        
        // Draw gear ratio text
        dc.setColor(colorText, colorBackground);
        var ratioText = frontGearSize + " / " + rearGearSize;
        dc.drawText(width/2, ratioY, Graphics.FONT_MEDIUM, ratioText, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Calculate the position for debug information below the ratio text
        var debugY = ratioY + TEXT_HEIGHT + 10;
        
        // ----- Draw Debug Information (if enabled) -----
        if (DEBUG) {
            dc.setColor(colorText, colorBackground);
            
            // Display gear indexes and counts
            var debugText = "F: " + frontGearIndex + "/" + frontGearMax + 
                        " R: " + rearGearIndex + "/" + rearGearMax;
            dc.drawText(width/2, debugY, Graphics.FONT_TINY, debugText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // If available, calculate and show gear ratio
            if (frontGearSize > 0 && rearGearSize > 0) {
                debugY += TEXT_HEIGHT + 2;
                var ratio = frontGearSize.toFloat() / rearGearSize.toFloat();
                var ratioCalcText = "Ratio: " + ratio.format("%.2f");
                dc.drawText(width/2, debugY, Graphics.FONT_TINY, ratioCalcText, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // Show battery level if available
            debugY += TEXT_HEIGHT + 2;
            dc.drawText(width/2, debugY, Graphics.FONT_TINY, "Batt: N/A", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}