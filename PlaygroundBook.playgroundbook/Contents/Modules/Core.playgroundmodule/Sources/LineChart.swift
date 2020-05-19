import UIKit
import QuartzCore

// delegate method
public protocol LineChartDelegate {
    func didSelectDataPoint(_ x: CGFloat, yValues: [CGFloat])
}

/**
 * LineChart
 */
open class LineChartView: UIView {

    /**
    * Helpers class
    */
    fileprivate class Helpers {

        /**
        * Convert hex color to UIColor
        */
        fileprivate class func UIColorFromHex(_ hex: Int) -> UIColor {
            let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
            let blue = CGFloat((hex & 0xFF)) / 255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1)
        }

        /**
        * Lighten color.
        */
        fileprivate class func lightenUIColor(_ color: UIColor) -> UIColor {
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            return UIColor(hue: h, saturation: s, brightness: b * 1.5, alpha: a)
        }
    }

    public struct Labels {
        public var visible: Bool = true
        public var values: [String] = []
    }

    public struct Grid {
        public var visible: Bool = true
        public var count: CGFloat = 10
        // #eeeeee
        public var color: UIColor = .lightGray//UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1)
    }

    public struct Axis {
        public var visible: Bool = true
        // #607d8b
        public var color: UIColor = UIColor.lightGray//(red: 96/255.0, green: 125/255.0, blue: 139/255.0, alpha: 1)
        public var inset: CGFloat = 15
    }

    public struct Coordinate {
        // public
        public var labels: Labels = Labels()
        public var grid: Grid = Grid()
        public var axis: Axis = Axis()

        // private
        fileprivate var linear: LinearScale?
        fileprivate var scale: ((CGFloat) -> CGFloat)?
        fileprivate var invert: ((CGFloat) -> CGFloat)?
        fileprivate var ticks: (CGFloat, CGFloat, CGFloat)?
    }

    public struct Animation {
        public var enabled: Bool = true
        public var duration: CFTimeInterval = 1
    }

    public struct Dots {
        public var visible: Bool = true
        public var color: UIColor = UIColor.lightGray
        public var innerRadius: CGFloat = 8
        public var outerRadius: CGFloat = 12
        public var innerRadiusHighlighted: CGFloat = 8
        public var outerRadiusHighlighted: CGFloat = 12
    }

    // default configuration
    open var area: Bool = true
    open var animation: Animation = Animation()
    open var dots: Dots = Dots()
    open var lineWidth: CGFloat = 2

    open var x: Coordinate = Coordinate()
    open var y: Coordinate = Coordinate()


    // values calculated on init
    fileprivate var drawingHeight: CGFloat = 0 {
        didSet {
            let max = getMaximumValue()
            let min = getMinimumValue()
            y.linear = LinearScale(domain: [min, max], range: [0, drawingHeight])
            y.scale = y.linear!.scale()
            y.ticks = y.linear!.ticks(Int(y.grid.count))
        }
    }
    fileprivate var drawingWidth: CGFloat = 0 {
        didSet {
            if let data = dataStore.first {
                x.linear = LinearScale(domain: [0.0, CGFloat(data.value.count - 1)], range: [0, drawingWidth])
                x.invert = x.linear!.invert()
                x.scale = x.linear!.scale()
                x.ticks = x.linear!.ticks(Int(x.grid.count))
            }
        }
    }

    open var delegate: LineChartDelegate?

    // data stores
    fileprivate var dataStore: [String: [CGFloat]] = [:]
//    fileprivate var dotsDataStore: [String: [DotCALayer]] = [:]
    fileprivate var lineLayerStore: [CAShapeLayer] = []

    fileprivate var removeAll: Bool = false

    // category10 colors from d3 - https://github.com/mbostock/d3/wiki/Ordinal-Scales
    open var colors: [UIColor] = [
        UIColor(red: 0.121569, green: 0.466667, blue: 0.705882, alpha: 1),
        UIColor(red: 1, green: 0.498039, blue: 0.054902, alpha: 1),
        UIColor(red: 0.172549, green: 0.627451, blue: 0.172549, alpha: 1),
        UIColor(red: 0.839216, green: 0.152941, blue: 0.156863, alpha: 1),
        UIColor(red: 0.580392, green: 0.403922, blue: 0.741176, alpha: 1),
        UIColor(red: 0.54902, green: 0.337255, blue: 0.294118, alpha: 1),
        UIColor(red: 0.890196, green: 0.466667, blue: 0.760784, alpha: 1),
        UIColor(red: 0.498039, green: 0.498039, blue: 0.498039, alpha: 1),
        UIColor(red: 0.737255, green: 0.741176, blue: 0.133333, alpha: 1),
        UIColor(red: 0.0901961, green: 0.745098, blue: 0.811765, alpha: 1)
    ]

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func draw(_ rect: CGRect) {

        if removeAll {
            let context = UIGraphicsGetCurrentContext()
            context?.clear(rect)
            return
        }

        self.drawingHeight = self.bounds.height - (2 * y.axis.inset)
        self.drawingWidth = self.bounds.width - (2 * x.axis.inset) - 20

        // remove all labels
        for view: AnyObject in self.subviews {
            view.removeFromSuperview()
        }

        // remove all lines on device rotation
        for lineLayer in lineLayerStore {
            lineLayer.removeFromSuperlayer()
        }
        lineLayerStore.removeAll()

//        // remove all dots on device rotation
//        for dotsData in dotsDataStore {
//            for dot in dotsData.value {
//                dot.removeFromSuperlayer()
//            }
//        }
//        dotsDataStore.removeAll()

        // draw grid
        if x.grid.visible && y.grid.visible { drawGrid() }

        // draw axes
        if x.axis.visible && y.axis.visible { drawAxes() }

        // draw labels
        if x.labels.visible { drawXLabels() }
        if y.labels.visible { drawYLabels() }

        // draw lines
        for (index, (identifier, value)) in dataStore.enumerated() {
            self.drawLine(index, identifier: identifier)

            // draw dots

            if dots.visible {
                self.drawDataDots(index, identifier: identifier)
            }

            // draw area under line chart
            if area {
                self.drawAreaBeneathLineChart(index, identifier: identifier)
            }

        }

    }

    /**
     * Get y value for given x value. Or return zero or maximum value.
     */
    fileprivate func getYValuesForXValue(_ x: Int) -> [CGFloat] {
        var result: [CGFloat] = []
        for lineData in dataStore.map({ $0.value }) {
            if x < 0 {
                result.append(lineData[0])
            } else if x > lineData.count - 1 {
                result.append(lineData[lineData.count - 1])
            } else {
                result.append(lineData[x])
            }
        }
        return result
    }


//
//    /**
//     * Handle touch events.
//      */
//    fileprivate func handleTouchEvents(_ touches: NSSet!, event: UIEvent) {
//        if (self.dataStore.isEmpty) {
//            return
//        }
//        guard let Xinvert = self.x.invert else { return }
//
//        let point: AnyObject! = touches.anyObject() as? AnyObject
//        let xValue = point.location(in: self).x
//        let inverted = Xinvert(xValue - x.axis.inset)
//        let rounded = Int(round(Double(inverted)))
//        let yValues: [CGFloat] = getYValuesForXValue(rounded)
////        highlightDataPoints(rounded)
//        delegate?.didSelectDataPoint(CGFloat(rounded), yValues: yValues)
//    }
//
//
//
//    /**
//     * Listen on touch end event.
//     */
//    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        handleTouchEvents(touches as? NSSet, event: event!)
//    }
//
//
//
//    /**
//     * Listen on touch move event
//     */
//    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        handleTouchEvents(touches as? NSSet, event: event!)
//    }



    /**
     * Highlight data points at index.
//     */
//    fileprivate func highlightDataPoints(_ index: Int) {
//        for (lineIndex, dotsData) in dotsDataStore.enumerated() {
//            // make all dots white again
//            for dot in dotsData.value {
//                dot.backgroundColor = dots.color.cgColor
//            }
//            // highlight current data point
//            var dot: DotCALayer
//            if index < 0 {
//                dot = dotsData.value[0]
//            } else if index > dotsData.value.count - 1 {
//                dot = dotsData.value[dotsData.value.count - 1]
//            } else {
//                dot = dotsData.value[index]
//            }
//            dot.backgroundColor = Helpers.lightenUIColor(colors[lineIndex]).cgColor
//        }
//    }



    /**
     * Draw small dot at every data point.
     */
    fileprivate func drawDataDots(_ lineIndex: Int, identifier: String) {
//        var dotLayers: [DotCALayer] = []
//        guard var data = self.dataStore[identifier] else { return }
//
//        guard let Xscale = self.x.scale, let Yscale = self.y.scale else { return }
//
//        for (index, item) in data.enumerated() {
//            let xValue = Xscale(CGFloat(index)) + x.axis.inset - dots.outerRadius/2
//            let yValue = self.bounds.height - Yscale(item) - y.axis.inset - dots.outerRadius/2
//
//            // draw custom layer with another layer in the center
//            let dotLayer = DotCALayer()
//            dotLayer.dotInnerColor = colors[lineIndex]
//            dotLayer.innerRadius = dots.innerRadius
//            dotLayer.backgroundColor = dots.color.cgColor
//            dotLayer.cornerRadius = dots.outerRadius / 2
//            dotLayer.frame = CGRect(x: xValue, y: yValue, width: dots.outerRadius, height: dots.outerRadius)
//            self.layer.addSublayer(dotLayer)
//            dotLayers.append(dotLayer)
//
//            // animate opacity
////            if animation.enabled {
////                let anim = CABasicAnimation(keyPath: "opacity")
////                anim.duration = animation.duration
////                anim.fromValue = 0
////                anim.toValue = 1
////                dotLayer.add(anim, forKey: "opacity")
////            }
//
//        }
//        self.dotsDataStore[identifier] = dotLayers
//        dotsDataStore.append(dotLayers)
    }



    /**
     * Draw x and y axis.
     */
    fileprivate func drawAxes() {
        guard let Yscale = self.y.scale else { return }

        let height = self.bounds.height
        let width = self.bounds.width
        let path = UIBezierPath()
        // draw x-axis
        x.axis.color.setStroke()

        let y0 = height - Yscale(0) - y.axis.inset
        path.move(to: CGPoint(x: x.axis.inset + 20 , y: y0))
        path.addLine(to: CGPoint(x: width - x.axis.inset + 20, y: y0))
        path.stroke()
        // draw y-axis
        y.axis.color.setStroke()
        path.move(to: CGPoint(x: 35, y: height - y.axis.inset))
        path.addLine(to: CGPoint(x: 35, y: y.axis.inset))
        path.stroke()
    }



    /**
     * Get maximum value in all arrays in data store.
     */
    fileprivate func getMaximumValue() -> CGFloat {
        var max: CGFloat = 1
        for data in dataStore {
            if let newMax = data.value.max(), newMax > max {
                max = newMax
            }
        }
        return max
    }



    /**
     * Get maximum value in all arrays in data store.
     */
    fileprivate func getMinimumValue() -> CGFloat {
        var min: CGFloat = 0
        for data in dataStore {
            if let newMin = data.value.min(), newMin < min {
                min = newMin
            }
        }
        return min
    }



    /**
     * Draw line.
     */
    fileprivate func drawLine(_ lineIndex: Int, identifier: String) {
        guard let data = self.dataStore[identifier], !data.isEmpty else { return }
        let path = UIBezierPath()

        guard let Xscale = self.x.scale, let Yscale = self.y.scale else { return }

        var xValue = Xscale(0) + x.axis.inset + 20
        var yValue = self.bounds.height - Yscale(data[0]) - y.axis.inset
        path.move(to: CGPoint(x: xValue, y: yValue))
        for index in 1..<data.count {
            xValue = Xscale(CGFloat(index)) + x.axis.inset
            yValue = self.bounds.height - Yscale(data[index]) - y.axis.inset
            path.addLine(to: CGPoint(x: xValue, y: yValue))
        }

        let layer = CAShapeLayer()
        layer.frame = self.bounds
        layer.path = path.cgPath
        layer.strokeColor = colors[lineIndex].cgColor
        layer.fillColor = nil
        layer.lineWidth = lineWidth
        self.layer.addSublayer(layer)

//        // animate line drawing
//        if animation.enabled {
//            let anim = CABasicAnimation(keyPath: "strokeEnd")
//            anim.duration = animation.duration
//            anim.fromValue = 0
//            anim.toValue = 1
//            layer.add(anim, forKey: "strokeEnd")
//        }

        // add line layer to store
        lineLayerStore.append(layer)
    }



    /**
     * Fill area between line chart and x-axis.
     */
    fileprivate func drawAreaBeneathLineChart(_ lineIndex: Int, identifier: String) {
        guard let data = self.dataStore[identifier], !data.isEmpty else { return }
        let path = UIBezierPath()

        guard let Yscale = self.y.scale else { return }
        guard let Xscale = self.x.scale else { return }

        colors[lineIndex].withAlphaComponent(0.2).setFill()
        // move to origin
        path.move(to: CGPoint(x: x.axis.inset + 20, y: self.bounds.height - Yscale(0) - y.axis.inset))
        // add line to first data point
        path.addLine(to: CGPoint(x: x.axis.inset + 20, y: self.bounds.height - Yscale(data[0]) - y.axis.inset))
        // draw whole line chart
        for index in 1..<data.count {
            let x1 = Xscale(CGFloat(index)) + x.axis.inset// + 20
            let y1 = self.bounds.height - Yscale(data[index]) - y.axis.inset
            path.addLine(to: CGPoint(x: x1, y: y1))
        }
        // move down to x axis
        path.addLine(to: CGPoint(x: Xscale(CGFloat(data.count - 1)) + x.axis.inset + 20.0, y: self.bounds.height - Yscale(0) - y.axis.inset))
        // move to origin
        path.addLine(to: CGPoint(x: x.axis.inset + 20.0, y: self.bounds.height - Yscale(0) - y.axis.inset))
        path.fill()
    }



    /**
     * Draw x grid.
     */
    fileprivate func drawXGrid() {
        x.grid.color.setStroke()
        let path = UIBezierPath()
        var x1: CGFloat
        let y1: CGFloat = self.bounds.height - y.axis.inset
        let y2: CGFloat = y.axis.inset

        guard let (start, stop, step) = self.x.ticks, start > stop else { return }
        guard let Xscale = self.x.scale else { return }

        for i in stride(from: start, through: stop, by: step) {
            x1 = Xscale(i) + x.axis.inset
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x1, y: y2))
        }
        path.stroke()
    }



    /**
     * Draw y grid.
     */
    fileprivate func drawYGrid() {
        self.y.grid.color.setStroke()
        let path = UIBezierPath()
        let x1: CGFloat = x.axis.inset + 20
        let x2: CGFloat = self.bounds.width - x.axis.inset
        var y1: CGFloat
        guard let (start, stop, step) = self.y.ticks else { return }
        guard let Yscale = self.y.scale else { return }

        for i in stride(from: start, through: stop, by: step){
            y1 = self.bounds.height - Yscale(i) - y.axis.inset
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y1))
        }
        path.stroke()
    }



    /**
     * Draw grid.
     */
    fileprivate func drawGrid() {
        drawXGrid()
        drawYGrid()
    }



    /**
     * Draw x labels.
     */
    fileprivate func drawXLabels() {
        let xAxisData = self.dataStore.first?.value ?? []
        let y = self.bounds.height - x.axis.inset

//        guard let Xlinear = x.linear else { return }
//        let (start, stop, step) = Xlinear.ticks(xAxisData.count)
//        guard start > stop else { return }
//        guard let Xscale = x.scale else { return }
//        let width = Xscale(step)
        guard let (start, stop, step) = self.x.ticks, start < stop else { return }
        guard let Xscale = self.x.scale else { return }
        let width = Xscale(step)
        for i in stride(from: start, through: stop, by: step){
            let xValue = Xscale(CGFloat(i)) + x.axis.inset - (width / 2)
            let label = UILabel(frame: CGRect(x: xValue, y: y, width: width, height: x.axis.inset))
            label.font = UIFont.preferredFont(forTextStyle: .caption2)
            label.textAlignment = .center
//            label.text = String(Int(round(i)))

            if (x.labels.values.count != 0) {
                label.text = x.labels.values[Int(i)]
            } else {
                label.text = String(Int(round(i)))
            }
//            label.text = text

//            self.addSubview(label)
        }

//        var text: String
//        for (index, _) in xAxisData.enumerated() {
//            let xValue = Xscale(CGFloat(index)) + x.axis.inset - (width / 2)
//            let label = UILabel(frame: CGRect(x: xValue, y: y, width: width, height: x.axis.inset))
//            label.font = UIFont.preferredFont(forTextStyle: .caption2)
//            label.textAlignment = .center
//            if (x.labels.values.count != 0) {
//                text = x.labels.values[index]
//            } else {
//                text = String(index)
        //            }
        //            label.text = text
        //            self.addSubview(label)
        //        }
    }
    
    
    
    /**
     * Draw y labels.
     */
    fileprivate func drawYLabels() {
        var yValue: CGFloat
        guard let (start, stop, step) = self.y.ticks else { return }
        guard let Yscale = self.y.scale else { return }

        for i in stride(from: start, through: stop, by: step){
            yValue = self.bounds.height - Yscale(i) - (y.axis.inset * 1.5)
            let label = UILabel(frame: CGRect(x: 0, y: yValue, width: y.axis.inset + 20, height: y.axis.inset))
            label.lineBreakMode = .byClipping
            label.font = UIFont.preferredFont(forTextStyle: .caption2)
            label.textAlignment = .center
            label.text = String(Double(round(i*100)/100))
            self.addSubview(label)
        }
    }
    /**
     * Add line chart
     */
    open func addLine(_ data: [CGFloat], for identifier: String) {
        self.dataStore[identifier] = data
        
        self.setNeedsDisplay()
    }

    open func addValue(to identifier: String, _ data: CGFloat) {
        self.dataStore[identifier, default: []].append(data)

        self.setNeedsDisplay()
    }



    /**
     * Make whole thing white again.
     */
    open func clearAll() {
        self.removeAll = true
        clear()
        self.setNeedsDisplay()
        self.removeAll = false
    }



    /**
     * Remove charts, areas and labels but keep axis and grid.
     */
    open func clear() {
        // clear data
        dataStore.removeAll()
        self.setNeedsDisplay()
    }
}


/**
 * LinearScale
 */
open class LinearScale {

    var domain: [CGFloat]
    var range: [CGFloat]

    public init(domain: [CGFloat] = [0, 1], range: [CGFloat] = [0, 1]) {
        self.domain = domain
        self.range = range
    }

    open func scale() -> (_ x: CGFloat) -> CGFloat {
        return bilinear(domain, range: range, uninterpolate: uninterpolate, interpolate: interpolate)
    }

    open func invert() -> (_ x: CGFloat) -> CGFloat {
        return bilinear(range, range: domain, uninterpolate: uninterpolate, interpolate: interpolate)
    }

    open func ticks(_ m: Int) -> (CGFloat, CGFloat, CGFloat) {
        return scale_linearTicks(domain, m: m)
    }

    fileprivate func scale_linearTicks(_ domain: [CGFloat], m: Int) -> (CGFloat, CGFloat, CGFloat) {
        return scale_linearTickRange(domain, m: m)
    }

    fileprivate func scale_linearTickRange(_ domain: [CGFloat], m: Int) -> (CGFloat, CGFloat, CGFloat) {
        let extent = scaleExtent(domain)
        let span = extent[1] - extent[0]
        var step = CGFloat(pow(10, floor(log(Double(span) / Double(m)) / M_LN10)))
        let err = CGFloat(m) / span * step

        // Filter ticks to get closer to the desired count.
        if (err <= 0.15) {
            step *= 10
        } else if (err <= 0.35) {
            step *= 5
        } else if (err <= 0.75) {
            step *= 2
        }

        // Round start and stop values to step interval.
        let start = ceil(extent[0] / step) * step
        let stop = floor(extent[1] / step) * step + step * 0.5 // inclusive

        return (start, stop, step)
    }

    fileprivate func scaleExtent(_ domain: [CGFloat]) -> [CGFloat] {
        let start = domain[0]
        let stop = domain[domain.count - 1]
        return start < stop ? [start, stop] : [stop, start]
    }

    fileprivate func interpolate(_ a: CGFloat, b: CGFloat) -> (_ c: CGFloat) -> CGFloat {
        var diff = b - a
        func f(_ c: CGFloat) -> CGFloat {
            return (a + diff) * c
        }
        return f
    }

    fileprivate func uninterpolate(_ a: CGFloat, b: CGFloat) -> (_ c: CGFloat) -> CGFloat {
        var diff = b - a
        var re = diff != 0 ? 1 / diff : 0
        func f(_ c: CGFloat) -> CGFloat {
            return (c - a) * re
        }
        return f
    }

    fileprivate func bilinear(_ domain: [CGFloat], range: [CGFloat], uninterpolate: (_ a: CGFloat, _ b: CGFloat) -> (_ c: CGFloat) -> CGFloat, interpolate: (_ a: CGFloat, _ b: CGFloat) -> (_ c: CGFloat) -> CGFloat) -> (_ c: CGFloat) -> CGFloat {
        var u: (_ c: CGFloat) -> CGFloat = uninterpolate(domain[0], domain[1])
        var i: (_ c: CGFloat) -> CGFloat = interpolate(range[0], range[1])
        func f(_ d: CGFloat) -> CGFloat {
            return i(u(d))
        }
        return f
    }

}
