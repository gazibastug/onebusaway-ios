//
//  RegionsService.swift
//  OBALocationKit
//
//  Created by Aaron Brethorst on 11/10/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation
import OBANetworkingKit
import CoreLocation

@objc(OBARegionsServiceDelegate)
public protocol RegionsServiceDelegate {
    func regionsServiceUnableToSelectRegion(_ service: RegionsService)
    func regionsService(_ service: RegionsService, updatedRegion region: Region)
}

@objc(OBARegionsService)
public class RegionsService: NSObject {
    private let modelService: RegionsModelService
    private let locationService: LocationService
    private let userDefaults: UserDefaults

    public weak var delegate: RegionsServiceDelegate?

    public init(modelService: RegionsModelService, locationService: LocationService, userDefaults: UserDefaults) {
        self.modelService = modelService
        self.locationService = locationService
        self.userDefaults = userDefaults
        self.regions = RegionsService.loadStoredRegions(from: userDefaults)
        self.currentRegion = RegionsService.loadCurrentRegion(from: userDefaults)

        super.init()

        updateRegionsList()

        self.locationService.addDelegate(self)
    }

    // MARK: - Regions Data

    public private(set) var regions: [Region] {
        didSet {
            storeRegions()
        }
    }

    public private(set) var currentRegion: Region? {
        didSet {
            if let currentRegion = currentRegion {
                delegate?.regionsService(self, updatedRegion: currentRegion)
            }

            storeCurrentRegion()
        }
    }
}

// MARK: - Region Data Storage
extension RegionsService {
    private static let storedRegionsUserDefaultsKey = "OBAStoredRegionsUserDefaultsKey"
    private static let currentRegionUserDefaultsKey = "OBACurrentRegionUserDefaultsKey"
    private static let regionsUpdatedAtUserDefaultsKey = "OBARegionsUpdatedAtUserDefaultsKey"

    // MARK: - Save Regions

    private func storeRegions() {
        do {
            let regionsData = try PropertyListEncoder().encode(regions)
            userDefaults.set(regionsData, forKey: RegionsService.storedRegionsUserDefaultsKey)
            userDefaults.set(Date(), forKey: RegionsService.regionsUpdatedAtUserDefaultsKey)
        }
        catch {
            print("Unable to write regions to user defaults: \(error)")
        }
    }

    private func storeCurrentRegion() {
        userDefaults.set(currentRegion, forKey: RegionsService.currentRegionUserDefaultsKey)
    }

    // MARK: - Load Stored Regions

    private class func loadStoredRegions(from userDefaults: UserDefaults) -> [Region] {
        guard
            let regionsData = userDefaults.object(forKey: storedRegionsUserDefaultsKey) as? Data,
            let regions = try? PropertyListDecoder().decode([Region].self, from: regionsData) else {
            return bundledRegions
        }

        return regions
    }

    private class func loadCurrentRegion(from userDefaults: UserDefaults) -> Region? {
        return userDefaults.object(forKey: currentRegionUserDefaultsKey) as? Region
    }

    // MARK: - Bundled Regions

    private class var bundledRegions: [Region] {
        let bundle = Bundle(for: self)
        let bundledRegionsFilePath = bundle.path(forResource: "regions-v3", ofType: "json")!
        let data = try! NSData(contentsOfFile: bundledRegionsFilePath) as Data
        return DictionaryDecoder.decodeRegionsFileData(data)
    }
}

extension RegionsService {
    public func updateRegionsList(forceUpdate: Bool = false) {
        // only update once per week, unless forceUpdate is true.
        if let lastUpdatedAt = userDefaults.object(forKey: RegionsService.regionsUpdatedAtUserDefaultsKey) as? Date,
           abs(lastUpdatedAt.timeIntervalSinceNow) < 604800,
           !forceUpdate {
            return
        }

        let op = modelService.getRegions()
        op.completionBlock = { [weak self] in
            guard let self = self else {
                return
            }

            self.regions = op.regions
            self.updateCurrentRegion()
        }
    }
}

// MARK: - Region Updates
extension RegionsService: LocationServiceDelegate {
    public func locationService(_ service: LocationService, locationChanged location: CLLocation) {
        updateCurrentRegion()
    }

    private func updateCurrentRegion() {
        guard let location = locationService.currentLocation else {
            return
        }

        guard let newRegion = (regions.filter { $0.contains(location: location) }).first else {
            delegate?.regionsServiceUnableToSelectRegion(self)
            return
        }

        currentRegion = newRegion
    }
}