//
//  GameScene.swift
//  FlappySwift
//
//  Created by Andrew on 2/2/15.
//  Copyright (c) 2015 Broken Games. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate{
    let verticalPipeGap = 150.0
    
    var pipeTextureUp:SKTexture!
    var pipeTextureDown:SKTexture!
    var movePipesAndRemove:SKAction!
    var pipes:SKNode!
    
    var moving:SKNode!
    var bird:SKSpriteNode!
    var skyColor:SKColor!
    
    var canRestart = Bool()
    var scoreLabel:SKLabelNode!
    var score = NSInteger()
    
    /* Bitmasking */
    
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    override func didMoveToView(view: SKView) {
        canRestart = false
        
        // setup physics
        self.physicsWorld.gravity = CGVectorMake(0.0, -5.0)
        self.physicsWorld.contactDelegate = self
        
        // setup background color
        skyColor = SKColor(red: 81.0 / 255.0, green: 192.0 / 255.0, blue: 201.0 / 255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        moving = SKNode()
        self.addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)
        
        // ground
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .Nearest
        
        let moveGroundSprite = SKAction.moveByX(groundTexture.size().width * -2.0, y: 0,
            duration: NSTimeInterval(0.02 * groundTexture.size().width * 2.0))
        
        let resetGroundSprite = SKAction.moveByX(groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        
        let moveGroundSpritesForever = infiniteAction(actionSequence(moveGroundSprite, resetGroundSprite))
        
        for var i:CGFloat = 0; i < 2.0 + self.frame.size.width / (groundTexture.size().width * 2.0); ++i {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            sprite.setScale(2.0)
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2.0)
            sprite.runAction(moveGroundSpritesForever)
            
            moving.addChild(sprite)
        }
        
        // skyline
        let skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = .Nearest
        
        let moveSkySprite = SKAction.moveByX(skyTexture.size().width * -2.0, y: 0,
            duration: NSTimeInterval(0.1 * skyTexture.size().width * 2.0))
        
        let resetSkySprite = SKAction.moveByX(skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        
        let moveSkySpritesForever = infiniteAction(actionSequence(moveSkySprite, resetSkySprite))
        
        for var i:CGFloat = 0; i < 2.0 + self.frame.size.width / (skyTexture.size().width * 2.0); ++i {
            let sprite = SKSpriteNode(texture: skyTexture)
            
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPointMake(i * sprite.size.width,
                sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
            
            sprite.runAction(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        // create the pipes textures
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .Nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .Nearest
        
        // create the pipes movement actions
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTextureUp.size().width)
        
        let movePipes = SKAction.moveByX(-distanceToMove, y: 0.0, duration:NSTimeInterval(0.01 * distanceToMove))
        
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = actionSequence(movePipes, removePipes)
        
        // spawn the pipes
        let spawn = createBlock() {
            self.spawnPipes()
        }
        
        let delay = delayAction(2)
        let spawnThenDelay = actionSequence(spawn, delay)
        let spawnThenDelayForever = infiniteAction(spawnThenDelay)
        
        self.runAction(spawnThenDelayForever)
        
        // setup our bird
        let birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = .Nearest
        let birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = .Nearest
        
        let anim = SKAction.animateWithTextures([birdTexture1, birdTexture2], timePerFrame: 0.2)
        let flap = infiniteAction(anim)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y: self.frame.size.height * 0.6)
        bird.runAction(flap)
        
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.dynamic = true
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        self.addChild(bird)
        
        // create the ground
        var ground = SKNode()
        ground.position = CGPointMake(0, groundTexture.size().height)
        
        ground.physicsBody = SKPhysicsBody(rectangleOfSize:
            CGSizeMake(self.frame.size.width, groundTexture.size().height * 2.0))
        
        ground.physicsBody?.dynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        // Initialize label and create a label which holds the score
        score = 0
        scoreLabel = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        scoreLabel.position =
            CGPointMake(CGRectGetMidX( self.frame ), 3 * self.frame.size.height / 4)
        
        scoreLabel.zPosition = 100
        scoreLabel.text = String(score)
        self.addChild(scoreLabel)
    }
    
    func spawnPipes() {
        let pipePair = SKNode()
        pipePair.position =
            CGPointMake(self.frame.size.width + pipeTextureUp.size().width * 2, 0)
        
        pipePair.zPosition = -10
        
        let height = UInt32(UInt(self.frame.size.height / 4))
        let y = arc4random() % height + height
        
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPointMake(0.0,
            CGFloat(Double(y)) + pipeDown.size.height + CGFloat(verticalPipeGap))
        
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOfSize: pipeDown.size)
        pipeDown.physicsBody?.dynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPointMake(0.0, CGFloat(Double(y)))
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOfSize: pipeUp.size)
        pipeUp.physicsBody?.dynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeUp)
        
        var contactNode = SKNode()
        
        contactNode.position = CGPointMake(
            pipeDown.size.width + bird.size.width / 2, CGRectGetMidY(self.frame))
        
        contactNode.physicsBody = SKPhysicsBody(
            rectangleOfSize: CGSizeMake(pipeUp.size.width, self.frame.size.height))
        
        contactNode.physicsBody?.dynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        pipePair.runAction(movePipesAndRemove)
        pipes.addChild(pipePair)
    }
    
    func resetScene () {
        // Move bird to original position and reset velocity
        bird.position = CGPointMake(self.frame.size.width / 2.5, CGRectGetMidY(self.frame))
        bird.physicsBody?.velocity = CGVectorMake(0, 0)
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // Remove all existing pipes
        pipes.removeAllChildren()
        
        // Reset _canRestart
        canRestart = false
        
        // Reset score
        score = 0
        scoreLabel.text = String(score)
        
        // Restart animation
        moving.speed = 1
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        if moving.speed > 0  {
            for touch: AnyObject in touches {
                let location = touch.locationInNode(self)
                
                bird.physicsBody?.velocity = CGVectorMake(0, 0)
                bird.physicsBody?.applyImpulse(CGVectorMake(0, 30))
                
            }
        } else if canRestart {
            self.resetScene()
        }
    }
    
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        bird.zRotation = clamp(min: -1, max: 0.5, value: bird.physicsBody!.velocity.dy *
            (bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001))
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory
                || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
                    // Bird has contact with score entity
                    score++
                    scoreLabel.text = String(score)
                    
                    // Add a little visual feedback for the score increment
                    scoreLabel.runAction(actionSequence(
                        SKAction.scaleTo(1.5, duration:NSTimeInterval(0.1)),
                        SKAction.scaleTo(1.0, duration:NSTimeInterval(0.1)))
                    )
            } else {
                moving.speed = 0
                
                bird.physicsBody?.collisionBitMask = worldCategory
                bird.runAction(SKAction
                    .rotateByAngle(CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration:1)) {
                    self.bird.speed = 0
                }
                
                
                // Flash background if contact is detected
                self.removeActionForKey("flash")
                
                let flash = actionSequence(
                    createBlock() {
                        self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                    },
                    delayAction(0.05),
                    createBlock() {
                        self.backgroundColor = self.skyColor
                    },
                    delayAction(0.05)
                )

                self.runAction(
                    actionSequence(
                    SKAction.repeatAction(flash, count: 4),
                    createBlock() { self.canRestart = true }),
                    withKey: "flash")
                

//                self.runAction(SKAction.sequence([SKAction.repeatAction(
//                    SKAction.sequence([
//                        SKAction.runBlock({
//                            self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
//                        }),
//                        SKAction.waitForDuration(NSTimeInterval(0.05)),
//                        SKAction.runBlock({
//                            self.backgroundColor = self.skyColor
//                        }),
//                        SKAction.waitForDuration(NSTimeInterval(0.05))]), count:4),
//                    SKAction.runBlock({
//                        self.canRestart = true
//                    })
//                    ]), withKey: "flash")
            }
        }
    }
}