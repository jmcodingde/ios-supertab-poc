//
//  SupertabLogo.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 17.10.22.
//

import SwiftUI

struct SupertabLogo: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Image(colorScheme == .light ? "SupertabLogo" : "SupertabLogoLight")
            .resizable()
            .scaledToFit()
    }
}

struct SupertabLogo_Previews: PreviewProvider {
    static var previews: some View {
        SupertabLogo()
            .padding()
    }
}
