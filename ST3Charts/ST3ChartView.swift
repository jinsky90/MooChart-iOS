//
//  ST3Chart.swift
//  ST3Charts
//
//  Created by Kim JungMoo on 18/02/2019.
//  Copyright © 2019 Kim JungMoo. All rights reserved.
//

import UIKit

protocol ST3ChartViewDelegate: class {
    func chartView(_ chartView: ST3ChartView, lineAxisTextFor value: CGFloat) -> String
    func chartView(_ chartView: ST3ChartView, axisTextFor axis: ST3ChartAxis) -> String
    func chartView(_ chartView: ST3ChartView, didSelected axis: ST3ChartAxis?)
}

final class ST3ChartView: UIView {
    var barData                 : ST3ChartBarData?
    var lineData                : ST3ChartLineData?
    
    var axises                  : [ST3ChartAxis]            = []
    var axisFont                : UIFont                    = UIFont.systemFont(ofSize: 9)
    var axisColor               : UIColor                   = UIColor.black
    var axisInterval            : Int                       = 3
    var axisDividerColor        : UIColor                   = UIColor.lightGray
    var axisBackgroundColor     : UIColor                   = UIColor.white
    
    var lineAxisFont            : UIFont                    = UIFont.systemFont(ofSize: 8)
    var lineAxisColor           : UIColor                   = UIColor.black
    var lineAxisInterval        : Int                       = 2

    var axisMargin              : CGFloat                   = 3
    
    var leftMargin              : CGFloat                   = 30
    var rightMargin             : CGFloat                   = 15
    var bottomMargin            : CGFloat                   = 25

    var horizontalIndicatorColor: UIColor                   = UIColor.gray
    var highlightIndicatorColor : UIColor                   = UIColor.gray

    var selectedAxis            : ST3ChartAxis?
    
    weak var delegate           : ST3ChartViewDelegate?

    var chartArea: CGRect {
        let width = self.bounds.width - (self.leftMargin + self.rightMargin)
        let height = self.bounds.height - self.bottomMargin
        return CGRect(x: self.leftMargin, y: 0, width: width, height: height)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.handleTouches(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        self.handleTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.handleTouches(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.handleTouches(touches)
    }
    
    override func draw(_ rect: CGRect) {
        self.drawLineAxis(rect)
        self.drawHighlightIndicator(rect)
        self.drawAxis(rect)
        self.drawAxisDivider(rect)

        self.drawChartBar(rect)
        self.drawChartLine(rect)
        self.drawHighlightLineCircle(rect)

    }
    
    func reloadData() {
        self.setNeedsDisplay()
    }
    
    private func handleTouches(_ touches: Set<UITouch>) {
        let findAxis = self.findAxisByTouch(touches.first)
        if self.selectedAxis != findAxis {
            self.selectedAxis = findAxis
            self.notifyDidSelected(axis: findAxis)
            self.setNeedsDisplay()
        }
    }
    
    private func findAxisByTouch(_ touch: UITouch?) -> ST3ChartAxis? {
        guard let location = touch?.location(in: self) else { return nil }
        let chartWidth = self.chartArea.width
        let groupCount = self.axises.count
        let groupWidth = chartWidth / CGFloat(groupCount)
        
        let findIndex = max(min(Int((location.x - self.leftMargin) / groupWidth), groupCount - 1), 0)
        return self.axises[findIndex]
    }
    
    private func lineAxisText(value: CGFloat) -> NSString {
        return (self.delegate?.chartView(self, lineAxisTextFor: value) ?? "\(value)") as NSString
    }
    
    private func axisText(axis: ST3ChartAxis) -> NSString {
        return (self.delegate?.chartView(self, axisTextFor: axis) ?? "\(axis.text)") as NSString
    }
    
    private func notifyDidSelected(axis: ST3ChartAxis?) {
        self.delegate?.chartView(self, didSelected: axis)
    }
    
    private func drawHighlightIndicator(_ rect: CGRect) {
        guard let selectedAxis = self.selectedAxis else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard let selectedIndex = self.axises.firstIndex(of: selectedAxis) else { return }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        let chartX = self.chartArea.origin.x
        let chartY = self.chartArea.origin.y
        let chartWidth = self.chartArea.width
        let viewHeight = rect.height
        
        let groupCount = self.axises.count
        let groupWidth = chartWidth / CGFloat(groupCount)
        
        let x = ((CGFloat(selectedIndex) * groupWidth) + groupWidth / 2) + chartX
        let y = chartY
        context.setFillColor(self.highlightIndicatorColor.cgColor)
        context.fill(CGRect(x: x, y: y, width: 0.5, height: viewHeight))
    }
    
    private func drawHighlightLineCircle(_ rect: CGRect) {
        guard let lineData = self.lineData else { return }
        guard let selectedAxis = self.selectedAxis else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard let selectedIndex = self.axises.firstIndex(of: selectedAxis) else { return }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        let chartX = self.chartArea.origin.x
        let chartWidth = self.chartArea.width
        let chartHeight = self.chartArea.height
        
        let groupCount = self.axises.count
        let groupWidth = chartWidth / CGFloat(groupCount)
        
        for dataSet in lineData.dataSets {
            guard selectedIndex < dataSet.entries.count else { continue }
            let entryIndex = selectedIndex
            let entry = dataSet.entries[entryIndex]
            
            let x = ((CGFloat(entryIndex) * groupWidth) + groupWidth / 2) + chartX
            let y = chartHeight - (entry.value * (chartHeight / lineData.maxValue))
            
            let circleRadius = dataSet.circleRadius
            let circleSize = (circleRadius) * 2
            let circleRect = CGRect(x: x - circleRadius, y: y - circleRadius, width: circleSize, height: circleSize)
            context.setFillColor(dataSet.color.cgColor)
            context.fillEllipse(in: circleRect)
            
            context.setStrokeColor(dataSet.circleBorderColor.cgColor)
            context.setLineWidth(dataSet.circleBorder)
            context.strokeEllipse(in: circleRect)
            
            let holeRadius = dataSet.holeRadius
            let holeSize = holeRadius * 2
            let holeRect = CGRect(x: x - holeRadius, y: y - holeRadius, width: holeSize, height: holeSize)
            context.setFillColor(dataSet.holeColor.cgColor)
            context.fillEllipse(in: holeRect)
        }
    }

    private func drawLineAxis(_ rect: CGRect) {
        guard let lineData = self.lineData else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        defer { context.restoreGState() }
        
        let chartX = self.chartArea.origin.x
        let chartWidth = self.chartArea.width
        let chartHeight = self.chartArea.height
        
        let maxValue = Int(lineData.maxValue)
        let attributes = self.textAttributes(font: self.lineAxisFont, color: self.lineAxisColor)
        
        let axisHeight = chartHeight / CGFloat(maxValue)
        
        var value = self.lineAxisInterval
        repeat {
            let text = self.lineAxisText(value: CGFloat(value))
            
            let textSize = self.textSize(text, attributes: attributes)
            
            let indicatorY = chartHeight - (axisHeight * CGFloat(value))
            let x = chartX - textSize.width
            let y = indicatorY - (textSize.height / 2)
            
            context.setFillColor(self.horizontalIndicatorColor.cgColor)
            context.fill(CGRect(x: chartX, y: indicatorY, width: chartWidth, height: 1))
            text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
            
            value = (value + self.lineAxisInterval)
        } while value < maxValue
    }
    
    private func drawAxis(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        defer { context.restoreGState() }
        
        let chartX = self.chartArea.origin.x
        let chartWidth = self.chartArea.width
        let chartHeight = self.chartArea.height
        
        let groupCount = self.axises.count
        let groupWidth = chartWidth / CGFloat(groupCount)
        
        let attributes = self.textAttributes(font: self.axisFont, color: self.axisColor)
        
        for (index, axis) in self.axises.enumerated() {
            guard (index + 1) % self.axisInterval == 0 else { continue }
    
            let text = self.axisText(axis: axis)
            let textSize = self.textSize(text, attributes: attributes)
            
            let x = (groupWidth * CGFloat(index)) + ((groupWidth - textSize.width) / 2) + chartX
            let y = chartHeight + self.axisMargin
            
            context.setFillColor(self.axisBackgroundColor.cgColor)
            context.fill(CGRect(x: x, y: y, width: textSize.width, height: textSize.height))
            
            text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }
    
    private func drawAxisDivider(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        defer { context.restoreGState() }
        
        let viewWidth = rect.width
        let chartHeight = self.chartArea.height
        
        let y = chartHeight
        
        context.setFillColor(self.axisDividerColor.cgColor)
        context.fill(CGRect(x: 0, y: y, width: viewWidth, height: 1))
    }
    
    private func drawChartBar(_ rect: CGRect) {
        guard let barData = self.barData else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        let chartX = self.chartArea.origin.x
        let chartWidth = self.chartArea.width
        let chartHeight = self.chartArea.height
        
        let groupCount = self.axises.count
        let groupWidth = chartWidth / CGFloat(groupCount)
        let totalBarWidth = groupWidth * (1 - barData.groupSpace)
        
        var maxBarHeight = chartHeight
        if let lineData = self.lineData {
            let axisHeight = chartHeight / lineData.maxValue
            maxBarHeight = (axisHeight * CGFloat(self.lineAxisInterval))
        }
        
        for (dataSetIndex, dataSet) in barData.dataSets.enumerated() {
            let barWidth = totalBarWidth / CGFloat(barData.dataSets.count)
            for (entryIndex, entry) in dataSet.entries.enumerated() {
                let x = (CGFloat(entryIndex) * groupWidth) + (CGFloat(dataSetIndex) * barWidth) + (totalBarWidth / 2) + chartX
                let y = chartHeight
                let barHeight = (entry.value * (maxBarHeight / barData.maxValue))
                context.setFillColor(dataSet.color.cgColor)
                context.fill(CGRect(x: x, y: y, width: barWidth, height: -barHeight))
            }
        }
    }
    
    private func drawChartLine(_ rect: CGRect) {
        guard let lineData = self.lineData else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.saveGState()
        defer { context.restoreGState() }

        let chartX = self.chartArea.origin.x
        let chartWidth = self.chartArea.width
        let chartHeight = self.chartArea.height
        
        let groupCount = self.axises.count
        let groupWidth = chartWidth / CGFloat(groupCount)
        
        for dataSet in lineData.dataSets {
            var lineSegments = [CGPoint]()
            for (entryIndex, entry) in dataSet.entries.enumerated() {
                let x = ((CGFloat(entryIndex) * groupWidth) + groupWidth / 2) + chartX
                let y = chartHeight - (entry.value * (chartHeight / lineData.maxValue))
                
                let newPoint = CGPoint(x: x, y: y)
                lineSegments.append(newPoint)
                if (0 < entryIndex) && (entryIndex < dataSet.entries.count - 1) {
                    lineSegments.append(newPoint)
                }
            }
            context.setStrokeColor(dataSet.color.cgColor)
            context.setLineWidth(dataSet.width)
            context.strokeLineSegments(between: lineSegments)
        }
    }
    
    private func textAttributes(font: UIFont, color: UIColor) -> [NSAttributedString.Key : Any] {
        return [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
    }
    
    private func textSize(_ text: NSString, attributes: [NSAttributedString.Key : Any]) -> CGSize {
        return text.boundingRect(with: self.bounds.size, options: .usesFontLeading, attributes: attributes, context: nil).size
    }
}
