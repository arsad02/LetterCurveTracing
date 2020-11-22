//
//  Activity1CurveTracingView.swift
//  TracingCharacter
//
//  Created by Mohd Arsad on 11/10/20.
//  Copyright © 2020 Mohd Arsad. All rights reserved.
//

import Foundation
import UIKit

class Activity1CurveTracingView: UIView, UIGestureRecognizerDelegate {
    
    private var movingCircle = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    
    //Curve View
    private var curveView: Activity1CurveView?
    
    //Fill Prgress at trace
    private var curveProgress: CGFloat = 0.0
    
    //Pan Gesture Initial Point
    private var initialCenter = CGPoint()
    
    //Initial angle for rate the circle
    var lastRotation: CGFloat = 0
    
    //Navigation Arrow
    private var arrowImage = UIImage(named: "arrowDownCircleBlue")
    private var allPoints: [CGPoint] = []
    private var endPoint: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initiateControl()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //Setup All Control
    private func initiateControl() {
        self.initCurveView()
        self.initDraggingCircle()
        self.setupGesture()
        self.initializePathArr()
    }
    
}

//MARK: - Initiate Support Control
private extension Activity1CurveTracingView {
    
    /*
     Initialize movable circle direct view
     */
    func initDraggingCircle() {
        self.movingCircle.layer.cornerRadius = self.movingCircle.bounds.height / 2
        self.movingCircle.image = arrowImage
        let quarterRatio = self.bounds.width * 0.25
        self.initialCenter = CGPoint(x: quarterRatio * 2.7, y: quarterRatio * 0.5)
        self.movingCircle.center = self.initialCenter
        self.addSubview(movingCircle)
        self.bringSubviewToFront(movingCircle)
    }
    
    /*
    Initialize movable circle direct view
    */
    func initCurveView() {
        curveView = Activity1CurveView(frame: self.bounds)
        curveView?.progress = curveProgress
        addSubview(curveView!)
    }
}

//MARK: - Gesture Control
private extension Activity1CurveTracingView {
    /*
     Initialize gesture to navigate and fill the curve
     Note: Only work inside of tracing view
     */
    func setupGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged(gestureRecognizer:)))
        movingCircle.addGestureRecognizer(gesture)
        movingCircle.isUserInteractionEnabled = true
        gesture.delegate = self
    }
    
    //Gesture action method
    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {

        guard gestureRecognizer.view != nil else {return}
        let piece = gestureRecognizer.view!
        let translation = gestureRecognizer.translation(in: piece.superview)
        
        if gestureRecognizer.state == .began {
           // Save the view's original position.
           self.initialCenter = piece.center
        }
           // Update the position for the .began, .changed, and .ended states
        if gestureRecognizer.state != .cancelled {
            let touchPoint: CGPoint = CGPoint(x: initialCenter.x, y: initialCenter.y + translation.y)
            if let point = getTracePoint() {
                let difference = touchPoint.distance(to: point)
                guard difference < 70.0 else {
                    return
                }
                if point == endPoint {
                    self.movingCircle.gestureRecognizers?.removeAll()
                }
                let newRotation = lastRotation + piece.center.angleRadian(between: point)
                self.movingCircle.transform = CGAffineTransform(rotationAngle: newRotation - 1)
                
                self.curveView?.touchPoint = point
                piece.center = point
                self.allPoints.removeFirst()
            }
        }
        else {
           // On cancellation, return the piece to its original location.
           piece.center = initialCenter
        }
    }
    
    func getTracePoint() -> CGPoint? {
        return self.allPoints.first
    }
    
    private func initializePathArr() {
        if let path = self.curveView?.dottedLayer.path {
            let allP = path.getPathElementsPoints()
            self.allPoints = allP
        }
        self.endPoint = self.allPoints.last ?? .zero
    }
}

fileprivate class Activity1CurveView: UIView {
    
    var dottedLayer = CAShapeLayer()
    private var curveLayer = CAShapeLayer()
    private var borderLayer = CAShapeLayer()
    
    //Color
    private var curveBackgroundColor = UIColor.white
    private var curveFillColor = UIColor(red: 25/255.0, green: 168/255.0, blue: 243/255.0, alpha: 1.0)
    private var lastPoint: CGPoint = .zero
    
    var progress: CGFloat? {
        didSet {
            self.createRatioCurve()
        }
    }
    var touchPoint: CGPoint = .zero {
        didSet {
            self.createRatioCurve()
        }
    }
    var curveMainPath: UIBezierPath?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
      
        self.backgroundColor = curveBackgroundColor
        self.createCurveForTracing()
        self.createDottedLine()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createRatioCurve() {
        
        let startPoint = lastPoint
        self.updateNavigationPath(start: startPoint, end: touchPoint)
        lastPoint = touchPoint
        
    }
}

private extension Activity1CurveView {
    
    func createCurveForTracing() {
        
        let quarterRatio = self.bounds.width * 0.25
        let halfRatio = self.bounds.width * 0.5
        
        let curvePath = UIBezierPath()
        
        curvePath.move(to: CGPoint(x: quarterRatio * 2.9, y: quarterRatio * 0.5))
        curvePath.addQuadCurve(to: CGPoint(x: quarterRatio * 3.5, y: quarterRatio * 3), controlPoint: CGPoint(x: quarterRatio * 3.4, y: halfRatio))
        curvePath.addQuadCurve(to: CGPoint(x: quarterRatio * 3, y: quarterRatio * 3.5), controlPoint: CGPoint(x: quarterRatio * 3.5, y: quarterRatio * 3.5))
        curvePath.addLine(to: CGPoint(x: quarterRatio, y: quarterRatio * 3.5))
        curvePath.addQuadCurve(to: CGPoint(x: quarterRatio * 0.8, y: quarterRatio * 2.6), controlPoint: CGPoint(x: quarterRatio * 0.5, y: quarterRatio * 3.5))
        curvePath.addCurve(to: CGPoint(x: quarterRatio * 0.95, y: quarterRatio * 2.6), controlPoint1: CGPoint(x: quarterRatio * 0.87, y: quarterRatio * 2.2), controlPoint2: CGPoint(x: quarterRatio, y: quarterRatio * 2.2))
        curvePath.addQuadCurve(to: CGPoint(x: quarterRatio * 1.3, y: quarterRatio * 3.0), controlPoint: CGPoint(x: quarterRatio * 0.9, y: quarterRatio * 3.0))
        curvePath.addLine(to: CGPoint(x: quarterRatio * 2.7, y: quarterRatio * 3.0))
        curvePath.addQuadCurve(to: CGPoint(x: quarterRatio * 3.0, y: quarterRatio * 2.5), controlPoint: CGPoint(x: quarterRatio * 3.2, y: quarterRatio * 3))
        curvePath.addLine(to: CGPoint(x: quarterRatio * 2.6, y: quarterRatio * 1.1))
        curvePath.close()
        self.curveMainPath = curvePath
        
        curveLayer = CAShapeLayer()
        curveLayer.path = curvePath.cgPath
        curveLayer.fillColor = curveBackgroundColor.cgColor
        curveLayer.strokeColor = UIColor.red.cgColor
        curveLayer.lineWidth = 5.0
        self.layer.mask = curveLayer
        
        borderLayer = CAShapeLayer()
        borderLayer.path = curvePath.cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 6.0
        self.layer.addSublayer(borderLayer)
    }
    
    private func createDottedLine() {
        let quarterRatio = self.bounds.width * 0.25

        dottedLayer = CAShapeLayer()
        dottedLayer.strokeColor = UIColor.lightGray.withAlphaComponent(0.7).cgColor
        dottedLayer.lineWidth = 2
        dottedLayer.lineDashPattern = [10,3]
        dottedLayer.fillColor = UIColor.white.cgColor
        let cgPath = CGMutablePath()
        
        let p0 = CGPoint(x: quarterRatio * 2.7, y: quarterRatio * 0.5)
        let p1 = CGPoint(x: quarterRatio * 3.3, y: quarterRatio * 3.2)
        let p2 = CGPoint(x: quarterRatio * 1.5, y: quarterRatio * 3.3)
        let p3 = CGPoint(x: quarterRatio * 1.0, y: quarterRatio * 2)
        let p4 = CGPoint(x: quarterRatio * 0.4, y: quarterRatio * 3.25)
        
        cgPath.move(to: p0)
        cgPath.addLine(to: p1)
        cgPath.addLine(to: p2)
        cgPath.addQuadCurve(to: p3, control: p4)
        cgPath.closeSubpath()
        dottedLayer.path = cgPath
        self.layer.insertSublayer(dottedLayer, below: borderLayer)
    }
    
    
    private func updateNavigationPath(start: CGPoint, end: CGPoint) {
        let layerT = drawLineFromPoint(start: start, toPoint: end, ofColor: curveFillColor, lineWidth: 60.0)
        self.layer.insertSublayer(layerT, below: borderLayer)
    }

    private func drawLineFromPoint(start : CGPoint, toPoint end:CGPoint, ofColor lineColor: UIColor, lineWidth: CGFloat) -> CAShapeLayer {

        //design the path
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        
        //design path in layer
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = lineColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = .round
        return shapeLayer
    }
    
    
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: from, to: to))
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
public enum PanDirection: Int {
    case up, down, left, right
}

public extension UIPanGestureRecognizer {

    var direction: PanDirection? {
     let velocity = self.velocity(in: view)
     let isVertical = abs(velocity.y) > abs(velocity.x)
         if isVertical {
             return velocity.y > 0 ? .down : .up
         } else {
             return velocity.x > 0 ? .right : .left
         }
    }
}
