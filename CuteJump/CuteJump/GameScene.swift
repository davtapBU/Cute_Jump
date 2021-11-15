//
//  GameScene.swift
//  CuteJump
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
    let playBreakSound = SKAction.playSoundFileNamed("breakingSound", waitForCompletion: false)
    var isSuperJumpOn = false
    var superJumpCounter: CGFloat = 0
    
    var motionManager = CMMotionManager()
    
    //Layers
    var backgroundNode: SKNode!
    
    //Scale factor
    var scaleFactor: CGFloat!
    
    //Player/Objects
    var player = SKSpriteNode(imageNamed: "Player")
    var pallets = [SKSpriteNode]()
    
    
    override func didMove(to view: SKView) {
        //Adjust scale of objects to standard 320 point iPhone dimensions
        scaleFactor = self.size.width / 320.0
        
        //Call function to layout the world
        createWorld()
    }
    
    func createWorld() {
        createPhysicsWorld()
        createBackground()
        createScore()
        createPlayer()
        createBottom()
        createPallets()
    }
    
    func createPhysicsWorld() {
        //Add gravity and initialize accelerometer
        motionManager.startAccelerometerUpdates()
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    }
    
    func createBackground()
    {
        // Create the background node
        backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor
        
        // Go through images until the entire background is built
        for index in 0...19 {
            let node = SKSpriteNode(imageNamed:String(format: "Background%02d", index + 1))
            node.setScale(scaleFactor)
            node.zPosition = ZPositions.background
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(index))
            backgroundNode.addChild(node)
        }
        addChild(backgroundNode)
    }
    
    
    func createScore() {
        star.texture = SKTexture(imageNamed: "star")
        star.position = CGPoint(x: 100 + star.size.width/2, y: frame.height - (view?.safeAreaInsets.top ?? 10) - 50)
        star.zPosition = ZPositions.star
        addChild(star)
        
        scoreLabel.fontSize = 46.0
        scoreLabel.fontName = "Bradley Hand"
        scoreLabel.fontColor = UIColor.init(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: star.position.x + star.frame.width/2 + 10, y: star.position.y-20)
        scoreLabel.zPosition = ZPositions.scoreLabel
        addChild(scoreLabel)
    }
    
    func createPlayer() {
        player.name = "Player"
        player.position = CGPoint(x: frame.midX, y: 20 + player.size.height/2)
        player.zPosition = ZPositions.player
        player.setScale(1.1)
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
        bottom.fillColor = UIColor.init(red: 25/255, green: 105/255, blue: 74/255, alpha: 1)
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
        pallet.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pallet.size.width, height:1.0))
        pallet.physicsBody?.categoryBitMask = PhysicsCategories.palletCategory
        pallet.physicsBody?.isDynamic = false
        pallet.physicsBody?.affectedByGravity = false
        pallets.append(pallet)
        addChild(pallet)
    }
    
    override func update(_ currentTime: TimeInterval) {
        checkPhoneTilt()
        if isGameStarted {
            checkPlayerPosition()
            checkPlayerVelocity()
            updatePalletsPositions()
        }
        
        // Calculate player y offset
        if player.position.y > 200.0 {
            //Move the background at 10% of the players speed to create a parallax effet
            backgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200.0)/10))
        }
    }
    
    func checkPhoneTilt() {
        var defaultAcceleration = 9.8
        if let accelerometerData = motionManager.accelerometerData {
            var xAcceleration = accelerometerData.acceleration.x * 10
            if xAcceleration > defaultAcceleration {
                xAcceleration = defaultAcceleration + 10.0
            }
            else if xAcceleration < -defaultAcceleration {
                xAcceleration = -defaultAcceleration - 10.0
            }
            player.run(SKAction.rotate(toAngle: CGFloat(-xAcceleration/5), duration: 0.1))
            if isGameStarted {
                if isSuperJumpOn {
                    defaultAcceleration = -0.1
                }
                physicsWorld.gravity = CGVector(dx: xAcceleration, dy: -defaultAcceleration)
            }
        }
    }
    
    func checkPlayerPosition() {
        let playerWidth = player.size.width
        if player.position.y+playerWidth < 0 {
            run(SKAction.playSoundFileNamed("gameOver", waitForCompletion: false))
            saveScore()
            isGameStarted = false
            removeAllChildren()
            createWorld()
        }
        setScore()
        if player.position.x+playerWidth >= frame.size.width || player.position.x+playerWidth <= 0 {
            fixPlayerPosition()
        }
    }
    
    func saveScore() {
        UserDefaults.standard.setValue(highestScore, forKey: "LastScore")
        if highestScore > UserDefaults.standard.integer(forKey: "HighScore") {
            UserDefaults.standard.setValue(highestScore, forKey: "HighScore")
        }
    }
    
    func setScore() {
        let oldScore = score
        score = (Int(player.position.y) - Int(player.size.height/2)) - (Int(bottom.position.y) - Int(bottom.frame.size.height)/2)
        score = score < 0 ? 0 : score
        if score > oldScore {
            star.texture = SKTexture(imageNamed: "star")
            scoreLabel.fontColor = UIColor.init(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
            if score > highestScore {
                highestScore = score
            }
        }
        else {
            star.texture = SKTexture(imageNamed: "starBad")
            scoreLabel.fontColor = UIColor.init(red: 136/255, green: 24/255, blue: 0/255, alpha: 1)
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.locale = Locale(identifier: "en_US")
        let formattedScore = numberFormatter.string(from: NSNumber(value: score))
        scoreLabel.text = (formattedScore ?? "0")
    }
    
    func checkPlayerVelocity() {
        if let playerVelocity = player.physicsBody?.velocity.dx {
            if playerVelocity > 1000 {
                player.physicsBody?.velocity.dx = 1000
            }
            else if playerVelocity < -1000 {
                player.physicsBody?.velocity.dx = -1000
            }
        }
    }
    
    func updatePalletsPositions() {
        var minimumHeight: CGFloat = frame.size.height/2
        guard let playerVelocity = player.physicsBody?.velocity.dy else {
            return
        }
        var distance = playerVelocity/50
        if isSuperJumpOn {
            minimumHeight = 0
            distance = 30 - superJumpCounter
            superJumpCounter += 0.16
        }
        if player.position.y > minimumHeight && playerVelocity > 0 {
            for pallet in pallets {
                pallet.position.y -= distance
                if pallet.position.y < 0-pallet.frame.size.height/2 {
                    update(pallet: pallet, positionY: pallet.position.y)
                }
            }
            bottom.position.y -= distance
        }
    }
    
    func update(pallet: SKSpriteNode, positionY: CGFloat) {
        pallet.position.x = CGFloat.random(in: 0...frame.size.width)
        
        var direction = "Left"
        if pallet.position.x > frame.midX {
            direction = "Right"
        }
        
        pallet.removeAllActions()
        pallet.alpha = 1.0
        if Int.random(in: 1...35) == 1 {
            pallet.texture = SKTexture(imageNamed: "grassPlatform")
            updateSizeOf(pallet: pallet)
            pallet.physicsBody?.categoryBitMask = PhysicsCategories.grassPlatform
        }
        else if Int.random(in: 1...5) == 1 {
            pallet.texture = SKTexture(imageNamed: "movingPlatform")
            pallet.setScale(2.5)
            updateSizeOf(pallet: pallet)
            pallet.physicsBody?.categoryBitMask = PhysicsCategories.palletCategory
            if direction == "Left" {
                pallet.position.x = 0
                animate(pallet: pallet, isLeft: true)
            }
            else {
                pallet.position.x = frame.size.width
                animate(pallet: pallet, isLeft: false)
            }
        }
        else if Int.random(in: 1...5) == 1 {
            pallet.texture = SKTexture(imageNamed: "dirtPlatform")
            updateSizeOf(pallet: pallet)
            pallet.physicsBody?.categoryBitMask = PhysicsCategories.dirtPlatform
        }
        else {
            pallet.texture = SKTexture(imageNamed: "Platform")
            updateSizeOf(pallet: pallet)
            pallet.physicsBody?.categoryBitMask = PhysicsCategories.palletCategory
        }
        
        pallet.position.y = frame.size.height + pallet.frame.size.height/2 + pallet.position.y
    }
    
    func updateSizeOf(pallet: SKSpriteNode) {
        if let textureSize = pallet.texture?.size() {
            pallet.size = CGSize(width: textureSize.width, height: textureSize.height)
            pallet.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pallet.size.width, height: 1.0))
            pallet.physicsBody?.isDynamic = false
            pallet.physicsBody?.affectedByGravity = false
        }
    }
    
    func animate(pallet: SKSpriteNode, isLeft: Bool) {
        let distanceX = isLeft ? frame.size.width : -frame.size.width
        pallet.run(SKAction.moveBy(x: distanceX, y: 0, duration: 2)) {
            pallet.run(SKAction.moveBy(x: -distanceX, y: 0, duration: 2)) {
                self.animate(pallet: pallet, isLeft: isLeft)
            }
        }
    }
    
    func fixPlayerPosition() {
        let playerWidth = player.size.width
        if player.position.x >= frame.size.width {
            player.position.x = 0 - playerWidth/2+1
        }
        else {
            player.position.x = frame.size.width + playerWidth/2-1
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isGameStarted {
            player.physicsBody?.velocity.dy = frame.size.height*1.2 - player.position.y
            isGameStarted = true
            run(playJumpSound)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if let playerVelocity = player.physicsBody?.velocity.dy {
            if playerVelocity < 0 {
                if contactMask == PhysicsCategories.playerCategory | PhysicsCategories.palletCategory {
                    run(playJumpSound)
                    player.physicsBody?.velocity.dy = frame.size.height*1.2 - player.position.y
                }
                else if contactMask == PhysicsCategories.playerCategory | PhysicsCategories.dirtPlatform {
                    run(playJumpSound)
                    run(playBreakSound)
                    player.physicsBody?.velocity.dy = frame.size.height*1.2 - player.position.y
                    if let platform = (contact.bodyA.node?.name != "Player") ? contact.bodyA.node as? SKSpriteNode : contact.bodyB.node as? SKSpriteNode {
                        platform.physicsBody?.categoryBitMask = PhysicsCategories.none
                        platform.run(SKAction.fadeOut(withDuration: 0.5))
                    }
                }
                else if contactMask == PhysicsCategories.playerCategory | PhysicsCategories.grassPlatform {
                    run(SKAction.playSoundFileNamed("superJump", waitForCompletion: false))
                    player.physicsBody?.velocity.dy = 10
                    isSuperJumpOn = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isSuperJumpOn = false
                        self.superJumpCounter = 0
                    }
                }
            }
        }
        
        //Cause haptic feedback upon impact of 2 objects
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
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
