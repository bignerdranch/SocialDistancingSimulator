//
//  PersonNode.swift
//  SocialDistancingSimulator
//
//  Created by John Solsma on 3/23/20.
//  Copyright © 2020 Solsma Dev Inc. All rights reserved.
//

import UIKit
import SpriteKit

final class PersonNode: SKSpriteNode {

    // MARK: - Constants

    private enum Constants {
        static let nodeTexture = SKTexture(imageNamed: "node_ring")
        static let nodeScale: CGFloat = 0.05
        static let physicsBodyRadius: CGFloat = 6.5
        static let movementKey = "movement"
        static let movementReverseKey = "movementReverse"
    }

    // MARK: - Contact Category

    enum ContactCategory  {
        static let person: UInt32 =  1 << 0
    }

    // MARK: - Prognosis
    
    enum Prognosis {
        case healthy
        case infected
        case recovered
    }

    // MARK: - Private Variables

    private var currentVector = vector2(0.0,0.0)
    private var nodePath = CGMutablePath()
    private var pathLine: SKShapeNode?

    private var shouldDrawPath = false {
        didSet {
            if shouldDrawPath {
                beginDrawingPath()
            } else {
                self.removeAction(forKey: "drawLine")
            }
        }
    }

    // MARK: - Public Variables

    var recoveryTime = 14
    var recoveryHandler: (()->(Void))?
    var state: Prognosis = .healthy {
        didSet {
            switch state {
            case .infected:
                infect()
            case .recovered:
                recover()
            case .healthy:
                break
            }
        }
    }

    var isSocialDistancing = false {
        didSet {
            if isSocialDistancing {
                removeAction(forKey: Constants.movementKey)
                removeAction(forKey: Constants.movementReverseKey)
            } else {
                commitRandomVector()
            }
        }
    }

    // MARK: - Setup

    init() {
        super.init(texture: Constants.nodeTexture,
                   color: SKColor.clear,
                   size: Constants.nodeTexture.size())
        setScale(Constants.nodeScale)
        color = UIColor.green
        colorBlendFactor = 1.0
        addObserver(self,
                    forKeyPath: #keyPath(SKNode.parent),
                    options: [.old, .new, .initial],
                    context: nil)
        physicsBody = buildPhysicsBody()

    }

    private func buildPhysicsBody() -> SKPhysicsBody {
        let pb = SKPhysicsBody(circleOfRadius: Constants.physicsBodyRadius)
        pb.isDynamic = true
        pb.affectedByGravity = false
        pb.usesPreciseCollisionDetection = true
        pb.categoryBitMask = ContactCategory.person
        pb.contactTestBitMask = ContactCategory.person | SimulatorScene.ContactCategory.walls
        pb.collisionBitMask = ContactCategory.person | SimulatorScene.ContactCategory.walls
        return pb
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)
    {
        if keyPath == #keyPath(SKNode.parent) && self.scene != nil
        {
            didAttachToScene()
        }
    }
    
    private func didAttachToScene()
    {
        commitRandomVector()
    }

    // MARK: - Helpers

    private func randomVector() -> simd_double2 {
        let randomNum = Double(Int.random(in: -100...100))
        let otherRandom = Double(100 - abs(randomNum)) * (Bool.random() ? 1 : -1)
        return  vector2(randomNum, otherRandom)
    }

    private func wildCardMovement() -> Bool {
        Bool.random() && Bool.random() && Bool.random() // 12.5% chance
    }
    
    private func commitRandomVector() {
        currentVector = randomVector()
        run(SKAction.repeatForever(SKAction.moveBy(x: CGFloat(currentVector.x),
                                                   y: CGFloat(currentVector.y),
                                                   duration: 2.0)), withKey: Constants.movementReverseKey)
    }

    private func beginDrawingPath() {
        let pathDrawingAction = SKAction.repeatForever(SKAction.sequence([SKAction.run { [weak self] in
            guard let self = self else { return }
            self.nodePath.move(to: self.position)
            }, SKAction.wait(forDuration: 0.2), SKAction.run { [weak self] in
                guard let self = self else { return }
                self.nodePath.addLine(to: self.position)
                if self.pathLine == nil {
                    self.pathLine = self.pathLine(from: self.nodePath)
                } else {
                    self.pathLine?.removeFromParent()
                    self.pathLine = self.pathLine(from: self.nodePath)
                }
                guard let path = self.pathLine else { return }
                self.parent?.addChild(path)
            }]))
        run(pathDrawingAction, withKey: "drawLine")
    }

    private func pathLine(from path: CGMutablePath) -> SKShapeNode {
        let line = SKShapeNode(path: path)
        line.strokeColor = .red
        line.fillColor = .red
        line.lineWidth = 3
        line.alpha = 0.5
        return line
    }

    private func reverseVector() {
        currentVector = vector2(currentVector.x * -1, currentVector.y * -1) // Reverse current vector
        if wildCardMovement() {
            currentVector = randomVector() // Or 12.5% of the time change to a random vector
        }
        removeAction(forKey: Constants.movementKey)
        removeAction(forKey: Constants.movementReverseKey)
        run(SKAction.repeatForever(SKAction.moveBy(x: CGFloat(currentVector.x),
                                                   y: CGFloat(currentVector.y),
                                                   duration: 2.0)), withKey: Constants.movementReverseKey)
    }

    // MARK: - Public Functions

    func contactedAnotherPerson() {
        if !isSocialDistancing {
            reverseVector()
        }
    }

    func contactedBarrier() {
        reverseVector()
    }
    
    private func infect() {
        color = .red
        shouldDrawPath = true
        run(SKAction.sequence([SKAction.wait(forDuration: TimeInterval(recoveryTime)), SKAction.run({ [weak self] in
            guard let self = self else { return }
            self.state = .recovered
            self.shouldDrawPath = false
            if let recover = self.recoveryHandler {
                recover()
            }
        })]))
    }

    private func recover() {
        color = .blue
    }

}
