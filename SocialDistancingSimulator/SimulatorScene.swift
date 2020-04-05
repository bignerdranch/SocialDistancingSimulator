//
//  SimulatorScene.swift
//  SocialDistancingSimulator
//
//  Created by John Solsma on 3/23/20.
//  Copyright © 2020 Solsma Dev Inc. All rights reserved.
//

import SpriteKit

protocol SimulatorSceneDelegate: class {
    func simulatorScenePopulationStateUpdated(infected: Int, healthy: Int, recovered: Int)
}

final class SimulatorScene: SKScene {

    // MARK: - Constants

    private enum Constants {
        static let startingXCoordinate = 340
        static let startingYCoordinate = 395
        static let numberOfRows = 18
        static let numberOfColumns = 15
        static let rowAndColumnPadding = 40
        static let simulatorBackgroundColor = UIColor(named: "graphBackgroundColor")!
    }

    // MARK: - Contact Category

    enum ContactCategory  {
        static let walls: UInt32 =  1 << 1
    }

    // MARK: - Public Variables
    
    weak var simulatorDelegate: SimulatorSceneDelegate?

    // MARK: - Setup

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsBody = buildPhysicsBody()
        backgroundColor = Constants.simulatorBackgroundColor
        buildInitialGameState()
        isPaused = true
    }

    private func buildPhysicsBody() -> SKPhysicsBody {
        let pb = SKPhysicsBody(edgeLoopFrom: self.frame)
        pb.categoryBitMask = ContactCategory.walls
        pb.collisionBitMask = PersonNode.ContactCategory.person
        pb.contactTestBitMask = PersonNode.ContactCategory.person
        return pb
    }

    private func buildInitialGameState() {
        placeNodes()
        infectPatientZero()
    }

    private func placeNodes() {
        var xPlacement = Constants.startingXCoordinate
        var yPlacement = Constants.startingYCoordinate
        for _ in 0...Constants.numberOfRows {
            yPlacement -= Constants.rowAndColumnPadding
            xPlacement = Constants.startingXCoordinate
            for _ in 0...Constants.numberOfColumns {
                xPlacement -= Constants.rowAndColumnPadding
                placePerson(at: CGPoint(x: xPlacement, y: yPlacement))
            }
        }
    }

    private func placePerson(at point: CGPoint) {
        let personNode = PersonNode()
        personNode.recoveryHandler = recoveryHandler
        personNode.position = point
        addChild(personNode)
    }

    private func infectPatientZero() {
        allPeople.randomElement()?.state = .infected
    }

    private func resetScene() {
        removeAllChildren()
        buildInitialGameState()
    }

    // MARK: - Private Functions

    private func socialDistance(percent: Float) {
        guard percent <= 100 else { return }
        let numberOfPeopleCurrentlySocialDistancing = peopleSocialDistancing.count
        let peopleWhoShouldBeSocialDistancing = Int(Float(allPeople.count) * percent)
        if peopleWhoShouldBeSocialDistancing > numberOfPeopleCurrentlySocialDistancing {
            let numberOfAdditionalPeopleToDistance = peopleWhoShouldBeSocialDistancing - numberOfPeopleCurrentlySocialDistancing
            peopleNotSocialDistancing.shuffled().prefix(numberOfAdditionalPeopleToDistance).forEach { $0.isSocialDistancing = true }
        } else {
            let numberOfPeopleToStopDistancing = numberOfPeopleCurrentlySocialDistancing - peopleWhoShouldBeSocialDistancing
            peopleSocialDistancing.shuffled().prefix(numberOfPeopleToStopDistancing).forEach { $0.isSocialDistancing = false }
        }
    }
}

extension SimulatorScene {

    // MARK: - Computed Variables

    private var allPeople: [PersonNode] {
        children.filter { $0 is PersonNode }.map{ $0 as! PersonNode }
    }

    private var numberOfInfected: Int {
        allPeople.filter { $0.state == .infected }.count
    }

    private var numberOfRecovered: Int {
        allPeople.filter { $0.state == .recovered }.count
    }

    private var healthyPeople: [PersonNode] {
        allPeople.filter { $0.state == .healthy }
    }

    private var numberOfHealthy: Int {
        healthyPeople.count
    }

    private var peopleSocialDistancing: [PersonNode] {
        allPeople.filter { $0.isSocialDistancing }
    }

    private var peopleNotSocialDistancing: [PersonNode] {
        allPeople.filter { !$0.isSocialDistancing }
    }

    private var recoveryHandler: ()->(Void) {
        { [weak self] in
            guard let self = self else { return }
            self.simulatorDelegate?.simulatorScenePopulationStateUpdated(infected: self.numberOfInfected, healthy: self.numberOfHealthy, recovered: self.numberOfRecovered)
        }
    }
}

extension SimulatorScene: SKPhysicsContactDelegate {

    // MARK: - Contact Delegate

    private func isNewInfection(between person: PersonNode, and otherPerson: PersonNode) -> Bool {
        (person.state == .healthy && otherPerson.state == .infected) || (person.state == .infected && otherPerson.state == .healthy)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if let personOne = contact.bodyA.node as? PersonNode, let personTwo = contact.bodyB.node as? PersonNode {
            if isNewInfection(between: personOne, and: personTwo) {
                (personOne.state == .healthy ? personOne : personTwo).state = .infected
                simulatorDelegate?.simulatorScenePopulationStateUpdated(infected: numberOfInfected, healthy: numberOfHealthy, recovered: numberOfRecovered)
            }
            personOne.contactedAnotherPerson()
            personTwo.contactedAnotherPerson()
        }
        if contact.bodyA.node is SimulatorScene || contact.bodyB.node is SimulatorScene {
            (((contact.bodyA.node is PersonNode) ? contact.bodyA.node : contact.bodyB.node) as? PersonNode)?.contactedBarrier()
        }
    }
}

extension SimulatorScene: SocialDistancingDelegate {

    // MARK: - Social Distancing Delegate

    func socialDistancingRecoveryTimeChanged(timeInSeconds: Int) {
        healthyPeople.forEach { $0.recoveryTime = timeInSeconds }
    }


    func socialDistancingPercentageChanged(percent: Float) {
        socialDistance(percent: percent)
    }

}

extension SimulatorScene: GameStateDelegate {

    // MARK: - Game State Delegate

    func gameStateSimulationSpeedChanged(speed: Float) {
        self.speed = CGFloat(speed)
    }

    func gameStateChanged(paused: Bool) {
        isPaused = paused
    }

    func gameStateReset() {
        resetScene()
    }

}
