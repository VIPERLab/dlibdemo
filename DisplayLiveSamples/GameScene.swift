//
//  GameScene.swift
//  Space Race
//
//  Created by Jason Eng on 9/13/15.
//  Copyright (c) 2015 EngJason. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var starfield: SKEmitterNode!
    var player: SKSpriteNode!
    var polygonNode:SKSpriteNode!
    var polygon:SKShapeNode!
    var scoreLabel: SKLabelNode!
    var transform:CGAffineTransform?
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var possibleEnemies = ["ball", "ball", "hammer"]
    var gameTimer: NSTimer!
    var gameOver = false
    
    override func didMoveToView(view: SKView) {
        
        transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        transform = CGAffineTransformMakeScale(1, -1)

        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.horizontalAlignmentMode = .Left
//        addChild(scoreLabel)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: #selector(setupNew), userInfo: nil, repeats: true)
    }
    
    func setupNew() {
        let start = CGPointMake(RandomCGFloat(0, max: self.frame.width), 0)
        let end = CGPointMake(RandomCGFloat(self.frame.width * 1/4, max: self.frame.width * 3/4), self.frame.height/2)
        
        createNew(view!, fromPoint: start, toPoint: end)
    }
    
    func createNew(view : SKView, fromPoint start : CGPoint, toPoint end: CGPoint) {
        //1 is good 2 is bad
        let rand = RandomInt(1, max: 2)
        let sprite = SKSpriteNode(imageNamed: possibleEnemies[rand])
        let path = arcBetweenPoints(view, fromPoint: start, toPoint: end)
        let followArc = SKAction.followPath(path, asOffset: false, orientToPath: true, duration: 1)
        
        sprite.position = start
        sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size)
        sprite.physicsBody?.categoryBitMask = UInt32(rand)
        
        self.addChild(sprite)
        sprite.runAction(followArc) {
            sprite.removeFromParent()
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let object:SKPhysicsBody!
        
        //if bodyA is an object
        if contact.bodyA.categoryBitMask > 0 {
            object = contact.bodyA
        } else {
            //bodyA is the player, instead use bodyB
            object = contact.bodyB
        }
        
        if object.categoryBitMask == 1 {
            if let thing = object.node {
                thing.removeFromParent()
                score += 100
            }
        } else {
            let explosionPath = NSBundle.mainBundle().pathForResource("explosion", ofType: "sks")!
            let explosion = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionPath) as! SKEmitterNode
            explosion.position = polygonNode.position
            addChild(explosion)
            
            polygonNode.removeFromParent()
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        let mouth = (UIApplication.sharedApplication().delegate as! AppDelegate).mouth
//        if we have data to work with
        if !mouth.isEmpty && mouth.first!.x != 0 && mouth.first!.y != 0 {
//        create player position and draw shape based on mouth array
            if polygonNode != nil { polygonNode.removeFromParent() }
            addMouth(mouth)
        }
    }
    
    func addMouth(mouth:[CGPoint]) {
        var anchorPoint:CGPoint!
        let pathToDraw:CGMutablePathRef = CGPathCreateMutable()
        
        var center = self.view!.convertPoint( CGPointMake( (mouth[2].x + mouth[6].x) / 2, (mouth[2].y + mouth[6].y) / 2), toScene: self)
        
        let trueCenter = self.view!.convertPoint(CGPointMake(414/2.0, 736/2.0), toScene: self)
//        print("from \(self.view!.convertPoint(center, fromScene: self))")
//        var newcenter = self.view!.convertPoint(center, fromScene: self)
        center = rotatePoint(center, aroundOrigin: trueCenter, byDegrees: -90)
//        newcenter = CGPointApplyAffineTransform(newcenter, CGAffineTransformMakeRotation(CGFloat(M_PI)))
//        newcenter = CGPointApplyAffineTransform(newcenter, CGAffineTransformMakeScale(1, -1))
//        center = self.view!.convertPoint(newcenter, toScene: self)
//        print("to \(self.view!.convertPoint(center, fromScene: self))")
        for m in mouth {
            let mm = self.view!.convertPoint(m, toScene: self)
            if m == mouth.first! {
                anchorPoint = mm
                CGPathMoveToPoint(pathToDraw, nil, mm.x, mm.y)
            } else {
                CGPathAddLineToPoint(pathToDraw, nil, mm.x, mm.y)
            }
        }
        CGPathAddLineToPoint(pathToDraw, nil, anchorPoint.x, anchorPoint.y)
        polygon = SKShapeNode(path: pathToDraw)
        polygon.antialiased = true
        polygon.strokeColor = SKColor.redColor()
        polygon.fillColor = SKColor.redColor()
        polygon.name = "mouthshape"

        let texture = view!.textureFromNode(polygon)
        polygonNode = SKSpriteNode(texture: texture, size: polygon.calculateAccumulatedFrame().size)
        polygonNode.physicsBody = SKPhysicsBody(texture: polygonNode.texture!, size: polygonNode.calculateAccumulatedFrame().size)
        
        polygonNode.name = "mouthnode"
        polygonNode.position = center
        
        polygonNode.physicsBody!.contactTestBitMask = 1 | 2
        polygonNode.physicsBody!.categoryBitMask = 0
        self.addChild(polygonNode)

    }
    
    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, byDegrees: CGFloat) -> CGPoint {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx) // in radians
        let newAzimuth = azimuth + byDegrees * CGFloat(M_PI / 180.0) // convert it to radians
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        return CGPoint(x: x, y: y)
    }
    
    func arcBetweenPoints(view : SKView, fromPoint start : CGPoint, toPoint end: CGPoint) -> CGPath {
        
        // Animation's path
        let path = UIBezierPath()
        
        // Move the "cursor" to the start
        path.moveToPoint(start)
        
        // Calculate the control points
        let factor : CGFloat = 0.5
        
        let deltaX : CGFloat = end.x - start.x
        let deltaY : CGFloat = end.y - start.y
        
        let c1 = CGPoint(x: start.x + deltaX * factor, y: start.y)
        let c2 = CGPoint(x: end.x, y: end.y - deltaY * factor)
        
        // Draw a curve towards the end, using control points
        path.addCurveToPoint(end, controlPoint1:c1, controlPoint2:c2)
        
        //        let curve = SKShapeNode()
        //        curve.path = path.CGPath
        //        curve.lineWidth = 4
        //        curve.strokeColor = UIColor.redColor()
        //        self.addChild(curve)
        
        // Use this path as the animation's path (casted to CGPath)
        return path.CGPath;
    }
}