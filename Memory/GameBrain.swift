//
//  GameBrain.swift
//  Memory
//
//  Created by Isaak Hanimann on 17.07.20.
//  Copyright © 2020 Isaak Hanimann. All rights reserved.
//

import RealityKit
import UIKit


class GameBrain {
    
    var arView: ARView!
    var gameBoard: Entity!
    let timerLabel = UILabel()
    let wonLabel = UILabel()
    let lostLabel = UILabel()
    let restartButton = UIButton()
    var tapGestureRecognizer: UITapGestureRecognizer!
    var timer: Timer?
    var secondsUntilTimeout = Constants.timoutDuration
    var selection1: CardEntity?
    var selection2: CardEntity?
    
    enum GameState {
        case notStarted
        case started
        case won
        case lost
    }
    
    var gameState = GameState.notStarted {
        didSet {
            if oldValue == .notStarted || oldValue == .won || oldValue == .lost {
                //start timer and update label
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateLabel), userInfo: nil, repeats: true)
                timerLabel.isHidden = false
            }
        }
        willSet {
            if newValue == .lost {
                DispatchQueue.main.async {
                    self.timer?.invalidate()
                    self.timerLabel.isHidden = true
                    self.lostLabel.isHidden = false
                    self.restartButton.isHidden = false
                    self.arView.removeGestureRecognizer(self.tapGestureRecognizer)
                }
            } else if newValue == .won {
                DispatchQueue.main.async {
                    self.timer?.invalidate()
                    self.timerLabel.isHidden = true
                    self.wonLabel.isHidden = false
                    self.restartButton.isHidden = false
                    self.arView.removeGestureRecognizer(self.tapGestureRecognizer)
                }
            }
        }
    }
    
    func startPlaying(on arView: ARView, with gameBoard: Entity) {
        self.arView = arView
        self.gameBoard = gameBoard
        setupTimerLabel()
        setupWonLabel()
        setupLostLabel()
        setupRestartButtonButton()
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func setupTimerLabel() {
        timerLabel.backgroundColor = UIColor(white: 0.8, alpha: 0.5)
        timerLabel.text = String(Constants.timoutDuration) + "s"
        timerLabel.textColor = .black
        timerLabel.layer.cornerRadius = 15
        timerLabel.layer.masksToBounds = true
        timerLabel.textAlignment = .center
        timerLabel.isHidden = true
        
        arView.addSubview(timerLabel)
        //the constraints have to be set after the subview is added to the view
        setTimerLabelConstraints()
    }
    
    func setTimerLabelConstraints() {
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.topAnchor.constraint(equalTo: arView.superview!.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        timerLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        timerLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timerLabel.centerXAnchor.constraint(equalTo: arView.centerXAnchor).isActive = true
    }
    
    func setupWonLabel() {
        wonLabel.backgroundColor = UIColor(red: 173/255.0, green: 228/255.0, blue: 152/255.0, alpha: 0.3)
        wonLabel.text = "You Won!"
        wonLabel.font = wonLabel.font.withSize(45)
        wonLabel.textColor = .white
        wonLabel.textAlignment = .center
        wonLabel.isHidden = true
        
        arView.addSubview(wonLabel)
        //the constraints have to be set after the subview is added to the view
        setWonLabelConstraints()
    }
    
    func setWonLabelConstraints() {
        wonLabel.translatesAutoresizingMaskIntoConstraints = false
        wonLabel.topAnchor.constraint(equalTo: arView.topAnchor).isActive = true
        wonLabel.bottomAnchor.constraint(equalTo: arView.bottomAnchor).isActive = true
        wonLabel.leadingAnchor.constraint(equalTo: arView.leadingAnchor).isActive = true
        wonLabel.trailingAnchor.constraint(equalTo: arView.trailingAnchor).isActive = true
    }
    
    func setupLostLabel() {
        lostLabel.backgroundColor = UIColor(red: 1, green: 95/255.0, blue: 64/255.0, alpha: 0.3)
        lostLabel.text = "You Lost!"
        lostLabel.font = lostLabel.font.withSize(45)
        lostLabel.textColor = .white
        lostLabel.textAlignment = .center
        lostLabel.isHidden = true
        
        arView.addSubview(lostLabel)
        //the constraints have to be set after the subview is added to the view
        setLostLabelConstraints()
    }
    
    func setLostLabelConstraints() {
        lostLabel.translatesAutoresizingMaskIntoConstraints = false
        lostLabel.topAnchor.constraint(equalTo: arView.topAnchor).isActive = true
        lostLabel.bottomAnchor.constraint(equalTo: arView.bottomAnchor).isActive = true
        lostLabel.leadingAnchor.constraint(equalTo: arView.leadingAnchor).isActive = true
        lostLabel.trailingAnchor.constraint(equalTo: arView.trailingAnchor).isActive = true
    }
    
    func setupRestartButtonButton() {
        restartButton.backgroundColor = .white
        restartButton.setTitleColor(.black, for: .normal)
        restartButton.setTitle("Restart", for: .normal)
        restartButton.layer.cornerRadius = 15
        restartButton.isHidden = true
        
        restartButton.addTarget(self, action: #selector(restartGame), for: .touchUpInside)
        
        arView.addSubview(restartButton)
        //the constraints have to be set after the subview is added to the view
        setRestartButtonConstraints()
    }
    
    func setRestartButtonConstraints() {
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        restartButton.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -80).isActive = true
        restartButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        restartButton.widthAnchor.constraint(equalToConstant: 180).isActive = true
        restartButton.centerXAnchor.constraint(equalTo: arView.centerXAnchor).isActive = true
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        
        let tapLocation = recognizer.location(in: arView)
        
        // Get the entity at the location we've tapped, if one exists
        if let cardEntity = arView.entity(at: tapLocation) as? CardEntity {
            
            if cardEntity.card.revealed {
                if self.selection1 == cardEntity {
                    // even though SelectionEntity is a reference type the item in the array won't be set to nil because the items in the array can't be nil because they are non optional
                    self.selection1 = nil
                } else if self.selection2 == cardEntity {
                    self.selection2 = nil
                }
                cardEntity.hide()
            } else {
                gameState = .started
                
                if self.selection1 == nil {
                    cardEntity.reveal()
                    self.selection1 = cardEntity
                } else if self.selection2 == nil {
                    cardEntity.reveal()
                    self.selection2 = cardEntity
                } else {
                    print("The user already has two cards selected and can therefore not reveal another card")
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.flipDuration + 0.2, execute: self.checkAndRemoveSelection)
            }
            
            
        }
    }
    
    @objc func restartGame() {
        secondsUntilTimeout = Constants.timoutDuration
        selection1 = nil
        selection2 = nil
        arView.addGestureRecognizer(tapGestureRecognizer)

        
        var cards: [CardEntity] = gameBoard.children.map({entity in
            if let cardEntity = entity as? CardEntity {
                return cardEntity
            } else {
                return nil
            }
        }).compactMap { $0 }
                
        for card in cards {
            if card.card.revealed {
                card.isEnabled = true
                card.hide()
            }
        }
        
        //Todo - cards need to be shuffled / repositioned
        cards.shuffle()
        
        for (index, card) in cards.enumerated() {
            let x = Float(index % 4) - 1.5
            let z = Float(index / 4) - 1.5
            // Set the position of the card
            let transform = Transform(rotation: simd_quatf(angle: .pi, axis: [1, 0, 0]), translation: [x * 0.1, 0, z * 0.1])
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.flipDuration) {
                card.move(to: transform, relativeTo: self.gameBoard, duration: Constants.shuffleDuration)
            }
        }
        
        DispatchQueue.main.async {
            self.restartButton.isHidden = true
            self.wonLabel.isHidden = true
            self.lostLabel.isHidden = true
            self.timerLabel.text = String(self.secondsUntilTimeout) + "s"
            self.timerLabel.isHidden = true
        }
    }
    
    func checkAndRemoveSelection() {
        if selection1?.card.kind == self.selection2?.card.kind {
            selection1?.isEnabled = false
            selection1 = nil
            selection2?.isEnabled = false
            selection2 = nil
            let numberOfEnabledCards = gameBoard.children.filter({entity in
                if let cardEntity = entity as? CardEntity {
                    if cardEntity.isEnabled {
                        return true
                    }
                }
                return false
            }).count
            
            if numberOfEnabledCards == 0 {
                gameState = .won
            }
        }
    }
    
    @objc func updateLabel() {
        if secondsUntilTimeout > 0 {
            secondsUntilTimeout -= 1
            DispatchQueue.main.async {
                self.timerLabel.text = String(self.secondsUntilTimeout) + "s"
            }
        } else {
            timer?.invalidate()
            gameState = .lost
        }
    }
    
    
    
    
}
