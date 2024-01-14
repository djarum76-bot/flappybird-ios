//
//  GameScene.swift
//  FlappyBird
//
//  Created by habil . on 14/01/24.
//

import SpriteKit
import GameplayKit

enum GameState {
    case initial, play, dead
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var backgroundMusic: SKAudioNode!
    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!
    let pipeTexture = SKTexture(imageNamed: "pipe")
    var pipePhysics: SKPhysicsBody!
    
    var gameState = GameState.initial
    
    var score = 0 {
        didSet{
            scoreLabel.text = "SCORE : \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        createPlayer()
        createBackground()
        createGround()
        createScore()
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        physicsWorld.contactDelegate = self
        
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "m4a") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        createLogo()
        pipePhysics = SKPhysicsBody(texture: pipeTexture, size: pipeTexture.size())
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .initial:
            gameState = .play
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let wait = SKAction.wait(forDuration: 0.5)
            let activatePlayer = SKAction.run { [unowned self] in
                self.player.physicsBody?.isDynamic = true
                self.startPipes()
            }
            
            let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
            logo.run(sequence)
        case .play:
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 5))
        case .dead:
            if let scene = GameScene(fileNamed: "GameScene") {
                scene.scaleMode = .aspectFill
                let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
                view?.presentScene(scene, transition: transition)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard player != nil else { return }
        
        let value = player.physicsBody!.velocity.dy * 0.001
        let rotate = SKAction.rotate(toAngle: value, duration: 0.1)
        
        player.run(rotate)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect" {
            if contact.bodyA.node == player {
                contact.bodyB.node?.removeFromParent()
            } else {
                contact.bodyA.node?.removeFromParent()
            }
            
            let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            run(sound)
            
            score += 1
            
            return
        }
        
        guard contact.bodyA.node != nil && contact.bodyB.node != nil else {
            return
        }
        
        if contact.bodyA.node == player || contact.bodyB.node == player {
            if let explosion = SKEmitterNode(fileNamed: "PlayerExplosion") {
                explosion.position = player.position
                addChild(explosion)
            }
            
            let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
            run(sound)
            
            gameOver.alpha = 1
            gameState = .dead
            backgroundMusic.run(SKAction.stop())
            
            player.removeFromParent()
            speed = 0
        }
    }
    
    func createPlayer() {
        let playerTexture = SKTexture(imageNamed: "player")
        player = SKSpriteNode(texture: playerTexture)
        player.zPosition = 10
        player.position = CGPoint(x: frame.width / 3, y: frame.height * 0.6)
        
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: playerTexture, size: playerTexture.size())
        player.physicsBody!.contactTestBitMask = player.physicsBody!.collisionBitMask
        player.physicsBody?.isDynamic = false
        
//        player.physicsBody?.collisionBitMask = 0
    }
    
    func createBackground() {
        let backgroundTexture = SKTexture(imageNamed: "background")
        
        for i in 0 ... 1 {
            let background = SKSpriteNode(texture: backgroundTexture)
            background.zPosition = -30
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: (backgroundTexture.size().width * CGFloat(i)) - CGFloat(1 * i), y: 0)
            addChild(background)
            
            let moveLeft = SKAction.moveBy(x: -backgroundTexture.size().width, y: 0, duration: 20)
            let moveReset = SKAction.moveBy(x: backgroundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            background.run(moveForever)
        }
    }
    
    func createGround() {
        let groundTexture = SKTexture(imageNamed: "ground")
        
        for i in 0 ... 1 {
            let ground = SKSpriteNode(texture: groundTexture)
            ground.zPosition = -10
            ground.position = CGPoint(x: (groundTexture.size().width / 2.0 + (groundTexture.size().width * CGFloat(i))), y: groundTexture.size().height / 2)
            
            ground.physicsBody = SKPhysicsBody(texture: ground.texture!, size: ground.texture!.size())
            ground.physicsBody?.isDynamic = false
            
            addChild(ground)
            
            let moveLeft = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
            let moveReset = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            ground.run(moveForever)
        }
    }
    
    func createPipes() {
        let topPipe = SKSpriteNode(texture: pipeTexture)
        topPipe.physicsBody = pipePhysics.copy() as? SKPhysicsBody
        topPipe.physicsBody?.isDynamic = false
        
        topPipe.zRotation = .pi
        topPipe.xScale = -1.0
        
        let bottomPipe = SKSpriteNode(texture: pipeTexture)
        bottomPipe.physicsBody = pipePhysics.copy() as? SKPhysicsBody
        bottomPipe.physicsBody?.isDynamic = false
        
        topPipe.zPosition = -20
        bottomPipe.zPosition = -20
        
        let pipeCollision = SKSpriteNode(color: UIColor.clear, size: CGSize(width: 32, height: frame.height))
        pipeCollision.physicsBody = SKPhysicsBody(rectangleOf: pipeCollision.size)
        pipeCollision.physicsBody?.isDynamic = false
        
        pipeCollision.name = "scoreDetect"
        
        addChild(topPipe)
        addChild(bottomPipe)
        addChild(pipeCollision)
        
        let xPosition = frame.width + topPipe.frame.width
        
        let max = CGFloat(frame.height / 4.75)
        let yPosition = CGFloat.random(in: max ... 320)
        
        let pipeDistance: CGFloat = 50
        
        topPipe.position = CGPoint(x: xPosition, y: yPosition + topPipe.size.height + pipeDistance)
        bottomPipe.position = CGPoint(x: xPosition, y: yPosition - pipeDistance)
        pipeCollision.position = CGPoint(x: xPosition + (pipeCollision.size.width * 2), y: frame.midY)
        
        let endPosition = frame.width + (topPipe.frame.width * 2)
        
        let moveAction = SKAction.moveBy(x: -endPosition, y: 0, duration: 6.2)
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        topPipe.run(moveSequence)
        bottomPipe.run(moveSequence)
        pipeCollision.run(moveSequence)
    }
    
    func startPipes() {
        let create = SKAction.run { [unowned self] in
            self.createPipes()
        }
        
        let wait = SKAction.wait(forDuration: 3)
        let sequence = SKAction.sequence([create, wait])
        let repeatForever = SKAction.repeatForever(sequence)
        
        run(repeatForever)
    }
    
    func createScore() {
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.fontSize = 24
        
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        scoreLabel.text = "SCORE : 0"
        scoreLabel.fontColor = .black
        
        addChild(scoreLabel)
    }
    
    func createLogo() {
        logo = SKSpriteNode(imageNamed: "welcome")
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logo)
        
        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOver.alpha = 0
        addChild(gameOver)
    }
}
