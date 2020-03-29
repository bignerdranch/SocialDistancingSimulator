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

class GameViewController: UIViewController {

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

    public weak var socialDistancingDelegate: SocialDistancingDelegate?
    public weak var gameStateDelegate: GameStateDelegate?

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        resetLabels()
        if let scene = SimulatorScene(fileNamed: "SimulatorScene") {
            socialDistancingDelegate = scene
            gameStateDelegate = scene
            scene.scaleMode = .aspectFit
            scene.simulatorDelegate = self
            sceneView.presentScene(scene)
            sceneView.ignoresSiblingOrder = true
            sceneView.showsFPS = true
            sceneView.showsNodeCount = true
        }
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
        simulationSpeedSlider.value = 1.0
        socialDistancingSlider.value = 0.0
        recoverySlider.value = 14.0
    }

    private func resetDelegates() {
        socialDistancingDelegate?.socialDistancingPercentageChanged(percent: 0.0)
        gameStateDelegate?.gameStateSimulationSpeedChanged(speed: 1.0)
        socialDistancingDelegate?.socialDistancingRecoveryTimeChanged(timeInSeconds: 14)
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
        print("healthy: \(healthy) infected: \(infected)")
        healthyLabel.text = "Healthy: \(healthy)"
        infectedLabel.text = "Infected: \(infected)"
        recoveredLabel.text = "Recovered: \(recovered)"
    }
    
    
}
