//
//  Functional.swift
//  FlappySwift
//
//  Created by Andrew on 2/3/15.
//  Copyright (c) 2015 Broken Games. All rights reserved.
//

import Foundation
import SpriteKit

func actionSequence(actions: SKAction...) -> SKAction {
    return SKAction.sequence(actions)
}

func actionGroup(actions: SKAction...) -> SKAction {
    return SKAction.group(actions)
}

func infiniteAction(action: SKAction) -> SKAction {
    return SKAction.repeatActionForever(action)
}

func addCallback(toAction action: SKAction, callback: () -> ())
    -> SKAction {
    return actionSequence(action, createBlock(callback))
}

func createBlock(task: () ->()) -> SKAction {
    return SKAction.runBlock(task)
}

func delayAction(time: Double) -> SKAction {
    return SKAction.waitForDuration(NSTimeInterval(time))
}

func clamp(#min: CGFloat, #max: CGFloat, #value: CGFloat) -> CGFloat {
    if(value > max) {
        return max
    } else if(value < min) {
        return min
    } else {
        return value
    }
}