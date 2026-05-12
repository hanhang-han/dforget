// V2.0 — Quiet Luxury 高级类别设置页面
import SwiftUI

struct AdvancedCategoriesView: View {
    @State private var petName = ""
    @State private var petType = PetProfileManager.PetType.dog
    @State private var showPetSetup = false
    @State private var petProfileManager = PetProfileManager.shared

    @Environment(\.dismiss) private var dismiss
    @State private var currentTier: SubscriptionTier = SubscriptionManager.shared.currentTier

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 可用类别
                Section {
                    ForEach(AdvancedCategory.allCases, id: \.rawValue) { category in
                        HStack {
                            Image(systemName: category.iconName)
                                .font(.system(size: 16))
                                .frame(width: 28)
                                .foregroundStyle(QLDesign.Color.primaryText)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.rawValue)
                                    .font(QLDesign.Font.body(16))
                                    .foregroundStyle(QLDesign.Color.primaryText)
                                Text(category.description)
                                    .font(QLDesign.Font.body(12))
                                    .foregroundStyle(QLDesign.Color.secondaryText)
                            }

                            Spacer()

                            if currentTier == .pro {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(QLDesign.Color.secondaryText)
                            } else {
                                Text("PRO")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(SwiftUI.Color.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(SwiftUI.Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("提醒类别")
                } footer: {
                    if currentTier != .pro {
                        Text("升级 Pro 解锁所有高级类别")
                    }
                }

                // MARK: - 宠物设置
                if currentTier == .pro {
                    Section {
                        Button {
                            showPetSetup = true
                        } label: {
                            HStack {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(QLDesign.Color.primaryText)
                                VStack(alignment: .leading, spacing: 2) {
                                    if let pet = petProfileManager.currentPet {
                                        Text("\(pet.name) (\(pet.type.rawValue))")
                                            .font(QLDesign.Font.body(16))
                                            .foregroundStyle(QLDesign.Color.primaryText)
                                        Text("喂食间隔 \(pet.feedInterval)h · 遛狗间隔 \(pet.walkInterval)h")
                                            .font(QLDesign.Font.body(12))
                                            .foregroundStyle(QLDesign.Color.secondaryText)
                                    } else {
                                        Text("设置宠物信息")
                                            .font(QLDesign.Font.body(16))
                                            .foregroundStyle(QLDesign.Color.primaryText)
                                        Text("获取喂食、遛狗等提醒")
                                            .font(QLDesign.Font.body(12))
                                            .foregroundStyle(QLDesign.Color.secondaryText)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(QLDesign.Color.labelText)
                            }
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("宠物档案")
                    }
                }

                // MARK: - 位置设置
                if currentTier == .pro {
                    Section {
                        HStack {
                            Text("位置感知")
                                .foregroundStyle(QLDesign.Color.primaryText)
                            Spacer()
                            Toggle("", isOn: .constant(false))
                        }

                        HStack {
                            Text("家的位置")
                                .foregroundStyle(QLDesign.Color.primaryText)
                            Spacer()
                            Text("未设置")
                                .foregroundStyle(QLDesign.Color.secondaryText)
                        }

                        HStack {
                            Text("公司位置")
                                .foregroundStyle(QLDesign.Color.primaryText)
                            Spacer()
                            Text("未设置")
                                .foregroundStyle(QLDesign.Color.secondaryText)
                        }
                    } header: {
                        Text("位置感知")
                    } footer: {
                        Text("开启后可以根据你的位置生成上下文提醒，如离家提醒、到家提醒")
                    }
                }

                // MARK: - 家庭共享
                if currentTier == .pro {
                    Section {
                        NavigationLink {
                            FamilySettingsView()
                        } label: {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(QLDesign.Color.primaryText)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("家庭共享")
                                        .font(QLDesign.Font.body(16))
                                        .foregroundStyle(QLDesign.Color.primaryText)
                                    Text("与家人共享提醒和关怀卡片")
                                        .font(QLDesign.Font.body(12))
                                        .foregroundStyle(QLDesign.Color.secondaryText)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .tint(.white)
            .navigationTitle("高级功能")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPetSetup) {
                PetSetupView()
            }
        }
    }
}

// MARK: - 宠物设置

struct PetSetupView: View {
    @State private var name = ""
    @State private var petType = PetProfileManager.PetType.dog
    @State private var feedInterval = 8.0
    @State private var walkInterval = 4.0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("宠物名字", text: $name)
                    Picker("宠物类型", selection: $petType) {
                        ForEach(PetProfileManager.PetType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("喂食间隔")
                            .foregroundStyle(QLDesign.Color.primaryText)
                        Spacer()
                        Text("\(Int(feedInterval)) 小时")
                            .foregroundStyle(QLDesign.Color.secondaryText)
                    }
                    Slider(value: $feedInterval, in: 4...24, step: 1)
                        .tint(.white)

                    if petType == .dog {
                        HStack {
                            Text("遛狗间隔")
                                .foregroundStyle(QLDesign.Color.primaryText)
                            Spacer()
                            Text("\(Int(walkInterval)) 小时")
                                .foregroundStyle(QLDesign.Color.secondaryText)
                        }
                        Slider(value: $walkInterval, in: 2...12, step: 1)
                            .tint(.white)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("设置宠物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        savePet()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private func savePet() {
        var pet = PetProfileManager.PetProfile(name: name, type: petType, feedInterval: Int(feedInterval), walkInterval: Int(walkInterval))
        pet.lastFed = Date()
        pet.lastWalked = Date()
        PetProfileManager.shared.savePet(pet)
    }
}

// MARK: - 家庭设置

struct FamilySettingsView: View {
    @State private var members: [FamilyMember] = []
    @State private var showAddMember = false
    @State private var newMemberName = ""
    @State private var newMemberRelation = ""

    var body: some View {
        List {
            ForEach(members) { member in
                HStack {
                    Circle()
                        .fill(QLDesign.Color.surface)
                        .overlay(Circle().stroke(QLDesign.Color.border, lineWidth: 0.5))
                        .frame(width: 36, height: 36)
                        .overlay(Text(String(member.name.prefix(1))))
                        .foregroundStyle(QLDesign.Color.primaryText)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(QLDesign.Font.body(15))
                            .foregroundStyle(QLDesign.Color.primaryText)
                        Text(member.relation)
                            .font(QLDesign.Font.body(12))
                            .foregroundStyle(QLDesign.Color.secondaryText)
                    }
                }
                .padding(.vertical, 4)
            }

            Button {
                showAddMember = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(QLDesign.Color.secondaryText)
                    Text("添加家庭成员")
                        .foregroundStyle(QLDesign.Color.secondaryText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("家庭")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddMember) {
            // TODO: 实现添加成员界面
        }
    }
}
