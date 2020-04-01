//
//  GameViewController.swift
//  SocialDistancingSimulator
//
//  Created by John Solsma on 3/23/20.
//  Copyright © 2020 Solsma Dev Inc. All rights reserved.
//

import UIKit
import SpriteKit

protocol SocialDistancingDelegate: class {
    func socialDistancingPercentageChanged(percent: Float)
    func socialDistancingRecoveryTimeChanged(timeInSeconds: Int)
}

protocol GameStateDelegate: class {
    func gameStateChanged(paused: Bool)
    func gameStateReset()
    func gameStateSimulationSpeedChanged(speed: Float)
}

final class GameViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let simulatorSceneSize = CGSize(width: 768, height: 802)
        static let sceneAnchorPoint = CGPoint(x: 0.5, y: 0.5)
        static let simulationSpeedSliderDefaultValue: Float = 1.0
        static let socialDistancingSliderDefaultValue: Float = 0.0
        static let recoverySliderDefaultValue: Float = 14.0
    }

    // MARK: - Outlets

    @IBOutlet private var recoverySlider: UISlider!
    @IBOutlet private var simulationSpeedSlider: UISlider!
    @IBOutlet private var socialDistancingSlider: UISlider!

    @IBOutlet private var simulationSpeedLabel: UILabel!
    @IBOutlet private var recoveryTimeLabel: UILabel!
    @IBOutlet private var socialDistancingLabel: UILabel!
    @IBOutlet private var healthyLabel: UILabel!
    @IBOutlet private var infectedLabel: UILabel!
    @IBOutlet private var recoveredLabel: UILabel!

    @IBOutlet private var startAndPauseButton: UIButton!
    @IBOutlet private var sceneView: SKView!

    // MARK: - Private Variables

    private var simulatorSceneIsPaused = true

    // MARK: - Delegates

    public weak var socialDistancingDelegate: SocialDistancingDelegate?
    public weak var gameStateDelegate: GameStateDelegate?

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        resetLabels()
        let scene = makeSimulatorScene()
        socialDistancingDelegate = scene
        gameStateDelegate = scene
        sceneView.presentScene(scene)
        sceneView.ignoresSiblingOrder = true
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
    }

    private func makeSimulatorScene() -> SimulatorScene {
        let scene = SimulatorScene(size: Constants.simulatorSceneSize)
        scene.anchorPoint = Constants.sceneAnchorPoint
        scene.scaleMode = .aspectFit
        scene.simulatorDelegate = self
        return scene
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
         return true
     }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    // MARK: - Private Functions

    private func resetSliders() {
        simulationSpeedSlider.value = Constants.simulationSpeedSliderDefaultValue
        socialDistancingSlider.value = Constants.socialDistancingSliderDefaultValue
        recoverySlider.value = Constants.recoverySliderDefaultValue
    }

    private func resetDelegates() {
        socialDistancingDelegate?.socialDistancingPercentageChanged(percent: Constants.socialDistancingSliderDefaultValue)
        gameStateDelegate?.gameStateSimulationSpeedChanged(speed: Constants.simulationSpeedSliderDefaultValue)
        socialDistancingDelegate?.socialDistancingRecoveryTimeChanged(timeInSeconds: Int(Constants.recoverySliderDefaultValue))
    }

    private func resetLabels() {
        simulationSpeedLabel.text = "Simulation speed: 1x"
        socialDistancingLabel.text = "0% Social Distancing"
        recoveryTimeLabel.text = "Recovery time: 14 days"
        healthyLabel.text = "Healthy: 303"
        infectedLabel.text = "Infected: 1"
        recoveredLabel.text = "Recovered: 0"

    }

    // MARK: - Actions

    @IBAction func startAndPauseButtonPressed(_ sender: Any) {
        simulatorSceneIsPaused.toggle()
        (sender as? UIButton)?.setTitle((simulatorSceneIsPaused ? "Start" : "Pause"), for: .normal)
        (sender as? UIButton)?.setTitleColor((simulatorSceneIsPaused ? .green : .red), for: .normal)
        gameStateDelegate?.gameStateChanged(paused: simulatorSceneIsPaused)
    }

    @IBAction func resetButtonPressed(_ sender: Any) {
        simulatorSceneIsPaused = true
        gameStateDelegate?.gameStateReset()
        gameStateDelegate?.gameStateChanged(paused: simulatorSceneIsPaused)
        startAndPauseButton.setTitle("Start", for: .normal)
        startAndPauseButton.setTitleColor(.green, for: .normal)
        resetSliders()
        resetDelegates()
        resetLabels()
    }

    @IBAction func sliderValueChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        if slider === socialDistancingSlider {
            let percentSocialDistancing = slider.value
            socialDistancingLabel.text = "\(Int(percentSocialDistancing * 100))% Social Distancing"
            socialDistancingDelegate?.socialDistancingPercentageChanged(percent: percentSocialDistancing)
        } else if slider === simulationSpeedSlider {
            let step: Float = 0.25
            let roundedValue = round(slider.value / step) * step
            let shouldPrettyFloatToInt = (floor(roundedValue) == roundedValue) && floor(roundedValue) != 0
            simulationSpeedLabel.text = (shouldPrettyFloatToInt ? "Simulation speed: \(Int(roundedValue))x" : "Simulation speed: \(roundedValue)x")
            gameStateDelegate?.gameStateSimulationSpeedChanged(speed: roundedValue)
        } else {
            let recoveryTime = (Int(slider.value))
            recoveryTimeLabel.text = "Recovery time: \(recoveryTime) days"
            socialDistancingDelegate?.socialDistancingRecoveryTimeChanged(timeInSeconds: recoveryTime)
        }
    }

}

extension GameViewController: SimulatorSceneDelegate {

    // MARK: - Simulator Scene Delegate

    func simulatorScenePopulationStateUpdated(infected: Int, healthy: Int, recovered: Int) {
        healthyLabel.text = "Healthy: \(healthy)"
        infectedLabel.text = "Infected: \(infected)"
        recoveredLabel.text = "Recovered: \(recovered)"
    }
    
    
}
