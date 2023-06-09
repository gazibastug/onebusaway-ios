//
//  TripSegmentView.swift
//  OBAKit
//
//  Copyright © Open Transit Software Foundation
//  This source code is licensed under the Apache 2.0 license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit
import OBAKitCore

/// The line/squircle adornment on the leading side of a cell on the `TripFloatingPanelController`.
///
/// Depicts if the associated stop is the user's destination or the current location of the transit vehicle.
class TripSegmentView: UIView {

    private let lineWidth: CGFloat = 1.0
    private let circleRadius: CGFloat = 30.0
    private var halfRadius: CGFloat {
        circleRadius / 2.0
    }
    private let imageInset: CGFloat = 5.0

    /// This is the color that is used to highlight a value change in this label.
    public var lineColor: UIColor = ThemeColors.shared.brand

    /// This is the color that is used to highlight a value change in this label.
    public var imageColor: UIColor = ThemeColors.shared.brand

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var image: UIImage? {
        didSet {
            setNeedsDisplay()
        }
    }

    var routeType: Route.RouteType = .unknown

    private var isUserDestination: Bool = false
    private var isCurrentVehicleLocation: Bool = false

    public func setDestinationStatus(user: Bool, vehicle: Bool) {
        isUserDestination = user
        isCurrentVehicleLocation = vehicle
        setAccessibilityLabel()
        setNeedsDisplay()
    }

    /// If the trip segment being represented is for an adjacent trip (i.e. either the previous or next trip), this should be non-nil.
    var adjacentTripOrder: AdjacentTripOrder?

    override public var intrinsicContentSize: CGSize {
        CGSize(width: circleRadius + (2.0 * lineWidth), height: UIView.noIntrinsicMetric)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        let ctx = UIGraphicsGetCurrentContext()
        ctx?.saveGState()

        lineColor.setFill()
        lineColor.setStroke()

        switch adjacentTripOrder {
        case .next:
            drawNextTripSegment(rect, context: ctx)
        case .previous:
            drawPreviousTripSegment(rect, context: ctx)
        default:
            drawRegularTripSegment(rect, context: ctx)
        }

        ctx?.restoreGState()
    }

    private func drawNextTripSegment(_ rect: CGRect, context: CGContext?) {
        let topLine = UIBezierPath(rect: CGRect(origin: CGPoint(x: rect.midX - (lineWidth / 2.0), y: rect.minY), size: CGSize(width: lineWidth, height: rect.midY)))
        topLine.fill()
    }

    private func drawPreviousTripSegment(_ rect: CGRect, context: CGContext?) {
        let bottomLine = UIBezierPath(rect: CGRect(origin: CGPoint(x: rect.midX - (lineWidth / 2.0), y: rect.midY), size: CGSize(width: lineWidth, height: rect.midY)))
        bottomLine.fill()
    }

    private func drawRegularTripSegment(_ rect: CGRect, context: CGContext?) {
        let topLine = UIBezierPath(rect: CGRect(origin: CGPoint(x: rect.midX - (lineWidth / 2.0), y: rect.minY), size: CGSize(width: lineWidth, height: rect.midY - halfRadius)))
        topLine.fill()

        let bezierFrame = CGRect(origin: CGPoint(x: rect.midX - halfRadius, y: rect.midY - halfRadius), size: CGSize(width: circleRadius, height: circleRadius))

        let bezierPath = UIBezierPath(roundedRect: bezierFrame, cornerRadius: ThemeMetrics.compactCornerRadius)
        bezierPath.lineWidth = lineWidth

        if isCurrentVehicleLocation {
            drawRouteType(routeType, frame: bezierFrame)
        }

        if isUserDestination {
            drawUserDestinationBadge(frame: bezierFrame, context: context)
        }

        bezierPath.stroke()

        let bottomLine = UIBezierPath(rect: CGRect(origin: CGPoint(x: rect.midX - (lineWidth / 2.0), y: rect.midY + halfRadius), size: CGSize(width: lineWidth, height: rect.midY - halfRadius)))
        bottomLine.fill()
    }

    private func drawUserDestinationBadge(frame: CGRect, context: CGContext?) {
        context?.saveGState()

        let miniFrame = CGRect(x: frame.midX - lineWidth, y: frame.midY - lineWidth, width: halfRadius + lineWidth, height: halfRadius + lineWidth)

        lineColor.setFill()
        ThemeColors.shared.systemBackground.setStroke()

        let corners = UIRectCorner.topLeft.union(.bottomRight)
        let cornerRadii = CGSize(width: ThemeMetrics.compactCornerRadius, height: ThemeMetrics.compactCornerRadius)
        let bezierPath = UIBezierPath(roundedRect: miniFrame, byRoundingCorners: corners, cornerRadii: cornerRadii)
        bezierPath.lineWidth = lineWidth
        bezierPath.fill()
        bezierPath.stroke()

        let icon = Icons.walkTransport.tinted(color: .white)
        icon.draw(in: miniFrame.insetBy(dx: 2.0, dy: 2.0))

        context?.restoreGState()
    }

    private func drawRouteType(_ routeType: Route.RouteType, frame: CGRect) {
        let image = Icons.transportIcon(from: routeType).tinted(color: imageColor)
        image.draw(in: frame.insetBy(dx: imageInset, dy: imageInset))
    }

    private func setAccessibilityLabel() {
        var flags: [String] = []

        if isUserDestination {
            flags.append(OBALoc("trip_stop.user_destination.accessibility_label", value: "Your destination", comment: "Voiceover text explaining that this stop is the user's destination"))
        }

        if isCurrentVehicleLocation {
            flags.append(OBALoc("trip_stop.vehicle_location.accessibility_label", value: "Vehicle is here", comment: "Voiceover text explaining that the vehicle is currently at this stop"))
        }

        let joined = flags.joined(separator: ", ")
        accessibilityLabel = joined.isEmpty ? nil : joined
        isAccessibilityElement = !joined.isEmpty
    }
}

#if DEBUG
import SwiftUI
import OBAKitCore

struct TripSegmentView_Previews: PreviewProvider {
    private static let width: CGFloat = 64
    private static let height: CGFloat = 44

    private static func tripSegmentView(user: Bool, vehicle: Bool) -> TripSegmentView {
        let view = TripSegmentView()
        view.setDestinationStatus(user: user, vehicle: vehicle)
        return view
    }

    private static func preview(for view: TripSegmentView, _ description: String) -> some View {
        VStack {
            UIViewPreview { view }
                .frame(width: width, height: height, alignment: .center)
            Text(description)
            Text(view.accessibilityLabel ?? "No VoiceOver label")
                .font(.caption)
        }.fixedSize()
    }

    static var previews: some View {
        HStack {
            preview(for: tripSegmentView(user: false, vehicle: false), "Standard")
            preview(for: tripSegmentView(user: true, vehicle: false), "User")
            preview(for: tripSegmentView(user: false, vehicle: true), "Vehicle")
            preview(for: tripSegmentView(user: true, vehicle: true), "User & Vehicle")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

#endif
