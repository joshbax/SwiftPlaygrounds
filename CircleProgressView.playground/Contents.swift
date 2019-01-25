import UIKit
import QuartzCore
import PlaygroundSupport

class CircleProgressView: UIView {
    public var progress: Double {
        get {
            return self._progress
        }
        set(newValue) {
            self._progress = min(max(newValue, 0), 1.0)
            self.setNeedsDisplay()
        }
    }
    
    public var lineWidth: CGFloat {
        get {
            return self._lineWidth
        }
        set(newValue) {
            self._lineWidth = newValue
            self._radius = frame.width / 2 - 2 * newValue
            self.setNeedsDisplay()
        }
    }
    
    public var color: UIColor = UIColor(red: 100/255, green: 149/255, blue: 237/255, alpha: 1.0) {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    private lazy var _displayLink: CADisplayLink = {
        return CADisplayLink(target: self, selector: #selector(self.tick))
    }()

    private var _lastDrawTime: CFTimeInterval?
    private var _elapsedTime: Double = 0
    private var _drawDuration: TimeInterval
    private var _totalDrawTime: Double
    private var _radius: CGFloat
    private var _progress: Double = 0.75
    private var _lineWidth: CGFloat = 20

    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.isOpaque = false
        self.backgroundColor = nil
    }
    
    override init(frame: CGRect) {
        _lineWidth = frame.width * 0.1
        _radius = frame.width / 2 - _lineWidth
        _totalDrawTime = 0
        _drawDuration = 2.0
        super.init(frame: frame)
        self.backgroundColor = nil
        self.isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if (newSuperview != nil) {
            _displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        }
    }

    override func draw(_ rect: CGRect) {
        
        guard let ctx = UIGraphicsGetCurrentContext() else{ return }
        ctx.clear(rect)
        
        let radiansToDraw = (self.progress * Double.pi * 2) * self.easeInOut(_totalDrawTime, _drawDuration)

        let startPoint = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        let arcStartRadians = -1 * CGFloat.pi / 2
        let arcEndRadians = (-1 * CGFloat.pi / 2) - CGFloat(radiansToDraw);
        let arcEndFullCircle = (-5 * CGFloat.pi / 2)// - 2 * CGFloat.pi

        let shadowArc = CGMutablePath.init()
        shadowArc.addArc(center: startPoint, radius: self._radius, startAngle: arcStartRadians, endAngle: arcEndFullCircle, clockwise: true)
        ctx.addPath(shadowArc)
        ctx.setStrokeColor(UIColor.init(white: 0, alpha: 0.1).cgColor)
        ctx.setLineWidth(self._lineWidth)
        ctx.drawPath(using: CGPathDrawingMode.stroke)
        
        let arc = CGMutablePath.init()
        arc.addArc(center: startPoint, radius: self._radius, startAngle: arcStartRadians, endAngle: arcEndRadians, clockwise: true)
        ctx.addPath(arc)
        ctx.setStrokeColor(self.color.cgColor)
        ctx.setLineWidth(self._lineWidth)
        ctx.drawPath(using: CGPathDrawingMode.stroke)
        
        _lastDrawTime = _displayLink.timestamp
    }
    
    @objc
    func tick(_ diplayLink: CADisplayLink) {
        if (_lastDrawTime == nil || _lastDrawTime == 0) {
            _lastDrawTime = _displayLink.timestamp
            return
        }
        
        if (_totalDrawTime >= _drawDuration) {
            diplayLink.invalidate()
        } else {
            _elapsedTime = _displayLink.timestamp - _lastDrawTime!
            _totalDrawTime = _totalDrawTime + _elapsedTime
        }
        
        self.setNeedsDisplay()
    }
    
    func easeInOut(_ totalDrawTime: Double, _ drawDuration: Double) -> Double {
        let t = totalDrawTime / drawDuration
        if(t > 0.5) {
            return 4 * pow((t - 1), 3) + 1
        } else {
            return 4 * pow(t, 3)
        }
        
    }
    
    private func onAnimationComplete() {
        _displayLink.invalidate()
    }
}

class MyViewController : UIViewController {
    override func loadView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let circle = CircleProgressView(frame: CGRect(x: 50, y: 50, width: 100, height: 100))
        view.backgroundColor = .green

        view.addSubview(circle)
        self.view = view
        circle.setNeedsLayout()
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = MyViewController()
