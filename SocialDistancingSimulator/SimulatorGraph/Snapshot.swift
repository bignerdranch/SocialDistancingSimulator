//
//  Snapshot.swift
//  CovidGraph
//
//  Created by Chris Morris on 3/23/20.
//  Copyright © 2020 Chris Morris. All rights reserved.
//

import Foundation

struct Snapshot {
    var healthyCount: Int
    var sickCount: Int
    var recoveredCount: Int
    
    var populationCount: Int {
        healthyCount + sickCount + recoveredCount
    }
    
    var healthyPercentage: Double {
        Double(healthyCount) / Double(populationCount)
    }
    
    var sickPercentage: Double {
        Double(sickCount) / Double(populationCount)
    }
    
    var recoveredPercentage: Double {
        Double(recoveredCount) / Double(populationCount)
    }
}
