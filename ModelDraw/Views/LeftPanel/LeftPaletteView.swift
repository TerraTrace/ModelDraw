//
//  LeftPaletteView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/14/25.
//


import SwiftUI


// MARK: - Updated Left Palette with Navigator Style
struct LeftPaletteView: View {
    let assemblies: [Assembly]
    let primitives: [GeometricPrimitive]
    @State private var selection: NavigatorItem?
    @State private var expandedItems: Set<UUID> = Set()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (same as before)
            HStack {
                Text("Project Navigator")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            
            // Navigator List with expansion control
            List(selection: $selection) {
                ForEach(navigatorItems, id: \.self) { item in
                    NavigatorNodeView(
                        item: item,
                        expandedItems: $expandedItems
                    )
                }
            }
            .listStyle(.sidebar)
            .onAppear {
                // Initialize top-level assemblies as expanded
                for assembly in assemblies {
                    if let assemblyItem = navigatorItems.first(where: {
                        if case .assembly = $0.itemType { return true }
                        return false
                    }) {
                        expandedItems.insert(assemblyItem.id)
                    }
                }
            }
        }
    }
    
    // Convert assemblies and primitives to navigator hierarchy
    private var navigatorItems: [NavigatorItem] {
        var items: [NavigatorItem] = []
        
        // Add assemblies with their hierarchical structure
        for assembly in assemblies {
            let assemblyChildren = createAssemblyChildren(assembly: assembly)
            let assemblyItem = NavigatorItem(
                name: assembly.name,
                itemType: .assembly,
                children: assemblyChildren.isEmpty ? [] : assemblyChildren
            )
            items.append(assemblyItem)
        }
        
        return items
    }
    
    private func createAssemblyChildren(assembly: Assembly) -> [NavigatorItem] {
        var children: [NavigatorItem] = []
        
        // Add child primitives
        for child in assembly.children {
            switch child {
            case .primitive(let id):
                if let primitive = primitives.first(where: { $0.id == id }) {
                    let primitiveItem = NavigatorItem(
                        name: primitive.primitiveType.rawValue.capitalized,
                        itemType: .primitive(primitive.primitiveType),
                        children: []
                    )
                    children.append(primitiveItem)
                }
            case .assembly(let id):
                // Handle nested assemblies (for future expansion)
                let nestedAssemblyItem = NavigatorItem(
                    name: "Nested Assembly",
                    itemType: .assembly,
                    children: []
                )
                children.append(nestedAssemblyItem)
            }
        }
        
        // Add mating rules as children
        if !assembly.matingRules.isEmpty {
            let matingRulesItem = NavigatorItem(
                name: "Mating Rules (\(assembly.matingRules.count))",
                itemType: .matingRule,
                children: assembly.matingRules.map { rule in
                    NavigatorItem(
                        name: "\(rule.anchorA) → \(rule.anchorB)",
                        itemType: .matingRule,
                        children: []
                    )
                }
            )
            children.append(matingRulesItem)
        }
        
        return children
    }
}


struct NavigatorNodeView: View {
    let item: NavigatorItem
    @Binding var expandedItems: Set<UUID>
    
    var body: some View {
        if let children = item.children, !children.isEmpty {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedItems.contains(item.id) },
                    set: { isExpanded in
                        if isExpanded {
                            expandedItems.insert(item.id)
                        } else {
                            expandedItems.remove(item.id)
                        }
                    }
                )
            ) {
                ForEach(children, id: \.self) { child in
                    NavigatorNodeView(item: child, expandedItems: $expandedItems)
                }
            } label: {
                NavigatorRowView(item: item)
            }
        } else {
            NavigatorRowView(item: item)
        }
    }
}
