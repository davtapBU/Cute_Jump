//
//  GameScene.swift
//  GyroGame
//
//  Created by David Tapia on 10/21/21.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Misc
    var bottom = SKShapeNode()
    let scoreLabel = SKLabelNode(text: "0")
    var score = 0
    var highestScore = 0
    var isGameStarted = false
    let star = SKSpriteNode(imageNamed: "star")
    let playJumpSound = SKAction.playSoundFileNamed("jump", waitForCompletion: false)
    let playBreakSound = SKAction.playSoundFileNamed("break", waitForCompletion: false)
    var isSuperJumpOn = false
    var superJumpCounter: CGFloat = 0
    
    var motionManager = CMMotionManager()
    
    //Layers
    var backgroundNode: SKNode!
    var foregroundNode : SKNode!
    
    //Scale factor
    var scaleFactor: CGFloat!
    
    //Player/Objects
    var player = SKSpriteNode(imageNamed: "player")
    var pallets = [SKSpriteNode]()
    
    
    override func didMove(to view: SKView) {
        
        //Add gravity and initialize accelerometer
        motionManager.startAccelerometerUpdates()
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        //Adjust scale of objects to standard 320 point iPhone dimensions
        scaleFactor = self.size.width / 320.0
        
        //Call function to layout the world
        createWorld()
    }
    
    func createWorld() {
        createBackForeground()
        createScore()
        createPlayer()
        createBottom()
        createPallets()
    }
    
    func createBackForeground()
    {
        // Create the background node
        let backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor
        
        // Go through images until the entire background is built
        for index in 0...19 {
            let node = SKSpriteNode(imageNamed:String(format: "Background%02d", index + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(index))
            backgroundNode.addChild(node)
        }
        addChild(backgroundNode)
        
        // Foreground
        foregroundNode = SKNode()
        addChild(foregroundNode)
    }
    
    
    func createScore() {
        star.texture = SKTexture(imageNamed: "star")
        star.position = CGPoint(x: 20 + star.size.width/2, y: frame.height - (view?.safeAreaInsets.top ?? 10) - 20)
        star.zPosition = ZPositions.star
        addChild(star)
        
        scoreLabel.fontSize = 24.0
        scoreLabel.fontName = "HelveticaNeue-Bold"
        scoreLabel.fontColor = UIColor.init(red: 38/255, green: 120/255, blue: 95/255, alpha: 1)
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: star.position.x + star.frame.width/2 + 10, y: star.position.y)
        scoreLabel.zPosition = ZPositions.scoreLabel
        addChild(scoreLabel)
    }
    
    func createPlayer() {
        player.name = "Player"
        player.position = CGPoint(x: frame.midX, y: 20 + player.size.height/2)
        player.zPosition = ZPositions.player
        player.setScale(1.5)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.categoryBitMask = PhysicsCategories.playerCategory
        player.physicsBody?.contactTestBitMask = PhysicsCategories.palletCategory | PhysicsCategories.dirtPlatform | PhysicsCategories.grassPlatform
        player.physicsBody?.collisionBitMask = PhysicsCategories.none
        
        addChild(player)
    }
    
    func createBottom() {
        bottom = SKShapeNode(rectOf: CGSize(width: frame.width*2, height: 20))
        bottom.position = CGPoint(x: frame.midX, y: 10)
        bottom.fillColor = UIColor.init(red: 25/255, green: 105/255, blue: 81/255, alpha: 1)
        bottom.strokeColor = bottom.fillColor
        bottom.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 20))
        bottom.physicsBody?.affectedByGravity = false
        bottom.physicsBody?.isDynamic = false
        bottom.physicsBody?.categoryBitMask = PhysicsCategories.palletCategory
        addChild(bottom)
    }
    
    func createPallets() {
        let spaceBetweenPallets = frame.size.height/10
        for i in 0..<Int(frame.size.height/spaceBetweenPallets) {
            let x = CGFloat.random(in: 0...frame.size.width)
            let y = CGFloat.random(in: CGFloat(i)*spaceBetweenPallets+10...CGFloat(i+1)*spaceBetweenPallets-10)
            createPallet(at: CGPoint(x: x, y: y))
        }
    }
    
    func createPallet(at position: CGPoint) {
        let pallet = SKSpriteNode(imageNamed: "Platform")
        
        pallet.position = position
        pallet.zPosition = ZPositions.pallet
        pallet.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pallet.size.width, height: pallet.size.height))
        pallet.physicsBody?.categoryBitMask = PhysicsCategories.palletCategory
        pallet.physicsBody?.isDynamic = false
        pallet.physicsBody?.affectedByGravity = false
        pallets.append(pallet)
        addChild(pallet)
    }
    
    func createPallet() -> SKNode {
        let palletNode = SKNode()
        palletNode.position = CGPoint(x: self.size.width / 2, y: 80.0)
        
        let sprite = SKSpriteNode(imageNamed: "Platform")
        sprite.setScale(3.0)
        palletNode.addChild(sprite)
        
        palletNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: sprite.size.width, height: sprite.size.height))
        palletNode.physicsBody?.isDynamic = false
        palletNode.physicsBody?.allowsRotation = false
        palletNode.physicsBody?.restitution = 1.0
        palletNode.physicsBody?.friction = 0.0
        palletNode.physicsBody?.angularDamping = 0.0
        palletNode.physicsBody?.linearDamping = 0.0
        
        palletNode.physicsBody?.contactTestBitMask = 1
        
        return palletNode
    }
    
    override func update(_ currentTime: TimeInterval) {
        checkPhoneTilt()
        if isGameStarted {
            checkPlayerPosition()
            checkPlayerVelocity()
            updatePalletsPositions()
        }
    }
    
    func checkPhoneTilt() {
    }
    
    func checkPlayerPosition() {
    }
    
    func saveScore() {
    }
    
    func setScore() {
    }
    
    func checkPlayerVelocity() {
    }
    
    func updatePalletsPositions() {
    }
    
    func update(pallet: SKSpriteNode, positionY: CGFloat) {
    }
}

enum PhysicsCategories {
    static let none: UInt32 = 0
    static let playerCategory: UInt32 = 0x1
    static let palletCategory: UInt32 = 0x1 << 1
    static let dirtPlatform: UInt32 = 0x1 << 2
    static let grassPlatform: UInt32 = 0x1 << 3
}

enum ZPositions {
    static let background: CGFloat = -1
    static let pallet: CGFloat = 0
    static let player: CGFloat = 1
    static let star: CGFloat = 2
    static let scoreLabel: CGFloat = 2
    static let logo: CGFloat = 2
    static let playButton: CGFloat = 2
}
